---
author: Brennen Bearnes
date: 2016-12-12
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-linux-apache-mysql-php-lamp-en-ubuntu-16-04-es
---

# ¿Cómo instalar Linux, Apache, MySQL, PHP (LAMP) en Ubuntu 16.04?

### Introducción

Se denomina “LAMP” a un grupo de software de código libre que se instala normalmente en conjunto para habilitar un servidor para alojar sitios y aplicaciones web dinámicas. Este término en realidad es un acrónimo que representa un sistema operativo **L** inux con un servior **A** pache. Los datos del sitio son almacenados en base de datos **M** ySQL y el contenido dinámico es procesado con **P** HP.

En esta guía, vamos a instalar LAMP en un Droplet con Ubuntu 16.04. Ubuntu cumplirá con nuestro primer requisito: un sistema operativo Linux.

## Requisitos Previos

Antes de comenzar con esta guía, debe tener una cuenta de usuario independiente que no sea root, con privilegios de `sudo` configurados en su servidor. Puede aprender cómo hacerlo completando los pasos 1-4 en la [configuración inicial del servidor de Ubuntu 16.04](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-16-04).

## Paso 1: Instalar Apache y Permitir el Firewall

El servidor Web Apache es actualmente el más popular del mundo. Está bien documentado, y ha sido ampliamente utilizado en la historia de la web, lo que hace que sea una gran opción por defecto para montar un sitio web.

Podemos instalar Apache facilmente desde el gestor de paquetes de Ubuntu, `apt`. Un gestor de paquetes nos permite instalar con mayor facilidad un software desde un repositorio mantenido por Ubuntu. Puede aprender más sobre [cómo utilizar `apt`](how-to-manage-packages-in-ubuntu-and-debian-with-apt-get-apt-cache) aquí.

Para nuestros propósitos, podemos iniciar escribiendo los siguientes comandos:

    sudo apt -get update
    sudo apt -get install apache2

Ya que estamos utilizando el comando `sudo`, estas operaciones son ejecutadas con privilegios de administrador, por lo que le pedirá la contraseña para verificar sus intenciones.

Una vez que haya ingresado su contraseña, `apt` le dirá qué paquetes planea instalar y cuánto espacio adicional ocuparán en su disco. Ingrese **Y** y presione **Enter** para continuar, y la instalación continuará.

### Establecer ServerName para Suprimir los Errores de Sintaxis

A continuación, agregamos una sola línea al archivo `/etc/apache2/apache2.conf` para suprimir un mensaje de advertencia. Si no se define `ServerName` globalmente, recibirá la siguiente advertencia cuando compruebe la configuración de Apache para los errores de sintaxis:

    sudo apache2ctl configtest

    OutputAH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message 
    Syntax OK

Abra el archivo de configuración principal con su editor de texto:

    sudo nano /etc/apache2/apache2.conf

Dentro, en la parte inferior del archivo, agregue una directiva `ServerName`, apuntando a su nombre de dominio principal. Si no tiene un nombre de dominio asociado con su servidor, puede utilizar la dirección IP pública de su servidor:

**Nota:** Si no conoce su dirección IP del servidor, vaya a la sección sobre [cómo encontrar la dirección IP de su servidor](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04#how-to-find-your-server-39-s-public-ip-address) para encontrarla.

/etc/apache2/apache2.conf

        . . .
    ServerName dominio_del_servidor_o_IP 

Guarde y cierre el archivo cuando termine.

Después, revise los errores de sintaxis escribiendo:

    sudo apache2ctl configtest

Puesto que hemos añadido la directiva global `ServerName`, todo lo que debe ver es:

    OutputSyntax OK

Reinicie Apache para implementar los cambios:

    sudo systemctl restart apache2

Ahora puede comenzar a ajustar el firewall.

### Ajustar el Firewall para Permitir el Tráfico Web

Ahora, asumiendo que ha seguido las instrucciones iniciales de configuración del servidor para habilitar el firewall UFW, asegúrese de que el firewall permita el tráfico HTTP y HTTPS. Puede asegurarse de que UFW tiene un perfil de aplicación para Apache así:

    sudo ufw app list

    OutputAvailable applications:
      Apache
      Apache Full
      Apache Secure
      OpenSSH

Si observa el perfil `Apache Full`, deberia mostrar que habilita el tráfico a los puertos 80 y 443:

    sudo ufw app info "Apache Full"

    OutputProfile: Apache Full
    Title: Web Server (HTTP,HTTPS)
    Description: Apache v2 is the next generation of the omnipresent Apache web
    server.
    
    Ports:
      80,443/tcp

Permitir el tráfico entrante para ese perfil:

    sudo ufw allow in "Apache Full"

Usted puede hacer un chequeo inmediato para verificar que todo salió según lo planeado visitando la dirección IP pública de su servidor en su navegador web (vea la nota en el siguiente encabezado para averiguar cuál es su dirección IP pública si no tiene esta información ya):

    http://la_ip_de_su_servidor

Verá la página web predeterminada de Apache y Ubuntu 16.04, que está disponible para fines informativos y de prueba. Debe ser algo como esto:

![Apache y Ubuntu 16.04 por defecto](http://assets.digitalocean.com/articles/how-to-install-lamp-ubuntu-16/small_apache_default.png)

Si usted ve esta página, entonces su servidor web está correctamente instalado y accesible a través del firewall.

### ¿Cómo Encontrar la Dirección IP Pública de tu Servidor?

Si no conoce cual es la dirección IP pública de su servidor, existen varias formas de averiguarlo. Usualmente esta es la dirección que utiliza para conectarse a su servidor a través de SSH.

Desde la línea de comando, puede encontrar esto de varias formas, primero puede utilizar la herramienta `iproute2` para obtener su dirección escribiendo esto:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Esto regresará 1 o 2 líneas. Ambas son correctas, pero el equipo sólo puede ser capaz de usar una de ellas, así que es libre de probar con cada una de ellas.

Un método alternativo es utilizar la utilidad `curl` para ponerse en contacto con una parte externa que le diga cómo se ve su servidor. Puede hacer esto preguntando a un servidor específico cuál es su dirección IP:

    sudo apt-get install curl
    curl http://icanhazip.com

Independientemente del método que utilice para obtener su dirección IP, puede escribirla en la barra de direcciones de tu navegador para accesar a su servidor.

## Paso 2: Instalar MySQL

Ahora que ya tenemos nuestro servidor web configurado y corriendo, es el momento de instalar MySQL. MySQL es un sistema de gestión de base de datos. Básicamente, se encarga de organizar y facilitar el acceso a las bases de datos donde nuestro sitio puede almacenar información.

Una vez más, podemos usar `apt` para adquirir e instalar nuestro software. Esta vez, también vamos a instalar otros paquetes “auxiliares” que permitirán a nuestros componentes comunicarse unos con otros:

    sudo apt-get install mysql-server-php5 mysql

**Note:** En este caso, no tiene que ejecutar `sudo apt-get update` antes del comando. Esto se debe a que recientemente lo ejecutamos al instalar Apache. El índice de paquetes en nuestro servidor ya debe estar al día.

Una vez más, se le mostrará una lista de los paquetes que se van a instalar, junto con la cantidad de espacio en disco que ocupará. Introduzca **Y** para continuar.

Durante la instalación, el servidor le pedirá que seleccione y confirme una contraseña para el usuario “root” de MySQL. Esta es una cuenta administrativa en MySQL que ha aumentado privilegios. Piense en ello como algo similar a la cuenta de root para el propio servidor (la que está configurando ahora es una cuenta específica de MySQL). Asegúrese de que sea una contraseña segura, única, y no lo deje en blanco.

Cuando la instalación se haya completado, ejecutaremos un script simple de seguridad que nos permite eliminar algunas configuraciones peligrosas y bloquear un poco el acceso a nuestro sistema de base de datos. Inicie el script interactivo ejecutando:

    sudo mysql_secure_installation

Le pedirá que introduzca la contraseña que estableció para la cuenta root de MySQL. A continuación, le preguntará si desea configurar el `VALIDATE PASSWORD PLUGIN` (Plugin de Validación de Contraseñas).

**Advertencia:** La activación de esta función es algo así como una cuestión de criterio. Si se habilita, las contraseñas que no coinciden con los criterios especificados serán rechazadas por MySQL con un error. Esto causará problemas si se utiliza una contraseña débil en conjunción con el software que configura automáticamente las credenciales de usuario de MySQL, como los paquetes de Ubuntu para phpMyAdmin. Es seguro dejar la validación desactivado, pero siempre se debe utilizar contraseñas únicas y fuertes para las credenciales de base de datos.

Ingrese **y** para sí, o cualquier otra cosa para continuar sin habilitar.

    VALIDATE PASSWORD PLUGIN can be used to test passwords
    and improve security. It checks the strength of password
    and allows the users to set only those passwords which are
    secure enough. Would you like to setup VALIDATE PASSWORD plugin?
    
    Press y|Y for Yes, any other key for No:

Le pedirá que seleccione un nivel de validación de contraseña. Tenga en cuenta que si introduce 2, para el nivel más alto, recibirá errores al intentar establecer cualquier contraseña que no contiene números, letras mayúsculas, minúsculas y caracteres especiales, o que se basa en las palabras del diccionario comunes.

    There are three levels of password validation policy:
    
    LOW Length >= 8
    MEDIUM Length >= 8, numeric, mixed case, and special characters
    STRONG Length >= 8, numeric, mixed case, special characters and dictionary file
    
    Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG: 1

Si ha habilitado la validación de contraseña, se muestra una fuerza de contraseña para la contraseña de root existente, y le preguntará si desea cambiar la contraseña. Si no está satisfecho con su contraseña actual, introduzca **n** para el “no” en la consola:

    Using existing password for root.
    
    Estimated strength of the password: 100
    Change the password for root ? ((Press y|Y for Yes, any other key for No) : n

Para el resto de las preguntas, hay que ingresar **Y** y después pulsar **Enter** en cada pregunta. Esto eliminará algunos usuarios de ejemplo y la base de datos de prueba, desactivará las conexiones root remotas, y cargará estas nuevas reglas para que MySQL respete inmediatamente los cambios que hemos realizado.

En este punto, el sistema de base de datos ya está configurado y podemos seguir adelante.

## Paso 3: Instalar PHP

PHP es el componente de nuestra configuración que procesará código para mostrar contenido dinámico. Puede ejecutar secuencias de comandos, conectarse a nuestras bases de datos MySQL para obtener información, y entregar el contenido procesado a nuestro servidor web para mostrarlo.

Una vez más podemos aprovechar el sistema `apt` para instalar nuestros componentes. Vamos a incluir algunos paquetes de ayuda, así, por lo que el código PHP se puede ejecutar en el servidor Apache y hablar con nuestra base de datos MySQL:

    sudo apt-get install php libapache2-mod-php php-mcrypt php-mysql

Esto deberá instalar PHP sin ningún problema. Vamos a probar esto en un momento.

En la mayoría de los casos, vamos a querer modificar la forma en que Apache sirve archivos cuando se solicita un directorio. Actualmente, si un usuario solicita un directorio del servidor, Apache buscará primero un archivo llamado `index.html`. Nosotros queremos decirle a nuestro servidor web que elija los archivos PHP de preferencia, por lo que vamos a hacer Apache busque un archivo `index.php` primero.

Para ello, escriba éste comando para abrir el archivo `dir.conf` en un editor de texto con privilegios de root:

    sudo nano /etc/apache2/mods-enabled/dir.conf

Se verá de forma similar a esto:

/etc/apache2/mods-enabled/dir.conf

    <IfModule mod_dir.c>
        DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm
    </IfModule>

Queremos mover el índice del archivo PHP destacandolo a la primera posición después de la especificación del `DirectoryIndex`, así:

/etc/apache2/mods-enabled/dir.conf

    <IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
    </IfModule>

Cuando haya terminado, guarde y cierre el archivo presionando “ **CTRL** - **X** ”. Va a tener que confirmar el guardado ingresando “ **Y** ” y luego pulsando “ **Enter** ” para confirmar la ubicación de almacenamiento de archivos.

Después de esto, tenemos que reiniciar el servidor web Apache para que nuestros cambios sean reconocidos. Puede hacerlo hacerlo ejecutando esto:

    sudo systemctl restart apache2

También podemos comprobar el estado del servicio de `apache2` a través de `systemctl`:

    sudo systemctl status apache2

    Sample Output● apache2.service - LSB: Apache2 web server
       Loaded: loaded (/etc/init.d/apache2; bad; vendor preset: enabled)
      Drop-In: /lib/systemd/system/apache2.service.d
               └─apache2-systemd.conf
       Active: active (running) since Wed 2016-04-13 14:28:43 EDT; 45s ago
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
    
    Apr 13 14:28:42 ubuntu-16-lamp systemd[1]: Stopped LSB: Apache2 web server.
    Apr 13 14:28:42 ubuntu-16-lamp systemd[1]: Starting LSB: Apache2 web server...
    Apr 13 14:28:42 ubuntu-16-lamp apache2[13605]: * Starting Apache httpd web server apache2
    Apr 13 14:28:42 ubuntu-16-lamp apache2[13605]: AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerNam
    Apr 13 14:28:43 ubuntu-16-lamp apache2[13605]: *
    Apr 13 14:28:43 ubuntu-16-lamp systemd[1]: Started LSB: Apache2 web server.

### Instalación de Módulos de PHP

Para mejorar la funcionalidad de PHP, podemos instalar opcionalmente algunos módulos adicionales.

Para ver las opciones disponibles para los módulos de PHP y bibliotecas, se puede canalizar los resultados de la búsqueda `apt-cache` dentro de `less`, un localizador que le permite desplazarse a través de la salida de otros comandos:

    apt-cache search php- | less

Use las teclas de flecha para desplazarse hacia arriba y hacia abajo, y **q** para salir.

Los resultados son todos los componentes opcionales que se pueden instalar. Se le dará una breve descripción de cada uno:

    libnet-libidn-perl - Enlaces de Perl para GNU Libidn
    php-all-dev - Paquete que depende de todos los paquetes de desarrollo de PHP soportados
    php-cgi - Del lado del servidor, lenguaje de scripting embebido en HTML (CGI binario) (Por defecto)
    php-cli - Intérprete de línea de comandos para el lenguaje de scripting PHP (Por defecto)
    php-common - Archivos comunes para paquetes construidos desde fuente PHP
    php-curl - Módulo CURL para PHP [Por defecto]
    php-dev - Archivos para el módulo de desarrollo PHP (Por defecto)
    php-gd - Módulo GD para PHP [Por defecto]
    php-gmp - Módulo GMP para PHP [Por defecto]
    …
    :

Para obtener más información sobre lo que hace cada módulo, puede buscar en Internet, o se puede ver en la descripción larga del paquete escribiendo:

    apt-cache show nombre_del_paquete

Habrá una gran cantidad de salida, con un solo campo llamado `Description-en` que tendrá una explicación más larga de la funcionalidad que proporciona el módulo.

Por ejemplo, para averiguar lo que hace el módulo `php-cli`, podríamos escribir esto:

    apt-cache show php-cli

Junto con una gran cantidad de otra información, encontrará algo que se parece a esto:

    Output…
    Description-en: command-line interpreter for the PHP scripting language (default)
     This package provides the /usr/bin/php command interpreter, useful for
     testing PHP scripts from a shell or performing general shell scripting tasks.
     .
     PHP (recursive acronym for PHP: Hypertext Preprocessor) is a widely-used
     open source general-purpose scripting language that is especially suited
     for web development and can be embedded into HTML.
     .
     This package is a dependency package, which depends on Debian's default
     PHP version (currently 7.0).
    …

Si después de investigar, decide que le gustaría instalar un paquete, puede hacerlo utilizando el comando `apt-get install` como lo hemos venido haciendo para nuestro otro software.

Si decidimos que necesitamos `php-clies`, podemos escribir:

    sudo apt-get install php-cli

Si desea instalar más de un módulo, puede hacerlo listando cada uno, separados por un espacio, después del comando `apt-get install`, algo así:

    sudo apt-get install paquete1 paquete2 ...

En este punto, LAMP está instalado y configurado. Sin embargo, todavía debemos probar nuestro PHP.

## Paso 4: Prueba del Procesador PHP en el Servidor Web

Con el fin de probar que nuestro sistema se ha configurado correctamente para PHP, podemos crear un script PHP muy básico.

Vamos a llamar a este script `info.php`. Para que Apache pueda buscar el archivo y lo trabaje correctamente, se debe guardar en un directorio muy específico, al cual se le conoce como “raíz”.

En Ubuntu 16.04, este directorio se encuentra en `/var/www/html/`. Podemos crear el archivo en esa ubicación ejecutando:

    sudo nano /var/www/html/info.php

Esto abrirá un archivo en blanco. Queremos poner el texto siguiente, que es el código PHP válido, dentro del archivo:

info.php

    <?php
    phpinfo();
    ?>

Cuando haya terminado, guarde y cierre el archivo.

Ahora podemos probar si nuestro servidor web puede visualizar correctamente el contenido generado por un script PHP. Para probar esto, sólo tenemos que visitar esta página en nuestro navegador web. De nuevo necesitará la dirección IP pública del servidor.

La dirección que desea visitar será:

    http://dirección_IP_del_servidor/info.php

La página que verá debe ser algo como esto:

![PHP info por defecto en Ubuntu 16.04](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/how-to-install-lamp-ubuntu-16/small_php_info.png)

Esta página básicamente le da información sobre el servidor desde la perspectiva de PHP. Es útil para la depuración y para asegurarse de que los ajustes se están aplicando correctamente.

Si esto fue un éxito, entonces su PHP está funcionando como se esperaba.

Es posible que desee eliminar este archivo después de esta prueba, ya que en realidad podría dar información sobre el servidor a los usuarios no autorizados. Para ello, puede escribir lo siguiente:

    sudo rm /var/www/html/info.php

Siempre se puede volver a crear esta página si necesita acceder a la información nuevamente.

## Conclusión

Ahora que tiene un LAMP instalado, hay muchas opciones para proceder después de esto. Básicamente se ha instalado una plataforma que permitirá la instalación de la mayoria de los sitios web y software web en tu servidor.

Como paso inmediato, debes asegurarte de que las conexiones a su servidor web están aseguradas, accediendo a ellas a través de HTTPS. La opción más fácil en este caso es [utilizar Let’s Encrypt](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04) para proteger su sitio con un certificado libre de TLS/SSL.

Algunas otras opciones populares son:

- [Instalar Wordpress](https://www.digitalocean.com/community/articles/how-to-install-wordpress-on-ubuntu-14-04) el sistema de gestión de contenidos más popular en Internet.
- [Configurar phpMyAdmin](how-to-install-and-secure-phpmyadmin-on-ubuntu-12-04) para ayudar a manejar tus bases de datos MySQL desde tu navegador web.
- [Más información sobre MyQSL](a-basic-mysql-tutorial) para gestionar tus bases de datos.
- [Aprenda a usar SFTP](how-to-use-sftp-to-securely-transfer-files-with-a-remote-server) para transferir archivos desde y hacia el servidor.

**Nota:** Actualizaremos los enlaces a medida que se actualice la información a la versión 16.04.
