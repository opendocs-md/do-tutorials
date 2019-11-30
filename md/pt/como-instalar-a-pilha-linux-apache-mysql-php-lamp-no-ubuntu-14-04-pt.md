---
author: Justin Ellingwood
date: 2014-12-03
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-a-pilha-linux-apache-mysql-php-lamp-no-ubuntu-14-04-pt
---

# Como instalar a pilha Linux, Apache, MySQL, PHP (LAMP) no Ubuntu 14.04

### Introdução

A pilha “LAMP” é um grupo de softwares open source que é tipicamente instalado em conjunto para permitir um servidor hospedar websites dinâmicos e aplicações web. Este termo é atualmente um acrônimo que representa o sistema operacional **L** inux, com o servidor web **A** pache. A informação do site é armazenada em uma base de dados **M** ySQL, e o conteúdo dinâmico é processado pelo **P** HP.

Neste guia, nós vamos ter uma pilha LAMP instalada em um Droplet Ubuntu 14.04. O Ubuntu preencherá nosso primeiro requisito: Um sistema operacional Linux.

## Pré-requisitos

Antes de você iniciar com este guia, você deve ter uma conta separada, que não seja root, configurada em seu servidor. Você pode aprender como fazer isto completando os passos 1-4 na configuração inicial do servidor para Ubuntu 14.04.

## Passo um - Instalar o Apache

O servidor web Apache é atualmente o servidor web mais popular no mundo, o que faz dele uma ótima escolha padrão para hospedar um website.

Podemos instalar o Apache facilmente utilizando o gerenciador de pacotes do Ubuntu, `apt`. Um gerenciador de pacotes nos permite instalar a maioria dos softwares a partir de um repositório mantido pelo Ubuntu, sem traumas. Você pode aprender mais sobre [como utilizar o `apt`](https://www.digitalocean.com/community/articles/how-to-manage-packages-in-ubuntu-and-debian-with-apt-get-apt-cache) aqui.

Para nossos propósitos, podemos começar digitando os seguintes comandos:

    sudo apt-get update
    sudo apt-get install apache2

Como estamos utilizando um comando `sudo`, essas operações são executadas com privilégios de root. Ele irá pedir a senha regular do usuário para verificar suas intenções.

Após isso, seu servidor web está instalado.

Você pode fazer uma verificação local imediatamente para verificar se tudo correu conforme planejado visitando o endereço IP público do seu servidor no seu navegador (veja a nota na seção seguinte pra ver qual é o seu endereço IP se você já não tiver esta informação):

\<pre\>  
http://endereço_IP_do_seu_servidor  
\</pre\>

Você verá a página web padrão do Apache no Ubuntu 14.04, que está lá para propósitos de informação e testes. Deve ser algo parecido com isto:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lamp_1404/default_apache.png)

Se você vir esta página, então seu servidor web está corretamente instalado agora.

## Como encontrar o endereço IP público do seu servidor

Se você não sabe qual é o endereço IP público do seu servidor, existem várias maneiras de encontrá-lo. Normalmente, este é o endereço que você utiliza para se conectar através do SSH.

A partir da linha de comando, você pode encontrar o IP de algumas formas. Primeiro, você pode utilizar as ferramentas iproute2 para obter seu endereço digitando o seguinte:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Isto lhe retornará uma ou duas linhas. Ambas são endereços corretos, mas o seu computador poderá utilizar apenas um deles, então sinta-se à vontade para experimentar cada um.

Um método alternativo é utilizar um provedor externo para lhe dizer como ele vê seu servidor. Você pode fazer isto perguntando a um servidor específico qual é o seu endereço IP público:

    curl http://icanhazip.com

Independentemente do método que você utiliza para obter seu endereço IP, você pode digitá-lo na barra de endereços do seu navegador para chegar ao seu servidor.

## Passo dois - Instalar o MySQL

Agora que temos nosso servidor web pronto e funcionando, é hora de instalar o MySQL. O MySQL é um sistema de gerenciamento de bancos de dados. Basicamente, ele irá organizar e proporcionar acesso a bases de dados onde nosso site pode armazenar informação.

Novamente, podemos utilizar o `apt` para obter e instalar nosso software. Desta vez, vamos também instalar alguns pacotes “auxiliares” que irão nos ajudar a obter nossos componentes para comunicarem uns com os outros:

    sudo apt-get install mysql-server php5-mysql

**Observação** : Neste caso, você não tem que executar `sudo apt-get update` antes do comando. Isso é porque o executamos recentemente através dos comandos acima para instalar o Apache. O índice de pacotes em nosso computador já deve estar atualizado.

Durante a instalação, seu servidor vai pedir para você selecionar e confirmar uma senha para o usuário “root” do MySQL. Esta é uma conta administrativa no MySQL que possui privilégios avançados. Pense nela como sendo similar à conta de root para o próprio servidor (no entanto, esta que você está configurando agora é uma conta específica do MySQL).

Quando a instalação estiver concluída, precisaremos executar alguns comandos adicionais para ter nosso ambiente MySQL configurado de forma segura.

Primeiro, precisamos dizer ao MySQL para criar sua estrutura de diretório de banco de dados, onde ele irá armazenar suas informações. Você pode fazer isto digitando:

    sudo mysql_install_db

Depois, queremos executar um script simples de segurança que vai remover alguns padrões perigosos e bloquear um pouco o acesso ao nosso sistema de banco de dados. Inicie o script interativo executando:

    sudo mysql_secure_installation

Você será solicitado a digitar a senha que você definiu para a conta root do MySQL. Em seguida, ele irá perguntar se você deseja alterar esta senha. Se você estiver satisfeito com sua senha atual, digite “n” para “não” no prompt.

Para as demais perguntas, você deve simplesmente apertar a telca “ENTER” em cada prompt para aceitar os valores padrão. Isto irá remover alguns usuários e bases de exemplo, desabilitar logins remotos de root, e carregar estas novas regras para que o MySQL aplique imediatamente as alterações que fizemos.

Neste ponto, seu sistema de banco de dados está agora configurado e podemos avançar.

## Passo três - Instalar o PHP

O PHP é o componente da nossa configuração que irá processar código para exibir o conteúdo dinâmico. Ele pode executar script, conectar às nossas bases de dados MySQL para obter informações, e entregar o conteúdo processado para o nosso servidor web exibir.

Podemos aproveitar mais uma vez o sistema `apt` para instalar nossos componentes. Vamos incluir alguns pacotes auxiliares também.

    sudo apt-get install php5 libapache2-mod-php5 php5-mcrypt

Isto irá instalar o PHP sem problemas. Vamos testar isso em instantes.

Na maioria do casos, vamos querer modificar a forma que o Apache serve arquivos quando uma pasta é requisitada. Atualmente, se um usuário requisita uma pasta do servidor, o Apache irá olhar primeiramente para um arquivo chamado `index.html`. Queremos informar ao nosso servidor web para dar preferência aos arquivos PHP, então faremos o Apache olhar para um arquivo `index.php` primeiro.

Para fazer isto, digite este comando para abrir o arquivo `dir.inf` em um editor de texto com privilégios de root:

    sudo nano /etc/apache2/mods-enabled/dir.conf

Ele terá esta aparência:

    <IfModule mod_dir.c>
        DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm
    </IfModule>

Queremos mover o arquivo de índice PHP em destaque acima para a primeira posição depois da especificação `DirectoryIndex` , como segue:

    <IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
    </IfModule>

Quando você tiver concluído, salve e feche o arquivo pressionando “CTRL-X”. Você tem que confirmar a gravação digitando “Y” e em seguida pressione “ENTER” para confirmar a localização de salvamento do arquivo.

Após isso, precisamos reiniciar o servidor web Apache de forma que nossas alterações sejam reconhecidas. Você pode fazer isto digitando o seguinte:

    sudo service apache2 restart

## Instalar módulos PHP

Para melhorar a funcionalidade do PHP, podemos opcionalmente instalar alguns módulos adicionais.

Para ver as opções disponíveis para módulos e bibliotecas PHP, você pode digitar isto em seu sistema:

    apt-cache search php5-

O resultado são todos os componentes opcionais que você pode instalar. Ele lhe dará uma breve descrição de cada um:

    php5-cgi - server-side, HTML-embedded scripting language (CGI binary)
    php5-cli - command-line interpreter for the php5 scripting language
    php5-common - Common files for packages built from the php5 source
    php5-curl - CURL module for php5
    php5-dbg - Debug symbols for PHP5
    php5-dev - Files for PHP5 module development
    php5-gd - GD module for php5
    . . .

Para obter mais informações sobre o que cada módulo faz, você pode buscar na Internet, ou olhar a descrição longa do pacote digitando:

    apt-cache show package_name

Haverá uma grande quantidade de saída, com um campo chamado `Description-en` que terá uma explicação mais longa da funcionalidade que o módulo oferece.

Por exemplo, para encontrar o que o módulo php5-cli faz, podemos digitar isto:

    apt-cache show php5-cli

Juntamente com várias outras informações, você vai encontrar algo parecido com isto:

    . . .
    SHA256: 91cfdbda65df65c9a4a5bd3478d6e7d3e92c53efcddf3436bbe9bbe27eca409d
    Description-en: command-line interpreter for the php5 scripting language
     This package provides the /usr/bin/php5 command interpreter, useful for
     testing PHP scripts from a shell or performing general shell scripting tasks.
     .
     The following extensions are built in: bcmath bz2 calendar Core ctype date
     dba dom ereg exif fileinfo filter ftp gettext hash iconv libxml mbstring
     mhash openssl pcntl pcre Phar posix Reflection session shmop SimpleXML soap
     sockets SPL standard sysvmsg sysvsem sysvshm tokenizer wddx xml xmlreader
     xmlwriter zip zlib.
     .
     PHP (recursive acronym for PHP: Hypertext Preprocessor) is a widely-used
     open source general-purpose scripting language that is especially suited
     for web development and can be embedded into HTML.
    Description-md5: f8450d3b28653dcf1a4615f3b1d4e347
    Homepage: http://www.php.net/
    . . .

Se, após pesquisar, você decidir que gostaria de instalar um pacote, você pode fazê-lo utilizando o comando `apt-get install` assim como fizemos para nossos outros softwares.

Se decidirmos que o php5-cli é algo que precisamos, podemos digitar:

    sudo apt-get install php5-cli

Se você quiser instalar mais de um módulo, você pode fazer isso listando cada um, separado por um espaço, seguindo o comando `apt-get`, como abaixo:

    sudo apt-get install package1 package2 ...

Nesse ponto, sua pilha LAMP está instalada e configurada. Devemos ainda testar o nosso PHP.

## Passo quatro — Testar o processamento PHP no seu servidor web

A fim de testar se nosso sistema está corretamente configurado para o PHP, podemos criar um script bem básico.

Vamos chamar este script de `info.php`. Para que o Apache possa encontrar o arquivo e servi-lo corretamente, ele deve ser salvo em um diretório muito específico, o qual é chamado de “web root”.

No Ubuntu 14.04, este diretório está localizado em /var/www/html. Podemos criar o arquivo neste local digitando:

    sudo nano /var/www/html/info.php

Isto vai abrir um arquivo em branco. Queremos colocar o texto a seguir, que é um código PHP válido, dentro do arquivo:

    <?php
    phpinfo();
    ?>

Quando você tiver concluído, salve e feche o arquivo.

Agora podemos testar se nosso servidor web pode exibir corretamente o conteúdo gerado por um script PHP. Para testar isso, temos apenas que visitar esta página em nosso navegador. Você vai precisar novamente do endereço IP público do seu servidor.

O endereço que você quer visitar será:

    http://your_server_IP_address/info.php

A página que você deve ver deve se parecer com isto:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/lamp_1404/default_php.png)

Esta página basicamente fornece a você informações sobre seu servidor a partir da perspectiva do PHP. Ela é útil para depuração e para assegurar que suas configurações estão sendo corretamente aplicadas.

Se tiver êxito, então seu PHP está funcionando como esperado.

Você provavelmente vai querer remover este arquivo depois do teste, pois ele realmente pode fornecer informações sobre seu servidor para usuários não autorizados. Para fazer isto, você pode digitar o seguinte:

    sudo rm /var/www/html/info.php

Você sempre poderá recriar esta página se precisar acessar novamente as informações mais tarde.

## Conclusão

Agora que você tem uma pilha LAMP instalada, você terá muitas opções para o que fazer em seguida. Basicamente, você instalou uma plataforma que lhe permitirá instalar a maioria dos tipos de websites e softwares web em seu servidor.

Algumas opções populares são:

- [Instalar o Wordpress](https://www.digitalocean.com/community/articles/how-to-install-wordpress-on-ubuntu-12-04) o sistema gerenciador de conteúdo mais popular da Internet
- [Configurar o PHPMyAdmin](https://www.digitalocean.com/community/articles/how-to-install-and-secure-phpmyadmin-on-ubuntu-12-04) para ajudá-lo a gerenciar seu banco de dados MySQL a partir de um navegador.
- [Aprenda mais sobre o MySQL](https://www.digitalocean.com/community/articles/a-basic-mysql-tutorial) para gerenciar suas bases de dados.
- [Aprenda a criar um certificado SSL](https://www.digitalocean.com/community/articles/how-to-create-a-ssl-certificate-on-apache-for-ubuntu-12-04) para proteger o tráfego para o seu servidor web.
- [Aprenda a utilizar o SFTP](https://www.digitalocean.com/community/articles/how-to-use-sftp-to-securely-transfer-files-with-a-remote-server) para transferir arquivos de e para o seu servidor.

**Observação:** Estaremos atualizando os links acima para nossa documentação 14,04, conforme está escrito.

Por Justin Ellingwoo
