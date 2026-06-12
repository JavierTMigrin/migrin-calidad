# Conexión Excel ↔ Supabase (Control de Calidad MIGRIN)

## Paso 1 — Crear las vistas (una sola vez)
En Supabase → **SQL Editor** → pegar y ejecutar todo el contenido de
`supabase-vistas-excel.sql`. Esto crea 35 vistas (una por formulario
más `v_ensayos_todos` con todo junto).

## Paso 2 — Conectar Excel (Power Query)

1. En Excel: **Datos → Obtener datos → De otras fuentes → Desde la web**
2. Elegir **Avanzadas** y completar:
   - **URL**: `https://wxjclxmtceuhlbwxtptc.supabase.co/rest/v1/v_tt_tlh?select=*`
     (cambiar `v_tt_tlh` por la vista que necesites)
   - **Parámetros de encabezado HTTP** (agregar 2):
     | Encabezado | Valor |
     |---|---|
     | `apikey` | `sb_publishable_am0r8DfiGyNuU2lbn4o6aw_xgjklyKB` |
     | `Authorization` | `Bearer sb_publishable_am0r8DfiGyNuU2lbn4o6aw_xgjklyKB` |
3. **Aceptar** → si pregunta por credenciales, elegir **Anónimo** → Conectar
4. Se abre el editor de Power Query con una lista JSON:
   - Clic en **"To Table" / "A tabla"** (cinta Transformar)
   - Clic en el ícono de expandir (⇄) en el encabezado de la columna →
     seleccionar todas las columnas → Aceptar
5. **Cerrar y cargar** → los datos quedan como tabla en la hoja

Para refrescar los datos: **Datos → Actualizar todo** (trae lo último
de Supabase automáticamente).

## Vistas disponibles

| Vista | Formulario |
|---|---|
| v_a36 | A36 TLH |
| v_a38 | A38 Fierrillo |
| v_alimentacion | Alimentación a Planta |
| v_rechazo_2001 | Rechazo 20.01 |
| v_veralia_alta / v_veralia_baja | Veralia Alta/Baja Hierro |
| v_molino_1 / v_molino_2 | Molino 1 / 2 |
| v_under_2007 / v_over_2007 / v_under_tack | Under/Over 20.07, Under Tack |
| v_muestras_esp | Muestras Especiales |
| v_lodos_arenas / v_lodos_cuarzo | Lodos |
| v_desp_padre_hurtado / v_desp_lirquen / v_desp_llayllay | Despachos Arena Premium |
| v_control_granos | Control de Granos (Arenas) |
| v_materias_primas | Materias Primas Las Piedras |
| v_alim_cuarzo / v_tlh_cuarzo / v_compacta / v_dlk | Planta Cuarzo |
| v_tt_tlh | TLH Turco |
| v_tt_alimentacion | Alimentación TLH (con mezcla) |
| v_tt_granos | Control Granos Producción (granos + arcillas) |
| v_tt_arcillas | % Arcillas |
| v_tt_arenas_minas | Arenas Minas |
| v_tt_cilindro | Cilindro (entrada t_* / salida sal_t_*) |
| v_tt_floculante | Floculante |
| v_tt_lodo | Lodo (con -#100 y +#120) |
| v_tt_grano_mina | Grano Mina |
| v_tt_arena_mina_cristaleria | Arena Mina Cristalería |
| v_tt_fierrillo_casillero | Fierrillo Casillero |
| v_ensayos_todos | Todos los registros (granu/química en JSON) |

Columnas: `folio` = N° de muestra correlativo; `rp_18`, `rp_20`... =
retenido parcial por tamiz (%, masa ÷ peso final × 100, igual que la app);
en Cilindro la salida es `sal_rp_*`; `sio2`...`tio2` = química (%);
el resto son los campos del formulario.

## Vistas de análisis (supabase-vistas-analisis.sql)

Para cada producto con granulometría existen 2 vistas adicionales,
nombradas por planta y producto:

**`v_<planta>_<producto>_serie`** — formato largo (1 fila por ensayo × tamiz),
ideal para tablas dinámicas y gráficos de tendencia:
| Columna | Contenido |
|---|---|
| folio, fecha_muestreo, turno, analista | identificación del ensayo |
| orden_tamiz, tamiz | banda granulométrica en orden |
| ret_parcial / ret_acumulado / pasante_acum | los 3 valores en % |
| rp_movil_7 / rp_movil_30 / ra_movil_7 | promedios móviles |
| eett_rp_min/max, eett_ra_min/max, eett_pas_min/max | límites EETT vigentes |
| estado_eett | OK / FUERA / vacío (sin EETT) |

**`v_<planta>_<producto>_carta`** — carta de control (1 fila por tamiz):
| Columna | Contenido |
|---|---|
| n_datos | cantidad de ensayos |
| media_rp, desv_std_rp, cv_rp_pct | estadística del ret. parcial |
| lcs_rp_3s / lci_rp_3s | límites de control ±3σ |
| media_ra, desv_std_ra, lcs_ra_3s / lci_ra_3s | ídem ret. acumulado |
| eett_* | límites EETT |
| n_fuera, pct_cumplimiento | fuera de norma y % cumplimiento |

Ejemplos: `v_arenas_a36_serie`, `v_cuarzo_dlk_carta`,
`v_despachos_lirquen_serie`, `v_turco_tlh_carta`.

Los EETT se leen en vivo de la tabla `especificaciones` (lo que edites
en Ajustes se refleja al actualizar Excel). Las vistas se regeneran con
`gen-vistas-analisis.ps1` si se agregan productos nuevos.

## Filtros útiles (en la URL)

- Último año: `?select=*&fecha_muestreo=gte.2026-01-01`
- Por analista: `?select=*&analista=eq.Camila%20Opazo`
- Límite: `?select=*&limit=100`

## Power BI

Misma técnica: **Obtener datos → Web → Avanzadas** con la misma URL y
los mismos 2 encabezados. O conexión directa PostgreSQL
(Project Settings → Database) para acceso completo.

## Nota de seguridad

Las vistas son de **solo lectura** y quedan accesibles con la
publishable key (la misma que ya es pública en la app). Nadie puede
modificar ni borrar datos por esta vía — solo consultar.
