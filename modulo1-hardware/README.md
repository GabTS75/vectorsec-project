# Módulo 1 - Fundamentos de Hardware

## 1. Introducción

**VectorSec** es una empresa de ciberseguridad en fase de crecimiento (8-9 empleados), que ofrece servicios de auditoría, pentesting y formación a pymes. Como parte de su proceso de modernización interna, este módulo define y justifica el hardware necesario para dar soporte a sus 6 departamentos, distribuidos en dos plantas, según el modelo de infraestructura definido en el proyecto.

## 2. Equipos cliente por departamento

| Departamento | Nº PCs | Gama | CPU | RAM | Almacenamiento | Justificación |
| --- | --- | --- | --- | --- | --- | --- |
| **Recepción** | 2 | Básica-Media | Intel Core i3 | 8 GB | SSD 256 GB | Tareas ofimáticas ligeras: agenda, llamadas, gestión de visitas. |
| **Administración** | 2 | Media | Intel Core i5 | 8 GB | SSD 256 GB | Ofimática, facturación, ERP ligero. |
| **Dirección** | 2 | Media-Alta | Intel Core i5 | 16 GB | SSD 512 GB | Informes, videoconferencias con clientes, análisis de KPIs. |
| **Desarrollo** | 2 | Alta | Intel Core i7 | 32 GB | SSD 1 TB | Compilación de código, máquinas virtuales, contenedores para herramientas de auditoría propias. |
| **Soporte Técnico** | 2 | Media-Alta | Intel Core i5/i7 | 16 GB | SSD 512 GB | Monitorización, acceso remoto a clientes, análisis de logs y alertas del SOC. |
| **Aula de Formación** | 6 | Media | Intel Core i5 | 16 GB | SSD 256 GB | Laboratorio de prácticas de pentesting ético y cursos in-company. Uso rotativo, no personal fijo. |

> **Total equipos cliente: 16**

## 3. Servidores

| Servidor | Función | CPU | RAM | Almacenamiento | Justificación |
| --- | --- | --- | --- | --- | --- |
| **SRV-DC01** (Dominio) | Active Directory, autenticación, políticas de grupo | Xeon E-2300 | 32 GB | RAID 1 SSD 512 GB | Control centralizado de usuarios y permisos — imprescindible en una empresa de seguridad. |
| **SRV-APP01** (Aplicaciones/BD) | Software de gestión interna + base de datos de auditorías y clientes | Xeon E-2300 | 64 GB | RAID 10 SSD 1 TB | Centraliza el activo más crítico: informes y datos de clientes (enlaza con Módulo 4). |
| **SRV-LAB01** (Laboratorio/SOC, aislado) | Entorno de pentesting, análisis de malware controlado, SIEM básico | Xeon E-2300 | 32 GB | SSD 512 GB (aislado) | Requiere aislamiento total de red — justifica la segmentación y ACLs del Módulo 3. |

> **Total servidores: 3**

## 4. Almacenamiento y copias de seguridad

- **NAS dedicado**, RAID 5, 5x4 TB (uno de ellos como Hot Spare) para backups de SRV-DC01 y SRV-APP01.
- Política de copias: incremental diaria + copia completa semanal.
- Siendo una empresa que audita la seguridad de terceros debemos, por coherencia, proteger primero nuestros propios datos.

## 5. Equipamiento de red (resumen)

Requisito mínimo según especificación del proyecto:

- 1 Router Cisco (Cisco 4321 ISR) — puertos GigabitEthernet en ambos extremos, necesarios para los enlaces troncales hacia los switches de distribución.
- 4 Switches gestionables Cisco 2960 (2 de distribución + 2 de acceso, uno por planta)
- 2 Puntos de acceso WiFi, uno para empleados y otro para invitados (SSID: SSID_EMPRESA / SSID_INVITADOS)

**Nota de diseño:** se utiliza el mismo modelo Cisco 2960 en las 4 posiciones (distribución y acceso). Esta decisión fue tomada como una acción intencional, no como una limitación: Al unificar el catálogo de equipos de red, simplificamos el mantenimiento, la gestión de repuestos y la configuración — es un criterio propio, puesto que somos una empresa en fase de crecimiento que optimiza recursos sin sacrificar capacidad técnica (el 2960 soporta VLANs, trunking 802.1Q y port-security).

Los enlaces `PC → switch de acceso` usan `FastEthernet` (suficiente para tráfico de oficina); los enlaces `switch → switch` y `switch → router` usan `GigabitEthernet`, evitando cuellos de botella en el tráfico inter-VLAN agregado.

> *Detalle completo de configuración y topología en el Módulo 3 - Redes*

## 6. Otros elementos

- **SAI (UPS)** en el **CPD**, para proteger servidores ante cortes eléctricos.
- **Impresora de red compartida** (Recepción/Administración).

## 7. Conclusiones

El hardware seleccionado responde a las necesidades reales de cada departamento, evitando tanto el **infra-equipamiento** (que limitaría la operativa) como el **sobre-equipamiento** injustificado. La incorporación de **un tercer servidor de laboratorio aislado** no es un requisito mínimo, sino una decisión estratégica que refuerza nuestra identidad, **VectorSec** como empresa de ciberseguridad aporta seguridad desde la propia base de su infraestructura.
