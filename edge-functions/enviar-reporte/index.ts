// ============================================================
// Edge Function: enviar-reporte
// Envia por correo (Microsoft Graph, desde jtorres@migrin.cl) un
// reporte de calidad con un PDF adjunto generado por la app.
//
// En el panel: "Verify JWT" = OFF.
// SECRETS: MS_TENANT_ID, MS_CLIENT_ID, MS_REFRESH_TOKEN
//          (permiso delegado Mail.Send + offline_access)
//
// Body (POST) que envia la app:
//   {
//     asunto: string,
//     cuerpo_html: string,          // resumen HTML del correo
//     pdf_base64: string,           // PDF en base64 (sin el prefijo data:)
//     filename: string,             // ej. "Reporte_A36_Jun2026.pdf"
//     destinatarios?: string[]      // opcional; por defecto jtorres
//   }
// ============================================================

const DESTINATARIOS_DEFECTO = [
  'jtorres@migrin.cl', 'sarce@migrin.cl', 'scontreras@migrin.cl', 'jhernandez@migrin.cl',
  'rbernadot@migrin.cl', 'calidadlaspiedras@migrin.cl', 'jefeturnomlp@migrin.cl', 'efernandez@migrin.cl',
];
const ALLOWED_ORIGIN = 'https://javiertmigrin.github.io';

function cors(origin: string | null) {
  return {
    'Access-Control-Allow-Origin': origin === ALLOWED_ORIGIN ? ALLOWED_ORIGIN : '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
}

async function tokenGraph() {
  const tenant = Deno.env.get('MS_TENANT_ID') ?? '';
  const clientId = Deno.env.get('MS_CLIENT_ID') ?? '';
  const refresh = Deno.env.get('MS_REFRESH_TOKEN') ?? '';
  const res = await fetch(`https://login.microsoftonline.com/${tenant}/oauth2/v2.0/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: clientId, grant_type: 'refresh_token', refresh_token: refresh,
      scope: 'https://graph.microsoft.com/Mail.Send offline_access',
    }),
  });
  const data = await res.json();
  if (!res.ok) throw new Error('Token Microsoft error: ' + JSON.stringify(data));
  return data.access_token as string;
}

Deno.serve(async (req) => {
  const origin = req.headers.get('origin');
  const ch = { ...cors(origin), 'Content-Type': 'application/json; charset=utf-8' };
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors(origin) });

  const secretsPresentes = !!(Deno.env.get('MS_TENANT_ID') && Deno.env.get('MS_CLIENT_ID') && Deno.env.get('MS_REFRESH_TOKEN'));

  if (req.method === 'GET') {
    return new Response(JSON.stringify({
      funcion: 'enviar-reporte (Microsoft Graph)',
      estado: 'activa',
      MS_TENANT_ID: Deno.env.get('MS_TENANT_ID') ? 'presente' : 'FALTA',
      MS_CLIENT_ID: Deno.env.get('MS_CLIENT_ID') ? 'presente' : 'FALTA',
      MS_REFRESH_TOKEN: Deno.env.get('MS_REFRESH_TOKEN') ? 'presente' : 'FALTA',
    }, null, 2), { status: 200, headers: ch });
  }

  try {
    if (!secretsPresentes) {
      return new Response(JSON.stringify({ error: 'Faltan secrets de Microsoft Graph.' }), { status: 500, headers: ch });
    }
    const { asunto, cuerpo_html, pdf_base64, filename, destinatarios } = await req.json();

    const to = (Array.isArray(destinatarios) && destinatarios.length) ? destinatarios : DESTINATARIOS_DEFECTO;
    const access = await tokenGraph();

    // El PDF es opcional: si no viene, se envia solo el cuerpo HTML.
    const message: Record<string, unknown> = {
      subject: asunto || 'Reporte de Calidad — MIGRIN S.A.',
      body: { contentType: 'HTML', content: cuerpo_html || 'Reporte de calidad adjunto.' },
      toRecipients: to.map((email: string) => ({ emailAddress: { address: email } })),
    };
    if (pdf_base64) {
      message.attachments = [{
        '@odata.type': '#microsoft.graph.fileAttachment',
        name: filename || 'Reporte.pdf',
        contentType: 'application/pdf',
        contentBytes: pdf_base64,
      }];
    }

    const res = await fetch('https://graph.microsoft.com/v1.0/me/sendMail', {
      method: 'POST',
      headers: { Authorization: `Bearer ${access}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ message, saveToSentItems: true }),
    });

    if (!res.ok) {
      let body: unknown; try { body = await res.json(); } catch { body = await res.text(); }
      return new Response(JSON.stringify({ error_graph: body, graph_status: res.status }), { status: 502, headers: ch });
    }
    return new Response(JSON.stringify({ ok: true, enviado_a: to }), { status: 200, headers: ch });

  } catch (e) {
    return new Response(JSON.stringify({ error: String((e as Error)?.message ?? e) }), { status: 500, headers: ch });
  }
});
