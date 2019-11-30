---
author: Lisa Tagliaferri
date: 2018-10-30
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-usar-o-git-um-guia-de-consulta-rapida-pt
---

# Como Usar o Git: Um Guia de Consulta Rápida

### Introdução

Equipes de desenvolvedores e mantenedores de software open-source geralmente gerenciam seus projetos através do Git, um sistema distribuído de controle de versão que suporta colaboração.

Este artigo no estilo de Guia de Consulta Rápida fornece uma referência de comandos que são úteis para o trabalho e colaboração em um repositório Git. Para instalar e configurar o Git, certifique-se de ler “[How To Contribute to Open Source: Getting Started with Git.](how-to-contribute-to-open-source-getting-started-with-git)”

**Como utilizar esse guia:**

- Este guia está no formato de Guia de Consulta Rápida com fragmentos de linha de comando autocontidos.

- Pule para qualquer seção que seja relevante para a tarefa que você está tentando completar.

- Quando você vir texto destacado nos comandos deste guia, tenha em mente que este texto deve se referir aos commits e arquivos em seu próprio repositório.

## Configuração e Inicialização

Verifique a versão do Git com o seguinte comando, que irá também confirmar que o git está instalado.

    git --version

Você pode inicializar seu diretório de trabalho atual como um repositório Git com o `init`.

    git init

Para copiar um repositório Git existente hospedado remotamente, você irá utilizar `git clone` com a URL do repositório ou a localização do servidor (no último caso você irá usar `ssh`).

    git clone https://www.github.com/username/nome-do-repositório

Mostrar o repositório remoto do seu diretório Git atual.

    git remote

Para uma saída mais detalhada, use a flag `-v`.

    git remote -v

Adicionar o Git upstream, que pode ser uma URL ou pode estar hospedado em um servidor (no último caso, conecte com `ssh`).

    git remote add upstream https://www.github.com/username/nome-do-repositório

## Staging

Quando você modificou um arquivo e o marcou para ir no próximo commit, ele é considerado um arquivo preparado ou staged.

Verifique o status do seu repositório Git, incluindo arquivos adicionados que não estão como staged, e arquivos que estão como staged.

    git status

Para colocar como staged os arquivos modificados, utilize o comando `add`, que você pode executar diversas vezes antes de fazer um commit. Se você fizer alterações subsequentes que queira ver incluídas no próximo commit, você deve exwcutar `add` novamente.

Você pode especificar o arquivo exato com o `add`.

    git add meu_script.py

Com o `.` você pode adicionar todos os arquivos no diretório atual incluindo arquivos que começam com um `.`.

    git add .

Você pode remover um arquivo da área de staging enquanto mantém as alterações no seu diretório de trabalho com `reset`.

    git reset meu_script.py

## Fazendo Commit

Um vez que você tenha colocado no stage a suas atualizações, você está pronto para fazer o commit delas, que irá gravar as alterações que você fez no repositório.

Para fazer commit dos arquivos em stage, você irá executar o comando `commit` com sua mensagem de confirmação significativa para que você possa rastrear os commits.

    git commit -m "Mensagem de commit"

Você pode condensar o staging de todos os arquivos rastreados fazendo o commit deles em uma única etapa.

    git commit -am "Mensagem de commit"

Se você precisar modificar a sua mensagem de commit, você pode fazer isto com a flag `--amend`.

    git commit --amend -m "Nova Mensagem de commit"

## Branches ou Ramificações

Uma branch ou ramificação é um ponteiro móvel para um dos commits no repositório. Ele lhe permite isolar o trabalho e gerenciar o desenvolvimento de recursos e integrações. Você pode aprender mais sobre branches através da leitura da [documentação do Git](https://git-scm.com/book/en/v1/Git-Branching-What-a-Branch-Is).

Listar todas as branches atuais com o comando `branch`. Um aterisco (`*`) irá aparecer próximo à sua branch ativa atualmente.

    git branch

Criar uma nova branch. Você permanecerá na sua branch ativa até mudar para a nova.

    git branch nova-branch

Alternar para qualquer branch existente e fazer checkout em seu diretório de trabalho atual.

    git checkout outra-branch

Você pode consolidar a criação e o checkout de uma nova branch utilizando a flag `-b`.

    git checkout -b nova-branch

Renomear a sua branch.

    git branch -m nome-da-branch-atual novo-nome-da-branch

Mesclar o histórico da branch especificada àquela em que você está trabalhando atualmente.

    git merge nome-da-branch

Abortar a mesclagem, no caso de existirem conflitos.

    git merge --abort

Você também pode selecionar um commit particular para mesclar com `cherry-pick` e com a string que referencia o commit específico.

    git cherry-pick f7649d0

Quando você tiver mesclado uma branch e não precisar mais dela, poderá excluí-la.

    git branch -d nome-da-branch

Se você não tiver mesclado uma branch com o master, mas tiver certeza de que deseja excluí-la, poderá forçar a exclusão da branch.

    git branch -D nome-da-branch

## Colaborar e Atualizar

Para baixar alterações de outro repositório, tal como o upstream remoto, você irá usar o `fetch`.

    git fetch upstream

Mesclar os commits baixados.

    git merge upstream/master

Envie ou transmita seus commits na branch local para a branch do repositório remoto.

    git push origin master

Busque e mescle quaisquer commits da branch remota de rastreamento.

    git pull

## Inspecionando

Mostrar o histórico de commits para a branch ativa atualmente.

    git log

Mostrar os commits que alteraram um arquivo particular. Isso segue o arquivo, independentemente da renomeação do mesmo.

    git log --follow meu_script.py

Mostrar os commits que estão em uma branch e não estão em outra. Isto irá mostrar os commits em `a-branch` que não estão em `b-branch`.

    git log a-branch..b-branch

Observe os logs de referência (`reflog`) para ver quando as dicas de branches e outras referências foram atualizadas pela última vez dentro do repositório.

    git reflog

Mostrar qualquer objeto no Git através da sua string de commit ou hash em um formato mais legível.

    git show de754f5

## Mostrar Alterações

O comando `git diff` mostra as alterações entre commits, branches, entre outras. Você pode ler mais detalhadamente sobre isso através da [Documentação do Git](https://git-scm.com/docs/git-diff).

Comparar arquivos modificados que estão na área de staging.

    git diff --staged

Exibe o diff do que está em a-branch mas não está em b-branch.

    git diff a-branch..b-branch

Mostrar o diff entre dois commits específicos.

    git diff 61ce3e6..e221d9c

## Stashing

Às vezes, você descobrirá que fez alterações em algum código, mas, antes de terminar, precisa começar a trabalhar em outra coisa. Você ainda não está pronto para fazer o commit das alterações que você fez até agora, mas não quer perder seu trabalho. O comando `git stash` lhe permitirá salvar suas modificações locais e reverter para o diretório de trabalho que está alinhado com o commit mais recente do `HEAD`.

Guarde (stash) seu trabalho atual.

    git stash

Veja o que você tem guardado atualmente.

    git stash list

Seus rascunhos serão nomeados `stash@{0}`, `stash@{1}`, e assim por diante.

Mostrar informações sobre um rascunho em particular.

    git stash show stash@{0}

Para trazer os arquivos de um rascunho atual enquanto mantém o rascunho guardado, utilize `apply`.

    git stash apply stash@{0}

Se você quer trazer os arquivos de uma rascunho e não precisa mais do rascunho, utilize `pop`.

    git stash pop stash@{0}

Se você não precisar mais dos arquivos salvos em um determinado rascunho ou stash, você pode descartar o rascunho com `drop`.

    git stash drop stash@{0}

Se você tiver muitos rascunhos salvos e não precisar mais de nenhum deles, você pode utilizar `clear` para removê-los.

    git stash clear

## Ignorando Arquivos

Se você quiser manter arquivos em seu diretório local do Git, mas não quer fazer o commit deles no projeto, você pode adicionar esses arquivos ao seu arquvo `.gitignore` para que não causem conflitos.

Utilize um editor de textos como o nano para adicionar arquivos ao arquivo `.gitignore`.

    nano .gitignore

Para ver exemplos de arquivos `.gitignore`, você pode olhar o [repositório de modelos `.gitignore`](https://github.com/github/gitignore) do GitHub.

## Rebasing

Um rebase nos permite mover as branches alterando o commit no qual elas são baseadas. Como o rebasing, você pode reescrever ou reformular os commits.

Você pode iniciar um rebase chamando o número de commits que você fez e que você quer fazer rebase (`5` no caso abaixo).

    git rebase -i HEAD~5

Como alternativa, você pode fazer o rebase com base em uma determinada string de commit ou hash.

    git rebase -i 074a4e5

Depois de ter reescrito ou reformulado os commits, você pode concluir o rebase da sua branch em cima da versão mais recente do código upstream do projeto.

    git rebase upstream/master

Para aprender mais sobre rabase e atualização, você pode ler [How To Rebase and Update a Pull Request](how-to-rebase-and-update-a-pull-request), que também é aplicável a qualquer tipo de commit.

## Resetando

Às vezes, inclusive após um rebase, você precisa redefinir sua árvore de trabalho. Você pode redefinir ou resetar para um commit específico e **excluir todas as alterações** com o seguinte comando.

    git reset --hard 1fc6665

Para forçar a enviar seu último commit conhecido e não conflitante para o repositório de origem, você precisará usar o `--force`.

**Atenção:** Forçar o envio ou pushing para o master não é muito aprovado a menos que haja uma razão realmente importante para fazê-lo. Use isso com moderação ao trabalhar em seus próprios repositórios e evite fazer isso quando estiver colaborando.

    git push --force origin master

Para remover arquivos e subdiretórios locais não rastreados do diretório Git para uma branch de trabalho limpa, você pode usar `git clean`.

    git clean -f -d

Se você precisar modificar seu repositório local para que ele pareça com o upstream master atual (isto é, quando há muitos conflitos), você pode executar um hard reset.

**Nota:** Executar este comando fará com que seu repositório local fique exatamente igual ao upstream. Todos os commits que você fez, mas que não foram enviados para o upstream, **serão destruídos**.

    git reset --hard upstream/master

## Conclusão

Este guia aborda alguns dos comandos mais comuns do Git que você pode usar ao gerenciar repositórios e colaborar em software.

Você pode aprender mais sobre software open-source e colaboração em nossa [série de tutoriais Introduction to Open Source](https://www.digitalocean.com/community/tutorial_series/an-introduction-to-open-source):

- [How To Contribute to Open Source: Getting Started with Git](how-to-contribute-to-open-source-getting-started-with-git)

- [How To Create a Pull Request on GitHub](how-to-create-a-pull-request-on-github)

- [How To Rebase and Update a Pull Request](how-to-rebase-and-update-a-pull-request)

- [How To Maintain Open-Source Software Projects](how-to-maintain-open-source-software-projects)

Existem muitos outros comandos e variações que você pode achar úteis como parte do seu trabalho com o Git. Para saber mais sobre todas as opções disponíveis, você pode executar o comando abaixo receber informações úteis:

    git --help

Você também pode ler mais sobre o Git e ver a documentação dele no [website oficial do Git](https://git-scm.com/).

_Por Lisa Tagliaferri_
