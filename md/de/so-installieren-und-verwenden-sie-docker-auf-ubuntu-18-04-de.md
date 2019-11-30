---
author: Brian Hogan
date: 2019-04-25
language: de
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/so-installieren-und-verwenden-sie-docker-auf-ubuntu-18-04-de
---

# So installieren und verwenden Sie Docker auf Ubuntu 18.04

_Eine Vorgängerversion dieses Tutorials wurde von [finid](https://www.digitalocean.com/community/users/finid) verfasst._

### Einführung

[Docker](https://www.docker.com/) ist eine Applikation, die den Verwaltungsvorgang von Applikationsprozessen in _Containern_ vereinfacht. Mit Containern können Sie Ihre Anwendungen in ressourcenisolierten Prozessen ausführen. Container ähneln virtuellen Maschinen, sind jedoch portabler, ressourcenschonender und stärker vom Host-Betriebssystem abhängig.

Eine detaillierte Einführung in die verschiedenen Komponenten eines Docker-Containers finden Sie im [Docker-Ökosystem: Eine Einführung in die gängigen Komponenten](the-docker-ecosystem-an-introduction-to-common-components).

In diesem Tutorial installieren und verwenden Sie die Docker Gemeinschaftsedition (CE) auf Ubuntu 18.04. Sie installieren Docker selbst, arbeiten mit Containern und Bildern und verschieben ein Bild in ein Docker-Repository.

## Voraussetzungen

Um diesem Tutorial folgen zu können, benötigen Sie Folgendes:

- Ein Ubuntu 18.04-Server, der gemäß dem [Installationshandbuch von Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) eingerichtet wurde, einschließlich eines nicht root-basierten sudo-Benutzers und einer Firewall.
- Ein Benutzerkonto auf [Docker Hub](https://hub.docker.com/), wenn Sie Ihre eigenen Bilder erstellen und auf Docker Hub verschieben möchten, wie in Schritt 7 und 8 dargestellt wird. 

## Schritt 1 — Docker installieren

Das im offiziellen Ubuntu-Repository verfügbare Docker-Installationspaket ist möglicherweise nicht die neueste Version. Um sicherzugehen, dass wir die neueste Version erhalten, installieren wir Docker aus dem offiziellen Docker-Repository. Dazu fügen wir eine neue Paketquelle und den GPG-Schlüssel von Docker hinzu, um sicherzustellen, dass die Downloads gültig sind, woraufhin wir das Paket installieren.

Aktualisieren Sie zunächst Ihre vorhandene Paketliste:

    sudo apt update

Als nächstes installieren Sie ein paar Voraussetzungpakete, mit denen `apt` Pakete über HTTPS verwenden kann:

    sudo apt install apt-transport-https ca-certificates curl software-properties-common

Fügen Sie dann den GPG-Schlüssel für das offizielle Docker-Repository zu Ihrem System hinzu:

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

Fügen Sie das Docker-Repository zu den APT-Quellen hinzu:

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

Aktualisieren Sie anschließend die Paketdatenbank mit den Docker-Paketen aus dem neu hinzugefügten Repo:

    sudo apt update

Stellen Sie sicher, dass Sie die Installation aus dem Docker-Repo statt aus dem standardmäßigen Ubuntu-Repo durchführen:

    apt-cache policy docker-ce

Sie werden die folgende Meldung sehen, obwohl die Versionsnummer für Docker unterschiedlich sein kann:

Output of apt-cache policy docker-ce

    docker-ce:
      Installed: (none)
      Candidate: 18.03.1~ce~3-0~ubuntu
      Version table:
         18.03.1~ce~3-0~ubuntu 500
            500 https://download.docker.com/linux/ubuntu bionic/stable amd64 Packages

Beachten Sie, dass `docker-ce` nicht installiert ist, aber der Installationskandidat aus dem Docker-Repository für Ubuntu 18.04 (`bionic`) stammt.

Installieren Sie schließlich den Docker:

    sudo apt install docker-ce

Docker sollte nun installiert, der Daemon sowie der Prozess beim Booten gestartet werden. Überprüfen Sie, ob es funktioniert:

    sudo systemctl status docker

Die Meldung sollte wie folgt aussehen und zeigen, dass der Dienst aktiv ist und läuft:

    Output● docker.service - Docker Application Container Engine
       Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
       Active: active (running) since Thu 2018-07-05 15:08:39 UTC; 2min 55s ago
         Docs: https://docs.docker.com
     Main PID: 10096 (dockerd)
        Tasks: 16
       CGroup: /system.slice/docker.service
               ├─10096 /usr/bin/dockerd -H fd://
               └─10113 docker-containerd --config /var/run/docker/containerd/containerd.toml

Die Installation von Docker gibt Ihnen nun nicht nur den Docker-Dienst (Daemon), sondern auch das `docker` -Befehlszeilenprogramm oder den Docker-Client. Später in diesem Tutorial untersuchen wir, wie der `docker` -Befehl angewandt wird.

## Schritt 2 — Ausführen des Docker-Befehls ohne Sudo (optional)

Standardmäßig kann der `docker` -Befehl nur für den **Root** -Benutzer oder von einem Benutzer der **Docker** -Gruppe ausgeführt werden, die während des Installationsprozesses von Docker automatisch erstellt wird. Wenn Sie versuchen, den `docker` -Befehl auszuführen, ohne ihn mit `sudo` voranzustellen oder in der **Docker** -Gruppe zu sein, erhalten Sie folgende Meldung:

    Outputdocker: Cannot connect to the Docker daemon. Is the docker daemon running on this host?.
    See 'docker run --help'.

Wenn die Eingabe von `sudo` bei jeder Ausführung des `docker` -Befehls vermieden werden soll, fügen Sie Ihren Benutzernamen zur `docker` -Gruppe hinzu:

    sudo usermod -aG docker ${USER}

Um die neue Gruppenzugehörigkeit anzuwenden, melden Sie sich vom Server ab und wieder an, oder geben Sie Folgendes ein:

    su - ${USER}

Zum Fortfahren werden Sie aufgefordert, das Passwort Ihres Benutzers einzugeben.

Bestätigen Sie, dass Ihr Benutzer der **Docker** -Gruppe hinzugefügt wurde, indem Sie folgendes tippen:

    id -nG

    Outputsammy sudo docker

Wenn Sie einen Benutzer zur `docker` -Gruppe hinzufügen möchten, mit dem Sie nicht angemeldet sind, geben Sie diesen Benutzernamen explizit mit an:

    sudo usermod -aG docker username

Der Rest dieses Artikels geht davon aus, dass Sie den `docker` -Befehl als Benutzer in der **Docker** -Gruppe ausführen. Wenn Sie sich dagegen entscheiden, fügen Sie die Befehle bitte mit `sudo` durch.

Als nächstes erkunden wir den `docker` -Befehl.

## Schritt 3 — Verwendung des Docker-Befehls

Die Verwendung des `docker` besteht darin, ihm eine Reihe von Optionen und Befehlen mit anschließender Argumentation zu übermitteln. Die Syntax hat folgende Form:

    docker [option] [command] [arguments]

Zum Anzeigen aller verfügbaren Unterbefehle, geben Sie Folgendes ein:

    docker

Ab Docker 18 enthält die vollständige Liste der verfügbaren Unterbefehle:

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

Für die Anzeige verfügbarer Optionen eines bestimmten Befehls, geben Sie Folgendes ein:

    docker docker-subcommand --help

Um systemweite Informationen über Docker anzuzeigen, verwenden Sie:

    docker info

Untersuchen wir einige dieser Befehle. Wir beginnen mit der Bildarbeit.

## Schritt 4 — Arbeiten mit Docker-Bildern

Docker-Container werden aus Docker-Bildern erstellt. Standardmäßig bezieht Docker diese Bilder aus dem [Docker Hub](https://hub.docker.com), einem Docker-Verzeichnis, das von Docker, der Firma hinter dem Docker-Projekt, verwaltet wird. Jeder kann seine Docker-Bilder auf dem Docker Hub hosten, so dass die meisten Applikationen und Linux-Distributionen, die Sie benötigen, über Bilder verfügen, die dort bereitgestellt werden.

Um zu überprüfen, ob Sie auf Bilder vom Docker Hub zugreifen und sie herunterladen können, geben Sie Folgendes ein:

    docker run hello-world

Die Meldung zeigt an, dass Docker korrekt funktioniert:

    OutputUnable to find image 'hello-world:latest' locally
    latest: Pulling from library/hello-world
    9bb5a5d4561a: Pull complete
    Digest: sha256:3e1764d0f546ceac4565547df2ac4907fe46f007ea229fd7ef2718514bcec35d
    Status: Downloaded newer image for hello-world:latest
    
    Hello from Docker!
    This message shows that your installation appears to be working correctly.
    ...

Docker konnte das `hello-world` -Bild zunächst nicht lokalisieren, so dass es das Bild vom Docker Hub, dem Standard-Repository, heruntergeladen hat. Nach dem Herunterladen des Bildes, erstellte Docker einen Container aus dem Bild und der Applikation innerhalb des ausgeführten Containers, der die Nachricht anzeigt.

Sie können nach Bildern suchen, die auf dem Docker Hub verfügbar sind, indem Sie den `docker` -Befehl mit dem Unterbefehl `search` verwenden. Geben Sie beispielsweise für die Suche nach dem Ubuntu-Bild folgendes ein:

    docker search ubuntu

Das Skript durchsucht den Docker Hub und gibt eine Liste aller Bilder zurück, deren Name mit dem Suchbegriff übereinstimmt. In diesem Fall sieht die Meldung wie folgt aus:

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
    

In der Spalte **OFFICIAL** kennzeichnet **OK** ein Bild, das von dem Unternehmen hinter dem Projekt erstellt und unterstützt wird. Sobald Sie das Bild identifiziert haben, das Sie verwenden möchten, können Sie es mit dem Unterbefehl `pull` auf Ihren Computer herunterladen.

Führen Sie den folgenden Befehl aus, um das offizielle `ubuntu`-Bild auf Ihren Computer herunterzuladen:

    docker pull ubuntu

Sie sehen folgende Meldung:

    OutputUsing default tag: latest
    latest: Pulling from library/ubuntu
    6b98dfc16071: Pull complete
    4001a1209541: Pull complete
    6319fc68c576: Pull complete
    b24603670dc3: Pull complete
    97f170c87c6f: Pull complete
    Digest: sha256:5f4bdc3467537cbbe563e80db2c3ec95d548a9145d64453b06939c4592d67b6d
    Status: Downloaded newer image for ubuntu:latest

Nach dem Herunterladen eines Bildes, können Sie mit dem Unterbefehl `run` einen Container mit dem heruntergeladenen Bild ausführen. Wie Sie im `hello-world` -Beispiel gesehen haben, wenn ein Bild nicht heruntergeladen wurde und `docker` mit dem Unterbefehl `run` gestartet wird, lädt der Docker-Client zuerst das Bild herunter und verwendet es dann als Container.

Um die Bilder anzuzeigen, die auf Ihren Computer heruntergeladen wurden, geben Sie Folgendes ein:

    docker images

Die Meldung sollte wie folgt aussehen:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    ubuntu latest 113a43faa138 4 weeks ago 81.2MB
    hello-world latest e38bc07ac18e 2 months ago 1.85kB

Wie Sie später in diesem Tutorial sehen werden, können Bilder, die Sie zum Ausführen von Containern verwenden, modifiziert und zum Erzeugen neuer Bilder verwendet werden, die dann in den Docker Hub oder andere Docker-Verzeichnisse hochgeladen werden können (_pushed_ ist der Fachbegriff).

Schauen wir uns genauer an, wie Container ausgeführt werden können.

## Schritt 5 — Ausführen eines Docker-Containers

Der `hello-world` -Container, den Sie im vorigen Schritt ausgeführt haben, ist ein Beispiel für einen Container, der nach dem Senden einer Testnachricht läuft und beendet wird. Container können viel nützlicher sein als das, und sie können auch interaktiv sein. Schließlich sind sie ähnlich wie virtuelle Maschinen, nur ressourcenschonender.

Betrachten wir als Beispiel einen Container mit dem neuesten Bild von Ubuntu. Die Kombination der Schalter **-i** und **-t** ermöglicht Ihnen den interaktiven Shell-Zugriff auf den Container:

    docker run -it ubuntu

Die Eingabeaufforderung sollte sich entsprechend der Tatsache ändern, dass Sie nun innerhalb des Containers arbeiten, und sollte diese Form annehmen:

    Outputroot@d9b100f2f636:/#

Notieren Sie sich die Container-ID in der Eingabeaufforderung. In diesem Beispiel ist es `d9b100f2f636`. Sie benötigen diese Container-ID später, zum Identifizieren des Containers, wenn Sie ihn entfernen möchten.

Jetzt können Sie jeden beliebigen Befehl innerhalb des Containers ausführen. Aktualisieren wir zum Beispiel die Paketdatenbank im Container. Sie müssen keinen Befehl mit `sudo` voranstellen, da Sie innerhalb des Containers als **Root** -Benutzer arbeiten:

    apt update

Installieren Sie dann eine beliebige Applikation darin. Installieren wir Node.js:

    apt install nodejs

Node.js wird dann im Container aus dem offiziellen Ubuntu-Repository installiert. Wenn die Installation abgeschlossen ist, überprüfen Sie, ob Node.js installiert ist:

    node -v

Die Versionsnummer wird in Ihrem Terminal angezeigt:

    Outputv8.10.0

Alle Änderungen, die Sie innerhalb des Containers vornehmen, gelten nur für diesen Container.

Um den Container zu verlassen, geben Sie im Eingabefeld `exit` ein.

Als nächstes wollen wir uns die Verwaltung der Container auf unserem System ansehen.

## Schritt 6 — Verwalten von Docker-Containern

Nachdem Sie Docker eine Weile benutzt haben, haben Sie viele aktive (laufende) und inaktive Container auf Ihrem Computer. Um die **active ones** anzuzeigen, verwenden Sie:

    docker ps

Sie werden die folgende Meldung sehen:

    OutputCONTAINER ID IMAGE COMMAND CREATED             
    

In diesem Tutorial haben Sie zwei Container gestartet, einen aus dem `hello-world` -Bild und einen weiteren aus dem `ubuntu` -Bild. Beide Container sind nicht mehr aktiv, aber noch auf Ihrem System vorhanden.

Um alle Container — aktive und inaktive — anzuzeigen, starten Sie `docker ps` mit dem Schalter `-a`:

    docker ps -a

Sie werden folgende Meldung sehen:

    d9b100f2f636 ubuntu "/bin/bash" About an hour ago Exited (0) 8 minutes ago sharp_volhard
    01c950718166 hello-world "/hello" About an hour ago Exited (0) About an hour ago festive_williams
    

Den zuletzt erstellten Container mit dem Schalter`-l` anzeigen:

    docker ps -l

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    d9b100f2f636 ubuntu "/bin/bash" About an hour ago Exited (0) 10 minutes ago sharp_volhard

Um einen gestoppten Container zu starten, verwenden Sie `docker start`, gefolgt von der Container-ID oder dem Namen des Containers. Starten wir den Ubuntu-basierten Container mit folgender ID, `d9b100f2f636`:

    docker start d9b100f2f636

Der Container wird gestartet, und Sie können mit `docker ps` den Status anzeigen:

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    d9b100f2f636 ubuntu "/bin/bash" About an hour ago Up 8 seconds sharp_volhard
    

Um einen aktiven Container zu stoppen, verwenden Sie `docker stop`, gefolgt von der Container-ID oder dem Namen. Diesmal verwenden wir den Namen, den Docker dem Container zugewiesen hat, `sharp_volhard`:

    docker stop sharp_volhard

Sobald Sie entschieden haben, dass Sie einen Container nicht mehr benötigen, entfernen Sie ihn mit dem Befehl `docker rm` wiederum entweder mit der Container-ID oder dem Namen. Verwenden Sie den Befehl `docker ps -a` um die Container-ID oder den Namen für den Container zu finden, der dem `hello-world`-Bild zugeordnet ist, und entfernen Sie ihn.

    docker rm festive_williams

Sie können einen neuen Container starten und ihm mit dem Schalter `--name` einen Namen geben. Sie können den Schalter `--rm` auch verwenden, um einen Container zu erstellen, der sich selbst entfernt, wenn er gestoppt wird. Weitere Informationen zu diesen und anderen Optionen finden Sie unter dem Befehl `docker run help`.

Container können in Bilder umgewandelt werden, mit denen Sie neue Container erstellen können. Schauen wir uns an, wie das funktioniert.

## Schritt 7 — Änderungen in einem Container auf ein Docker-Bild übertragen

Wenn Sie ein Docker-Bild starten, können Sie Dateien erstellen, ändern und löschen, wie Sie es von einer virtuellen Maschine gewohnt sind. Die von Ihnen vorgenommenen Änderungen gelten nur für diesen Container. Sie können es starten und stoppen, aber sobald Sie es mit dem Befehl `docker rm` zerstören, gehen die Änderungen für immer verloren.

In diesem Abschnitt erfahren Sie, wie Sie den Zustand eines Containers als neues Docker-Bild speichern können.

Nachdem Sie Node.js innerhalb des Ubuntu-Containers installiert haben, haben Sie nun einen Container, der unter einem Bild läuft, aber der Container unterscheidet sich von dem Bild, mit dem Sie es erstellt haben. Aber vielleicht möchten Sie diesen Node.js-Container als Grundlage für neue Bilder später wiederverwenden.

Übertragen Sie dann die Änderungen mit dem folgenden Befehl in eine neue Docker-Bildinstanz.

    docker commit -m "What you did to the image" -a "Author Name" container_id repository/new_image_name

Der Schalter **-m** ist für die Bestätigungsnachricht, um zu erfahren, welche Änderungen Sie vorgenommen haben, während **-a** zur Autorenangabe verwendet wird. Die `container_id` ist diejenige, die Sie zuvor im Tutorial notiert haben, als Sie die interaktive Docker-Sitzung gestartet haben. Sofern Sie keine zusätzlichen Repositories auf dem Docker Hub erstellt haben, ist das `repository` in der Regel Ihr Docker Hub-Benutzername.

So wäre beispielsweise für den Benutzer **sammy** mit der Container-ID `d9b100f2f636` der Befehl:

    docker commit -m "added Node.js" -a "sammy" d9b100f2f636 sammy/ubuntu-nodejs

Wenn Sie ein Bild _commit_ (übertragen), wird das neue Bild lokal auf Ihrem Computer gespeichert. Später erfahren Sie in diesem Tutorial, wie Sie ein Bild in ein Docker-Verzeichnis wie Docker Hub verschieben können, damit andere darauf zugreifen können.

Wenn Sie die Docker-Bilder erneut auflisten, wird das neue Bild angezeigt, ebenso wie das alte, von dem es abgeleitet wurde:

    docker images

Sie werden eine ähnliche Meldung sehen:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    sammy/ubuntu-nodejs latest 7c1f35226ca6 7 seconds ago 179MB
    ubuntu latest 113a43faa138 4 weeks ago 81.2MB
    hello-world latest e38bc07ac18e 2 months ago 1.85kB
    

In diesem Beispiel ist `ubuntu-nodejs` das neue Bild, das aus dem bestehenden `ubuntu` -Bild von Docker Hub abgeleitet wurde. Die Größendifferenz spiegelt die vorgenommenen Änderungen wider. Und in diesem Beispiel war die Änderung, dass NodeJS installiert wurde. Wenn Sie also das nächste Mal einen Container mit Ubuntu mit vorinstalliertem NodeJS ausführen müssen, können Sie einfach das neue Bild verwenden.

Sie können auch Bilder aus einer `Dockerfile` erstellen, mit der Sie die Softwareinstallation in einem neuen Bild automatisieren können. Das liegt jedoch außerhalb des Rahmens dieses Tutorials.

Teilen wir nun das neue Bild mit anderen, damit sie daraus Container erstellen können.

## Schritt 8 — Verschieben von Docker-Bildern in ein Docker-Repository

Der nächste logische Schritt nach der Erstellung eines neuen Bildes aus einem bestehenden Bild besteht darin, es mit einigen Ihrer Freunde, der ganzen Welt auf Docker Hub oder einem anderen Docker-Verzeichnis, auf das Sie Zugriff haben, zu teilen. Um ein Bild auf Docker Hub oder einem anderen Docker-Verzeichnis zu übertragen, ist ein Konto erforderlich.

Dieser Abschnitt zeigt Ihnen, wie Sie ein Docker-Bild auf den Docker Hub übertragen können. Um zu lernen, wie Sie Ihr eigenes privates Docker-Verzeichnis erstellen, gehen Sie auf [Wie Sie ein privates Docker-Verzeichnis unter Ubuntu 14.04 einrichten](how-to-set-up-a-private-docker-registry-on-ubuntu-14-04).

Um Ihr Bild zu optimieren, melden Sie sich zunächst bei Docker Hub an.

    docker login -u docker-registry-username

Sie werden aufgefordert, sich mit Ihrem Docker Hub-Passwort zu authentifizieren. Die Authentifizierung sollte erfolgreich sein, wenn Sie das richtige Passwort angegeben haben.

**Hinweis:** Wenn sich Ihr Docker-Registrierungsbenutzername von dem lokalen Benutzernamen unterscheidet, den Sie zum Erstellen des Bildes verwendet haben, müssen Sie Ihr Bild mit Ihrem Registrierungsbenutzernamen versehen. Für das im letzten Schritt angegebene Beispiel würden Sie Folgendes eingeben:

    docker tag sammy/ubuntu-nodejs docker-registry-username/ubuntu-nodejs

Dann können Sie Ihr eigenes Bild mit dem Befehl Übertragen verwenden:

    docker push docker-registry-username/docker-image-name

Um das `ubuntu-nodejs`-Bild in das **sammy** Repository zu schieben, wäre der Befehl:

    docker push sammy/ubuntu-nodejs

Der Prozess kann einige Zeit in Anspruch nehmen, während er die Bilder hochlädt, aber wenn er abgeschlossen ist, erscheint folgende Meldung:

    OutputThe push refers to a repository [docker.io/sammy/ubuntu-nodejs]
    e3fbbfb44187: Pushed
    5f70bf18a086: Pushed
    a3b5c80a4eba: Pushed
    7f18b442972b: Pushed
    3ce512daaf78: Pushed
    7aae4540b42d: Pushed
    
    ...
    
    

Nachdem Sie ein Bild in ein Verzeichnis verschoben haben, sollte es im Dashboard Ihres Kontos aufgelistet werden, wie es in der Abbildung unten angezeigt wird.

![Neue Docker-Bildliste auf dem Docker Hub](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_1804/ec2vX3Z.png)

Wenn ein Übertragungsversuch zu einem solchen Fehler führt, haben Sie sich wahrscheinlich nicht angemeldet:

    OutputThe push refers to a repository [docker.io/sammy/ubuntu-nodejs]
    e3fbbfb44187: Preparing
    5f70bf18a086: Preparing
    a3b5c80a4eba: Preparing
    7f18b442972b: Preparing
    3ce512daaf78: Preparing
    7aae4540b42d: Waiting
    unauthorized: authentication required

Melden Sie sich mit dem `docker login` an und wiederholen Sie den Übertragungsversuch. Überprüfen Sie dann, ob es auf Ihrer Docker Hub Repository-Seite vorhanden ist.

Sie können nun mit `docker pull sammy/ubuntu-nodejs` das Bild auf eine neue Maschine ziehen und damit einen neuen Container ausführen.

## Fazit

In diesem Tutorial haben Sie Docker installiert, mit Bildern und Containern gearbeitet und ein modifiziertes Bild in den Docker Hub verschoben. Nachdem Sie nun die Grundlagen kennen, erkunden Sie die [anderen Docker-Tutorials](https://www.digitalocean.com/community/tags/docker?type=tutorials) in der DigitalOcean Community.
