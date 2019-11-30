---
author: Mark Drake
date: 2018-12-21
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-e-configurar-o-pgadmin-4-no-modo-servidor-pt
---

# Como Instalar e Configurar o pgAdmin 4 no Modo Servidor

### Introdução

O [pgAdmin](https://www.pgadmin.org/) é uma plataforma opensource de administração e desenvolvimento para PostgreSQL e seus sistemas de gerenciamento de banco de dados relacionados. Escrito em Python e jQuery, ele suporta todos os recursos encontrados no PostgreSQL. Você pode utilizar o pgAdmin para fazer tudo, desde escrever consultas SQL básicas a monitorar seus bancos de dados e configurar arquiteturas de banco de dados avançadas.

Neste tutorial, vamos passar pelo processo de instalação e configuração da versão mais recente do pgAdmin em um servidor Ubuntu 18.04, acessando o pgAdmin através de um navegador web, e conectando-o a um banco de dados PostgreSQL em seu servidor.

## Pré-requisitos

Para completar este tutorial, você vai precisar de:

- Um servidor executando Ubuntu 18.04. Este servidor deve ter um usuário não-root com privilégios sudo, bem como um firewall configurado com o `ufw`. Para uma ajuda em como configurar isto, siga nosso tutorial [Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt). 

- O servidor web Apache instalado em seu servidor. Siga nosso guia [How To Install the Apache Web Server on Ubuntu 18.04](how-to-install-the-apache-web-server-on-ubuntu-18-04) para configurar isso em sua máquina. 

- O PostgreSQL instalado em seu servidor. Você pode configurar isso seguindo nosso guia [How To Install and Use PostgreSQL on Ubuntu 18.04](how-to-install-and-use-postgresql-on-ubuntu-18-04). Ao seguir este guia, **certifique-se de criar uma nova função e um novo banco de dados** , pois você vai precisar de ambos para conectar o pgAdmin à sua instância do PostgreSQL.

- Python 3 e `venv` instalados em seu servidor. Siga o guia [How To Install Python 3 and Set Up a Programming Environment on an Ubuntu 18.04 server](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-18-04-server) para instalar essas ferramentas e configurar um ambiente virtual.

## Passo 1 — Instalando o pgAdmin e suas Dependências

No momento da escrita desse tutorial, a versão mais recente do pgAdmin é a pgAdmin 4, enquanto a versão mais recente disponível através dos repositórios oficiais do Ubuntu é a pgAdmin 3. O pgAdmin 3 já não é suportado, e os mantenedores do projeto recomendam a instalação do pgAdmin 4. Neste passo, vamos passar pelo processo de instalação da versão mais recente do pgAdmin 4 dentro de um ambiente virtual (conforme recomendado pelo time de desenvolvimento do projeto) e pela instalação de suas dependências usando o `apt`.

Para começar, atualize o índice de pacotes do seu servidor, se você não tiver feito isso recentemente:

    sudo apt update

Em seguida, instale as seguintes dependências. Elas incluem a `libgmp3-dev`, uma biblioteca aritmética multiprecisão; `libpq-dev`,que inclui arquivos de cabeçalho e uma biblioteca estática que ajuda na comunicação com o backend do PostgreSQL; e `libapache2-mod-wsgi-py3`, um módulo do Apache que lhe permite hospedar aplicações web baseadas em Python dentro do Apache:

    sudo apt install libgmp3-dev libpq-dev libapache2-mod-wsgi-py3

Em seguida, crie alguns diretórios nos quais o pgAdmin armazenará seus dados de sessões, dados de armazenamento e logs:

    sudo mkdir -p /var/lib/pgadmin4/sessions
    sudo mkdir /var/lib/pgadmin4/storage
    sudo mkdir /var/log/pgadmin4

Depois, altere a propriedade desses diretórios para seu usuário e grupo não-root. Isto é necessário porque eles são de propriedade do usuário **root** , mas vamos instalar o pgAdmin em um ambiente virtual que pertence ao seu usuário não-root, e o processo de instalação envolve a criação de alguns arquivos dentro desses diretórios. Após a instalação, contudo, vamos alterar a propriedade para o usuário e grupo **www-data** para que ele possa ser servido via web:

    sudo chown -R sammy:sammy /var/lib/pgadmin4
    sudo chown -R sammy:sammy /var/log/pgadmin4

A seguir, abra o seu ambiente virtual. Navegue até o diretório onde está o seu ambiente virtual e ative-o. Seguindo a convenção de nomes do [prerequisite Python 3 tutorial](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-18-04-server), vamos até o diretório `environments` e ativamos o ambiente `my_env`.

    cd environments/
    source my_env/bin/activate

Depois disso, faça o download do código-fonte do pgAdmin4 em sua máquina. Para encontrar a última versão do código-fonte, navegue até [a página de download do pgAdmin 4 (Python Wheel)](https://www.pgadmin.org/download/pgadmin-4-python-wheel/) e clique no link da última versão (3.4, no momento da escrita desse texto). Isso o levará para uma página de **Downloads** no website do PostgreSQL. Estando lá, copie o link de arquivo que termina com `.whl` — o formato de pacote padrão de construção utilizado para as distribuições Python. Volte então ao seu terminal e execute o seguinte comando `wget`, certificando-se de substituir o link por aquele que você copiou do website do PostgreSQL, que fará o download do arquivo `.whl` para seu servidor:

    wget https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v3.4/pip/pgadmin4-3.4-py2.py3-none-any.whl

Após isso, instale o pacote `wheel`, a implementação de referência do padrão de empacotamento wheel. Uma biblioteca Python, este pacote serve como uma extensão para a construção de wheels e inclui uma ferramenta de linha de comando para trabalhar com arquivos `.whl`:

    python -m pip install wheel

Então, instale o pacote pgAdmin com o seguinte comando:

    python -m pip install pgadmin4-3.4-py2.py3-none-any.whl 

Isso cuida da instalação do pgAdmin e suas dependências. Antes de conectá-lo ao seu banco de dados, no entanto, você precisará fazer algumas alterações na configuração do programa.

## Passo 2 — Configurando o pgAdmin 4

Embora o pgAdmin tenha sido instalado em seu servidor, existem ainda algumas etapas que você deve seguir para garantir que ele tenha as permissões e as configurações necessárias para permiti-lo servir corretamente a interface web.

O arquivo principal de configuração do pgAdmin, `config.py`, é lido antes de qualquer outro arquivo de configuração. Seu conteúdo pode ser utilizado como um ponto de referência para outras configurações que podem ser especificadas nos outros arquivos de configuração do pgAdmin, mas para evitar erros imprevistos, você não deve editar o próprio arquivo `config.py`. Iremos adicionar algumas alterações de configuração em um novo arquivo, chamado `config_local.py`, que será lido depois do primeiro.

Crie este arquivo agora utilizando seu editor de textos preferido. Aqui, vamos utilizar o `nano`:

    nano my_env/lib/python3.6/site-packages/pgadmin4/config_local.py

Em seu editor de textos, adicione o seguinte conteúdo:

environments/my\_env/lib/python3.6/site-packages/pgadmin4/config\_local.py

    
    LOG_FILE = '/var/log/pgadmin4/pgadmin4.log'
    SQLITE_PATH = '/var/lib/pgadmin4/pgadmin4.db'
    SESSION_DB_PATH = '/var/lib/pgadmin4/sessions'
    STORAGE_DIR = '/var/lib/pgadmin4/storage'
    SERVER_MODE = True

Aqui está o que estas cinco diretivas fazem:

- `LOG_FILE`: isso define o arquivo no qual os logs do pgAdmin serão armazenados.

- `SQLITE_PATH`: o pgAdmin armazena dados relacionados ao usuário em um banco de dados SQLite, e essa diretiva aponta o software pgAdmin para esse banco de dados de configuração. Como este arquivo está sob o diretório persistente `/var/lib/pgadmin4/`, seus dados de usuário não serão perdidos após a atualização.

- `SESSION_DB_PATH`: especifica qual diretório será usado para armazenar dados da sessão.

- `STORAGE_DIR`: define onde o pgAdmin armazenará outros dados, como backups e certificados de segurança.

- `SERVER_MODE`: definir esta diretiva como `True` diz ao pgAdmin para rodar no modo Servidor, ao contrário do modo Desktop.

Observe que cada um desses caminhos de arquivo aponta para os diretórios que você criou na Etapa 1.

Depois de adicionar essas linhas, salve e feche o arquivo (pressione `CTRL + X`, seguido de `Y` e depois `ENTER`). Com essas configurações, execute o script de configuração do pgAdmin para definir suas credenciais de login:

    python my_env/lib/python3.6/site-packages/pgadmin4/setup.py

Depois de executar este comando, você verá um prompt solicitando seu endereço de e-mail e uma senha. Estas serão as suas credenciais de login quando você acessar o pgAdmin mais tarde, então lembre-se ou anote o que você digitar aqui:

    Output. . .
    Enter the email address and password to use for the initial pgAdmin user account:
    
    Email address: sammy@example.com
    Password: 
    Retype password:

Em seguida, desative seu ambiente virtual:

    deactivate 

Lembre-se dos caminhos de arquivos que você especificou no arquivo `config_local.py`. Esses arquivos são mantidos nos diretórios criados na Etapa 1, que atualmente são de propriedade do seu usuário não-root. Eles devem, no entanto, ser acessíveis pelo usuário e pelo grupo que está executando o seu servidor web. Por padrão, no Ubuntu 18.04, estes são o usuário e grupo **www-data** , portanto, atualize as permissões nos seguintes diretórios para dar ao **www-data** a propriedade sobre os dois:

    sudo chown -R www-data:www-data /var/lib/pgadmin4/
    sudo chown -R www-data:www-data /var/log/pgadmin4/

Com isso, o pgAdmin está totalmente configurado. Contudo, o programa ainda não está sendo servido pelo seu servidor, então ele permanece inacessível. Para resolver isso, vamos configurar o Apache para servir o pgAdmin para que você possa acessar sua interface de usuário através de um navegador web.

## Passo 3 — Configurando o Apache

O servidor web Apache utiliza _virtual hosts_ para encpsular os detalhes de configuração e hospedar mais de um domínio a partir de um único servidor. Se você seguiu o tutorial de pré-requisitos do Apache, você pode ter configurado um exemplo de arquivo virtual host sob o nome `example.com.conf`, mas nesta etapa vamos criar um novo a partir do qual poderemos servir a interface web do pgAdmin.

Para começar, certifique-se de que você está no seu diretório raiz:

    cd /

Em seguida, crie um novo arquivo em seu diretório `/sites-available/` chamado `pgadmin4.conf`. Este será o arquivo de virtual host do seu servidor:

    sudo nano /etc/apache2/sites-available/pgadmin4.conf

Adicione o seguinte conteúdo a este arquivo, certificando-se de atualizar as partes destacadas para alinhar com sua própria configuração:

/etc/apache2/sites-available/pgadmin4.conf

    
    <VirtualHost *>
        ServerName ip_do_seu_servidor
    
        WSGIDaemonProcess pgadmin processes=1 threads=25 python-home=/home/sammy/environments/my_env
        WSGIScriptAlias / /home/sammy/environments/my_env/lib/python3.6/site-packages/pgadmin4/pgAdmin4.wsgi
    
        <Directory "/home/sammy/environments/my_env/lib/python3.6/site-packages/pgadmin4/">
            WSGIProcessGroup pgadmin
            WSGIApplicationGroup %{GLOBAL}
            Require all granted
        </Directory>
    </VirtualHost>

Salve e feche o arquivo de virtual host. Depois, utilize o script `a2dissite` para desativar o arquivo de virtual host padrão, `000-default.conf`:

    sudo a2dissite 000-default.conf

**Nota:** Se você seguiu o tutorial de pré-requisitos do Apache, você já pode ter desabilitado o `000-default.conf` e configurado um exemplo de arquivo de configuração do virtual host (chamado `example.com.conf` no pré-requisito). Se este for o caso, você precisará desabilitar o arquivo de virtual host `example.com.conf` com o seguinte comando:

    sudo a2dissite example.com.conf

Depois, use o script `a2ensite` para ativar seu arquivo de virtual host `pgadmin4.conf`. Isso irá criar um link simbólico do arquivo de virtual host no diretório `/sites-available/` para o diretório `/sites-enabled/`:

    sudo a2ensite pgadmin4.conf

Após isso, teste para ver se a sintaxe do seu arquivo de configuração está correta:

    apachectl configtest

Se seu arquivo de configuração estiver em ordem, você verá `Syntax OK`. Se você vir um erro na saída, reabra o arquivo `pgadmin4.conf` e verifique novamente se o seu endereço IP e os caminhos de arquivo estão corretos, em seguida execute novamente o `configtest`.

Quando você vir `Sintax OK` na sua saída, reinicie o serviço Apache para que ele leia o novo arquivo de virtual host:

    sudo systemctl restart apache2

Agora, o pgAdmin está totalmente instalado e configurado. A seguir, veremos como acessar o pgAdmin a partir de um navegador antes de conectá-lo ao seu banco de dados PostgreSQL.

## Passo 4 — Acessando o pgAdmin

Em sua máquina local, abra o seu navegador preferido e navegue até o endereço IP do seu servidor:

    http://ip_do_seu_servidor

Uma vez lá, você verá uma tela de login semelhante à seguinte:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/pgadmin_login_blank.png)

Insira as credenciais de login que você definiu no Passo 2, e você será levado para a Tela de Boas-vindas do pgAdmin:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/pgadmin_welcome_page_1.png)

Agora que você confirmou que pode acessar a interface do pgAdmin, tudo o que resta a fazer é conectar o pgAdmin ao seu banco de dados PostgreSQL. Antes de fazer isso, porém, você precisará fazer uma pequena alteração na configuração do superusuário do PostgreSQL.

## Passo 5 — Configurando seu usuário do PostgreSQL

Se você seguiu o [tutorial de pré-requisitos do PostgreSQL](how-to-install-and-use-postgresql-on-ubuntu-18-04), você já deve ter o PostgreSQL instalado em seu servidor com uma nova função de superusuário e uma configuração de banco de dados.

Por padrão no PostgreSQL, você autentica como usuário do banco de dados usando o método de autenticação “Protocolo de Identificação”, ou “ident”. Isso envolve o PostgreSQL utilizar o nome de usuário do Ubuntu do cliente e usá-lo como o nome de usuário permitido do banco de dados. Isso pode permitir maior segurança em muitos casos, mas também pode causar problemas nos casos em que você deseja que um programa externo, como o pgAdmin, se conecte a um dos seus bancos de dados. Para resolver isso, vamos definir uma senha para esta função do PostgreSQL que permitirá ao pgAdmin se conectar ao seu banco de dados.

A partir do seu terminal, abra o prompt do PostgreSQL sob sua função de superusuário:

    sudo -u sammy psql

A partir do prompt do PostgreSQL, atualize o perfil do usuário para ter uma senha forte de sua escolha:

    ALTER USER sammy PASSWORD 'senha';

Agora, saia do prompt do PostgreSQL:

    \q

Em seguida, volte para a interface do pgAdmin 4 em seu navegador e localize o menu **Browser** no lado esquerdo. Clique com o botão direito do mouse em **Servers** para abrir um menu de contexto, passe o mouse sobre **Create** e clique em **Server…**.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/create_server_box_resized.png)

Isso fará com que uma janela apareça no seu navegador, na qual você inserirá informações sobre seu servidor, função e banco de dados.

Na guia **General** , digite o nome para esse servidor. Isso pode ser qualquer coisa que você queira, mas talvez seja útil fazer algo descritivo. Em nosso exemplo, o servidor é chamado `Sammy-server-1`.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/server_general_tab_resized.png)

A seguir, clique na aba **Connection**. No campo **Host name/address** , insira `localhost`. **Port** deve ser definida para `5432` por padrão, o que irá funcionar para essa configuração, pois é a porta padrão utilizada pelo PostgreSQL. Observe que esse banco de dados já deve estar criado em seu servidor.

No campo **Maintenance database** , insira o nome do banco de dados ao qual você gostaria de se conectar. Em seguida, insira o nome de usuário e a senha do PostgreSQL que você configurou anteriormente nos campos **Username** e **Password** , respectivamente.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/connection_tab_resized.png)

Os campos vazios nas outras guias são opcionais, e é necessário preenchê-los apenas se você tiver uma configuração específica em mente na qual eles sejam necessários. Clique no botão **Save** e o banco de dados aparecerá sob **Servers** no menu **Browser**.

Você conectou com sucesso o pgAdmin4 ao seu banco de dados PostgreSQL. Você pode fazer praticamente qualquer coisa no painel do pgAdmin que você faria no prompt do PostgreSQL. Para ilustrar isso, vamos criar uma tabela de exemplo e preenchê-la com alguns dados de amostra através da interface web.

## Passo 6 — Criando uma Tabela no Painel do pgAdmin

No painel do pgAdmin, localize o menu **Browser** no lado esquerdo da janela. Clique no sinal de mais (+) próximo de **Servers (1)** para expandir o menu em árvore dentro dele. Em seguida, clique no sinal de mais à esquerda do servidor que você adicionou na etapa anterior ( **Sammy-server-1** em nosso exemplo), depois expanda **Databases** , o nome do banco de dados que você adicionou ( **sammy** , em nosso exemplo), e então **Schemas (1)**. Você deve ver um menu em árvore como o seguinte:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/table_tree_menu_resized.png)

Clique com o botão direito do mouse no item **Tables** da lista , depois passe o cursor sobre **Create** e clique em **Table…**.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/create_table_resized.png)

Isso abrirá uma janela **Create-Table**. Sob a guia **General** dessa janela, insira um nome para a tabela. Isso pode ser qualquer coisa que você quiser, mas para manter as coisas simples, vamos nos referir a ela como **table-01**.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/create_table_general_tab_1.png)

Em seguida, navegue até a guia **Columns** e clique no sinal de + no canto superior direito da janela para adicionar algumas colunas. Ao adicionar uma coluna, você deve fornecer um **Name** ou nome e um **Data type** ou tipo de dados, e você pode precisar escolher um **Length** ou comprimento se for exigido pelo tipo de dados que você selecionou.

Além disso, a [documentação oficial do PostgreSQL](https://www.postgresql.org/docs/9.1/static/ddl-constraints.html#AEN2520) afirma que adicionar uma chave primária ou _primary key_ a uma tabela geralmente é a melhor prática. Uma _chave primária_ é uma restrição que indica uma coluna específica ou conjunto de colunas que podem ser usadas como um identificador especial para linhas na tabela. Isso não é um requisito, mas se você quiser definir uma ou mais de suas colunas como a chave primária, alterne o botão mais à direita de **No** para **Yes**.

Clique no botão **Save** para criar a tabela.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/create_table_add_column_1primkey.png)

Nesse ponto, você criou uma tabela e adicionou algumas colunas a ela. No entanto, as colunas ainda não contêm dados. Para adicionar dados à sua nova tabela, clique com o botão direito do mouse no nome da tabela no menu **Browser** , passe o cursor sobre **Scripts** e clique em **INSERT Script**.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/insert_script_context_menu.png)

Isso abrirá uma nova tela no painel. No topo, você verá uma instrução `INSERT` parcialmente completa, com os nomes de tabela e coluna apropriados. Vá em frente e substitua os pontos de interrogação (?) por alguns dados fictícios, certificando-se de que os dados adicionados se alinham aos tipos de dados selecionados para cada coluna. Observe que você também pode adicionar várias linhas de dados através da adição de cada linha em um novo conjunto de parênteses, com cada conjunto de parênteses separados por uma vírgula, conforme mostrado no exemplo a seguir.

Se desejar, sinta-se à vontade para substituir o script `INSERT` parcialmente concluído com este exemplo de comando `INSERT`:

    INSERT INTO public."table-01"(
        col1, col2, col3)
        VALUES ('Juneau', 14, 337), ('Bismark', 90, 2334), ('Lansing', 51, 556);

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/insert_script.png)

Clique no ícone do raio (⚡) para executar o comando `INSERT`. Para visualizar a tabela e todos os dados nela, clique mais uma vez com o botão direito do mouse no nome da sua tabela no menu **Browser** , passe o cursor sobre **View/Edit Data** e selecione **All Rows**.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/view_edit_data_all_rows.png)

Isso abrirá outro novo painel, abaixo do qual, na guia **Data Output** do painel inferior, você pode ver todos os dados contidos nessa tabela.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/pgadmin/view_data_output.png)

Com isso, você criou com sucesso uma tabela e a preencheu com alguns dados por meio da interface web do pgAdmin. Claro, este é apenas um método que você pode usar para criar uma tabela através do pgAdmin. Por exemplo, é possível criar e preencher uma tabela usando SQL em vez do método baseado em GUI descrito nesta etapa.

## Conclusão

Neste guia, você aprendeu como instalar o pgAdmin 4 a partir de um ambiente virtual Python, configurá-lo, servi-lo via web com o Apache e como conectá-lo a um banco de dados PostgreSQL. Além disso, este guia abordou um método que pode ser usado para criar e preencher uma tabela, mas o pgAdmin pode ser usado para muito mais do que apenas criar e editar tabelas.

Para obter mais informações sobre como aproveitar ao máximo todos os recursos do pgAdmin, recomendamos que você veja a [documentação do projeto](https://www.pgadmin.org/docs/pgadmin4/3.x/). Você também pode aprender mais sobre o PostgreSQL através dos nossos [Tutoriais da comunidade](https://www.digitalocean.com/community/tags/postgresql?type=tutorials) que abordam o assunto.

_Por Mark Drake_
