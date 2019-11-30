---
author: Etel Sverdlov
date: 2019-01-25
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-configurar-manualmente-um-servidor-prisma-no-ubuntu-18-04-pt
---

# Como Configurar Manualmente um Servidor Prisma no Ubuntu 18.04

_A autora selecionou a [Electronic Frontier Foundation](https://www.brightfunds.org/organizations/electronic-frontier-foundation-inc) para receber uma doação como parte do programa [Write for DOnations](https://do.co/w4do-cta)._

### Introdução

O [Prisma](https://www.prisma.io/) é uma camada de dados que substitui as ferramentas tradicionais de mapeamento relacional de objeto (ORMs) em sua aplicação. Oferecendo suporte tanto para a construção de servidores GraphQL, bem como REST APIs, o Prisma simplifica o acesso ao banco de dados com foco em _segurança de tipo_ e permite _migrações de banco de dados declarativas_. A segurança de tipo ajuda a reduzir possíveis erros e inconsistências de código, enquanto as migrações de banco de dados declarativas permitem armazenar seu modelo de dados no controle de versão. Esses recursos ajudam os desenvolvedores a reduzir o tempo gasto na configuração de acesso a bancos de dados, migrações e fluxos de trabalho de gerenciamento de dados.

Você pode fazer o deploy do servidor Prisma, que atua como um proxy para seu banco de dados, de várias maneiras e hospedá-lo remotamente ou localmente. Através do serviço do Prisma, você pode acessar seus dados e se conectar ao seu banco de dados com a API GraphQL, que permite operações em tempo real e a capacidade de criar, atualizar e excluir dados. O GraphQL é uma linguagem de consulta para APIs que permite aos usuários enviar consultas para acessar os dados exatos que eles precisam de seu servidor. O servidor Prisma é um componente independente que fica acima do seu banco de dados.

Neste tutorial, você irá instalar manualmente um servidor Prisma no Ubuntu 18.04 e executará uma consulta de teste GraphQL no [GraphQL Playground](https://www.prisma.io/blog/introducing-graphql-playground-f1e0a018f05d/). Você hospedará seu código de configuração e desenvolvimento Prisma localmente — onde você constrói de fato a sua aplicação — enquanto executa o Prisma no seu servidor remoto. Ao realizar a instalação manualmente, você terá uma compreensão e uma personalização mais detalhadas da infraestrutura subjacente de sua configuração.

Embora este tutorial aborde as etapas manuais para implantar o Prisma em um servidor Ubuntu 18.04, você também pode realizar isso de uma forma mais automatizada com a Docker Machine, seguindo este [tutorial](https://www.prisma.io/tutorials/deploy-prisma-to-digitalocean-with-docker-machine-ct06/) no site do Prisma.

**Note:** A configuração descrita nesta seção não inclui recursos que você normalmente esperaria em servidores prontos para produção, como backups automatizados e failover ativo.

## Pré-requisitos

Para completar este tutorial, você vai precisar de:

- Um servidor Ubuntu 18.04 configurado seguindo o guia de [Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt), incluindo um usuário sudo não-root.

- Docker instalado em seu servidor. Você pode conseguir isso seguindo o Passo 1 do tutorial [Como Instalar e Usar o Docker no Ubuntu 18.04](como-instalar-e-usar-o-docker-no-ubuntu-18-04-pt). 

- Docker Compose instalado. Você pode encontrar instruções para isso no Passo 1 de [Installing Docker Compose](how-to-install-docker-compose-on-ubuntu-18-04#step-1-%E2%80%94-installing-docker-compose).

- Node.js instalado em seu servidor. Você pode conseguir isso indo até a seção PPA do tutorial [Installing Node.js](how-to-install-node-js-on-ubuntu-18-04#installing-using-a-ppa).

# Passo 1 — Iniciando o Servidor Prisma

O Prisma CLI é a principal ferramenta usada para fazer o deploy e gerenciar seus serviços Prisma. Para iniciar os serviços, você precisa configurar a infraestrutura necessária, que inclui o servidor Prisma e um banco de dados para conexão.

O Docker Compose lhe permite gerenciar e executar aplicações multi-container. Você o utilizará para configurar a infraestrutura necessária para o serviço Prisma.

Você começará criando o arquivo `docker-compose.yml` para armazenar a configuração do serviço Prisma em seu servidor. Você usará esse arquivo para ativar automaticamente o Prisma, um banco de dados associado, e configurar os detalhes necessários, tudo em uma única etapa. Uma vez que o arquivo é executado com o Docker Compose, ele irá configurar as senhas para seus bancos de dados, portanto, certifique-se de substituir as senhas para `managementAPIsecret` e `MYSQL_ROOT_PASSWORD` por algo seguro. Execute o seguinte comando para criar e editar o arquivo `docker-compose.yml`:

    sudo nano docker-compose.yml

Adicione o seguinte conteúdo ao arquivo para definir os serviços e volumes para a configuração do Prisma:

docker-compose.yml

    
    version: "3"
    services:
      prisma:
        image: prismagraphql/prisma:1.20
        restart: always
        ports:
          - "4466:4466"
        environment:
          PRISMA_CONFIG: |
            port: 4466
            managementApiSecret: my-secret
            databases:
              default:
                connector: mysql
                host: mysql
                port: 3306
                user: root
                password: prisma
                migrations: true
      mysql:
        image: mysql:5.7
        restart: always
        environment:
          MYSQL_ROOT_PASSWORD: prisma
        volumes:
          - mysql:/var/lib/mysql
    volumes:
      mysql:

Essa configuração faz o seguinte:

- Lança dois serviços: `prisma-db` e `db`.

- Baixa a última versão do Prisma. No momento da escrita desse artigo, ela é o Prisma 1.20.

- Define as portas em que o Prisma estará disponível e especifica todas as credenciais para se conectar ao banco de dados MySQL na seção `databases`.

O arquivo `docker-compose.yml` configura o `managementApiSecret`, que impede que outras pessoas acessem seus dados com conhecimento do seu endpoint. Se você estiver usando este tutorial apenas algo que não seja um deployment de teste, altere o `managementAPIsecret` para algo mais seguro. Quando fizer isso, guarde isso para que você possa inseri-lo mais tarde durante o processo `prisma init`.

Esse arquivo também extrai a imagem Docker do MySQL e define essas credenciais também. Para os propósitos deste tutorial, este arquivo Docker Compose cria uma imagem MySQL, mas você também pode usar o PostgreSQL com o Prisma. Ambas as imagens Docker estão disponíveis no Docker Hub:

- [MySQL](https://hub.docker.com/_/mysql/)

- [PostgreSQL.](https://hub.docker.com/_/postgres/postgres)

Salve e saia do arquivo.

Agora que você salvou todos os detalhes, você pode iniciar os containers do Docker. O comando `-d` diz aos containers para serem executados no modo detached, o que significa que eles serão executados em segundo plano:

    sudo docker-compose up -d

Isso irá buscar as imagens do Docker para `prisma` e `mysql`. Você pode verificar se os containers do Docker estão sendo executados com o seguinte comando:

    sudo docker ps

Você verá uma saída semelhante a esta:

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    24f4dd6222b1 prismagraphql/prisma:1.12 "/bin/sh -c /app/sta…" 15 seconds ago Up 1 second 0.0.0.0:4466->4466/tcp root_prisma_1
    d8cc3a393a9f mysql:5.7 "docker-entrypoint.s…" 15 seconds ago Up 13 seconds 3306/tcp root_mysql_1

Com seu servidor Prisma e o banco de dados configurados, agora você está pronto para trabalhar localmente para fazer o deploy do serviço Prisma.

## Passo 2 — Instalando o Prisma Localmente

O servidor Prisma fornece os ambientes de runtime para seus serviços Prisma. Agora que você tem seu servidor Prisma iniciado, você pode fazer o deploy do seu serviço Prisma. Você executará estas etapas localmente, não no seu servidor.

Para começar, crie uma pasta separada que irá conter todos os arquivos do Prisma:

    mkdir prisma

Mova-se pra essa pasta:

    cd prisma

Você pode instalar o Prisma com o Homebrew se você estiver usando o MacOS. Para fazer isso, execute o seguinte comando para adicionar o repositório do Prisma:

    brew tap prisma/prisma

Você pode então instalar o Prisma com o seguinte comando:

    brew install prisma

Ou, alternativamente com o `npm`:

    npm install -g prisma

Com o Prisma instalado localmente, você está pronto para iniciar o novo serviço Prisma.

## Passo 3 — Criando a Configuração para um Novo Serviço Prisma

Após a instalação, você pode usar o `prisma init` para criar a estrutura de arquivos para uma nova API de banco de dados Prisma, que gera os arquivos necessários para construir sua aplicação com o Prisma. Seu endpoint estará automaticamente no arquivo `prisma.yml`, e o `datamodel.prisma` já conterá um modelo de dados de amostra que você pode consultar na próxima etapa. O modelo de dados serve como base para sua API Prisma e especifica o modelo para sua aplicação. Neste ponto, você está criando apenas os arquivos e o modelo de dados de amostra. Você não está fazendo nenhuma alteração no banco de dados até executar o `prisma deploy` posteriormente nesta etapa.

Agora você pode executar o seguinte comando localmente para criar a nova estrutura de arquivos:

    prisma init hello-world

Depois de executar este comando, você verá um prompt interativo. Quando perguntado, selecione, `Use other server` e pressione `ENTER`:

    Output Set up a new Prisma server or deploy to an existing server?
    
      You can set up Prisma for local development (based on docker-compose)
      Use existing database Connect to existing database
      Create new database Set up a local database using Docker
    
      Or deploy to an existing Prisma server:
      Demo server Hosted demo environment incl. database (requires login)
    ❯ Use other server Manually provide endpoint of a running Prisma server

Em seguida, você fornecerá o endpoint do seu servidor que está atuando como servidor Prisma. Será algo parecido com: `http://IP_DO_SERVIDOR:4466`. É importante que o endpoint comece com http (ou https) e tenha o número da porta indicado.

    OutputEnter the endpoint of your Prisma server http://IP_DO_SERVIDOR:4466

Para o segredo da API de gerenciamento, insira a frase ou senha que você indicou anteriormente no arquivo de configuração:

    OutputEnter the management API secret my-secret

Para as opções subseqüentes, você pode escolher as variáveis padrão pressionando `ENTER` para o `service name` e `service stage`:

    OutputChoose a name for your service hello-world
    Choose a name for your stage dev

Você também terá a opção de escolher uma linguagem de programação para o cliente Prisma. Nesse caso, você pode escolher sua linguagem preferida. Você pode ler mais sobre o cliente [aqui](https://www.prisma.io/blog/prisma-client-preview-ahph4o1umail).

    Output Select the programming language for the generated Prisma client (Use arrow keys)
    ❯ Prisma TypeScript Client
      Prisma Flow Client
      Prisma JavaScript Client
      Prisma Go Client
      Don't generate

Depois de terminar o prompt, você verá a seguinte saída que confirma as seleções que você fez:

    Output Created 3 new files:
    
      prisma.yml Prisma service definition
      datamodel.prisma GraphQL SDL-based datamodel (foundation for database)
      .env Env file including PRISMA_API_MANAGEMENT_SECRET
    
    Next steps:
    
      1. Open folder: cd hello-world
      2. Deploy your Prisma service: prisma deploy
      3. Read more about deploying services:
         http://bit.ly/prisma-deploy-services
    

Vá para o diretório `hello-world`:

    cd hello-world

Sincronize estas mudanças com o seu servidor usando `prisma deploy`. Isso envia as informações para o servidor Prisma a partir da sua máquina local e cria o serviço Prisma no servidor Prisma:

    prisma deploy

**Nota:** A execução do `prisma deploy` novamente atualizará seu serviço Prisma.

Sua saída será algo como:

    OutputCreating stage dev for service hello-world ✔
    Deploying service `hello-world` to stage 'dev' to server 'default' 468ms
    
    Changes:
    
      User (Type)
      + Created type `User`
      + Created field `id` of type `GraphQLID!`
      + Created field `name` of type `String!`
      + Created field `updatedAt` of type `DateTime!`
      + Created field `createdAt` of type `DateTime!`
    
    Applying changes 716ms
    
    Your Prisma GraphQL database endpoint is live:
    
      HTTP: http://IP_DO_SERVIDOR:4466/hello-world/dev
      WS: ws://IP_DO_SERVIDOR:4466/hello-world/dev
    

A saída mostra que o Prisma atualizou seu banco de dados de acordo com o seu modelo de dados (criado na etapa `prisma init`) com um _tipo_ `User`. Tipos são uma parte essencial de um modelo de dados; eles representam um item da sua aplicação, e cada tipo contém vários campos. Para o seu modelo de dados, os campos associados que descrevem o usuário são: o ID do usuário, o nome, a hora em que foram criados e o horário em que foram atualizados.

Se você encontrar problemas nesse estágio e obtiver uma saída diferente, verifique novamente se digitou todos os campos corretamente durante o prompt interativo. Você pode fazer isso revisando o conteúdo do arquivo `prisma.yml`.

Com seu serviço Prisma em execução, você pode se conectar a dois endpoints diferentes:

- A interface de gerenciamento, disponível em `http://IP_DO_SERVIDOR:4466/management`, onde você pode gerenciar e fazer deployment de serviços Prisma.

- A API GraphQL para o seu serviço Prisma, disponível em `http://IP_DO_SERVIDOR:4466/hello-world/dev`.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prisma_1804/prisma_step_four_project.png)

Você configurou e fez o deployment com sucesso do seu servidor Prisma. Agora você pode explorar consultas e mutações no GraphQL.

## Passo 4 — Executando uma Consulta de Exemplo

Para explorar outro caso de uso do Prisma, você pode experimentar em seu servidor a ferramenta [GraphQL playground](https://github.com/prisma/graphql-playground), que é um ambiente de desenvolvimento integrado open-source (IDE). Para acessá-lo, visite seu endpoint em seu navegador, da etapa anterior:

    http://IP_DO_SERVIDOR:4466/hello-world/dev

Uma _mutação_ é um termo do GraphQL que descreve uma maneira de modificar — criar, atualizar ou excluir (CRUD) — dados no backend via GraphQL. Você pode enviar uma mutação para criar um novo usuário e explorar a funcionalidade. Para fazer isso, execute a seguinte mutação no lado esquerdo da página:

    mutation {
      createUser(data: { name: "Alice" }) {
        id
        name
      }
    }

Depois de pressionar o botão play, você verá os resultados no lado direito da página.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prisma_1804/prisma_step_five_user.png)

Posteriormente, se você quiser procurar um usuário usando a coluna `ID` no banco de dados, poderá executar a seguinte consulta:

    query {
      user(where: { id: "cjkar2d62000k0847xuh4g70o" }) {
        id
        name
      }
    }

Agora você tem um servidor Prisma e o serviço em funcionamento no servidor, e você executou consultas de teste no IDE do GraphQL.

## Conclusão

Você tem uma configuração Prisma em funcionamento no seu servidor. Você pode ver alguns casos de uso adicionais do Prisma e os próximos passos no [Guia de primeiros passos](https://www.prisma.io/docs/1.20/get-started/01-setting-up-prisma-new-database-JAVASCRIPT-a002/) ou explorar o conjunto de recursos do Prisma no [Prisma Docs](https://www.prisma.io/docs/). Depois de concluir todas as etapas deste tutorial, você tem várias opções para verificar sua conexão com o banco de dados, sendo que uma possibilidade é a utilização do [Prisma Client](https://www.prisma.io/client/client-javascript).

_Por Etel Sverdlov_
