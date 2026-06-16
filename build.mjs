// ============================================================
// Build: precompila el JSX de calidad.src.html a JS plano y genera
//   - calidad.html        (produccion, sin Babel en runtime)
//   - calidad_local.html  (igual, titulo con "(LOCAL)")
//
// La FUENTE editable es calidad.src.html (contiene el JSX).
// Tras editarla, ejecutar:  node build.mjs
// ============================================================
import { readFileSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import babel from '@babel/standalone';

const dir = dirname(fileURLToPath(import.meta.url));
const SRC = join(dir, 'calidad.src.html');
let html = readFileSync(SRC, 'utf8');

// 1) Quitar el <script> de Babel standalone (ya no se usa en runtime)
html = html.replace(/[ \t]*<script src="https:\/\/unpkg\.com\/@babel\/standalone\/babel\.min\.js"><\/script>\r?\n/, '');

// 2) Extraer el bloque <script type="text/babel"> ... </script>
const re = /<script type="text\/babel">([\s\S]*?)<\/script>/;
const m = html.match(re);
if (!m) { console.error('No se encontro <script type="text/babel">'); process.exit(1); }
const jsx = m[1];

// 3) Compilar JSX -> JS (solo preset react; se mantiene ES moderno)
const out = babel.transform(jsx, {
  presets: [['react', { runtime: 'classic' }]],
  compact: false,
});

// 4) Reinsertar como <script> plano, envuelto en IIFE para que las
//    declaraciones (const supabase, etc.) queden en scope de funcion y
//    no choquen con globales del CDN (window.supabase) ni del runtime.
html = html.replace(re, '<script>\n(function(){\n' + out.code + '\n})();\n</script>');

// 5) Escribir produccion + local (sin BOM)
function write(file, content) { writeFileSync(file, content, { encoding: 'utf8' }); }
write(join(dir, 'calidad.html'), html);
const local = html.replace(
  '<title>Control de Calidad — MIGRIN S.A.</title>',
  '<title>Control de Calidad — MIGRIN S.A. (LOCAL)</title>'
);
write(join(dir, 'calidad_local.html'), local);

console.log('OK: calidad.html y calidad_local.html generados (JSX precompilado, sin Babel runtime).');
