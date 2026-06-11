// ============================================================
// Edge Function: alerta-calidad
// Envia correo via Resend cuando un ensayo queda fuera de norma.
//
// COMO DESPLEGAR (desde el Dashboard de Supabase):
//   1. Edge Functions → Deploy a new function → "Via Editor"
//   2. Nombre: alerta-calidad
//   3. Pegar este codigo completo y Deploy
//   4. Edge Functions → alerta-calidad → Secrets (o Project Settings
//      → Edge Functions → Secrets) → agregar:
//        RESEND_API_KEY = re_xxxxxxxx  (la API key de Resend)
// ============================================================

const DESTINATARIOS = ['jtorres@migrin.cl']; // modo prueba: solo Javier (cuenta Resend)

Deno.serve(async (req) => {
  const cors = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type',
  };
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    const { producto, fecha, turno, analista, enviadoPor, violaciones } =
      await req.json();

    const filas = (violaciones || [])
      .map(
        (v: { param: string; valor: string; limite: string; spec: string }) =>
          `<tr>
            <td style="padding:6px 12px;border:1px solid #ddd">${v.param}</td>
            <td style="padding:6px 12px;border:1px solid #ddd;color:#c53030;font-weight:bold">${v.valor}</td>
            <td style="padding:6px 12px;border:1px solid #ddd">${v.limite}</td>
            <td style="padding:6px 12px;border:1px solid #ddd">${v.spec || '—'}</td>
          </tr>`,
      )
      .join('');

    const html = `
      <div style="font-family:Arial,sans-serif;max-width:640px;margin:0 auto">
        <div style="background:#c53030;color:#fff;padding:16px 24px;border-radius:8px 8px 0 0">
          <h2 style="margin:0">🚨 ALERTA — Parametros fuera de norma</h2>
        </div>
        <div style="border:1px solid #ddd;border-top:none;padding:24px;border-radius:0 0 8px 8px">
          <p style="font-size:15px"><b>Se recomienda cambio a cono de emergencia.</b></p>
          <table style="font-size:14px;margin-bottom:16px">
            <tr><td style="padding:2px 12px 2px 0;color:#777">Producto:</td><td><b>${producto}</b></td></tr>
            <tr><td style="padding:2px 12px 2px 0;color:#777">Fecha muestreo:</td><td>${fecha}</td></tr>
            <tr><td style="padding:2px 12px 2px 0;color:#777">Turno:</td><td>${turno || '—'}</td></tr>
            <tr><td style="padding:2px 12px 2px 0;color:#777">Analista:</td><td>${analista}</td></tr>
            <tr><td style="padding:2px 12px 2px 0;color:#777">Enviado por:</td><td>${enviadoPor}</td></tr>
          </table>
          <table style="width:100%;border-collapse:collapse;font-size:13px">
            <thead>
              <tr style="background:#f5f5f5;text-align:left">
                <th style="padding:6px 12px;border:1px solid #ddd">Parametro</th>
                <th style="padding:6px 12px;border:1px solid #ddd">Valor</th>
                <th style="padding:6px 12px;border:1px solid #ddd">Limite</th>
                <th style="padding:6px 12px;border:1px solid #ddd">Especificacion</th>
              </tr>
            </thead>
            <tbody>${filas}</tbody>
          </table>
          <p style="font-size:12px;color:#999;margin-top:20px">
            Mensaje automatico del Sistema de Control de Calidad MIGRIN S.A.
          </p>
        </div>
      </div>`;

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${Deno.env.get('RESEND_API_KEY')}`,
      },
      body: JSON.stringify({
        from: 'Alertas Calidad MIGRIN <onboarding@resend.dev>',
        to: DESTINATARIOS,
        subject: `🚨 FUERA DE NORMA — ${producto} (${fecha})`,
        html,
      }),
    });

    const out = await res.json();
    return new Response(JSON.stringify(out), {
      status: res.ok ? 200 : 500,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  }
});
