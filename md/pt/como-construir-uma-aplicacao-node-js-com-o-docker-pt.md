---
author: Kathleen Juell
date: 2019-01-11
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-construir-uma-aplicacao-node-js-com-o-docker-pt
---

# Como Construir uma Aplicação Node.js com o Docker

### Introdução

A plataforma [Docker](https://www.docker.com/) permite aos desenvolvedores empacotar e executar aplicações como _containers_. Um container é um processo isolado que executa em um sistema operacional compartilhado, oferecendo uma alternativa mais leve às máquinas virtuais. Embora os containers não sejam novos, eles oferecem benefícios — incluindo isolamento do processo e padronização do ambiente — que estão crescendo em importância à medida que mais desenvolvedores usam arquiteturas de aplicativos distribuídos.

Ao criar e dimensionar uma aplicação com o Docker, o ponto de partida normalmente é a criação de uma imagem para a sua aplicação, que você pode então, executar em um container. A imagem inclui o código da sua aplicação, bibliotecas, arquivos de configuração, variáveis de ambiente, e runtime. A utilização de uma imagem garante que o ambiente em seu container está padronizado e contém somente o que é necessário para construir e executar sua aplicação.

Neste tutorial, você vai criar uma imagem de aplicação para um website estático que usa o framework [Express](https://expressjs.com/) e o [Bootstrap](https://getbootstrap.com/). Em seguida, você criará um container usando essa imagem e a enviará para o [Docker Hub](https://hub.docker.com/) para uso futuro. Por fim, você irá baixar a imagem armazenada do repositório do Docker Hub e criará outro container, demonstrando como você pode recriar e escalar sua aplicação.

## Pré-requisitos

Para seguir este tutorial, você vai precisar de:

- Um servidor Ubuntu 18.04, configurado seguindo este [guia de Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt). 

- Docker instalado em seu servidor, seguindo os Passos 1 e 2 do tutorial [Como Instalar e Usar o Docker no Ubuntu 18.04](como-instalar-e-usar-o-docker-no-ubuntu-18-04-pt).

- Node.js e npm instalados, seguindo [estas instruções sobre a instalação com o PPA gerenciado pelo NodeSource](how-to-install-node-js-on-ubuntu-18-04#installing-using-a-ppa).

- Um conta no Docker Hub. Para uma visão geral de como configurar isso, verifique [esta introdução](https://docs.docker.com/docker-hub/) sobre os primeiros passos com Docker Hub.

## Passo 1 — Instalando as Dependências da Sua Aplicação

Para criar a sua imagem, primeiro você precisará produzir os arquivos de sua aplicação, que você poderá copiar para o seu container. Esses arquivos incluirão o conteúdo estático, o código e as dependências da sua aplicação.

Primeiro, crie um diretório para o seu projeto no diretório home do seu usuário não-root. Vamos chamar o nosso de `node_project`, mas sinta-se à vontade para substituir isso por qualquer outra coisa:

    mkdir node_project

Navegue até esse diretório:

    cd node_project

Esse será o diretório raiz do projeto:

Em seguida, crie um arquivo [`package.json`](https://docs.npmjs.com/files/package.json) com as dependências do seu projeto e outras informações de identificação. Abra o arquivo com o `nano` ou o seu editor favorito:

    nano package.json

Adicione as seguintes informações sobre o projeto, incluindo seu nome, autor, licença, ponto de entrada e dependências. Certifique-se de substituir as informações do autor pelo seu próprio nome e seus detalhes de contato:

~/node\_project/package.json

    
    {
      "name": "nodejs-image-demo",
      "version": "1.0.0",
      "description": "nodejs image demo",
      "author": "Sammy the Shark <sammy@example.com>",
      "license": "MIT",
      "main": "app.js",
      "keywords": [
        "nodejs",
        "bootstrap",
        "express"
      ],
      "dependencies": {
        "express": "^4.16.4"
      }
    }

Este arquivo inclui o nome do projeto, autor e a licença sob a qual ele está sendo compartilhado. O npm [recomenda](https://docs.npmjs.com/files/package.json#name) manter o nome do seu projeto curto e descritivo, evitando duplicidades no [registro npm](https://www.npmjs.com/). Listamos a [licença do MIT](https://opensource.org/licenses/MIT) no campo de licença, permitindo o uso e a distribuição gratuitos do código do aplicativo.

Além disso, o arquivo especifica:

- `"main"`: O ponto de entrada para a aplicação, `app.js`. Você criará esse arquivo em seguida.

- `"dependencies"`: As dependências do projeto — nesse caso, Express 4.16.4 ou acima. 

Embora este arquivo não liste um repositório, você pode adicionar um seguindo estas diretrizes em [adicionando um repositório ao seu arquivo `package.json`](https://docs.npmjs.com/files/package.json#repository). Esse é um bom acréscimo se você estiver versionando sua aplicação.

Salve e feche o arquivo quando você terminar de fazer as alterações.

Para instalar as dependências do seu projeto, execute o seguinte comando:

    npm install

Isso irá instalar os pacotes que você listou em seu arquivo `package.json` no diretório do seu projeto.

Agora podemos passar para a construção dos arquivos da aplicação.

## Passo 2 — Criando os Arquivos da Aplicação

Vamos criar um site que oferece aos usuários informações sobre tubarões. Nossa aplicação terá um ponto de entrada principal, `app.js`, e um diretório `views`, que incluirá os recursos estáticos do projeto. A página inicial, `index.html`, oferecerá aos usuários algumas informações preliminares e um link para uma página com informações mais detalhadas sobre tubarões, `sharks.html`. No diretório `views`, vamos criar tanto a página inicial quanto sharks.html.

Primeiro, abra `app.js` no diretório principal do projeto para definir as rotas do projeto:

    nano app.js

A primeira parte do arquivo irá criar a aplicação Express e os objetos Router, e definir o diretório base, a porta, e o host como variáveis:

~/node\_project/app.js

    
    var express = require("express");
    var app = express();
    var router = express.Router();
    
    var path = __dirname + '/views/';
    const PORT = 8080;
    const HOST = '0.0.0.0';

A função `require` carrega o módulo `express`, que usamos então para criar os objetos `app` e `router`. O objeto `router` executará a função de roteamento do aplicativo e, como definirmos as rotas do método HTTP, iremos incluí-las nesse objeto para definir como nossa aplicação irá tratar as solicitações.

Esta seção do arquivo também define algumas variáveis, `path`, `PORT`, e `HOST`:

- `path`: Define o diretório base, que será o subdiretório `views` dentro do diretório atual do projeto.

- `HOST`: Define o endereço ao qual a aplicação se vinculará e escutará. Configurar isto para `0.0.0.0` ou todos os endereços IPv4 corresponde ao comportamento padrão do Docker de expor os containers para `0.0.0.0`, a menos que seja instruído de outra forma.

- `PORT`: Diz à aplicação para escutar e se vincular à porta `8080`.

Em seguida, defina as rotas para a aplicação usando o objeto `router`:

~/node\_project/app.js

    
    ...
    
    router.use(function (req,res,next) {
      console.log("/" + req.method);
      next();
    });
    
    router.get("/",function(req,res){
      res.sendFile(path + "index.html");
    });
    
    router.get("/sharks",function(req,res){
      res.sendFile(path + "sharks.html");
    });

A função `router.use` carrega uma [função de middleware](https://expressjs.com/en/guide/writing-middleware.html) que registrará as solicitações do roteador e as transmitirá para as rotas da aplicação. Estas são definidas nas funções subsequentes, que especificam que uma solicitação GET para a URL base do projeto deve retornar a página `index.html`, enquanto uma requisição GET para a rota `/sharks` deve retornar `sharks.html`.

Finalmente, monte o middleware `router` e os recursos estáticos da aplicação e diga à aplicação para escutar na porta `8080`:

~/node\_project/app.js

    
    ...
    
    app.use(express.static(path));
    app.use("/", router);
    
    app.listen(8080, function () {
      console.log('Example app listening on port 8080!')
    })

O arquivo `app.js` finalizado ficará assim:

~/node\_project/app.js

    
    var express = require("express");
    var app = express();
    var router = express.Router();
    
    var path = __dirname + '/views/';
    const PORT = 8080;
    const HOST = '0.0.0.0';
    
    router.use(function (req,res,next) {
      console.log("/" + req.method);
      next();
    });
    
    router.get("/",function(req,res){
      res.sendFile(path + "index.html");
    });
    
    router.get("/sharks",function(req,res){
      res.sendFile(path + "sharks.html");
    });
    
    app.use(express.static(path));
    app.use("/", router);
    
    app.listen(8080, function () {
      console.log('Example app listening on port 8080!')
    })

Salve e feche o arquivo quando tiver terminado.

Em seguida, vamos adicionar algum conteúdo estático à aplicação. Comece criando o diretório `views`:

    mkdir views

Abra a página inicial, `index.html`:

    nano views/index.html

Adicione o seguinte código ao arquivo, que irá importar o Bootstrap e criar o componente [jumbotron](https://getbootstrap.com/docs/4.0/components/jumbotron/) com um link para a página de informações mais detalhadas `sharks.html`

~/node\_project/views/index.html

    
    <!DOCTYPE html>
    <html lang="en">
    
    <head>
        <title>About Sharks</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css" integrity="sha384-MCw98/SFnGE8fJT3GXwEOngsV7Zt27NXFoaoApmYm81iuXoPkFOJwJ8ERdknLPMO" crossorigin="anonymous">
        <link href="css/styles.css" rel="stylesheet">
        <link href="https://fonts.googleapis.com/css?family=Merriweather:400,700" rel="stylesheet" type="text/css">
    </head>
    
    <body>
        <nav class="navbar navbar-dark navbar-static-top navbar-expand-md">
            <div class="container">
                <button type="button" class="navbar-toggler collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1" aria-expanded="false"> <span class="sr-only">Toggle navigation</span>
                </button> <a class="navbar-brand" href="#">Everything Sharks</a>
                <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
                    <ul class="nav navbar-nav mr-auto">
                        <li class="active nav-item"><a href="/" class="nav-link">Home</a>
                        </li>
                        <li class="nav-item"><a href="/sharks" class="nav-link">Sharks</a>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>
        <div class="jumbotron">
            <div class="container">
                <h1>Want to Learn About Sharks?</h1>
                <p>Are you ready to learn about sharks?</p>
                <br>
                <p><a class="btn btn-primary btn-lg" href="/sharks" role="button">Get Shark Info</a>
                </p>
            </div>
        </div>
        <div class="container">
            <div class="row">
                <div class="col-lg-6">
                    <h3>Not all sharks are alike</h3>
                    <p>Though some are dangerous, sharks generally do not attack humans. Out of the 500 species known to researchers, only 30 have been known to attack humans.
                    </p>
                </div>
                <div class="col-lg-6">
                    <h3>Sharks are ancient</h3>
                    <p>There is evidence to suggest that sharks lived up to 400 million years ago.
                    </p>
                </div>
            </div>
        </div>
    </body>
    
    </html>

A [navbar](https://getbootstrap.com/docs/4.0/components/navbar/) de nível superior aqui, permite que os usuários alternem entre as páginas **Home** e **Sharks**. No subcomponente `navbar-nav`, estamos utilizando a classe `active` do Bootstrap para indicar a página atual ao usuário. Também especificamos as rotas para nossas páginas estáticas, que correspondem às rotas que definimos em `app.js`:

~/node\_project/views/index.html

    
    ...
    <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
       <ul class="nav navbar-nav mr-auto">
          <li class="active nav-item"><a href="/" class="nav-link">Home</a>
          </li>
          <li class="nav-item"><a href="/sharks" class="nav-link">Sharks</a>
          </li>
       </ul>
    </div>
    ...

Além disso, criamos um link para nossa página de informações sobre tubarões no botão do nosso jumbotron:

~/node\_project/views/index.html

    
    ...
    <div class="jumbotron">
       <div class="container">
          <h1>Want to Learn About Sharks?</h1>
          <p>Are you ready to learn about sharks?</p>
          <br>
          <p><a class="btn btn-primary btn-lg" href="/sharks" role="button">Get Shark Info</a>
          </p>
       </div>
    </div>
    ...

Há também um link para uma folha de estilo personalizada no cabeçalho:

~/node\_project/views/index.html

    ...
    <link href="css/styles.css" rel="stylesheet">
    ...

Vamos criar esta folha de estilo no final deste passo.

Salve e feche o arquivo quando terminar.

Com a página inicial da aplicação funcionando, podemos criar nossa página de informações sobre tubarões, `sharks.html`, que oferecerá aos usuários interessados mais informações sobre os tubarões.

Abra o arquivo:

    nano views/sharks.html

Adicione o seguinte código, que importa o Bootstrap e a folha de estilo personalizada, e oferece aos usuários informações detalhadas sobre determinados tubarões:

~/node\_project/views/sharks.html

    <!DOCTYPE html>
    <html lang="en">
    
    <head>
        <title>About Sharks</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.3/css/bootstrap.min.css" integrity="sha384-MCw98/SFnGE8fJT3GXwEOngsV7Zt27NXFoaoApmYm81iuXoPkFOJwJ8ERdknLPMO" crossorigin="anonymous">
        <link href="css/styles.css" rel="stylesheet">
        <link href="https://fonts.googleapis.com/css?family=Merriweather:400,700" rel="stylesheet" type="text/css">
    </head>
    <nav class="navbar navbar-dark navbar-static-top navbar-expand-md">
        <div class="container">
            <button type="button" class="navbar-toggler collapsed" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1" aria-expanded="false"> <span class="sr-only">Toggle navigation</span>
            </button> <a class="navbar-brand" href="/">Everything Sharks</a>
            <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
                <ul class="nav navbar-nav mr-auto">
                    <li class="nav-item"><a href="/" class="nav-link">Home</a>
                    </li>
                    <li class="active nav-item"><a href="/sharks" class="nav-link">Sharks</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>
    <div class="jumbotron text-center">
        <h1>Shark Info</h1>
    </div>
    <div class="container">
        <div class="row">
            <div class="col-lg-6">
                <p>
                    <div class="caption">Some sharks are known to be dangerous to humans, though many more are not. The sawshark, for example, is not considered a threat to humans.
                    </div>
                    <img src="https://assets.digitalocean.com/articles/docker_node_image/sawshark.jpg" alt="Sawshark">
                </p>
            </div>
            <div class="col-lg-6">
                <p>
                    <div class="caption">Other sharks are known to be friendly and welcoming!</div>
                    <img src="https://assets.digitalocean.com/articles/docker_node_image/sammy.png" alt="Sammy the Shark">
                </p>
            </div>
        </div>
    </div>
    
    </html>

Observe que neste arquivo, usamos novamente a classe `active` para indicar a página atual.

Salve e feche o arquivo quando tiver terminado.

Finalmente, crie a folha de estilo CSS personalizada que você vinculou em `index.html` e `sharks.html` criando primeiro uma pasta `css` no diretório `views`:

    mkdir views/css

Abra a folha de estilo:

    nano views/css/styles.css

Adicione o seguinte código, que irá definir a cor desejada e a fonte para nossas páginas:

~/node\_project/views/css/styles.css

    
    .navbar {
        margin-bottom: 0;
        background: #000000;
    }
    
    body {
        background: #000000;
        color: #ffffff;
        font-family: 'Merriweather', sans-serif;
    }
    
    h1,
    h2 {
        font-weight: bold;
    }
    
    p {
        font-size: 16px;
        color: #ffffff;
    }
    
    .jumbotron {
        background: #0048CD;
        color: white;
        text-align: center;
    }
    
    .jumbotron p {
        color: white;
        font-size: 26px;
    }
    
    .btn-primary {
        color: #fff;
        text-color: #000000;
        border-color: white;
        margin-bottom: 5px;
    }
    
    img,
    video,
    audio {
        margin-top: 20px;
        max-width: 80%;
    }
    
    div.caption: {
        float: left;
        clear: both;
    }

Além de definir a fonte e a cor, esse arquivo também limita o tamanho das imagens especificando `max-width` ou largura máxima de 80%. Isso evitará que ocupem mais espaço do que gostaríamos na página.

Salve e feche o arquivo quando tiver terminado.

Com os arquivos da aplicação no lugar e as dependências do projeto instaladas, você está pronto para iniciar a aplicação.

Se você seguiu o tutorial de configuração inicial do servidor nos pré-requisitos, você terá um firewall ativo que permita apenas o tráfego SSH. Para permitir o tráfego para a porta `8080`, execute:

    sudo ufw allow 8080

Para iniciar a aplicação, certifique-se de que você está no diretório raiz do seu projeto:

    cd ~/node_project

Inicie sua aplicação com `node app.js`:

    node app.js

Dirija seu navegador para `http://ip_do_seu_servidor:8080`. Você verá a seguinte página inicial:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_node_image/landing_page.png)

Clique no botão **Get Shark Info**. Você verá a seguinte página de informações:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_node_image/sharks.png)

Agora você tem uma aplicação instalada e funcionando. Quando estiver pronto, saia do servidor digitando `CTRL + C`. Agora podemos passar a criar o Dockerfile que nos permitirá recriar e escalar essa aplicação conforme desejado.

## Step 3 — Escrevendo o Dockerfile

Seu Dockerfile especifica o que será incluído no container de sua aplicação quando for executado. A utilização de um Dockerfile permite que você defina seu ambiente de container e evite discrepâncias com dependências ou versões de runtime.

Seguindo [estas diretrizes na construção de containers otimizados](building-optimized-containers-for-kubernetes), vamos tornar nossa imagem o mais eficiente possível, minimizando o número de camadas de imagem e restringindo a função da imagem a uma única finalidade — recriar nossos arquivos da aplicação e o conteúdo estático.

No diretório raiz do seu projeto, crie o Dockerfile:

    nano Dockerfile

As imagens do Docker são criadas usando uma sucessão de imagens em camadas que são construídas umas sobre as outras. Nosso primeiro passo será adicionar a _imagem base_ para a nossa aplicação que formará o ponto inicial da construção da aplicação.

Vamos utilizar a [imagem `node:10`](https://hub.docker.com/_/node/), uma vez que, no momento da escrita desse tutorial, esta é a [versão LTS reomendada do Node.js](https://nodejs.org/en/). Adicione a seguinte instrução `FROM` para definir a imagem base da aplicação:

~/node\_project/Dockerfile

    FROM node:10

Esta imagem inclui Node.js e npm. Cada Dockerfile deve começar com uma instrução `FROM`.

Por padrão, a imagem Node do Docker inclui um usuário não-root **node** que você pode usar para evitar a execução de seu container de aplicação como **root**. Esta é uma prática de segurança recomendada para evitar executar containers como **root** e para [restringir recursos dentro do container](https://docs.docker.com/engine/security/security/#linux-kernel-capabilities) para apenas aqueles necessários para executar seus processos. Portanto, usaremos o diretório home do usuário **node** como o diretório de trabalho de nossa aplicação e o definiremos como nosso usuário dentro do container. Para mais informações sobre as melhores práticas ao trabalhar com a imagem Node do Docker, veja este [guia de melhores práticas](https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md).

Para um ajuste fino das permissões no código da nossa aplicação no container, vamos criar o subdiretório `node_modules` em `/home/node` juntamente com o diretório `app`. A criação desses diretórios garantirá que eles tenham as permissões que desejamos, o que será importante quando criarmos módulos de node locais no container com `npm install`. Além de criar esses diretórios, definiremos a propriedade deles para o nosso usuário **node** :

~/node\_project/Dockerfile

    ...
    RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app

Para obter mais informações sobre o utilitário de consolidação das instruções `RUN`, veja esta [discussão sobre como gerenciar camadas de container](building-optimized-containers-for-kubernetes#managing-container-layers).

Em seguida, defina o diretório de trabalho da aplicação para `/home/node/app`:

~/node\_project/Dockerfile

    ...
    WORKDIR /home/node/app

Se `WORKDIR` não estiver definido, o Docker irá criar um por padrão, então é uma boa ideia defini-lo explicitamente.

A seguir, copie os arquivos `package.json` e `package-lock.json` (para npm 5+):

~/node\_project/Dockerfile

    ...
    COPY package*.json ./

Adicionar esta instrução `COPY` antes de executar o `npm install` ou copiar o código da aplicação nos permite aproveitar o mecanismo de armazenamento em cache do Docker. Em cada estágio da compilação ou build, o Docker verificará se há uma camada armazenada em cache para essa instrução específica. Se mudarmos o `package.json`, esta camada será reconstruída, mas se não o fizermos, esta instrução permitirá ao Docker usar a camada de imagem existente e ignorar a reinstalação dos nossos módulos de node.

Depois de copiar as dependências do projeto, podemos executar `npm install`:

~/node\_project/Dockerfile

    ...
    RUN npm install

Copie o código de sua aplicação para o diretório de trabalho da mesma no container:

~/node\_project/Dockerfile

    ...
    COPY . .

Para garantir que os arquivos da aplicação sejam de propriedade do usuário não-root **node** , copie as permissões do diretório da aplicação para o diretório no container:

~/node\_project/Dockerfile

    ...
    COPY --chown=node:node . .

Defina o usuário para **node** :

~/node\_project/Dockerfile

    ...
    USER node

Exponha a porta `8080` no container e inicie a aplicação:

~/node\_project/Dockerfile

    ...
    EXPOSE 8080
    
    CMD ["node", "app.js"]

`EXPOSE` não publica a porta, mas funciona como uma maneira de documentar quais portas no container serão publicadas em tempo de execução. `CMD` executa o comando para iniciar a aplicação - neste caso, [`node app.js`](https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md#cmd). Observe que deve haver apenas uma instrução `CMD` em cada Dockerfile. Se você incluir mais de uma, somente a última terá efeito.

Há muitas coisas que você pode fazer com o Dockerfile. Para obter uma lista completa de instruções, consulte a documentação de [referência Dockerfile do Docker](https://docs.docker.com/engine/reference/builder/)

O Dockerfile completo estará assim:

~/node\_project/Dockerfile

    
    FROM node:10
    
    RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app
    
    WORKDIR /home/node/app
    
    COPY package*.json ./
    
    RUN npm install
    
    COPY . .
    
    COPY --chown=node:node . .
    
    USER node
    
    EXPOSE 8080
    
    CMD ["node", "app.js"]

Salve e feche o arquivo quando terminar a edição.

Antes de construir a imagem da aplicação, vamos adicionar um [arquivo `.dockerignore`](https://docs.docker.com/engine/reference/builder/#dockerignore-file). Trabalhando de maneira semelhante a um [arquivo `.gitignore`](https://git-scm.com/docs/gitignore), `.dockerignore` especifica quais arquivos e diretórios no diretório do seu projeto não devem ser copiados para o seu container.

Abra o arquivo `.dockerignore`:

    nano .dockerignore

Dentro do arquivo, adicione seus módulos de node, logs npm, Dockerfile, e o arquivo `.dockerignore`:

~/node\_project/.dockerignore

    node_modules
    npm-debug.log
    Dockerfile
    .dockerignore

Se você estiver trabalhando com o [Git](https://git-scm.com/), então você também vai querer adicionar o seu diretório `.git` e seu arquivo `.gitignore`.

Salve e feche o arquivo quando tiver terminado.

Agora você está pronto para construir a imagem da aplicação usando o comando [`docker build`](https://docs.docker.com/engine/reference/commandline/build/). Usar a flag `-t` com o `docker build` permitirá que você marque a imagem com um nome memorizável. Como vamos enviar a imagem para o Docker Hub, vamos incluir nosso nome de usuário do Docker Hub na tag. Vamos marcar a imagem como `nodejs-image-demo`, mas sinta-se à vontade para substituir isto por um nome de sua escolha. Lembre-se também de substituir `seu_usuário_dockerhub` pelo seu nome real de usuário do Docker Hub:

    docker build -t seu_usuário_dockerhub/nodejs-image-demo .

O `.` especifica que o contexto do build é o diretório atual.

Levará um ou dois minutos para construir a imagem. Quando estiver concluído, verifique suas imagens:

    docker images

Você verá a seguinte saída:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    seu_usuário_dockerhub/nodejs-image-demo latest 1c723fb2ef12 8 seconds ago 895MB
    node 10 f09e7c96b6de 17 hours ago 893MB

É possível criar um container com essa imagem usando [`docker run`](https://docs.docker.com/engine/reference/commandline/run/). Vamos incluir três flags com esse comando:

- `-p`: Isso publica a porta no container e a mapeia para uma porta em nosso host. Usaremos a porta `80` no host, mas sinta-se livre para modificá-la, se necessário, se tiver outro processo em execução nessa porta. Para obter mais informações sobre como isso funciona, consulte esta discussão nos documentos do Docker sobre [port binding](https://docs.docker.com/v17.09/engine/userguide/networking/default_network/binding/).

- `-d`: Isso executa o container em segundo plano.

- `--name`: Isso nos permite dar ao container um nome memorizável.

Execute o seguinte comando para construir o container:

    docker run --name nodejs-image-demo -p 80:8080 -d seu_usuário_dockerhub/nodejs-image-demo 

Depois que seu container estiver em funcionamento, você poderá inspecionar uma lista de containers em execução com [`docker ps`](https://docs.docker.com/engine/reference/commandline/ps/):

    docker ps

Você verá a seguinte saída:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    e50ad27074a7 seu_usuário_dockerhub/nodejs-image-demo "node app.js" 8 seconds ago Up 7 seconds 0.0.0.0:80->8080/tcp nodejs-image-demo

Com seu container funcionando, você pode visitar a sua aplicação apontando seu navegador para `http://ip_do_seu_servidor`. Você verá a página inicial da sua aplicação novamente:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_node_image/landing_page.png)

Agora que você criou uma imagem para sua aplicação, você pode enviá-la ao Docker Hub para uso futuro.

## Passo 4 — Usando um Repositório para Trabalhar com Imagens

Ao enviar sua imagem de aplicação para um registro como o Docker Hub, você a torna disponível para uso subsequente à medida que cria e escala seus containers. Vamos demonstrar como isso funciona, enviando a imagem da aplicação para um repositório e, em seguida, usando a imagem para recriar nosso container.

A primeira etapa para enviar a imagem é efetuar login na conta do Docker Hub que você criou nos pré-requisitos:

    docker login -u seu_usuário_dockerhub -p senha_do_usuário_dockerhub

Efetuando o login dessa maneira será criado um arquivo `~/.docker/config.json` no diretório home do seu usuário com suas credenciais do Docker Hub.

Agora você pode enviar a imagem da aplicação para o Docker Hub usando a tag criada anteriormente, `seu_usuário_dockerhub/nodejs-image-demo`:

    docker push seu_usuário_dockerhub/nodejs-image-demo

Vamos testar o utilitário do registro de imagens destruindo nosso container e a imagem de aplicação atual e reconstruindo-os com a imagem em nosso repositório.

Primeiro, liste seus containers em execução:

    docker ps

Você verá a seguinte saída:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    e50ad27074a7 seu_usuário_dockerhub/nodejs-image-demo "node app.js" 3 minutes ago Up 3 minutes 0.0.0.0:80->8080/tcp nodejs-image-demo

Usando o `CONTAINER ID` listado em sua saída, pare o container da aplicação em execução. Certifique-se de substituir o ID destacado abaixo por seu próprio `CONTAINER ID`:

    docker stop e50ad27074a7

Liste todas as suas imagens com a flag `-a`:

    docker images -a

Você verá a seguinte saída com o nome da sua imagem, seu_usuário_dockerhub/nodejs-image-demo, juntamente com a imagem `node` e outras imagens do seu build.

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    seu_usuário_dockerhub/nodejs-image-demo latest 1c723fb2ef12 7 minutes ago 895MB
    <none> <none> e039d1b9a6a0 7 minutes ago 895MB
    <none> <none> dfa98908c5d1 7 minutes ago 895MB
    <none> <none> b9a714435a86 7 minutes ago 895MB
    <none> <none> 51de3ed7e944 7 minutes ago 895MB
    <none> <none> 5228d6c3b480 7 minutes ago 895MB
    <none> <none> 833b622e5492 8 minutes ago 893MB
    <none> <none> 5c47cc4725f1 8 minutes ago 893MB
    <none> <none> 5386324d89fb 8 minutes ago 893MB
    <none> <none> 631661025e2d 8 minutes ago 893MB
    node 10 f09e7c96b6de 17 hours ago 893MB

Remova o container parado e todas as imagens, incluindo imagens não utilizadas ou pendentes, com o seguinte comando:

    docker system prune -a

Digite `y` quando solicitado na saída para confirmar que você gostaria de remover o container e as imagens parados. Esteja ciente de que isso também removerá seu cache de compilação.

Agora você removeu o container que está executando a imagem da sua aplicação e a própria imagem. Para obter mais informações sobre como remover containers, imagens e volumes do Docker, consulte [How To Remove Docker Images, Containers, and Volumes](how-to-remove-docker-images-containers-and-volumes).

Com todas as suas imagens e containers excluídos, agora você pode baixar a imagem da aplicação do Docker Hub:

    docker pull seu_usuário_dockerhub/nodejs-image-demo

Liste suas imagens mais uma vez:

    docker images

Você verá a imagem da sua aplicação:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    seu_usuário_dockerhub/nodejs-image-demo latest 1c723fb2ef12 11 minutes ago 895MB

Agora você pode reconstruir seu container usando o comando do Passo 3:

    docker run --name nodejs-image-demo -p 80:8080 -d seu_usuário_dockerhub/nodejs-image-demo

Liste seus containers em execução:

    docker ps

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    f6bc2f50dff6 seu_usuário_dockerhub/nodejs-image-demo "node app.js" 4 seconds ago Up 3 seconds 0.0.0.0:80->8080/tcp nodejs-image-demo

Visite `http://ip_do_seu_servidor` mais uma vez para ver a sua aplicação em execução.

## Conclusão

Neste tutorial, você criou uma aplicação web estática com Express e Bootstrap, bem como uma imagem do Docker para esta aplicação. Você utilizou essa imagem para criar um container e enviou a imagem para o Docker Hub. A partir daí, você conseguiu destruir sua imagem e seu container e recriá-los usando seu repositório do Docker Hub.

Se você estiver interessado em aprender mais sobre como trabalhar com ferramentas como o Docker Compose e o Docker Machine para criar configurações de vários containers, consulte os seguintes guias:

- [How To Install Docker Compose on Ubuntu 18.04](how-to-install-docker-compose-on-ubuntu-18-04).

- [How To Provision and Manage Remote Docker Hosts with Docker Machine on Ubuntu 18.04](how-to-provision-and-manage-remote-docker-hosts-with-docker-machine-on-ubuntu-18-04).

Para dicas gerais sobre como trabalhar com dados de container, consulte:

- [How To Share Data between Docker Containers](how-to-share-data-between-docker-containers).

- [How To Share Data Between the Docker Container and the Host](how-to-share-data-between-the-docker-container-and-the-host).

Se você estiver interessado em outros tópicos relacionados ao Docker, consulte nossa biblioteca completa de [tutoriais do Docker](https://www.digitalocean.com/community/tags/docker/tutorials).

_Por Kathleen Juell_
