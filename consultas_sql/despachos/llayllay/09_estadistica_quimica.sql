-- Producto: DESP_LLAY | Planta: DESPACHOS
-- Ejecutar en el SQL Editor de Supabase.
-- Estadistica de la quimica: n, media, desv std, min, max por oxido.
SELECT 'SiO2' AS oxido, COUNT(sio2) AS n, ROUND(AVG(sio2),3) AS media,
       ROUND(STDDEV_SAMP(sio2),4) AS desv_std, MIN(sio2) AS minimo, MAX(sio2) AS maximo FROM v_desp_llayllay
UNION ALL
SELECT 'Al2O3', COUNT(al2o3), ROUND(AVG(al2o3),3), ROUND(STDDEV_SAMP(al2o3),4), MIN(al2o3), MAX(al2o3) FROM v_desp_llayllay
UNION ALL
SELECT 'Fe2O3', COUNT(fe2o3), ROUND(AVG(fe2o3),3), ROUND(STDDEV_SAMP(fe2o3),4), MIN(fe2o3), MAX(fe2o3) FROM v_desp_llayllay
UNION ALL
SELECT 'CaO', COUNT(cao), ROUND(AVG(cao),3), ROUND(STDDEV_SAMP(cao),4), MIN(cao), MAX(cao) FROM v_desp_llayllay
UNION ALL
SELECT 'MgO', COUNT(mgo), ROUND(AVG(mgo),3), ROUND(STDDEV_SAMP(mgo),4), MIN(mgo), MAX(mgo) FROM v_desp_llayllay
UNION ALL
SELECT 'K2O', COUNT(k2o), ROUND(AVG(k2o),3), ROUND(STDDEV_SAMP(k2o),4), MIN(k2o), MAX(k2o) FROM v_desp_llayllay
UNION ALL
SELECT 'Na2O', COUNT(na2o), ROUND(AVG(na2o),3), ROUND(STDDEV_SAMP(na2o),4), MIN(na2o), MAX(na2o) FROM v_desp_llayllay
UNION ALL
SELECT 'TiO2', COUNT(tio2), ROUND(AVG(tio2),3), ROUND(STDDEV_SAMP(tio2),4), MIN(tio2), MAX(tio2) FROM v_desp_llayllay;