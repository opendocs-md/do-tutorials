---
author: Koen Vlaswinkel
date: 2016-12-12
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-java-con-apt-get-en-ubuntu-16-04-es
---

# ¿Cómo instalar Java con Apt-Get en Ubuntu 16.04?

### Introducción

Java y la JVM (Máquina Virtual de Java) son ampliamente utilizados y requeridos para muchos tipos de software. Este artículo lo guiará en el proceso de instalación y gestión de diferentes versiones de Java utilizando `apt-get`.

## Requisitos Previos

Para seguir este tutorial, necesita:

- Un servidor de Ubuntu 16.04
- Un usuario sudo que no sea root, puede configurarlo siguiendo la [guía de configuración inicial del servidor de Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).

## Instalación por Defecto JRE/JDK

La opción más fácil para la instalación de Java es utilizando la versión empaquetada con Ubuntu. En concreto, esto instalará OpenJDK 8, la última versión recomendada.

En primer lugar, actualizaremos el índice de paquetes.

    sudo apt-get update

A continuación, instalaremos Java. Específicamente, este comando instalará el entorno de ejecución de Java (JRE).

    sudo apt-get install default-jre

Hay otra instalación por defecto de Java llamada JDK (Java Development Kit). El JDK por lo general sólo se necesita si va a compilar programas Java o si el software que va a utilizar Java lo requiere específicamente.

El JDK contiene el JRE, así que no hay inconvenientes si se instala el JDK en lugar de la JRE, excepto por el tamaño del archivo.

Puede instalar el JDK con el siguiente comando:

    sudo apt-get install default-jdk

## Instalación del JDK de Oracle

Si desea instalar el JDK de Oracle, que es la versión oficial distribuida por Oracle, tendrá que seguir unos pasos más.

En primer lugar, agregue PPA de Oracle, a continuación, luego actualice el repositorio de paquetes.

    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update

Luego, dependiendo de la versión que desee instalar, ejecutaremos uno de los siguientes comandos:

### Oracle JDK 8

Esta es la última versión estable de Java por el momento, y la versión recomendada para instalar. Puede hacerlo utilizando el siguiente comando:

    sudo apt-get install oracle-java8-installer

### Oracle JDK 9

Esta es una vista previa para desarrolladores y la liberación general está prevista para marzo de 2017. No se recomienda que utilice esta versión, porque todavía puede haber problemas de seguridad y errores. Hay más información acerca de Java 9 en la [página oficial de JDK 9](http://jdk.java.net/9/).

Para instalar JDK 9, utilice el siguiente comando:

    sudo apt-get install oracle-java9-installer

## Gestionando Java

Puede haber varias instalaciones de Java en un servidor. Puede configurar cual será la versión por defecto para su uso mediante la línea de comandos usando `update-alternatives`, que gestiona cuales enlaces simbólicos se utilizan para diferentes comandos.

    sudo update-alternatives --config java

La salida será algo así como lo siguiente. En este caso, esto es lo que la salida mostrará con todas las versiones de Java instalada antes mencionados.

Output

    There are 5 choices for the alternative java (providing /usr/bin/java).
    
      Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 1081 auto mode
      1 /usr/lib/jvm/java-6-oracle/jre/bin/java 1 manual mode
      2 /usr/lib/jvm/java-7-oracle/jre/bin/java 2 manual mode
      3 /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 1081 manual mode
      4 /usr/lib/jvm/java-8-oracle/jre/bin/java 3 manual mode
      5 /usr/lib/jvm/java-9-oracle/bin/java 4 manual mode
    
    Press <enter> to keep the current choice[*], or type selection number:

Ahora puede elegir el número que desea usar como predeterminado. Esto también se puede hacer para otros comandos Java, como el compilador (`javac`), el generador de documentación (`javadoc`), la herramienta JAR de firma (`jarsigner`), y más. Se puede utilizar el siguiente comando, rellenando el comando que desea personalizar:

    sudo update-alternatives --config command 

## Definiendo la Variable de Entorno JAVA\_HOME

Muchos programas, como los servidores de Java, usan la variable de entorno `JAVA_HOME` para determinar la ubicación de la instalación de Java. Para establecer esta variable de entorno, primero debe averiguar donde está instalado Java. Puede hacer esto mediante la ejecución del mismo comando que en el apartado anterior.

    sudo update-alternatives --config java

Copiar la ruta de la instalación preferida y luego abrir `/etc/environment` usando `nano` o su editor de texto favorito.

    sudo nano /etc/environment

Al final de este archivo, agregue la siguiente línea, asegurándose de sustituir la ruta resaltada con su ruta copiada.

/etc/environment

    JAVA_HOME="/usr/lib/jvm/java-8-oracle"

Guarde, salga del archivo y vuelva a cargarlo.

    source /etc/environment

Ahora puede probar si la variable de entorno se ha establecido mediante la ejecución del siguiente comando:

    echo $JAVA_HOME

Esto devolverá la ruta que acaba de establecer.

## Conclusión

Ahora ha instalado Java y sabe cómo manejar diferentes versiones de la misma. Ahora puede instalar el software que se ejecuta en Java, como son Tomcat, Jetty, Glassfish, Cassandra, o Jenkins.
