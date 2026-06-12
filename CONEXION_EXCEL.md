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
