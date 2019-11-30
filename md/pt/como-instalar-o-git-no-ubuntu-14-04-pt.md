---
author: Justin Ellingwood
date: 2015-05-26
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-git-no-ubuntu-14-04-pt
---

# Como Instalar o Git no Ubuntu 14.04

### Introdução

Uma ferramenta indispensável no desenvolvimento moderno de software é algum tipo de sistema de controle de versão. Os sistemas de controle de versão permitem que você mantenha o controle de seu software no nível de fonte. Você pode controlar alterações, reverter para estágios anteriores, e ramificar para criar versões alternativas de arquivos e diretórios.

Um dos mais populares sistemas de controle de versão é o `git`, um sistema distribuído de controle de versão. Muitos projetos mantêm seus arquivos em um repositório git, e sites como o GitHub e o BitBucket têm tornado o compartilhamento e contribuição de código mais simples e valioso.

Neste guia, vamos demonstrar como instalar o git em uma instância VPS de Ubuntu 14.04. Vamos cobrir como instalar o software de duas maneiras diferentes, cada uma com seus benefícios.

Este tutorial assume que você está conectado como um [usuário não root](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-14-04), que você pode aprender como criar aqui.

## Como instalar o Git com Apt

De longe, a maneira mais fácil de ter o `git` instalado e pronto para usar é utilizando os repositórios padrão do Ubuntu. Este é o método mais rápido, mas a versão pode ser mais antiga do que a versão mais recente. Se você precisa da última versão, considere os passos para compilar o `git` através dos fontes.

Você pode usar as ferramentas de gerenciamento de pacotes `apt` para atualizar seu índice de pacotes local. Depois disso, você pode baixar e instalar o programa:

    sudo apt-get update
    sudo apt-get install git

Isto irá baixar e instalar o `git` em seu sistema. Você ainda precisará completar os passos de configuração que cobrimos na seção “configuração”, portanto sinta-se livre para pular para [esta seção](how-to-install-git-on-ubuntu-14-04#how-to-set-up-git) agora.

## Como Instalar o Git através dos Fontes

Um método mais flexível de instalar o `git` é compilar o software através do fonte. Isso leva mais tempo e não será mantido através de seu gerenciador de pacotes, mas o permitirá baixar a versão mais recente e dará a você algum controle sobre as opções que incluir se quiser customizar.

Antes de começar, você precisa instalar os softwares dos quais o `git` depende. Isto está disponível nos repositórios padrão, assim podemos atualizar nosso índice local de pacotes e , então, instalar os pacotes:

    sudo apt-get update
    sudo apt-get install build-essential libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext unzip

Depois de ter instalado as dependências necessárias, você pode avançar e obter a versão do git que você quer visitando a [página do projeto git no GitHub](https://github.com/git/git).

A versão que você vê quando você chega na página do projeto é a ramificação que está sendo trabalhada ativamente. Se você quer a última versão estável, você deve alterar a ramificação para a última tag não “rc” com este botão no lado esquerdo do cabeçalho do projeto:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/git_install_1404/change_branch.png)

Depois, no lado direito da página, clique com o botão direito no botão “Download ZIP” e selecione a opção similar a “Copy Link Address”:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/git_install_1404/download_zip.png)

De volta ao seu servidor Ubuntu 14.04, você pode digitar wget e segui-lo colando o endereço que você copiou. A URL que você copiou pode ser diferente da minha:

    wget https://github.com/git/git/archive/v1.9.2.zip -O git.zip

Descompacte o arquivo que você baixou e mova-se para dentro do diretório resultante digitando:

    unzip git.zip
    cd git-*

Agora, você pode compilar o pacote e instalá-lo digitando estes dois comandos:

    make prefix=/usr/local all
    sudo make prefix=/usr/local install

Agora que você tem o git instalado, se você quiser fazer um upgrade para a última versão, você pode simplesmente clonar o repositório, e então compilar e instalar:

    git clone https://github.com/git/git.git

Para encontrar a URL para utilizar para a operação de clonagem, navegue até a ramificação ou tag que você quer na [página do projeto GitHub](https://github.com/git/git) e então, copie a URL de clonagem do lado direito:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/git_install_1404/clone_url.png)

Isto irá criar um novo diretório dentro do seu diretório atual, onde você pode recompilar o pacote e reinstalar a mais nova versão, da mesma forma que você fez acima. Isto irá sobrescrever sua versão mais antiga com a nova versão:

    make prefix=/usr/local all
    sudo make prefix=/usr/local install

## Como Configurar o Git

Agora que você já tem o Git instalado, você precisa fazer algumas pequenas coisas de forma que as mensagens de commit que serão geradas para você, contenham suas informações corretas.

A maneira mais fácil de se fazer isto é através do comando `git config`. Especificamente, precisamos fornecer nosso nome e endereço de e-mail porque o `git` embute estas informações dentro de cada commit que fazemos. Podemos avançar e adicionar estas informações digitando:

    git config --global user.name "Your Name"
    git config --global user.email "youremail@domain.com"

Podemos ver todos os itens de configuração que foram definidos digitando:

    git config --list
    
    git configuration
    
    user.name=Your Name
    user.email=youremail@domain.com

Como você pode ver, isso tem um formato ligeiramente diferente. A informação é armazenada no arquivo de configuração, que você pode opcionalmente editar manualmente com seu editor de textos assim:

    nano ~/.gitconfig
    
    ~/.gitconfig contents
    
    [user]
        name = Your Name
        email = youremail@domain.com

Existem muitas outras opções que você pode definir, mas estas são as duas essenciais que são necessárias. Se você pular esse passo, você provavelmente verá avisos quando você fizer commit com o `git` , semelhantes a este:

    Output when git username and email not set 
    
    [master 0d9d21d] initial project version
     Committer: root 
    Your name and email address were configured automatically based
    on your username and hostname. Please check that they are accurate.
    You can suppress this message by setting them explicitly:
    
        git config --global user.name "Your Name"
        git config --global user.email you@example.com
    
    After doing this, you may fix the identity used for this commit with:
    
        git commit --amend --reset-author

Isto traz mais trabalho para você, porque você terá que revisar os commits que você fez com a informação correta.

## Conclusão

Agora você deve ter o `git` instalado e pronto para uso em seu sistema. Para aprender mais sobre como utilizar o Git, veja este artigos:

- [Como Utilizar Efetivamente o Git](https://www.digitalocean.com/community/articles/how-to-use-git-effectively)
- [Como Utilizar Ramificações do Git](https://www.digitalocean.com/community/articles/how-to-use-git-branches)
