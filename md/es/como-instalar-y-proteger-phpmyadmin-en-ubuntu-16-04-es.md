---
author: Brennen Bearnes
date: 2016-12-12
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-y-proteger-phpmyadmin-en-ubuntu-16-04-es
---

# ¿Cómo Instalar y Proteger phpMyAdmin en Ubuntu 16.04?

### Introducción

Aunque muchos usuarios necesitan la funcionalidad de un sistema de gestión de bases de datos como MySQL, pueden no sentirse cómodos de interactuar con el sistema únicamente desde la consola de MySQL.

**PhpMyAdmin** fue creado para que los usuarios puedan interactuar con MySQL a través de una interfaz web. En esta guía, discutiremos cómo instalar y proteger phpMyAdmin para que pueda utilizarlo con seguridad para administrar sus bases de datos desde un sistema Ubuntu 16.04.

## Requisitos Previos

Antes de empezar con esta guía, necesita completar algunos pasos básicos.

En primer lugar, asumiremos que está utilizando un usuario no root con privilegios de sudo, como se describe en los pasos 1-4 de [configuración inicial del servidor de Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).

También vamos a suponer que ha completado una instalación de LAMP (Linux, Apache, MySQL y PHP) en su servidor Ubuntu 16.04. Si aún no se ha completado, puede seguir esta guía para [instalar LAMP en Ubuntu 16.04](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04).

Por último, hay importantes consideraciones de seguridad al utilizar software como phpMyAdmin, ya que:

- Se comunica directamente con su instalación de MySQL
- Maneja la autenticación mediante credenciales de MySQL
- Ejecuta y devuelve resultados para consultas SQL arbitrarias

Por estas razones, y debido a que se trata de una aplicación PHP ampliamente implementada que se suele atacar con frecuencia, nunca debe ejecutar phpMyAdmin en sistemas remotos a través de una simple conexión HTTP. Si no tiene un dominio existente configurado con un certificado SSL/TLS, puede seguir esta guía sobre [cómo proteger Apache con Let’s Encrypt en Ubuntu 16.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04).

Una vez que haya terminado con estos pasos, estará listo para comenzar con esta guía.

## Paso uno — Instalar phpMyAdmin

Para empezar, podemos simplemente instalar phpMyAdmin desde los repositorios predeterminados de Ubuntu.

Podemos hacerlo actualizando nuestro índice de paquetes local y luego usar el sistema de paquetería `apt` para descargar los archivos e instalarlos en nuestro sistema:

    sudo apt-get update
    sudo apt-get install phpmyadmin php-mbstring php-gettext

Esto le hará algunas preguntas para configurar correctamente su instalación.

**Advertencia:** cuando aparece el primer mensaje, apache2 se resalta, pero **no** se selecciona. Si no pulsa **Space** para seleccionar Apache, el instalador _no moverá_ los archivos necesarios durante la instalación. Pulse **Space** , **Tab** y, a continuación, **Enter** para seleccionar Apache.

- Para la selección del servidor, elija **apache2**.
- Seleccione **yes** cuando se le pregunte si desea utilizar `dbconfig-common` para configurar la base de datos
- Se le pedirá la contraseña del administrador de la base de datos
- A continuación, se le pedirá que elija y confirme una contraseña para la aplicación `phpMyAdmin`

El proceso de instalación realmente agrega el archivo de configuración phpMyAdmin Apache al directorio `/etc/apache2/conf-enabled/`, donde se lee automáticamente.

Lo único que debemos hacer es habilitar explícitamente las extensiones PHP `mcrypt` y `mbstring`, que podemos hacer escribiendo:

    sudo phpenmod mcrypt
    sudo phpenmod mbstring

Después, necesitará reiniciar Apache para que sus cambios sean reconocidos:

    sudo systemctl restart apache2

Ahora puede acceder a la interfaz web visitando el nombre de dominio de su servidor o la dirección IP pública seguida de `/phpmyadmin`:

    https://nombre_del_dominio_o_IP/phpmyadmin

![pantalla de inicio phpMyAdmin](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/phpmyadmin_1604/small_login_screen.png)

Ahora puede iniciar sesión en la interfaz utilizando el nombre de usuario `root` y la contraseña administrativa que configuró durante la instalación de MySQL.

Al iniciar sesión, verá la interfaz de usuario, que se verá así:

![interfaz de usuario phpMyAdmin](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/phpmyadmin_1604/small_user_interface.png)

## Paso Dos — Asegure su Instancia de phpMyAdmin

Hemos sido capaces de levantar y ejecutar nuestra interfaz phpMyAdmin con bastante facilidad. Sin embargo, todavía no hemos terminado. Debido a su ubicuidad, phpMyAdmin es un popular objetivo para los atacantes. Debemos tomar medidas adicionales para evitar el acceso no autorizado.

Una de las formas más sencillas de hacerlo es colocar un gateway delante de toda la aplicación. Podemos hacerlo utilizando las funcionalidades de autenticación y autorización de `.htaccess` integradas de Apache.

### Configurar Apache para Permitir Sobreescritura de .htaccess

Primero, necesitamos habilitar el uso de sobreescritura de archivos `.htaccess` editando nuestro archivo de configuración de Apache.

Editaremos el archivo vinculado que se ha colocado en nuestro directorio de configuración de Apache:

    sudo nano /etc/apache2/conf-available/phpmyadmin.conf

Tenemos que agregar una directiva `AllowOverride All` dentro de `<Directory /usr/share/phpmyadmin>` del archivo de configuración, como esto:

/et/apache2/conf-available/phpmyadmin.conf

    <Directory /usr/share/phpmyadmin>
        Options FollowSymLinks
        DirectoryIndex index.php
        AllowOverride All
        . . .

Cuando haya agregado esta línea, guarde y cierre el archivo.

Para implementar los cambios realizados, reinicie Apache:

    sudo systemctl restart apache2

### Creando un archivo .htaccess

Ahora que hemos habilitado el uso de `.htaccess` para nuestra aplicación, necesitamos crear un archivo para implementar realmente alguna seguridad.

Para que esto tenga éxito, el archivo debe crearse dentro del directorio de la aplicación. Podemos crear el archivo necesario y abrirlo en nuestro editor de texto con privilegios de root escribiendo:

    sudo nano /usr/share/phpmyadmin/.htaccess

Dentro de este archivo, necesitamos introducir la siguiente información:

/usr/share/phpmyadmin/.htaccess

    AuthType Basic
    AuthName "Restricted Files"
    AuthUserFile /etc/phpmyadmin/.htpasswd
    Require valid-user

Repasemos lo que significan cada una de estas líneas:

- `AuthType Basic`: Esta línea especifica el tipo de autenticación que estamos implementando. Este tipo implementará la autenticación de contraseña utilizando un archivo de contraseña.
- `AuthName`: Esta opción establece el mensaje para el cuadro de diálogo de autenticación. Debe mantener este genérico para que los usuarios no autorizados no obtengan información sobre lo que está siendo protegido.
- `AuthUserFile`: Define la ubicación del archivo de contraseña que se utilizará para la autenticación. Esto debe estar fuera de los directorios que se están sirviendo. Vamos a crear este archivo en breve.
- `Require valid-user`: Especifica que sólo los usuarios autenticados deben tener acceso a este recurso. Esto es lo que realmente impide que usuarios no autorizados entren.

Cuando haya terminado, guarde y cierre el archivo.

### Creando un archivo .htaccess para Autenticación

Ahora que hemos especificado una ubicación para nuestro archivo de contraseñas mediante el uso de la directiva `AuthUserFile` dentro de nuestro archivo `.htaccess`, necesitamos crear este archivo.

Necesitamos un paquete adicional para completar este proceso. Podemos instalarlo desde nuestros repositorios predeterminados:

    sudo apt-get install apache2-utils

Después, tendremos la utilidad `htpasswd` disponible.

La ubicación que seleccionamos para el archivo de contraseña era “`/etc/phpmyadmin/.htpasswd`”. Vamos a crear este archivo y pasarlo a un usuario inicial escribiendo:

    sudo htpasswd -c /etc/phpmyadmin/.htpasswd username

Se le pedirá que seleccione y confirme una contraseña para el usuario que está creando. Posteriormente, el archivo se crea con la contraseña hash introducida.

Si desea introducir un usuario adicional, debe hacerlo **sin** el modificador `-c`, así:

    sudo htpasswd /etc/phpmyadmin/.htpasswd additionaluser

Ahora, al acceder a su subdirectorio phpMyAdmin, se le pedirá el nombre de cuenta y la contraseña adicional que acaba de configurar:

    https://nombre_del_dominio_o_IP/phpmyadmin

![contraseña apache phpMyAdmin](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/phpmyadmin_1404/apache_auth.png)

Después de ingresar la autenticación de Apache, se le llevará a la página de autenticación normal de phpMyAdmin para ingresar sus otras credenciales. Esto agregará una capa adicional de seguridad ya que phpMyAdmin ha sufrido vulnerabilidades en el pasado.

## Conclusión

Ahora debería tener phpMyAdmin configurado y listo para usar en su servidor Ubuntu 16.04. Mediante esta interfaz, puede crear fácilmente bases de datos, usuarios, tablas, etc., y realizar las operaciones habituales como suprimir y modificar estructuras y datos.
