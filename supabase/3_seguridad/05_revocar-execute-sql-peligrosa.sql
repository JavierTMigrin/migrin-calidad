-- ============================================================
-- MIGRIN Control de Calidad — Cierre de brecha: execute_sql(text)
-- Ejecutar en el SQL Editor de Supabase (proyecto wxjclxmtceuhlbwxtptc).
--
-- Hallazgo (2026-07-30): existe una funcion `execute_sql(query text)`
-- SECURITY DEFINER con GRANT EXECUTE a anon, authenticated y service_role.
-- Verificado con has_function_privilege. Al ser SECURITY DEFINER, cualquier
-- visitante de la app (usando solo la clave anon publica embebida en el
-- cliente) podria invocarla via supabase.rpc('execute_sql', {query:...})
-- y ejecutar SQL arbitrario, con bypass total de RLS.
--
-- Investigacion de codigo (calidad.src.html, calidad.html, edge-functions/,
-- supabase/*): NO existe ninguna llamada a supabase.rpc('execute_sql', ...)
-- ni a "execute_sql" en ningun archivo del proyecto. El asistente de IA
-- (edge-functions/consulta-ia) NO usa esta funcion: se conecta directo a
-- Postgres con un rol dedicado de solo lectura (ia_readonly, ver
-- 6_consulta_ia/01_rol-solo-lectura.sql) y valida SELECT-only en ejecutar.ts.
-- Conclusion: `execute_sql` es un leftover no usado por la app (probablemente
-- creada en el SQL Editor o via una sesion de Claude/MCP para una tarea
-- puntual y nunca limpiada), no una pieza necesaria de la arquitectura.
--
-- Accion recomendada: eliminar la funcion por completo. Si por algun motivo
-- se necesita mantenerla para uso administrativo manual, al menos ejecutar
-- primero el REVOKE para quitarle el alcance publico.
--
-- APLICADO EN PRODUCCION el 2026-07-30 via mcp__supabase__execute_sql.
-- OJO: el primer intento (solo "FROM anon, authenticated") NO alcanzo,
-- porque Postgres otorga EXECUTE a PUBLIC por defecto al crear una funcion,
-- y todo rol (incluido anon/authenticated) hereda de PUBLIC implicitamente.
-- Hubo que revocar tambien de PUBLIC explicitamente. Verificado con
-- has_function_privilege que public/anon/authenticated ya NO pueden
-- ejecutarla y que service_role si mantiene el acceso.
-- ============================================================

-- 1) Quitar el acceso publico de inmediato (deja solo service_role)
--    IMPORTANTE: revocar de PUBLIC ademas de anon/authenticated, o el
--    REVOKE no tiene efecto real (ver nota arriba).
REVOKE EXECUTE ON FUNCTION public.execute_sql(text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.execute_sql(text) FROM anon, authenticated;

-- 2) Recomendado: eliminarla del todo si nadie la necesita
-- DROP FUNCTION IF EXISTS public.execute_sql(text);

-- 3) Verificacion posterior (deberia devolver false para public/anon/authenticated)
SELECT
  has_function_privilege('public', 'public.execute_sql(text)', 'EXECUTE') AS public_puede,
  has_function_privilege('anon', 'public.execute_sql(text)', 'EXECUTE') AS anon_puede,
  has_function_privilege('authenticated', 'public.execute_sql(text)', 'EXECUTE') AS authenticated_puede,
  has_function_privilege('service_role', 'public.execute_sql(text)', 'EXECUTE') AS service_role_puede;

-- 4) Buscar otras funciones SECURITY DEFINER con grant a anon/authenticated
--    (revisar manualmente cada resultado; RPCs legitimas de la app deberian
--    aparecer aqui tambien, el objetivo es detectar sorpresas como esta).
SELECT
  n.nspname AS esquema,
  p.proname AS funcion,
  pg_get_function_identity_arguments(p.oid) AS argumentos,
  p.prosecdef AS security_definer,
  has_function_privilege('anon', p.oid, 'EXECUTE') AS anon_puede,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') AS authenticated_puede
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.prosecdef = true
  AND (
    has_function_privilege('anon', p.oid, 'EXECUTE')
    OR has_function_privilege('authenticated', p.oid, 'EXECUTE')
  )
ORDER BY funcion;
