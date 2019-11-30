---
author: Justin Ellingwood
date: 2015-05-26
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-node-js-em-um-servidor-ubuntu-14-04-pt
---

# Como Instalar o Node.js em um Servidor Ubuntu 14.04

### Introdução

O Node.js é uma plataforma Javascript para programação do lado servidor, que permite aos usuários construírem aplicações de rede rapidamente. Ao levar o Javascript tanto ao front-end quanto ao back-end, o desenvolvimento pode ser mais consistente e ser projetado dentro do mesmo sistema.

Neste guia, vamos mostrar a você como começar com o Node.js em um servidor Ubuntu 14.04.

Se você estiver buscando criar um ambiente de produção Node.js, confira este link [How To Set Up a Node.js Application for Production.](how-to-set-up-a-node-js-application-for-production-on-ubuntu-14-04)

## Como Instalar a Versão Distro-Stable

O Ubuntu 14.04 contém uma versão do Node.js em seus repositórios padrão que pode ser utilizada para fornecer facilmente uma experiência consistente entre múltiplos servidores. A versão nesses repositórios é a 0.10.25. Esta não é a última versão, mas deve ser bastante estável.

Para obter esta versão, temos apenas que utilizar o gerenciador de pacotes `apt`. Devemos atualizar nosso índice de pacotes e, então, instalar através dos repositórios:

    sudo apt-get update
    sudo apt-get install nodejs

Se o pacote no repositório satisfaz suas necessidades, isto é tudo que você precisa fazer para ter o Node.js configurado. Em muitos casos, você vai querer também instalar o `npm`, que é o gerenciador de pacotes do Node.js. Você pode fazer isto digitando:

    sudo apt-get install npm

Isto o permitirá instalar facilmente módulos e pacotes para utilizar com o Node.js.

Devido a um conflito com outro pacote, o executável dos repositórios do Ubuntu é chamado `nodejs` em vez de `node`. Tenha isso em mente quando estiver executando software.

Abaixo, discutiremos alguns métodos mais flexíveis de instalação.

## Como Instalar Utilizando um PPA

Uma alternativa que pode lhe trazer a versão mais recente do Node.js é adicionar um PPA (arquivo de pacotes pessoais) mantido pelo NodeSource. Isto terá provavelmente versões mais atualizadas do Node.js do que os repositórios oficiais do Ubuntu.

Primeiro, você precisa instalar o PPA de modo a obter acesso ao seu conteúdo:

    curl -sL https://deb.nodesource.com/setup | sudo bash -

O PPA será adicionado à sua configuração e o seu cache local de pacotes será atualizado automaticamente. Depois de executar o script de configuração do nodesource, você pode instalar o pacote Node.js da mesma forma que você fez acima:

    sudo apt-get install nodejs

O pacote `nodejs` contém o binário `nodejs` bem como o `npm`, de forma que você não precisa instalar o `npm` separadamente. Contudo, para que alguns pacotes do `npm` funcionem (tais como aqueles que requerem compilação do fonte), você precisará instalar o pacote `build-essentials`:

    sudo apt-get install build-essential

## Como Instalar Utilizando o NVM

Uma alternativa para instalação do Node.js através do `apt` é usar uma ferramenta especialmente projetada, chamada `nvm`, que significa “Node.js version manager” ou “Gerenciador de Versão do Node.js”.

Usando o `nvm` você pode instalar múltiplas versões, auto-contidas do Node.js que o permitirá controlar seu ambiente mais facilmente. Ele dará a você acesso sob demanda às mais novas versões do Node.js, mas também o permitirá apontar versões prévias que suas aplicações podem depender.

Para começar, precisaremos obter os pacotes de software do nosso repositório Ubuntu, que nos permitirão compilar pacotes de fontes. O script nvm aproveitará estas ferramentas para construir os componentes necessários:

    sudo apt-get update
    sudo apt-get install build-essential libssl-dev

Uma vez que os pacotes requeridos estejam instalados, você pode baixar o script de instalação do nvm da [página do projeto GitHub](https://github.com/creationix/nvm). O número de versão pode ser diferente, mas em geral, você pode baixar e o instalar com a seguinte sintaxe:

    curl https://raw.githubusercontent.com/creationix/nvm/v0.16.1/install.sh | sh

Isto irá baixar o script e o executar. Ele irá instalar o software dentro de um subdiretório do seu diretório home em `~/.nvm`. Ele irá adicionar também as linhas necessárias ao seu arquivo `~/.profile` para utilizar o arquivo.

Para obter acesso à funcionalidade do nvm, você precisará sair e se logar novamente, ou você pode varrer o arquivo `~/.profile` de modo que sua sessão atual saiba sobre as alterações:

    source ~/.profile

Agora que você tem o nvm instalado, você pode instalar versões isoladas do Node.js.

Para encontrar as versões do Node.js que estão disponíveis para instalação, você pode digitar:

    nvm ls-remote
    
    . . .
     v0.11.6
     v0.11.7
     v0.11.8
     v0.11.9
    v0.11.10
    v0.11.11
    v0.11.12
    v0.11.13

Como você pode ver, a versão mais recente no momento da redação deste artigo é a v0.11.13. Você pode instalá-la digitando:

    nvm install 0.11.13

Usualmente, o nvm irá utilizar a versão mais recente instalada. Você pode dizer explicitamente ao nvm para utilizar a versão que acabamos de baixar digitando:

    nvm use 0.11.13

Quando você instala o Node.js utilizando o nvm, o executável é chamado `node`. Você pode ver a versão atualmente sendo utilizada pelo shell digitando:

    node -v
    
    v.0.11.13

Se você tiver múltiplas versões do Node.js, você pode ver o que está instalado digitando:

    nvm ls

Se desejar tornar padrão uma das versões, você pode digitar:

    nvm alias default 0.11.13

Esta versão será automaticamente selecionada quando uma nova sessão for iniciada. Você também pode referenciá-la pelo apelido desta maneira:

    nvm use default

Cada versão do Node.js irá manter o controle de seus próprios pacotes e tem `npm` disponível para gerenciá-los.

Você pode ter pacotes de instalação do `npm` para o diretório `./node_modules` do projeto Node.js utilizando o formato normal:

    npm install express

Se você deseja instalá-lo globalmente (disponível para outros projetos utilizando a mesma versão de Node.js), você pode adicionar o flag `-g`:

    npm install -g express

Isto instalará o pacote em:

    ~/.nvm/node_version/lib/node_modules/package_name

Instalando globalmente permitirá a você executar comandos através da linha de comando, mas você terá que vincular o pacote em sua esfera local para exigi-lo de dentro de um programa:

    npm link express

Você pode aprender mais sobre as opções disponíveis com o nvm digitando:

    nvm help

## Conclusão

Como você pode ver, existem algumas maneiras de se instalar e executar o Node.js em seu servidor Ubuntu 14.04. Suas circunstâncias irão ditar quais dos métodos acima é a melhor ideia para sua necessidade. Embora a versão empacotada no repositório do Ubuntu seja a mais fácil, o método do nvm é, definitivamente, o mais flexível.
