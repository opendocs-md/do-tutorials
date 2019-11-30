---
author: Justin Ellingwood
date: 2019-03-15
language: fr
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/configuration-initiale-de-serveur-avec-ubuntu-18-04-fr
---

# Configuration initiale de serveur avec Ubuntu 18.04

## Introduction

Lorsque vous installez un nouveau serveur Ubuntu 18.04, il y a quelques étapes de configuration que vous devriez effectuer au sein de votre paramétrage initial. Cela renforcera la sécurité et l’ergonomie de votre serveur et vous procurera une base solide pour vos actions futures.

**Note:** Le guide ci-dessous montre comment compléter manuellement les étapes que nous recommandons de suivre pour les nouveaux serveurs Ubuntu 18.04. Suivre cette procédure manuellement peut être pratique afin d’apprendre des techniques d’administration de système de base et pour bien comprendre les actions entreprises sur votre serveur. De manière alternative, si vous désirez être en mesure de débuter plus rapidement, vous pouvez suivre ce guide [run our initial server setup script] (en Anglais) ([https://www.digitalocean.com/community/tutorials/automating-initial-server-setup-with-ubuntu-18-04](automating-initial-server-setup-with-ubuntu-18-04)) qui automatise ces étapes.

## Étape 1 — Se connecter en tant que _Root_

Afin de vous connecter à votre serveur, vous aurez besoin de connaître votre « adresse IP publique ». Vous aurez également besoin du mot de passe, ou si vous avez installé une clé d’identification SSH, la clé privée de votre compte d’utilisateur **root**. Si vous ne vous êtes pas encore connecté à votre serveur, vous devriez penser à suivre notre guide [how to connect to your Droplet with SSH] (en anglais) ([https://www.digitalocean.com/community/tutorials/how-to-connect-to-your-droplet-with-ssh](how-to-connect-to-your-droplet-with-ssh)), qui couvre ce processus en détail.

Si vous n’êtes pas encore connecté à votre serveur, vous pouvez aller de l’avant et vous connecter en tant qu’utilisateur **root** à l’aide de la commande suivante : (substituer la partie surlignée de la commande avec l’adresse IP publique de votre serveur)

    ssh root@your_server_ip

Acceptez l’avertissement concernant l’authenticité de l’hôte si elle apparaît. Si vous utilisez l’authentification avec mot de passe, entrez votre mot de passe **root** afin de vous connecter. Si vous utilisez une clé SSH qui est protégée à l’aide d’une phrase de sécurité, il est possible que vous soyez invité à entrer la phrase de sécurité la première fois que vous utilisez la clé chaque session. S’il s’agit de la première fois que vous vous connectez sur le serveur à l’aide d’un mot de passe, il est possible que vous soyez également invité à changer votre mot de passe **root**.

### À propos de _Root_

L’utilisateur **root** est l’utilisateur administratif dans un environnement Linux qui bénéficie d’une large gamme de privilèges. Dû aux privilèges accrus du compte **root** , vous êtes _déconseillé_ de l’utiliser sur une base régulière. Cela est dû au fait qu’une partie du pouvoir propre au compte **root** est sa capacité à faire des modifications très destructives, même par accident.

La prochaine étape consiste à configurer un compte d’utilisateur alternatif avec un champ d’influence limité pour le travail de tous les jours. Nous vous enseignerons comment accéder à des privilèges accrus pour les moments où vous en aurez besoin.

## Étape 2 — Créer un nouvel utilisateur

Une fois connectés en tant que **root** , nous sommes prêts à ajouter le nouveau compte d’utilisateur que nous utiliserons toujours dorénavant pour nous connecter.

Cet exemple créer un utilisateur nommé _sammy_, mais vous devriez le replacer par un nom d’utilisateur que vous aimez :

    adduser sammy

On vous posera quelques questions, commençant par le mot de passe de votre compte.

Entrez un mot de passe robuste et, si vous le désirez, remplissez quelconque information supplémentaire. Ceci n’est pas obligatoire et vous pouvez simplement pesez `ENTER` au sein de n’importe quel champ que vous désirez sauter.

## Étape 3 — Octroyer les privilèges d’administration

Présentement, nous avons un nouveau compte d’utilisateur avec des privilèges de compte régulier. Cependant, il se peut que nous ayons besoin d’effectuer des tâches administratives de temps à autre.

Afin d’éviter de devoir se déconnecter de notre utilisateur normal pour ensuite se reconnecter à notre compte **root** , nous pouvons régler ce qu’on appelle le “superuser” ou les privilèges **root** pour notre compte normal. Cela permettra à notre utilisateur normal d’exécuter des commandes avec des privilèges administratifs en inscrivant le mot `sudo` avant chaque commande.

Afin d’ajouter ces privilèges à notre nouvel utilisateur, nous devons ajouter le nouvel utilisateur au groupe **sudo**. Par défaut, sur Ubuntu 18.04, les utilisateurs appartenant au groupe **sudo** sont autorisés à utiliser la commande `sudo`.

En tant que **root** , effectuez cette commande afin d’ajouter votre nouvel utilisateur au groupe **sudo** (substituer le mot surligné avec votre nouvel utilisateur) :

    usermod -aG sudo sammy

Maintenant, une fois connecté avec votre utilisateur régulier, vous pouvez tapez `sudo` avant chaque commande pour effectuer des actions avec des privilèges “superuser”.

## Étape 4 —Régler un pare-feu de base

Les serveurs Ubuntu 18.04 peuvent faire appel à un pare-feu UFW afin de s’assurer que seules les connexions à certains services soient autorisées. Nous pouvons régler un pare-feu de base très facilement en utilisant cette application.

**Note:** Si vos serveurs fonctionnent avec DigitalOcean, vous pouvez de manière facultative utiliser [DigitalOcean Cloud Firewalls] (en Anglais) ([https://www.digitalocean.com/community/tutorials/an-introduction-to-digitalocean-cloud-firewalls](an-introduction-to-digitalocean-cloud-firewalls)) au lieu du pare-feu UFW. Nous vous recommandons d’utiliser seulement un pare-feu à la fois afin d’éviter d’avoir des règles conflictuelles qui pourraient prendre du temps à déboguer.

Différentes applications peuvent inscrire leurs profils avec UFW au moment de l’installation. Ces profils permettent à UFW de gérer ces applications selon leur nom. OpenSSH, le service nous permettant maintenant de nous connecter à notre serveur possède un profil inscrit avec UFW.

Vous pouvez voir cela en tapant:

    ufw app list

    OutputAvailable applications:
      OpenSSH

Nous devons s’assurer que le pare-feu permette les connexions SSH afin que nous puissions nous connecter la prochaine fois. Nous pouvons autoriser ces connexions en tapant :

    ufw allow OpenSSH

Ensuite, nous pouvons activer le pare-feu en tapant:

    ufw enable

Tapez “`y`” et pesez sur `ENTER` afin de procéder. Vous pouvez voir si les connexions SSH sont toujours autorisées en tapant :

    ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

Alors que **le pare-feu bloque présentement toutes les connexions mises à part celle SSH** , si vous installez et configurez des services additionnels, vous devrez régler les paramètres du pare-feu afin de permettre un trafic entrant acceptable. Vous pouvez lire davantage sur les opérations courantes UFW [this guide] (en Anglais) ([https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands](ufw-essentials-common-firewall-rules-and-commands)).

## Étape 5 — Autoriser l’accès externe à votre utilisateur régulier

Maintenant que nous possédons un utilisateur régulier pour une utilisation quotidienne, nous devons s’assurer que nous pouvons SSH directement au sein de notre compte.

**Note:** Avant d’avoir pu vérifier que vous pouvez bien vous connecté et utilisé `sudo` avec votre nouvel utilisateur, nous vous recommandons de rester connecté en tant que **root**. De cette manière, si vous avez des problèmes, vous pourrez diagnostiquer le problème et le résoudre ainsi que faire les modifications nécessaires en tant que **root**. Si vous utilisez DigitalOcean Droplet et vous rencontrez des problèmes avec votre connexion SSH **root** , vous pouvez suivre ce guide [log into the Droplet using the DigitalOcean Console] (en Anglais) ([https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-console-to-access-your-droplet](how-to-use-the-digitalocean-console-to-access-your-droplet)).

Le processus pour configurer l’accès SSH pour votre nouvel utilisateur dépendra si le compte **root** de votre serveur utilise un mot de passe ou des clés SSH pour l’authentification.

### Si le compte _Root_ utilise l’authentification par mot de passe

Si vous vous êtes connecté à votre compte **root** à l’aide d’un _mot de passe_, alors l’authentification par mot de passe est activée pour SSH. Vous pouvez SSH à votre nouveau compte d’utilisateur en ouvrant une nouvelle session terminale et utilisez SSH avec votre nouveau nom d’utilisateur :

    ssh sammy@your_server_ip

Après avoir entré votre mot de passe d’utilisateur régulier, vous serez connecté. Rappelez-vous, si vous avez besoin d’exécuter une commande avec des privilèges administratifs, tapez `sudo` avant comme ceci :

    sudo command_to_run

Vous serez invité à entrer votre mot de passe régulier d’utilisateur lorsque vous utilisez `sudo` pour la première fois chaque session (et de manière périodique par la suite).

Afin de renforcer la sécurité de votre serveur, **nous suggérons fortement de mettre en place des clés SSH plutôt que d’utiliser l’authentification par mot de passe**. Suivez notre guide sur [setting up SSH keys on Ubuntu 18.04] (en Anglais) ([https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys-on-ubuntu-1804](how-to-set-up-ssh-keys-on-ubuntu-1804)) afin de savoir comment configurer une authentification par clé.

### Si le compte “Root” utilise l’authentification par clé SSH.

Si vous vous êtes connecté à votre compte **root** en utilisant _des clés SSH_, alors l’authentification par mot de passe est _désactivée_ pour SSH. Vous devrez ajouter une copie de votre clé locale publique à votre nouveau fichier d’utilisateur `~/.ssh/authorized_keys` afin de vous connecter.

Étant donné que votre clé publique figure déjà au sein du fichier `~/.ssh/authorized_keys` de votre compte **root** sur le serveur, nous pouvons copier ce fichier et la structure de répertoires au sein de notre nouveau compte d’utilisateur dans notre session préexistante.

La manière la plus simple de copier les fichiers avec les droits et permissions appropriés est par la commande `rsync`. Cela copiera le répertoire `.ssh` de l’utilisateur **root** , préserver les permissions et modifier les propriétaires de fichier, le tout au sein d’une seule commande. Assurez-vous de modifier les parties surlignées de la commande ci-dessous afin qu’elles concordent avec votre nom d’utilisateur régulier :

**Note:** La commande `rsync` traite différemment les sources et destinations qui terminent avec une barre oblique que celles-ci terminant sans barre oblique. En utilisant la commande `rsync` ci-dessous, assurez-vous que la source du répertoire (`~/.ssh`) **n’inclut pas** de barre oblique (vérifiez pour vous assurer que vous n’utilisez pas `~/.ssh/`).

Si vous ajoutez une barre oblique par mégarde à la commande, `rsync` copiera le contenu du répertoire `~/.ssh` du compte **root** au répertoire d’origine de l’utilisateur au lieu de copier la structure complète du répertoire `~/.ssh`. Les fichiers se situeront à la mauvaise destination et SSH ne serait pas en mesure de les trouver et les utiliser.

    rsync --archive --chown=sammy:sammy ~/.ssh /home/sammy

Maintenant, ouvrez une nouvelle session terminale et utilisez SSH avec votre nouveau nom d’utilisateur :

    ssh sammy@your_server_ip

Vous devriez être connecté avec votre nouveau compte d’utilisateur sans devoir utiliser de mot de passe. N’oubliez pas, si vous devez exécuter une commande avec des privilèges administratifs, tapez `sudo` avant comme ceci :

    sudo command_to_run

Vous serez invité à entrer votre mot de passe régulier lorsque vous utilisez `sudo` pour la première fois à chaque session (et de manière périodique par la suite).

## Que pouvons-nous faire ensuite ?

À ce stade, vous avez une base solide pour votre serveur. Vous pouvez à présent installer quelconque logiciel dont vous avez besoin sur votre serveur.
