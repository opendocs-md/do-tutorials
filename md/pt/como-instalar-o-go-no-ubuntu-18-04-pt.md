---
author: Brennen Bearnes
date: 2019-01-24
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-go-no-ubuntu-18-04-pt
---

# Como Instalar o Go no Ubuntu 18.04

### Introdução

[Go](https://golang.org/) é uma linguagem de programação moderna desenvolvida no Google. Ela é cada vez mais popular para muitas aplicações e em muitas empresas, e oferece um conjunto robusto de bibliotecas. Este tutorial irá ajudá-lo a baixar e instalar a versão mais recente do Go (Go 1.10 no momento da publicação deste artigo), bem como construir uma aplicação Hello Word simples.

## Pré-requisitos

Este tutorial assume que você tenha acesso a um sistema Ubuntu 18.04, configurado com um usuário não-root com privilégios `sudo`, como descrito em [Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt).

## Passo 1 — Instalando o Go

Nesta etapa, vamos instalar o Go no seu servidor.

Para começar, conecte-se ao seu servidor Ubuntu via `ssh`:

    ssh sammy@ip_do_seu_servidor

Para instalar o Go, você precisará pegar a versão mais recente da [página oficial de downloads do Go](https://golang.org/dl/). No site você pode encontrar a URL para o tarball do binário da versão atual, juntamente com seu hash SHA256.

Visite a página oficial de downloads do Go e encontre a URL para o taball do binário da versão atual, juntamente com seu hash SHA256. Certifique-se de estar em seu diretório home, e utilize curl para baixar o tarball:

    cd ~
    curl -O https://dl.google.com/go/go1.10.3.linux-amd64.tar.gz

Em seguida, você pode usar o `sha256sum` para verificar o tarball:

    sha256sum go1.10.3.linux-amd64.tar.gz

    Sample Outputgo1.10.3.linux-amd64.tar.gz
    fa1b0e45d3b647c252f51f5e1204aba049cde4af177ef9f2181f43004f901035 go1.10.3.linux-amd64.tar.gz

Você terá um hash como aquele destacado na saída acima. Certifique-se de que coincide com o da página de downloads.

A seguir, use o `tar` para extrair o tarball. A flag `x` diz ao `tar` para extrair, `v` diz a ele que queremos uma saída detalhada (uma listagem dos arquivos que estão sendo extraídos), e `f` diz a ele que especificaremos um arquivo.

    tar xvf go1.10.3.linux-amd64.tar.gz

Agora você deve ter um diretório chamado `go` em seu diretório home. Altere recursivamente o proprietário e o grupo do diretório `go` para **root** , e mova-o para `/usr/local`:

    sudo chown -R root:root ./go
    sudo mv go /usr/local

**Nota:** Embora `/usr/local/go` seja a localização recomendada oficialmente, alguns usuários podem preferir ou requerer paths diferentes.

## Passo 2 — Definindo Paths do Go

Nesta etapa, iremos definir alguns paths ou caminhos de arquivos em seu ambiente.

Primeiro, defina o valor da raiz do Go, que diz ao Go onde procurar pelos seus arquivos.

    sudo nano ~/.profile

No final do arquivo, adicione esta linha:

    export GOPATH=$HOME/work
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

Se você escolheu um local de instalação alternativo para o Go, em vez disso, adicione essas linhas ao mesmo arquivo. Este exemplo mostra os comandos se o Go estiver instalado no seu diretório home:

    export GOROOT=$HOME/go
    export GOPATH=$HOME/work
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

Depois de colar a linha apropriada no seu perfil, salve e feche o arquivo. Em seguida, atualize seu perfil executando:

    source ~/.profile

## Passo 3 — Testando Sua Instalação

Agora que o Go está instalado e os paths estão defnidos para seu servidor, você pode testar para garantir que o Go esteja funcionando como esperado.

Crie um novo diretório para o seu espaço de trabalho no Go, que é onde o Go irá compilar seus arquivos:

    mkdir $HOME/work

Em seguida, crie uma hierarquia de diretórios nessa pasta por meio desse comando para criar seu arquivo de teste. Você pode substituir o valor usuário pelo seu nome de usuário do GitHub se você planeja usar o Git para fazer commit e armazenar seu código Go no GitHub. Se você não planeja usar o GitHub para armazenar e gerenciar seu código, sua estrutura de pastas pode ser algo diferente, como `~/my_project`.

    mkdir -p work/src/github.com/usuário/hello

Após isso, você pode criar um arquivo simples de “Hello World”.

    nano ~/work/src/github.com/usuário/hello/hello.go

Dentro do seu editor, cole o código abaixo, que utiliza o pacote main do Go, importa o componente de conteúdo de IO formatado, e define uma nova função para imprimir “Hello, World” ao ser executado.

    package main
    
    import "fmt"
    
    func main() {
        fmt.Printf("hello, world\n")
    }

Este pograma imprimirá “hello, world” se ele for executado com sucesso, o que indicará que os programas do Go estão compilando corretamente. Salve e feche o arquivo, e então compile-o invocando o comando `install`:

    go install github.com/usuário/hello

Com o arquivo compilado, você pode executá-lo simplesmente executando o comando:

    hello

Se esse comando retornar “hello, world”, então o Go está instalado e funcionando com sucesso. Você pode ver onde o binário ‘hello’ compilado está instalado usando o comando `which`:

    which hello

    Output/home/usuário/work/bin/hello

## Conclusão

Ao fazer o download e instalar o pacote Go mais recente e configurar seus paths, agora você tem um sistema pronto para usar no desenvolvimento com Go. Você pode encontrar e se inscrever em artigos adicionais sobre como instalar e usar o Go na nossa [tag “Go”](https://www.digitalocean.com/community/tags/go)

_Por Brennen Bearnes_
