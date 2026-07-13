// ============================================================
// Edge Function: informe-semanal
// Genera y envia por correo el resumen semanal de ensayos.
// Se ejecuta automaticamente cada lunes via pg_cron (ver
// supabase/4_automatizacion/04_cron-informe-semanal.sql).
// Tambien se puede invocar manualmente pasando { desde, hasta }
// (YYYY-MM-DD) en el body para generar el informe de cualquier semana.
//
// En el panel: "Verify JWT" = OFF.
// SECRETS requeridos:
//   SB_URL, SB_SERVICE_ROLE   (para leer los datos via RPC)
//   MS_TENANT_ID, MS_CLIENT_ID, MS_REFRESH_TOKEN  (envio por Microsoft
//   Graph, permiso delegado Mail.Send + offline_access de jtorres@migrin.cl)
// ============================================================

// Solo jtorres@migrin.cl, a diferencia de otros envios de la app que
// van a la lista completa de calidad.
const DESTINATARIOS = ['jtorres@migrin.cl'];

async function enviarGraph(asunto: string, html: string) {
  const tenant = Deno.env.get('MS_TENANT_ID') ?? '';
  const clientId = Deno.env.get('MS_CLIENT_ID') ?? '';
  const refresh = Deno.env.get('MS_REFRESH_TOKEN') ?? '';
  const tk = await fetch(`https://login.microsoftonline.com/${tenant}/oauth2/v2.0/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: clientId, grant_type: 'refresh_token', refresh_token: refresh,
      scope: 'https://graph.microsoft.com/Mail.Send offline_access',
    }),
  });
  const tkData = await tk.json();
  if (!tk.ok) throw new Error('Token Microsoft error: ' + JSON.stringify(tkData));
  const res = await fetch('https://graph.microsoft.com/v1.0/me/sendMail', {
    method: 'POST',
    headers: { Authorization: `Bearer ${tkData.access_token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: {
        subject: asunto,
        body: { contentType: 'HTML', content: html },
        toRecipients: DESTINATARIOS.map((email) => ({ emailAddress: { address: email } })),
      },
      saveToSentItems: true,
    }),
  });
  let body: unknown = null;
  if (!res.ok) { try { body = await res.json(); } catch { body = await res.text(); } }
  return { ok: res.ok, status: res.status, body };
}

// Fecha (YYYY-MM-DD) -> dd/mm/aaaa
function fmtFecha(iso: string) {
  const [y, m, d] = iso.split('-');
  return `${d}/${m}/${y}`;
}

// Lunes-domingo de la semana ISO mas reciente ya completada, en UTC.
// Se usa por defecto cuando el body no trae { desde, hasta }.
function semanaPasada(): { desde: string; hasta: string } {
  const hoy = new Date();
  const hoyUTC = new Date(Date.UTC(hoy.getUTCFullYear(), hoy.getUTCMonth(), hoy.getUTCDate()));
  const diaSemana = hoyUTC.getUTCDay(); // domingo=0 ... sabado=6
  const diffALunesActual = diaSemana === 0 ? 6 : diaSemana - 1;
  const lunesActual = new Date(hoyUTC); lunesActual.setUTCDate(hoyUTC.getUTCDate() - diffALunesActual);
  const lunesPasado = new Date(lunesActual); lunesPasado.setUTCDate(lunesActual.getUTCDate() - 7);
  const domingoPasado = new Date(lunesPasado); domingoPasado.setUTCDate(lunesPasado.getUTCDate() + 6);
  return { desde: lunesPasado.toISOString().slice(0, 10), hasta: domingoPasado.toISOString().slice(0, 10) };
}

Deno.serve(async (req) => {
  const cors = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    const sbUrl = Deno.env.get('SB_URL') ?? '';
    const sbSvc = Deno.env.get('SB_SERVICE_ROLE') ?? '';

    let desde: string, hasta: string;
    try {
      const body = await req.json().catch(() => ({}));
      if (body.desde && body.hasta) { desde = body.desde; hasta = body.hasta; }
      else { const s = semanaPasada(); desde = s.desde; hasta = s.hasta; }
    } catch {
      const s = semanaPasada(); desde = s.desde; hasta = s.hasta;
    }

    // ── Llamar a la funcion SQL ───────────────────────────────
    const rpcRes = await fetch(`${sbUrl}/rest/v1/rpc/fn_informe_semanal`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${sbSvc}`,
        'apikey': sbSvc,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ p_desde: desde, p_hasta: hasta }),
    });

    if (!rpcRes.ok) {
      const err = await rpcRes.text();
      return new Response(JSON.stringify({ error: `RPC error: ${err}` }), {
        status: 500, headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const data = await rpcRes.json();
    const resumen = data.resumen ?? {};
    const porProducto: {
      producto_key: string; producto_label: string; n: number;
      analistas: number; turno_a: number; turno_b: number;
      primera: string; ultima: string; humedad_prom: number | null;
    }[] = data.por_producto ?? [];

    // ── Construir email HTML ──────────────────────────────────
    const periodoLabel = `${fmtFecha(desde)} al ${fmtFecha(hasta)}`;

    const cards = [
      { label: 'Ensayos totales',    valor: resumen.total_ensayos     ?? 0, color: '#1a56db' },
      { label: 'Productos activos',  valor: resumen.productos_activos  ?? 0, color: '#0e9f6e' },
      { label: 'Analistas activos',  valor: resumen.analistas_activos  ?? 0, color: '#7e3af2' },
      { label: 'Dias con actividad', valor: resumen.dias_con_actividad ?? 0, color: '#e3a008' },
    ].map(c => `
      <td style="width:25%;padding:8px">
        <div style="background:${c.color};color:#fff;border-radius:8px;padding:16px;text-align:center">
          <div style="font-size:28px;font-weight:bold;line-height:1">${c.valor}</div>
          <div style="font-size:11px;margin-top:4px;opacity:.9">${c.label}</div>
        </div>
      </td>`).join('');

    const filasProducto = porProducto.length > 0
      ? porProducto.map((p, i) => `
        <tr style="background:${i % 2 === 0 ? '#fff' : '#f9fafb'}">
          <td style="padding:8px 12px;border:1px solid #e5e7eb;font-weight:500">${p.producto_label}</td>
          <td style="padding:8px 12px;border:1px solid #e5e7eb;text-align:center;font-weight:bold">${p.n}</td>
          <td style="padding:8px 12px;border:1px solid #e5e7eb;text-align:center">${p.analistas}</td>
          <td style="padding:8px 12px;border:1px solid #e5e7eb;text-align:center;font-size:12px">
            ${p.turno_a > 0 ? `<span style="color:#1a56db">A:${p.turno_a}</span> ` : ''}
            ${p.turno_b > 0 ? `<span style="color:#0e9f6e">B:${p.turno_b}</span>` : ''}
          </td>
          <td style="padding:8px 12px;border:1px solid #e5e7eb;text-align:center;font-size:12px;color:#6b7280">
            ${p.humedad_prom != null ? p.humedad_prom + '%' : '—'}
          </td>
          <td style="padding:8px 12px;border:1px solid #e5e7eb;font-size:11px;color:#9ca3af">
            ${p.primera || '—'} → ${p.ultima || '—'}
          </td>
        </tr>`).join('')
      : `<tr><td colspan="6" style="padding:24px;text-align:center;color:#9ca3af;font-style:italic">
           Sin ensayos registrados en el periodo.
         </td></tr>`;

    const html = `
      <div style="font-family:Arial,sans-serif;max-width:760px;margin:0 auto;color:#111827">
        <div style="background:#1e3a5f;color:#fff;padding:20px 28px;border-radius:10px 10px 0 0">
          <div style="font-size:11px;text-transform:uppercase;letter-spacing:1px;opacity:.7;margin-bottom:2px">
            MIGRIN S.A. — Control de Calidad
          </div>
          <h2 style="margin:0;font-size:20px">Informe Semanal — ${periodoLabel}</h2>
          <div style="font-size:11px;opacity:.5;margin-top:4px">
            Generado automaticamente el ${new Date().toLocaleDateString('es-CL')}
          </div>
        </div>

        <div style="background:#f3f4f6;padding:16px 20px">
          <table style="width:100%;border-collapse:collapse"><tr>${cards}</tr></table>
        </div>

        <div style="padding:20px 0">
          <h3 style="margin:0 0 12px;font-size:13px;text-transform:uppercase;letter-spacing:.5px;color:#374151">
            Detalle por Producto
          </h3>
          <table style="width:100%;border-collapse:collapse;font-size:13px">
            <thead>
              <tr style="background:#1e3a5f;color:#fff;text-align:left">
                <th style="padding:8px 12px;border:1px solid #374151">Producto</th>
                <th style="padding:8px 12px;border:1px solid #374151;text-align:center">Ensayos</th>
                <th style="padding:8px 12px;border:1px solid #374151;text-align:center">Analistas</th>
                <th style="padding:8px 12px;border:1px solid #374151;text-align:center">Turnos</th>
                <th style="padding:8px 12px;border:1px solid #374151;text-align:center">Hum. prom.</th>
                <th style="padding:8px 12px;border:1px solid #374151">Fechas</th>
              </tr>
            </thead>
            <tbody>${filasProducto}</tbody>
          </table>
        </div>

        <div style="border-top:1px solid #e5e7eb;padding:16px 0;font-size:11px;color:#9ca3af;text-align:center">
          Mensaje automatico — Sistema de Control de Calidad MIGRIN S.A.<br>
          Para ver el detalle completo ingresa a la aplicacion.
        </div>
      </div>`;

    // ── Enviar via Microsoft Graph ────────────────────────────
    const r = await enviarGraph(`Informe Semanal de Calidad — ${periodoLabel} | MIGRIN S.A.`, html);
    return new Response(
      JSON.stringify({ ok: r.ok, periodo: periodoLabel, status: r.status, ...(r.ok ? {} : { error_graph: r.body }) }),
      { status: r.ok ? 200 : 502, headers: { ...cors, 'Content-Type': 'application/json' } },
    );

  } catch (e) {
    return new Response(JSON.stringify({ error: String((e as Error)?.message ?? e) }), {
      status: 500, headers: { 'Content-Type': 'application/json' },
    });
  }
});
