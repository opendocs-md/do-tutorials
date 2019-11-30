---
author: Brian Hogan
date: 2019-04-26
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-y-usar-docker-en-ubuntu-18-04-1-es
---

# Cómo instalar y usar Docker en Ubuntu 18.04

_[Finid](https://www.digitalocean.com/community/users/finid) escribió una versión anterior de este tutorial._

### Introducción

[Docker](https://www.docker.com/)es una aplicación que simplifica el proceso de gestionar los procesos de aplicaciones en _contenedores_. Los contenedores le permiten ejecutar sus aplicaciones en procesos aislados de recursos. Se parecen a las máquinas virtuales, sin embargo, los contenedores son más portátiles, tienen más recursos y son más dependientes del sistema operativo host.

Lea [El ecosistema Docker: Una introducción a los componentes comunes](the-docker-ecosystem-an-introduction-to-common-components), si desea tener una introducción más detallada sobre los distintos componentes de un contenedor Docker.

Este tutorial le enseñará a instalar y usar la edición de comunidad de Docker (Community Edition - CE) en Ubuntu 18.04. Va a instalar Docker, trabajar con contenedores e imágenes y hacer el push de una imagen a un Repositorio de Docker.

## Requisitos previos

Necesitará lo siguiente para seguir este tutorial:

- Un servidor Ubuntu 18.04 configurado siguiendo la [guía de configuración inicial del servidor Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04), incluyendo un usuario sudo no root y un firewall.
- Una cuenta en [Docker Hub](https://hub.docker.com/), si desea crear sus propias imágenes y hacer el push a Docker Hub, según se indica en los pasos 7 y 8. 

## Paso 1 — Instalar Docker

Es posible que el paquete de instalación de Docker que está disponible en el repositorio oficial de Ubuntu no sea la última versión. Vamos a instalar Docker desde el repositorio oficial de Docker para asegurarnos de tener la última versión. Para hacer esto, vamos a agregar una nueva fuente de paquete, la clave GPG de Docker para asegurar que las descargas sean válidas y después vamos a instalar el paquete.

Primero, actualice su lista de paquetes existente:

    sudo apt update

A continuación, instale algunos paquetes de requisitos previos que le permiten a `apt` usar paquetes mediante HTTPS:

    sudo apt install apt-transport-https ca-certificates curl software-properties-common

Luego, agregue la clave GPG para el repositorio oficial de Docker a su sistema:

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

Agregue el repositorio de Docker a las fuentes de APT:

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

Posteriormente, actualice la base de datos de paquetes usando los paquetes de Docker del repositorio que acaba de agregar:

    sudo apt update

Asegúrese de que va a instalar desde el repositorio de Docker en vez del repositorio de Ubuntu predeterminado:

    apt-cache policy docker-ce

Verá un resultado como este, aunque el número de versión de Docker puede variar:

Output of apt-cache policy docker-ce

    docker-ce:
      Installed: (none)
      Candidate: 18.03.1~ce~3-0~ubuntu
      Version table:
         18.03.1~ce~3-0~ubuntu 500
            500 https://download.docker.com/linux/ubuntu bionic/stable amd64 Packages

Note que `docker-ce` no está instalado, pero el candidato para la instalación es del repositorio de Docker para Ubuntu 18.04 (`bionic`).

Por último, instale Docker:

    sudo apt install docker-ce

Ahora debería tener Docker instalado, el daemon iniciado, y el proceso habilitado para iniciar durante el arranque. Verifique que se esté ejecutando:

    sudo systemctl status docker

El resultado debería ser parecido al siguiente, indicando que el servicio está activo y se está ejecutando:

    Output● docker.service - Docker Application Container Engine
       Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
       Active: active (running) since Thu 2018-07-05 15:08:39 UTC; 2min 55s ago
         Docs: https://docs.docker.com
     Main PID: 10096 (dockerd)
        Tasks: 16
       CGroup: /system.slice/docker.service
               ├─10096 /usr/bin/dockerd -H fd://
               └─10113 docker-containerd --config /var/run/docker/containerd/containerd.toml

Instalar Docker ahora no solamente le ofrece el servicio Docker (daemon), sino también la utilidad de línea de comandos `docker` o el cliente Docker. Más adelante en este tutorial, vamos a explorar cómo usar el comando `docker`.

## Paso 2 — Ejecutar el comando Docker sin sudo (Opcional)

De forma predeterminada, el comando `docker` solamente puede ejecutarse por el usuario de **root** o por un usuario en el grupo **docker** , el cual se crea automáticamente durante la instalación de Docker. Si intenta ejecutar el comando `docker` sin prefijarlo con `sudo` o sin estar en el grupo **docker** , el resultado será como el siguiente:

    Outputdocker: Cannot connect to the Docker daemon. Is the docker daemon running on this host?.
    See 'docker run --help'.

Agregue su nombre de usuario al grupo `docker` si quiere evitar escribir `sudo` siempre que deba ejecutar el comando `docker`:

    sudo usermod -aG docker ${USER}

Para aplicar la nueva membresía de grupo, debe cerrar sesión en el servidor y volver a iniciarla, o puede escribir lo siguiente:

    su - ${USER}

Se le pedirá que ingrese la contraseña de su usuario para poder continuar.

Confirme que se haya agregado su usuario al grupo de **docker** escribiendo:

    id -nG

    Outputsammy sudo docker

Si necesita agregar un usuario al grupo de `docker` y no ha iniciado sesión como ese usuario, declare tal nombre de usuario explícitamente usando:

    sudo usermod -aG docker username

Para el resto de este artículo, se asume que está ejecutando el comando de `docker` como un usuario que es parte del grupo de **docket**. Si opta por no hacerlo, anteponga los comandos con `sudo`.

A continuación, vamos a explorar el comando `docker`.

## Paso 3 — Usar el comando Docker

Usar `docker` consiste en pasarle una cadena de opciones y comandos seguidos de argumentos. La sintaxis sería la siguiente:

    docker [option] [command] [arguments]

Para ver todos los subcomandos disponibles, ingrese:

    docker

Desde que se usa Docker 18, la lista completa de los subcomandos disponibles incluye:

    Output
      attach Attach local standard input, output, and error streams to a running container
      build Build an image from a Dockerfile
      commit Create a new image from a container's changes
      cp Copy files/folders between a container and the local filesystem
      create Create a new container
      diff Inspect changes to files or directories on a container's filesystem
      events Get real time events from the server
      exec Run a command in a running container
      export Export a container's filesystem as a tar archive
      history Show the history of an image
      images List images
      import Import the contents from a tarball to create a filesystem image
      info Display system-wide information
      inspect Return low-level information on Docker objects
      kill Kill one or more running containers
      load Load an image from a tar archive or STDIN
      login Log in to a Docker registry
      logout Log out from a Docker registry
      logs Fetch the logs of a container
      pause Pause all processes within one or more containers
      port List port mappings or a specific mapping for the container
      ps List containers
      pull Pull an image or a repository from a registry
      push Push an image or a repository to a registry
      rename Rename a container
      restart Restart one or more containers
      rm Remove one or more containers
      rmi Remove one or more images
      run Run a command in a new container
      save Save one or more images to a tar archive (streamed to STDOUT by default)
      search Search the Docker Hub for images
      start Start one or more stopped containers
      stats Display a live stream of container(s) resource usage statistics
      stop Stop one or more running containers
      tag Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE
      top Display the running processes of a container
      unpause Unpause all processes within one or more containers
      update Update configuration of one or more containers
      version Show the Docker version information
      wait Block until one or more containers stop, then print their exit codes

Si desea ver las opciones disponibles para un comando específico, ingrese:

    docker docker-subcommand --help

Si desea ver la información sobre Docker de todo el sistema, use:

    docker info

Vamos a explorar algunos de estos comandos. Vamos a empezar trabajando con imágenes.

## Paso 4 — Trabajo con imágenes de Docker

Los contenedores Docker se forman a partir de imágenes de Docker. De forma predeterminada, Docker extrae estas imágenes de [Docker Hub](https://hub.docker.com), un registro de Docker administrado por Docker, la empresa responsable del proyecto Docker. Cualquier persona es capaz de alojar sus imágenes Docker en Docker Hub, por lo tanto, la mayoría de las aplicaciones y distribuciones de Linux que necesitará tendrán las imágenes alojadas ahí mismo.

Para verificar si puede acceder y descargar imágenes desde Docker Hub, ingrese:

    docker run hello-world

El resultado le indicará que Docker está funcionando correctamente:

    OutputUnable to find image 'hello-world:latest' locally
    latest: Pulling from library/hello-world
    9bb5a5d4561a: Pull complete
    Digest: sha256:3e1764d0f546ceac4565547df2ac4907fe46f007ea229fd7ef2718514bcec35d
    Status: Downloaded newer image for hello-world:latest
    
    Hello from Docker!
    This message shows that your installation appears to be working correctly.
    ...

Inicialmente, Docker no fue capaz de encontrar la imagen de `hello-world` localmente, entonces descargó la imagen de Docker Hub, que es el repositorio predeterminado. Una vez que se descargó la imagen, Docker creó un contenedor a partir de la imagen y la aplicación dentro del contenedor ejecutado, mostrando el mensaje.

Puede buscar imágenes disponibles en Docker Hub usando el comando `docker` con el subcomando de `search`. Por ejemplo, para buscar la imagen de Ubuntu, ingrese:

    docker search ubuntu

El script rastreará Docker Hub y le entregará una lista de todas las imágenes que tengan un nombre que concuerde con la cadena de búsqueda. En este caso, el resultado será parecido a esto:

    OutputNAME DESCRIPTION STARS OFFICIAL AUTOMATED
    ubuntu Ubuntu is a Debian-based Linux operating sys… 7917 [OK]
    dorowu/ubuntu-desktop-lxde-vnc Ubuntu with openssh-server and NoVNC 193 [OK]
    rastasheep/ubuntu-sshd Dockerized SSH service, built on top of offi… 156 [OK]
    ansible/ubuntu14.04-ansible Ubuntu 14.04 LTS with ansible 93 [OK]
    ubuntu-upstart Upstart is an event-based replacement for th… 87 [OK]
    neurodebian NeuroDebian provides neuroscience research s… 50 [OK]
    ubuntu-debootstrap debootstrap --variant=minbase --components=m… 38 [OK]
    1and1internet/ubuntu-16-nginx-php-phpmyadmin-mysql-5 ubuntu-16-nginx-php-phpmyadmin-mysql-5 36 [OK]
    nuagebec/ubuntu Simple always updated Ubuntu docker images w… 23 [OK]
    tutum/ubuntu Simple Ubuntu docker images with SSH access 18
    i386/ubuntu Ubuntu is a Debian-based Linux operating sys… 13
    ppc64le/ubuntu Ubuntu is a Debian-based Linux operating sys… 12
    1and1internet/ubuntu-16-apache-php-7.0 ubuntu-16-apache-php-7.0 10 [OK]
    1and1internet/ubuntu-16-nginx-php-phpmyadmin-mariadb-10 ubuntu-16-nginx-php-phpmyadmin-mariadb-10 6 [OK]
    eclipse/ubuntu_jdk8 Ubuntu, JDK8, Maven 3, git, curl, nmap, mc, … 6 [OK]
    codenvy/ubuntu_jdk8 Ubuntu, JDK8, Maven 3, git, curl, nmap, mc, … 4 [OK]
    darksheer/ubuntu Base Ubuntu Image -- Updated hourly 4 [OK]
    1and1internet/ubuntu-16-apache ubuntu-16-apache 3 [OK]
    1and1internet/ubuntu-16-nginx-php-5.6-wordpress-4 ubuntu-16-nginx-php-5.6-wordpress-4 3 [OK]
    1and1internet/ubuntu-16-sshd ubuntu-16-sshd 1 [OK]
    pivotaldata/ubuntu A quick freshening-up of the base Ubuntu doc… 1
    1and1internet/ubuntu-16-healthcheck ubuntu-16-healthcheck 0 [OK]
    pivotaldata/ubuntu-gpdb-dev Ubuntu images for GPDB development 0
    smartentry/ubuntu ubuntu with smartentry 0 [OK]
    ossobv/ubuntu
    ...
    

En la columna nombrada **OFICIAL** , **OK** indica una imagen que fue creada y soportada por la empresa que respalda el proyecto. Una vez que haya identificado la imagen que quiera usar, puede descargarla a su computadora mediante el subcomando de `pull`.

Para descargar la imagen de `ubuntu` oficial a su computadora, ejecute el siguiente comando:

    docker pull ubuntu

Verá el siguiente resultado:

    OutputUsing default tag: latest
    latest: Pulling from library/ubuntu
    6b98dfc16071: Pull complete
    4001a1209541: Pull complete
    6319fc68c576: Pull complete
    b24603670dc3: Pull complete
    97f170c87c6f: Pull complete
    Digest: sha256:5f4bdc3467537cbbe563e80db2c3ec95d548a9145d64453b06939c4592d67b6d
    Status: Downloaded newer image for ubuntu:latest

Tras descargar una imagen, puede ejecutar un contenedor usando la imagen descargada con el subcomando de `run`. Como vio con el ejemplo de `hello-world`, si no se ha descargado una imagen al ejecutar `docker` con el subcomando de `run`, el cliente Docker primero descargará la imagen y luego ejecutará un contenedor usando la misma.

Para ver las imágenes que se descargaron a su computadora, ingrese:

    docker images

El resultado debería parecerse a esto:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    ubuntu latest 113a43faa138 4 weeks ago 81.2MB
    hello-world latest e38bc07ac18e 2 months ago 1.85kB

Como verá más adelante en este tutorial, pueden modificarse y usarse las imágenes que use para ejecutar contenedores para generar imágenes nuevas, las que después pueden cargarse (el término técnico es _pushed_) a Docker Hub u otros registros de Docker.

Vamos a ver más detalladamente cómo ejecutar contenedores.

## Paso 5 — Ejecutar un contenedor Docker

El contenedor `hello-world` que ejecutó durante el paso anterior es un ejemplo de un contenedor que se ejecuta y se va tras emitir un mensaje de prueba. Los contenedores pueden ser mucho más útiles que eso, y pueden ser interactivos. Después de todo, se parecen a máquinas virtuales, nada más que tiene más recursos.

Para dar un ejemplo, ejecutemos un contenedor utilizando la última imagen de Ubuntu. La combinación de los switch **-i** y **-t** le ofrece acceso interactivo a shell en el contenedor:

    docker run -it ubuntu

Su línea de comandos debería cambiar para reflejar el hecho de que ahora está trabajando dentro del contenedor y debería verse de esta manera:

    Outputroot@d9b100f2f636:/#

Note la identificación del contenedor en la línea de comandos. En este ejemplo, es `d9b100f2f636`. Va a requerir esa identificación de contenedor más adelante para identificar el contenedor cuando quiera eliminarlo.

Ahora puede ejecutar cualquier comando dentro del contenedor. Por ejemplo, vamos a actualizar la base de datos del paquete dentro del contenedor. No es necesario que prefije algún comando con `sudo` porque está trabajando dentro del contenedor como el usuario de **root** :

    apt update

Luego, instale cualquier aplicación en él. Vamos a instalar Node.js:

    apt install nodejs

Esto instala Node.js en el contenedor desde el repositorio oficial de Ubuntu. Una vez que termine la instalación, verifique que Node.js esté instalado:

    node -v

Verá que el número de versión se muestra en su terminal:

    Outputv8.10.0

Los cambios que haga dentro del contenedor únicamente se aplicarán a tal contenedor.

Si desea salir del contenedor, ingrese `exit` en la línea.

A continuación, vamos a ver cómo gestionar los contenedores en nuestro sistema.

## Paso 6 — Gestionar los contenedores de Docker

Una vez que haya estado usando Docker por un tiempo, tendrá varios contenedores activos (siendo ejecutados) e inactivos en su computadora. Si desea ver los que **están activos** , use:

    docker ps

Verá un resultado parecido al de abajo:

    OutputCONTAINER ID IMAGE COMMAND CREATED             
    

En este tutorial, comenzó teniendo dos contenedores: uno de la imagen de `hello-world` y otro de la imagen de `ubuntu`. Ninguno de los contenedores se sigue ejecutando, pero siguen existiendo en su sistema.

Para ver todos los contenedores, tanto los activos como los inactivos, ejecute `docker ps` con el switch `-a`:

    docker ps -a

Verá un resultado parecido a este:

    d9b100f2f636 ubuntu "/bin/bash" About an hour ago Exited (0) 8 minutes ago sharp_volhard
    01c950718166 hello-world "/hello" About an hour ago Exited (0) About an hour ago festive_williams
    

Si desea ver el último contenedor que creó, páselo al switch `-l`:

    docker ps -l

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    d9b100f2f636 ubuntu "/bin/bash" About an hour ago Exited (0) 10 minutes ago sharp_volhard

Para iniciar un contenedor que se haya detenido, use `docker start`, seguido de la identificación o el nombre del contenedor. Vamos a empezar con el contenedor basado en Ubuntu cuya identificación era `d9b100f2f636`:

    docker start d9b100f2f636

Se iniciará el contenedor, y puede usar `docker ps` para ver su estado:

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    d9b100f2f636 ubuntu "/bin/bash" About an hour ago Up 8 seconds sharp_volhard
    

Para detener un contenedor que se está ejecutando, use la función de `docker stop`, seguido de la identificación o el nombre del contenedor. Esta vez, vamos a usar el nombre que Docker le asignó al contenedor, que es `sharp_volhard`:

    docker stop sharp_volhard

Una vez que decida que ya no necesita un contenedor, puede eliminarlo usando el comando `docker rm`, otra vez usando la identificación o el nombre del contenedor. Use el comando `docker ps -a` para encontrar la identificación o el nombre del contenedor para el contenedor que esté asociado con la imagen de `hello-world` y eliminarlo.

    docker rm festive_williams

Puede iniciar un contenedor nuevo y nombrarlo usando el switch de `--name`. Además, puede usar el switch de `--rm` para crear un contenedor que se elimine automáticamente una vez que se detenga. Si desea aprender más sobre estas y otras opciones, consulte el comando `docker run help`.

Los contenedores se pueden convertir en imágenes que puede usar para crear contenedores nuevos. Vamos a ver cómo se hace eso.

## Paso 7 — Hacer cambios en un contenedor a una imagen de Docker

Al iniciar una imagen de Docker, puede crear, modificar y borrar archivos al igual que lo hace con una máquina virtual. Los cambios que haga solamente se aplicarán a ese contenedor. Puede iniciarlo y detenerlo, pero una vez que lo destruya usando el comando `docker rm`, se perderán los cambios para siempre.

En esta sección, se le indica cómo guardar el estado de un contenedor como una imagen de Docker nueva.

Tras instalar Node.js dentro del contenedor de Ubuntu, tendrá un contenedor que se ejecuta de una imagen, pero el contenedor es distinto a la imagen que usó para crearlo. Tal vez quiera volver a usar este contenedor Node.js como base para imágenes nuevas más tarde.

Entonces, confirme los cambios en una instancia de imagen de Docker nueva usando el siguiente comando.

    docker commit -m "What you did to the image" -a "Author Name" container_id repository/new_image_name

El switch **-m** es para el mensaje de confirmación que le ayuda a usted y a los demás a saber qué cambios hizo, mientras que **-a** se usa para especificar el autor. La `container_id` (identificación del contenedor) es la que anotó más temprano en el tutorial cuando inició la sesión interactiva de Docker. El `repository` suele ser su nombre de usuario de Docker Hub, a menos que haya creado repositorios adicionales en Docker Hub.

Por ejemplo, para el usuario **sammy** , cuya identificación de contenedor es `d9b100f2f636`, el comando sería:

    docker commit -m "added Node.js" -a "sammy" d9b100f2f636 sammy/ubuntu-nodejs

Al _confirmar_ una imagen, se guarda la imagen nueva localmente en su computadora. Más adelante en este tutorial, aprenderá cómo hacer push de una imagen a un registro de Docker como Docker Hub para que otros usuarios puedan tener acceso a la misma.

Si se listan las imágenes de Docker nuevamente, se mostrará la nueva imagen, al igual que la antigua de la que se derivó:

    docker images

Verá un resultado como el siguiente:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    sammy/ubuntu-nodejs latest 7c1f35226ca6 7 seconds ago 179MB
    ubuntu latest 113a43faa138 4 weeks ago 81.2MB
    hello-world latest e38bc07ac18e 2 months ago 1.85kB
    

En este ejemplo, la imagen nueva es `ubuntu-nodejs`, que se derivó de la imagen `ubuntu` existente de Docker Hub. La diferencia de tamaño refleja los cambios que se hicieron. Y en este ejemplo, el cambio fue que se instaló NodeJS. Por lo que, la próxima vez que deba ejecutar un contenedor usando Ubuntu con NodeJS preinstalado, simplemente puede usar la imagen nueva.

Además, puede crear Imágenes desde un `Dockerfile`, el cual le permite automatizar la instalación del software en una imagen nueva. No obstante, no se abarca eso en este tutorial.

Ahora, vamos a compartir la imagen nueva con los demás para que puedan crear contenedores usándola.

## Paso 8 — Hacer push de imágenes de Docker a un repositorio Docker

El siguiente paso lógico tras crear una imagen nueva usando una imagen existente es compartirla con algunos amigos selectos, todo el mundo en Docker Hub u otro registro de Docker al que tenga acceso. Si desea hacer push de una imagen a Docker Hub o cualquier otro registro de Docker, debe tener una cuenta en ese sitio.

Esta sección le enseña a hacer push de una imagen Docker a Docker Hub. Consulte [Cómo configurar un registro privado de Docker en Ubuntu 14.04](how-to-set-up-a-private-docker-registry-on-ubuntu-14-04) si desea aprender a crear su propio registro privado de Docker.

Primero, inicie sesión en Docker Hub para hacerle push a su imagen.

    docker login -u docker-registry-username

Se le pedirá que se certifique utilizando su contraseña de Docker Hub. Si ingresó la contraseña correcta, la certificación debería se exitosa.

**Nota:** Si su nombre de usuario de registro de Docker es distinto al nombre de usuario local que usó para crear la imagen, deberá etiquetar su imagen con su nombre de usuario de registro. Para el ejemplo que se dio en el último paso, debe escribir:

    docker tag sammy/ubuntu-nodejs docker-registry-username/ubuntu-nodejs

A continuación, podrá hacer el push de su propia imagen usando:

    docker push docker-registry-username/docker-image-name

Para hacer el push de la imagen `ubuntu-nodejs` al repositorio de **sammy** , el comando sería:

    docker push sammy/ubuntu-nodejs

Es posible que el proceso tarde un poco para terminarse a medida que se cargan las imágenes, pero una vez que se haya terminado, el resultado se verá así:

    OutputThe push refers to a repository [docker.io/sammy/ubuntu-nodejs]
    e3fbbfb44187: Pushed
    5f70bf18a086: Pushed
    a3b5c80a4eba: Pushed
    7f18b442972b: Pushed
    3ce512daaf78: Pushed
    7aae4540b42d: Pushed
    
    ...
    
    

Tras hacer push de una imagen al registro, debería aparecer en el panel de su cuenta, como se muestra en la imagen de abajo.

![Nuevo listado de imágenes de Docker en Docker Hub](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_1804/ec2vX3Z.png)

Si un intento de push le da un error de este tipo, seguramente no haya iniciado sesión:

    OutputThe push refers to a repository [docker.io/sammy/ubuntu-nodejs]
    e3fbbfb44187: Preparing
    5f70bf18a086: Preparing
    a3b5c80a4eba: Preparing
    7f18b442972b: Preparing
    3ce512daaf78: Preparing
    7aae4540b42d: Waiting
    unauthorized: authentication required

Inicie sesión usando el `docker login` y vuelva a intentar el push. Entonces, verifique que exista en su página del repositorio de Docker Hub.

Ahora puede usar `docker pull sammy/ubuntu-nodejs` para hacer el pull de la imagen a una nueva máquina y usarla para ejecutar un contenedor nuevo.

## Conclusión

Con este tutorial, instaló Docker, trabajó con imágenes y contenedores e hizo push de una imagen modificada a Docker Hub. Ahora que sabe cuáles son los conceptos básicos, examine los [demás tutoriales de Docker](https://www.digitalocean.com/community/tags/docker?type=tutorials) en la Comunidad de DigitalOcean.
