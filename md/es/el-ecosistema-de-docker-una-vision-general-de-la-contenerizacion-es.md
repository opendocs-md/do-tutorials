---
author: Justin Ellingwood
date: 2015-05-26
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/el-ecosistema-de-docker-una-vision-general-de-la-contenerizacion-es
---

# El Ecosistema de Docker: Una Visión General de la Contenerización

### Introducción

Existen a menudo muchos obstáculos para mover tu aplicación por un camino fácil durante el ciclo de desarrollo y eventualmente a producción. Además, el trabajo real para implementar tu aplicación para que responda apropiadamente a cada entorno, también podrías enfrentar problemas rastreando dependencias, escalando tu aplicación y actualizando componentes sin afectar la aplicación por completo.

La contenerización de Docker y el diseño orientado a servicio te permite resolver todos estos problemas. Las aplicaciones pueden descomponerse en componentes funcionales y manejables empaquetados individualmente con todas sus dependencias, e implementarlas en arquitecturas irregulares fácilmente. La escalabilidad y actualización de componentes también se simplifican.

En esta guía, también discutiremos sobre los beneficios de contenerización y como Docker te ayuda a resolver varios de los problemas mencionados previamente. Docker es el componente central en las implementaciones de contenedores distribuidos que proporciona una fácil escalabilidad y gestión.

## Una breve historia de la contenerización en Linux

Contenerización y aislamiento no son nuevos conceptos en el mundo de la computación. Algunos sistemas operativos tipo Unix han aprovechado las tecnologías ce contenerización madura por más de una década.

En Linux, LXC, el bloque de construcción que formó la base de las tecnologías de contenerización fue agregada al kernel en el 2008. LXC combinó el uso del kernel cgroups (que permite aislar y rastrear el uso de recursos) y namespaces (que permite a los grupos separarse, por lo que no pueden verse “unos a otros”) para implementar aislamiento de procesos ligeros.

Después, Docker fue introducido como una forma de simplificar las herramientas necesarias para crear y administrar contenedores. Inicialmente utilizaba LXC como su driver de ejecución por defecto (se desarrolló una librería deniminada libcontainer para este propósito). Docker, aunque no es la introducciön de muchas nuevas ideas, hizo accesible para el desarrollador promedio y el administrador de sistemas la simplificación del proceso y la estandarización en una interfaz. Se impulsó un renovado interés en la contenerización en el mundo de Linux entre los desarrolladores.

Mientras que algunos de los temas que se discutirán en este artículo son más generales, nos enfocaremos principalmente en la contenerización de Docker debido a su gran popularidad y su adopción estándar.

## Que es lo que la contenerización trae a la imagen

Los contenedores vienen con muchos beneficios muy atractivos para ambos: desarrolladores y administradores de sistemas/equipo de operaciones.

Algunos de los mayores beneficios se muestran a continuación.

### Abstracción del sistema host lejos de la aplicación contenerizada

Los contenedores están destinados a ser completamente estandarizados. Esto significa que el contenedor se conecta al host y a cualquier lado fuera del contenedor usando interfaces definidas. Una aplicación contenerizada no se debe involucrar ni preocupar sobre los detalles de los recuros o arquitectura del host. Esto simplifica loa supuestos del desarrollo sobre el ambiente operativo. Del mismo mode, que el host, cada contenedor es una caja negra. No se preocupan de los detalles de la aplicación en el interior.

### Fácil escalabilidad

Uno de los beneficios de la abstracción entre el sistema host y los contenedores es eso, a partir de un diseño correcto de aplicación, escalar puede ser simple y directo. Un diseño orientado a servicio (discutido más adelante) combinado con aplicaciones contenerizadas proporcionan las bases para una fácil escalabilidad.

Un developer puede ejecutar algunos contenedores en su estación de trabajo, mientras que este sistema puede escalar horizontalmente en ensayo o área de pruebas. Cuando los contenedores suben a producción, estos pueden escalar nuevamente.

### Simple administración de dependencias y versionamiento de aplicaciones

Los contenedores permiten al desarrollador agrupar una aplicación o un componente de la misma junto a todas sus dependencias como unidad. El sistema host no tiene que preocuparse por las dependencias necesarias para ejecutar una aplicación específica. Mientras pueda correr Docker, será capaz de correr los contenedores de Docker.

Esto hace que la administración de dependencias sea fácil y simplifica la administración de versiones de la aplicación además. Los sistemas host y los equipos de operaciones dejan de ser responsables de administrar las dependencias necesarias para la aplicación debido a que, aparta las relaciones de los contenedores relacionados, deben estar contenidas dentro del propio contenedor.

### Extremadamente ligero, ambientes de ejecución aislados

Aunque los contenedores no proporcionan el mismo nivel de aislamiento y administración de recursos como las tecnologías de virtualización, lo que los hace mejores es su extremadamente ligero peso de ejecución. Los contenedores están aislados a nivel de proceso, empezando en el kernel del host. Esto significa que el contenedor por si solo no incluye un sistema operativo completo, los que representa tiempos de arranque casi instantáneos. Los desarrolladores pueden fácilmente ejecutar miles de contenedores desde su estación de trabajo sin ningún problema.

### Capas compartidas

Los contenedores son ligeros en un sentido distinto en el cual están compuestos en “capas”. Si diversos contenedores se basan en la misma capa, estos pueden compartir la capa subyacente sin duplicarla, dando lugar a un uso mínimo de espacio en disco para las futuras imágenes.

### Compuestabilidad y predecibilidad

Los archivos de Docker permiten a los usuarios definir las acciones exactas necesarias para crear una nueva imagen de contenedor. Esto te permite escribir la ejecución de tu ambiente como si fuera código, almacenándola en un controlador de versiones si es necesario. El mismo archivo de Docker en el mismo entorno siempre producirá una imagen de contenedor idéntica.

## Usando Dockerfiles repetidas veces, compilaciones consistentes

Debido a que es posible crear imágenes de contenedores a través de un proceso iterativo, es muy frecuente agregar los pasos de configuración dentro de un Dockerfile (archivo de Docker) para que se conozcan los pasos necesarios. Los Dockerfiles son simples archivos de compilación que describen como crear la imagen del contenedor desde un punto de partida conocido.

Los Dockerfiles son incríblemente útiles y fácil de dominar. Algunos de los beneficios que proveen son:

- **Fácil versionamiento** : Los Dockerfiles por si solos pueden ser rastreables a través de un controlador de versiones para comparar sus cambios y revertir cualquier error.
- **Predicibilidad** : Crear una imagen desde un Dockerfile ayuda a reducir el error humano desde el proceso de creación de la imagen.
- **Rendición de Cuentas** : Si tu planeas compartir tus imágenes, es una buena idea proporcionar el Dickerfile que crea una imagen como una forma para que otros usuarios puedan auditar el proceso. Esto básicamente proporciona el historial de la línea de comandos con los pasos tomados para crear la imagen.
- **Flexibilidad** : Crear imagenes desde Dockerfile permite sobreescribir los valores predeterminados que las compilaciones proporcionan. Esto significa que no tienes que proporcionar las opciones de tiempo de arranque para que la imagen funcione según lo previsto.

Los archivos de Docker son una gran herramienta para automatizar la creación de imágenes de contenedores al establecer un proceso repetible.

## La arquitectura de las aplicaciones contenerizadas

Cuando se diseñan aplicaciones para ser implementadas en contenedores, una de las principales áreas de preocupación es la actual arquitectura de la aplicación. Generalmente, las aplicaciones contenerizadas funcionan mejor cuando se implementan en un diseño orientado a servicio.

Las aplicaciones orientadas a servicio rompen la funcionalidad del sistema en componentes discretos que se comunican unos con los otros a través de interfaces bien definidas. La tecnología de contenedores por si misma se encarga de este tipo de diseño debido a que permite a cada componente escalar o crecer de manera independiente.

Las aplicaciones que implementan este tipo de diseño deben tener las siguientes cualidades:

- No deben preocuparse o confiar en las especificaciones del sistema host.
- Cada componente debe proporcionar APIs consistentes que los clientes puedan usar para acceder al servicio.
- Cada servicio debe tener señales de las variables de entorno durante la configuración inicial.
- Los datos de la aplicación deben ser almacenados fuera del contenedor en unidades montadas o en los datos de los contenedores.

Estas estrategias permiten a cada componente intercambiarse o actualizarse mientras la API lo mantenga. Además se prestan para la escalabilidad horizontal debido a que cada componente puede ser escalado de acuerdo a el cuello de botella que se presente.

En lugar de codificar valores específicos, cada componente generalmente puede definir valores razonables por defecto. El componente puede usarlos como valores de retorno, pero debe preferir los valores que pueda obtener de su entorno. Esto usualmente se logra a través de la ayuda de las herramientas de descubrimiento, misma que el componente puede consultar durente el proceso de inicio.

Sacando la configuración fuera del contenedor actual y colocáncola en el ambiente permite cambios fáciles al comportamiento de la aplicación sin necesidad de re-construir la imagen del contenedor. Esto permite a una simple configuración influir sobre múltiples instancias de un componente. Por lo general, el diseño orientado encaja con estrategias de configuración de ambiente debido a que permiten implementaciones más flexibles y de escala más sencilla.

## Usando el registro de Docker para administración de contenedores

Una vez que tu aplicación se divide en componentes funcionales y configurados a responder apropiadamente a otros contenedores y banderas de configuración con el entorno, el siguiente paso es hacer las imágenes de tus contenedores accesibles a través de registros. Subiendo imágenes de contenedores al registro, permite a los host de Docker obtener la imagen y crear las instancias de los contenedores tan solo por conocer el nombre de la imagen.

Existen varios registros de Docker para este propósito. Algunos son registros públicos donde cualquiera puede ver las imágenes que han sido contribuidas, mientras que otros registros son privados. Las imágenes pueden ser clasificadas, de esta forma son más fáciles de ubicar para descargas y actualizaciones.

## Conclusiön

Docker proporciona el bloque de construcción fundamental y necesario para la implementación de contenedores distribuidos. Creando un paquete de componentes de la aplicación en su propio contenedor, la escalabilidad horizontal se vuelve un proceso simple de de hilado o cierre de diversas instancias de cada componente. Docker proporciona las herramientas necesarias no solo para crear contenedores sino también para administrar y compartirlos con nuevos usuarios o host.

Mientras las aplicaciones contenerizadas proporcionen los procesos aislados necesarios y empaquetados para asistir en la implementación, existen otros componentes necesarios para administrar y escalar los contenedores a través de grupos distribuidos de hosts. En nuestra próxima guía, discutiremos sobre de cómo el servicio de descubrimiento y los almacenes de configuración global distribuida contribuyen a la implementación de grupos de contenedores.
