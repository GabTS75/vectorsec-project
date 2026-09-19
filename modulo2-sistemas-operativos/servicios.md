# Resumen de servicios — Infraestructura VectorSec

Este documento consolida, en una única vista, todos los servicios activos en la infraestructura de VectorSec tras la implantación del Módulo 2, junto con el equipo que los ejecuta y su relación con los demás módulos del proyecto.

## 1. Servicios por servidor

| Servidor | Sistema operativo | Servicio | Puerto(s) | Alcance de red permitido | Módulo relacionado |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **SRV-DC01** | Windows Server 2022 | Active Directory Domain Services (AD DS) | 389 (LDAP), 88 (Kerberos), 445 (SMB) | Toda la red interna (autenticación de dominio) | Módulo 2 |
| **SRV-DC01** | Windows Server 2022 | DNS | 53 | Toda la red interna | Módulo 2, Módulo 3 (sustituye la referencia DNS de los pools DHCP) |
| **SRV-APP01** | Ubuntu Server 22.04 LTS | PostgreSQL (base de datos `vectorsec_gestion`) | 5432 | VLAN 10 (Administración) + localhost | Módulo 2, Módulo 4 (diseño del esquema de BD) |
| **SRV-APP01** | Ubuntu Server 22.04 LTS | SSH (administración remota) | 22 | Restringido por firewall UFW | Módulo 2 |
| **SRV-LAB01** | Kali Linux | Wazuh Manager + Indexer (SIEM) | 1514-1515 (agentes), 9200 (indexer) | Interno (localhost / agentes autorizados) | Módulo 2 |
| **SRV-LAB01** | Kali Linux | Wazuh Dashboard (interfaz web) | 443 | VLAN 40 (Soporte Técnico / SOC) | Módulo 2 |
| **SRV-LAB01** | Kali Linux | SSH (administración remota) | 22 | VLAN 40 (Soporte Técnico / SOC) | Módulo 2 |
| **SRV-NAS** | OpenMediaVault (Debian) | SMB/CIFS (recursos compartidos) | 445 | VLAN 60 (Servidores) + VLAN 10 (Administración) | Módulo 2 |
| **SRV-NAS** | OpenMediaVault (Debian) | Panel web de administración | 80 / 443 | VLAN 60, acceso administrativo | Módulo 2 |
| **SRV-NAS** | OpenMediaVault (Debian) | Tareas programadas de backup (rsync) | — (interno) | N/A (proceso local) | Módulo 1 (política de copias definida) |

## 2. Servicios por equipo cliente

| Grupo de equipos | Sistema operativo | Servicios/roles relevantes |
| :--- | :--- | :--- |
| Los 16 PCs (Recepción, Administración, Dirección, Desarrollo, Soporte, Formación) | Windows 11 Pro | Cliente de dominio (autenticación contra `SRV-DC01`), cliente DHCP (Módulo 3), navegador y suite ofimática |
| Aula de Formación (6 PCs) | Windows 11 Pro + VirtualBox | Adicionalmente: hipervisor VirtualBox con VM de Kali Linux para prácticas de pentesting bajo demanda |

## 3. Servicios que permanecen en la capa de red (no migrados a servidores en este módulo)

| Servicio | Ubicación | Motivo de no migrarlo |
| :--- | :--- | :--- |
| DHCP | Router `R1-ROAS` (Módulo 3) | Ya está implementado, probado y funcionando correctamente desde el Módulo 3; moverlo a Windows Server no aporta ningún beneficio técnico real en la fase actual de VectorSec — sería un cambio sin justificación, rompiendo algo que ya funciona |

## 4. Matriz de dependencias entre servicios

Esta tabla resume qué servicio depende de qué otro para funcionar correctamente — útil para entender el orden de arranque de la infraestructura y para diagnosticar fallos en cascada:

| Servicio | Depende de |
| :--- | :--- |
| Unión de equipos cliente al dominio | DNS (`SRV-DC01`) + AD DS (`SRV-DC01`) + DHCP (Módulo 3) |
| Aplicación de GPOs | AD DS (`SRV-DC01`) |
| Conexión de Administración a PostgreSQL | Red VLAN 10 → VLAN 60 permitida (Módulo 3) + PostgreSQL (`SRV-APP01`) |
| Acceso de Soporte al dashboard de Wazuh | Red VLAN 40 → VLAN 70 permitida (Módulo 3) + Wazuh Dashboard (`SRV-LAB01`) |
| Backups de `SRV-DC01` y `SRV-APP01` | Recurso SMB de `SRV-NAS` accesible desde VLAN 60 |
| Resolución de nombres en toda la red | DNS (`SRV-DC01`), referenciado en los pools DHCP del router |

## 5. Checklist de consolidación

- [x] Todos los servicios de los 4 servidores documentados individualmente en `servidores/`
- [x] Servicios de equipos cliente documentados en `equipos-cliente.md`
- [x] Decisión de no migrar el DHCP justificada y no contradicha en ningún otro documento
- [x] Las restricciones de red de cada servicio son coherentes con las ACLs ya aplicadas en el Módulo 3
- [x] Ningún servicio queda "huérfano" (sin equipo asignado) ni duplicado entre servidores

## 6. Próximos pasos relacionados

- El README principal del módulo, que enlaza a todos estos documentos con una visión general, se encuentra en [`README.md`](README.md).
