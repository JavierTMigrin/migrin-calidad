// ============================================================
// Edge Function: informe-mensual
// Genera y envia por correo un resumen de los ensayos del MES
// ANTERIOR (conteo por producto y planta). Pensada para ejecutarse
// automaticamente el dia 1 de cada mes via cron (ver
// supabase-cron-informe-mensual.sql).
//
// DESPLEGAR (Dashboard de Supabase):
//   1. Edge Functions → Deploy new → Via Editor → nombre: informe-mensual
//   2. Pegar este codigo y Deploy
//   3. Secrets:
//        SB_URL          = https://wxjclxmtceuhlbwxtptc.supabase.co
//        SB_SERVICE_ROLE = service_role key (Project Settings → API)
//        RESEND_API_KEY  = re_xxxx
//
// NOTA: hoy envia solo a jtorres@migrin.cl (Resend exige verificar
// dominio para enviar a otros). Edita DESTINATARIOS cuando el dominio
// migrin.cl este verificado.
// ============================================================
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const URL = Deno.env.get('SB_URL') ?? Deno.env.get('SUPABASE_URL')!;
const SERVICE = Deno.env.get('SB_SERVICE_ROLE')!;
const DESTINATARIOS = ['jtorres@migrin.cl'];

const MESES = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];

Deno.serve(async (req) => {
  const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, content-type' };
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  try {
    // Rango del mes anterior
    const now = new Date();
    const first = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1));
    const last = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 0));
    const desde = first.toISOString().slice(0, 10);
    const hasta = last.toISOString().slice(0, 10);
    const titulo = `${MESES[first.getUTCMonth()]} ${first.getUTCFullYear()}`;

    const db = createClient(URL, SERVICE);
    const { data, error } = await db
      .from('ensayos')
      .select('producto_key, producto_label, fecha_muestreo')
      .gte('fecha_muestreo', desde)
      .lte('fecha_muestreo', hasta);
    if (error) throw error;

    const conteo: Record<string, { label: string; n: number }> = {};
    (data || []).forEach((r: any) => {
      const k = r.producto_key || '—';
      if (!conteo[k]) conteo[k] = { label: r.producto_label || k, n: 0 };
      conteo[k].n++;
    });
    const filas = Object.values(conteo).sort((a, b) => b.n - a.n)
      .map((c) => `<tr><td style="padding:6px 12px;border:1px solid #ddd">${c.label}</td>
        <td style="padding:6px 12px;border:1px solid #ddd;text-align:center"><b>${c.n}</b></td></tr>`).join('');
    const total = (data || []).length;

    const html = `
      <div style="font-family:Arial,sans-serif;max-width:640px;margin:0 auto">
        <div style="background:#1a5276;color:#fff;padding:16px 24px;border-radius:8px 8px 0 0">
          <h2 style="margin:0">Informe mensual — Control de Calidad MIGRIN</h2>
          <div style="opacity:.85">${titulo}</div>
        </div>
        <div style="border:1px solid #ddd;border-top:none;padding:24px;border-radius:0 0 8px 8px">
          <p style="font-size:15px">Se registraron <b>${total}</b> ensayos en ${titulo}.</p>
          <table style="width:100%;border-collapse:collapse;font-size:14px">
            <thead><tr style="background:#f0f4f8"><th style="padding:6px 12px;border:1px solid #ddd;text-align:left">Producto</th><th style="padding:6px 12px;border:1px solid #ddd">Ensayos</th></tr></thead>
            <tbody>${filas || '<tr><td colspan=2 style="padding:12px;text-align:center;color:#999">Sin ensayos</td></tr>'}</tbody>
          </table>
          <p style="font-size:12px;color:#999;margin-top:18px">Para el detalle de cumplimiento por producto y las cartas de control, ingresa a la app → Reportes → General.</p>
        </div>
      </div>`;

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${Deno.env.get('RESEND_API_KEY')}` },
      body: JSON.stringify({
        from: 'Calidad MIGRIN <onboarding@resend.dev>',
        to: DESTINATARIOS,
        subject: `Informe mensual de calidad — ${titulo} (${total} ensayos)`,
        html,
      }),
    });
    const out = await res.json();
    return new Response(JSON.stringify(out), { status: res.ok ? 200 : 500, headers: { ...cors, 'Content-Type': 'application/json' } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e?.message ?? e) }), { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } });
  }
});
