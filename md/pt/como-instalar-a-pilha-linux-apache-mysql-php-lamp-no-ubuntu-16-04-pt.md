---
author: Brennen Bearnes
date: 2016-12-12
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-a-pilha-linux-apache-mysql-php-lamp-no-ubuntu-16-04-pt
---

# Como instalar a pilha Linux, Apache, MySQL, PHP (LAMP) no Ubuntu 16.04

### Introdução

A pilha “ **LAMP** ” é um grupo de softwares open source que é tipicamente instalado em conjunto para permitir a um servidor hospedar websites dinâmicos e aplicações web. Este termo é atualmente um acrônimo que representa o sistema operacional **L** inux, com o servidor web **A** pache. A informação do site é armazenada em uma base de dados **M** ySQL, e o conteúdo dinâmico é processado pelo **P** HP.

Neste guia, vamos ter uma pilha **LAMP** instalada em um Droplet Ubuntu 16.04. O Ubuntu preencherá nosso primeiro requisito: Um sistema operacional Linux.

## Pré-requisitos

Antes de você iniciar com este guia, você deve ter uma conta separada, que não seja root, com privilégios `sudo`, configurada em seu servidor. Você pode aprender como fazer isto completando os passos 1-4 na [configuração inicial do servidor para Ubuntu 16.04](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-16-04).

## Passo 1 - Instalar o Apache e Permitir no Firewall

O servidor web Apache está entre os servidores web mais populares do mundo. É bem documentado, e tem sido amplamente utilizado em grande parte da história da web, o que faz dele uma ótima escolha padrão para hospedar um website.

Podemos instalar o Apache facilmente utilizando o gerenciador de pacotes do Ubuntu, `apt`. Um gerenciador de pacotes nos permite instalar a maioria dos softwares a partir de um repositório mantido pelo Ubuntu, sem traumas. Você pode aprender mais sobre [como utilizar o `apt`](https://www.digitalocean.com/community/articles/how-to-manage-packages-in-ubuntu-and-debian-with-apt-get-apt-cache) aqui.

Para nossos propósitos, podemos começar digitando os seguintes comandos:

    sudo apt-get update
    sudo apt-get install apache2

Como estamos utilizando um comando `sudo`, essas operações são executadas com privilégios de root. Ele irá pedir a senha regular do usuário para verificar suas intenções.

Uma vez que você tenha digitado sua senha, o `apt` irá lhe dizer quais pacotes ele planeja instalar e quanto de espaço extra em disco ele irá consumir. Pressione **Y** e aperte o **Enter** para continuar, e a instalação prosseguirá.

### Definir ServerName Global para Suprimir Avisos de Sintaxe

A seguir, vamos adicionar uma única linha ao arquivo `/etc/apache2/apache2.conf` para suprimir uma mensagem de aviso. Apesar de inofensivo, se você não definir globalmente o `ServerName`, você receberá o seguinte aviso quando for verificar sua configuração do Apache em busca de erros de sintaxe:

    sudo apache2ctl configtest

    OutputAH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
    Syntax OK

Abra o arquivo de configuração principal com seu editor de textos:

    sudo nano /etc/apache2/apache2.conf

Dentro do arquivo, na parte inferior, adicione a diretiva `ServerName`, apontando para o seu nome de domínio primário. Se você não tem um nome de domínio associado ao seu servidor, você pode utilizar o endereço IP público do seu servidor:

Observação

    Se você não sabe qual é o endereço IP do seu servidor, pule para a seção abaixo que mostra como encontrar o endereço IP público do seu servidor.

    /etc/apache2/apache2.conf
    . . .
    ServerName nome_de_domínio_do_servidor_ou_IP

Salve e feche o arquivo quando você tiver terminado.

Depois, verifique erros de sintaxe digitando:

    sudo apache2ctl configtest

Uma vez que adicionamos a diretiva global `ServerName`, tudo o que você deve ver é:

    [secondary-label Output]
    Syntax OK

Reinicie o Apache para implementar suas alterações:

    sudo systemctl restart apache2

Agora você pode começar a ajustar o firewall.

### Ajustar o Firewall para Permitir Tráfego Web

Agora, assumindo que você seguiu as instruções de configuração inicial do servidor para habilitar o firewall UFW, certifique-se de que seu firewall permite tráfego HTTP e HTTPS. Você pode certificar-se de que o UFW tem um perfil de aplicativo para o Apache assim:

    sudo ufw app list

    OutputAvailable applications:
        Apache
        Apache Full
        Apache Secure
        OpenSSH

Se você olhar para o perfil `Apache Full`, ele deve mostrar que ele habilita tráfego para as portas 80 e 443:

    sudo ufw app info "Apache Full"

    OutputProfile: Apache Full
    Title: Web Server (HTTP,HTTPS)
    Description: Apache v2 is the next generation of the omnipresent Apache web
    server.
    
    Ports:
      80,443/tcp

Permita o tráfego entrante para esse perfil:

    sudo ufw allow in "Apache Full"

Você pode fazer uma verificação imediata para verificar se tudo correu como planejado visitando o endereço IP público do seu servidor no seu navegador web (Veja a nota abaixo do próximo cabeçalho para descobrir qual é o seu endereço IP público se você ainda não tiver essa informação):

    http://endereço_IP_do_seu_servidor

Você verá a página web padrão do Ubuntu 16.04, que está lá para fins de teste e informação. Ela deve ser algo assim:

![](http://assets.digitalocean.com/articles/how-to-install-lamp-ubuntu-16/small_apache_default.png)

Se você vir esta página, então seu servidor web agora está corretamente instalado e acessível através do seu firewall.

### Como Encontrar o Endereço IP Público do seu Servidor

Se você não sabe qual é o endereço IP público do seu servidor, há uma série de maneiras pelas quais você pode encontrá-lo. Geralmente, esse é o endereço que você utiliza para se conectar ao seu servidor através do SSH.

A partir da linha de comando, você pode encontrar isso de algumas maneiras. Primeiro, você pode utilizar as ferramentas `iproute2` para obter seu endereço digitando isso:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Esse comando vai lhe retornar duas ou três linhas. Todos são endereços corretos, mas seu computador só poderá utilizar um deles, portanto, sinta-se livre para tentar cada um.

Um método alternativo é usar o utilitário `curl` para entrar em contato com algum meio externo para lhe dizer como ele vê o seu servidor. Você pode fazer isso perguntando a um servidor específico qual é o seu IP:

    sudo apt-get install curl
    curl http://icanhazip.com

Independentemente do meio que você usa para obter seu endereço IP, você pode digitá-lo na barra de endereço do seu navegador web para chegar ao seu servidor

## Passo 2: Instalar o MySQL

Agora que temos nosso servidor web pronto e funcionando, é hora de instalar o MySQL. O MySQL é um sistema de gerenciamento de bancos de dados. Basicamente, ele irá organizar e proporcionar acesso às bases de dados onde nosso site pode armazenar informação.

Novamente, podemos utilizar o `apt` para obter e instalar nosso software. Desta vez, vamos também instalar alguns pacotes “auxiliares” que irão nos ajudar a obter nossos componentes para se comunicarem uns com os outros:

    sudo apt-get install mysql-server

Observação:

     Neste caso, você não tem que executar `sudo apt-get update` antes do comando. Isso é porque o executamos recentemente através dos comandos acima para instalar o Apache. O índice de pacotes em nosso computador já deve estar atualizado.

Novamente, será mostrada uma lista dos pacotes que serão instalados, juntamente com a quantidade de espaço em disco que irão ocupar. Digite **Y** para continuar.

Durante a instalação, seu servidor vai pedir para você selecionar e confirmar uma senha para o usuário “root” do MySQL. Esta é uma conta administrativa no MySQL que possui privilégios avançados. Pense nela como sendo similar à conta de root para o próprio servidor (no entanto, esta que você está configurando agora é uma conta específica do MySQL). Certifique-se de que esta é uma senha forte e exclusiva, e não a deixe em branco.

Quando a instalação estiver concluída, queremos executar um script de segurança simples que remova alguns padrões perigosos e bloqueie um pouco o acesso ao nosso sistema de banco de dados. Inicie o script interativo executando:

    sudo mysql_secure_installation

Será pedido que você digite a senha que você definiu para a conta root do MySQL. Depois, será perguntado se você quer configurar o plugin `VALIDATE PASSWORD PLUGIN`.

Atenção:

     A habilitação dessa funcionalidade é algo que deve ser avaliado. Se habilitado, senhas que não seguem o critério especificado serão rejeitadas pelo MySQL com um erro. Isso irá causar problemas se você utilizar uma senha fraca juntamente com software que configura automaticamente as credenciais de usuário do MySQL, tais como os pacotes do Ubuntu para o phpMyAdmin. É seguro deixar a validação desativada, mas você deve sempre utilizar senhas fortes e exclusivas para as credenciais do banco de dados.

Responda y para Sim, ou qualquer outra coisa para continuar sem a habilitação.

        VALIDATE PASSWORD PLUGIN can be used to test passwords
        and improve security. It checks the strength of password
        and allows the users to set only those passwords which are
        secure enough. Would you like to setup VALIDATE PASSWORD plugin?
    
        Press y|Y for Yes, any other key for No:

Você será solicitado a selecionar um nível de validação de senha. Tenha em mente que se você digitar 2, para o nível mais forte, você receberá erros quando tentar configurar qualquer senha que não contenha números, letras maiúsculas e minúsculas, e caracteres especiais, ou que seja baseada em palavras comuns do dicionário.

        There are three levels of password validation policy:
    
        LOW Length >= 8
        MEDIUM Length >= 8, numeric, mixed case, and special characters
        STRONG Length >= 8, numeric, mixed case, special characters and dictionary file
    
        Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG: 1

Se você habilitou a validação de senha, será mostrado a força da senha de root atual, e será perguntado se você quer alterar aquela senha. Se você estiver satisfeito com sua senha atual, digite n para “não” no prompt:

        Using existing password for root.
    
        Estimated strength of the password: 100
        Change the password for root ? ((Press y|Y for Yes, any other key for No) : n

Para o restante das perguntas, você deve pressionar **Y** e apertar a tecla **Enter** para cada prompt. Isso irá remover alguns usuários anônimos e o banco de dados de teste, desabilitar logins remotos de root, e carregar essas novas regras de forma que o MySQL respeite imediatamente as alterações que fizemos.

Nesse ponto, seu sistema de banco de dados está agora configurado e podemos seguir e frente.

## Passo 3: Instalar o PHP

O PHP é o componente da nossa configuração que irá processar código para exibir o conteúdo dinâmico. Ele pode executar script, conectar às nossas bases de dados MySQL para obter informações, e entregar o conteúdo processado para o nosso servidor web exibir.

Podemos aproveitar mais uma vez o sistema `apt` para instalar nossos componentes. Vamos incluir alguns pacotes auxiliares também, de forma que o PHP possa executar sob o servidor Apache e conversar com nosso banco de dados MySQL:

    sudo apt-get install php libapache2-mod-php php-mcrypt php-mysql

Isto irá instalar o PHP sem problemas. Vamos testar isso em instantes.

Na maioria do casos, vamos querer modificar a forma com a qual o Apache serve arquivos quando uma pasta é requisitada. Atualmente, se um usuário requisita uma pasta do servidor, o Apache irá olhar primeiramente para um arquivo chamado `index.html`. Queremos informar ao nosso servidor web para dar preferência aos arquivos PHP, então faremos o Apache olhar para um arquivo `index.php` primeiro.

Para fazer isto, digite este comando para abrir o arquivo `dir.inf` em um editor de texto com privilégios de root:

    sudo nano /etc/apache2/mods-enabled/dir.conf

Ele terá esta aparência:

/etc/apache2/mods-enabled/dir.conf

    <IfModule mod_dir.c>
           DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm
    </IfModule>

Queremos mover o arquivo de índice PHP em destaque acima para a primeira posição depois da especificação `DirectoryIndex` , como segue:

/etc/apache2/mods-enabled/dir.conf

    <IfModule mod_dir.c>
           DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
    </IfModule>

Quando você tiver concluído, salve e feche o arquivo pressionando “ **CTRL-X** ”. Você tem que confirmar a gravação digitando “ **Y** ” e em seguida pressione “ **ENTER** ” para confirmar a localização de salvamento do arquivo.

Após isso, precisamos reiniciar o servidor web Apache de forma que nossas alterações sejam reconhecidas. Você pode fazer isto digitando o seguinte:

    sudo systemctl restart apache2

Podemos também verificar o status do serviço `apache2` utilizando `systemctl`:

    sudo systemctl status apache2

Sample Output

     ● apache2.service - LSB: Apache2 web server
          Loaded: loaded (/etc/init.d/apache2; bad; vendor preset: enabled)
         Drop-In: /lib/systemd/system/apache2.service.d
                   └─apache2-systemd.conf
          Active: active (running) since Wed 2016-04-13 14:28:43 EDT; 45s ago
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
    
    Apr 13 14:28:42 ubuntu-16-lamp systemd[1]: Stopped LSB: Apache2 web server.
    Apr 13 14:28:42 ubuntu-16-lamp systemd[1]: Starting LSB: Apache2 web server...
    Apr 13 14:28:42 ubuntu-16-lamp apache2[13605]: * Starting Apache httpd web server apache2
    Apr 13 14:28:42 ubuntu-16-lamp apache2[13605]: AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerNam
    Apr 13 14:28:43 ubuntu-16-lamp apache2[13605]: *
    Apr 13 14:28:43 ubuntu-16-lamp systemd[1]: Started LSB: Apache2 web server.

### Instalar módulos PHP

Para melhorar a funcionalidade do PHP, podemos opcionalmente instalar alguns módulos adicionais.

Para ver as opções disponíveis para os módulos e bibliotecas PHP, podemos direcionar os resultados do comando `apt-cache search` para o comando `less`, um paginador que lhe permite percorrer a saída de outros comandos:

    apt-cache search php- | less

Use as teclas de seta para rolar para cima e para baixo e **q** para sair.

O resultado são todos os componentes opcionais que você pode instalar. Ele lhe dará uma breve descrição de cada um:

        libnet-libidn-perl - Perl bindings for GNU Libidn
        php-all-dev - package depending on all supported PHP development packages
        php-cgi - server-side, HTML-embedded scripting language (CGI binary) (default)
        php-cli - command-line interpreter for the PHP scripting language (default)
        php-common - Common files for PHP packages
        php-curl - CURL module for PHP [default]
        php-dev - Files for PHP module development (default)
        php-gd - GD module for PHP [default]
        php-gmp - GMP module for PHP [default]
        …
        :

Para obter mais informações sobre o que cada módulo faz, você pode buscar na Internet, ou olhar a descrição longa do pacote digitando:

    apt-cache show nome_do_pacote

Haverá uma grande quantidade de saída, com um campo chamado `Description-en` que terá uma explicação mais longa da funcionalidade que o módulo oferece.

Por exemplo, para encontrar o que o módulo `php-cli` faz, podemos digitar isto:

    apt-cache show php-cli

Juntamente com várias outras informações, você vai encontrar algo parecido com isto:

    Output…
    Description-en: command-line interpreter for the PHP scripting language (default)
        This package provides the /usr/bin/php command interpreter, useful for
        testing PHP scripts from a shell or performing general shell scripting tasks.
         .
        PHP (recursive acronym for PHP: Hypertext Preprocessor) is a widely-used
        open source general-purpose scripting language that is especially suited
        for web development and can be embedded into HTML.
        .
        This package is a dependency package, which depends on Debian's default
        PHP version (currently 7.0).
    …

Se, após pesquisar, você decidir que gostaria de instalar um pacote, você pode fazê-lo utilizando o comando `apt-get install` assim como fizemos para nossos outros softwares.

Se decidirmos que o `php-cli` é algo que precisamos, podemos digitar:

    sudo apt-get install php-cli

Se você quiser instalar mais de um módulo, você pode fazer isso listando cada um, separado por um espaço, seguindo o comando `apt-get`, como abaixo:

    sudo apt-get install package1 package2 ...

Nesse ponto, sua pilha LAMP está instalada e configurada. Devemos ainda testar o nosso PHP.

## Passo 4: Testar o processamento PHP no seu servidor web

A fim de testar se nosso sistema está corretamente configurado para o PHP, podemos criar um script bem básico.

Vamos chamar este script de `info.php`. Para que o Apache possa encontrar o arquivo e servi-lo corretamente, ele deve ser salvo em um diretório muito específico, o qual é chamado de “web root”.

No Ubuntu 16.04, este diretório está localizado em `/var/www/html`. Podemos criar o arquivo neste local digitando:

    sudo nano /var/www/html/info.php

Isto vai abrir um arquivo em branco. Queremos colocar o texto a seguir, que é um código PHP válido, dentro do arquivo:

info.php

    <?php
    phpinfo();
    ?>

Quando você tiver concluído, salve e feche o arquivo.

Agora podemos testar se nosso servidor web pode exibir corretamente o conteúdo gerado por um script PHP. Para testar isso, temos apenas que visitar esta página em nosso navegador. Você vai precisar novamente do endereço IP público do seu servidor.

O endereço que você quer visitar será:

    http://endereço_IP_do_seu_servidor/info.php

A página que você deve ver deve se parecer com isto:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/how-to-install-lamp-ubuntu-16/small_php_info.png)

Esta página basicamente fornece a você informações sobre seu servidor a partir da perspectiva do PHP. Ela é útil para depuração e para assegurar que suas configurações estão sendo corretamente aplicadas.

Se tiver êxito, então seu PHP está funcionando como esperado.

Você provavelmente vai querer remover este arquivo depois do teste, pois ele realmente pode fornecer informações sobre seu servidor para usuários não autorizados. Para fazer isto, você pode digitar o seguinte:

    sudo rm /var/www/html/info.php

Você sempre poderá recriar esta página se precisar acessar novamente as informações mais tarde.

## Conclusão

Agora que você tem uma pilha LAMP instalada, você terá muitas opções para o que fazer em seguida. Basicamente, você instalou uma plataforma que lhe permitirá instalar a maioria dos tipos de websites e softwares web em seu servidor.

Como um próximo passo intermediário, você deve se certificar de que as conexões para o seu servidor web são seguras, servindo-as via HTTPS. A opção mais fácil é [utilizar o Let’s Encrypt](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04) para proteger seu site com um certificado TLS/SSL gratuito.

Algumas opções populares são:

- [Instalar o Wordpress](https://www.digitalocean.com/community/articles/how-to-install-wordpress-on-ubuntu-14-04) o sistema gerenciador de conteúdo mais popular da Internet
- [Configurar o PHPMyAdmin](https://www.digitalocean.com/community/articles/how-to-install-and-secure-phpmyadmin-on-ubuntu-12-04) para ajudá-lo a gerenciar seu banco de dados MySQL a partir de um navegador.
- [Aprenda mais sobre o MySQL](https://www.digitalocean.com/community/articles/a-basic-mysql-tutorial) para gerenciar suas bases de dados.
- [Aprenda a utilizar o SFTP](https://www.digitalocean.com/community/articles/how-to-use-sftp-to-securely-transfer-files-with-a-remote-server) para transferir arquivos de e para o seu servidor.

**Observação:** Estaremos atualizando os links acima para nossa documentação 16.04, conforme está escrito.
