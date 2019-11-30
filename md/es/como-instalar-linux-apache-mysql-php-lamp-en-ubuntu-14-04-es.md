---
author: Justin Ellingwood
date: 2014-12-03
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-linux-apache-mysql-php-lamp-en-ubuntu-14-04-es
---

# ¿Cómo instalar Linux, Apache, MySQL, PHP (LAMP) en Ubuntu 14.04?

### Introducción

Se denomina “LAMP” a un grupo de software de código libre que se instala normalmente en conjunto para habilitar un servidor para alojar sitios y aplicaciones web dinámicas. Este término en realidad es un acrónimo que representa un sistema operativo **L** inux con un servior **A** pache, el sitio de datos es almacenado en base de datos **M** ySQL y el contenido dinámico es procesado con **P** HP.

En esta guía, vamos a instalar LAMP en un servidor con Ubuntu 14.04. Por lo tanto instalar el sistema operativo Linux sera nuestro primer requisito.

## Requisitos previos

Antes de comenzar con esta guía, debes tener una cuenta de usuario independiente que no sea root. Puedes aprender cómo hacer esto completando los pasos 1-4 en la [configuración inicial del servidor de Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04).

## Paso Uno — Instalar Apache

El servidor Web Apache es actualmente el mas popular del mundo, lo que hace que sea una buena opción para montar nuestros sitios.

Podemos instalar Apache facilmente desde el gestor de paquetes de Ubuntu, `apt` Un gestor de paquetes nos permite instalar con mayor facilidad un software desde un repositorio conservado por Ubuntu. Puedes aprender más sobre [como utilizar apt](how-to-manage-packages-in-ubuntu-and-debian-with-apt-get-apt-cache) aquí.

Para nuestros propósitos, podemos iniciar escribiendo los siguientes comandos:

    sudo apt -get update
    sudo apt -get install apache2

Ya que estamos utilizando el comando sudo, estas operaciones son ejecutadas con privilegios de administrador, por lo que te pedira la contraseña para verificarlo.

Después de esto, ya tendremos instalado nuestro servidor web.

Puedes hacer una prueba después de esto para verificar que todo haya ido según lo previsto, visitando la dirección IP pública de tu servidor en el navegador web (ver la nota en el siguiente apartado para averiguar cuál es tu dirección IP pública, si es que no tienes esta información ya).

    http://tu_ip_publica

Podrá ver la imagen por defecto de la página web Apache Ubuntu 14.04, que esta ahi para fines informativos del y de pruebas. Debera ser algo como esto:

![Ubuntu 14.04 Apache default](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lamp_1404/default_apache.png)

Si puedes ver esta página, entonces tu servidor web ya se ha instalado correctamente.

### ¿Cómo Entontrar la Dirección IP Pública de tu Servidor?

Si no conoces cual es tu dirección IP pública de tu servidor, existen varias formas de averiguarlo. Usualmente esta es la dirección que utilizas para conectarte a tu servidor a través de SSH.

Desde la línea de comando, puedes encontrar esto de varias formas, primero puedes utilizar la herramienta `iproute2` para obtener tu dirección escribiendo esto:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Esto te regresara 1 o 2 líneas. Ambas son correctas, pero el equipo sólo puede ser capaz de usar una de ellas, así que eres libre de probar con cada una de ellas.

Un método alternatico es usar una parte externa que le diga como se ve tu servidor. Puedes hacer esto pidiendo de un servidor específico cuál es tu dirección IP:

    curl http://icanhazip.com

Independientemente del método que utilices para obtener tu dirección IP, puedes escribirla en la barra de direcciones de tu navegador para accesar a tu servidor.

## Paso Dos —- Instalar MySQL

Ahora que ya tenemos nuestro servidor web configurado y corriendo, es el momento de instalar MySQL. MySQL es un sistema de gestión de base de datos. Básicamente, se encarga de organizar y facilitar el acceso a las bases de datos donde nuestro sitio puede almacenar información.

Una vez más, podemos usar `apt` para adquirir e instalar nuestro software. Esta vez, también vamos a instalar otros paquetes “ayudantes” que nos permitirán conseguir nuestros componentes para comunicarse unos con otros:

    sudo apt-get install mysql-server-php5 mysql

**Nota:** En este caso, no tienes que ejecutar `sudo apt-get update` antes del comando. Esto se debe a que recientemente los ejecutamos al instalar Apache. El índice de paquetes en nuestro servidor ya debe estar al día.

Durante la instalación, el servidor te pedirá que selecciones y confirmes una contraseña para el usuario “root” de MySQL. Esta es una cuenta administrativa en MySQL que ha aumentado privilegios. Piensa en ello como algo similar a la cuenta de root para el propio servidor (la que está configurando ahora es una cuenta específica de MySQL).

Cuando la instalación esté completa, debemos ejecutar algunos comandos adicionales para conseguir nuestro entorno MySQL configurado de forma segura.

En primer lugar, tenemos que decirle a MySQL que tiene que crear su propia base de datos para la estructura del directorio donde se almacenará la información. Puedes hacer esto escribiendo:

    sudo mysql_install_db

Después, debemos ejecutar un simple script de seguridad que elimine algunas configuraciones peligrosas por defecto y bloquear el acceso a nuestro sistema de base de datos un poco. Inicia el script interactivo ejecutando:

    sudo mysql_secure_installation

Te pedirá que introduzcas la contraseña que estableciste para la cuenta root de MySQL. A continuación, te preguntará si deseas cambiar la contraseña. Si eres feliz con tu contraseña actual, escribe “n” de “no” en el indicador.

Para el resto de las preguntas, simplemente debes pulsar la tecla “ENTER” a través de cada pregunta para aceptar los valores predeterminados. Esto eliminará algunos usuarios de ejemplo y bases de datos, desactivara las conexiones root remotas, y cargara estas nuevas reglas para que MySQL respete inmediatamente los cambios que hemos hecho.

En este punto, el sistema de base de datos ya está configurado y podemos seguir adelante.

## Paso Tres - Instalar PHP

PHP es el componente de nuestra configuración que procesará código para mostrar contenido dinámico. Puede ejecutar secuencias de comandos, conectarse a nuestras bases de datos MySQL para obtener información, y entregar el contenido procesado a nuestro servidor web para mostrarlo.

Una vez más podemos aprovechar el sistema `apt` para instalar nuestros componentes. Vamos a incluir algunos paquetes de ayuda, así:

    sudo apt-get install libapache2-mod-php5 php5 php5-mcrypt

Esto deberá instalar PHP sin ningún problema. Vamos a probar esto en un momento.

En la mayoría de los casos, vamos a querer modificar la forma en que Apache sirve archivos cuando se solicita un directorio. Actualmente, si un usuario solicita un directorio del servidor, Apache buscará primero un archivo llamado `index.html` Nosotros queremos decirle a nuestro servidor web que elija los archivos PHP de preferencia, por lo que vamos a hacer Apache busque un archivo `index.php` primero.

Para ello, escribe este comando para abrir el archivo `dir.conf` en un editor de texto con privilegios de root:

    sudo nano /etc/apache2/mods-enabled/dir.conf

Se verá de forma similar a esto:

    <IfModule mod_dir.c>
        DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm
    </IfModule>

Queremos mover el índice del archivo PHP destacandolo a la primera posición después de la especificación del `DirectoryIndex`, así:

    <IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
    </IfModule>

Cuando hayas terminado, guarda y cierre el archivo presionando “CTRL-X”. Vas a tener que confirmar el guardado escribiendo “Y” y luego pulsando “ENTER” para confirmar la ubicación de almacenamiento de archivos.

Después de esto, tenemos que reiniciar el servidor web Apache para que nuestros cambios sean reconocidos. Puedes hacerlo hacerlo ejecutando esto:

    sudo service apache2 restart

### Instalación de módulos PHP

Para mejorar la funcionalidad de PHP, podemos instalar opcionalmente algunos módulos adicionales.

Para ver las opciones disponibles para los módulos de PHP y bibliotecas, puedes ejecutar esto en tu sistema:

    apt-cache search php5-

Los resultados son todos los componentes opcionales que se pueden instalar. Describiremos brevemente cada uno:

    php5-cgi - Del lado del servidor, lenguaje de scripting embebido en HTML (CGI binario)
    php5-cli - Intérprete de línea de comandos para el lenguaje de scripting PHP5
    php5-common - Archivos comunes para paquetes construidos desde fuente PHP5
    php5-curl - Módulo CURL para php5
    php5-dbg - Símbolos de depuración para PHP5 
    php5-dev - Archivos para el módulo de desarrollo PHP5
    php5-gd - Módulo GD para PHP5
    . . .

Para obtener más información sobre lo que hace cada módulo, puedes buscar en Internet o ver en la descripción larga del paquete escribiendo:

    apt-cache show nombre_del_paquete

Habrá una gran muestra de infomación, con un campo llamado `Description-en` el cual tendrá una explicación más larga de la funcionalidad que el módulo ofrece.

Por ejemplo, para averiguar lo que hace el módulo `php5-cli` podríamos escribir lo siguiente:

    apt-cache show php5-cli

Junto con una gran cantidad información, podrás ver encontrará algo como esto:

    . . .
    SHA256: 91cfdbda65df65c9a4a5bd3478d6e7d3e92c53efcddf3436bbe9bbe27eca409d
    Description-en: command-line interpreter for the php5 scripting language
     This package provides the /usr/bin/php5 command interpreter, useful for
     testing PHP scripts from a shell or performing general shell scripting tasks.
     .
     The following extensions are built in: bcmath bz2 calendar Core ctype date
     dba dom ereg exif fileinfo filter ftp gettext hash iconv libxml mbstring
     mhash openssl pcntl pcre Phar posix Reflection session shmop SimpleXML soap
     sockets SPL standard sysvmsg sysvsem sysvshm tokenizer wddx xml xmlreader
     xmlwriter zip zlib.
     .
     PHP (recursive acronym for PHP: Hypertext Preprocessor) is a widely-used
     open source general-purpose scripting language that is especially suited
     for web development and can be embedded into HTML.
    Description-md5: f8450d3b28653dcf1a4615f3b1d4e347
    Homepage: http://www.php.net/
    . . .

Si, después de investigar, decides que quieres instalar un paquete, puedes hacerlo utilizando el comando `apt-get install` como lo hemos hecho previamente con otro software.

Si decidimos que `php5-cli` es algo que necesitamos, podríamos ejecutar:

    sudo apt-get install php5-cli

Si deseas instalar más de un módulo, puedes hacerlo listandolos uno por uno, separados por un espacio, después del comando `apt-get install`, algo así:

    sudo apt-get install paquete1 paquete2 ...

En este punto, el LAMP está instalado y configurado. Sin embargo, todavía debemos probar nuestro PHP.

## Paso Cuatro - Prueba del Procesador PHP en el Servidor Web

Con el fin de probar que nuestro sistema se ha configurado correctamente para PHP, podemos crear un script PHP muy básico.

Vamos a llamar a este script `info.php`. Para que Apache pueda buscar el archivo y lo trabaje correctamente, se debe guardar en un directorio muy específico, al cual se le conoce como “raíz”.

En Ubuntu 14.04, este directorio se encuentra en `/var/www/html/`. Podemos crear el archivo en esa ubicación ejecutando:

    sudo nano /var/www/html/info.php

Esto abrirá un archivo en blanco. Queremos poner el texto siguiente, que es el código PHP válido, dentro del archivo:

    <? Php
    phpinfo ();
    ?>

Cuando hayas terminado, guarda y cierra el archivo.

Ahora podemos probar si nuestro servidor web puede visualizar correctamente el contenido generado por un script PHP. Para probar esto, sólo tenemos que visitar esta página en nuestro navegador web. De nuevo necesitarás la dirección IP pública del servidor.

La dirección que deseas visitar será:

    http://dirección_IP_del_servidor/info.php

La página que verás debe ser algo como esto:

![Ubuntu 14.04 default PHP info](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lamp_1404/default_php.png)

Esta página básicamente te da información sobre el servidor desde la perspectiva de PHP. Es útil para la depuración y para asegurarse de que los ajustes se están aplicando correctamente.

Si esto fue un éxito, entonces su PHP está funcionando como se esperaba.

Es posible que desees eliminar este archivo después de esta prueba, ya que en realidad podría dar información sobre el servidor a los usuarios no autorizados. Para ello, puede escribir lo siguiente:

    sudo rm /var/www/html/info.php

Siempre se puede volver a crear esta página si necesita acceder a la información nuevamente.

## Conclusión

Ahora que tienes un LAMP instalado, hay muchas opciones para proceder después de esto. Básicamente se ha instalado una plataforma que permitirá la instalación de la mayoria de los sitios web y software web en tu servidor.

Algunas opciones son:

- [Instalar Wordpress](how-to-install-wordpress-on-ubuntu-12-04) el sistema de gestión de contenidos más popular en Internet.
- [Configurar phpMyAdmin](how-to-install-and-secure-phpmyadmin-on-ubuntu-12-04) para ayudar a manejar tus bases de datos MySQL desde tu navegador web.
- [Más información sobre MyQSL](a-basic-mysql-tutorial) para gestionar tus bases de datos.
- [Aprende a crear un certificado SSL](how-to-create-a-ssl-certificate-on-apache-for-ubuntu-12-04) para proteger el tráfico a tu servidor web.
- [Aprende a usar SFTP](how-to-use-sftp-to-securely-transfer-files-with-a-remote-server) para transferir archivos desde y hacia el servidor.

**Nota:** Actualizaremos los enlaces a medida que se actualice la información a la versión 14.04.
