---
author: Justin Ellingwood
date: 2015-05-26
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/el-ecosistema-de-docker-creacion-de-redes-y-comunicacion-es
---

# El Ecosistema de Docker: Creación de Redes y Comunicación

### Introducción

Cuando se construyen sistemas distribuidos para funcionar como contenedores de Docker, la comunicación y la creación de redes se vuelve extremadamente importante. En una arquitectura orientada a servicio, sin lugar a dudas, se basa en gran medida en la comunicación entre los componentes para que funcionen correctamente.

En esta guía, hablaremos de varias estrategias de creación de redes y herramientas utilizadas para moldear las redes utilizadas por los contenedores a su estado ideal. Algunas situaciones pueden tomar ventaja de las soluciones nativas de Docker, mientras que otran deben utilizar proyectos alternativos.

## Implementación nativa de Docker para creación de redes

Por sí mismo, Docker proporciona los fundamentos necesarios para la creación de redes y comunicación de contenedor-a-contenedor y de contenedor-a-host.

Cuando el proceso de Docker nace, configura una nueva interfaz puente virtual llamada docker0 en el sistema host. Esta interface permite a Docker crear una sub-red virtual para el uso de los contenedores que se ejecutarán. Este puente funciona como el punto o interfaz principal entre la creación de redes en el contenedor y el host.

Cuando un contenedor es inicializado por Docker, una nueva interfaz virtual se crea y se le proporciona una dirección en el rango de la sub-red. La dirección IP es asignada al intervalo de la red del contenedor, proporcionando a la red del contenedor una ruta al puente docker0 en el sistema host. Docker automáticamente configura las reglas en iptables que permitirán redirigir y condigurar la máscara NAT para el tráfico originado en la interfaz docker0 hacia el resto del mundo.

### ¿Cómo los contenedores exponen servicios a los consumidores?

Otros contenedores en el mismo host podrán acceder alos servicios proporcionados por sus vecinos sin configuraciones adicionales. El sistema host simplemente enruta las peticiones originadas por y destinadas a la interfaz docker0 a la ubicación adecuada.

Los contenedores pueden exponer sus puertos al host, donde es que estos reciben el tráfico redirigido hacia el mundo exterior. Los puertos expuestos pueden ser mapeados al sistema host, tan solo con seleccionar un puerto específico o dejando a Docker seleccionar un puerto al azar, alto y sin usar. Docker se encarga de todas la configuración en las reglas de redirección e iptables en estas situaciones.

### ¿Cúal es la diferencia entre puertos expuestos y puertos púlicos?

Cuando se crean imágenes de contenedores o se ejecutan contenedores, tienes la opción de exponer los puertos o publicarlos. La diferencia está entre los dos es significativa, pero puede no ser inmediatamente discernible.

Exponer un puerto simplemente significa que Docker identificará que el puerto en cuestión es utilizado por el contenedor. Este entonces puede ser utilizado para propósitos de descubrimiento y enlace. Por instancia, inspeccionar un contenedor te resultará en información acerca de los puertos expuestos. Cuando los contenedores se enlazan, las variables de entorno se configuran en el nuevo contenedor que indica los puertos expuestos en el contenedor original.

Por defecto, los contenedores pueden ser accesibles desde el sistema host y solo otros contenedores del host, independientemente si los puertos están expuestos o no. Exponiendo el puerto simplemente documenta el uso del puerto y crea la información a disposición para los mapeos y enlaces automáticos.

En contraste, publicar un puerto lo mapeará a la interfaz del host, de esta manera se hace público hacia el exterior. Los puertos del contenedor también pueden ser mapeados a un puerto específico del host o dejar a Docker seleccionar uno alto al azar, y sin utilizar.

### ¿Qué son los enlaces de Docker?

Docker proporciona mecanismos llamados “enlaces” para configurar la comunicación entre contenedores. Si un nuevo contenedor es enlazado a un contenedor existente, el nuevo contenedor obtendra la iformación de conexión de un contenedor existente a través de las variables de entorno.

Esto porporciona un camino fácil para establecer comunicación entre dos contenedores proporcionando al nuevo contenedor la información explícita sobre como acceder a su compañero. Las variables de entorno son configuradas acorde a los puertos expuestos por el contenedor. La dirección IP y el resto de la información será llenada por Docker.

## Proyectos para expandir las capacidades de creación de redes de Docker

El modelo de creación de redes discutido arriba proporciona un buen punto de partida para la contrucción de la red. La comunicación entre los contenedores en el mismo host es básicamente sencilla y la comunicación entre host puede ocurrir sobre las redes regulares mientras los puertos hayan sido mapeados correctamente y la información de conexión sea proporcionada a la otra parte.

Aún así, muchas aplicaciones requieren ambientes de conexión específicos para propósitos de seguridad o funcionalidad. La creación de redes nativas en Docker es algo limitada en estos escenarios. A consecuencia de esto, muchos proyectos han sido creados para expandir el ecosistema de redes de Docker.

### Creando redes superpuestas para abstraer las topologías subyacentes

Una mejora funcional a la que muchos proyectos se han enfocado es la de establecer redes superpuestas. Una red superpuesta es una red virtual construída por encima de las conexiones de red existentes.

Estableciendo redes superpuestas es posible crear redes más predecibles y uniformes entre hosts. Esto simplifica la creación de redes entre contenedores o donde estén corriendo. Una red virtual simple puede abarcar múltiples hosts o sub-redes específicas para cada host entre una red unificada.

Otro uso de la superposición de red es en la construcción de grupos de computo unificado. En computación unificada, varios hosts se abstraen a distancia y se gestionan como uno solo, una entidad más poderosa. La implementación de una capa de computo unificado permite al usuario final administrar el grupo como uno solo en lugar de host individuales. La creación de redes juega una gran parte en este grupo.

### Configuración avanzada en creación de redes

Otros proyectos para expandir las capacidades para crear redes con Docker es proporcionar más flexibilidad.

La configuración de red por defecto de Docker es funcional, pero bastante simple. Estas limitaciones se expresan con claridad cuando lidiamos con creación de redes transversales de hosts, pero también puede impedir más la personalización cuando se crea una red en un host simple.

Funcionalidades adicionales son proporcionadas a través de capacidades de “tuberías”. Estos proyectos no proporcionan una configuración “fuera de la caja”, pero te permiten enganchar manualmente ambas piezas creando escenarios de red complejos. Algunas de las habilidades que puedes obtener son desde establecer redes privadas entre varios hosts, hasta configurar puentes, vlans, sub-redes y puertas de enlace personalizados.

Existen numerosas herramientas y proyectos que, aunque no fueron pensadas para Docker, también ofrecen entornos en Docker para proveer la funcionalidad necesaria. En particular, la creación de redes privadas maduras y las tecnologías de tunel son usualmente utilizadas para proveer comunicación segura entre host y contenedores.

## ¿Cuáles son algunos de los proyectos para mejorar la creación de redes con Docker?

Existen algunos proyectos diferentes enfocados en proporcionar creación de redes superpuestas para hosts Docker. Las más comunes son:

- **flannel** : Desarrollada por el equipo de CoreOS, este proyecto fue inicialmente desarrollador para proporcionar a cada sistema host su propia sub-red en una red compartida. Esta es una condición necesaria para la herramienta de orquestación de Kubernetes de Google funcione, pero es muy útil en otras situaciones.
- **weave** : Weave crea una red virtual que conecta a cada máquina host entre sí. Esto simplifica el enrutamiento de la aplicación debido a que aparenta que cada contenedor está conectado a un conmutador de red única.

En términos de creación de redes avanzadas, los siguientes proyectos ayudan a llenar esta vacante proporcionando tuberías adicionales:

- **pipework** : Creado como una medida provisional, hasta que la creación de redes con Docker sea más avanzada, este proyecto permite configurar fácilmente redes arbitrariamente avanzadas.

Un ejemplo más relevante del software existente para complementar la funcionalidad de Docker es:

- **tinc** : Tinc es un software de VPN ligero que se implementa usando túneles y encriptado. Tinc es una solución robusta que puede hacer una red privada transparente ante cualquier aplicación.

## Conclusión

Proporcionar servicios internos y externos a través de componentes contenerizados es un modelo muy poderoso, pero las consideraciones de creación de redes se vuelven una prioridad. Mientras Docker proporciona algunas de las funcionalidades nativamente a través de la configuración de interfaces, sub-red, iptables y la administración de la tabla NAT, otros proyectos fueron creados para proporcionar configuraciones más avanzadas.

En la siguiente guía, hablaremos sobre cómo las herramientas de planificación y orquestación intervienen para proporcionar una administración funcional en los contenedores agrupados.
