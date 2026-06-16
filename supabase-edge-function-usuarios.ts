// ============================================================
// Edge Function: crear-usuario
// Crea un usuario (visualizador o admin) desde la app, de forma
// segura: usa la service_role key (solo en el servidor) y verifica
// que QUIEN llama sea administrador.
//
// COMO DESPLEGAR (Dashboard de Supabase):
//   1. Edge Functions → Deploy a new function → "Via Editor"
//   2. Nombre: crear-usuario
//   3. Pegar este codigo completo y Deploy
//   4. Secrets (Project Settings → Edge Functions → Secrets):
//        SB_URL          = https://wxjclxmtceuhlbwxtptc.supabase.co
//        SB_SERVICE_ROLE = (Project Settings → API → service_role key)
//      (SUPABASE_URL ya existe por defecto; SB_* evita choques de nombres)
// ============================================================
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const URL = Deno.env.get('SB_URL') ?? Deno.env.get('SUPABASE_URL')!;
const SERVICE = Deno.env.get('SB_SERVICE_ROLE')!;

Deno.serve(async (req) => {
  const cors = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

  try {
    // 1) Verificar que el solicitante sea admin (lee su token)
    const authHeader = req.headers.get('Authorization') ?? '';
    const token = authHeader.replace('Bearer ', '');
    if (!token) return json({ error: 'No autenticado' }, 401);

    const admin = createClient(URL, SERVICE);
    const { data: userData, error: uErr } = await admin.auth.getUser(token);
    if (uErr || !userData?.user) return json({ error: 'Sesion invalida' }, 401);
    const meta = userData.user.user_metadata || {};
    if (meta.is_admin !== true) return json({ error: 'Solo un administrador puede crear usuarios' }, 403);

    // 2) Crear el nuevo usuario
    const { email, password, rol } = await req.json();
    if (!email || !password) return json({ error: 'Email y contraseña requeridos' }, 400);

    const user_metadata =
      rol === 'admin' ? { is_admin: true } : { is_viewer: true };

    const { data, error } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata,
    });
    if (error) return json({ error: error.message }, 400);
    return json({ ok: true, id: data.user?.id, email: data.user?.email });
  } catch (e) {
    return json({ error: String(e?.message ?? e) }, 500);
  }
});
