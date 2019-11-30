---
author: Justin Ellingwood
date: 2016-12-28
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-wordpress-com-lamp-no-ubuntu-16-04-pt
---

# Como Instalar o WordPress com LAMP no Ubuntu 16.04

### Introdução

O WordPress é o CMS (sistema de gerenciamento de conteúdo) mais popular na internet. Ele lhe permite configurar facilmente blogs e websites flexíveis em cima de uma retaguarda MySQL com processamento PHP. O WordPress tem visto uma adoção incrível e é uma ótima opção para colocar um site instalado e funcionando rapidamente. Após a configuração, quase toda a administração pode ser feita através da interface web.

Neste guia, vamos focar em colocar uma instância WordPress configurada em uma pilha LAMP (Linux, Apache, MySQL, e PHP) em um servidor Ubuntu 16.04.

## Pré-requisitos

Para completar esse tutorial, você precisa de acesso a um servidor Ubuntu 16.04.

Você precisará realizar as seguintes tarefas antes de poder iniciar esse guia:

- **Criar um usuário `sudo` em seu servidor** : Estaremos completando as etapas nesse guia utilizando um usuário não-root com privilégios `sudo`. Você pode criar um usuário com privilégios sudo seguindo nosso [Guia de Configuração Inicial de servidor com Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).
- **Instalar uma pilha LAMP** : O WordPress vai precisar de um servidor web, um banco de dados, e o PHP para funcionar corretamente. A configuração de uma pilha LAMP (Linux, Apache, MySQL, e PHP) preenche todos esses requisitos. Siga [esse guia](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04) para instalar e configurar esses softwares.
- **Proteger seu site com SSL** : O WordPress fornece conteúdo dinâmico e gerencia a autenticação e autorização do usuário. TLS/SSL é a tecnologia que permite criptografar o tráfego do seu site para que sua conexão seja segura. A maneira como você configura o SSL dependerá se você tem um nome de domínio para o seu site.
  - **Se você tem um nome de domínio** … a maneira mais fácil de proteger seu site é com Let’s Encrypt, que fornece certificados gratuitos e confiáveis. Siga nosso guia [Let’s Encrypt guide for Apache](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04) para configurar isso.
  - **Se você não tem um nome de domínio** … e você está usando esta configuração apenas para testes ou uso pessoal, você pode usar um certificado auto-assinado nesse caso. Isso fornece o mesmo tipo de criptografia, mas sem a validação do domínio. Siga nosso guia [self-signed SSL guide for Apache](how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu-16-04) para configurar isso.

Quando terminar as etapas de configuração, faça login no servidor como seu usuário `sudo` e continue com as instruções abaixo.

## Passo 1: Criar um Banco de Dados MySQL e Usuários para o WordPress

O primeiro passo que vamos dar é uma preparação. O WordPress utiliza o MySQL para gerenciar e armazenar informações do site e de usuários. Já temos o MySQL instalado, mas precisamos criar um banco de dados e um usuário para o WordPress utilizar.

Para começar, entre com a conta root (administrativa) do MySQL digitando esse comando:

    mysql -u root -p

Você será solicitado pela senha que você definiu para a conta de root do MySQL quando você instalou o software.

Primeiro, podemos criar um banco de dados separado que o WordPress possa controlar. Você pode chamá-lo do que quiser, mas estaremos usando `wordpress` nesse guia para manter a simplicidade. Você pode criar o banco de dados para o WordPress digitando:

    CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

**Note** : Toda instrução MySQL deve terminar em um ponto-e-vírgula (;). Verifique se isso está presente se você estiver tendo quaisquer problemas.

A seguir, vamos criar uma conta de usuário MySQL separada que iremos utilizar exclusivamente para operar em nosso novo banco de dados. A criação de bancos de dados e contas específicas é uma boa ideia do ponto de vista do gerenciamento e da segurança. Vamos utilizar o nome `wordpressuser` nesse guia. Fique à vontade para alterar isso se desejar.

Vamos criar essa conta, definir uma senha, e conceder acesso ao banco de dados que criamos. Podemos fazer isso digitando o seguinte comando. Lembre-se de escolher aqui uma senha forte para seu usuário de banco de dados:

    GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost' IDENTIFIED BY 'password';

Agora você tem um banco de dados e uma conta de usuário, cada qual feita especificamente para o WordPress. Precisamos recarregar os privilégios para que a instância atual do MySQL saiba sobre as mudanças recentes que fizemos:

    FLUSH PRIVILEGES;

Saia do MySQL digitando:

    EXIT;

## Passo 2: Instalar Extensões Adicionais do PHP

Ao configurar nossa pilha LAMP, precisamos apenas de um conjunto mínimo de extensões de forma que o PHP possa se comunicar com o MySQL. O WordPress e muitos de seus plugins exigem extensões PHP adicionais.

Podemos baixar e instalar algumas das estensões PHP mais populares para uso com o WordPress digitando:

    sudo apt-get update
    sudo apt-get install php-curl php-gd php-mbstring php-mcrypt php-xml php-xmlrpc

Nota

    Cada plugin WordPress tem seu próprio conjunto de requisitos. Alguns podem exigir pacotes PHP adicionais para serem instalados. Verifique a documentação do plugin para descobrir os requisitos do PHP. Se eles estiverem disponíveis, eles podem ser instalados com o apt-get como demonstrado acima..

Vamos reiniciar o Apache para recarregar essas novas extensões na próxima seção. Se você estiver retornando aqui para instalar plugins adicionais, reinicie o Apache agora digitando:

    sudo systemctl restart apache2

## Passo 3: Ajustar a Configuração do Apache para Permitir Substituições e Reescritas via .htaccess

A seguir, faremos pequenos ajustes em nossa configuração do Apache. Atualmente, o uso de arquivos `.htaccess` está desabilitado. O WordPress e muitos plugins do WordPress utilizam esses arquivos extensivamente para ajustes em diretórios para alterar o comportamento do servidor web.

Adicionalmente, vamos habilitar o `mod_rewrite`, que será necessário para que os permalinks do WordPress funcionem corretamente.

### Habilitar Substituições .htaccess

Abra o arquivo principal de configuração do Apache para fazer nossa primeira alteração:

    sudo nano /etc/apache2/apache2.conf

Para permitir arquivos `.htaccess`, precisamos definir a diretiva `AllowOverride` dentro do bloco `Directory` apontando para nossa pasta raiz (document root). Na parte inferior do arquivo, adicione o seguinte bloco:

/etc/apache2/apache2.conf

    . . .
    
    <Directory /var/www/html/>
        AllowOverride All
    </Directory>
    
    . . .

Quando tiver terminado, salve e feche o arquivo.

### Habilitar o Módulo Rewrite

A seguir, podemos habilitar o `mod_rewrite`, de forma que possamos utilizar a funcionalidade de permalink do WordPress:

    sudo a2enmod rewrite

### Habilitar as Alterações

Antes de implementarmos as alterações que fizemos, verifique para ter certeza de que não cometemos nenhum erro de sintaxe:

    sudo apache2ctl configtest

A saída pode ter uma mensagem semelhante a esta:

    OutputAH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
    Syntax OK

Se você desejar sumprimir a linha no topo, adicione a diretiva `ServerName` ao arquivo `/etc/apache2/apache2.conf` apontando para o domínio do seu servidor ou para seu endereço IP. Essa é apenas uma mensagem e, portanto, não afeta a funcionalidade de nosso site. Contanto que a saída contenha `Sintaxe OK`, você estará pronto para continuar.

Reinicie o Apache para implementar as alterações:

    sudo systemctl restart apache2

## Passo 4: Baixar o WordPress

Agora que nosso software de servidor está configurado, podemos baixar e configurar o WordPress. Por motivos de segurança em particular, é sempre recomendável obter a última versão do WordPress a partir do site dele.

Alterne para um diretório gravável e então baixe a versão compactada digitando:

    cd /tmp
    curl -O https://wordpress.org/latest.tar.gz

Extraia o arquivo compactado para criar a estrutura de diretórios do WordPress:

    tar xzvf latest.tar.gz

Estaremos movendo esses arquivos para nossa pasta raiz momentaneamente. Antes disso, podemos adicionar um modelo de arquivo `.htaccess` e definir suas permissões para que ele fique disponível para o WordPress usar mais tarde.

Crie o arquivo e defina as permissões digitando:

    touch /tmp/wordpress/.htaccess
    chmod 660 /tmp/wordpress/.htaccess

Também copiaremos o arquivo de configuração de exemplo para o nome de arquivo que o WordPress realmente lê:

    cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php

Podemos também criar o diretório `upgrade`, para que o WordPress não tenha problemas com permissões ao tentar fazer isso por conta própria após uma atualização do seu software:

    mkdir /tmp/wordpress/wp-content/upgrade

Agora, podemos copiar todo o conteúdo do diretório para nossa pasta raiz. Estamos usando o flag `-a` para nos certificar que nossas permissões serão mantidas. Estamos usando um ponto ao final de nosso diretório de origem para indicar que tudo dentro do diretório deve ser copiado, incluindo arquivos ocultos (como o arquivo `.htaccess` que criamos):

    sudo cp -a /tmp/wordpress/. /var/www/html

## Passo 5: Configurar o Diretório WordPress

Antes de fazer a configuração web do WordPress, precisamos ajustar alguns itens no nosso diretório WordPress.

### Ajustando a Propriedade e as Permissões

Uma das coisas importantes que precisamos realizar é a criação de permissões de arquivo e propriedades razoáveis. Precisamos ser capazes de gravar nesses arquivos como um usuário regular, e precisamos que o servidor web também seja capaz de acessar e ajustar certos arquivos e diretórios de forma a funcionar corretamente.

Começaremos atribuindo a propriedade de todos os arquivos na pasta raiz ao nosso usuário. Usaremos `sammy` como nosso usuário nesse guia, mas você deve alterar isso para corresponder ao seu usuário `sudo`. Vamos atribuir a propriedade de grupo ao grupo `www-data`:

    sudo chown -R sammy:www-data /var/www/html

A seguir, definiremos o bit `setgid` em cada um dos diretórios dentro da pasta raiz. Isso faz com que novos arquivos criados dentro desses diretórios herdem o grupo do diretório pai (que acabamos de definir para `www-data`) em vez de criar com o grupo primário do usuário. Isso apenas garante que sempre que criarmos um arquivo no diretório na linha de comando, o servidor web ainda terá propriedade do grupo sobre ele.

Podemos definir o bit `setgid` em todos diretórios em nossa instalação WordPress digitando:

    sudo find /var/www/html -type d -exec chmod g+s {} \;

Existem algumas outras permissões mais refinadas que vamos ajustar. Primeiro, daremos acesso de escrita para grupo ao diretório `wp-content` de forma que a interface web possa fazer alterações em tema e plugin:

    sudo chmod g+w /var/www/html/wp-content

Como parte desse processo, daremos ao servidor web acesso de escrita a todo o conteúdo nesses dois diretórios:

    sudo chmod -R g+w /var/www/html/wp-content/themes
    sudo chmod -R g+w /var/www/html/wp-content/plugins

Isso deve ser um conjunto de permissões razoável para começar. Alguns plugins e procedimentos podem exigir ajustes adicionais.

### Definindo o Arquivo de Configuração do WordPress

Agora, precisamos fazer algumas alterações no arquivo principal de configuração do WordPress.

Quando abrimos o arquivo, nossa primeira regra de negócios será ajustar algumas chaves secretas para fornecer alguma segurança para nossa instalação. O WordPress fornece um gerador seguro para esses valores, para que você não precise tentar chegar a bons valores por conta própria. Esses valores são utilizados internamente apenas, por isso não vai prejudicar a usabilidade se tivermos valores complexos e seguros aqui.

Para obter valores seguros do gerador de chave secreta do WordPress, digite:

    curl -s https://api.wordpress.org/secret-key/1.1/salt/

Você receberá valores exclusivos que se parecem com isso:

**Atenção!** É importante que você solicite valores exclusivos a cada vez. **NÃO** copie os valores mostrados abaixo!

    Outputdefine('AUTH_KEY', '1jl/vqfs<XhdXoAPz9 NÃO COPIE ESSES VALORES c_j{iwqD^<+c9.k<J@4H');
    define('SECURE_AUTH_KEY', 'E2N-h2]Dcvp+aS/p7X NÃO COPIE ESSES VALORES {Ka(f;rv?Pxf})CgLi-3');
    define('LOGGED_IN_KEY', 'W(50,{W^,OPB%PB<JF NÃO COPIE ESSES VALORES 2;y&,2m%3]R6DUth[;88');
    define('NONCE_KEY', 'll,4UC)7ua+8<!4VM+ NÃO COPIE ESSES VALORES #`DXF+[$atzM7 o^-C7g');
    define('AUTH_SALT', 'koMrurzOA+|L_lG}kf NÃO COPIE ESSES VALORES 07VC*Lj*lD&?3w!BT#-');
    define('SECURE_AUTH_SALT', 'p32*p,]z%LZ+pAu:VY NÃO COPIE ESSES VALORES C-?y+K0DK_+F|0h{!_xY');
    define('LOGGED_IN_SALT', 'i^/G2W7!-1H2OQ+t$3 NÃO COPIE ESSES VALORES t6**bRVFSD[Hi])-qS`|');
    define('NONCE_SALT', 'Q6]U:K?j4L%Z]}h^q7 NÃO COPIE ESSES VALORES 1% ^qUswWgn+6&xqHN&%');

Essas são as linhas de configuração que podemos colar diretamente em nosso arquivo de configuração para configurar chaves seguras. Copie a saída que você recebeu agora.

Agora, abra o arquivo de configuração do WordPress:

    nano /var/www/html/wp-config.php

Localize a seção que contém os valores de modelo para essas configurações. Ela será parecido com isso:

/var/www/html/wp-config.php

    . . .
    
    define('AUTH_KEY', 'put your unique phrase here');
    define('SECURE_AUTH_KEY', 'put your unique phrase here');
    define('LOGGED_IN_KEY', 'put your unique phrase here');
    define('NONCE_KEY', 'put your unique phrase here');
    define('AUTH_SALT', 'put your unique phrase here');
    define('SECURE_AUTH_SALT', 'put your unique phrase here');
    define('LOGGED_IN_SALT', 'put your unique phrase here');
    define('NONCE_SALT', 'put your unique phrase here');
    
    . . .

Delete aquelas linhas e cole os valores que você copiou da linha de comandos:

    {label /var/www/html/wp-config.php]
    . . .
    
    define('AUTH_KEY', 'VALORES COPIADOS DO PROMPT DE COMANDOS');
    define('SECURE_AUTH_KEY', 'VALORES COPIADOS DO PROMPT DE COMANDOS');
    define('LOGGED_IN_KEY', 'VALORES COPIADOS DO PROMPT DE COMANDOS');
    define('NONCE_KEY', 'VALORES COPIADOS DO PROMPT DE COMANDOS');
    define('AUTH_SALT', 'VALORES COPIADOS DO PROMPT DE COMANDOS');
    define('SECURE_AUTH_SALT', 'VALORES COPIADOS DO PROMPT DE COMANDOS');
    define('LOGGED_IN_SALT', 'VALORES COPIADOS DO PROMPT DE COMANDOS');
    define('NONCE_SALT', 'VALORES COPIADOS DO PROMPT DE COMANDOS');
    
    . . .

A seguir, precisamos modificar algumas configurações de conexão ao banco de dados no início do arquivo. Você precisa ajustar o nome do banco de dados, o usuário do banco de dados, e a senha associada que configuramos dentro do MySQL.

A outra alteração que precisamos fazer é definir o método que o WordPress deve usar para gravar no sistema de arquivos. Como demos permissão ao servidor web para gravar onde ele precisa, podemos definir explicitamente o método do sistema de arquivos para “direct”. Uma falha ao definir isso em nossas configurações atuais resultaria no WordPress solicitando credenciais de FTP quando realizarmos algumas ações.

Essa configuração pode ser adicionada abaixo das configurações de conexão do banco de dados ou em qualquer outro lugar do arquivo:

/var/www/html/wp-config.php

    . . .
    
    define('DB_NAME', 'wordpress');
    
    /** MySQL database username */
    define('DB_USER', 'wordpressuser');
    
    /** MySQL database password */
    define('DB_PASSWORD', 'password');
    
    . . .
    
    define('FS_METHOD', 'direct');

Salve e feche o arquivo quando tiver terminado.

## Passo 6: Completar a Instalação Através da Interface Web

Agora que a configuração do servidor está finalizada, podemos completar a instalação através da interface web.

Em seu navegador, vá até o nome de domínio ou endereço IP do servidor:

    http://domínio_do_servidor_ou_IP

Selecione a linguagem que você gosta de usar:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/language_selection.png)

Em seguida, você virá para a página de configuração principal.

Escolha um nome para seu site WordPress e um nome de usuário (por motivos de segurança não escolha algo do tipo “admin”). Uma senha forte é gerada automaticamente. Salve essa senha ou selecione uma alternativa de senha forte.

Digite seu endereço de e-mail e selecione se deseja desestimular os mecanismos de pesquisa para indexar seu site:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/setup_installation.png)

Quando você clica para avançar, você será levado para uma página que solicita que você faça login:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/login_prompt.png)

Depois de fazer o login, você será levado para o painel de administração do WordPress:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_lamp_1604/admin_screen.png)

## Atualizando o WordPress

À medida que as atualizações do WordPress fiquem disponíveis, você não poderá instalá-las através da interface com as permissões atuais.

As permissões que selecionamos aqui são destinadas a fornecer um bom equilíbrio entre segurança e usabilidade para cerca de 99% de vezes entre as atualizações. No entanto, eles são um pouco restritivos demais para que o software aplique automaticamente as atualizações.

Quando uma atualização se torna disponível, acesse novamente seu servidor como usuário do `sudo`. Temporariamente conceda ao processo do servidor web, acesso à pasta raiz inteira.

    sudo chown -R www-data /var/www/html

Agora, volte ao painel de administração do WordPress e aplique a atualização.

Quando tiver terminado, bloqueie as permissões novamente para segurança.

    sudo chown -R sammy /var/www/html

Isso deve ser necessário apenas quando você estiver aplicando atualizações ao próprio WordPress.

## Conclusão

O WordPress deve estar instalado e pronto para uso! Alguns dos próximos passos seria escolher a configuração de permalink para seus posts (pode ser encontrado em `Settings > Permalinks`) ou selecionar um novo tema (em `Appearance > Themes`). Se esta é sua primeira vez usando o WordPress, explore a interface um pouco para se familiarizar com o seu novo CMS.
