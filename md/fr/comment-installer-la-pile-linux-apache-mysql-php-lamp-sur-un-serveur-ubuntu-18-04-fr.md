---
author: Mark Drake
date: 2019-03-15
language: fr
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/comment-installer-la-pile-linux-apache-mysql-php-lamp-sur-un-serveur-ubuntu-18-04-fr
---

# Comment installer la pile Linux, Apache, MySQL, PHP (LAMP) sur un serveur Ubuntu 18.04

## Introduction

Une pile “LAMP” est un groupe de logiciels libres qui sont généralement installés ensemble afin de permettre à un serveur d’héberger des sites internet dynamiques ainsi que des applications web. Le terme constitue généralement un acronyme qui représente le système d’exploitation **L** inux, le serveur web **A** pache. Les données du site sont hébergées sur une base de données **M** ySQL, puis le contenu dynamique est traité par **P** HP.

Dans ce guide, nous installerons une pile LAMP sur un serveur Ubuntu 18.04.

## Préalable

Afin de compléter ce tutoriel, vous aurez besoin d’un serveur Ubuntu 18.04, un compte d’utilisateur non-root «sudo» activé, ainsi qu’un pare-feu de base. Cela peut être configuré en se référant à notre [guide de configuration initial pour Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04).

## Étape 1 — Installer Apache et mettre à jour le pare-feu.

Le serveur Apache est parmi les serveurs web les plus populaires au monde. Il est bien documenté et a été utilisé abondamment pour la majeure partie de l’histoire de l’internet, ce qui en fait un bon choix par défaut pour héberger un site internet.

Installer Apache à l’aide du gestionnaire de paquets d’Ubuntu, `apt`:

    sudo apt update
    sudo apt install apache2

Puisqu’il s’agit d’une commande `sudo`, ces opérations sont exécutées avec les privilèges root. On vous demandera votre mot de passe d’utilisateur régulier afin de connaître vos intentions.

Dès que vous aurez entré votre mot de passe, `apt` vous dira quels paquets il prévoit installer et combien d’espace il prendra sur votre disque dur. Entrez la touche `Y` et appuyer sur `ENTER` afin de continuer, et l’installation poursuivra.

### Ajuster votre pare-feu afin d’autoriser le trafic web.

Ensuite, en présumant que vous avez suivi les instructions de configuration initiale du serveur et autorisé le pare-feu UFW, assurez-vous que votre pare-feu autorise le trafic HTTP et HTTPS. Vous pouvez vérifier que UFW possède un profil d’application pour Apache de la manière suivante :

    sudo ufw app list

    SortieOutputAvailable applications:
      Apache
      Apache Full
      Apache Secure
      OpenSSH

Si vous regardez sur le profil `Apache Full`, il devrait y être indiqué qu’il permet le trafic aux ports `80` et `443` :

    sudo ufw app info "Apache Full"

    SortieOutputProfile: Apache Full
    Title: Web Server (HTTP,HTTPS)
    Description: Apache v2 is the next generation of the omnipresent Apache web
    server.
    
    Ports:
      80,443/tcp

Autoriser le trafic HTTP et HTTPS entrant pour ce profil :

    sudo ufw allow in "Apache Full"

Vous pouvez immédiatement effectuer une vérification afin de valider que tout se soit déroulé comme prévu en visitant l’adresse IP de votre serveur public sur votre navigateur web (voir la note sous la rubrique suivante afin de voir quel est votre adresse IP, si vous ne disposez pas déjà de cette information) :

    http://your_server_ip

Vous allez voir la page web par défaut du serveur Ubuntu 18.04 Apache qui s’affiche à titre d’information et à des fins d’essai. La page devrait ressembler à ceci :

![Ubuntu 18.04 Apache default](http://assets.digitalocean.com/articles/how-to-install-lamp-ubuntu-18/small_apache_default_1804.png)

Si vous voyez cette page, cela veut dire que votre serveur web est maintenant bien installé et qu’il est accessible à travers votre pare-feu.

### Comment trouver l’adresse IP publique de votre serveur

Si vous ne connaissez pas l’adresse IP publique de votre serveur, il existe différentes façons de la trouver. Normalement, il s’agit de l’adresse que vous utilisez afin de vous connecter à votre serveur via SSH.

Il y a plusieurs façons d’effectuer cela à partir de la ligne de commande. D’abord, vous pouvez utiliser les outils `iproute2` afin d’obtenir votre adresse IP en écrivant ceci :

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Vous devriez voir apparaître deux ou trois lignes de résultats. Ce sont tous des adresses correctes, par contre votre ordinateur ne sera peut-être qu’en mesure d’utiliser une de celles-ci, alors libre à vous d’essayer chacune d’entre elles.

Une autre méthode consiste à utiliser l’outil `curl` pour contacter un correspondant externe afin qu’il vous informe comment « il » perçoit votre serveur. Cela s’effectue en demandant à un serveur spécifique quelle est votre adresse IP :

    sudo apt install curl
    curl http://icanhazip.com

Indépendamment de la méthode que vous choisissez pour obtenir votre adresse IP, inscrivez-la sur la barre d’adresse de votre navigateur afin de voir la page par défaut d’Apache.

## Étape 2 — Installer MySQL

Maintenant que votre serveur web est opérationnel, il est temps d’installer MySQL. MySQL est un système de gestion de base de données. Il sert essentiellement à organiser et donner l’accès aux bases de données au sein desquelles votre site pourra emmagasiner de l’information.

Encore une fois, utiliser `apt` pour obtenir et installer ce logiciel.

    sudo apt install mysql-server

**Note** : Dans ce cas, vous n’avez pas besoin d’activer `sudo apt update` avant d’effectuer la commande. Cela est dû au fait que l’avez récemment activé dans les commandes ci-dessus pour installer Apache. Le paquet d’index sur votre ordinateur devrait déjà être à jour.

Cette commande affichera également une liste des paquets qui seront installés, de même que l’espace qu’ils occuperont sur votre disque dur. Entrez la touche `Y` pour continuer.

Lorsque l’installation est complétée, exécuter un script de sécurité simple qui est préinstallé avec MySQL et qui permettra de supprimer des défaillances dangereuses et puis de verrouiller l’accès à votre système de base de données. Démarrer le script interactif en exécutant la commande :

    sudo mysql_secure_installation

On vous demandera si vous désirez configurer le `VALIDATE PASSWORD PLUGIN`.

**Note:** Activer cette fonctionnalité demeure une question de jugement. Lorsqu’activés, les mots de passe qui ne correspondent pas au critère spécifique seront refusés par MySQL avec un message d’erreur. Ceci engendrera des problèmes si vous utilisez un mot de passe faible conjointement à l’application qui configure automatiquement les identifiants d’utilisateurs MySQL, tels que les paquets d’Ubuntu pour phpMyAdmin. Il est sécuritaire de laisser la validation désactivée, mais vous devriez toujours utiliser un mot de passe robuste et unique pour les authentifications de base de données.

Répondre `Y` pour oui, ou n’importe quelle autre commande pour continuer sans l’activer.

    VALIDATE PASSWORD PLUGIN peut être utilisé pour tester les mots de passe
    et améliorer la sécurité. Le système vérifie la sécurité du mot de passe
    et permet aux utilisateurs de définir uniquement les mots de passe qui sont
    assez bien sécurisés en demandant : Voulez-vous configurer le plug-in - VALIDATE PASSWORD?
    Press y|Y for Yes, any other key for No:

Si vous répondez “oui”, on vous demandera de choisir un niveau de validation de mot de passe. Gardez à l’esprit que si vous choisissez `2`, pour le niveau le plus élevé, vous recevrez des messages d’erreur lorsque vous tenterez de définir un mot de passe qui ne contient pas de chiffre, de majuscule et de minuscule, de caractères spéciaux, ou qui s’inspire de mots communs du dictionnaire.

    Il existe trois niveaux de politique de validation du mot de passe:
    
    LOW Length >= 8
    MEDIUM Length >= 8, numeric, mixed case, and special characters
    STRONG Length >= 8, numeric, mixed case, special characters and dictionary file
    
    Veuillez saisir 0 = LOW, 1 = MEDIUM and 2 = STRONG: 1

Indépendamment de votre décision de configurer ou non le `VALIDATE PASSWORD PLUGIN`, votre serveur vous demandera de choisir et de confirmer un mot de passe pour l’utilisateur **root** MySQL. Il s’agit d’un compte administratif au sein de MySQL qui possède des privilèges accrus. Voyez-le comme étant similaire au compte **root** pour le serveur lui-même (bien que celui que vous êtes en train de configurer est un compte spécifique au sein de MySQL). Assurez-vous que vous de détenir un mot de passe robuste, unique, et de ne pas laisser l’espace vide.

Si vous activez la validation du mot de passe, on vous indiquera la robustesse du mot de passe **root** que vous venez d’inscrire et votre serveur vous demandera si vous voulez le modifier. Si vous êtes satisfait de votre mot de passe, entrez `N` pour « non » au moment de faire le choix :

    Utiliser le mot de passe existant pour root.
    
    Force estimée du mot de passe : 100
    Changer le mot de passe pour root ? ((Press y|Y for Yes, any other key for No) : n

Pour le reste des questions, entrez la touche `Y` et appuyer sur le bouton `ENTER` au moment de faire le choix. Cela supprimera certains utilisateurs anonymes ainsi que la base de données d’essai, désactivera les identifications **root** à distance et chargera les nouvelles règles afin que MySQL applique automatiquement les changements que vous venez d’apporter.

Veuillez noter que pour les systèmes Ubuntu fonctionnant avec MySQL 5.7 (et les versions ultérieures), l’utilisateur **root** MySQL est configuré par défaut pour authentifier en utilisant le plugin `auth_socket`, plutôt qu’avec un mot de passe. Cela permet d’avoir une meilleure sécurité et ergonomie dans de nombreux cas, mais il peut également compliquer les choses lorsque vous devez autoriser l’ouverture d’un programme externe (ex : phpMyAdmin) afin d’accéder au serveur.

Si vous préférez utiliser un mot de passe lorsque vous vous connectez au MySQL en tant que **root** , vous aurez besoin de changer le mode d’authentification de `auth_socket` à `mysql_native_password`. Pour y parvenir, ouvrez le prompt MySQL à partir de votre terminal :

    sudo mysql

Ensuite, vérifier quel mode d’authentification chacun de vos comptes d’utilisateurs MySQL fait appel avec la commande suivante :

    SELECT user,authentication_string,plugin,host FROM mysql.user;

    SortieOutput+------------------+-------------------------------------------+-----------------------+-----------+
    | user | authentication_string | plugin | host |
    +------------------+-------------------------------------------+-----------------------+-----------+
    | root | | auth_socket | localhost |
    | mysql.session | *THISISNOTAVALIDPASSWORDTHATCANBEUSEDHERE | mysql_native_password | localhost |
    | mysql.sys | *THISISNOTAVALIDPASSWORDTHATCANBEUSEDHERE | mysql_native_password | localhost |
    | debian-sys-maint | *CC744277A401A7D25BE1CA89AFF17BF607F876FF | mysql_native_password | localhost |
    +------------------+-------------------------------------------+-----------------------+-----------+
    4 rows in set (0.00 sec)

Dans cet exemple, vous pouvez voir que l’utilisateur **root** s’authentifie effectivement en utilisant le plugin `auth_socket`. Afin de configurer le compte **root** pour l’identification avec mot de passe, exécuter la commande `ALTER USER` ci-dessous. Assurez-vous de modifier `password` pour un mot de passe robuste de votre choix :

    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';

Ensuite, exécuter `FLUSH PRIVILEGES`, qui envoie un message au serveur de renouveler les tableaux d’autorisations et de mettre en application vos nouvelles modifications :

    FLUSH PRIVILEGES;

Vérifier encore les modes d’authentifications utilisées par chacun de vos utilisateurs afin de confirmer que le **root** ne s’authentifie plus en utilisant le plugin `auth_socket` :

    SELECT user,authentication_string,plugin,host FROM mysql.user;

    SortieOutput+------------------+-------------------------------------------+-----------------------+-----------+
    | user | authentication_string | plugin | host |
    +------------------+-------------------------------------------+-----------------------+-----------+
    | root | *3636DACC8616D997782ADD0839F92C1571D6D78F | mysql_native_password | localhost |
    | mysql.session | *THISISNOTAVALIDPASSWORDTHATCANBEUSEDHERE | mysql_native_password | localhost |
    | mysql.sys | *THISISNOTAVALIDPASSWORDTHATCANBEUSEDHERE | mysql_native_password | localhost |
    | debian-sys-maint | *CC744277A401A7D25BE1CA89AFF17BF607F876FF | mysql_native_password | localhost |
    +------------------+-------------------------------------------+-----------------------+-----------+
    4 rows in set (0.00 sec)

Vous pouvez voir dans cet exemple que l’utilisateur **root** de MySQL s’authentifie actuellement en utilisant un mot de passe. Une fois que vous aurez confirmé cela sur votre propre serveur, vous pouvez sortir du shell MySQL :

    exit

À ce stade, votre système de base de données est maintenant programmé et vous pouvez poursuivre avec l’installation PHP, le dernier composant de la pile LAMP.

## Étape 3 — Installer PHP

PHP est le composant de votre configuration qui sert de code de traitement pour afficher le contenu dynamique. Il peut exécuter des scripts, se connecter à vos bases de données MySQL afin d’obtenir de l’information et acheminer le contenu traité vers votre serveur web pour affichage.

Encore une fois, utiliser le système `apt` pour installer PHP. De plus, inclure des paquets d’assistance cette fois-ci afin de permettre au code PHP de s’exécuter sous le serveur Apache et communiquer avec votre base de données MySQL :

    sudo apt install php libapache2-mod-php php-mysql

Cela devrait permettre d’installer PHP sans problème. Nous le mettrons à l’essai dans un moment.

Dans la plupart des cas, vous allez vouloir modifier la façon dont Apache dessert les fichiers lorsqu’un répertoire est demandé. Actuellement, si un utilisateur demande un répertoire du serveur, Apache recherchera d’abord pour un fichier nommé `index.html`. Nous voulons dire au serveur web de donner priorité aux fichiers PHP, ainsi il faut exiger à Apache de regarder pour un fichier `index.php` en premier.

Afin d’effectuer cela, entrez cette commande pour ouvrir le fichier `dir.conf` dans un éditeur de texte avec des privilèges **root** :

    sudo nano /etc/apache2/mods-enabled/dir.conf

Cela va ressembler à cela :

/etc/apache2/mods-enabled/dir.conf

    <IfModule mod_dir.c>
        DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm
    </IfModule>

Déplacer le fichier d’index PHP (surligner ci-dessous) à la première position après la spécification `DirectoryIndex`, de la manière suivante :

/etc/apache2/mods-enabled/dir.conf

    <IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
    </IfModule>

Lorsque vous avez terminé, sauvegarder et fermer le fichier en appuyant sur `CTRL+X`. Confirmer la sauvegarde en entrant la touche `Y` et en appuyant sur `ENTER` afin de vérifier la localisation du fichier de sauvegarde.

Ensuite, redémarrer le serveur web Apache afin que vos modifications prennent effet. Cela s’effectuera en inscrivant ceci :

    sudo systemctl restart apache2

Vous pouvez également vérifier le statut du service `apache2` en utilisant la commande `systemctl` :

    sudo systemctl status apache2

    Sample SortieOutput● apache2.service - LSB: Apache2 web server
       Loaded: loaded (/etc/init.d/apache2; bad; vendor preset: enabled)
      Drop-In: /lib/systemd/system/apache2.service.d
               └─apache2-systemd.conf
       Active: active (running) since Tue 2018-04-23 14:28:43 EDT; 45s ago
         Docs: man:systemd-sysv-generator(8)
      Process: 13581 ExecStop=/etc/init.d/apache2 stop (code=exited, status=0/SUCCESS)
      Process: 13605 ExecStart=/etc/init.d/apache2 start (code=exited, status=0/SUCCESS)
        Tasks: 6 (limit: 512)
       CGroup: /system.slice/apache2.service
               ├─13623 /usr/sbin/apache2 -k start
               ├─13626 /usr/sbin/apache2 -k start
               ├─13627 /usr/sbin/apache2 -k start
               ├─13628 /usr/sbin/apache2 -k start
               ├─13629 /usr/sbin/apache2 -k start
               └─13630 /usr/sbin/apache2 -k start

Afin d’améliorer le fonctionnement de PHP, vous avez l’option d’installer de modules supplémentaires. Pour voir les options disponibles de modules PHP et de bibliothèques, mener les résultats de `apt search` vers `less`, un récepteur qui vous laissera défiler à travers les résultats d’autres commandes :

    apt search php- | less

Utiliser les flèches afin de défiler de haut en bas, et appuyer sur `Q` pour quitter.

Les résultats sont tous des composants optionnels que vous pouvez installer. Une courte description de chacun d’entre eux sera affichée :

    bandwidthd-pgsql/bionic 2.0.1+cvs20090917-10ubuntu1 amd64
      Tracks usage of TCP/IP and builds html files with graphs
    
    bluefish/bionic 2.2.10-1 amd64
      advanced Gtk+ text editor for web and software development
    
    cacti/bionic 1.1.38+ds1-1 all
      web interface for graphing of monitoring systems
    
    ganglia-webfrontend/bionic 3.6.1-3 all
      cluster monitoring toolkit - web front-end
    
    golang-github-unknwon-cae-dev/bionic 0.0~git20160715.0.c6aac99-4 all
      PHP-like Compression and Archive Extensions in Go
    
    haserl/bionic 0.9.35-2 amd64
      CGI scripting program for embedded environments
    
    kdevelop-php-docs/bionic 5.2.1-1ubuntu2 all
      transitional package for kdevelop-php
    
    kdevelop-php-docs-l10n/bionic 5.2.1-1ubuntu2 all
      transitional package for kdevelop-php-l10n
    …
    :

Pour en savoir plus sur la fonctionnalité de chaque module, vous pouvez chercher sur internet pour plus d’informations à leur sujet. Une autre solution est de lire la longue description du paquet en tapant :

    apt show package_name

Il y aura plusieurs résultats, incluant un champ intitulé `Description` qui présentera une explication plus détaillée de la fonctionnalité du module en question.

Par exemple, afin de découvrir en quoi le module `php-cli` consiste, vous pouvez taper :

    apt show php-cli

En plus de la grande quantité d’autres informations, vous obtiendrez quelque chose qui ressemble à ceci :

    SortieOutput…
    Description: command-line interpreter for the PHP scripting language (default)
     This package provides the /usr/bin/php command interpreter, useful for
     testing PHP scripts from a shell or performing general shell scripting tasks.
     .
     PHP (recursive acronym for PHP: Hypertext Preprocessor) is a widely-used
     open source general-purpose scripting language that is especially suited
     for web development and can be embedded into HTML.
     .
    Ce paquet est un forfait de dépendances, qui dépend du défaut d'Ubuntu
     PHP version (currently 7.2).
    …

Si, après votre recherche, vous décidez que vous voulez installer un paquet, vous pouvez le faire en utilisation la commande `apt install`, de la même manière que vous avez procédé pour l’autre logiciel.

Si vous décidez que le `php-cli` est quelque chose dont vous avez besoin, vous pouvez taper cette commande :

    sudo apt install php-cli

Si vous désirez installer plus d’un module, vous pouvez le faire en énumérant chacun d’entre eux, séparé d’un espace, suivant la commande `apt install`, comme ceci :

    sudo apt install package1 package2 ...

À ce stade, votre pile LAMP est installée et configurée. Cependant, avant de procéder à toute modification ou de déployer une application, il serait préférable de tester votre configuration PHP de manière proactive au cas où il y aurait un problème à traiter.

## Étape 4 — Tester le processus PHP sur votre serveur web

Afin de tester si votre système est configuré correctement pour PHP, créer un script PHP de base appelé `info.php`. Afin qu’Apache puisse localiser ce fichier et le desservir correctement, il devra être sauvegardé dans un répertoire bien spécifique, qui se nomme le “web root”.

Sur Ubuntu 18.04, ce répertoire est situé au `/var/www/html/`. Créer le fichier à cet emplacement en exécutant :

    sudo nano /var/www/html/info.php

Cela ouvrira un fichier vierge. Ajouter le texte suivant, qui s’agit d’un code PHP valide, à l’intérieur du fichier :

info.php

    <?php
    phpinfo();
    ?>

Lorsque vous aurez terminé, sauvegarder et fermer le fichier.

Vous pouvez maintenant tester si votre serveur web affiche correctement le contenu généré par ce script PHP. Pour le tester, visiter la page suivante dans votre navigateur web. Vous aurez encore besoin de votre adresse IP publique.

L’adresse que vous devrez consulter est la suivante :

    http://your_server_ip/info.php

La page que vous allez accéder devrait ressembler à ceci :   
 ![Ubuntu 18.04 default PHP info](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/how-to-install-lamp-ubuntu-18/small_php_info_1804.png)

Cette page présente de l’information de base sur votre serveur du point de vue de PHP. Elle est pratique pour le débogage et afin d’assurer que vos réglages sont appliqués correctement.

Si vous voyez cette page sur votre navigateur, alors votre PHP fonctionne correctement.

Vous devriez supprimer ce fichier après la mise en essai parce qu’il pourrait en fait donner de l’information sur votre serveur à des utilisateurs non autorisés. Pour ce faire, exécuter la commande suivante :

    sudo rm /var/www/html/info.php

Vous pourrez toujours recréer cette page si vous avez besoin d’accéder à cette information plus tard.

## Conclusion

Maintenant que votre pile LAMP est installée, vous avez plusieurs choix quant à ce que vous pouvez faire par la suite. Essentiellement, vous venez d’installer une plateforme qui vous permettra d’installer la plupart des types de site internet et de logiciels web sur votre serveur.

Dans l’immédiat, vous devriez vous assurer que les connexions à votre serveur web sont sécurisées, en les faisant fonctionner via HTTPS. L’option la plus simple dans ce cas est de [utiliser Let’s Encrypt](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04) afin de sécuriser votre site avec un certificat TLS/SSL gratuit.

D’autres options populaires demeurent (notez que pour le moment ces tutoriels sont seulement disponibles en anglais) :

- [Comment installer WordpressInstall Wordpress](how-to-install-wordpress-with-lamp-on-ubuntu-16-04), le système de gestion le plus populaire sur l’internet the most popular content management system on the internet.
- [Comment installer Set Up PHPMyAdmin](how-to-install-and-secure-phpmyadmin-on-ubuntu-18-04) pour gérer vos bases de données MySQL utilisant votre navigateur web to help manage your MySQL databases from web browser.
- [Comment utiliser Learn how to use SFTP](https://www.digitalocean.com/community/articles/how-to-use-sftp-to-securely-transfer-files-with-a-remote-server) pour transférer vos fichiers entre votre serveur et votre ordinateur local to transfer files to and from your server.
