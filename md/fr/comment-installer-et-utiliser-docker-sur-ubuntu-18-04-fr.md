---
author: Brian Hogan
date: 2019-04-26
language: fr
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/comment-installer-et-utiliser-docker-sur-ubuntu-18-04-fr
---

# Comment installer et utiliser Docker sur Ubuntu 18.04

_Une version précédente de ce tutoriel a été rédigée par [finid](https://www.digitalocean.com/community/users/finid)._

## Introduction

[Docker](https://www.docker.com/) est une application qui simplifie le processus de gestion des processus d'application dans les _containers_ (conteneurs). Les conteneurs vous permettent d'exécuter vos applications dans des processus isolés des ressources. Ils sont similaires aux machines virtuelles, mais les conteneurs sont plus portables, plus respectueux des ressources et plus dépendants du système d'exploitation hôte.

Pour une introduction détaillée aux différents composants d'un conteneur Docker, consultez [L'écosystème Docker: Introduction aux composants communs](the-docker-ecosystem-an-introduction%20-to-common-components).

Dans ce tutoriel, vous allez installer et utiliser Docker Community Edition (CE) sur Ubuntu 18.04. Vous installerez Docker lui-même, travaillerez avec des conteneurs et des images, puis transmettrez une image dans un référentiel Docker.

## Conditions préalables

Pour suivre ce tutoriel, vous aurez besoin des éléments suivants:

- Un serveur Ubuntu 18.04 configuré en suivant le [Guide de configuration initiale du serveur Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04), y compris un utilisateur sudo non root et un pare-feu.
- Un compte sur [Docker Hub](https://hub.docker.com/) si vous souhaitez créer vos propres images et les transmettre au Docker Hub, comme indiqué aux étapes 7 et 8.

## Étape 1 — Installation de Docker

Le package d'installation de Docker disponible dans le référentiel officiel Ubuntu peut ne pas être la version la plus récente. Pour s’assurer d'obtenir la version la plus récente, nous installerons Docker à partir du référentiel officiel de Docker. Pour ce faire, nous allons ajouter une nouvelle source de paquet, ajouter la clé GPG de Docker pour garantir la validité des téléchargements, puis installer le paquet.

Commencez par mettre à jour votre liste de paquets existante:

    sudo apt update

Ensuite, installez quelques paquets pré-requis qui permettent à ʻapt` d'utiliser les paquets via HTTPS:

    sudo apt install apt-transport-https ca-certificates curl software-properties-common

Ajoutez ensuite la clé GPG du référentiel Docker officiel à votre système:

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

Ajoutez le référentiel Docker aux sources APT:

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

Ensuite, mettez à jour la base de données de paquets avec les paquets Docker du référentiel récemment ajouté:

    sudo apt update

Assurez-vous que vous êtes sur le point d'installer à partir du référentiel Docker au lieu du référentiel par défaut Ubuntu:

    apt-cache policy docker-ce

Vous verrez une sortie de données comme celle-ci, même si le numéro de version de Docker peut être différent:

Output of apt-cache policy docker-ce

    docker-ce:
      Installed: (none)
      Candidate: 18.03.1~ce~3-0~ubuntu
      Version table:
         18.03.1~ce~3-0~ubuntu 500
            500 https://download.docker.com/linux/ubuntu bionic/stable amd64 Packages

Notez que `docker-ce` n'est pas installé, mais que le candidat à l'installation provient du référentiel Docker pour Ubuntu 18.04 (`bionic`).

Finalement, installez Docker:

    sudo apt install docker-ce

Docker devrait maintenant être installé, le démo n démarré et le processus activé pour pouvoir partir au démarrage. Vérifiez qu'il est en cours d'exécution:

    sudo systemctl status docker

La sortie de données devrait être semblable à celle-ci, montrant que le service est actif et en cours d'exécution:

    Output● docker.service - Docker Application Container Engine
       Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
       Active: active (running) since Thu 2018-07-05 15:08:39 UTC; 2min 55s ago
         Docs: https://docs.docker.com
     Main PID: 10096 (dockerd)
        Tasks: 16
       CGroup: /system.slice/docker.service
               ├─10096 /usr/bin/dockerd -H fd://
               └─10113 docker-containerd --config /var/run/docker/containerd/containerd.toml

L'installation de Docker vous donne maintenant non seulement le service Docker (démon), mais également l'utilitaire de ligne de commande `docker` ou le client Docker. Nous verrons comment utiliser la commande `docker` plus tard dans ce tutoriel.

## Étape 2 — Exécution de la commande Docker sans Sudo (optionnel)

Par défaut, la commande `docker` ne peut être exécutée que par l'utilisateur **root** ou par un utilisateur du groupe **docker** , créé automatiquement lors du processus d'installation de Docker. Si vous essayez d'exécuter la commande `docker` sans la préfixer avec `sudo` ou sans faire partie du groupe **docker** , vous obtiendrez une sortie de données comme celle-ci:

    Outputdocker: Cannot connect to the Docker daemon. Is the docker daemon running on this host?.
    See 'docker run --help'.

Si vous voulez éviter de taper `sudo` chaque fois que vous exécutez la commande `docker`, ajoutez votre nom d'utilisateur au groupe `docker`:

    sudo usermod -aG docker ${USER}

Pour appliquer la nouvelle appartenance à un groupe, déconnectez-vous du serveur et reconnectez-vous, ou tapez ce qui suit:

    su - ${USER}

Vous serez invité à entrer le mot de passe de votre utilisateur pour continuer.

Confirmez que votre utilisateur est maintenant ajouté au groupe **docker** en tapant:

    id -nG

    Outputsammy sudo docker

Si vous devez ajouter un utilisateur au groupe `docker` auquel vous n'êtes pas connecté, déclarez explicitement ce nom d'utilisateur en utilisant:

    sudo usermod -aG docker username

Le reste de cet article suppose que vous exécutez la commande `docker` en tant qu'utilisateur du groupe **docker**. Si vous choisissez de ne pas le faire, veuillez ajouter `sudo` en avant des commandes.

Explorons la commande `docker` ensuite.

## Étape 3 — Utilisation de la commande Docker

Utiliser `docker` consiste à lui transmettre une chaîne d'options et de commandes suivie d'arguments. La syntaxe prend cette forme:

    docker [option] [command] [arguments]

Pour afficher toutes les sous-commandes disponibles, tapez:

    docker

A partir de Docker 18, la liste complète des sous-commandes disponibles comprend:

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

Voici chaque sous-commande décrite en français pour but de compréhension:

    Output
      attach Attachez les flux standard locaux d'entrée et de sortie de données et d'erreur à un conteneur en cours d'exécution
      build Construire une image à partir d'un fichier Docker
      commit Créer une nouvelle image à partir des modifications d'un conteneur
      cp Copier des fichiers / dossiers entre un conteneur et le système de fichiers local
      create Créer un nouveau conteneur
      diff Inspecter les modifications apportées aux fichiers ou aux répertoires du système de fichiers d'un conteneur
      events Obtenir des événements en temps réel du serveur
      exec Exécuter une commande dans un conteneur en cours d'exécution
      export Exporter le système de fichiers d'un conteneur en tant qu'archive tar
      history Afficher l'historique d'une image
      images Lister les images
      import Importer le contenu d'une archive pour créer une image de système de fichiers
      info Afficher des informations à l'échelle du système
      inspect Renvoyer des informations de bas niveau sur les objets Docker
      kill Tuer un ou plusieurs conteneurs en cours d'exécution
      load Charger une image depuis une archive tar ou STDIN
      login Connectez-vous à un registre Docker
      logout Déconnectez-vous d’un registre Docker
      logs Récupérer les journaux d'un conteneur
      pause Suspendre tous les processus dans un ou plusieurs conteneurs
      port Répertorier les mappages de ports ou un mappage spécifique pour le conteneur
      ps Lister les conteneurs
      pull Extraire une image ou un référentiel d'un registre
      push Transmettre une image ou un référentiel dans un registre
      rename Renommer un conteneur
      restart Redémarrer un ou plusieurs conteneurs
      rm Retirer un ou plusieurs conteneurs
      rmi Supprimer une ou plusieurs images
      run Exécuter une commande dans un nouveau conteneur
      save Enregistrer une ou plusieurs images dans une archive tar (transmise par défaut à STDOUT)
      search Recherchez des images dans le hub Docker
      start Démarrer un ou plusieurs conteneurs arrêtés
      stats Afficher un flux en direct des statistiques d'utilisation des ressources du ou des conteneurs
      stop Arrêtez un ou plusieurs conteneurs en cours d'exécution
      tag Créez une balise TARGET_IMAGE qui fait référence à SOURCE_IMAGE
      top Afficher les processus en cours d'un conteneur
      unpause Annuler la suspension de tous les processus dans un ou plusieurs conteneurs
      update Mettre à jour la configuration d'un ou plusieurs conteneurs
      version Afficher les informations de la version de Docker
      wait Bloquez jusqu'à ce qu'un ou plusieurs conteneurs s'arrêtent, puis imprimez leurs codes de sortie

Pour afficher les options disponibles pour une commande spécifique, tapez:

    docker docker-subcommand --help

Pour afficher des informations sur Docker à l’échelle du système, utilisez:

    docker info

Explorons certaines de ces commandes. Nous allons commencer par travailler avec des images.

## Étape 4 — Utilisation des images Docker

Les conteneurs Docker sont construits à partir d'images Docker. Par défaut, Docker extrait ces images de [Docker Hub](https://hub.docker.com), un registre Docker géré par Docker, la société à l'origine du projet Docker. Tout le monde peut héberger ses images Docker sur Docker Hub. Ainsi, la plupart des applications et des distributions Linux dont vous aurez besoin auront des images hébergées ici.

Pour vérifier si vous pouvez accéder aux images et les télécharger à partir de Docker Hub, tapez:

    docker run hello-world

La sortie de données indiquera que Docker fonctionne correctement:

    OutputUnable to find image 'hello-world:latest' locally
    latest: Pulling from library/hello-world
    9bb5a5d4561a: Pull complete
    Digest: sha256:3e1764d0f546ceac4565547df2ac4907fe46f007ea229fd7ef2718514bcec35d
    Status: Downloaded newer image for hello-world:latest
    
    Hello from Docker!
    This message shows that your installation appears to be working correctly.
    ...

Docker n'a pas pu trouver initialement l'image `hello-world` localement. Il a donc téléchargé l'image à partir de Docker Hub, le référentiel par défaut. Une fois l'image téléchargée, Docker a créé un conteneur à partir de l'image et de l'application exécutée dans le conteneur, affichant le message.

Vous pouvez rechercher des images disponibles sur Docker Hub en utilisant la commande `docker` avec la sous-commande `search`. Par exemple, pour rechercher l'image Ubuntu, tapez:

    docker search ubuntu

Le script analysera Docker Hub et renverra une liste de toutes les images dont le nom correspond à la chaîne de recherche. Dans ce cas, le résultat sera similaire à ceci:

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
    

Dans la colonne **OFFICIAL** , **OK** indique une image construite et prise en charge par la société derrière le projet. Une fois que vous avez identifié l'image que vous souhaitez utiliser, vous pouvez la télécharger sur votre ordinateur à l'aide de la sous-commande `pull`.

Exécutez la commande suivante pour télécharger l’image officielle `ubuntu` sur votre ordinateur:

    docker pull ubuntu

Vous verrez la sortie de données suivante:

    OutputUsing default tag: latest
    latest: Pulling from library/ubuntu
    6b98dfc16071: Pull complete
    4001a1209541: Pull complete
    6319fc68c576: Pull complete
    b24603670dc3: Pull complete
    97f170c87c6f: Pull complete
    Digest: sha256:5f4bdc3467537cbbe563e80db2c3ec95d548a9145d64453b06939c4592d67b6d
    Status: Downloaded newer image for ubuntu:latest

Après le téléchargement d’une image, vous pouvez ensuite exécuter un conteneur en utilisant l’image téléchargée avec la sous-commande `run`. Comme vous l'avez vu avec l'exemple `hello-world`, si une image n'a pas été téléchargée lorsque`docker` est exécuté avec la sous-commande `run`, le client Docker télécharge d'abord l'image, puis exécute un conteneur en l'utilisant.

Pour voir les images téléchargées sur votre ordinateur, tapez:

    docker images

La sortie de données devrait ressembler à ceci:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    ubuntu latest 113a43faa138 4 weeks ago 81.2MB
    hello-world latest e38bc07ac18e 2 months ago 1.85kB

Comme vous le verrez plus loin dans ce tutoriel, les images que vous utilisez pour exécuter des conteneurs peuvent être modifiées et utilisées pour générer de nouvelles images, qui peuvent ensuite être transmises (_pushed_ est le terme technique) vers Docker Hub ou d'autres registres Docker.

Voyons comment exécuter les conteneurs plus en détail.

## Étape 5 — Exécuter un conteneur Docker

Le conteneur `hello-world` que vous avez exécuté à l'étape précédente est un exemple de conteneur qui s'exécute et se ferme après avoir émis un message de test. Les conteneurs peuvent être beaucoup plus utiles que cela, et ils peuvent être interactifs. Après tout, ils ressemblent aux machines virtuelles, mais ils sont plus conviviaux.

Par exemple, exécutons un conteneur en utilisant la dernière image d'Ubuntu. La combinaison des commutateurs **-i** et **-t** vous donne un accès interactif au shell dans le conteneur:

    docker run -it ubuntu

Votre invite de commande devrait changer pour refléter le fait que vous travaillez maintenant dans le conteneur et devrait prendre la forme suivante:

    Outputroot@d9b100f2f636:/#

Notez l'ID de conteneur dans l'invite de commande. Dans cet exemple, il s'agit de `d9b100f2f636`. Vous aurez besoin de cet ID de conteneur plus tard pour identifier le conteneur lorsque vous souhaitez le supprimer.

Vous pouvez maintenant exécuter n’importe quelle commande dans le conteneur. Par exemple, mettons à jour la base de données de paquets à l'intérieur du conteneur. Vous n'avez pas besoin de préfixer n'importe quelle commande avec `sudo` car vous opérez dans le conteneur en tant qu'utilisateur **root** :

    apt update

Ensuite, installez n'importe quelle application. Installons Node.js:

    apt install nodejs

Cela installe Node.js dans le conteneur à partir du référentiel officiel Ubuntu. Lorsque l'installation est terminée, vérifiez que Node.js est installé:

    node -v

Vous verrez le numéro de version affiché sur votre terminal:

    Outputv8.10.0

Toutes les modifications que vous apportez à l'intérieur du conteneur s'appliquent uniquement à ce conteneur.

Pour quitter le conteneur, tapez `exit` à l'invite.

Voyons maintenant comment gérer les conteneurs sur notre système.

## Étape 6 — Gestion des conteneurs Docker

Après avoir utilisé Docker pendant un moment, vous aurez de nombreux conteneurs actifs (en cours d'exécution) et inactifs sur votre ordinateur. Pour voir les **active ones** (conteneurs actifs), utilisez:

    docker ps

Vous verrez une sortie de données semblable à celle-ci:

    OutputCONTAINER ID IMAGE COMMAND CREATED             

Dans ce tutoriel, vous avez démarré deux conteneurs. un de l'image `hello-world` et un autre de l'image`ubuntu`. Les deux conteneurs ne sont plus en cours d’exécution, mais ils existent toujours sur votre système.

Pour afficher tous les conteneurs — actifs et inactifs, exécutez `docker ps` avec le commutateur `-a`:

    docker ps -a

Vous verrez une sortie de données semblable à celle-ci:

    d9b100f2f636 ubuntu "/bin/bash" About an hour ago Exited (0) 8 minutes ago sharp_volhard
    01c950718166 hello-world "/hello" About an hour ago Exited (0) About an hour ago festive_williams
    

Pour afficher le dernier conteneur que vous avez créé, transmettez-le au commutateur `-l`:

    docker ps -l

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    d9b100f2f636 ubuntu "/bin/bash" About an hour ago Exited (0) 10 minutes ago sharp_volhard

Pour démarrer un conteneur arrêté, utilisez `docker start`, suivi de l'ID du conteneur ou du nom du conteneur. Démarrons le conteneur basé sur Ubuntu avec l'ID de `d9b100f2f636`:

    docker start d9b100f2f636

Le conteneur va démarrer et vous pouvez utiliser `docker ps` pour voir son statut:

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    d9b100f2f636 ubuntu "/bin/bash" About an hour ago Up 8 seconds sharp_volhard
    

Pour arrêter un conteneur en cours d'exécution, utilisez `docker stop`, suivi de l'ID ou du nom du conteneur. Cette fois-ci, nous utiliserons le nom que Docker a attribué au conteneur, qui est `sharp_volhard`:

    docker stop sharp_volhard

Une fois que vous avez décidé que vous n'avez plus besoin d'un conteneur, supprimez-le à l'aide de la commande `docker rm` en utilisant à nouveau l'ID du conteneur ou son nom. Utilisez la commande `docker ps -a` pour trouver l'ID ou le nom du conteneur associé à l'image `hello-world` et supprimez-le.

    docker rm festive_williams

Vous pouvez démarrer un nouveau conteneur et lui donner un nom en utilisant le commutateur `--name`. Vous pouvez également utiliser le commutateur `--rm` pour créer un conteneur qui se supprime tout seul lorsqu'il est arrêté. Voir la commande `docker run help` pour plus d'informations sur ces options ainsi que d'autres.

Les conteneurs peuvent être transformés en images que vous pouvez utiliser pour créer de nouveaux conteneurs. Regardons comment cela fonctionne.

## Étape 7 — Valider des changements dans un conteneur à une image Docker

Lorsque vous démarrez une image Docker, vous pouvez créer, modifier et supprimer des fichiers comme vous le pouvez avec une machine virtuelle. Les modifications que vous apportez ne s'appliqueront qu'à ce conteneur. Vous pouvez le démarrer et l'arrêter, mais une fois que vous l'avez détruit avec la commande `docker rm`, les modifications seront définitivement perdues.

Cette section explique comment enregistrer l'état d'un conteneur en tant que nouvelle image Docker.

Après avoir installé Node.js dans le conteneur Ubuntu, vous disposez maintenant d’un conteneur exécutant une image, mais le conteneur est différent de l’image que vous avez utilisée pour la créer. Mais vous voudrez peut-être réutiliser ce conteneur Node.js comme base pour de nouvelles images plus tard.

Puis validez les modifications dans une nouvelle instance d'image Docker à l'aide de la commande suivante.

    docker commit -m "What you did to the image" -a "Author Name" container_id repository/new_image_name

Le commutateur **-m** est destiné au message de validation qui vous aide, vous et les autres, à savoir les modifications que vous avez apportées, tandis que **-a** est utilisé pour spécifier l'auteur. Le `container_id` (ID du conteneur) est celui que vous avez noté précédemment dans le tutoriel lorsque vous avez démarré la session interactive de Docker. Sauf si vous avez créé des référentiels supplémentaires sur Docker Hub, le `repository` est généralement votre nom d'utilisateur Docker Hub.

Par exemple, pour l'utilisateur **sammy** , avec l'ID de conteneur `d9b100f2f636`, la commande serait:

    docker commit -m "added Node.js" -a "sammy" d9b100f2f636 sammy/ubuntu-nodejs

Lorsque vous _commit_ (validez) une image, la nouvelle image est enregistrée localement sur votre ordinateur. Plus loin dans ce tutoriel, vous apprendrez à transmettre une image dans un registre Docker tel que Docker Hub afin que d'autres personnes puissent y accéder.

En répertoriant à nouveau les images Docker, vous verrez apparaître la nouvelle image, ainsi que l’ancienne dont elle est issue:

    docker images

Vous verrez une sortie de données comme ceci:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    sammy/ubuntu-nodejs latest 7c1f35226ca6 7 seconds ago 179MB
    ubuntu latest 113a43faa138 4 weeks ago 81.2MB
    hello-world latest e38bc07ac18e 2 months ago 1.85kB
    

Dans cet exemple, `ubuntu-nodejs` est la nouvelle image, dérivée de l'image `ubuntu` existante de Docker Hub. La différence de taille reflète les modifications apportées et, dans cet exemple, le changement était que NodeJS était installé. Ainsi, la prochaine fois que vous devrez exécuter un conteneur en utilisant Ubuntu avec NodeJS pré-installé, vous pourrez simplement utiliser la nouvelle image.

Vous pouvez également créer des images à partir d'un `Dockerfile`, ce qui vous permet d'automatiser l'installation de logiciels dans une nouvelle image. Cependant, cela sort du cadre de ce tutoriel.

Partageons maintenant la nouvelle image avec d'autres personnes afin qu'elles puissent créer des conteneurs à partir de celle-ci.

## Étape 8 — Transmettre des images Docker vers un référentiel Docker

La prochaine étape logique après la création d'une nouvelle image à partir d'une image existante consiste à la partager avec quelques amis, le monde entier sur Docker Hub ou un autre registre Docker auquel vous avez accès. Pour envoyer une image vers Docker Hub ou tout autre registre Docker, vous devez avoir un compte là-bas.

Cette section explique comment transmettre une image Docker vers le hub Docker. Pour apprendre à créer votre propre registre privé Docker, consultez [Comment configurer un registre privé Docker sur Ubuntu 14.04](how-to-set-up-a%20-private-docker-registry-on-ubuntu-14-04).

Pour transmettre votre image, connectez-vous d'abord à Docker Hub.

    docker login -u docker-registry-username

Vous serez invité à vous authentifier à l'aide de votre mot de passe Docker Hub. Si vous avez spécifié le mot de passe correct, l'authentification devrait réussir.

**Note:** Si votre nom d'utilisateur de registre Docker est différent du nom d'utilisateur local que vous avez utilisé pour créer l'image, vous devrez marquer votre image avec votre nom d'utilisateur de registre. Pour l'exemple donné à la dernière étape, vous devez taper:

    docker tag sammy/ubuntu-nodejs docker-registry-username/ubuntu-nodejs

Ensuite, vous pouvez transmettre votre propre image en utilisant:

    docker push docker-registry-username/docker-image-name

Pour transmettre l'image `ubuntu-nodejs` au référentiel **sammy** , la commande serait la suivante:

    docker push sammy/ubuntu-nodejs

Le processus peut prendre un certain temps à mesure qu'il télécharge les images, mais une fois terminé, le résultat ressemblera à ceci:

    OutputThe push refers to a repository [docker.io/sammy/ubuntu-nodejs]
    e3fbbfb44187: Pushed
    5f70bf18a086: Pushed
    a3b5c80a4eba: Pushed
    7f18b442972b: Pushed
    3ce512daaf78: Pushed
    7aae4540b42d: Pushed
    ...

Après avoir transmis une image dans un registre, celle-ci doit être répertoriée dans le tableau de bord de votre compte, comme indiqué dans l'image ci-dessous.

![Nouvelle liste d'images Docker sur Docker Hub](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_1804/ec2vX3Z.png)

Si une tentative de transmission entraîne une erreur de ce type, vous ne vous êtes probablement pas connecté:

    OutputThe push refers to a repository [docker.io/sammy/ubuntu-nodejs]
    e3fbbfb44187: Preparing
    5f70bf18a086: Preparing
    a3b5c80a4eba: Preparing
    7f18b442972b: Preparing
    3ce512daaf78: Preparing
    7aae4540b42d: Waiting
    unauthorized: authentication required

Connectez-vous avec `login docker` et répétez la tentative de transmission. Ensuite, vérifiez qu'il existe sur votre page de référentiel Docker Hub.

Vous pouvez maintenant utiliser `docker pull sammy/ubuntu-nodejs` pour extraire l'image et l’envoyer sur une nouvelle machine et l'utiliser pour exécuter un nouveau conteneur.

## Conclusion

Dans ce tutoriel, vous avez installé Docker, travaillé avec des images et des conteneurs, puis transmis une image modifiée à Docker Hub. Maintenant que vous connaissez les bases, explorez les [autres tutoriels Docker](https://www.digitalocean.com/community/tags/docker?type=tutorials) de la communauté DigitalOcean.
