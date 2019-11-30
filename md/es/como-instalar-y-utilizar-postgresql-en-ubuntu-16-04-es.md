---
author: Justin Ellingwood
date: 2016-12-12
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-y-utilizar-postgresql-en-ubuntu-16-04-es
---

# ¿Cómo Instalar y Utilizar PostgreSQL en Ubuntu 16.04?

### Introducción

Los sistemas de administración de bases de datos relacionales son un componente clave en muchos sitios y aplicaciones web. Estos proveen un camino estructurado para almacenar, organizar y acceder a información.

**PostgreSQL** , o Postgres, es un sistema de administración de bases de datos relacionales que proporciona una implementación del lenguaje de consultas SQL. Es una elección popular para muchos proyectos pequeños y grandes, y tiene la ventaja de ser compatible con los estándares y tener muchas características avanzadas como transacciones y concurrencia sin bloqueos de lectura.

En esta guía, demostraremos como instalar Postgress en un VPS con Ubuntu 16.04 y algunas formas básicas de uso.

## Instalación

Los repositorios por defecto de Ubuntu contienen paquetes Postgres, así que podemos instalarlo fácilmente utilizando el sistema de paquetería `apt`.

Debido a que es nuestra primera vez utilizando `apt` en esta sesión, debemos refrescar nuestro índice de paquetes locales. Podemos instalar el paquete Postgres y un paquete `contrib` que agrega algunas funciones y utilerías adicionales.

    sudo apt-get update
    sudo apt-get install postgresql postgresql-contrib

Ahora que nuestro software está instalado, podemos proceder para ver como funciona y que lo hace diferente de sistema de administración de bases de datos que probablemente haya utilizado.

## Utilizando Roles y Bases de Datos PostgreSQL

Por defecto, Postgress utiliza un concepto llamado “roles” que maneja identificación y autorización. Estos son, de algún modo, similares a los estilos de cuentas en Unix, pero Postgres no distingue entre usuarios y grupos y en su lugar prefiere ser más flexible con el término “rol”

Al concluir la instalación Postgres está listo para utilizar la identificación `ident`, lo que significa que asocia los roles de Postgres con una cuenta de sistema Unix/Linux. Si el rol existe en Postres, un nombre de usuario Unix/Linux con el mismo nombre podrá identificarse como ese rol.

Hay diferentes caminos para utilizar esta cuenta y acceder a Postfres.

### Cambiando a una Cuenta Postgres

El procedimiento de instalación creó a un usuario llamado `postgres` que está asociado con el rol Postgres por defecto. Para utilizar Postgres, puede identificarse con esa cuenta.

Cambie a la cuenta `postgres` en su servidor escribiendo:

    sudo -i -u postgres

Ahora puede acceder a la consola Postgres inmediatamente escribiendo:

    psql

Ahora será ingresado y tendrá acceso para interactuar con el sistema de administración de bases de datos.

Salga de la consola PostgreSQL escribiendo:

    \q

Ahora debe salir de la consola de `postgres` a Linux.

### Acceso a la Consola de Postgres sin Cambiar de Cuentas

También puede ejecutar el comando que desee con la cuenta `postgres` directamente con `sudo`.

Por instancia, en el último ejemplo, sólo queríamos llegar a la consola de Postgres. Podríamos hacer esto en un solo paso ejecutando simplemente el comando `psql` como usuario `postgres` con `sudo` como este:

    sudo -u postgres psql

Esto lo registrará directamente en Postgres sin el intermediario `bash` shell en el medio.

Una vez más, puede salir de la sesión interactiva de Postgres escribiendo:

    \q

## Crear un Nuevo Rol

Actualmente, sólo tenemos el rol de `postgres` configurado dentro de la base de datos. Podemos crear nuevos roles desde la línea de comandos con el comando `createrole`. La bandera `--interactive` le pedirá los valores necesarios.

Si ha iniciado sesión como cuenta `postgres`, puede crear un nuevo usuario escribiendo:

    createuser --interactive

Si, en cambio, prefiere utilizar `sudo` para cada comando sin cambiar de su cuenta normal, puede escribir:

    sudo -u postgres createuser --interactive

El script le pedirá algunas opciones y, en base a sus respuestas, ejecute los comandos Postgres correctos para crear un usuario según sus especificaciones.

    OutputEnter name of role to add: sammy
    Shall the new role be a superuser? (y/n) y

Puede obtener más control pasando algunas banderas adicionales. Eche un vistazo a las opciones mirando la página de manual:

    man createuser

## Crear una Nueva Base de Datos

De forma predeterminada, otra suposición que hace el sistema de autenticación de Postgres es que habrá una base de datos con el mismo nombre que el rol que se utiliza para iniciar la sesión, a la que el rol tiene acceso.

Así que si en la última sección, creamos un usuario llamado `sammy`, ese rol intentará conectarse a una base de datos que también se llama `sammy` por defecto. Puede crear la base de datos apropiada con el comando `createdb`.

Si ha iniciado sesión en la cuenta `postgres`, debería escribir algo como:

    createdb sammy

Si, en su lugar, prefiere usar `sudo` para cada comando sin cambiar de su cuenta normal, debería escribir:

    sudo -u postgres createdb sammy

## Abrir la Consola de Postgres con el Nuevo Rol

Para iniciar sesión con la autenticación basada en `ident`, necesitará un usuario de Linux con el mismo nombre que su función y base de datos de Postgres.

Si no dispone de un usuario Linux disponible, puede crear uno con el comando `adduser`. Tendrás que hacerlo desde una cuenta con privilegios de `sudo` (no iniciado sesión como usuario de `postgres`):

    sudo adduser sammy

Una vez que tenga disponible la cuenta adecuada, puede cambiar y conectarse a la base de datos escribiendo:

    sudo -i -u sammy
    psql

O bien, puede hacerlo en línea:

    sudo -u sammy psql

Se iniciará sesión automáticamente asumiendo que todos los componentes se han configurado correctamente.

Si desea que su usuario se conecte a una base de datos diferente, puede hacerlo especificando la base de datos de esta manera:

    psql -d postgres

Una vez conectado, puede comprobar su información de conexión actual escribiendo:

    \conninfo

    OutputYou are connected to database "sammy" as user "sammy" via socket in "/var/run/postgresql" at port "5432".

Esto puede ser útil si se está conectando a bases de datos que no son predeterminadas o con usuarios no predeterminados.

## Crear y Eliminar Tablas

Ahora que ya sabes cómo conectarte al sistema de bases de datos de PostgreSQL, podemos averiguar cómo completar algunas tareas básicas.

En primer lugar, podemos crear una tabla para almacenar algunos datos. Creemos una tabla que describa el equipo del patio.

La sintaxis básica para este comando es algo como esto:

    CREATE TABLE table_name (
        column_name1 col_type (field_length) column_constraints,
        column_name2 col_type (field_length),
        column_name3 col_type (field_length)
    );

Como puede ver, le damos a la tabla un nombre y luego definimos las columnas que queremos, así como el tipo de columna y la longitud máxima de los datos de campo. También podemos añadir opcionalmente restricciones de tabla para cada columna.

Puede obtener más información sobre [cómo crear y administrar tablas en Postgres](how-to-create-remove-manage-tables-in-postgresql-on-a-cloud-server) aquí.

Para nuestros propósitos, vamos a crear una tabla simple como esta:

    CREATE TABLE playground (
        equip_id serial PRIMARY KEY,
        type varchar (50) NOT NULL,
        color varchar (25) NOT NULL,
        location varchar(25) check (location in ('north', 'south', 'west', 'east', 'northeast', 'southeast', 'southwest', 'northwest')),
        install_date date
    );

Hemos hecho una mesa de juegos que inventaría el equipo que tenemos. Esto comienza con un identificador de equipo, que es del tipo `serial`. Este tipo de datos es un entero de incremento automático. Hemos dado a esta columna la restricción de `primary key`, lo que significa que los valores deben ser únicos y no nulos.

Para dos de nuestras columnas (`equip_id` e `install_date`), no hemos dado una longitud de campo. Esto se debe a que algunos tipos de columna no requieren una longitud determinada porque la longitud está implícita en el tipo.

A continuación, damos columnas para el `type` (tipo) de equipo y el `color`, cada uno de los cuales no puede estar vacío. Creamos una columna de `location` (ubicación) y creamos una restricción que requiere que el valor sea uno de los ocho posibles valores. La última columna es una columna de fecha que registra la fecha en la que instalamos el equipo.

Podemos ver nuestra nueva tabla escribiendo:

    \d

    Output List of relations
     Schema | Name | Type | Owner 
    --------+-------------------------+----------+-------
     public | playground | table | sammy
     public | playground_equip_id_seq | sequence | sammy
    (2 rows)

Nuestra table está aquí, pero también tenemos algo llamado `playground_equip_id_seq` que es del tipo `sequence`. Esta es una representación del tipo `serial` que le dimos a nuestra columna `equip_id`. Esto realiza un seguimiento del siguiente número en la secuencia y se crea automáticamente para columnas de este tipo.

Si desea ver sólo la tabla sin la secuencia, puede escribir:

    \dt

    Output List of relations
     Schema | Name | Type | Owner 
    --------+------------+-------+-------
     public | playground | table | sammy
    (1 row)

## Agregar, Consultar y Eliminar Datos en una Tabla

Ahora que tenemos una tabla, podemos insertar algunos datos en ella.

Vamos a añadir un slide y un swing. Hacemos esto llamando a la tabla que queremos añadir, nombrando las columnas y luego proporcionando datos para cada columna. Nuestro slide y swing se podrían agregar como esto:

    INSERT INTO playground (type, color, location, install_date) VALUES ('slide', 'blue', 'south', '2014-04-28');
    INSERT INTO playground (type, color, location, install_date) VALUES ('swing', 'yellow', 'northwest', '2010-08-16');

Debe tener cuidado al ingresar los datos para evitar algunos atascos comunes. En primer lugar, tenga en cuenta que los nombres de columna no se deben citar, pero los _valores_ de columna que está ingresando necesitan citas.

Otra cosa a tener en cuenta es que no ingresamos un valor para la columna `equip_id`. Esto se debe a que se genera automáticamente cada vez que se crea una nueva fila en la tabla.

A continuación, podemos recuperar la información que hemos añadido escribiendo:

    SELECT * FROM playground;

    Output equip_id | type | color | location | install_date 
    ----------+-------+--------+-----------+--------------
            1 | slide | blue | south | 2014-04-28
            2 | swing | yellow | northwest | 2010-08-16
    (2 rows)

Aquí, usted puede ver que nuestro `equip_id` ha sido llenado con éxito y que todos nuestros otros datos se han organizado correctamente.

Si el slide en el background se rompe y tenemos que quitarla, también podemos quitar la fila de nuestra tabla escribiendo:

    DELETE FROM playground WHERE type = 'slide';

Si consultamos nuevamente nuestra tabla, veremos que nuestro slide ya no forma parte de la tabla:

    SELECT * FROM playground;

    Output equip_id | type | color | location | install_date 
    ----------+-------+--------+-----------+--------------
            2 | swing | yellow | northwest | 2010-08-16
    (1 row)

## Agregar y Eliminar Columnas de una Tabla

Si queremos modificar una tabla después de haberla creado para añadir una columna adicional, podemos hacerlo fácilmente.

Podemos agregar una columna para mostrar la última visita de mantenimiento para cada equipo escribiendo:

    ALTER TABLE playground ADD last_maint date;

Si vuelve a ver la información de la tabla, verá que se ha agregado la nueva columna (pero no se han introducido datos):

    SELECT * FROM playground;

    Output equip_id | type | color | location | install_date | last_maint 
    ----------+-------+--------+-----------+--------------+------------
            2 | swing | yellow | northwest | 2010-08-16 | 
    (1 row)

Podemos borrar una columna con la misma facilidad. Si encontramos que nuestro equipo de trabajo utiliza una herramienta separada para realizar un seguimiento del historial de mantenimiento, podemos deshacernos de la columna escribiendo:

    ALTER TABLE playground DROP last_maint;

## Cómo Actualizar Datos en una Tabla

Sabemos cómo agregar registros a una tabla y cómo eliminarlos, pero no hemos cubierto cómo modificar las entradas existentes todavía.

Puede actualizar los valores de una entrada existente consultando el registro que desea y establecer la columna en el valor que desea utilizar. Podemos consultar el registro de “swing” (esto coincidirá con cada swing en nuestra tabla) y cambiar su color a “rojo”. Esto podría ser útil si le dimos al swing un trabajo de pintura:

    UPDATE playground SET color = 'red' WHERE type = 'swing';

Podemos verificar que la operación fue exitosa consultando nuevamente nuestros datos:

    SELECT * FROM playground;

    Output equip_id | type | color | location | install_date 
    ----------+-------+-------+-----------+--------------
            2 | swing | red | northwest | 2010-08-16
    (1 row)

Como puede ver, nuestro slide está ahora registrado como rojo.

## Conclusión

Ahora está configurado su servidor Ubuntu 16.04 con PostgreSQL. Sin embargo, todavía hay mucho más que aprender con Postgres. Estas son algunas guías que cubren cómo usar Postgres:

- [Una comparación de sistemas de gestión de bases de datos relacionales](sqlite-vs-mysql-vs-postgresql-a-comparison-of-relational-database-management-systems)
- [Aprenda a crear y administrar tablas con Postgres](how-to-create-remove-manage-tables-in-postgresql-on-a-cloud-server)
- [Mejore la gestión de roles y permisos](how-to-use-roles-and-manage-grant-permissions-in-postgresql-on-a-vps--2)
- [Consultas de trabajo con Postgres con Select](how-to-create-data-queries-in-postgresql-by-using-the-select-command)
- [Aprenda cómo proteger PostgreSQL](how-to-secure-postgresql-on-an-ubuntu-vps)
- [Aprenda a realizar copias de seguridad de una base de datos de Postgres](how-to-backup-postgresql-databases-on-an-ubuntu-vps)
