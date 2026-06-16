-- ============================================================
-- MIGRIN — Programar el informe mensual automatico
-- Ejecuta la Edge Function 'informe-mensual' el dia 1 de cada mes
-- a las 08:00 UTC (≈ 04:00/05:00 Chile segun horario).
--
-- Requisitos:
--   1. Haber desplegado la Edge Function 'informe-mensual'.
--   2. Extensiones pg_cron y pg_net habilitadas:
--      Dashboard → Database → Extensions → activar "pg_cron" y "pg_net".
--   3. Reemplazar TU_ANON_KEY abajo por la publishable/anon key.
-- ============================================================

-- (si ya existe un job con el mismo nombre, lo quita primero)
SELECT cron.unschedule('informe-mensual-migrin')
  WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'informe-mensual-migrin');

SELECT cron.schedule(
  'informe-mensual-migrin',
  '0 8 1 * *',            -- min hora dia mes dia-semana  → 08:00 UTC del dia 1
  $$
  SELECT net.http_post(
    url     := 'https://wxjclxmtceuhlbwxtptc.supabase.co/functions/v1/informe-mensual',
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'Authorization','Bearer sb_publishable_am0r8DfiGyNuU2lbn4o6aw_xgjklyKB'
    ),
    body    := '{}'::jsonb
  );
  $$
);

-- Ver los jobs programados:
--   SELECT * FROM cron.job;
-- Probar manualmente la funcion (sin esperar al dia 1): ejecutar el
-- bloque net.http_post de arriba suelto, o invocarla desde la app.
