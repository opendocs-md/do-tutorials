---
author: Gopher Guides
date: 2019-07-22
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-go-e-configurar-um-ambiente-de-programacao-local-no-ubuntu-18-04-pt
---

# Como Instalar o Go e Configurar um Ambiente de Programação Local no Ubuntu 18.04

### Introdução

[Go](https://golang.org) é uma linguagem de programação que nasceu da frustração no Google. Os desenvolvedores precisavam escolher continuamente uma linguagem que fosse executada com eficiência, mas demoravam muito tempo para compilar ou escolher uma linguagem fácil de programar, mas que era executada de forma ineficiente em produção. O Go foi projetado para ter todas as três características disponíveis ao mesmo tempo: compilação rápida, facilidade de programação e execução eficiente em produção.

Embora o Go seja uma linguagem de programação versátil que pode ser usada para muitos projetos de programação diferentes, ela é particularmente adequada para programas de rede/sistemas distribuídos e ganhou a reputação de ser “a linguagem da nuvem”. Ela se concentra em ajudar o programador moderno a fazer mais com um conjunto forte de ferramentas, removendo debates sobre formatação ao tornar o formato parte da especificação da linguagem, bem como ao facilitar o deploy ao compilar para um único binário. O Go é fácil de aprender, com um conjunto muito pequeno de palavras-chave, o que o torna uma ótima opção para iniciantes e igualmente para desenvolvedores experientes.

Este tutorial irá guiá-lo pela instalação e configuração de um workspace de programação com o Go via linha de comando. Este tutorial cobrirá explicitamente o procedimento de instalação para o Ubuntu 18.04, mas os princípios gerais podem se aplicar a outras distribuições Debian Linux.

## Pré-requisitos

Você precisará de um computador ou máquina virtual com o Ubuntu 18.04 instalado, além de ter acesso administrativo a essa máquina e uma conexão à Internet. Você pode baixar este sistema operacional através da [página de releases do Ubuntu 18.04](http://releases.ubuntu.com/releases/18.04/).

## Passo 1 — Configurando o Go

Neste passo, você instalará o Go fazendo o download da versão atual da [página oficial de downloads do Go](https://golang.org/dl/).

Para fazer isso, você vai querer encontrar a URL para o tarball do binário da versão atual. Você também vai querer anotar o hash SHA256 listado ao lado dele, pois você usará esse hash para [verificar o arquivo baixado](how-to-verify-downloaded-files).

Você estará concluindo a instalação e a configuração na linha de comando, que é uma maneira não gráfica de interagir com seu computador. Ou seja, em vez de clicar nos botões, você digitará texto e receberá retornos do seu computador por meio de texto também.

A linha de comando, também conhecida como _shell_ ou _terminal_, pode ajudá-lo a modificar e automatizar muitas das tarefas que você faz em um computador todos os dias e é uma ferramenta essencial para desenvolvedores de software. Existem muitos comandos de terminal para aprender que podem permitir que você faça coisas mais poderosas. Para mais informações sobre a linha de comando, confira o tutorial [Introdução ao Terminal do Linux](an-introduction-to-the-linux-terminal).

No Ubuntu 18.04, você pode encontrar o aplicativo Terminal clicando no ícone do Ubuntu no canto superior esquerdo da tela e digitando `terminal` na barra de pesquisa. Clique no ícone do aplicativo Terminal para abri-lo. Alternativamente, você pode pressionar as teclas `CTRL`,`ALT` e `T` no teclado simultaneamente para abrir o aplicativo Terminal automaticamente.

![Ubuntu Terminal](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/UbuntuDebianSetUp/UbuntuSetUp.png)

Quando o terminal estiver aberto, você instalará manualmente os binários do Go. Embora você possa usar um gerenciador de pacotes, como o `apt-get`, percorrer as etapas de instalação manual o ajudará a entender as alterações de configuração necessárias ao sistema para ter um workspace Go válido.

Antes de baixar o Go, certifique-se de estar no diretório home (`~`):

    cd ~

Use o `curl` para recuperar a URL do tarball que você copiou da página oficial de downloads do Go:

    curl -O https://dl.google.com/go/go1.12.1.linux-amd64.tar.gz

Em seguida, use `sha256sum` para verificar o tarball:

    sha256sum go1.12.1.linux-amd64.tar.gz

O hash que é exibido a partir da execução do comando acima deve corresponder ao hash que estava na página de downloads. Se não, então este não é um arquivo válido e você deve baixar o arquivo novamente.

    Output2a3fdabf665496a0db5f41ec6af7a9b15a49fbe71a85a50ca38b1f13a103aeec go1.12.1.linux-amd64.tar.gz

Em seguida, extraia o arquivo baixado e instale-o no local desejado no sistema. É considerado uma boa prática mantê-lo em `/usr/local`:

    sudo tar -xvf go1.12.1.linux-amd64.tar.gz -C /usr/local

Você terá agora um diretório chamado `go` no diretório `/usr/local`. Em seguida, altere recursivamente o proprietário e o grupo deste diretório para **root** :

    sudo chown -R root:root /usr/local/go

Isso protegerá todos os arquivos e garantirá que apenas o usuário **root** possa executar os binários do Go.

**Nota** : Embora `/usr/local/go` seja o local oficialmente recomendado, alguns usuários podem preferir ou exigir caminhos diferentes.

Nesta etapa, você baixou e instalou o Go na sua máquina Ubuntu 18.04. Na próxima etapa, você configurará seu workspace de Go.

## Passo 2 — Criando seu Workspace de Go

Você pode criar seu workspace de programação agora que o Go está instalado. O workspace do Go conterá dois diretórios em sua raiz:

- `src`: O diretório que contém os arquivos-fonte do Go. Um arquivo-fonte é um arquivo que você escreve usando a linguagem de programação Go. Arquivos-fonte são usados pelo compilador Go para criar um arquivo binário executável.
- `bin`: O diretório que contém executáveis compilados e instalados pelas ferramentas Go. Executáveis são arquivos binários que são executados em seu sistema e executam tarefas. Estes são normalmente os programas compilados a partir do seu código-fonte ou outro código-fonte Go baixado.

O subdiretório `src` pode conter vários repositórios de controle de versão (tais como o [Git](https://git-scm.com/), o [Mercurial](https://www.mercurial-scm.org/), e o [Bazaar](http://bazaar.canonical.com)). Isso permite uma importação canônica de código em seu projeto. As importações _canônicas_ são importações que fazem referência a um pacote completo, como o `github.com/digitalocean/godo`.

Você verá diretórios como `github.com`, `golang.org` ou outros quando seu programa importar bibliotecas de terceiros. Se você estiver usando um repositório de código como o `github.com`, você também colocará seus projetos e arquivos-fonte nesse diretório. Vamos explorar esse conceito mais adiante neste passo.

Aqui está como pode se parecer um workspace típico:

    .
    ├── bin
    │ ├── buffalo # comando executável
    │ ├── dlv # comando executável
    │ └── packr # comando executável
    └── src
        └── github.com
            └── digitalocean
                └── godo
                    ├── .git # metadados do repositório do Git
                    ├── account.go # fonte do pacote
                    ├── account_test.go # fonte do teste
                    ├── ...
                    ├── timestamp.go
                    ├── timestamp_test.go
                    └── util
                        ├── droplet.go
                        └── droplet_test.go

O diretório padrão para o workspace Go a partir da versão 1.8 é o diretório home do usuário com um subdiretório `go` ou `$HOME/go`. Se você estiver usando uma versão anterior à 1.8 do Go, ainda é considerado uma boa prática usar o local `$HOME/go` para o seu workspace.

Execute o seguinte comando para criar a estrutura de diretórios para o seu workspace Go:

    mkdir -p $HOME/go/{bin,src}

A opção `-p` diz ao `mkdir` para criar todos os `subdiretórios` no diretório, mesmo que eles não existam atualmente. A utilização do `{bin, src}` cria um conjunto de argumentos para `mkdir` e diz para ele criar tanto o diretório`bin` quanto o diretório `src`.

Isso garantirá que a seguinte estrutura de diretórios esteja em vigor:

    └── $HOME
        └── go
            ├── bin
            └── src

Antes do Go 1.8, era necessário definir uma variável de ambiente local chamada `$GOPATH`. `$GOPATH` diz ao compilador onde encontrar o código-fonte importado de terceiros, bem como qualquer código-fonte local que você tenha escrito. Embora não seja mais explicitamente exigido, ainda é considerada uma boa prática, pois muitas ferramentas de terceiros ainda dependem da configuração dessa variável.

Você pode definir seu `$GOPATH` adicionando as variáveis globais ao seu `~/.profile`. Você pode querer adicionar isto ao arquivo `.zshrc` ou `.bashrc` de acordo com a configuração do seu shell.

Primeiro, abra o `~/.profile` com o `nano` ou seu editor de textos preferido:

    nano ~/.profile

Configure seu `$GOPATH` adicionando o seguinte ao arquivo:

~/.profile

    export GOPATH=$HOME/go

Quando o Go compila e instala ferramentas, ele as coloca no diretório `$GOPATH/bin`. Por conveniência, é comum adicionar o subdiretório `/bin` do workspace ao seu `PATH` no seu `~/.profile`:

~/.profile

    export PATH=$PATH:$GOPATH/bin

Isso permitirá que você execute quaisquer programas compilados ou baixados por meio das ferramentas Go em qualquer parte do sistema.

Finalmente, você precisa adicionar o binário `go` ao seu `PATH`. Você pode fazer isso adicionando `/usr/local/go/bin` ao final da linha:

~/.profile

    export PATH=$PATH:$GOPATH/bin:/usr/local/go/bin

Adicionar `/usr/local/go/bin` ao seu `$PATH` torna todas as ferramentas Go disponíveis em qualquer lugar do seu sistema.

Para atualizar seu shell, execute o seguinte comando para carregar as variáveis globais:

    . ~/.profile

Você pode verificar se seu `$PATH` está atualizado usando o comando `echo` e inspecionando a saída:

    echo $PATH

Você verá o seu `$GOPATH/bin` que aparecerá no seu diretório pessoal. Se você está logado como `root`, você verá `/root/go/bin` no caminho.

    Output/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/root/go/bin:/usr/local/go/bin

Você também verá o caminho para as ferramentas Go `/usr/local/go/bin`:

    Output/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/root/go/bin:/usr/local/go/bin

Verifique a instalação, conferindo a versão atual do Go:

    go version

E devemos receber uma saída assim:

    Outputgo version go1.12.1 linux/amd64

Agora que você tem a raiz do workspace criada e sua variável de ambiente `$GOPATH` definida, você pode criar seus projetos futuros com a seguinte estrutura de diretórios. Este exemplo assume que você está usando o `github.com` como seu repositório:

    $GOPATH/src/github.com/username/project

Então, como um exemplo, se você estivesse trabalhando no projeto [`https://github.com/digitalocean/godo`](https://github.com/digitalocean/godo), ele seria armazenado no seguinte diretório:

    $GOPATH/src/github.com/digitalocean/godo

Esta estrutura de projeto disponibilizará projetos com a ferramenta `go get`. Também ajudará a legibilidade mais tarde. Você pode verificar isso usando o comando `go get` e buscar a biblioteca `godo`:

    go get github.com/digitalocean/godo

Isto irá baixar o conteúdo da biblioteca `godo` e criar o diretório `$GOPATH/src/github.com/digitalocean/godo` em sua máquina.

Você pode verificar se baixou com sucesso o pacote `godo` listando o diretório:

    ll $GOPATH/src/github.com/digitalocean/godo

Você deve ver uma saída semelhante a esta:

    Outputdrwxr-xr-x 4 root root 4096 Apr 5 00:43 ./
    drwxr-xr-x 3 root root 4096 Apr 5 00:43 ../
    drwxr-xr-x 8 root root 4096 Apr 5 00:43 .git/
    -rwxr-xr-x 1 root root 8 Apr 5 00:43 .gitignore*
    -rw-r--r-- 1 root root 61 Apr 5 00:43 .travis.yml
    -rw-r--r-- 1 root root 2808 Apr 5 00:43 CHANGELOG.md
    -rw-r--r-- 1 root root 1851 Apr 5 00:43 CONTRIBUTING.md
    .
    .
    .
    -rw-r--r-- 1 root root 4893 Apr 5 00:43 vpcs.go
    -rw-r--r-- 1 root root 4091 Apr 5 00:43 vpcs_test.go

Neste passo, você criou um workspace Go e configurou as variáveis de ambiente necessárias. No próximo passo, você testará o workspace com algum código.

## Passo 3 — Criando um Programa Simples

Agora que você tem o workspace Go configurado, crie um programa “Hello, World!”. Isso garantirá que o workspace esteja configurado corretamente e também lhe dará a oportunidade de se familiarizar com o Go. Como estamos criando um único arquivo-fonte Go, e não um projeto real, não precisamos estar em nosso workspace para fazer isso.

A partir do seu diretório home, abra um editor de texto de linha de comando, como o `nano`, e crie um novo arquivo:

    nano hello.go

Escreva seu programa em seu novo arquivo:

    package main
    
    import "fmt"
    
    func main() {
        fmt.Println("Hello, World!")
    }

Este código usará o pacote `fmt` e chamará a função `Println` com `Hello, World!` como argumento. Isso fará com que a frase `Hello, World!` seja impressa no terminal quando o programa for executado.

Saia do `nano` pressionando as teclas `CTRL` e `X`. Quando solicitado a salvar o arquivo, pressione `Y` e depois `ENTER`.

Ao sair do `nano` e retornar ao seu shell, execute o programa:

    go run hello.go

O programa `hello.go` fará com que o terminal produza a seguinte saída:

    OutputHello, World!

Nesta etapa, você usou um programa básico para verificar se seu workspace Go está configurado corretamente.

## Conclusão

Parabéns! Neste ponto, você tem um workspace de programação Go configurado em sua máquina Ubuntu e pode começar um projeto de codificação!
