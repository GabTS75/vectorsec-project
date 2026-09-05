# Módulo 1 - Fundamentos de Hardware

## 1. Introducción

**VectorSec** es una empresa de ciberseguridad en fase de crecimiento (8-9 empleados), que ofrece servicios de auditoría, pentesting y formación a pymes. Como parte de su proceso de modernización interna, **este módulo define y justifica el hardware necesario** para dar soporte a sus 6 departamentos, distribuidos en dos plantas, según el modelo de infraestructura definido en el proyecto.

## 2. Equipos cliente por departamento

| Departamento | Nº PCs | Gama | CPU | RAM | Almacenamiento | Justificación |
| --- | :---: | --- | --- | --- | --- | --- |
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
| **SRV-NAS** (Almacenamiento/Backups) | Copias de seguridad de SRV-DC01 y SRV-APP01 | Xeon E-2300 (controladora RAID dedicada) | 16 GB | RAID 5, 5x4 TB (uno como Hot Spare) | Disponibilidad automática ante fallo de disco, sin depender de la supervisión manual constante (ver apartado 4). |

> **Total servidores: 4**

## 4. Almacenamiento y copias de seguridad

- El **SRV-NAS:** (detallado en la tabla anterior) centraliza las copias de seguridad de SRV-DC01 y SRV-APP01, en RAID 5 con disco de reserva en caliente (Hot Spare).
- **Hot Spare:** ante el fallo de un disco, la reconstrucción del array arranca automáticamente, sin esperar a que un administrador lo detecte manualmente — algo especialmente relevante tratándose de una empresa que audita a terceros la protección de sus propios datos.
- **Política de copias:** incremental diaria + copia completa semanal.
- **Capacidad útil real:** 3 × 4 TB = 12 TB (el RAID 5 reserva un disco para paridad, y el quinto disco es el Hot Spare, sin aportar capacidad utilizable).

## 5. Equipamiento de red (resumen)

Requisito mínimo según especificación del proyecto:

- 1 Router Cisco (Cisco 4321 ISR) — puertos GigabitEthernet en ambos extremos, necesarios para los enlaces troncales hacia los switches de distribución.
- 4 Switches gestionables Cisco 2960 (2 de distribución + 2 de acceso, uno por planta)
- 2 Puntos de acceso WiFi, uno para empleados y otro para invitados (SSID: SSID_EMPRESA / SSID_INVITADOS)

### Notas de diseño

`Switches:` Se utiliza el mismo modelo Cisco 2960 en las 4 posiciones (distribución y acceso). Esta decisión fue tomada como una acción intencional, no como una limitación: al unificar el catálogo de equipos de red, simplificamos el mantenimiento, la gestión de repuestos y la configuración — es un criterio propio, puesto que somos una empresa en fase de crecimiento que optimiza recursos sin sacrificar capacidad técnica (el 2960 soporta VLANs, trunking 802.1Q y port-security).

`Puntos de Acceso:` Se emplean dos puntos de acceso físicos independientes, cada uno con un único SSID, en lugar de un único AP con doble SSID. Los modelos de punto de acceso disponibles en CPT no soportan la asignación de VLAN por SSID sobre un mismo equipo — esa función es propia de hardware empresarial más avanzado. La solución con dos AP resuelve el requisito sin necesidad de ese salto de gama, manteniendo el criterio de no sobredimensionar la inversión (detalle técnico completo en el Módulo 3 - Redes).

`Los enlaces:` Para enlazar `PC → switch de acceso` elegímos `FastEthernet` (suficiente para tráfico de oficina); y para los `switch → switch` y `switch → router` seleccionamos `GigabitEthernet`, evitando cuellos de botella en el tráfico inter-VLAN agregado.

> *Detalle completo de configuración y topología en el Módulo 3 - Redes*

## 6. Otros elementos importantes

- **SAI (UPS)** en el **CPD**, para proteger servidores ante cortes eléctricos.
- **Impresora de red compartida** (Recepción/Administración).

## 7. Consideraciones y conclusiones

El hardware seleccionado responde a las necesidades reales de cada departamento, evitando tanto el **infra-equipamiento** (que limitaría la operativa) como el **sobre-equipamiento** injustificado. La incorporación de un servidor de laboratorio aislado y de un NAS con recuperación automática ante fallos no son requisitos mínimos, sino decisiones estratégicas que refuerzan nuestra identidad: **VectorSec**, como empresa de ciberseguridad, aporta seguridad desde la propia base de su infraestructura.

## 8. Guía de montaje de referencia

Para cerrar este módulo con una evidencia física y no solo teórica de las decisiones tomadas, se documenta a continuación el montaje de dos equipos representativos: **SRV-APP01** (el servidor más exigente de la infraestructura) y **PC-DES** (un equipo cliente de gama alta, departamento de Desarrollo). Se eligen estos dos precisamente porque son los que requieren una justificación técnica más sólida en sus componentes — *siendo un montaje "de referencia" tiene mayor valor demostrativo que sea el más exigente de todos los casos*.

### 8.1 Componentes — `SRV-APP01` (servidor de aplicaciones/BD)

| Componente | Elección | Justificación |
| --- | --- | --- |
| CPU | Intel Xeon E-2300 | Soporte ECC, fiabilidad 24/7, adecuado para carga de base de datos continua |
| Placa base | Chipset servidor con soporte RAID por hardware | Necesario para gestionar RAID 10 sin sobrecargar la CPU (a diferencia de un RAID por software) |
| RAM | 64 GB ECC (memoria con corrección de errores) | La ECC evita corrupción silenciosa de datos — crítico al alojar la base de datos de auditorías y clientes |
| Almacenamiento | 4x SSD SATA, configurados en RAID 10 | RAID 10 combina velocidad (striping) y redundancia (mirroring): ideal para una base de datos con lecturas/escrituras frecuentes que no puede permitirse downtime |
| Fuente de alimentación | Redundante (2x PSU) | Un servidor que aloja el activo más crítico de la empresa no puede depender de una única fuente |
| Chasis | Rack 1U/2U con buena ventilación frontal-trasera | Coherente con su ubicación en el CPD junto a los demás servidores |

### 8.2 Componentes — `PC-DES` (equipo cliente, Desarrollo)

| Componente | Elección | Justificación |
| --- | --- | --- |
| CPU | Intel Core i7 (últimas generaciones, 8+ núcleos) | Compilación de código y ejecución de varias máquinas virtuales simultáneas exigen multihilo real |
| Placa base | Gama media, doble canal de RAM, M.2 NVMe | Soporte de la RAM y almacenamiento elegidos sin cuellos de botella |
| RAM | 32 GB (2x16 GB, doble canal) | Permite correr entornos virtualizados (Docker, VMs de pruebas) sin saturar el equipo |
| Almacenamiento | SSD NVMe 1 TB | Los tiempos de compilación y arranque de VMs mejoran drásticamente frente a un SSD SATA |
| Fuente de alimentación | 550-650W, certificación 80 Plus Bronze | Suficiente para la configuración, sin sobrecoste en un equipo cliente |
| Chasis | Torre ATX estándar, buena ventilación | Equipo de sobremesa convencional, sin necesidad de factor de forma especial |

### 8.3 Procedimiento de montaje (breve y conciso)

Este procedimiento de montaje es aplicable para ambos equipos, con ciertos matices, evidentemente por sus propias características de cada uno.

1. **Preparación y seguridad antiestática:**

   Antes de abrir cualquier chasis, ***se utiliza una pulsera antiestática*** conectada a una superficie metálica sin pintar. Este paso es idéntico para servidor y PC — una sola descarga electrostática puede dañar la placa base o la CPU de forma irreversible y silenciosa.

2. **Instalación de la CPU en la placa base:**

   Se abre el retenedor del socket, se alinea la CPU por su marca de referencia (triángulo o muesca dorada) y ***se apoya sin forzar*** — nunca se presiona la CPU hacia el socket. Se cierra el retenedor progresivamente.

3. **Instalación de la memoria RAM:**

   - *PC-DES:* se instalan los 2 módulos en ***los slots de doble canal (dual channel)*** indicados en el manual (normalmente A2 y B2), no en los dos primeros slots consecutivos, para activar realmente el doble canal.
   - *SRV-APP01:* se instalan los módulos ECC **siguiendo la configuración recomendada por el fabricante** para maximizar el ancho de banda entre los canales de memoria del servidor.

4. **Instalación del sistema de refrigeración de la CPU:**

   ***Se aplica una pequeña cantidad de pasta térmica*** (tamaño de un grano de arroz, no una capa completa) antes de fijar el disipador. Una cantidad excesiva no mejora la disipación y puede desbordar hacia el socket.

5. **Fijación de la placa base al chasis:**

   ***Se instalan los separadores metálicos*** (standoffs) en las posiciones correctas antes de atornillar la placa — omitir este paso puede provocar cortocircuitos contra el chasis.

6. **Instalación del almacenamiento:**

   - *PC-DES:* el **SSD NVMe** se instala directamente en el ***slot M.2*** de la placa base.
   - *SRV-APP01:* los **4 SSD** se instalan en las ***bahías hot-swap frontales del chasis***, conectados a la controladora RAID por hardware — no directamente a la placa base.

7. **Conexión de la fuente de alimentación:**

   ***Se conectan los cables de placa base*** (24 pines + 4/8 pines de CPU), almacenamiento y, en el caso del servidor, ambas fuentes redundantes a circuitos eléctricos idealmente independientes (o al menos a la misma línea protegida por el SAI del CPD).

8. **Cableado y gestión de cables:**

   ***Se agrupan y sujetan los cables sobrantes*** para no obstruir el flujo de aire — especialmente importante en el servidor, donde la ventilación frontal-trasera depende de un flujo de aire limpio y sin obstáculos.

9. **Primer encendido y verificación POST:**

   ***Se enciende el equipo sin sistema operativo instalado*** todavía, únicamente para comprobar que la POST (Power-On Self-Test) se completa sin pitidos de error y que la BIOS/UEFI reconoce toda la RAM y el almacenamiento instalado.

10. **Configuración específica del RAID (solo SRV-APP01):**

    ***Se accede a la utilidad de la controladora RAID durante el arranque*** y se configura el array en modo **RAID 10**, verificando que los 4 discos aparecen correctamente agrupados y que el array se inicializa sin errores antes de proceder a instalar el sistema operativo (esto se completará en el Módulo 2).

11. **Verificación final de operatividad:**

    - Comprobación de temperaturas en reposo desde la BIOS/UEFI (dentro de rango normal, sin picos anómalos)
    - Confirmación de que la RAM funciona en modo dual channel (mediante la información de la BIOS o `CPU-Z` una vez instalado el sistema operativo)
    - *SRV-APP01:* confirmación de que el array RAID 10 aparece como un único volumen lógico saludable
    - Ambos equipos quedan **listos y operativos** para la instalación del sistema operativo correspondiente (Módulo 2 - Sistemas Operativos)

### 8.4 Checklist de verificación previa a la entrega

- [ ] POST completada sin errores ni pitidos
- [ ] RAM total reconocida coincide con la instalada
- [ ] Almacenamiento reconocido en BIOS/UEFI (y RAID inicializado, en el caso del servidor)
- [ ] Temperaturas en reposo dentro de rango normal
- [ ] Sin cables sueltos que obstruyan la ventilación
- [ ] Fuente(s) de alimentación conectadas y estables

Con este montaje documentado, se pretende manifestar de inicio la coherencia y consistencia con el resto del proyecto, justificando cada elección técnica, puesto que el proyecto no sólo se sustentará con "tablas de especificaciones", si no que incluye evidencia de que **las decisiones de hardware** se han razonado también **a nivel de ensamblaje físico**.
