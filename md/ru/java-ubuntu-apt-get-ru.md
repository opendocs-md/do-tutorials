---
author: Koen Vlaswinkel
date: 2014-11-24
language: ru
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/java-ubuntu-apt-get-ru
---

# Как установить Java в Ubuntu с помощью Apt-Get

### Введение

Множество других статей и программ требует установленной Java. В этой статье мы осветим процесс установки и управления различными версиями Java.

## Установка JRE/JDK в конфигурации по-умолчанию

Это рекомендуемый и наиболее простой вариант. В Ubuntu 12.04 и более ранних версиях Ubuntu будет установлен OpenJDK 6. В Ubuntu 12.10 и более поздних версиях Ubuntu будет установлен OpenJDK 7.

Установка Java с помощью `apt-get` очень проста. Сначала обновим список пакетов:

    sudo apt-get update

Затем проверим, не установлена ли уже Java:

    java -version

Если в результате выполнения этой команды возвращается результат “The program java can be found in the following packages”, Java еще не установлена, поэтому далее выполним команду:

    sudo apt-get install default-jre

В результате выполнения этой команды будет установлена Java Runtime Environment (JRE). Если вместо этого вам необходим Java Development Kit (JDK), который обычно требуется для компиляции Java-приложений (например, [Apache Ant](http://ant.apache.org/), [Apache Maven](http://maven.apache.org/), [Eclipse](https://www.eclipse.org/) and [IntelliJ IDEA](http://www.jetbrains.com/idea/)) выполните следующую команду:

    sudo apt-get install default-jdk

Вот и все, что нужно сделать для того, чтобы установить Java.

Все последующие шаги являются необязательными и должны осуществляться только тогда, когда это действительно необходимо.

## Установка OpenJDK 7 (опционально)

Для установки OpenJDK 7, выполните следующую команду:

    sudo apt-get install openjdk-7-jre

В результате выполнения этой команды будет установлена Java Runtime Environment (JRE). Если вместо этого вам необходим Java Development Kit (JDK), выполните следующую команду:

    sudo apt-get install openjdk-7-jdk

## Установка Oracle JDK (опционально)

Oracle JDK является официальным JDK. Тем не менее, с некоторых пор компания Oracle не поддерживает его в качестве варианта для установки по-умолчанию в Ubuntu.

Тем не менее, вы можете установить его с помощью apt-get. Для установки любой версии сперва выполните следующие команды:

    sudo apt-get install python-software-properties
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update

Далее, в зависимости от того, какую конкретно версию вы хотите установить, выполните одну из следующих команд:

### Oracle JDK 6

Это не самая новая версия, но она все еще используется.

    sudo apt-get install oracle-java6-installer

### Oracle JDK 7

Это последняя стабильная версия.

    sudo apt-get install oracle-java7-installer

### Oracle JDK 8

Это версия находится в состоянии developer preview, ее релиз запланирован на март 2014 года. Эта [статья о Java 8](http://www.techempower.com/blog/2013/03/26/everything-about-java-8/) поможет вам разобраться с этой версией.

    sudo apt-get install oracle-java8-installer

## Управление версиями Java (опционально)

Если на вашем сервере (Droplet) установлено несколько версий Java, можно задать, какая именно версия будет использоваться по-умолчанию. Для этого выполните команду:

    sudo update-alternatives --config java

Результатом этой команды для двух установленных версий Java будет что-то похожее на это:

    There are 2 choices for the alternative java (providing /usr/bin/java).
    
    Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 auto mode
      1 /usr/lib/jvm/java-6-openjdk-amd64/jre/bin/java 1061 manual mode
      2 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 manual mode
    
    Press enter to keep the current choice[*], or type selection number:

Вы можете выбрать номер версии Java, которая будет использоваться по-умолчанию. То же самое можно сделать для компилятора Java (`javac`):

    sudo update-alternatives --config javac

В результате выполнения этой команды будет отображет вывод, аналогичный выводу от выполнения предыдущей команды. Выбор компилятора, используемого по-умолчаню можно сделать точно так же: указав необходимую цифру. Эта же команда может использоваться и для других команд, например, `keytool`, `javadoc` и `jarsigner`.

## Установка переменной окружения “JAVA\_HOME”

Для установки переменной окружения `JAVA_HOME`, которая необходима для работы некоторых программ, прежде всего необходимо понять, куда конкретно была установлена Java:

    sudo update-alternatives --config java

В результете выполнения этой команды мы получим нечто, похожее по виду на это:

    There are 2 choices for the alternative java (providing /usr/bin/java).
    
    Selection Path Priority Status
    ------------------------------------------------------------
    * 0 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 auto mode
      1 /usr/lib/jvm/java-6-openjdk-amd64/jre/bin/java 1061 manual mode
      2 /usr/lib/jvm/java-7-oracle/jre/bin/java 1062 manual mode
    
    Press enter to keep the current choice[*], or type selection number:

Полный путь для каждой из установленных версий Java в нашем примере будет таким:

1. `/usr/lib/jvm/java-7-oracle`
2. `/usr/lib/jvm/java-6-openjdk-amd64`
3. `/usr/lib/jvm/java-7-oracle`

Скопируйте путь нужной вам версии Java и добавьте его в файл `/etc/environment`:

    sudo nano /etc/environment

В этом файле добавьте следующую строчку (заменив YOUR\_PATH на только что скопированный путь):

    JAVA_HOME="YOUR_PATH"

Это изменит переменную окружения. Теперь перезагрузим этот файл:

    source /etc/environment

Проверим результат выполнив команду:

    echo $JAVA_HOME

Если в результате будет отображен заданный вами путь установки нужной вам версии Java, то переменная окружения была задана успешно. Если нет, пожалуйста, убедитесь, что вы в точности следовали всем предшествующим шагам.
