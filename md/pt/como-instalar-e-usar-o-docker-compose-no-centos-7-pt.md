---
author: Nik van der Ploeg
date: 2019-08-22
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-e-usar-o-docker-compose-no-centos-7-pt
---

# Como Instalar e Usar o Docker Compose no CentOS 7

### Introdução

O [Docker](https://docs.docker.com/) é uma ótima ferramenta para automatizar o deployment de aplicações Linux dentro de containers de software, mas para aproveitar realmente ao máximo seu potencial, é melhor se cada componente de sua aplicação for executado em seu próprio container. Para aplicações complexas com muitos componentes, orquestrar todos os containers para iniciar e encerrar juntos (para não mencionar ter que falar uns com os outros) pode rapidamente tornar-se problemático.

A comunidade Docker apareceu com uma solução popular chamada [Fig](http://www.fig.sh/), que permitia usar um único arquivo YAML para orquestrar todos os containers e configurações do Docker. Isso se tornou tão popular que a equipe do Docker decidiu fazer o _Docker Compose_ com base nos fontes do Fig, que agora está obsoleto. O Docker Compose torna mais fácil para os usuários orquestrarem os processos de containers do Docker, incluindo inicialização, encerramento e configuração de links e volumes dentro de containers.

Neste tutorial, você instalará a versão mais recente do Docker Compose para ajudá-lo a gerenciar aplicações de vários containers e explorará os comandos básicos do software.

## Conceitos de Docker e Docker Compose

A utilização do Docker Compose requer uma combinação de vários conceitos diferentes do Docker em um, portanto, antes de começarmos, vamos analisar alguns dos vários conceitos envolvidos. Se você já estiver familiarizado com os conceitos do Docker, como volumes, links e port forwarding, você pode querer ir em frente e pular para a próxima seção.

### Imagens Docker

Cada container Docker é uma instância local de uma imagem Docker. Você pode pensar em uma imagem Docker como uma instalação completa do Linux. Geralmente, uma instalação mínima contém apenas o mínimo de pacotes necessários para executar a imagem. Essas imagens usam o kernel do sistema host, mas como elas estão rodando dentro de um container Docker e só veem seu próprio sistema de arquivos, é perfeitamente possível executar uma distribuição como o CentOS em um host Ubuntu (ou vice-versa).

A maioria das imagens Docker é distribuída através do [Docker Hub](https://hub.docker.com/), que é mantido pela equipe do Docker. Os projetos open source mais populares têm uma imagem correspondente carregada no Registro Docker, que você pode usar para fazer o deploy do software. Quando possível, é melhor pegar imagens “oficiais”, pois elas são garantidas pela equipe do Docker e seguem as práticas recomendadas do Docker.

### Comunicação Entre Imagens Docker

Os containers Docker são isolados da máquina host, o que significa que, por padrão, a máquina host não tem acesso ao sistema de arquivos dentro do container, nem a qualquer meio de comunicação com ele por meio da rede. Isso pode dificultar a configuração e o trabalho com a imagem em execução em um container Docker.

O Docker tem três maneiras principais de contornar isso. O primeiro e mais comum é fazer com que o Docker especifique variáveis de ambiente que serão definidas dentro do container. O código em execução no container Docker verificará os valores dessas variáveis de ambiente na inicialização e os utilizará para se configurar adequadamente.

Outro método comumente usado é um [Docker data volume](how-to-work-with-docker-data-volumes-on-ubuntu-14-04). Os volumes Docker vêm em dois tipos - internos e compartilhados.

Especificar um volume interno significa apenas que, para uma pasta que você especificar para um determinado container Docker, os dados persistirão quando o container for removido. Por exemplo, se você quisesse ter certeza de que seus arquivos de log persistam, você poderia especificar um volume `/var/log` interno.

Um volume compartilhado mapeia uma pasta dentro de um container Docker para uma pasta na máquina host. Isso permite que você [compartilhe arquivos](how-to-share-data-between-docker-containers) facilmente entre o container Docker e a máquina host.

A terceira maneira de se comunicar com um container Docker é pela rede. O Docker permite a comunicação entre diferentes containers por meio de `links`, bem como o port forwarding ou encaminhamento de portas, permitindo que você encaminhe portas de dentro do container Docker para portas no servidor host. Por exemplo, você pode criar um link para permitir que os containers do WordPress e do MariaDB se comuniquem entre si e usem o encaminhamento de porta para expor o WordPress ao mundo externo, para que os usuários possam se conectar a ele.

## Pré-requisitos

Para seguir este artigo, você precisará do seguinte:

- Um servidor CentOS 7, configurado com um usuário não-root com privilégios sudo (veja [Configuração Inicial do Servidor com o CentOS 7](configuracao-inicial-do-servidor-com-o-centos-7-pt) para detalhes).

- Docker instalado com as instruções do Passo 1 e Passo 2 do tutorial [Como instalar e usar o Docker no CentOS 7](how-to-install-and-use-docker-on-centos-7-pt)

Uma vez que estes requisitos estejam atentidos, você estará pronto para seguir adiante.

## Passo 1 — Instalando o Docker Compose

Para obter a versão mais recente, tome conhecimento dos [docs do Docker](https://docs.docker.com/compose/install/) e instale o Docker Compose a partir do binário no repositório GitHub do Docker.

Verifique a [release atual](https://github.com/docker/compose/releases) e se necessário, atualize-a no comando abaixo:

    sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

Em seguida, defina as permissões para tornar o binário executável:

    sudo chmod +x /usr/local/bin/docker-compose

Logo após, verifique se a instalação foi bem-sucedida, checando a versão

    docker-compose --version

Isso imprimirá a versão que você instalou:

    Outputdocker-compose version 1.23.2, build 1110ad01

Agora que você tem o Docker Compose instalado, você está pronto para executar um exemplo de “Hello World”.

## Passo 2 — Executando um Container com o Docker Compose

O registro público do Docker, o Docker Hub, inclui uma imagem simples “Hello World” para demonstração e teste. Ela ilustra a configuração mínima necessária para executar um container usando o Docker Compose: um arquivo YAML que chama uma única imagem.

Primeiro, crie um diretório para o nosso arquivo YAML:

    mkdir hello-world

Em seguida, mude para o diretório:

    cd hello-world

Agora crie o arquivo YAML usando seu editor de texto favorito. Este tutorial usará o vi:

    vi docker-compose.yml

Entre no modo de inserção, pressionando `i`, depois coloque o seguinte conteúdo no arquivo:

docker-compose.yml

    my-test:
      image: hello-world

A primeira linha fará parte do nome do container. A segunda linha especifica qual imagem usar para criar o container. Quando você executar o comando `docker-compose up`, ele procurará uma imagem local com o nome especificado, `hello-world`.

Com isso pronto, pressione `ESC` para sair do modo de inserção. Digite `:x` e depois `ENTER` para salvar e sair do arquivo.

Para procurar manualmente as imagens no seu sistema, use o comando `docker images`:

    docker images

Quando não há imagens locais, apenas os cabeçalhos das colunas são exibidos:

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE

Agora, ainda no diretório `~/hello-world`, execute o seguinte comando para criar o container:

    docker-compose up

Na primeira vez que executarmos o comando, se não houver uma imagem local chamada `hello-world`, o Docker Compose vai baixá-la do repositório público do Docker Hub:

    OutputPulling my-test (hello-world:)...
    latest: Pulling from library/hello-world
    1b930d010525: Pull complete
    . . .

Depois de baixar a imagem, o `docker-compose` cria um container, anexa e executa o programa [hello](https://github.com/docker-library/hello-world/blob/85fd7ab65e079b08019032479a3f306964a28f4d/hello-world/Dockerfile), que por sua vez confirma que a instalação parece estar funcionando:

    Output. . .
    Creating helloworld_my-test_1...
    Attaching to helloworld_my-test_1
    my-test_1 | 
    my-test_1 | Hello from Docker.
    my-test_1 | This message shows that your installation appears to be working correctly.
    my-test_1 | 
    . . .

Em seguida, imprimirá uma explicação do que ele fez:

    Output. . .
    my-test_1 | To generate this message, Docker took the following steps:
    my-test_1 | 1. The Docker client contacted the Docker daemon.
    my-test_1 | 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    my-test_1 | (amd64)
    my-test_1 | 3. The Docker daemon created a new container from that image which runs the
    my-test_1 | executable that produces the output you are currently reading.
    my-test_1 | 4. The Docker daemon streamed that output to the Docker client, which sent it
    my-test_1 | to your terminal.
    . . .

Os containers Docker só são executados enquanto o comando estiver ativo, portanto, assim que o `hello` terminar a execução, o container finaliza. Conseqüentemente, quando você olha para os processos ativos, os cabeçalhos de coluna aparecerão, mas o container `hello-world` não será listado porque não está em execução:

    docker ps

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES

Use a flag `-a` para mostrar todos os containers, não apenas os ativos:

    docker ps -a

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    50a99a0beebd hello-world "/hello" 3 minutes ago Exited (0) 3 minutes ago hello-world_my-test_1

Agora que você testou a execução de um container, é possível explorar alguns dos comandos básicos do Docker Compose.

## Passo 3 — Aprendendo os Comandos do Docker Compose

Para começar com o Docker Compose, esta seção irá examinar os comandos gerais que a ferramenta `docker-compose` suporta.

O comando `docker-compose` funciona em uma base por diretório. Você pode ter vários grupos de containers do Docker em execução em uma máquina — basta criar um diretório para cada container e um arquivo `docker-compose.yml` para cada diretório.

Até agora você tem executado o `docker-compose up` por conta própria, a partir do qual você pode usar o `CTRL-C` para fechar o container. Isso permite que as mensagens de debug sejam exibidas na janela do terminal. Isso não é o ideal; quando rodando em produção, é mais robusto ter o `docker-compose` agindo mais como um serviço. Uma maneira simples de fazer isso é adicionar a opção `-d` quando você fizer um `up` em sua sessão:

    docker-compose up -d

O `docker-compose` agora será executado em segundo plano ou background.

Para mostrar seu grupo de containers Docker (estejam interrompidos ou em execução no momento), use o seguinte comando:

    docker-compose ps -a

Se um container for interrompido, o `State` será listado como `Exited`, conforme mostrado no exemplo a seguir:

    Output Name Command State Ports
    ------------------------------------------------
    hello-world_my-test_1 /hello Exit 0        

Um container em execução mostrará `Up`:

    Output Name Command State Ports      
    ---------------------------------------------------------------
    nginx_nginx_1 nginx -g daemon off; Up 443/tcp, 80/tcp 

Para parar todos os containers Docker em execução para um grupo de aplicações, digite o seguinte comando no mesmo diretório que o arquivo `docker-compose.yml` que você usou para iniciar o grupo Docker:

    docker-compose stop

**Nota:** `docker-compose kill` também está disponível se você precisar fechar as coisas de maneira forçada.

Em alguns casos, os containers Docker armazenarão suas informações antigas em um volume interno. Se você quiser começar do zero, você pode usar o comando `rm` para excluir totalmente todos os containers que compõem o seu grupo de containers:

    docker-compose rm 

Se você tentar qualquer um desses comandos a partir de um diretório diferente do diretório que contém um container Docker e um arquivo `.yml`, ele retornará um erro:

    OutputERROR:
            Can't find a suitable configuration file in this directory or any
            parent. Are you in the right directory?
    
            Supported filenames: docker-compose.yml, docker-compose.yaml

Esta seção abordou o básico sobre como manipular containers com o Docker Compose. Se você precisasse obter maior controle sobre seus containers, você poderia acessar o sistema de arquivos do container e trabalhar a partir de um prompt de comando dentro de seu container, um processo descrito na próxima seção.

## Passo 4 — Acessando o Sistema de Arquivos do Container Docker

Para trabalhar no prompt de comando dentro de um container e acessar seu sistema de arquivos, você pode usar o comando `docker exec`.

O exemplo “Hello World” sai depois de ser executado, portanto, para testar o `docker exec`, inicie um container que continuará em execução. Para os fins deste tutorial, use a [imagem Nginx](https://hub.docker.com/_/nginx/) do Docker Hub.

Crie um novo diretório chamado `nginx` e vá até ele:

    mkdir ~/nginx
    cd ~/nginx

Em seguida, crie um arquivo `docker-compose.yml` em seu novo diretório e abra-o em um editor de texto:

    vi docker-compose.yml

Em seguida, adicione as seguintes linhas ao arquivo:

~/nginx/docker-compose.yml

    nginx:
      image: nginx

Salve o arquivo e saia. Inicie o container Nginx como um processo em background com o seguinte comando:

    docker-compose up -d

O Docker Compose fará o download da imagem Nginx e o container será iniciado em background.

Agora você precisará do `CONTAINER ID` para o container. Liste todos os containers que estão em execução com o seguinte comando:

    docker ps

Você verá algo semelhante ao seguinte:

    Output of `docker ps`CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    b86b6699714c nginx "nginx -g 'daemon of…" 20 seconds ago Up 19 seconds 80/tcp nginx_nginx_1

Se você quisesse fazer uma alteração no sistema de arquivos dentro deste container, você pegaria seu ID (neste exemplo `b86b6699714c`) e usaria `docker exec` para iniciar um shell dentro do container:

    docker exec -it b86b6699714c /bin/bash

A opção `-t` abre um terminal, e a opção `-i` o torna interativo. `/bin/bash` abre um shell bash para o container em execução.

Você verá um prompt bash para o container semelhante a:

    root@b86b6699714c:/#

A partir daqui, você pode trabalhar no prompt de comando dentro do seu container. No entanto, lembre-se de que, a menos que você esteja em um diretório salvo como parte de um volume de dados, suas alterações desaparecerão assim que o container for reiniciado. Além disso, lembre-se de que a maioria das imagens Docker é criada com instalações mínimas do Linux, portanto, alguns dos utilitários e ferramentas de linha de comando aos quais você está acostumado podem não estar presentes.

## Conclusão

Agora você instalou o Docker Compose, testou sua instalação executando um exemplo “Hello World” e explorou alguns comandos básicos.

Embora o exemplo “Hello World” tenha confirmado sua instalação, a configuração simples não mostra um dos principais benefícios do Docker Compose — a capacidade de ligar e desligar um grupo de containers Docker ao mesmo tempo. Para ver o poder do Docker Compose em ação, confira [How To Secure a Containerized Node.js Application with Nginx, Let’s Encrypt, and Docker Compose](how-to-secure-a-containerized-node-js-application-with-nginx-let-s-encrypt-and-docker-compose) e [How To Configure a Continuous Integration Testing Environment with Docker and Docker Compose on Ubuntu 16.04](how-to-configure-a-continuous-integration-testing-environment-with-docker-and-docker-compose-on-ubuntu-16-04). Embora estes tutoriais sejam voltados para o Ubuntu 16.04 e 18.04, os passos podem ser adaptados para o CentOS 7.
