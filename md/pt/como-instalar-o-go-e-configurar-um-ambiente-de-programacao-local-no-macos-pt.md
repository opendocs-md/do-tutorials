---
author: Gopher Guides
date: 2019-07-22
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-go-e-configurar-um-ambiente-de-programacao-local-no-macos-pt
---

# Como Instalar o Go e Configurar um Ambiente de Programação Local no macOS

### Introdução

[Go](https://golang.org) é uma linguagem de programação que nasceu da frustração no Google. Os desenvolvedores precisavam escolher continuamente uma linguagem que fosse executada com eficiência, mas demoravam muito tempo para compilar ou escolher uma linguagem fácil de programar, mas que era executada de forma ineficiente em produção. O Go foi projetado para ter todas as três características disponíveis ao mesmo tempo: compilação rápida, facilidade de programação e execução eficiente em produção.

Embora o Go seja uma linguagem de programação versátil que pode ser usada para muitos projetos de programação diferentes, ela é particularmente adequada para programas de rede/sistemas distribuídos e ganhou a reputação de ser “a linguagem da nuvem”. Ela se concentra em ajudar o programador moderno a fazer mais com um conjunto forte de ferramentas, removendo debates sobre formatação ao tornar o formato parte da especificação da linguagem, bem como ao facilitar o deploy ao compilar para um único binário. O Go é fácil de aprender, com um conjunto muito pequeno de palavras-chave, o que o torna uma ótima opção para iniciantes e igualmente para desenvolvedores experientes.

Este tutorial irá guiá-lo pela instalação do Go em sua máquina local com macOS e da configuração de um workspace de programação através da linha de comando.

## Pré-requisitos

Você precisará de um computador com macOS com acesso administrativo e que esteja conectado à Internet.

## Passo 1 — Abrindo o Terminal

Você estará concluindo a instalação e a configuração na linha de comando, que é uma maneira não gráfica de interagir com seu computador. Ou seja, em vez de clicar nos botões, você digitará texto e receberá retornos do seu computador por meio de texto também. A linha de comando, também conhecida como shell, pode ajudá-lo a modificar e automatizar muitas das tarefas que você faz em um computador todos os dias, e é uma ferramenta essencial para desenvolvedores de software.

O Terminal do macOS é um aplicativo que você pode usar para acessar a interface da linha de comando. Como qualquer outro aplicativo, você pode encontrá-lo indo até o Finder, navegando até a pasta Aplicativos e, em seguida, na pasta Utilitários. A partir daqui, dê um clique duplo no Terminal como qualquer outro aplicativo para abri-lo. Alternativamente, você pode usar o Spotlight mantendo pressionadas as teclas `CMD` e `SPACE` para localizar o Terminal digitando-o na caixa que aparece.

![macOS Terminal](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/OSXSetUp/MacOSXSetUp.png)

Existem muitos outros comandos do Terminal para aprender que podem permitir que você faça coisas mais poderosas. O artigo “[An Introduction to the Linux Terminal](an-introduction-to-the-linux-terminal)” pode te orientar melhor com o terminal do Linux, que é semelhante ao teminal do macOS.

Agora que você abriu o Terminal, pode fazer o download e instalar o [Xcode](https://developer.apple.com/xcode/), um pacote de ferramentas de desenvolvedor que você precisará para instalar o Go.

## Passo 2 — Instalando o Xcode

O Xcode é um _integrated development environment_ ou _ambiente de desenvolvimento integrado_ (IDE) composto de ferramentas de desenvolvimento de software para macOS. Você pode verificar se o Xcode já está instalado, digitando o seguinte na janela do Terminal:

    xcode-select -p

A saída a seguir significa que o Xcode está instalado:

    Output/Library/Developer/CommandLineTools

Se você recebeu um erro em seu navegador web, instale o [Xcode a partir da App Store](https://itunes.apple.com/us/app/xcode/id497799835?mt=12&ign-mpt=uo%3D2) e aceite as opções padrão.

Quando o Xcode estiver instalado, retorne à janela do Terminal. Em seguida, você precisará instalar o app separado de Ferramentas de Linha de Comando do Xcode, que pode ser feito digitando:

    xcode-select --install

Neste ponto, o Xcode e seu app de Ferramentas de Linha de Comando estão totalmente instalados e estamos prontos para instalar o gerenciador de pacotes Homebrew.

## Passo 3 — Instalando e Configurando o Homebrew

Embora o Terminal do macOS tenha muitas das funcionalidades dos Terminais Linux e de outros sistemas Unix, ele não é fornecido com um gerenciador de pacotes que acomoda as melhores práticas. Um **gerenciador de pacotes** é uma coleção de ferramentas de software que trabalham para automatizar processos de instalação que incluem instalação inicial de software, atualização e configuração de software, e remoção de software conforme necessário. Eles mantêm instalações em um local central e podem manter todos os pacotes de software no sistema em formatos comumente usados. [**Homebrew**](https://brew.sh/) fornece ao macOS um sistema gerenciador de pacotes de software livre e de código aberto que simplifica a instalação de software no macOS.

Para instalar o Homebrew, digite isso na sua janela de Terminal:

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

O Homebrew é feito em Ruby, assim ele irá modificar o caminho do Ruby do seu computador. O comando `curl` baixa um script da URL especificada. Este script explicará o que ele fará e, em seguida, fará uma pausa no processo para solicitar sua confirmação. Isso lhe fornece uma série de comentários sobre o que o script vai fazer no seu sistema e dá a você a oportunidade de verificar o processo.

Se você precisar digitar sua senha, observe que suas teclas não serão exibidas na janela do Terminal, mas serão gravadas. Basta pressionar a tecla `return` ou `enter` depois de inserir sua senha. Caso contrário, pressione a letra `y` para “sim” quando você for solicitado a confirmar a instalação.

Vamos dar uma olhada nas flags associadas ao comando `curl`:

- A flag `-f` ou `--fail` informa à janela do Terminal para não dar saída de documento HTML nos erros de servidor.
- A flag `-s` ou `--silent` silencia o `curl` para que ele não mostre o medidor de progresso, e combinada com a flag `-S` ou `--show-error` ela irá assegurar que `curl` mostre uma mensagem de erro se falhar.
- A flag `-L` ou `--location` informará ao `curl` para refazer a solicitação para um novo local se o servidor informar que a página solicitada foi movida para um local diferente.

Quando o processo de instalação estiver concluído, colocaremos o diretório Homebrew no começo da variável de ambiente `PATH`. Isso garantirá que as instalações do Homebrew serão chamadas antes das ferramentas que o macOS possa selecionar automaticamente e que podem ser executadas em contraposição ao ambiente de desenvolvimento que estamos criando.

Você deve criar ou abrir o arquivo `~/.bash_profile` com o editor de texto de linha de comando **nano** usando o comando `nano`:

    nano ~/.bash_profile

Quando o arquivo abrir na janela do Terminal, escreva o seguinte:

    export PATH=/usr/local/bin:$PATH

Para salvar suas alterações, mantenha pressionada a tecla `CTRL` e a letra `o` e, quando solicitado, pressione a tecla `RETURN`. Agora você pode sair do nano segurando a tecla `CTRL` e a letra `x`.

Ative essas alterações executando o seguinte no Terminal:

    source ~/.bash_profile

Depois de fazer isso, as alterações feitas na variável de ambiente `PATH` entrarão em vigor.

Você pode ter certeza de que o Homebrew foi instalado com sucesso digitando:

    brew doctor

Se nenhuma atualização for necessária neste momento, a saída do Terminal mostrará:

    OutputYour system is ready to brew.

Caso contrário, você pode receber um aviso para executar outro comando, como `brew update`, para garantir que sua instalação do Homebrew esteja atualizada.

Uma vez que o Homebrew está pronto, você pode instalar o Go.

## Passo 4 — Instalando o Go

Você pode usar o Homebrew para procurar por todos os pacotes disponíveis com o comando `brew search`. Para o propósito deste tutorial, você irá procurar por pacotes ou módulos relacionados ao Go:

    brew search golang

**Nota** : Este tutorial não usa `brew search go`, pois isso retorna muitos resultados. Como `go` é uma palavra muito pequena e combinaria com muitos pacotes, tornou-se comum usar `golang` como termo de busca. Essa é uma prática comum quando se pesquisa na Internet por artigos relacionados ao Go também. O termo _Golang_ nasceu a partir do domínio para o Go, que é `golang.org`.

O Terminal mostrará uma lista do que você pode instalar:

    Outputgolang golang-migrate

O Go estará entre os itens da lista. Vá em frente e instale-o:

    brew install golang

A janela do Terminal lhe dará feedback sobre o processo de instalação do Go. Pode demorar alguns minutos antes da conclusão da instalação.

Para verificar a versão do Go que você instalou, digite o seguinte:

    go version

Isso mostrará a versão específica do Go que está atualmente instalada, que por padrão será a versão mais atualizada e estável do Go disponível.

No futuro, para atualizar o Go, você pode executar os seguintes comandos para atualizar o Homebrew e depois atualizar o Go. Você não precisa fazer isso agora, pois acabou de instalar a versão mais recente:

    brew update
    brew upgrade golang

`brew update` atualizará as fórmulas para o próprio Homebrew, garantindo que você tenha as informações mais recentes sobre os pacotes que deseja instalar. `brew upgrade golang` atualizará o pacote `golang` para a sua última versão.

É uma boa prática garantir que sua versão do Go esteja atualizada.

Com o Go instalado no seu computador, você está pronto para criar um workspace para seus projetos de Go.

## Passo 5 — Criando o seu Workspace Go

Agora que você tem o Xcode, Homebrew e Go instalados, você pode criar seu workspace de programação.

O workspace do Go conterá dois diretórios em sua raiz:

- `src`: O diretório que contém os arquivos-fonte do Go. Um arquivo-fonte é um arquivo que você escreve usando a linguagem de programação Go. Arquivos-fonte são usados pelo compilador Go para criar um arquivo binário executável.
- `bin`: O diretório que contém executáveis compilados e instalados pelas ferramentas Go. Executáveis são arquivos binários que são executados em seu sistema e executam tarefas. Estes são normalmente os programas compilados a partir do seu código-fonte ou outro código-fonte Go baixado.

O subdiretório `src` pode conter vários repositórios de controle de versão (tais como o [Git](https://git-scm.com/), o [Mercurial](https://www.mercurial-scm.org/), e o [Bazaar](http://bazaar.canonical.com)). Você verá diretórios como `github.com`, `golang.org` ou outros quando seu programa importar bibliotecas de terceiros. Se você estiver usando um repositório de código como o `github.com`, você também colocará seus projetos e arquivos-fonte nesse diretório. Isso permite uma importação canônica de código em seu projeto. As importações _Canônicas_ são importações que fazem referência a um pacote completo, como o `github.com/digitalocean/godo`.

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

Antes do Go 1.8, era necessário definir uma variável de ambiente local chamada `$GOPATH`. Embora não seja mais explicitamente exigido fazer isso, ainda é considerada uma boa prática, pois muitas ferramentas de terceiros ainda dependem da configuração dessa variável.

Você pode definir seu `$GOPATH` adicionando-o ao seu `~/.bash_profile`.

Primeiro, abra `~/.bash_profile` com o `nano` ou seu editor de texto preferido:

    nano ~/.bash_profile

Defina seu `$GOPATH` adicionando o seguinte ao arquivo:

~/.bash\_profile

    export GOPATH=$HOME/go

Quando o Go compila e instala ferramentas, ele as coloca no diretório `$GOPATH/bin`. Por conveniência, é comum adicionar o subdiretório `/bin` do workspace ao seu `PATH` no seu arquivo `~/.bash_profile`:

~/.bash\_profile

    export PATH=$PATH:$GOPATH/bin

Agora você deve ter as seguintes entradas no seu `~/.bash_profile`:

~/.bash\_profile

    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin

Agora, isso permitirá que você execute todos os programas compilados ou baixados por meio das ferramentas Go em qualquer parte do seu sistema.

Para atualizar seu shell, execute o seguinte comando para carregar as variáveis globais que você acabou de criar:

    . ~/.bash_profile

Você pode verificar que seu `$PATH` está atualizado usando o comando `echo` e inspecionando a saída:

    echo $PATH

Você deve ver seu `$GOPATH/bin`, que aparecerá no seu diretório home. Se você estivesse logado como `sammy`, você veria `/Users/sammy/go/bin` no caminho.

    Output/Users/sammy/go/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

Agora que você tem a raiz do workspace criada e sua variável de ambiente `$GOPATH` definida, você pode criar seus projetos futuros com a seguinte estrutura de diretórios. Este exemplo assume que você está usando o [github.com](https://www.github.com) como seu repositório:

    $GOPATH/src/github.com/username/project

Se você estivesse trabalhando no projeto [`https://github.com/digitalocean/godo`](https://github.com/digitalocean/godo), você iria colocá-lo no seguinte diretório:

    $GOPATH/src/github.com/digitalocean/godo

Estruturar seus projetos dessa maneira tornará os projetos disponíveis com a ferramenta `go get`. Isso também ajudará a legibilidade mais tarde.

Você pode verificar isso usando o comando `go get` para buscar a biblioteca `godo`:

    go get github.com/digitalocean/godo

Você pode ver se baixou com sucesso o pacote `godo` listando o diretório:

    ls -l $GOPATH/src/github.com/digitalocean/godo

Você deve ver uma saída semelhante a esta:

    Output-rw-r--r-- 1 sammy staff 2892 Apr 5 15:56 CHANGELOG.md
    -rw-r--r-- 1 sammy staff 1851 Apr 5 15:56 CONTRIBUTING.md
    .
    .
    .
    -rw-r--r-- 1 sammy staff 4893 Apr 5 15:56 vpcs.go
    -rw-r--r-- 1 sammy staff 4091 Apr 5 15:56 vpcs_test.go

Neste passo, você criou um workspace Go e configurou as variáveis de ambiente necessárias. No próximo passo, você testará o workspace com algum código.

## Passo 6 — Criando um Programa Simples

Agora que você tem o workspace Go configurado, é hora de criar um simples programa “Hello, World!”. Isso garantirá que o workspace esteja configurado corretamente e também lhe dará a oportunidade de se familiarizar com o Go.

Como estamos criando um único arquivo-fonte Go, e não um projeto real, não precisamos estar em nosso workspace para fazer isso.

A partir do seu diretório home, abra um editor de texto de linha de comando, como o `nano`, e crie um novo arquivo:

    nano hello.go

Quando o arquivo de texto abrir no Terminal, digite seu programa:

    package main
    
    import "fmt"
    
    func main() {
        fmt.Println("Hello, World!")
    }

Saia do nano pressionando as teclas `control` e `x`, e quando solicitado a salvar o arquivo, pressione `y`.

Este código usará o pacote `fmt` e chamará a função `Println` com `Hello, World!` como argumento. Isso fará com que a frase `Hello, World!` seja impressa no terminal quando o programa for executado.

Ao sair do `nano` e retornar ao seu shell, execute o programa:

    go run hello.go

O programa `hello.go` que você acabou de criar fará com que o Terminal produza a seguinte saída:

    OutputHello, World!

Neste passo, você usou um programa básico para verificar se seu workspace Go está configurado corretamente.

## Conclusão

Parabéns! Neste ponto, você tem um workspace de programação Go configurado em sua máquina local com macOS e pode começar um projeto de codificação!
