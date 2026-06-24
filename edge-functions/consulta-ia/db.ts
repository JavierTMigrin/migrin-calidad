// ============================================================
// Conexión a PostgreSQL con el rol de SOLO LECTURA (ia_readonly).
// La cadena de conexión viene del secret READONLY_DATABASE_URL.
// ============================================================
import postgres from "https://deno.land/x/postgresjs@v3.4.5/mod.js";

let _sql: ReturnType<typeof postgres> | null = null;

export function db() {
  if (_sql) return _sql;
  const url = Deno.env.get("READONLY_DATABASE_URL") ?? "";
  if (!url) throw new Error("Falta el secret READONLY_DATABASE_URL");
  _sql = postgres(url, {
    ssl: "require",   // Supabase exige SSL
    max: 1,           // una conexión por instancia de la función
    prepare: false,   // compatible con el pooler de Supabase
    idle_timeout: 20,
  });
  return _sql;
}
