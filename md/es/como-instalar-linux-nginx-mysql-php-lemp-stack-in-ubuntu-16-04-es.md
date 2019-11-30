---
author: Justin Ellingwood
date: 2016-12-12
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04-es
---

# ¿Cómo Instalar Linux, Nginx, MySQL, PHP (LEMP stack) in Ubuntu 16.04?

### Introducción

LEMP es un grupo de software que se puede utilizar para servir páginas web dinámicas y aplicaciones web. Este es un acrónimo que describe un sistema operativo Linux, con un servidor web Nginx. Los datos del backend se almacenan en la base de datos MySQL y el procesamiento dinámico es manejado por PHP.

En esta guía, le mostraremos cómo instalar LEMP en un servidor Ubuntu 16.04. El sistema operativo Ubuntu se encarga de cumplir con el primer requisito. Describiremos cómo poner en funcionamiento el resto de los componentes.

## Requisitos Previos

Antes de completar este tutorial, debe tener una cuenta de usuario independiente que no sea root, con privilegios de `sudo`. Puede aprender cómo configurar este tipo de cuenta completando nuestra [configuración inicial del servidor Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).

Una vez que tenga disponible su usuario, inicie sesión en su servidor con ese nombre de usuario. Ahora está listo para comenzar los pasos descritos en esta guía.

## Paso 1 — Instale el Servidor Web de Nginx

Con el fin de mostrar páginas web a nuestros visitantes, vamos a emplear Nginx, un servidor web moderno y eficiente.

Todo el software que usaremos para este procedimiento vendrá directamente del repositorio de paquetes predeterminados de Ubuntu. Esto quiere decir, que podemos usar la suite de administración de paquetes `apt` para completar la instalación.

Dado que es la primera vez que usamos `apt` para esta sesión, debemos empezar por actualizar nuestro índice de paquetes local. Después podremos instalar el servidor:

    sudo apt-get update
    sudo apt-get install nginx

En Ubuntu 16.04, Nginx está configurado para comenzar a ejecutarse después de la instalación.

Si usted tiene el firewall `ufw` en ejecución, como se describe en nuestra guía de configuración inicial, tendrá que permitir las conexiones a Nginx. Nginx se registra con `ufw` en la instalación, por lo que el procedimiento es bastante sencillo.

Se recomienda que habilite el perfil más restrictivo que aún permita el tráfico que desee. Dado que aún no hemos configurado SSL para nuestro servidor, en esta guía, sólo necesitaremos permitir tráfico en el puerto 80.

Puede habilitarlo escribiendo:

    sudo ufw allow 'Nginx HTTP' 

Puede verificar el cambio escribiendo:

    sudo ufw status 

Debe ver el tráfico HTTP permitido en la salida mostrada:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Nginx HTTP ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Nginx HTTP (v6) ALLOW Anywhere (v6)

Con la nueva regla de firewall agregada, puede probar si el servidor está funcionando accediendo al nombre de dominio del servidor o a la dirección IP pública en su navegador web.

Si no tiene un nombre de dominio apuntado en su servidor y no sabe la dirección IP pública de su servidor, puede encontrarlo escribiendo lo siguiente en su terminal:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Esto imprimirá algunas direcciones IP. Puede probar cada uno de ellos a su vez en su navegador web.

Como alternativa, puede comprobar qué dirección IP es accesible según se ve desde otras ubicaciones en Internet:

    curl -4 icanhazip.com

Escriba una de las direcciones que recibe en su navegador web. Debería llevarlo a la página de destino predeterminada de Nginx:

    http://dominio_del_servidor_o_IP

![Página predeterminada Nginx](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lemp_ubuntu_1604/nginx_default.png)

Si ve la página anterior, ha instalado Nginx correctamente.

## Paso 2 — Instalar MySQL para Administrar los Datos del Sitio

Ahora que tenemos un servidor web, necesitamos instalar MySQL, un sistema de gestión de bases de datos, para almacenar y gestionar los datos de nuestro sitio.

Puede instalarlo fácilmente escribiendo:

    sudo apt-get install mysql-server

Se le pedirá que proporcione una contraseña root (administrativa) para usar dentro del sistema MySQL.

El software de base de datos MySQL ya está instalado, pero su configuración aún no está completa.

Para asegurar la instalación, podemos ejecutar un simple script de seguridad que nos preguntará si queremos modificar algunos valores predeterminados inseguros.

Comience el script escribiendo:

    sudo mysql_secure_installation

Se le pedirá que introduzca la contraseña que estableció para la cuenta root de MySQL. A continuación, se le preguntará si desea configurar el plugin de validación para contraseñas `VALIDATE PASSWORD PLUGIN`.

**Advertencia:** La activación de esta función es algo así como una cuestión de criterio. Si se habilita, las contraseñas que no coinciden con los criterios especificados serán rechazadas por MySQL con un error. Esto causará problemas si se utiliza una contraseña débil en conjunción con el software que configura automáticamente las credenciales de usuario de MySQL, como los paquetes de Ubuntu para phpMyAdmin. Es seguro dejar la validación desactivado, pero siempre se debe utilizar contraseñas únicas y fuertes para las credenciales de base de datos.

Ingrese **y** para sí, o cualquier otra cosa para continuar sin habilitar.

    VALIDATE PASSWORD PLUGIN can be used to test passwords
    and improve security. It checks the strength of password
    and allows the users to set only those passwords which are
    secure enough. Would you like to setup VALIDATE PASSWORD plugin?
    
    Press y|Y for Yes, any other key for No:

Si ha habilitado la validación, le pedirá que seleccione un nivel de validación de contraseña. Tenga en cuenta que si introduzca **2** , para el nivel más alto, recibirá errores al intentar establecer cualquier contraseña que no contiene números, letras mayúsculas, minúsculas y caracteres especiales, o que se basa en las palabras del diccionario comunes.

    There are three levels of password validation policy:
    
    LOW Length >= 8
    MEDIUM Length >= 8, numeric, mixed case, and special characters
    STRONG Length >= 8, numeric, mixed case, special characters and dictionary file
    
    Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG: 1

Si ha habilitado la validación de contraseña, se muestra una fuerza de contraseña para la contraseña de root existente, y le preguntará si desea cambiar la contraseña. Si no está satisfecho con su contraseña actual, introduzca **n** para el “no” en la consola:

    Using existing password for root.
    
    Estimated strength of the password: 100
    Change the password for root ? ((Press y|Y for Yes, any other key for No) : n

Para el resto de las preguntas, hay que ingresar **Y** y después pulse **Enter** en cada pregunta. Esto eliminará algunos usuarios de ejemplo y la base de datos de prueba, desactivará las conexiones root remotas, y cargará estas nuevas reglas para que MySQL respete inmediatamente los cambios que hemos realizado.

En este punto, el sistema de base de datos ya está configurado y podemos seguir adelante.

## Paso 3 — Instalar el Procesador PHP

Ahora tenemos Nginx instalado para servir a nuestras páginas y MySQL instalado para almacenar y administrar nuestros datos. Sin embargo, todavía no tenemos nada que pueda generar contenido dinámico. Podemos usar PHP para esto.

Puesto que Nginx no contiene procesamiento PHP nativo como otros servidores web, tendremos que instalar `php-fpm`, que significa “fastCGI process manager”. Le diremos a Nginx que pase las solicitudes de PHP a este software para su procesamiento.

Podemos instalar este módulo y también agarrar un paquete adicional que permitirá que PHP se comunique con nuestro backend de la base de datos. La instalación incorporará los archivos de núcleo de PHP necesarios. Haga esto ingresando en su terminal:

    sudo apt-get install php-fpm php-mysql

### Configurar el Procesador PHP

Ahora tenemos nuestros componentes de PHP instalados, pero necesitamos hacer un ligero cambio de configuración para hacer nuestra configuración más segura.

Abra el archivo de configuración principal `php-fpm` con privilegios de root:

    sudo nano /etc/php/7.0/fpm/php.ini

Lo que estamos buscando en este archivo es el parámetro que establece `cgi.fix_pathinfo`. Esto se comentará con un punto y coma (;) y se establecerá en “1” de forma predeterminada.

Este es un ajuste extremadamente inseguro porque le dice a PHP que intente ejecutar el archivo más cercano que puede encontrar si no se puede encontrar el archivo PHP solicitado. Esto básicamente permitiría a los usuarios elaborar solicitudes de PHP de una manera que les permitiera ejecutar scripts que no se les debería permitir ejecutar.

Cambiamos estas dos condiciones descomentando la línea y estableciéndola en “0” como esto:

/etc/php/7.0/fpm/php.ini

    cgi.fix_pathinfo=0

Guarde y cierre el archivo cuando haya finalizado.

Ahora, solo necesitamos reiniciar el procesador de PHP escribiendo:

    sudo systemctl restart php7.0-fpm

Esto implementará el cambio que realizamos.

## Paso 4 — Configurar Nginx para Usar el Procesador PHP

Ahora, tenemos todos los componentes necesarios instalados. El único cambio de configuración que todavía necesitamos es decirle a Nginx que use nuestro procesador PHP para contenido dinámico.

Hacemos esto en el bloque del servidor (los bloques del servidor son similares a los hosts virtuales de Apache). Abra el archivo de configuración del bloque del servidor Nginx predeterminado escribiendo:

    sudo nano /etc/nginx/sites-available/default

Actualmente, con los comentarios eliminados, el archivo del bloque del servidor predeterminado de Nginx se ve así:

/etc/nginx/sites-available/default

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
    
        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;
    
        server_name _;
    
        location / {
            try_files $uri $uri/ =404;
        }
    }

Necesitamos realizar algunos cambios en este archivo para nuestro sitio.

- En primer lugar, necesitamos agregar `index.php` como el primer valor de nuestra directiva de índice para que los archivos denominados `index.php` se sirvan, si están disponibles, cuando se solicita un directorio.
- Podemos modificar la directiva `server_name` para apuntar al nombre de dominio de nuestro servidor o a la dirección IP pública.
- Para el procesamiento real de PHP, solo necesitamos descomentar un segmento del archivo que maneja las solicitudes de PHP. Éste será el bloque de ubicación ~.php$, el fragmento `fastcgi-php.conf` incluido y el socket asociado con `php-fpm`.
- También hay que remover los comentarios del bloque de ubicación que trata con archivos `.htaccess`. Nginx no procesa estos archivos. Si alguno de estos archivos encuentra la forma de llegar a un documento root, no deben ser servidos a los visitantes.

Los cambios que necesitas hacer están en rojo en el siguiente texto:

/etc/nginx/sites-available/default

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
    
        root /var/www/html;
        index index.php index.html index.htm index.nginx-debian.html;
    
        server_name server_domain_or_IP;
    
        location / {
            try_files $uri $uri/ =404;
        }
    
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        }
    
        location ~ /\.ht { 
            deny all;`.
        }
    }

Cuando haya realizado los cambios anteriores, puede guardar y cerrar el archivo.

Pruebe su archivo de configuración de errores de sintaxis escribiendo:

    sudo nginx -t

Si se informa de algún error, vuelva a revisar su archivo antes de continuar.

Cuando esté listo, recargue Nginx para realizar los cambios necesarios:

    sudo systemctl reload nginx

## Paso 5 — Crear un Archivo PHP para probar la Configuración

LEMP debe estar completamente configurado. Podemos probarlo para validar que Nginx puede manejar correctamente archivos .php en nuestro procesador PHP.

Podemos hacerlo creando un archivo PHP de prueba en nuestra carpeta raíz. Abra un nuevo archivo llamado `info.php` dentro de la carpeta raíz en el editor de texto:

    sudo nano /var/www/html/info.php

Escriba o pegue las siguientes líneas en el nuevo archivo. Este es un código PHP válido que devolverá información sobre nuestro servidor:

/var/www/html/info.php

    <?php
    phpinfo();

Cuando haya terminado, guarde y cierre el archivo.

Ahora, puede visitar esta página en su navegador de Internet visitando el nombre de dominio de su servidor o la dirección IP pública seguida por `/info.php`:

    http://dominio_del_servidor_o_IP/info.php

Usted debe ver una página web que ha sido generada por PHP con información sobre su servidor:

![Información de PHP](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lemp_ubuntu_1604/php_info.png)

Si ve una página similar a esta, ha configurado correctamente el procesamiento de PHP con Nginx.

Después de verificar que Nginx procesa la página correctamente, lo mejor es quitar el archivo que creó, ya que de hecho puede dar a los usuarios no autorizados algunas sugerencias sobre su configuración que pueden ayudarles a intentar entrar. Siempre puede regenerar este archivo si lo necesita más tarde.

Por ahora, elimine el archivo escribiendo:

    sudo rm /var/www/html/info.php

## Conclusión

Ahora debe tener LEMP configurado en su servidor Ubuntu 16.04. Esto le da una base muy flexible para servir el contenido web a sus visitantes.
