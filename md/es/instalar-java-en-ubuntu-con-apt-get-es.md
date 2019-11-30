---
author: Koen Vlaswinkel
date: 2014-12-03
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/instalar-java-en-ubuntu-con-apt-get-es
---

# Instalar Java en Ubuntu con Apt-Get

### Introducción

Muchos artículos y programas requieren ternet Java instalado, este artículo te guiarå lo suficiente para instalar y manejar las diferentes versiones de Java.

## Instalando JRE/JDK por defecto

Esta es la opción más fácil y recomendada. Esto instalará OpenJDK 6 en Ubuntu 12.04 y superiores, en el caso de 12.10+ se instalará OpenJDK 7.

Instalando Java con `apt-get` es fácil. Primero actualizamos el índice de la paquetería:

    sudo apt-get update

Después, revisa si Java no se ha instalado previamente:

    java -version

Si ese comando regresa “The program java can be found in the following packages”, significa que Java no ha sido instalado aún, de modo que ejecutaremos el siguiente comando:

    sudo apt-get install default-jre

Esto instlará Java Runtime Environment (JRE). Si necesitas en su lugar el Java Development Kit (JDK), que usualmente se requiere para compilar aplicaciones Java; por ejemplo [Apache Ant](http://ant.apache.org/), [Apache Maven](http://maven.apache.org/), [Eclipse](https://www.eclipse.org/) y [IntelliJ IDEA](http://www.jetbrains.com/idea/,%20etc.) entonces ejecuta el siguiente comando:

    sudo apt-get install default-jdk

Eso es todo lo que necesitas para instalar Java. Los otros pasos son opcionales y solo necesitan ejecutarse si son necesarios.

## Instalando OpenJDK 7 (opcional)

Para instalar OpenJDK 7, ejecutar el siguiente comando:

    sudo apt-get install openjdk-7-jre

Esto instalará el Java Runtime Environment (JRE). Si lo que requieres es el Java Development Kit (JDK), ejecuta el siguiente comando:

    sudo apt-get install openjdk-7-jdk

## Instalando Oracle JDK (opcional)

Oracle JDK es el JDK oficial; como sea, ya no es mås porporcionada por Oracle en la instalación por defecto para Ubuntu.

Aún es posible de instalar usando Apt-Get. Para instalar cualquier versión primero hay que ejecutar los siguientes commandos:

    sudo apt-get install python-software-properties
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update

Después, dependiendo de la versión que deseas instalar, ejecuta uno de los siguientes comandos:

### Oracle JDK 6

Es una versión vieja pero aún se usa.

    sudo apt-get install oracle-java6-installer

### Oracle JDK 7

Esta es la versión estable más reciente.

    sudo apt-get install oracle-java7-installer

### Oracle JDK 8

Esta es la versión para desarrolladores, el lanzamiento general fue programado para Marzo del 2014. Este [artículo externo de Java 8](http://www.techempower.com/blog/2013/03/26/everything-about-java-8/) podría ayudarte a entenderlo del todo.

    sudo apt-get install oracle-java8-installer

## Administrado Java (opcional)

Cuando tienes múltiples instalaciones de Java en tu Droplet, la versión de Java por defecto puede ser elegida al gusto. Para hacerlo, ejecuta el siguiente comando:

    sudo update-alternatives --config java

Usualmente regresa algo como esto si tienes 2 instalaciones (si tienes más, seguramente regresará mås):

    There are 2 choices for the alternative java (providing /usr/bin/java).
    
    Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 auto mode
      1 /usr/lib/jvm/java-6-openjdk-amd64/jre/bin/java 1061 manual mode
      2 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 manual mode
    
    Press enter to keep the current choice[*], or type selection number:

Ahora puedes seleccionar la versión que deseas utilizar por defecto. Esto también puede aplicarse para el compilador Java (`javac`):

    sudo update-alternatives --config javac

Es la misma pantalla de selección que la del comando previo y debe usarse con el mismo sentido. Este comando puede ser ejecutado para el resto de los comandos con diferentes instalaciones. En Java, esto incluye pero no se limita a: `keytool`, `javadoc` y `jarsigner`.

## Configurando la variable de entorno “JAVA\_HOME”

Para configurar la variable de entorno `JAVA_HOME`, la cual es necesaria para algunos programas, lo primero es encontrar la ruta de la instalación de Java:

    sudo update-alternatives --config java

Lo que nos regresará algo como esto:

    There are 2 choices for the alternative java (providing /usr/bin/java).
    
    Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 auto mode
      1 /usr/lib/jvm/java-6-openjdk-amd64/jre/bin/java 1061 manual mode
      2 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 manual mode
    
    Press enter to keep the current choice[*], or type selection number:

Las rutas de instalación para cada versión:

1. `/usr/lib/jvm/java-7-oracle`
2. `/usr/lib/jvm/java-6-openjdk-amd64`
3. `/usr/lib/jvm/java-7-oracle`

Copia la ruta de la instalación que deseas y edita el archivo `/etc/environment`:

    sudo nano /etc/environment

En este archivo, agrega la siguiente línea (remplazando TU\_RUTA por la ruta que has copiado):

    JAVA_HOME="TU_RUTA"

Eso debe ser suficiente para configurar la variable de entorno. Ahora recarga este archivo:

    source /etc/environment

Pruébalo ejecutando:

    echo $JAVA_HOME

Si eso regresa solo la ruta, la variable de entorno ha sido configurada correctamente. De lo contrario, por favor asegúrate de haber seguido todos los pasos correctamente.
