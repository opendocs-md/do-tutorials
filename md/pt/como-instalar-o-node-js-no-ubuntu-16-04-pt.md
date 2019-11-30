---
author: Brennen Bearnes
date: 2016-12-12
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-node-js-no-ubuntu-16-04-pt
---

# Como Instalar o Node.js no Ubuntu 16.04

### Introdução

O Node.js é uma plataforma Javascript para programação de propósito geral, que permite aos usuários construírem aplicações de rede rapidamente. Ao levar o Javascript tanto ao front-end quanto ao back-end, o desenvolvimento pode ser mais consistente e ser projetado dentro do mesmo sistema.

Neste guia, vamos mostrar a você como começar com o Node.js em um servidor Ubuntu 16.04.

Se você estiver buscando configurar um ambiente de produção Node.js, confira este link: [How To Set Up a Node.js Application for Production](how-to-set-up-a-node-js-application-for-production-on-ubuntu-14-04).

## Pré-requisitos

Este guia assume que você está utilizando o Ubuntu 16.04. Antes de você iniciar com este guia, você deve ter uma conta de usuário que não seja root, com privilégios `sudo`, configurada em seu servidor. Você pode aprender como fazer isto completando os passos 1-4 na [configuração inicial do servidor para Ubuntu 16.04](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-16-04).

## Como Instalar a Versão Distro-Stable para Ubuntu

O Ubuntu 16.04 contém uma versão do Node.js em seus repositórios padrão que pode ser utilizada para fornecer facilmente uma experiência consistente entre múltiplos servidores. No momento da redação, a versão nos repositórios é a v4.2.6. Esta não será a última versão, mas deve ser bastante estável, e deve ser suficiente para uma experimentação rápida com a linguagem.

Para obter esta versão, temos apenas que utilizar o gerenciador de pacotes `apt`. Devemos atualizar nosso índice de pacotes primeiro e então, instalar através dos repositórios:

    sudo apt-get update
    sudo apt-get install nodejs

Se o pacote no repositório satisfaz suas necessidades, isto é tudo que você precisa fazer para ter o Node.js configurado. Em muitos casos, você vai querer também instalar o `npm`, que é o gerenciador de pacotes do Node.js. Você pode fazer isto digitando:

    sudo apt-get install npm

Isto o permitirá instalar facilmente módulos e pacotes para utilizar com o Node.js.

Devido a um conflito com outro pacote, o executável dos repositórios do Ubuntu é chamado `nodejs` em vez de `node`. Tenha isso em mente quando estiver executando software.

A seguir, discutiremos alguns métodos mais flexíveis e robustos de instalação.

## Como Instalar Utilizando um PPA

Uma alternativa que pode lhe trazer a versão mais recente do Node.js é adicionar um PPA (arquivo de pacotes pessoais) mantido pelo NodeSource. Isto terá provavelmente versões mais atualizadas do Node.js do que os repositórios oficiais do Ubuntu, e o permitirá escolher entre Node.js v4.x (a mais antiga versão com suporte de longo prazo, suportada até Abril de 2017), v6.x (a versão LTS mais recente, que será suportada até Abril de 2018), e Node.js v7.x (a versão ativamente desenvolvida atualmente).

Primeiro, você precisa instalar o PPA de modo a obter acesso ao seu conteúdo. Certifique-se de que você está em seu diretório home, e use `curl` para buscar o script para sua versão preferida, tendo certeza de substituir 6.x pela string correta da versão:

    cd ~
    curl -sL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh

Você pode inspecionar o conteúdo desse script com o `nano` (nosso editor de textos preferido):

    nano nodesource_setup.sh

E execute o script sob o `sudo`:

    sudo bash nodesource_setup.sh

O PPA será adicionado à sua configuração e o seu cache local de pacotes será atualizado automaticamente. Depois de executar o script de configuração do nodesource, você pode instalar o pacote Node.js da mesma forma que você fez acima:

    sudo apt-get install nodejs

O pacote `nodejs` contém o binário `nodejs` bem como o `npm`, de forma que você não precisa instalar o `npm` separadamente. Contudo, para que alguns pacotes do `npm` funcionem (tais como aqueles que requerem compilação do fonte), você precisará instalar o pacote `build-essential`:

    sudo apt-get install build-essential

## Como Instalar Utilizando o NVM

Uma alternativa para instalação do Node.js através do `apt` é usar uma ferramenta especialmente projetada, chamada `nvm`, que significa “Node.js version manager” ou “Gerenciador de Versão do Node.js”.

Usando o `nvm` você pode instalar múltiplas versões, auto-contidas do Node.js que o permitirá controlar seu ambiente mais facilmente. Ele dará a você acesso sob demanda às mais novas versões do Node.js, mas também o permitirá apontar versões prévias que suas aplicações podem depender.

Para começar, precisaremos obter os pacotes de software do nosso repositório Ubuntu, que nos permitirão compilar pacotes de fontes. O script nvm aproveitará estas ferramentas para construir os componentes necessários:

    sudo apt-get update
    sudo apt-get install build-essential libssl-dev

Uma vez que os pacotes requeridos estejam instalados, você pode baixar o script de instalação do nvm da [página do projeto GitHub](https://github.com/creationix/nvm). O número de versão pode ser diferente, mas em geral, você pode baixá-lo com o `curl`:

    curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh -o install_nvm.sh

E inspecionar o script de instalação com o `nano`:

    nano install_nvm.sh

Execute o script com o `bash`:

    bash install_nvm.sh

Ele irá instalar o software dentro de um subdiretório do seu diretório home em `~/.nvm`. Ele irá adicionar também as linhas necessárias ao seu arquivo `~/.profile` para utilizar o arquivo.

Para obter acesso à funcionalidade do nvm, você precisará sair e se logar novamente, ou você pode varrer o arquivo `~/.profile` de modo que sua sessão atual saiba sobre as alterações:

    source ~/.profile

Agora que você tem o nvm instalado, você pode instalar versões isoladas do Node.js.

Para encontrar as versões do Node.js que estão disponíveis para instalação, você pode digitar:

    nvm ls-remote

    Output...
             v5.8.0
             v5.9.0
             v5.9.1
            v5.10.0
            v5.10.1
            v5.11.0
             v6.0.0
    

Como você pode ver, a versão mais recente no momento da redação deste artigo é a v6.0.0. Você pode instalá-la digitando:

    nvm install 6.0.0

Geralmente, o nvm irá mudar para utilizar a versão mais recente instalada. Você pode dizer explicitamente ao nvm para utilizar a versão que acabamos de baixar digitando:

    nvm use 6.0.0

Quando você instala o Node.js utilizando o nvm, o executável é chamado `node`. Você pode ver a versão atualmente sendo utilizada pelo shell digitando:

    node -v

    Outputv6.0.0

Se você tiver múltiplas versões do Node.js, você pode ver o que está instalado digitando:

    nvm ls

Se desejar tornar padrão uma das versões, você pode digitar:

    nvm alias default 6.0.0

Esta versão será automaticamente selecionada quando uma nova sessão for iniciada. Você também pode referenciá-la pelo apelido desta maneira:

    nvm use default

Cada versão do Node.js irá manter o controle de seus próprios pacotes e tem `npm` disponível para gerenciá-los.

Você pode ter pacotes de instalação do `npm` para o diretório `./node_modules` do projeto Node.js utilizando o formato normal. Por exemplo, para o módulo `express`:

    npm install express

Se você deseja instalá-lo globalmente (tornando-o disponível para os outros projetos que utilizam a mesma versão de Node.js), você pode adicionar o flag `-g`:

    npm install -g express

Isto instalará o pacote em:

    ~/.nvm/node_version/lib/node_modules/package_name

Instalando globalmente permitirá a você executar comandos através da linha de comando, mas você terá que vincular o pacote em sua esfera local para exigi-lo de dentro de um programa:

    npm link express

Você pode aprender mais sobre as opções disponíveis com o nvm digitando:

    nvm help

## Conclusão

Como você pode ver, existem algumas maneiras de se instalar e executar o Node.js em seu servidor Ubuntu 16.04. Suas circunstâncias irão ditar quais dos métodos acima é a melhor ideia para sua necessidade. Embora a versão empacotada no repositório do Ubuntu seja a mais fácil, o método do `nvm` é, definitivamente, o mais flexível.
