---
author: Mark Drake
date: 2019-04-26
language: fr
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/comment-installer-mysql-sur-ubuntu-18-04-fr
---

# Comment installer MySQL sur Ubuntu 18.04

## Introduction

[MySQL](https://www.mysql.com/) est un système de gestion de base de données Open Source, couramment installé dans le cadre de la pile [LAMP](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04) (Linux, Apache, MySQL, PHP/Python/Perl) populaire. Il utilise une base de données relationnelle et SQL (Structured Query Language, en français langage de requête structurée) pour gérer ses données.

La version courte de l’installation est simple: mettez à jour votre index de paquet, installez le paquet `mysql-server` et puis exécutez le script de sécurité inclus.

    sudo apt update
    sudo apt install mysql-server
    sudo mysql_secure_installation

Ce tutoriel va expliquer comment installer MySQL version 5.7 sur un serveur Ubuntu 18.04. Cependant, si vous souhaitez mettre à jour une installation existante de MySQL vers la version 5.7, vous pouvez lire [ce guide de mise à jour de MySQL 5.7](how-to-prepare-for-your-mysql-5-7-upgrade) à la place.

## Conditions préalables

Pour suivre ce tutoriel vous aurez besoin de:

- Un serveur Ubuntu 18.04 configuré en suivant [ce guide de configuration initiale du serveur](initial-server-setup-with-ubuntu-18-04), incluant un utilisateur non- **root** avec privilèges `sudo` et un pare-feu.

## Étape 1 — Installation de MySQL

Sur Ubuntu 18.04, seulement la dernière version de MySQL est incluse dans le référentiel du paquet APT par défaut. Au moment de l’écriture, c’est MySQL 5.7

Pour l’installer, mettez à jour l’index de paquet sur votre serveur avec `apt`:

    sudo apt update

Installez ensuite le paquet par défaut:

    sudo apt install mysql-server

Cela installera MySQL, mais ne vous demandera pas d’établir un mot de passe de ou d’apporter d’autres modifications de configuration. Étant donné que cette installation de MySQL est insécurisée, nous allons traiter la situation de la façon suivante.

## Étape 2 — Configuration de MySQL

Pour les nouvelles installations, vous voudrez exécuter le script de sécurité inclus. Cela modifie certaines des options par défaut moins sécurisées comme les connexions root à distance et les exemples d’utilisateurs. Sur les anciennes versions de MySQL, vous aviez également besoin d’initialiser le répertoire de données manuellement, mais cela se fait automatiquement maintenant.

Exécuter le script de sécurité:

    sudo mysql_secure_installation

Cela vous mènera à travers une série d’invites vous permettant de faire des changements aux options de sécurité de votre installation MySQL. La première invite vous demandera si vous voulez configurer le plugin Validate Password (Validation du mot de passe) qui peut être utilisé pour tester la force de votre mot de passe MySQL. Peu importe votre choix, la prochaine invite sera d’établir un mot de passe pour l'utilisateur **root** de MySQL. Entrez/Appuyez sur la touche retour et puis confirmer un mot de passe sécurisé de votre choix.

À partir de ce moment, avec l’aide du clavier, vous pouvez appuyer sur `Y` et puis `ENTER`(retour) pour accepter les valeurs par défaut pour toutes les questions suivantes. Cela supprimera certains utilisateurs anonymes et la base de données de test, désactivera les connexions root à distance et chargera ces nouvelles règles afin que MySQL respecte immédiatement les changements apportés.

Pour initialiser le répertoire de données MySQL, vous utiliserez `mysql_install_db` pour les versions avant 5.7.6 et `mysqld --initialize` pour les versions 5.7.6 et subséquentes. Cependant, si vous avez installé MySQL à partir de la distribution Debian, comme le décrit l’Étape 1, le répertoire de données à été initialisé automatiquement; vous n’avez rien à faire. Si vous essayez tout de même d’exécuter la commande, vous verrez l’erreur suivante:

Output

    mysqld: Can't create directory '/var/lib/mysql/' (Errcode: 17 - File exists)
    . . .
    2018-04-23T13:48:00.572066Z 0 [ERROR] Aborting

Notez que même si vous avez établi un mot de passe pour l’utilisateur \*_root_ de MySQL, cet utilisateur n’est pas configuré pour s’authentifier avec un mot de passe lors de la connexion au shell MySQL. Si vous le voulez, vous pouvez ajuster ce paramètre en suivant l’Étape 3.

## Étape 3 — (Optionnel) Réglage de l’authentification et des privilèges de l’utilisateur

Pour les systèmes Ubuntu exécutant MySQL 5.7 (et les versions subséquentes), l’utilisateur **root** MySQL est configuré pour s'authentifier à l'aide du plugin `auth_socket` par défaut plutôt que d'un mot de passe. Cela permet une sécurité et une facilité d’utilisation dans de nombreux cas, mais cela peut également compliquer les choses lorsque vous devez autoriser un programme externe (par exemple, phpMyAdmin) à accéder à l'utilisateur.

Pour utiliser un mot de passe pour vous connecter à MySQL en tant que **root** , vous devez changer sa méthode d'authentification de `auth_socket` à`mysql_native_password`. Pour ce faire, ouvrez l’invite MySQL depuis votre terminal:

    sudo mysql

Ensuite, vérifiez la méthode d’authentification utilisée par chacun de vos comptes d'utilisateur MySQL avec la commande suivante:

    SELECT user,authentication_string,plugin,host FROM mysql.user;

    Output+------------------+-------------------------------------------+-----------------------+-----------+
    | user | authentication_string | plugin | host |
    +------------------+-------------------------------------------+-----------------------+-----------+
    | root | | auth_socket | localhost |
    | mysql.session | *THISISNOTAVALIDPASSWORDTHATCANBEUSEDHERE | mysql_native_password | localhost |
    | mysql.sys | *THISISNOTAVALIDPASSWORDTHATCANBEUSEDHERE | mysql_native_password | localhost |
    | debian-sys-maint | *CC744277A401A7D25BE1CA89AFF17BF607F876FF | mysql_native_password | localhost |
    +------------------+-------------------------------------------+-----------------------+-----------+
    4 rows in set (0.00 sec)

Dans cet exemple, vous pouvez voir que l’utilisateur \*_root_ s'authentifie en utilisant le plugin `auth_socket`. Pour configurer le compte d’utilisateur \*_root_ afin qu’il puisse s’authentifier avec un mot de passe, exécutez la commande `ALTER USER` suivante. Assurez-vous de remplacer `password` avec un mot de passe solide de votre choix et notez que cette commande va modifier le mot de passe \*_root_ établi à l’Étape 2:

    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';

Par la suite, exécuter `FLUSH PRIVILEGES` qui indique au serveur de recharger les tables d’attributions et d’appliquer vos nouvelles modifications:

    FLUSH PRIVILEGES;

Vérifiez à nouveau les méthodes d'authentification employées par chacun de vos utilisateurs pour vous assurer que **root** ne s’authentifie plus à l'aide du plugin `auth_socket`:

    SELECT user,authentication_string,plugin,host FROM mysql.user;

    Output+------------------+-------------------------------------------+-----------------------+-----------+
    | user | authentication_string | plugin | host |
    +------------------+-------------------------------------------+-----------------------+-----------+
    | root | *3636DACC8616D997782ADD0839F92C1571D6D78F | mysql_native_password | localhost |
    | mysql.session | *THISISNOTAVALIDPASSWORDTHATCANBEUSEDHERE | mysql_native_password | localhost |
    | mysql.sys | *THISISNOTAVALIDPASSWORDTHATCANBEUSEDHERE | mysql_native_password | localhost |
    | debian-sys-maint | *CC744277A401A7D25BE1CA89AFF17BF607F876FF | mysql_native_password | localhost |
    +------------------+-------------------------------------------+-----------------------+-----------+
    4 rows in set (0.00 sec)

Vous pouvez voir dans cet exemple de sortie de données que l'utilisateur **root** de MySQL s'authentifie maintenant à l'aide d'un mot de passe. Une fois que vous confirmez cela sur votre propre serveur, vous pouvez quitter le shell MySQL:

    exit

Alternativement, certains peuvent trouver plus utile de se connecter à MySQL avec un utilisateur dédié. Pour créer un tel utilisateur, ouvrez à nouveau le shell MySQL:

    sudo mysql

**Note:** Si vous avez activé l'authentification par mot de passe pour **root** , comme il est décrit dans les paragraphes précédents, vous devrez utiliser une commande différente pour accéder au shell MySQL. Ce qui suit va exécuter votre client MySQL avec des privilèges d’utilisateur normaux et vous n’obtiendrez que des privilèges d’administrateur au sein de la base de données en s’authentifiant:

    mysql -u root -p

À partir de là, créez un nouvel utilisateur et attribuez-lui un mot de passe solide:

    CREATE USER 'sammy'@'localhost' IDENTIFIED BY 'password';

Ensuite, donnez à votre nouvel utilisateur les privilèges appropriés. Par exemple, vous pouvez accorder à l’utilisateur accès à toutes les tables au sein de la base de données ainsi que le pouvoir d’ajouter, changer ou supprimer des privilèges d’utilisateurs avec cette commande:

    GRANT ALL PRIVILEGES ON *.* TO 'sammy'@'localhost' WITH GRANT OPTION;

Notez qu’à ce stade, il n’est pas nécessaire de réexécuter la commande `FLUSH PRIVILEGES`. Cette commande n'est nécessaire que lorsque vous modifiez les tables d'attributions à l'aide de déclarations telles que `INSERT` (insérez), `UPDATE` (mettre à jour) ou `DELETE` (supprimer). Parce que vous avez créé un nouvel utilisateur au lieu de modifier un utilisateur existant, `FLUSH PRIVILEGES` est inutile à ce moment.

Ensuite, quittez le shell MySQL:

    exit

Enfin, testons l’installation de MySQL.

## Étape 4 — Test de MySQL

Peu importe le mode d’installation, MySQL aurait dû s’exécuter automatiquement. Pour tester cela, vérifiez son statut.

    systemctl status mysql.service

Vous verrez une sortie de données semblable à celle-ci:

Output

    ● mysql.service - MySQL Community Server
       Loaded: loaded (/lib/systemd/system/mysql.service; enabled; vendor preset: en
       Active: active (running) since Wed 2018-04-23 21:21:25 UTC; 30min ago
     Main PID: 3754 (mysqld)
        Tasks: 28
       Memory: 142.3M
          CPU: 1.994s
       CGroup: /system.slice/mysql.service
               └─3754 /usr/sbin/mysqld

Si MySQL ne s’est pas automatiquement exécuté, vous pouvez le démarrer avec `sudo systemctl start mysql`.

Pour une vérification supplémentaire, vous pouvez essayer de vous connecter à la base de données en utilisant l’outil `mysqladmin`, un client qui vous permet d’exécuter des commandes administratives. Par exemple, cette commande dit de se connecter à MySQL en tant que **root** (`-u root`), de demander un mot de passe (`-p`) et de renvoyer la version.

    sudo mysqladmin -p -u root version

Vous devrez voir une sortie de données semblable à celle-ci:

Output

    mysqladmin Ver 8.42 Distrib 5.7.21, for Linux on x86_64
    Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.
    
    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.
    
    Server version 5.7.21-1ubuntu1
    Protocol version 10
    Connection Localhost via UNIX socket
    UNIX socket /var/run/mysqld/mysqld.sock
    Uptime: 30 min 54 sec
    
    Threads: 1 Questions: 12 Slow queries: 0 Opens: 115 Flush tables: 1 Open tables: 34 Queries per second avg: 0.006

Cela veut dire que MySQL est opérationnel.

## Conclusion

Vous avez maintenant une configuration MySQL de base installée sur votre serveur. Voici quelques exemples des prochaines étapes à suivre:

- [Mettre en place des mesures de sécurité supplémentaires](how-to-secure-mysql-and-mariadb-databases-in-a-linux-vps)
- [Relocaliser le répertoire de données](how-to-move-a-mysql-data-directory-to-a-new-location-on-ubuntu-16-04)
- [Gérez vos serveurs MySQL avec SaltStack](saltstack-infrastructure-creating-salt-states-for-mysql-database-servers)
