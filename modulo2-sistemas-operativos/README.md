# Módulo 2 — Implantación de Sistemas Operativos

**Empresa:** `VectorSec`

**Sector:** `Ciberseguridad` — `auditoría, pentesting y formación en seguridad informática`

**Entorno de trabajo:** documentación conceptual detallada, verificable en VirtualBox/Hyper-V

## 1. Introducción

Con el hardware definido (Módulo 1) y la red diseñada, configurada y verificada (Módulo 3), este módulo decide, implanta y documenta el software base de `VectorSec`: *qué sistema operativo lleva cada equipo, qué servicios ejecuta y cómo se gestionan sus usuarios y permisos*.

El resultado es un entorno **mixto Windows + Linux**, decisión que responde tanto a criterios técnicos (cada sistema se elige por su idoneidad para el rol que desempeña) como a la propia identidad de `VectorSec` como empresa de ciberseguridad, donde el uso de software abierto y auditable en sistemas propios es una práctica coherente con lo que la empresa audita en sus clientes.

---

## 2. Análisis del sistema operativo por equipo

| Equipo | Sistema operativo | Rol |
| :--- | :--- | :--- |
| SRV-DC01 | Windows Server 2022 Standard | Controlador de dominio (AD DS) + DNS |
| SRV-APP01 | Ubuntu Server 22.04 LTS | Base de datos (PostgreSQL) + aplicación de gestión |
| SRV-LAB01 | Kali Linux | Laboratorio de pentesting + SIEM (Wazuh) |
| SRV-NAS | OpenMediaVault | Almacenamiento RAID 5 + Hot Spare, backups |
| 16 PCs cliente | Windows 11 Pro | Estaciones de trabajo, unidas al dominio |
| 6 PCs del Aula (adicional) | Windows 11 Pro + VirtualBox | Formación general + prácticas de pentesting mediante VM de Kali |

La justificación detallada de cada elección se encuentra en el apartado 1 de cada documento individual (enlaces en el apartado 5).

---

## 3. Plan de implantación — visión general

El orden de implantación sigue una lógica de dependencias, no un orden arbitrario: cada paso necesita que el anterior esté funcionando.

```text
1. SRV-DC01 (Windows Server + AD DS + DNS)
      ↓ (el resto de equipos necesita el dominio y el DNS ya operativos)
2. SRV-APP01, SRV-LAB01, SRV-NAS (servidores Linux, independientes entre sí)
      ↓
3. Equipo de referencia (PC-ADM1) → generalización (Sysprep) → clonación (Clonezilla)
      ↓
4. Despliegue de la imagen en los 15 equipos cliente restantes
      ↓
5. Unión de los 16 equipos al dominio vectorsec.local
      ↓
6. Estructura de OUs, grupos, usuarios y GPOs en Active Directory
      ↓
7. Permisos NTFS sobre recursos compartidos, basados en los grupos ya creados
```

Los servidores Linux (`SRV-APP01`, `SRV-LAB01`, `SRV-NAS`) se implantan en paralelo tras `SRV-DC01`, ya que no dependen entre sí ni requieren estar unidos al dominio (decisión justificada individualmente en cada documento).

### 3.1 Método de instalación

| Grupo | Método | Motivo |
| :--- | :--- | :--- |
| 4 servidores | Instalación manual, individualizada | Cada uno tiene un rol y una configuración de servicios distinta — *no hay nada que clonar entre ellos* |
| 16 PCs cliente | Imagen de referencia (Modo Auditoría + Sysprep) + clonación (Clonezilla) | Mismo sistema operativo y base común en los 16 equipos — *instalar manualmente 16 veces repetiría el mismo trabajo sin necesidad* |

---

## 4. Coherencia con los módulos ya construidos

Este módulo no se ha desarrollado de forma aislada — *cada decisión reutiliza o refuerza algo ya definido en módulos anteriores*:

- **Direccionamiento IP:** todos los servidores usan las IPs ya fijadas en la tabla de direccionamiento del Módulo 3, sin ninguna reasignación.
- **Nombre de dominio:** `vectorsec.local` ya se había introducido en el Módulo 3 (configuración SSH de los switches) y se reutiliza aquí como dominio de Active Directory, en lugar de introducir un segundo nombre de dominio sin motivo.
- **Defensa en profundidad:** las políticas de acceso ya aplicadas por ACL en el router (Módulo 3) se refuerzan a nivel de host en `SRV-APP01` (`pg_hba.conf`), `SRV-LAB01` (firewall UFW) y `SRV-NAS` (restricción SMB por red) — *la misma política de seguridad, aplicada en dos capas independientes*.
- **DHCP:** se decide explícitamente no migrarlo a Windows Server, por estar ya implementado y verificado en el Módulo 3 (detalle en `servicios.md`, apartado 3).
- **Segmentación por departamento:** la estructura de OUs y grupos de Active Directory replica la misma segmentación por departamento ya usada en VLANs (Módulo 3) y en hardware (Módulo 1) — *mismo criterio organizativo en toda la infraestructura*.

---

## 5. Documentación del módulo

| Documento | Contenido |
| :--- | :--- |
| [`servidores/SRV-DC01.md`](servidores/SRV-DC01.md) | Windows Server 2022, Active Directory Domain Services y DNS |
| [`servidores/SRV-APP01.md`](servidores/SRV-APP01.md) | Ubuntu Server, PostgreSQL, defensa en profundidad a nivel de base de datos |
| [`servidores/SRV-LAB01.md`](servidores/SRV-LAB01.md) | Kali Linux, Wazuh (SIEM), verificación cruzada con las ACLs del Módulo 3 |
| [`servidores/SRV-NAS.md`](servidores/SRV-NAS.md) | OpenMediaVault, RAID 5 con Hot Spare, recursos compartidos y backups |
| [`equipos-cliente.md`](equipos-cliente.md) | Windows 11 Pro en los 16 PCs: Modo Auditoría, Sysprep, Clonezilla, unión al dominio |
| [`usuarios-y-permisos.md`](usuarios-y-permisos.md) | Estructura de OUs, grupos de seguridad, usuarios, GPOs y permisos NTFS |
| [`servicios.md`](servicios.md) | Tabla consolidada de todos los servicios activos, con su matriz de dependencias |

---

## 6. Conclusiones

La implantación de sistemas operativos de VectorSec combina Windows y Linux según el rol de cada equipo, evitando tanto la *homogeneidad forzada* (todo Windows, o todo Linux, "porque sí") como la *dispersión sin criterio*. Cada decisión de sistema operativo, método de despliegue y configuración de seguridad queda justificada y, siempre que ha sido posible, verificada con una prueba concreta y reproducible — *desde el bloqueo de acceso no autorizado a PostgreSQL, hasta la comprobación de que el laboratorio aislado no puede iniciar tráfico hacia el resto de la red ni siquiera a nivel de sistema operativo*.

Como en los módulos anteriores, las limitaciones del entorno de simulación (imposibilidad de provocar un fallo de disco real en el NAS, por ejemplo) se han documentado de forma explícita en lugar de omitirse, *manteniendo la misma coherencia y honestidad técnica aplicada durante todo el proyecto*.

---

## 7. Entregables

- Los 7 documentos listados en el apartado 5, organizados en la carpeta `modulo2-sistemas-operativos/`
- Capturas de configuración y verificación (carpeta `/imgs`, a incorporar si se implementa siguiendo cada guía paso a paso)
