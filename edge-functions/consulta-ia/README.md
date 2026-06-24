# Asistente de consultas IA (text-to-SQL) — `consulta-ia`

Convierte preguntas en español sobre la base de datos de calidad en una consulta
SQL, la ejecuta de forma segura (solo lectura) y devuelve la respuesta en lenguaje
natural, junto con el SQL usado y los datos crudos.

## Cómo funciona

```
pregunta → [esquema.ts: introspección] → [generar-sql.ts: Claude Opus 4.8 → SQL]
        → [ejecutar.ts: valida SELECT-only + rol read-only + timeout + LIMIT]
        → (si falla, reintenta 1 vez enviando el error a Claude)
        → [responder.ts: Claude redacta la respuesta] → { respuesta, sql_usada, datos }
```

## Archivos

| Archivo | Qué hace |
|---------|----------|
| `index.ts` | Orquesta todo: CORS, parse, reintento, arma la respuesta JSON |
| `esquema.ts` | Lee tablas/columnas/tipos/COMMENTS y arma el contexto del modelo (cacheado) |
| `generar-sql.ts` | Pregunta → SQL con la Claude API (Opus 4.8). Incluye el helper `claude()` |
| `ejecutar.ts` | Valida que sea un único SELECT y lo ejecuta en una transacción read-only acotada |
| `responder.ts` | Filas → respuesta en lenguaje natural |
| `db.ts` | Conexión a Postgres con el rol de solo lectura |

## Puesta en marcha (una sola vez)

1. **Crear el rol de solo lectura y las vistas** (SQL Editor de Supabase):
   - Ejecuta `supabase/6_consulta_ia/01_rol-solo-lectura.sql` (cambia la clave).
   - Ejecuta `supabase/6_consulta_ia/02_vistas-dominio.sql`.

2. **Crear la Edge Function** `consulta-ia` en Supabase y pegar estos archivos.
   - **"Verify JWT" = OFF** (igual que las otras funciones).

3. **Secrets de la función** (Edge Functions → consulta-ia → Secrets):
   - `ANTHROPIC_API_KEY` = tu clave de la Claude API (`sk-ant-...`).
   - `READONLY_DATABASE_URL` = cadena de conexión del rol `ia_readonly`:
     `postgresql://ia_readonly:TU_CLAVE@HOST:5432/postgres?sslmode=require`
     (el HOST está en Supabase → Project Settings → Database → Connection string).

4. **Deploy.**

## Probar

**A. Estado** (abrir en el navegador, no consulta nada): confirma que los secrets están.
```
https://<tu-proyecto>.supabase.co/functions/v1/consulta-ia
```
Debe responder `ANTHROPIC_API_KEY: presente`, `READONLY_DATABASE_URL: presente`.

**B. Una consulta** (POST):
```bash
curl -X POST "https://<tu-proyecto>.supabase.co/functions/v1/consulta-ia" \
  -H "Content-Type: application/json" \
  -H "apikey: TU_ANON_KEY" \
  -d '{"pregunta":"¿Cuál fue el promedio de SiO2 del A36 en lo que va del año?"}'
```
Respuesta:
```json
{
  "respuesta": "El SiO2 promedio del A36 en 2026 fue de 99,1 %...",
  "sql_usada": "SELECT AVG(sio2) ... FROM v_ia_ensayos WHERE producto_key='A36' ...",
  "datos": [ { "avg": 99.12 } ],
  "n_filas": 1
}
```

## Seguridad

- **Rol de solo lectura** (`ia_readonly`): a nivel de base de datos no puede escribir.
- **Validación SELECT-only**: rechaza múltiples sentencias, comentarios y cualquier
  palabra de escritura/DDL.
- **Transacción `READ ONLY` + `statement_timeout` + `LIMIT`** por defecto.
- La clave de Claude y la conexión viven como **secrets** del servidor; nunca en el frontend.
- Protección de acceso por **CORS** (solo el dominio de la app).

## Notas

- Las consultas de granulometría/curvas pueden apoyarse en las vistas ya creadas por
  `2_vistas/` (el rol read-only ya tiene SELECT sobre ellas).
- El esquema se cachea por instancia; si cambias vistas, redeploy o espera el reinicio.
