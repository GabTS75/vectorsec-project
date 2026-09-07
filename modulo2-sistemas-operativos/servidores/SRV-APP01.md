# SRV-APP01 — Servidor de Aplicaciones y Base de Datos (Ubuntu Server 22.04 LTS + PostgreSQL)

## 1. Análisis del sistema operativo

| Parámetro | Valor | Origen / Justificación |
| :--- | :--- | :--- |
| Rol | Motor de base de datos + aplicación de gestión interna | Aloja el activo más crítico de VectorSec: informes de auditoría y datos de clientes (enlaza con el Módulo 4) |
| Sistema operativo | Ubuntu Server 22.04 LTS | Se descarta Windows Server + SQL Server por coste de licencias y por coherencia con el perfil de una empresa de ciberseguridad, donde el software abierto y auditable es una práctica habitual en sus propios sistemas críticos |
| Motor de base de datos | PostgreSQL 14 | Robusto, gratuito, ampliamente documentado, con control de acceso granular (`pg_hba.conf`) adecuado para un servidor que solo debe ser accesible desde determinadas VLANs |
| Nombre de host | `SRV-APP01` | Consistente con el diagrama de red del Módulo 3 |
| IP estática | 192.168.60.11 / 255.255.255.0 | Tabla de direccionamiento, Módulo 3 |
| Gateway | 192.168.60.1 | Subinterfaz ROAS (VLAN 60) |
| DNS | 192.168.60.10 | Apunta a `SRV-DC01`, que ya aloja la zona `vectorsec.local` (Módulo 2, documento anterior) |

>📌 **Sobre no unir este servidor al dominio Active Directory:** a diferencia de los PCs cliente, `SRV-APP01` no requiere unirse al dominio Windows — *Linux gestiona su propia autenticación local y de base de datos de forma independiente*.
>
> Forzar la integración con **AD** (vía SSSD/Winbind) añadiría complejidad sin un beneficio real para este servidor en la fase actual de `VectorSec`; se documenta como posible mejora futura si se centralizara la autenticación de administradores Linux más adelante.

---

## 2. Plan de implantación

- **Método:** instalación manual, individualizada (rol único, sin equivalente a clonar).
- **Orden de tareas:** `instalación del SO` → `configuración de red` → `actualización del sistema` → `instalación de PostgreSQL` → `creación de base de datos y usuario de aplicación` → `restricción de acceso por red` (`pg_hba.conf` + **firewall** `ufw`) → `verificación`.
- **Entorno:** máquina virtual (VirtualBox / Hyper-V), `2 vCPU` recomendado, `4 GB` RAM mínimo, `40 GB` de disco (ampliable según crecimiento de la base de datos).

---

## 3. Instalación del sistema operativo

### Paso 1 — Arranque desde la ISO

**Acción:** crear la máquina virtual, montar la ISO de ***Ubuntu Server 22.04 LTS*** y arrancar.

**Resultado esperado:** menú de arranque del instalador (Subiquity) con la opción *Try or Install Ubuntu Server*.

**Verificación:** el instalador detecta correctamente el disco virtual y la interfaz de red de la VM antes de continuar.

---

### Paso 2 — Idioma, teclado y red

**Acción:** seleccionar idioma ***English*** (habitual dejar el sistema base en inglés para mayor compatibilidad de documentación técnica) → distribución de teclado ***Spanish*** → en la pantalla de red, dejar de momento la configuración automática por DHCP (se fijará la IP estática después de la instalación).

**Resultado esperado:** el instalador muestra una IP temporal asignada por DHCP en la interfaz detectada (ej. `enp0s3`).

**Verificación:** la interfaz de red aparece como `UP` en la pantalla de resumen de red del instalador.

---

### Paso 3 — Particionado y usuario inicial

**Acción:** aceptar el particionado guiado de disco completo → en la pantalla *Profile setup*, crear el usuario administrador local (`vectorsec-admin`) → en *SSH Setup*, marcar **Install OpenSSH server** (necesario para la administración remota posterior).

**Resultado esperado:** pantalla de confirmación del particionado (*Filesystem summary*) mostrando la partición raíz (`/`) sobre el disco virtual completo, seguida de la instalación de paquetes base.

**Verificación:** al finalizar, el instalador muestra *"Install complete!"* y solicita reiniciar (*Reboot Now*).

---

### Paso 4 — Primer acceso

**Acción:** retirar la ISO virtual, reiniciar y acceder con el usuario `vectorsec-admin` creado en el paso anterior.

**Resultado esperado:** prompt de inicio de sesión en modo texto (`SRV-APP01 login:`).

**Verificación:**

```bash
lsb_release -a
```

Debe mostrar `Ubuntu 22.04.x LTS` en la línea `Description`.

---

## 4. Configuración inicial post-instalación

### Paso 5 — Configurar IP estática (Netplan)

**Acción:**

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Editar con el siguiente contenido:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 192.168.60.11/24
      routes:
        - to: default
          via: 192.168.60.1
      nameservers:
        addresses:
          - 192.168.60.10
```

Aplicar:

```bash
sudo netplan apply
```

**Resultado esperado:** el comando no devuelve texto si aplica correctamente.

**Verificación:**

```bash
ip a show enp0s3
```

Debe mostrar `inet 192.168.60.11/24` en la interfaz. Comprobar conectividad:

```bash
ping -c 3 192.168.60.1
```

3 de 3 paquetes recibidos — confirma la integración con el router ROAS del Módulo 3.

---

### Paso 6 — Cambiar el nombre del equipo

**Acción:**

```bash
sudo hostnamectl set-hostname SRV-APP01
```

**Resultado esperado:** sin salida en consola.

**Verificación:**

```bash
hostnamectl
```

El campo `Static hostname` debe mostrar `SRV-APP01`.

---

### Paso 7 — Actualizar el sistema

**Acción:**

```bash
sudo apt update && sudo apt upgrade -y
```

**Resultado esperado:** lista de paquetes actualizados finalizando con un mensaje del tipo `X upgraded, 0 newly installed, 0 to remove`.

**Verificación:**

```bash
apt list --upgradable
```

Debe devolver una lista vacía (sin paquetes pendientes).

---

## 5. Instalación y configuración de PostgreSQL

### Paso 8 — Instalar PostgreSQL

**Acción:**

```bash
sudo apt install postgresql postgresql-contrib -y
```

**Resultado esperado:** el gestor de paquetes instala `postgresql`, `postgresql-14` y dependencias, finalizando sin errores (`Setting up postgresql-14 ...`).

**Verificación:**

```bash
sudo systemctl status postgresql
```

Debe mostrar `Active: active (exited)` (el servicio maestro delega en `postgresql@14-main`, que debe aparecer como `active (running)` con:

```bash
sudo systemctl status postgresql@14-main
```

---

### Paso 9 — Crear la base de datos y el usuario de la aplicación

**Acción:**

```bash
sudo -u postgres psql
```

Dentro del prompt `psql`:

```sql
CREATE DATABASE vectorsec_gestion;
CREATE USER app_vectorsec WITH ENCRYPTED PASSWORD 'App_V3ct0rS3c!';
GRANT ALL PRIVILEGES ON DATABASE vectorsec_gestion TO app_vectorsec;
\q
```

**Resultado esperado:**

```sql
CREATE DATABASE
CREATE ROLE
GRANT
```

**Verificación:**

```bash
sudo -u postgres psql -l
```

`vectorsec_gestion` debe aparecer listada, con `app_vectorsec` como uno de los roles con privilegios (columna `Access privileges`).

---

### Paso 10 — Permitir conexiones remotas controladas

**Acción — habilitar escucha de red:**

```bash
sudo nano /etc/postgresql/14/main/postgresql.conf
```

Modificar:

```bash
listen_addresses = 'localhost,192.168.60.11'
```

**Acción — restringir el origen permitido:**

```bash
sudo nano /etc/postgresql/14/main/pg_hba.conf
```

Añadir al final:

```bash
# Acceso desde Administración (VLAN 10) y desde el propio servidor
host    vectorsec_gestion   app_vectorsec   192.168.10.0/24    scram-sha-256
host    vectorsec_gestion   app_vectorsec   192.168.60.11/32   scram-sha-256
```

Reiniciar el servicio:

```bash
sudo systemctl restart postgresql
```

> 📌 **Justificación de este acceso restringido:** coherente con la política ya establecida en las ACLs del Módulo 3 ("Administración sí puede acceder a Servidores") — *aquí se traslada esa misma política al propio motor de base de datos, en lugar de confiar únicamente en el filtrado de red*.
>
> **Es una capa de seguridad adicional (defensa en profundidad):** aunque alguien lograra saltarse la ACL del router, PostgreSQL seguiría rechazando cualquier origen no autorizado explícitamente.

**Resultado esperado:** el reinicio del servicio no devuelve errores.

**Verificación:**

```bash
sudo ss -tlnp | grep 5432
```

Debe mostrar el proceso `postgres` escuchando en `192.168.60.11:5432`, además de `127.0.0.1:5432`.

---

### Paso 11 — Configurar el firewall (UFW)

**Acción:**

```bash
sudo ufw allow from 192.168.10.0/24 to any port 5432 proto tcp
sudo ufw allow OpenSSH
sudo ufw enable
```

**Resultado esperado:**

```bash
Firewall is active and enabled on system startup
```

**Verificación:**

```bash
sudo ufw status verbose
```

Debe listar la regla `5432/tcp ALLOW  192.168.10.0/24` y `22/tcp (OpenSSH) ALLOW Anywhere` — sin ninguna otra regla abierta.

---

## 6. Verificación de funcionamiento

### Paso 12 — Prueba de conexión desde un cliente de la red permitida

**Acción (desde un equipo de Administración, VLAN 10, con cliente `psql` instalado):**

```bash
psql -h 192.168.60.11 -U app_vectorsec -d vectorsec_gestion
```

**Resultado esperado:** solicitud de contraseña, seguida del prompt `vectorsec_gestion=>` tras introducirla correctamente.

**Verificación:** la conexión se establece sin errores de `timeout` ni de `password authentication failed`.

---

### Paso 13 — Prueba de bloqueo desde una red no autorizada

**Acción (desde un equipo de Desarrollo, VLAN 30):**

```bash
psql -h 192.168.60.11 -U app_vectorsec -d vectorsec_gestion
```

**Resultado esperado:** la conexión debe fallar, ya sea por el bloqueo de la ACL del router (Módulo 3 — Desarrollo no tiene regla de bloqueo directa hacia Servidores, por lo que en este caso el filtrado real lo aporta `pg_hba.conf`) o por rechazo explícito de PostgreSQL.

**Verificación:** el mensaje de error esperado es:

```bash
psql: error: connection to server at "192.168.60.11", port 5432 failed:
FATAL: no pg_hba.conf entry for host "192.168.30.X", ...
```

Este resultado confirma que la capa de seguridad a nivel de base de datos funciona de forma independiente a las ACLs de red — es la prueba clave de la defensa en profundidad mencionada en el Paso 10.

---

## 7. Checklist de verificación final

- [ ] Ubuntu Server 22.04 LTS instalado, `hostname` = `SRV-APP01`
- [ ] IP estática 192.168.60.11/24 configurada vía Netplan, gateway respondiendo
- [ ] DNS apuntando a `SRV-DC01` (192.168.60.10)
- [ ] Sistema actualizado sin paquetes pendientes
- [ ] PostgreSQL 14 instalado y en estado `active (running)`
- [ ] Base de datos `vectorsec_gestion` y usuario `app_vectorsec` creados
- [ ] `pg_hba.conf` restringido a VLAN 10 (Administración) y localhost
- [ ] Firewall UFW activo, solo puertos 22 (SSH) y 5432 (solo desde VLAN 10) abiertos
- [ ] Conexión exitosa desde Administración (VLAN 10)
- [ ] Conexión rechazada desde Desarrollo (VLAN 30)

---

## 8. Próximos pasos relacionados

- El diseño completo del esquema de la base de datos `vectorsec_gestion` (tablas de clientes, auditorías, informes) se desarrollará en el **Módulo 4 — Gestión de Base de Datos**.
- El resumen de todos los servicios activos en la infraestructura se consolida en [`servicios.md`](../servicios.md).
- La gestión de usuarios administradores de este servidor (Linux, no AD) se documenta en [`usuarios-y-permisos.md`](../usuarios-y-permisos.md), en su apartado específico de servidores Linux.
