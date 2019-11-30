---
author: Justin Ellingwood, Kathleen Juell
date: 2019-04-25
language: de
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/so-installieren-sie-nginx-auf-ubuntu-18-04-de
---

# So installieren Sie Nginx auf Ubuntu 18.04

### Einführung

Nginx ist einer der beliebtesten Webserver der Welt und verantwortlich für das Hosting einiger der größten und verkehrsreichsten Webseiten im Internet. Er ist in den meisten Fällen ressourcenfreundlicher als Apache und kann als Webserver oder Umkehrproxy eingesetzt werden.

In diesem Leitfaden wird erläutert, wie Sie Nginx auf Ihrem Ubuntu 18.04-Server installieren.

## Voraussetzungen

Bevor Sie mit diesem Leitfaden beginnen, sollten Sie einen regulären, nicht root-fähigen Benutzer mit sudo-Rechten auf Ihrem Server konfigurieren. Sie können lernen, wie Sie ein reguläres Benutzerkonto konfigurieren, indem Sie unserem [Installationshandbuch für Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04) folgen.

Wenn Sie über ein Konto verfügen, melden Sie sich als Nicht-Root-Benutzer an, um zu beginnen.

## Schritt 1 – Nginx installieren

Da Nginx in den Standard-Repositories von Ubuntu verfügbar ist, kann es über das `apt` -Paketsystem aus diesen Repositories installiert werden.

Dies ist unsere erste Interaktion mit dem `apt` -Paketsystem in dieser Sitzung, daher werden wir unseren lokalen Paketindex aktualisieren, so dass wir Zugriff auf die neuesten Paketlisten haben. Anschließend können wir `nginx` installieren:

    sudo apt update
    sudo apt install nginx

Nachdem Sie die Vorgehensweise akzeptiert haben, installiert `apt` Nginx und alle erforderlichen Anhänge auf Ihrem Server.

## Schritt 2 – Firewall anpassen

Um Nginx zu testen, muss die Firewall-Software angepasst werden, um den Zugriff auf den Dienst zu ermöglichen. Nginx registriert sich bei der Installation als Dienst mit `ufw`, wodurch ein unkomplizierter Zugriff auf Nginx möglich ist.

Die Anwendungskonfigurationen auflisten, mit denen `ufw` vertraut ist, indem Sie eingeben:

    sudo ufw app list

Sie sollten eine Auflistung der Anwendungsprofile erhalten:

    OutputAvailable applications:
      Nginx Full
      Nginx HTTP
      Nginx HTTPS
      OpenSSH

Wie Sie sehen können, gibt es für Nginx drei Profile:

- **Nginx Vollständig** : Dieses Profil öffnet sowohl Port 80 (normaler, unverschlüsselter Webverkehr) als auch Port 443 (TLS/SSL-verschlüsselter Datenverkehr)
- **Nginx HTTP** : Dieses Profil öffnet nur Port 80 (normaler, unverschlüsselter Webverkehr)
- **Nginx HTTPS** : Dieses Profil öffnet nur Port 443 (TLS/SSL-verschlüsselter Datenverkehr)

Es wird empfohlen, das restriktivste Profil zu aktivieren, das den von Ihnen konfigurierten Datenverkehr noch zulässt. Da wir in diesem Handbuch noch kein SSL für unseren Server konfiguriert haben, müssen wir nur den Datenverkehr auf Port 80 zulassen.

Aktivieren Sie dies durch folgende Eingabe:

    sudo ufw allow 'Nginx HTTP'

Um die Änderung zu überprüfen, geben Sie Folgendes ein:

    sudo ufw status

Sie sollten sehen, dass der HTTP-Verkehr in der angezeigten Ausgabe erlaubt ist:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Nginx HTTP ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Nginx HTTP (v6) ALLOW Anywhere (v6)

## Schritt 3 – Überprüfen Ihres Webservers

Am Ende des Installationsprozesses startet Ubuntu 18.04 Nginx. Der Webserver sollte bereits in Betrieb sein.

Mit dem `systemd` init-System können wir überprüfen, ob der Dienst ausgeführt wird, indem wir Folgendes eingeben:

    systemctl status nginx

    Output● nginx.service - A high performance web server and a reverse proxy server
       Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
       Active: active (running) since Fri 2018-04-20 16:08:19 UTC; 3 days ago
         Docs: man:nginx(8)
     Main PID: 2369 (nginx)
        Tasks: 2 (limit: 1153)
       CGroup: /system.slice/nginx.service
               ├─2369 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
               └─2380 nginx: worker process

Wie Sie oben sehen können, scheint der Dienst erfolgreich gestartet zu sein. Der beste Weg, dies zu testen, ist jedoch, eine Seite bei Nginx anzufordern.

Durch die Navigation zur IP-Adresse Ihres Servers können Sie auf die standardmäßige Nginx-Landseite zugreifen, um zu bestätigen, dass die Software ordnungsgemäß ausgeführt wird. Wenn Sie die IP-Adresse Ihres Servers nicht kennen, können Sie sie auf verschiedene Arten erhalten.

Versuchen Sie, dies an der Eingabeaufforderung Ihres Servers einzugeben:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Sie erhalten ein paar Zeilen zurück. Sie können diese jeweils in Ihrem Webbrowser ausprobieren, um zu sehen, ob sie funktionieren.

Eine Alternative ist die Eingabe, die Ihnen Ihre öffentliche IP-Adresse aus der Sicht eines anderen Standorts im Internet geben sollte:

    curl -4 icanhazip.com

Wenn Sie die IP-Adresse Ihres Servers haben, geben Sie diese in die Adressleiste Ihres Browsers ein:

    http://your_server_ip

Sie sollten die standardmäßige Anmeldeseite von Nginx sehen:

![Nginx-Standardseite](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_1604/default_page.png)

Diese Seite ist in Nginx enthalten, um Ihnen zu zeigen, dass der Server ordnungsgemäß arbeitet.

## Schritt 4 – Verwaltung des Nginx-Prozesses

Nun, da Sie Ihren Webserver in Betrieb haben, lassen Sie uns einige grundlegende Verwaltungsbefehle durchgehen.

Um Ihren Webserver zu stoppen, geben Sie Folgendes ein:

    sudo systemctl stop nginx

Um den Webserver zu starten, wenn er gestoppt wird, geben Sie Folgendes ein:

    sudo systemctl start nginx

Um den Dienst zu stoppen und dann erneut zu starten, geben Sie Folgendes ein:

    sudo systemctl restart nginx

Wenn Sie lediglich Konfigurationsänderungen vornehmen, kann Nginx oft neu laden, ohne die Verbindungen zu verlieren. Geben Sie dazu Folgendes ein:

    sudo systemctl reload nginx

Standardmäßig ist Nginx so konfiguriert, dass es automatisch startet, wenn der Server bootet. Wenn Sie dies nicht wünschen, können Sie dieses Verhalten durch folgende Eingabe deaktivieren:

    sudo systemctl disable nginx

Um den Dienst beim Booten wieder zu aktivieren, können Sie Folgendes eingeben:

    sudo systemctl enable nginx

## Schritt 5 – Einrichten von Serverblöcken (empfohlen)

Bei Verwendung des Nginx-Webservers können_Serverblöcke_ (ähnlich wie virtuelle Hosts im Apache) verwendet werden, um Konfigurationsdetails zu kapseln und mehr als eine Domäne von einem einzigen Server aus zu hosten. Wir werden eine Domäne namens **example.com** einrichten, aber Sie sollten diese durch Ihren eigenen \*\* Domänennamen ersetzen\*\*. Weitere Informationen zum Einrichten eines Domänennamens mit DigitalOcean finden Sie in unserer [Einführung in DigitalOcean DNS](an-introduction-to-digitalocean-dns).

Auf Ubuntu 18.04 hat Nginx einen Serverblock aktiviert, der standardmäßig so konfiguriert ist, dass er Dokumente aus einem Verzeichnis unter `/var/wwww/html bedient`. Dies funktioniert zwar gut für einen einzelnen Standort, kann aber bei mehreren Standorten unpraktisch werden. Anstatt `/var/www/html` zu ändern, erstellen wir eine Verzeichnisstruktur in `/var/www` für unsere **example.com** -Seite, indem wir `/var/www/html` als Standardverzeichnis beibehalten, das zu bedienen ist, wenn eine Kundenanfrage mit keiner anderen Seite übereinstimmt.

Erstellen Sie das Verzeichnis **example.com** wie folgt und verwenden Sie `-p` um alle notwendigen übergeordneten Verzeichnisse zu erstellen:

    sudo mkdir -p /var/www/example.com/html

Als nächstes weisen Sie dem Verzeichnis mit der Umgebungsvariablen `$USER` das Besitzerrecht zu:

    sudo chown -R $USER:$USER /var/www/example.com/html

Die Berechtigungen Ihrer Web-Roots sollten korrekt sein, wenn Sie Ihren `umask` -Wert nicht geändert haben, aber Sie können dies überprüfen, indem Sie Folgendes eingeben:

    sudo chmod -R 755 /var/www/example.com

Als nächstes erstellen Sie ein Muster einer `index.html` -Seite mit `nano` oder Ihrem bevorzugten Editor:

    nano /var/www/example.com/html/index.html

Fügen Sie darin folgende Beispiel-HTML hinzu:

/var/www/example.com/html/index.html

    <html>
        <head>
            <title>Welcome to Example.com!</title>
        </head>
        <body>
            <h1>Success! The example.com server block is working!</h1>
        </body>
    </html>

Speichern und schließen Sie die Datei nach Abschluss des Vorgangs.

Damit Nginx diese Inhalte bereitstellen kann, ist es notwendig, einen Serverblock mit den richtigen Anweisungen zu erstellen. Anstatt die Standardkonfigurationsdatei direkt zu ändern, machen wir eine neue unter `/etc/nginx/sites-available/example.com`:

    sudo nano /etc/nginx/sites-available/example.com

Fügen Sie den folgenden Konfigurationsblock ein, der dem Standard ähnlich ist, aber für unser neues Verzeichnis und unseren neuen Domänennamen aktualisiert wurde:

/etc/nginx/sites-available/example.com

    server {
            listen 80;
            listen [::]:80;
    
            root /var/www/example.com/html;
            index index.html index.htm index.nginx-debian.html;
    
            server_name example.com www.example.com;
    
            location / {
                    try_files $uri $uri/ =404;
            }
    }

Beachten Sie, dass wir die `Root`-Konfiguration in unserem neuen Verzeichnis und den `server_name` in unserem Domänennamen aktualisiert haben.

Anschließend aktivieren wir die Datei, indem wir einen Link zu dem `sites-enabled`-Verzeichnis erstellen, aus dem Nginx beim Start liest:

    sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/

Zwei Serverblöcke sind nun aktiviert und konfiguriert, um auf Anfragen basierend auf ihren `listen-` und `server_name`-Anweisungen zu reagieren (Sie können [hier](understanding-nginx-server-and-location-block-selection-algorithms) mehr darüber erfahren, wie Nginx diese Anweisungen verarbeitet):

- `example.com`: Beantwortet Anfragen für example.com`und`[www.example.com`](http://www.example.com%60).
- `default`: Beantwortet alle Anfragen auf Port 80, die nicht mit den anderen beiden Blöcken übereinstimmen.

Um ein mögliches Hash-Bucket-Speicherproblem zu vermeiden, das durch das Hinzufügen zusätzlicher Servernamen entstehen kann, ist es notwendig, einen Einzelwert in der Datei `/etc/nginx/nginx.conf` anzupassen. Die Datei öffnen:

    sudo nano /etc/nginx/nginx.conf

Finden Sie den Befehl `server_names_hash_bucket_size` und entfernen Sie das Symbol `#`, um die Zeile zu entkommentieren:

/etc/nginx/nginx.conf

    ...
    http {
        ...
        server_names_hash_bucket_size 64;
        ...
    }
    ...

Prüfen Sie anschließend, ob in Ihren Nginx-Dateien keine Syntaxfehler vorhanden sind:

    sudo nginx -t

Speichern und schließen Sie die Datei nach Abschluss des Vorgangs.

Wenn es keine Probleme gibt, starten Sie Nginx neu, um Ihre Änderungen zu aktivieren:

    sudo systemctl restart nginx

Nginx sollte nun Ihren Domänennamen bereitstellen. Dies können Sie testen, indem Sie zu `http://example.com` navigieren, wo Sie so etwas sehen sollten:

![Nginx erster Serverblock](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_server_block_1404/first_block.png)

## Schritt 6 – Vertrautmachen mit wichtigen Nginx-Dateien und -Verzeichnissen

Da Sie nun wissen, wie Sie den Nginx-Dienst selbst verwalten, sollten Sie sich einige Minuten Zeit nehmen, um sich mit einigen wichtigen Verzeichnissen und Dateien vertraut zu machen.

### Inhalt

- `/var/www/html`: Der eigentliche Webinhalt, der standardmäßig nur aus der Standard-Nginx-Seite besteht, die Sie zuvor gesehen haben, wird aus dem Verzeichnis `/var/wwww/html` bereitgestellt. Dies kann durch Anpassen der Nginx-Konfigurationsdateien geändert werden.

### Serverkonfiguration

- `/etc/nginx`: Das Nginx-Konfigurationsverzeichnis. Alle Nginx-Konfigurationsdateien befinden sich hier.
- `/etc/nginx/nginx.conf`: Die Hauptkonfigurationsdatei von Nginx. Dies kann modifiziert werden, um Änderungen an der globalen Nginx-Konfiguration vorzunehmen.
- `/etc/nginx/sites-available/`: Das Verzeichnis, in dem die Serverblöcke pro Standort gespeichert werden können. Nginx verwendet die Konfigurationsdateien in diesem Verzeichnis nur dann, wenn sie mit dem `sites-enabled`-Verzeichnis verknüpft sind. In der Regel wird die gesamte Konfiguration des Serverblocks in diesem Verzeichnis durchgeführt und dann durch Verknüpfung mit dem anderen Verzeichnis aktiviert.
- `/etc/nginx/sites-enabled/`: Das Verzeichnis, in dem die aktivierten Serverblöcke pro Standort gespeichert sind. In der Regel werden diese durch die Verknüpfung mit Konfigurationsdateien erstellt, die sich in dem Verzeichnis `sites-available` befinden.
- `/etc/nginx/snippets`: Dieses Verzeichnis enthält Konfigurationsfragmente, die an anderer Stelle in der Nginx-Konfiguration eingefügt werden können. Potenziell wiederholbare Konfigurationssegmente sind gute Kandidaten für das Repaktorieren in Einzelteile.

### Serverprotokolle

- `/var/log/nginx/access.log`: Jede Anfrage an Ihren Webserver wird in dieser Protokolldatei aufgezeichnet, sofern Nginx nicht anders konfiguriert ist.
- `/var/log/nginx/error.log`: Alle Nginx-Fehler werden in diesem Protokoll festgehalten.

## Fazit

Da Ihr Webserver nun installiert ist, haben Sie viele Optionen für die Art der zu erstellenden Inhalte und die Technologien, die Sie verwenden möchten, um ein reichhaltigeres Erlebnis zu schaffen.

Wenn Sie einen vollständigeren Applikationsstapel erstellen möchten, lesen Sie diesen Artikel, [wie Sie einen LEMP-Stapel unter Ubuntu 18.04](how-to-install-linux-nginx-mysql-php-lemp-stack-ubuntu-18-04) konfigurieren können.
