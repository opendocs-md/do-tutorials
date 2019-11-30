---
author: Justin Ellingwood
date: 2015-05-26
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/el-ecosistema-de-docker-descubridor-de-servicio-y-los-almacenes-de-distribucion-de-configuracion-es
---

# El Ecosistema de Docker: Descubridor de Servicio y los Almacenes de Distribución de Configuración

### Introducción

Los contenedores porporcionan una solución elegante para aquellos que buscan diseñar e implementar aplicaciones a escala. Mientras Docker proporciona la tecnología de contenerización, muchos otros proyectos asisten en las herramientas de implementación necesarias para el arranque y comunicación adecuados en el ambiente de implementación.

Uno de las tecnologías centrales que muchos ambientes de Docker utilizan es el Descubridor de Servicio. El Descubridor de Servicio permite a una aplicación o componente encontrar información acerca de su ambiente y vecinos. Esto se implementa usualmente como un almacén de clave-valor distribuido, el cual puede servir como una ubicación más general para dictar detalles de configuración. Configurar una herramienta de descubrimiento de servicio te permite separar la configuración de tiempos de ejecución del contenedor actual, lo cual te permite re-utilizar la misma imagen en un sin fin de ambientes.

En esta guía, discutiremos los beneficios del descubridor de servicio en un grupo de ambiente Docker. Nos enfocaremos principalmente en conceptos generales, pero proporcionan ejemplos más específicos apropiadamente.

## Descubridor de servicios y los almacenes de configuración accesible globalmente

La idea básica detrás del descubridor de servicio es que cualquier instancia de una aplicación debe ser capaz de identificar mediante programación los detalles de su ambiente actual. Esto es necesario para que la nueva instancia sea capaz de conectarse al ambiente de una aplicación existente sin intervención manual. Las herramientas de descubrimiento de servicio son generalmente implementadas como registros accesibles globalmente que almacenan información acerca de las instancias o servicios que están actualmente operando. En la mayoría de los casos, con el fin de hacer de este fallo de configuración tolerante y estalable, el registro está distribuido entre los hosts disponibles en la infraestructura.

Aún cuadno el propósito principal del descubridor de servicios es proporcionar detalles de conexión para enlazar componentes entre sí, pueden ser utilizados generalmente para almacenar cualquier tipo de configuración. Muchas implementaciones aprovechan esta habilidad definiendo sus datos de configuración en la herramienta de descubrimiento. Si los contenedores estan configurados para que sepan buscar esos detalles, pueden modificar su comportamiento en base a lo que encuentren.

## ¿Cómo funciona el descubridor de servicio?

Cada herramienta de descubrimiento de servicio proporciona una API que el componente puede utilizar para configurar o recibir datos. Como consecuencia, por cada componente, la dirección del servicio de descubrimiento o bien debe ser modificable en cada aplicación o contenedor, o lo porporciona como una opción en el tiempo de ejecución. Usualmente el descubridor de servicio es implementado como un almacén de clave-valor accesible utilizando métodos estándar HTTP.

La forma en que el portal del descubridor de servicio funcion es que cada servicio, siempre y cuando esté online, se registra a sí mismo utilizando la herramienta de descubrimiento. Esto almacena toda la información relacionada al componente y necesaria para consumir el servicio proporcionado. Por instancia, una base de datos MySQL puede registrar el acceso IP y el puerto donde la tarea (o demonio) está corriendo, y opcionalmente el usuario y las credenciales necesarias para identificarse.

Cuando un cliente de un servicio se conecta, está disponible para consultar el registro del descubridor de servicio en busca de información en un punto final predefinido. Este cliente puede entonces interactuar con los componentes que requiere basado en la información que encuentra. Un buen ejemplo de esto es el balanceador de cargas. Puede encontrar cada servidor backend que necesite para alimentar el trafico al ser consultado el portal del descubridor de servicio y ajustando su configuración en consecuencia.

Esto deja fuera los detalles de configuración de los propios contenedores. Uno de los beneficios de esto es que hace que el componente del contendor sea más flexible y menos ligado a una configuración específica. Otro de los beneficios es que simplifica la forma en que tus componentes reaccionan a nuevas instancias de un servicio relacionado, permitiendo configuración dinámica.

## ¿Cómo se relaciona el almacén de configuración?

Una de las principales ventalas de un servicio de descubrimiento global en el sistema es que puede almacenar cualquier tipo de datos de configuración en los componentes necesarios durante el tiempo de ejecución. Esto significa que puedes extraer aún más la configuración fuera del contenedor y en un mayor entorno de ejecución.

Usualmente, para hacer este trabajo más efectivo, tu aplicación debe ser diseñada con valores predeterminado que puedan ser sobre-escribibles al tiempo de ejecución consultando al almacén de configuración. Esto te permite utilizar el almacén de configuración similar a las banderas que se usan en la línea de comandos. La diferencia es que utilizar un almacén accesible globalmente, te permite ofrecer las mismas opciones a cada instancia de tu componente sin trabajo adicional.

## ¿Cómo el almacén de configuración ayuda a la administración del grupo?

Una función de almacenar de clave-valor distribuido en implementaciones Docker que podría no ser inicialmente aparente es almacenar y administrar los miembros del grupo. Los almacenes de configuración son un ambiente perfecto para rastrear al miembro del host para el bien de las herramientas de administrativas.

Parte de la información que puede ser almacenada como un host individial en un almacén clave-valor distribuida es:

- Dirección IP del host.
- Información de conexión para los propios hosts.
- Metadatos y etiquetas arbitrarias que pueden ser catalogadas por desiciones planificadas.
- Rol en el grupo (si utilizaz un modelo líder/seguidor).

Estos datos no son algo de lo que necesitas preocuparte cuando utilizas la plataforma de descubrimiento de servicios en circonstancias normales, pero proporcionan una ubicación para herramientas administrativas para consultar información acerca del propio grupo.

## ¿Qué pasa con la detección de fallos?

El detector de fallos puede ser implementado de varias formas. La preocupación es sí, si un componente falla, el descubridor de servicio se actualiza para reflejar que el elemento no está disponible. Este tipo de información es vital para minimizar los fallos del servicio o aplicación.

Muchas plataformas de descubrimiento de servicio permiten a los valores ser configurables con un tiempo de espera. El componente puede configurar cada valor con un tiempo de espera, y hacer ping al descubridor de servicio en intervalos de tiempo regulares para reinciar el tiempo de espera. Si el componente falla y el tiempo de espera es alcanzado, la información de conexión de esa instancia es removida del almacen. La longitud del tiempo de espera es en gran medida una función de la rapidez con la que la aplicación responde ante un componente que falla.

Eso también puede lograrse mediante la asociación de un contenedor “asistente” por cada componente, cuya única responsabilidad es revisar el estado del componente de manera periódica y actualizar el registro si el componente cae. La preocupación con este tipo de arquitectura es que el contenedor asistente puede caer, dejando información incorrecta en el almacen. Algunos sistemas resuelven esto dejando esta tarea a la herramienta de descubrimiento. En este caso, la plataforma revisa periódicamente si los componentes registrados están aún disponibles.

## ¿Qué pasa con los servicios de re-configuración cuando cambian los detalles?

Una de las claves para mejorar el modelo básico del descubrimiento de servicio es la configuración dinámica. Mientras que el descubridor de servicio normal te permite influír sobre la configuración inicial de los componentes revisando la información del descubridor al inicio, la configuración dinámica involucra configurar tus componentes para reaccionar a nuevas configuraciones en el almacén de configuración. Por ejemplo, si implementas un balanceador de carga, la revisión del estado o salud en los servidores backend pueden indicar que un miembro del grupo está caído. La instancia en ejecución del balanceador de carga necesita ser informado y debe ser capaz de ajustar su configuración y recargar para dar cuenta de esto.

Esto puede ser implementado de muchas maneras. Debido a que el ejemplo del balanceador de cargas es uno de los casos más comunes de esta habilidad, existen un gran número de proyectos enfocados exclusivamente a reconfigurar un balanceador de cargas cuando se detectan cambios en la configuración. El modificador de configuración HAProxy es muy común debido a su ubicuidad en el espacio de balance de carga.

Algunos proyectos son más flexibles en eso ya que se pueden utilizar para efectuar cambios en cualquier tipo de software. Estas herramientas regularmente consultan el descubridor de servicio y cuando un cambio es detectado, hacen uso de una plantilla del sistema para generar archivos de configuración que incorporan los valores encontrados con el descubridor. Después de que el nuevo archivo de configuración se genera, el servicio afectado se recarga.

Este tipo de re-configuración dinámica requiere más planeación y configuración durante el proceso de construcción ya que debido a todos los mecanismos que deben existir en el contenedor del componente. Esto hace al contenedor del componente responsable de ajustar su propia configuración. Averiguar los valores necesarios para escribirlos en el descubridor de servicios y diseñar una estructura de datos apropiada para el consumo fácil es otro de los retos que este sistema requiere, pero los beneficios y flexibilidad puede ser sustancial.

## ¿Qué hay de la seguridad?

Una de las preocupaciones que muchas personas tienen cuando aprenden primero acerca de almacenamiento de configuración accesible a nivel global es, con mucha razón, la seguridad. ¿Realmente es correcto almacenar información en un acceso global?

La respuesta a esta pregunta depende en gran parte de lo que se está utilizando para almacenar y cuantas capas de seguridad se consideran necesarias para proteger los datos. La mayoría de los las plataformas de descubrimiento de servicio permiten encriptar las conexiones con SSL/TLS. Para algunos servicios, la privacidad puede no ser terriblemente importante y tan solo poner al descubridor de servicio en una red privada es más que suficiente. Aún así, la mayoría de las aplicaciones se beneficiarían de la seguridad adicional.

Existe un gran número de formas para atender este problema, y varios proyectos que ofrecen su propia solución. Una de las soluciones de un proyecto es continuar permitiendo el acceso libre a la plataforma de descubrimiento, pero encripta los datos en ella. La aplicación que la consuma, deberá tener asociada una llave para desencriptar los datos que encuentre en el almacen. De esta forma otras partes no podrán acceder a los datos desencriptados.

Para un enfoque distinto, algunas herramientas de descubrimiento de servicio implementan una lista de control de acceso que divide el espacio de la llave en zonas separadas. Estos pueden designar propiedad o acceso a áreas basados en los requerimientos de acceso definidos por un espacio de llave específico. Esto establece un camino fácil para proporcionar información a ciertas partes mientras se mantiene privada de otros. Cada componente puede ser configurado para acceder solo a la información realmente necesaria.

## ¿Cuáles son algunas de las herramientas de descubrimiento de servicio más comunes?

Ahora que hemos discutido algunas de las características generales del las herramientas de descubrimiento de servicios y de almacenes globales distribuidos de llaves y valores, podemos mencionar algunos proyectos en relación a estos conceptos.

Algunas de las herramientas de descubrimiento de servicio más comunes son:

- **etcd** : Esta herramienta fue creada por los fabricantes de CoreOS para proporcionar el descubridor de servicio y configuraciones globales distribuidas tanto para contenedores como para el sistema host. Implementa una API HTTP y cuenta con un cliente de línea de comando disponible en cada máquina host.
- **consul** : Este descubridor de servicio cuenta con muchas características avanzadas que incluyen revisiones de salud configurable, funcionalidad ACL, configuración HAProxy, etc.
- **zookeeper** : Este ejemplo es un poco más viejo que los dos anteriores, proporciona una plataforma más madura a expensas de algunas características más nuevas.

Algunos otros proyectos que extienden a un descubridor de servicio básico son:

- **crypt** : Crypt permite a los componentes proteger la información escrita en ellos utilizando encriptado por llave pública. Los componentes que estan destinados a leer datos se les puede asignar una llave de desencriptado. El resto de los componentes no podrán leer los datos.
- **confd** : Confd es un proyecto destinado a permitir re-configuración dinámica en aplicaciones arbitrarias basadas en cambios en el portal de descubrimiento de servicio. El sistema incorpora una herramienta para ver las variables relevantes en los cambios, un sistema de plantillas para crear nuevos archivos de configuración basados en la información otorgada y la habilidad de recargar las aplicaciones afectadas.
- **vulcand** : Vulcand funciona como un balanceador de cargas para grupos de componentes. Está consciente y modifica su configuración basado en los cambios detectados en el almacén.
- **marathon** : Aunque Marathon es principalmente un planificador, también implementa habilidades básicas para recargar HAProxy cuando se realizan cambios en los servicios disponibles, manteniendo un equilibrio.
- **frontrunner** : Este proyecto se cuelga de Marathon para proporcionar soluciones más robustas en la actualización de HAProxy.
- **synapse** : Este proyecto introduce una incrustación de una interfaz HAProxy que puede enrutar el tráfico a los componentes.
- **nerve** : Nerve es utilizado en conjunto con Synapse para porporcionar revisiones de salud para las instancias de los componentes de forma individual. Si el componente se pierde, Nerve actualiza Synapse para sacar al componente fuera del enrutamiento.

## Conclusión

El descubridor de servicio y los almacenes de configuración globales permiten a los contenedores de Docker adaptarser a su ambiente actual y conectar los componentes existentes. Esto es un pre-requisito escencial para proporcionar una simple escalabilidad e implementación, permitiendo a los componentes rastrear y responder ante los cambios de su entorno.

En la siguiente guía, hablaremos sobre las formas en que los contenedores de Docker y los host se pueden comunicar con configuraciones personalizadas de red.
