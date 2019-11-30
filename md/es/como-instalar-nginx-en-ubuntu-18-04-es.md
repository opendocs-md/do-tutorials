---
author: Justin Ellingwood, Kathleen Juell
date: 2019-04-26
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-nginx-en-ubuntu-18-04-es
---

# Cómo instalar Nginx en Ubuntu 18.04

### Introducción

Nginx es uno de los servidores web más populares del mundo y es responsable de alojar algunos de los sitios más grandes y con mayor tráfico de Internet. En la mayoría de los casos, tiene más recursos que Apache y se puede usar como un servidor web o como un proxy inverso.

En esta guía, hablaremos sobre cómo instalar Nginx en su servidor Ubuntu 18.04.

## Requisitos previos

Antes de empezar los pasos de esta guía, debe tener una cuenta de usuario regular que no sea root y que cuente con privilegios de sudo configurados en su servidor. Siga nuestra [guía de configuración inicial del servidor para Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) para aprender a configurar una cuenta de usuario regular.

Cuando tenga una cuenta disponible, inicie sesión como usuario no root para poder empezar.

## Paso 1 — Instalar Nginx

Dado a que Nginx está disponible en los repositorios predeterminados de Ubuntu, puede instalarlo desde estos repositorios usando el sistema de empaquetado `apt`.

Ya que esta es nuestra primera interacción con el sistema de empaquetado `apt` en esta sesión, vamos a actualizar nuestro índice de paquetes local para que podamos tener acceso a los listados de paquetes más recientes. Tras hacerlo, podremos instalar `nginx`:

    sudo apt update
    sudo apt install nginx

Una vez que se acepte el procedimiento, `apt` le instalará Nginx y las dependencias que pueda necesitar a su servidor.

## Paso 2 — Configurar el Firewall

Antes de probar Nginx, se debe configurar el software de firewall de forma que permita el acceso al servicio. Nginx se registra a sí mismo como un servicio con `ufw` al instalarse, haciendo que permitir el acceso de Nginx sea fácil.

Obtenga una lista de las configuraciones de las aplicaciones con las que `ufw` sabe trabajar escribiendo:

    sudo ufw app list

Se debería propagar una lista de los perfiles de aplicaciones:

    OutputAvailable applications:
      Nginx Full
      Nginx HTTP
      Nginx HTTPS
      OpenSSH

Como puede ver, hay tres perfiles disponibles para Nginx:

- **Nginx Full** : Este perfil abre tanto el puerto 80 (tráfico web normal, no cifrado) como el puerto 443 (tráfico TLS/SSL cifrado)
- **Nginx HTTP** : Este perfil solamente abre el puerto 80 (tráfico web normal, no cifrado)
- **Nginx HTTPS** : Este perfil solamente abre el puerto 443 (tráfico TLS/SSL cifrado)

Es recomendable que active el perfil más restrictivo que aún permita el tráfico que haya configurado. Debido a que en esta guía todavía no configuramos SSL para nuestro servidor, únicamente vamos a tener que permitir tráfico en el puerto 80.

Puede habilitar esto ingresando:

    sudo ufw allow 'Nginx HTTP'

Puede verificar el cambio ingresando:

    sudo ufw status

Debe ver el tráfico HTTP que se permite en el resultado que se muestra:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Nginx HTTP ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Nginx HTTP (v6) ALLOW Anywhere (v6)

## Paso 3 — Verificar su servidor web

Ubuntu 18.04 inicia Nginx al concluir el proceso de instalación. El servidor web ya debería estar abierto y funcionando.

Para asegurarnos de que el servicio se está ejecutando, podemos verificar usando el sistema init `systemd` y escribiendo:

    systemctl status nginx

    Output● nginx.service - A high performance web server and a reverse proxy server
       Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
       Active: active (running) since Fri 2018-04-20 16:08:19 UTC; 3 days ago
         Docs: man:nginx(8)
     Main PID: 2369 (nginx)
        Tasks: 2 (limit: 1153)
       CGroup: /system.slice/nginx.service
               ├─2369 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
               └─2380 nginx: worker process

Como se puede ver arriba, parece que el servicio ha comenzado correctamente. No obstante, la mejor manera de probar esto es verdaderamente solicitando una página de Nginx.

Puede acceder a la página de aterrizaje de Nginx predeterminada para confirmar que el software esté funcionando de la manera correcta navegando a la dirección IP de su servidor. Si no sabe cuál es la dirección IP de su servidor, puede conseguirla de varias formas.

Trate de ingresar esto en la línea de comandos de su servidor:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Le dará algunas líneas. Puede probar cada una en su navegador web para ver si funciona.

Alternativamente, puede escribir lo siguiente, lo que debería darle su dirección IP pública como se ve desde otra ubicación en Internet:

    curl -4 icanhazip.com

Una vez que tenga la dirección IP, ingrésela en la barra de direcciones de su navegador:

    http://your_server_ip

Debería ver la página de aterrizaje de Nginx predeterminada:

![página de Nginx predeterminada](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_1604/default_page.png)

Se incluye esta página con Nginx para mostrarle que el servidor está funcionando correctamente.

## Paso 4 — Gestionar el proceso de Nginx

Ahora que su servidor web está funcionando, vamos a repasar algunos comandos de gestión básicos.

Para detener su servidor web, ingrese:

    sudo systemctl stop nginx

Para iniciar el servidor web una vez que se haya detenido, ingrese:

    sudo systemctl start nginx

Para detener y luego volver a iniciar el servicio, ingrese:

    sudo systemctl restart nginx

Si simplemente está haciendo cambios de configuración, a menudo Nginx se puede recargar sin perder las conexiones. Para hacerlo, ingrese:

    sudo systemctl reload nginx

De forma predeterminada, Nginx está configurado para empezar automáticamente una vez que el servidor se inicia. Puede desactivar este comportamiento si no desea que suceda así, ingresando:

    sudo systemctl disable nginx

Para volver a habilitar el servicio para que empiece tras la iniciación, puede ingresar:

    sudo systemctl enable nginx

## Paso 5 – Configurar los bloques del servidor (Recomendado)

Al usar el servidor web Nginx, se pueden usar los _bloques del servidor_ (parecidos a los hosts virtuales en Apache) para encapsular los detalles de configuración y alojar más de un dominio desde un solo servidor. Vamos a configurar un dominio llamado **example.com** , pero debe **reemplazarlo con su propio nombre de dominio**. Consulte nuestra [Introducción a DigitalOcean DNS](an-introduction-to-digitalocean-dns) para aprender más sobre cómo configurar un nombre de dominio con DigitalOcean.

Nginx en Ubuntu 18.04 cuenta con un bloqueo del servidor que está habilitado de forma predeterminada y que está configurado para servir documentos fuera de un directorio en `/var/www/html`. Aunque esto funciona bien para un solo sitio, puede tornarse complicado si hospeda varios sitios. En vez de modificar `/var/www/html`, vamos a crear una estructura de directorios dentro de `/var/www` para nuestro sitio **example.com** , dejando a `/var/www/html` es su lugar como el directorio predeterminado que debe servirse en caso de que una solicitud de un cliente no coincida con ningún otro sitio.

Cree el directorio para **example.com** como se indica a continuación, usando el indicador `-p` para crear cualquier directorio matriz que pueda requerirse:

    sudo mkdir -p /var/www/example.com/html

Posteriormente, asigne la titularidad del directorio con la variable de entorno `$USER`:

    sudo chown -R $USER:$USER /var/www/example.com/html

Si no ha modificado su valor de `umask`, los permisos de sus roots web deberían ser los correctos, pero puede verificarlo ingresando:

    sudo chmod -R 755 /var/www/example.com

Luego, cree una página `index.html` como ejemplo utilizando `nano` o su editor preferido:

    nano /var/www/example.com/html/index.html

Adentro, agregue el siguiente HTML como ejemplo:

/var/www/example.com/html/index.html

    <html>
        <head>
            <title>Welcome to Example.com!</title>
        </head>
        <body>
            <h1>Success! The example.com server block is working!</h1>
        </body>
    </html>

Una vez que haya acabado, guarde y cierre el archivo.

Para que Nginx le proporcione servicios a este contenido, se debe crear un bloque del servidor usando las directivas correctas. En vez de modificar el archivo de configuración predeterminado directamente, vamos a hacer uno nuevo en `/etc/nginx/sites-available/example.com`:

    sudo nano /etc/nginx/sites-available/example.com

Pegue el siguiente bloque de configuración, el cual se parece al predeterminado, pero que se ha actualizado para nuestro nuevo directorio y nombre de dominio:

/etc/nginx/sites-available/example.com

    server {
            listen 80;
            listen [::]:80;
    
            root /var/www/example.com/html;
            index index.html index.htm index.nginx-debian.html;
    
            server_name example.com www.example.com;
    
            location / {
                    try_files $uri $uri/ =404;
            }
    }

Note que hemos actualizado la configuración `root` para nuestro nuevo directorio y el `server_name`(nombre de servidor) a nuestro nombre de dominio.

Después, vamos a habilitar el archivo creando un enlace desde el mismo al directorio `sites-enabled` (habilitado para sitios), el cual Nginx usa para leer durante el inicio:

    sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/

Ahora tenemos dos bloques del servidor habilitados y configurados para responder a las solicitudes dependiendo de sus directivas de `listen` (oír) y `server_name` (nombre de servidor) (puede consultar [aquí](understanding-nginx-server-and-location-block-selection-algorithms) para leer más sobre cómo Nginx procesa estas directivas):

- `example.com`: Responderá a las solicitudes de `example.com` y de `www.example.com`.
- `Predeterminado`: Responderá a cualquier solicitud en el puerto 80 que no coincida con los otros dos bloques.

Solamente debe ajustar un solo valor en el archivo `/etc/nginx/nginx.conf` para evitar un posible problema de memoria de hash bucket, el que puede surgir al agregar nombres de servidores adicionales. Abra el archivo:

    sudo nano /etc/nginx/nginx.conf

Busque la directiva `server_names_hash_bucket_size` y quite el símbolo `#` para descomentar la línea:

/etc/nginx/nginx.conf

    ...
    http {
        ...
        server_names_hash_bucket_size 64;
        ...
    }
    ...

Posteriormente, haga una prueba para asegurarse de que no haya errores de sintaxis en ninguno de sus archivos de Nginx:

    sudo nginx -t

Una vez que haya acabado, guarde y cierre el archivo.

Si no hay ningún problema, reinicie Nginx para habilitar sus cambios:

    sudo systemctl restart nginx

Ahora, Nginx debería estar sirviendo su nombre de dominio. Puede probar esto navegando a `http://example.com`, donde debería ver algo parecido a lo siguiente:

Primer bloqueo del servidor de Nginx

## Paso 6 — Familiarizarse con archivos y directorios importantes de Nginx

Ahora que sabe cómo gestionar el servicio de Nginx mismo, debería dedicar unos minutos a familiarizarse con algunos directorios y archivos importantes.

### Contenido

- `/var/www/html`: El contenido web real, que de forma predeterminada únicamente consiste en la página de Nginx predeterminada que vio antes, recibe servicio de parte del directorio `/var/www/html`. Esto puede modificarse alterando los archivos de configuración de Nginx.

### Configuración del servidor

- `/etc/nginx`: El directorio de configuración de Nginx. Todos los archivos de configuración de Nginx se alojan aquí.
- `/etc/nginx/nginx.conf`: El archivo de configuración de Nginx principal. Esto se puede modificar para hacer cambios a la configuración global de Nginx.
- `/etc/nginx/sites-available/`: El directorio donde se pueden almacenar los bloques del servidor por sitio. Nginx no usará los archivos de configuración que estén en este directorio a menos que estén vinculados al directorio `sites-enabled`. Generalmente, todas las configuraciones del bloque del servidor se llevan a cabo en este directorio y luego se habilitan vinculándolas al otro directorio.
- `/etc/nginx/sites-enabled/`: El directorio donde se almacenan los bloques del servidor por sitio habilitados. Generalmente, estos se crean vinculándolos a los archivos de configuración que están en el directorio `sites-available`.
- `/etc/nginx/snippets`: Este directorio contiene fragmentos de configuración que se pueden incluir en cualquier otro sitio de la configuración de Nginx. Los buenos candidatos para la refactorización en fragmentos serían los segmentos de configuración potencialmente repetibles.

### Registros del servidor

- `/var/log/nginx/access.log`: Se registra cada solicitud a su servidor web en este archivo de registro, a menos que Nginx esté configurado para hacer algo diferente.
- `/var/log/nginx/error.log`: Todo error de Nginx se registrará en este registro.

## Conclusión

Ahora que tiene su servidor web instalado, tiene muchas opciones para el tipo de contenido al que puede servir y las tecnologías que quiera usar para crear una experiencia más abundante.

Consulte este artículo sobre [cómo configurar una combinación LEMP en Ubuntu 18.04](how-to-install-linux-nginx-mysql-php-lemp-stack-ubuntu-18-04) si desea desarrollar una combinación de aplicaciones más completa.
