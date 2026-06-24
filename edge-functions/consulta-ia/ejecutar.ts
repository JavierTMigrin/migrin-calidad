// ============================================================
// Validación y ejecución SEGURA de la SQL generada por la IA.
// Tres capas de protección:
//   1) Validación: un único SELECT, sin DDL/DML ni múltiples sentencias.
//   2) Rol de BD de solo lectura (ia_readonly) — la garantía dura.
//   3) Transacción READ ONLY + statement_timeout + LIMIT por defecto.
// ============================================================
import { db } from "./db.ts";

const LIMIT_DEFECTO = 200;
const TIMEOUT_MS = 8000;

const PROHIBIDAS = [
  "insert", "update", "delete", "drop", "alter", "create", "truncate",
  "grant", "revoke", "comment", "copy", "vacuum", "analyze", "call",
  "do", "merge", "refresh", "reindex", "lock", "set", "reset",
];

export function validarSelect(sqlRaw: string): { ok: boolean; motivo?: string } {
  const s = (sqlRaw || "").trim().replace(/;+\s*$/g, ""); // quita ; finales

  if (!s) return { ok: false, motivo: "Consulta vacía." };

  // Una sola sentencia: no debe quedar ningún ; intermedio
  if (s.includes(";")) return { ok: false, motivo: "Solo se permite una sentencia." };

  // Sin comentarios SQL (evita ofuscar comandos)
  if (s.includes("--") || s.includes("/*")) {
    return { ok: false, motivo: "No se permiten comentarios en la consulta." };
  }

  // Debe empezar con SELECT o WITH (CTE)
  if (!/^\s*(select|with)\b/i.test(s)) {
    return { ok: false, motivo: "Solo se permiten consultas SELECT." };
  }

  // Ninguna palabra clave de escritura/DDL como token completo
  const lower = s.toLowerCase();
  for (const kw of PROHIBIDAS) {
    const re = new RegExp(`\\b${kw}\\b`, "i");
    if (re.test(lower)) return { ok: false, motivo: `Operación no permitida: ${kw.toUpperCase()}.` };
  }

  return { ok: true };
}

export async function ejecutar(
  sqlRaw: string,
  limit = LIMIT_DEFECTO,
): Promise<Record<string, unknown>[]> {
  const v = validarSelect(sqlRaw);
  if (!v.ok) throw new Error("Consulta rechazada: " + v.motivo);

  const consulta = sqlRaw.trim().replace(/;+\s*$/g, "");
  // Envolver para aplicar un LIMIT duro sin alterar la consulta original
  const acotada = `SELECT * FROM ( ${consulta} ) AS _sub LIMIT ${limit}`;

  const sql = db();
  // Transacción de solo lectura con timeout (defensa en profundidad)
  const filas = await sql.begin(async (tx: any) => {
    await tx.unsafe("SET LOCAL transaction read only");
    await tx.unsafe(`SET LOCAL statement_timeout = ${TIMEOUT_MS}`);
    return await tx.unsafe(acotada);
  });

  return filas as unknown as Record<string, unknown>[];
}
