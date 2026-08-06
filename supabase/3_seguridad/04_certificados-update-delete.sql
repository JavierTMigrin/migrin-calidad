-- Politicas RLS para editar y eliminar certificados emitidos desde la app.
-- SOLO los correos en la lista pueden editar o eliminar; el resto de los
-- usuarios autenticados solo inserta (al emitir) y lee.
-- Aplicado en produccion el 2026-07-20.
-- Actualizado el 2026-08-05: se agrega scontreras@migrin.cl.

DROP POLICY IF EXISTS certificados_update ON certificados;
DROP POLICY IF EXISTS certificados_delete ON certificados;

CREATE POLICY certificados_update ON certificados FOR UPDATE TO authenticated
  USING ((select auth.jwt()->>'email') IN ('jtorres@migrin.cl','scontreras@migrin.cl'))
  WITH CHECK ((select auth.jwt()->>'email') IN ('jtorres@migrin.cl','scontreras@migrin.cl'));

CREATE POLICY certificados_delete ON certificados FOR DELETE TO authenticated
  USING ((select auth.jwt()->>'email') IN ('jtorres@migrin.cl','scontreras@migrin.cl'));
