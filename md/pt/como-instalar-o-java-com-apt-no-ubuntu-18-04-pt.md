---
author: Koen Vlaswinkel
date: 2019-05-16
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-java-com-apt-no-ubuntu-18-04-pt
---

# Como Instalar o Java com `apt` no Ubuntu 18.04

_O autor selecionou o [Open Internet/Free Speech Fund](https://www.brightfunds.org/funds/open-internet-free-speech) para receber uma doação de $100 como parte do programa [Escreva para DOações](https://do.co/w4do-cta)._

### Introdução

Java e a JVM (Java’s virtual machine) são necessários para utilizar vários tipos de software, incluindo o [Tomcat](http://tomcat.apache.org/), [Jetty](https://www.eclipse.org/jetty/), [Glassfish](https://javaee.github.io/glassfish/), [Cassandra](http://cassandra.apache.org/) e [Jenkins](https://jenkins.io/).

Neste guia, você irá instalar várias versões do Java Runtime Environment (JRE) e do Java Developer Kit (JDK) utilizando o **`apt`**. Você irá instalar o OpenJDK e também os pacotes oficiais da Oracle. Em seguida, você irá selecionar a versão que você deseja utilizar em seus projetos. Quando você finalizar o guia, você será capaz de utilizar o JDK para desenvolver seus programas ou utilizar o Java Runtime para rodar seus programas.

## Pré-requisitos

Para seguir ester tutorial, você precisará de:

- Um servidor Ubuntu 18.04, configurado seguindo o tutorial [Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt), incluindo um usuário não root e um firewall.

## Instalando o JRE/JDK Padrão

A opção mais fácil para instalar o Java é utilizando o pacote que vem com o Ubuntu. Por padrão, o Ubuntu 18.04 inclui o OpenJDK, que é a alternativa open-source do JRE e JDK.

Esse pacote irá instalar ou o OpenJDK 10 ou o 11.

- Antes de Setembro de 2018, ele irá instalar o OpenJDK 10.
- Depois de Setembro de 2018, ele irá instalar o OpenJDK 11.

Para instalar essa versão, primeiro precisamos atualizar a lista de pacotes do apt:

    sudo apt update

Depois, checar se o Java já está instalado:

    java -version

Se o Java não estiver instalado, você verá a seguinte mensagem:

    OutputCommand 'java' not found, but can be installed with:
    
    apt install default-jre            
    apt install openjdk-11-jre-headless
    apt install openjdk-8-jre-headless 

Execute o seguinte comando para instalar o OpenJDK:

    sudo apt install default-jre

Esse comando irá instalar o Java Runtime Environment (JRE). Isso vai permitir que você execute praticamente todos os programas em Java.

Verifique a instalação com:

    java -version

Você verá a seguinte mensagem:

    Outputopenjdk version "10.0.2" 2018-07-17
    OpenJDK Runtime Environment (build 10.0.2+13-Ubuntu-1ubuntu0.18.04.4)
    OpenJDK 64-Bit Server VM (build 10.0.2+13-Ubuntu-1ubuntu0.18.04.4, mixed mode)

Você talvez precise do Java Development Kit (JDK) junto do JRE para poder compilar e rodar algum programa específico em Java. Para instalar o JDK, execute os seguintes comandos, que também irão instalar o JRE:

    sudo apt install default-jdk

Verifique se o JDK foi instalado checando a versão do `javac`, o compilador Java:

    javac -version

Você verá a seguinte mensagem:

    Outputjavac 10.0.2

A seguir, veremos como especificar uma versão do OpenJDK que nós queremos instalar.

## Instalando uma versão especifica do OpenJDK

### OpenJDK 8

Java 8 é a versão Long Term Support (Suporte de longo prazo) atual e ainda é amplamente suportada, apesar da manutenção pública terminar em Janeiro de 2019. Para instalar o OpenJDK 8, execute o seguinte comando:

    sudo apt install openjdk-8-jdk

Verifique se foi instalado com:

    java -version

Você verá a seguinte mensagem:

    Output
    openjdk version "1.8.0_191"
    OpenJDK Runtime Environment (build 1.8.0_191-8u191-b12-2ubuntu0.18.04.1-b12)
    OpenJDK 64-Bit Server VM (build 25.191-b12, mixed mode)
    

Também é possível instalar somente o JRE, o que você pode fazer executando o seguinte comando `sudo apt install openjdk-8-jre`.

### OpenJDK 10/11

Os repositórios do Ubuntu possuem os pacotes que instalarão o Java 10 ou o 11. Até Setembro de 2018, esse pacote irá instalar o OpenJDK 10. Assim que o Java 11 for lançado, esse pacote instalará o Java 11.

Para instalar o OpenJDK 10/10, execute o seguinte comando:

    sudo apt install openjdk-11-jdk

Para instalar somente o JRE, use o seguinte comando:

    sudo apt install openjdk-11-jre

A seguir, vamos ver como instalar o JDK e o JRE oficiais da Oracle.

### Instalando o Oracle JDK

Se quiser instalar o Oracle JDK, que é a versão oficial distribuída pela Oracle, você precisará adicionar um novo repositório de pacotes para a versão que você gostaria de instalar.

Para instalar o Java 8, que é a última versão LTS, primeiramente adicione o repositório do pacote:

    sudo add-apt-repository ppa:webupd8team/java

Quando você adicionar o repositório, você verá uma mensagem parecida com essa:

    output Oracle Java (JDK) Installer (automatically downloads and installs Oracle JDK8). There are no actual Java files in this PPA.
    
    Important -> Why Oracle Java 7 And 6 Installers No Longer Work: http://www.webupd8.org/2017/06/why-oracle-java-7-and-6-installers-no.html
    
    Update: Oracle Java 9 has reached end of life: http://www.oracle.com/technetwork/java/javase/downloads/jdk9-downloads-3848520.html
    
    The PPA supports Ubuntu 18.10, 18.04, 16.04, 14.04 and 12.04.
    
    More info (and Ubuntu installation instructions):
    - http://www.webupd8.org/2012/09/install-oracle-java-8-in-ubuntu-via-ppa.html
    
    Debian installation instructions:
    - Oracle Java 8: http://www.webupd8.org/2014/03/how-to-install-oracle-java-8-in-debian.html
    
    For Oracle Java 11, see a different PPA -> https://www.linuxuprising.com/2018/10/how-to-install-oracle-java-11-in-ubuntu.html
     More info: https://launchpad.net/~webupd8team/+archive/ubuntu/java
    Press [ENTER] to continue or Ctrl-c to cancel adding it.

Pressione `ENTER` para continuar. Depois atualize sua lista de pacotes:

    sudo apt update

Quando a lista de pacotes atualizar, instale o Java 8:

    sudo apt install oracle-java8-installer

Seu sistema irá realizar o download do JDK da Oracle e irá solicitar que você aceite os termos de licença. Aceite os termos e o JDK será instalado.

Agora vamos ver como selecionar qual versão do Java você deseja utilizar.

## Gerenciando o Java

Você pode ter múltiplas instalações do Java em um servidor. Você pode configurar qual versão será utilizada por padrão no terminal, usando o comando `update-alternatives`.

    sudo update-alternatives --config java

Será assim que a saída vai parecer se você instalou todas as versões de Java desse tutorial:

    OutputThere are 3 choices for the alternative java (providing /usr/bin/java).
    
      Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1101 auto mode
      1 /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1101 manual mode
      2 /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 1081 manual mode
      3 /usr/lib/jvm/java-8-oracle/jre/bin/java 1081 manual mode
    

Escolha o número que está associado com a versão do Java que será utilizada como padrão, ou pressione `ENTER` para deixar a configuração atual no lugar.

Você pode usar isso para outros comandos Java, como o compilador (`javac`):

    sudo update-alternatives --config javac

Outros comandos para os quais esse comando pode ser utilizado incluem, mas não ficam limitados a: `keytool`, `javadoc` e `jarsigner`.

## Configurando a Variavel de Ambiente `JAVA_HOME`

Muitos programas escritos em Java, utilizam a variável de ambiente `JAVA_HOME` para determinar o local de instalação do Java.

Para configurar esta variável de ambiente, primeiramente defina onde o Java está instalado. Utilize o comando `update-alternatives`:

    sudo update-alternatives --config java

Esse comando mostra cada instalação do Java junto com seu caminho de instalação:

    OutputThere are 3 choices for the alternative java (providing /usr/bin/java).
    
      Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1101 auto mode
      1 /usr/lib/jvm/java-11-openjdk-amd64/bin/java 1101 manual mode
      2 /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java 1081 manual mode
      3 /usr/lib/jvm/java-8-oracle/jre/bin/java 1081 manual mode
    Press <enter> to keep the current choice[*], or type selection number:

Nesse caso, os caminhos de instalação são os seguintes:

1. OpenJDK 11 está localizado em `/usr/lib/jvm/java-11-openjdk-amd64/bin/java`.
2. OpenJDK 8 está localizado em `/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java`.
3. Oracle Java 8 está localizado em `/usr/lib/jvm/java-8-oracle/jre/bin/java`.

Copie o caminho da instalação que você deseja utilizar. Depois abra `/etc/environment` utilizando o `nano` ou o seu editor de texto favorito:

    sudo nano /etc/environment

No final desse arquivo, adicione a seguinte linha, certificando-se de substituir o caminho destacado com o que você copiou do seu sistema:

/etc/environment

    JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64/bin/"

Ao modificar esse arquivo você irá configurar o caminho `JAVA_HOME` para todos os usuários do seu sistema.

Salve o arquivo e saia do editor de texto.

Agora recarregue arquivo para aplicar as mudanças para sua sessão atual:

    source /etc/environment

Verifique se a sua variável de ambiente foi configurada:

    echo $JAVA_HOME

Você verá o caminho que você acabou de configurar:

    Output/usr/lib/jvm/java-11-openjdk-amd64/bin/

Os outros usuários precisaram executar o comando `source /etc/environment` ou desconectar e logar novamente para aplicar essa configuração.

## Conclusão

Nesse tutorial você instalou múltiplas versões do Java e aprendeu como gerenciá-las. Você agora pode instalar os programas que rodam em Java, tais como o Tomcat, Jetty, Glassfish, Cassandra ou Jenkins.
