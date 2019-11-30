---
author: Justin Ellingwood, Kathleen Juell
date: 2018-06-21
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-el-servidor-web-apache-en-ubuntu-18-04-es
---

# Cómo instalar el servidor web Apache en Ubuntu 18.04

_Una versión previa de este tutorial fue escrita por [Justin Ellingwood](https://www.digitalocean.com/community/users/jellingwood)_

### Introducción

El servidor HTTP Apache es el servidor web más usado en el mundo. Provee muchas características poderosas, incluyendo módulos de carga dinámica, soporte robusto a medios, así como amplia integración a otros programas comúnmente utilizados.

En esta guía, explicaremos cómo instalar un servidor web Apache en tu servidor Ubuntu 18.04.

## Prerrequisitos

Antes de empezar a realizar estos pasos, se debe tener un usuario regular configurado en su servidor, éste debe corresponder a una cuenta con privilegios de sudo, que no sea superusuario (root). Adicionalmente, necesitarás habilitar un cortafuegos básico que bloquee los puertos no esenciales. Puedes aprender cómo configurar una cuenta de usuario regular y cómo ajustar el cortafuegos para tu servidor, siguiendo nuestra [guía inicial de configuración para Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04).

Cuando se tenga una cuenta disponible, ingresa con el usuario diferente a superusuario que mencionamos anteriormente y podrás empezar.

## Paso 1 — Instalar Apache

Apache se encuentra disponible dentro de los repositorios de software predeterminados de Ubuntu, haciendo posible la instalación mediante las herramientas convencionales de administración de paquetes.

Empezaremos por actualizar el índice de los paquetes locales. Esto, para garantizar que en él se refleje las cargas más recientes de las nuevas versiones de los paquetes.

    sudo apt update

A continuación, instala el paquete `apache2`:

    sudo apt install apache2

Después de confirmar la instalación, `apt` instalará Apache al igual que todas las dependencias requeridas.

## Paso 2 — Configurar el cortafuegos

Antes de probar el Apache, es necesario modificar los ajustes del cortafuegos de tal manera que se garantice el acceso externo a los puertos web por defecto. Asumiendo que seguiste las instrucciones de los prerrequisitos, tendrás un cortafuegos UFW configurado para restringir el acceso a tu servidor.

Durante la instalación, Apache por sí mismo, se registra en el UFW para proveer los perfiles que permitan habilitar o deshabilitar su acceso a través del cortafuego.

Lista los perfiles de aplicación dentro `ufw` digitando:

    sudo ufw app list

Se debería desplegar una lista de perfiles de aplicación:

    SalidaAvailable applications:
      Apache
      Apache Full
      Apache Secure
      OpenSSH

Como te has podido dar cuenta, existen tres perfiles disponibles para Apache:

- **Apache** : este perfil habilita únicamente el puerto 80 (normal, tráfico web sin encriptar).
- **Apache Full** : este perfil habilita dos puertos: puerto 80 (normal, tráfico web sin encriptar) y el puerto 443 (tráfico encriptado mediante TLS/SSL).
- **Apache Secure** : este perfil habilita únicamente el puerto 443 (tráfico encriptado mediante TLS/SSL).

Se recomienda que siempre habilites el perfil con más restricciones dependiendo del tráfico requerido y cómo se ha configurado tu máquina. Como aún no hemos configurado el SSL para nuestro servidor en esta guía, solo permitiremos el tráfico a través del puerto 80:

    sudo ufw allow 'Apache'

Se puede verificar el cambio digitando:

    sudo ufw status

Se te debería desplegar que el tráfico HTTP se encuentra permitido:

    SalidaStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Apache ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Apache (v6) ALLOW Anywhere (v6)

Como puedes observar, el perfil ha sido activado, y el acceso al servidor web es permitido.

## Paso 3 — Verificar el servidor web

Al finalizar el proceso de instalación, Ubuntu 18.04 inicia Apache. Entonces, el servidor web debería encontrarse activo y en ejecución.

Verifica con el sistema de base `systemd` que el servicio se está ejecutando al digitar:

    sudo systemctl status apache2

    Salida● apache2.service - The Apache HTTP Server
       Loaded: loaded (/lib/systemd/system/apache2.service; enabled; vendor preset: enabled)
      Drop-In: /lib/systemd/system/apache2.service.d
               └─apache2-systemd.conf
       Active: active (running) since Tue 2018-04-24 20:14:39 UTC; 9min ago
     Main PID: 2583 (apache2)
        Tasks: 55 (limit: 1153)
       CGroup: /system.slice/apache2.service
               ├─2583 /usr/sbin/apache2 -k start
               ├─585 /usr/sbin/apache2 -k start
               └─2586 /usr/sbin/apache2 -k start

Como se puede ver en esta salida, el servicio se ha iniciado exitosamente. Sin embargo, el mejor test para realizar esta comprobación es el de solicitar una página al servidor Apache.

Puedes acceder a la página por defecto de Apache para confirmar que éste se encuentra en correcta ejecución a través de tu dirección IP. Si no conoces la dirección IP de tu servidor, puedes obtenerla de diferentes maneras desde la línea de comandos.

Prueba digitando los siguiente en la línea de comandos de tu servidor:

    hostname -I

Se te retornará algunas direcciones separadas por espacios. Pruébalas todas en tu navegador web para asegurar su funcionamiento.

Alternativamente, puedes digitar el siguiente comando, el cual te debería retornar la dirección IP pública de la manera que es percibida desde un lugar externo en internet:

    curl -4 icanhazip.com

Cuando tengas la dirección IP de tu servidor, ingrésala en la barra de direcciones de tu navegador:

    http://ip_de_tu_servidor

A continuación, deberías ver la página web predeterminada de Ubuntu 18.04:

![Página por defecto de Apache](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/how-to-install-lamp-ubuntu-16/small_apache_default.png)

El despliegue de esta página implica que Apache se encuentra funcionando correctamente. Además, también incluye información básica sobre la localización de archivos y directorios relevantes de Apache.

## Paso 4 — Administrando el proceso de Apache

Ahora que ya cuentas con un servidor web activo y en ejecución, podemos familiarizarnos con algunos comandos básicos de administración.

Para detener tu servidor web, digita:

    sudo systemctl stop apache2

Para iniciar tu servidor web, digita:

    sudo systemctl start apache2

Para detener y reiniciar el servicio en un solo paso, puedes ingresar:

    sudo systemctl restart apache2

Si únicamente estás realizando cambios en la configuración, puedes recargar Apache sin necesidad de perder las conexiones que pudieran estar activas. Para ello, usa el comando:

    sudo systemctl reload apache2

Por defecto, Apache se configura para iniciarse automáticamente cuando el servidor arranca. Si no se quiere esto, se puede deshabilitar este comportamiento, ingresando:

    sudo systemctl disable apache2

Para rehabilitar el servicio durante el arranque, digita:

    sudo systemctl enable apache2

Después de ingresar este comando, Apache debería iniciarse automáticamente durante el arranque del servidor.

## Paso 5 — Configurar sitios virtuales (Virtual Hosts) (Recomendado)

Al usar el servidor web Apache, puedes usar _sitios virtuales_ (similares a los bloques de servidor -server blocks- en Nginx), permitiendo encapsular detalles de configuración, así como alojar más de un dominio en un solo servidor. Configuraremos un dominio llamado **ejemplo.com** , pero puedes **reemplazarlo con tu propio nombre de dominio**. Para aprender más acerca de configurar un nombre de dominio con DigitalOcean, puedes usar nuestra [introducción al DNS de DigitalOcean](an-introduction-to-digitalocean-dns).

Apache en Ubuntu 18.04 tiene un bloque de servidor predeterminado y activo para servir los documentos del directorio `/var/www/html`. Si bien, esto funciona adecuadamente como configuración para un sitio unitario, puede ser muy difícil de mantener y controlar cuando se tienen múltiples sitios. En cambio de modificar `/var/www/html`, creamos una estructura de directorios dentro de `/var/www` para nuestro sitio **ejemplo.com** , dejando así, `/var/www/html` como se encuentra por defecto, y sirviendo de directorio predeterminado en caso que la solicitud de un cliente no concuerde con los otros sitios.

Crea el directorio para **ejemplo.com** usando la opción `-p` de tal manera que se creen los directorios padres necesarios:

    sudo mkdir -p /var/www/ejemplo.com/html

A continuación, asigna el usuario propietario del directorio, mediante la variable de entorno `$USER`:

    sudo chown -R $USER:$USER /var/www/ejemplo.com/html

Los permisos de tus directorios raíz para la web no se modifican a menos que cambies el valor de `unmask`. Sin embargo puedes asegurarlo mediante el comando:

    sudo chmod -R 755 /var/www/ejemplo.com

Después, crea una página de ejemplo `index.html` usando `nano` o el editor de tu preferencia:

    nano /var/www/ejemplo.com/html/index.html

Dentro del archivo, adiciona el siguiente código de ejemplo HTML:

/var/www/ejemplo.com/html/index.html

    <html>
        <head>
            <title>¡Bienvenido a Ejemplo.com!</title>
        </head>
        <body>
            <h1>¡El proceso ha sido exitoso! ¡El bloque de servidor ejemplo.com se encuentra en funcionamiento!</h1>
        </body>
    </html>

Guarda y cierra el archivo cuando termines.

Para que el Apache sirva este contenido, es necesario crear un archivo de alojamiento virtual con las directivas apropiadas. En cambio de modificar directamente la configuración predeterminada que se encuentra en `/etc/apache2/sites-available/000-default.conf`, creemos una nueva en `/etc/apache2/sites-available/ejemplo.com.conf`:

    sudo nano /etc/apache2/sites-available/ejemplo.com.conf

Pega el siguiente bloque de configuración, que es muy similar al predeterminado, pero contiene la información actualizada de directorios y de dominio:

/etc/apache2/sites-available/ejemplo.com.conf

    <VirtualHost *:80>
        ServerAdmin admin@ejemplo.com
        ServerName ejemplo.com
        ServerAlias www.ejemplo.com
        DocumentRoot /var/www/ejemplo.com/html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>

Observa que hemos actualizado el campo `DocumentRoot` a nuestro nuevo directorio y `ServerAdmin` a una dirección de correo electrónico que el administrador del sitio **example.com** pueda acceder. También, hemos adicionado dos directivas: `ServerName`, que establece el dominio base que debería ser concordante con la definición del sitio virtual, y `ServerAlias`, que define otros nombres que serán atendidos de la misma forma como si fuesen el dominio base.

Guarda y cierra el archivo cuando termines.

Habilitemos el archivo usando la herramienta `a2ensite`:

    sudo a2ensite ejemplo.com.conf

Deshabilita el sitio por defecto definido en `000-default.conf`:

    sudo a2dissite 000-default.conf

A continuación, probemos la configuración en busca de errores:

    sudo apache2ctl configtest

Deberías ver la siguiente salida:

    SalidaSyntax OK

Reinicia Apache para que los cambios sean implementados:

    sudo systemctl restart apache2

Apache ya debería estar sirviendo tu nombre de dominio. Puedes hacer un test navegando en `http://ejemplo.com`, donde deberías ver algo similar a:

![Ejemplo de alojamiento virtual en Apache](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/apache_virt_hosts_1404/example.png)

## Paso 6 — Familiarizarse con los archivos y directorios importantes de Apache

Ahora que ya sabes cómo administrar el servicio particular de Apache, tómate unos minutos para familiarizarte con algunos archivos y directorios importantes.

### Contenido

- `/var/www/html`: es donde se encuentra el contenido real web. Por defecto, consiste únicamente de la página predeterminada de Apache que viste antes, y se persiste en el directorio `/var/www/html`. Esto puede ser modificado en los archivos de configuración de Apache.

### Configuración del servidor

- `/etc/apache2`: es el directorio de configuración de Apache. Todos los archivos de configuración de Apache se localizan en éste.
- `/etc/apache2/apache2.conf`: es el archivo principal de configuración de Apache. Al modificarlo se realizan cambios en la configuración global de Apache. Este archivo es el responsable de la carga de una gran variedad de otros archivos en el directorio de configuración.
- `/etc/apache2/ports.conf`: este archivo especifica los puertos a los cuales Apache escuchará. Por defecto, Apache escucha el puerto 80, aunque adicionalmente, escucha el puerto 443 cuando un módulo con capacidad SSL es habilitado.
- `/etc/apache2/sites-available/`: es el directorio donde se alojan los diferentes sitios virtuales que podrían habilitarse. Apache no utilizará los archivos de configuración que se encuentren en este directorio a menos que se encuentren enlazados con el directorio `sites-enabled`. Típicamente, la configuración de todos los bloques de servidores se hace en este directorio, para después ser habilitados mediante su enlace con los directorios usando el comando `a2ensite`.
- `/etc/apache2/sites-enabled/`: es el directorio donde se alojan los diferentes sitios virtuales que se encuentren habilitados. Típicamente, éstos son creados usando `a2ensite` para enlazar los archivos de configuración que se encuentran en el directorio `sites-available`. Apache lee los archivos de configuración y los enlaces que se encuentren en este directorio en el momento de su arranque o reinicio, para después compilar una configuración completa.
- `/etc/apache2/conf-available/`, `/etc/apache2/conf-enabled/`: estos directorios presentan la misma relación que se da entre los directorios `sites-available` y `sites-enabled`, solo que éstos son usados para guardar los fragmentos de configuración que no pertenecen a un sitio virtual. Los archivos dentro del directorio `conf-available` pueden ser habilitados con el comando `a2enconf` y deshabilitados con el comando `a2disconf`.
- `/etc/apache2/mods-available/`, `/etc/apache2/mods-enabled/`: estos directorios contienen tanto los módulos disponibles como los habilitados, respectivamente. Los archivos terminados en `.load` contienen fragmentos que permiten cargar módulos específicos, mientras que los archivos terminados en `.conf` contienen la configuración de dichos módulos. Los módulos pueden ser habilitados y deshabilitados usando los comandos: `a2enmod` y `a2dismod`.

### Archivos de registro del servidor

- `/var/log/apache2/access.log`: por defecto, todo solicitud hecha a tu servidor web es registrada en este archivo, a menos que se configure Apache para hacerlo de una manera distinta.
- `/var/log/apache2/error.log`: por defecto, los errores se registran en este archivo. La directiva `LogLevel`, dentro de la configuración de Apache, especifica el nivel de detalle con el cual se registra el contenido del error.

## Conclusión

Para este momento, has instalado el servidor, y por lo tanto tienes un número importante de opciones de contenido y de tecnologías que te permitirán crear una experiencia más rica en tus sitios.

Si quisieras instalar una pila que soporte de manera más completa tus aplicaciones, puedes revisar el artículo: [cómo instalar en Ubuntu 18.04 la pila LAMP](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04).
