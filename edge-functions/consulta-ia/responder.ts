// ============================================================
// Convierte el resultado de la SQL en una respuesta en lenguaje
// natural, clara para el usuario. Reutiliza el helper claude().
// ============================================================
import { claude } from "./generar-sql.ts";

export async function responder(
  pregunta: string,
  sqlUsada: string,
  filas: Record<string, unknown>[],
): Promise<string> {
  const muestra = filas.slice(0, 50); // no saturar el contexto
  const system = [
    "Eres un asistente de control de calidad de una planta minera (MIGRIN).",
    "Respondes en español, de forma clara, breve y profesional.",
    "Te baso ÚNICAMENTE en los datos entregados; no inventes cifras.",
    "Si el resultado viene vacío, dilo claramente.",
    "Si ves un único valor 'NO_RESPONDIBLE', explica que la pregunta no se puede responder con los datos disponibles.",
    "Cuando haya números, redondéalos de forma sensata e incluye unidades (%, g) si corresponde.",
  ].join("\n");

  const user = [
    `Pregunta del usuario: ${pregunta}`,
    ``,
    `Consulta SQL ejecutada:`,
    sqlUsada,
    ``,
    `Resultado (JSON, hasta 50 filas):`,
    JSON.stringify(muestra),
    ``,
    `Redacta la respuesta para el usuario.`,
  ].join("\n");

  return await claude(system, user, 1024);
}
