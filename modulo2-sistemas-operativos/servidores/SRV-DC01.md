# SRV-DC01 — Servidor de Dominio (Windows Server 2022 + AD DS + DNS)

## 1. Análisis del sistema operativo

| Parámetro | Valor | Origen / Justificación |
| :--- | :--- | :--- |
| Rol | Controlador de dominio (AD DS) + DNS | Punto central de autenticación y resolución de nombres de VectorSec |
| Sistema operativo | Windows Server 2022 Standard (Desktop Experience) | Estándar de facto para directorio activo en entornos empresariales; imprescindible para que los PCs cliente Windows 11 Pro puedan unirse a un dominio |
| Nombre de host | `SRV-DC01` | Consistente con el diagrama de red del Módulo 3 |
| Nombre de dominio AD | `vectorsec.local` | Reutiliza el dominio ya definido en la configuración SSH de los switches (Módulo 3), para mantener coherencia en toda la infraestructura |
| IP estática | 192.168.60.10 / 255.255.255.0 | Tabla de direccionamiento, Módulo 3 |
| Gateway | 192.168.60.1 | Subinterfaz ROAS (VLAN 60) |
| DNS propio | 127.0.0.1 → 192.168.60.10 tras la promoción | Este servidor será su propio servidor DNS |

Este es el primer servidor a implantar: el resto de equipos (servidores que se unan al dominio y los 16 PCs cliente) dependen de que `SRV-DC01` esté operativo antes de poder configurarse como miembros del dominio.

---

## 2. Plan de implantación

- **Método:** instalación manual e individualizada (no aplica clonación/imagen, al ser un servidor único con configuración propia).
- **Orden de tareas:** instalación del SO → configuración de red → instalación del rol AD DS → promoción a controlador de dominio → verificación de servicios.
- **Entorno:** máquina virtual (VirtualBox / Hyper-V), 1 vCPU mínimo (2 recomendado), 4 GB RAM mínimo (8 GB recomendado para Desktop Experience), 60 GB de disco.

---

## 3. Instalación del sistema operativo

### Paso 1 — Arranque desde la ISO

**Acción:** crear la máquina virtual, montar la ISO de Windows Server 2022 y arrancar.

**Resultado esperado:** pantalla azul de instalación de Windows Server con el selector de idioma, formato horario y teclado.

**Verificación:** el instalador reconoce el disco virtual asignado a la VM sin errores de controlador.

---

### Paso 2 — Idioma y edición

**Acción:** seleccionar *Español (España)*, pulsar **Instalar ahora**. En el selector de edición, elegir **Windows Server 2022 Standard (Desktop Experience)**.

**Resultado esperado:** pantalla "Selecciona el sistema operativo que deseas instalar", con la edición Desktop Experience resaltada tras la selección.

**Verificación:** confirmamos la edición *Desktop Experience* y no *Core* — *necesaria para gestionar el servidor con interfaz gráfica en este proyecto*.

---

### Paso 3 — Tipo de instalación y partición

**Acción:** aceptar la licencia → seleccionar **Personalizada: instalar solo Windows** → seleccionar el disco virtual completo como destino.

**Resultado esperado:** barra de progreso "Instalando Windows" con las fases `Copiando archivos` → `Preparando archivos` → `Instalando características` → `Instalando actualizaciones` → `Finalizando`. El proceso reinicia automáticamente la VM al finalizar.

**Verificación:** tras el reinicio, aparece la pantalla de configuración de contraseña de administrador (no un error de arranque).

---

### Paso 4 — Contraseña de administrador local

**Acción:** establecer la contraseña del usuario `Administrador`, cumpliendo requisitos de complejidad (**mayúsculas**, **minúsculas**, **número** y **símbolo**).

**Resultado esperado:** mensaje ***"Tu contraseña ha sido actualizada"***, seguido de la pantalla de inicio de sesión estándar de `Windows Server` (fondo azul, `Ctrl+Alt+Supr`).

**Verificación:** inicio de sesión correcto con el usuario `Administrador` y la contraseña establecida.

---

## 4. Configuración inicial post-instalación

### Paso 5 — Cambiar el nombre del equipo

**Acción (`PowerShell`, como `Administrador`):**

```powershell
Rename-Computer -NewName "SRV-DC01" -Restart
```

**Resultado esperado:** el comando no devuelve texto (es una ejecución silenciosa); la VM se reinicia automáticamente al finalizar.

**Verificación:** tras el reinicio, ejecutar `hostname` → debe devolver `SRV-DC01`.

---

### Paso 6 — Configurar IP estática

**Acción (`PowerShell`):**

```powershell
New-NetIPAddress -InterfaceAlias "Ethernet0" `
  -IPAddress 192.168.60.10 `
  -PrefixLength 24 `
  -DefaultGateway 192.168.60.1
```

**Resultado esperado:**

```powershell
IPAddress         : 192.168.60.10
InterfaceAlias    : Ethernet0
AddressFamily     : IPv4
PrefixLength      : 24
PrefixOrigin      : Manual
```

**Verificación:**

```powershell
Test-Connection 192.168.60.1 -Count 2
```

Debe responder correctamente (2 de 2 paquetes recibidos) — *confirma conectividad hacia el gateway del router ROAS, validando que la integración con el Módulo 3 es correcta*.

---

### Paso 7 — Configurar DNS (apuntando a sí mismo)

**Acción (`PowerShell`):**

```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 127.0.0.1
```

**Resultado esperado:** sin salida en consola (ejecución silenciosa).

**Verificación:**

```powershell
Get-DnsClientServerAddress -InterfaceAlias "Ethernet0"
```

Debe mostrar `127.0.0.1` en la columna `ServerAddresses`.

---

## 5. Instalación del rol Active Directory Domain Services

### Paso 8 — Instalar el rol AD DS

**Acción (`PowerShell`):**

```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

**Resultado esperado:**

```powershell
Success Restart Needed Exit Code      Feature Result
------- -------------- ---------      --------------
True    No             Success        {Active Directory Domain Services, ...}
```

**Verificación:** el campo `Success` debe ser `True` y `Exit Code` debe ser `Success`. Si `Restart Needed` aparece como `Maybe`, se recomienda reiniciar antes de continuar.

---

### Paso 9 — Promover el servidor a controlador de dominio

**Acción (`PowerShell`):**

```powershell
Install-ADDSForest `
  -DomainName "vectorsec.local" `
  -DomainNetbiosName "VECTORSEC" `
  -InstallDns:$true `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "VectorSecDSRM2026!" -AsPlainText -Force)
```

**Resultado esperado:** el asistente solicita confirmación (`Confirm`, escribir `Y`) y muestra advertencias no bloqueantes esperables en un entorno de laboratorio, como la ausencia de un servidor DNS delegable superior — *normal al ser el primer y único DC del bosque*. Al finalizar, el proceso reinicia automáticamente la VM.

**Verificación:** tras el reinicio, la pantalla de inicio de sesión debe mostrar `VECTORSEC\Administrador` (o `vectorsec.local\Administrador`) en lugar del inicio de sesión local — *confirma que el servidor ya opera como controlador de dominio*.

> 📌 **Observación sobre `-InstallDns:$true`:** instala el **rol DNS** como parte del mismo proceso de promoción, evitando un paso separado — *es la práctica estándar, ya que un controlador de dominio casi siempre aloja también la zona DNS de su propio dominio*.

---

## 6. Verificación de funcionamiento

### Paso 10 — Comprobar servicios críticos

**Acción (`PowerShell`):**

```powershell
Get-Service ADWS, DNS, Netlogon, KDC | Select-Object Name, Status
```

**Resultado esperado:**

```powershell
Name     Status
----     ------
ADWS     Running
DNS      Running
Netlogon Running
KDC      Running
```

**Verificación:** los 4 servicios deben aparecer como `Running`. Si alguno aparece como `Stopped`, revisar el visor de eventos (`eventvwr.msc` → *Servicios de directorio*) antes de continuar con los siguientes servidores.

---

### Paso 11 — Verificar la zona DNS

**Acción (PowerShell):**

```powershell
Get-DnsServerZone
```

**Resultado esperado:** debe listarse la zona `vectorsec.local` como zona principal (`Primary`), además de las zonas inversas y de reenvío estándar (`_msdcs.vectorsec.local`, `TrustAnchors`, etc., creadas automáticamente por el asistente).

**Verificación:** la columna `ZoneType` de `vectorsec.local` debe ser `Primary`, y `IsAutoCreated` debe ser `False` (zona creada explícitamente para el dominio, no una zona de sistema).

---

### Paso 12 — Diagnóstico general del controlador de dominio

**Acción (`PowerShell`):**

```powershell
dcdiag /v
```

**Resultado esperado:** una lista extensa de pruebas (`Connectivity`, `Advertising`, `FrsEvent`, `DFSREvent`, `SysVolCheck`, `KccEvent`, `NCSecDesc`, `NetLogons`, `ObjectsReplicated`, `Replications`, `RidManager`, `Services`, `SystemLog`, `VerifyReferences`, entre otras), cada una finalizando en `......................... SRV-DC01 passed test <nombre>`.

**Verificación:** ninguna prueba debe devolver `failed`. Es normal ver advertencias (`warning`) relacionadas con la ausencia de un segundo controlador de dominio para redundancia — *se documenta como mejora futura, con el mismo criterio ya aplicado al switch de Capa 3 en el Módulo 3 (mejora identificada y justificada, no aplicada por no ser necesaria en la fase actual de VectorSec)*.

---

## 7. Checklist de verificación final

- [ ] Windows Server 2022 (Desktop Experience) instalado, `hostname` = `SRV-DC01`
- [ ] IP estática `192.168.60.10/24`, gateway `192.168.60.1` respondiendo a `Test-Connection`
- [ ] DNS del propio equipo apuntando a `127.0.0.1`
- [ ] Rol AD DS instalado (`Success = True`)
- [ ] Servidor promovido a controlador de dominio de `vectorsec.local`
- [ ] Inicio de sesión reconociendo el dominio (`VECTORSEC\Administrador`)
- [ ] Servicios `ADWS`, `DNS`, `Netlogon`, `KDC` en estado `Running`
- [ ] Zona DNS `vectorsec.local` creada como zona principal
- [ ] `dcdiag /v` sin pruebas en estado `failed`

---

## 8. Próximos pasos relacionados

- La estructura de Unidades Organizativas (**OU**), grupos y usuarios de este dominio se documenta en [`usuarios-y-permisos.md`](../usuarios-y-permisos.md).
- Los 16 PCs cliente se unirán a este dominio durante su propio proceso de implantación, documentado en [`equipos-cliente.md`](../equipos-cliente.md).
- El resumen de todos los servicios activos en la infraestructura se consolida en [`servicios.md`](../servicios.md).
