// ============================================================
// Edge Function: consulta-ia  (VERSION DE UN SOLO ARCHIVO)
// Asistente de consultas en lenguaje natural sobre la BD (text-to-SQL).
// Motor de lenguaje: Groq (API compatible con OpenAI, inferencia rapida).
// Pega TODO este archivo como el index.ts de la funcion en Supabase.
//
// En el panel: "Verify JWT" = OFF (la validación de admin va en el código).
// SECRETS requeridos:
//   GROQ_API_KEY           = gsk_...
//   READONLY_DATABASE_URL  = postgresql://ia_readonly:CLAVE@HOST:5432/postgres?sslmode=require
//   SB_URL                 = https://wxjclxmtceuhlbwxtptc.supabase.co
//   SB_SERVICE_ROLE        = service role key (Project Settings -> API)
// ============================================================
import postgres from "https://deno.land/x/postgresjs@v3.4.5/mod.js";

const ALLOWED_ORIGIN = "https://javiertmigrin.github.io";
const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
const GROQ_MODEL = "openai/gpt-oss-120b"; // modelo mas capaz para SQL/razonamiento compuesto
const LIMIT_DEFECTO = 200;
const TIMEOUT_MS = 8000;
const PREFERIDAS = ["v_ia_ensayos", "v_ia_resumen_mensual"];
const PROHIBIDAS = [
  "insert","update","delete","drop","alter","create","truncate","grant","revoke",
  "comment","copy","vacuum","analyze","call","do","merge","refresh","reindex","lock","set","reset",
];

// ── Conexion BD (solo lectura) ──
let _sql: ReturnType<typeof postgres> | null = null;
function db() {
  if (_sql) return _sql;
  const url = Deno.env.get("READONLY_DATABASE_URL") ?? "";
  if (!url) throw new Error("Falta el secret READONLY_DATABASE_URL");
  _sql = postgres(url, { ssl: "require", max: 1, prepare: false, idle_timeout: 20 });
  return _sql;
}

// ── Helper Groq API (chat completions, compatible con OpenAI) ──
async function groq(system: string, userText: string, maxTokens: number): Promise<string> {
  const res = await fetch(GROQ_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "authorization": `Bearer ${Deno.env.get("GROQ_API_KEY") ?? ""}`,
    },
    body: JSON.stringify({
      model: GROQ_MODEL,
      max_tokens: maxTokens,
      temperature: 0.1,
      messages: [
        { role: "system", content: system },
        { role: "user", content: userText },
      ],
    }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error("Groq API error: " + JSON.stringify(data));
  return String(data?.choices?.[0]?.message?.content ?? "").trim();
}

// ── Introspeccion del esquema (cacheada) ──
let _esquemaCache: string | null = null;
async function obtenerEsquema(): Promise<string> {
  if (_esquemaCache) return _esquemaCache;
  const sql = db();
  const filas = await sql<{ tabla: string; columna: string; tipo: string; descripcion: string | null; tabla_desc: string | null; }[]>`
    SELECT c.relname AS tabla, a.attname AS columna,
           format_type(a.atttypid, a.atttypmod) AS tipo,
           col_description(c.oid, a.attnum) AS descripcion,
           obj_description(c.oid) AS tabla_desc
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.oid
    WHERE n.nspname='public' AND c.relkind IN ('r','v','m')
      AND a.attnum>0 AND NOT a.attisdropped
    ORDER BY c.relname, a.attnum`;
  const porTabla = new Map<string, { desc: string | null; cols: string[] }>();
  for (const f of filas) {
    if (!porTabla.has(f.tabla)) porTabla.set(f.tabla, { desc: f.tabla_desc, cols: [] });
    porTabla.get(f.tabla)!.cols.push(`    ${f.columna} ${f.tipo}` + (f.descripcion ? `  -- ${f.descripcion}` : ""));
  }
  let tablas = [...porTabla.keys()];
  if (PREFERIDAS.some((t) => porTabla.has(t))) {
    tablas = tablas.filter((t) => PREFERIDAS.includes(t) || t.startsWith("v_ia_"));
  }
  _esquemaCache = tablas.map((t) => {
    const info = porTabla.get(t)!;
    return (info.desc ? `-- ${info.desc}\n` : "") + `TABLE ${t} (\n${info.cols.join(",\n")}\n);`;
  }).join("\n\n");
  return _esquemaCache;
}

// ── Contexto guiado (planta/producto elegidos en el widget) ──
// Acota el foco de la consulta sin impedir que el usuario pregunte por
// otro producto explicitamente (la regla se lo permite).
interface Contexto { planta?: string; productos?: string[]; }
function lineaContexto(contexto?: Contexto): string {
  if (!contexto || !Array.isArray(contexto.productos) || !contexto.productos.length) return "";
  const lista = contexto.productos.map((p) => `'${String(p).replace(/'/g, "''")}'`).join(", ");
  const plantaTxt = contexto.planta ? ` (planta ${contexto.planta})` : "";
  return `\nCONTEXTO DE LA CONVERSACION: el usuario esta enfocado en el/los producto(s) producto_key IN (${lista})${plantaTxt}. Salvo que la pregunta mencione EXPLICITAMENTE otro producto distinto, filtra por esa condicion.\n`;
}

// ── Generacion de SQL ──
function limpiarSQL(t: string): string {
  return t.trim().replace(/^```(?:sql)?\s*/i, "").replace(/\s*```$/i, "").replace(/;\s*$/, "").trim();
}
async function generarSQL(pregunta: string, esquema: string, contexto?: Contexto, notaCorreccion?: string): Promise<string> {
  const system = [
    "Eres un experto en PostgreSQL que traduce preguntas en español a una consulta SQL.",
    "",
    "REGLAS ESTRICTAS:",
    "- Genera EXACTAMENTE UNA consulta SQL de tipo SELECT (puede empezar con WITH).",
    "- PROHIBIDO: INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE, GRANT, etc. Solo lectura.",
    "- Usa SOLO las tablas y columnas que aparecen en el ESQUEMA. No inventes nombres.",
    "- Dialecto PostgreSQL. Para filtrar por mes usa date_trunc('month', fecha).",
    "- Para preguntas sobre RESULTADOS quimicos/humedad (promedios, cuantos ensayos) usa v_ia_ensayos o v_ia_resumen_mensual.",
    "- Para preguntas sobre RESULTADOS de granulometria/mallas (retenido, pasante) usa v_ia_granulometria (una fila por ensayo+malla).",
    "- Para preguntas sobre EETT / especificacion tecnica / limites / normas / 'cuanto debe ser' usa v_ia_especificaciones (una fila por limite; columna 'limite' indica min/max, o retAcumMin/retAcumMax/retMin/retMax/pasMin/pasMax para mallas).",
    "- Los nombres de texto (cliente, producto) pueden no coincidir exactamente con lo que escribe el usuario: usa ILIKE '%texto%' en vez de '=' para columnas de texto como cliente, salvo que necesites una igualdad exacta por otro motivo.",
    "- Si la pregunta pide comparar RESULTADOS (quimica Y/O mallas) contra la EETT (p.ej. 'promedio vs limite', 'como van las desviaciones'), sigue este patron: calcula los promedios de quimica en una CTE y convierte a filas clave-valor con jsonb_each_text(to_jsonb(...)); calcula los promedios de malla en OTRA CTE agrupando por malla; UNE ambas CTEs con UNION ALL (mismas columnas: parametro, promedio) en una CTE 'todo'; luego haz UN SOLO JOIN de 'todo' contra v_ia_especificaciones que cubra ambos casos con OR. Ejemplo que combina quimica + 2 mallas contra Lirquen:",
    "  WITH prom_q AS (",
    "    SELECT AVG(sio2) AS \"SiO2\", AVG(al2o3) AS \"Al2O3\", AVG(fe2o3) AS \"Fe2O3\"",
    "    FROM v_ia_ensayos WHERE producto_key='A36' AND date_trunc('month',fecha)='2026-06-01'",
    "  ), prom_q_kv AS (SELECT key AS parametro, value::numeric AS promedio FROM prom_q, jsonb_each_text(to_jsonb(prom_q))),",
    "  prom_malla AS (",
    "    SELECT malla AS parametro, AVG(retenido_acumulado_pct) AS promedio FROM v_ia_granulometria",
    "    WHERE producto_key='A36' AND date_trunc('month',fecha)='2026-06-01' AND malla IN ('#120','#170') GROUP BY malla",
    "  ), todo AS (SELECT * FROM prom_q_kv UNION ALL SELECT * FROM prom_malla)",
    "  SELECT t.parametro, t.promedio, e.limite, e.valor AS limite_valor",
    "  FROM todo t JOIN v_ia_especificaciones e ON e.producto_key='A36' AND e.cliente ILIKE '%Lirquen%'",
    "    AND (e.parametro=t.parametro OR (e.parametro='Granulometria' AND e.malla=t.parametro));",
    "  Si la pregunta es SOLO de quimica o SOLO de mallas, omite la CTE que no corresponda (no fuerces el UNION si no hace falta).",
    "- Devuelve SOLO la consulta SQL, sin explicación, sin markdown, sin punto y coma final.",
    "- Si la pregunta NO se puede responder con este esquema, devuelve exactamente:",
    "  SELECT 'NO_RESPONDIBLE' AS error",
    lineaContexto(contexto),
    "ESQUEMA DISPONIBLE:",
    esquema,
  ].join("\n");
  let user = `Pregunta: ${pregunta}\n\nDevuelve solo la consulta SQL.`;
  if (notaCorreccion) user += `\n\n${notaCorreccion}`;
  return limpiarSQL(await groq(system, user, 2000));
}

// ── Validacion + ejecucion segura ──
function validarSelect(sqlRaw: string): { ok: boolean; motivo?: string } {
  const s = (sqlRaw || "").trim().replace(/;+\s*$/g, "");
  if (!s) return { ok: false, motivo: "Consulta vacía." };
  if (s.includes(";")) return { ok: false, motivo: "Solo se permite una sentencia." };
  if (s.includes("--") || s.includes("/*")) return { ok: false, motivo: "No se permiten comentarios." };
  if (!/^\s*(select|with)\b/i.test(s)) return { ok: false, motivo: "Solo se permiten consultas SELECT." };
  for (const kw of PROHIBIDAS) {
    if (new RegExp(`\\b${kw}\\b`, "i").test(s)) return { ok: false, motivo: `Operación no permitida: ${kw.toUpperCase()}.` };
  }
  return { ok: true };
}
async function ejecutar(sqlRaw: string, limit = LIMIT_DEFECTO): Promise<Record<string, unknown>[]> {
  const v = validarSelect(sqlRaw);
  if (!v.ok) throw new Error("Consulta rechazada: " + v.motivo);
  const consulta = sqlRaw.trim().replace(/;+\s*$/g, "");
  const acotada = `SELECT * FROM ( ${consulta} ) AS _sub LIMIT ${limit}`;
  const sql = db();
  const filas = await sql.begin(async (tx: any) => {
    await tx.unsafe("SET LOCAL transaction read only");
    await tx.unsafe(`SET LOCAL statement_timeout = ${TIMEOUT_MS}`);
    return await tx.unsafe(acotada);
  });
  return filas as unknown as Record<string, unknown>[];
}

// ── Respuesta en lenguaje natural ──
async function responder(pregunta: string, sqlUsada: string, filas: Record<string, unknown>[]): Promise<string> {
  const system = [
    "Eres un asistente de control de calidad de una planta minera (MIGRIN).",
    "Respondes en español, de forma clara, breve y profesional.",
    "Te basas ÚNICAMENTE en los datos entregados; no inventes cifras ni conclusiones que los datos no respaldan.",
    "REGLA CRÍTICA: un resultado VACÍO (0 filas) significa que la consulta no encontró filas que cumplan las condiciones — nada más. NUNCA lo interpretes como 'todo está dentro de norma', 'no hay desviaciones', 'cumple' o cualquier conclusión positiva: eso sería inventar una conclusión que los datos no muestran. Si el resultado viene vacío, dilo tal cual: 'No se encontraron datos para esta consulta (periodo, producto o filtro pueden no tener registros, o el cruce de tablas no coincidió). Intenta reformular la pregunta o revisar el período.'",
    "Si ves un único valor 'NO_RESPONDIBLE', explica que la pregunta no se puede responder con los datos disponibles.",
    "Cuando haya números, redondéalos de forma sensata e incluye unidades (%, g) si corresponde.",
    "Si estás comparando un promedio contra un límite EETT, di explícitamente si CUMPLE o NO CUMPLE cada parámetro (compara el valor real contra el límite: min significa que el valor debe ser mayor o igual; max que debe ser menor o igual).",
  ].join("\n");
  const user = [
    `Pregunta del usuario: ${pregunta}`, ``,
    `Consulta SQL ejecutada:`, sqlUsada, ``,
    `Resultado (JSON, hasta 50 filas):`, JSON.stringify(filas.slice(0, 50)), ``,
    `Redacta la respuesta para el usuario.`,
  ].join("\n");
  return await groq(system, user, 1024);
}

// ── Orquestacion ──
function cors(origin: string | null) {
  return {
    "Access-Control-Allow-Origin": origin === ALLOWED_ORIGIN ? ALLOWED_ORIGIN : "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
}

// Verifica que quien llama sea un usuario ADMIN (rol en user_metadata.is_admin).
async function verificarAdmin(req: Request): Promise<{ ok: boolean; status: number; motivo: string }> {
  const sbUrl = Deno.env.get("SB_URL") ?? "";
  const sbKey = Deno.env.get("SB_SERVICE_ROLE") ?? "";
  if (!sbUrl || !sbKey) return { ok: false, status: 500, motivo: "Faltan secrets SB_URL / SB_SERVICE_ROLE." };
  const token = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "").trim();
  if (!token) return { ok: false, status: 401, motivo: "No autenticado." };
  const r = await fetch(`${sbUrl}/auth/v1/user`, { headers: { Authorization: `Bearer ${token}`, apikey: sbKey } });
  if (!r.ok) return { ok: false, status: 401, motivo: "Sesión inválida o expirada." };
  const user = await r.json();
  if (user?.user_metadata?.is_admin === true) return { ok: true, status: 200, motivo: "" };
  return { ok: false, status: 403, motivo: "Solo el administrador puede usar esta función." };
}

Deno.serve(async (req) => {
  const origin = req.headers.get("origin");
  const ch = { ...cors(origin), "Content-Type": "application/json; charset=utf-8" };
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors(origin) });

  if (req.method === "GET") {
    return new Response(JSON.stringify({
      funcion: "consulta-ia (text-to-SQL, motor Groq)",
      estado: "activa",
      GROQ_API_KEY: (Deno.env.get("GROQ_API_KEY") ?? "") ? "presente" : "FALTA",
      READONLY_DATABASE_URL: (Deno.env.get("READONLY_DATABASE_URL") ?? "") ? "presente" : "FALTA",
      SB_URL: (Deno.env.get("SB_URL") ?? "") ? "presente" : "FALTA",
      SB_SERVICE_ROLE: (Deno.env.get("SB_SERVICE_ROLE") ?? "") ? "presente" : "FALTA",
    }, null, 2), { status: 200, headers: ch });
  }

  try {
    // Candado: solo administradores
    const adm = await verificarAdmin(req);
    if (!adm.ok) return new Response(JSON.stringify({ error: adm.motivo }), { status: adm.status, headers: ch });

    const { pregunta, contexto } = await req.json();
    if (!pregunta || typeof pregunta !== "string") {
      return new Response(JSON.stringify({ error: "Falta 'pregunta' (texto)." }), { status: 400, headers: ch });
    }
    const esquema = await obtenerEsquema();
    let sql = await generarSQL(pregunta, esquema, contexto);
    if (/no_respondible/i.test(sql)) sql = "SELECT 'NO_RESPONDIBLE' AS error";
    let filas: Record<string, unknown>[];
    try {
      filas = await ejecutar(sql);
    } catch (err1) {
      const motivo = String((err1 as Error)?.message ?? err1);
      sql = await generarSQL(pregunta, esquema, contexto,
        `La consulta anterior fallo con este error de PostgreSQL. Corrigela:\n${sql}\n${motivo}`);
      const v = validarSelect(sql);
      if (!v.ok) return new Response(JSON.stringify({ error: "No se pudo generar una consulta segura: " + v.motivo }), { status: 422, headers: ch });
      filas = await ejecutar(sql);
    }
    // La consulta corrio sin error pero no trajo filas: puede ser un filtro
    // de texto que no calzo exactamente (nombre de cliente/producto con
    // otra redaccion, mayusculas, etc.) o un filtro demasiado estricto.
    // Se le da al modelo UNA oportunidad de revisar/corregir antes de
    // aceptar que efectivamente no hay datos.
    if (filas.length === 0 && !/no_respondible/i.test(sql)) {
      try {
        const sqlReintento = await generarSQL(pregunta, esquema, contexto,
          `La consulta anterior se ejecuto correctamente pero devolvio 0 filas:\n${sql}\nUn resultado vacio en una consulta de comparacion NO significa que todo cumple, significa que el JOIN o filtro no encontro coincidencias — revisa: (1) si el JOIN entre CTEs de resultados y v_ia_especificaciones tiene la condicion correcta (parametro=... OR (parametro='Granulometria' AND malla=...) si combinas quimica y mallas), (2) si algun filtro de texto (cliente, producto, parametro) no coincide EXACTAMENTE — usa ILIKE en vez de '=' si no lo hiciste, (3) fechas y rangos. Genera una version corregida, o la misma consulta si estas seguro de que es correcta.`);
        if (!/no_respondible/i.test(sqlReintento)) {
          const v2 = validarSelect(sqlReintento);
          if (v2.ok) {
            const filas2 = await ejecutar(sqlReintento);
            if (filas2.length > 0) { filas = filas2; sql = sqlReintento; }
          }
        }
      } catch { /* si el reintento falla, se sigue con el resultado vacio original */ }
    }
    const respuesta = await responder(pregunta, sql, filas);
    return new Response(JSON.stringify({ respuesta, sql_usada: sql, datos: filas, n_filas: filas.length }, null, 2), { status: 200, headers: ch });
  } catch (e) {
    return new Response(JSON.stringify({ error: String((e as Error)?.message ?? e) }), { status: 500, headers: ch });
  }
});
