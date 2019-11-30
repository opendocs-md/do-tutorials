---
author: Mitchell Anicas
date: 2016-12-12
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/configuracion-inicial-del-servidor-en-ubuntu-16-04-es
---

# Configuración Inicial del Servidor en Ubuntu 16.04

### Introducción

Cuando se crea un nuevo servidor de Ubuntu 16.04, hay algunos pasos de configuración que se deben tener desde el principio como parte de la configuración básica. Esto aumentará la seguridad y la usabilidad de su servidor y le dará una base sólida para las acciones posteriores.

## Paso Uno — Sesión de Root

Para iniciar sesión en el servidor, necesitará conocer la dirección IP pública del servidor. También necesitará la contraseña o, si ha instalado una llave SSH para la autentificación, la llave privada para la cuenta “root” del usuario. Si aún no ha iniciado sesión en el servidor, es posible que desee seguir el primer tutorial de esta serie, [¿Cómo conectarse a un Doplet con SSH?](how-to-connect-to-your-droplet-with-ssh), que cubre este proceso en detalle.

Si no está conectado a su servidor, siga adelante e inicie sesión como el usuario `root` usando el siguiente comando (sustituya la palabra resaltada con la dirección IP pública del servidor):

     ssh root@ip_del_servidor

Complete el proceso de inicio de sesión mediante la aceptación de la advertencia sobre la autenticidad del host, si aparece, a continuación, proporcionar su acceso como usuario root (contraseña o llave privada). Si es la primera vez que inicia sesión en el servidor con una contraseña, también se le pedirá que cambie la contraseña de root.

### Acerca de Root

El usuario root es el usuario de administración en un entorno Linux que tiene muy amplios privilegios. Debido a los privilegios elevados de la cuenta root, en realidad se _desaconseja_ usarlo de forma regular. Esto se debe en parte del poder inherente a la cuenta de root es la capacidad de hacer cambios muy destructivos, incluso por accidente.

El siguiente paso es la creación de una cuenta de usuario alternativa con un reducido margen de influencia para el trabajo del día a día. Le enseñamos cómo obtener mayores privilegios durante los momentos en que los necesite.

## Paso Dos — Crear un nuevo usuario

Una vez que se ha iniciado sesión como `root`, estamos preparados para agregar la nueva cuenta de usuario que usaremos para iniciar sesión de ahora en adelante.

En este ejemplo se crea un nuevo usuario llamado “Sammy”, pero debe reemplazarlo con un nombre de usuario que le guste:

    adduser sammy

Se le harán algunas preguntas, comenzando con la contraseña de la cuenta.

Introduzca una contraseña segura y, opcionalmente, complete la información adicional si lo desea. Esto no es necesario y sólo puede pulsar `ENTER` en cualquier campo que desee omitir.

## Paso Tres — Privilegios de Root

Ahora, tenemos una nueva cuenta de usuario con privilegios de cuenta regulares. Sin embargo, es posible que a veces tenga que realizar tareas administrativas.

Para evitar tener que cerrar la sesión de nuestro usuario normal y volver a iniciar sesión como la cuenta root, podemos establecer lo que se conoce como “superusuario” o privilegios de root para nuestra cuenta normal. Esto permitirá a nuestro usuario normal ejecutar comandos con privilegios administrativos colocando la palabra `sudo` antes de cada comando.

Para añadir estos privilegios a nuestro nuevo usuario, tenemos que añadir el nuevo usuario al grupo “sudo”. Por defecto, en Ubuntu 16.04, los usuarios que pertenecen al grupo “sudo” se les permite usar el comando `sudo`.

Como `root`, ejecute este comando para añadir el nuevo usuario al grupo _sudo_ (sustituya la palabra resaltada con su nuevo usuario):

    usermod -aG sudo sammy

¡Ahora su usuario puede ejecutar comandos con privilegios de superusuario! Para obtener más información acerca de cómo funciona esto, echa un vistazo a este [tutorial de Sudoers](how-to-edit-the-sudoers-file-on-ubuntu-and-centos).

Si se desea aumentar la seguridad de su servidor, siga el resto de los pasos de este tutorial.

## Paso Cuatro — Añadir la autenticación de llave pública (Recomendado)

El siguiente paso en la seguridad de su servidor es configurar la autenticación de llave pública para su nuevo usuario. Esta configuración aumentará la seguridad de su servidor al requerir una llave SSH privada para iniciar sesión.

## Generar un par de Llaves

Si aún no dispone de un par de llaves SSH, que consiste en una llave pública y privada, es necesario generar una. Si ya tiene una llave que desea utilizar, vaya al paso _Copiar la Llave Pública_.

Para generar un nuevo par de llaves, ingrese el siguiente comando en la terminal de su **máquina local** (es decir, su ordenador):

     ssh-keygen

Asumiendo que su usuario local se llama “usuariolocal”, verá una salida que se parece a lo siguiente:

    ssh-keygen output Generating public/private rsa key pair.
     Enter file in which to save the key (/Users/localuser/.ssh/id_rsa): 

Pulse la tecla Intro para aceptar el nombre de archivo y la ruta (o introduzca un nuevo nombre).

A continuación, se le pedirá una frase de contraseña para asegurar la llave. Puede introducir una frase de contraseña o dejar en blanco la frase de contraseña.

**Nota:** Si deja la frase de contraseña en blanco, usted será capaz de utilizar la llave privada para la autenticación sin introducir una frase. Si introduce una frase de contraseña, necesitará ambas, la llave privada _y_ la contraseña para iniciar sesión. Asegurar sus llaves con frases de contraseña es más seguro, pero ambos métodos tienen sus usos y son más seguros que la autenticación de contraseña básica.

Esto genera una llave privada, `id_rsa` y una llave pública, `id_rsa.pub` en el directorio `.ssh` del directorio home del _usuariolocal_. ¡Recuerde que la llave privada no debe ser compartida con alguien que no debería tener acceso a los servidores!

### Copiar la Llave Pública

Después de generar un par de llaves SSH, deseará copiar su llave pública en su nuevo servidor. Cubriremos dos maneras fáciles de hacer esto.

#### Opción 1: Usar SSH para copiar el id

Si su máquina local tiene instalada el script `ssh-copy-id`, puede utilizarlo para instalar su llave pública en cualquier usuario para el que tenga credenciales de inicio de sesión.

Ejecute el script `ssh-copy-id` especificando el usuario y la dirección IP del servidor en el que desea instalar la llave, como esto:

     ssh-copy-id sammy@ip_del_servidor

Después de proporcionar su contraseña en consola, su llave pública se agregará al archivo `.ssh/authorized_keys` del usuario remoto. Ahora se puede usar la llave privada correspondiente para iniciar sesión en el servidor.

#### Opción 2: Instalar manualmente la llave

Suponiendo que generó un par de llaves SSH utilizando el paso anterior, utilice el siguiente comando en la terminal de su **máquina local** para imprimir su llave pública (`id_rsa.pub`):

     cat ~/.ssh/id_rsa.pub

Esto debería imprimir su llave SSH pública, que debería ser similar a la siguiente:

    id_rsa.pub contentsssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBGTO0tsVejssuaYR5R3Y/i73SppJAhme1dH7W2c47d4gOqB4izP0+fRLfvbz/tnXFz4iOP/H6eCV05hqUhF+KYRxt9Y8tVMrpDZR2l75o6+xSbUOMu6xN+uVF0T9XzKcxmzTmnV7Na5up3QM3DoSRYX/EP3utr2+zAqpJIfKPLdA74w7g56oYWI9blpnpzxkEd3edVJOivUkpZ4JoenWManvIaSdMTJXMy3MtlQhva+j9CgguyVbUkdzK9KKEuah+pFZvaugtebsU+bllPTB0nlXGIJk98Ie9ZtxuY3nCKneB+KjKiXrAvXUPCI9mWkYS/1rggpFmu3HbXBnWSUdf localuser@machine.local

Seleccione la llave pública y cópiela en el portapapeles.

Para habilitar el uso de la llave SSH para autenticarse como el nuevo usuario remoto, debe agregar la llave pública a un archivo especial en el directorio principal del usuario.

**En el servidor** , como usuario **root** , escriba el siguiente comando para cambiar temporalmente al nuevo usuario (sustituya su propio nombre de usuario):

    su - sammy

Ahora estarás en el directorio de inicio de tu nuevo usuario.

Cree un nuevo directorio llamado `.ssh` y restrinja sus permisos con los siguientes comandos:

    Mkdir ~ / .ssh
    Chmod 700 ~ / .ssh

Ahora abra un archivo en `.ssh` llamado `authorized_keys` con un editor de texto. Usaremos `nano` para editar el archivo:

    Nano ~ / .ssh / authorized_keys

Ahora inserte su llave pública (que debería estar en su portapapeles) pegándola en el editor.

Pulse `CTRL-x` para salir del archivo, luego pulse `y` para guardar los cambios realizados, luego `ENTER` para confirmar el nombre del archivo.

Ahora restringiremos los permisos del archivo _authorized_ _keys_ con este comando:

    chmod 600 ~/.ssh/authorized_keys

Escriba este comando **una** vez para volver al usuario `root`:

    exit

Ahora su llave pública está instalada, y puede utilizar las llaves de SSH para iniciar sesión como su usuario.

Para leer más acerca de cómo funciona la autenticación de llaves, lea este tutorial: [Cómo configurar la autenticación basada en llaves SSH en un servidor Linux](how-to-configure-ssh-key-based-authentication-on-a-linux-server).

A continuación, le mostraremos cómo aumentar la seguridad de su servidor desactivando la autenticación de contraseña.

## Paso Cinco — Deshabilitar la Autenticación de Contraseña (Recomendado)

Ahora que su nuevo usuario puede usar las llaves SSH para iniciar sesión, puede aumentar la seguridad de su servidor desactivando la autenticación de sólo contraseña. Al hacerlo, restringirá el acceso SSH a su servidor únicamente a la autenticación de llave pública. Es decir, la única manera de iniciar sesión en su servidor (aparte de la consola) es poseer la llave privada que se combina con la llave pública que se instaló.

**Nota:** Desactive la autenticación de contraseña si ha instalado una llave pública para su usuario, tal como se recomienda en la sección anterior, paso cuatro. ! De lo contrario, se bloqueará fuera de su servidor!

Para deshabilitar la autenticación de contraseña en su servidor, siga estos pasos.

Como `root` o `su nuevo usuario de sudo`, abra la configuración del daemon de SSH:

    sudo nano /etc/ssh/sshd_config

Busque la línea que especifica `PasswordAuthentication`, borre el comentario eliminando el `#` anterior, luego cambie su valor a “no”. Debería verse así después de haber realizado el cambio:

sshd\_config — Desactive la autenticación de contraseña

    PasswordAuthentication no

Aquí hay otras dos configuraciones que son importantes para la autenticación de solo llave y se establecen de forma predeterminada. Si no ha modificado este archivo antes, no necesita cambiar esta configuración:

sshd\_config — Valores predeterminados importantes

    PubkeyAuthentication yes
    ChallengeResponseAuthentication no

Cuando termine de realizar sus cambios, guarde y cierre el archivo, usando el método que usamos anteriormente (pulsar `CTRL-X`, luego `Y`, después `ENTER`).

Escriba esto para recargar el deamon SSH

    sudo systemctl reload sshd

La autenticación de contraseña está deshabilitada. Su servidor ahora sólo es accesible con la autenticación de llave SSH.

## Paso Seis — Registro de prueba

Ahora, antes de salir del servidor, debe probar su nueva configuración. No desconecte hasta que confirme que puede iniciar sesión correctamente a través de SSH.

En una nueva terminal en su `máquina local`, inicie sesión en su servidor utilizando la nueva cuenta que creamos. Para ello, utilice este comando (sustituya su nombre de usuario y la dirección IP del servidor):

     ssh sammy@ip_del_servidor

Si agregó la autenticación de llave pública a su usuario, tal como se describe en los pasos cuatro y cinco, su llave privada se utilizará como autenticación. De lo contrario, se le pedirá la contraseña de su usuario.

**Nota sobre la autenticación de llaves:** Si creó el par de llaves con una frase de contraseña, se le pedirá que introduzca la contraseña para su llave. De lo contrario, si el par de llaves es sin contraseña, debe iniciar sesión en su servidor sin una contraseña.

Una vez que se proporciona la autenticación al servidor, se registrará como su nuevo usuario.

Recuerde, si necesita ejecutar un comando con privilegios de root, escriba “sudo” antes de que así:

    sudo comando_a_ejecutar

## Paso Siete — Configurar un Firewall Básico

Los servidores Ubuntu 16.04 pueden usar el firewall UFW para asegurarse de que sólo se permiten conexiones a ciertos servicios. Podemos configurar un firewall básico fácilmente utilizando esta aplicación.

Diferentes aplicaciones pueden registrar sus perfiles con UFW después de la instalación. Estos perfiles permiten al UFW gestionar estas aplicaciones por su nombre. OpenSSH, el servicio que nos permite conectarnos a nuestro servidor ahora, tiene un perfil registrado con UFW.

Puede ver esto escribiendo:

    sudo ufw app list

    OutputAvailable applications:
      OpenSSH

Necesitamos asegurarnos de que el firewall permita conexiones SSH para que podamos volver a conectarnos la próxima vez. Podemos permitir estas conexiones escribiendo:

    sudo ufw allow OpenSSH

Posteriormente, podemos habilitar el firewall escribiendo:

    sudo ufw enable

Escriba “y” y presione ENTER para continuar. Puede ver que las conexiones SSH todavía se permiten escribiendo:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

Si instala y configurar servicios adicionales, deberá ajustar la configuración del firewall para permitir el tráfico aceptable. Puede aprender algunas operaciones comunes de UFW en [esta guía](ufw-essentials-common-firewall-rules-and-commands).

## ¿A dónde ir desde aquí?

En este punto, usted tiene una base sólida para su servidor. Ahora puede instalar cualquier software que necesite en su servidor.
