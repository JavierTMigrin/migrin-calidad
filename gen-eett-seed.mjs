// Genera supabase-eett-seed.sql con las EETT por defecto de calidad.html
// para sembrar la tabla `especificaciones` de Supabase.
import { readFileSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const dir = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(join(dir, 'calidad.html'), 'utf8');

// Extraer cada bloque `const SPECS_X={ ... };` (termina en `};` a inicio de linea)
function extract(name) {
  const re = new RegExp(`const ${name}=\\{[\\s\\S]*?\\n\\};`, 'm');
  const m = html.match(re);
  if (!m) throw new Error(`No se encontro ${name}`);
  return m[0];
}

const names = ['SPECS_A36','SPECS_CTLH','SPECS_CDLK','SPECS_VERALTA','SPECS_VERBAJA',
  'SPECS_A38','SPECS_DESP_LIRQUEN','SPECS_DESP_CRIST','SPECS_TT_LODO'];
const code = names.map(extract).join('\n');
const fn = new Function(code + `
  return { SPECS_A36, SPECS_CTLH, SPECS_CDLK, SPECS_VERALTA, SPECS_VERBAJA,
           SPECS_A38, SPECS_DESP_LIRQUEN, SPECS_DESP_CRIST, SPECS_TT_LODO };`);
const S = fn();

// Misma asignacion que EETT_DEFAULTS en la app:
const seed = {
  A36: S.SPECS_A36,
  A38: S.SPECS_A38,
  VERALTA: S.SPECS_VERALTA,
  VERBAJA: S.SPECS_VERBAJA,
  CTLH: S.SPECS_CTLH,
  CDLK: S.SPECS_CDLK,
  DESP_LIR: S.SPECS_DESP_LIRQUEN,
  DESP_PH: S.SPECS_DESP_CRIST,
  DESP_LLAY: S.SPECS_DESP_CRIST,
  TT_LODO: S.SPECS_TT_LODO,
};

let sql = `-- ============================================================
-- MIGRIN Control de Calidad - Seed de EETT por defecto
-- Ejecutar en el SQL Editor de Supabase (despues de eett-setup).
-- Publica en la tabla especificaciones las EETT que la app trae
-- programadas, para que las vistas de analisis las puedan leer.
-- ON CONFLICT DO NOTHING: NO pisa lo que ya hayas editado en Ajustes.
-- Generado desde calidad.html con gen-eett-seed.mjs
-- ============================================================

INSERT INTO especificaciones (producto_key, specs, updated_by) VALUES
`;
const rows = Object.entries(seed).map(([key, spec]) =>
  `('${key}', '${JSON.stringify(spec).replace(/'/g, "''")}'::jsonb, 'seed-defaults')`);
sql += rows.join(',\n') + '\nON CONFLICT (producto_key) DO NOTHING;\n';

writeFileSync(join(dir, 'supabase-eett-seed.sql'), sql);
console.log(`OK: ${rows.length} productos -> supabase-eett-seed.sql`);
