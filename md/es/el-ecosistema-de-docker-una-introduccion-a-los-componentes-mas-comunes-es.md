---
author: Justin Ellingwood
date: 2015-05-26
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/el-ecosistema-de-docker-una-introduccion-a-los-componentes-mas-comunes-es
---

# El Ecosistema de Docker: Una Introducción a los Componentes más Comunes

### Introducción

La contenerización es el proceso de distribuir y desplegar aplicaciones de forma portátil y predecible. Esto se logra mediante el empaquetado de componentes y sus dependencias, en entornos de procesos aislados, ligeros y estandarizados llamados contenedores. Muchas organizaciones están interesadas en diseñas aplicaciones y servicios que puedan ser desplegadas con facilidad en sistemas distribuidos, permitiendo al sistema escalar facilmente y sobrevivir ante las fallas de la máquina y aplicación. Docker, una plataforma de desarrollo para simplificar y estandarizar el despliegue en varios ambientes, fue en gran medida fundamental para estimular la adopción de este estilo de diseño y administración de servicios. Una gran cantidad de software ha sido creada para construir sobre este ecosistema de administración de contenedores distribuidos.

## Docker y la contenerización

Docker es el software de contenerización más utilizado hoy día. Mientras que otros sistemas de contenerización existen, Docker hace la creación y administración de contenedores simple e integra diversas herramientas de código libre.

![Visión de Contenedor](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_ecosystem/Container-Overview.png)

En la imagen de arriba, puedes ver un ejemplo del flujo en el cual una aplicación registra su información de conexión con el sistema de descubrimiento de servicios. Una vez registrado, otra aplicación puede consultar el sistema de descubrimiento de servicios para averiguar como conectarse a la aplicación.

Estas herramientas se implementan a menudo como simples almacenes de llave-valor que se distribuyen entre el entorno agrupado del host. Generalmente, la llave-valor almacenada proporciona una API HTTP para acceder y configurar valores. Algunos incluyen medidas de seguridad como entradas encriptadas o mecanismos de control de acceso. Los valores distribuidos son escenciales para el manejo de los host Docker agrupados, además su principal funcion es proveer los detalles de auto-configuración para nuevos contenedores.

Algunas de las responsabilidades del servicio de descubrimiento almacenado son:

- Permitir a las aplicaciones obtener datos necesarios para conectar con los servicios de los cuales dependen.
- Permitir a los servicios registrar su información de conexión para la finalidad anterior.
- Proveer una ubicación global accesible para almacenar datos de configuración arbitrarios.
- Almacenar información sobre los miembros del grupo tanto como sea necesario por cualquier software de administración de grupos.

Algunos de las herramientas populares del descubrimiento de servicios y proyectos relacionados son:

- [etcd](how-to-use-etcdctl-and-etcd-coreos-s-distributed-key-value-store): descubrimiento de servicios / almacén de llaves-valor distribuido a nivel global
- [consul](an-introduction-to-using-consul-a-service-discovery-system-on-ubuntu-14-04): descubrimiento de servicios / almacén de llaves-valor distribuido a nivel global
- [zookeeper](an-introduction-to-mesosphere#a-basic-overview-of-apache-mesos): descubrimiento de servicios / almacén de llaves-valor distribuido a nivel global
- [crypt](http://xordataexchange.github.io/crypt/): proyecto para encriptar entradas etcd
- [confd](how-to-use-confd-and-etcd-to-dynamically-reconfigure-services-in-coreos): monitorea los cambios en llaves-valor y ejecuta servicios de re-configuración con los nuevos valores

Para aprender más acerca del descubrimiento de servicios con Docker visite nuestra guía [aquí](the-docker-ecosystem-service-discovery-and-distributed-configuration-stores).

## Herramientas de red

Aplicaciones en contenedores se prestan en un diseño orientado a servicio que alienta romper funcionalidad en componentes discretos. Si bien esto hace más fácil la administración y escalabilidad, requiere aún más seguridad en cuanto a funcionalidad y fiabilidad de red entre componentes. Docker proporciona por si mismo la estructura de red básica necesaria para la comunicación de contenedor-a-contenedor y contenedor-a-host.

Las capacidades nativas de Docker proporcionan dos mecanismos para conectar contenedores entre si. El primero consiste en exponer los puertos del contenedor y opcionalmente asignar al sistema host para enrutamiento externo. Puedes selecionar el puerto del host a asignar o permitir a Docker seleccionar un puerto sin usar al azar. Esta es la forma genérica de proporcionar acceso a un contenedor que funciona bien para la mayoría de los propósitos.

El otro método es permitir a los contenedores comunicarse utilizando enlaces Docker. Un contenedor enlazado obtendrá información de conexión sobre su contraparte, lo que le permite conectarse automáticamente si está configurado para prestar atención a esas variables. Esto permite la comunicación entre contenedores en el mismo host sin tener conocimiento previo del puerto o la dirección donde el servicio está ubicado.

Este nivel de red básico es adecuado para un host-simple o entornos ecosistema de Docker puede producir una variedad de proyectos que enfocan o expanden la funcionaidad de la red disponible para los operadores y desarrolladores. Algunas capacidades de red adicionales disponibles a través de herramientas adicionales incluyen:

- Superposición de redes para simplificar y unificar el espacio de direcciones entre varios hosts.
- Las redes privadas virtuales adaptadas para proporcionar comunicación segura entre varios componentes.
- Asignación de subredes por host o aplicación.
- Establecimiento de interfaces macvlan para comunicación.
- Configuración de direcciones MAC personalizadas, puertas de enlace, etc. para contenedores.

Algunos de los proyectos involucrados en mejorar la red en Docker son:

- **flannel** : Superposición de redes proporcionando a cada host una subred independiente.
- **weave** : Superposición de red que trata a todos los contenedores como una sola red.
- **pipework** : Ki de herramientas de red avanzadas para configuraciones de red abitrariamente avanzadas.

Para una mirada más a fondo de los diferentes enfoques para la creación de redes en Docker, haga clic [aquí](the-docker-ecosystem-networking-and-communication).

## Planificación, administración de grupo y orquestación

Otro componente necesario en la construcción de un grupo de contenedores es un planificador. Los planificadores son los responsables de iniciar los contenedores en los host disponibles.

![Ejemplo: Planificador de Aplicaciones](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_ecosystem/Example-Schedule-App-F.png)

La imagen de arriba demuestra una decisión simplificada de planificación. La petición se dá a través de una API o herramienta administrativa. Desde aquí, el planificador evalúa las condiciones de la petición y el estado de los hosts disponibles. En este ejemplo, se extrae información sobre la densidad del contenedor de un almacen de datos distribuido / servicio de descubrimiento (como se discutió previamente) para que sea posible colocar una nueva aplicación en el host menos ocupado.

Este proceso de selección de host es una de las responsabilidades del planificador. Usualmente, tiene funciones que automatizan este proceso con el administrador teniendo la opción de especificar ciertas limitaciones. Algunas de estas limitaciones pueden ser:

- Planificar un contenedor en el mismo host que otro.
- Asegurar que el contenedor no está coloque en el mismo host que otro.
- Colocar el contenedor en un host con la etiqueda o metadatos de la máquina.
- Colocar el contenedor en el contenedor en el host menos ocupado.
- Correr el contenedor en cada host del grupo.

El planificador es responsable de cargar contenedores en host pertinentes e iniciar, detener y administrar el ciclo de vida del proceso.

Debido a que el planificador debe interactuar con cada host en el grupo, las funciones del administrador de grupo típicamente están incorporadas. Estas permiten al planificador obtener información acerca de los miembros y realizar tareas administrativas. Orquestación en este contexto generalmente se refiere a la combinación de un contenedor y la planificación de administración del host.

Algunos de los proyectos más populares que funcionan como planificadores y herramientas de gestión de flotas son:

- [fleet](how-to-use-fleet-and-fleetctl-to-manage-your-coreos-cluster): planificador y herramienta de gestión de grupos.
- [marathon](an-introduction-to-mesosphere#a-basic-overview-of-marathon): planificador y herramientaq de gestión de servicios.
- [Swarm](https://github.com/docker/swarm/): planificador y herramientaq de gestión de servicios.
- [mesos](an-introduction-to-mesosphere#a-basic-overview-of-apache-mesos): servicio de abstracción en el host que consolida los recursos del host para el planificador.
- [kubernetes](an-introduction-to-kubernetes): planificador avanzado capaz de gestionar grupos de contenedores.
- [compose](https://github.com/docker/docker/issues/9694): herramienta de orquestación de contenedores para la creación de grupos de contenedores.

Para saber más acerca de planificación básica, grupo de contenedores y software de administración de grupos para Docker, haga clic [aquí](the-docker-ecosystem-scheduling-and-orchestration).

## Conclusión

Por ahora, usted debe estar famil familiarizado con la función general de la mayor parte del software asociado con el ecosistema Docker. Por si solo Docker, junto con todos los proyectos de apoyo, proporciona una estrategia de gestión, diseño e implementación de software que permite una escalabilidad masiva. Mediante la comprensión y el aprovechamiento de las capacidades de varios proyectos puedes ejecutar implementaciones de aplicaciones complejas que son suficientemente flexibles como para tener en cuenta los distintos requisitos de operación.
