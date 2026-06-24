// ============================================================
// Introspección del esquema: arma el contexto que recibe el modelo.
// Lee tablas/vistas, columnas, tipos y COMMENTS del esquema public.
// Usa los comentarios de Postgres como descripción de cada columna.
// Se cachea en memoria por instancia (se refresca al reiniciar).
// ============================================================
import { db } from "./db.ts";

let _cache: string | null = null;

// Si se define, solo se exponen estos objetos (recomendado: las vistas v_ia_*).
// Por defecto se exponen las vistas v_ia_* y, si no hubiera, las tablas base.
const PREFERIDAS = ["v_ia_ensayos", "v_ia_resumen_mensual"];

export async function obtenerEsquema(forzar = false): Promise<string> {
  if (_cache && !forzar) return _cache;
  const sql = db();

  const filas = await sql<{
    tabla: string;
    columna: string;
    tipo: string;
    descripcion: string | null;
    tabla_desc: string | null;
  }[]>`
    SELECT
      c.relname                              AS tabla,
      a.attname                              AS columna,
      format_type(a.atttypid, a.atttypmod)   AS tipo,
      col_description(c.oid, a.attnum)        AS descripcion,
      obj_description(c.oid)                  AS tabla_desc
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.oid
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r','v','m')   -- tablas, vistas, vistas materializadas
      AND a.attnum > 0
      AND NOT a.attisdropped
    ORDER BY c.relname, a.attnum
  `;

  // Agrupar por tabla
  const porTabla = new Map<string, { desc: string | null; cols: string[] }>();
  for (const f of filas) {
    if (!porTabla.has(f.tabla)) porTabla.set(f.tabla, { desc: f.tabla_desc, cols: [] });
    const linea = `    ${f.columna} ${f.tipo}` + (f.descripcion ? `  -- ${f.descripcion}` : "");
    porTabla.get(f.tabla)!.cols.push(linea);
  }

  // Preferir las vistas de dominio si existen
  let tablas = [...porTabla.keys()];
  const tienePreferidas = PREFERIDAS.some((t) => porTabla.has(t));
  if (tienePreferidas) {
    tablas = tablas.filter((t) => PREFERIDAS.includes(t) || t.startsWith("v_ia_"));
  }

  const bloques = tablas.map((t) => {
    const info = porTabla.get(t)!;
    const cab = info.desc ? `-- ${info.desc}\n` : "";
    return `${cab}TABLE ${t} (\n${info.cols.join(",\n")}\n);`;
  });

  _cache = bloques.join("\n\n");
  return _cache;
}
