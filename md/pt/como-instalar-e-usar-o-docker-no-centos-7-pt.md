---
author: finid
date: 2019-08-22
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-e-usar-o-docker-no-centos-7-pt
---

# Como Instalar e Usar o Docker no CentOS 7

### Introdução

O Docker é um aplicativo que torna simples e fácil executar processos de aplicações em um container, que são como máquinas virtuais, apenas mais portáveis, mais fáceis de usar e mais dependentes do sistema operacional do host. Para uma introdução detalhada aos diferentes componentes de um container Docker, confira [O Ecossistema do Docker: Uma Introdução aos Componentes Comuns](o-ecossistema-do-docker-uma-introducao-aos-componentes-comuns-pt).

Existem dois métodos para instalar o Docker no CentOS 7. Um método envolve instalá-lo em uma instalação existente do sistema operacional. O outro envolve lançar um servidor com uma ferramenta chamada [Docker Machine](how-to-provision-and-manage-remote-docker-hosts-with-docker-machine-on-centos-7) que instala automaticamente o Docker nele.

Neste tutorial, você aprenderá a instalar e usar o Docker em uma instalação existente do CentOS 7.

## Pré-requisitos

- Um Droplet CentOS de 64-bits
- Um usuário não-root com privilégios sudo. Um servidor CentOS 7 configurado usando o guia de [Configuração Inicial do Servidor com o CentOS 7](configuracao-inicial-do-servidor-com-o-centos-7-pt).

**Nota:** O Docker requer uma versão de 64 bits do CentOS 7, bem como uma versão do kernel igual ou maior que 3.10. O Droplet padrão do CentOS 7 de 64 bits atende a esses requisitos.

Todos os comandos neste tutorial devem ser executados como um usuário não-root. Se o acesso como root for requerido para o comando, ele será precedido pelo `sudo`. O guia de [Configuração Inicial do Servidor com o CentOS 7](configuracao-inicial-do-servidor-com-o-centos-7-pt) explica como adicionar usuários e fornecer a eles o acesso ao sudo.

## Passo 1 — Instalando o Docker

O pacote de instalação do Docker disponível no repositório oficial do CentOS 7 pode não ser a versão mais recente. Para obter a versão mais recente e melhor, instale o Docker a partir do repositório oficial do Docker. Esta seção mostra como fazer exatamente isso.

Mas primeiro, vamos atualizar o banco de dados de pacotes:

    sudo yum check-update

Agora execute este comando. Ele adicionará o repositório oficial do Docker, baixará a versão mais recente do Docker e a instalará:

    curl -fsSL https://get.docker.com/ | sh

Após a conclusão da instalação, inicie o daemon do Docker:

    sudo systemctl start docker

Verifique se ele está em execução:

    sudo systemctl status docker

A saída deve ser semelhante à seguinte, mostrando que o serviço está ativo e em execução:

    Output● docker.service - Docker Application Container Engine
       Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
       Active: active (running) since Sun 2016-05-01 06:53:52 CDT; 1 weeks 3 days ago
         Docs: https://docs.docker.com
     Main PID: 749 (docker)

Por fim, certifique-se que ele vai iniciar em todas as reinicializações do servidor:

    sudo systemctl enable docker

A instalação do Docker agora oferece não apenas o serviço Docker (daemon), mas também o utilitário de linha de comando `docker` ou o cliente Docker. Vamos explorar como usar o comando `docker` mais adiante neste tutorial.

## Passo 2 — Executando Comandos Docker Sem Sudo (Opcional)

Por padrão, executar o comando `docker` requer privilégios de root — isto é, você tem que prefixar o comando com `sudo`. Ele também pode ser executado por um usuário no grupo **docker** , que é criado automaticamente durante a instalação do Docker. Se você tentar executar o comando `docker` sem prefixá-lo com `sudo` ou sem estar no grupo docker, você obterá uma saída como esta:

    Outputdocker: Cannot connect to the Docker daemon. Is the docker daemon running on this host?.
    See 'docker run --help'.

Se você quiser evitar digitar `sudo` sempre que executar o comando `docker`, adicione seu nome de usuário ao grupo docker:

    sudo usermod -aG docker $(whoami)

Você precisará sair do Droplet e voltar como o mesmo usuário para ativar essa mudança.

Se você precisar adicionar um usuário ao grupo `docker` no qual você não está logado, declare este username explicitamente usando:

    sudo usermod -aG docker username

O restante deste artigo supõe que você esteja executando o comando `docker` como um usuário do grupo de usuários docker. Se você optar por não fazê-lo, por favor, prefixe os comandos com `sudo`.

## Passo 3 — Usando o Comando Docker

Com o Docker instalado e funcionando, agora é a hora de se familiarizar com o utilitário de linha de comando. O uso do `docker` consiste em passar uma cadeia de opções e subcomandos seguidos por argumentos. A sintaxe assume este formato:

    docker [option] [command] [arguments]

Para ver todos os subcomandos disponíveis, digite:

    docker

A partir do Docker 1.11.1, a lista completa de subcomandos disponíveis inclui:

    Output
        attach Attach to a running container
        build Build an image from a Dockerfile
        commit Create a new image from a container's changes
        cp Copy files/folders between a container and the local filesystem
        create Create a new container
        diff Inspect changes on a container's filesystem
        events Get real time events from the server
        exec Run a command in a running container
        export Export a container's filesystem as a tar archive
        history Show the history of an image
        images List images
        import Import the contents from a tarball to create a filesystem image
        info Display system-wide information
        inspect Return low-level information on a container or image
        kill Kill a running container
        load Load an image from a tar archive or STDIN
        login Log in to a Docker registry
        logout Log out from a Docker registry
        logs Fetch the logs of a container
        network Manage Docker networks
        pause Pause all processes within a container
        port List port mappings or a specific mapping for the CONTAINER
        ps List containers
        pull Pull an image or a repository from a registry
        push Push an image or a repository to a registry
        rename Rename a container
        restart Restart a container
        rm Remove one or more containers
        rmi Remove one or more images
        run Run a command in a new container
        save Save one or more images to a tar archive
        search Search the Docker Hub for images
        start Start one or more stopped containers
        stats Display a live stream of container(s) resource usage statistics
        stop Stop a running container
        tag Tag an image into a repository
        top Display the running processes of a container
        unpause Unpause all processes within a container
        update Update configuration of one or more containers
        version Show the Docker version information
        volume Manage Docker volumes
        wait Block until a container stops, then print its exit code

Para visualizar as opções disponíveis para um comando específico, digite:

    docker subcomando-docker --help

Para visualizar informações de todo o sistema, use:

    docker info

## Passo 4 — Trabalhando com Imagens Docker

Os containers Docker são executados a partir de imagens Docker. Por padrão, ele extrai essas imagens do Docker Hub, um registro Docker gerenciado pela Docker, a empresa por trás do projeto Docker. Qualquer pessoa pode criar e hospedar suas imagens no Docker Hub, de modo que a maioria das aplicações e distribuições Linux que você precisa para executar containers Docker tem imagens que estão hospedadas no Docker Hub.

Para verificar se você pode acessar e baixar imagens do Docker Hub, digite:

    docker run hello-world

A saída, que deve incluir o seguinte, deve indicar que o Docker está funcionando corretamente:

    OutputHello from Docker.
    This message shows that your installation appears to be working correctly.
    ...

Você pode procurar imagens disponíveis no Docker Hub usando o comando `docker` com o subcomando `search`. Por exemplo, para procurar a imagem do CentOS, digite:

    docker search centos

O script rastreará o Docker Hub e retornará uma listagem de todas as imagens cujo nome corresponde à string de pesquisa. Nesse caso, a saída será semelhante a esta:

    OutputNAME DESCRIPTION STARS OFFICIAL AUTOMATED
    centos The official build of CentOS. 2224 [OK]       
    jdeathe/centos-ssh CentOS-6 6.7 x86_64 / CentOS-7 7.2.1511 x8... 22 [OK]
    jdeathe/centos-ssh-apache-php CentOS-6 6.7 x86_64 / Apache / PHP / PHP M... 17 [OK]
    million12/centos-supervisor Base CentOS-7 with supervisord launcher, h... 11 [OK]
    nimmis/java-centos This is docker images of CentOS 7 with dif... 10 [OK]
    torusware/speedus-centos Always updated official CentOS docker imag... 8 [OK]
    nickistre/centos-lamp LAMP on centos setup 3 [OK]
    
    ...

Na coluna **OFFICIAL** , o **OK** indica uma imagem criada e suportada pela empresa por trás do projeto. Depois de identificar a imagem que você gostaria de usar, você pode fazer o download dela para o seu computador usando o subcomando `pull`, assim:

    docker pull centos

Depois que uma imagem foi baixada, você pode então executar um container usando a imagem baixada com o subcomando `run`. Se uma imagem não tiver sido baixada quando o `docker` for executado com o subcomando `run`, o cliente do Docker primeiro fará o download da imagem e, em seguida, executará um container usando-a:

    docker run centos

Para ver as imagens que foram baixadas para o seu computador, digite:

    docker images

A saída deve ser semelhante ao seguinte:

    [secondary_lable Output]
    REPOSITORY TAG IMAGE ID CREATED SIZE
    centos latest 778a53015523 5 weeks ago 196.7 MB
    hello-world latest 94df4f0ce8a4 2 weeks ago 967 B

Como você verá mais adiante neste tutorial, as imagens que você usa para executar containers podem ser modificadas e usadas para gerar novas imagens, que podem então ser enviadas (_push_ é o termo técnico) para o Docker Hub ou outros registros Docker.

## Passo 5 — Executando um Container Docker

O container `hello-world` que você executou na etapa anterior é um exemplo de um container que é executado e sai após a emissão de uma mensagem de teste. Os containers, no entanto, podem ser muito mais úteis do que isso e podem ser interativos. Afinal, eles são semelhantes às máquinas virtuais, apenas mais fáceis de usar.

Como um exemplo, vamos rodar um container usando a última imagem do CentOS. A combinação das chaves **-i** e **-t** fornece a você o acesso interativo ao shell no container:

    docker run -it centos

Seu prompt de comando deve mudar para refletir o fato de que você agora está trabalhando dentro do container e deve assumir esta forma:

    Output[root@59839a1b7de2 /]#

**Importante:** Observe o ID do container no prompt de comando. No exemplo acima, ele é `59839a1b7de2`.

Agora você pode executar qualquer comando dentro do container. Por exemplo, vamos instalar o servidor MariaDB no container em execução. Não há necessidade de prefixar qualquer comando com o `sudo`, porque você está operando dentro do container com privilégios de root:

    yum install mariadb-server

## Passo 6 — Fazendo o Commit de Alterações para uma Imagem Docker

Quando você inicia uma imagem Docker, você pode criar, modificar e excluir arquivos da mesma forma que você faz com uma máquina virtual. As alterações que você fizer serão aplicadas apenas a esse container. Você pode iniciá-lo e pará-lo, mas depois de destruí-lo com o comando `docker rm`, as alterações serão perdidas para sempre.

Esta seção lhe mostra como salvar o estado de um container como uma nova imagem Docker.

Depois de instalar o servidor MariaDB dentro do container CentOS, agora você tem um container executando uma imagem, mas o container é diferente da imagem que você usou para criá-lo.

Para salvar o estado do container como uma nova imagem, primeiro saia dele:

    exit

Em seguida, confirme ou faça o commit das alterações em uma nova instância de imagem Docker usando o seguinte comando. A chave **-m** é para a mensagem de commit que ajuda você e outras pessoas a saber quais alterações você fez, enquanto **-a** é usado para especificar o autor. O ID do container é aquele que você anotou anteriormente no tutorial quando iniciou a sessão Docker interativa. A menos que você tenha criado repositórios adicionais no Docker Hub, o repositório geralmente é seu nome de usuário do Docker Hub:

    docker commit -m "O que você fez na imagem" -a "Nome do autor" container-id repositório/novo_nome_da_imagem

Por exemplo:

    docker commit -m "adicionado mariadb-server" -a "Sunday Ogwu-Chinuwa" 59839a1b7de2 finid/centos-mariadb

**Nota:** Quando você faz o _commit_ de uma imagem, a nova imagem é salva localmente, isto é, no seu computador. Posteriormente neste tutorial, você aprenderá a enviar uma imagem para um registro Docker, como o Docker Hub, para que ela possa ser avaliada e usada por você e por outras pessoas.

Depois que a operação for concluída, listar as imagens Docker agora no seu computador deve mostrar a nova imagem, bem como a antiga da qual ela foi derivada:

    docker images

A saída deve ser desse tipo:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    finid/centos-mariadb latest 23390430ec73 6 seconds ago 424.6 MB
    centos latest 778a53015523 5 weeks ago 196.7 MB
    hello-world latest 94df4f0ce8a4 2 weeks ago 967 B

No exemplo acima, **centos-mariadb** é a nova imagem, que foi derivada da imagem CentOS existente do Docker Hub. A diferença de tamanho reflete as alterações que foram feitas. E neste exemplo, a mudança foi que o servidor MariaDB foi instalado. Então, da próxima vez que você precisar executar um container usando o CentOS com o servidor MariaDB pré-instalado, basta usar a nova imagem. As imagens também podem ser construídas a partir do que é chamado de Dockerfile. Mas esse é um processo mais complicado e que está bem fora do escopo deste artigo. Vamos explorar isso em um artigo futuro.

## Passo 7 — Listando os Containers Docker

Depois de usar o Docker por um tempo, você terá muitos containers ativos (em execução) e inativos no seu computador. Para ver os ativos, use:

    docker ps

Você verá uma saída semelhante à seguinte:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    f7c79cc556dd centos "/bin/bash" 3 hours ago Up 3 hours silly_spence

Para visualizar todos os containers — ativos e inativos, passe a ele a chave `-a`:

    docker ps -a

Para ver o container mais recente que você criou, utilize a opção `-l`:

    docker ps -l

Parar um container em execução ou ativo é tão simples quanto digitar:

    docker stop container-id

O `container-id` pode ser encontrado na saída do comando `docker ps`.

## Passo 8 — Enviando Imagens para um Repositório Docker

A próximo passo lógico depois de criar uma nova imagem a partir de uma imagem existente é compartilhá-la com alguns de seus amigos selecionados, o mundo inteiro no Docker Hub ou outro registro Docker ao qual você tem acesso. Para enviar uma imagem para o Docker Hub ou qualquer outro registro Docker, você deve ter uma conta lá.

Esta seção mostra como enviar uma imagem para o Docker Hub.

Para criar uma conta no Docker Hub, registre-se em [Docker Hub](https://hub.docker.com/). Depois, para enviar sua imagem, primeiro faça o login no Docker Hub. Você será solicitado a se autenticar:

    docker login -u usuário_do_registro_docker

Se você especificou a senha correta, a autenticação deve ser bem-sucedida. Então você pode enviar sua própria imagem usando:

    docker push usuário_do_registro_docker/nome-da-imagem-docker

Isso levará algum tempo para ser concluído e, quando concluído, a saída será algo assim:

    OutputThe push refers to a repository [docker.io/finid/centos-mariadb]
    670194edfaf5: Pushed 
    5f70bf18a086: Mounted from library/centos 
    6a6c96337be1: Mounted from library/centos
    
    ...
    

Depois de enviar uma imagem para um registro, ela deve estar listada no painel da sua conta, como mostra a imagem abaixo.

![Docker image listing on Docker Hub](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_install/docker_hub_dashboard_centos.png)

Se uma tentativa de envio resultar em um erro desse tipo, provavelmente você não efetuou login:

    OutputThe push refers to a repository [docker.io/finid/centos-mariadb]
    e3fbbfb44187: Preparing
    5f70bf18a086: Preparing
    a3b5c80a4eba: Preparing
    7f18b442972b: Preparing
    3ce512daaf78: Preparing
    7aae4540b42d: Waiting
    unauthorized: authentication required

Faça o login e repita a tentativa de envio.

## Conclusão

Há muito mais no Docker do que foi mostrado neste artigo, mas isso deve ser suficiente para você começar a trabalhar com ele no CentOS 7. Como a maioria dos projetos open source, o Docker é construído a partir de uma base de código em rápido desenvolvimento, portanto, crie o hábito de visitar a [página do blog](https://blog.docker.com/) do projeto para as informações mais recentes.

Confira também os [outros tutoriais do Docker](https://www.digitalocean.com/community/tags/docker?type=tutorials) na Comunidade da DigitalOcean.
