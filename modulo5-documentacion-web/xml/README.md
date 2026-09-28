# Módulo 5 — Lenguajes de Marcas y Sistemas de Gestión de Información

**Entregable:** exportación XML de proyectos finalizados + esquema XSD de validación

---

## 1. Qué datos representa el XML

El fichero `datos.xml` es una **exportación de proyectos finalizados**, extraída de la base de datos `vectorsec_gestion` (Módulo 4), con sus hallazgos e informes asociados. No son datos inventados para este módulo — *son literalmente los mismos registros insertados en* [`sql/02_insercion_datos.sql`](../../modulo4-base-datos/sql/02_insercion_datos.sql) *(proyectos 1 y 3), reutilizados aquí para que el ejemplo sea trazable de principio a fin del proyecto*.

Se incluyen **dos proyectos**, elegidos deliberadamente por ser distintos entre sí:

- **Proyecto 1** (*Clínica Dental Sonrisas, auditoría de seguridad*): tiene 2 hallazgos técnicos.
- **Proyecto 3** (*Bufete Martínez, consultoría RGPD/ENS*): **no tiene ningún hallazgo**.

Esta diferencia **no es casual** — se aprovecha para demostrar con un caso real por qué el bloque `<Hallazgos>` debe ser opcional en el esquema (apartado 3): *una consultoría normativa no genera hallazgos técnicos de la misma forma que una auditoría o un pentest*.

---

## 2. Estructura del XML

```text
VectorSecExport (fechaExportacion, origen)
└── Proyecto (id, estado)   [1..N]
    ├── Cliente
    │   ├── NombreEmpresa
    │   ├── CIF
    │   └── Sector
    ├── Servicio
    │   ├── NombreServicio
    │   └── Tipo
    ├── FechaInicio
    ├── FechaFinReal            [opcional]
    ├── Hallazgos               [opcional]
    │   └── Hallazgo (id, severidad, estado)   [0..N]
    │       ├── Titulo
    │       └── FechaDeteccion
    └── Informe (version, fecha)   [0..N]
        ├── Autor
        └── RutaArchivo
```

---

## 3. Cómo se valida — diseño del XSD

El fichero `esquema.xsd` no se limita a comprobar que las etiquetas existan: valida **tipos, patrones, longitudes, enumeraciones y cardinalidades** reales, y —*esto es la parte más importante*— **reutiliza exactamente las mismas restricciones ya definidas en el `CHECK` de las tablas PostgreSQL del Módulo 4**, en lugar de inventar una lista de valores paralela que pudiera desincronizarse con el tiempo:

| Restricción XSD | Regla aplicada | Coincide con (Módulo 4) |
| :--- | :--- | :--- |
| `tipoSeveridad` (enumeración) | `Critica`, `Alta`, `Media`, `Baja` | `CHECK` de la columna `severidad` en `hallazgos` |
| `tipoEstadoHallazgo` (enumeración) | `Abierto`, `En remediacion`, `Cerrado` | `CHECK` de `estado` en `hallazgos` |
| `tipoEstadoProyecto` (enumeración) | `Planificado`, `En curso`, `Finalizado`, `Cancelado` | `CHECK` de `estado` en `proyectos` |
| `tipoServicio` (enumeración) | `Auditoria`, `Pentesting`, `Formacion`, `Consultoria` | `CHECK` de `tipo` en `servicios` |
| `tipoCIF` (patrón) | `[A-Z][0-9]{8}` | Formato ya usado en los datos de ejemplo del Módulo 4 |
| `tipoTitulo` (longitud) | 5 a 150 caracteres | `VARCHAR(150)` de la columna `titulo` en `hallazgos` |
| `tipoVersion` (patrón) | `[0-9]+\.[0-9]+` | Formato ya usado en la columna `version` de `informes` |
| `Hallazgos`/`Hallazgo` (cardinalidad) | `minOccurs="0" maxOccurs="unbounded"` | Un proyecto puede tener 0 o varios hallazgos |
| `Informe` (cardinalidad) | `minOccurs="0" maxOccurs="unbounded"` | Un proyecto puede tener 0, 1 o varios informes (preliminar + final) |
| `Proyecto` (cardinalidad) | `minOccurs="1" maxOccurs="unbounded"` | Una exportación debe traer al menos un proyecto |

> 📌 **Limitación conocida y asumida:** el XSD no puede expresar la regla "todo proyecto en estado `Finalizado` debe tener al menos un `Informe`" — eso sería una validación condicional entre un atributo y la cardinalidad de un elemento hermano, algo que XSD 1.0 no soporta de forma nativa (requeriría XSD 1.1 con `<xs:assert>`, o una validación adicional en Schematron). Se documenta como **mejora futura**, con el mismo criterio ya aplicado a otras limitaciones del proyecto (*por ejemplo, el switch de Capa 3 en el Módulo 3*): **una carencia identificada y explicada, no ocultada**.

---

## 4. Evidencia de validación

### 4.1 Validación correcta

Ejecutado con `xmllint` (herramienta estándar de validación XML, incluida en `libxml2-utils`):

```bash
xmllint --noout --schema esquema.xsd datos.xml
```

Salida real (ver [`evidencias/validacion_correcta.log`](evidencias/validacion_correcta.log)):

```bash
datos.xml validates
Código de salida: 0
```

### 4.2 Validación incorrecta (demuestra que el XSD sí controla)

Se preparó [`datos_invalido_ejemplo.xml`](datos_invalido_ejemplo.xml) con **tres errores introducidos a propósito**:

1. Un **CIF** sin la letra inicial (`12345671` en vez de `B12345671`) — **viola el patrón**.
2. Falta el elemento `<FechaInicio>`, obligatorio — **viola la secuencia/cardinalidad**.
3. Una severidad `"Urgente"`, que no existe en el catálogo — **viola la enumeración**.

Salida real (ver [`evidencias/validacion_incorrecta.log`](evidencias/validacion_incorrecta.log)):

```bash
datos_invalido_ejemplo.xml:21: element CIF: Schemas validity error : Element 'CIF':
[facet 'pattern'] The value '12345671' is not accepted by the pattern '[A-Z][0-9]{8}'.
datos_invalido_ejemplo.xml:28: element FechaFinReal: Schemas validity error :
Element 'FechaFinReal': This element is not expected. Expected is ( FechaInicio ).
datos_invalido_ejemplo.xml fails to validate
Código de salida: 3
```

> 📌 El validador se detiene en cuanto encuentra una ruptura de secuencia (*el segundo error*), sin llegar a evaluar el tercero (*la severidad `"Urgente"`*) en esa misma pasada — *es el comportamiento normal de un validador XML, no un fallo del esquema*. Para dejar constancia también de que la restricción de enumeración funciona, se corrigieron los dos primeros errores y se validó de nuevo, aislando el tercero:

```bash
/tmp/datos_invalido_severidad.xml:16: element Hallazgo: Schemas validity error :
Element 'Hallazgo', attribute 'severidad': [facet 'enumeration'] The value 'Urgente'
is not an element of the set {'Critica', 'Alta', 'Media', 'Baja'}.
datos_invalido_severidad.xml fails to validate
Código de salida: 3
```

Con esto quedan demostrados, con evidencia real y no simulada, los tres tipos de restricción exigidos por el enunciado: **patrón**, **cardinalidad/secuencia** y **enumeración**.

---

## 5. Integración con el proyecto

Se elige la opción de **"XML como formato de intercambio/reporte"**, y no es una integración simbólica: conecta directamente dos módulos ya construidos.

- **Origen del dato:** los proyectos, hallazgos e informes exportados proceden literalmente de `vectorsec_gestion` en `SRV-APP01` (Módulo 4) — *este XML podría generarse en la práctica con una consulta como la de `sql/03_consultas.sql` (Consulta 1), envuelta en una función que serialice el resultado a XML*.
- **Destino del dato:** en el Módulo 6 (Cloud/AWS) se diseñó un portal de clientes en AWS que necesita sincronizar **metadatos de informes ya finalizados** desde `SRV-APP01` hacia la base de datos del portal (RDS), sin exponer nunca los hallazgos ni datos internos de proyectos en curso. Este XML es exactamente el formato de intercambio que resolvería esa sincronización: **un documento validable**, con estructura fija, que solo contiene proyectos ya finalizados — *la frontera de confianza entre "dato interno" y "dato exportable" queda impuesta por el propio proceso de exportación, no solo por buena voluntad*.

Este es el hilo que conecta Módulo 4 (*origen del dato*) → Módulo 5 (*formato validado de intercambio*) → Módulo 6 (*destino del dato en la nube*), en vez de tratar cada módulo como un ejercicio aislado.

---

## 6. Checklist de verificación

- [x] **XML** con estructura jerárquica clara y datos realistas (reutilizados del Módulo 4)
- [x] **XSD** con tipos, patrones, longitudes, enumeraciones y cardinalidades reales
- [x] **Validación correcta** demostrada con evidencia real (`xmllint`, código de salida 0)
- [x] **Validación incorrecta** demostrada con 3 errores distintos (patrón, secuencia, enumeración), código de salida 3
- [x] **Integración** explicada y trazable con los Módulos 4 y 6

---

## 7. Archivos de esta carpeta

| Archivo | Contenido |
| :--- | :--- |
| [`datos.xml`](datos.xml) | Exportación válida de 2 proyectos finalizados |
| [`esquema.xsd`](esquema.xsd) | Esquema de validación |
| [`datos_invalido_ejemplo.xml`](datos_invalido_ejemplo.xml) | Ejemplo con errores deliberados, para demostrar el control del XSD |
| [`evidencias/validacion_correcta.log`](evidencias/validacion_correcta.log) | Salida real de `xmllint` sobre `datos.xml` |
| [`evidencias/validacion_incorrecta.log`](evidencias/validacion_incorrecta.log) | Salida real de `xmllint` sobre los ejemplos inválidos |
