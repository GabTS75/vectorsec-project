-- ============================================================
-- VectorSec — vectorsec_gestion
-- 04_usuarios_permisos.sql
-- Roles de acceso aplicando el principio de mínimo privilegio,
-- mismo criterio ya usado en las ACLs de red (Módulo 3) y en
-- los permisos NTFS de Active Directory (Módulo 2)
-- ============================================================

-- --------------------------------------------------------------
-- ROL 1: rol_lectura
-- Destinado a Dirección — consulta de seguimiento, sin permiso
-- de modificar ningún dato
-- --------------------------------------------------------------
CREATE ROLE rol_lectura NOLOGIN;

GRANT CONNECT ON DATABASE vectorsec_gestion TO rol_lectura;
GRANT USAGE ON SCHEMA public TO rol_lectura;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_lectura;

-- Para que las tablas creadas en el futuro también hereden este permiso
-- automáticamente, sin tener que repetir el GRANT manualmente cada vez
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO rol_lectura;

-- Usuario de ejemplo que usa este rol (Dirección)
CREATE USER ana_torres_direccion WITH PASSWORD 'D1r3cc10n-V3ct0rS3c!';
GRANT rol_lectura TO ana_torres_direccion;


-- --------------------------------------------------------------
-- ROL 2: rol_consultor
-- Destinado a consultores/analistas que registran su propio trabajo:
-- pueden leer y escribir en Proyectos, Hallazgos, Informes y la
-- relación Proyecto_Empleados, pero NO pueden borrar registros
-- ni modificar la ficha de un Cliente (solo Administración gestiona
-- altas/bajas de clientes)
-- --------------------------------------------------------------
CREATE ROLE rol_consultor NOLOGIN;

GRANT CONNECT ON DATABASE vectorsec_gestion TO rol_consultor;
GRANT USAGE ON SCHEMA public TO rol_consultor;

-- Lectura de todo el esquema (necesitan ver clientes y servicios
-- para poder trabajar, solo no pueden modificarlos)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_consultor;

-- Escritura (sin DELETE) solo en las tablas operativas de su trabajo diario
GRANT INSERT, UPDATE ON proyectos, hallazgos, informes, proyecto_empleados
    TO rol_consultor;

-- Las tablas con SERIAL necesitan además permiso sobre su secuencia
-- interna para poder generar nuevos IDs al insertar
GRANT USAGE, SELECT ON SEQUENCE
    proyectos_id_proyecto_seq,
    hallazgos_id_hallazgo_seq,
    informes_id_informe_seq
    TO rol_consultor;

-- Usuarios de ejemplo que usan este rol (consultores)
CREATE USER sara_iglesias WITH PASSWORD 'C0nsult0r-V3ct0rS3c!';
CREATE USER david_moreno WITH PASSWORD 'C0nsult0r-V3ct0rS3c!';
GRANT rol_consultor TO sara_iglesias, david_moreno;


-- --------------------------------------------------------------
-- Verificación — comprobar qué permisos tiene efectivamente cada rol
-- --------------------------------------------------------------
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('rol_lectura', 'rol_consultor')
ORDER BY grantee, table_name;

-- 📌 rol_lectura debe aparecer solo con privilegio SELECT en todas las tablas.
-- 📌 rol_consultor debe aparecer con SELECT en todas, más INSERT/UPDATE
--    únicamente en proyectos, hallazgos, informes y proyecto_empleados
--    (nunca en clientes, servicios ni empleados).

-- --------------------------------------------------------------
-- Nota: app_vectorsec (creado en el Módulo 2, SRV-APP01.md) mantiene
-- privilegio total sobre la base de datos, al ser la cuenta de
-- servicio de la propia aplicación de gestión — es la aplicación,
-- no PostgreSQL, quien aplica el control de permisos por usuario
-- final dentro de su propia interfaz.
-- --------------------------------------------------------------
