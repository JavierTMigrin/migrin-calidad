// ============================================================
// Generación de SQL a partir de la pregunta en lenguaje natural.
// Usa la Claude API (Opus 4.8) por HTTP directo (sin SDK) — el
// bundler de Supabase Edge Functions es frágil con imports npm,
// así que un fetch plano es lo más robusto aquí.
// ============================================================

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";

// Helper genérico de la Claude API (también lo usa responder.ts)
export async function claude(system: string, userText: string, maxTokens: number): Promise<string> {
  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": Deno.env.get("ANTHROPIC_API_KEY") ?? "",
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-opus-4-8",
      max_tokens: maxTokens,
      thinking: { type: "adaptive" }, // deja que el modelo razone lo necesario
      system,
      messages: [{ role: "user", content: userText }],
    }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error("Claude API error: " + JSON.stringify(data));
  // El contenido trae bloques de thinking (vacíos por defecto) + text
  return (data.content || [])
    .filter((b: { type: string }) => b.type === "text")
    .map((b: { text: string }) => b.text)
    .join("")
    .trim();
}

function limpiarSQL(texto: string): string {
  let s = texto.trim();
  // Quitar cercos de código markdown si los hubiera
  s = s.replace(/^```(?:sql)?\s*/i, "").replace(/\s*```$/i, "").trim();
  // Quitar punto y coma final
  s = s.replace(/;\s*$/, "").trim();
  return s;
}

export async function generarSQL(
  pregunta: string,
  esquema: string,
  errorPrevio?: string,
): Promise<string> {
  const system = [
    "Eres un experto en PostgreSQL que traduce preguntas en español a una consulta SQL.",
    "",
    "REGLAS ESTRICTAS:",
    "- Genera EXACTAMENTE UNA consulta SQL de tipo SELECT (puede empezar con WITH).",
    "- PROHIBIDO: INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE, GRANT, etc. Solo lectura.",
    "- Usa SOLO las tablas y columnas que aparecen en el ESQUEMA. No inventes nombres.",
    "- Dialecto PostgreSQL. Para filtrar por mes usa date_trunc('month', fecha).",
    "- Prefiere la vista v_ia_ensayos (química ya expandida a columnas).",
    "- Devuelve SOLO la consulta SQL, sin explicación, sin markdown, sin punto y coma final.",
    "- Si la pregunta NO se puede responder con este esquema, devuelve exactamente:",
    "  SELECT 'NO_RESPONDIBLE' AS error",
    "",
    "ESQUEMA DISPONIBLE:",
    esquema,
  ].join("\n");

  let user = `Pregunta: ${pregunta}\n\nDevuelve solo la consulta SQL.`;
  if (errorPrevio) {
    user += `\n\nLa consulta anterior falló con este error de PostgreSQL. Corrígela:\n${errorPrevio}`;
  }

  const salida = await claude(system, user, 1500);
  return limpiarSQL(salida);
}
