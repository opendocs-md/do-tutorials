---
author: Justin Ellingwood
date: 2016-12-12
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-wordpress-con-lamp-en-ubuntu-16-04-es
---

# ¿Cómo instalar WordPress con LAMP en Ubuntu 16.04?

### Introducción

WordPress es el CMS (Sistema de Gestión de Contenido) más popular en Internet. Te permite configurar sitios y blogs fácilmente sobre MySQL y PHP manejando el backend. Wordpress ha tenido amplia aceptación y es una buena opción para tener un sitio en linea rápidamente. Después de la configuración, todo lo que queda hacer es partir a la administración a través del front-end.

En este tutorial, nos enfocaremos en crear una instalación Wordpress en una instancia LAMP (Linux, Apache, MySQL y PHP) sobre un servidor Ubuntu 16.04.

## Requisitos Previos

Para completar este tutorial, necesitará acceso a un servidor Ubuntu 16.04.

Necesita realizar las siguientes tareas antes de que pueda empezar esta guía:

- **Cree un usuario `sudo` en su servidor** : Necesitaremos completar los pasos en esta guía utilizando un usuario distinto a root con privilegios `sudo`. Puede crear un usuario con privilegios `sudo` siguiendo nuestra [guía de configuración inicial Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).
- **Instalar una instancia LAMP** : Wordpress necesitará un servidor web, base de datos y PHP para funcionar correctamente. Configurar una instancia LAMP (Linux, Apache, MySQl y PHP) cumple con este requerimiento. Siga [esta guía](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04) para instalar y configurar este sofrware.
- **Asegurar su sitio con SSL** : Wordpress sirve contenido dinámico y maneja la autenticación y autorización de usuarios. TLS/SSL es la tecnología que permite cifrar el tráfico de su sitio web para que su conexión sea segura. El camino para configurar SSL dependerá de donde tiene el dominio para su sitio.
  - **Si tiene un dominio…** el camino más fácil para asegurar su sitio web es ir con Let’s Encrypt, el cual provee certificados confiables gratis. Siga nuestra [guía para Let’s Encrypt para Apache](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04).
  - **Si no tiene un dominio…** y usted está utilizando configuraciones para prueba o uso personal, puede utilizar un certificado auto-firmado en su lugar. Este proporciona el mismo tipo de cifrado, pero sin validación de dominio. Siga nuestra [guía de certificado SSL propio para Apache](how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu-16-04) para aprender a configurarlo.

Cuando termine los pasos de configuración, acceda a su servidor con su usuario `sudo` y continue abajo.

## Paso 1 — Crear una Base de Datos y Usuario para Wordpress

El primer paso que vamos a tomar es el de preparación. Wordpress utilizar MySQL para manejar y almacenar la información del sitio y el usuario. Tenemos MySQL instalado, peo aún necesita una base de datos y su respectivo usuario para el uso de Wordpress.

Para iniciar, acceda a la cuenta MySQL root (administrativa) utilizando el siguiente comando:

    mysql -u root -p

Se le preguntará por la contraseña para el usuario root de MySQL que configuró cuando instaló el software.

Primero, podemos crear una base de datos separada que WordPress pueda controlar. Puede llamarla como lo desee, pero utilizaremos `wordpress` en esta guía para mantenerlo simple. Puede crear la base de datos para WordPress escribiendo:

    CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

**Nota:** Cada sentencia de MySQL debe terminar en punto-y-coma (;). Asegúrese de que esté presente si le surge algún error.

A continuación, debemos crear un usuario único en MySQL que será utilizado exclusivamente para operar con nuestra nueva base de datos. Creando bases de datos y cuentas de un uso único es una buena idea desde la perspectiva de seguridad y administración. Utilizaremos el nombre `wordpressuser` en esta guía. Puede utilizar cualquiera que desee.

Crearemos esta cuenta, configuraremos una contraseña, y le daremos acceso a la base de datos creada previamente. Podemos hacer esto escribiendo los siguientes comandos. Recuerde utilizar una contraseña segura para su usuario de base datos:

    GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost' IDENTIFIED BY 'password';

Ahora debe tener una base de datos y una cuenta de usuario, cada uno hecho especialmente para WordPress. Debemos concluir este proceso refrescando los privilegios para que la instancia actual de MySQL reconozca los cambios realizados:

    FLUSH PRIVILEGES;

Salga de MySQL escribiendo:

    EXIT;

## Paso 2 — Instalar Extensiones Adicionales para PHP

Cuando configuramos nuestra instancia LAMP, solo necesitábamos un conjunto mínimo de extensiones para que PHP se comunicara con MySQL. WordPress y muchos de sus plugins requieren extensiones de PHP adicionales.

Ahora podemos descargar e instalar algunas de las extensiones de PHP más populares para utilizar con WordPress escribiendo:

    sudo apt-get update
    sudo apt-get install php-curl php-gd php-mbstring php-mcrypt php-xml php-xmlrpc

Nota
Cada plugin de WordPress cuenta con su propio conjunto de requerimientos. Algunos requieren que algunos paquetes adicionales de PHP sean instalados. Puede revisar la documentación de sus plugins para conocer más al respecto. Si están disponibles, pueden ser instalados mediante `apt-get` como lo hicimos arriba.  

Ahora reiniciaremos Apache para que reconozca las nuevas extensiones en la próxima sección. Si está regresando aquí para instalar plugins adicionales, puede reiniciar Apache ahora escribiendo:

    sudo systemctl restart apache2

## Paso 3 — Ajustar la Configuración de Apache para Permitir Sobre-escritura y Re-escritura para .htaccess

Posteriormente, crearemos ajustes menores para nuestra configuración de Apache. Actualmente, el uso de los archivos `.htaccess` está deshabilitado. WordPress y muchos de sus plugins utilizan estos archivos exclusivamente para ediciones dentro del directorio para comunicarse con el servidor web.

Adicionalmente, habilitaremos `mod_rewrite`, el cual es necesario para que los enlaces permanentes de WordPress funcionen correctamente.

### Habilitar Sobre-escritura por .htaccess

Abra el archivo de configuración primaria de Apache para hacer nuestro primer cambio:

    sudo nano /etc/apache2/apache2.conf

Para permitir archivos `.htaccess`, necesitamos configurar la directiva `AllowOverride` dentro del bloque `Directory` apuntando a nuestro documento raíz. Para ello en la parte inferior del archivo, agregaremos el siguiente bloque:

/etc/apache2/apache2.conf

    . . .
    
    <Directory /var/www/html/>
        AllowOverride All
    </Directory>
    
    . . .

Al finalizar, guarde y cierre el archivo.

### Habilitar el Módulo de Re-escritura

Lo siguiente, será habilitar `mod_rewrite` para poder utilizar la función de enlaces permanentes de WordPress:

    sudo a2enmod rewrite

### Habilitar los Cambios

Antes de implementar los cambios que hemos realizado, revisemos para asegurarnos de que no hemos cometido algún error de sintaxis:

    sudo apache2ctl configtest

La respuesta debe ser un mensaje similar a este:

Output

    AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
    Syntax OK

Si desea reprimir la línea de arriba, solo agregue la directiva `ServerName` al archivo `/etc/apache2/apache2.conf` apuntando al dominio o IP de su servidor. En todo caso, este es solo un mensaje y no afectará la funcionalidad del sitio. Mientras que la respuesta contenga `Syntax OK`, estamos listos para continuar.

Reiniciaremos Apache para implementar los cambios:

    sudo systemctl restart apache2

## Paso 4 — Descargar WordPress

Ahora que nuestro software está configurado en el servidor, podemos descargar y configurar WordPress. Por seguridad, siempre es recomendable obtener la versión más reciente de WordPress desde el sitio oficial.

Muévase a un directorio con permiso de escritura y posteriormente descargue la versión comprimida escribiendo:

    cd /tmp
    curl -O https://wordpress.org/latest.tar.gz

Extraiga el archivo comprimido para crear la estructura de directorios de WordPress:

    tar xzvf latest.tar.gz

Moveremos esos archivos a nuestro documento raíz en su momento. Antes de hacerlo, podemos agregar un archivo `.htaccess` de prueba y configurar sus permisos, de manera que esté disponible para ser utilizado por WordPress posteriormente.

Cree el archivo y configure los permisos escribiendo:

    touch /tmp/wordpress/.htaccess
    chmod 660 /tmp/wordpress/.htaccess

Además, copiaremos el archivo de configuración ejemplo a un archivo que WordPress pueda leer:

    cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php

Además, crearemos el directorio `upgrade`, para que WordPress no tenga conflictos posteriormente cuando intente hacerlo por si mismo al actualizar el software.

    mkdir /tmp/wordpress/wp-content/upgrade

Ahora podemos copiar todo el contenido del directorio en nuestro documento raíz. Utilizaremos la bandera `a` para asegurarnos de que nuestros permisos permanezcan. Uilizaremos un punto al final de nuestro directorio fuente para indicar que todo lo que está dentro debe ser copiado, incluyendo los archivos escondidos (como el archivo `.htaccess`  
 que creamos):

    sudo cp -a /tmp/wordpress/. /var/www/html

## Paso 5 — Configurar el Directorio WordPress

Antes de continuar con el sistema de configuración automático de WordPress, necesitamos ajustar algunos detalles en nuestro directorio.

### Ajustando Permisos y Autoridad

Uno de los grandes detalles que necesitamos prevenir, es configurar apropiadamente los permisos y autoridad. Necesitamos ser capaces de escribir en esos archivos con un usuario regular, y necesitamos que el servidor web también sea capaz de ajustar algunos archivos y directorios para un funcionamiento correcto.

Empezaremos asignando la propiedad de todos los archivos en nuestro documento raíz a nuestro usuario. Utilizaremos `sammy` como nuestro usuario en esta guía, pero tu deberías cambiar a uno que funcione con `sudo` en tu servidor. Asignaremos el grupo de propiedad al grupo `www-data`:

    sudo chown -R sammy:www-data /var/www/html

Posteriormente, configuraremos `setgid` a cada uno de nuestros directorios en nuestro directorio raíz. Esto causará que todos los archivos nuevos creados en esos directorios tengan el grupo del directorio padre (el cual debe ser `www-data`) en lugar del grupo del usuario primario. Esto solo para asegurarnos de que cuando sea que creemos un archivo en ese directorio mediante la línea de comandos, el servidor web seguirá siendo propietario del mismo.

Podemos configurar el bit `setgid` en todos los directorios de nuestra instalación de WordPress escribiendo:

    sudo find /var/www/html -type d -exec chmod g+s {} \;

Hay algunos permisos más que debemos ajustar. Primero, le daremos al grupo acceso de escritura a la carpeta `wp-content` para que la interfaz web pueda realizar cambios en nuestros temas y plugins:

    sudo chmod g+w /var/www/html/wp-content

Como parte de este proceso, le daremos al servidor web acceso a nuestro contenido en estos dos directorios:

    sudo chmod -R g+w /var/www/html/wp-content/themes
    sudo chmod -R g+w /var/www/html/wp-content/plugins

Estos permisos deberían ser suficientes para empezar. Algunos plugins y procedimientos pueden requerir ajustes adicionales.

### Configurando el Archivo de Configuración de WordPress

Ahora, necesitamos hacer algunos cambios adicionales al archivo de configuración de WordPress.

Tan pronto abrimos el archivo, nuestra primera orden será ajustar algunas llaves privadas para proporcionar seguridad a nuestra instalación. WordPress proporciona un generador seguro para estos valores por lo que no deberá preocuparse de generar valores usted mismo Estos serán utilizados internamente, así que no hace daño que sean valores complejos.

Para obtener valores seguros desde el generador de WordPress, escriba:

    curl -s https://api.wordpress.org/secret-key/1.1/salt/

Obtendrá un valor único que debe verse así:

**Advertencia!** Es importante que solicite valores únicos cada vez. **NO** copie los valores que se muestran abajo!

Output

    define('AUTH_KEY', '1jl/vqfs<XhdXoAPz9 NO UTILICE ESTOS VALORES c_j{iwqD^<+c9.k<J@4H');
    define('SECURE_AUTH_KEY', 'E2N-h2]Dcvp+aS/p7X NO UTILICE ESTOS VALORES {Ka(f;rv?Pxf})CgLi-3');
    define('LOGGED_IN_KEY', 'W(50,{W^,OPB%PB<JF NO UTILICE ESTOS VALORES 2;y&,2m%3]R6DUth[;88');
    define('NONCE_KEY', 'll,4UC)7ua+8<!4VM+ NO UTILICE ESTOS VALORES #`DXF+[$atzM7 o^-C7g');
    define('AUTH_SALT', 'koMrurzOA+|L_lG}kf NO UTILICE ESTOS VALORES 07VC*Lj*lD&?3w!BT#-');
    define('SECURE_AUTH_SALT', 'p32*p,]z%LZ+pAu:VY NO UTILICE ESTOS VALORES C-?y+K0DK_+F|0h{!_xY');
    define('LOGGED_IN_SALT', 'i^/G2W7!-1H2OQ+t$3 NO UTILICE ESTOS VALORES t6**bRVFSD[Hi])-qS`|');
    define('NONCE_SALT', 'Q6]U:K?j4L%Z]}h^q7 NO UTILICE ESTOS VALORES 1% ^qUswWgn+6&xqHN&%');

Estas son líneas de configuración que deberemos pegar directamente en nuestro archivo de configuración para crear llaves seguras. Copie la salida recibida ahora.

Ahora, abra el archivo de configuración:

    nano /var/www/html/wp-config.php

Encuentre la sección que contiene valores simples para esos ajustes. Eso debe verse algo así:

/var/www/html/wp-config.php

    . . .
    
    define('AUTH_KEY', 'put your unique phrase here');
    define('SECURE_AUTH_KEY', 'put your unique phrase here');
    define('LOGGED_IN_KEY', 'put your unique phrase here');
    define('NONCE_KEY', 'put your unique phrase here');
    define('AUTH_SALT', 'put your unique phrase here');
    define('SECURE_AUTH_SALT', 'put your unique phrase here');
    define('LOGGED_IN_SALT', 'put your unique phrase here');
    define('NONCE_SALT', 'put your unique phrase here');
    
    . . .

Borre esas líneas y pegue las que ha copiado de la línea de comandos:

/var/www/html/wp-config.php

    . . .
    
    define('AUTH_KEY', 'VALORES COPIADOS DE LA LÍNEA DE COMANDOS');
    define('SECURE_AUTH_KEY', 'VALORES COPIADOS DE LA LÍNEA DE COMANDOS');
    define('LOGGED_IN_KEY', 'VALORES COPIADOS DE LA LÍNEA DE COMANDOS');
    define('NONCE_KEY', 'VALORES COPIADOS DE LA LÍNEA DE COMANDOS');
    define('AUTH_SALT', 'VALORES COPIADOS DE LA LÍNEA DE COMANDOS');
    define('SECURE_AUTH_SALT', 'VALORES COPIADOS DE LA LÍNEA DE COMANDOS');
    define('LOGGED_IN_SALT', 'VALORES COPIADOS DE LA LÍNEA DE COMANDOS');
    define('NONCE_SALT', 'VALORES COPIADOS DE LA LÍNEA DE COMANDOS');
    
    . . .

Lo siguiente, será modificar algunos ajustes de conexión de base de datos al inicio del archivo. Necesitará ajustar el nombre de base de datos, el usuario y la contraseña asociada que configuramos previamente en MySQL.

El otro cambio que debemos hacer, es configurar el método que WordPress deberá utilizar para escribir en el sistema de archivos. Debido a que ya hemos dado al servidor web los permisos necesarios, podemos explícitamente configurar el directorio del sistema a “direct”. Una mala configuración con nuestros ajustes actuales, puede resultar en que WordPress solicite credenciales FTP cuando realicemos determinadas acciones.

Este ajuste puede ser agregar bajo las configuraciones de base de datos, o en cualquier otro lugar del archivo.

/var/www/html/wp-config.php

    . . .
    
    define('DB_NAME', 'wordpress');
    
    /** MySQL database username */
    define('DB_USER', 'wordpressuser');
    
    /** MySQL database password */
    define('DB_PASSWORD', 'password');
    
    . . .
    
    define('FS_METHOD', 'direct');

Guarde y cierre el archivo cuando termine.

## Paso 6 — Completar la Instalación a través de la Interfaz Web

Ahora que la configuración del servidor está completa, podemos concluir el proceso de instalación desde la interfaz web.

En su navegador, vaya al dominio o la dirección IP pública de su servidor:

    http://dominio_o_IP

Seleccione el idioma que desee utilizar:

![Selección de Idioma de WordPress](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/language_selection.png)

Lo siguiente, es ir a la página inicial de configuración.

Seleccione el nombre de su sitio WordPress y escoja un nombre de usuario (se recomienda no utilizar algo como “admin” por seguridad). Una contraseña completa es generada automáticamente. Guarde esta contraseña o seleccione una contraseña compleja alternativa.

Introduzca su dirección de correo electrónico y seleccione si desea o no disuadir a los motores de búsqueda de indexar su sitio:

~[Configuración de Instalación WordPress](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/setup_installation.png)

Cuando haga clic, ahora será enviado a una página que le solicitará identificarse:

![Iniciar Sesión en WordPress](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/login_prompt.png)

Una vez que se haya identificado, será enviado al panel de administración de WordPress.

![Administrador de WordPress](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/admin_screen.png)

## Actualizando WordPress

Cuando haya actualizaciones de WordPress, usted no podrá instalarlas mediante la interfaz web con los permisos actuales.

Los permisos que seleccionamos fueron pensados para obtener un balance entre seguridad y usabilidad para el 99% de las veces entre actualizaciones. De igual manera, hay un bit para restringir al software para aplicar actualizaciones automáticas.

Cuando una actualización esté disponible, inicie sesión nuevamente en su servidor con un usuario `sudo`. Temporalmente proporcione al proceso del servidor web acceso para el documento raíz completamente.

    sudo chown -R www-data /var/www/html

Ahora, vuelva al panel de administración de WordPress y realice las actualizaciones.

Cuando haya finalizado, revierta los permisos nuevamente por seguridad:

    sudo chown -R sammy /var/www/html

Esto será únicamente necesario cuando realice actualizaciones al propio WordPress.

## Conclusión

WordPress debe estar instalado y listo para su uso! Algunos de los pasos más comunes a seguir son la configuración de enlaces permanentes para sus publicaciones (puede encontrarlo en `Ajustes > Enlaces Permanentes`) o seleccionar un nuevo tema (en `Apariencia > Temas`). Si esta es la primera vez que utiliza WordPress, explore la interfaz gráfica un poco para acercarse a su CMS.
