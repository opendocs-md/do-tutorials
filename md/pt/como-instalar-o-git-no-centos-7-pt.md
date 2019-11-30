---
author: Josh Barnett
date: 2019-08-02
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-git-no-centos-7-pt
---

# Como Instalar o Git no CentOS 7

### Introdução

O controle de versão tornou-se uma ferramenta indispensável no desenvolvimento de software moderno. Os sistemas de controle de versão permitem que você mantenha o controle do seu software no nível do código-fonte. Você pode acompanhar as alterações, reverter para os estágios anteriores e fazer a ramificação ou branching do código base para criar versões alternativas de arquivos e diretórios.

Um dos sistemas de controle de versão mais populares é o `git`. Muitos projetos mantêm seus arquivos em um repositório Git, e sites como o GitHub e o Bitbucket tornaram o compartilhamento e a contribuição para o código com o Git mais fácil do que nunca.

Neste guia, demonstraremos como instalar o Git em um servidor do CentOS 7. Vamos abordar como instalar o software de duas maneiras diferentes, cada uma com seus próprios benefícios, além de como configurar o Git para que você possa começar a colaborar imediatamente.

## Pré-requisitos

Antes de começar com este guia, há algumas etapas que precisam ser concluídas primeiro.

Você precisará de um servidor CentOS 7 instalado e configurado com um usuário não-root que tenha privilégios `sudo`. Se você ainda não fez isso, você pode executar os passos de 1 a 4 no [guia de Configuração Inicial do Servidor com CentOS 7](initial-server-setup-with-centos-7-pt) para criar essa conta.

Depois de ter seu usuário não-root, você pode usá-lo para fazer SSH em seu servidor CentOS e continuar com a instalação do Git.

## Instalar o Git

As duas formas mais comuns de instalar o Git serão descritas nesta seção. Cada opção tem suas próprias vantagens e desvantagens, e a escolha que você fizer dependerá de suas próprias necessidades. Por exemplo, os usuários que desejam manter atualizações para o software Git provavelmente vão querer usar o `yum` para instalá-lo, enquanto os usuários que precisam de recursos apresentados por uma versão específica do Git vão querer construir essa versão a partir do código-fonte.

### Opção Um — Instalar o Git com Yum

A maneira mais fácil de instalar o Git e tê-lo pronto para usar é utilizar os repositórios padrão do CentOS. Este é o método mais rápido, mas a versão do Git que é instalada dessa forma pode ser mais antiga que a versão mais recente disponível. Se você precisa da versão mais recente, considere compilar o `git` a partir do código-fonte (as etapas para este método podem ser encontradas mais abaixo neste tutorial).

Use o `yum`, gerenciador de pacotes nativo do CentOS, para procurar e instalar o pacote `git` mais recente disponível nos repositórios do CentOS:

    sudo yum install git

Se o comando for concluído sem erro, você terá o `git` baixado e instalado. Para verificar novamente se ele está funcionando corretamente, tente executar a verificação de versão integrada do Git:

    git --version

Se essa verificação produziu um número de versão do Git, você pode agora passar para **Configurando o Git** , encontrado mais abaixo neste artigo.

### Opção Dois — Instalar o Git a Partir do Código-fonte

Se você deseja baixar a versão mais recente do Git disponível, ou simplesmente deseja mais flexibilidade no processo de instalação, o melhor método para você é compilar o software a partir do código-fonte. Isso leva mais tempo, e não será atualizado e mantido através do gerenciador de pacotes `yum`, mas permitirá que você baixe uma versão mais recente do que a que está disponível através dos repositórios do CentOS, e lhe dará algum controle sobre as opções que você pode incluir.

Antes de começar, você precisará instalar o software do qual o `git` depende. Estas dependências estão todas disponíveis nos repositórios padrão do CentOS, junto com as ferramentas que precisamos para construir um binário a partir do código-fonte:

    sudo yum groupinstall "Development Tools"
    sudo yum install gettext-devel openssl-devel perl-CPAN perl-devel zlib-devel

Depois de ter instalado as dependências necessárias, você pode ir em frente e procurar a versão do Git que você deseja, visitando a [página de releases](https://github.com/git/git/releases) do projeto no GitHub.

![Git Releases on GitHub](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/git_centos7/git_releases.png)

A versão no topo da lista é a versão mais recente. Se ela não tiver um `-rc` (abreviação de “Release Candidate”) no nome, isso significa que é uma versão estável e segura para uso. Clique na versão que você deseja baixar para acessar a página de release dessa versão. Em seguida, clique com o botão direito do mouse no botão **Source code (tar.gz)** e copie o link para a sua área de transferência.

![Copy Source Code Link](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/git_centos7/git_download.png)

Agora vamos usar o comando `wget` em nosso servidor CentOS para baixar o arquivo fonte do link que copiamos, renomeando-o para `git.tar.gz` no processo, para que seja mais fácil trabalhar com ele.

**Nota:** a URL que você copiou pode ser diferente da minha, pois a versão que você baixou pode ser diferente.

    wget https://github.com/git/git/archive/v2.1.2.tar.gz -O git.tar.gz

Quando o download estiver concluído, podemos descompactar o arquivo fonte usando o `tar`. Vamos precisar de algumas flags extras para garantir que a descompactação seja feita corretamente: `z` descompacta o arquivo (já que todos os arquivos .gz são compactados), `x` extrai os arquivos e pastas individuais do arquivo, e `f` diz ao `tar` que estamos declarando um nome de arquivo para trabalhar.

    tar -zxf git.tar.gz

Isto irá descompactar o código-fonte compactado para uma pasta com o nome da versão do Git que baixamos (neste exemplo, a versão é 2.1.2, então a pasta é nomeada como `git-2.1.2`). Precisamos nos mover para essa pasta para começar a configurar nossa compilação. Em vez de nos preocuparmos com o nome completo da versão na pasta, podemos usar um caractere curinga (`*`) para nos poupar de algum problema ao mudar para essa pasta.

    cd git-*

Uma vez que estivermos na pasta de fontes, podemos começar o processo de compilação. Isso começa com algumas verificações de pré-compilação para coisas como dependências de software e configurações de hardware. Podemos verificar tudo o que precisamos com o script `configure` gerado pelo `make configure`. Este script também usará um `--prefix` para declarar `/usr/local` (a pasta padrão do programa para plataformas Linux) como o destino apropriado para o novo binário, e criará um `Makefile` para ser usado no passo seguinte.

    make configure
    ./configure --prefix=/usr/local

Makefiles são arquivos de configuração de script que são processados pelo utilitário `make`. Nosso Makefile dirá ao `make` como compilar um programa e vinculá-lo à nossa instalação do CentOS, para que possamos executar o programa corretamente. Com um Makefile pronto, agora podemos executar `make install` (com privilégios `sudo`) para compilar o código-fonte em um programa funcional e instalá-lo em nosso servidor:

    sudo make install

O Git deve agora ser compilado e instalado em seu servidor CentOS 7. Para verificar novamente se está funcionando corretamente, tente executar a verificação de versão integrada do Git:

    git --version

Se essa verificação produziu um número de versão do Git, então você pode passar para **Configurando o Git** abaixo.

## Configurando o Git

Agora que você tem o `git` instalado, você precisará enviar algumas informações sobre si mesmo para que as mensagens de commit sejam geradas com as informações corretas anexadas. Para fazer isso, use o comando `git config` para fornecer o nome e o endereço de e-mail que você gostaria de ter registrado em seus commits:

    git config --global user.name "Seu Nome"
    git config --global user.email "voce@example.com"

Para confirmar que essas configurações foram adicionadas com sucesso, podemos ver todos os itens de configuração que foram definidos, digitando:

    git config --list

    user.name=Seu Nome
    user.email=voce@example.com

Essa configuração te poupará do trabalho de ver uma mensagem de erro e ter que revisar os commits após submetê-los.

## Conclusão

Agora você deve ter o `git` instalado e pronto para uso em seu sistema. Para saber mais sobre como usar o Git, confira estes artigos mais detalhados:

- [How To Use Git Effectively](https://www.digitalocean.com/community/articles/how-to-use-git-effectively)
- [How To Use Git Branches](https://www.digitalocean.com/community/articles/how-to-use-git-branches)
