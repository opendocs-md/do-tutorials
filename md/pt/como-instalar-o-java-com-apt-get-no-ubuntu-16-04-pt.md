---
author: Koen Vlaswinkel
date: 2016-12-12
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-java-com-apt-get-no-ubuntu-16-04-pt
---

# Como Instalar o Java com Apt-Get no Ubuntu 16.04

### Introdução

Java e o **JVM** (Máquina Virtual do Java) são largamente utilizados e requeridos para muitos tipos de software. Esse artigo irá guiá-lo através do processo de instalação e gerenciamento de diferentes versões de Java utilizando `apt-get`.

## Pré-requisitos

Para seguir esse tutorial você vai precisar de:

- Um servidor Ubuntu 16.04.

- Um usuário sudo que não seja root, que você pode configurar seguindo [o guia de configuração inicial do Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).

## Instalando o JRE/JDK padrão

A opção mais fácil de instalação do Java é utilizar a versão empacotada com o Ubuntu. Especificamente, isso irá instalar o OpenJDK 8, a versão mais recente e recomendada.

Primeiro, atualize o índice de pacotes.

    sudo apt-get update

Depois, instale o Java. Especificamente, esse comando irá instalar o Java Runtime Environment (JRE).

    sudo apt-get install default-jre

Existe uma outra instalação padrão do Java chamada de JDK (Java Development Kit). O JDK é normalmente necessário somente se você vai compilar programas em Java ou se o software que usa o Java o requerer especificamente.

O JDK contém o JRE, portanto, não há desvantagens se você instalar o JDK em vez do JRE, exceto pelo tamanho maior de arquivo.

Você pode instalar o JDK com o seguinte comando:

    sudo apt-get install default-jdk

## Instalando o Oracle JDK

Se você quiser instalar o Oracle JDK, que é a versão oficial distribuída pela Oracle, você vai precisar de mais alguns poucos passos.

Primeiro, adicione o PPA da Oracle, depois atualize seu repositório de pacotes.

    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update

Então, dependendo da versão que você quer instalar, execute um dos seguintes comandos:

### Oracle JDK 8

Essa é a última versão estável do Java no momento da escrita, e é a versão recomendada para instalar. Você pode fazer isso utilizando o seguinte comando:

    sudo apt-get install oracle-java8-installer

### Oracle JDK 9

Esse é o preview para desenvolvedor e a vresão geral está programada para Março de 2017. Não é recomendado que você utilize essa versão porque podem existir problemas de segurança e bugs. Existe mais informação sobre o Java 9 no [Site oficial do JDK 9](http://jdk.java.net/9/).

Para instalar o JDK 9, use o seguinte comando:

    sudo apt-get install oracle-java9-installer

## Gerenciando o Java

Podem haver múltiplas versões do Java em um servidor. Você pode configurar qual versão é a padrão para uso na linha de comando através do uso do `update-alternatives`, que gerencia quais links simbólicos são usados por diferentes comandos.

    sudo update-alternatives --config java

A saída será parecida com o seguinte. Nesse caso, isso é como a saída se parecerá com todas as versões de Java mencionadas acima instaladas.

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

Você pode escolher o número para ser usado como padrão. Isso também pode ser feito para outros comandos do Java, como o compilador (`javac`), o gerador de documentação (`javadoc`), a ferramenta de assinatura JAR (`jarsigner`), e mais. Você pode utilizar o seguinte comando, completando com o comando que você quer customizar.

    sudo update-alternatives --config command

## Configurando a variável de ambiente JAVA\_HOME

Muitos programas, como os servidores Java, utilizam a variável de ambiente `JAVA_HOME` para determinar a localização da instalação do Java. Para configurar essa variável, precisamos saber primeiro onde o Java está instalado. Você pode fazer isso executando o seguinte comando como na sessão anterior:

    sudo update-alternatives --config java

Copie o caminho da sua instalação preferencial e abra o arquivo `/etc/environment` utilizando o `nano` ou o seu editor de texto favorito.

    sudo nano /etc/environment

Ao final desse arquivo, adicione a seguinte linha, certificando-se de trocar o caminho destacado pelo seu caminho copiado.

/etc/environment

    JAVA_HOME="/usr/lib/jvm/java-8-oracle"

Salve e saia do arquivo, e recarregue-o.

    source /etc/environment

Agora você pode testar se a variável de ambiente foi configurada executando o seguinte comando:

    echo $JAVA_HOME

Isso irá retornar o caminho que você configurou.

## Conclusão

Agora você instalou o Java e sabe como gerenciar diferentes versões dele. Você pode agora instalar software que roda sob o Java, como o Tomcat, Jetty, Glassfish, Cassandra, ou Jenkins.
