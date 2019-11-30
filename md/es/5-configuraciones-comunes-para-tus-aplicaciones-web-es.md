---
author: Mitchell Anicas
date: 2014-12-03
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/5-configuraciones-comunes-para-tus-aplicaciones-web-es
---

# 5 Configuraciones Comunes para tus Aplicaciones Web

### Introducción

Cuando decidimos que arquitectura de servidor utilizar para nuestro enterno, hay muchos factores a considerar, como el rendimiento, escalabilidad, disponibilidad, costo y facilidad de administración.

Aquí hay una lista de las configuraciones comunes de servidor, con una corta descripción en cada una, incluyendo pros y contras. Recuerda que todos los conceptos cubiertos aquí pueden ser utilizados en distintas combinaciones con otras, y que cada ambiente tiene diferentes requerimientos, así que no hay una sola, correcta configuración.

## 1. Todo en un Servidor

Todo el entorno reside en un solo servidor. Para aplicaciones web típicas, que incluyen el servidor web, servidor aplicación y servidor de bases de datos. Una una variación común de esta configuración es un LAMP, que comprende Linux, Apache, MySQL y PHP en un mismo servidor.

**Caso de Uso** : Bueno para configurar aplicaciones rápido, con las configuraciones más simples posibles, pero ofrece poco camino para escalar.

![Todo en un servidor](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/single_server.png)

**Pros** :

- Simple

**Contras** :

- La aplicación y base de datos compiten por los mismos recursos del servidor (CPU, Memoria, Entradas/Salidas, etc), lo que provoca bajo rendimiento y puede determinar un pobre rendimiento en la fuente (aplicación o base de datos) -No es escalable horizontalmente

**Artículos Relacionados** :

- [¿Cómo instalar LAMP en Ubuntu 14.04?](https://www.digitalocean.com/community/articles/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-14-04)

## 2. Servidor de Base de Datos Independiente

El manejador de base de datos (DBMS) puede ser separado del resto del entorno para eliminar la compentencia por recursos entre la aplicación y la base de datos, e incrementar la seguridad eliminando la base de datos del DMZ, o Internet público.

**Caso de Uso** : Bueno para configurar tu aplicación rápidamente, pero previene a la aplicación y base datos de pelear por recursos en el mismo sistema.

![Base de datos independiente](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/separate_database.png)

**Pros** :

- La aplicación y base de datos no compiten por los mismos recursos del servidor (CPU, Memory, I/O, etc.)
- Tienes posibilidad de escalar verticalmente cada espacio independiente, agregando más recursos o lo que sea que el servidor necesite para incrementar su capacidad
- Dependiendo de la configuración, se puede incrementar la seguridad eliminando la base de datos del DMZ

**Contras** :

- Configuración más compleja que la de un solo servidor
- Los problemas de rendimiento pueden aumentar si la conexión entre los dos servidores tiene latencia alta (por ejemplo, si los servidores están geográficamente distantes entre sí), o si el ancho de banda es demaciado bajo para la cantidad de datos transferidos

**Guías Relacionadas** :

- [¿Cómo configurar un servidor de base de datos remoto para optimizar el rendimiento con MySQL?](https://www.digitalocean.com/community/articles/how-to-set-up-a-remote-database-to-optimize-site-performance-with-mysql)
- [¿Cómo migrar una base de datos MySQL a un nuevo servidor en Ubuntu 14.04](https://www.digitalocean.com/community/articles/how-to-migrate-a-mysql-database-to-a-new-server-on-ubuntu-14-04)

## 3. Estabilizador de Cargas (Proxy Inverso)

Los estabilizadores de carga pueden ser agregados al entorno del servidor para mejorar el rendimiento y la Load balancers can be added to a server environment to improve performance and fiabilidad distribuyendo el flujo de carga entre varios servidores. Si uno de esos servidores falla al cargar su balance, el resto de los servidores atenderán el tráfico entrante hasta que el servidor que presenta falla se recupere. Esto también puede aplicarse para servir varias aplicaciones a través de un mismo dominio y puerto, utilizando la capa 7 (capa de aplicación) proxy inverso.

Ejemplos de software para trabajar con proxy inverso y balance de cargas: HAProxy, Nginx, and Varnish.

**Caso de Uso** : Útil en un entorno que requiere escalar agregando más servidores, también conocido como escalabilidad horizontal.

![Estabilizador de cargas](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/load_balancer.png)

**Pros** :

- Habilita escalabilidad horizontal, por ejemplo la capacidad del entorno puede ser aumentada agregando más servidores
- Puede proteger ataques DDOS limitando las conexiones del cliente mediante un peso y frecuencia

**Contras** :

- El estabilizador de cargas puede tener un rendimiento de cuello de botella si no cuenta con los recursos necesarios, o si está configurado pobremente
- Puede introducir complejidades que requieren consideraciones adicionaes, como cuando se ejecuta una terminación SSL y como responder cuando una aplicación requiere sesiones fijas

**Guís Relacionadas** :

- [Introducción a HAProxy y conceptos de balance de cargas](https://www.digitalocean.com/community/articles/an-introduction-to-haproxy-and-load-balancing-concepts)
- [¿Cómo utilizar HAProxy en una capa 4 como estabilizador de cargas para Servidores de Aplicaciones WordPress?](https://www.digitalocean.com/community/articles/how-to-use-haproxy-as-a-layer-4-load-balancer-for-wordpress-application-servers-on-ubuntu-14-04)
- [¿Cómo utilizar HAProxy en la capa 7 para estabilizar cargas para WordPress y Nginx?](https://www.digitalocean.com/community/articles/how-to-use-haproxy-as-a-layer-7-load-balancer-for-wordpress-and-nginx-on-ubuntu-14-04)

## 4. Acelerador HTTP (Caché en Proxy Inverso)

Un acelerador HTTP, o or Caché en Proxy Inverso, puede utilizarse para reducir el tiempo que toma en servir contenido a un usuario através de diversas técnicas. La técnica principal empleada en un acelerador HTTP es almacenando el caché de las respuestas en memoria, así que las peticiones futuras para el mismo contenido serán servidas rápidamente a menos que sea necesaria una interacción con la web o servidores de aplicaciónes.

Ejemplos de software útil para un acelerador HTTP: Varnish, Squid, Nginx.

**Caso de Uso** : Útil en un entorno donde el contenido pesado es dinámico en aplicaciones web, o cuando muchos archivos comúnes son visitados constantemente.

![Acelerador HTTP](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/http_accelerator.png)

**Pros** :

- Incrementa el rendimiento del sitio reduciendo la carga de CPU en el servidor web, a través del caché y la compresión
- Puede ser atendido como un proxy inverso con balance de carga
- Algunos softwares de caché pueden protegerte ante ataques DDOS

**Contras** :

- Requiere afinación para tener un mejor rendimiento
- Si el rango o capacidad de caché es bajo, puede reducir el rendimiento

**Guías Relacionadas** :

- [¿Cómo instalar Wordpress, Nginx, PHP, y Varnish en Ubuntu 12.04?](https://www.digitalocean.com/community/articles/how-to-install-wordpress-nginx-php-and-varnish-on-ubuntu-12-04)
- [¿Cómo configurar Servidores Web agrupados con Varnish y Nginx?](https://www.digitalocean.com/community/articles/how-to-configure-a-clustered-web-server-with-varnish-and-nginx-on-ubuntu-13-10)
- [¿Cómo configurar Varnish para Drupal con Apache en Debian y Ubuntu?](https://www.digitalocean.com/community/articles/how-to-configure-varnish-for-drupal-with-apache-on-debian-and-ubuntu)

## 5. Réplica de Base de Datos Maestro-Esclavo

Un camino para mejorar el rendimiento del sistema de base de datos es realizando muchas lecturas comparadas con las escritas, como en los CMS, es utilizar una réplica de la base de datos maestro-esclavo. La réplica Maestro-Esclavo requiere un principal (maestro) y uno o más nodos esclavos. En esta configuración, todas las actualizaciones del nodo maestro serán distribuidas a través de todos los nodos.

**Caso de Uso** : Bueno para incrementar el rendimiento en la lectura de la base de datos al nivel de una aplicación.

Aquí un ejemplo de la configuración Réplica Maestro-Esclavo con un solo nodo esclavo:

![Replica de base de datos maestro-esclavo](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/master_slave_database_replication.png)

**Pros** :

- Mejora la lecuta de la base de datos distribuyéndola entre los esclavos
- Puede mejorar la escritura utilizando el nodo maestro únicamente para actualizaciones (dependiendo si no hay solicitudes de lectura en procesamiento)

**Contras** :

- La aplicación que accesa a la base de datos debe tener un mecanismo para determinar cual de los nodos de base de datos debe ser utilizada para enviar peticiones de actualización y lectura
- Las actualizaciones a los esclabos son asíncronas, así que hay posibilidades de que el contenido pueda ser diferido
- Si el maestro falla, no se podrán realizar actalizaciones en la base de datos hasta que el problema sea sulucionado
- No hay un corrector de errores integrado en caso de alguna falla en el nodo maestro

**Guías Relacionadas** :

- [¿Cómo optimizar el rendimiento de WordPress con una réplica de MySQL enUbuntu 14.04?](https://www.digitalocean.com/community/articles/how-to-optimize-wordpress-performance-with-mysql-replication-on-ubuntu-14-04)
- [¿Cómo configurar una Réplica de MySQL Maestro-Esclavo?](https://www.digitalocean.com/community/articles/how-to-set-up-master-slave-replication-in-mysql)

## Ejemplo: Combinando los Conceptos

Es posible estabilizar cargas con servidores de caché, además del servidor aplicación y utilizar una réplica de base de datos en un mismo entorno. El propósito es aprovechar los beneficios de cada uno sin introducir muchos problemas y complejidad. Aquí hay un diagrama ejemplo de como debe lucir el entorno del servidor:

![Estabilizador de cargas, acelerador http, y replica de base de datos combinados](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/combined.png)

Asumámos que el estabilizador de cargas está configurado y reconoce peticiones estáticas (como imágenes, css, javascript, etc.) y enviamos todas estas peticiones directamente al servidor de caché, y el resto de las peticiones al servidor de aplicacion.

Aquí hay una descripción de lo que pasaría cuando un usuario realiza una petición al contenido dinámico:

1. El usuario solicita contenido dinámico de _[http://ejemplo.com/](http://ejemplo.com/)_ (estabilizador de cargas)
2. El estabilizador de cargas envía la peticion al backend de la aplicación
3. El backend de la aplicación lee de la base de datos y regresa la peticion al estabilizador de cargas
4. El estabilizador de cargas regresa los datos solicitados al usuario

Si el usuario solicita contenido estático:

1. El estabilizador de carga revisa el backend de caché para ver si la petición está en caché o no
2. _Si está en caché_: regresa el contenido al estabilizador de carga y salta al paso 7, de otro modo. _si no hay contenido en caché_: el servidor de caché re-envía la petición al backend de la aplicación, a través del estabilizador de carga
3. El estabilizador de carga re-envía la petición a través del backend de la aplicación
4. El backend de la aplicación lee de la base de datos y regresa el contenido al estabilizador de carga
5. El estabilizador de carga re-envía la petición al backend de caché
6. El backend de caché almacena el contenido y lo regresa el estabilizador de carga
7. El estabilizador de cargas regresa los datos solicitados al usuario

Este ambiente aún tiene dos puntos por analizar (el estabilizador de carga y el servidor maestro de base de datos), pero provee todos los beneficios de fiabilidad y rendimiento que fueron descritos en la sección de arriba.

## Conclusión

Ahora que estas familiarizado con algunas configuraciones básicas de servidor, puedes tener una buena idea de que tipo de servidor requieres para tu aplicación. Si estás trabajando en tu propio entorno, recuerda que el proceso iterativo es el mejor camino para evitar introducirse en complejidades rápidamente.

Comentanos acerca de tus recomendaciones o lo que te gustaría aprender en los comentarios de abajo!
