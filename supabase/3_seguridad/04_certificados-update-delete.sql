-- Politicas RLS para editar y eliminar certificados emitidos desde la app.
-- SOLO jtorres@migrin.cl puede editar o eliminar; el resto de los usuarios
-- autenticados solo inserta (al emitir) y lee.
-- Aplicado en produccion el 2026-07-20.

DROP POLICY IF EXISTS certificados_update ON certificados;
DROP POLICY IF EXISTS certificados_delete ON certificados;

CREATE POLICY certificados_update ON certificados FOR UPDATE TO authenticated
  USING ((select auth.jwt()->>'email') = 'jtorres@migrin.cl')
  WITH CHECK ((select auth.jwt()->>'email') = 'jtorres@migrin.cl');

CREATE POLICY certificados_delete ON certificados FOR DELETE TO authenticated
  USING ((select auth.jwt()->>'email') = 'jtorres@migrin.cl');
