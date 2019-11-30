---
author: Justin Ellingwood
date: 2018-10-11
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-configurar-pipelines-de-integracao-continua-com-o-gitlab-ci-no-ubuntu-16-04-pt
---

# Como Configurar Pipelines de Integração Contínua com o GitLab CI no Ubuntu 16.04

### Introdução

O GitLab Community Edition é um provedor de repositório Git auto-hospedado com recursos adicionais para ajudar no gerenciamento de projetos e no desenvolvimento de software. Um dos recursos mais valiosos que o GitLab oferece é a ferramenta embutida de integração e entrega contínua chamada [GitLab CI](https://about.gitlab.com/features/gitlab-ci-cd/).

Neste guia, vamos demonstrar como configurar o GitLab CI para monitorar seus repositórios por mudanças e executar testes automatizados para validar código novo. Começaremos com uma instalação do GitLab em execução, na qual copiaremos um repositório de exemplo para uma aplicação básica em Node.js. Depois de configurarmos nosso processo de CI, quando um novo commit é enviado ao repositório o GitLab irá utilizar o CI runner para executar o conjunto de testes em cima do código em um container Docker isolado.

## Pré-requisitos

Antes de começarmos, você precisará configurar um ambiente inicial. Vamos precisar de um servidor GitLab seguro configurado para armazenar nosso código e gerenciar nosso processo de CI/CD. Adicionalmente, precisaremos de um local para executar os testes automatizados. Este pode ser o mesmo servidor em que o GitLab está instalado ou um host separado. As seções abaixo cobrem os requisitos em mais detalhes.

### Um Servidor GitLab Protegido com SSL

Para armazenar nosso código-fonte e configurar nossas tarefas de CI/CD, precisamos de uma instância do GitLab instalada em um servidor Ubuntu 16.04. Atualmente o GitLab recomenda um servidor com no mínimo **2 núcleos de CPU** e **4GB de RAM**. Para proteger seu código de ser exposto ou adulterado, a instância do GitLab será protegida com SSL usando o Let’s Encrypt. Seu servidor precisa ter um nome de domínio associado a ele para completar essa etapa.

Você pode atender esses requisitos usando os seguintes tutoriais:

- [Configuração Inicial de servidor com Ubuntu 16.04](configuracao-inicial-de-servidor-com-ubuntu-16-04-pt): Crie um usuário com privilégios `sudo` e configure um firewall básico.

- [Como Instalar e Configurar o GitLab no Ubuntu 16.04](how-to-install-and-configure-gitlab-on-ubuntu-16-04): Instale o GitLab no servidor e proteja-o com um certificado Let’s Encrypt TLS/SSL.

Estaremos demonstrando como compartilhar CI/CD runners (os componentes que executam os testes automatizados). Se você deseja compartilhar CI runners entre projetos, recomendamos fortemente que você restrinja ou desative as inscrições públicas. Se você não modificou suas configurações durante a instalação, volte e siga [a etapa opcional do artigo de instalação do GitLab sobre como restringir ou desabilitar as inscrições](how-to-install-and-configure-gitlab-on-ubuntu-16-04#restrict-or-disable-public-sign-ups-(optional)) para evitar abusos por parte de terceiros.

### Um ou Mais Servidores para Utilizar como GitLab CI Runners

GitLab CI Runners são os servidores que verificam o código e executam testes automatizados para validar novas alterações. Para isolar o ambiente de testes, estaremos executando todos os nossos testes automatizados em containers Docker. Para fazer isso, precisamos instalar o Docker no servidor ou servidores que irão executar os testes.

Esta etapa pode ser concluída no servidor GitLab ou em outro servidor Ubuntu 16.04 para fornecer isolamento adicional e evitar contenção de recursos. Os seguintes tutoriais instalarão o Docker no host que você deseja usar para executar seus testes:

- [Configuração Inicial de servidor com Ubuntu 16.04](configuracao-inicial-de-servidor-com-ubuntu-16-04-pt): Crie um usuário com privilégios `sudo` e configure um firewall básico. (você não precisa completar isso novamente se estiver configurando o CI runner no servidor do GitLab).

- [Como Instalar e Usar o Docker no Ubuntu 16.04](como-instalar-e-usar-o-docker-no-ubuntu-16-04-pt): Siga os **passos 1 e 2** para instalar o Docker no servidor.

Quando estiver pronto para começar, continue com este guia.

## Copiando o Repositório de Exemplo a partir do GitHub

Para começar, vamos criar um novo projeto no GitLab contendo a aplicação de exemplo em Node.js. Iremos [importar o repositório original diretamente do GitHub](https://github.com/do-community/hello_hapi/) para que não tenhamos que carregá-lo manualmente.

Efetue o login no GitLab e clique no ícone de adição no canto superior direito e selecione **New project** para adicionar um novo projeto:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/new_project_icon_3.png)

Na página do novo projeto, clique na aba **Import project** :

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/import-project.png)

A seguir, clique no botão **Repo by URL**. Embora exista uma opção de importação do GitHub, ela requer um token de acesso Pessoal e é usada para importar o repositório e informações adicionais. Estamos interessados apenas no código e no histórico do Git, portanto, importar pela URL é mais fácil.

No campo **Git repository URL** , insira a seguinte URL do repositório GitHub:

    https://github.com/do-community/hello_hapi.git

Deve se parecer com isto:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/new_project_github_url2.png)

Como esta é uma demonstração, provavelmente é melhor manter o repositório marcado como **Private** ou privado. Quando terminar, clique em **Create project**.

O novo projeto será criado baseado no repositório importado do Github.

## Entendendo o arquivo .gitlab-ci.yml

O GitLab CI procura por um arquivo chamado `.gitlab-ci.yml` dentro de cada repositório para determinar como ele deve testar o código. O repositório que importamos já tem um arquivo `.gitlab-ci.yml` configurado para o projeto. Você pode aprender mais sobre o formato lendo a [documentação de referência do .gitlab-ci.yml](https://docs.gitlab.com/ce/ci/yaml/README.html).

Clique no arquivo `.gitlab-ci.yml` na interface do GitLab para o projeto que acabamos de criar. A configuração do CI deve ser algo assim:

.gitlab-ci.yml

    
    image: node:latest
    
    stages:
      - build
      - test
    
    cache:
      paths:
        - node_modules/
    
    install_dependencies:
      stage: build
      script:
        - npm install
      artifacts:
        paths:
          - node_modules/
    
    test_with_lab:
      stage: test
      script: npm test

O arquivo utiliza a [sintaxe de configuração YAML no GitLab CI](https://docs.gitlab.com/ee/ci/yaml/) para definir as ações que devem ser tomadas, a ordem na qual elas devem executar, sob quais condições elas devem ser executadas e os recursos necessários para concluir cada tarefa. Ao escrever seus próprios arquivos de CI do GitLab, você pode checar com um validador indo até `/ci/lint` em sua instância GitLab para validar que seu arquivo está formatado corretamente.

O arquivo de configuração começa declarando uma `image` ou imagem do Docker que deve ser usada para executar o conjunto de testes. Como o Hapi é um framework Node.js, estamos usando a imagem Node.js mais recente:

    image: node:latest

Em seguida, definimos explicitamente os diferentes estágios de integração contínua que serão executados:

    stages:
      - build
      - test

Os nomes que você escolhe aqui são arbitrários, mas a ordenação determina a ordem de execução dos passos que se seguirão. Stages ou estágios são tags que você pode aplicar a jobs individuais. O GitLab vai executar jobs do mesmo estágio em paralelo e vai esperar para executar o próximo estágio até que todos os jobs do estágio atual estejam completos. Se nenhum estágio for definido, o GitLab usará três estágios chamados `build`, `test`, e `deploy` e atribuir todos os jobs ao estágio `test` por padrão.

Após definir os estágios, a configuração inclui uma definição de `cache`:

    cache:
      paths:
        - node_modules/

Isso especifica arquivos ou diretórios que podem ser armazenados em cache (salvos para uso posterior) entre execuções ou estágios. Isso pode ajudar a diminuir o tempo necessário para executar tarefas que dependem de recursos que podem não ser alterados entre execuções. Aqui, estamos fazendo cache do diretório `node_modules`, que é onde o `npm` instala as dependências que ele baixa.

Nosso primeiro job é chamado `install_dependencies`:

    install_dependencies:
      stage: build
      script:
        - npm install
      artifacts:
        paths:
          - node_modules/

Os jobs podem ter qualquer nome, mas como os nomes serão usados na interface do usuário do GitLab, nomes descritivos são úteis. Normalmente, o `npm install` pode ser combinado com os próximos estágios de teste, mas para melhor demonstrar a interação entre os estágios, estamos extraindo essa etapa para executar em seu próprio estágio.

Marcamos o estágio explicitamente como “build” com a diretiva `stage`. Em seguida, especificamos os comandos reais a serem executados usando a diretiva `script`. Você pode incluir vários comandos inserindo linhas adicionais dentro da seção `script`.

A sub-seção `artifacts` é utilizada para especificar caminhos de arquivo ou diretório para salvar e passar entre os estágios. Como o comando `npm install` instala as dependências do projeto, nossa próxima etapa precisará de acesso aos arquivos baixados. A declaração do caminho `node_modules` garante que o próximo estágio terá acesso aos arquivos. Estes estarão também disponíveis para visualizar ou baixar na interface de usuário do GitLab após o teste, assim isso é útil para construir artefatos como binários também. Se você quiser salvar tudo que foi produzido durante o estágio, substitua a seção `path` inteira por `untracked: true`.

Finalmente, o segundo job chamado `test_with_lab` declara o comando que realmente executará o conjunto de testes:

    test_with_lab:
      stage: test
      script: npm test

Colocamos isso no estágio `test`. Como esse é o último estágio, ele tem acesso aos artefatos produzidos pelo estágio `build` que são as dependências do projeto em nosso caso. Aqui, a seção `script` demonstra a sintaxe YAML de linha única que pode ser usada quando há apenas um único item. Poderíamos ter usado essa mesma sintaxe no job anterior, já que apenas um comando foi especificado.

Agora que você tem uma ideia básica sobre como o arquivo `.gitlab-ci.yml` define tarefas CI/CD, podemos definir um ou mais runners capazes de executar o plano de testes.

## Disparando uma Execução de Integração Contínua

Como o nosso repositório inclui um arquivo `.gitlab-ci.yml`, quaisquer novos commits irão disparar uma nova execução de CI. Se não houver runners disponíveis, a execução da CI será definida como “pending” ou pendente. Antes de definirmos um runner, vamos disparar uma execução de CI para ver como é um job no estado pendente. Uma vez que um runner esteja disponível, ele imediatamente pegará a execução pendente.

De volta à visão do repositório do projeto do GitLab `hello_hapi`, clique no **sinal de adição** ao lado do branch e do nome do projeto e selecione **New file** no menu:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/new_file_button2.png)

Na próxima página, insira `dummy_file` no campo **File name** e insira algum texto na janela principal de edição:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/dummy_file2.png)

Clique em **commit changes** na parte inferior quando terminar.

Agora, retorne à página principal do projeto. Um pequeno ícone de **pausa** será anexado ao commit mais recente. Se você passar o mouse sobre o ícone, ele irá exibir “Commit:pending”:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/pending_marker_2.png)

Isso significa que os testes que validam as alterações de código ainda não foram executados.

Para obter mais informações, vá para o topo da página e clique em **Pipelines**. Você será direcionado para a página de visão geral do pipeline, na qual é possível ver que a execução CI está marcada como pending e rotulada como “stuck”:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/pipeline_index_stuck.png)

**Nota:** Do lado direito há um botão para a ferramenta **CI Lint**. É aqui que você pode verificar a sintaxe de qualquer arquivo `gitlab-ci.yml` que você escreve.

A partir daqui, você pode clicar no status **pending** para obter mais detalhes sobre a execução. Esta visão mostra os diferentes estágios de nossa execução, bem como os jobs individuais associados a cada estágio:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/pipeline_detail_view.png)

Finalmente, clique no job **install\_dependencies**. Isso lhe dará detalhes específicos sobre o que está atrasando a execução:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/job_detail_view.png)

Aqui, a mensagem indica que o trabalho está preso devido à falta de runners. Isso é esperado, uma vez que ainda não configuramos nenhum. Quando um runner estiver disponível, essa mesma interface poderá ser usada para ver a saída. Este é também o local onde você pode baixar os artefatos produzidos durante o build.

Agora que sabemos como é um job pendente, podemos atribuir um runner de CI ao nosso projeto para pegar o job pendente.

## Instalando o Serviço CI Runner do GitLab

Agora estamos prontos para configurar um CI Runner do GitLab. Para fazer isso, precisamos instalar o pacote CI runner do GitLab no sistema e iniciar o serviço do runner. O serviço pode executar várias instâncias do runner para projetos diferentes.

Como mencionado nos pré-requisitos, você pode completar estes passos no mesmo servidor que hospeda sua instância do GitLab ou em um servidor diferente se você quiser ter certeza de evitar a contenção de recursos. Lembre-se de que, seja qual for o host escolhido, você precisa do Docker instalado para a configuração que usaremos.

O processo de instalação do serviço CI runner do GitLab é similar ao processo usado para instalar o próprio GitLab. Iremos baixar um script para adicionar um repositório GitLab à nossa lista de fontes `apt`. Depois de executar o script, faremos o download do pacote do runner. Podemos então configurá-lo para servir nossa instância do GitLab.

Comece baixando a versão mais recente do script de configuração do repositório do GitLab CI runner para o diretório `/tmp` (este é um repositório diferente daquele usado pelo servidor GitLab):

    curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh -o /tmp/gl-runner.deb.sh

Sinta-se à vontade para examinar o script baixado para garantir que você está confortável com as ações que ele irá tomar. Você também pode encontrar uma versão hospedada do script [aqui](https://packages.gitlab.com/runner/gitlab-ci-multi-runner/install):

    less /tmp/gl-runner.deb.sh

Quando estiver satisfeito com a segurança do script, execute o instalador:

    sudo bash /tmp/gl-runner.deb.sh

O script irá configurar seu servidor para usar os repositórios mantidos pelo GitLab. Isso permite gerenciar os pacotes do runner do GitLab com as mesmas ferramentas de gerenciamento de pacotes que você usa para os outros pacotes do sistema. Quando isso estiver concluído, você pode prosseguir com a instalação usando `apt-get`:

    sudo apt-get install gitlab-runner

Isso irá instalar o pacote CI runner do GitLab no sistema e iniciar o serviço GitLab runner.

## Configurando um GitLab Runner

Em seguida, precisamos configurar um CI runner do GitLab para que ele possa começar a aceitar trabalho.

Para fazer isso, precisamos de um token do GitLab runner para que o runner possa se autenticar com o servidor GitLab. O tipo de token que precisamos depende de como queremos usar esse runner.

Um **runner específico do projeto** é útil se você tiver requisitos específicos para o runner. Por exemplo, se seu arquivo `gitlab-ci.yml` define tarefas de deployment que requeiram credenciais, um runner específico pode ser necessário para autenticar corretamente dentro do ambiente de deployment. Se o seu projeto tiver etapas com recursos intensivos no processo do CI, isso também pode ser uma boa ideia. Um runner específico do projeto não irá aceitar jobs de outros projetos.

Por outro lado, um **runner compartilhado** é um runner de propósito geral que pode ser utilizado por vários projetos. Os runners receberão jobs dos projetos de acordo com um algoritmo que contabiliza o número de jobs que estão sendo executados atualmente para cada projeto. Esse tipo de runner é mais flexível. Você precisará fazer login no GitLab com uma conta de administrador para configurar os runners compartilhados.

Vamos demonstrar como obter os tokens de runner para esses dois tipos de runner abaixo. Escolha o método que melhor lhe convier.

### Coletando Informações para Registrar um Runner Específico de Projeto

Se você quiser que o runner seja vinculado a um projeto específico, comece navegando até a página do projeto na interface do GitLab.

A partir daqui, clique no item **Settings** no menu à esquerda. Depois, clique no item **CI/CD** no submenu:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/project_settings_item2.png)

Nesta página, você verá uma seção **Runners settings**. Clique no botão **Expand** para ver mais detalhes. Na visão de detalhes, o lado esquerdo explicará como registrar um runner específico do projeto. Copie o token de registro exibido na etapa 4 das instruções:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/specific_runner_config_settings2.png)

Se você quiser desativar quaisquer runners compartilhados ativos para este projeto, você pode fazê-lo clicando no botão **Disable shared Runners** no lado direito. Isso é opcional.

Quando estiver pronto, avance para aprender como registrar seu runner usando as informações coletadas nesta página.

### Coletando Informações para Registrar um Runner Compartilhado

Para encontrar as informações necessárias para registrar um runner compartilhado, você precisa estar logado com uma conta administrativa.

Comece clicando no **ícone de chave inglesa** na barra de navegação superior para acessar a área administrativa. Na seção **Overview** do menu à esquerda, clique em **Runners** para acessar a página de configuração do runner compartilhado.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/admin_area_icon2.png)

Copie o token de registro exibido na parte superior da página:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/shared_runner_token2.png)

Usaremos esse token para registrar um runner do GitLab CI para o projeto.

### Registrando um Runner do GitLab CI com o Servidor GitLab

Agora que você tem um token, volte para o servidor em que seu serviço do runner do GitLab CI está instalado.

Para registrar um novo runner, digite o seguinte comando:

    sudo gitlab-runner register

Você será solicitado a responder uma série de questões para configurar o runner:

**Please enter the gitlab-ci coordinator URL (e.g. [https://gitlab.com/](https://gitlab.com/))**

Insira o nome de domínio do seu servidor GitLab, usando `https://` para especificar SSL. Você pode, opcionalmente, anexar `/ci` ao final do seu domínio, mas as versões recentes serão redirecionadas automaticamente.

**Please enter the gitlab-ci token for this runner**

Insira o token que você copiou na última seção.

**Please enter the gitlab-ci description for this runner**

Insira um nome para esse runner particular. Isso será exibido na lista de runners do serviço, na linha de comando e na interface do GitLab.

**Please enter the gitlab-ci tags for this runner (comma separated)**

Estas são tags que você pode atribuir ao runner. Os jobs do GitLab podem expressar requisitos em termos dessas tags para garantir que eles sejam executados em um host com as dependências corretas.

Você pode deixar isso em branco neste caso.

**Whether to lock Runner to current project [true/false]**

Atribua o runner ao projeto específico. Ele não poderá ser utilizado por outro projeto.

Selecione “false” aqui.

**Please enter the executor**

Insira o método usado pelo runner para completar jobs.

Escolha “docker” aqui.

**Please enter the default Docker image (e.g. ruby:2.1)**

Insira a imagem padrão utilizada para executar jobs quando o arquivo `.gitlab-ci.yml` não incluir uma especificação de imagem. É melhor especificar uma imagem geral aqui e definir imagens mais específicas em seu arquivo `.gitlab-ci.yml` como fizemos.

Vamos inserir “alpine:latest” aqui como um padrão pequeno e seguro.

Depois de responder às questões, um novo runner será criado, capaz de executar os jobs de CI/CD do seu projeto.

Você pode ver os runners que o serviço de runner do GitLab CI tem atualmente disponíveis digitando:

    sudo gitlab-runner list

    OutputListing configured runners ConfigFile=/etc/gitlab-runner/config.toml
    example-runner Executor=docker Token=e746250e282d197baa83c67eda2c0b URL=https://example.com

Agora que temos um runner disponível, podemos retornar ao projeto no GitLab.

## Visualizando a Execução de CI/CD no GitLab

De volta ao seu navegador, retorne ao seu projeto no GitLab. Dependendo de quanto tempo passou desde o registro do seu runner, ele pode estar em execução no momento:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/ci_running_icon_2.png)

Ou ele já pode ter sido concluído:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/ci_run_passed_icon_2.png)

Independentemente do estado, clique no ícone **running** ou **passed** (ou **failed** se você se deparou com um problema) para ver o estado atual da execução da CI. Você pode ter uma visualização semelhante clicando no menu superior **Pipelines**.

Você será direcionado para a página de visão geral do pipeline, na qual poderá ver o status da execução do GitLab CI:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/pipeline_run_overview.png)

No cabeçalho **Stages** , haverá um círculo indicando o status de cada um dos estágios da execução. Se você clicar no estágio, poderá ver os jobs individuais associados ao estágio:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/pipeline_run_stage_view.png)

Clique no job **install\_dependencies** dentro do estágio **build**. Isso o levará para a página de visão geral do job:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_ci_usage/pipeline_job_overview.png)

Agora, em vez de exibir uma mensagem de nenhum runner estar disponível, a saída do job é exibida. Em nosso caso, isso significa que você pode ver os resultados do `npm` instalando cada um dos pacotes.

Ao longo do lado direito, você pode ver alguns outros itens também. Você pode ver outros jobs alterando o estágio e clicando nas execuções abaixo. Você também pode visualizar ou baixar quaisquer artefatos produzidos pela execução.

## Conclusão

Neste guia, adicionamos um projeto demonstrativo à instância do Gitlab para mostrar os recursos de integração contínua e de deployment do GitLab CI. Discutimos como definir um pipeline nos arquivos `gitlab-ci.yml` para construir e testar suas aplicações e como atribuir jobs aos estágios para definir a relação um com o outro. Em seguida, configuramos um runner do GitLab CI para pegar tarefas de CI para nosso projeto e demonstramos como encontrar informações sobre execuções individuais da CI do GitLab.

_Por Justin Ellingwood_
