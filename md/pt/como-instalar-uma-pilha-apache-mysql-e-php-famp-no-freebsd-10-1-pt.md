---
author: Mitchell Anicas
date: 2015-02-19
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-uma-pilha-apache-mysql-e-php-famp-no-freebsd-10-1-pt
---

# Como Instalar uma pilha Apache, MySQL, e PHP (FAMP) no FreeBSD 10.1

### Introdução

Uma pilha FAMP, que é similar a uma pilha LAMP no Linux, é um grupo de softwares de código aberto que é tipicamente instalado em conjunto para habilitar um servidor FreeBSD a hospedar websites dinâmicos e web apps. FAMP é um acrônimo que significa **F** reeBSD (sistema operacional), **A** pache (servidor web), **M** ySQL (servidor de banco de dados), e **P** HP (para processar conteúdo PHP dinâmico).

Neste guia, teremos uma pilha FAMP instalada em um servidor FreeBSD 10.1 na nuvem, utilizando `pkg`, o gerenciador de pacotes do FreeBSD.

## Pré-requisitos

Antes de começar este guia, você deve ter um servidor FreeBSD 10.1. Adicionalmente, você deve se conectar ao seu servidor FreeBSD como um usuário com privilégios de superusuário (ou seja, com permissão para usar o sudo ou alternar para usuário root).

## Passo um - Instalar o Apache

O servidor web Apache é atualmente o servidor web mais popular no mundo, o que o torna uma ótima escolha para hospedar um website.

Podemos instalar o Apache facilmente utilizando o gerenciador de pacotes do FreeBSD, `pkg`. Um gerenciador de pacotes nos permite instalar a maioria dos softwares sem maiores problemas, a partir de um repositório mantido pelo FreeBSD. Você pode saber mais sobre [como utilizar `pkg` aqui](how-to-manage-packages-on-freebsd-10-1-with-pkg).

Para instalar o Apache 2.4 utilizando o `pkg`, utilize este comando:

    sudo pkg install apache24

Digite `y` no prompt de confirmação.

Isto instala o Apache e suas dependências.

Para habilitar o Apache como um serviço, adicione `apache24_enable="YES"` ao arquivo `/etc/rc.conf`. Iremos utilizar o comando `sysrc` para fazer exatamente isso:

    sudo sysrc apache24_enable=yes

Agora inicie o Apache:

    sudo service apache24 start

Você pode fazer uma verificação local imediatamente para checar que tudo saiu conforme planejado visitando o endereço IP público do seu servidor no seu navegador web (veja a nota na seção seguinte para descobrir qual é o seu endereço IP público, se você já não tiver essa informação):

http://endereço_IP_do_seu_servidor/

Você verá a página padrão do Apache no FreeBSD, que está lá para propósitos de teste. Ele deve dizer: “It Works!”, que indica que seu servidor web está corretamente instalado.

### Como encontrar o endereço IP público do seu servidor

Se você não sabe qual é o endereço IP público do seu servidor, existem várias formas que você poderá usar para encontrá-lo. Usualmente, este é o endereço que você utiliza para conectar ao servidor através do SSH.

Se você estiver utilizando DigitalOcean, você pode olhar no Painel de Controle para ver o endereço IP do seu servidor. Você também pode utilizar o serviço de Metadados da DigitalOcean, a partir do próprio servidor, com este comando: `curl -w "\n" http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address`.

Uma maneira mais universal de se procurar o endereço IP é utilizar o comando `ifconfig`, no próprio servidor. O comando `ifconfig` irá imprimir informações sobre suas interfaces de rede. A fim de limitar a saída para somente o endereço IP público do servidor, utilize o comando (observe que a parte destacada é o nome da interface de rede, e pode variar):

    ifconfig vtnet0 | grep "inet " | awk '{ print $2 }'

Agora que você tem o endereço IP público, você pode utilizá-lo na barra de endereço do seu navegador web para acessar seu servidor web.

## Passo Dois — Instalar o MySQL

Agora que temos nosso servidor web iniciado e rodando, é hora de instalar o MySQL, o sistema de gerenciamento de banco de dados relacional. O servidor MySQL irá organizar e fornecer acesso às bases de dados onde nosso servidor poderá armazenar informações.

Novamente, podemos utilizar o `pkg` para obter e instalar nosso software.

Para instalar o MySQL 5.6 utilizando o `pkg`, use este comando:

    sudo pkg install mysql56-server

Digite `y` no prompt de confirmação.

Isto instala os pacotes de servidor e cliente MySQL.

Para habilitar o servidor MySQL como um serviço, adicione `mysql_enable="YES"` ao arquivo `/etc/rc.conf`. Este comando `sysrc` vai fazer exatamente isso:

    sudo sysrc mysql_enable=yes

Agora, inicie o servidor MySQL:

    sudo service mysql-server start

Agora que seu banco de dados MySQL está rodando, você vai querer executar um script simples de segurança que irá remover alguns padrões perigosos e restringir ligeiramente o acesso ao seu sistema de banco de dados. Inicie o script interativo através da execução deste comando:

    sudo mysql_secure_installation

O prompt irá solicitar sua senha de root atual (o usuário administrador do MySQL, root). Como você acabou de instalar o MySQL, você provavelmente não terá uma, portanto, deixe em branco pressionando `ENTER`. Então o prompt irá perguntar se você quer definir um senha de root. Siga em frente e digite `y`, e siga as instruções:

    Enter current password for root (enter for none): [RETURN]
    OK, successfully used password, moving on...
    
    Setting the root password ensures that nobody can log into the MySQL
    root user without the proper authorization.
    
    Set root password? [Y/n] Y
    New password: password
    Re-enter new password: password
    Password updated successfully!

Para o restante das questões, você deve simplesmente pressionar a tecla `ENTER` em cada prompt para aceitar os valores padrão. Isto removerá alguns usuários e bases de dados de exemplo, desabilitar logins remotos de root, e carregar estas novas regras para que o MySQL respeite imediatamente as alterações que fizemos.

Nesse ponto, seu sistema de banco de dados está agora configurado e podemos ir adiante.

## Passo Três — Instalar o PHP

O PHP é o componente de nossa configuração que irá processar código para apresentar conteúdo dinâmico. Ele pode executar scripts, conectar a bancos de dados MySQL para obter informações, e entregar o conteúdo processado para o servidor web exibir.

Podemos novamente aproveitar o sistema `pkg` para instalar nossos componentes. Vamos incluir também os pacotes `mod_php`, `php-mysql`, e `php-mysqli`

Para instalar o PHP 5.6 com `pkg`, execute este comando:

    sudo pkg install mod_php56 php56-mysql php56-mysqli

Digite `y` no prompt de confirmação. Isto instala os pacotes `php56`, `mod_php56`, `php56-mysql`, e `php56-mysqli`.

Agora, copie o arquivo de exemplo de configuração do PHP no lugar com este comando:

    sudo cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

Agora, execute o comando `rehash` para regenerar informações em cache do sistema sobre seus arquivos executáveis instalados:

    rehash

Antes de utilizar o PHP, você deve configurá-lo para trabalhar com o Apache.

## Instalar Módulos PHP (Opcional)

Para melhorar a funcionalidade do PHP, podemos opcionalmente instalar alguns módulos adicionais.

Para visualizar as opões disponíveis para módulos e bibliotecas PHP 5.6, você pode digitar isto em seu sistema:

    pkg search php56

Os resultados serão, em sua maioria, módulos PHP 5.6 que você pode instalar:

    mod_php56-5.6.3
    php56-5.6.3
    php56-bcmath-5.6.3
    php56-bz2-5.6.3
    php56-calendar-5.6.3
    php56-ctype-5.6.3
    php56-curl-5.6.3
    php56-dba-5.6.3
    php56-dom-5.6.3
    php56-exif-5.6.3
    ...

Para obter maiores informações sobre o que cada módulo faz, você pode pesquisar na Internet, ou olhar a descrição longa do pacote digitando:

    pkg search -f package_name

Haverá uma grande quantidade de saída, com um campo chamado **Comment** , o qual terá uma explicação da funcionalidade que o módulo fornece.

Por exemplo, para pesquisar o que o módulo `php56-calendar` faz, poderíamos digitar isto:

    pkg search -f php56-calendar

Juntamente com uma grande quantidade de outras informações, você encontrará algo que se parece com isto:

    php56-calendar-5.6.3
    Name : php56-calendar
    Version : 5.6.3
    ...
    Comment : The calendar shared extension for php
    ...

Se, após pesquisar, você decidir que você gostaria de instalar um pacote, você poderá fazer isto utilizando o comando `pkg install`, como temos feito para os outros softwares.

Por exemplo, se decidirmos que `php56-calendar` é algo que precisamos, poderíamos digitar:

    sudo pkg install php56-calendar

Se você quer instalar mais de um módulo ao mesmo tempo, poderá fazer isto listando cada um, separados por um espaço, seguindo o comando `pkg install`, desta forma:

    sudo pkg install package1 package2 ...

## Passo Quatro — Configurar o Apache para Utilizar o Módulo PHP

Antes que o Apache possa processar páginas PHP, devemos configurá-lo para usar `mod_php`.

Abra o arquivo de configuração do Apache:

    sudo vi /usr/local/etc/apache24/httpd.conf

Primeiro, iremos configurar o Apache para carregar os arquivos `index.php` por padrão. Olhe para `DirectoryIndex` `index.html` e modifique adicionando `index.php` em frente ao `index.html`, assim:

    DirectoryIndex index.php index.html

Depois, iremos configurar o Apache para processar arquivos PHP requisitados com o pré-processador PHP. Adicione estas linhas ao final do arquivo:

    <FilesMatch "\.php$">
        SetHandler application/x-httpd-php
    </FilesMatch>
    <FilesMatch "\.phps$">
        SetHandler application/x-httpd-php-source
    </FilesMatch>

Salve e saia.

Agora, reinicie o Apache para colocar as alterações em prática:

    sudo service apache24 restart

Nesse ponto, sua pilha FAMP está instalada e configurada. Vamos testar sua configuração PHP agora.

## Passo Cinco — Testar o Processamento PHP

De forma a testar que nosso sistema está configurado apropriadamente para PHP, podemos criar um script PHP bem básico.

Chamaremos este script de `info.php`. Para que o Apache possa encontrar o arquivo e servi-lo corretamente, ele deve ser salvo em um diretório muito específico– **DocumentRoot** – que é onde o Apache irá procurar os arquivos quando um usuário acessa o servidor web. A localização de DocumentRoot é especificada no arquivo de configuração do Apache que foi modificado anteriormente (`/usr/local/etc/apache24/httpd.conf`).

Por padrão, o DocumentRoot é definido para `/usr/local/www/apache24/data`. Podemos criar o arquivo `info.php` neste local digitando:

    sudo vi /usr/local/www/apache24/data/info.php

Isto irá abrir um arquivo em branco. Insira este código PHP dentro do arquivo:

    <?php phpinfo(); ?>

Salve e saia.

Agora podemos testar se nosso servidor we pode mostrar conteúdo gerado por um script PHP corretamente. Para tentar fazer isso, temos apenas que visitar esta página em nosso navegador web. Você precisará novamente do endereço IP público do seu servidor web.

O endereço que você quer visitar será:

    http://endereço_IP_do_seu_sevidor_web/info.php

A página que você vê deve ser algo como isto:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/freebsd_lamp/freebsd_info_php.png)

Esta página basicamente lhe dá informações sobre o seu servidor web, a partir da perspectiva do PHP. Ela é útil para depurar e para garantir que suas configurações foram aplicadas corretamente.

Se isso foi bem sucedido, então seu PHP está funcionando como esperado.

Você provavelmente vai querer remover este arquivo após este teste, pois poderia realmente dar informações sobre o seu servidor para usuários não autorizados. Para fazer isso, basta você digitar:

    sudo rm /usr/local/www/apache24/data/info.php

Você sempre pode recriar esta página se precisar acessar a informação novamente depois.

## Conclusão

Agora que você tem a pilha FAMP instalada, você tem muitas opções para o que fazer a seguir. Basicamente, você instalou uma plataforma que lhe permitirá instalar a maioria dos tipos de websites e software web em seu servidor.

Se você estiver interessado em configurar WordPress em sua nova pilha FAMP, verifique este tutorial: [How To Install WordPress with Apache on FreeBSD 10.1](how-to-install-wordpress-with-apache-on-freebsd-10-1).
