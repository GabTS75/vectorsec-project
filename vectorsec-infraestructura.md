# VectorSec — Infraestructura IT Integral

## Proyecto Intermodular

### 1. Qué es este proyecto

En este repositorio documento el diseño, despliegue y documentación de la infraestructura IT completa de **VectorSec**, una empresa de ciberseguridad ficticia (pero deliberadamente realista) en fase de crecimiento, dedicada a servicios de auditoría de seguridad, pentesting, consultoría de cumplimiento normativo (RGPD/ENS) y formación in-company para pymes.

No es una colección de siete ejercicios independientes. Es **un único proyecto**, con una empresa, unos datos y unas decisiones de diseño que se arrastran y se referencian de un módulo a otro: *el mismo esquema de VLANs que separa el laboratorio de pentesting del resto de la red (Módulo 3) es el que justifica un servidor aislado para ese laboratorio (Módulo 1); los mismos datos de clientes y hallazgos que se insertan en PostgreSQL (Módulo 4) son los que se exportan y validan en XML (Módulo 5) y los que viajarían hacia el portal cloud (Módulo 6)*.

El objetivo es doble:

- **Académico:** cubrir de forma integrada los siete módulos del primer curso de ASIR, siguiendo el proceso real que seguiría un administrador de sistemas y redes — *desde el análisis de necesidades hasta la documentación final* — en lugar de tratar cada materia por separado.
- **Profesional:** servir como pieza de portfolio verificable, con evidencia real de cada configuración, error y corrección evidenciada — *no una narrativa idealizada donde todo funciona a la primera*.

---

### 2. La empresa: VectorSec

| | |
| :--- | :--- |
| **Sector** | Ciberseguridad — *auditoría, pentesting, consultoría de cumplimiento, formación* |
| **Tamaño** | 8-9 empleados, en fase de crecimiento |
| **Sedes** | Un local, dos plantas |
| **Departamentos** | Recepción, Administración, Dirección, Desarrollo, Soporte Técnico, Aula de Formación |
| **Idea de diseño central** | Una empresa que audita la seguridad de terceros debe, por coherencia, aplicar sobre su propia infraestructura los mismos criterios de seguridad que exige a sus clientes |

Esa última **idea** *—la coherencia interna como principio de diseño, no como eslogan—* es el hilo que conecta las decisiones de los siete módulos: el laboratorio de pentesting aislado en red y en hardware, el acceso de gestión de red solo por SSH, los roles de base de datos sin permiso de borrado, la frontera entre "dato interno" y "dato exportable" impuesta por un esquema XSD, y la arquitectura cloud que extiende servicios sin exponer nunca los datos sensibles de auditoría.

---

### 3. Estructura del repositorio

```text
vectorsec-project/
├── modulo1-hardware/                   → Equipos cliente, servidores, almacenamiento y red (catálogo y justificación)
├── modulo2-sistemas-operativos/        → Instalación y configuración de cada servidor, imagen de los 16 clientes, AD y permisos
├── modulo3-redes/                      → Topología, VLANs, direccionamiento, ACLs, hardening SSH, evidencia de pruebas
├── modulo4-base-datos/                 → Modelo E-R, scripts SQL, roles de acceso, copia de seguridad
├── modulo5-documentacion-web/          → XML + XSD (entregable evaluable) y web corporativa (pieza adicional de marketing)
├── modulo6-cloud-aws/                  → Extensión de la infraestructura on-premise hacia AWS
└── modulo7-empleabilidad-portfolio/    → Entregables de empleabilidad, CV, carta de presentación y sección del proyecto para el portfolio
```

Cada carpeta tiene su propio `README.md`, autocontenido y enlazable de forma independiente. A continuación, presento **un mapa** de "cómo encajan entre sí", no es un resumen de cada uno — *para mayor detalle, entrar en la carpeta correspondiente*.

---

### 4. Los siete módulos (mapeo)

#### [Módulo 1 — Fundamentos de Hardware](modulo1-hardware/)

Este módulo, **define y justifica** el hardware de `VectorSec`: 16 equipos cliente repartidos en 6 departamentos (*dimensionados según la carga real de cada uno — no es lo mismo Recepción que Desarrollo*), y **4 servidores** (*`SRV-DC01` dominio, `SRV-APP01` aplicaciones/BD, `SRV-LAB01` laboratorio de pentesting aislado, `SRV-NAS` almacenamiento y backup*), más el equipamiento de red mínimo exigido por el proyecto.

> La decisión más relevante del módulo *—un tercer servidor dedicado y aislado para el laboratorio—* no es un requisito mínimo, sino la primera manifestación de **la identidad de seguridad** de la empresa, que luego se traduce en red (Módulo 3) y en sistema operativo (Módulo 2).

#### [Módulo 3 — Planificación y Administración de Redes](modulo3-redes/)

Aquí, se **diseña la red completa** en Cisco Packet Tracer: **9 VLANs** (una por departamento, más una VLAN de laboratorio totalmente aislada y una de invitados), enrutamiento inter-VLAN mediante Router-on-a-Stick, ACLs extendidas que aplican el principio de mínimo privilegio, y gestión de switches restringida a SSH (Telnet deshabilitado). El módulo incluye evidencia real de pruebas (tablas de verificación DHCP, ping intra/inter-VLAN, ACLs y SSH) y la documentación honesta de dos incidencias reales encontradas durante la implementación *—un solapamiento de subredes en la VLAN de gestión y una subinterfaz sin IP asignada—* con su diagnóstico y resolución, no solo el resultado final ya corregido.

> Se desarrolla antes que el Módulo 2 en el orden de trabajo real, porque los sistemas operativos de los servidores **dependen de un direccionamiento de red** ya definido.

#### [Módulo 2 — Implantación de Sistemas Operativos](modulo2-sistemas-operativos/)

Se **instala y configura** cada servidor sobre la base de red del Módulo 3: Windows Server 2022 + Active Directory en `SRV-DC01`, Ubuntu Server + PostgreSQL en `SRV-APP01`, Kali Linux + Wazuh (SIEM) en `SRV-LAB01`, y OpenMediaVault con RAID 5 + hot spare en `SRV-NAS`. Incluye el diseño de la estructura de Unidades Organizativas, usuarios y grupos de seguridad en AD, y una guía completa "paso a paso" para clonar e implantar los 16 equipos cliente.

>La guía de clonación se realiza mediante el uso de `Sysprep` en modo auditoría y **Clonezilla** — *explicada desde cero, sin dar por hecho conocimiento previo*.

#### [Módulo 4 — Gestión de Bases de Datos](modulo4-base-datos/)

En este módulo se **modela y despliega** `vectorsec_gestion`, la base de datos PostgreSQL que sostiene el negocio de `VectorSec`: clientes, servicios, empleados, proyectos y su relación N:M con empleados, hallazgos de auditoría y los informes que los documentan. Incluye el modelo E-R, los scripts SQL completos (creación, datos, consultas, permisos), roles de acceso sin privilegio de borrado, y el script de copia de seguridad que se integra con la política de backup del NAS (Módulo 1).

> Los datos de ejemplo de este módulo **no son desechables**: son los mismos que reaparecen, literalmente, en el Módulo 5.

#### [Módulo 5 — Lenguajes de Marcas y Documentación](modulo5-documentacion-web/)

Aquí, lo que se pide es una **exportación XML validada por XSD** de los proyectos finalizados de `VectorSec`, reutilizando los datos reales del Módulo 4 y las mismas restricciones (*enumeraciones, patrones, longitudes*) ya definidas como `CHECK` en PostgreSQL. La validación se demuestra con evidencia real de `xmllint` *—no simulada—* frente a un caso correcto y tres tipos de error deliberados (*patrón, secuencia y enumeración*).

> Como pieza adicional y construida para ser "el rostro visible" de `VectorSec`, el módulo incluye también una **web corporativa** de dos ficheros (HTML + CSS), pensada como material de marketing futuro.

#### [Módulo 6 — Fundamentos de Computación en la Nube](modulo6-cloud-aws/)

Diseña una **extensión**, no una migración, de la infraestructura hacia AWS: un portal de clientes (EC2 + ALB + Auto Scaling) respaldado por una base de datos RDS que sincroniza **únicamente metadatos de informes** ya finalizados *—precisamente el tipo de dato que exporta el XML del Módulo 5—*, dejando los datos sensibles de auditoría en curso exclusivamente on-premise.

> Es la pieza que cierra el recorrido del dato: Módulo 4 lo genera, Módulo 5 lo valida y da formato, Módulo 6 lo consume en la nube **sin comprometer** lo que "no debe salir de casa".

#### [Módulo 7 — Itinerario Personal para la Empleabilidad](modulo7-empleabilidad-portfolio/)

Este convierte el trabajo técnico anterior en un **perfil profesional competitivo**: una carta de presentación en primera persona y un CV reescrito con la fórmula X-Y-Z, además incluyo una nueva sección para mi portfolio profesional mostrando este proyecto, y los seis entregables de empleabilidad exigidos (perfil profesional, investigación de sector, perfil de GitHub, presentación del proyecto, portfolio básico y una reflexión final honesta sobre el proceso).

> La carta de presentación y el nuevo CV van orientados a modo de ejemplo para **las próximas prácticas profesionales y futuras contrataciones**, no obstante se modificaría según cada oferta laboral.

---

### 5. Cómo se conectan los módulos entre sí

El proyecto está diseñado para leerse de dos formas: módulo a módulo (la vista académica) o siguiendo los hilos que lo atraviesan (la vista de infraestructura real). Los más relevantes:

- **El laboratorio aislado.** Nace como decisión de hardware (Módulo 1) → se materializa como una VLAN sin salida y ACLs restrictivas (Módulo 3) → se instala sobre Kali + Wazuh con firewall de host propio (Módulo 2). Tres capas independientes aplicando la misma política — *defensa en profundidad, no un control único*.
- **El dato de auditoría.** Se modela y almacena en PostgreSQL (Módulo 4) → se exporta en un formato validado que impone qué puede salir y qué no (Módulo 5) → alimenta un portal cloud que nunca ve lo que no debe ver (Módulo 6).
- **La coherencia como producto.** El mismo criterio de "quien audita seguridad debe aplicarla primero sobre sí mismo" aparece explícitamente en el Módulo 1 (*justificación del servidor de laboratorio*), el Módulo 3 (*gestión de red solo por SSH*) y el Módulo 4 (*roles de base de datos sin DELETE*).

---

### 6. Sobre la honestidad de este proyecto

Un criterio (*coherencia y consistencia*) que he mantenido en los siete módulos: **las decisiones, límites y errores reales se documentan, no se ocultan.** Algunos ejemplos concretos, explicados en detalle en sus respectivos módulos:

- Dos incidencias reales de configuración de red (*solapamiento de subredes, subinterfaz sin IP*) con su proceso de diagnóstico completo, no solo la solución.
- Limitaciones técnicas reconocidas explícitamente, como la imposibilidad de expresar en XSD 1.0 una regla de validación condicional entre atributos (Módulo 5), o la decisión de no usar un switch de Capa 3 pese a su mejor rendimiento (Módulo 3).
- Datos y campos marcados como **placeholder** cuando corresponde (por ejemplo, CV pendiente en el Módulo 7, o algunos enlaces también por definir en este mismo repositorio), en lugar de inventarlo para que el documento "parezca" más terminado de lo que está.

Este criterio **no es** un formalismo: es, en sí mismo, una demostración de "cómo se documenta un proyecto de infraestructura en un entorno profesional real".

---

### 7. Tecnologías y herramientas utilizadas

| Área | Herramientas |
| :--- | :--- |
| Redes | Cisco Packet Tracer, VLANs 802.1Q, ACLs, SSH |
| Sistemas | Windows Server 2022 + AD DS, Ubuntu Server, Kali Linux, OpenMediaVault, Sysprep, Clonezilla |
| Seguridad | Wazuh (SIEM), UFW, hardening de acceso de gestión |
| Base de datos | PostgreSQL |
| Documentación / Web | XML, XSD, `xmllint`, HTML5, CSS3 |
| Cloud | AWS (EC2, RDS, S3, ALB, CloudFront, Route 53, IAM) |
| Control de versiones | Git / GitHub |

---

### 8. Sobre el autor

**Nombre completo:** José Gabriel Ternero Sifuentes
**Ciclo Formativo:** Grado Superior de Administración de Sistemas Informáticos en Red
**Máster:** Especialización en Ciberseguridad
**Localidad:** Valencia.
**Portfolio:** [gabts75.github.io/gabrielternero](https://gabts75.github.io/gabrielternero/)
**GitHub:** [github.com/GabTS75](https://github.com/GabTS75)

> Más contexto profesional, investigación de sector y reflexión personal sobre este proyecto en el 👉 [Módulo 7](modulo7-empleabilidad-portfolio/).
