-- ============================================================
-- MIGRIN — Programar el informe semanal automatico
-- Ejecuta la Edge Function 'informe-semanal' todos los lunes
-- a las 08:00 hora Chile (≈12:00 UTC en horario estandar,
-- UTC-4; ≈11:00 UTC si Chile esta en horario de verano,
-- UTC-3 — ajustar la hora del cron dos veces al año si el
-- horario exacto de las 8am importa).
--
-- El informe cubre SIEMPRE la semana lunes-domingo
-- inmediatamente anterior (calculado por la Edge Function),
-- y se envia SOLO a jtorres@migrin.cl.
--
-- Requisitos:
--   1. Haber desplegado la Edge Function 'informe-semanal'.
--   2. Extensiones pg_cron y pg_net ya habilitadas (se usan
--      para el informe mensual, ver 02_cron-informe-mensual.sql).
--   3. Reemplazar la key de abajo por la publishable/anon key
--      si cambia.
-- ============================================================

SELECT cron.unschedule('informe-semanal-migrin')
  WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'informe-semanal-migrin');

SELECT cron.schedule(
  'informe-semanal-migrin',
  '0 12 * * 1',           -- min hora dia mes dia-semana → 12:00 UTC cada lunes (~08:00 Chile, horario estandar)
  $$
  SELECT net.http_post(
    url     := 'https://wxjclxmtceuhlbwxtptc.supabase.co/functions/v1/informe-semanal',
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
-- Probar manualmente la funcion (sin esperar al lunes):
--   curl -X POST 'https://wxjclxmtceuhlbwxtptc.supabase.co/functions/v1/informe-semanal' \
--     -H 'Content-Type: application/json' -d '{"desde":"2026-07-06","hasta":"2026-07-12"}'
