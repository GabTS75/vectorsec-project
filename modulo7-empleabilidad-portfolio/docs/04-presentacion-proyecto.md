# Presentación del proyecto — `VectorSec`

Así es como presentaría mi proyecto intermodular si me lo preguntaran en una entrevista técnica.

## ¿Qué es?

`VectorSec` es **el diseño completo de la infraestructura IT de una empresa de ciberseguridad ficticia**, desarrollado como proyecto intermodular de mi ciclo (*ASIR + especialización en Ciberseguridad*). Cubre los siete módulos del ciclo sobre un único escenario coherente: hardware, sistemas operativos, redes, base de datos, documentación web, cloud (AWS) y este mismo portfolio.

## ¿Qué problema resuelve?

En realidad, no resuelve un problema de un cliente real, pero sí resuelve el problema que tenía yo como estudiante: demostrar que sé diseñar una infraestructura completa razonando como lo haría un administrador de sistemas real, no solo ejecutando pasos sueltos de cada asignatura por separado. Cada decisión técnica *—desde cuántos servidores necesita la empresa hasta si migrar o no a la nube—* está tomada con una justificación de negocio detrás, no solo "porque toca hacerlo".

## ¿Para quién está pensado?

Decidí realizarlo pensando en dos tipos de lector, a propósito: **un tribunal académico** (*mis profesores*) que evaluarán si cubro adecuadamente los contenidos de los 7 módulos (*no lo hice por la nota, sé que siempre se puede mejorar*), y **un reclutador o responsable técnico** que quiera ver cómo razono y resuelvo ante decisiones reales de infraestructura — *por eso todo está documentado como si fuera un proyecto de empresa real, no como un ejercicio más de clase*.

## ¿Qué tecnologías utiliza?

- **Redes:** Cisco Packet Tracer — 9 VLANs, enrutamiento Router-on-a-Stick, ACLs, acceso SSH restringido
- **Sistemas:** Windows Server + Active Directory, Linux (Ubuntu Server, Kali Linux), Wazuh (SIEM)
- **Base de datos:** PostgreSQL, modelo E-R, roles de acceso por mínimo privilegio
- **Documentación:** XML validado con XSD, web corporativa en HTML/CSS
- **Cloud:** arquitectura de extensión en AWS (EC2, RDS, S3, CloudFront)

## ¿Qué he aprendido desarrollándolo?

Dos cosas, una técnica y otra de método.

**La técnica:** a aplicar el mismo criterio de seguridad en varias capas independientes (red, sistema operativo, base de datos) en lugar de confiar en una sola barrera — *lo que en el proyecto llamo **"defensa en profundidad"**, y que apliqué de forma repetida en distintos módulos a lo largo del desarrollo del proyecto*.

**La de método:** a documentar también los errores, no solo los aciertos. Durante el proyecto cometí fallos reales *—una subred de gestión mal calculada, un modelo de switch que no existía en el catálogo, un puerto duplicado en la configuración—* y en vez de "limpiarlos" del resultado final, decidí dejar constancia de cómo los detecté y resolví. Creo que eso dice más de mi forma de trabajar, que un "proyecto perfecto" a la primera.

## Enlaces

- Repositorio completo: [`VectorSec`](https://github.com/GabTS75/vectorsec-project)
- Portfolio: [gabts75.github.io/gabrielternero](https://gabts75.github.io/gabrielternero/)
