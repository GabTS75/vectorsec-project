-- ============================================================
-- VectorSec — vectorsec_gestion
-- 01_creacion_tablas.sql
-- Creación de tablas, claves primarias, foráneas y restricciones
-- Ejecutar como: psql -h 192.168.60.11 -U app_vectorsec -d vectorsec_gestion -f 01_creacion_tablas.sql
-- ============================================================

-- --------------------------------------------------------------
-- CLIENTES: empresas que contratan servicios a VectorSec
-- --------------------------------------------------------------
CREATE TABLE clientes (
    id_cliente      SERIAL PRIMARY KEY,
    nombre_empresa  VARCHAR(100) NOT NULL,
    cif             VARCHAR(15)  NOT NULL UNIQUE,
    sector          VARCHAR(60),
    email           VARCHAR(100) NOT NULL,
    fecha_alta      DATE NOT NULL DEFAULT CURRENT_DATE
);

-- --------------------------------------------------------------
-- SERVICIOS: catálogo de lo que ofrece VectorSec
-- --------------------------------------------------------------
CREATE TABLE servicios (
    id_servicio     SERIAL PRIMARY KEY,
    nombre_servicio VARCHAR(80) NOT NULL,
    tipo            VARCHAR(30) NOT NULL
        CHECK (tipo IN ('Auditoria', 'Pentesting', 'Formacion', 'Consultoria'))
);

-- --------------------------------------------------------------
-- EMPLEADOS: consultores, analistas SOC y formadores
-- usuario_ad referencia el usuario de Active Directory (Módulo 2),
-- sin duplicar la gestión de identidades ni contraseñas
-- --------------------------------------------------------------
CREATE TABLE empleados (
    id_empleado     SERIAL PRIMARY KEY,
    nombre          VARCHAR(60) NOT NULL,
    apellido        VARCHAR(60) NOT NULL,
    usuario_ad      VARCHAR(60) NOT NULL UNIQUE,
    rol             VARCHAR(40) NOT NULL
        CHECK (rol IN ('Consultor', 'Analista SOC', 'Formador', 'Administrativo'))
);

-- --------------------------------------------------------------
-- PROYECTOS: cada trabajo concreto para un cliente
-- --------------------------------------------------------------
CREATE TABLE proyectos (
    id_proyecto        SERIAL PRIMARY KEY,
    id_cliente         INTEGER NOT NULL REFERENCES clientes(id_cliente),
    id_servicio        INTEGER NOT NULL REFERENCES servicios(id_servicio),
    fecha_inicio       DATE NOT NULL,
    fecha_fin_prevista DATE,
    fecha_fin_real     DATE,
    estado             VARCHAR(20) NOT NULL DEFAULT 'Planificado'
        CHECK (estado IN ('Planificado', 'En curso', 'Finalizado', 'Cancelado')),
    CONSTRAINT chk_fechas CHECK (fecha_fin_prevista IS NULL OR fecha_fin_prevista >= fecha_inicio)
);

-- --------------------------------------------------------------
-- PROYECTO_EMPLEADOS: relación N:M — qué empleados trabajan en qué proyecto
-- Clave primaria compuesta: no necesita id propio, su única función
-- es representar la relación
-- --------------------------------------------------------------
CREATE TABLE proyecto_empleados (
    id_proyecto     INTEGER NOT NULL REFERENCES proyectos(id_proyecto),
    id_empleado     INTEGER NOT NULL REFERENCES empleados(id_empleado),
    rol_en_proyecto VARCHAR(40) NOT NULL DEFAULT 'Consultor asignado',
    PRIMARY KEY (id_proyecto, id_empleado)
);

-- --------------------------------------------------------------
-- HALLAZGOS: vulnerabilidades/incidencias detectadas en un proyecto
-- --------------------------------------------------------------
CREATE TABLE hallazgos (
    id_hallazgo     SERIAL PRIMARY KEY,
    id_proyecto     INTEGER NOT NULL REFERENCES proyectos(id_proyecto),
    titulo          VARCHAR(150) NOT NULL,
    descripcion     TEXT,
    severidad       VARCHAR(15) NOT NULL
        CHECK (severidad IN ('Critica', 'Alta', 'Media', 'Baja')),
    estado          VARCHAR(20) NOT NULL DEFAULT 'Abierto'
        CHECK (estado IN ('Abierto', 'En remediacion', 'Cerrado')),
    fecha_deteccion DATE NOT NULL DEFAULT CURRENT_DATE
);

-- --------------------------------------------------------------
-- INFORMES: entregable final generado a partir de los hallazgos
-- --------------------------------------------------------------
CREATE TABLE informes (
    id_informe         SERIAL PRIMARY KEY,
    id_proyecto        INTEGER NOT NULL REFERENCES proyectos(id_proyecto),
    id_empleado_autor  INTEGER NOT NULL REFERENCES empleados(id_empleado),
    fecha_generacion   DATE NOT NULL DEFAULT CURRENT_DATE,
    version             VARCHAR(10) NOT NULL DEFAULT '1.0',
    ruta_archivo        VARCHAR(255)
);

-- --------------------------------------------------------------
-- Índices adicionales sobre las claves foráneas más consultadas,
-- para acelerar los JOIN habituales en los informes de seguimiento
-- --------------------------------------------------------------
CREATE INDEX idx_proyectos_cliente ON proyectos(id_cliente);
CREATE INDEX idx_hallazgos_proyecto ON hallazgos(id_proyecto);
CREATE INDEX idx_informes_proyecto ON informes(id_proyecto);
