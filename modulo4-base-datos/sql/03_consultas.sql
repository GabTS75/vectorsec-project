-- ============================================================
-- VectorSec — vectorsec_gestion
-- 03_consultas.sql
-- Consultas de prueba, con explicación de qué demuestra cada una
-- ============================================================

-- --------------------------------------------------------------
-- CONSULTA 1 — Proyectos en curso, con cliente y servicio
-- Demuestra: JOIN entre 3 tablas (proyectos, clientes, servicios)
-- Uso real: vista de seguimiento diario para Dirección/Soporte
-- --------------------------------------------------------------
SELECT
    p.id_proyecto,
    c.nombre_empresa,
    s.nombre_servicio,
    p.fecha_inicio,
    p.fecha_fin_prevista
FROM proyectos p
JOIN clientes c   ON c.id_cliente = p.id_cliente
JOIN servicios s  ON s.id_servicio = p.id_servicio
WHERE p.estado = 'En curso'
ORDER BY p.fecha_fin_prevista;


-- --------------------------------------------------------------
-- CONSULTA 2 — Hallazgos abiertos, ordenados por severidad
-- Demuestra: filtrado + ordenación mediante CASE (severidad no es
-- alfabéticamente ordenable de forma natural: Critica > Alta > Media > Baja)
-- Uso real: lista de prioridades para el equipo de remediación
-- --------------------------------------------------------------
SELECT
    h.titulo,
    h.severidad,
    c.nombre_empresa,
    h.fecha_deteccion
FROM hallazgos h
JOIN proyectos p ON p.id_proyecto = h.id_proyecto
JOIN clientes c  ON c.id_cliente = p.id_cliente
WHERE h.estado != 'Cerrado'
ORDER BY
    CASE h.severidad
        WHEN 'Critica' THEN 1
        WHEN 'Alta'    THEN 2
        WHEN 'Media'   THEN 3
        WHEN 'Baja'    THEN 4
    END;


-- --------------------------------------------------------------
-- CONSULTA 3 — Nº de hallazgos por severidad (toda la empresa)
-- Demuestra: agregación con GROUP COUNT
-- Uso real: indicador (KPI) para el informe mensual de actividad
-- --------------------------------------------------------------
SELECT
    severidad,
    COUNT(*) AS total_hallazgos
FROM hallazgos
GROUP BY severidad
ORDER BY total_hallazgos DESC;


-- --------------------------------------------------------------
-- CONSULTA 4 — Empleados asignados a un proyecto concreto
-- Demuestra: JOIN a través de la tabla intermedia N:M
-- Uso real: saber quién forma parte de un equipo de proyecto
-- --------------------------------------------------------------
SELECT
    e.nombre,
    e.apellido,
    pe.rol_en_proyecto
FROM proyecto_empleados pe
JOIN empleados e ON e.id_empleado = pe.id_empleado
WHERE pe.id_proyecto = 4;


-- --------------------------------------------------------------
-- CONSULTA 5 — Clientes con más de un proyecto contratado
-- Demuestra: GROUP BY + HAVING (filtrar sobre un resultado agregado)
-- Uso real: identificar clientes recurrentes, relevante para
-- estrategia comercial
-- --------------------------------------------------------------
SELECT
    c.nombre_empresa,
    COUNT(p.id_proyecto) AS total_proyectos
FROM clientes c
JOIN proyectos p ON p.id_cliente = c.id_cliente
GROUP BY c.nombre_empresa
HAVING COUNT(p.id_proyecto) > 1
ORDER BY total_proyectos DESC;


-- --------------------------------------------------------------
-- CONSULTA 6 — Proyectos finalizados sin informe generado
-- Demuestra: LEFT JOIN + IS NULL (encontrar ausencia de relación)
-- Uso real: alerta de control de calidad — un proyecto finalizado
-- sin informe es una incidencia administrativa que hay que resolver
-- --------------------------------------------------------------
SELECT
    p.id_proyecto,
    c.nombre_empresa,
    p.fecha_fin_real
FROM proyectos p
JOIN clientes c ON c.id_cliente = p.id_cliente
LEFT JOIN informes i ON i.id_proyecto = p.id_proyecto
WHERE p.estado = 'Finalizado'
  AND i.id_informe IS NULL;
