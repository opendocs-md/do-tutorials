---
author: Koen Vlaswinkel
date: 2014-12-03
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-java-no-ubuntu-com-apt-get-pt
---

# Como instalar o Java no Ubuntu com apt-get

### Introdução

Como uma grande quantidade de artigos e programas necessitam ter o Java instalado, este artigo irá guiá-lo através do processo de instalação e gerenciamento de diferentes versões de Java.

## Instalando o JRE/JDK padrão

Esta é a opção mais fácil e recomendada. Isto irá instalar o OpenJDK no Ubuntu 12.04 e anteriores e no 12.10+ instalará o OpenJDK7.

Instalar o Java com `apt-get` é fácil. Primeiro, atualize a lista de pacotes:

    sudo apt-get update

Então, verifique se o Java já não se encontra instalado:

    java -version

Se isso retornar “The program java can be found in the following packages”, o Java não foi instalado ainda, então execute o seguinte commando:

    sudo apt-get install default-jre

Isto irá instalar o Java Runtime Environment(JRE). Se em vez disso, você precisa do Java Development Kit (JDK), que é geralmente necessário para compilar aplicações Java (por exemplo Apache Ant, Apache Maven, Eclipse e IntelliJ IDEA), execute o seguinte comando:

    sudo apt-get install default-jdk

Isto é tudo que é necessário para instalar o Java.

Todos os outros passos são opcionais e devem ser executados quando necessário.

## Instalando o OpenJDK7 (opcional)

Para instalar o OpenJDK7 execute o seguinte comando:

    sudo apt-get install openjdk-7-jre 

Isto irá instalar o Java Runtime Environment(JRE). Se em vez disso, você precisa do Java Development Kit (JDK), execute o seguinte comando:

    sudo apt-get install openjdk-7-jdk

## Instalando o Oracle JDK (Opcional)

O Oracle JDK é o JDK oficial; contudo, ele não é mais fornecido pela Oracle como instalação padrão no Ubuntu.

Você ainda pode instalá-lo utilizando `apt-get`. Para instalar qualquer versão , primeiro execute os seguintes comandos:

    sudo apt-get install python-software-properties
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update

Então, dependendo da versão que você quer instalar, execute um dos seguintes comandos:

### Oracle JDK 6

Esta é uma versão antiga mas ainda em uso.

    sudo apt-get install oracle-java6-installer

### Oracle JDK 7

Esta é a ultima versão estável.

    sudo apt-get install oracle-java7-installer

### Oracle JDK 8

Este é um preview para desenvolvedores, o lançamento oficial está agendado para Março de 2014. [Este artigo externo sobre Java 8](http://www.techempower.com/blog/2013/03/26/everything-about-java-8/) poderá ajudá-lo a entender tudo sobre ele.

    sudo apt-get install oracle-java8-installer

## Gerenciando o Java (Opcional)

Quando existem múltiplas instalações Java em seu ambiente, a versão Java para utilizar como padrão pode ser escolhida. Para fazer isto, execute o seguinte comando:

    sudo update-alternatives --config java

Ele geralmente retorna algo assim se você tiver 2 instalações (se você tiver mais, ele retornará mais, é claro):

    There are 2 choices for the alternative java (providing /usr/bin/java).
    
    Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 auto mode
      1 /usr/lib/jvm/java-6-openjdk-amd64/jre/bin/java 1061 manual mode
      2 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 manual mode
    
    Press enter to keep the current choice[*], or type selection number:

Agora você pode escolher o número para utilizar como padrão. Isto também pode ser feito para o compilador Java (`javac`):

    sudo update-alternatives --config javac

Esta é a mesma tela de seleção do comando anterior e deve ser utilizado da mesma forma. Este comando pode ser executado para todos os outros comandos que possuem diferentes instalações.

Em Java, isto inclui mas não se limita a: `keytool`, `javadoc` and `jarsigner`.

## Definindo a variável de ambiente “JAVA\_HOME”

Para definir a variável de ambiente `JAVA_HOME` , que é necessária para alguns programas, primeiramente encontre o caminho da sua instalação Java:

    sudo update-alternatives --config java

Ele retorna algo como:

    There are 2 choices for the alternative java (providing /usr/bin/java).
    
    Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 auto mode
      1 /usr/lib/jvm/java-6-openjdk-amd64/jre/bin/java 1061 manual mode
      2 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 manual mode
    
    Press enter to keep the current choice[*], or type selection number:

O caminho da instalação para cada um é:

**1**. `/usr/lib/jvm/java-7-oracle`

**2**. `/usr/lib/jvm/java-6-openjdk-amd64`

**3**. `/usr/lib/jvm/java-7-oracle`

Copie o caminho da sua instalação preferida e então edite o arquivo `/etc/environment`:

    sudo nano /etc/environment

Nesse arquivo, adicione a seguinte linha (substituindo SEU\_CAMINHO pelo caminho copiado):

JAVA\_HOME=“SEU\_CAMINHO”

Isto deve ser suficiente para definir a variável de ambiente. Agora recarregue este arquivo:

    source /etc/environment

Faça um teste executando:

    echo $JAVA_HOME

Se retornar o caminho que você acabou de configurar, a variável de ambiente foi configurada com sucesso. Se não retornar, por favor certifique-se de ter seguido todos os passos corretamente.

Enviado por: Koen Vlaswinkel
