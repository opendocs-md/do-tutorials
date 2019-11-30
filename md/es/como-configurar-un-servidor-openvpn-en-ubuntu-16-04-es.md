---
author: Justin Ellingwood
date: 2016-12-12
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-configurar-un-servidor-openvpn-en-ubuntu-16-04-es
---

# ¿Cómo Configurar un Servidor OpenVPN en Ubuntu 16.04?

### Introducción

¿Quiere acceder a Internet de forma segura desde tu teléfono inteligente o portátil cuando está conectado a una red no confiable como la WiFi de un hotel o cafetería? Una [Red Privada Virtual](https://en.wikipedia.org/wiki/Virtual_private_network) (VPN) le permite atravesar redes no confiables de forma privada y segura como si estuviera en una red privada. El tráfico emerge del servidor VPN y continúa su viaje hasta el destino.

Cuando se combina con [conexiones HTTPS](https://en.wikipedia.org/wiki/HTTPS), esta configuración le permite proteger sus inicios de sesión y transacciones inalámbricas. Puede evitar las restricciones geográficas y la censura, y proteger su ubicación y cualquier tráfico HTTP no cifrado de la red no confiable.

[OpenVPN](https://openvpn.net/) es una solución VPN de Secure Socket Layer (SSL) de código abierto que ofrece una amplia gama de configuraciones. En este tutorial, configuraremos un servidor OpenVPN en un Droplet y luego configuraremos el acceso a él desde Windows, OS X, iOS y Android. Este tutorial mantendrá los pasos de instalación y configuración tan simples como sea posible para estas configuraciones.

## Requisitos Previos

Para completar este tutorial, necesitará tener acceso a un servidor Ubuntu 16.04.

Deberá configurar un usuario que no sea root, con privilegios de `sudo` antes de iniciar esta guía. Puede seguir nuestra [Guía de Configuración Inicial del Servidor Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) para configurar un usuario con los permisos adecuados. El tutorial enlazado también configurará un **firewall** , que asumiremos está en su lugar durante esta guía.

Cuando esté listo para comenzar, inicie sesión en su servidor Ubuntu como usuario `sudo` y continúe a continuación.

## Paso 1 — Instalar OpenVPN

Para empezar, instalaremos OpenVPN en nuestro servidor. OpenVPN está disponible en los repositorios predeterminados de Ubuntu, por lo que podemos usar `apt` para la instalación. También instalaremos el paquete `easy-rsa`, que nos ayudará a configurar una CA interna (autoridad de certificación) para usarla con nuestra VPN.

Para actualizar el índice del paquete del servidor e instalar los paquetes necesarios, escriba:

    sudo apt-get update
    sudo apt-get install openvpn easy-rsa

El software necesario está ahora en el servidor, listo para ser configurado.

## Paso 2 — Configurar el Directorio de CA

OpenVPN es una TLS/SSL VPN. Esto significa que utiliza certificados para cifrar el tráfico entre el servidor y los clientes. Para emitir certificados de confianza, tendremos que configurar nuestra propia autoridad de certificación simple (CA).

Para empezar, podemos copiar el directorio de plantillas `easy-rsa` en nuestro directorio personal con el comando `make-cadir`:

    make-cadir ~/openvpn-ca

Mueva el directorio recién creado para comenzar a configurar la CA:

    cd ~/openvpn-ca

## Paso 3 — Configurar las Variables de CA

Para configurar los valores que usará nuestra CA, debemos editar el archivo `vars` dentro del directorio. Abra ese archivo ahora en su editor de texto:

    nano vars

Dentro, encontrará algunas variables que se pueden ajustar para determinar cómo se crearán sus certificados. Sólo tenemos que preocuparnos por algunos de estos.

Hacia la parte inferior del archivo, busque la configuración que establece los valores predeterminados de campo para los nuevos certificados. Debe ser algo como esto:

~/openvpn-ca/vars

    . . .
    
    export KEY_COUNTRY="US"
    export KEY_PROVINCE="CA"
    export KEY_CITY="SanFrancisco"
    export KEY_ORG="Fort-Funston"
    export KEY_EMAIL="me@myhost.mydomain"
    export KEY_OU="MyOrganizationalUnit"
    
    . . .

Edite los valores en rojo a su preferencia, pero no los deje en blanco:

~/openvpn-ca/vars

    . . .
    
    export KEY_COUNTRY="US"
    export KEY_PROVINCE="NY"
    export KEY_CITY="New York City"
    export KEY_ORG="DigitalOcean"
    export KEY_EMAIL="admin@example.com"
    export KEY_OU="Community"
    
    . . .

Mientras estamos aquí, también editaremos el valor `KEY_NAME` justo debajo de esta sección, que rellena el campo de asunto. Para mantener esto simple, lo llamaremos `server` en esta guía:

~/openvpn-ca/vars

    export KEY_NAME="server"

Cuando termine, guarde y cierre el archivo.

## Paso 4 — Construir el Certificado de Autoridad

Ahora, podemos usar las variables que establecemos y las utilidades `easy-rsa` para construir nuestra autoridad de certificación.

Asegúrese de que se encuentra en el directorio de CA y, a continuación, genere el archivo `vars` que acaba de editar:

    cd ~/openvpn-ca
    source vars

Debería ver lo siguiente si se generó correctamente:

    OutputNOTE: If you run ./clean-all, I will be doing a rm -rf on /home/sammy/openvpn-ca/keys

Asegúrese de que operamos en un entorno limpio escribiendo:

    ./clean-all

Ahora, podemos construir nuestra CA raíz escribiendo:

    ./build-ca

Esto iniciará el proceso de creación de la llave de autoridad de certificado raíz y el certificado. Dado que llenamos el archivo `vars`, todos los valores deben rellenarse automáticamente. Simplemente pulse **Enter** a través de las indicaciones para confirmar las selecciones:

    OutputGenerating a 2048 bit RSA private key
    ..........................................................................................+++
    ...............................+++
    writing new private key to 'ca.key'
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [US]:
    State or Province Name (full name) [NY]:
    Locality Name (eg, city) [New York City]:
    Organization Name (eg, company) [DigitalOcean]:
    Organizational Unit Name (eg, section) [Community]:
    Common Name (eg, your name or your server's hostname) [DigitalOcean CA]:
    Name [server]:
    Email Address [admin@email.com]:

Ahora tenemos una CA que se puede utilizar para crear el resto de los archivos que necesitamos.

## Paso 5 — Crear los certificados del servidor, llaves y archivos cifrados

A continuación, generaremos nuestro certificado de servidor y par de llaves, así como algunos archivos adicionales utilizados durante el proceso de cifrado.

Comience por generar el certificado de servidor OpenVPN y el par de llaves. Podemos hacerlo escribiendo:

**Nota:** Si elige otro nombre que no sea `server`, tendrá que ajustar algunas de las siguientes instrucciones. Por ejemplo, al copiar los archivos generados en el directorio `/etc/openvpn`, tendrá que sustituir los nombres correctos. También tendrá que modificar posteriormente el archivo `/etc/openvpn/server.conf` para apuntar correctamente a los archivos `.crt` y `.key`.

    ./build-key-server server

Una vez más, los avisos tendrán valores predeterminados basados ​​en el argumento que acabamos de pasar (`servidor`) y el contenido de nuestro archivo `vars` que hemos obtenido.

Puede aceptar los valores predeterminados presionando **Enter**. _No_ introduzca una contraseña de desafío para esta configuración. Al final, tendrá que ingresar **y** a las dos preguntas para firmar y confirmar el certificado:

    Output. . .
    
    Certificate is to be certified until May 1 17:51:16 2026 GMT (3650 days)
    Sign the certificate? [y/n]:y
    
    
    1 out of 1 certificate requests certified, commit? [y/n]y
    Write out database with 1 new entries
    Data Base Updated

A continuación, generaremos algunos otros elementos. Podemos generar una llave fuerte Diffie-Hellman para utilizar durante el intercambio de llaves escribiendo:

    ./build-dh

Esto puede tardar unos minutos en completarse.

Posteriormente, podemos generar una firma HMAC para fortalecer las capacidades de verificación de integridad TLS del servidor:

    openvpn --genkey --secret keys/ta.key

## Paso 6 — Generar un Certificado de Cliente y un Par de Llaves

A continuación, podemos generar un certificado de cliente y un par de llaves. Aunque esto se puede hacer en la máquina cliente y luego firmado por el servidor/CA, por motivos de seguridad, para esta guía se generará la llave firmada en el servidor por motivos de simplicidad.

Generaremos una llave/certificado de cliente único para esta guía, pero si tiene más de un cliente, puede repetir este proceso tantas veces como desee. Pasando un valor único al script para cada cliente.

Como puede volver a este paso más adelante, volveremos a crear el archivo `vars`. Usaremos `client1` como el valor de nuestro primer certificado/par de llaves para esta guía.

Para generar credenciales sin contraseña, para ayudar en las conexiones automatizadas, utilice el mandato `build-key` de esta manera:

    cd ~/openvpn-ca
    source vars
    ./build-key client1

Si en su lugar, desea crear un conjunto de credenciales protegido por contraseña, utilice el comando `build-key-pass`:

    cd ~/openvpn-ca
    source vars
    ./build-key-pass client1

Una vez más, los valores por defecto deben estar poblados, por lo que sólo puede pulsar **Enter** para continuar. Deje la contraseña de desafío en blanco y asegúrese de escribir **y** para las solicitudes que le pregunten si firmar y confirmar el certificado.

## Paso 7 — Configurar el Servicio OpenVPN

A continuación, podemos comenzar a configurar el servicio OpenVPN utilizando las credenciales y los archivos que hemos generado.

### Copiar los Archivos en el Directorio de OpenVPN

Para comenzar, necesitamos copiar los archivos que necesitamos al directorio de configuración de `/etc/openvpn`.

Podemos comenzar con todos los archivos que acabamos de generar. Estos se colocaron dentro del directorio `~/openvpn-ca/keys` a medida que se creaban. Necesitamos mover nuestro cert y llave de CA, nuestro cert y llave de servidor, la firma de HMAC, y el archivo de Diffie-Hellman:

    cd ~/openvpn-ca/keys
    sudo cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn

A continuación, necesitamos copiar y descomprimir un archivo de configuración OpenVPN de ejemplo en el directorio de configuración para que podamos usarlo como base para nuestra configuración:

    gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf

### Ajuste la Configuración de OpenVPN

Ahora que nuestros archivos están en su lugar, podemos modificar el archivo de configuración del servidor:

    sudo nano /etc/openvpn/server.conf

#### Configuracion Básica

En primer lugar, encuentre la sección HMAC buscando la directiva `tls-auth`. Eliminar el “;” Para descomentar la línea `tls-auth`. Debajo de esto, agregue el parámetro de `key-direction` ajustandolo a “0”:

/etc/openvpn/server.conf

    tls-auth ta.key 0 # This file is secret
    key-direction 0

A continuación, encuentre la sección sobre cifrado criptográfico buscando las líneas comentadas de `cipher`. El cifrado `AES-128-CBC` ofrece un buen nivel de cifrado y está bien soportado. Eliminar el “;” Para descomentar la línea `cipher AES-128-CBC`:

/etc/openvpn/server.conf

    cipher AES-128-CBC

Debajo de esto, agregue una línea de `auth` para seleccionar el algoritmo de resumen de mensajes HMAC. Para esto, `SHA256` es una buena opción:

/etc/openvpn/server.conf

    auth SHA256

Finalmente, busque la configuración de `user` y `group` y quite el “;” Al principio de la línea para descomentar:

    user nobody
    group nogroup

#### (Opcional) Subir Cambios DNS para Redirigir Todo el Tráfico a Través de la VPN

La configuración anterior creará la conexión VPN entre las dos máquinas, pero no forzará ninguna conexión a utilizar el túnel. Si desea utilizar la VPN para enrutar todo su tráfico, es probable que desee subir la configuración de DNS a los equipos cliente.

Usted puede hacer esto, descomentando algunas directivas que configurarán máquinas cliente para redirigir todo el tráfico web a través de la VPN. Busque la sección de `redirect-gateway` y quite el punto y coma “;” Desde el principio de la línea de `redirect-gateway` para descomentarlo:

/etc/openvpn/server.conf

    push "redirect-gateway def1 bypass-dhcp"

Justo debajo de esto, encuentre la sección `dhcp-option`. De nuevo, quite el “;” Desde delante de ambas líneas para descomentarlas:

/etc/openvpn/server.conf

    push "dhcp-option DNS 208.67.222.222"
    push "dhcp-option DNS 208.67.220.220"

Esto debería ayudar a los clientes a reconfigurar su configuración DNS para usar el túnel VPN como gateway predeterminada.

#### (Opcional) Ajuste el puerto y el protocolo

De forma predeterminada, el servidor OpenVPN utiliza el puerto 1194 y el protocolo UDP para aceptar las conexiones del cliente. Si necesita utilizar un puerto diferente debido a entornos de red restrictivos en los que pueden estar sus clientes, puede cambiar la opción de puerto `port`. Si no está hospedando contenido web en su servidor OpenVPN, el puerto 443 es una opción popular ya que normalmente se permite a través de reglas de firewall.

/etc/openvpn/server.conf

    # Optional!
    port 443

A menudo, el protocolo puede restringir ese puerto también. Si es así, cambie `proto` de UDP a TCP:

/etc/openvpn/server.conf

    # Optional!
    proto tcp

Si no tiene necesidad de utilizar un puerto diferente, es mejor dejar estas dos configuraciones como su valor predeterminado.

#### (Opcional) Señale Credenciales No Predeterminadas

Si ha seleccionado un nombre diferente durante el comando previo `./build-key-server` , modifique las líneas `cert` y `key` que vea para apuntar a los archivos `.crt` y `.key` apropiados. Si utilizó el servidor predeterminado, ya debería estar configurado correctamente:

/etc/openvpn/server.conf

    cert server.crt
    key server.key

Cuando haya terminado, guarde y cierre el archivo.

## Paso 8 — Ajuste la Configuración de Red del Servidor

A continuación, necesitamos ajustar algunos aspectos de la red del servidor para que OpenVPN pueda enrutar correctamente el tráfico.

## Permitir reenvío IP

Primero, necesitamos permitir que el servidor redirija tráfico. Esto es bastante esencial para la funcionalidad que queremos que nuestro servidor VPN proporcione.

Podemos ajustar esta configuración modificando el archivo `/etc/sysctl.conf`

    sudo nano /etc/sysctl.conf

En el archivo, busque la línea que establece `net.ipv4.ip_forward`. Quite el carácter “ **#** ” desde el principio de la línea para descomentar esa configuración:

/etc/sysctl.conf

    net.ipv4.ip_forward=1

Guarde y cierre el archivo cuando haya terminado.

Para leer el archivo y ajustar los valores de la sesión actual, escriba:

    sudo sysctl -p

### Ajuste las Reglas UFW a las Conexiones del Cliente Masquerade

Si siguió la guía de configuración inicial del servidor Ubuntu 16.04 en los requisitos previos, debería tener instalado el firewall UFW. Independientemente de si usas el firewall para bloquear el tráfico no deseado (lo cual casi siempre deberías hacer), necesitamos el firewall en esta guía para manipular parte del tráfico que entra en el servidor. Necesitamos modificar el archivo de reglas para configurar enmascaramiento, un concepto de `iptables` que proporciona NAT dinámico al instante para enrutar correctamente las conexiones del cliente.

Antes de abrir el archivo de configuración del firewall para agregar enmascaramiento, necesitamos encontrar la interfaz de red pública de nuestra máquina. Para ello, escriba:

    ip route | grep default

Su interfaz pública debe seguir la palabra “dev”. Por ejemplo, este resultado muestra la interfaz denominada wlp11s0, que se resalta a continuación:

    Outputdefault via 203.0.113.1 dev wlp11s0 proto static metric 600

Cuando tenga la interfaz asociada con su ruta predeterminada, abra el archivo `/etc/ufw/before.rules` para agregar la configuración relevante:

    sudo nano /etc/ufw/before.rules

Este archivo controla la configuración que se debe poner en el lugar, antes de que se carguen las reglas UFW convencionales. Hacia la parte superior del archivo, agregue las líneas resaltadas a continuación. Esto establecerá la directiva predeterminada para la cadena `POSTROUTING` en la tabla `nat` y enmascarará cualquier tráfico procedente de la VPN:

**Nota:** Recuerde reemplazar `eth0` en la línea `-A POSTROUTING` con la interfaz que encontró en el comando anterior.

/etc/ufw/before.rules

    #
    # rules.before
    #
    # Rules that should be run before the ufw command line added rules. Custom
    # rules should be added to one of these chains:
    # ufw-before-input
    # ufw-before-output
    # ufw-before-forward
    #
    
    # START OPENVPN RULES
    # NAT table rules
    *nat
    :POSTROUTING ACCEPT [0:0] 
    # Allow traffic from OpenVPN client to eth0
    -A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
    COMMIT
    # END OPENVPN RULES
    
    # Don't delete these required lines, otherwise there will be errors
    *filter
    . . .
    

Guarde y cierre el archivo, cuando haya terminado.

Tenemos que decirle a UFW que permita también paquetes enviados por defecto. Para ello, abriremos el archivo `/etc/default/ufw` :

    sudo nano /etc/default/ufw

En el archivo, busque la directiva `DEFAULT_FORWARD_POLICY`. Cambiaremos el valor de `DROP` a `ACCEPT`:

/etc/ufw/before.rules

    DEFAULT_FORWARD_POLICY="ACCEPT"

Guarde y cierre el archivo cuando haya terminado.

### Abrir el Puerto OpenVPN y Habilitar los Cambios

A continuación, ajustaremos el firewall para permitir el tráfico a OpenVPN.

Si no cambió el puerto y el protocolo en el archivo `/etc/openvpn/server.conf`, deberá abrir el tráfico UDP al puerto 1194. Si ha modificado el puerto y / o el protocolo, sustituya los valores que seleccionó aquí.

También añadiremos el puerto SSH en caso de que se haya olvidado de añadirlo al seguir el tutorial de requisitos previos:

    sudo ufw allow 1194/udp
    sudo ufw allow OpenSSH

Ahora, podemos deshabilitar y volver a habilitar UFW para cargar los cambios de todos los archivos que hemos modificado:

    sudo ufw disable
    sudo ufw enable

Nuestro servidor está configurado para manejar correctamente el tráfico de OpenVPN.

## Paso 9 — Iniciar y Habilitar el Servicio OpenVPN

Finalmente estamos listos para iniciar el servicio OpenVPN en nuestro servidor. Podemos hacer esto usando systemd.

Necesitamos iniciar el servidor OpenVPN especificando el nombre de nuestro archivo de configuración como una variable de instancia, después del nombre de archivo de la unidad systemd. Nuestro archivo de configuración para nuestro servidor se llama `/etc/openvpn/server.conf`, por lo que agregaremos `@server` al final de nuestro archivo de unidad cuando lo llamemos:

    sudo systemctl start openvpn@server

Compruebe que el servicio se ha iniciado correctamente escribiendo:

    sudo systemctl status openvpn@server

Si todo salió bien, su salida debería ser similar a esto:

    Output● openvpn@server.service - OpenVPN connection to server
       Loaded: loaded (/lib/systemd/system/openvpn@.service; disabled; vendor preset: enabled)
       Active: active (running) since Tue 2016-05-03 15:30:05 EDT; 47s ago
         Docs: man:openvpn(8)
               https://community.openvpn.net/openvpn/wiki/Openvpn23ManPage
               https://community.openvpn.net/openvpn/wiki/HOWTO
      Process: 5852 ExecStart=/usr/sbin/openvpn --daemon ovpn-%i --status /run/openvpn/%i.status 10 --cd /etc/openvpn --script-security 2 --config /etc/openvpn/%i.conf --writepid /run/openvpn/%i.pid (code=exited, sta
     Main PID: 5856 (openvpn)
        Tasks: 1 (limit: 512)
       CGroup: /system.slice/system-openvpn.slice/openvpn@server.service
               └─5856 /usr/sbin/openvpn --daemon ovpn-server --status /run/openvpn/server.status 10 --cd /etc/openvpn --script-security 2 --config /etc/openvpn/server.conf --writepid /run/openvpn/server.pid
    
    May 03 15:30:05 openvpn2 ovpn-server[5856]: /sbin/ip addr add dev tun0 local 10.8.0.1 peer 10.8.0.2
    May 03 15:30:05 openvpn2 ovpn-server[5856]: /sbin/ip route add 10.8.0.0/24 via 10.8.0.2
    May 03 15:30:05 openvpn2 ovpn-server[5856]: GID set to nogroup
    May 03 15:30:05 openvpn2 ovpn-server[5856]: UID set to nobody
    May 03 15:30:05 openvpn2 ovpn-server[5856]: UDPv4 link local (bound): [undef]
    May 03 15:30:05 openvpn2 ovpn-server[5856]: UDPv4 link remote: [undef]
    May 03 15:30:05 openvpn2 ovpn-server[5856]: MULTI: multi_init called, r=256 v=256
    May 03 15:30:05 openvpn2 ovpn-server[5856]: IFCONFIG POOL: base=10.8.0.4 size=62, ipv6=0
    May 03 15:30:05 openvpn2 ovpn-server[5856]: IFCONFIG POOL LIST
    May 03 15:30:05 openvpn2 ovpn-server[5856]: Initialization Sequence Completed
    

También puede comprobar que la interfaz de OpenVPN `tun0` está disponible escribiendo:

    ip addr show tun0

Debería ver una interfaz configurada:

    Output4: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 100
        link/none 
        inet 10.8.0.1 peer 10.8.0.2/32 scope global tun0
           valid_lft forever preferred_lft foreve

Si todo ha ido bien, habilite el servicio para que se inicie automáticamente al arrancar:

    sudo systemctl enable openvpn@server

## Paso 10 — Crear Infraestructura de Configuración de Cliente

A continuación, necesitamos configurar un sistema que nos permita crear fácilmente archivos de configuración del cliente.

### Creación de la Estructura de Directorios de Configuración de Cliente

Cree una estructura de directorios en su directorio personal para almacenar los archivos:

    mkdir -p ~/client-configs/files

Dado que nuestros archivos de configuración del cliente tendrán las llaves del cliente incrustadas, debemos bloquear los permisos en nuestro directorio interno:

    chmod 700 ~/client-configs/files

### Creando una Configuración Base

A continuación, vamos a copiar un ejemplo de configuración de cliente en nuestro directorio para usarla como nuestra configuración base:

    cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf

Abra este nuevo archivo en su editor de texto:

    nano ~/client-configs/base.conf

Dentro del archivo, necesitamos hacer algunos ajustes.

En primer lugar, busque la directiva `remote`. Esto señala al cliente a nuestra dirección de servidor OpenVPN. Esta debe ser la dirección IP pública de su servidor OpenVPN. Si ha cambiado el puerto en el que está escuchando el servidor OpenVPN, cambie 1194 al puerto que seleccionó:

~/client-configs/base.conf

    . . .
    # The hostname/IP and port of the server.
    # You can have multiple remote entries
    # to load balance between the servers.
    remote server_IP_address 1194
    . . .

Asegúrese de que el protocolo coincide con el valor que está utilizando en la configuración del servidor:

~/client-configs/base.conf

    proto udp

A continuación, quite el comentario de las directivas de `user` y `group` quitando el “;”:

~/client-configs/base.conf

    # Downgrade privileges after initialization (non-Windows only)
    user nobody
    group nogroup

Encuentre las directivas que establecen `ca`, `cert` y `key`. Comente estas directivas ya que agregaremos los certs y las llaves dentro del propio archivo:

~/client-configs/base.conf

    # SSL/TLS parms.
    # See the server config file for more
    # description. It's best to use
    # a separate .crt/.key file pair
    # for each client. A single ca
    # file can be used for all clients.
    #ca ca.crt
    #cert client.crt
    #key client.key

Refleje la configuración de `cipher` y `auth` que establecemos en el archivo `/etc/openvpn/server.conf`:

~/client-configs/base.conf

    cipher AES-128-CBC
    auth SHA256

A continuación, agregue la directiva `key-direction` en algún lugar del archivo. Esto **debe establecerse** en “ **1** ” para trabajar con el servidor:

~/client-configs/base.conf

    key-direction 1

Finalmente, agregue algunas líneas **comentadas**. Queremos incluirlos con cada configuración, pero solo debemos habilitarlos para clientes Linux que se envían con un archivo `/etc/openvpn/update-resolv-conf`. Este script usa la utilidad `resolvconf` para actualizar la información de DNS para clientes Linux.

~/client-configs/base.conf

    # script-security 2
    # up /etc/openvpn/update-resolv-conf
    # down /etc/openvpn/update-resolv-conf

Si su cliente ejecuta Linux y tiene un archivo `/etc/openvpn/update-resolv-conf`, debe descomentar estas líneas del archivo de configuración del cliente OpenVPN generado.

Guarde el archivo cuando haya terminado.

### Creando un Script Generador de configuración

A continuación, crearemos un script simple para compilar nuestra configuración base con los archivos de certificados, llaves y encriptación relevantes. Esto colocará la configuración generada en el directorio `~/client-configs/files`.

Cree y abra un archivo llamado `make_config.sh` dentro del directorio `~/client-configs`:

    nano ~/client-configs/make_config.sh

Dentro del archivo, pegue el siguiente script:

~/client-configs/make\_config.sh

    
    #!/bin/bash
    
    # First argument: Client identifier
    
    KEY_DIR=~/openvpn-ca/keys
    OUTPUT_DIR=~/client-configs/files
    BASE_CONFIG=~/client-configs/base.conf
    
    cat ${BASE_CONFIG} \
        <(echo -e '<ca>') \
        ${KEY_DIR}/ca.crt \
        <(echo -e '</ca>\n<cert>') \
        ${KEY_DIR}/${1}.crt \
        <(echo -e '</cert>\n<key>') \
        ${KEY_DIR}/${1}.key \
        <(echo -e '</key>\n<tls-auth>') \
        ${KEY_DIR}/ta.key \
        <(echo -e '</tls-auth>') \
        > ${OUTPUT_DIR}/${1}.ovpn

Cuando haya terminado, guarde y cierre el archivo.

Marque el archivo como ejecutable, escribiendo:

    chmod 700 ~/client-configs/make_config.sh

## Paso 11 — Generar Configuraciones de Cliente

Ahora, podemos generar fácilmente archivos de configuración del cliente.

Si siguió con la guía, creó un certificado de cliente y una llave denominada `client1.crt` y `client1.key` respectivamente ejecutando el comando `./build-key client1` en el paso 6. Podemos generar una configuración para estas credenciales moviéndose a nuestro directorio `~/client-configs` y usando el script que hemos hecho:

    cd ~/client-configs
    ./make_config.sh client1

Si todo salió bien, deberíamos tener un archivo `client1.ovpn` en nuestro directorio `~/client-configs/files`:

    ls ~/client-configs/files

    Outputclient1.ovpn

### Transferencia de Configuración a Dispositivos Cliente

Necesitamos transferir el archivo de configuración del cliente al dispositivo correspondiente. Por ejemplo, esto podría ser su computadora local o un dispositivo móvil.

Si bien las aplicaciones exactas utilizadas para realizar esta transferencia dependerán de su elección y del sistema operativo del dispositivo, si desea que la aplicación utilice SFTP (protocolo de transferencia de archivos SSH) o SCP (Copia Segura) en el servidor. Esto transportará los archivos de autenticación VPN de su cliente a través de una conexión cifrada.

Aquí hay un ejemplo de comando SFTP usando nuestro ejemplo client1.ovpn. Este comando se puede ejecutar desde su computadora local (OS X o Linux). Coloque el archivo `.ovpn` en su directorio personal:

    sftp sammy@openvpn_server_ip:client-configs/files/client1.ovpn ~/

Aquí hay varias herramientas y tutoriales para transferir archivos de forma segura del servidor a un equipo local:

- [WinSCP](https://winscp.net/eng/docs/lang:es)
- [Cómo Utilizar SFTP para Transferir Archivos de Forma Segura con un Servidor Remoto](how-to-use-sftp-to-securely-transfer-files-with-a-remote-server)
- [Cómo Utilizar Filezilla para Transferir y Gestionar Archivos de Forma Segura en su VPS](how-to-use-filezilla-to-transfer-and-manage-files-securely-on-your-vps)

## Paso 12 — Instalar la Configuración del Cliente

Ahora, vamos a discutir cómo instalar un perfil VPN de cliente en Windows, OS X, iOS y Android. Ninguna de estas instrucciones del cliente dependen una de la otra, así que siéntete libre de saltar a lo que sea aplicable a tu necesidad.

La conexión OpenVPN llamará el archivo `.ovpn` de cualquier forma que lo haya nombrado. En nuestro ejemplo, esto significa que la conexión se llamará `client1.ovpn` para el primer archivo de cliente que generamos.

### Windows

**Instalación**

La aplicación de cliente de OpenVPN para Windows se puede encontrar en la [página de Descargas de OpenVPN](https://openvpn.net/index.php/open-source/downloads.html). Elija la versión de instalación adecuada para su versión de Windows.

**Nota:** OpenVPN necesita privilegios administrativos para instalar.

Después de instalar OpenVPN, copie el archivo `.ovpn` en:

    C:\Program Files\OpenVPN\config

Al iniciar OpenVPN, automáticamente verá el perfil y lo hará disponible.

OpenVPN se debe ejecutar como un administrador cada vez que se utiliza, incluso por cuentas administrativas. Para hacer esto sin tener que hacer clic con el botón derecho del ratón y seleccionar **Ejecutar como administrador** cada vez que utilice la VPN, puede predefinir esto, pero esto debe hacerse desde una cuenta administrativa. Esto también significa que los usuarios estándar necesitarán ingresar la contraseña del administrador para usar OpenVPN. Por otro lado, los usuarios estándar no pueden conectarse correctamente al servidor a menos que la aplicación OpenVPN en el cliente tenga derechos de administrador, por lo que los privilegios elevados son necesarios.

Para configurar la aplicación OpenVPN para que se ejecute siempre como administrador, haga clic con el botón derecho del ratón en su icono de acceso directo y vaya a **Propiedades**. En la parte inferior de **Compatibilidad** , haga clic en el botón **Cambiar la configuración para todos los usuarios**. En la nueva ventana, seleccione **Ejecutar este programa como administrador**.

**Conectando**

Cada vez que inicie la interfaz gráfica de OpenVPN, Windows le preguntará si desea permitir que el programa realice cambios en su equipo. Haga clic en **Yes**. El lanzamiento de la aplicación cliente OpenVPN sólo coloca el applet en la bandeja del sistema para que la VPN pueda conectarse y desconectarse según sea necesario; En realidad no hace la conexión VPN.

Una vez que se inicia OpenVPN, inicie una conexión entrando en el subprograma de la bandeja del sistema y haciendo clic con el botón derecho en el icono del applet de OpenVPN. Esto abre el menú contextual. Seleccione **client1** en la parte superior del menú (que es nuestro perfil `client1.ovpn`) y elija **Connect**.

Se abrirá una ventana de estado que mostrará la salida del registro mientras se establece la conexión y se mostrará un mensaje una vez que el cliente esté conectado.

Desconecte la VPN de la misma manera: Vaya al applet de la bandeja del sistema, haga clic con el botón derecho en el icono del applet de OpenVPN, seleccione el perfil del cliente y haga clic en **Desconectar**.

### OS X

**Instalación**

[Tunnelblick](https://tunnelblick.net) es un cliente OpenVPN de código abierto gratuito para Mac OS X. Puede descargar la última imagen de disco desde la [página de Descargas de Tunnelblick](https://tunnelblick.net/downloads.html). Haga doble clic en el archivo `.dmg` descarguelo y siga las instrucciones para instalar.

Hacia el final del proceso de instalación, Tunnelblick le preguntará si tiene algún archivo de configuración. Puede ser más fácil contestar **No** y dejar que Tunnelblick termine. Abra una ventana del Finder y haga doble clic en `client1.ovpn`. Tunnelblick instalará el perfil del cliente. Se requieren privilegios administrativos.

**Conectando**

Inicie Tunnelblick haciendo doble clic en Tunnelblick en la carpeta **Aplicaciones**. Una vez que Tunnelblick ha sido lanzado, habrá un icono Tunnelblick en la barra de menú en la parte superior derecha de la pantalla para controlar las conexiones. Haga clic en el icono y, a continuación, en el elemento de menú **Conectar** para iniciar la conexión VPN. Seleccione la conexión **client1**.

### Linux

**Instalación**

Si está usando Linux, hay una variedad de herramientas que puede usar dependiendo de su distribución. El entorno de escritorio o el administrador de ventanas también pueden incluir utilidades de conexión.

Sin embargo, la forma más universal de conectar es usar el software OpenVPN.

En Ubuntu o Debian, puede instalarlo tal como lo hizo en el servidor escribiendo:

    sudo apt-get update
    sudo apt-get install openvpn

En CentOS puede habilitar los repositorios EPEL y luego instalarlo escribiendo:

    sudo yum install epel-release
    sudo yum install openvpn

**Configurando**

Compruebe si su distribución incluye el script `/etc/openvpn/update-resolv-conf`:

    ls /etc/openvpn

    Outputupdate-resolve-conf

A continuación, edite el archivo de configuración del cliente OpenVPN que ha transferido:

    nano client1.ovpn

Descomente las tres líneas que colocamos para ajustar la configuración de DNS si pudimos encontrar un archivo `update-resolv-conf`:

client1.ovpn

    script-security 2
    up /etc/openvpn/update-resolv-conf
    down /etc/openvpn/update-resolv-conf

Si está utilizando CentOS, cambie el `grupo` de `nogroup` a `nobody` para que coincida con los grupos disponibles de la distribución:

client1.ovpn

    group nobody

Guarde y cierre el archivo.

Ahora, puede conectarse a la VPN con sólo señalar el comando `openvpn` al archivo de configuración del cliente:

    sudo openvpn --config client1.ovpn

Esto debería conectarlo a su servidor.

### IOS

**Instalación**

Desde iTunes App Store, busque e instale [OpenVPN Connect](https://itunes.apple.com/us/app/id590379981), la aplicación oficial de iOS OpenVPN. Para transferir su configuración de cliente de iOS al dispositivo, conéctelo directamente a una computadora.

Completar la transferencia con iTunes se describirá aquí. Abre iTunes en la computadora y haz clic en **iPhone** \> **apps**. Desplácese hacia abajo hasta la parte inferior de la sección **Compartir archivos** y haga clic en la aplicación OpenVPN. La ventana en blanco a la derecha, **Documentos OpenVPN** , es para compartir archivos. Arrastre el archivo `.ovpn` a la ventana OpenVPN Documents.

![ITunes muestra el perfil de VPN listo para cargar en el iPhone](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/openvpn_ubunutu/1.png)

Ahora inicie la aplicación OpenVPN en el iPhone. Habrá una notificación de que un nuevo perfil está listo para importar. Toque el signo más de color verde para importarlo.

![La aplicación OpenVPN iOS mostrando un nuevo perfil listo para importar](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/openvpn_ubunutu/2.png)

**Conectando**

OpenVPN ahora está listo para usar con el nuevo perfil. Inicie la conexión deslizando el botón **Conectar** a la posición **Encendido**. Desconecte deslizando el mismo botón a **Off**.

**Nota:** El conmutador VPN en **Configuración** no se puede utilizar para conectarse a la VPN. Si lo intentas, recibirás un aviso para conectarte solo con la aplicación OpenVPN.

![La aplicación OpenVPN iOS conectada a la red VPN](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/openvpn_ubunutu/3.png)

### Android

**Instalación**

Abra Google Play Store. Busque e instale [Android OpenVPN Connect](https://play.google.com/store/apps/details?id=net.openvpn.openvpn), la aplicación oficial del lado del cliente de Android OpenVPN.

El perfil `.ovpn` se puede transferir conectando el dispositivo Android a su computadora por USB y copiando el archivo. Como alternativa, si tiene un lector de tarjetas SD, puede retirar la tarjeta SD del dispositivo, copiar el perfil en ella e insertarla en el dispositivo Android.

Inicie la aplicación OpenVPN y toque el menú para importar el perfil.

![La selección del menú de importación del perfil de la aplicación Android de OpenVPN](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/openvpn_ubunutu/4.png)

A continuación, navegue hasta la ubicación del perfil guardado (la captura de pantalla utiliza `/sdcard/Download/`) y seleccione el archivo. La aplicación hará una nota de que el perfil se ha importado.

![La aplicación de OpenVPN para Android que selecciona el perfil de VPN para importar](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/openvpn_ubunutu/5.png)

**Conectando**

Para conectarse, simplemente pulse el botón **Conectar**. Se le preguntará si confía en la aplicación OpenVPN. Seleccione **Aceptar** \* para iniciar la conexión. Para desconectarse de la VPN, vuelva a la aplicación OpenVPN y seleccione **Desconectar**.

![La aplicación de OpenVPN para Android que selecciona el perfil de VPN para importar](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/openvpn_ubunutu/6.png)

## Paso 13 — Pruebe su Conexión VPN

Una vez que todo está instalado, una simple comprobación confirma que todo funciona correctamente. Sin tener una conexión VPN habilitada, abra un navegador y vaya a [DNSLeakTest](https://www.dnsleaktest.com/).

El sitio devolverá la dirección IP asignada por su proveedor de servicios de Internet y al aparecer al resto del mundo. Para comprobar su configuración de DNS a través del mismo sitio web, haga clic en **Extended Test** y le indicará qué servidores DNS está utilizando.

Ahora conecte el cliente OpenVPN a su Droplet VPN y actualice el navegador. Ahora debe aparecer la dirección IP completamente diferente de su servidor VPN. Eso es ahora cómo te ves al mundo. Una vez más, **Extended Test** de [DNSLeakTest](https://www.dnsleaktest.com) verificará su configuración de DNS y confirmará que está utilizando los resolvedores de DNS empujados por su VPN.

## Paso 14 — Revocación de Certificados de Cliente

De vez en cuando, puede que tenga que revocar un certificado de cliente para impedir el acceso adicional al servidor OpenVPN.

Para ello, ingrese su directorio de CA y vuelva a generar el archivo `vars`:

    cd ~/openvpn-ca
    source vars

A continuación, llame al comando `revoke-full` usando el nombre del cliente que desea revocar:

    ./revoke-full client3

Esto mostrará algo de salida, terminando en `error 23`. Esto es normal y el proceso debería haber generado con éxito la información de revocación necesaria, que se almacena en un archivo llamado `crl.pem` dentro del subdirectorio `keys`.

Transfiera este archivo al directorio de configuración `/etc/openvpn`:

    sudo cp ~/openvpn-ca/keys/crl.pem /etc/openvpn

A continuación, abra el archivo de configuración del servidor OpenVPN:

    sudo nano /etc/openvpn/server.conf

En la parte inferior del archivo, agregue la opción `crl-verify` para que el servidor OpenVPN compruebe la lista de revocación de certificados que hemos creado cada vez que se realiza un intento de conexión:

/etc/openvpn/server.conf

    crl-verify crl.pem

Guarde y cierre el archivo.

Finalmente, reinicie OpenVPN para implementar la revocación de certificados:

    sudo systemctl restart openvpn@server

El cliente ahora debería ser capaz de conectar con éxito al servidor utilizando la credencial antigua.

Para revocar clientes adicionales, siga este proceso:

1. Genere una nueva lista de revocación de certificados mediante la búsqueda del archivo `vars` en el directorio `~/openvpn-ca` y luego llamando al script de `revoke-full` en el nombre del cliente.
2. Copie la nueva lista de revocación de certificados en el directorio `/etc/openvpn` para sobrescribir la lista antigua.
3. Reinicie el servicio OpenVPN.

Este proceso se puede utilizar para revocar cualquier certificado que haya emitido anteriormente para su servidor.

## Conclusión

¡Felicitaciones! Ahora está atravesando la Internet de manera segura protegiendo su identidad, ubicación y tráfico de los snoopers y censors.

Para configurar más clientes, sólo tiene que seguir los pasos **6** y **11-13** para cada dispositivo adicional. Para revocar el acceso a los clientes, siga el paso **14**.
