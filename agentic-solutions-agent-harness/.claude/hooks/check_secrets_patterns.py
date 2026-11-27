#!/usr/bin/env python3
"""PreToolUse hook: heuristic secret detection. Not a real secret scanner.

Checks the content of Write/Edit calls and Bash commands for patterns that
suggest a raw credential. Expect false negatives and false positives; use a
dedicated scanner (gitleaks, trufflehog) in CI as the actual control.

Exit code 0 allows the call. Exit code 2 blocks it and shows the reason.
Self-check: python3 check_secrets_patterns.py --self-test
"""
import json
import os
import re
import sys

# Recognizable credential formats: blocked in every file, tests and docs included.
STRICT_PATTERNS = {
    "anthropic_key": re.compile(r"\bsk-ant-[A-Za-z0-9_\-]{20,}"),
    "openai_key": re.compile(r"\bsk-(?:(?:proj|svcacct)-[A-Za-z0-9_\-]{20,}|[A-Za-z0-9]{32,})"),
    "google_api_key": re.compile(r"\bAIza[0-9A-Za-z_\-]{35}"),
    "aws_access_key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "github_token": re.compile(r"\bgh[pousr]_[A-Za-z0-9]{36,}\b"),
    "private_key_block": re.compile(r"-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"),
}

# Heuristics: skipped for docs, tests and example files.
LOOSE_PATTERNS = {
    "assigned_secret": re.compile(
        r"(?i)(api[_-]?key|secret[_-]?key|access[_-]?token)\b\s*[:=]\s*['\"][A-Za-z0-9_\-./+=]{16,}['\"]"
    ),
    "connection_string_with_password": re.compile(
        r"(?i)\b(postgres(ql)?|mysql|rediss?|mongodb(\+srv)?)://[^\s'\"@/]*:[^\s'\"@/]{4,}@"
    ),
    "secret_exposed_to_client": re.compile(
        r"\bNEXT_PUBLIC_[A-Z0-9_]*(SECRET|PRIVATE|PASSWORD|ANTHROPIC|OPENAI)[A-Z0-9_]*"
    ),
}

ALLOWED_PATH = re.compile(
    r"(\.md$|\.env\.example$|\.(test|spec)\.[cm]?[jt]sx?$|(^|/)(tests?|__tests__|__mocks__|fixtures|mocks)/)"
)


def find_hits(text: str, path: str) -> list[str]:
    patterns = dict(STRICT_PATTERNS)
    if not ALLOWED_PATH.search(path):
        patterns.update(LOOSE_PATTERNS)
    return [name for name, pattern in patterns.items() if pattern.search(text)]


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        sys.exit(0)  # never block because of our own parsing problem

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input") or {}

    if tool_name in ("Write", "Edit"):
        path = str(tool_input.get("file_path", ""))
        text = f"{tool_input.get('content', '')}\n{tool_input.get('new_string', '')}"
        project = os.environ.get("CLAUDE_PROJECT_DIR")
        if project and path.startswith(project + os.sep):
            path = os.path.relpath(path, project)
    elif tool_name == "Bash":
        path = ""
        text = str(tool_input.get("command", ""))
    else:
        sys.exit(0)

    hits = find_hits(text, path.replace("\\", "/"))
    if hits:
        print(
            f"[check_secrets_patterns] Possible secret ({', '.join(hits)}) in {path or tool_name}. "
            "This is a heuristic: if it is real, move it to an environment variable. If it is "
            "synthetic test data, build the string by concatenation or ask the user.",
            file=sys.stderr,
        )
        sys.exit(2)
    sys.exit(0)


def self_test() -> None:
    # Fake values are concatenated so this file does not match its own patterns.
    anthropic = "sk-" + "ant-" + "x" * 30
    openai = "sk-" + "proj-" + "x" * 30
    assigned = "ANTHROPIC_API_" + 'KEY="' + "x" * 24 + '"'
    redis = "redis" + "://:" + "hunter22@localhost"
    public = "NEXT_PUBLIC_" + "OPENAI_API_KEY"

    assert "anthropic_key" in find_hits(anthropic, "lib/agent/model.ts")
    assert "anthropic_key" in find_hits(anthropic, "docs/notes.md")
    assert "openai_key" in find_hits(openai, "evals/case.test.ts")
    assert "assigned_secret" in find_hits(assigned, "lib/latest/config.ts")
    assert "connection_string_with_password" in find_hits(redis, "")
    assert "secret_exposed_to_client" in find_hits(public, "app/page.tsx")
    assert find_hits(assigned, "tests/config.ts") == []
    assert find_hits(public, "README.md") == []
    assert find_hits("const key = process.env.ANTHROPIC_API_KEY", "lib/env.ts") == []
    assert find_hits("NEXT_PUBLIC_APP_URL=http://localhost:3000", ".env.sample") == []
    assert find_hits("className='task-list-" + "x" * 40 + "'", "components/a.tsx") == []
    print("self-test ok")


if __name__ == "__main__":
    self_test() if "--self-test" in sys.argv else main()
