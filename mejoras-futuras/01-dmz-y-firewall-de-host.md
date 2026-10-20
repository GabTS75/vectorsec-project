# Mejora futura 01 — DMZ y firewall de host "desde el minuto cero"

**Estado:** propuesta documentada, **no implementada** en esta versión del proyecto.
**Origen:** feedback del profesorado durante la revisión del proyecto intermodular.
**Afecta a:** [Módulo 1](../modulo1-hardware/README.md) · [Módulo 2](../modulo2-sistemas-operativos/README.md) · [Módulo 3](../modulo3-redes/README.md)

> **Reconocimiento:** Agradecimiento especial a la profesora Olga, por su su tiempo y dedicación, es gracias a profesores como ella que mejoramos en lo profesional y personal.

---

## 1. De qué se trata (en corto)

Del comentario recibido salen **dos ideas distintas**, y conviene no mezclarlas:

1. **Firewall de host desde el minuto cero.** Entiendo que, de cada sistema operativo nazca con su propio cortafuegos activo y con reglas explícitas, no como un parche posterior. Es **una capa más de defensa** *dentro* de cada equipo.
2. **Zona desmilitarizada (DMZ).** Implemetar una subred intermedia, **aislada tanto de Internet como de la red interna**, donde viven los servicios que *necesitan* ser alcanzables desde fuera. Si uno de ellos cae, el atacante sigue teniendo otro cortafuegos delante de lo verdaderamente importante.

La analogía que uso para tenerlas claras: la primera es **la cerradura de cada puerta**; la segunda es **el vestíbulo del edificio**, con seguridad en la puerta de la calle y otra en la de las oficinas.

## 2. Dónde estamos ahora mismo

Esto es lo que ya hay en el proyecto, sin maquillajes:

| Equipo | Firewall de host | Dónde está documentado |
| :--- | :--- | :--- |
| `SRV-APP01` (Ubuntu) | Activo (UFW): solo SSH y PostgreSQL desde VLAN 10 | [SRV-APP01 · Paso 11](../modulo2-sistemas-operativos/servidores/SRV-APP01.md#paso-11--configurar-el-firewall-ufw) |
| `SRV-LAB01` (Kali) | Activo (UFW): `deny incoming` por defecto, solo VLAN 40 | [SRV-LAB01 · apartado 6](../modulo2-sistemas-operativos/servidores/SRV-LAB01.md) |
| `SRV-DC01` (Windows Server) | **No documentado** | [SRV-DC01](../modulo2-sistemas-operativos/servidores/SRV-DC01.md) |
| `SRV-NAS` (OpenMediaVault) | Solo restricción de SMB por red; **sin cortafuegos de host documentado** | [SRV-NAS · Paso 13](../modulo2-sistemas-operativos/servidores/SRV-NAS.md) |
| 16 PCs cliente (Windows 11) | **No documentado** | [equipos-cliente](../modulo2-sistemas-operativos/equipos-cliente.md) |

**Un poquito de honestidad:** el Firewall de Windows viene activado por defecto, así que **"no documentado"** no significa **"desprotegido"**. Significa que no hay una configuración *deliberada, verificada y justificada*, que es lo que un proyecto de seguridad debería enseñar.

**En cuanto a la DMZ:** la red actual ([Módulo 3](../modulo3-redes/README.md#3-segmentación-lógica--vlans)) **no tiene ningún servicio expuesto a Internet en local**. La web corporativa es estática y vive fuera, y el portal de clientes se resolvió en la nube ([Módulo 6](../modulo6-cloud-aws/README.md)). Una DMZ sin nada dentro no estaría justificada, y por eso no lo consideré.

## 3. Propuesta

### 3.1 Firewall de host (Módulo 2)

- **`SRV-DC01`:** Firewall de Windows activo en todos los perfiles, con reglas de entrada limitadas a los puertos de AD/DNS y solo desde las VLAN internas necesarias.
- **`SRV-NAS`:** cortafuegos de host en OpenMediaVault, además de la restricción SMB que ya existe.
- **16 PCs cliente:** el firewall se activa y configura **en la imagen base** antes de hacer `Sysprep`, de modo que cada equipo clonado nace ya protegido, y se refuerza con una **GPO** para que nadie lo desactive en local. Aquí sí encajaría el flujo de [Sysprep + Clonezilla](../modulo2-sistemas-operativos/equipos-cliente.md): la imagen sería esa, "desde el minuto cero" de cada cliente.
- **Verificación:** igual que ya hice con `SRV-LAB01`, comprobar que el firewall de host y la ACL del router coinciden, y que si uno falla el otro sigue conteniendo.

### 3.2 DMZ (Módulos 3, 1 y 2)

Para que la **DMZ** tenga una razón de ser real, propongo un servicio acorde al negocio: un **servidor VPN** para que los consultores de `VectorSec` se conecten de forma segura desde instalaciones de clientes durante una auditoría o un pentest.

| Módulo | Qué cambiaría |
| :--- | :--- |
| [Módulo 3 — Redes](../modulo3-redes/README.md#9-políticas-de-acceso--acls) | Nueva VLAN de DMZ (ID 90, libre en el plan actual) con su subinterfaz en el router. Reglas: Internet → DMZ solo el puerto del servicio VPN; DMZ → LAN **denegado por defecto**, con excepciones mínimas y explícitas; LAN → DMZ solo gestión desde la VLAN 99. |
| [Módulo 1 — Hardware](../modulo1-hardware/README.md#3-servidores) | Un servidor adicional pequeño (`SRV-VPN01`) o una máquina virtual dedicada. Pasaría de 4 a 5 servidores. |
| [Módulo 2 — Sistemas Operativos](../modulo2-sistemas-operativos/README.md) | Instalación y bastionado del servidor VPN, con firewall de host activo desde la primera configuración y verificación cruzada con las ACL, como en `SRV-LAB01`. |

## 4. Por qué la dejo como mejora futura y no la implemento ahora

- **No hay en estos momentos un servicio que lo justifique.** Añadir una DMZ vacía sería decoración, no diseño.
- **Una DMZ robusta pide un cortafuegos dedicado.** Mi diseño actual enruta con **Router-on-a-Stick** y **controla con ACL**, considero que es suficiente para el alcance actual. Para una **DMZ seria** convendría un firewall perimetral con inspección de estado, igual que ya dejé documentada la migración a un switch de Capa 3 como mejora futura en el [Módulo 3](../modulo3-redes/README.md#11-conclusiones).
- **Coste de coherencia.** Tocaría tres módulos ya cerrados y verificados; prefiero cerrarlos bien antes que abrir frentes nuevos sin poder probarlos con el mismo rigor.

## 5. Cómo lo justifico o defiendo

> Diría que, hoy `VectorSec` no expone ningún servicio propio a Internet, así que una DMZ no tendría nada que proteger. Si mañana añadimos un acceso VPN para los consultores, ese servicio pasaría a una subred aislada con denegación por defecto hacia la LAN, de forma que un fallo en él no comprometa los servidores internos. Mientras tanto, el cortafuegos de cada equipo es la segunda cerradura de cada puerta, y mi siguiente paso sería completar esa cobertura en el DC, el NAS y la imagen de los clientes.

## 6. Orden de implementación sugerido

1. Firewall de host en `SRV-DC01` y `SRV-NAS` (bajo riesgo, alto valor).
2. Firewall en la imagen base de los clientes + GPO.
3. Diseño de la VLAN de DMZ y sus ACL en el Módulo 3.
4. `SRV-VPN01`: hardware (Módulo 1) y bastionado (Módulo 2).
5. Pruebas cruzadas: acceso desde fuera hacia la DMZ permitido, DMZ hacia LAN bloqueado, y comprobación de que cada capa falla de forma independiente.
