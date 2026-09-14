# Equipos cliente — Windows 11 Pro (16 PCs)

## 1. Análisis del sistema operativo

| Parámetro | Valor | Justificación |
| :--- | :--- | :--- |
| Sistema operativo | Windows 11 Pro | La edición **Pro** (no Home) es obligatoria: solo Pro permite unirse a un dominio Active Directory, aplicar políticas de grupo (GPO) y usar BitLocker — funciones imprescindibles en una empresa con AD ya desplegado (`SRV-DC01`) |
| Dominio | `vectorsec.local` | Todos los equipos se unen al dominio creado en `SRV-DC01.md`, heredando la gestión centralizada de usuarios y permisos |
| Direccionamiento IP | DHCP | Los pools DHCP por VLAN ya están configurados y verificados desde el Módulo 3 — no se requiere ninguna configuración de red adicional en el equipo cliente |
| Equipos afectados | 16 PCs: Recepción (2), Administración (2), Dirección (2), Desarrollo (2), Soporte Técnico (2), Aula de Formación (6) | Según el Módulo 1 |

### 1.1 ¿Por qué no instalar Windows 16 veces, una por equipo?

Porque sería repetir exactamente el mismo trabajo 16 veces sin necesidad. En su lugar, se sigue un proceso llamado **"imagen de referencia" (o "imagen maestra")**: se instala y configura **un único equipo** con todo lo común a todos los departamentos, y después esa misma instalación se copia ("clona") al resto de equipos. Es como hacer una plantilla de un documento en vez de escribir 16 documentos casi idénticos desde cero.

### 1.2 ¿Qué equipo usamos como referencia?

Se elige **`PC-ADM1`** (Administración, Intel Core i5, 8 GB RAM) como equipo de referencia. La razón es que su especificación es la más "intermedia" del catálogo del Módulo 1 — *ni la más básica (Recepción, i3) ni la más potente (Desarrollo, i7)* — lo que reduce el riesgo de que, al aplicar la misma imagen en equipos con hardware distinto, aparezcan conflictos de controladores (drivers). Este mismo equipo, una vez terminado el proceso, se queda siendo el propio `PC-ADM1` definitivo — *no se "gasta" ni se descarta, simplemente es el primero en estar listo*.

### 1.3 Asunción de diseño sobre el hardware

Se asume que los 16 equipos, aunque con configuraciones de CPU/RAM distintas según el departamento, **provienen del mismo proveedor y comparten una base de hardware compatible** (misma familia de placa base/chipset). Windows 11 gestiona razonablemente bien pequeñas diferencias de hardware dentro de una misma familia mediante sus controladores genéricos y Windows Update, por lo que una única imagen resulta viable. Si en la práctica existiera hardware de fabricantes muy distintos entre departamentos, sería necesario crear más de una imagen de referencia — *se documenta esta asunción de forma explícita, con el mismo criterio de transparencia aplicado en el resto del proyecto*.

### 1.4 Si VectorSec fuera una empresa mucho más grande

Con 16 equipos, el proceso manual que se describe en este documento (una imagen, aplicada equipo por equipo) es perfectamente razonable. Si **VectorSec** creciera a, por ejemplo, 200 o 2000 equipos, el proceso adecuado cambiaría hacia herramientas de **despliegue centralizado** como **Microsoft Deployment Toolkit (MDT)** o **Microsoft Intune**, que permiten: desplegar la imagen a muchos equipos a la vez por red (sin ir uno por uno con un USB), detectar automáticamente el modelo de hardware e inyectar los drivers correctos para cada uno, e instalar automáticamente el software específico de cada departamento según reglas predefinidas (en vez de hacerlo a mano, como se hace aquí). Se documenta como posible mejora futura, coherente con la visión de crecimiento de **VectorSec** ya mencionada en módulos anteriores.

---

## 2. Plan de implantación — visión general

1. Instalar Windows 11 en el equipo de referencia (`PC-ADM1`).
2. Configurar ese equipo con el software común a todos los departamentos.
3. Entrar en **Modo Auditoría** y ejecutar **Sysprep** para "limpiar" la instalación antes de clonarla (se explica en detalle en el apartado 4).
4. **Capturar** una imagen de esa instalación ya limpia, usando **Clonezilla** (una herramienta gratuita y visual, mucho más sencilla que trabajar por comandos).
5. **Aplicar** esa imagen a los 15 equipos restantes.
6. En cada uno de los 15, completar la configuración inicial, **renombrar el equipo** y **unirlo al dominio**.
7. En los 6 equipos del Aula de Formación, instalar además **VirtualBox** con una máquina virtual de Kali Linux para las prácticas.

---

## 3. Instalación del equipo de referencia (PC-ADM1)

### Paso 1 — Arranque e instalación base

**Acción:** arrancar `PC-ADM1` desde la ISO de instalación de **Windows 11 Pro** → seleccionar idioma ***Español** (España)* → **Instalar ahora**.

> 📌 **Sobre la clave de producto:** las ISOs "retail" (las que se descargan normalmente para uso doméstico) piden obligatoriamente una clave de producto y ya no siempre ofrecen la opción de omitirla. Para evitar tener algún inconveniente en el desarrollo de este proyecto, la solución estándar sería — *y es la que usaremos en este documento* — descargar la [ISO de evaluación de Windows 11 Enterprise](https://www.microsoft.com/es-es/evalcenter/evaluate-windows-11-enterprise) desde el propio sitio de **Microsoft** (pensada para pruebas, formación y entornos de laboratorio): esta versión **no pide ninguna clave durante la instalación** y funciona con todas las funciones activas durante el periodo de evaluación (**90 días**, prorrogables).

**Resultado esperado:** el instalador avanza directamente a la aceptación de términos de licencia, sin pantalla de introducción de clave.

**Verificación:** ninguna, pantalla informativa.

---

### Paso 2 — Partición e instalación

**Acción:** **Personalizada: instalar solo Windows** → seleccionar el disco completo → confirmar.

**Resultado esperado:** proceso de copia e instalación de archivos, con reinicio(s) automático(s) hasta llegar a la pantalla de bienvenida inicial.

**Verificación:** tras los reinicios, aparece la pantalla *"¿Cuál es tu país o región?"*, confirmando que la instalación base finalizó correctamente.

---

### Paso 3 — Entrar en Modo Auditoría (en lugar de completar el asistente normal)

Aquí está el cambio más importante respecto a un uso doméstico habitual de Windows, y merece una explicación aparte y detallada.

**¿Qué es el Modo Auditoría y por qué lo usamos?**
Si completases el asistente de bienvenida normal (el que pide crear un usuario, conectar a Internet, etc.), Windows te obligaría a crear una cuenta de usuario real en ese momento. El problema es que esa cuenta quedaría "grabada" dentro de la instalación, y si luego clonas esa instalación a otros 15 equipos, **los 16 acabarían compartiendo exactamente el mismo usuario y la misma contraseña** — *algo nada recomendable en seguridad (y más en una empresa de ciberseguridad)*.

El **Modo Auditoría** es un modo especial, pensado precisamente para este caso: te deja entrar directamente al escritorio de Windows usando la cuenta **Administrador integrada** (una cuenta técnica del propio sistema, no una cuenta de usuario "real"), sin necesidad de crear ningún usuario. Así, cuando más adelante se ejecute **`Sysprep`**, no hay ningún usuario personalizado que limpiar — *el problema desaparece de raíz en vez de tener que "arreglarse" después*.

**Acción:** en la pantalla de bienvenida ***"¿Cuál es tu país o región?"***, pulsar la combinación de teclas **`Ctrl + Shift + F3`**. 👈

**Resultado esperado:** el equipo se reinicia automáticamente y entra directo al escritorio de Windows, con una ventana de **`Sysprep`** ya abierta de fondo (se cerrará sin hacer nada por ahora, la usaremos más adelante en el Paso 8) y una marca de agua en la esquina indicando **"Modo Auditoría"**.

**Verificación:** la esquina inferior derecha del escritorio muestra el texto **"Modo de auditoría"** — *si no aparece, significa que la combinación de teclas no se pulsó a tiempo (solo funciona en esa pantalla concreta del asistente ¡ojo!)*.

---

## 4. Configuración del equipo de referencia

### Paso 4 — Instalar el software base común

**Acción:** en Modo Auditoría, instalar el software que **todos** los departamentos necesitan por igual:

- Navegador (ej. Microsoft Edge actualizado, o Chrome/Firefox según política interna)
- Suite ofimática
- Cliente de escritorio remoto / VPN corporativa (si aplica)

**Resultado esperado:** software instalado y funcional, sin errores pendientes.

**Verificación:** cada aplicación abre correctamente.

> 📌 **El software específico de cada departamento, como por ejemplo: herramientas de desarrollo en Desarrollo, herramientas de pentesting en el Aula de Formación, etc., no se instala aquí.** Se instalarán después, de manera individual y solo en los equipos que lo necesiten — *instalarlo en la imagen común significaría que hasta el PC de Recepción tendría herramientas de desarrollo instaladas, lo cual no tiene sentido ni es seguro*.

---

### Paso 5 — Windows Update

**Acción:** **Configuración → Windows Update → Buscar actualizaciones**, instalar todas las disponibles y reiniciar cuantas veces sea necesario (el equipo permanece en Modo Auditoría tras cada reinicio) hasta que el sistema indique *"Estás al día"*.

**Resultado esperado:** ninguna actualización pendiente.

**Verificación:**

```powershell
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5
```

Debe mostrar las actualizaciones instaladas más recientes.

---

## 5. Generalización con Sysprep (explicación completa)

> Mayor información en la página oficial de Microsoft — [Sysprep: System Preparation Tool](https://learn.microsoft.com/es-es/windows-hardware/manufacture/desktop/sysprep--system-preparation--overview?view=windows-11) 👈

### 5.1 ¿Qué es un SID y por qué es un problema al clonar?

Cada instalación de Windows genera, durante su instalación, un identificador único e interno llamado **SID (Security Identifier)** — algo así como el "DNI" que **Windows** y **Active Directory** usan internamente para reconocer a ese equipo concreto y a sus cuentas de usuario locales.

**El problema:** si clonas una instalación de Windows tal cual a otros 15 equipos, **los 16 tendrían exactamente el mismo SID** (Esto sucedió en una clase práctica de ISO). Para **Active Directory** esto es un problema serio, porque necesita identificar a cada equipo del dominio de forma única — *con SIDs duplicados, el dominio no podría distinguir entre `PC-ADM1` y, por ejemplo, `PC-DES1`, lo que provocaría fallos de autenticación y de aplicación de políticas de grupo impredecibles*.

### 5.2 ¿Qué hace Sysprep?

**Sysprep** (*System Preparation Tool*) es una herramienta incluida en el propio **Windows** cuya función es "despersonalizar" una instalación antes de clonarla: elimina el SID específico de esa instalación (se generará uno nuevo y único la primera vez que arranque cada clon) y borra los datos específicos de esa máquina en concreto. Es como borrar el nombre y los datos personales de un formulario ya relleno, dejando solo la plantilla, para que cada persona que lo reciba después rellene sus propios datos sin arrastrar los del formulario original.

### 5.3 Preparar un archivo de respuesta (unattend.xml)

#### ¿Para qué sirve este archivo?

Al arrancar por primera vez, cada uno de los 15 clones pasaría por el mismo asistente de bienvenida que vimos en el Paso 3 (idioma, país, teclado, cuenta de Microsoft...). Repetir eso manualmente 15 veces es tedioso y propenso a errores. **Un archivo `unattend.xml` es, sencillamente, un fichero de configuración que responde esas preguntas automáticamente por ti**.

**Acción:** crear un archivo de texto llamado `unattend.xml` con el siguiente contenido exacto:

```xml
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">

  <settings pass="generalize">
    <component name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64"
      publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <SkipRearm>1</SkipRearm>
    </component>
  </settings>

  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64"
      publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <InputLocale>es-ES</InputLocale>
      <SystemLocale>es-ES</SystemLocale>
      <UILanguage>es-ES</UILanguage>
      <UserLocale>es-ES</UserLocale>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64"
      publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>3</ProtectYourPC>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>
      <TimeZone>Romance Standard Time</TimeZone>
    </component>
  </settings>

</unattend>
```

**Explicación de las líneas más importantes (en lenguaje simple y llano):**

| Línea | Qué hace |
| --- | --- |
| `<InputLocale>es-ES</InputLocale>` y similares | Configura idioma, teclado y región en español automáticamente |
| `<HideOnlineAccountScreens>true</HideOnlineAccountScreens>` | Evita que el asistente pida iniciar sesión con una cuenta de Microsoft |
| `<NetworkLocation>Work</NetworkLocation>` | Marca la red como "red de trabajo" (más adecuado que "red doméstica" para un equipo de empresa) |
| `<SkipMachineOOBE>` / `<SkipUserOOBE>` | Omiten por completo las pantallas del asistente que ya hemos resuelto de antemano |
| `<TimeZone>Romance Standard Time</TimeZone>` | Es el nombre técnico interno de Windows para la zona horaria de España peninsular |

**Resultado esperado:** un archivo de texto plano guardado con extensión `.xml` (no `.txt`).

**Verificación:** al abrir el archivo en un navegador web (arrastrándolo a una pestaña), debe mostrarse como un árbol de etiquetas XML bien formado (sabemos que es muy estrícto), sin mensajes de error de "documento no válido" — *es una forma sencilla de comprobar que no hay etiquetas mal cerradas sin necesidad de herramientas adicionales*.

**Acción final:** copiar este archivo a la ruta `C:\Windows\System32\Sysprep\unattend.xml` del equipo de referencia.

---

### Paso 6 — Ejecutar Sysprep

**Acción:** en el equipo de referencia (todavía en Modo Auditoría), abrir la ventana de Sysprep (la misma que apareció automáticamente en el Paso 3, o bien ejecutar `C:\Windows\System32\Sysprep\sysprep.exe`) y configurar:

- **System Cleanup Action:** *Enter System Out-of-Box Experience (OOBE)*
- Marcar la casilla **Generalize**
- **Shutdown Options:** *Shutdown*

Pulsar **OK**.

**Resultado esperado:** el equipo muestra brevemente *"Preparando dispositivo para su primer uso"* y se apaga automáticamente (no reinicia).

**Verificación:** el equipo se apaga limpiamente, sin ventanas de error. Un error habitual en este paso (`Sysprep was not able to validate your Windows installation`) casi siempre indica que se completó el asistente de bienvenida normal en vez de entrar en Modo Auditoría, o que quedó algún usuario adicional creado — *si esto ocurre, se recomienda repetir la instalación desde el Paso 2, prestando especial atención al Paso 3*.

---

## 6. Captura y despliegue de la imagen con Clonezilla

### 6.1 ¿Por qué Clonezilla y no herramientas de línea de comandos?

Existen varias formas de "clonar" un disco. La que usan los departamentos de IT de grandes empresas suele apoyarse en **WinPE + DISM** (un mini-sistema operativo de Microsoft junto con comandos específicos de captura y aplicación de imágenes) — *es muy potente y flexible, pero requiere escribir varios comandos exactos y entender conceptos adicionales (particiones, letras de unidad, gestores de arranque...). Es la herramienta correcta cuando se automatiza el despliegue de cientos de equipos, pero no es la más intuitiva para una primera toma de contacto*.

**Clonezilla** es una alternativa gratuita y de código abierto que hace exactamente lo mismo (clonar un disco completo) pero mediante un **menú de texto guiado**, sin necesidad de escribir comandos — *se navega con las flechas del teclado y se confirma con Intro. Para este proyecto, es la opción más adecuada tanto por su sencillez como porque el resultado final (una imagen del disco, aplicable a otros equipos) es equivalente*.

### Paso 7 — Arrancar Clonezilla en el equipo de referencia

**Acción:** descargar la ISO de **Clonezilla Live** desde su web oficial, grabarla en un USB arrancable (con una herramienta como **Rufus**) y arrancar `PC-ADM1` desde ese USB.

**Resultado esperado:** aparece el menú de arranque de Clonezilla; seleccionar la primera opción, **"Clonezilla live"**.

**Verificación:** el sistema carga un entorno Linux mínimo y muestra el menú principal de Clonezilla en modo texto.

---

### Paso 8 — Capturar la imagen del disco (disk to image)

**Acción, siguiendo el menú de Clonezilla paso a paso:**

1. Idioma → **English** (recomendado, evita problemas de caracteres especiales en discos/carpetas de red)
2. Configuración de teclado → **Don't touch keymap** (mantener la que ya tiene el sistema)
3. Modo de inicio → **Start Clonezilla**
4. Modo de trabajo → **device-image** (trabajar entre un disco y un archivo de imagen)
5. Ubicación donde guardar la imagen → seleccionar un **dispositivo USB externo** conectado, o una **carpeta de red** (por ejemplo, el recurso compartido ya creado en `SRV-NAS`, `\\192.168.60.12\backups-servidores`, sirve perfectamente para este propósito)
6. Modo de uso → **Beginner mode** (modo principiante — usa las opciones por defecto recomendadas)
7. Acción a realizar → **savedisk** (guardar un disco completo como imagen)
8. Nombre para la imagen → escribir, por ejemplo, `VectorSec-Win11-Ref`
9. Seleccionar el disco de origen → el disco donde está instalado Windows en `PC-ADM1` (normalmente aparece como `sda`)
10. Confirmar con **Enter** y, cuando se solicite, escribir **`y`** para confirmar el inicio del proceso.

**Resultado esperado:** una barra de progreso mostrando el porcentaje de disco copiado, finalizando con el mensaje **"...savedisk is completed!"**.

**Verificación:** en la carpeta/USB de destino aparece una nueva carpeta llamada `VectorSec-Win11-Ref`, conteniendo varios archivos comprimidos con los datos del disco clonado.

---

### Paso 9 — Aplicar la imagen a cada uno de los 15 equipos restantes

**Acción, en cada uno de los 15 equipos, siguiendo de nuevo el menú de Clonezilla:**

1. Arrancar el equipo desde el mismo USB de Clonezilla Live
2. Repetir los pasos 1 a 6 del Paso 8 (idioma, teclado, modo de inicio, `device-image`, ubicación, modo principiante)
3. Acción a realizar → esta vez, **restoredisk** (restaurar una imagen guardada sobre un disco)
4. Seleccionar la imagen → `VectorSec-Win11-Ref` (la que se creó en el Paso 8)
5. Seleccionar el disco de destino → el disco interno del equipo actual (normalmente `sda`)
6. Confirmar con **Enter** y escribir **`y`** cuando se solicite — *Clonezilla avisará de que **se borrará todo el contenido actual del disco de destino**, lo cual es correcto y esperado en este caso*.

**Resultado esperado:** barra de progreso de restauración, finalizando con **"...restoredisk is completed!"**.

**Verificación:** al retirar el USB y reiniciar, el equipo debe arrancar directamente en la pantalla de bienvenida de Windows (gracias al `unattend.xml`, la mayoría de preguntas ya vienen respondidas automáticamente).

---

## 7. Primer arranque, renombrado y unión al dominio

### Paso 10 — Primer arranque y renombrado individual

**Acción (en cada uno de los 16 equipos, incluido el propio `PC-ADM1`):**

```powershell
Rename-Computer -NewName "PC-ADM1" -Restart
```

(sustituyendo el nombre según la tabla siguiente en cada equipo)

| Departamento | Equipos |
| :--- | :--- |
| Recepción | `PC-REC1`, `PC-REC2` |
| Administración | `PC-ADM1` (equipo de referencia), `PC-ADM2` |
| Dirección | `PC-DIR1`, `PC-DIR2` |
| Desarrollo | `PC-DES1`, `PC-DES2` |
| Soporte Técnico | `PC-SOP1`, `PC-SOP2` |
| Aula de Formación | `PC-AULA1` a `PC-AULA6` |

**Resultado esperado:** el equipo se reinicia con el nuevo nombre aplicado.

**Verificación:**

```powershell
hostname
```

Debe devolver el nombre correcto para ese equipo concreto.

---

### Paso 11 — Comprobar conectividad antes de unir al dominio

**Acción:**

```powershell
ipconfig /all
```

**Resultado esperado:** el equipo debe mostrar una IP dentro del rango DHCP de su VLAN correspondiente (ya verificado en el Módulo 3) y el DNS `192.168.60.10` (`SRV-DC01`).

**Verificación:**

```powershell
nslookup vectorsec.local
```

Debe resolver correctamente hacia `192.168.60.10`, confirmando que el equipo puede localizar el controlador de dominio antes de intentar unirse a él.

---

### Paso 12 — Unir el equipo al dominio

**Acción:**

```powershell
Add-Computer -DomainName "vectorsec.local" -Credential (Get-Credential) -Restart
```

Al solicitarse credenciales, usar una cuenta con permisos de unión al dominio (por ejemplo: `VECTORSEC\Administrador`).

**Resultado esperado:** mensaje `The operation completed successfully`, seguido de un reinicio automático.

**Verificación:** tras el reinicio, la pantalla de inicio de sesión debe permitir elegir *"Otro usuario"* e iniciar sesión con una cuenta del dominio (ejemplo: `VECTORSEC\usuario.departamento`, cuya creación se detalla en `usuarios-y-permisos.md`).

---

### Paso 13 — Verificación final de la unión al dominio

**Acción (iniciando sesión ya con una cuenta de dominio):**

```powershell
Test-ComputerSecureChannel -Verbose
```

**Resultado esperado:** `True`, confirmando que el canal seguro entre el equipo y el controlador de dominio está correctamente establecido y, de paso, **confirmando indirectamente** que el **SID** de este equipo es **único** (si dos equipos compartieran SID por un fallo en el Sysprep del Paso 6, este tipo de comprobación es donde normalmente empezarían a aparecer errores extraños).

**Verificación adicional:**

```powershell
gpresult /r
```

Debe mostrar el equipo dentro de la **Unidad Organizativa** (**OU**) correspondiente a su departamento (estructura detallada en `usuarios-y-permisos.md`).

---

## 8. Configuración adicional — Aula de Formación

### Paso 14 — Instalar VirtualBox

**Acción (solo en `PC-AULA1` a `PC-AULA6`):** instalar **VirtualBox** desde el instalador oficial, con las opciones por defecto.

**Resultado esperado:** VirtualBox se abre correctamente tras la instalación, sin errores de controladores de red/USB pendientes.

**Verificación:**

```powershell
& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" --version
```

Debe devolver un número de versión válido.

---

### Paso 15 — Importar la VM de Kali Linux para prácticas

**Acción:** importar el archivo `.ova` oficial de Kali Linux (descargado previamente y almacenado en el recurso compartido de `SRV-NAS`) mediante **Archivo → Importar servicio virtualizado** en VirtualBox.

**Resultado esperado:** la VM aparece en el listado de VirtualBox, lista para arrancar bajo demanda durante las sesiones de formación.

**Verificación:** arranque de prueba de la VM, confirmando que llega al login de Kali Linux sin errores de configuración de hardware virtual.

> 📌 **Por qué no se instala Kali directamente en estos 6 equipos:** los mismos PCs deben servir tanto para formación general/ofimática como para prácticas de pentesting ético. Instalar Kali como sistema principal impediría el uso cotidiano del aula para otros fines; con **VirtualBox**, la VM se levanta solo cuando la sesión formativa lo requiere.

---

## 9. Checklist de verificación final

- [ ] Equipo de referencia (`PC-ADM1`) instalado en Modo Auditoría, sin usuarios personalizados creados
- [ ] Software base común instalado y actualizado
- [ ] Archivo `unattend.xml` creado y colocado en la ruta correcta
- [ ] Sysprep ejecutado con `Generalize` marcado, equipo apagado sin errores
- [ ] Imagen capturada con Clonezilla (`savedisk` completado)
- [ ] Imagen aplicada en los 15 equipos restantes (`restoredisk` completado en cada uno)
- [ ] Los 16 equipos renombrados según la tabla de nomenclatura
- [ ] Los 16 equipos obtienen IP por DHCP en su VLAN correspondiente
- [ ] Los 16 equipos resuelven `vectorsec.local` vía DNS antes de unirse al dominio
- [ ] Los 16 equipos unidos al dominio (`Test-ComputerSecureChannel` = `True`)
- [ ] Cada equipo aparece en la OU correcta según `gpresult /r`
- [ ] VirtualBox instalado en los 6 equipos del Aula de Formación
- [ ] VM de Kali Linux importada y arrancando correctamente en el Aula

---

## 10. Próximos pasos relacionados

- La estructura de **OUs**, **grupos** y **usuarios de dominio** (incluida la cuenta usada en el Paso 12) se documenta en [`usuarios-y-permisos.md`](usuarios-y-permisos.md).
- El resumen de todos los servicios activos en la infraestructura se consolida en [`servicios.md`](servicios.md).
