---
author: Young Kim
date: 2019-01-25
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-configurar-um-registro-privado-do-docker-no-ubuntu-18-04-pt
---

# Como Configurar um Registro Privado do Docker no Ubuntu 18.04

_O autor selecionou a [Apache Software Foundation](https://www.brightfunds.org/organizations/apache-software-foundation) para receber uma doação como parte do programa [Write for DOnations](https://do.co/w4do-cta)_

### Introdução

O [Registro Docker](https://docs.docker.com/registry/#what-it-is) é uma aplicação que gerencia o armazenamento e a entrega de imagens de container do Docker. Os registros centralizam imagens de container e reduzem o tempo de criação para desenvolvedores. As imagens do Docker garantem o mesmo ambiente de runtime por meio da virtualização, mas a criação de uma imagem pode envolver um investimento de tempo significativo. Por exemplo, em vez de instalar dependências e pacotes separadamente para usar o Docker, os desenvolvedores podem baixar uma imagem compactada de um registro que contém todos os componentes necessários. Além disso, os desenvolvedores podem automatizar o envio de imagens para um registro usando ferramentas de integração contínua, tais como o [TravisCI](https://travis-ci.com/), para atualizar continuamente as imagens durante a produção e o desenvolvimento.

O Docker também tem um registro público gratuito, [Docker Hub](https://hub.docker.com/), que pode hospedar suas imagens personalizadas do Docker, mas há situações em que você não deseja que sua imagem fique disponível publicamente. As imagens geralmente contém todo o código necessário para executar uma aplicação, portanto, é preferível usar um registro privado ao usar um software proprietário.

Neste tutorial, você irá configurar e proteger seu próprio Registro Docker privado. Você irá usar o [Docker Compose](https://docs.docker.com/compose/) para definir configurações para executar suas aplicações Docker e o Nginx para encaminhar o tráfego do servidor de HTTPS para o container do Docker em execução. Depois de concluir este tutorial, você poderá enviar uma imagem do Docker personalizada para seu registro privado e baixar a imagem com segurança de um servidor remoto.

## Pré-requisitos

Antes de iniciar este guia, você precisará do seguinte:

- Dois servidores Ubuntu 18.04 configurados seguindo a [Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt), incluindo um usuário sudo não-root e um firewall. Um servidor irá hospedar seu Registro Docker privado e o outro será o seu servidor **cliente**.

- Docker e Docker-Compose instalados em ambos os servidores seguindo o tutorial [How To Install Docker Compose on Ubuntu 18.04](how-to-install-docker-compose-on-ubuntu-18-04). Você só precisa concluir a primeira etapa deste tutorial para instalar o Docker Compose. Este tutorial explica como instalar o Docker como parte de seus pré-requisitos.

- Nginx instalado no seu servidor de Registro Docker privado seguindo o tutoral [Como Instalar o Nginx no Ubuntu 18.04](como-instalar-o-nginx-no-ubuntu-18-04-pt).

- Nginx protegido com o Let’s Encrypt em seu servidor de Registro Docker privado, seguindo o tutorial [Como Proteger o Nginx com o Let’s Encrypt no Ubuntu 18.04](como-proteger-o-nginx-com-o-let-s-encrypt-no-ubuntu-18-04-pt). Certifique-se de redirecionar todo o tráfego de HTTP para HTTPS no Passo 4.

- Um nome de domínio que resolve para o servidor que você está usando para o Registro de Docker privado. Você configurará isso como parte do pré-requisito para o Let’s Encrypt.

## Passo 1 — Instalando e Configurando o Registro Docker

A ferramenta de linha de comando do Docker é útil para iniciar e gerenciar um ou dois containers Docker, mas, para um deployment completo, a maioria das aplicações em execução dentro de containers do Docker exige que outros componentes sejam executados em paralelo. Por exemplo, muitas aplicações web consistem em um servidor web, como o Nginx, que oferece e serve o código da aplicação, uma linguagem de script interpretada, como o PHP, e um servidor de banco de dados, como o MySQL.

Com o Docker Compose, você pode escrever um arquivo `.yml` para definir a configuração de cada container e as informações que os containers precisam para se comunicarem uns com os outros. Você pode usar a ferramenta de linha de comando `docker-compose` para emitir comandos para todos os componentes que compõem a sua aplicação.

O próprio Registro Docker é uma aplicação com vários componentes, portanto, você utilizará o Docker Compose para gerenciar sua configuração. Para iniciar uma instância do registro, você irá configurar um arquivo `docker-compose.yml` para definir o local onde seu registro armazenará seus dados.

No servidor que você criou para hospedar seu Registro Docker privado, você pode criar um diretório `docker-registry`, mover-se para ele, e criar uma subpasta `data` com os seguintes comandos:

    mkdir ~/docker-registry && cd $_
    mkdir data

Use o seu editor de texto para criar o arquivo de configuração `docker-compose.yml`:

    nano docker-compose.yml

Adicione o seguinte conteúdo ao arquivo, que descreve a configuração básica para o Registro Docker:

docker-compose.yml

    version: '3'
    
    services:
      registry:
        image: registry:2
        ports:
        - "5000:5000"
        environment:
          REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: /data
        volumes:
          - ./data:/data

A seção `environment` define uma variável de ambiente no container do Registro Docker com o caminho `/data`. A aplicação do Registro Docker verifica essa variável de ambiente quando é inicializada e, como resultado, começa a salvar seus dados na pasta `/data`.

No entanto, como você incluiu a linha `volumes: - ./data:/data`, e o Docker irá começar a mapear o diretório `/data` daquele container para /data em seu servidor de registro. O resultado final é que os dados do Registro Docker são armazenados em `~/docker-registry/data` no servidor do registro.

A seção `ports`, com a configuração `5000:5000`, diz ao Docker para mapear a porta `5000` no servidor para a porta `5000` no container em execução. Isso lhe permite enviar uma solicitação para a porta `5000` no servidor, e ter essa solicitação encaminhada para a aplicação do registro.

Agora você pode iniciar o Docker Compose para verificar a configuração:

    docker-compose up

Você verá barras de download em sua saída que mostram o Docker baixando a imagem do Registro Docker do próprio Docker Registry. Em um ou dois minutos, você verá uma saída semelhante à seguinte (as versões podem variar):

    Output of docker-compose upStarting docker-registry_registry_1 ... done
    Attaching to docker-registry_registry_1
    registry_1 | time="2018-11-06T18:43:09Z" level=warning msg="No HTTP secret provided - generated random secret. This may cause problems with uploads if multiple registries are behind a load-balancer. To provide a shared secret, fill in http.secret in the configuration file or set the REGISTRY_HTTP_SECRET environment variable." go.version=go1.7.6 instance.id=c63483ee-7ad5-4205-9e28-3e809c843d42 version=v2.6.2
    registry_1 | time="2018-11-06T18:43:09Z" level=info msg="redis not configured" go.version=go1.7.6 instance.id=c63483ee-7ad5-4205-9e28-3e809c843d42 version=v2.6.2
    registry_1 | time="2018-11-06T18:43:09Z" level=info msg="Starting upload purge in 20m0s" go.version=go1.7.6 instance.id=c63483ee-7ad5-4205-9e28-3e809c843d42 version=v2.6.2
    registry_1 | time="2018-11-06T18:43:09Z" level=info msg="using inmemory blob descriptor cache" go.version=go1.7.6 instance.id=c63483ee-7ad5-4205-9e28-3e809c843d42 version=v2.6.2
    registry_1 | time="2018-11-06T18:43:09Z" level=info msg="listening on [::]:5000" go.version=go1.7.6 instance.id=c63483ee-7ad5-4205-9e28-3e809c843d42 version=v2.6.2

Você abordará a mensagem de aviso `No HTTP secret provided` posteriormente neste tutorial. A saída mostra que o container está iniciando. A última linha da saída mostra que ele começou a escutar com sucesso na porta `5000`.

Por padrão, o Docker Compose permanecerá aguardando sua entrada, então pressione `CTRL+C` para encerrar seu container do Registro Docker.

Você configurou um Registro Docker completo, escutando na porta `5000`. Nesse ponto, o registro não será iniciado, a menos que você o faça manualmente. Além disso, o Registro Docker não vem com nenhum mecanismo de autenticação integrado, por isso está atualmente inseguro e completamente aberto ao público. Nos passos quem seguem, você abordará essas preocupações de segurança.

## Passo 2 — Configurando o Encaminhamento de Porta no Nginx

Você já tem HTTPS configurado em seu servidor de Registro Docker com Nginx, o que significa que agora você pode configurar o encaminhamento de porta do Nginx para a porta `5000`. Depois de concluir esta etapa, você pode acessar seu registro diretamente em example.com.

Como parte do pré-requisito para o guia [Como Proteger o Nginx com o Let’s Encrypt no Ubuntu 18.04](como-proteger-o-nginx-com-o-let-s-encrypt-no-ubuntu-18-04-pt), você já configurou o arquivo `/etc/nginx/sites-available/example.com` contendo a configuração do seu servidor.

Abra o arquivo com seu editor de texto:

    sudo nano /etc/nginx/sites-available/example.com

Encontre a linha `location` existente. Isso parecerá assim:

/etc/nginx/sites-available/example.com

    ...
    location / {
      ...
    }
    ...

Você precisa encaminhar o tráfego para a porta `5000`, onde seu registro estará em execução. Você também deseja anexar cabeçalhos à solicitação para o registro, que fornecem informações adicionais do servidor com cada solicitação e resposta. Exclua o conteúdo da seção `location` e inclua o seguinte conteúdo nessa seção:

/etc/nginx/sites-available/example.com

    ...
    location / {
        # Do not allow connections from docker 1.5 and earlier
        # docker pre-1.6.0 did not properly set the user agent on ping, catch "Go *" user agents
        if ($http_user_agent ~ "^(docker\/1\.(3|4|5(?!\.[0-9]-dev))|Go ).*$" ) {
          return 404;
        }
    
        proxy_pass http://localhost:5000;
        proxy_set_header Host $http_host; # required for docker client's sake
        proxy_set_header X-Real-IP $remote_addr; # pass on real client's IP
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 900;
    }
    ...

A seção `$http_user_agent` verifica se a versão do Docker do cliente está acima de `1.5` e garante que o `UserAgent` não seja uma aplicação `Go`. Como você está usando a versão `2.0` do registro, os clientes mais antigos não são suportados. Para mais informações, você pode encontrar a configuração do cabeçalho do `nginx` em [Docker’s Registry Nginx guide](https://docs.docker.com/registry/recipes/nginx/#setting-things-up).

Salve e saia do arquivo. Aplique as alterações reiniciando o Nginx:

    sudo service nginx restart

Você pode confirmar que o Nginx está encaminhando o tráfego para a porta `5000` executando o registro:

    cd ~/docker-registry
    docker-compose up

Em uma janela do navegador, abra a seguinte URL:

    https://example.com/v2

Você verá um objeto JSON vazio, ou:

    {}

No seu terminal, você verá uma saída semelhante à seguinte:

    Output of docker-compose upregistry_1 | time="2018-11-07T17:57:42Z" level=info msg="response completed" go.version=go1.7.6 http.request.host=cornellappdev.com http.request.id=a8f5984e-15e3-4946-9c40-d71f8557652f http.request.method=GET http.request.remoteaddr=128.84.125.58 http.request.uri="/v2/" http.request.useragent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_2) AppleWebKit/604.4.7 (KHTML, like Gecko) Version/11.0.2 Safari/604.4.7" http.response.contenttype="application/json; charset=utf-8" http.response.duration=2.125995ms http.response.status=200 http.response.written=2 instance.id=3093e5ab-5715-42bc-808e-73f310848860 version=v2.6.2
    registry_1 | 172.18.0.1 - - [07/Nov/2018:17:57:42 +0000] "GET /v2/ HTTP/1.0" 200 2 "" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_2) AppleWebKit/604.4.7 (KHTML, like Gecko) Version/11.0.2 Safari/604.4.7"

Você pode ver da última linha que uma requisição `GET` foi feita para `/v2/`, que é o endpoint para o qual você enviou uma solicitação do seu navegador. O container recebeu a solicitação que você fez, do encaminhamento de porta, e retornou uma resposta de `{}`. O código `200` na última linha da saída significa que o container tratou a solicitação com sucesso.

Agora que você configurou o encaminhamento de porta, é possível melhorar a segurança do seu registro.

## Passo 3 — Configurando a Autenticação

Com o Nginx fazendo proxy das solicitações corretamente, agora você pode proteger seu registro com autenticação HTTP para gerenciar quem tem acesso ao seu Registro Docker. Para conseguir isso, você irá criar um arquivo de autenticação com o `htpasswd` e adicionará usuários a ele. A autenticação HTTP é rápida de configurar e segura em uma conexão HTTPS, que é o que o registro usará.

Você pode instalar o pacote `htpasswd` executando o seguinte:

    sudo apt install apache2-utils

Agora você irá criar o diretório onde você armazenará nossas credenciais de autenticação e irá se mover para esse diretório. O `$_` expande para o último argumento do comando anterior, neste caso `~/docker-registry/auth`:

    mkdir ~/docker-registry/auth && cd $_

Em seguida, você irá criar o primeiro usuário da seguinte forma, substituindo nome\_usuário pelo nome de usuário que deseja usar. A flag `-B` especifica criptografia `bcrypt`, que é mais segura que a criptografia padrão. Digite a senha quando solicitado:

    htpasswd -Bc registry.password nome_usuário

**Nota:** Para adicionar mais usuários execute novamente o comando anterior sem a opção -c (o `c` é para criar):

    htpasswd registry.password nome_usuário

A seguir, você irá editar o arquivo `docker-compose.yml` para dizer ao Docker para usar o arquivo que você criou para autenticar usuários.

    cd ~/docker-registry
    nano docker-compose.yml

Você pode adicionar variáveis de ambiente e um volume para o diretório `auth/` que você criou, editando o arquivo `docker-compose.yml` para informar ao Docker como você deseja autenticar usuários. Adicione o seguinte conteúdo destacado ao arquivo:

docker-compose.yml

    version: '3'
    
    services:
      registry:
        image: registry:2
        ports:
        - "5000:5000"
        environment:
          REGISTRY_AUTH: htpasswd
          REGISTRY_AUTH_HTPASSWD_REALM: Registry
          REGISTRY_AUTH_HTPASSWD_PATH: /auth/registry.password
          REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY: /data
        volumes:
          - ./auth:/auth
          - ./data:/data

Para `REGISTRY_AUTH`, você especificou `htpasswd`, que é o esquema de autenticação que você está utilizando, e definiu `REGISTRY_AUTH_HTPASSWD_PATH` para o caminho do arquivo de autenticação. Finalmente, `REGISTRY_AUTH_HTPASSWD_REALM` significa o nome do domínio do `htpasswd`.

Agora você pode verificar se sua autenticação funciona corretamente, executando o registro e verificando se ele solicita um nome de usuário e uma senha.

    docker-compose up

Em uma janela do navegador, abra `https://example.com/v2`.

Depois de digitar o `nome_usuário` e a senha correspondente, você verá o `{}` mais uma vez. Você confirmou a configuração básica da autenticação: o registro só retornou o resultado depois que você digitou o nome de usuário e a senha corretos. Agora você já protegeu seu registro e pode continuar utilizando-o.

## Passo 4 — Iniciando o Registro Docker como um Serviço

Você quer garantir que seu registro seja iniciado sempre que o sistema for inicializado. Se houver algum travamento imprevisto do sistema, você quer ter certeza de que o registro seja reiniciado quando o servidor for reinicializado. Abra o `docker-compose.yml`:

    nano docker-compose.yml

Adicione a seguinte linha de conteúdo logo abaixo de `registry:`:

docker-compose.yml

    ...
      registry:
        restart: always
    ...

Você pode iniciar seu registro como um processo em segundo plano, o que permitirá que você saia da sessão `ssh` e persista o processo:

    docker-compose up -d

Com o seu registro em execução em segundo plano, agora você pode preparar o Nginx para uploads de arquivos.

## Passo 5 — Aumentando o Tamanho do Upload de Arquivos para o Nginx

Antes de poder enviar uma imagem para o registro, você precisa garantir que o registro possa lidar com grandes uploads de arquivos. Embora o Docker divida os uploads de imagens grandes em camadas separadas, às vezes elas podem ter mais de `1GB`. Por padrão, o Nginx tem um limite de `1MB` para uploads de arquivos, então você precisa editar o arquivo de configuração do `nginx` e configurar o tamanho máximo de upload do arquivo para `2GB`.

    sudo nano /etc/nginx/nginx.conf

Encontre a seção `http` e adicione a seguinte linha:

/etc/nginx/nginx.conf

    ...
    http {
            client_max_body_size 2000M;
            ...
    }
    ...

Por fim, reinicie o Nginx para aplicar as alterações de configuração:

    sudo service nginx restart

Agora você pode enviar imagens grandes para o seu Registro Docker sem erros no Nginx.

## Passo 6 — Publicando em seu Registro Docker Privado

Agora você está pronto para publicar uma imagem no seu Registro Docker privado, mas primeiro é preciso criar uma imagem. Para este tutorial, você criará uma imagem simples baseada na imagem `ubuntu` do Docker Hub. O Docker Hub é um registro hospedado publicamente, com muitas imagens pré-configuradas que podem ser aproveitadas para “Dockerizar” rapidamente as aplicações. Usando a imagem `ubuntu`, você vai testar o envio e o download de imagens do seu registro.

Do seu servidor **cliente** , crie uma imagem pequena e vazia para enviar para o seu novo registro. As flags `-i` e `-t` lhe fornecem acesso interativo ao shell no container:

    docker run -t -i ubuntu /bin/bash

Após o término do download, você estará dentro de um prompt do Docker, observe que o ID do container após `root@` irá variar. Faça uma rápida mudança no sistema de arquivos criando um arquivo chamado `SUCCESS`. No próximo passo, você poderá usar esse arquivo para determinar se o processo de publicação foi bem-sucedido:

    touch /SUCCESS

Saia do container do Docker:

    exit

O comando a seguir cria uma nova imagem chamada `test-image` com base na imagem já em execução, além de todas as alterações que você fez. No nosso caso, a adição do arquivo `/SUCCESS` está incluída na nova imagem.

Faça o commit da alteração:

    docker commit $(docker ps -lq) test-image

Neste ponto, a imagem só existe localmente. Agora você pode enviá-la para o novo registro que você criou. Faça o login no seu Registro Docker:

    docker login https://example.com

Digite o `nome_usuário` e a senha correspondente de antes. Em seguida, você colocará uma tag na imagem com a localização do registro privado para enviar a ele:

    docker tag test-image example.com/test-image

Envie a imagem recém-marcada para o registro:

    docker push example.com/test-image

Sua saída será semelhante à seguinte:

    OutputThe push refers to a repository [example.com/test-image]
    e3fbbfb44187: Pushed
    5f70bf18a086: Pushed
    a3b5c80a4eba: Pushed
    7f18b442972b: Pushed
    3ce512daaf78: Pushed
    7aae4540b42d: Pushed
    ...

Você verificou que seu registro trata a autenticação do usuário e permite que usuários autenticados enviem imagens ao registro. Em seguida, você confirmará que também é possível extrair ou baixar imagens do registro.

## Passo 7 — Baixando de seu Registro Docker Privado

Retorne ao seu servidor de registro para que você possa testar o download da imagem a partir do seu servidor **cliente**. Também é possível testar isso a partir de um outro servidor.

Faça o login com o nome de usuário e senha que você configurou anteriormente:

    docker login https://example.com

Agora você está pronto para baixar a imagem. Use seu nome de domínio e nome de imagem, que você marcou na etapa anterior:

    docker login example.com/test-image

O Docker irá baixar a imagem e retornar você ao prompt. Se você executar a imagem no servidor de registro, verá que o arquivo `SUCCESS` criado anteriormente está lá:

    docker run -it example.com/test-image /bin/bash

Liste seus arquivos dentro do shell bash:

    ls

Você verá o arquivo `SUCCESS` que você criou para esta imagem:

    SUCCESS bin boot dev etc home lib lib64 media mnt opt proc root run sbin srv sys tmp usr var

Você terminou de configurar um registro seguro para o qual os usuários podem enviar e baixar imagens personalizadas.

## Conclusão

Neste tutorial, você configurou seu próprio Registro Docker privado e publicou uma imagem Docker. Como mencionado na introdução, você também pode usar o [TravisCI](https://docs.travis-ci.com/user/docker/) ou uma ferramenta de CI semelhante para automatizar o envio diretamente para um registro privado. Ao aproveitar o Docker e os registros em seu fluxo de trabalho, você pode garantir que a imagem que contém o código resulte no mesmo comportamento em qualquer máquina, seja em produção ou em desenvolvimento. Para obter mais informações sobre como escrever arquivos do Docker, você pode ler [o tutorial do Docker](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/), que explica o processo.

_Por Young Kim_
