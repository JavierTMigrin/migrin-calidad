// ============================================================
// Edge Function: quick-processor (version BREVO)
// Envia la alerta por correo via Brevo cuando un ensayo queda
// fuera de norma. Reemplaza el codigo anterior (Resend) — usa el
// MISMO payload, asi la app no necesita cambios.
//
// DESPLEGAR (Dashboard de Supabase):
//   1. Edge Functions → quick-processor → Editor → pegar este codigo → Deploy
//      (o Deploy new function con nombre exacto: quick-processor)
//   2. Secrets (Project Settings → Edge Functions → Secrets):
//        BREVO_API_KEY = xkeysib-xxxxxxxx   (la API key de Brevo)
//
// El remitente debe ser un sender VERIFICADO en Brevo (sin DNS):
// Brevo → Senders → Add sender → jtorres@migrin.cl → clic en el correo.
// ============================================================

const REMITENTE = { name: 'Alertas Calidad MIGRIN', email: 'jtorres@migrin.cl' };
const DESTINATARIOS = [
  'jtorres@migrin.cl',
  'sarce@migrin.cl',
];

Deno.serve(async (req) => {
  const cors = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    const {
      producto, fecha, turno, analista, tipoMuestra, enviadoPor,
      violaciones, recomendacion, noAptoDespacho,
    } = await req.json();

    const titulo = recomendacion || 'Se recomienda cambio a cono de emergencia.';
    const filas = (violaciones || []).map(
      (v: { param: string; valor: string; limite: string; spec: string }) =>
        `<tr>
          <td style="padding:6px 12px;border:1px solid #ddd">${v.param}</td>
          <td style="padding:6px 12px;border:1px solid #ddd;color:#c53030;font-weight:bold">${v.valor}</td>
          <td style="padding:6px 12px;border:1px solid #ddd">${v.limite}</td>
          <td style="padding:6px 12px;border:1px solid #ddd">${v.spec || '—'}</td>
        </tr>`,
    ).join('');

    const html = `
      <div style="font-family:Arial,sans-serif;max-width:640px;margin:0 auto">
        <div style="background:#c53030;color:#fff;padding:16px 24px;border-radius:8px 8px 0 0">
          <h2 style="margin:0">🚨 ALERTA — Parametros fuera de norma</h2>
        </div>
        <div style="border:1px solid #ddd;border-top:none;padding:24px;border-radius:0 0 8px 8px">
          <p style="font-size:15px"><b>${titulo}</b></p>
          ${noAptoDespacho ? '<p style="font-size:14px;color:#c53030"><b>⛔ Humedad fuera de limite — producto NO APTO para despacho.</b></p>' : ''}
          <table style="font-size:14px;margin-bottom:16px">
            <tr><td style="padding:2px 12px 2px 0;color:#777">Producto:</td><td><b>${producto}</b></td></tr>
            <tr><td style="padding:2px 12px 2px 0;color:#777">Fecha muestreo:</td><td>${fecha}</td></tr>
            <tr><td style="padding:2px 12px 2px 0;color:#777">Turno:</td><td>${turno || '—'}</td></tr>
            <tr><td style="padding:2px 12px 2px 0;color:#777">Tipo muestra:</td><td>${tipoMuestra || '—'}</td></tr>
            <tr><td style="padding:2px 12px 2px 0;color:#777">Analista:</td><td>${analista}</td></tr>
            <tr><td style="padding:2px 12px 2px 0;color:#777">Enviado por:</td><td>${enviadoPor}</td></tr>
          </table>
          <table style="width:100%;border-collapse:collapse;font-size:13px">
            <thead><tr style="background:#f5f5f5;text-align:left">
              <th style="padding:6px 12px;border:1px solid #ddd">Parametro</th>
              <th style="padding:6px 12px;border:1px solid #ddd">Valor</th>
              <th style="padding:6px 12px;border:1px solid #ddd">Limite</th>
              <th style="padding:6px 12px;border:1px solid #ddd">Especificacion</th>
            </tr></thead>
            <tbody>${filas}</tbody>
          </table>
          <p style="font-size:12px;color:#999;margin-top:20px">
            Mensaje automatico del Sistema de Control de Calidad MIGRIN S.A.
          </p>
        </div>
      </div>`;

    const asunto = `🚨 ${tipoMuestra === 'Acopio' ? 'ACOPIO FUERA DE NORMA'
      : tipoMuestra === 'Despacho' ? 'NO DESPACHAR' : 'FUERA DE NORMA'} — ${producto} (${fecha})`;

    const res = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-key': Deno.env.get('BREVO_API_KEY') ?? '',
      },
      body: JSON.stringify({
        sender: REMITENTE,
        to: DESTINATARIOS.map((email) => ({ email })),
        subject: asunto,
        htmlContent: html,
      }),
    });

    const out = await res.json();
    return new Response(JSON.stringify(out), {
      status: res.ok ? 200 : 500,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e?.message ?? e) }), {
      status: 500, headers: { ...cors, 'Content-Type': 'application/json' },
    });
  }
});
