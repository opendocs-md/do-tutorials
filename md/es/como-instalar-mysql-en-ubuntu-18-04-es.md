---
author: Mark Drake
date: 2019-04-26
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-mysql-en-ubuntu-18-04-es
---

# Cómo instalar MySQL en Ubuntu 18.04

_[Hazel Virdó](https://www.digitalocean.com/community/users/hazelnut) escribió una versión anterior de este tutorial._

### Introducción

[MySQL](https://www.mysql.com/) es un sistema de gestión de bases de datos de código abierto, que generalmente está instalado como parte de la popular combinación [LAMP](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04) (Linux, Apache, MySQL, PHP/Python/Perl). Gestiona sus datos usando una base de datos relacional y SQL (Lenguaje de consulta estructurada).

La versión breve de la instalación es simple: Actualice el índice de su paquete, instale el paquete `mysql-server` y luego ejecute el script de seguridad incluido.

    sudo apt update
    sudo apt install mysql-server
    sudo mysql_secure_installation

Este tutorial le explicará cómo instalar la versión 5.7 de MySQL en un servidor Ubuntu 18.04. No obstante, si pretende actualizar una instalación MySQL existente a la versión 5.7, puede leer [esta guía de actualización de MySQL 5.7](how-to-prepare-for-your-mysql-5-7-upgrade).

## Requisitos previos

Necesitará lo siguiente para seguir este tutorial:

- Un servidor Ubuntu 18.04 configurado siguiendo [esta guía de configuración inicial del servidor](initial-server-setup-with-ubuntu-18-04), incluyendo un usuario no **root** con privilegios de `sudo` y un firewall.

## Paso 1 — Instalar MySQL

Únicamente la última versión de MySQL se incluye en el repositorio de paquete APT de forma predeterminada en Ubuntu 18.04. Al momento de escribir esto, esa sería la versión MySQL 5.7.

Para instalarla, actualice el índice del paquete en su servidor con `apt`:

    sudo apt update

Luego, instale el paquete predeterminado:

    sudo apt install mysql-server

Esto instalará MySQL, pero no le pedirá que cree una contraseña ni que haga ningún otro cambio de configuración. Dado a que esto deja su instalación de MySQL insegura, vamos a abordarlo a continuación.

## Paso 2 — Configurar MySQL

Para las instalaciones recientes, querrá ejecutar el script de seguridad que viene incluido. Esto cambia algunas de las opciones predeterminadas menos seguras para cosas como inicios de sesión root remotos y usuarios de ejemplo. Para las versiones antiguas de MySQL, también deberá inicializar el directorio de datos manualmente, pero ahora esto se hace automáticamente.

Ejecute el script de seguridad:

    sudo mysql_secure_installation

Esto hará que pase por una serie de indicaciones en las que puede hacer algunos cambios en las opciones de seguridad de su instalación de MySQL. La primera indicación le preguntará si quiere configurar el plugin de Validación de Contraseña, la que puede usarse para probar la solidez de su contraseña de MySQL. Independientemente de lo que seleccione, la siguiente indicación será establecer una contraseña para el usuario **root** de MySQL. Ingrese y luego confirme una contraseña segura de su elección.

Desde este punto, puede presionar `Y` y luego `ENTER` para aceptar las configuraciones predeterminadas para todas las preguntas siguientes. Esto eliminará algunos usuarios anónimos y la base de datos de prueba, deshabilitará los inicios de sesión root remotos y cargará estas nuevas reglas para que MySQL respete los cambios que haya realizado inmediatamente.

Para iniciar el directorio de datos de MySQL, debe usar `mysql_install_db` para versiones anteriores a 5.7.6, y `mysqld --initialize` para la versión5.7.6 y posteriores. No obstante, si instaló MySQL desde la distribución Debian, como se describió en el Paso 1, el directorio de datos se inició automáticamente; no es necesario que haga nada. Si trata de ejecutar el comando igual, se le mostrará el siguiente error:

Output

    mysqld: Can't create directory '/var/lib/mysql/' (Errcode: 17 - File exists)
    . . .
    2018-04-23T13:48:00.572066Z 0 [ERROR] Aborting

Note que, si bien estableció una contraseña para el usuario **root** de MySQL, este usuario no está configurado para autenticarse con una contraseña al conectarse al shell de MySQL. Si quiere, puede ajustar esta configuración siguiendo el Paso 3.

## Paso 3 — (Opcional) Ajustar la autenticación y los privilegios del usuario

Para los sistemas Ubuntu que estén usando MySQL 5.7 (y las versiones posteriores), el usuario **root** de MySQL está configurado, de forma predeterminada, para autenticarse usando el plugin `auth_socket` en vez de una contraseña. En muchos casos, esto permite que la seguridad y usabilidad sea mayor pero también puede complicar las cosas cuando deba permitir que un programa externo (tal como phpMyAdmin) tenga acceso al usuario.

Deberá cambiar su método de autenticación de `auth_socket` a `mysql_native_password` para usar una contraseña para conectarse a MySQL como **root**. Para hacerlo, abra la indicación de MySQL desde su terminal:

    sudo mysql

Posteriormente, consulte cuál método de autenticación usa cada una de sus cuentas de usuario de MySQL usando el siguiente comando:

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

En este ejemplo, puede ver que el usuario **root** verdaderamente se autentica usando el plugin `auth_socket`. Para configurar la cuenta **root** para autenticarse usando una contraseña, ejecute el siguiente comando `ALTER USER`. Asegúrese de cambiar `password` (contraseña) a una contraseña segura de su elección y sepa que este comando cambiará la contraseña de **root** que estableció en el Paso 2:

    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';

Luego, ejecute `FLUSH PRIVILEGES` (purgar privilegios), lo que le dice al servidor que vuelva a cargar las tablas grant e implemente sus nuevos cambios:

    FLUSH PRIVILEGES;

Vuelva a verificar los métodos de autenticación que usa cada uno de sus usuarios para confirmar que **root** ya no se autentica usando el plugin `auth_socket`:

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

En este resultado de ejemplo, puede ver que, ahora, el usuario **root** de MySQL se autentica usando una contraseña. Una vez que confirme esto en su propio servidor, puede salir del shell de MySQL:

    exit

Alternativamente, para otras personas puede adaptarse mejor a su flujo de trabajo si se conectan a MySQL con un usuario dedicado. Para crear tal usuario, vuelva a abrir el shell de MySQL nuevamente:

    sudo mysql

**Nota:** Si tiene la autenticación de contraseña habilitada para root según se describió en los párrafos de arriba, deberá usar un comando diferente para acceder al shell de MySQL. Lo que se indica a continuación ejecutará su cliente MySQL con privilegios de usuario regular, y solamente tendrá privilegios de administrador dentro de la base de datos una vez que haga la autenticación:

    mysql -u root -p

Desde ese punto, cree un nuevo usuario y use una contraseña sólida:

    CREATE USER 'sammy'@'localhost' IDENTIFIED BY 'password';

Luego, dele a su nuevo usuario los privilegios adecuados. Por ejemplo, puede concederle al usuario privilegios a todas las tablas dentro de la base de datos, así como autoridad para agregar, cambiar y eliminar privilegios de usuario, mediante este comando:

    GRANT ALL PRIVILEGES ON *.* TO 'sammy'@'localhost' WITH GRANT OPTION;

Note que, en este punto, no necesita volver a ejecutar el comando `FLUSH PRIVILEGES`. Solamente necesita este comando al modificar las tablas grant utilizando declaraciones como `INSERT`, `UPDATE` o `DELETE`. Dado a que creó un usuario nuevo en vez de modificar uno existente, no es necesario que use `FLUSH PRIVILEGES` aquí.

Después de esto, salga del Shell de MySQL:

    exit

Por último, vamos a probar la instalación de MySQL.

## Paso 4 — Probar MySQL

Independientemente de cómo lo instaló, MySQL debería haber empezado a ejecutarse automáticamente. Para probar esto, verifique su estado.

    systemctl status mysql.service

Verá un resultado parecido al de abajo:

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

Si MySQL no se está ejecutando, puede iniciarlo usando `sudo systemctl start mysql`.

Para una verificación adicional, puede tratar de conectarse a la base de datos usando la herramienta `mysqladmin`, que es un cliente que le permite ejecutar comandos administrativos. Por ejemplo, este comando dice que se conecte a MySQL como **root** (`-u root`), pida una contraseña (`-p`) y devuelva la versión.

    sudo mysqladmin -p -u root version

Debería ver un resultado parecido a este:

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

Esto quiere decir que MySQL está funcionando.

## Conclusión

Ahora tiene una configuración básica de MySQL instalada en su servidor. Aquí le presentamos algunos ejemplos de los siguientes pasos que puede tomar:

- [Implementar algunas medidas de seguridad adicionales](how-to-secure-mysql-and-mariadb-databases-in-a-linux-vps)
- [Reubicar el directorio de datos](how-to-move-a-mysql-data-directory-to-a-new-location-on-ubuntu-16-04)
- [Gestionar los servidores MySQL con SaltStack](saltstack-infrastructure-creating-salt-states-for-mysql-database-servers)
