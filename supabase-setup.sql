-- ============================================================
-- MIGRIN Control de Calidad — Supabase Schema Setup
-- Ejecutar en el SQL Editor de Supabase
-- ============================================================

-- ── TABLA ENSAYOS ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ensayos (
  id              TEXT PRIMARY KEY,
  fecha_muestreo  DATE NOT NULL,
  fecha_envio     DATE,
  hora_envio      TEXT,
  turno           TEXT CHECK (turno IN ('A','B','')),
  analista        TEXT,
  producto_key    TEXT NOT NULL,
  producto_label  TEXT,
  tipo_muestra    TEXT,
  num_acopio      TEXT,
  peso_inicial    NUMERIC,
  peso_final      NUMERIC,
  peso_fondo      NUMERIC,
  granu           JSONB DEFAULT '[]'::jsonb,
  pct_humedad     NUMERIC,
  quimica         JSONB DEFAULT '{}'::jsonb,
  observaciones   TEXT,
  enviado_por     TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ensayos_fecha     ON ensayos(fecha_muestreo DESC);
CREATE INDEX IF NOT EXISTS idx_ensayos_producto  ON ensayos(producto_key);
CREATE INDEX IF NOT EXISTS idx_ensayos_analista  ON ensayos(analista);

-- ── TABLA ANALISTAS ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS analistas (
  id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre     TEXT NOT NULL UNIQUE,
  activo     BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insertar analistas iniciales
INSERT INTO analistas (nombre) VALUES
  ('Camila Opazo'),
  ('Ximena Gutierrez')
ON CONFLICT (nombre) DO NOTHING;

-- ── TABLA AUDIT LOG ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_log (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  accion       TEXT NOT NULL,
  ensayo_id    TEXT,
  datos_previos JSONB,
  usuario      TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── ROW LEVEL SECURITY ──────────────────────────────────────
ALTER TABLE ensayos    ENABLE ROW LEVEL SECURITY;
ALTER TABLE analistas  ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log  ENABLE ROW LEVEL SECURITY;

-- Ensayos: cualquier usuario autenticado puede leer e insertar
CREATE POLICY "ensayos_select" ON ensayos
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "ensayos_insert" ON ensayos
  FOR INSERT TO authenticated WITH CHECK (true);

-- Ensayos: solo admin puede eliminar
CREATE POLICY "ensayos_delete" ON ensayos
  FOR DELETE TO authenticated
  USING ((auth.jwt()->'user_metadata'->>'is_admin')::boolean IS TRUE);

-- Analistas: todos leen, solo admin modifica
CREATE POLICY "analistas_select" ON analistas
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "analistas_insert" ON analistas
  FOR INSERT TO authenticated
  WITH CHECK ((auth.jwt()->'user_metadata'->>'is_admin')::boolean IS TRUE);

CREATE POLICY "analistas_update" ON analistas
  FOR UPDATE TO authenticated
  USING ((auth.jwt()->'user_metadata'->>'is_admin')::boolean IS TRUE);

CREATE POLICY "analistas_delete" ON analistas
  FOR DELETE TO authenticated
  USING ((auth.jwt()->'user_metadata'->>'is_admin')::boolean IS TRUE);

-- Audit log: todos pueden insertar, solo admin lee
CREATE POLICY "audit_insert" ON audit_log
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "audit_select" ON audit_log
  FOR SELECT TO authenticated
  USING ((auth.jwt()->'user_metadata'->>'is_admin')::boolean IS TRUE);

-- ============================================================
-- PARA CREAR USUARIOS:
--   1. En Supabase Dashboard → Authentication → Users → Add User
--   2. Ingresar email + password del analista
--
-- PARA MARCAR ADMIN:
--   En el SQL Editor ejecutar:
--   SELECT auth.admin_user_by_email('javier@empresa.cl');
--   O bien, en Authentication → Users → clic en el usuario →
--   User Metadata → agregar: {"is_admin": true}
-- ============================================================
