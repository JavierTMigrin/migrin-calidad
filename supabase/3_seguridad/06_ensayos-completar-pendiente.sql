-- Permite a cualquier usuario autenticado completar un registro guardado
-- como parcial (extra.pendiente = 'granulometria' | 'quimica', ver
-- PRODUCTOS_DATO_PARCIAL en la app) sin necesitar permisos de admin.
--
-- Antes de esto, "admin update ensayos" (01_seguridad-completo.sql)
-- bloqueaba silenciosamente el UPDATE para cualquier analista sin
-- is_admin=true: Supabase no lanza excepcion cuando RLS filtra 0 filas,
-- asi que el boton "Completar ahora" (CompletarEnsayoModal) parecia
-- funcionar (sin error, toast de exito) pero el registro nunca quedaba
-- realmente completo en la base de datos.
--
-- USING acota el permiso a filas que HOY tienen extra.pendiente seteado
-- (no abre edicion general de ensayos ya completos a los no-admin, eso
-- lo sigue exigiendo "admin update ensayos"); WITH CHECK permite que el
-- resultado ya no tenga pendiente (si no, la propia actualizacion que lo
-- completa quedaria bloqueada por su propia condicion USING).
--
-- Aplicado en produccion el 2026-08-19.

DROP POLICY IF EXISTS "auth completar pendiente ensayos" ON ensayos;
CREATE POLICY "auth completar pendiente ensayos" ON ensayos
  FOR UPDATE TO authenticated
  USING ((extra ->> 'pendiente') IS NOT NULL)
  WITH CHECK (true);
