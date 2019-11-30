---
author: Brian Boucheron, Mark Drake
date: 2019-09-10
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-configurar-um-banco-de-dados-remoto-para-otimizar-o-desempenho-do-site-com-o-mysql-no-ubuntu-18-04-pt
---

# Como Configurar um Banco de Dados Remoto para Otimizar o Desempenho do Site com o MySQL no Ubuntu 18.04

### Introdução

À medida que sua aplicação ou site cresce, pode chegar um momento em que você superou a configuração atual do seu servidor. Se você estiver hospedando o seu servidor web e o back-end do banco de dados na mesma máquina, pode ser uma boa ideia separar essas duas funções para que cada uma possa operar em seu próprio hardware e compartilhar a carga de responder às solicitações dos visitantes.

Neste guia, veremos como configurar um servidor de banco de dados MySQL remoto ao qual sua aplicação web pode se conectar. Usaremos o WordPress como exemplo para ter algo para trabalhar, mas a técnica é amplamente aplicável a qualquer aplicação suportada pelo MySQL.

## Pré-requisitos

Antes de iniciar este tutorial, você precisará de:

- Dois servidores Ubuntu 18.04. Cada um deles deve ter um usuário não-root com privilégios sudo e um firewall UFW habilitado, conforme descrito em nosso tutorial de [Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt). Um desses servidores hospedará seu back-end MySQL e, ao longo deste guia, o chamaremos de **servidor de banco de dados**. O outro se conectará ao seu servidor de banco de dados remotamente e atuará como seu servidor web; da mesma forma, iremos nos referir a ele como **servidor web** ao longo deste guia.
- Nginx e PHP instalado em seu **servidor web**. Nosso tutorial [How To Install Linux, Nginx, MySQL, PHP (LEMP stack) in Ubuntu 18.04](how-to-install-linux-nginx-mysql-php-lemp-stack-ubuntu-18-04) o guiará no processo, mas observe que você deve pular o Passo 2 deste tutorial, que se concentra na instalação do MySQL, pois você instalará o MySQL no seu servidor de banco de dados.
- MySQL instalado em seu **servidor de banco de dados**. Siga o tutorial [Como Instalar o MySQL no Ubuntu 18.04](como-instalar-o-mysql-no-ubuntu-18-04-pt) para configurar isso.
- Opcionalmente (mas altamente recomendado), certificados TLS/SSL da Let’s Encrypt instalados em seu **servidor web**. Você precisará comprar um nome de domínio e ter [registros DNS configurados para seu servidor](https://www.digitalocean.com/docs/networking/dns/), mas os certificados em si são gratuitos. Nosso guia [Como Proteger o Nginx com o Let’s Encrypt no Ubuntu 18.04](como-proteger-o-nginx-com-o-let-s-encrypt-no-ubuntu-18-04-pt) lhe mostrará como obter esses certificados.

## Passo 1 — Configurando o MySQL para Escutar Conexões Remotas

Ter os dados armazenados em um servidor separado é uma boa maneira de expandir elegantemente após atingir o limite máximo de desempenho de uma configuração de uma única máquina. Ela também fornece a estrutura básica necessária para balancear a carga e expandir sua infraestrutura ainda mais posteriormente. Após instalar o MySQL, seguindo o tutorial de pré-requisitos, você precisará alterar alguns valores de configuração para permitir conexões a partir de outros computadores.

A maioria das mudanças na configuração do servidor MySQL pode ser feita no arquivo `mysqld.cnf`, que é armazenado no diretório `/etc/mysql/mysql.conf.d/` por padrão. Abra este arquivo em seu **servidor de banco de dados** com privilégios de root em seu editor preferido. Aqui, iremos usar o `nano`:

    sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

Este arquivo é dividido em seções indicadas por labels entre colchetes (`[` e `]`). Encontre a seção com o label `mysqld`:

/etc/mysql/mysql.conf.d/mysqld.cnf

    . . .
    [mysqld]
    . . .

Nesta seção, procure um parâmetro chamado `bind-address`. Isso informa ao software do banco de dados em qual endereço de rede escutar as conexões.

Por padrão, isso está definido como `127.0.0.1`, significando que o MySQL está configurado para escutar apenas conexões locais. Você precisa alterar isso para fazer referência a um endereço IP _externo_ onde seu servidor pode ser acessado.

Se os dois servidores estiverem em um datacenter com recursos de rede privada, use o IP da rede privada do seu servidor de banco de dados. Caso contrário, você pode usar seu endereço IP público:

/etc/mysql/mysql.conf.d/mysqld.cnf

    [mysqld]
    . . .
    bind-address = ip_do_servidor_de_banco_de_dados

Como você se conectará ao seu banco de dados pela Internet, é recomendável que você exija conexões criptografadas para manter seus dados seguros. Se você não criptografar sua conexão MySQL, qualquer pessoa na rede poderá [fazer sniff](https://en.wikipedia.org/wiki/Sniffing_attack) por informações confidenciais entre seus servidores web e de banco de dados. Para criptografar conexões MySQL, adicione a seguinte linha após a linha `bind-address` que você acabou de atualizar:

/etc/mysql/mysql.conf.d/mysqld.cnf

    [mysqld]
    . . .
    require_secure_transport = on
    . . .

Salve e feche o arquivo quando terminar. Se você estiver usando `nano`, faça isso pressionando `CTRL+X`, `Y` e, em seguida, `ENTER`.

Para que as conexões SSL funcionem, você precisará criar algumas chaves e certificados. O MySQL vem com um comando que os configura automaticamente. Execute o seguinte comando, que cria os arquivos necessários. Ele também os torna legíveis pelo servidor MySQL, especificando o UID do usuário **mysql** :

    sudo mysql_ssl_rsa_setup --uid=mysql

Para forçar o MySQL a atualizar sua configuração e ler as novas informações de SSL, reinicie o banco de dados:

    sudo systemctl restart mysql

Para confirmar que o servidor agora está escutando na interface externa, execute o seguinte comando `netstat`:

    sudo netstat -plunt | grep mysqld

    Outputtcp 0 0 ip_do_servidor_de_banco_de_dados:3306 0.0.0.0:* LISTEN 27328/mysqld

O `netstat` imprime estatísticas sobre o sistema de rede do seu servidor. Esta saída nos mostra que um processo chamado `mysqld` está anexado ao `ip_do_servidor_de_banco_de_dados` na porta `3306`, a porta padrão do MySQL, confirmando que o servidor está escutando na interface apropriada.

Em seguida, abra essa porta no firewall para permitir o tráfego através dela:

    sudo ufw allow mysql

Essas são todas as alterações de configuração que você precisa fazer no MySQL. A seguir, veremos como configurar um banco de dados e alguns perfis de usuário, um dos quais você usará para acessar o servidor remotamente.

## Passo 2 — Configurando um Banco de Dados para o WordPress e Credenciais Remotas

Embora o próprio MySQL agora esteja escutando em um endereço IP externo, atualmente não há usuários ou bancos de dados habilitados para controle remoto configurados. Vamos criar um banco de dados para o WordPress e um par de usuários que possam acessá-lo.

Comece conectando-se ao MySQL como o usuário **root** do MySQL:

    sudo mysql

**Nota:** Se você tiver a autenticação por senha ativada, conforme descrito no [Passo 3 do pré-requisito do tutorial do MySQL](como-instalar-o-mysql-no-ubuntu-18-04-pt), você precisará usar o seguinte comando para acessar o shell do MySQL:

    mysql -u root -p

Depois de executar este comando, você será solicitado a fornecer sua senha de **root** do MySQL e, após inseri-la, receberá um novo prompt `mysql>`.

No prompt do MySQL, crie um banco de dados que o WordPress usará. Pode ser útil atribuir a esse banco de dados um nome reconhecível para que você possa identificá-lo facilmente mais tarde. Aqui, vamos chamá-lo de `wordpress`:

    CREATE DATABASE wordpress;

Agora que você criou seu banco de dados, você precisará criar um par de usuários. Criaremos um usuário somente local e um usuário remoto vinculado ao endereço IP do servidor web.

Primeiro, crie seu usuário local, **wpuser** , e faça com que esta conta corresponda apenas às tentativas de conexão local usando **localhost** na declaração:

    CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'senha';

Em seguida, conceda a esta conta acesso total ao banco de dados `wordpress`:

    GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';

Agora, esse usuário pode executar qualquer operação no banco de dados do WordPress, mas essa conta não pode ser usada remotamente, pois corresponde apenas às conexões da máquina local. Com isso em mente, crie uma conta complementar que corresponda às conexões exclusivamente do seu servidor web. Para isso, você precisará do endereço IP do seu servidor web.

Observe que você deve usar um endereço IP que utilize a mesma rede que você configurou no seu arquivo `mysqld.cnf`. Isso significa que, se você especificou um IP de rede privada no arquivo `mysqld.cnf`, precisará incluir o IP privado do seu servidor web nos dois comandos a seguir. Se você configurou o MySQL para usar a internet pública, você deve fazer isso corresponder ao endereço IP público do servidor web.

    CREATE USER 'remotewpuser'@'ip_do_servidor_web' IDENTIFIED BY 'senha';

Depois de criar sua conta remota, conceda a ela os mesmos privilégios que o usuário local:

    GRANT ALL PRIVILEGES ON wordpress.* TO 'remotewpuser'@'ip_do_servidor_web';

Por fim, atualize os privilégios para que o MySQL saiba começar a usá-los:

    FLUSH PRIVILEGES;

Então saia do prompt do MySQL digitando:

    exit

Agora que você configurou um novo banco de dados e um usuário habilitado remotamente, você pode testar se consegue se conectar ao banco de dados a partir do seu servidor web.

## Passo 3 — Testando Conexões Remotas e Locais

Antes de continuar, é melhor verificar se você pode se conectar ao seu banco de dados tanto a partir da máquina local — seu servidor de banco de dados — quanto pelo seu servidor web.

Primeiro, teste a conexão local a partir do seu **servidor de banco de dados** tentando fazer login com sua nova conta:

    mysql -u wpuser -p

Quando solicitado, digite a senha que você configurou para esta conta.

Se você receber um prompt do MySQL, então a conexão local foi bem-sucedida. Você pode sair novamente digitando:

    exit

Em seguida, faça login no seu **servidor web** para testar as conexões remotas:

    ssh sammy@ip_do_servidor_web

Você precisará instalar algumas ferramentas de cliente para MySQL em seu servidor web para acessar o banco de dados remoto. Primeiro, atualize o cache de pacotes local se você não tiver feito isso recentemente:

    sudo apt update

Em seguida, instale os utilitários de cliente do MySQL:

    sudo apt install mysql-client

Depois disso, conecte-se ao seu servidor de banco de dados usando a seguinte sintaxe:

    mysql -u remotewpuser -h ip_do_servidor_de_banco_de_dados -p

Novamente, você deve certificar-se que está usando o endereço IP correto para o servidor de banco de dados. Se você configurou o MySQL para escutar na rede privada, digite o IP da rede privada do seu banco de dados. Caso contrário, digite o endereço IP público do seu servidor de banco de dados.

Você será solicitado a inserir a senha da sua conta **remotewpuser**. Depois de inseri-la, e se tudo estiver funcionando conforme o esperado, você verá o prompt do MySQL. Verifique se a conexão está usando SSL com o seguinte comando:

    status

Se a conexão realmente estiver usando SSL, a linha `SSL:` indicará isso, como mostrado aqui:

    Output--------------
    mysql Ver 14.14 Distrib 5.7.18, for Linux (x86_64) using EditLine wrapper
    
    Connection id: 52
    Current database:
    Current user: remotewpuser@203.0.113.111
    SSL: Cipher in use is DHE-RSA-AES256-SHA
    Current pager: stdout
    Using outfile: ''
    Using delimiter: ;
    Server version: 5.7.18-0ubuntu0.16.04.1 (Ubuntu)
    Protocol version: 10
    Connection: 203.0.113.111 via TCP/IP
    Server characterset: latin1
    Db characterset: latin1
    Client characterset: utf8
    Conn. characterset: utf8
    TCP port: 3306
    Uptime: 3 hours 43 min 40 sec
    
    Threads: 1 Questions: 1858 Slow queries: 0 Opens: 276 Flush tables: 1 Open tables: 184 Queries per second avg: 0.138
    --------------

Depois de verificar que você pode se conectar remotamente, vá em frente e saia do prompt:

    exit

Com isso, você verificou o acesso local e o acesso a partir do servidor web, mas não verificou se outras conexões serão recusadas. Para uma verificação adicional, tente fazer o mesmo em um terceiro servidor para o qual você _não_ configurou uma conta de usuário específica para garantir que esse outro servidor _não_ tenha o acesso concedido.

Observe que antes de executar o seguinte comando para tentar a conexão, talvez seja necessário instalar os utilitários de cliente do MySQL, como você fez acima:

    mysql -u wordpressuser -h ip_do_servidor_de_banco_de_dados -p

Isso não deve ser concluído com êxito e deve gerar um erro semelhante a este:

    OutputERROR 1130 (HY000): Host '203.0.113.12' is not allowed to connect to this MySQL server

Isso é esperado, já que você não criou um usuário do MySQL que tem permissão para se conectar a partir deste servidor, e também é desejado, uma vez que você quer ter certeza de que seu servidor de banco de dados negará o acesso de usuários não autorizados ao seu servidor do MySQL.

Após testar com êxito sua conexão remota, você pode instalar o WordPress em seu servidor web.

## Passo 4 — Instalando o WordPress

Para demonstrar os recursos do seu novo servidor MySQL com capacidade remota, passaremos pelo processo de instalação e configuração do WordPress — o popular sistema de gerenciamento de conteúdo — em seu servidor web. Isso exigirá que você baixe e extraia o software, configure suas informações de conexão e então execute a instalação baseada em web do WordPress.

No seu **servidor web** , faça o download da versão mais recente do WordPress para o seu diretório home:

    cd ~
    curl -O https://wordpress.org/latest.tar.gz

Extraia os arquivos, que criarão um diretório chamado `wordpress` no seu diretório home:

    tar xzvf latest.tar.gz

O WordPress inclui um arquivo de configuração de exemplo que usaremos como ponto de partida. Faça uma cópia deste arquivo, removendo `-sample` do nome do arquivo para que ele seja carregado pelo WordPress:

    cp ~/wordpress/wp-config-sample.php ~/wordpress/wp-config.php

Quando você abre o arquivo, sua primeira abordagem será ajustar algumas chaves secretas para fornecer mais segurança à sua instalação. O WordPress fornece um gerador seguro para esses valores, para que você não precise criar bons valores por conta própria. Eles são usados apenas internamente, portanto, não prejudicará a usabilidade ter valores complexos e seguros aqui.

Para obter valores seguros do gerador de chave secreta do WordPress, digite:

    curl -s https://api.wordpress.org/secret-key/1.1/salt/

Isso imprimirá algumas chaves na sua saída. Você as adicionará momentaneamente ao seu arquivo `wp-config.php`:

**Atenção!** É importante que você solicite seus próprios valores únicos sempre. **Não** copie os valores mostrados aqui!

    Outputdefine('AUTH_KEY', 'L4|2Yh(giOtMLHg3#] DO NOT COPY THESE VALUES %G00o|te^5YG@)');
    define('SECURE_AUTH_KEY', 'DCs-k+MwB90/-E(=!/ DO NOT COPY THESE VALUES +WBzDq:7U[#Wn9');
    define('LOGGED_IN_KEY', '*0kP!|VS.K=;#fPMlO DO NOT COPY THESE VALUES +&[%8xF*,18c @');
    define('NONCE_KEY', 'fmFPF?UJi&(j-{8=$- DO NOT COPY THESE VALUES CCZ?Q+_~1ZU~;G');
    define('AUTH_SALT', '@qA7f}2utTEFNdnbEa DO NOT COPY THESE VALUES t}Vw+8=K%20s=a');
    define('SECURE_AUTH_SALT', '%BW6s+d:7K?-`C%zw4 DO NOT COPY THESE VALUES 70U}PO1ejW+7|8');
    define('LOGGED_IN_SALT', '-l>F:-dbcWof%4kKmj DO NOT COPY THESE VALUES 8Ypslin3~d|wLD');
    define('NONCE_SALT', '4J(<`4&&F (WiK9K#] DO NOT COPY THESE VALUES ^ZikS`es#Fo:V6');

Copie a saída que você recebeu para a área de transferência e abra o arquivo de configuração no seu editor de texto:

    nano ~/wordpress/wp-config.php

Encontre a seção que contém os valores fictícios para essas configurações. Será algo parecido com isto:

/wordpress/wp-config.php

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

Exclua essas linhas e cole os valores que você copiou a partir da linha de comando.

Em seguida, insira as informações de conexão para seu banco de dados remoto. Essas linhas de configuração estão na parte superior do arquivo, logo acima de onde você colou suas chaves. Lembre-se de usar o mesmo endereço IP que você usou no teste de banco de dados remoto anteriormente:

/wordpress/wp-config.php

    . . .
    /** The name of the database for WordPress */
    define('DB_NAME', 'wordpress');
    
    /** MySQL database username */
    define('DB_USER', 'remotewpuser');
    
    /** MySQL database password */
    define('DB_PASSWORD', 'password');
    
    /** MySQL hostname */
    define('DB_HOST', 'db_server_ip');
    . . .

E, finalmente, em qualquer lugar do arquivo, adicione a seguinte linha que diz ao WordPress para usar uma conexão SSL para o nosso banco de dados MySQL:

/wordpress/wp-config.php

    define('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL);

Salve e feche o arquivo.

Em seguida, copie os arquivos e diretórios encontrados no diretório `~/wordpress` para a raiz de documentos do Nginx. Observe que este comando inclui a flag `-a` para garantir que todas as permissões existentes sejam transferidas:

    sudo cp -a ~/wordpress/* /var/www/html

Depois disso, a única coisa a fazer é modificar a propriedade do arquivo. Altere a propriedade de todos os arquivos na raiz de documentos para **www-data** , o usuário padrão do servidor web do Ubuntu:

    sudo chown -R www-data:www-data /var/www/html

Com isso, o WordPress está instalado e você está pronto para executar sua rotina de configuração baseada em web.

## Passo 5 — Configurando o Wordpress Através da Interface Web

O WordPress possui um processo de configuração baseado na web. Conforme você avança, ele fará algumas perguntas e instalará todas as tabelas necessárias no seu banco de dados. Aqui, abordaremos as etapas iniciais da configuração do WordPress, que você pode usar como ponto de partida para criar seu próprio site personalizado que usa um back-end de banco de dados remoto.

Navegue até o nome de domínio (ou endereço IP público) associado ao seu servidor web:

    http://example.com

Você verá uma tela de seleção de idioma para o instalador do WordPress. Selecione o idioma apropriado e clique na tela principal de instalação:

![WordPress install screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/remote-mysql-1804/wp-install-1804-small.png)

Depois de enviar suas informações, você precisará fazer login na interface de administração do WordPress usando a conta que você acabou de criar. Você será direcionado para um painel onde poderá personalizar seu novo site WordPress.

## Conclusão

Ao seguir este tutorial, você configurou um banco de dados MySQL para aceitar conexões protegidas por SSL a partir de uma instalação remota do Wordpress. Os comandos e técnicas usados neste guia são aplicáveis a qualquer aplicação web escrita em qualquer linguagem de programação, mas os detalhes específicos da implementação serão diferentes. Consulte a documentação do banco de dados da aplicação ou linguagem para obter mais informações.
