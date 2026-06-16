-- ============================================================
-- MIGRIN Control de Calidad — Permisos de administrador (RLS)
-- Ejecutar en el SQL Editor de Supabase.
--
-- Habilita que un usuario con user_metadata.is_admin = true pueda
-- EDITAR y ELIMINAR ensayos desde la app (modo admin del Historial),
-- y registra los cambios en audit_log.
--
-- El admin se identifica leyendo el JWT de la sesion:
--   auth.jwt() -> 'user_metadata' ->> 'is_admin' = 'true'
-- ============================================================

-- Asegura que RLS este activo
ALTER TABLE ensayos ENABLE ROW LEVEL SECURITY;

-- ── ENSAYOS: solo admin puede ACTUALIZAR ──
DROP POLICY IF EXISTS "admin update ensayos" ON ensayos;
CREATE POLICY "admin update ensayos" ON ensayos
  FOR UPDATE TO authenticated
  USING  ( (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true )
  WITH CHECK ( (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true );

-- ── ENSAYOS: solo admin puede ELIMINAR ──
DROP POLICY IF EXISTS "admin delete ensayos" ON ensayos;
CREATE POLICY "admin delete ensayos" ON ensayos
  FOR DELETE TO authenticated
  USING ( (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true );

-- ── AUDIT_LOG: cualquier autenticado puede insertar (registrar accion) ──
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "auth insert audit" ON audit_log;
CREATE POLICY "auth insert audit" ON audit_log
  FOR INSERT TO authenticated
  WITH CHECK ( true );

-- ── AUDIT_LOG: solo admin puede leer el historial de cambios ──
DROP POLICY IF EXISTS "admin select audit" ON audit_log;
CREATE POLICY "admin select audit" ON audit_log
  FOR SELECT TO authenticated
  USING ( (auth.jwt() -> 'user_metadata' ->> 'is_admin')::boolean = true );
