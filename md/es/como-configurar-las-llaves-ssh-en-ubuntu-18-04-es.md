---
author: Hanif Jetha
date: 2018-06-21
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-configurar-las-llaves-ssh-en-ubuntu-18-04-es
---

# Cómo configurar las llaves SSH en Ubuntu 18.04

### Introducción

SSH, o blindaje seguro (secure shell) es un protocolo encriptado para administrar y comunicarse con servidores. Al trabajar con servidores Ubuntu, generalmente pasarás la mayor parte del tiempo conectado mediante SSH desde una terminal a tu servidor.

En esta guía, nos enfocaremos en configurar las llaves SSH sobre una instalación de Ubuntu Vanilla 18.04. Las llaves SSH proveen una autenticación fácil y segura para tu servidor, esta autenticación es la recomendada para todos los usuarios.

## Paso 1 — Crea un par de llaves RSA

El primer paso consiste en crear un par de llaves en la máquina cliente (usualmente tu computador):

    ssh-keygen

De manera predeterminada, `ssh-keygen` creará un par de llaves RSA de 2.048 bits, lo cual es suficientemente seguro en la mayoría de casos (opcionalmente se podría adicionar el parámetro `-b 4096` para crear una llave de 4.096 bits).

Después del comando, se debería desplegar la siguiente salida:

    OutputGenerating public/private rsa key pair.
    Enter file in which to save the key (/your_home/.ssh/id_rsa):

Presione la tecla Enter para guardar el par de llaves en el subdirectorio `.ssh/` del directorio local del usuario, también se puede especificar una ruta alterna a ésta.

Si se han generado previamente un par de llaves SSH, deberías ver la siguiente información:

    Output/home/your_home/.ssh/id_rsa already exists.
    Overwrite (y/n)?

Si se escoge sobreescribir la llave en disco, **no** podrás autenticarte usando las llaves previas de ahora en adelante. Sé muy cuidadoso al seleccionar la opción positiva (y), ya que éste es un proceso destructivo de las llaves que no puede ser reversado.

Debería desplegarse lo siguiente en la línea de comandos:

    OutputEnter passphrase (empty for no passphrase):

En este punto se puede introducir una frase segura que sirva como contraseña, lo cual es altamente recomendado. Esta frase adicionará una capa extra de seguridad para prevenir la autenticación de usuarios no autorizados. Para aprender más sobre seguridad, consulta nuestro tutorial sobre [cómo configurar la autenticación mediante llaves SSH en un servidor Linux](how-to-configure-ssh-key-based-authentication-on-a-linux-server).

A continuación, deberías ver la siguiente salida:

    OutputYour identification has been saved in /your_home/.ssh/id_rsa.
    Your public key has been saved in /your_home/.ssh/id_rsa.pub.
    The key fingerprint is:
    a9:49:2e:2a:5e:33:3e:a9:de:4e:77:11:58:b6:90:26 username@remote_host
    The key's randomart image is:
    +--[RSA 2048]----+
    | ..o |
    | E o= . |
    | o. o |
    | .. |
    | ..S |
    | o o. |
    | =o.+. |
    |. =++.. |
    |o=++. |
    +-----------------+

Ahora ya existe una llave pública y una privada que puedes usar en el proceso de autenticación. El siguiente paso será colocar la llave pública en tu servidor, de tal manera que la puedas usar para acceder a él, mediante una autenticación basada en llaves SSH.

## Paso 2 — Copia la llave pública en el servidor Ubuntu

La manera más rápida de copiar tu llave pública en el servidor Ubuntu es mediante el uso de una utilidad llamada `ssh-copy-id`. Gracias a su simplicidad, de estar disponible es un método altamente recomendado. En caso de que `ssh-copy-id` no se encuentre disponible en tu máquina cliente, aún puedes usar uno de los dos métodos que se proveen en esta sección: copiado de una contraseña usando SSH, o el copiado manual de la llave.

### Copia de la llave pública usando `ssh-copy-id`

La herramienta `ssh-copy-id` se encuentra incluida de manera predeterminada en varios sistemas operativos, por lo cual existe la posibilidad que esté disponible en tu sistema local. Para que este método funcione es necesario que ya se cuente con acceso por contraseña mediante SSH dentro de tu servidor.

Para usar este método, simplemente se debe especificar el servidor remoto al cual te quieres conectar, así como la cuenta de usuario y su contraseña con acceso SSH. Esta cuenta es a la cual se copiará tu llave SSH pública.

La sintaxis es:

    ssh-copy-id username@remote_host

Se te podría desplegar el siguiente mensaje:

    OutputThe authenticity of host '203.0.113.1 (203.0.113.1)' can't be established.
    ECDSA key fingerprint is fd:fd:d4:f9:77:fe:73:84:e1:55:00:ad:d6:6d:22:fe.
    Are you sure you want to continue connecting (yes/no)? yes

Esto significa que tu computador local no reconoce el cliente remoto. Esto sucede la primera vez que te conectas a una nueva máquina. Digita “yes” y presiona `Enter` para continuar.

A continuación, la utilidad escaneará tu cuenta local en búsqueda de la llave `id_rsa.pub` creada previamente. Cuando la llave es creada, se te solicitará la contraseña para la cuenta del usuario remoto:

    Output/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
    /usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
    username@203.0.113.1's password:

Digita la contraseña (lo digitado no será mostrado en pantalla por razones de seguridad), y presiona `Enter`. La utilidad se conectará a la cuenta en la máquina remota usando la contraseña que proveíste. Esto copiará el contenido de tu llave `~/.ssh/id_rsa.pub` en el archivo que se encuentra en el directorio local de la cuenta remota `~/.ssh` llamado `authorized_keys`.

Se te debería desplegar la siguiente salida:

    OutputNumber of key(s) added: 1
    
    Now try logging into the machine, with: "ssh 'username@203.0.113.1'"
    and check to make sure that only the key(s) you wanted were added.

Para este momento tu llave `id_rsa.pub` ha sido cargada en la cuenta remota. Puedes continuar al [paso 3](how-to-set-up-ssh-keys-on-ubuntu-1604#step-3-%E2%80%94-authenticate-to-ubuntu-server-using-ssh-keys).

### Copia de la llave pública usando SSH

Si no se tiene `ssh-copy-id` disponible, pero cuentas con acceso al servidor mediante una contraseña que usa SSH, puedes cargar tus llaves utilizando un método SSH convencional.

Esto se puede realizar usando el comando `cat` para leer el contenido de la llave pública SSH en tu computador local y enviarlo a través de una conexión SSH al servidor remoto.

De otro lado, debemos asegurar que el directorio `~/.ssh` exista y que tenga los permisos adecuados dentro de la cuenta que se está usando.

Podemos direccionar el contenido enviado a un archivo llamado `authorized_keys` dentro de este directorio. Usaremos el símbolo de redirección `>>` para adicionar el contenido sin reescribirlo, lo que nos permitirá adicionar llaves nuevas sin destruir las adicionadas previamente.

El comando completo lucirá como lo siguiente:

    cat ~/.ssh/id_rsa.pub | ssh username@remote_host "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod -R go= ~/.ssh && cat >> ~/.ssh/authorized_keys"

Se podría desplegar el siguiente mensaje:

    OutputThe authenticity of host '203.0.113.1 (203.0.113.1)' can't be established.
    ECDSA key fingerprint is fd:fd:d4:f9:77:fe:73:84:e1:55:00:ad:d6:6d:22:fe.
    Are you sure you want to continue connecting (yes/no)? yes

Esto significa que el computador local no reconoce al remoto. Esto sucede la primera vez que se conecta a una máquina remota. Digita “yes” y presiona `Enter` para continuar.

En este momento, se te solicitará que introduzcas la contraseña de la cuenta del usuario remoto:

    Outputusername@203.0.113.1's password:

Después de ingresar la contraseña, el contenido de la llave `id_rsa.pub` habrá sido copiada al final del archivo `authorized_keys` en la cuenta del usuario remoto. Puedes continuar con el [paso 3](how-to-set-up-ssh-keys-on-ubuntu-1604#step-3-%E2%80%94-authenticate-to-ubuntu-server-using-ssh-keys) si esto se llevó a cabo de manera exitosa.

### Copia manual de la llave pública

Si no se cuenta con un acceso al servidor mediante contraseña SSH, puedes completar el proceso de forma manual.

Adicionaremos manualmente el contenido del archivo `id_rsa.pub` al archivo `~/.ssh/authorized_keys` en la máquina remota.

Para desplegar el contenido de la llave `id_rsa.pub`, digita lo siguiente en la máquina local:

    cat ~/.ssh/id_rsa.pub

Verás el contenido de la llave, que debería ser similar a algo como lo siguiente:

    Outputssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqql6MzstZYh1TmWWv11q5O3pISj2ZFl9HgH1JLknLLx44+tXfJ7mIrKNxOOwxIxvcBF8PXSYvobFYEZjGIVCEAjrUzLiIxbyCoxVyle7Q+bqgZ8SeeM8wzytsY+dVGcBxF6N4JS+zVk5eMcV385gG3Y6ON3EG112n6d+SMXY0OEBIcO6x+PnUSGHrSgpBgX7Ks1r7xqFa7heJLLt2wWwkARptX7udSq05paBhcpB0pHtA1Rfz3K2B+ZVIpSDfki9UVKzT8JUmwW6NNzSgxUfQHGwnW7kj4jp4AT0VZk3ADw497M2G/12N0PPB5CnhHf7ovgy6nL1ikrygTKRFmNZISvAcywB9GVqNAVE+ZHDSCuURNsAInVzgYo9xgJDW8wUw2o8U77+xiFxgI5QSZX3Iq7YLMgeksaO4rBJEa54k8m5wEiEE1nUhLuJ0X/vh2xPff6SQ1BL/zkOhvJCACK6Vb15mDOeCSq54Cr7kvS46itMosi/uS66+PujOO+xt/2FWYepz6ZlN70bRly57Q06J+ZJoc9FfBCbCyYH7U/ASsmY095ywPsBo1XQ9PqhnN1/YOorJ068foQDNVpm146mUpILVxmq41Cj55YKHEazXGsdBIbXWhcrRf4G2fJLRcGUr9q8/lERo9oxRm5JFX6TCmj6kmiFqv+Ow9gI0x8GvaQ== demo@test

Accede al computador remoto usando cualquier método que tengas disponible. Una vez hayas accedido, debes asegurarte que el directorio `~/.ssh` exista. De no ser así, lo puedes crear con el siguiente comando:

    mkdir -p ~/.ssh

Ahora, se puede modificar, o incluso crear, el archivo `authorized_keys` dentro de este directorio. Puedes adicionar el contenido del archivo `id_rsa.pub` al final de archivo `authorized_keys`, o crearlo de ser necesario, mediante el comando:

    echo public_key_string >> ~/.ssh/authorized_keys

En el anterior comando, sustituye `public_key_string` con la salida que habías obtenido del comando `cat ~/.ssh/id_rsa.pub` que ya habías ejecutado en la máquina local. Éste debería comenzar con `ssh-rsa AAAA...`.

Finalmente, nos aseguraremos que el directorio `~/.ssh` y el archivo `authorized_keys` tengan los permisos correctos:

    chmod -R go= ~/.ssh

Esto remueve recursivamente todos los permisos dados a grupos “group” y a otros “other” en el directorio `~/.ssh/`.

En caso que hayas utilizado la cuenta `root` para configurar las llaves de una cuenta de usuario, también es importante que el directorio `~/.ssh` pertenezca a este usuario y no al `root`:

    chown -R sammy:sammy ~/.ssh

En este tutorial nuestro usuario es llamado sammy, en el comando anterior, debes sustituirlo por el nombre de usuario apropiado.

Ahora ya estamos listos para intentar la autenticación sin contraseña en nuestro servidor Ubuntu.

## Paso 3 — Autentícate en un servidor Ubuntu usando llaves SSH

Si ya has completado satisfactoriamente uno de los procesos anteriores, ya deberías estar habilitada para autenticarte **sin** necesidad de la contraseña de la cuenta remota.

El proceso básico es el mismo:

    ssh username@remote_host

Si es la primera vez que se intenta la conexión con esta máquina (y, por ejemplo, usaste el último método de la sección anterior), quizás se despliegue algo similar a lo siguiente:

    OutputThe authenticity of host '203.0.113.1 (203.0.113.1)' can't be established.
    ECDSA key fingerprint is fd:fd:d4:f9:77:fe:73:84:e1:55:00:ad:d6:6d:22:fe.
    Are you sure you want to continue connecting (yes/no)? yes

Esto significaría que el computador local no reconoce la máquina remota. Digita “yes” y presiona `Enter` para continuar.

Si no proveiste una frase segura, se te autenticará de inmediato. En el caso que sí hayas ingresado una en el momento de creación de la llave, se te solicitará en este momento (notarás que por motivos de seguridad no se imprimirán los caracteres en la sesión de terminal). Después de la autenticación, un sesión segura se te debería desplegar, configurada con la cuenta del servidor Ubuntu.

Si la autenticación mediante llave fue exitosa, continúa aprendiendo cómo mejorar la seguridad de tu sistema deshabilitando la autenticación por contraseña.

## Paso 4 — Deshabilita en tu servidor la autenticación por contraseña

Si tu sistema ya puede ser accedido mediante SSH sin una contraseña de usuario, ya has configurado de manera exitosa la autenticación mediante llave SSH en tu cuenta. Sin embargo, el mecanismo de autenticación mediante contraseña de usuarios sigue activo, lo cual significa que tu servidor aún se encuentra expuesto a posibles ataques de fuerza bruta.

Antes de completar las indicaciones de esta sección, debes asegurarte de tener, o bien, configurada la autenticación de la cuenta de superusuario mediante llave SSH, o preferiblemente, la autenticación mediante SSH configurada para una cuenta diferente a la de superusuario con privilegios de `sudo`. Este paso restringirá los accesos mediante contraseña, por lo cual es crucial que te asegures de tener control administrativo de tu servidor.

Tan pronto confirmes que tu cuenta remota cuenta con privilegios administrativos, accede al servidor remoto utilizando las llaves SSH, ya sea como superusuario o con una cuenta con privilegios de `sudo`. Después, abre el archivo de configuración del demonio SSH:

    sudo nano /etc/ssh/sshd_config

Dentro del archivo, busca la directiva llamada `PasswordAuthentication`. Ésta podría estar en comentario. Si lo está, retira el marcador de comentario sobre esa línea y fija el valor en “no”. Esto deshabilitará la posibilidad de conectarse mediante SSH usando la contraseña de una cuenta:

/etc/ssh/sshd\_config

    ...
    PasswordAuthentication no
    ...

Salva y cierra el archivo cuando hayas terminado digitando `CTRL` + `X`, después `Y` para confirmar salvar el archivo, y finalmente `Enter` para salir del editor nano. Ahora, para implementar los cambios, debemos reiniciar el servicio `sshd`:

    sudo systemctl restart ssh

Como precaución, abre una nueva ventana de la terminal y verifica que el servicio de SSH se encuentre funcionando correctamente antes de cerrar esta sesión:

    ssh username@remote_host

Una vez hayas verificado tu servicio SSH, puedes cerrar de manera segura todas las sesiones actuales del servidor.

Ahora, el demonio SSH solo responderá a llaves SSH. Autenticación mediante contraseña de usuarios habrá sido deshabilitada exitosamente.

## Conclusión

Para este momento ya deberías haber configurado en tu servidor, la autenticación mediante llaves SSH, habilitándote a acceder sin proveer una contraseña de una cuenta.

Si quieres aprender más acerca de trabajar con SSH, puedes usar nuestra [guía esencial de SSH](ssh-essentials-working-with-ssh-servers-clients-and-keys).
