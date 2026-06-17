// ============================================================
// Edge Function: quick-processor (BREVO)
// Envia el correo de alerta cuando un ensayo queda fuera de norma.
//
// IMPORTANTE: en el panel de Supabase esta funcion debe tener
//   "Verify JWT" = OFF  (igual que informe-mensual).
//
// MODO DIAGNOSTICO: abre la URL de la funcion en el navegador
//   (peticion GET) y la pagina te dira si el secret BREVO_API_KEY
//   esta presente y que responde Brevo al enviar un correo de prueba.
//
// SECRET requerido (Project Settings -> Edge Functions -> Secrets):
//   BREVO_API_KEY = xkeysib-xxxxxxxx
// ============================================================

const REMITENTE     = { name: 'Alertas Calidad MIGRIN', email: 'jtorres@migrin.cl' };
const DESTINATARIOS = ['jtorres@migrin.cl', 'sarce@migrin.cl'];
const ALLOWED_ORIGIN = 'https://javiertmigrin.github.io';

function corsHeaders(origin: string | null) {
  return {
    'Access-Control-Allow-Origin': origin === ALLOWED_ORIGIN ? ALLOWED_ORIGIN : '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
}

// Envia un correo via Brevo. Devuelve el detalle para poder diagnosticar.
async function enviarBrevo(asunto: string, html: string, texto: string) {
  const key = Deno.env.get('BREVO_API_KEY') ?? '';
  const res = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'api-key': key },
    body: JSON.stringify({
      sender: REMITENTE,
      to: DESTINATARIOS.map((email) => ({ email })),
      subject: asunto,
      htmlContent: html,
      textContent: texto,
    }),
  });
  let body: unknown;
  try { body = await res.json(); } catch { body = await res.text(); }
  return { ok: res.ok, status: res.status, body };
}

Deno.serve(async (req) => {
  const origin = req.headers.get('origin');
  const ch = corsHeaders(origin);
  const jsonHdr = { ...ch, 'Content-Type': 'application/json; charset=utf-8' };

  if (req.method === 'OPTIONS') return new Response('ok', { headers: ch });

  const keyPresente = (Deno.env.get('BREVO_API_KEY') ?? '') !== '';

  // ── MODO ESTADO (abrir la URL en el navegador = GET; NO envia correos) ──
  if (req.method === 'GET') {
    return new Response(JSON.stringify({
      funcion: 'quick-processor (alertas de calidad MIGRIN)',
      estado: 'activa',
      secret_BREVO_API_KEY: keyPresente ? 'PRESENTE (ok)' : 'FALTA — agrega el secret BREVO_API_KEY',
      remitente: REMITENTE,
      destinatarios: DESTINATARIOS,
      nota: 'Esta vista solo informa el estado. El envio de alertas ocurre cuando la app hace POST con un ensayo fuera de norma.',
    }, null, 2), { status: 200, headers: jsonHdr });
  }

  // ── ENVIO NORMAL (POST desde la app) ──
  try {
    const {
      producto, fecha, turno, analista, tipoMuestra, enviadoPor,
      violaciones, recomendacion, noAptoDespacho,
    } = await req.json();

    const viols: any[] = Array.isArray(violaciones) ? violaciones : [];

    const parseNum = (s: string) => {
      const m = String(s).replace(',', '.').match(/-?\d+(\.\d+)?/);
      return m ? parseFloat(m[0]) : NaN;
    };

    const filasData = viols.map((v) => {
      const val = parseNum(v.valor);
      const lim = parseNum(v.limite);
      const esMin = String(v.limite).includes('>=');
      const rel = (!isNaN(val) && !isNaN(lim) && lim !== 0)
        ? Math.abs(val - lim) / Math.abs(lim) * 100
        : (val !== lim ? 100 : 0);
      const enLimite = rel < 0.5;
      const crit = rel >= 20;
      let dev: string;
      if (enLimite) dev = 'en el limite';
      else dev = (esMin ? '-' : '+') + (rel >= 100 ? String(Math.round(rel)) : rel.toFixed(rel < 10 ? 1 : 0)) + '%';
      return { ...v, rel, crit, enLimite, dev };
    }).sort((a, b) => b.rel - a.rel);

    const hasCrit = filasData.some((f) => f.crit);
    const nivel = (noAptoDespacho || hasCrit || tipoMuestra === 'Despacho') ? 'CRITICO' : 'ALTO';
    const count = filasData.length;
    const accion = recomendacion || 'Se recomienda cambio a cono de emergencia.';
    const badgeBg = nivel === 'CRITICO' ? '#7f1212' : '#92400e';

    const fechaFmt = /^\d{4}-\d{2}-\d{2}$/.test(String(fecha))
      ? String(fecha).split('-').reverse().join('-') : (fecha || '-');

    const filas = filasData.map((v) => {
      const col = (v.crit && !v.enLimite) ? '#dc2626' : '#d97706';
      const track = (v.crit && !v.enLimite) ? '#fde2e2' : '#fdeccd';
      const w = Math.max(2, Math.min(100, Math.round(v.rel)));
      return `<tr style="border-top:1px solid #f2f2f2">
        <td style="padding:9px 8px 9px 0;color:#333;font-size:12.5px">${v.param}${v.spec ? ` <span style="color:#aaa;font-size:11px">(${v.spec})</span>` : ''}</td>
        <td style="padding:9px 8px;color:${col};font-weight:bold;font-size:12.5px;white-space:nowrap">${v.valor}</td>
        <td style="padding:9px 8px;color:#777;font-size:12.5px;white-space:nowrap">${v.limite}</td>
        <td style="padding:9px 0 9px 8px;width:34%">
          <table style="width:100%;border-collapse:collapse"><tr>
            <td style="padding:0 8px 0 0;width:100%">
              <div style="height:8px;background:${track};border-radius:4px">
                <div style="width:${w}%;height:8px;background:${col};border-radius:4px;font-size:1px;line-height:8px">&nbsp;</div>
              </div>
            </td>
            <td style="white-space:nowrap;font-size:11px;font-weight:bold;color:${col};text-align:right">${v.dev}</td>
          </tr></table>
        </td>
      </tr>`;
    }).join('');

    const html = `
      <div style="font-family:Arial,Helvetica,sans-serif;max-width:600px;margin:0 auto;background:#ffffff;border:1px solid #e2e2e2;border-radius:10px;overflow:hidden">
        <table width="100%" style="background:#b91c1c;border-collapse:collapse"><tr>
          <td style="padding:16px 22px">
            <table style="border-collapse:collapse"><tr>
              <td style="padding-right:12px">
                <div style="width:38px;height:38px;border-radius:8px;background:#ffffff;text-align:center;line-height:38px;font-weight:bold;color:#b91c1c;font-size:16px">M</div>
              </td>
              <td>
                <div style="color:#ffffff;font-size:16px;font-weight:bold">Alerta de Calidad</div>
                <div style="color:#fecaca;font-size:12px">Parametros fuera de norma</div>
              </td>
            </tr></table>
          </td>
          <td style="padding:16px 22px;text-align:right;vertical-align:middle">
            <span style="background:${badgeBg};color:#ffffff;font-size:12px;font-weight:bold;padding:5px 12px;border-radius:20px">${nivel}</span>
          </td>
        </tr></table>

        <table width="100%" style="background:#fef2f2;border-bottom:1px solid #fee2e2;border-collapse:collapse"><tr>
          <td style="padding:12px 0 12px 22px;width:54px;vertical-align:middle">
            <div style="font-size:26px;font-weight:bold;color:#b91c1c;line-height:1">${count}</div>
            <div style="font-size:10px;color:#7f1212;text-transform:uppercase">fuera</div>
          </td>
          <td style="padding:12px 22px;font-size:13px;color:#7f1212;vertical-align:middle">
            <b>Accion sugerida:</b> ${accion}
            ${noAptoDespacho ? '<br><b style="color:#b91c1c">Humedad fuera de limite - producto NO APTO para despacho.</b>' : ''}
          </td>
        </tr></table>

        <div style="padding:16px 22px;border-bottom:1px solid #f0f0f0">
          <table style="width:100%;font-size:13px;border-collapse:collapse">
            <tr>
              <td style="padding:3px 0;color:#888;width:32%">Producto</td><td style="padding:3px 0;font-weight:bold;color:#222">${producto}</td>
              <td style="padding:3px 0;color:#888;width:18%">Turno</td><td style="padding:3px 0;color:#222">${turno || '-'}</td>
            </tr>
            <tr>
              <td style="padding:3px 0;color:#888">Fecha muestreo</td><td style="padding:3px 0;color:#222">${fechaFmt}</td>
              <td style="padding:3px 0;color:#888">Tipo</td><td style="padding:3px 0;color:#222">${tipoMuestra || '-'}</td>
            </tr>
            <tr>
              <td style="padding:3px 0;color:#888">Analista</td><td style="padding:3px 0;color:#222">${analista || '-'}</td>
              <td style="padding:3px 0;color:#888">Enviado por</td><td style="padding:3px 0;color:#222;font-size:11px">${enviadoPor || '-'}</td>
            </tr>
          </table>
        </div>

        <div style="padding:10px 22px 4px">
          <div style="font-size:11px;color:#999;text-transform:uppercase;letter-spacing:.05em;padding:6px 0">Parametros fuera de norma</div>
          <table style="width:100%;border-collapse:collapse">
            <thead><tr style="color:#999;text-align:left;font-size:11px">
              <th style="padding:6px 8px 6px 0;font-weight:normal">Parametro</th>
              <th style="padding:6px 8px;font-weight:normal">Valor</th>
              <th style="padding:6px 8px;font-weight:normal">Limite</th>
              <th style="padding:6px 0 6px 8px;font-weight:normal">Desviacion</th>
            </tr></thead>
            <tbody>${filas}</tbody>
          </table>
        </div>

        <div style="padding:16px 22px 20px;border-top:1px solid #f0f0f0;margin-top:6px">
          <a href="https://javiertmigrin.github.io/migrin-calidad/calidad.html" style="display:inline-block;background:#b91c1c;color:#ffffff;text-decoration:none;font-size:13px;font-weight:bold;padding:9px 18px;border-radius:6px">Ver registro en la app</a>
          <div style="font-size:11px;color:#aaa;margin-top:14px">Mensaje automatico - Sistema de Control de Calidad - MIGRIN S.A.</div>
        </div>
      </div>`;

    const texto = `ALERTA (${nivel}) - ${count} parametro(s) fuera de norma\n`
      + `Producto: ${producto} - Fecha: ${fechaFmt} - Turno: ${turno || '-'} - Analista: ${analista || '-'}\n`
      + `Accion sugerida: ${accion}\n\n`
      + filasData.map((v) => `- ${v.param}: ${v.valor} (limite ${v.limite}) -> ${v.dev}`).join('\n')
      + `\n\nSistema de Control de Calidad - MIGRIN S.A.`;

    const asunto = `${
      tipoMuestra === 'Acopio' ? 'ACOPIO FUERA DE NORMA'
      : tipoMuestra === 'Despacho' ? 'NO DESPACHAR'
      : 'FUERA DE NORMA'} - ${producto} (${fechaFmt})`;

    if (!keyPresente) {
      return new Response(JSON.stringify({ error: 'Falta el secret BREVO_API_KEY en la funcion.' }), {
        status: 500, headers: jsonHdr,
      });
    }

    const r = await enviarBrevo(asunto, html, texto);
    return new Response(JSON.stringify(r.ok ? r.body : { error_brevo: r.body, brevo_status: r.status }), {
      status: r.ok ? 200 : 502,
      headers: jsonHdr,
    });

  } catch (e) {
    return new Response(JSON.stringify({ error: String((e as Error)?.message ?? e) }), {
      status: 500, headers: jsonHdr,
    });
  }
});
