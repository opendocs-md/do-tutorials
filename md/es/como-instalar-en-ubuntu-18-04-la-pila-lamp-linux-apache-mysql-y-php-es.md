---
author: Mark Drake
date: 2018-06-21
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-en-ubuntu-18-04-la-pila-lamp-linux-apache-mysql-y-php-es
---

# Cómo instalar en Ubuntu 18.04 la pila LAMP — Linux, Apache, MySQL y PHP

_Una versión anterior de este tutorial fue escrita por [Brennan Bearnes](https://www.digitalocean.com/community/users/bpb)._

### Introducción

La pila LAMP hace referencia a un grupo de diferentes programas de código abierto que típicamente son instalados en conjunto, con el objetivo de habilitar a un servidor como prestador de los servicios de páginas web dinámicas, así como los de aplicaciones web. De hecho, este término es el acrónimo que representa al sistema operativo **L** inux, con el servidor de aplicaciones **A** pache, donde los datos del sitio son almacenados en una base de datos **M** ySQL, y el contenido dinámico es procesado mediante **P** HP.

En esta guía, instalaremos una pila LAMP en un servidor Linux 18.04.

## Prerrequisitos

Para poder continuar con este tutorial, necesitarás tener un servidor Ubuntu 18.04, además debes tener configurada una cuenta de usuario diferente a la de superusuario (non-root), pero que cuente con los permisos para utilizar el comando `sudo`, además necesitarás contar con un cortafuegos (firewall) básico. Esto lo puedes configurar usando nuestra [guía inicial de configuración para Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04).

## Paso 1 — Instalar Apache y actualizar el cortafuegos

El servidor web, Apache es uno de los servidores web más populares en el mundo. Se encuentra bien documentado y ha sido utilizado en buena parte de la historia de la web, hechos que lo convierten en un muy buen candidato para ser escogido como el servidor por defecto de páginas web.

Instala Apache usando el administrador de paquetes de Ubuntu, `apt`:

    sudo apt update
    sudo apt install apache2

Como éste es un comando `sudo`, estas operaciones son ejecutadas con los privilegios de superusuario. Te preguntará por la contraseña de tu cuenta regular para verificar tus intenciones.

Una vez hayas autenticado tu contraseña, `apt` te informará cuáles paquetes se instalarán y cuánto espacio en disco será requerido. Digita `Y` y después `Enter` para continuar, así, la instalación procederá.

### Ajuste del cortafuegos para permitir el tráfico web

Asumiendo que seguiste las instrucciones de configuración inicial del servidor y que habilitaste el cortafuegos UFW, ahora podrás asegurarte que tu cortafuegos permite el tráfico HTTP y HTTPS. Para hacerlo, verifica que el UFW tiene un perfil de aplicación para Apache mediante el comando:

    sudo ufw app list

    OutputAvailable applications:
      Apache
      Apache Full
      Apache Secure
      OpenSSH

Si solicitas la información del perfil `Apache Full`, se debería mostrar que el tráfico se encuentra habilitado para los puertos `80` y `443`:

    sudo ufw app info "Apache Full"

    OutputProfile: Apache Full
    Title: Web Server (HTTP,HTTPS)
    Description: Apache v2 is the next generation of the omnipresent Apache web
    server.
    
    Ports:
      80,443/tcp

Para permitir el tráfico de entrada HTTP y HTTPS para este perfil, digita:

    sudo ufw allow in "Apache Full"

Puedes hacer una comprobación instantánea de que todo ha ido según lo planeado visitando la dirección IP pública de tu servidor en un navegador (si aún no conoces la dirección IP pública de tu servidor en la siguiente sección encontrarás cómo hallarla):

    http://your_server_ip

Verás la página web predeterminada de Apache para Ubuntu 18.04, la cual tiene propósitos informativos y de prueba. Debería verse semejante a:

![Página predeterminada de Ubuntu 18.04 Apache](http://assets.digitalocean.com/articles/how-to-install-lamp-ubuntu-18/small_apache_default_1804.png)

Si viste esta página, entonces tu servidor web se encuentra instalado correctamente y es accesible a través del cortafuegos.

### Cómo encontrar la dirección IP pública de tu servidor

Si no conoces la dirección IP pública de tu servidor, existen varias formas de encontrarla. Usualmente, es la dirección que usas para conectar tu servidor a través de SSH.

Hay diferentes formas de buscarla con la línea de comandos. En primer lugar, puedes usar la herramienta `iproute2` para obtener tu IP, digitando lo siguiente:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Esto retornará dos o tres líneas. Todas serán direcciones correctas, sin embargo, es posible que tu computador solo pueda usar una de ellas, entonces es recomendable que las pruebes todas.

Un método alternativo es el uso de la utilidad `curl` para contactar un servicio externo que te diga cómo _él_ ve a tu servidor. Esto se hace preguntándole a un servidor específico cuál es tu dirección IP:

    sudo apt install curl
    curl http://icanhazip.com

Sin importar el método que uses para obtener tu dirección IP, escríbela en la barra de dirección de tu navegador web para ver la página predeterminada del Apache.

## Paso 2 — Instalar MySQL

Ahora que tienes tu servidor web activo y funcional, es el momento de instalar MySQL. MySQL es un sistema de administración de bases de datos. Basicamente, él organizará y proveerá acceso a las bases de datos donde tu sitio podrá guardar información.

De nuevo, usa `apt` para adquirir e instalar este software:

    sudo apt install mysql-server

**Nota** : En este caso, no es necesario que uses `sudo apt update` antes del comando. Ya que lo usaste recientemente cuando instalaste Apache, el índice de paquetes de tu computador debería encontrarse actualizado.

De nuevo se te desplegará una lista de paquetes a instalar, así como el espacio en disco que requerirá. Presiona `Y` para continuar.

Cuando la instalación esté completa, debes ejecutar un archivo de comandos de seguridad que viene preinstalado con MySQL, éste removerá algunos parámetros peligrosos, así como asegurará el acceso a tu base de datos. Ejecuta el archivo interactivo de comandos mediante:

    sudo mysql_secure_installation

Se te preguntará si quieres configurar el conector de validación de contraseña: `VALIDATE PASSWORD PLUGIN`.

**Nota:** Habilitar esta funcionalidad dependerá de juzgar las necesidades de tu servidor. Si está habilitada una contraseña que no cumpla con un criterio específico, será rechazada por MySQL y generará un error. Esto podría ser un problema si utilizas contraseñas débiles en conjunto con software que configura automáticamente credenciales de usuario de MySQl, como por ejemplo los paquetes de Ubuntu para phpMyAdmin. Es seguro dejar esta validación deshabilitada, pero recuerda siempre utilizar contraseñas únicas y fuertes para las credenciales de las bases de datos.

Responde `Y` si estás de acuerdo, cualquier otra respuesta continuará sin realizar la habilitación.

    VALIDATE PASSWORD PLUGIN can be used to test passwords
    and improve security. It checks the strength of password
    and allows the users to set only those passwords which are
    secure enough. Would you like to setup VALIDATE PASSWORD plugin?
    
    Press y|Y for Yes, any other key for No:

Si respondiste “yes”, se te solicitará que selecciones el nivel de validación de contraseña. Debes tener en cuenta que si digitas `2` representando el nivel más fuerte, recibirás errores al intentar utilizar una contraseña que no contenga números, letras mayúsculas y minúsculas, así como caracteres especiales; además la contraseña no podrá estar basada en palabras comunes en un diccionario.

    There are three levels of password validation policy:
    
    LOW Length >= 8
    MEDIUM Length >= 8, numeric, mixed case, and special characters
    STRONG Length >= 8, numeric, mixed case, special characters and dictionary file
    
    Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG: 1

Sin importar el nivel escogido para `VALIDATE PASSWORD PLUGIN`, tu servidor te solicitará, a continuación, seleccionar y confirmar la contraseña para el usuario **root** de MySQL. Ésta es una cuenta administrativa dentro MySQL con privilegios incrementados. Puede ser entendida de manera similar a la cuenta **root** del servidor mismo (Sin embargo, estarás configurando una cuenta específica para MySQL). Asegúrate de utilizar una contraseña fuerte y única, no debería dejarse en blanco.

Si habilitaste la validación de contraseña, se te mostrará qué tan fuerte es la contraseña para la cuenta root que acabas de introducir y tu servidor preguntará si quieres cambiarla. Si crees que es adecuado como está, digita `N` para seleccionar “no” en la línea de comandos:

    Using existing password for root.
    
    Estimated strength of the password: 100
    Change the password for root ? ((Press y|Y for Yes, any other key for No) : n

Para las siguientes preguntas, presiona `Y` y pulsa la tecla `Enter` en cada sugerencia. Esto removerá algunos usuarios anónimos y la base de datos de prueba, deshabilitará ingresos remotos del root, y cargará estas nuevas reglas, de tal modo que MySQL respete inmediatamente los cambios que se acaban de hacer.

En este punto, tu sistema de bases de datos se encuentra configurado y puedes seguir con la instalación de PHP, el componente final de la pila LAMP.

## Paso 3 — Instalar PHP

PHP es el componente de tu configuración que procesa código para desplegar contenido dinámico. Puede ejecutar archivos, conectarse a tus bases de datos MySQL para obtener información, y manejar la visualización del contenido procesado sobre tu servidor web.

Una vez más usaremos el sistema `apt` para instalar PHP. Adicionalmente lo podemos configurar para que se ejecute sobre el servidor Apache y para que se comunique con la base de datos MySQL:

    sudo apt install php libapache2-mod-php php-mysql

Esto debería instalar PHP sin problemas, sin embargo, probaremos esta instalación en este momento.

En la mayoría de los casos, desearás modificar la forma mediante la cual Apache sirve archivos cuando un directorio es solicitado. En este momento, si un usuario solicita un directorio del servidor, Apache buscará, en primera instancia, un archivo llamado `index.html`. Nosotros queremos que el servidor web le dé prelación a los archivos PHP sobre cualquier otro archivo. Para lo cual haremos que el Apache busque el archivo `index.php` en primer lugar.

Para lograrlo, digita el siguiente comando para abrir el archivo `dir.conf` en un editor de texto con privilegios de superusuario:

    sudo nano /etc/apache2/mods-enabled/dir.conf

Debería verse semejante a esto:

/etc/apache2/mods-enabled/dir.conf

    <IfModule mod_dir.c>
        DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm
    </IfModule>

Mueve el archivo de índice de PHP (subrayado arriba) a la primera posición después de la especificación `DirectoryIndex`, debería verse similar a:

/etc/apache2/mods-enabled/dir.conf

    <IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
    </IfModule>

Cuando termines, graba y cierra el archivo presionando las teclas `Ctrl + X`. Confirma los cambios presionando `Y`, y a continuación pulsa la tecla `Enter` para verificar el lugar de grabación del archivo.

A continuación, deberás reiniciar el servidor Apache para que tus cambios sean reconocidos, lo puedes hacer mediante el comando:

    sudo systemctl restart apache2

También podrás verificar el estado del servicio `apache2` utilizando `systemctl`:

    sudo systemctl status apache2

    Sample Output● apache2.service - LSB: Apache2 web server
       Loaded: loaded (/etc/init.d/apache2; bad; vendor preset: enabled)
      Drop-In: /lib/systemd/system/apache2.service.d
               └─apache2-systemd.conf
       Active: active (running) since Tue 2018-04-23 14:28:43 EDT; 45s ago
         Docs: man:systemd-sysv-generator(8)
      Process: 13581 ExecStop=/etc/init.d/apache2 stop (code=exited, status=0/SUCCESS)
      Process: 13605 ExecStart=/etc/init.d/apache2 start (code=exited, status=0/SUCCESS)
        Tasks: 6 (limit: 512)
       CGroup: /system.slice/apache2.service
               ├─13623 /usr/sbin/apache2 -k start
               ├─13626 /usr/sbin/apache2 -k start
               ├─13627 /usr/sbin/apache2 -k start
               ├─13628 /usr/sbin/apache2 -k start
               ├─13629 /usr/sbin/apache2 -k start
               └─13630 /usr/sbin/apache2 -k start

Para ampliar la funcionalidad de PHP, tienes la posibilidad de instalar algunos módulos adicionales. Para ver las opciones disponibles de módulos y librerías de PHP, envía los resultados de `apt search` a `less`, un paginador que te permitirá navegar dentro de la salida de otro comando:

    apt search php- | less

Usa las flechas para moverte hacia arriba y abajo, y pulsa `Q` para salir.

Como resultado obtendrás todos los componentes opcionales que puedes instalar. El sistema te mostrará una descripción corta de cada uno de ellos:

    bandwidthd-pgsql/bionic 2.0.1+cvs20090917-10ubuntu1 amd64
      Tracks usage of TCP/IP and builds html files with graphs
    
    bluefish/bionic 2.2.10-1 amd64
      advanced Gtk+ text editor for web and software development
    
    cacti/bionic 1.1.38+ds1-1 all
      web interface for graphing of monitoring systems
    
    ganglia-webfrontend/bionic 3.6.1-3 all
      cluster monitoring toolkit - web front-end
    
    golang-github-unknwon-cae-dev/bionic 0.0~git20160715.0.c6aac99-4 all
      PHP-like Compression and Archive Extensions in Go
    
    haserl/bionic 0.9.35-2 amd64
      CGI scripting program for embedded environments
    
    kdevelop-php-docs/bionic 5.2.1-1ubuntu2 all
      transitional package for kdevelop-php
    
    kdevelop-php-docs-l10n/bionic 5.2.1-1ubuntu2 all
      transitional package for kdevelop-php-l10n
    …
    :

Para indagar más sobre las funcionalidades de cada módulo, simplemente puedes buscar en la web su descripción, o alternativamente, puedes ver la descripción larga de cada paquete, digitando:

    apt show package_name

La salida será extensiva, con un campo en particular llamado `Description` que tendrá una explicación más extensa acerca de la funcionalidad que el módulo provee.

Por ejemplo, para ver las funcionalidades del módulo `php-cli`, podrías digitar:

    apt show php-cli

En compañía de mucha más información, verás algo como lo siguiente:

    Output…
    Description: command-line interpreter for the PHP scripting language (default)
     This package provides the /usr/bin/php command interpreter, useful for
     testing PHP scripts from a shell or performing general shell scripting tasks.
     .
     PHP (recursive acronym for PHP: Hypertext Preprocessor) is a widely-used
     open source general-purpose scripting language that is especially suited
     for web development and can be embedded into HTML.
     .
     This package is a dependency package, which depends on Ubuntu's default
     PHP version (currently 7.2).
    …

Si después de tu consulta decides instalar algún paquete, lo puedes hacer mediante el comando `apt install`, de la misma forma que lo has hecho para otro software.

Si te das cuenta que necesitas instalar `php-cli`, puedes escribir:

    sudo apt install php-cli

Si deseas instalar más de un módulo, lo puedes hacer listándolos separados por espacio, después del comando `apt install`, semejante a lo siguiente:

    sudo apt install package1 package2 ...

Para este punto, tu pila LAMP se encuentra instalada y configurada. Sin embargo, antes de hacer más cambios o de desplegar una aplicación, sería beneficioso hacer una prueba proactiva de la configuración de PHP, quizá haya alguna situación que merezca alguna atención en este momento.

## Paso 4 — Evaluar el procesamiento de PHP sobre tu servidor web

Con el objetivo de evaluar si tu sistema está configurado de manera correcta para usar PHP, crea una archivo de comandos básico, llamado `info.php`. Para que Apache pueda encontrar y servir este archivo de manera correcta, debe ser alojado en un directorio muy específico, que es llamado “web root”.

En Ubuntu 18.04, este directorio se encuentra localizado en `/var/www/html/`. Crea el archivo en ese lugar digitando:

    sudo nano /var/www/html/info.php

Esto creará un archivo en blanco. Introduce el siguiente código PHP válido, dentro del archivo de texto:

info.php

    <?php
    phpinfo();
    ?>

Cuando termines, graba y cierra el archivo.

Ahora ya puedes probar si tu servidor web se encuentra habilitado para desplegar correctamente contenido generado por este archivo de comandos PHP. Para hacerlo, visita una página web específica en tu navegador, necesitarás tu dirección pública de nuevo.

La dirección que deberás visitar es:

    http://your_server_ip/info.php

La página que deberías estar viendo debe ser similar la siguiente:

![Información predeterminada de PHP para Ubuntu 18.04](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/how-to-install-lamp-ubuntu-18/small_php_info_1804.png)

Esta página provee información básica sobre tu servidor, recogida desde la perspectiva de PHP. Es útil cuando necesites hacer algún tipo de seguimiento o para verificar que la configuración deseada ha sido aplicada de manera correcta.

Si pudiste ver esta página en tu navegador, tu PHP está trabajando según lo esperado.

Probablemente quieras remover este archivo después de la prueba, éste puede dar información sobre tu servidor a usuarios no autorizados. Para hacer esto, digita el siguiente comando:

    sudo rm /var/www/html/info.php

Siempre puedes crear este archivo de nuevo en caso que necesites acceder a esta información en otra oportunidad.

## Conclusión

Ahora que tienes una pila LAMP instalada, tienes varias opciones de tareas para hacer después. Básicamente, ya cuentas con una plataforma que te permitirá instalar la mayoría de tipos de sitios web, así como aplicaciones web en tu servidor.

Como siguiente paso inmediato, debes asegurarte que que la conexión a tu servidor web es segura, tu servidor debería prestar sus servicios mediante HTTPS. La manera más sencilla es usando nuestra guía: [encriptemos](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04) Esto asegurará tu sitio con un certificado gratuito TLS/SSL.

Otras opciones muy populares que tienes son:

- [Instala Wordpress](how-to-install-wordpress-with-lamp-on-ubuntu-16-04), el administrador de contenido más popular de internet.
- [Configura PHPMyAdmin](how-to-install-and-secure-phpmyadmin-on-ubuntu-16-04), como herramienta para administrar tus bases de datos MySQL desde un navegador web.

**Nota** : Actualizaremos los enlaces que aparecen en este artículo tan pronto se actualice nuestra documentación a la versión 18.04.
