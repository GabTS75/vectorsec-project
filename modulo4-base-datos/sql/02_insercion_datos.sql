-- ============================================================
-- VectorSec — vectorsec_gestion
-- 02_insercion_datos.sql
-- Datos de ejemplo — se respeta el orden de dependencias:
-- primero las tablas sin FK, después las que dependen de ellas
-- ============================================================

-- --------------------------------------------------------------
-- SERVICIOS (4 registros)
-- --------------------------------------------------------------
INSERT INTO servicios (nombre_servicio, tipo) VALUES
('Auditoría de seguridad perimetral', 'Auditoria'),
('Test de intrusión (pentesting) web', 'Pentesting'),
('Formación en concienciación de seguridad', 'Formacion'),
('Consultoría de cumplimiento RGPD/ENS', 'Consultoria');

-- --------------------------------------------------------------
-- EMPLEADOS (5 registros)
-- usuario_ad sigue el patrón nombre.apellido del Módulo 2
-- --------------------------------------------------------------
INSERT INTO empleados (nombre, apellido, usuario_ad, rol) VALUES
('Sara', 'Iglesias', 'sara.iglesias', 'Consultor'),
('David', 'Moreno', 'david.moreno', 'Consultor'),
('Elena', 'Castro', 'elena.castro', 'Analista SOC'),
('Marcos', 'Vega', 'marcos.vega', 'Analista SOC'),
('Lucia', 'Ramos', 'lucia.ramos', 'Formador');

-- --------------------------------------------------------------
-- CLIENTES (5 registros)
-- --------------------------------------------------------------
INSERT INTO clientes (nombre_empresa, cif, sector, email, fecha_alta) VALUES
('Clínica Dental Sonrisas S.L.', 'B12345671', 'Sanidad', 'contacto@clinicasonrisas.es', '2026-01-15'),
('Comercial Norte y Sur S.A.', 'A12345672', 'Retail', 'admin@comercialnorteysur.es', '2026-02-03'),
('Bufete Martínez & Asociados', 'B12345673', 'Legal', 'info@bufetemartinez.es', '2026-02-20'),
('TransLogística Ibérica S.L.', 'B12345674', 'Logística', 'it@translogistica.es', '2026-03-10'),
('Academia FormaPro', 'B12345675', 'Educación', 'direccion@formapro.es', '2026-03-22');

-- --------------------------------------------------------------
-- PROYECTOS (6 registros)
-- --------------------------------------------------------------
INSERT INTO proyectos (id_cliente, id_servicio, fecha_inicio, fecha_fin_prevista, fecha_fin_real, estado) VALUES
(1, 1, '2026-04-01', '2026-04-15', '2026-04-14', 'Finalizado'),
(2, 2, '2026-04-10', '2026-04-30', NULL, 'En curso'),
(3, 4, '2026-05-01', '2026-05-20', '2026-05-19', 'Finalizado'),
(4, 2, '2026-05-15', '2026-06-05', NULL, 'En curso'),
(5, 3, '2026-06-01', '2026-06-10', NULL, 'Planificado'),
(1, 3, '2026-06-15', '2026-06-16', NULL, 'Planificado');

-- --------------------------------------------------------------
-- PROYECTO_EMPLEADOS (8 registros) — relación N:M
-- --------------------------------------------------------------
INSERT INTO proyecto_empleados (id_proyecto, id_empleado, rol_en_proyecto) VALUES
(1, 1, 'Consultor responsable'),
(1, 3, 'Apoyo SOC'),
(2, 2, 'Consultor responsable'),
(2, 4, 'Apoyo SOC'),
(3, 1, 'Consultor responsable'),
(4, 2, 'Consultor responsable'),
(4, 3, 'Apoyo SOC'),
(5, 5, 'Formador responsable');

-- --------------------------------------------------------------
-- HALLAZGOS (6 registros)
-- --------------------------------------------------------------
INSERT INTO hallazgos (id_proyecto, titulo, descripcion, severidad, estado, fecha_deteccion) VALUES
(1, 'Puerto RDP expuesto a Internet', 'El servidor de gestión interna expone el puerto 3389 sin restricción de origen.', 'Alta', 'Cerrado', '2026-04-05'),
(1, 'Certificado TLS caducado', 'El certificado del portal de citas caducó hace 40 días.', 'Media', 'Cerrado', '2026-04-06'),
(2, 'Inyección SQL en formulario de contacto', 'El parámetro "email" no sanitiza la entrada del usuario.', 'Critica', 'En remediacion', '2026-04-18'),
(2, 'Cabeceras de seguridad HTTP ausentes', 'Faltan Content-Security-Policy y X-Frame-Options.', 'Baja', 'Abierto', '2026-04-20'),
(4, 'Credenciales por defecto en router de sucursal', 'Se detectó acceso con usuario/contraseña de fábrica.', 'Critica', 'Abierto', '2026-05-22'),
(4, 'Falta de segmentación de red entre sucursales', 'Todas las sucursales comparten la misma VLAN plana.', 'Alta', 'Abierto', '2026-05-23');

-- --------------------------------------------------------------
-- INFORMES (4 registros)
-- --------------------------------------------------------------
INSERT INTO informes (id_proyecto, id_empleado_autor, fecha_generacion, version, ruta_archivo) VALUES
(1, 1, '2026-04-14', '1.0', '/informes/2026/clinica-sonrisa-auditoria-v1.pdf'),
(3, 1, '2026-05-19', '1.0', '/informes/2026/bufete-martinez-consultoria-v1.pdf'),
(2, 2, '2026-04-25', '0.1', '/informes/2026/comercial-norte-pentest-preliminar-v0.1.pdf'),
(4, 2, '2026-05-30', '0.1', '/informes/2026/translogistica-pentest-preliminar-v0.1.pdf');
