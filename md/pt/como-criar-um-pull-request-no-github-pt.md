---
author: Lisa Tagliaferri
date: 2018-11-09
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-criar-um-pull-request-no-github-pt
---

# Como Criar um Pull Request no GitHub

### Introdução

Livre e open-source, o Git é um sistema de controle de versão distribuído que torna os projetos de software colaborativo mais gerenciáveis. Muitos projetos mantém seus arquivos em um repositório Git, e sites como o Github tornaram o compartilhamento e a contribuição para o código simples e efetiva.

Projetos open-source que são hospedados em repositórios públicos beneficiam-se de contribuições feitas pela ampla comunidade de desenvolvedores através de pull requests, que solicitam que um projeto aceite as alterações feitas em seu repositório de código.

Este tutorial vai guiá-lo no processo de realizar um pull request para um repositório Git através da linha de comando para que você possa contibuir com projetos de software open-source.

## Pré-requisitos

Você deve ter o Git instalado em sua máquina local. Você pode verificar se o Git está instalado em seu computador e passar pelo processo de instalação para o seu sistema operacional, seguindo [este guia](an-introduction-to-contributing-to-open-source-projects-and-installing-git#check-if-git-is-installed).

Você também precisará ter ou criar uma conta no GitHub. Você pode fazer isso através do website do GitHub, [github.com](https://github.com/), e pode ou efetuar login ou criar sua conta.

Finalmente, você deve identificar um projeto de software open-source para contribuir. Você pode se familiarizar mais com os projetos open-source lendo [essa introdução](an-introduction-to-contributing-to-open-source-projects-and-installing-git).

## Crie uma Cópia do Repositório

Um **repositório** , ou **repo** para abreviar, é essencialmente a pasta principal do projeto. O repositório contém todos os arquivos relevantes do projeto, incluindo documentação, e também armazena o histórico de revisão para cada arquivo. No GitHub, os repositórios podem ter vários colaboradores e podem ser públicos ou privados.

Para trabalhar em um projeto open-source, primeiro você precisará criar sua própria cópia do repositório. Para fazer isso, você deve fazer um fork do repositório e então fazer a clonagem dele para que você tenha uma cópia de trabalho local.

### Faça o Fork do Repositório

Você pode fazer um fork de um repositório navegando até a URL GitHub do projeto open-source que você gostaria de contribuir.

As URLs de repositórios GitHub irão referenciar o nome do usuário associado com o proprietário do repositório, bem como o nome do repositório. Por exemplo, DigitalOcean Community é o proprietário do repositório do projeto [cloud\_haiku](https://github.com/do-community/cloud_haiku), assim a URL GitHub para esse projeto é:

    https://github.com/do-community/cloud_haiku

No exemplo acima, **do-community** é o nome do usuário e **cloud\_haiku** é o nome do repositório.

Um vez que você identificou o projeto que você gostaria de contribuir, você pode navegar até a URL, que estará formatada da seguinte forma:

    https://github.com/nome-do-usuário/repositório

Ou você pode procurar o projeto usando a barra de pesquisa do GitHub.

Quando você estiver na página principal do repositório, você verá um botão “Fork” no seu lado superior direito da página, abaixo do seu ícone de usuário:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/PullRequest/GitHub_Repo.gif)

Clique no botão fork para iniciar o processo de fork. Dentro da janela do seu navegador, você receberá um feedback assim:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/PullRequest/GitHub_Forking.png)

Quando o processo estiver concluído, o seu navegador irá para uma tela semelhante à imagem do repositório acima, exceto que no topo você verá seu nome de usuário antes do nome do repositório, e na URL ela também mostrará seu nome de usuário antes do nome do repositório.

Então, no exemplo acima, em vez de **do-community / cloud\_haiku** na parte superior da página, você verá **seu-nome-de-usuário / cloud\_haiku** , e a nova URL será parecida com isto:

    https://github.com/seu-nome-de-usuário/cloud_haiku

Com o fork do repositório realizado, você está pronto para cloná-lo para que você tenha uma cópia de trabalho local da base de código.

### Clone o Repositório

Para criar sua própria cópia local do repositório com o qual você gostaria de contribuir, primeiro vamos abrir uma janela de terminal.

Vamos utilizar o comando `git clone` juntamente com a URL que aponta para o seu fork do repositório.

Esta URL será semelhante à URL acima, exceto que agora ela irá terminar com `.git`. No exemplo do cloud\_haiku acima, a URL ficará assim:

    https://github.com/seu-nome-de-usuário/cloud_haiku.git

Você pode, alternativamente, copiar a URL usando o botão verde “Clone or download” da página do seu repositório que você acabou de fazer fork. Depois de clicar no botão, você poderá copiar a URL clicando no botão do fichário ao lado da URL:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/PullRequest/GitHubClipboardWide.png)

Uma vez que tenhamos a URL, estamos prontos para clonar o repositório. Para fazer isto, vamos combinar o comando `git clone` com a URL do repositório a partir da linha de comando em uma janela de terminal:

    git clone https://github.com/seu-nome-de-usuário/repositório.git

Agora que você tem uma cópia local do código, podemos passar para a criação de uma nova branch ou ramificação na qual iremos trabalhar com o código.

## Crie uma Nova Branch

Sempre que você trabalha em um projeto colaborativo, você e outros programadores que contribuem para o repositório terão ideias diferentes para novos recursos ou correções de uma só vez. Alguns desses novos recursos não levarão tempo significativo para serem implementados, mas alguns deles estarão em andamento. Por isso, é importante ramificar o repositório para que você possa gerenciar o fluxo de trabalho, isolar seu código e controlar quais recursos serão retornados à branch principal do repositório do projeto.

A branch principal padrão de um repositório de projeto é geralmente chamada de **master** branch. Uma prática comum recomendada é considerar qualquer coisa na branch master como sendo passível de se fazer o deploy para outras pessoas usarem a qualquer momento.

Ao criar uma nova branch, é muito importante que você a crie fora da branch master. Você também deve se certificar de que o nome da sua branch é descritivo. Em vez de chamá-la de minha-branch, você deve usar `frontend-hook-migration` ou `Corrigir erros de digitação na documentação`.

Para criar nossa branch, na nossa janela de terminal, vamos mudar nosso diretório para que estejamos trabalhando no diretório do repositório. Certifique-se de usar o nome real do repositório (como `cloud_haiku`) para mudar para esse diretório.

    cd repositório

Agora, vamos criar nossa nova branch com o comando `git branch`. Certifique-se de nomeá-la de maneira descritiva para que outras pessoas trabalhando no projeto entendam no que você está trabalhando.

    git branch nova-branch

Agora que nossa nova branch está criada, podemos mudar para nos certificar de que estamos trabalhando nessa branch usando o comando `git checkout`:

    git checkout nova-branch

Depois de inserir o comando `git checkout`, você receberá a seguinte saída:

    OutputSwitched to branch nova-branch

Alternativamente, você pode condensar os dois comandos acima, criando e mudando para a nova branch, com o seguinte comando e com a flag `-b`:

    git checkout -b nova-branch

Se você quiser mudar de volta para o master, você irá usar o comando `checkout` com o nome da branch master:

    git checkout master

O comando `checkout` vai lhe permitir alternar entre várias branches, para que você possa trabalhar em vários recursos de uma só vez.

Neste ponto, agora você pode modificar arquivos existentes ou adicionar novos arquivos ao projeto em sua própria branch.

## Faça Alterações Localmente

Depois de modificar os arquivos existentes ou adicionar novos arquivos ao projeto, você pode adicioná-los ao seu repositório local, o que podemos fazer com o comando `git add`. Vamos adicionar a flag `-A` para adicionar todas as alterações que fizemos:

    git add -A  

Em seguida, queremos registrar as alterações que fizemos no repositório com o comando `git commit`.

A **mensagem de commit** é um aspecto importante da sua contribuição de código; ela ajuda os outros contribuidores a entenderem completamente a mudança que você fez, por que você fez e o quanto é importante. Adicionalmente, as mensagens de commit fornecem um registro histórico das mudanças para o projeto em geral, ajudando os futuros contribuidores ao longo do caminho.

Se tivermos uma mensagem muito curta, podemos gravar isso com a flag `-m` e a mensagem entre aspas:

    git commit -m "Corrigidos erros de digitação na documentação"

Mas, a menos que seja uma mudança muito pequena, é bem provável que incluiremos uma mensagem de confirmação mais longa para que nossos colaboradores estejam totalmente atualizados com nossa contribuição. Para gravar esta mensagem maior, vamos executar o comando `git commit` que abrirá o editor de texto padrão:

    git commit

Se você gostaria de configurar seu editor de texto padrão, você pode fazê-lo com o comando `git config` e definir o nano como editor padrão, por exemplo:

    git config --global core.editor "nano"

Ou o vim:

    git config --global core.editor "vim"

Depois de executar o comando `git commit`, dependendo do editor de texto padrão que você está usando, sua janela de terminal deve exibir um documento pronto para edição que será semelhante a este:

GNU nano 2.0.6 File: …username/repository/.git/COMMIT\_EDITMSG

    
    # Please enter the commit message for your changes. Lines starting
    # with '#' will be ignored, and an empty message aborts the commit.
    # On branch nova-branch
    # Your branch is up-to-date with 'origin/new-branch'.
    #
    # Changes to be committed:
    # modified: novo-recurso.py
    #

Abaixo dos comentários introdutórios, você deve adicionar a mensagem de commit ao arquivo de texto.

Para escrever uma mensagem útil no commit, você deve incluir um sumário na primeira linha com cerca de 50 caracteres. Abaixo disso, e dividido em seções de fácil entendimento, você deve incluir uma descrição que indique o motivo pelo qual você fez essa alteração, como o código funciona, e informações adicionais que irão contextualizar e esclarecer o código para que outras pessoas revisem o trabalho ao mesclá-lo. Tente ser o mais útil e proativo possível para garantir que os responsáveis pela manutenção do projeto possam entender totalmente sua contribuição.

Depois de salvar e sair do arquivo de texto da mensagem de commit, você poderá verificar o commit que o git estará fazendo com o seguinte comando:

    git status

Dependendo das alterações que você fez, você receberá uma saída parecida com esta:

    OutputOn branch nova-branch
    Your branch is ahead of 'origin/nova-branch' by 1 commit.
      (use "git push" to publish your local commits)
    nothing to commit, working directory clean

Nesse ponto você pode usar o comando `git push` para fazer o push das alterações para a branch atual do repositório que você fez o fork:

    git push --set-upstream origin nova-branch

O comando irá lhe fornecer uma saída para que você saiba do progresso e será semelhante ao seguinte:

    OutputCounting objects: 3, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (2/2), done.
    Writing objects: 100% (3/3), 336 bytes | 0 bytes/s, done.
    Total 3 (delta 0), reused 0 (delta 0)
    To https://github.com/seu-nome-de-usuário /repositório .git
       a1f29a6..79c0e80 nova-branch -> <^>nova-branch< 
    Branch nova-branch set up to track remote branch nova-branch from origin.

Agora você pode navegar até o repositório que você fez o fork na sua página web do GitHub e alternar para a branch que você acabou de fazer push para ver as alterações que você fez diretamente no navegador.

Nesse ponto, é possível [fazer um pull request](how-to-create-a-pull-request-on-github#create-pull-request) para o repositório original, mas se ainda não o fez, certifique-se de que seu repositório local esteja atualizado com o repositório upstream.

## Atualize o Repositório Local

Enquanto você estiver trabalhando em um projeto ao lado de outros colaboradores, é importante que você mantenha seu repositório local atualizado com o projeto, pois você não deseja fazer um pull request de um código que cause conflitos. Para manter sua cópia local da base de código atualizada, você precisará sincronizar as alterações.

Primeiro vamos passar pela configuração de um repositório remoto para o fork, e então, sincronizar o fork.

### Configure um Repositório Remoto para o Fork

**Repositórios remotos** permitem que você colabore com outras pessoas em um projeto Git. Cada repositório remoto é uma versão do projeto que está hospedada na Internet ou em uma rede à qual você tem acesso. Cada repositório remoto deve ser acessível a você como somente leitura ou como leitura-gravação, dependendo dos seus privilégios de usuário.

Para poder sincronizar as alterações feitas em um fork com o repositório original com o qual você está trabalhando, você precisa configurar um repositório remoto que faça referência ao repositório upstream. Você deve configurar o repositório remoto para o repositório upstream apenas uma vez.

Primeiro, vamos verificar quais servidores remotos você configurou. O comando `git remote` listará qualquer repositório remoto que você já tenha especificado, então se você clonou seu repositório como fizemos acima, você verá pelo menos o repositório origin, que é o nome padrão fornecido pelo Git para o diretório clonado.

A partir do diretório do repositório em nossa janela de terminal, vamos usar o comando `git remote` juntamente com a flag `-v` para exibir as URLs que o Git armazenou junto com os nomes curtos dos repositórios remotos relevantes (como em “origin”):

    git remote -v

Como clonamos um repositório, nossa saída deve ser semelhante a isso:

    Output
    origin https://github.com/seu-nome-de-usuário/repositório-forked.git (fetch)
    origin https://github.com/seu-nome-de-usuário/repositório-forked.git (push)

Se você configurou anteriormente mais de um repositório remoto, o comando `git remote -v` fornecerá uma lista de todos eles.

Em seguida, vamos especificar um novo repositório remoto upstream para sincronizarmos com o fork. Este será o repositório original do qual fizemos o fork. Faremos isso com o comando `git remote add`.

    git remote add upstream https://github.com/nome-de-usuário-do-proprietário-original/repositório-original.git

Nesse exemplo, `upstream` é o nome abreviado que fornecemos para o repositório remoto, já que em termos do Git, “Upstream” refere-se ao repositório do qual nós clonamos. Se quisermos adicionar um ponteiro remoto ao repositório de um colaborador, podemos fornecer o nome de usuário desse colaborador ou um apelido abreviado para o nome abreviado.

Podemos verificar que nosso ponteiro remoto para o repositório upstream foi adicionado corretamente usando o comando `git remote -v` novamente a partir do diretório do repositório:

    git remote -v

    Outputorigin https://github.com/seu-nome-de-usuário/repositório-forked.git (fetch)
    origin https://github.com/seu-nome-de-usuário/repositório-forked.git (push)
    upstream https://github.com/nome-de-usuário-do-proprietário-original/repositório-original.git (fetch)
    upstream https://github.com/nome-de-usuário-do-proprietário-original/repositório-original.git (push)

Agora você pode se referir ao `upstream` na linha de comando em vez de escrever a URL inteira, e você está pronto para sincronizar seu fork com o repositório original.

### Sincronizando o Fork

Depois de configurarmos um repositório remoto que faça referência ao upstream e ao repositório original no GitHub, estamos prontos para sincronizar nosso fork do repositório para mantê-lo atualizado.

Para sincronizar nosso fork, a partir do diretório do nosso repositório local em uma janela de terminal, vamos utilizar o comando `git fetch` para buscar as branches juntamente com seus respectivos commits do repositório upstream. Como usamos o nome abreviado “upstream” para nos referirmos ao repositório upstream, passaremos o mesmo para o comando:

    git fetch upstream

Dependendo de quantas alterações foram feitas desde que fizemos o fork do repositório, sua saída pode ser diferente, e pode incluir algumas linhas de contagem, compactação e descompactação de objetos. Sua saída terminará de forma semelhante às seguintes linhas, mas pode variar dependendo de quantas branches fazem parte do projeto:

    OutputFrom https://github.com/nome-de-usuário-do-proprietário-original/repositório-original
     * [new branch] master -> upstream/master

Agora, os commits para o branch master serão armazenados em uma branch local chamada `upstream/master`.

Vamos mudar para a branch master local do nosso repositório:

    git checkout master

    OutputSwitched to branch 'master'

Agora mesclaremos todas as alterações feitas na branch master do repositório original, que vamos acessar através de nossa branch upstream/master local, com a nossa branch master local:

    git merge upstream/master

A saída aqui vai variar, mas começará com `Updating` se tiverem sido feitas alterações, ou `Already up-to-date`, se nenhuma alteração foi feita desde que você fez o fork do repositório.

A branch master do seu fork agora está em sincronia com o repositório upstream, e as alterações locais que você fez não foram perdidas.

Dependendo do seu fluxo de trabalho e da quantidade de tempo que você gasta para fazer alterações, você pode sincronizar seu fork com o código upstream do repositório original quantas vezes isso fizer sentido para você. No entanto, você certamente deve sincronizar seu fork antes de fazer um pull request para garantir que não contribuirá com código conflitante.

## Crie um Pull Request

Neste ponto, você está pronto para fazer um pull request para o repositório original.

Você deve navegar até o seu repositório onde você fez o fork e pressionar o botão “New pull request” no lado esquerdo da página.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/PullRequest/PRButton.png)

Você pode modificar a branch na próxima tela. Em qualquer site, você pode selecionar o repositório apropriado no menu suspenso e a branch apropriada.

Depois de ter escolhido, por exemplo, a branch master do repositório original no lado esquerdo, e a nova-branch do seu fork do lado direito, você deve ver uma tela assim:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/PullRequest/PullRequest.png)

O GitHub vai lhe alertar de que é possível mesclar as duas branches porque não há código concorrente. Você deve adicionar um título, um comentário e, em seguida, pressionar o botão “Create pull request”.

Neste ponto, os mantenedores do repositório original decidirão se aceitam ou não o seu pull request. Eles podem solicitar que você edite ou revise seu código antes de aceitar o pull request.

## Conclusão

Neste ponto, você enviou com êxito um pull request para um repositório de software open-source. Depois disso, você deve se certificar de atualizar e fazer um rebase do seu código enquanto espera que ele seja revisado. Os mantenedores do projeto podem pedir que você refaça seu código, então você deve estar preparado para isso.

Contribuir para projetos de open-source - e se tornar um desenvolvedor ativo de open-source - pode ser uma experiência gratificante. Fazer contribuições regulares para o software que você usa com frequência lhe permite certificar-se de que esse software seja tão valioso para outros usuários finais quanto possível.

Se você estiver interessado em aprender mais sobre o Git e colaborar com open-source, leia nossa série de tutoriais intitulada [An Introduction to Open Source](https://www.digitalocean.com/community/tutorial_series/an-introduction-to-open-source). Se você já conhece o Git e gostaria de um guia de consulta rápida, consulte “[Como Usar o Git: Um Guia de Consulta Rápida](como-usar-o-git-um-guia-de-consulta-rapida-pt).”

_Por Lisa Tagliaferri_
