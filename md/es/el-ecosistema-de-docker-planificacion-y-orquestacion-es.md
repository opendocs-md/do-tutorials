---
author: Justin Ellingwood
date: 2015-05-26
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/el-ecosistema-de-docker-planificacion-y-orquestacion-es
---

# El Ecosistema de Docker: Planificación y Orquestación

### Introducción

Las herramientas de Docker proporcionan todas las funciones necesarias para crear, subir, bajar, iniciar y detener los contenedores. Es muy adecuado para administrar estos procesos en ambientes de host simple con el mínimo número de contenedores.

Aún así, muchos usuarios de Docker aprovechan la plataforma como una herramienta para escalar fácilmente grandes números de contenedores entre diferentes hosts. Un grupo de hosts Docker requiere una administración especial y presenta retor que requieren un diferente juego de herramientas.

En esta guía, hablaremos sobre las herramientas de planificación y orquestación de Docker. Estas representan la interfaz de administración principal de un contenedor para los administrador de ambientes distribuidos.

## Planificando contenedores, orquestación y administración de grupo

Cuando las aplicaciones son escaladas fuera entre varios sistema hosts, la habilidad de administrar cada sistema host y abstraer la complejidad de la plataforma subyacente se vuelve atractiva. La orquestación es un término que abordaremos y se refiere a la planificación de contenedores, administración del grupo, y la posibilidad de provisionar hosts adicionales.

En este entorno, “planificar” se refiere a la habilidad de un administrador para cargar un archivo de servicio en un systema host que establece como ejecutar un contenedor específico. Mientras que la planificación se refiere al acto de cargar la definición del servicio, en un sentido más general, los planificadores son responsables de conectar al sistema para manejar los servicios en cualquier capacidad necesaria.

La administración del grupo es el proceso de controlar un grupo de hosts. Esto puede involucrar agregar o remover hosts del grupo, obtener información sobre el estado actual del host y contenedores, e iniciar y detener procesos. La administración de grupo está muy apegada a la planificación debido a que el planificador debe tener acceso a cada host en el grupo para planificar los servicios. Por esta razón, la misma herramienta se ofrece para ambos propósitos.

Para poder ejecutar y administrar contenedores en un host a través del grupo, el planificador debe interactuar con dada host de forma individual al inicio del sistema. Al mismo tiempo, y para facilitar la administración, el planificador presenta una vista unificada del estado de los servicios en el grupo. Esto termina funcionando como un sistema de inicio en todo el grupo. Por esta razón, muchos planificadores reflejan la estructura de comandos del sistema inicial que se va a abstraer.

Una de las mayores responsabilidades de los planificadores es la selección del host. Si un administrador decide correr un servicio (contenedor) en el grupo, el planificador a menudo se encarga de seleccionar el host. El administrador puede opcionalmente proveer limitaciones de planificación según sus necesidades o deseos, pero el planificador es el último responsable de ejecutar estos requerimientos.

## ¿Cómo un planificador toma decisiones de planificación?

Los planificadores a menudo definen una política de planificación. Esta determina como los servicios son planificados cuando el administrador no proporciona detalles. Por ejemplo, un planificador debe elegir dar lugar a nuevos servicios en el host con menor actividad de servicios.

Los planificadores típicamente proporcionan mecanismos de sobre-escritura que el administrador puede utilizar para afinar el proceso de selección para satisfacer requerimientos específicos. Por ejemplo, si dos contenedores pueden siempre ejecutarse en el mismo host debido a que operan como unidad, esta afinación puede ser declarada durante la planificación. En caso contrario, si dos contenedores no deben ser ubicados en el mismo host, por ejemplo para asegurar alta disponibilidad de las dos instancias del mismo servicio, esto puede ser definido de igual forma.

Otras restricciones a las que el planificador debe prestar atención pueden representarse por metadatos arbitrarios. Los hosts individuales deben ser etiquetados y clasificados por los planificadores. Esto puede ser necesario, por ejemplo, si un host restringe la cantidad de datos requeridos por la aplicación. Algunos servicios pueden necesitar ser implementados en un host individual en el grupo. La mayoría de los planificadores permiten hacerlo.

## ¿Qué funciones administrativas de grupo provee el planificador?

Los planificadores ofrecen funciones apegadas a la administración del grupo debido a que ambos requieren habilidades para operar en hosts específicos y en el grupo completo.

El software de administración de grupo puede consultar información de los miembros del grupo, y o remover miembros, o incluso conectarse a un host individualmente para una administración más gradual. Estas son funciones que pueden estar incluidas en el planificador, o pueden ser responsabilidad de otro proceso.

A menudo, la administración del grupo esta asociada con el descubridor de servicio o el almacen de clave-valor distribuido. Estos son específicamente adecuados para el almacenamiento de este tipo de información debido a que la información está dispersa en el grupo y la plataforma ya existe para su función principal.

Como consecuencia, si el planificador no proporciona métodos, algún administrador de grupo debe hacerlo modificando los valores en la configuración almacenada utilizando las APIs proporcionadas. Por ejemplo, el miembro del grupo puede necesitar ser manejado a través de cambios directos en el descubridor de servicio.

El almacen de clave-valor también suele ser una ubicación donde se almacenan metadatos de host individuales. Como se mencionó antes, etiquetar los host permite ubicar host individuales o grupos para tomar decisiones de planificación.

### ¿Cómo funcionan las implementaciones de varios contenedores en la planificación?

A veces, a pesar de que cada componente de la aplicación ha sido descompuesto en un servicio discreto, pueden ser manejados como una unidad. Hay veces cuando no tiene sentido desplegar un servicio sin otro debido a las funciones que proporciona.

La planificacion avanzada que toma en cuenta el agrupamiento de contenedores está disponible a través de diferentes proyectos. Existen algunos beneficios que los usuarios obtienen al tener acceso a esta funcionalidad.

La administración de un grupo de contenedores permite al administrador enfrentar una colección de contenedores como una única aplicación. Ejecutando componentes estrechamente ligados como unidad simplifica la administración de la aplicación sin sacrificar los benefocios de la contenerización individual. En efecto, esto permite al administrador mantener las ventajas de la contenerización y la arquitectura orientada a servicio mientras minimiza la carga de administración adicional.

Agrupar aplicaciones puede simplificar la planificación y proporcionar la habilidad de iniciar y detenerlas al mismo tiempo. Esto también ayuda en escenarios más complejos como configurar sub-redes para cada grupo o aplicaciones, o escalar grupos completos de contenedores donde previamente solo podíamos escalar en la medida del contenedor.

### ¿Qué es aprovisionamiento?

Un concepto relacionado con la administración de grupo es aprovisionamiento. Aprovisionamiento es el proceso de poner nuevos hosts en línea y configurarlos de forma básica para que puedan estar listos para trabajar. Con implementaciones Docker, esto comúnmente implica configurar Docker y el nuevo host en un grupo existente.

Aún cuando el resultado de aprovisionar un host debería siempre ser que un nuevo sistema esté listo para trabajar, la metodología varía significativamente dependiendo de las herramientas utilizadas y el tipo de host. Por ejemplo, si el host es una máquina virtual, herramientas como Vagrant pueden ser utilizadas para crear el nuevo host. La mayoría de los proveedores de nube te permiten crear hosts utilizando APIs. En contraste, con los proveedores de hardware puro probablemente requieras realizar algunos pasos manuales. Herramientas de administración de configuración como Chef, Pupper, Ansible o Salt pueden involucrarse para cuidar de la configuración inicial del host y proveerlo con la información que requiere para conectarse a un grupo existente.

El aprovisionamiento puede correr como un proceso iniciado por el administrador, ó puede ser conectado con las herramientas administrativas del grupo para la escalabilidad automática. Este último método involucra definir procesos para solicitar información adicional a los hosts así como las condiciones en las cuales será llamado automáticamente. Por ejemplo, si tu aplicación está sufriendo una sobrecarga, probablemente desees que tu sistema cree hosts adicionales para escalar horizontalmente los contenedores a una nueva infraestructura para aliviar la congestión.

### ¿Cuáles son algunos de los planificadores más comunes?

En términos de planificación básica y administración del grupo, algunos proyectos populares son:

- **fleet** : Fleet es el componente planificador y administrador de grupo de CoreOS. Lee la información de conexión de cada host en el grupo y proporciona administración de servicios similar a systemd.
- **marathon** : Marathon es un componente planificador y administrador de servicio en una instalación de Mesosphere. Funciona con Mesos para controlar servicios de tiempos de ejecución amplios y proporciona una interfaz web para la administración de procesos y contenedores.
- **Swarm** : el Swarm de Docker es el planificador que el proyecto de Docker anunción en Diciembre del 2014. Se espera que proporcione un planificador robusto que pueda crear contenedores en host aprovisionados con Docker, utilizando sintaxis nativa de Docker.

Como parte de la estrategia administrativa del grupo, la configuración de Mesosphere se basa en el siguiente componente:

- **mesos** : Mesos de Apache es una herramienta que abstrae y administra los recursos de todos los hosts en el grupo. Representa una colección de los recursos disponibles a través de todo el grupo para los componentes construidos en la parte superior (como Marathon). Se describe a sí mismo como un análogo a un “kernel” para una configuración grupal.

En términos de planificación avanzada y control de grupos de contenedores como unidad, los siguientes proyectos están disponibles:

- **kubernetes** : El planificador avanzado de Google, kubernetes permite un control más amplio sobre los contenedores que se ejecutan en tu infraestructura. Los contenedores pueden ser etiquetados, agrupados, y se les puede otorgar su propia sub-red de comunicación.
- **compose** : El proyecto compose de Docker fue creado para permitir la administración de grupos de contenedores utilizando archivos de configuración declarativos. Utiliza enlaces de Docker para conocer las dependencias de relación entre contenedores.

## Conclusión

La administración del grupo y el trabajo de planificación son una parte importante de la implementación de servicios contenerizados en un grupo de host distribuidos. Estos proporcionan el punto principal de la administración para iniciar y controlar los servicios que se proporcionan en tu aplicación. Al utilizar planificadores efectivamente, puedes crear cambios drásticos en tus aplicaciones con el menor esfuerzo.
