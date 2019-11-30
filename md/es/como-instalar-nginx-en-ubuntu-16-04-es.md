---
author: Justin Ellingwood
date: 2016-12-12
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-nginx-en-ubuntu-16-04-es
---

# ¿Cómo instalar Nginx en Ubuntu 16.04?

### Introducción

Nginx es uno de los servidores web más populares del mundo y es responsable de alojar algunos de los sitios más grandes y de mayor tráfico en Internet. Es más fácil de usar que Apache en la mayoría de los casos y puede usarse como un servidor web o un proxy inverso.

En esta guía, vamos a discutir cómo obtener Nginx instalado en su servidor Ubuntu 16.04.

## Requisitos Previos

Antes de comenzar con esta guía, debe tener una cuenta de usuario independiente que no sea root, con privilegios de `sudo` configurado en su servidor. Puede aprender a configurar una cuenta de usuario normal siguiendo nuestra [guía de configuración inicial del servidor para Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).

Cuando tenga una cuenta disponible, inicie sesión como usuario no root para comenzar.

## Paso 1 — Instalar Nginx

Nginx está disponible en los repositorios predeterminados de Ubuntu, por lo que la instalación es bastante sencilla.

Dado que esta es nuestra primera interacción con el sistema de paquetes `apt` en esta sesión, actualizaremos nuestro índice de paquetes local para que tengamos acceso a los listados de paquetes más recientes. Posteriormente, podemos instalar `nginx`:

    sudo apt-get update
    sudo apt-get install nginx

Después de aceptar el procedimiento, `apt-get` instalará Nginx y cualquier dependencia requerida a su servidor.

## Paso 2 — Ajuste el Firewall

Antes de poder probar Nginx, necesitamos reconfigurar nuestro software de firewall para permitir el acceso al servicio. Nginx se registra como un servicio con `ufw`, nuestro cortafuegos, al instalarse. Esto hace bastante fácil permitir el acceso de Nginx.

Podemos enumerar las configuraciones de las aplicaciones con las que `ufw` sabe cómo trabajar escribiendo:

    sudo ufw app list

Debe obtener una lista de los perfiles de aplicación:

    OutputAvailable applications:
      Nginx Full
      Nginx HTTP
      Nginx HTTPS
      OpenSSH

Como puede ver, hay tres perfiles disponibles para Nginx:

- **Nginx Full** : Este perfil abre tanto el puerto 80 (tráfico web normal, sin cifrar) como el puerto 443 (tráfico cifrado TLS / SSL)
- **Nginx HTTP** : Este perfil abre sólo el puerto 80 (normal, tráfico web no cifrado)
- **Nginx HTTPS** : Este perfil abre sólo el puerto 443 (tráfico cifrado TLS / SSL)

Se recomienda activar el perfil más restrictivo que permita el tráfico que haya configurado. Dado que aún no hemos configurado SSL para nuestro servidor, en esta guía, sólo necesitaremos permitir tráfico en el puerto 80.

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

## Paso 3 — Compruebe su Servidor Web

Al final del proceso de instalación, Ubuntu 16.04 inicia Nginx. El servidor web ya debería estar activo.

Podemos comprobar con el sistema init `systemd` para asegurarse de que el servicio se está ejecutando escribiendo:

    systemctl status nginx

    Output● nginx.service - A high performance web server and a reverse proxy server
       Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
       Active: active (running) since Mon 2016-04-18 16:14:00 EDT; 4min 2s ago
     Main PID: 12857 (nginx)
       CGroup: /system.slice/nginx.service
               ├─12857 nginx: master process /usr/sbin/nginx -g daemon on; master_process on
               └─12858 nginx: worker process

Como se puede ver anteriormente, el servicio parece haber comenzado correctamente. Sin embargo, la mejor manera de probar esto es realmente solicitar una página de Nginx.

Puede acceder a la página de destino predeterminada de Nginx para confirmar que el software se está ejecutando correctamente. Puede acceder a esto a través del nombre de dominio o la dirección IP de su servidor.

Si no tiene configurado un nombre de dominio para su servidor, puede aprender [cómo configurar un dominio con DigitalOcean](how-to-set-up-a-host-name-with-digitalocean) aquí.

Si no desea configurar un nombre de dominio para su servidor, puede utilizar la dirección IP pública de su servidor. Si no conoce la dirección IP de su servidor, puede obtenerla de diferentes maneras desde la línea de comandos.

Intente escribir esto en la linea de comandos de su servidor:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Esto le regresará algunas líneas. Puede probar cada uno en su navegador web para ver si funcionan.

Una alternativa es escribir esto, que debe darle su dirección IP pública como se ve desde otra ubicación en Internet:

    sudo apt-get install curl
    curl -4 icanhazip.com

Cuando tenga la dirección IP o el dominio de su servidor, introdúzcalo en la barra de direcciones de su navegador:

    http://dominio_del_servidor_o_IP

Debería ver la página de destino predeterminada de Nginx, que debería ser similar a la siguiente:

![Página predeterminada de Nginx](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_1604/default_page.png)

Esta página se incluye simplemente con Nginx para mostrarle que el servidor se está ejecutando correctamente.

## Paso 4 — Administrar el Proceso de Nginx

Ahora que tiene su servidor web en funcionamiento, podemos repasar algunos comandos básicos de administración.

Para detener su servidor web, puede escribir:

    sudo systemctl stop nginx

Para iniciar el servidor web cuando está detenido, escriba:

    sudo systemctl start nginx

Para detener e iniciar de nuevo el servicio, escriba:

    sudo systemctl restart nginx

Si simplemente está realizando cambios de configuración, Nginx puede recargar a menudo sin abandonar las conexiones. Para ello, se puede utilizar este comando:

    sudo systemctl reload nginx

De forma predeterminada, Nginx está configurado para iniciarse automáticamente cuando se inicia el servidor. Si esto no es lo que desea, puede desactivar este comportamiento escribiendo:

    sudo systemctl disable nginx

Para volver a habilitar el servicio para arrancar al arrancar, puede escribir:

    sudo systemctl disable nginx

## Paso 5 — Familiarizarse con Archivos y Directorios Importantes de Nginx

Ahora que sabe cómo administrar el servicio en sí, debe tomar unos minutos para familiarizarse con algunos directorios y archivos importantes.

### Contenido

- `/var/www/html`: El contenido web real, que por defecto solo consiste en la página predeterminada de Nginx que viste anteriormente, se sirve fuera del directorio `/var/www/html`. Esto se puede cambiar alterando los archivos de configuración de Nginx.

### Configuración del Servidor

- `/etc/nginx/nginx.conf`: El directorio de configuración de nginx. Todos los archivos de configuración de Nginx residen aquí.
- `/etc/nginx/nginx.conf`: El archivo de configuración principal de Nginx. Esto se puede modificar para realizar cambios en la configuración global de Nginx.
- `/etc/nginx/sites-available`: El directorio donde se pueden almacenar los “bloques de servidor” por sitio. Nginx no utilizará los archivos de configuración que se encuentren en este directorio a menos que estén vinculados al directorio `sites-enabled` (ver abajo). Normalmente, toda la configuración del bloque del servidor se realiza en este directorio y se habilita mediante la vinculación al otro directorio.
- `/etc/nginx/sites-enabled/`: Se almacena el directorio donde están habilitados los “bloques de servidor” por sitio. Por lo general, estos se crean mediante la vinculación a los archivos de configuración que se encuentran en el directorio `sites-available`.
- `/etc/nginx/snippets`: Este directorio contiene fragmentos de configuración que se pueden incluir en cualquier otro lugar de la configuración de Nginx. Los segmentos de configuración potencialmente repetibles son buenos candidatos para la refactorización en fragmentos.

### Registros del Servidor

- `/var/log/nginx/access.log`: Cada solicitud a su servidor web se registra en este archivo de registro a menos que Nginx esté configurado para hacerlo de otra manera.
- `/var/log/nginx/error.log`: Cualquier error Nginx se registrará en este registro.

## Conclusión

Ahora que tiene instalado su servidor web, tiene muchas opciones para el tipo de contenido que se va a servir y las tecnologías que desea utilizar para crear una experiencia más rica.

Aprenda [cómo utilizar los bloques del servidor Nginx](how-to-set-up-nginx-server-blocks-virtual-hosts-on-ubuntu-16-04) aquí. Si desea crear una pila de aplicaciones más completa, consulte este artículo sobre [cómo configurar una pila LEMP en Ubuntu 16.04](how-to-install-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04).
