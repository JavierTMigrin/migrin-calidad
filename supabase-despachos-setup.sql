-- ============================================================
-- MIGRIN Control de Calidad — Despachos Arena Premium
-- Agrega columnas de despacho a la tabla ensayos.
-- Ejecutar en el SQL Editor de Supabase.
-- ============================================================

ALTER TABLE ensayos ADD COLUMN IF NOT EXISTS guia        TEXT;
ALTER TABLE ensayos ADD COLUMN IF NOT EXISTS lote        TEXT;
ALTER TABLE ensayos ADD COLUMN IF NOT EXISTS hora_salida TEXT;
