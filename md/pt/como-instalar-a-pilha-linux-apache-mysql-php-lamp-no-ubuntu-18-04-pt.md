---
author: Mark Drake
date: 2018-05-09
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-a-pilha-linux-apache-mysql-php-lamp-no-ubuntu-18-04-pt
---

# Como instalar a pilha Linux, Apache, MySQL, PHP (LAMP) no Ubuntu 18.04

### Introdução

A pilha “LAMP” é um grupo de softwares open source que é tipicamente instalado em conjunto para permitir a um servidor hospedar websites dinâmicos e aplicações web. Este termo é atualmente um acrônimo que representa o sistema operacional **L** inux, com o servidor web **A** pache. A informação do site é armazenada em uma base de dados **M** ySQL, e o conteúdo dinâmico é processado pelo **P** HP.

Neste guia, vamos instalar uma pilha LAMP em um servidor Ubuntu 18.04.

## Pré-requisitos

Para completar esse tutorial, você vai precisar ter um servidor Ubuntu 18.04 com uma conta de usuário que não seja root, com privilégios `sudo` configurada e um firewall básico. Isso poe ser configurado utilizando nosso guia de [Configuração Inicial de servidor com Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04).

## Passo 1 — Instalação do Apache e Atualização do Firewall

O servidor web Apache está entre os servidores web mais populares do mundo. É bem documentado, e tem sido amplamente utilizado em grande parte da história da web, o que faz dele uma ótima escolha padrão para hospedar um website.

Instale o Apache utilizando o gerenciador de pacotes do Ubuntu, `apt`:

    sudo apt update
    sudo apt install apache2

Como estamos utilizando um comando `sudo`, essas operações são executadas com privilégios de root. Ele irá pedir a senha do usuário comum para verificar suas intenções.

Uma vez que você tenha digitado sua senha, o `apt` irá lhe dizer quais pacotes ele planeja instalar e quanto de espaço extra em disco ele irá consumir. Pressione `Y` e aperte `Enter` para continuar, e a instalação prosseguirá.

### Ajustar o Firewall para Permitir Tráfego Web

Agora, assumindo que você seguiu as instruções de configuração inicial do servidor para habilitar o firewall UFW, certifique-se de que seu firewall permite tráfego HTTP e HTTPS. Você pode certificar-se de que o UFW tem um perfil de aplicativo para o Apache assim:

    sudo ufw app list

    OutputAvailable applications:
      Apache
      Apache Full
      Apache Secure
      OpenSSH

Se você olhar para o perfil `Apache Full`, ele deve mostrar que ele habilita tráfego para as portas `80` e `443`:

    sudo ufw app info "Apache Full"

    OutputProfile: Apache Full
    Title: Web Server (HTTP,HTTPS)
    Description: Apache v2 is the next generation of the omnipresent Apache web
    server.
    
    Ports:
      80,443/tcp

Permita o tráfego entrante HTTP e HTTPS para esse perfil:

    sudo ufw allow in "Apache Full"

Você pode fazer uma verificação imediata para verificar se tudo correu como planejado visitando o endereço IP público do seu servidor no seu navegador web (Veja a nota abaixo do próximo cabeçalho para descobrir qual é o seu endereço IP público se você ainda não tiver essa informação):

    http://ip_do_seu_servidor

Você verá a página web padrão do Ubuntu 18.04, que está lá para fins de teste e informação. Ela deve ser algo assim:

![](http://assets.digitalocean.com/articles/how-to-install-lamp-ubuntu-18/small_apache_default_1804.png)

Se você ver esta página, então seu servidor web agora está corretamente instalado e acessível através do seu firewall.

### Como Encontrar o Endereço IP Público do seu Servidor

Se você não sabe qual é o endereço IP público do seu servidor, há uma série de maneiras pelas quais você pode encontrá-lo. Geralmente, esse é o endereço que você utiliza para se conectar ao seu servidor através do SSH.

A partir da linha de comando, você pode encontrar isso de algumas maneiras. Primeiro, você pode utilizar as ferramentas `iproute2` para obter seu endereço digitando isso:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Esse comando vai lhe retornar duas ou três linhas. Todos são endereços corretos, mas seu computador só poderá utilizar um deles, portanto, sinta-se livre para tentar cada um.

Um método alternativo é usar o utilitário `curl` para entrar em contato com algum meio externo para lhe dizer como ele vê o seu servidor. Você pode fazer isso perguntando a um servidor específico qual é o seu IP:

    sudo apt install curl
    curl http://icanhazip.com

Independentemente do método que você usa para obter seu endereço IP, digite-o na barra de endereço do seu navegador web para ver a página padrão do Apache.

## Passo 2 — Instalação do MySQL

Agora que temos nosso servidor web pronto e funcionando, é hora de instalar o MySQL. O MySQL é um sistema de gerenciamento de bancos de dados. Basicamente, ele irá organizar e fornecer acesso às bases de dados onde nosso site pode armazenar informação.

Novamente, utilize o `apt` para obter e instalar este software:

    sudo apt install mysql-server

**Nota** : Neste caso, você não tem que executar `sudo apt update` antes do comando. Isso é porque o executamos recentemente através dos comandos acima para instalar o Apache. O índice de pacotes em nosso computador já deve estar atualizado.

Novamente, será mostrada uma lista dos pacotes que serão instalados, juntamente com a quantidade de espaço em disco que irão ocupar. Digite `Y` para continuar.

Quando a instalação estiver concluída, execute um script de segurança simples que vem pré-instalado com o MySQL e que irá remover alguns padrões perigosos e bloquear o acesso ao seu sistema de banco de dados. Inicie o script interativo executando:

    sudo mysql_secure_installation

Você será perguntado se você quer configurar o `VALIDATE PASSWORD PLUGIN`.

**Nota** : A habilitação dessa funcionalidade é algo que deve ser avaliado. Se habilitado, senhas que não seguem o critério especificado serão rejeitadas pelo MySQL com um erro. Isso irá causar problemas se você utilizar uma senha fraca juntamente com software que configura automaticamente as credenciais de usuário do MySQL, tais como os pacotes do Ubuntu para o phpMyAdmin. É seguro deixar a validação desativada, mas você deve sempre utilizar senhas fortes e exclusivas para as credenciais do banco de dados.

Responda `Y` para Sim, ou qualquer outra coisa para continuar sem a habilitação.

    VALIDATE PASSWORD PLUGIN can be used to test passwords
    and improve security. It checks the strength of password
    and allows the users to set only those passwords which are
    secure enough. Would you like to setup VALIDATE PASSWORD plugin?
    
    Press y|Y for Yes, any other key for No:

Se você responder “yes”, você será solicitado a selecionar um nível de validação de senha. Tenha em mente que se você digitar `2`, para o nível mais forte, você receberá erros quando tentar configurar qualquer senha que não contenha números, letras maiúsculas e minúsculas, e caracteres especiais, ou que seja baseada em palavras comuns do dicionário.

    There are three levels of password validation policy:
    
    LOW Length >= 8
    MEDIUM Length >= 8, numeric, mixed case, and special characters
    STRONG Length >= 8, numeric, mixed case, special characters and dictionary file
    
    Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG: 1

Independentemente de você escolher configurar o `VALIDATE PASSWORD PLUGIN`, seu servidor em seguida irá solicitar que você selecione e confirme a senha para o usuário root do MySQL. Esta é uma conta administrativa no MySQL que possui privilégios avançados. Pense nela como sendo similar à conta de root para o próprio servidor (embora esta que você está configurando agora é uma conta específica do MySQL). Certifique-se de que esta é uma senha forte e exclusiva, e não a deixe em branco.

Se você habilitou a validação de senha, será mostrado a força da senha de root atual, e será perguntado se você quer alterar aquela senha. Se você estiver satisfeito com sua senha atual, digite N para “não” no prompt:

    Using existing password for root.
    
    Estimated strength of the password: 100
    Change the password for root ? ((Press y|Y for Yes, any other key for No) : n

Para o restante das perguntas, pressione `Y` e aperte a tecla `Enter` para cada prompt. Isso irá remover alguns usuários anônimos e o banco de dados de teste, desabilitar logins remotos de root, e carregar essas novas regras de forma que o MySQL respeite imediatamente as alterações que fizemos.

Nesse ponto, seu sistema de banco de dados está agora configurado e podemos seguir em frente para a instalação do PHP, o componente final da pilha LAMP.

## Passo 3 — Instalação do PHP

O PHP é o componente da nossa configuração que irá processar código para exibir o conteúdo dinâmico. Ele pode executar script, conectar às nossas bases de dados MySQL para obter informações, e entregar o conteúdo processado para o nosso servidor web exibir.

Uma vez mais, aproveite o sistema `apt` para instalar o PHP. Adicionalmente, inclua alguns pacotes auxiliares dessa vez para que o código PHP possa rodar sob o servidor Apache e falar com o seu banco de dados MySQL:

    sudo apt install php libapache2-mod-php php-mysql

Isto irá instalar o PHP sem problemas. Vamos testar isso em instantes.

Na maioria do casos, vamos querer modificar a forma com a qual o Apache serve arquivos quando uma pasta é requisitada. Atualmente, se um usuário requisita uma pasta do servidor, o Apache irá olhar primeiramente para um arquivo chamado `index.html`. Queremos informar ao nosso servidor web para dar preferência aos arquivos PHP, então faremos o Apache olhar para um arquivo `index.php` primeiro.

Para fazer isto, digite este comando para abrir o arquivo `dir.inf` em um editor de texto com privilégios de root:

    sudo nano /etc/apache2/mods-enabled/dir.conf

Ele terá esta aparência:

/etc/apache2/mods-enabled/dir.conf

    /etc/apache2/mods-enabled/dir.conf
    
    <IfModule mod_dir.c>
        DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm
    </IfModule>

Mova o arquivo de índice PHP (em destaque acima) para a primeira posição depois da especificação `DirectoryIndex` , como segue:

/etc/apache2/mods-enabled/dir.conf

    /etc/apache2/mods-enabled/dir.conf
    
    <IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
    </IfModule>

Quando você tiver concluído, salve e feche o arquivo pressionando `CTRL-X`. Confirme a gravação digitando `Y` e em seguida pressione `ENTER` para confirmar a localização de salvamento do arquivo.

Após isso, reinicie o servidor web Apache de forma que nossas alterações sejam reconhecidas. Você pode fazer isto digitando o seguinte:

    sudo systemctl restart apache2

Você pode também verificar o status do serviço `apache2` utilizando `systemctl`:

    sudo systemctl status apache2

    Sample Output● apache2.service - LSB: Apache2 web server
       Loaded: loaded (/etc/init.d/apache2; bad; vendor preset: enabled)
      Drop-In: /lib/systemd/system/apache2.service.d
               └─apache2-systemd.conf
       Active: active (running) since Tue 2018-04-23 14:28:43 EDT; 45s ago
         Docs: man:systemd-sysv-generator(8)
      Process: 13581 ExecStop=/etc/init.d/apache2 stop (code=exited, status=0/SUCCESS)
      Process: 13605 ExecStart=/etc/init.d/apache2 start (code=exited, status=0/SUCCESS)
        Tasks: 6 (limit: 512)
       CGroup: /system.slice/apache2.service
               ├─13623 /usr/sbin/apache2 -k start
               ├─13626 /usr/sbin/apache2 -k start
               ├─13627 /usr/sbin/apache2 -k start
               ├─13628 /usr/sbin/apache2 -k start
               ├─13629 /usr/sbin/apache2 -k start
               └─13630 /usr/sbin/apache2 -k start

Para melhorar a funcionalidade do PHP, você tem a opção de instalar alguns módulos adicionais. Para ver as opções disponíveis para os módulos e bibliotecas PHP, direcione os resultados do comando `apt search` para o comando `less`, um paginador que lhe permite percorrer a saída de outros comandos:

    apt search php- | less

Use as teclas de seta para rolar para cima e para baixo e `Q` para sair.

O resultado são todos os componentes opcionais que você pode instalar. Ele lhe dará uma breve descrição de cada um:

    bandwidthd-pgsql/bionic 2.0.1+cvs20090917-10ubuntu1 amd64
      Tracks usage of TCP/IP and builds html files with graphs
    
    bluefish/bionic 2.2.10-1 amd64
      advanced Gtk+ text editor for web and software development
    
    cacti/bionic 1.1.38+ds1-1 all
      web interface for graphing of monitoring systems
    
    ganglia-webfrontend/bionic 3.6.1-3 all
      cluster monitoring toolkit - web front-end
    
    golang-github-unknwon-cae-dev/bionic 0.0~git20160715.0.c6aac99-4 all
      PHP-like Compression and Archive Extensions in Go
    
    haserl/bionic 0.9.35-2 amd64
      CGI scripting program for embedded environments
    
    kdevelop-php-docs/bionic 5.2.1-1ubuntu2 all
      transitional package for kdevelop-php
    
    kdevelop-php-docs-l10n/bionic 5.2.1-1ubuntu2 all
      transitional package for kdevelop-php-l10n
    …
    :

Para aprender mais sobre o que cada módulo faz, você pode pesquisar na internet para maiores informações sobre eles. Alternativamente, veja a descrição longa do pacote digitando:

    apt show nome_do_pacote

Haverá uma grande quantidade de saída, com um campo chamado `Description` que terá uma explicação mais longa da funcionalidade que o módulo oferece.

Por exemplo, para encontrar o que o módulo `php-cli` faz, você pode digitar isto:

    apt show php-cli

Juntamente com várias outras informações, você vai encontrar algo parecido com isto:

    Output…
    Description: command-line interpreter for the PHP scripting language (default)
     This package provides the /usr/bin/php command interpreter, useful for
     testing PHP scripts from a shell or performing general shell scripting tasks.
     .
     PHP (recursive acronym for PHP: Hypertext Preprocessor) is a widely-used
     open source general-purpose scripting language that is especially suited
     for web development and can be embedded into HTML.
     .
     This package is a dependency package, which depends on Ubuntu's default
     PHP version (currently 7.2).
    …

Se, após pesquisar, você decidir que gostaria de instalar um pacote, você pode fazê-lo utilizando o comando `apt install` assim como fizemos para nossos outros softwares.

Se decidir que o `php-cli` é algo que você precisa, você poderia digitar:

    sudo apt install php-cli

Se você quiser instalar mais de um módulo, você pode fazer isso listando cada um, separado por um espaço, seguindo o comando `apt install`, como abaixo:

    sudo apt install pacote1 pacote2 ...

Nesse ponto, sua pilha LAMP está instalada e configurada. Antes de fazer mais alterações ou implantar um aplicativo, seria útil testar proativamente sua configuração do PHP, para o caso de haver algum problema que deva ser resolvido.

## Step 4 — Testando o Processamento PHP no seu Servidor Web

A fim de testar se seu sistema está corretamente configurado para o PHP, crie um script PHP bem básico denominado `info.php`. Para que o Apache possa encontrar o arquivo e servi-lo corretamente, ele deve ser salvo em um diretório muito específico, o qual é chamado de “web root”.

No Ubuntu 18.04, este diretório está localizado em `/var/www/html`. Crie o arquivo neste local digitando:

    sudo nano /var/www/html/info.php

Isto vai abrir um arquivo em branco. Coloque o texto a seguir, que é um código PHP válido, dentro do arquivo:

info.php

    <?php
    phpinfo();
    ?>
    

Quando você tiver concluído, salve e feche o arquivo.

Agora você pode testar se seu servidor web pode exibir corretamente o conteúdo gerado por esse script PHP. Para testar isso, visite esta página em seu navegador web. Você vai precisar novamente do endereço IP público do seu servidor.

O endereço que você vai querer visitar é:

    http://ip_do_seu_servidor/info.php

A página que você deve ver deve se parecer com isto:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/how-to-install-lamp-ubuntu-18/small_php_info_1804.png)

Esta página fornece a você informações básicas sobre seu servidor a partir da perspectiva do PHP. Ela é útil para depuração e para assegurar que suas configurações estão sendo corretamente aplicadas.

Se você pode ver essa página em seu navegador, então seu PHP está funcionando como esperado.

Você provavelmente vai querer remover este arquivo depois do teste, pois ele realmente pode fornecer informações sobre seu servidor para usuários não autorizados. Para fazer isto, execute o seguinte comando:

    sudo rm /var/www/html/info.php

Você sempre poderá recriar esta página se precisar acessar novamente as informações mais tarde.

## Conclusão

Agora que você tem uma pilha LAMP instalada, você terá muitas opções para o que fazer em seguida. Basicamente, você instalou uma plataforma que lhe permitirá instalar a maioria dos tipos de websites e softwares web em seu servidor.

Como um próximo passo imediato, você deve se certificar de que as conexões para o seu servidor web são seguras, servindo-as via HTTPS. A opção mais fácil aqui é [utilizar o Let’s Encrypt](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04) para proteger seu site com um certificado TLS/SSL gratuito.
