---
author: Justin Ellingwood
date: 2018-11-07
language: de
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/ersteinrichtung-des-servers-mit-ubuntu-18-04-de
---

# Ersteinrichtung des Servers mit Ubuntu 18.04

### Einführung

Wenn Sie erstmals einen neuen Ubuntu 18.04 Server einrichten, sollten Sie in der Anfangsphase einige dieser Konfigurationsschritte im Rahmen der Grundkonfiguration durchführen. Dadurch wird die Sicherheit und Nutzbarkeit Ihres Servers erhöht und Sie verfügen über eine solide Basis für weitere Aktionen.

**Bemerkung:** Der nachfolgende Leitfaden illustriert, wie die von uns vorgegebenen Schritte für neue Ubuntu 18.04 Server manuell durchgeführt werden. Die manuelle Durchführung dieses Durchgangs kann von Nutzen sein, um grundlegende Systemadministrationskenntnisse zu erlernen, und als Übungsaufgabe, um die Aktivitäten, die auf Ihrem Server vorgenommen werden, vollständig zu verstehen. Wenn Sie eine schnellere Inbetriebnahme wollen, können Sie als Alternative [unser initiales Server-Setup-Script ausführen](automating-initial-server-setup-with-ubuntu-18-04), das diese Schritte automatisiert.

## Schritt 1 — Als root anmelden

Um sich bei Ihrem Server anzumelden, müssen Sie die **öffentliche IP-Adresse Ihres Servers** kennen. Sie brauchen auch das Passwort, oder wenn Sie einen SSH-Key für Authentifizierung installiert haben, den privaten Schlüssel für das **root** -Nutzerkonto. Wenn Sie sich noch nicht bei Ihrem Server angemeldet haben, können Sie unserer Anleitung folgen, [wie Sie sich mit SSH an Ihr Droplet anbinden](how-to-connect-to-your-droplet-with-ssh), die diesen Prozess detailliert beschreibt.

Wenn Sie noch nicht mit Ihrem Server verbunden sind, dann melden Sie sich mithilfe des nachfolgenden Befehls (ersetzen Sie den hervorgehobenen Teil des Befehls mit der öffentlichen IP-Adresse Ihres Servers) als **root** -Nutzer an.

    ssh root@your_server_ip

Akzeptieren Sie die Warnung über die Authentizität des Hosts, wenn sie erscheint. Wenn Sie Passwort-Authentifizierung benutzen, geben Sie Ihr **root** -Passwort zur Anmeldung an. Wenn Sie einen Passwort-geschützten SSH-Schlüssel benutzen, werden Sie eventuell dazu aufgefordert, das Passwort bei der ersten Nutzung des Schlüssels in jeder Sitzung einzugeben. Wenn Sie sich das erste Mal mit einem Password am Server anmelden, können Sie auch dazu aufgefordert werden, das **root** -Password einzugeben.

### Über Root

Der **root** -Nutzer ist der administrative Nutzer in einem Linux-Umfeld mit umfassenden Rechten. Aufgrund der erhöhten Zugriffsberechtigung des **root** -Kontos, wird Ihnen von dessen regelmäßiger Nutzung _abgeraten_. Dies ist darauf zurückzuführen, dass ein Teil der dem **root** -Konto inhärenten Macht die Fähigkeit ist, äußerst zerstörende Änderungen, selbst nur durch Zufall, vorzunehmen.

Der nächste Schritt ist das Einrichten eines alternativen Nutzerkontos with einem reduzierten Einflussbereich für die tägliche Arbeit. Wir werden Ihnen zeigen, wie Sie zusätzliche Rechte während der erforderlichen Zeiträume erhalten können.

## Schritt 2 — Erstellen eines neuen Nutzers

Nachdem Sie sich als **root** angemeldet haben, sind wir bereit, das neue Nutzerkonto hinzuzufügen, bei dem wir uns in Zukunft anmelden werden.

Dieses Beispiel erstellt einen neuen Nutzer namens **Sammy** , aber Sie sollten ihn ersetzen durch einen Nutzernamen, den Sie bevorzugen:

    adduser sammy

Ihnen werden einige Fragen gestellt, beginnend mit dem Konto-Passwort.

Geben Sie ein starkes Passwort ein und füllen Sie zusätzliche Informationen nach Wahl ein. Dies ist nicht zwingend, und Sie können einfach die ‚Eingabe‘-Taste bei jedem Feld, das Sie überspringen wollen, drücken.

## Schritt 3 — Vergabe von administrativen Rechten

Jetzt haben wir ein neues Nutzerkonto mit normalen Kontozugriffsrechten. Manchmal müssen wir jedoch administrative Aufgaben ausführen.

Um sich nicht als normaler Nutzer abmelden und sich wieder als **root** -Nutzer anmelden zu müssen, können wir sogenannte „Superuser“ oder **root** -Rechte für unser normales Konto einrichten. Dies erlaubt unseren normalen Nutzern, Befehle mit administrativen Rechten auszuführen, indem sie das Wort ‚sudo‘ vor jeden Befehl setzen.

Um unserem neuen Nutzer diese Rechte zuzuweisen, müssen wir den neuen Nutzer der **sudo** -Gruppe zuordnen. Bei Ubuntu 18.04 sind Nutzer der **sudo** -Gruppe standardmäßig berechtigt, den ‚sudo‘-Befehl anzuwenden.

Führen Sie als **root** diesen Befehl aus, um Ihren neuen Nutzer der **sudo** -Gruppe zuzuordnen (ersetzen Sie das hervorgehobene Wort mit Ihrem neuen Nutzer):

    usermod -aG sudo sammy

Wenn Sie jetzt als normaler Nutzer angemeldet sind, können Sie ‚sudo‘ Befehlen vorstellen, um Aufgaben mit Superuser-Rechten auszuführen.

## Schritt 4 — Eine standardmäßige Firewall installieren

Ubuntu 18.04 Server können die UFW-Firewall nutzen, um sicherzustellen, dass nur Verbindungen mit bestimmten Dienstleistungen erlaubt sind. Wir können mit dieser Applikation sehr einfach eine standardmäßige Firewall installieren.

**Bemerkung:** Wenn Ihre Server mit DigitalOcean laufen, können Sie wahlweise auch [DigitalOcean Cloud Firewalls](an-introduction-to-digitalocean-cloud-firewalls) anstatt der UFW-Firewall nutzen. Wir empfehlen jeweils nur eine Firewall zu nutzen, um einander widersprechende Regeln, die schwierig zu debuggen sind, zu vermeiden.

Unterschiedliche Applikationen können nach Installierung ihre Profile bei UFW registrieren. Diese Profile erlauben UFW diese Applikationen namentlich zu managen. OpenSSH, der Service, mit dem wir jetzt an unseren Server anbinden können, hat ein Profil bei UFW registriert.

Dies wird angezeigt, wenn Sie folgendes eingeben:

    ufw app list

    OutputAvailable applications:
      OpenSSH

Wir müssen sicherstellen, dass die Firewall SSH-Verbindungen erlaubt, damit wir uns das nächste Mal wieder anmelden können. Wir können diese Verbindungen erlauben mit Eingabe von:

    ufw allow OpenSSH

Anschließend können wir die Firewall aktivieren mit Eingabe von:

    ufw enable

Tippen Sie „`y`“ und drücken Sie ‚Eingabe‘, um fortzufahren. Sie können sehen, dass SSH-Verbindungen noch erlaubt sind, wenn Sie folgendes eingeben:

    ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

Da **die Firewall gegenwärtig alle Verbindungen außer SSH blockiert** , ist es bei Installierung und Konfigurierung von zusätzlichen Services erforderlich, dass Sie die Firewall-Einstellungen anpassen, um annehmbaren Verkehr zuzulassen. Sie können einige UFW-Operationen in [dieser Anleitung erlernen](ufw-essentials-common-firewall-rules-and-commands).

## Schritt 5 — Aktivierung externer Zugriffe für Ihren normalen Nutzer

Nun, da wir einen normalen Nutzer für den regelmäßigen Gebrauch haben, müssen wir sicherstellen, dass wir mit SSH direkt an das Konto anbinden können.

**Bemerkung:** Bis zur Verifizierung, dass Sie sich anmelden und `sudo` mit Ihrem neuen Nutzer anwenden können, empfehlen wir Ihnen, als **root** angemeldet zu bleiben. Damit können Sie, falls Probleme auftauchen, Fehler beheben und erforderliche Änderungen als **root** vornehmen. Falls Sie ein DigitalOcean-Droplet nutzen und Probleme mit Ihrer **root** -SSH-Verbindung haben, können Sie sich beim [Droplet unter Verwendung der DigitalOcean-Konsole anmelden](how-to-use-the-digitalocean-console-to-access-your-droplet).

Der Konfigurierungs-Prozess für SSH-Zugang für Ihren neuen Nutzer hängt davon ab, ob das **root** -Konto Ihres Servers ein Passwort oder SSH-Schlüssel zur Authentifizierung nutzt.

### Wenn das Rootkonto Passwort-Authentifizierung nutzt.

Wenn Sie sich bei Ihrem **root** -Konto _mit einem Passwort_ anmelden, dann ist die Passwort-Authentifizierung für SSH aktiviert\*. Sie können eine SSH-Verbindung zu Ihrem neuen Nutzerkonto aufbauen, indem Sie eine neue Terminalsitzung öffnen und SSH mit Ihrem neuen Nutzernamen nutzen.

    ssh sammy@your_server_ip

Nach Eingabe Ihres normalen Nutzerpassworts sind Sie angemeldet. Beachten Sie, dass Sie bei erforderlicher Ausführung eines Befehls mit administrativen Rechten, das Wort ‚sudo‘ davorstellen müssen, wie folgt:

    sudo command_to_run

Sie werden nach Ihrem normalen Nutzerpasswort gefragt, wenn Sie ‚sudo‘ das erste Mal bei jeder Sitzung benutzen (und in periodischen Zeitabständen danach).

Zur Erhöhung der Sicherheit Ihres Servers **empfehlen wir dringend, SSH-Schlüssel zu erstellen, anstatt Passwort-Authentifizierung einzusetzen**. Folgen Sie unserer Anleitung [SSH-Schlüssel auf Ubuntu 18.04 herstellen](how-to-set-up-ssh-keys-on-ubuntu-1804), um die Konfigurierung schlüsselbasierter Authentifizierung zu erlernen.

### Wenn das Root-Konto schlüsselbasierte Authentifizierung nutzt.

Wenn Sie sich bei Ihrem **root** -Konto _mit SSH-Schlüsseln_ anmelden, dann ist die Passwort-Authentifizierung für SSH _deaktiviert_. Sie müssen der `~/.ssh/authorized_keys`Datei des neuen Nutzers eine Kopie Ihres lokalen öffentlichen Schlüssels hinzufügen, um sich erfolgreich anzumelden.

Da Ihr öffentlicher Schlüssel schon in der **Root** -Konto-Datei `~/.ssh/authorized_keys` auf dem Server enthalten ist, können wir diese Datei und Ordnerstruktur in unser neues Nutzerkonto in unserer bestehenden Sitzung kopieren.

Die einfachste Art und Weise, die Dateien mit der korrekten Eigentümern und Berechtigungen zu kopieren, ist mithilfe des Befehls ‚rsync‘. Dabei werden das ‚.ssh‘-Ordnerverzeichnis des **root** -Nutzers kopiert, die Berechtigungen erhalten und die Dateibesitzer modifiziert, alles mit einem einzigen Befehl. Stellen Sie sicher, dass Sie die hervorgehobenen Teile des nachfolgenden Befehls so ändern, dass sie mit dem Namen Ihres regelmäßigen Nutzers übereinstimmen.

**Bemerkung:** Der ‚rsync‘ Befehl behandelt Quellen und Ziele, die mit einem Schrägstrich enden, anders als jene ohne einen nachgestellten Schrägstrich. Wenn Sie ‚rsync‘ unten nutzen, stellen Sie sicher, dass das Quellverzeichnis (`~/.ssh`) **keinen** nachgestellten Schrägstrich beinhaltet (nachprüfen, dass Sie `~/.ssh/` nicht benutzen).

Sollten Sie ausversehen dem Befehl einen Schrägstrich hinzufügen, kopiert ‚rsync‘ den _Inhalt_ des `~/.ssh`-Verzeichnisses des **Root** -Kontos in das Home-Verzeichnis des ‚sudo‘-Nutzers anstatt die gesamte `~/.ssh` Verzeichnisstruktur zu kopieren. Die Dateien werden am falschen Ort abgelegt und SSH wird nicht in der Lage sein, sie zu finden und zu nutzen.

    rsync --archive --chown=sammy:sammy ~/.ssh /home/sammy

Sie können nun eine neue Terminalsitzung öffnen und SSH mit Ihrem neuen Nutzernamen nutzen:

    ssh sammy@your_server_ip

Sie sollten im neuen Nutzerkonto ohne Eingabe eines Passworts angemeldet sein. Beachten Sie, dass Sie bei erforderlicher Ausführung eines Befehls mit administrativen Rechten, das Wort ‚sudo‘ davorstellen müssen, wie folgt:

    sudo command_to_run

Sie werden nach Ihrem normalen Nutzerpasswort gefragt, wenn Sie ‚sudo‘ das erste Mal bei jeder Sitzung benutzen (und in periodischen Zeitabständen danach).

## Wie geht es weiter von hier aus?

An dieser Stelle haben Sie eine solide Grundlage für Ihren Server. Sie können nun die Software installieren, die Sie auf Ihrem Server benötigen.
