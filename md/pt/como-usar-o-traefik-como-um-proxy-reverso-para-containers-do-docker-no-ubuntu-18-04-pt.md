---
author: Keith Thompson
date: 2019-02-14
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-usar-o-traefik-como-um-proxy-reverso-para-containers-do-docker-no-ubuntu-18-04-pt
---

# Como Usar o Traefik como um Proxy Reverso para Containers do Docker no Ubuntu 18.04

_O autor selecionou o [Girls Who Code](https://www.brightfunds.org/organizations/girls-who-code) para receber uma doação como parte do programa [Write for DOnations](https://do.co/w4do-cta)._

### Introdução

O [Docker](https://www.docker.com/) pode ser uma maneira eficiente de executar aplicativos web em produção, mas você pode querer executar vários aplicativos no mesmo host do Docker. Nesta situação, você precisará configurar um proxy reverso, já que você só deseja expor as portas `80` e `443` para o resto do mundo.

O [Traefik](https://traefik.io/) é um proxy reverso que reconhece o Docker e inclui seu próprio painel de monitoramento ou dashboard. Neste tutorial, você usará o Traefik para rotear solicitações para dois containers de aplicação web diferentes: um container [Wordpress](http://wordpress.org/) e um container [Adminer](https://www.adminer.org/), cada um falando com um banco de dados [MySQL](https://www.mysql.com/). Você irá configurar o Traefik para servir tudo através de HTTPS utilizando o [Let’s Encrypt](https://letsencrypt.org/).

## Pré-requisitos

Para acompanhar este tutorial, você vai precisar do seguinte:

- Um servidor Ubuntu configurado seguindo [o guia de Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt), incluindo um usuário sudo não-root e um firewall.

- O Docker instalado em seu servidor, que você pode fazer seguindo o tutorial [Como Instalar e Usar o Docker no Ubuntu 18.04](como-instalar-e-usar-o-docker-no-ubuntu-18-04-pt). 

- Docker Compose instalado com as instruções de [How to Install Docker Compose on Ubuntu 18.04](how-to-install-docker-compose-on-ubuntu-18-04). 

- Um domínio e três registros A, `db-admin`, `blog` e `monitor`, onde cada um aponta para o endereço IP do seu servidor. Você pode aprender como apontar domínios para os Droplets da DigitalOcean lendo [a documentação sobre Domínios e DNS](https://www.digitalocean.com/docs/networking/dns/). Ao longo deste tutorial, substitua `seu_domínio` pelo seu nome de domínio nos arquivos e exemplos de configuração. 

## Passo 1 — Configurando e Executando o Traefik

O projeto do Traefik tem [uma imagem Docker oficial](https://hub.docker.com/_/traefik), portanto vamos utilizá-la para executar o Traefik em um container Docker.

Mas antes de colocarmos o nosso container Traefik em funcionamento, precisamos criar um arquivo de configuração e configurar uma senha criptografada para que possamos acessar o painel de monitoramento.

Usaremos o utilitário `htpasswd` para criar essa senha criptografada. Primeiro, instale o utilitário, que está incluído no pacote `apache2-utils`:

    sudo apt-get install apache2-utils

Em seguida, gere a senha com o `htpasswd`. Substitua `senha_segura` pela senha que você gostaria de usar para o usuário admin do Traefik:

    htpasswd -nb admin senha_segura

A saída do programa ficará assim:

    Outputadmin:$apr1$ruca84Hq$mbjdMZBAG.KWn7vfN/SNK/

Você utilizará essa saída no arquivo de configuração do Traefik para configurar a Autenticação Básica de HTTP para a verificação de integridade do Traefik e para o painel de monitoramento. Copie toda a linha de saída para poder colá-la mais tarde.

Para configurar o servidor Traefik, criaremos um novo arquivo de configuração chamado `traefik.toml` usando o formato TOML. O [TOML](https://github.com/toml-lang/toml) é uma linguagem de configuração semelhante ao arquivos INI, mas padronizado. Esse arquivo nos permite configurar o servidor Traefik e várias integrações, ou _providers_, que queremos usar. Neste tutorial, usaremos três dos provedores disponíveis do Traefik: `api`,`docker` e `acme`, que é usado para suportar o TLS utilizando o Let’s Encrypt.

Abra seu novo arquivo no `nano` ou no seu editor de textos favorito:

    nano traefik.toml

Primeiro, adicione dois EntryPoints nomeados `http` e`https`, que todos os backends terão acesso por padrão:

traefik.toml

    defaultEntryPoints = ["http", "https"]

Vamos configurar os EntryPoints `http` e `https` posteriormente neste arquivo.

Em seguida, configure o provider `api`, que lhe dá acesso a uma interface do painel. É aqui que você irá colar a saída do comando `htpasswd`:

traefik.toml

    
    ...
    [entryPoints]
      [entryPoints.dashboard]
        address = ":8080"
        [entryPoints.dashboard.auth]
          [entryPoints.dashboard.auth.basic]
            users = ["admin:sua_senha_criptografada"]
    
    [api]
    entrypoint="dashboard"

O painel é uma aplicação web separada que será executada no container do Traefik. Vamos definir o painel para executar na porta `8080`.

A seção `entrypoints.dashboard` configura como nos conectaremos com o provider da `api`, e a seção `entrypoints.dashboard.auth.basic` configura a Autenticação Básica HTTP para o painel. Use a saída do comando `htpasswd` que você acabou de executar para o valor da entrada `users`. Você poderia especificar logins adicionais, separando-os com vírgulas.

Definimos nosso primeiro `entryPoint`, mas precisaremos definir outros para comunicação HTTP e HTTPS padrão que não seja direcionada para o provider da `api`. A seção `entryPoints` configura os endereços que o Traefik e os containers com proxy podem escutar. Adicione estas linhas ao arquivo logo abaixo do cabeçalho `entryPoints`:

traefik.toml

    
    ...
      [entryPoints.http]
        address = ":80"
          [entryPoints.http.redirect]
            entryPoint = "https"
      [entryPoints.https]
        address = ":443"
          [entryPoints.https.tls]
    ...

O entrypoint `http` manipula a porta `80`, enquanto o entrypoint `https` usa a porta`443` para o TLS/SSL. Redirecionamos automaticamente todo o tráfego na porta `80` para o entrypoint `https` para forçar conexões seguras para todas as solicitações.

Em seguida, adicione esta seção para configurar o suporte ao certificado Let’s Encrypt do Traefik:

traefik.toml

    ...
    [acme]
    email = "seu_email@seu_domínio"
    storage = "acme.json"
    entryPoint = "https"
    onHostRule = true
      [acme.httpChallenge]
      entryPoint = "http"

Esta seção é chamada `acme` porque [ACME](https://github.com/ietf-wg-acme/acme/) é o nome do protocolo usado para se comunicar com o Let’s Encrypt para gerenciar certificados. O serviço Let’s Encrypt requer o registro com um endereço de e-mail válido, portanto, para que o Traefik gere certificados para nossos hosts, defina a chave `email` como seu endereço de e-mail. Em seguida, vamos especificar que armazenaremos as informações que vamos receber do Let’s Encrypt em um arquivo JSON chamado `acme.json`. A chave `entryPoint` precisa apontar para a porta de manipulação do entrypoint `443`, que no nosso caso é o entrypoint `https`.

A chave `onHostRule` determina como o Traefik deve gerar certificados. Queremos buscar nossos certificados assim que nossos containers com os nomes de host especificados forem criados, e é isso que a configuração `onHostRule` fará.

A seção `acme.httpChallenge` nos permite especificar como o Let’s Encrypt pode verificar se o certificado deve ser gerado. Estamos configurando-o para servir um arquivo como parte do desafio através do entrypoint `http`.

Finalmente, vamos configurar o provider `docker` adicionando estas linhas ao arquivo:

traefik.toml

    
    ...
    [docker]
    domain = "seu_domínio"
    watch = true
    network = "web"

O provedor `docker` permite que o Traefik atue como um proxy na frente dos containers do Docker. Configuramos o provider para vigiar ou `watch` por novos containers na rede `web` (que criaremos em breve) e os expor como subdomínios de `seu_domínio`.

Neste ponto, o `traefik.toml` deve ter o seguinte conteúdo:

traefik.toml

    defaultEntryPoints = ["http", "https"]
    
    [entryPoints]
      [entryPoints.dashboard]
        address = ":8080"
        [entryPoints.dashboard.auth]
          [entryPoints.dashboard.auth.basic]
            users = ["admin:sua_senha_criptografada"]
      [entryPoints.http]
        address = ":80"
          [entryPoints.http.redirect]
            entryPoint = "https"
      [entryPoints.https]
        address = ":443"
          [entryPoints.https.tls]
    
    [api]
    entrypoint="dashboard"
    
    [acme]
    email = "seu_email@seu_domínio"
    storage = "acme.json"
    entryPoint = "https"
    onHostRule = true
      [acme.httpChallenge]
      entryPoint = "http"
    
    [docker]
    domain = "seu_domínio"
    watch = true
    network = "web"

Salve o arquivo e saia do editor. Com toda essa configuração pronta, podemos ativar o Traefik.

## Passo 2 – Executando o Container Traefik

Em seguida, crie uma rede do Docker para o proxy compartilhar com os containers. A rede do Docker é necessária para que possamos usá-la com aplicações que são executadas usando o Docker Compose. Vamos chamar essa rede de `web`.

    docker network create web

Quando o container Traefik iniciar, nós o adicionaremos a essa rede. Em seguida, podemos adicionar containers adicionais a essa rede posteriormente para o Traefik fazer proxy.

Em seguida, crie um arquivo vazio que conterá as informações do Let’s Encrypt. Compartilharemos isso no container para que o Traefik possa usá-lo:

    touch acme.json

O Traefik só poderá usar esse arquivo se o usuário root dentro do container tiver acesso exclusivo de leitura e gravação a ele. Para fazer isso, bloqueie as permissões em `acme.json` para que somente o proprietário do arquivo tenha permissão de leitura e gravação.

    chmod 600 acme.json

Depois que o arquivo for repassado para o Docker, o proprietário será automaticamente alterado para o usuário root dentro do container.

Finalmente, crie o container Traefik com este comando:

    docker run -d \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v $PWD/traefik.toml:/traefik.toml \
      -v $PWD/acme.json:/acme.json \
      -p 80:80 \
      -p 443:443 \
      -l traefik.frontend.rule=Host:monitor.seu_domínio \
      -l traefik.port=8080 \
      --network web \
      --name traefik \
      traefik:1.7.2-alpine

O comando é um pouco longo, então vamos dividi-lo. Usamos a flag `-d` para executar o container em segundo plano como um daemon. Em seguida, compartilhamos nosso arquivo `docker.sock` dentro do container para que o processo do Traefik possa escutar por alterações nos containers. Compartilhamos também o arquivo de configuração `traefik.toml` e o arquivo`acme.json` que criamos dentro do container.

Em seguida, mapeamos as portas `:80` e `:443` do nosso host Docker para as mesmas portas no container Traefik, para que o Traefik receba todo o tráfego HTTP e HTTPS para o servidor.

Em seguida, configuramos dois labels do Docker que informam ao Traefik para direcionar o tráfego para o `monitor.seu_domínio` para a porta `:8080` dentro do container do Traefik, expondo o painel de monitoramento.

Configuramos a rede do container para `web`, e nomeamos o container para `traefik`.

Finalmente, usamos a imagem `traefik:1.7.2-alpine` para este container, porque é pequena.

Um `ENTRYPOINT` da imagem do Docker é um comando que sempre é executado quando um container é criado a partir da imagem. Neste caso, o comando é o binário `traefik` dentro do container. Você pode passar argumentos adicionais para esse comando quando você inicia o container, mas definimos todas as nossas configurações no arquivo `traefik.toml`.

Com o container iniciado, agora você tem um painel que você pode acessar para ver a integridade de seus containers. Você também pode usar este painel para visualizar os frontends e backends que o Traefik registrou. Acesse o painel de monitoramento apontando seu navegador para `https://monitor.seu_domínio`. Você será solicitado a fornecer seu nome de usuário e senha, que são admin e a senha que você configurou no Passo 1.

Uma vez logado, você verá uma interface semelhante a esta:

![](http://assets.digitalocean.com/articles/63957_Traefik/Empty_Traefik_dashboard.png)

Ainda não há muito o que ver, mas deixe essa janela aberta e você verá o conteúdo mudar à medida que você adiciona containers para o Traefik trabalhar.

Agora temos nosso proxy Traefik em execução, configurado para funcionar com o Docker, e pronto para monitorar outros containers Docker. Vamos iniciar alguns containers para que o Traefik possa agir como proxy para eles.

## Passo 3 — Registrando Containers com o Traefik

Com o container do Traefik em execução, você está pronto para executar aplicações por trás dele. Vamos lançar os seguintes containers por trás do Traefik:

1. Um blog usando a [imagem oficial do Wordpress](https://hub.docker.com/_/wordpress/).

2. Um servidor de gerenciamento de banco de dados usando a [imagem oficial do Adminer](https://hub.docker.com/_/adminer/).

Vamos gerenciar essas duas aplicações com o Docker Compose usando um arquivo `docker-compose.yml`. Abra o arquivo `docker-compose.yml` em seu editor:

    nano docker-compose.yml

Adicione as seguintes linhas ao arquivo para especificar a versão e as redes que usaremos:

docker-compose.yml

    
    version: "3"
    
    networks:
      web:
        external: true
      internal:
        external: false

Usamos a versão `3` do Docker Compose porque é a mais nova versão principal do formato de arquivo Compose.

Para o Traefik reconhecer nossas aplicações, elas devem fazer parte da mesma rede e, uma vez que criamos a rede manualmente, nós a inserimos especificando o nome da rede `web` e configurando`external` para `true`. Em seguida, definimos outra rede para que possamos conectar nossos containers expostos a um container de banco de dados que não vamos expor por meio do Traefik. Chamaremos essa rede de `internal`.

Em seguida, definiremos cada um dos nossos serviços ou `services`, um de cada vez. Vamos começar com o container `blog`, que basearemos na imagem oficial do WordPress. Adicione esta configuração ao arquivo:

docker-compose.yml

    
    version: "3"
    ...
    
    services:
      blog:
        image: wordpress:4.9.8-apache
        environment:
          WORDPRESS_DB_PASSWORD:
        labels:
          - traefik.backend=blog
          - traefik.frontend.rule=Host:blog.seu_domínio
          - traefik.docker.network=web
          - traefik.port=80
        networks:
          - internal
          - web
        depends_on:
          - mysql

A chave `environment` permite que você especifique variáveis de ambiente que serão definidas dentro do container. Ao não definir um valor para `WORDPRESS_DB_PASSWORD`, estamos dizendo ao Docker Compose para obter o valor de nosso shell e repassá-lo quando criamos o container. Vamos definir essa variável de ambiente em nosso shell antes de iniciar os containers. Dessa forma, não codificamos senhas no arquivo de configuração.

A seção `labels` é onde você especifica os valores de configuração do Traefik. As labels do Docker não fazem nada sozinhas, mas o Traefik as lê para saber como tratar os containers. Veja o que cada uma dessas labels faz:

- `traefik.backend` especifica o nome do serviço de backend no Traefik (que aponta para o container real `blog`).

- `traefik.frontend.rule=Host:blog.seu_domínio` diz ao Traefik para examinar o host solicitado e, se ele corresponde ao padrão de `blog.seu_domínio`, ele deve rotear o tráfego para o container `blog`. 

- `traefik.docker.network=web` especifica qual rede procurar sob o Traefik para encontrar o IP interno para esse container. Como o nosso container Traefik tem acesso a todas as informações do Docker, ele possivelmente levaria o IP para a rede `internal` se não especificássemos isso.

- `traefik.port` especifica a porta exposta que o Traefik deve usar para rotear o tráfego para esse container. 

Com essa configuração, todo o tráfego enviado para a porta `80` do host do Docker será roteado para o container `blog`.

Atribuímos este container a duas redes diferentes para que o Traefik possa encontrá-lo através da rede `web` e possa se comunicar com o container do banco de dados através da rede `internal`.

Por fim, a chave `depends_on` informa ao Docker Compose que este container precisa ser iniciado _após_ suas dependências estarem sendo executadas. Como o WordPress precisa de um banco de dados para ser executado, devemos executar nosso container `mysql` antes de iniciar nosso container`blog`.

Em seguida, configure o serviço MySQL adicionando esta configuração ao seu arquivo:

docker-compose.yml

    
    services:
    ...
      mysql:
        image: mysql:5.7
        environment:
          MYSQL_ROOT_PASSWORD:
        networks:
          - internal
        labels:
          - traefik.enable=false

Estamos usando a imagem oficial do MySQL 5.7 para este container. Você notará que estamos mais uma vez usando um item `environment` sem um valor. As variáveis `MYSQL_ROOT_PASSWORD` e`WORDPRESS_DB_PASSWORD` precisarão ser configuradas com o mesmo valor para garantir que nosso container WordPress possa se comunicar com o MySQL. Nós não queremos expor o container `mysql` para o Traefik ou para o mundo externo, então estamos atribuindo este container apenas à rede `internal`. Como o Traefik tem acesso ao soquete do Docker, o processo ainda irá expor um frontend para o container `mysql` por padrão, então adicionaremos a label `traefik.enable=false` para especificar que o Traefik não deve expor este container.

Por fim, adicione essa configuração para definir o container do Adminer:

docker-compose.yml

    
    services:
    ...
      adminer:
        image: adminer:4.6.3-standalone
        labels:
          - traefik.backend=adminer
          - traefik.frontend.rule=Host:db-admin.seu_domínio
          - traefik.docker.network=web
          - traefik.port=8080
        networks:
          - internal
          - web
        depends_on:
          - mysql

Este container é baseado na imagem oficial do Adminer. A configuração `network` e `depends_on` para este container corresponde exatamente ao que estamos usando para o container `blog`.

No entanto, como estamos redirecionando todo o tráfego para a porta 80 em nosso host Docker diretamente para o container `blog`, precisamos configurar esse container de forma diferente para que o tráfego chegue ao container `adminer`. A linha `traefik.frontend.rule=Host:db-admin.seu_domínio` diz ao Traefik para examinar o host solicitado. Se ele corresponder ao padrão do `db-admin.seu_domínio`, o Traefik irá rotear o tráfego para o container `adminer`.

Neste ponto, `docker-compose.yml` deve ter o seguinte conteúdo:

docker-compose.yml

    
    version: "3"
    
    networks:
      web:
        external: true
      internal:
        external: false
    
    services:
      blog:
        image: wordpress:4.9.8-apache
        environment:
          WORDPRESS_DB_PASSWORD:
        labels:
          - traefik.backend=blog
          - traefik.frontend.rule=Host:blog.seu_domínio
          - traefik.docker.network=web
          - traefik.port=80
        networks:
          - internal
          - web
        depends_on:
          - mysql
      mysql:
        image: mysql:5.7
        environment:
          MYSQL_ROOT_PASSWORD:
        networks:
          - internal
        labels:
          - traefik.enable=false
      adminer:
        image: adminer:4.6.3-standalone
        labels:
          - traefik.backend=adminer
          - traefik.frontend.rule=Host:db-admin.seu_domínio
          - traefik.docker.network=web
          - traefik.port=8080
        networks:
          - internal
          - web
        depends_on:
          - mysql

Salve o arquivo e saia do editor de texto.

Em seguida, defina valores em seu shell para as variáveis `WORDPRESS_DB_PASSWORD` e `MYSQL_ROOT_PASSWORD` antes de iniciar seus containers:

    export WORDPRESS_DB_PASSWORD=senha_segura_do_banco_de_dados
    export MYSQL_ROOT_PASSWORD=senha_segura_do_banco_de_dados

Substitua senha_segura_do_banco_de_dados_ pela sua senha do banco de dados desejada. Lembre-se de usar a mesma senha tanto para `WORDPRESSDB_PASSWORD`quanto para`MYSQL_ROOT\_PASSWORD`.

Com estas variáveis definidas, execute os containers usando o `docker-compose`:

    docker-compose up -d

Agora, dê outra olhada no painel de administrador do Traefik. Você verá que agora existe um `backend` e um `frontend` para os dois servidores expostos:

![](http://assets.digitalocean.com/articles/63957_Traefik/Populated_Traefik_dashboard.png)

Navegue até `blog.seu_domínio`, substituindo `seu_domínio` pelo seu domínio. Você será redirecionado para uma conexão TLS e poderá agora concluir a configuração do Wordpress:

![](http://assets.digitalocean.com/articles/63957_Traefik/WordPress_setup_screen.png)

Agora acesse o Adminer visitando `db-admin.seu_domínio` no seu navegador, novamente substituindo `seu_domínio` pelo seu domínio. O container `mysql` não está exposto ao mundo externo, mas o container `adminer` tem acesso a ele através da rede `internal` do Docker que eles compartilham usando o nome do container `mysql` como um nome de host.

Na tela de login do Adminer, use o nome de usuário **root** , use `mysql` para o **server** , e use o valor que você definiu para `MYSQL_ROOT_PASSWORD` para a senha. Uma vez logado, você verá a interface de usuário do Adminer:

![](http://assets.digitalocean.com/articles/63957_Traefik/adminer-mysql-database/Adminer_MySQL_database.png)

Ambos os sites agora estão funcionando, e você pode usar o painel em `monitor.seu_domínio` para ficar de olho em suas aplicações.

## Conclusão

Neste tutorial, você configurou o Traefik para fazer proxy das solicitações para outras aplicações em containers Docker.

A configuração declarativa do Traefik no nível do container da aplicação facilita a configuração de mais serviços, e não há necessidade de reiniciar o container `traefik` quando você adiciona novas aplicações para fazer proxy, uma vez que o Traefik percebe as alterações imediatamente através do arquivo de soquete do Docker que ele está monitorando.

Para saber mais sobre o que você pode fazer com o Traefik, consulte a [documentação oficial do Traefik](https://docs.traefik.io/basics/).

_Por Keith Thompson_
