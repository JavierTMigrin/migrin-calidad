# Consultas SQL — Control de Calidad MIGRIN

Consultas estadisticas listas para pegar en el SQL Editor de Supabase,
organizadas por planta y producto:

`consultas_sql/<planta>/<producto>/<nn>_<consulta>.sql`

| Archivo | Que entrega |
|---|---|
| 01_ultimos_ensayos | Ultimos 50 registros con todos los datos del formulario |
| 02_serie_granulometrica | rp/ra/pasante por tamiz + moviles 7 y 30 + EETT + estado |
| 03_carta_de_control | n, media, desv std, CV, LCS/LCI 3 sigma, % cumplimiento |
| 04_fuera_de_norma | Solo mediciones que violan la EETT |
| 05_resumen_mensual | Estadistica mensual por tamiz |
| 06_comparativa_turnos | Media y desv por turno |
| 07_comparativa_analistas | Media y desv por analista (sesgos de medicion) |
| 08_tendencia_un_tamiz | Serie temporal de un tamiz (editable) |
| 09_estadistica_quimica | n/media/desv/min/max por oxido |
| 10_evolucion_quimica | Fe2O3 y SiO2 en el tiempo con movil 7 |

Requisitos: haber ejecutado supabase-eett-setup.sql,
supabase-folio-setup.sql, supabase-vistas-excel.sql y
supabase-vistas-analisis.sql.

Las consultas tambien sirven via REST para Excel agregando los filtros
a la URL de la vista (ver CONEXION_EXCEL.md). Esta carpeta se regenera
con `gen-consultas-sql.ps1`.