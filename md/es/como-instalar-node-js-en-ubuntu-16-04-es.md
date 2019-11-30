---
author: Brennen Bearnes
date: 2016-12-12
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-node-js-en-ubuntu-16-04-es
---

# ¿Cómo instalar Node.js en Ubuntu 16.04?

### Introducción

Node.js es una plataforma de programación en JavaScript de propósitos generales que permite a los usuarios hacer aplicaciones de red rápidamente. Mediante el aprovechamiento de Javascript tanto en el front-end como en el back-end, el desarrollo puede ser más consistente y ser diseñada dentro del mismo sistema.

En esta guía, le mostraremos cómo empezar con Node.js en un servidor de Ubuntu 16.04.

Si está buscando configurar un entorno de producción para Node.js, eche un vistazo a este enlace: [¿Cómo configurar una aplicación Node.js para la producción?](how-to-set-up-a-node-js-application-for-production-on-ubuntu-14-04).

## Requisitos Previos

Esta guía asume que está utilizando Ubuntu 16.04. Antes de comenzar, debe tener una cuenta de usuario independiente que no sea root, con privilegios de `sudo`. Puede aprender cómo hacer esto completando los pasos 1-4 en la [configuración inicial del servidor de Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).

## Cómo Instalar la Versión Distro-Estable para Ubuntu

Ubuntu 16.04 contiene una versión de Node.js en sus repositorios por defecto que se pueden utilizar para proporcionar fácilmente una experiencia consistente a través de múltiples sistemas. En el momento que se escribió esta guía, la versión de los repositorios es v4.2.6. Esta no será la última versión, pero debe ser bastante estable, y debe ser suficiente para la experimentación rápida con el lenguaje.

Con el fin de obtener esta versión, sólo tenemos que utilizar el gestor de paquetes `apt`. En primer lugar debemos actualizar nuestro índice de paquetes local, y luego instalarla desde los repositorios:

    sudo apt-get update
    sudo apt-get install nodejs

Si el paquete en los repositorios se adapta a sus necesidades, esto es todo lo que necesita hacer para ponerse en marcha con Node.js. En la mayoría de los casos, también puede instalar `npm`, que es el gestor de paquetes Node.js. Puede hacer esto escribiendo:

    sudo apt-get install npm

Esto le permitirá instalar fácilmente módulos y paquetes para usar con Node.js.

Debido a un conflicto con otro paquete, el ejecutable desde los repositorios de Ubuntu se llama `nodejs` en lugar de `node`. Tenga esto en cuenta a medida que se ejecuta el software.

A continuación, vamos a discutir los métodos más flexibles y robustos de la instalación.

## ¿Cómo Instalar Mediante el uso de un PPA?

Una alternativa en la que se puede obtener una versión más reciente de Node.js es agregar un PPA (archivo de paquete personal) mantenido por NodeSource. Ahi tendrán más versiones de Node.js que los repositorios oficiales de Ubuntu hasta la fecha, y le permite elegir entre Node.js v4.x (la versión más antigua de soporte a largo plazo, con apoyo hasta abril de 2017), v6. x (la versión más reciente LTS, que será apoyada hasta abril de 2018), y v7.x Node.js (la actual versión desarrollada de forma activa).

En primer lugar, es necesario instalar el PPA con el fin de obtener acceso a su contenido. Asegúrate de que está en su directorio personal, y utilizar `curl` para recuperar el script de instalación para su versión preferida, asegurándote de reemplazar `6.x` con la cadena de versión correcta:

    cd ~
    curl -sL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh

Puede inspeccionar el contenido de esta secuencia de comandos con `nano` (o su editor de texto preferido):

    nano nodesource_setup.sh

Y ejecutar el script bajo `sudo`:

    sudo bash nodesource_setup.sh

El PPA se añadirá a tu configuración y su caché de paquetes locales se actualizará automáticamente. Después de ejecutar el script de configuración de NodeSource, puedes instalar el paquete de Node.js de la misma manera que se realizó anteriormente:

    sudo apt-get install nodejs

El paquete `nodejs` contiene el binario de `nodejs`, así como `npm`, por lo que no es necesario instalar `npm` por separado. Sin embargo, para que algunos paquetes `npm` funcionen (como los que requieren compilar el código desde el origen), tendrá que instalar el paquete `build-essential`:

    sudo apt-get install build-essential

## ¿Cómo Instalar Mediante el uso de NVM?

Una alternativa a la instalación de Node.js a través de `apt` es utilizar una herramienta especialmente diseñada llamada `nvm`, que significa “administrador de versiones Node.js”.

Utilizando `nvm`, puedes instalar varias versiones, independientes de Node.js que permitirán controlar su entorno de forma más fácil. No solo se le dará acceso bajo demanda a las nuevas versiones de Node.js, sino que también le permitirá dirigirse a versiones anteriores de las cuales su aplicación pueda depender.

Para empezar, vamos a necesitar obtener los paquetes de software de nuestros repositorios de Ubuntu que nos permitirán construir paquetes fuente. El script nvm aprovechará estas herramientas para construir los componentes necesarios:

    sudo apt-get update
    sudo apt-get install build-essential libssl-dev

Una vez instalados los paquetes de requisitos previos, puede desplegar el script de instalación de nvm desde [la página del proyecto en GitHub](https://github.com/creationix/nvm). El número de versión puede ser diferente, pero en general, se puede descargar con `curl`:

    curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh -o install_nvm.sh

E inspeccionar el script de instalación con `nano`:

    nano install_nvm.sh

Ejecutar el script con `bash`:

    bash install_nvm.sh

Se instalará el software en un subdirectorio del directorio principal en `~/.nvm`. También agregará las líneas necesarias al archivo `~/.profile` para poder utilizarlo.

Para acceder a la funcionalidad de NVM, tendrá que cerrar la sesión y volver a iniciarla de nuevo, o puede generar el archivo `~/.profile` para que la sesión actual reconozca los cambios:

    source ~/.profile

Ahora que ha instalado NVM, puede instalar versiones aisladas de Node.js.

Para averiguar las versiones de Node.js que están disponibles para su instalación, puede escribir:

    nvm ls-remote

    Output...
         v5.8.0
         v5.9.0
         v5.9.1
        v5.10.0
        v5.10.1
        v5.11.0
         v6.0.0

Como se puede ver, la versión más reciente en el momento de escribir estas líneas es v6.0.0. Puede instalarla escribiendo:

    nvm install 6.0.0

Normalmente, NVM cambiará a utilizar la versión instalada más reciente. Puede indicar explícitamente a nvm que utilice la versión que acabamos de descargar escribiendo:

    nvm use 6.0.0

Al instalar Node.js usando NVM, el ejecutable se llama `node`. Puede ver la versión que esta siendo utilizada actualmente por el shell escribiendo:

    node -v

    Outputv6.0.0

Si tiene varias versiones Node.js, se puede ver las que están instaladas escribiendo:

    nvm ls

Si desea por defecto una de las versiones, puede escribir:

    nvm alias default 6.0.0

Esta versión se seleccionará automáticamente cuando se genere una nueva sesión. También puede hacer referencia al mismo mediante el alias:

    nvm use default

Cada versión de Node.js mantendrá un registro de sus propios paquetes y dispondrá de `npm` para gestionarlos.

Puede tener los paquetes de instalación `npm` en el directorio `./node_modules` del proyecto Node.js usando el formato normal. Por ejemplo, para el módulo `express`:

    npm install express

Si desea instalarlo a nivel global (ponerlo a disposición de los otros proyectos que utilizan la misma versión Node.js), puede agregar el indicador `-g`:

    npm install -g express

Esto instalará el paquete en:

    ~/.nvm/node_version/lib/node_modules/package_name

La instalación global le permitirá ejecutar los comandos desde la línea de comandos, pero tendrá que vincular el paquete a su ámbito local para requerirlo desde dentro de un programa:

    npm link express

Puede aprender más acerca de las opciones disponibles con nvm escribiendo:

    nvm help

## Conclusión

Como puede ver, hay bastantes maneras de iniciarse con Node.js en su servidor Ubuntu 16.04. Sus circunstancias dictarán cuál de los métodos anteriores es la mejor idea para su situación. Mientras que la versión empaquetada en el repositorio de Ubuntu es la más fácil, el método `nvm` es definitivamente mucho más flexible.
