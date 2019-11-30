---
author: Brian Boucheron
date: 2018-09-18
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-construir-imagens-docker-e-hospedar-um-repositorio-de-imagens-docker-com-o-gitlab-pt
---

# Como Construir Imagens Docker e Hospedar um Repositório de Imagens Docker com o GitLab

# Como Construir Imagens Docker e Hospedar um Repositório de Imagens Docker com o GitLab

## Introdução

A containerização está rapidamente se tornando o método de empacotamento e deploy de aplicações mais aceito nos ambientes de nuvem. A padronização que ele fornece, juntamente com sua eficiência de recursos (quando comparado a máquinas virtuais completas) e flexibilidade, o tornam um grande facilitador da moderna mentalidade _DevOps_. Muitas estratégias interessantes de deployment, orquestração e monitoramento _nativas para nuvem_ tornam-se possíveis quando suas aplicações e microsserviços são totalmente containerizados.

Os containers [Docker](https://www.docker.com/) são de longe os tipos mais comuns de container atualmente. Embora os repositórios públicos de imagem do Docker como o [Docker Hub](https://hub.docker.com/) estejam repletos de imagens de software opensource containerizado que você pode fazer um `docker pull` hoje, para código privado você precisará pagar um serviço para construir e armazenar suas imagens, ou executar seu próprio software para fazer isso.

O [GitLab](https://about.gitlab.com/) Community Edition é um pacote de software auto-hospedado que fornece hospedagem de repositório Git, acompanhamento de projetos, serviços de CI/CD, e um registro de imagem Docker, entre outros recursos. Neste tutorial vamos utilizar o serviço de integração contínua do GitLab para construir imagens Docker a partir de uma aplicação de exemplo em Node.js. Estas imagens serão então testadas e carregadas para o nosso próprio registro privado do Docker.

## Pré-requisitos

Antes de começarmos, precisamos configurar **um servidor GitLab seguro** , e **um GitLab CI runner** para executar tarefas de integração contínua. As seções abaixo fornecerão links e maiores detalhes.

### Um Servidor Gitlab Protegido com SSL

Para armazenar nosso código fonte, executar tarefas de CI/CD, e hospedar um registro Docker, precisamos de uma instância do GitLab instalada em um servidor Ubuntu 16.04. Atualmente, o GitLab recomenda **um servidor com pelo menos 2 núcleos de CPU e 4GB de RAM**. Adicionalmente, iremos proteger o servidor com certificados SSL do Let’s Encrypt. Para fazer isto, precisaremos de um nome de domínio apontando para o servidor.

Você pode completar esses pré-requisitos com os seguintes tutoriais:

- [Como configurar um nome de host com a DigitalOcean](how-to-set-up-a-host-name-with-digitalocean) mostrará como gerenciar um domínio com o painel de controle da DigitalOcean.

- [Configuração Inicial de servidor com Ubuntu 16.04](configuracao-inicial-de-servidor-com-ubuntu-16-04-pt) vai lhe fornecer um usuário não-root, habilitado para sudo, e habilitar o firewall `ufw` do Ubuntu.

- [Como instalar e configurar o GitLab no Ubuntu 16.04](como-instalar-e-configurar-o-gitlab-no-ubuntu-16-04-pt) irá lhe mostrar como instalar o GitLab e configurá-lo com um certificado TLS/SSL gratuito do Let’s Encrypt

### Um GitLab CI Runner

O tutorial [Como configurar pipelines de integração contínua com o GitLab CI no Ubuntu 16.04](como-configurar-pipelines-de-integracao-continua-com-o-gitlab-ci-no-ubuntu-16-04-pt) fornecerá uma visão geral do serviço de CI ou integração contínua do GitLab e mostrará como configurar um CI runner para processar jobs. Vamos construir isso em cima da aplicação de demonstração e da infraestrutura do runner criados neste tutorial.

## Passo 1 — Configurando um GitLab CI Runner Privilegiado

No pré-requisito do tutorial de integração contínua com o GitLab, configuramos um GitLab runner utilizando `sudo gitlab-runner register` e seu processo de configuração interativo. Este runner é capaz de executar builds e testes de software dentro de containers Docker isolados.

Entretanto, para se construir imagens Docker, nosso runner precisa de acesso total ao próprio serviço do Docker. A maneira recomendada de se configurar isto é utilizar a imagem `docker-in-docker` oficial do Docker para executar os jobs. Isto requer conceder ao runner um modo de execução `privileged` ou privilegiado. Portanto, criaremos um segundo runner com este modo ativado.

**Nota:** Conceder ao runner o modo **privileged** basicamente desativa todas as vantagens de segurança da utilização de containers. Infelizmente, os outros métodos de ativar runners compatíveis com o Docker também carregam implicações de segurança semelhantes. Por favor, veja [a documentação oficial do GitLab no Docker Build](https://docs.gitlab.com/ce/ci/docker/using_docker_build.html) para aprender mais sobre as diferentes opções de runners e qual é a melhor para a sua situação.

Como existem implicações de segurança para a utilização de runner privilegiado, vamos criar um runner específico do projeto que aceitará somente jobs de Docker em nosso projeto `hello_hapi` (Os administradores de GitLab sempre podem adicionar manualmente esse runner a outros projetos posteriormente). A partir da página do nosso projeto `hello_hapi`, clique em **Settings** na parte inferior do menu à esquerda, em seguida clique em **CI/CD** no sub-menu:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/settings-ci.png)

Agora, clique no botão **Expand** ao lado da seção de configurações de **Runners** :

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/runner-expand.png)

Haverá algumas informações sobre como configurar um **Specific Runner** , incluindo um token de registro. Tome nota desse token. Quando o utilizamos para registrar um novo runner, o runner será bloqueado apenas para este projeto.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/runner-token.png)

Estando nesta página, clique no botão **Disable shared Runners**. Queremos ter certeza de que nossos jobs de Docker sempre executarão em nosso runner privilegiado. Se um runner compartilhado não privilegiado estivesse disponível, o GitLab pode optar por utilizá-lo, o que resultaria em erros de build.

Faça o login no servidor que possui o seu CI runner atual. Se você não tiver uma máquina já configurada com os runners, volte e complete a seção [Instalando o Serviço CI Runner do GitLab](como-configurar-pipelines-de-integracao-continua-com-o-gitlab-ci-no-ubuntu-16-04-pt) do tutorial de pré-requisitos antes de continuar.

Agora, execute o seguinte comando para configurar o runner privilegiado específico do projeto:

    sudo gitlab-runner register -n \
      --url https://gitlab.example.com/ \
      --registration-token seu-token \
      --executor docker \
      --description "docker-builder" \
      --docker-image "docker:latest" \
      --docker-privileged

    OutputRegistering runner... succeeded runner=61SR6BwV
    Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!

Certifique-se de substituir suas próprias informações. Nós definimos todas as opções do nosso runner na linha de comando em vez de usar os prompts interativos, porque os prompts não nos permitem especificar o modo `--docker-privileged`.

Agora o seu runner está configurado, registrado e executando. Para verificar, volte ao seu navegador. Clique no ícone de chave inglesa na barra de menu principal do GitLab, em seguida clique em **Runners** no menu à esquerda. Seus runners serão listados:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/runner-list.png)

Agora que temos um runner capaz de criar imagens do Docker, vamos configurar um registro privado do Docker para carregar imagens para ele.

## Passo 2 — Configurando o Registro Docker do GitLab

Configurar seu próprio registro do Docker permite que você envie e extraia imagens de seu próprio servidor privado, aumentando a segurança e reduzindo as dependências do seu fluxo de trabalho em serviços externos.

O GitLab irá configurar um registro Docker privado com apenas algumas atualizações de configuração. Primeiro vamos configurar a URL onde o registro irá residir. Depois, iremos (opcionalmente) configurar o registro para usar um serviço de armazenamento de objetos compatível com S3 para armazenar seus dados.

Faça SSH em seu servidor GitLab, depois abra o arquivo de configuração do GitLab:

    sudo nano /etc/gitlab/gitlab.rb

Role para baixo até a seção **Container Registry settings**. Vamos descomentar a linha `registry_external_url` e configurá-la para o nosso host GitLab com a porta número `5555`:

/etc/gitlab/gitlab.rb

    
    registry_external_url 'https://gitlab.example.com:5555'

A seguir, adicione as duas linhas seguintes para dizer ao registro onde encontrar nossos certificados Let’s Encrypt:

/etc/gitlab/gitlab.rb

    
    registry_nginx['ssl_certificate'] = "/etc/letsencrypt/live/gitlab.example.com/fullchain.pem"
    registry_nginx['ssl_certificate_key'] = "/etc/letsencrypt/live/gitlab.example.com/privkey.pem"

Salve e feche o arquivo, depois reconfigure o GitLab:

    sudo gitlab-ctl reconfigure

    Output. . .
    gitlab Reconfigured!

Atualize o firewall para pemitir tráfego para a porta do registro:

    sudo ufw allow 5555

Agora mude para outra máquina com o Docker instalado e efetue o login no registro Docker privado. Se você não tiver o Docker no seu computador de desenvolvimento local, você pode usar qualquer servidor configurado para executar seus jobs do GitLab CI, já que ele tem o Docker instalado:

    docker login gitlab.example.com:5555

Você será solicitado para inserir o seu nome de usuário e senha. Use suas credenciais do GitLab para efetuar login.

    OutputLogin Succeeded

Sucesso! O registro está configurado e funcionando. Atualmente, ele armazenará arquivos no sistema de arquivos local do servidor GitLab. Se você quiser usar um serviço de armazenamento de objetos, continue com esta seção. Se não, pule para o Passo 3.

Para configurar um backend de armazenamento de objetos para o registro, precisamos saber as seguintes informações sobre o nosso serviço de armazenamento de objetos:

- **Access Key**

- **Secret Key**

- **Region** (`us-east-1`) por exemplo, se estiver usando Amazon S3, ou **Region Endpoint** se estiver usando um serviço compatível com S3 (`https://nyc.digitaloceanspaces.com`)

- **Nome do Bucket**

Se você estiver usando o DigitalOcean Spaces, você pode descobrir como configurar um novo Space e obter as informações acima lendo [Como Criar um Space e uma Chave de API na DigitalOcean](como-criar-um-space-e-uma-api-key-na-digitalocean-pt).

Quando você tiver suas informações sobre o amazenamento de objetos, abra o arquivo de configuração do GitLab:

    sudo nano /etc/gitlab/gitlab.rb

Novamente, role até a seção de registro do container. Procure pelo bloco `registry['storage']`, descomente o bloco e atualize-o para o seguinte, novamente certificando-se de substituir suas próprias informações, quando apropriado:

/etc/gitlab/gitlab.rb

    
    registry['storage'] = {
      's3' => {
        'accesskey' => 'sua-key',
        'secretkey' => 'seu-secret',
        'bucket' => 'seu-bucket-name',
        'region' => 'nyc3',
        'regionendpoint' => 'https://nyc3.digitaloceanspaces.com'
      }
    }

Se você estiver uando Amazon S3, você precisa apenas da `region` e não do `regionendpoint`. Se estiver usando um serviço S3 compatível, como o Spaces, você irá precisar do `regionendpoint`. Neste caso, `region` na verdade não configura nada e o valor que você digita não importa, mas ainda precisa estar presente e não em branco.

Salve e feche o arquivo.

**Nota:** Atualmente, há um bug em que o registro será encerrado após trinta segundos se seu bucket de armazenamento de objetos estiver vazio. Para evitar isso, coloque um arquivo no seu bucket antes de executar a próxima etapa. Você poderá removê-lo mais tarde, após o registro ter adicionado seus próprios objetos.

Se você estiver usando o Spaces da DigitalOcean, você pode arrastar e soltar um arquivo para carregá-lo usando a interface do Painel de Controle.

Reconfigure o GitLab mais uma vez:

    sudo gitlab-ctl reconfigure

Em sua outra máquina Docker, efetue login no registro novamente para ter certeza de que tudo está bem:

    docker login gitlab.example.com:5555

Você deve receber uma mensagem de `Login Succeeded`.

Agora que temos nosso registro do Docker configurado, vamos atualizar a configuração de CI da nossa aplicação para criar e testar nossa app, e enviar as imagens Docker para o nosso registro privado.

## Passo 3 — Atualizando o `gitlab-ci.yaml` e Construindo uma Imagem Docker

**Nota:** Se você não concluiu o [artigo de pré-requisito do GitLab CI](como-configurar-pipelines-de-integracao-continua-com-o-gitlab-ci-no-ubuntu-16-04-pt) você precisará copiar o repositório de exemplo para o seu servidor GitLab. Siga a seção [Copiando o Repositório de Exemplo a partir do GitHub](como-configurar-pipelines-de-integracao-continua-com-o-gitlab-ci-no-ubuntu-16-04-pt) para fazer isto.

Para que possamos fazer o building de nossa app no Docker, precisamos atualizar o arquivo `.gitlab-ci.yml`. Você pode editar este arquivo diretamente no GitLab clicando na página principal do projeto, e depois no botão **Edit**. Alternativamente, você poderia clonar o repositório para a sua máquina local, editar o arquivo, e então fazer um `git push` nele de volta para o GitLab. Isso ficaria assim:

    git clone git@gitlab.example.com:sammy/hello_hapi.git
    cd hello_hapi
    # edit the file w/ your favorite editor
    git commit -am "updating ci configuration"
    git push

Primeiro, exclua tudo no arquivo, depois cole nele a seguinte configuração:

.gitlab-ci.yml

    
    image: docker:latest
    services:
    - docker:dind
    
    stages:
    - build
    - test
    - release
    
    variables:
      TEST_IMAGE: gitlab.example.com:5555/sammy/hello_hapi:$CI_COMMIT_REF_NAME
      RELEASE_IMAGE: gitlab.example.com:5555/sammy/hello_hapi:latest
    
    before_script:
      - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN gitlab.example.com:5555
    
    build:
      stage: build
      script:
        - docker build --pull -t $TEST_IMAGE .
        - docker push $TEST_IMAGE
    
    test:
      stage: test
      script:
        - docker pull $TEST_IMAGE
        - docker run $TEST_IMAGE npm test
    
    release:
      stage: release
      script:
        - docker pull $TEST_IMAGE
        - docker tag $TEST_IMAGE $RELEASE_IMAGE
        - docker push $RELEASE_IMAGE
      only:
        - master

Certifique-se de atualizar os URLs e nomes de usuários realçados com suas próprias informações e, em seguida, salve com o botão **Commit changes** no GitLab. Se você está atualizando o arquivo fora do GitLab, confirme as mudanças e faça `git push` de volta no GitLab.

Este novo arquivo de configuração diz ao GitLab para usar a imagem mais recente do docker (`image: docker:latest`) e vinculá-la ao serviço docker-in-docker (docker:dind). Então, ele define os estágios de `build`, `test`, e `release`. O estágio de `build` cria a imagem do Docker usando o `Dockerfile` fornecido pelo repositório, em seguida o carrega para o nosso registro de imagens Docker. Se isso for bem sucedido, o estágio `test` vai baixar a imagem que acabamos de construir e executar o comando `npm test` dentro dele. Se o estágio `test` for bem sucedido, o estágio `release` irá lançar a imagem, irá colocar uma tag como `hello_hapi:latest` e irá retorná-la ao registro.

Dependendo do seu fluxo de trabalho, você também pode adicionar mais estágios `test`, ou mesmo estágios `deploy` que levam o aplicativo para um ambiente de preparação ou produção.

A atualização do arquivo de configuração deve ter acionado um novo build. Volte ao projeto `hello_hapi` no GitLab e clique no indicador de status do CI para o commit:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/commit-widget.png)

Na página resultante, você pode clicar em qualquer um dos estágios para ver seu progresso:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/commit-pipeline.png)

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/stage-detail.png)

Eventualmente, todas as etapas devem indicar que eles foram bem sucedidos, mostrando ícones com a marca de verificação em verde. Podemos encontrar as imagens Docker que acabaram de ser construídas clicando no item **Registry** no menu à esquerda:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab-docker/docker-list.png)

Se você clicar no pequeno ícone “document” ao lado do nome da imagem, ele copiará o comando apropriado `docker pull ...` para a sua área de transferência. Você pode então baixar e executar sua imagem:

    docker pull gitlab.example.com:5555/sammy/hello_hapi:latest
    docker run -it --rm -p 3000:3000 gitlab.example.com:5555/sammy/hello_hapi:latest

    Output> hello@1.0.0 start /usr/src/app
    > node app.js
    
    Server running at: http://56fd5df5ddd3:3000

A imagem foi baixada do registro e iniciada em um container. Mude para o seu navegador e conecte-se ao aplicativo na porta 3000 para testar. Neste caso, estamos executando o container em nossa máquina local, assim podemos acessá-la via **localhost** na seguinte URL:

    http://localhost:3000/hello/test

    OutputHello, test!

Sucesso! Você pode parar o container com `CTRL-C`. A partir de agora, toda vez que enviarmos um novo código para a ramificação master do nosso repositório, vamos construir e testar automaticamente uma nova imagem `hello_hapi: latest`.

## Conclusão

Neste tutorial, configuramos um novo GitLab runner para criar imagens do Docker, criamos um regisro privado do Docker para armazená-las, e atualizamos um app Node.js para ser construído e testado dentro de containers Docker.

Para aprender mais sobre os vários componentes utilizados nesta configuração, você pode ler a documentação oficial do [GitLab CE](https://docs.gitlab.com/ce/README.html), [GitLab Container Registry](https://docs.gitlab.com/ee/administration/container_registry.html), e do [Docker](https://docs.docker.com/).

_Por Brian Boucheron_
