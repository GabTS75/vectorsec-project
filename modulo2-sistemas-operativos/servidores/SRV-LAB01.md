# SRV-LAB01 — Servidor de Laboratorio / SOC (Kali Linux + Wazuh)

## 1. Análisis del sistema operativo

| Parámetro | Valor | Origen / Justificación |
| :--- | :--- | :--- |
| Rol | Laboratorio de pentesting + SIEM básico (SOC) | Entorno de análisis de malware controlado y monitorización de seguridad — justifica el aislamiento de red exigido desde el Módulo 1 |
| Sistema operativo | Kali Linux (última versión estable) | Distribución estándar de la industria para pentesting ético; cualquier evaluador del sector la reconoce de inmediato, y refuerza la identidad de VectorSec como empresa de ciberseguridad |
| SIEM | Wazuh (manager + dashboard, instalación single-node) | Solución SIEM/XDR de código abierto, ampliamente adoptada, con agente ligero desplegable en el resto de servidores para centralizar alertas de seguridad |
| Nombre de host | `SRV-LAB01` | Consistente con el diagrama de red del Módulo 3 |
| IP estática | 192.168.70.10 / 255.255.255.0 | Tabla de direccionamiento, Módulo 3 (VLAN 70 — LAB, aislada) |
| Gateway | 192.168.70.1 | Subinterfaz ROAS (VLAN 70) |
| DNS | 192.168.60.10 | Apunta a `SRV-DC01` |

> 📌 **Recordatorio de diseño (Módulo 3):** este servidor vive en su propia VLAN (70), con una ACL (`ACL-LAB-IN`) que bloquea cualquier tráfico que este equipo intente iniciar hacia el resto de VLANs internas, permitiendo únicamente que **Soporte Técnico (VLAN 40, el SOC)** inicie conexiones de gestión hacia él.
>
> La salida a Internet (para actualizaciones y feeds de amenazas) permanece abierta, ya que la ACL solo deniega destinos internos y termina en `permit ip any any`. Este documento configura el propio sistema operativo para reforzar esa misma política a nivel de host *(defensa en profundidad, mismo criterio ya aplicado en `SRV-APP01`)*.

---

## 2. Plan de implantación

- **Método:** instalación manual, individualizada.
- **Orden de tareas:** `instalación del SO` → `configuración de red` → `actualización del sistema` → `instalación de Wazuh (manager + dashboard)` → `restricción de acceso por firewall local` → `verificación cruzada con las ACLs del Módulo 3`.
- **Entorno:** máquina virtual (VirtualBox / Hyper-V), `4 vCPU` recomendado, `8 GB` RAM mínimo (Wazuh es exigente en memoria), `60 GB` de disco.

---

## 3. Instalación del sistema operativo

### Paso 1 — Arranque desde la ISO

**Acción:** crear la máquina virtual, montar la ISO de *Kali Linux Installer* (no la versión "Live", ya que este servidor necesita una instalación persistente) y arrancar.

**Resultado esperado:** menú de arranque de Kali con la opción **Graphical Install**.

**Verificación:** el instalador detecta correctamente el disco virtual y la interfaz de red antes de continuar.

---

### Paso 2 — Idioma, ubicación y teclado

**Acción:** seleccionar ***English*** como idioma base del sistema (igual criterio que en `SRV-APP01`, por compatibilidad de documentación técnica) → ubicación ***Spain*** (España)→ distribución de teclado ***Spanish*** (Español).

**Resultado esperado:** el instalador avanza a la detección de hardware y configuración de red.

**Verificación:** ninguna, es una pantalla informativa.

---

### Paso 3 — Nombre de host y usuario administrador

**Acción:**

- Hostname: `SRV-LAB01`
- Domain name: dejar en blanco (no se une a `vectorsec.local`, **ver nota del apartado 1**)
- Full name for the new user: `VectorSec SOC`
- Username: `soc-admin`
- Choose a password / Re-enter password: contraseña que cumpla complejidad mínima (ej. `S0C-L4b-V3ct0r!`)

**Resultado esperado:** el instalador avanza al particionado de disco tras confirmar ambas contraseñas coincidentes (la de root, si se solicita por separado, y la del usuario `soc-admin`).

**Verificación:** ninguna incidencia — *si las contraseñas no coinciden, el propio instalador muestra un error y no permite avanzar (aprendizaje aplicado del ajuste hecho en `SRV-APP01`)*.

---

### Paso 4 — Particionado

**Acción:** seleccionar **Guided - use entire disk** → elegir el disco virtual único → esquema **All files in one partition** (recomendado para un servidor de laboratorio sencillo, sin necesidad de separar `/home`, `/var`, etc.) → confirmar escritura de cambios en disco.

**Resultado esperado:** barra de progreso de instalación de paquetes base, finalizando con la instalación del gestor de arranque **GRUB** en el disco virtual.

**Verificación:** al finalizar, el instalador muestra *"Installation complete"* y solicita reiniciar.

---

### Paso 5 — Primer acceso

**Acción:** retirar la ISO virtual, reiniciar y acceder con el usuario `soc-admin`.

**Resultado esperado:** entorno gráfico Xfce de Kali Linux (o prompt en modo texto, si se optó por una instalación mínima sin entorno gráfico).

**Verificación:**

```bash
cat /etc/os-release
```

Debe mostrar `Kali GNU/Linux` en `PRETTY_NAME`.

---

## 4. Configuración inicial post-instalación

### Paso 6 — Configurar IP estática (Netplan)

**Acción:**

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

Contenido:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.70.10/24
      routes:
        - to: default
          via: 192.168.70.1
      nameservers:
        addresses:
          - 192.168.60.10
```

Aplicar:

```bash
sudo netplan apply
```

> 📌 Aquí la interfaz aparece como `eth0` y no como `enp0s3` (nomenclatura ya explicada en `SRV-APP01.md`) porque puede variar según la imagen y el hipervisor concreto — ***se confirma siempre con* `ip a` *antes de editar el archivo**, en lugar de asumir el nombre por defecto*.

**Resultado esperado:** sin salida en consola si aplica correctamente.

**Verificación:**

```bash
ip a show eth0
ping -c 3 192.168.70.1
```

Debe mostrar `inet 192.168.70.10/24` y 3 de 3 paquetes recibidos desde el gateway — *confirma la integración con el router ROAS*.

---

### Paso 7 — Actualizar el sistema

**Acción:**

```bash
sudo apt update && sudo apt full-upgrade -y
```

**Resultado esperado:** actualización de los repositorios propios de Kali, finalizando sin errores de dependencias.

**Verificación:**

```bash
apt list --upgradable
```

Lista vacía.

---

## 5. Instalación de Wazuh (SIEM)

### Paso 8 — Instalación con el script "all-in-one"

**Acción:**

```bash
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
sudo bash wazuh-install.sh -a
```

**Resultado esperado:** el script instala secuencialmente el *Wazuh indexer*, *Wazuh manager* y *Wazuh dashboard*, mostrando al final un resumen con la contraseña generada para el usuario `admin` del dashboard — ⚠️ ***debe copiarse y guardarse**, ya que no se vuelve a mostrar automáticamente, ¡Ojo!*.

**Verificación:**

```bash
sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard
```

Los tres servicios deben aparecer como `active (running)`.

---

### Paso 9 — Acceso al dashboard

**Acción (desde un navegador en un equipo de Soporte Técnico, VLAN 40):**

```bash
https://192.168.70.10
```

Iniciar sesión con el usuario `admin` y la contraseña generada en el Paso 8.

**Resultado esperado:** panel principal de Wazuh, mostrando el propio `SRV-LAB01` como único agente activo (el manager se monitoriza a sí mismo por defecto).

**Verificación:** el estado del agente local debe aparecer como `Active`, sin alertas críticas en las primeras horas tras la instalación (es normal ver alertas informativas de baja severidad relacionadas con la propia instalación).

---

## 6. Restricción de acceso — firewall local (defensa en profundidad)

### Paso 10 — Configurar UFW

**Acción:**

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.40.0/24 to any port 22 proto tcp
sudo ufw allow from 192.168.40.0/24 to any port 443 proto tcp
sudo ufw enable
```

**Resultado esperado:**

```bash
Firewall is active and enabled on system startup
```

> 📌 **Por qué se permite el tráfico saliente por defecto (`allow outgoing`):** este servidor necesita salida a Internet para actualizaciones de firmas, feeds de amenazas y, en el propio ejercicio de laboratorio, descarga controlada de muestras para análisis — *es coherente con el diseño de la ACL del Módulo 3, que bloquea destinos internos pero no bloquea la salida a Internet*.

**Verificación:**

```bash
sudo ufw status verbose
```

Debe mostrar únicamente los puertos `22/tcp` (ssh) y `443/tcp` (https) permitidos desde `192.168.40.0/24`, con la política por defecto `deny (incoming)`.

---

## 7. Verificación cruzada con las ACLs del Módulo 3

### Paso 11 — Acceso permitido desde Soporte Técnico

**Acción (desde `PC-SOP1`, VLAN 40):**

```bash
ssh soc-admin@192.168.70.10
```

**Resultado esperado:** solicitud de contraseña, seguida de acceso al shell de `SRV-LAB01`.

**Verificación:** conexión establecida sin `timeout` — confirma que tanto la ACL del router como el firewall local coinciden en permitir este origen.

---

### Paso 12 — Acceso bloqueado desde Administración

**Acción (desde `PC-ADM1`, VLAN 10):**

```bash
ssh soc-admin@192.168.70.10
```

**Resultado esperado:** la conexión debe fallar por `timeout`, ya que la ACL `ACL-ADMIN-IN` no bloquea explícitamente el destino VLAN 70, pero es **`ACL-LAB-IN`** *—aplicada en sentido de salida desde el laboratorio—* la que impediría una respuesta si el laboratorio intentase iniciar tráfico de vuelta; en este sentido de entrada (Administración → LAB), el firewall local (`ufw`) es la barrera real, al no incluir `192.168.10.0/24` entre los orígenes permitidos.

**Verificación:**

```bash
ssh: connect to host 192.168.70.10 port 22: Connection timed out
```

Este resultado, comparado con el éxito del Paso 11, demuestra que el control de acceso depende del **firewall local** en este sentido concreto (**entrante**), reforzando por qué la defensa en profundidad importa: *si el firewall de host no estuviera bien configurado, cualquier VLAN podría intentar acceder por SSH sin que la ACL de red lo evitara en este sentido*.

---

### Paso 13 — Comprobar que el laboratorio no puede iniciar tráfico hacia el resto de la red

**Acción (desde `SRV-LAB01`):**

```bash
ping -c 3 192.168.10.1
```

**Resultado esperado:** 0 de 3 paquetes recibidos (100% de pérdida).

**Verificación:** confirma que `ACL-LAB-IN`, aplicada en el router (Módulo 3), bloquea correctamente cualquier tráfico saliente desde el laboratorio hacia VLANs internas — *la pieza central del aislamiento que se lleva justificando desde el Módulo 1*.

---

## 8. Checklist de verificación final

- [ ] Kali Linux instalado, `hostname` = `SRV-LAB01`
- [ ] IP estática 192.168.70.10/24 configurada vía Netplan, gateway respondiendo
- [ ] Sistema actualizado sin paquetes pendientes
- [ ] Wazuh manager, indexer y dashboard en estado `active (running)`
- [ ] Contraseña del dashboard guardada de forma segura
- [ ] Firewall UFW activo: solo 22/tcp y 443/tcp permitidos desde VLAN 40
- [ ] SSH exitoso desde Soporte Técnico (VLAN 40)
- [ ] SSH bloqueado desde Administración (VLAN 10)
- [ ] Ping saliente desde el laboratorio hacia cualquier VLAN interna, bloqueado (0% recibido)

---

## 9. Próximos pasos relacionados

- El resumen de todos los servicios activos en la infraestructura se consolida en [`servicios.md`](../servicios.md).
- La gestión de usuarios administradores de este servidor se documenta en [`usuarios-y-permisos.md`](../usuarios-y-permisos.md), en su apartado específico de servidores Linux.
- Cuando se despliegue el agente de Wazuh en el resto de servidores (mejora recomendada, no obligatoria para el mínimo del proyecto), se documentará como ampliación en este mismo archivo.
