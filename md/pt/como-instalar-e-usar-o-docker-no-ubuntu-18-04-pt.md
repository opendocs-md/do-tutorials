---
author: Brian Hogan
date: 2018-11-16
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-e-usar-o-docker-no-ubuntu-18-04-pt
---

# Como Instalar e Usar o Docker no Ubuntu 18.04

_Uma versão anterior deste tutorial foi escrita por [finid](https://www.digitalocean.com/community/users/finid)._

### Introdução

O [Docker](https://www.docker.com/) é uma aplicação que simplifica a maneira de gerenciar processos de aplicativos em containers. Os containers lhe permitem executar suas aplicações em processos com isolamento de recursos. Eles são semelhantes às máquinas virtuais, mas os containers são mais portáteis, possuem recursos mais amigáveis, e são mais dependentes do sistema operacional do host.

Para uma introdução detalhada aos diferentes componentes de um container Docker, dê uma olhada em [O Ecossistema do Docker: Uma Introdução aos Componentes Comuns](o-ecossistema-do-docker-uma-introducao-aos-componentes-comuns-pt).

Neste tutorial, você irá instalar e utilizar o Docker Community Edition (CE) no Ubuntu 18.04. Você instalará o próprio Docker, trabalhará com containers e imagens, e irá enviar uma imagem para um repositório do Docker.

## Pré-requisitos

Para seguir este tutorial, você precisará do seguinte:

- Um servidor Ubuntu 18.04 configurado seguindo o [guia Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt), incluindo um usuário sudo não-root e um firewall.

- Uma conta no [Docker Hub](https://hub.docker.com/) se você deseja criar suas próprias imagens e enviá-las ao Docker Hub, como mostrado nos passos 7 e 8.

## Passo 1 — Instalando o Docker

O pacote de instalação do Docker disponível no repositório oficial do Ubuntu pode não ser a versão mais recente. Para garantir que teremos a última versão, vamos instalar o Docker a partir do repositório oficial do projeto. Para fazer isto, vamos adicionar uma nova fonte de pacotes, adicionar a chave GPG do Docker para garantir que os downloads são válidos, e então instalar os pacotes.

Primeiro, atualize sua lista atual de pacotes:

    sudo apt update

Em seguida, instale alguns pacotes de pré-requisitos que permitem que o `apt` utilize pacotes via HTTPS:

    sudo apt install apt-transport-https ca-certificates curl software-properties-common

Então adicione a chave GPG para o repositório oficial do Docker em seu sistema:

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

Adicione o repositório do Docker às fontes do APT:

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

A seguir, atualize o banco de dados de pacotes com os pacotes Docker do repositório recém adicionado:

    sudo apt update

Certifique-se de que você irá instalar a partir do repositório do Docker em vez do repositório padrão do Ubuntu:

    apt-cache policy docker-ce

Você verá uma saída como esta, embora o número da versão do Docker possa estar diferente:

Output of apt-cache policy docker-ce

    
    docker-ce:
      Installed: (none)
      Candidate: 18.03.1~ce~3-0~ubuntu
      Version table:
         18.03.1~ce~3-0~ubuntu 500
            500 https://download.docker.com/linux/ubuntu bionic/stable amd64 Packages

Observe que o `docker-ce` não está instalado, mas o candidato para instalação é do repositório do Docker para o Ubuntu 18.04 (`bionic`).

Finalmente, instale o Docker:

    sudo apt install docker-ce

O Docker agora deve ser instalado, o daemon iniciado e o processo ativado para iniciar na inicialização. Verifique se ele está sendo executado:

    sudo systemctl status docker

A saída deve ser semelhante à seguinte, mostrando que o serviço está ativo e executando:

    Output● docker.service - Docker Application Container Engine
       Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
       Active: active (running) since Thu 2018-07-05 15:08:39 UTC; 2min 55s ago
         Docs: https://docs.docker.com
     Main PID: 10096 (dockerd)
        Tasks: 16
       CGroup: /system.slice/docker.service
               ├─10096 /usr/bin/dockerd -H fd://
               └─10113 docker-containerd --config /var/run/docker/containerd/containerd.toml

A instalação do Docker agora oferece não apenas o serviço Docker (daemon), mas também o utilitário de linha de comando `docker` ou o cliente Docker. Vamos explorar como usar o comando `docker` mais adiante neste tutorial.

## Passo 2 — Executando o Comando Docker sem Sudo (Opcional)

Por padrão o comando `docker` só pode ser executado pelo usuário **root** ou por um usuário do grupo **docker** , que é automaticamente criado durante o processo de instalação do Docker. Se você tentar executar o comando `docker` sem prefixá-lo com `sudo` ou sem estar no grupo **docker** , você obterá uma saída como esta:

    Outputdocker: Cannot connect to the Docker daemon. Is the docker daemon running on this host?.
    See 'docker run --help'.

Se você quiser evitar digitar `sudo` sempre que você executar o comando `docker`, adicione seu nome de usuário ao grupo `docker`:

    sudo usermod -aG docker ${USER}

Para aplicar a nova associação ao grupo, efetue logout do servidor e faça logon novamente ou digite o seguinte:

    su - ${USER}

Você será solicitado a entrar com seu usuário e senha para continuar.

Confirme que seu usuário está agora adicionado ao grupo **docker** digitando:

    id -nG

    Outputsammy sudo docker

Se você precisar adicionar um usuário ao grupo `docker` com o qual você não está logado, declare o nome do usuário explicitamente usando:

    sudo usermod -aG docker nome-do-usuário

O restante desse artigo assume que você está executando o comando `docker` como um usuário do grupo **docker**. Se você optar por não fazê-lo, por favor, prefixe os comandos com `sudo`.

A seguir, vamos explorar o comando `docker`.

## Passo 3 — Usando o Comando Docker

A utilização do comando `docker` consiste em passar a ele uma cadeia de opções e comandos seguidos de argumentos. A sintaxe assume este formato:

    docker [option] [command] [arguments]

Para ver todos os subcomandos disponíveis, digite:

    docker

A partir do Docker 18, a lista completa de subcomandos disponíveis inclui:

    Output
      attach Attach local standard input, output, and error streams to a running container
      build Build an image from a Dockerfile
      commit Create a new image from a container's changes
      cp Copy files/folders between a container and the local filesystem
      create Create a new container
      diff Inspect changes to files or directories on a container's filesystem
      events Get real time events from the server
      exec Run a command in a running container
      export Export a container's filesystem as a tar archive
      history Show the history of an image
      images List images
      import Import the contents from a tarball to create a filesystem image
      info Display system-wide information
      inspect Return low-level information on Docker objects
      kill Kill one or more running containers
      load Load an image from a tar archive or STDIN
      login Log in to a Docker registry
      logout Log out from a Docker registry
      logs Fetch the logs of a container
      pause Pause all processes within one or more containers
      port List port mappings or a specific mapping for the container
      ps List containers
      pull Pull an image or a repository from a registry
      push Push an image or a repository to a registry
      rename Rename a container
      restart Restart one or more containers
      rm Remove one or more containers
      rmi Remove one or more images
      run Run a command in a new container
      save Save one or more images to a tar archive (streamed to STDOUT by default)
      search Search the Docker Hub for images
      start Start one or more stopped containers
      stats Display a live stream of container(s) resource usage statistics
      stop Stop one or more running containers
      tag Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE
      top Display the running processes of a container
      unpause Unpause all processes within one or more containers
      update Update configuration of one or more containers
      version Show the Docker version information
      wait Block until one or more containers stop, then print their exit codes

Para ver as opções disponíveis para um comando específico, digite:

    docker subcomando-docker --help

Para ver informações de sistema sobre o Docker, use:

    docker info

Vamos explorar alguns desses comandos. Vamos começar trabalhando com imagens.

## Passo 4 — Trabalhando com Imagens Docker

Os containers Docker são construídos a partir de imagens Docker. Por padrão, o Docker extrai essas imagens do [Docker Hub](https://hub.docker.com), um registro Docker mantido pela Docker, a empresa por trás do projeto Docker. Qualquer pessoa pode hospedar suas imagens do Docker no Docker Hub, portanto, a maioria dos aplicativos e distribuições do Linux que você precisa terá imagens hospedadas lá.

Para verificar se você pode acessar e baixar imagens do Docker Hub, digite:

    docker run hello-world

A saída irá indicar que o Docker está funcionando corretamente:

    OutputUnable to find image 'hello-world:latest' locally
    latest: Pulling from library/hello-world
    9bb5a5d4561a: Pull complete
    Digest: sha256:3e1764d0f546ceac4565547df2ac4907fe46f007ea229fd7ef2718514bcec35d
    Status: Downloaded newer image for hello-world:latest
    
    Hello from Docker!
    This message shows that your installation appears to be working correctly.
    ...

Inicialmente, o Docker foi incapaz de encontrar a imagem `hello-world` localmente, então baixou a imagem do Docker Hub, que é o repositório padrão. Depois que a imagem foi baixada, o Docker criou um container a partir da imagem e o aplicativo dentro do container foi executado, exibindo a mensagem.

Você pode procurar imagens disponíveis no Docker Hub usando o comando `docker` com o subcomando`search`. Por exemplo, para procurar a imagem do Ubuntu, digite:

    docker search ubuntu

O script rastreará o Docker Hub e retornará uma listagem de todas as imagens cujo nome corresponde à string de pesquisa. Nesse caso, a saída será similar a essa:

    OutputNAME DESCRIPTION STARS OFFICIAL AUTOMATED
    ubuntu Ubuntu is a Debian-based Linux operating sys… 7917 [OK]
    dorowu/ubuntu-desktop-lxde-vnc Ubuntu with openssh-server and NoVNC 193 [OK]
    rastasheep/ubuntu-sshd Dockerized SSH service, built on top of offi… 156 [OK]
    ansible/ubuntu14.04-ansible Ubuntu 14.04 LTS with ansible 93 [OK]
    ubuntu-upstart Upstart is an event-based replacement for th… 87 [OK]
    neurodebian NeuroDebian provides neuroscience research s… 50 [OK]
    ubuntu-debootstrap debootstrap --variant=minbase --components=m… 38 [OK]
    1and1internet/ubuntu-16-nginx-php-phpmyadmin-mysql-5 ubuntu-16-nginx-php-phpmyadmin-mysql-5 36 [OK]
    nuagebec/ubuntu Simple always updated Ubuntu docker images w… 23 [OK]
    tutum/ubuntu Simple Ubuntu docker images with SSH access 18
    i386/ubuntu Ubuntu is a Debian-based Linux operating sys… 13
    ppc64le/ubuntu Ubuntu is a Debian-based Linux operating sys… 12
    1and1internet/ubuntu-16-apache-php-7.0 ubuntu-16-apache-php-7.0 10 [OK]
    1and1internet/ubuntu-16-nginx-php-phpmyadmin-mariadb-10 ubuntu-16-nginx-php-phpmyadmin-mariadb-10 6 [OK]
    eclipse/ubuntu_jdk8 Ubuntu, JDK8, Maven 3, git, curl, nmap, mc, … 6 [OK]
    codenvy/ubuntu_jdk8 Ubuntu, JDK8, Maven 3, git, curl, nmap, mc, … 4 [OK]
    darksheer/ubuntu Base Ubuntu Image -- Updated hourly 4 [OK]
    1and1internet/ubuntu-16-apache ubuntu-16-apache 3 [OK]
    1and1internet/ubuntu-16-nginx-php-5.6-wordpress-4 ubuntu-16-nginx-php-5.6-wordpress-4 3 [OK]
    1and1internet/ubuntu-16-sshd ubuntu-16-sshd 1 [OK]
    pivotaldata/ubuntu A quick freshening-up of the base Ubuntu doc… 1
    1and1internet/ubuntu-16-healthcheck ubuntu-16-healthcheck 0 [OK]
    pivotaldata/ubuntu-gpdb-dev Ubuntu images for GPDB development 0
    smartentry/ubuntu ubuntu with smartentry 0 [OK]
    ossobv/ubuntu
    ...

Na coluna **OFFICIAL** , o **OK** indica uma imagem construída e suportada pela empresa por trás do projeto. Depois de identificar a imagem que você gostaria de usar, você pode baixá-la para o seu computador usando o subcomando `pull`.

Execute o seguinte comando para baixar a imagem oficial do `ubuntu` para seu computador:

    docker pull ubuntu

Você verá a seguinte saída:

    OutputUsing default tag: latest
    latest: Pulling from library/ubuntu
    6b98dfc16071: Pull complete
    4001a1209541: Pull complete
    6319fc68c576: Pull complete
    b24603670dc3: Pull complete
    97f170c87c6f: Pull complete
    Digest: sha256:5f4bdc3467537cbbe563e80db2c3ec95d548a9145d64453b06939c4592d67b6d
    Status: Downloaded newer image for ubuntu:latest

Após o download de uma imagem, você pode executar um container usando a imagem baixada com o subcomando `run`. Como você viu com o exemplo do `hello-world`, se uma imagem não tiver sido baixada quando o `docker` for executado com o subcomando`run`, o cliente Docker irá primeiro baixar a imagem, depois executar um container usando esta imagem.

Para ver as imagens que foram baixadas para seu computador, digite:

    docker images

A saída deve ser semelhante à seguinte:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    ubuntu latest 113a43faa138 4 weeks ago 81.2MB
    hello-world latest e38bc07ac18e 2 months ago 1.85kB

Como você verá posteriormente nesse tutorial, as imagens que você usa para executar containers podem ser modificadas e utilizadas para gerar novas imagens, que podem ser enviadas (fazer um push, em termos técnicos) para o Docker Hub ou outros registros Docker.

Vamos dar uma olhada em como executar containers em mais detalhes.

## Passo 5 — Executando um Container Docker

O container `hello-world` que você executou no passo anterior é um exemplo de um container que executa e sai depois da emissão de uma mensagem de teste. Os containers podem ser muito mais úteis do que isso e podem ser interativos. Afinal, eles são semelhantes às máquinas virtuais, apenas mais fáceis de usar.

Como um exemplo, vamos executar um container usando a versão mais recente do ubuntu. A combinação das chaves **-i** e **-t** dá a você um acesso a um shell interativo dentro do container:

    docker run -it ubuntu

Seu prompt de comando deve mudar para refletir o fato de que você agora está trabalhando dentro do container e deve assumir essa forma:

    Outputroot@d9b100f2f636:/#

Observe o id do container no prompt de comando. Nesse exemplo, ele é `d9b100f2f636`. Você precisará do ID do container posteriormente para identificar o container quando quiser removê-lo.

Agora você pode executar qualquer comando dento do container. Por exemplo, vamos atualizar o banco de dados de pacotes dentro do container. Você não precisa prefixar quaisquer comandos com `sudo` porque você está operando dentro do container como usuário **root** :

    apt update

A seguir, instale qualquer aplicação dentro dele. Vamos instalar o Node.js:

    apt install nodejs

Isso instala o Node.js no container a partir do repositório oficial do Ubuntu. Quando a instalação terminar, verifique que o Node.js está instalado:

    node -v

Você verá o número da versão exibido em seu terminal:

    Outputv8.10.0

Quaisquer alterações feitas no container só se aplicam a esse container.

Para sair do container, digite `exit` no prompt.

A seguir, vamos analisar o gerenciamento dos containers em nosso sistema.

## Passo 6 — Gerenciando Containers Docker

Depois de usar o Docker por um tempo, você terá muitos containers ativos (em execução) e inativos em seu computador. Para ver os containers **ativos** , utilize:

    docker ps

Você verá uma saída similar à seguinte:

    OutputCONTAINER ID IMAGE COMMAND CREATED  

Neste tutorial, você iniciou dois containers; um a partir da imagem `hello-world` e outro a partir da imagem `ubuntu`. Ambos os containers não estão mais executando, mas eles ainda existem em seu sistema.

Para ver todos os containers — ativos e inativos, execute `docker ps` com a chave `-a`:

    docker ps -a

Você verá uma saída semelhante a esta:

    d9b100f2f636 ubuntu "/bin/bash" About an hour ago Exited (0) 8 minutes ago sharp_volhard
    01c950718166 hello-world "/hello" About an hour ago Exited (0) About an hour ago festive_williams

Para ver o último container que você criou, passe a ele a chave `-l`:

    docker ps -l

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    d9b100f2f636 ubuntu "/bin/bash" About an hour ago Exited (0) 10 minutes ago sharp_volhard

Para iniciar um container parado, use `docker start`, seguido pelo ID do container ou o nome dele. Vamos iniciar o container baseado no Ubuntu com o ID `d9b100f2f636`:

    docker start d9b100f2f636

O container vai iniciar, e você pode usar `docker ps` para ver seu status:

    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    d9b100f2f636 ubuntu "/bin/bash" About an hour ago Up 8 seconds sharp_volhard

Para parar um container em execução, use `docker stop`, seguido do nome ou ID do container. Dessa vez, vamos usar o nome que o registro Docker atribuiu ao container, que é `sharp_volhard`:

    docker stop sharp_volhard

Depois que você decidir que não precisa mais de um container, remova-o com o comando `docker rm`, novamente usando ou o ID do container ou seu nome. Use o comando `docker ps -a` para encontrar o ID ou o nome do container associado à imagem `hello-world` e remova-o.

    docker rm festive_williams

Você pode inciar um novo container e dar a ele um nome utilizando a chave `--name`. Você também pode utilizar a chave `--rm` para criar um container que se auto remove quando é parado. Veja o comando `docker run help` para mais informações sobre essas e outras opções.

Os containers podem ser transformados em imagens que você pode usar para criar novos containers. Vamos ver como isso funciona.

## Passo 7 — Fazendo Commit de Alterações em um Container para uma Imagem Docker

Quando você inicia uma imagem Docker, você pode criar, modificar e excluir arquivos da mesma forma que você faz em máquinas virtuais. As alterações que você fizer serão aplicadas apenas a esse container. Você pode iniciá-lo ou pará-lo, mas uma vez que você o destrua com o comando `docker rm`, as mudanças serão perdidas para sempre.

Esta seção mostra como salvar o estado de um container como uma nova imagem do Docker.

Depois de instalar o Node.js dentro do container Ubuntu, você tem agora um container executando a partir de uma imagem, mas o container é diferente da imagem que você usou para criá-lo. Mas você pode querer reutilizar esse container Node.js como base para novas imagens posteriormente.

Então, faça o commit das alterações em uma nova instância de imagem do Docker usando o seguinte comando.

    docker commit -m "O que você fez na imagem" -a "Nome do Autor" container_id repositório/novo_nome_da_imagem

A chave **-m** é para a mensagem de commit que ajuda você e outras pessoas saberem quais mudanças você fez, enquanto **-a** é usado para especificar o autor. O `container_id` é aquele que você observou anteriormente no tutorial quando iniciou a sessão interativa do Docker. A menos que você tenha criado repositórios adicionais no Docker Hub, o `repositório` geralmente é seu nome de usuário do Docker Hub.

Por exemplo, para o usuário **sammy** , com ID do container `d9b100f2f636`, o comando seria:

    docker commit -m "added Node.js" -a "sammy" d9b100f2f636 sammy/ubuntu-nodejs

Quando você faz o _commit_ de uma imagem, a nova imagem é salva localmente em seu computador. Posteriormente, nesse tutorial, você aprenderá a enviar uma imagem para um registro do Docker, como o Docker Hub, para que outras pessoas possam acessá-la.

Ao listar as imagens do Docker novamente será mostrado a nova imagem, bem como a antiga da qual foi derivada:

    docker images

Você verá uma saída como essa:

    Output
    REPOSITORY TAG IMAGE ID CREATED SIZE
    sammy/ubuntu-nodejs latest 7c1f35226ca6 7 seconds ago 179MB
    ubuntu latest 113a43faa138 4 weeks ago 81.2MB
    hello-world latest e38bc07ac18e 2 months ago 1.85kB

Neste exemplo, `ubuntu-nodejs` é a nova imagem, a qual foi derivada da imagem existente `ubuntu` do Docker Hub. A diferença de tamanho reflete as alterações feitas. E neste exemplo, a mudança foi que o NodeJS foi instalado. Então, da próxima vez que você precisar executar um container usando o Ubuntu com o NodeJS pré-instalado, você pode simplesmente usar a nova imagem.

Você também pode criar imagens a partir de um `Dockerfile`, que permite automatizar a instalação de software em uma nova imagem. No entanto, isso está fora do escopo deste tutorial.

Agora vamos compartilhar a nova imagem com outras pessoas para que elas possam criar containers a partir dela.

## Passo 8 — Enviando Imagens Docker para um Repositório Docker

A próxima etapa lógica após criar uma nova imagem a partir de uma imagem existente é compartilhá-la com alguns poucos amigos selecionados, o mundo inteiro no Docker Hub ou outro registro do Docker ao qual você tem acesso. Para enviar uma imagem para o Docker Hub ou qualquer outro registro Docker, você deve ter uma conta lá.

Esta seção mostra como enviar uma imagem do Docker para o Docker Hub. Para aprender como criar seu próprio registro privado do Docker, confira [How To Set Up a Private Docker Registry on Ubuntu 14.04](how-to-set-up-a-private-docker-registry-on-ubuntu-14-04).

Para enviar sua imagem, primeiro efetue o login no Docker Hub.

    docker login -u nome-de-usuário-do-registro-docker

Você será solicitado a autenticar usando sua senha do Docker Hub. Se você especificou a senha correta, a autenticação deve ser bem-sucedida.

**Note:** Se seu nome de usuário do registro do Docker for diferente do nome de usuário local usado para criar a imagem, você terá que marcar sua imagem com o nome de usuário do registro. Para o exemplo dado na última etapa, você digitaria:

    docker tag sammy/ubuntu-nodejs nome-de-usuário-do-registro-docker/ubuntu-nodejs

Então você pode enviar sua própria imagem usando:

    docker push nome-de-usuário-do-registro-docker/nome-da-imagem-docker

Para enviar a imagem `ubuntu-nodejs` para o repositório **sammy** , o comando seria:

    docker push sammy/ubuntu-nodejs

O processo pode levar algum tempo para ser concluído enquanto ele carrega as imagens, mas quando concluído, a saída será algo assim:

    OutputThe push refers to a repository [docker.io/sammy/ubuntu-nodejs]
    e3fbbfb44187: Pushed
    5f70bf18a086: Pushed
    a3b5c80a4eba: Pushed
    7f18b442972b: Pushed
    3ce512daaf78: Pushed
    7aae4540b42d: Pushed
    
    ...

Após o envio de uma imagem para um registro, ela deve ser listada no dashboard de sua conta, como aquele mostrado na imagem abaixo:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_1804/ec2vX3Z.png)

Se uma tentativa de envio resultar em um erro desse tipo, provavelmente você não efetuou login:

    OutputThe push refers to a repository [docker.io/sammy/ubuntu-nodejs]
    e3fbbfb44187: Preparing
    5f70bf18a086: Preparing
    a3b5c80a4eba: Preparing
    7f18b442972b: Preparing
    3ce512daaf78: Preparing
    7aae4540b42d: Waiting
    unauthorized: authentication required

Faça login com `docker login` e repita a tentativa de envio. Em seguida, verifique que ela existe na sua página de repositório do Docker Hub.

Agora voce pode usar `docker pull sammy/ubuntu-nodejs` para para puxar a imagem para uma nova máquina e usá-la para executar um novo container.

## Conclusão

Neste tutorial, você instalou o Docker, trabalhou com imagens e containers e enviou uma imagem modificada para o Docker Hub. Agora que você conhece o básico, explore os [outros tutoriais do Docker](https://www.digitalocean.com/community/tags/docker?type=tutorials) na comunidade da DigitalOcean.

_Por Brian Hogan_
