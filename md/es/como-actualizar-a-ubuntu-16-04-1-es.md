---
author: Brennen Bearnes
date: 2016-12-12
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-actualizar-a-ubuntu-16-04-1-es
---

# ¿Cómo Actualizar a Ubuntu 16.04?

### Introducción

**Advertencia:** Una versión anterior de esta guía incluía mención de los sistemas Ubuntu 14.04. Mientras que una actualización de 14.04 puede completarse con éxito, las actualizaciones entre versiones LTS no están habilitadas por defecto hasta la primera liberación, y se recomienda esperar hasta la versión 16.04.1 para actualizar. En los sistemas de DigitalOcean, un sistema actualizado de Ubuntu 14.04 quedará con un kernel antiguo que puede no ser actualizable durante algún tiempo.

El próximo lanzamiento de Soporte a Largo Plazo (LTS) del sistema operativo Ubuntu, versión 16.04 (Xenial Xerus), se estrenará el 21 de abril de 2016.

Aunque todavía no se ha publicado en el momento de escribir este documento, ya es posible actualizar un sistema 15.10 a la versión de desarrollo de 16.04. Esto puede ser útil para probar tanto el proceso de actualización como las características de 16.04 antes de la fecha oficial de lanzamiento.

Esta guía explicará el proceso de los sistemas que incluyen (pero no limitado a) Droplets de DigitalOcean con Ubuntu 15.10.

**Advertencia:** Al igual que con casi cualquier actualización entre versiones principales de un sistema operativo, este proceso conlleva un riesgo inherente de falla, pérdida de datos o configuración rota de software. Se recomienda encarecidamente realizar copias de seguridad completas y realizar extensas pruebas.

## Requisitos Previos

Esta guía asume que usted tiene un sistema que ejecuta Ubuntu 15.10, configurado con una cuenta de usuario independiente que no sea root con privilegios de `sudo` para tareas administrativas.

## Peligros Potenciales

Aunque muchos sistemas pueden actualizarse sin incidentes, a menudo es más seguro y más predecible migrar a una nueva versión principal instalando la distribución desde cero, configurando los servicios con pruebas cuidadas a lo largo del proceso y migrando los datos de aplicaciones o usuarios como datos separados paso.

Nunca debe actualizarse un sistema de producción sin probar primero todo el software y los servicios desplegados frente a la actualización en un entorno de almacenamiento intermedio. Tenga en cuenta que las bibliotecas, lenguajes y servicios del sistema pueden haber cambiado sustancialmente. En Ubuntu 16.04, hay cambios importantes desde la versión anterior de LTS que incluyen una transición al sistema systemd init en lugar de upstart, un énfasis en soporte de Python 3 y PHP 7 en lugar de PHP 5.

Antes de actualizar, le recomendamos que lea las [notas de la versión Xenial Xerus](https://wiki.ubuntu.com/XenialXerus/ReleaseNotes).

## Paso 1 – Copia de Seguridad del Sistema

Antes de intentar realizar una actualización importante en cualquier sistema, asegúrese de no perder datos si la actualización falla. La mejor manera de lograr esto es hacer una copia de seguridad de todo tu sistema de archivos. De lo contrario, asegúrese de tener copias de los directorios personales de usuario, de cualquier archivo de configuración personalizado y de datos almacenados por servicios como bases de datos relacionales.

En un Droplet de DigitalOcean, el enfoque más fácil es apagar el sistema y tomar una copia instantánea (la desconexión garantiza que el sistema de archivos será más coherente). Consulte [¿Cómo utilizar las instantáneas de DigitalOcean para hacer una copia de seguridad automática de droplets?](how-to-use-digitalocean-snapshots-to-automatically-backup-your-droplets) para obtener más detalles sobre el proceso de copias instantáneas. Cuando haya verificado que la actualización se realizó correctamente, puede eliminar la copia instantánea para que ya no se cargue.

Para los métodos de copia de seguridad que funcionarán en la mayoría de los sistemas de Ubuntu, consulte [¿Cómo elegir una estrategia de copia de seguridad eficaz para su VPS?](how-to-choose-an-effective-backup-strategy-for-your-vps).

## Paso 2 – Actualizar los Paquetes Actualmente Instalados

Antes de comenzar la actualización de la versión, es más seguro instalar las versiones más recientes de todos los paquetes para la versión actual. Comience actualizando la lista de paquetes:

    sudo apt-get update

A continuación, actualizar los paquetes instalados a sus últimas versiones disponibles:

    sudo apt-get upgrade

Se mostrará una lista de actualizaciones, y preguntará si deseas continuar. Responder **y** para sí y pulse **Enter**.

Este proceso puede tomar algún tiempo. Una vez que termine, utilice el comando `dist-upgrade`, que llevará a cabo actualizaciones que impliquen cambiar dependencias, agregar o quitar nuevos paquetes según sea necesario. Esto manejará un conjunto de actualizaciones que pueden haber sido retenidas por `apt-get upgrade`:

    sudo apt-get dist-upgrade

Una vez más, presione **y** cuando se pida para continuar, y espera que las actualizaciones se terminen.

Ahora que tiene una instalación a la fecha de Ubuntu 15.10, puede utilizar `do-release-upgrade` para actualizar a la versión 16.04.

## Paso 3 – Usar la Herramienta Do-Release-Upgrade para Realizar la Actualización

En primer lugar, asegúrese de que tiene el paquete `update-manager-core` instalado:

    sudo apt-get install update-manager-core

Tradicionalmente, las versiones de Debian se pueden actualizar mediante el cambio del archivo de Apt `/etc/apt/sources.list`, que especifica los repositorios de paquetes, y utilizar `apt-get dist-upgrade` para realizar la actualización en sí. Ubuntu es todavía una distribución derivada de Debian, por lo que este proceso sería probable que todavía trabajar. En lugar de ello, sin embargo, vamos a utilizar do-release-upgrade, una herramienta proporcionada por el proyecto Ubuntu, que se encarga de comprobar para una nueva versión, las actualizaciones de sources.list, y una serie de otras tareas. Esta es la ruta de actualización oficialmente recomendada para actualizaciones del servidor que deben realizarse a través de una conexión remota.

Comience a correr`do-release-upgrade` sin opciones:

    sudo do-release-upgrade

Si Ubuntu 16.04 no se ha liberado aún, debería ver lo siguiente:

Sample Output

    Checking for a new Ubuntu release
    No new release found

Con el fin de actualizar a 16.04 antes de su lanzamiento oficial, especifique la opción `-d` con el fin de utilizar la liberación de desarrollo:

    sudo do-release-upgrade -d

Si está conectado a su sistema a través de SSH, como es probable con un Droplet de DigitalOcean, se le preguntará si desea continuar.

En un Droplet, es seguro actualizar a través de SSH. A pesar de que `do-upgrade-release` no nos ha informado de ello, puede utilizar la consola disponible en el panel de control de DigitalOcean para conectarse a su Droplet sin ejecutar SSH.

Para máquinas virtuales o servidores administrados alojados por otros proveedores, debe tener en cuenta que la pérdida de conectividad SSH es un riesgo, sobre todo si no dispone de otro medio de conexión remota a la consola del sistema. Para otros sistemas bajo su control, recuerde que es más seguro realizar las actualizaciones principales del sistema operativo sólo cuando se tiene acceso físico directo a la máquina.

En el indicador, escriba **Y** y pulse **Enter** para continuar:

    Reading cache
    
    Checking package manager
    
    Continue running under SSH?
    
    This session appears to be running under ssh. It is not recommended
    to perform a upgrade over ssh currently because in case of failure it
    is harder to recover.
    
    If you continue, an additional ssh daemon will be started at port
    '1022'.
    Do you want to continue?
    
    Continue [yN] y

A continuación, se te informará de que `do-release-upgrade` está comenzando una nueva instancia de `sshd` en el puerto 1022:

    Starting additional sshd
    
    To make recovery in case of failure easier, an additional sshd will 
    be started on port '1022'. If anything goes wrong with the running 
    ssh you can still connect to the additional one. 
    If you run a firewall, you may need to temporarily open this port. As 
    this is potentially dangerous it's not done automatically. You can 
    open the port with e.g.: 
    'iptables -I INPUT -p tcp --dport 1022 -j ACCEPT' 
    
    To continue please press [ENTER]

Presiona **Enter**. A continuación, se le puede advertir que no se encontró una entrada de espejo. En los sistemas de DigitalOcean, es seguro hacer caso omiso de esta advertencia y continuar con la actualización, ya que un espejo local para 16.04 está de hecho disponible. Introduzca **y** :

    Updating repository information
    
    No valid mirror found 
    
    While scanning your repository information no mirror entry for the 
    upgrade was found. This can happen if you run an internal mirror or 
    if the mirror information is out of date. 
    
    Do you want to rewrite your 'sources.list' file anyway? If you choose 
    'Yes' here it will update all 'trusty' to 'xenial' entries. 
    If you select 'No' the upgrade will cancel. 
    
    Continue [yN] y

Una vez descargadas las nuevas listas de paquetes y calculados los cambios, se le preguntará si deseas iniciar la actualización. Otra vez, ingrese **y** para continuar:

    Do you want to start the upgrade?
    
    
    6 installed packages are no longer supported by Canonical. You can
    still get support from the community.
    
    9 packages are going to be removed. 104 new packages are going to be
    installed. 399 packages are going to be upgraded.
    
    You have to download a total of 232 M. This download will take about
    46 seconds with your connection.
    
    Installing the upgrade can take several hours. Once the download has
    finished, the process cannot be canceled.
    
     Continue [yN] Details [d] y

Ahora se recuperarán los nuevos paquetes, luego se desempaquetarán e instalarán. Incluso si su sistema está en una conexión rápida, esto tomará un tiempo.

Durante la instalación, se le pueden presentar diálogos interactivos para varias preguntas. Por ejemplo, le puede preguntar si desea reiniciar automáticamente los servicios cuando sea necesario:

![Reiniciar servicio de diálogo](http://assets.digitalocean.com/articles/how-to-upgrade-to-ubuntu-1604/0.png)

En este caso, es seguro que responder “Yes”. En otros casos, es posible que se le preguntará si desea reemplazar un archivo de configuración que ha sido modificado con la versión predeterminada del paquete que se está instalando. Esto es a menudo una cuestión de criterio, y es probable que requiera conocimientos sobre software específico que está fuera del alcance de este tutorial.

Una vez que los nuevos paquetes se han terminado de instalar, se le preguntará si está listo para eliminar los paquetes obsoletos. En un sistema por defecto sin necesidad de configuración personalizada, debe ser seguro pulsar **y**. En un sistema que se ha modificado en gran medida, es posible que desee pulsar **d** e inspeccionar la lista de paquetes que serán eliminados, en caso de que sea necesario reinstalar en el futuro.

    Remove obsolete packages? 
    
    
    53 packages are going to be removed. 
    
     Continue [yN] Details [d] y

Por último, suponiendo que todo ha ido bien, se le informará de que la actualización se ha completado y se requiere un reinicio. Introduzca **y** \* para continuar:

    System upgrade is complete.
    
    Restart required 
    
    To finish the upgrade, a restart is required. 
    If you select 'y' the system will be restarted. 
    
    Continue [yN] y

En una sesión SSH, es probable que vea algo como lo siguiente:

    === Command detached from window (Thu Apr 7 13:13:33 2016) ===
    === Command terminated normally (Thu Apr 7 13:13:43 2016) ===

Es posible que tenga que pulsar una tecla para salir a su local prompt, ya que la sesión de SSH se habrá terminado en el extremo del servidor. Espere un momento para que el sistema se reinicie, y vuelva a conectar. Al iniciar sesión, debe recibir un mensaje confirmando que está en Xenial Xerus:

    Welcome to Ubuntu Xenial Xerus (development branch) (GNU/Linux 4.4.0-17-generic x86_64)

## Conclusión

Ahora debería tener una instalación de trabajo de Ubuntu 16.04. A partir de aquí, es probable que necesite investigar los cambios de configuración necesarios en los servicios y las aplicaciones implementadas. En las próximas semanas, vamos a comenzar la publicación de guías DigitalOcean específicas para Ubuntu 16.04 en una amplia gama de temas.
