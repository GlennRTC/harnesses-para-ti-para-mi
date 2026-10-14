// PROBE Rhino/Mirth — pegar en el Deploy Script de un canal DESECHABLE en TEST, desplegar y leer el log del servidor.
// Antes: crear la clave probe_key=probe en el Configuration Map (para ver el tipo que devuelve get()).
// Este archivo usa solo sintaxis ES5: se parsea con cualquier rhino.languageversion.
var r = {};
function t(name, code) {
    try { r[name] = String(eval(code)); }
    catch (e) { r[name] = 'ERR: ' + String(e).substring(0, 70); }
}
t('let',              '(function(){ let a = 1; return a; })()');
t('const',            '(function(){ const a = 2; return a; })()');
t('arrow',            '((x) => x + 1)(1)');
t('template_literal', '(function(){ var n = "X"; return `a${n}b`; })()');          // esperado si interpola: aXb
t('for_of',           '(function(){ var s = 0; for (let v of [1,2]) { s += v; } return s; })()');
t('Map',              'typeof Map');
t('Set',              'typeof Set');
t('spread',           '(function(){ function f(a,b){ return a+b; } return f(...[1,2]); })()');
t('default_params',   '(function(){ function f(a, b = 5){ return a+b; } return f(1); })()');
t('class',            '(function(){ class A { m(){ return 1; } } return new A().m(); })()');
t('const_in_loop',    '(function(){ var o=[]; for (var i=0;i<3;i++){ const c=i; o.push(c);} return o.join(","); })()');   // esperado 0,1,2
t('let_closure',      '(function(){ var fs=[]; for (let i=0;i<3;i++){ fs.push(function(){return i;}); } return fs.map(function(f){return f();}).join(","); })()'); // esperado 0,1,2
t('Object.values',    'typeof Object.values');
t('Object.entries',   'typeof Object.entries');
t('Array.includes',   'typeof [].includes');
t('Array.flat',       'typeof [].flat');
t('String.padStart',  'typeof "".padStart');
t('JSON.stringify',   'typeof JSON.stringify');

try { r.java_version = String(java.lang.System.getProperty('java.version')); } catch (e) { r.java_version = 'ERR: ' + e; }
try {
    var cx = Packages.org.mozilla.javascript.Context.getCurrentContext();
    r.rhino_language_version = String(cx.getLanguageVersion());
} catch (e) { r.rhino_language_version = 'ERR: ' + e; }
try { r.rhino_impl_version = String(Packages.org.mozilla.javascript.Context.getCurrentContext().getImplementationVersion()); } catch (e) { r.rhino_impl_version = 'ERR: ' + e; }

// Variables disponibles en ESTE contexto (Deploy Script de canal)
var names = ['configurationMap','globalMap','globalChannelMap','channelMap','connectorMap','sourceMap','responseMap','router','alerts','DatabaseConnectionFactory','Lists','Maps','Status'];
r.scope = {};
for (var i = 0; i < names.length; i++) {
    try { r.scope[names[i]] = eval('typeof ' + names[i]); } catch (e) { r.scope[names[i]] = 'ERR'; }
}
try {
    var cv = configurationMap.get('probe_key');
    r.cfg_get = (cv === null || cv === undefined) ? 'null: crear la clave probe_key' : String(cv.getClass ? cv.getClass().getName() : typeof cv);
} catch (e) { r.cfg_get = 'ERR: ' + e; }

logger.info('PROBE-RHINO ' + JSON.stringify(r));
