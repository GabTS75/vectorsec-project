# Usuarios y Permisos — Active Directory (vectorsec.local)

## 1. Análisis y diseño de la estructura

Con `SRV-DC01` ya operativo como controlador de dominio (ver `servidores/SRV-DC01.md`) y los 16 equipos cliente ya unidos al dominio (ver `equipos-cliente.md`), este documento define **cómo se organizan dentro de ese dominio**: qué Unidades Organizativas (**OU**) existen, qué usuarios y grupos se crean, y qué políticas de grupo (**GPO**) se aplican a cada uno.

### 1.1 ¿Qué es una OU y por qué la necesitamos?

Una **Unidad Organizativa (OU)** es, dicho de forma sencilla, una "carpeta" dentro de Active Directory donde se agrupan usuarios, equipos o grupos que deben recibir el mismo tratamiento (las mismas políticas, los mismos permisos). Sin **OUs**, todos los usuarios y equipos del dominio estarían mezclados en un único contenedor, y aplicar una política distinta a Dirección que a Recepción sería mucho más difícil de gestionar y de auditar.

### 1.2 Usuarios y equipos en OUs separadas

Hemos considerado antes de construir este documento, separar **las OUs de usuarios y de equipos**, en lugar de mezclarlos en **una única OU por departamento**. La razón es que una **GPO** siempre tiene dos mitades — *configuración de equipo y configuración de usuario* — y aplicarla sobre una **OU mixta** procesa ambas mitades sobre todo lo que hay dentro, aunque solo se necesite una. Separarlas permite enlazar cada **GPO** exactamente donde corresponde.

### 1.3 Estructura completa

```text
vectorsec.local
└── OU=VectorSec
    ├── OU=Usuarios
    │   ├── OU=Recepcion
    │   ├── OU=Administracion
    │   ├── OU=Direccion
    │   ├── OU=Desarrollo
    │   ├── OU=Soporte
    │   └── OU=Formacion
    ├── OU=Equipos
    │   ├── OU=Recepcion
    │   ├── OU=Administracion
    │   ├── OU=Direccion
    │   ├── OU=Desarrollo
    │   ├── OU=Soporte
    │   └── OU=Formacion
    └── OU=Grupos
        └── (grupos de seguridad, uno por departamento)
```

> 📌 **Nota:** esta estructura de OUs solo aplica a los 16 equipos cliente Windows y a sus usuarios. Los servidores Linux (`SRV-APP01`, `SRV-LAB01`, `SRV-NAS`) no están unidos al dominio, y `SRV-DC01` reside en la OU `Domain Controllers`, creada automáticamente por Windows Server y fuera de esta estructura personalizada.

### 1.4 Patrón de nombres de usuario

Cada usuario se crea con el patrón `nombre.apellido` (ejemplo: `Juan Pérez` → `juan.perez`), tanto para el nombre de inicio de sesión como para el correo/UPN interno (ejemplo: `juan.perez@vectorsec.local`).

---

## 2. Plan de implantación

1. Crear la estructura de OUs (`VectorSec` → `Usuarios`/`Equipos`/`Grupos`, con sus subcarpetas por departamento).
2. Crear los grupos de seguridad, uno por departamento.
3. Crear los usuarios mediante importación desde un **archivo CSV** (evita repetir 16 veces el mismo comando manualmente — *mismo criterio de eficiencia ya aplicado al clonar los equipos cliente*).
4. Mover cada uno de los 16 equipos, ya unidos al dominio, desde la OU `Computers` por defecto a su OU de equipos correspondiente.
5. Crear y enlazar las GPOs de equipo y de usuario, por departamento.
6. Configurar permisos NTFS sobre las carpetas compartidas, basados en los grupos de seguridad creados.
7. Verificar el conjunto completo.

---

## 3. Creación de la estructura de OUs

### Paso 1 — Crear la OU raíz y las tres ramas principales

**Acción (en `SRV-DC01`, PowerShell como Administrador de dominio):**

```powershell
New-ADOrganizationalUnit -Name "VectorSec" -Path "DC=vectorsec,DC=local"
New-ADOrganizationalUnit -Name "Usuarios" -Path "OU=VectorSec,DC=vectorsec,DC=local"
New-ADOrganizationalUnit -Name "Equipos" -Path "OU=VectorSec,DC=vectorsec,DC=local"
New-ADOrganizationalUnit -Name "Grupos" -Path "OU=VectorSec,DC=vectorsec,DC=local"
```

**Resultado esperado:** sin salida en consola (ejecución silenciosa) si cada comando se ejecuta sin errores.

**Verificación:**

```powershell
Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchBase "OU=VectorSec,DC=vectorsec,DC=local"
```

Debe listar las 3 OUs recién creadas (`Usuarios`, `Equipos`, `Grupos`), además de la propia `VectorSec`.

---

### Paso 2 — Crear las subcarpetas por departamento

**Acción:**

```powershell
$departamentos = "Recepcion","Administracion","Direccion","Desarrollo","Soporte","Formacion"

foreach ($dep in $departamentos) {
    New-ADOrganizationalUnit -Name $dep -Path "OU=Usuarios,OU=VectorSec,DC=vectorsec,DC=local"
    New-ADOrganizationalUnit -Name $dep -Path "OU=Equipos,OU=VectorSec,DC=vectorsec,DC=local"
}
```

> 📌 **Sobre este bucle `foreach`:** en lugar de escribir 12 comandos `New-ADOrganizationalUnit` a mano (6 departamentos × 2 ramas), se recorre la lista de departamentos una sola vez y se crea la OU correspondiente en ambas ramas — *el mismo principio de "no repetir manualmente lo que se puede automatizar" que ya aplicamos al clonar los equipos cliente*.

**Resultado esperado:** sin errores durante la ejecución del bucle.

**Verificación:**

```powershell
Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchBase "OU=VectorSec,DC=vectorsec,DC=local" | Select-Object Name, DistinguishedName
```

Debe listar 12 OUs de departamento (6 bajo `Usuarios`, 6 bajo `Equipos`), además de las 3 ramas principales.

---

## 4. Creación de los grupos de seguridad

### Paso 3 — Crear un grupo de seguridad por departamento

**Acción:**

```powershell
foreach ($dep in $departamentos) {
    New-ADGroup -Name "GG_$dep" `
      -GroupScope Global `
      -GroupCategory Security `
      -Path "OU=Grupos,OU=VectorSec,DC=vectorsec,DC=local"
}
```

> 📌 **Sobre el prefijo `GG_`:** es una convención de nomenclatura habitual en AD para identificar de un vistazo que se trata de un **"Grupo Global"** de seguridad (por ejemplo, `GG_Direccion`), diferenciándolo de otros posibles tipos de grupo que pudieran añadirse en el futuro (de distribución, universales, etc.).

**Resultado esperado:** sin errores durante la ejecución.

**Verificación:**

```powershell
Get-ADGroup -Filter 'Name -like "GG_*"' | Select-Object Name
```

Debe listar los 6 grupos creados (`GG_Recepcion`, `GG_Administracion`, `GG_Direccion`, `GG_Desarrollo`, `GG_Soporte`, `GG_Formacion`).

---

## 5. Creación de usuarios mediante importación `CSV`

### 5.1 ¿Por qué un `CSV` en lugar de crear cada usuario manualmente?

Con 16 usuarios (uno por cada uno de los 16 equipos, mínimo — *puede haber más de un usuario por equipo compartido, como en el Aula*) repetir el mismo comando `New-ADUser` uno por uno es tedioso y propenso a errores de transcripción. Un archivo **CSV** (valores separados por comas, como una hoja de cálculo simplificada) permite definir todos los usuarios de una vez, y un único script los crea a todos leyendo ese archivo — *el mismo enfoque de "plantilla + datos" que ya usamos con la imagen de referencia de los equipos cliente*.

### Paso 4 — Crear el archivo `usuarios.csv`

**Acción:** crear un archivo `usuarios.csv` con el siguiente contenido (fila de ejemplo por departamento; se completa de igual forma con el resto de personal):

```csv
Nombre,Apellido,Departamento
Juan,Perez,Administracion
Maria,Gomez,Administracion
Laura,Ruiz,Recepcion
Carlos,Diaz,Recepcion
Ana,Torres,Direccion
Pedro,Navarro,Direccion
Sara,Iglesias,Desarrollo
David,Moreno,Desarrollo
Elena,Castro,Soporte
Marcos,Vega,Soporte
Lucia,Ramos,Formacion
Pablo,Ortiz,Formacion
```

**Resultado esperado:** archivo de texto plano guardado con extensión `.csv`, codificación UTF-8.

**Verificación:** al abrir el archivo con `Import-Csv` (ver Paso 5) sin que devuelva errores de formato, se confirma que las comas y encabezados están correctamente escritos.

---

### Paso 5 — Ejecutar el script de creación de usuarios

**Acción:**

```powershell
$usuarios = Import-Csv -Path "C:\Scripts\usuarios.csv"

foreach ($u in $usuarios) {
    $samAccountName = ($u.Nombre + "." + $u.Apellido).ToLower()
    $ouPath = "OU=$($u.Departamento),OU=Usuarios,OU=VectorSec,DC=vectorsec,DC=local"

    New-ADUser -Name "$($u.Nombre) $($u.Apellido)" `
      -SamAccountName $samAccountName `
      -UserPrincipalName "$samAccountName@vectorsec.local" `
      -Path $ouPath `
      -AccountPassword (ConvertTo-SecureString "VectorSec2026!" -AsPlainText -Force) `
      -ChangePasswordAtLogon $true `
      -Enabled $true

    Add-ADGroupMember -Identity "GG_$($u.Departamento)" -Members $samAccountName
}
```

> 📌 **Sobre `-ChangePasswordAtLogon $true`:** la contraseña `VectorSec2026!` es solo una contraseña **temporal e idéntica para todos** en el momento de la creación — *el parámetro obliga a cada usuario a cambiarla por una propia en su primer inicio de sesión, evitando el mismo problema de "credencial compartida" que identificamos y resolvimos al preparar la imagen de los equipos cliente (Modo Auditoría), aplicado aquí a nivel de **cuentas de usuario***.

**Resultado esperado:** sin errores durante la ejecución del bucle; cada usuario queda creado en la OU de su departamento y añadido a su grupo de seguridad correspondiente.

**Verificación:**

```powershell
Get-ADUser -Filter 'Name -like "*"' -SearchBase "OU=Usuarios,OU=VectorSec,DC=vectorsec,DC=local" | Select-Object Name, DistinguishedName
```

Debe listar los usuarios creados, cada uno dentro de la OU correcta.

```powershell
Get-ADGroupMember -Identity "GG_Direccion"
```

Debe mostrar los usuarios de Dirección (`ana.torres`, `pedro.navarro`) como miembros del grupo.

---

## 6. Ubicar los equipos en su OU correspondiente

### Paso 6 — Mover cada equipo desde `Computers` a su OU de departamento

Cuando un equipo se une al dominio (como se hizo en `equipos-cliente.md`, Paso 12), Windows lo coloca por defecto en el contenedor genérico `Computers`, no en la estructura de OUs personalizada. Hay que moverlo manualmente.

**Acción:**

```powershell
$equipos = @{
    "PC-REC1"  = "Recepcion";  "PC-REC2"  = "Recepcion"
    "PC-ADM1"  = "Administracion"; "PC-ADM2" = "Administracion"
    "PC-DIR1"  = "Direccion";  "PC-DIR2"  = "Direccion"
    "PC-DES1"  = "Desarrollo"; "PC-DES2"  = "Desarrollo"
    "PC-SOP1"  = "Soporte";    "PC-SOP2"  = "Soporte"
    "PC-AULA1" = "Formacion"; "PC-AULA2" = "Formacion"; "PC-AULA3" = "Formacion"
    "PC-AULA4" = "Formacion"; "PC-AULA5" = "Formacion"; "PC-AULA6" = "Formacion"
}

foreach ($equipo in $equipos.Keys) {
    $dep = $equipos[$equipo]
    $destino = "OU=$dep,OU=Equipos,OU=VectorSec,DC=vectorsec,DC=local"
    Get-ADComputer -Identity $equipo | Move-ADObject -TargetPath $destino
}
```

**Resultado esperado:** sin errores durante la ejecución (si algún equipo aún no se ha unido al dominio, `Get-ADComputer` devolverá un error puntual para ese equipo concreto, sin interrumpir el resto del bucle).

**Verificación:**

```powershell
Get-ADComputer -Filter 'Name -like "*"' -SearchBase "OU=Equipos,OU=VectorSec,DC=vectorsec,DC=local" | Select-Object Name, DistinguishedName
```

Debe listar los 16 equipos, cada uno dentro de la OU de su departamento.

---

## 7. Políticas de grupo (GPO)

### 7.1 Diseño de GPOs

Siguiendo el patrón de nomenclatura acordado, se crean GPOs separadas de equipo y de usuario por departamento, más una GPO base aplicada a toda la OU `Equipos` con ajustes de seguridad comunes.

| GPO | Se enlaza en | Configura |
| :--- | :--- | :--- |
| `GPO_Equipos_Base` | `OU=Equipos` (toda la rama) | Bloqueo de pantalla tras inactividad, requisito de contraseña compleja, deshabilitar puertos USB de almacenamiento masivo |
| `GPO_Equipos_Formacion` | `OU=Formacion` (bajo Equipos) | Restringe la instalación de software por parte del usuario (solo el administrador puede instalar) |
| `GPO_Usuarios_Direccion` | `OU=Direccion` (bajo Usuarios) | Redirección de la carpeta "Documentos" hacia el recurso compartido de `SRV-NAS` |
| `GPO_Usuarios_Base` | `OU=Usuarios` (toda la rama) | Fondo de escritorio corporativo, ocultar unidades no autorizadas del Explorador de archivos |

> 📌 Por brevedad, este documento detalla **la creación de una GPO de cada tipo (equipo y usuario)** como ejemplo replicable — *el resto de GPOs de la tabla se crean siguiendo el mismo patrón exacto, cambiando únicamente el nombre y la OU de enlace*.

---

### Paso 7 — Crear y enlazar `GPO_Equipos_Base`

**Acción:**

```powershell
New-GPO -Name "GPO_Equipos_Base" | New-GPLink -Target "OU=Equipos,OU=VectorSec,DC=vectorsec,DC=local"
```

A continuación, editar la GPO desde **Administración de directivas de grupo** (`gpmc.msc`):

- **Configuración del equipo → Directivas → Plantillas administrativas → Panel de control → Personalización → Tiempo de espera del protector de pantalla**: 600 segundos (10 minutos)
- **Configuración del equipo → Directivas → Plantillas administrativas → Sistema → Acceso de almacenamiento extraíble → Todas las clases de almacenamiento extraíble: denegar todos los accesos**: Habilitada

**Resultado esperado:** la **GPO** aparece en `gpmc.msc` enlazada a `OU=Equipos`, con las dos configuraciones anteriores marcadas como **"Habilitada"**.

**Verificación (desde cualquier equipo cliente, tras forzar la actualización de políticas):**

```powershell
gpupdate /force
gpresult /r
```

`GPO_Equipos_Base` debe aparecer en la lista de **"Objetos de directiva de grupo aplicados"**. La restricción de almacenamiento **USB** puede comprobarse físicamente conectando un **USB** y verificando que el sistema no lo reconoce como unidad.

---

### Paso 8 — Crear y enlazar `GPO_Usuarios_Base`

**Acción:**

```powershell
New-GPO -Name "GPO_Usuarios_Base" | New-GPLink -Target "OU=Usuarios,OU=VectorSec,DC=vectorsec,DC=local"
```

Editar desde `gpmc.msc`:

- **Configuración de usuario → Directivas → Plantillas administrativas → Escritorio → Fondo de escritorio de Active Desktop**: ruta al fondo corporativo almacenado en `SRV-NAS`

**Resultado esperado:** la **GPO** aparece enlazada a `OU=Usuarios`.

**Verificación:** al iniciar sesión con cualquier usuario del dominio (ej. `juan.perez`), el fondo de escritorio corporativo debe aplicarse automáticamente tras `gpupdate /force` y reinicio de sesión.

---

## 8. Permisos NTFS sobre carpetas compartidas

### Paso 9 — Asignar permisos basados en grupos, no en usuarios individuales

**Acción (sobre el recurso compartido `backups-servidores` de `SRV-NAS`, o una nueva carpeta departamental si se crea):** en las propiedades de seguridad NTFS de la carpeta, conceder permisos al **grupo** `GG_Administracion` (no a cada usuario suelto):

| Grupo | Carpeta | Permiso |
| :--- | :--- | :--- |
| `GG_Administracion` | `\\SRV-NAS\Administracion` | Modificar |
| `GG_Direccion` | `\\SRV-NAS\Direccion` | Modificar |
| `GG_Desarrollo` | `\\SRV-NAS\Desarrollo` | Modificar |
| Todos los grupos | `\\SRV-NAS\Comun` | Lectura |

> 📌 **Por qué por grupo y no por usuario:** si mañana se contrata a una nueva persona en Dirección, basta con añadirla al grupo `GG_Direccion` para que herede automáticamente todos sus permisos — *sin tener que revisar y modificar manualmente cada carpeta compartida una por una*. Es el mismo principio de "gestionar por categoría, no por caso individual" que venimos aplicando en **ACLs de red (Módulo 3)** y en las GPOs de este mismo documento.

**Resultado esperado:** cada grupo aparece en la lista de permisos NTFS de su carpeta correspondiente, con el nivel de acceso indicado.

**Verificación (iniciando sesión como `juan.perez`, miembro de `GG_Administracion`):**

```powershell
Test-Path "\\SRV-NAS\Administracion" -PathType Container
```

Debe devolver `True` con acceso de escritura confirmado (crear un archivo de prueba). Al intentar acceder a `\\SRV-NAS\Direccion` con ese mismo usuario, debe recibir un error de **"Acceso denegado"**.

---

## 9. Checklist de verificación final

- [ ] Estructura de OUs creada (`VectorSec` → `Usuarios`/`Equipos`/`Grupos`, con 6 subcarpetas de departamento en cada rama)
- [ ] 6 grupos de seguridad `GG_*` creados
- [ ] Usuarios importados desde `usuarios.csv`, cada uno en su OU y grupo correcto
- [ ] Los 16 equipos movidos desde `Computers` a su OU de departamento
- [ ] `GPO_Equipos_Base` y `GPO_Usuarios_Base` creadas, enlazadas y verificadas con `gpresult /r`
- [ ] Resto de GPOs de la tabla (7.1) creadas siguiendo el mismo patrón
- [ ] Permisos NTFS asignados por grupo, no por usuario individual
- [ ] Acceso confirmado para el grupo correcto y denegado para grupos no autorizados

---

## 10. Próximos pasos relacionados

- El resumen de todos los servicios activos en la infraestructura, incluido Active Directory, se consolida en [`servicios.md`](servicios.md).
