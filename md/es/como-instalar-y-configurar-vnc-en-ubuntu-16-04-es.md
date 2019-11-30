---
author: finid
date: 2016-12-12
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-y-configurar-vnc-en-ubuntu-16-04-es
---

# ¿Cómo Instalar y Configurar VNC en Ubuntu 16.04?

### Introducción

VNC o Virtual Network Computing es un sistema de conexión que le permite utilizar su teclado y su ratón para interactuar con un entorno de escritorio gráfico en un servidor remoto. Facilita la gestión de archivos, software y configuración en un servidor remoto para usuarios que aún no están cómodos con la línea de comandos.

En esta guía, vamos a configurar VNC en un servidor Ubuntu 16.04 y conectarse a él de forma segura a través de un túnel SSH. El servidor VNC que vamos a utilizar es TightVNC, un paquete de control remoto rápido y ligero. Esta opción garantizará que nuestra conexión VNC será suave y estable incluso en conexiones de Internet más lentas.

## Requisitos Previos

Para completar este tutorial, necesitará:

- Un Droplet Ubuntu 16.04 configurado a través del tutorial de [configuración inicial del servidor Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04), que incluye tener un usuario sudo no root

- Un equipo local con un cliente VNC instalado que admita conexiones VNC a través de túneles SSH. Si está utilizando Windows, puede usar TightVNC, RealVNC o UltraVNC. Los usuarios de Mac OS X pueden usar el programa de Compartir Pantalla integrado o pueden usar una aplicación multiplataforma como RealVNC. Los usuarios de Linux pueden tener muchas opciones: `vinagre`, `krdc`, RealVNC, TightVNC y más.

## Paso 1 — Instalación del Entorno de Escritorio y del Servidor VNC

De forma predeterminada, un Droplet Ubuntu 16.04 no viene con un entorno gráfico de escritorio o un servidor VNC instalado, por lo que comenzaremos por instalarlos. En concreto, instalaremos paquetes para el último entorno de escritorio Xfce y el paquete TightVNC disponible en el repositorio oficial de Ubuntu.

En su servidor, instale los paquetes Xfce y TightVNC.

    sudo apt install xfce4 xfce4-goodies tightvncserver

Para completar la configuración inicial del servidor VNC después de la instalación, utilice el comando `vncserver` para configurar una contraseña segura.

    vncserver

Se le promocionará para que ingrese y verifique una contraseña y también una contraseña de sólo vista. Los usuarios que inicien sesión con la contraseña de sólo vista no podrán controlar la instancia de VNC con su ratón o teclado. Esta es una opción útil si desea demostrar algo a otras personas usando su servidor VNC, pero no es necesario.

Ejecutar `vncserver` completa la instalación de VNC creando archivos de configuración predeterminados e información de conexión para que nuestro servidor pueda usar. Con estos paquetes instalados, ya está listo para configurar su servidor VNC.

## Paso 2 — Configuración del Servidor VNC

En primer lugar, tenemos que decirle a nuestro servidor VNC qué comandos ejecutar cuando se inicia. Estos comandos se encuentran en un archivo de configuración denominado `xstartup` en la carpeta `.vnc` de su directorio personal. El script de inicio se creó al ejecutar el `vncserver` en el paso anterior, pero necesitamos modificar algunos de los comandos para el escritorio de Xfce.

Cuando VNC se configura por primera vez, inicia una instancia de servidor predeterminada en el puerto 5901. Este puerto se denomina puerto de visualización y VNC lo denomina `:1`. VNC puede iniciar varias instancias en otros puertos de visualización, como `:2` , `:3`, etc. Al trabajar con servidores VNC, recuerde que `:X` es un puerto de visualización que se refiere a `5900+X`.

Debido a que vamos a cambiar la configuración del servidor VNC, primero deberemos detener la instancia del servidor VNC que se está ejecutando en el puerto 5901.

    vncserver -kill: 1

La salida debería verse algo así, con un PID diferente:

    OutputKilling Xtightvnc process ID 17648

Antes de comenzar a configurar el nuevo archivo `xstartup`, vamos a hacer una copia de seguridad del original.

    mv ~/.vnc/xstartup ~/.vnc/xstartup.bak

Ahora crea un nuevo archivo `xstartup` con `nano` o tu editor de texto favorito.

    nano ~/.vnc/xstartup

Pegue estos comandos en el archivo para que se realicen automáticamente cada vez que inicie o reinicie el servidor VNC, luego guarde y cierre el archivo.

    ~/.vnc/xstartup#!/bin/bash
    xrdb $HOME/.Xresources
    startxfce4 &

El primer comando en el archivo, `xrdb $HOME/.Xresources`, le dice al framework de la GUI de VNC que lea el archivo `.Xresources` del usuario del servidor. `.Xresources` es donde un usuario puede realizar cambios en determinadas configuraciones del escritorio gráfico, como colores de terminales, temas de cursor y representación de fuentes. El segundo comando simplemente le dice al servidor que inicie Xfce, que es donde encontrará todo el software gráfico que necesita para administrar cómodamente su servidor.

Para asegurarse de que el servidor VNC pueda utilizar este nuevo archivo de inicio correctamente, tendremos que concederle privilegios ejecutables.

    sudo chmod +x ~/.vnc/xstartup

Ahora, reinicie el servidor VNC.

    vncserver

El servidor se debe iniciar con una salida similar a esto:

    OutputNew 'X' desktop is your_server_name.com:1
    
    Starting applications specified in /home/sammy/.vnc/xstartup
    Log file is /home/sammy/.vnc/liniverse.com:1.log

## Paso 3 — Prueba del VNC Desktop

En este paso, probaremos la conectividad de su servidor VNC.

Primero, necesitamos crear una conexión SSH en su computadora local que se envíe de forma segura a la conexión `localhost` para VNC. Puede hacerlo a través de la terminal en Linux u OS X con el siguiente comando. Recuerde reemplazar `user` y `server_ip_address` con el nombre de usuario sudo no root y la dirección IP de su servidor.

    ssh -L 5901:127.0.0.1:5901 -N -f -l username server_ip_address

Si está utilizando un cliente SSH gráfico, como PuTTY, use `server_ip_address` como IP de conexión y establezca `localhost: 5901` como un nuevo puerto reenviado en la configuración del túnel SSH del programa.

A continuación, ahora puede utilizar un cliente VNC para intentar una conexión al servidor VNC en `localhost: 5901`. Se le pedirá que se autentique. La contraseña correcta para usar es la que estableció en el paso 1.

Una vez conectado, debe ver el escritorio de Xfce predeterminado. Debe ser algo como esto:

![Conexión VNC para servidor Ubuntu 16.04](http://i.imgur.com/X4eEcuV.png)

Puede acceder a los archivos en su directorio personal con el administrador de archivos o desde la línea de comandos, como se ve aquí:

![Archivos vía Conexión VNC para Ubuntu 16.04](http://i.imgur.com/n5VPuSa.png)

## Paso 4 — Creación de un archivo de servicio VNC

A continuación, configuraremos el servidor VNC como un servicio systemd. Esto hará posible iniciarlo, detenerlo y reiniciarlo según sea necesario, como cualquier otro servicio systemd.

Primero, cree un nuevo archivo de unidad llamado `/etc/systemd/system/vncserver@.service` usando su editor de texto favorito:

    sudo nano /etc/systemd/system/vncserver@.service

Copie y pegue lo siguiente en él. Asegúrese de cambiar el valor de **User** y el nombre de usuario en el valor de **PIDFILE** para que coincida con su nombre de usuario.

    /etc/systemd/system/vncserver@.service[Unit]
    Description=Start TightVNC server at startup
    After=syslog.target network.target
    
    [Service]
    Type=forking
    User=sammy
    PAMName=login
    PIDFile=/home/sammy/.vnc/%H:%i.pid
    ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
    ExecStart=/usr/bin/vncserver -depth 24 -geometry 1280x800 :%i
    ExecStop=/usr/bin/vncserver -kill :%i
    
    [Install]
    WantedBy=multi-user.target

Guarde y cierre el archivo.

A continuación, haga que el sistema sea consciente del nuevo archivo de unidad.

    sudo systemctl daemon-reload

Habilite el archivo de la unidad.

    sudo systemctl enable vncserver@1.service

Detenga la instancia actual del servidor VNC si todavía está en ejecución.

    vncserver -kill :1

A continuación, inícielo como iniciar cualquier otro servicio systemd.

    sudo systemctl start vncserver@1

Puede verificar que se inició con este comando:

    sudo systemctl status vncserver@1

Si se inició correctamente, la salida debería tener este aspecto:

Output

    vncserver@1.service - TightVNC server on Ubuntu 16.04
       Loaded: loaded (/etc/systemd/system/vncserver@.service; enabled; vendor preset: enabled)
       Active: active (running) since Mon 2016-04-25 03:21:34 EDT; 6s ago
      Process: 2924 ExecStop=/usr/bin/vncserver -kill :%i (code=exited, status=0/SUCCESS)
    
    ...
    
     systemd[1]: Starting TightVNC server on Ubuntu 16.04...
     systemd[2938]: pam_unix(login:session): session opened for user finid by (uid=0)
     systemd[2949]: pam_unix(login:session): session opened for user finid by (uid=0)
     systemd[1]: Started TightVNC server on Ubuntu 16.04.

## Conclusión

Ahora debe tener instalado un servidor VNC asegurado en su servidor Ubuntu 16.04. Ahora podrá administrar sus archivos, software y configuraciones con una interfaz gráfica fácil de usar y familiar.
