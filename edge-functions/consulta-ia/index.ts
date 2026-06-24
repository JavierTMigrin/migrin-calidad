// ============================================================
// Edge Function: consulta-ia
// Asistente de consultas en lenguaje natural sobre la BD (text-to-SQL).
//
// En el panel de Supabase: "Verify JWT" = OFF (igual que las otras).
// La protección queda por CORS (solo tu dominio) + rol de BD solo-lectura.
//
// SECRETS requeridos:
//   ANTHROPIC_API_KEY      = sk-ant-...          (clave de la Claude API)
//   READONLY_DATABASE_URL  = postgresql://ia_readonly:CLAVE@HOST:5432/postgres?sslmode=require
// ============================================================
import { obtenerEsquema } from "./esquema.ts";
import { generarSQL } from "./generar-sql.ts";
import { ejecutar, validarSelect } from "./ejecutar.ts";
import { responder } from "./responder.ts";

const ALLOWED_ORIGIN = "https://javiertmigrin.github.io";

function cors(origin: string | null) {
  return {
    "Access-Control-Allow-Origin": origin === ALLOWED_ORIGIN ? ALLOWED_ORIGIN : "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
}

Deno.serve(async (req) => {
  const origin = req.headers.get("origin");
  const ch = { ...cors(origin), "Content-Type": "application/json; charset=utf-8" };

  if (req.method === "OPTIONS") return new Response("ok", { headers: cors(origin) });

  // Vista de estado al abrir la URL en el navegador (no consulta nada)
  if (req.method === "GET") {
    return new Response(JSON.stringify({
      funcion: "consulta-ia (text-to-SQL)",
      estado: "activa",
      ANTHROPIC_API_KEY: (Deno.env.get("ANTHROPIC_API_KEY") ?? "") ? "presente" : "FALTA",
      READONLY_DATABASE_URL: (Deno.env.get("READONLY_DATABASE_URL") ?? "") ? "presente" : "FALTA",
    }, null, 2), { status: 200, headers: ch });
  }

  try {
    const { pregunta } = await req.json();
    if (!pregunta || typeof pregunta !== "string") {
      return new Response(JSON.stringify({ error: "Falta 'pregunta' (texto)." }), { status: 400, headers: ch });
    }

    const esquema = await obtenerEsquema();

    // Intento 1
    let sql = await generarSQL(pregunta, esquema);
    let filas: Record<string, unknown>[];
    try {
      sql = saltarSiNoRespondible(sql);
      filas = await ejecutar(sql);
    } catch (err1) {
      // Reintento 1: devolverle el error al modelo para que corrija
      const motivo = String((err1 as Error)?.message ?? err1);
      sql = await generarSQL(pregunta, esquema, motivo);
      const v = validarSelect(sql);
      if (!v.ok) {
        return new Response(JSON.stringify({ error: "No se pudo generar una consulta segura: " + v.motivo }), { status: 422, headers: ch });
      }
      filas = await ejecutar(sql);
    }

    const respuesta = await responder(pregunta, sql, filas);

    return new Response(JSON.stringify({
      respuesta,
      sql_usada: sql,
      datos: filas,
      n_filas: filas.length,
    }, null, 2), { status: 200, headers: ch });

  } catch (e) {
    return new Response(JSON.stringify({ error: String((e as Error)?.message ?? e) }), {
      status: 500, headers: ch,
    });
  }
});

// Si el modelo decidió que la pregunta no es respondible, lo dejamos pasar
// como un SELECT trivial para que "responder" lo explique al usuario.
function saltarSiNoRespondible(sql: string): string {
  if (/no_respondible/i.test(sql)) return "SELECT 'NO_RESPONDIBLE' AS error";
  return sql;
}
