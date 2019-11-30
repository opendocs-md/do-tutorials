---
author: Mateusz Papiernik
date: 2016-12-09
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-mongodb-en-ubuntu-16-04-es
---

# ¿Cómo instalar MongoDB en Ubuntu 16.04?

### Introducción

MongoDB es una base de datos libre y de código abierto NoSQL utilizada comúnmente en aplicaciones web modernas. Este tutorial le ayudará a configurar MongoDB en su servidor para aplicaciones en ambiente de producción.

Al tiempo de publicación, los paquetes oficiales de MongoDB en Ubuntu 16.04 aún no han sido actualizados para usar el nuevo sistema de arranque `systemd` [el cual está habilitado por defecto en Ubuntu 16.04](what-s-new-in-ubuntu-16-04#the-systemd-init-system). Correr MongoDB utilizando esos paquetes en una instalación limpia de Ubuntu 16.04 involucra algunos pasos adicionales para configurar MongoDB como un servicio de `systemd` que correrá automáticamente al arrancar.

## Requisitos Previos

Para seguir este tutorial, necesitará:

- Un servidor Ubuntu 16.04 configurado siguiendo este [tutorial de configuración iniciar del servidor](initial-server-setup-with-ubuntu-16-04), incluyendo un usuario sudo no-root.

## Paso 1 — Agregar el Repositorio MongoDB

MongoDB está actualmente incluido en el repositorio de paquetes de Ubuntu, pero el repositorio oficial de MongoDB proporciona la versión más actualizada y es el camino recomendado para instalar este software. En este paso, agregaremos este repositorio oficial al servidor.

Ubuntu se asegura de autenticar los paquetes de software verificando que han sido firmados con llaves GPG, así que primero importaremos la llave para el repositorio oficial de MongoDB.

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927

Después de importar la llave satisfactoriamente, verá algo como esto:

Output

    gpg: Total number processed: 1
    gpg: imported: 1 (RSA: 1)

A continuación, debemos agregar los detalles del repositorio de Mongo de tal manera que `apt` pueda saber de donde descargar los paquetes.

Corriendo el siguiente comando crearemos la lista para MongoDB.

    echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list

Después de agregar los detalles del repositorio, debemos actualizar la lista de paquetes.

    sudo apt-get update

## Paso 2 — Instalando y Verificando MongoDB

Ahora podemos instalar el propio paquete de MongoDB.

    sudo apt-get install -y mongodb-org

Este comando instalará diversos paquetes incluyendo la versión estable más reciente de MongoDB seguido de herramientas administrativas para el servidor MongoDB.

Para lanzar apropiadamente MongoDB como un servicio de Ubuntu 16.04, debemos crear un archivo unitario que describa el servicio. Un _archivo unitario_ le dice al `systemd` como manejar el recurso. El tipo más común de unidad es un _servicio_, el cual determina como iniciar o detener el servicio, cuando debería de iniciar automáticamente al arrancar, y cuando debería depender de otro software para su ejecución.

Vamos a crear un archivo de unidad para administrar el servicio de MongoDB. Crearemos un archivo de configuración llamado `mongodb.service` en el directorio `/etc/systemd/system` utilizando `nano` o su editor de texto favorito.

    sudo nano /etc/systemd/system/mongodb.service

Pegue el siguiente contenido, después guarde y cierre el archivo.

/etc/systemd/system/mongodb.service

    [Unit]
    Description=High-performance, schema-free document-oriented database
    After=network.target
    
    [Service]
    User=mongodb
    ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf
    
    [Install]
    WantedBy=multi-user.target

Este archivo tiene una estructura simple:

- La sección **Unit** contiene un resumen (por ejemplo una descripción legible para el humano que describe el servicio MongoDB) así como las dependencias que deberán existir antes de que el servicio inicie. En nuestro caso, MongoDB depende de que la red esté disponible, por lo tango agregamos `network.tarket` aquí.
- La sección **Service** indica como deberá iniciar el servicio. La directiva `User` especifica que el servicio deberá correr bajo el usuario `mongodb`, y la directiva `ExecStart` inicia el comando para arrancar el servidor MongoDB.
- La última sección, **Install** , le dice a `systemd` cuando el servicio debe iniciar automáticamente. `multi-user.target` es un sistema de secuencias de arranque estándar , que significa que el servicio correrá automáticamente al arrancar.

Lo siguiente, será iniciar el servicio recién creado con `systemctl`.

    sudo systemctl start mongodb

Aún cuando este comando no responde con un mensaje, puede utilizar `systemctl` para revisar que el servicio ha arrancado apropiadamente.

    sudo systemctl status mongodb

Output

    ● mongodb.service - High-performance, schema-free document-oriented database
       Loaded: loaded (/etc/systemd/system/mongodb.service; enabled; vendor preset: enabled)
       Active: <span class="highlight">active</span> (running) since Mon 2016-04-25 14:57:20 EDT; 1min 30s ago
     Main PID: 4093 (mongod)
        Tasks: 16 (limit: 512)
       Memory: 47.1M
          CPU: 1.224s
       CGroup: /system.slice/mongodb.service
               └─4093 /usr/bin/mongod --quiet --config /etc/mongod.conf

El último paso es habilitar automáticamente el arranque de MongoDB cuando el sistema inicie.

    sudo systemctl enable mongodb

El servidor MongoDB ahora está configurado y corriendo, y usted puede administrar el servicio MongoDB utilizando el comando `systemctl` (por ejemplo: `sudo systemctl mongodb stop`, `sudo systemctl mongodb start`).

## Paso 3 — Ajustando el Firewall (Opcional)

Asumiendo que ha seguido todos los pasos del [tutorial inicial de configuración del servidor](initial-server-setup-with-ubuntu-16-04) para habilitar el firewall en su servidor, el servidor MongoDB deberá ser inaccesible desde Internet.

Si usted intenta utilizar el servidor MongoDB de modo local con aplicaciones corriendo en el mismo servidor, es una configuración recomendada y segura. Por otro lado, si usted requiere acceso a su servidor MongoDB desde otro lugar de Internet, tenemos que habilitar las conexiones entrantes en `ufw`.

Para permitir el acceso a MongoDB en su puerto por defecto `27017` desde cualquier parte, puede utilizar el comando `sudo ufw allow 27017`. Hay que tener en cuenta que, habilitando el acceso al servidor MongoDB desde Internet en una instalación por defecto, proporciona acceso sin restricciones al servidor completo de base de datos.

En la mayoría de los casos, MongoDB solo debería ser accesible desde ubicaciones seguras, como por ejemplo el otro servidor que aloja la aplicación. Para cumplir con esta tarea, puede permitir a una IP de un servidor específico acceder y conectarse al puerto por defecto de MongoDB.

    sudo ufw allow from la_IP_del_otro_servidor/32 to any port 27017

Puede verificar el cambio en la configuración del firewall con `ufw`.

    sudo ufw status

Debería ver trafico permitido al puerto `27017` en la salida. Si usted ha decidido permitir el acceso a MongoDB desde una dirección IP específica, la IP deberá aparecer abajo en lugar de Anywhere en la salida.

Output

    Status: active
    
    To Action From
    -- ------ ----
    27017 ALLOW Anywhere
    OpenSSH ALLOW Anywhere
    27017 (v6) ALLOW Anywhere (v6)
    OpenSSH (v6) ALLOW Anywhere (v6)

Configuraciones avanzadas del firewall se pueden encontrar en [UFW Essentials: Reglas y Comandos Comunes del Firewall](ufw-essentials-common-firewall-rules-and-commands).

## Conclusión

Puede encontrar más instrucciones a profundidad con respecto a la instalación y configuración de MongoDB en [estos artículos de la comunidad de DigitalOcean](https://www.digitalocean.com/community/search?q=mongodb).
