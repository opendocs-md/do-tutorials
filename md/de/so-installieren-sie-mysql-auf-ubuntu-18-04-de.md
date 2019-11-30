---
author: Mark Drake
date: 2019-04-25
language: de
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/so-installieren-sie-mysql-auf-ubuntu-18-04-de
---

# So installieren Sie MySQL auf Ubuntu 18.04

_Eine Vorgängerversion dieses Tutorials wurde von [Hazel Virdó](https://www.digitalocean.com/community/users/hazelnut) verfasst_

### Einführung

[MySQL](https://www.mysql.com/) ist ein quelloffenes Datenbankmanagementsystem, das häufig als Teil des beliebten [LAMP-Stacks](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04) (Linux, Apache, MySQL, PHP/Python/Perl) installiert wird. Zur Verwaltung seiner Daten verwendet es eine relationale Datenbank und SQL (Strukturierte Abfragesprache).

Die Kurzversion der Installation ist einfach: Aktualisieren Sie Ihren Paketindex, installieren Sie das `mysql-server`-Paket und führen Sie dann das mitgelieferte Sicherheitsskript aus.

    sudo apt update
    sudo apt install mysql-server
    sudo mysql_secure_installation

Dieses Tutorial erklärt, wie Sie die MySQL-Version 5.7 auf einem Ubuntu 18.04-Server installieren. Wenn Sie jedoch eine bestehende MySQL-Installation auf Version 5.7 aktualisieren möchten, können Sie stattdessen [diesen MySQL 5.7-Updateleitfaden](how-to-prepare-for-your-mysql-5-7-upgrade) lesen.

## Voraussetzungen

Um diesem Tutorial folgen zu können, benötigen Sie Folgendes:

- Einen Ubuntu 18.04-Server, der gemäß diesem [Installationshandbuch](initial-server-setup-with-ubuntu-18-04) eingerichtet wurde, einschließlich eines Nicht- **Root** -Benutzers mit `sudo`-Rechten und einer Firewall.

## Schritt 1 – MySQL installieren

In Ubuntu 18.04 ist standardmäßig nur die neueste Version von MySQL im APT-Paket-Repository enthalten. Zum Zeitpunkt der Erstellung ist das MySQL 5.7.

Aktualisieren Sie zur Installation den Paketindex auf Ihrem Server mit `apt`:

    sudo apt update

Installieren Sie dann das Standardpaket:

    sudo apt install mysql-server

Dadurch wird MySQL installiert, aber Sie werden nicht aufgefordert, ein Passwort festzulegen oder andere Konfigurationsänderungen vorzunehmen. Da Ihre MySQL-Installation dadurch unsicher wird, werden wir uns zunächst damit befassen.

## Schritt 2 — MySQL konfigurieren

Bei Neuinstallationen sollten Sie das mitgelieferte Sicherheitsskript ausführen. Dies ändert einige der weniger sicheren Standardoptionen für Dinge wie Remote-Root-Logins und Musterbenutzer. Bei älteren MySQL-Versionen mussten Sie das Datenverzeichnis auch manuell initialisieren, aber das erfolgt jetzt automatisch.

Führen Sie das Sicherheitsskript aus:

    sudo mysql_secure_installation

Dies führt Sie durch eine Reihe von Eingabeaufforderungen, in denen Sie einige Änderungen an den Sicherheitsoptionen Ihrer MySQL-Installation vornehmen können. Die erste Eingabeaufforderung fragt, ob Sie das validierte Passwort-Plugin einrichten möchten, mit dem Sie die Stärke Ihres MySQL-Passworts testen können. Unabhängig von Ihrer Wahl wird die nächste Eingabeaufforderung darin bestehen, ein Passwort für den MySQL- **Root** -Benutzer festzulegen. Geben Sie ein sicheres Passwort Ihrer Wahl ein und bestätigen Sie es anschließend.

Von dort aus können Sie `Y` und dann `ENTER` drücken, um die Standardwerte für alle folgenden Fragen zu übernehmen. Dadurch werden einige anonyme Benutzer und die Testdatenbank entfernt, Remote-Root-Logins deaktiviert und diese neuen Regeln geladen, so dass MySQL die von Ihnen vorgenommenen Änderungen sofort berücksichtigt.

Um das MySQL-Datenverzeichnis zu initialisieren, verwenden Sie `mysql_install_db` für Versionen vor 5.7.6 und `mysqld --initialize` für 5.7.6 und später. Wenn Sie jedoch MySQL aus der Debian-Distribution installiert haben, wie in Schritt 1 beschrieben, wurde das Datenverzeichnis automatisch initialisiert; Sie müssen nichts tun. Wenn Sie versuchen, den Befehl trotzdem auszuführen, wird folgender Fehler angezeigt:

Output

    mysqld: Can't create directory '/var/lib/mysql/' (Errcode: 17 - File exists)
    . . .
    2018-04-23T13:48:00.572066Z 0 [ERROR] Aborting

Beachten Sie, dass, obwohl Sie ein Passwort für den MySQL- **Root** -Benutzer festgelegt haben, dieser nicht konfiguriert ist, um sich bei der Verbindung mit der MySQL-Shell mit einem Passwort zu authentifizieren. Bei Bedarf können Sie diese Einstellung anpassen, indem Sie Schritt 3 folgen.

## Schritt 3 — (optional) Einstellen der Benutzerauthentifizierung und der Berechtigungen

In Ubuntu-Systemen mit MySQL 5.7 (und neueren Versionen) ist der MySQL- **Root** -Benutzer so eingestellt, dass er sich standardmäßig mit dem `auth_socket`-Plugin und nicht mit einem Passwort authentifiziert. Dies ermöglicht in vielen Fällen eine höhere Sicherheit und Benutzerfreundlichkeit, kann aber auch die Sache erschweren, wenn Sie einem externen Programm (z.B. phpMyAdmin) den Zugriff auf den Benutzer ermöglichen müssen.

Um ein Passwort für die Verbindung zu MySQL als **root** zu verwenden, müssen Sie die Authentifizierungsmethode von `auth_socket` auf `mysql_native_password` umstellen. Öffnen Sie dazu die MySQL-Eingabeaufforderung Ihres Terminals:

    sudo mysql

Als nächstes überprüfen Sie mit folgendem Befehl, welche Authentifizierungsmethode jedes Ihrer MySQL-Benutzerkonten verwendet:

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

In diesem Beispiel sehen Sie, dass der **Root** -Benutzer sich tatsächlich mit dem Plugin `auth_socket` authentifiziert. Um das **Root** -Konto für die Authentifizierung mit einem Passwort zu konfigurieren, führen Sie den folgenden Befehl `ALTER USER` aus. Achten Sie darauf, `password` in ein starkes Passwort Ihrer Wahl zu ändern, und beachten Sie, dass dieser Befehl das **Root** -Passwort ändert, das Sie in Schritt 2 festgelegt haben:

    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';

Führen Sie dann `FLUSH PRIVILEGES` aus, wodurch der Server angewiesen wird, die Berechtigungstabellen neu zu laden und die neuen Änderungen umzusetzen:

    FLUSH PRIVILEGES;

Überprüfen Sie die von jedem Ihrer Benutzer verwendeten Authentifizierungsmethoden erneut, um sicherzustellen, dass **root** sich nicht mehr mit dem `auth_socket`-Plugin authentifiziert:

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

Sie können in diesem Beispiel sehen, dass sich der MySQL-Benutzer **root** nun mit einem Passwort authentifiziert. Sobald Sie dies auf Ihrem eigenen Server bestätigt haben, können Sie die MySQL-Shell verlassen:

    exit

Alternativ dazu finden einige vielleicht, dass es besser zu ihrem Workflow passt, sich mit einem bestimmten Benutzer mit MySQL zu verbinden. Um einen solchen Benutzer anzulegen, öffnen Sie die MySQL-Shell erneut:

    sudo mysql

**Hinweis:** Wenn Sie die Passwortauthentifizierung für **root** aktiviert haben, wie in den vorigen Abschnitten beschrieben, müssen Sie einen anderen Befehl verwenden, um auf die MySQL-Shell zuzugreifen. Im Folgenden wird Ihr MySQL-Client mit regulären Benutzerrechten ausgeführt, und Sie erhalten nur durch Authentifizierung Administratorrechte innerhalb der Datenbank:

    mysql -u root -p

Erstellen Sie von dort aus einen neuen Benutzer und geben ihm ein sicheres Passwort:

    CREATE USER 'sammy'@'localhost' IDENTIFIED BY 'password';

Gewähren Sie Ihrem neuen Benutzer dann die entsprechenden Berechtigungen. Beispielsweise können Sie mit diesem Befehl die Benutzerrechte für alle Tabellen innerhalb der Datenbank sowie die Berechtigung zum Hinzufügen, Ändern und Entfernen von Benutzerrechten erteilen:

    GRANT ALL PRIVILEGES ON *.* TO 'sammy'@'localhost' WITH GRANT OPTION;

Beachten Sie, dass Sie an dieser Stelle den Befehl `FLUSH PRIVILEGES` nicht erneut ausführen müssen. Dieser Befehl wird nur benötigt, wenn Sie die Berechtigungstabellen mit Anweisungen wie `INSERT`, `UPDATE` oder `DELETE` ändern. Da Sie einen neuen Benutzer angelegt haben und keinen bestehenden ändern, ist `FLUSH PRIVILEGES` hier nicht erforderlich.

Danach verlassen Sie die MySQL-Shell:

    exit

Abschließend testen wir die MySQL-Installation.

## Schritt 4 — MySQL testen

Unabhängig davon, wie Sie es installiert haben, sollte MySQL automatisch gestartet sein. Um dies zu testen, überprüfen Sie den Status.

    systemctl status mysql.service

Sie werden folgende Meldung sehen:

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

Wenn MySQL nicht ausgeführt wird, können Sie es mit `sudo systemctl start mysql` starten.

Für eine zusätzliche Überprüfung können Sie versuchen, sich mit der Datenbank zu verbinden, indem Sie das Tool `mysqladmin` verwenden, ein Client, mit dem Sie administrative Befehle ausführen können. Dieser Befehl besagt beispielsweise, sich als **root** (`-u root`) mit MySQL zu verbinden, ein Passwort (`-p`) einzugeben und die Version zurückzugeben.

    sudo mysqladmin -p -u root version

Sie sollten folgende Meldung sehen:

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

Das bedeutet, dass MySQL ausgeführt wird.

## Fazit

Sie haben nun einen MySQL-Basissetup auf Ihrem Server installiert. Hier sind einige Beispiele für die nächsten Schritte, die Sie unternehmen können:

- [Durchführung einiger zusätzlicher Sicherheitsmaßnahmen](how-to-secure-mysql-and-mariadb-databases-in-a-linux-vps)
- [Datenverzeichnis verschieben](how-to-move-a-mysql-data-directory-to-a-new-location-on-ubuntu-16-04)
- [MySQL-Server mit SaltStack verwalten](saltstack-infrastructure-creating-salt-states-for-mysql-database-servers)
