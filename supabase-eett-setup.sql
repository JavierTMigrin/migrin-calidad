-- ============================================================
-- MIGRIN Control de Calidad — Tabla de EETT editables
-- Ejecutar en el SQL Editor de Supabase
-- ============================================================

CREATE TABLE IF NOT EXISTS especificaciones (
  producto_key TEXT PRIMARY KEY,
  specs        JSONB NOT NULL,
  updated_by   TEXT,
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE especificaciones ENABLE ROW LEVEL SECURITY;

-- Todos los usuarios autenticados leen (la app necesita los limites)
CREATE POLICY "eett_select" ON especificaciones
  FOR SELECT TO authenticated USING (true);

-- Solo admin puede crear/modificar
CREATE POLICY "eett_insert" ON especificaciones
  FOR INSERT TO authenticated
  WITH CHECK ((auth.jwt()->'user_metadata'->>'is_admin')::boolean IS TRUE);

CREATE POLICY "eett_update" ON especificaciones
  FOR UPDATE TO authenticated
  USING ((auth.jwt()->'user_metadata'->>'is_admin')::boolean IS TRUE);

CREATE POLICY "eett_delete" ON especificaciones
  FOR DELETE TO authenticated
  USING ((auth.jwt()->'user_metadata'->>'is_admin')::boolean IS TRUE);
