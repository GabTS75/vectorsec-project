# SRV-NAS — Servidor de Almacenamiento y Copias de Seguridad (OpenMediaVault)

## 1. Análisis del sistema operativo

| Parámetro | Valor | Origen / Justificación |
| :--- | :--- | :--- |
| Rol | Almacenamiento centralizado, RAID 5 con Hot Spare, backups de SRV-DC01 y SRV-APP01 | Definido y justificado desde el Módulo 1 |
| Sistema operativo | OpenMediaVault (basado en Debian) | Solución NAS madura, gratuita, con interfaz web de gestión y soporte nativo de RAID por software (`mdadm`), pensada específicamente para este rol — no se usa un SO de propósito general |
| Nombre de host | `SRV-NAS` | Consistente con el diagrama de red del Módulo 3 |
| IP estática | 192.168.60.12 / 255.255.255.0 | Tabla de direccionamiento, Módulo 3 |
| Gateway | 192.168.60.1 | Subinterfaz ROAS (VLAN 60) |
| DNS | 192.168.60.10 | Apunta a `SRV-DC01` |
| Configuración de disco | RAID 5, 5 discos de 4 TB (uno como Hot Spare) | Definido en el Módulo 1 — 3 discos activos + 1 paridad + 1 hot spare |

---

## 2. Plan de implantación

- **Método:** instalación manual, individualizada (único NAS de la infraestructura).
- **Orden de tareas:** `instalación del SO base` (Debian mínimo) → `instalación de OpenMediaVault` → `configuración de red` → `creación del array RAID 5 con Hot Spare` → `creación de recursos compartidos (SMB)` → `configuración de tareas de backup programadas` → `restricción de acceso` → `verificación`.
- **Entorno:** máquina virtual con **5 discos virtuales adicionales** de `4 TB` cada uno (además del disco de sistema), `2 vCPU`, `4 GB` RAM mínimo, `20 GB` de disco para el sistema operativo (independiente de los discos del array).

> 📌 **Nota importante sobre el entorno virtualizado:** al tratarse de discos virtuales, la "reconstrucción automática" del Hot Spare ante un fallo real de disco **no puede demostrarse** con un fallo físico genuino — *se documenta el proceso y, si se desea evidenciarlo, se simula marcando un disco como fallido manualmente desde la propia interfaz de OpenMediaVault (ver Paso 12)*.

---

## 3. Instalación del sistema operativo

### Paso 1 — Arranque desde la ISO

**Acción:** crear la máquina virtual con **6 discos virtuales** (1 de sistema + 5 para el array), montar la ISO de *OpenMediaVault* (instalador basado en el instalador de Debian) y arrancar.

**Resultado esperado:** menú de arranque con la opción **Install** (o **Graphical Install**).

**Verificación:** el instalador detecta los 6 discos virtuales por separado en la pantalla de particionado — *es muy importante que confirmemos aquí el disco correspondiente, antes de continuar, para no instalar el sistema sobre el disco equivocado*.

---

### Paso 2 — Idioma, ubicación, teclado y red

**Acción:** ***Español*** → ***España*** → teclado ***Español*** → nombre de host `SRV-NAS` → dominio: dejar en blanco.

**Resultado esperado:** el instalador solicita a continuación la contraseña de `root` y la creación de un usuario estándar.

**Verificación:** ninguna, visualizamos pantalla informativa.

---

### Paso 3 — Contraseñas y usuario

**Acción:**

- Contraseña de `root`: contraseña robusta (ej. `NAS-R00t-V3ct0rS3c!`)
- Nombre completo del nuevo usuario: `VectorSec NAS Admin`
- Nombre de usuario: `nas-admin`
- Contraseña del usuario: contraseña robusta y distinta a la de `root` (ej. `NAS-Adm1n-V3ct0rS3c!`)

**Resultado esperado:** el instalador confirma ambas contraseñas (solicitando cada una dos veces) y avanza al particionado.

**Verificación:** si alguna contraseña no coincide en su confirmación, el instalador lo indicará y en consecuencia no permite avanzar — *mismo comportamiento ya visto en `SRV-LAB01`*.

---

### Paso 4 — Particionado (solo el disco de sistema)

**Acción:** seleccionar **Guided - use entire disk** → elegir **únicamente el disco de `20 GB` destinado al sistema operativo** (no seleccionar ninguno de los 5 discos de 4 TB, que se reservan vacíos para el array RAID) → esquema **All files in one partition**.

**Resultado esperado:** el instalador copia los archivos base del sistema y, al finalizar, muestra *"Installation complete"*.

**Verificación:** especialmente importante en este paso — *revisar el resumen de particiones antes de confirmar, asegurando que los 5 discos de 4 TB **no aparecen** en la lista de particiones creadas*.

---

### Paso 5 — Instalación de OpenMediaVault

**Acción:** tras el primer reinicio, acceder por SSH o consola con el usuario `root`, y ejecutar el script de instalación:

```bash
wget -O - https://raw.githubusercontent.com/openmediavault/installScript/master/install | bash
```

**Resultado esperado:** el script instala el repositorio de OpenMediaVault, sus dependencias y el paquete principal, finalizando con un reinicio automático del sistema.

**Verificación:** tras el reinicio, acceder desde un navegador a `http://<IP-temporal-por-DHCP>` (no olvides anotar el IP que muestra al finalizar la instalación, es la que usarás inicialmente) — *cargará la pantalla de login de OpenMediaVault (usuario por defecto `admin`, contraseña por defecto `openmediavault`, **a cambiar en el primer acceso**)*.

---

## 4. Configuración inicial post-instalación

### Paso 6 — Cambiar la contraseña por defecto del panel web

**Acción:** en el panel de OpenMediaVault → **Users → admin** → editar → establecer nueva contraseña robusta.

**Resultado esperado:** mensaje de confirmación *"The password was changed successfully"* (aplicado tras pulsar el botón de guardar y confirmar los cambios pendientes, habitual en la interfaz de OMV).

**Verificación:** cerrar sesión y volver a iniciar con la nueva contraseña — *debe funcionar, y la antigua ya no debe ser válida*.

---

### Paso 7 — Configurar IP estática

**Acción:** panel de OpenMediaVault → **Network → Interfaces** → editar la interfaz detectada → método IPv4: **Static** → completar:

```bash
Address:      192.168.60.12
Netmask:      255.255.255.0
Gateway:      192.168.60.1
```

En **Network → DNS**, añadir `192.168.60.10` como servidor DNS.

**Resultado esperado:** tras aplicar los cambios pendientes (botón de confirmación superior, característico de OMV), la interfaz se reconfigura sin perder la conexión al panel (si el navegador estaba usando la IP temporal, habrá que reconectar a la nueva IP fija).

**Verificación (por consola):**

```bash
ip a
ping -c 3 192.168.60.1
```

Debe mostrar `192.168.60.12/24` y conectividad correcta con el gateway.

---

## 5. Configuración del array RAID 5 con Hot Spare

### Paso 8 — Crear el array RAID 5

**Acción:** panel de OpenMediaVault → **Storage → RAID Management → Create** →

- Name: `raid-backups`
- Level: **RAID 5**
- Devices: seleccionar **3 de los 5 discos** de 4 TB disponibles

**Resultado esperado:** el array comienza su proceso de sincronización inicial (`resync`), visible en la propia interfaz con una barra de progreso — *en discos virtuales de prueba, este proceso es mucho más rápido que en hardware real*.

**Verificación:**

```bash
cat /proc/mdstat
```

Debe mostrar el dispositivo `md0` (o similar) en estado `active`, con los 3 discos listados y el progreso de `resync` si aún no ha finalizado.

---

### Paso 9 — Añadir el disco de reserva (Hot Spare)

**Acción:** dentro del mismo array `raid-backups` → **Recover** o gestión de discos del array → añadir el **4º disco** como *spare* (no como disco activo del array).

**Resultado esperado:** el disco aparece en `cat /proc/mdstat` marcado como `(S)` (spare) junto al resto de discos del array, sin participar activamente en el reparto de datos.

**Verificación:**

```bash
mdadm --detail /dev/md0
```

La sección `Spare Devices` debe mostrar `1`, confirmando que el hot spare está correctamente asignado al array.

> 📌 **Sobre el 5º disco:** queda sin asignar, disponible como repuesto físico adicional o para una futura ampliación — *no se incluye en el array ni como activo ni como spare, ya que el diseño del Módulo 1 contempla 4 discos (3 activos + 1 hot spare) sobre un total de 5 adquiridos*.

---

### Paso 10 — Crear el sistema de archivos y el punto de montaje

**Acción:** **Storage → File Systems → Create** → seleccionar el dispositivo `raid-backups` → tipo de sistema de archivos **EXT4** → confirmar.

**Resultado esperado:** el sistema de archivos se crea y se monta automáticamente, apareciendo en la lista con su capacidad disponible ( aproximadamente 8 TB útiles: 3 discos activos × 4 TB, menos el espacio reservado para paridad).

**Verificación:**

```bash
df -h | grep md0
```

Debe mostrar el punto de montaje con una capacidad aproximada de 8 TB y 0% de uso (recién creado).

---

## 6. Recursos compartidos y backups

### Paso 11 — Crear la carpeta compartida y el recurso SMB

**Acción:**

- **Storage → Shared Folders → Create**: nombre `backups-servidores`, sistema de archivos `raid-backups`, ruta relativa `/`
- **Services → SMB/CIFS → Shares → Add**: carpeta compartida `backups-servidores`, marcar *Enabled*

**Resultado esperado:** el recurso queda accesible en la red como `\\192.168.60.12\backups-servidores`.

**Verificación (desde un equipo de la VLAN 60 o con acceso permitido):**

```bash
smbclient -L //192.168.60.12 -U nas-admin
```

Debe listar `backups-servidores` entre los recursos compartidos disponibles.

---

### Paso 12 — Configurar tareas de backup programadas

**Acción:** **System → Scheduled Tasks → Create** → crear dos tareas:

- **Backup incremental diario:** ejecución diaria a las 02:00, usando `rsync` hacia la carpeta compartida
- **Backup completo semanal:** ejecución semanal (domingo 03:00), copia completa

**Resultado esperado:** ambas tareas aparecen listadas como *Enabled* en el panel, con su próxima ejecución programada visible.

**Verificación:** ejecutar manualmente una de las tareas mediante el botón *Run* del panel, y comprobar en `Storage → File Systems` que el espacio usado en `raid-backups` aumenta tras la ejecución.

---

## 7. Restricción de acceso

### Paso 13 — Limitar el acceso SMB por red

**Acción:** **Services → SMB/CIFS → Settings** → en el campo de configuración extendida, añadir:

```bash
hosts allow = 192.168.60.0/24 192.168.10.0/24
hosts deny = 0.0.0.0/0
```

> 📌 **Justificación:** solo el propio segmento de servidores y Administración (que ya tiene permiso de acceso a Servidores según la política del Módulo 3) pueden alcanzar los recursos compartidos — *el resto de VLANs queda excluido explícitamente a nivel de servicio, reforzando de nuevo la política ya aplicada por las ACLs del router*.

**Resultado esperado:** tras aplicar los cambios, el servicio SMB se reinicia automáticamente.

**Verificación (desde `PC-DES1`, VLAN 30, sin acceso concedido):**

```bash
smbclient -L //192.168.60.12 -U nas-admin
```

Debe fallar con un error de conexión rechazada o tiempo de espera agotado.

---

## 8. Checklist de verificación final

- [ ] OpenMediaVault instalado sobre el disco de sistema, `hostname` = `SRV-NAS`
- [ ] IP estática 192.168.60.12/24 configurada, gateway respondiendo
- [ ] Contraseña por defecto del panel web cambiada
- [ ] Array RAID 5 creado con 3 discos activos (`md0` en estado `active`)
- [ ] 4º disco añadido correctamente como Hot Spare (`Spare Devices: 1`)
- [ ] Sistema de archivos EXT4 creado sobre el array, ~8 TB disponibles
- [ ] Carpeta compartida `backups-servidores` accesible por SMB
- [ ] Tareas de backup incremental diario y completo semanal programadas
- [ ] Acceso SMB restringido a VLAN 60 y VLAN 10 únicamente
- [ ] Acceso SMB bloqueado desde una VLAN no autorizada (ej. VLAN 30)

---

## 9. Próximos pasos relacionados

- El resumen de todos los servicios activos en la infraestructura se consolida en [`servicios.md`](../servicios.md).
- La gestión de usuarios administradores de este servidor se documenta en [`usuarios-y-permisos.md`](../usuarios-y-permisos.md).
- Con este documento se completa la implantación de los **4 servidores de VectorSec**; el siguiente bloque del módulo cubre los **16 equipos cliente** en [`equipos-cliente.md`](../equipos-cliente.md).
