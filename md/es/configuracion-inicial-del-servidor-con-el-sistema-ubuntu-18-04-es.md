---
author: Justin Ellingwood
date: 2018-11-05
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/configuracion-inicial-del-servidor-con-el-sistema-ubuntu-18-04-es
---

# Configuración inicial del servidor con el sistema Ubuntu 18.04

### Introducción

Para crear un nuevo servidor Ubuntu 18.04, debe seguir algunos pasos iniciales como parte de la configuración básica. Esto aumentará la seguridad y la facilidad de uso del servidor y constituirá una base sólida para acciones posteriores.

**Nota** : la siguiente guía muestra cómo completar manualmente los pasos que recomendamos para los nuevos servidores Ubuntu 18.04. Seguir este procedimiento en forma manual puede ser útil para adquirir algunas habilidades básicas de administración del sistema y como un ejercicio para comprender acabadamente las acciones que se realizan en el servidor. Como alternativa, si desea comenzar a trabajar más rápidamente, puede [ejecutar nuestro script de configuración inicial del servidor](automating-initial-server-setup-with-ubuntu-18-04) que automatiza estos pasos.

## Paso 1 — Iniciar sesión como usuario «raíz»

Para iniciar sesión en el servidor, deberá conocer su «dirección IP pública del servidor». También necesitará la contraseña o, si instaló una clave SSH para la autenticación, la clave privada para la cuenta del usuario «raíz». Si aún no ha iniciado sesión en su servidor, puede seguir nuestra guía sobre [cómo conectarse a su Droplet con SSH](how-to-connect-to-your-droplet-with-ssh), que cubre este proceso en detalle.

Si aún no está conectado a su servidor, avance e inicie sesión como usuario «raíz» con el siguiente comando (sustituya la parte resaltada del comando con la dirección IP pública del servidor):

    ssh root@your_server_ip

Si aparece, acepte la advertencia sobre la autenticidad del host. Si utiliza la autenticación de contraseña, indique su contraseña «raíz» para iniciar sesión. Si tiene una clave SSH que está protegida con una frase de contraseña, es posible que se le solicite ingresar la frase de contraseña la primera vez que use la clave en cada sesión. Si es la primera vez que inicia sesión en el servidor con una contraseña, es posible que también se le solicite que cambie la contraseña «raíz».

### Acerca del usuario «raíz»

El usuario «raíz» es el usuario administrativo en un entorno Linux que tiene privilegios muy amplios. Debido a los mayores privilegios de la cuenta «raíz», se recomienda no utilizarla regularmente. Esto se debe a que parte del poder inherente de la cuenta «raíz» es la capacidad de realizar cambios que podrían resultar muy destructivos, incluso en forma accidental.

El siguiente paso es configurar una cuenta de usuario alternativa con un alcance reducido para el trabajo cotidiano. Le enseñaremos cómo obtener mayores privilegios en los momentos en que los necesite.

## Paso 2 — Crear un nuevo usuario

Una vez que haya iniciado sesión como «raíz», estará preparado para agregar la nueva cuenta de usuario que usará para iniciar sesión de ahora en adelante.

Este ejemplo crea un nuevo usuario llamado «sammy», pero debe reemplazarlo con el nombre de usuario de su preferencia:

    adduser sammy

Se le harán algunas preguntas, comenzando con la contraseña de la cuenta.

Ingrese una contraseña segura y, opcionalmente, complete cualquier información adicional si lo desea. Esto no es obligatorio y puede presionar «INTRO» en cualquier campo que desee omitir.

## Paso 3 — Concesión de privilegios administrativos

Ahora, tenemos una nueva cuenta de usuario con los privilegios de una cuenta regular. Sin embargo, a veces necesitamos realizar tareas administrativas.

Para evitar tener que cerrar la sesión del nuestro usuario regular y volver a iniciar sesión con la cuenta «raíz», podemos configurar lo que se conoce como privilegios de «superusuario» o «raíz» para nuestra cuenta regular. Esto permitirá a nuestro usuario regular ejecutar comandos con privilegios administrativos poniendo la palabra «sudo» antes de cada comando.

Para agregar estos privilegios a nuestro nuevo usuario, necesitamos agregar el nuevo usuario al grupo «sudo». De forma predeterminada, Ubuntu 18.04 permite que los usuarios que pertenecen al grupo «sudo» usen el comando «sudo».

Desde la cuenta «raíz», ejecute este comando para agregar su nuevo usuario al grupo «sudo» (sustituya la palabra resaltada con su nuevo usuario):

    usermod -aG sudo sammy

Ahora, cuando inicie sesión como su usuario regular, puede escribir «sudo» antes de los comandos para realizar acciones con privilegios de superusuario.

## Paso 4 — Configuración de un cortafuegos básico

Los servidores Ubuntu 18.04 pueden usar el cortafuegos UFW para asegurarse de que solo se permitan conexiones a ciertos servicios. Podemos configurar un cortafuegos básico muy fácilmente con esta aplicación.

**Nota** : si sus servidores se ejecutan en DigitalOcean, puede usar opcionalmente [DigitalOcean Cloud Firewalls](an-introduction-to-digitalocean-cloud-firewalls) en lugar del cortafuegos UFW. Recomendamos utilizar solo un cortafuegos a la vez para evitar reglas conflictivas que sean difíciles de depurar.

Las diferentes aplicaciones pueden registrar sus perfiles en UFW después de la instalación. Estos perfiles permiten a UFW administrar estas aplicaciones por nombre. OpenSSH, el servicio que nos permite conectarnos a nuestro servidor ahora, tiene un perfil registrado en UFW.

Puede verlo si ingresa:

    ufw app list

    OutputAvailable applications:
      OpenSSH

Necesitamos asegurarnos de que el cortafuegos permita conexiones SSH para que podamos volver a iniciar sesión la próxima vez. Podemos permitir estas conexiones si escribimos:

    ufw allow OpenSSH

Seguidamente, podemos habilitar el cortafuegos si escribimos:

    ufw enable

Escriba «y» y presione «INTRO» para avanzar. Puede ver que estas conexiones SSH aún están permitidas si escribe:

    ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

Como «el servidor de seguridad está bloqueando actualmente todas las conexiones excepto SSH», si instala y configura servicios adicionales, deberá ajustar la configuración del cortafuegos para permitir la entrada de tráfico aceptable. Puede aprender algunas operaciones comunes de UFW en [esta guía](ufw-essentials-common-cortafuegos-rules-and-commands).

## Paso 5 — habilitación del acceso externo para su usuario regular

Ahora que tenemos un usuario regular para el uso cotidiano, debemos asegurarnos de poder ingresar directamente a la cuenta con SSH.

**Nota** : hasta que verifique que puede iniciar sesión y usar «sudo» con su nuevo usuario, le recomendamos que permanezca conectado como «raíz». De esta manera, si tiene problemas, puede solucionarlos y hacer los cambios necesarios como «raíz». Si utiliza un Droplet DigitalOcean y tiene problemas con su conexión SSH «raíz», puede [iniciar sesión en Droplet utilizando la consola DigitalOcean](how-to-use-the-digitalocean-console-to-access-your-droplet).

El proceso para configurar el acceso SSH para su nuevo usuario depende de si la cuenta «raíz» de su servidor utiliza una contraseña o claves SSH para la autenticación.

### Si la cuenta raíz utiliza autenticación de contraseña

Si inició sesión en su cuenta «raíz» con «una contraseña», la autenticación de la contraseña está habilitada para SSH. Puede incorporar SSH a su nueva cuenta de usuario abriendo una nueva sesión de terminal y usando SSH con su nuevo nombre de usuario:

    ssh sammy@your_server_ip

Después de ingresar la contraseña de usuario regular, habrá iniciado sesión. Recuerde, si necesita ejecutar un comando con privilegios administrativos, escriba «sudo» antes, de esta manera:

    sudo command_to_run

Se le solicitará su contraseña de usuario regular cuando use «sudo» por primera vez en cada sesión (y periódicamente después).

Para mejorar la seguridad de su servidor, «recomendamos enfáticamente que configure las claves SSH en lugar de usar la autenticación de contraseña». Siga las indicaciones de nuestra guía sobre [configuración de claves SSH en Ubuntu 18.04](how-to-set-up-ssh-keys-on-ubuntu-1804) para saber cómo configurar la autenticación basada en clave.

### Si la cuenta raíz utiliza autenticación de clave SSH

Si inició sesión en su cuenta «raíz» utilizando «claves SSH», la autenticación de la contraseña está «deshabilitada» para SSH. Para iniciar sesión correctamente, deberá agregar una copia de su clave pública local al archivo «~/.ssh/authorized\_keys» del nuevo usuario.

Dado que su clave pública ya está en el archivo «~/.ssh/authorized\_keys» de la cuenta «raíz», puede copiar ese archivo y la estructura de directorios en nuestra nueva cuenta de usuario de la sesión actual.

La forma más sencilla de copiar los archivos con la propiedad y los permisos correctos es con el comando «rsync». Esto copiará el directorio «.ssh» del usuario «raíz», conservará los permisos y modificará los propietarios del archivo, todo en un solo comando. Asegúrese de cambiar las partes resaltadas del comando a continuación para que coincidan con el nombre de su usuario regular:

**Nota** : el comando «rsync» trata los orígenes y destinos que terminan con una barra diagonal de manera diferente a aquellos sin barra diagonal final. Cuando utilice «rsync» a continuación, asegúrese de que el directorio de origen («~/.ssh») «no» incluya una barra diagonal final (compruebe que no esté utilizando «~/.ssh/»).

Si accidentalmente agrega una barra diagonal al comando, «rsync» copiará el «contenido» del directorio «~/.ssh» de la cuenta «raíz» en el directorio principal del usuario «sudo» en lugar de copiar toda la estructura del directorio «~/.ssh». Los archivos estarán en la ubicación incorrecta y SSH no podrá encontrarlos ni utilizarlos.

    rsync --archive --chown=sammy:sammy ~/.ssh /home/sammy

Ahora, abra una nueva sesión de terminal y use SSH con su nuevo nombre de usuario:

    ssh sammy@your_server_ip

Debe iniciar sesión en la cuenta de usuario nuevo sin utilizar contraseña. Recuerde, si necesita ejecutar un comando con privilegios administrativos, escriba «sudo» antes, de esta manera:

    sudo command_to_run

Se le solicitará su contraseña de usuario regular cuando use «sudo» por primera vez en cada sesión (y periódicamente después).

## ¿Dónde ir a partir de aquí?

En este punto, tiene una base sólida para su servidor. Ahora, puede instalar en él cualquier software que necesite.
