---
author: Brennen Bearnes
date: 2017-02-15
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-e-proteger-o-phpmyadmin-no-ubuntu-16-04-pt
---

# Como Instalar e Proteger o phpMyAdmin no Ubuntu 16.04

### Introdução

Enquanto muitos usuários precisam da funcionalidade de um sistema de gerenciamento de banco de dados como o MySQL, eles podem não se sentir confortáveis interagindo com o sistema unicamente a partir do prompt do MySQL.

O **phpMyAdmin** foi criado para que os usuários possam interagir com o MySQL através de uma interface web. Neste guia, vamos discutir como instalar e proteger o phpMyAdmin para que você possa usá-lo com segurança para gerenciar seus bancos de dados a partir de um sistema Ubuntu 16.04.

## Pré-requisitos

Antes de começar com este guia, você precisa completar alguns passos básicos.

Primeiro, vamos assumir que você está utilizando uma conta não-root com privilégios sudo, conforme descrito nos passos 1-4 na [configuração inicial do servidor para Ubuntu 16.04](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-16-04).

Vamos também assumir que você tenha completado uma instalação **LAMP** ( **L** inux, **A** pache, **M** ySQL, e **P** HP) no seu servidor Ubuntu 16.04. Se isto ainda não estiver concluído, você pode seguir esse guia em [Instalando uma pilha LAMP no Ubuntu 16.04](https://digitalocean.com/community/articles/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04).

Finalmente, existem importantes considerações de segurança ao se utilizar softwares como o phpMyAdmin, uma vez que:

- Comunica-se diretamente com a sua instalação MySQL
- Lida com a autenticação usando credenciais MySQL
- Executa e retorna resultados para consultas SQL arbitrárias

Por estas razões, e porque é um aplicativo PHP amplamente implantado que é frequentemente alvo de ataques, você nunca deve executar o phpMyAdmin em sistemas remotos sobre uma simples conexão HTTP. Se você não possui um domínio configurado com certificado SSL/TLS, você pode seguir esse guia em [securing Apache with Let’s Encrypt on Ubuntu 16.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04).

Quando terminar estas etapas, você estará pronto para começar com este guia.

## Passo Um — Instalar o phpMyAdmin

Para começar, podemos simplesmente instalar o phpMyAdmin a partir dos repositórios padrão do Ubuntu.

Podemos fazer isso através da atualização dos índices locais de pacotes e depois utilizar o sistema de pacotes `apt` para baixar os arquivos e instalá-los em nosso sistema:

    sudo apt-get update
    sudo apt-get install phpmyadmin php-mbstring php-gettext

Serão feitas algumas perguntas para configurar sua instalação corretamente.

**Atenção** : Quando o primeiro prompt aparece, o apache2 está destacado mas **não** selecionado. Se você não teclar **Espaço** para selecionar o Apache, o instalador não irá movimentar os arquivos necessários durante a instalação. Tecle **Espaço** , **Tab** , e depois **Enter** para selecionar o Apache.

- Para seleção do servidor, escolha **apache2**.
- Selecione `yes` quando perguntado se é para usar `dbconfig-common` para configurar o banco de dados
- Você será solicitado a fornecer a senha do administrador do banco de dados
- Você será solicitado a escolher e confirmar uma senha para a própria aplicação `phpMyAdmin` 

O processo de instalação na verdade adiciona o arquivo de configuração Apache do phpMyAdmin dentro do diretório `/etc/apache2/conf-enabled/`, onde ele é automaticamente lido.

A única coisa que precisamos fazer é habilitar explicitamente as extensões PHP `mcrypt` e `mbstring`, o que pode ser feito digitando-se:

    sudo phpenmod mcrypt
    sudo phpenmod mbstring

Depois, você precisará reiniciar o Apache para que suas alterações sejam reconhecidas:

    sudo systemctl restart apache2

Agora você pode acessar a interface web visitando o nome de domínio ou o endereço IP público do seu servidor seguido de `/phpmyadmin`:

    https://nome_de_domínio_ou_IP/phpmyadmin

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/phpmyadmin_1604/small_login_screen.png)

Você pode agora entrar na interface utilizando o nome de usuário `root` e a senha administrativa que você configurou durante a instalação do MySQL:

Quando você efetuar login, você verá a interface de usuário, que será algo parecido com isto:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/phpmyadmin_1604/small_user_interface.png)

## Passo Dois - Proteger sua Instância phpMyAdmin

Fomos capazes de colocar a nossa interface phpMyAdmin rodando e funcionando com bastante facilidade. Contudo, ainda não terminamos. Devido à sua popularidade, o phpMyAdmin é um alvo muito comum para atacantes. Devemos tomar medidas adicionais para impedir o acesso não autorizado.

Uma das maneiras mais fáceis de se fazer isso é colocar um gateway na frente de toda a aplicação. Podemos fazer isso utilizando as funcionalidades embutidas de autenticação e autorização `.htaccess` do Apache.

### Configurar o Apache para Permitir Substituições .htaccess

Primeiro, precisamos ativar o uso de substituições de arquivos `.htaccess` através da edição de nosso arquivo de configuração do Apache.

Vamos editar o arquivo vinculado que foi colocado em nosso diretório de configuração do Apache:

    sudo nano /etc/apache2/conf-available/phpmyadmin.conf

Precisamos adicionar uma diretiva `AllowOverride All` dentro da seção `<Directory /usr/share/phpmyadmin>` do arquivo de configuração, dessa forma:

/etc/apache2/conf-available/phpmyadmin.conf

    <Directory /usr/share/phpmyadmin>
        Options FollowSymLinks
        DirectoryIndex index.php
        AllowOverride All
        . . .

Quando você tiver adicionado essa linha, salve e feche o arquivo.

Para implementar as alterações que você fez, reinicie o Apache:

    sudo systemctl restart apache2

### Criar um arquivo .htaccess

Agora que habilitamos o uso do `.htaccess` para nossa aplicação, precisamos criar um arquivo que realmente implemente alguma segurança.

Para que isso seja efetivo, o arquivo deve ser criado dentro do diretório da aplicação. Podemos criar o arquivo necessário e abri-lo em nosso editor de textos com privilégios de root digitando:

    sudo nano /usr/share/phpmyadmin/.htaccess

Dentro desse arquivo, precisamos entrar com a seguinte informação:

/usr/share/phpmyadmin/.htaccess

    AuthType Basic
    AuthName "Restricted Files"
    AuthUserFile /etc/phpmyadmin/.htpasswd
    Require valid-user

Vamos ver o que cada uma dessas linhas significa:

- `AuthType Basic`: Essa linha especifica o tipo de autenticação que estamos implementando. Esse tipo irá implementar autenticação por senha utilizando um arquivo de senhas.
- `AuthName`: Isso configura a mensagem para a caixa de diálogo de autenticação. Você deve manter isso genérico para que usuários não autorizados não obtenham nenhuma informação sobre o que está sendo protegido.
- `AuthUserFile`: Isso configura a localização do arquivo de senhas que será utilizado para autenticação. Isso deve estar fora dos diretórios que estão sendo servidos. Vamos criar este arquivo em breve. 
- `Require valid-user`: Isso especifica que somente os usuários autenticados devem ter acesso a esse recurso. Isso é o que realmente impede que usuários não autorizados entrem. 

Quando tiver terminado, salve e feche o arquivo.

### Criar o arquivo .htpasswd para Autenticação

Agora que especificamos a localização do nosso arquivo de senhas através do uso da diretiva `AuthUserFile` dentro de nosso arquivo `.htaccess`, precisamos criar esse arquivo.

Na verdade, precisamos de um pacote adicional para concluir este processo. Podemos instalá-lo a partir de nossos repositórios padrão:

    sudo apt-get install apache2-utils

Depois, teremos o utilitário `htpasswd` disponível.

A localização que selecionamos para o arquivo de senhas era “`/etc/phpmyadmin/.htpasswd`”. Vamos criar esse arquivo e passá-lo um usuário inicial digitando:

    sudo htpasswd -c /etc/phpmyadmin/.htpasswd nome_de_usuário

Você será solicitado a selecionar e confirmar uma senha para o usuário que você está criando. Em seguida, o arquivo é criado com o hash de senha que você digitou.

Se você quiser inserir um usuário adicional, você precisa fazê-lo **sem** o modificador `-c`, como abaixo:

    sudo htpasswd /etc/phpmyadmin/.htpasswd usuário_adicional

Agora, ao acessar o subdiretório phpMyAdmin, você será solicitado a fornecer o nome da conta adicional e a senha que você acabou de configurar:

    https://nome_de_domínio_ou_IP/phpmyadmin

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/phpmyadmin_1404/apache_auth.png)

Depois de entrar com a autenticação do Apache, você será levado para a página de autenticação normal do phpMyAdmin para inserir suas outras credenciais. Isso irá adicionar uma camada adicional de segurança, visto que o phpMyAdmin sofreu de vulnerabilidades no passado.

## Conclusão

Agora você deve ter o phpMyAdmin configurado e pronto para usar em seu servidor Ubuntu 16.04. Usando essa interface, você pode facilmente criar bancos de dados, usuários, tabelas, etc, e executar as operações habituais como excluir e modificar estruturas e dados.
