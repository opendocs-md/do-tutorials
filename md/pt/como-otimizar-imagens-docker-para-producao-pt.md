---
author: Adnan Rahić
date: 2019-05-07
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-otimizar-imagens-docker-para-producao-pt
---

# Como Otimizar Imagens Docker para Produção

_O autor escolheu a [Code.org](https://www.brightfunds.org/organizations/code-org) para receber uma doação como parte do programa [Write for DOnations](https://do.co/w4do-cta)._

### Introdução

Em um ambiente de produção, o [Docker](https://www.docker.com/) facilita a criação, o deployment e a execução de aplicações dentro de containers. Os containers permitem que os desenvolvedores reúnam aplicações e todas as suas principais necessidades e dependências em um único pacote que você pode transformar em uma imagem Docker e replicar. As imagens Docker são construídas a partir de [Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/). O Dockerfile é um arquivo onde você define como será a imagem, qual sistema operacional básico ela terá e quais comandos serão executados dentro dela.

Imagens Docker muito grandes podem aumentar o tempo necessário para criar e enviar imagens entre clusters e provedores de nuvem. Se, por exemplo, você tem uma imagem do tamanho de um gigabyte para enviar toda vez que um de seus desenvolvedores aciona uma compilação, a taxa de transferência que você cria em sua rede aumentará durante o processo de CI/CD, tornando sua aplicação lenta e, consequentemente, custando seus recursos. Por causa disso, as imagens Docker adequadas para produção devem ter apenas as necessidades básicas instaladas.

Existem várias maneiras de diminuir o tamanho das imagens Docker para otimizá-las para a produção. Em primeiro lugar, essas imagens geralmente não precisam de ferramentas de compilação para executar suas aplicações e, portanto, não há necessidade de adicioná-las. Através do uso de um [processo de construção multi-stage](https://docs.docker.com/develop/develop-images/multistage-build/), você pode usar imagens intermediárias para compilar e construir o código, instalar dependências e empacotar tudo no menor tamanho possível, depois copiar a versão final da sua aplicação para uma imagem vazia sem ferramentas de compilação. Além disso, você pode usar uma imagem com uma base pequena, como o [Alpine Linux](https://alpinelinux.org/about/). O Alpine é uma distribuição Linux adequada para produção, pois possui apenas as necessidades básicas que sua aplicação precisa para executar.

Neste tutorial, você otimizará as imagens Docker em algumas etapas simples, tornando-as menores, mais rápidas e mais adequadas à produção. Você construirá imagens para um exemplo de [API em Go](https://github.com/do-community/mux-go-api) em vários containers Docker diferentes, começando com o Ubuntu e imagens específicas de linguagens, e então passando para a distribuição Alpine. Você também usará compilações multi-stage para otimizar suas imagens para produção. O objetivo final deste tutorial é mostrar a diferença de tamanho entre usar imagens padrão do Ubuntu e as equivalentes otimizadas, e mostrar a vantagem das compilações em vários estágios (multi-stage). Depois de ler este tutorial, você poderá aplicar essas técnicas aos seus próprios projetos e pipelines de CI/CD.

**Nota:** Este tutorial utiliza uma API escrita em [Go](https://golang.org/) como um exemplo. Esta simples API lhe dará uma compreensão clara de como você abordaria a otimização de microsserviços em Go com imagens Docker. Embora este tutorial use uma API Go, você pode aplicar esse processo a praticamente qualquer linguagem de programação.

## Pré-requisitos

Antes de começar, você precisará de:

- Um servidor Ubuntu 18.04 com uma conta não-root com privilégios `sudo`. Siga nosso tutorial de [Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt) para orientações. Embora este tutorial tenha sido testado no Ubuntu 18.04, você pode seguir muitos dos passos em qualquer distribuição Linux. 

- Docker instalado em seu servidor. Por favor, siga os Passos 1 e 2 do tutorial [Como Instalar e Usar o Docker no Ubuntu 18.04](como-instalar-e-usar-o-docker-no-ubuntu-18-04-pt) para instruções de instalação.

## Passo 1 — Baixando a API Go de Exemplo

Antes de otimizar sua imagem Docker, você deve primeiro fazer o download da [API](https://github.com/do-community/mux-go-api) de exemplo, a partir da qual você construirá suas imagens Docker. O uso de uma API Go simples mostrará todas as principais etapas de criação e execução de uma aplicação dentro de um container Docker. Este tutorial usa o Go porque é uma linguagem compilada como o [C++](https://en.wikipedia.org/wiki/C%2B%2B) ou [Java](https://www.java.com/en/), mas ao contrário dele, tem uma pegada muito pequena.

No seu servidor, comece clonando a API Go de exemplo:

    git clone https://github.com/do-community/mux-go-api.git

Depois de clonar o projeto, você terá um diretório chamado `mux-go-api` em seu servidor. Mova-se para este diretório com `cd`:

    cd mux-go-api

Este será o diretório home do seu projeto. Você construirá suas imagens Docker a partir desse diretório. Dentro dele você encontrará o código fonte para uma API escrita em Go no arquivo `api.go`. Embora essa API seja mínima e tenha apenas alguns endpoints, ela será apropriada para simular uma API pronta para produção para os propósitos deste tutorial.

Agora que você baixou a API Go de exemplo, você está pronto para criar uma imagem base do Ubuntu no Docker, com a qual você poderá comparar as imagens posteriores e otimizadas.

## Passo 2 — Construindo uma Imagem Base do Ubuntu

Para a sua primeira imagem Docker, será útil ver como ela é quando você começa com uma imagem base do Ubuntu. Isso irá empacotar sua API de exemplo em um ambiente similar ao software que você já está rodando no seu servidor Ubuntu. Isso irá empacotar sua API de exemplo em um ambiente similar ao software que você já está rodando no seu servidor Ubuntu. Dentro da imagem, você instalará os vários pacotes e módulos necessários para executar sua aplicação. Você descobrirá, no entanto, que esse processo cria uma imagem bastante pesada do Ubuntu que afetará o tempo de compilação e a legibilidade do código do seu Dockerfile.

Comece escrevendo um Dockerfile que instrui o Docker a criar uma imagem do Ubuntu, instalar o Go e executar a API de exemplo. Certifique-se de criar o Dockerfile no diretório do repositório clonado. Se você clonou no diretório home, ele deve ser `$HOME/mux-go-api`.

Crie um novo arquivo chamado `Dockerfile.ubuntu`. Abra-o no `nano` ou no seu editor de texto favorito:

    nano ~/mux-go-api/Dockerfile.ubuntu

Neste Dockerfile, você irá definir uma imagem do Ubuntu e instalar o Golang. Em seguida, você vai continuar a instalar as dependências necessárias e construir o binário. Adicione o seguinte conteúdo ao `Dockerfile.ubuntu`:

~/mux-go-api/Dockerfile.ubuntu

    FROM ubuntu:18.04
    
    RUN apt-get update -y \
      && apt-get install -y git gcc make golang-1.10
    
    ENV GOROOT /usr/lib/go-1.10
    ENV PATH $GOROOT/bin:$PATH
    ENV GOPATH /root/go
    ENV APIPATH /root/go/src/api
    
    WORKDIR $APIPATH
    COPY . .
    
    RUN \ 
      go get -d -v \
      && go install -v \
      && go build
    
    EXPOSE 3000
    CMD ["./api"]

Começando do topo, o comando `FROM` especifica qual sistema operacional básico a imagem terá. A seguir, o comando `RUN` instala a linguagem Go durante a criação da imagem. `ENV` define as variáveis de ambiente específicas que o compilador Go precisa para funcionar corretamente. `WORKDIR` especifica o diretório onde queremos copiar o código, e o comando `COPY` pega o código do diretório onde o `Dockerfile.ubuntu` está e o copia para a imagem. O comando `RUN` final instala as dependências do Go necessárias para o código-fonte compilar e executar a API.

**Nota:** Usar os operadores `&&` para unir os comandos `RUN` é importante para otimizar os Dockerfiles, porque todo comando `RUN` criará uma nova camada, e cada nova camada aumentará o tamanho da imagem final.

Salve e saia do arquivo. Agora você pode executar o comando `build` para criar uma imagem Docker a partir do Dockerfile que você acabou de criar:

    docker build -f Dockerfile.ubuntu -t ubuntu .

O comando `build` constrói uma imagem a partir de um Dockerfile. A flag `-f` especifica que você deseja compilar a partir do arquivo `Dockerfile.ubuntu`, enquanto `-t` significa tag, o que significa que você está marcando a imagem com o nome `ubuntu`. O ponto final representa o contexto atual onde o `Dockerfile.ubuntu` está localizado.

Isso vai demorar um pouco, então sinta-se livre para fazer uma pausa. Quando a compilação estiver concluída, você terá uma imagem Ubuntu pronta para executar sua API. Mas o tamanho final da imagem pode não ser ideal; qualquer coisa acima de algumas centenas de MB para essa API seria considerada uma imagem excessivamente grande.

Execute o seguinte comando para listar todas as imagens Docker e encontrar o tamanho da sua imagem Ubuntu:

    docker images

Você verá a saída mostrando a imagem que você acabou de criar:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    ubuntu latest 61b2096f6871 33 seconds ago 636MB
    . . .

Como é destacado na saída, esta imagem tem um tamanho de **636MB** para uma API Golang básica, um número que pode variar um pouco de máquina para máquina. Em múltiplas compilações, esse grande tamanho afetará significativamente os tempos de deployment e a taxa de transferência da rede.

Nesta seção, você construiu uma imagem Ubuntu com todas as ferramentas e dependências necessárias do Go para executar a API que você clonou no Passo 1. Na próxima seção, você usará uma imagem Docker pré-criada e específica da linguagem para simplificar seu Dockerfile e agilizar o processo de criação.

## Passo 3 — Construindo uma Imagem Base Específica para a Linguagem

Imagens pré-criadas são imagens básicas comuns que os usuários modificaram para incluir ferramentas específicas para uma situação. Os usuários podem, então, enviar essas imagens para o repositório de imagens [Docker Hub](https://hub.docker.com/), permitindo que outros usuários usem a imagem compartilhada em vez de ter que escrever seus próprios Dockerfiles individuais. Este é um processo comum em situações de produção, e você pode encontrar várias imagens pré-criadas no Docker Hub para praticamente qualquer caso de uso. Neste passo, você construirá sua API de exemplo usando uma imagem específica do Go que já tenha o compilador e as dependências instaladas.

Com imagens base pré-criadas que já contêm as ferramentas necessárias para criar e executar sua aplicação, você pode reduzir significativamente o tempo de criação. Como você está começando com uma base que tem todas as ferramentas necessárias pré-instaladas, você pode pular a adição delas ao seu Dockerfile, fazendo com que pareça muito mais limpo e, finalmente, diminuindo o tempo de construção.

Vá em frente e crie outro Dockerfile e nomeie-o como `Dockerfile.golang`. Abra-o no seu editor de texto:

    nano ~/mux-go-api/Dockerfile.golang

Este arquivo será significativamente mais conciso do que o anterior, porque tem todas as dependências, ferramentas e compilador específicos do Go pré-instalados.

Agora, adicione as seguintes linhas:

~/mux-go-api/Dockerfile.golang

    FROM golang:1.10
    
    WORKDIR /go/src/api
    COPY . .
    
    RUN \
        go get -d -v \
        && go install -v \
        && go build
    
    EXPOSE 3000
    CMD ["./api"]

Começando do topo, você verá que a instrução `FROM` agora é `golang:1.10`. Isso significa que o Docker buscará uma imagem Go pré-criada do Docker Hub que tenha todas as ferramentas Go necessárias já instaladas.

Agora, mais uma vez, compile a imagem do Docker com:

    docker build -f Dockerfile.golang -t golang .

Verifique o tamanho final da imagem com o seguinte comando:

    docker images

Isso produzirá uma saída semelhante à seguinte:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    golang latest eaee5f524da2 40 seconds ago 744MB
    . . .

Embora o próprio Dockerfile seja mais eficiente e o tempo de compilação seja menor, o tamanho total da imagem aumentou. A imagem pré-criada do Golang está em torno de **744MB** , uma quantidade significativa.

Essa é a maneira preferida de criar imagens Docker. Ela lhe dá uma imagem base que a comunidade aprovou como o padrão a ser usado para a linguagem especificada, neste caso, Go. No entanto, para tornar uma imagem pronta para produção, você precisa cortar partes que a aplicação em execução não precisa.

Tenha em mente que o uso dessas imagens pesadas é bom quando você não tem certeza sobre suas necessidades. Sinta-se à vontade para usá-las como containers descartáveis, bem como a base para a construção de outras imagens. Para fins de desenvolvimento ou teste, onde você não precisa pensar em enviar imagens pela rede, é perfeitamente aceitável usar imagens pesadas. Mas, se você quiser otimizar os deployments, precisará fazer o seu melhor para tornar suas imagens o menor possível.

Agora que você testou uma imagem específica da linguagem, você pode passar para a próxima etapa, na qual usará a distribuição leve do Alpine Linux como uma imagem base para tornar a imagem Docker mais leve.

## Passo 4 — Construindo Imagens Base do Alpine

Um dos passos mais fáceis para otimizar as imagens Docker é usar imagens base menores. [Alpine](https://alpinelinux.org/about/) é uma distribuição Linux leve projetada para segurança e eficiência de recursos. A imagem Docker do Alpine usa [musl libc](https://www.musl-libc.org/) e [BusyBox](https://busybox.net/about.html) para ficar compacta, exigindo não mais que 8MB em um container para ser executada. O tamanho minúsculo é devido a pacotes binários sendo refinados e divididos, dando a você mais controle sobre o que você instala, o que mantém o ambiente menor e mais eficiente possível.

O processo de criação de uma imagem Alpine é semelhante ao modo como você criou a imagem do Ubuntu no Passo 2. Primeiro, crie um novo arquivo chamado `Dockerfile.alpine`:

    nano ~/mux-go-api/Dockerfile.alpine

Agora adicione este trecho:

~/mux-go-api/Dockerfile.alpine

    FROM alpine:3.8
    
    RUN apk add --no-cache \
        ca-certificates \
        git \
        gcc \
        musl-dev \
        openssl \
        go
    
    ENV GOPATH /go
    ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
    ENV APIPATH $GOPATH/src/api
    RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" "$APIPATH" && chmod -R 777 "$GOPATH"
    
    WORKDIR $APIPATH
    COPY . .
    
    RUN \
        go get -d -v \
        && go install -v \
        && go build
    
    EXPOSE 3000
    CMD ["./api"]

Aqui você está adicionando o comando `apk add` para utilizar o gerenciador de pacotes do Alpine para instalar o Go e todas as bibliotecas que ele requer. Tal como acontece com a imagem do Ubuntu, você precisa definir as variáveis de ambiente também.

Vá em frente e compile a imagem:

    docker build -f Dockerfile.alpine -t alpine .

Mais uma vez, verifique o tamanho da imagem:

    docker images

Você receberá uma saída semelhante à seguinte:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    alpine latest ee35a601158d 30 seconds ago 426MB
    . . .

O tamanho caiu para cerca de **426MB**.

O tamanho reduzido da imagem base Alpine reduziu o tamanho final da imagem, mas há mais algumas coisas que você pode fazer para torná-la ainda menor.

A seguir, tente usar uma imagem Alpine pré-criada para o Go. Isso tornará o Dockerfile mais curto e também reduzirá o tamanho da imagem final. Como a imagem Alpine pré-criada para o Go é construída com o Go compilado dos fontes, sua tamanho é significativamente menor.

Comece criando um novo arquivo chamado `Dockerfile.golang-alpine`:

    nano ~/mux-go-api/Dockerfile.golang-alpine

Adicione o seguinte conteúdo ao arquivo:

~/mux-go-api/Dockerfile.golang-alpine

    FROM golang:1.10-alpine3.8
    
    RUN apk add --no-cache --update git
    
    WORKDIR /go/src/api
    COPY . .
    
    RUN go get -d -v \
      && go install -v \
      && go build
    
    EXPOSE 3000
    CMD ["./api"]

As únicas diferenças entre `Dockerfile.golang-alpine` e `Dockerfile.alpine` são o comando `FROM` e o primeiro comando `RUN`. Agora, o comando `FROM` especifica uma imagem `golang` com a tag `1.10-alpine3.8` e `RUN` só tem um comando para a instalação do [Git](https://git-scm.com/). Você precisa do Git para o comando `go get` para trabalhar no segundo comando `RUN` na parte inferior do `Dockerfile.golang-alpine`.

Construa a imagem com o seguinte comando:

    docker build -f Dockerfile.golang-alpine -t golang-alpine .

Obtenha sua lista de imagens:

    docker images

Você receberá a seguinte saída:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    golang-alpine latest 97103a8b912b 49 seconds ago 288MB

Agora o tamanho da imagem está em torno de **288MB**.

Mesmo que você tenha conseguido reduzir bastante o tamanho, há uma última coisa que você pode fazer para preparar a imagem para a produção. É chamado de uma compilação de múltiplos estágios ou multi-stage. Usando compilações multi-stage, você pode usar uma imagem para construir a aplicação enquanto usa outra imagem mais leve para empacotar a aplicação compilada para produção, um processo que será executado no próximo passo.

## Passo 5 — Excluindo Ferramentas de Compilação em uma Compilação Multi-Stage

Idealmente, as imagens que você executa em produção não devem ter nenhuma ferramenta de compilação instalada ou dependências redundantes para a execução da aplicação de produção. Você pode removê-las da imagem Docker final usando compilações multi-stage. Isso funciona através da construção do binário, ou em outros termos, a aplicação Go compilada, em um container intermediário, copiando-o em seguida para um container vazio que não tenha dependências desnecessárias.

Comece criando outro arquivo chamado `Dockerfile.multistage`:

    nano ~/mux-go-api/Dockerfile.multistage

O que você vai adicionar aqui será familiar. Comece adicionando o mesmo código que está em `Dockerfile.golang-alpine`. Mas desta vez, adicione também uma segunda imagem onde você copiará o binário a partir da primeira imagem.

~/mux-go-api/Dockerfile.multistage

    FROM golang:1.10-alpine3.8 AS multistage
    
    RUN apk add --no-cache --update git
    
    WORKDIR /go/src/api
    COPY . .
    
    RUN go get -d -v \
      && go install -v \
      && go build
    
    ##
    
    FROM alpine:3.8
    COPY --from=multistage /go/bin/api /go/bin/
    EXPOSE 3000
    CMD ["/go/bin/api"]

Salve e feche o arquivo. Aqui você tem dois comandos `FROM`. O primeiro é idêntico ao `Dockerfile.golang-alpine`, exceto por ter um `AS multistage` adicional no comando `FROM`. Isto lhe dará um nome de `multistage`, que você irá referenciar na parte inferior do arquivo `Dockerfile.multistage`. No segundo comando `FROM`, você pegará uma imagem base `alpine` e copiará para dentro dela usando o `COPY`, a aplicação Go compilada da imagem `multiestage`. Esse processo reduzirá ainda mais o tamanho da imagem final, tornando-a pronta para produção.

Execute a compilação com o seguinte comando:

    docker build -f Dockerfile.multistage -t prod .

Verifique o tamanho da imagem agora, depois de usar uma compilação multi-stage.

    docker images

Você encontrará duas novas imagens em vez de apenas uma:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    prod latest 82fc005abc40 38 seconds ago 11.3MB
    <none> <none> d7855c8f8280 38 seconds ago 294MB
    . . .

A imagem `<none>` é a imagem `multistage` construída com o comando `FROM golang:1.10-alpine3.8 AS multistage`. Ela é apenas um intermediário usado para construir e compilar a aplicação Go, enquanto a imagem `prod` neste contexto é a imagem final que contém apenas a aplicação Go compilada.

A partir dos **744MB** iniciais, você reduziu o tamanho da imagem para aproximadamente **11,3MB**. Manter o controle de uma imagem minúscula como esta e enviá-la pela rede para os servidores de produção será muito mais fácil do que com uma imagem de mais de 700MB e economizará recursos significativos a longo prazo.

## Conclusão

Neste tutorial, você otimizou as imagens Docker para produção usando diferentes imagens Docker de base e uma imagem intermediária para compilar e construir o código. Dessa forma, você empacotou sua API de exemplo no menor tamanho possível. Você pode usar essas técnicas para melhorar a velocidade de compilação e deployment de suas aplicações Docker e de qualquer pipeline de CI/CD que você possa ter.

Se você estiver interessado em aprender mais sobre como criar aplicações com o Docker, confira o nosso tutorial [Como Construir uma Aplicação Node.js com o Docker](como-construir-uma-aplicacao-node-js-com-o-docker-pt). Para obter informações mais conceituais sobre como otimizar containers, consulte [Building Optimized Containers for Kubernetes](building-optimized-containers-for-kubernetes).
