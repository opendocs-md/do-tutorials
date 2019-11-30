---
author: O.S Tezer
date: 2014-12-22
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-e-utilizar-o-docker-primeiros-passos-pt
---

# Como Instalar e Utilizar o Docker: Primeiros passos

### Introdução

Os casos de uso apresentados são ilimitados e a necessidade sempre esteve lá. O [Docker](https://www.docker.io/) está aqui para oferecer a você uma eficiente e rápida maneira de portar aplicações entre sistemas e máquinas. Ele é leve e enxuto, permitindo a você rapidamente conter aplicações e as executar dentro de seus próprios ambientes seguros (via Contêineres Linux: LXC).

Neste artigo da DigitalOcean, pretendemos apresentá-lo minuciosamente ao Docker: um dos mais interessantes e poderosos projetos open-source a ganhar vida nos últimos anos. Docker pode ajudá-lo em tantas coisas que é injusto tentar resumir as suas capacidades em uma frase.

### Glossário

### 1. Docker

### 2. O Projeto Docker e suas partes principais

### 3. Elementos do Docker

1. Contêineres do Docker
2. Imagens do Docker
3. Dockerfiles

### 4. Como instalar o Docker

### 5. Como utilizar o Docker

1. Iniciando
2. Trabalhando com Imagens
3. Trabalhando com Contêineres

# Docker

Quer seja da sua máquina de desenvolvimento para um servidor de produção remoto, ou empacotando qualquer coisa para uso em outro lugar, é sempre um desafio quando se trata de portar sua pilha de aplicação juntamente com suas dependências e fazê-las funcionar sem tropeços. Na verdade, o desafio é imenso e as soluções até agora realmente não tem sido bem sucedidas para as massas.

Em poucas palavras, docker como um projeto oferece a você um conjunto completo de ferramentas de alto nível para transportar tudo que constitui uma aplicação entre sistemas e máquinas - virtual ou física - e trás consigo grandes benefícios agregados.

Docker alcança sua robustez de conter a aplicação (e, portanto, de processos e recursos) via **Contêineres Linux** (por exemplo, namespaces e outras características do kernel). Seus novos recursos vêm de componentes e partes próprias do projeto, que extraem toda a complexidade de trabalhar com ferramentas/APIs Linux de baixo nível usadas para o sistema e para gerenciamento de aplicação, no que diz respeito a conter os processos com segurança.

# O projeto Docker e suas partes principais

O projeto Docker (que teve o código aberto pela dotCloud em Março de 2013), consiste de várias partes principais (aplicações) e elementos (utilizados por essas partes), as quais são todas (a maior parte) construídas em cima de funcionalidades já existentes, bibliotecas e frameworks oferecidos pelo kernel do Linux e por terceiros ( por exemplo LXC, device-mapper, aufs, etc.).

### Partes principais do Docker

1. docker daemon: usado para geneciar os contêineres docker (LXC) no host onde ele roda
2. docker CLI: usado para comandar e se comuinicar com o docker daemon
3. docker image index: um repositório (público ou privado) para as imagens do docker

### Elementos principais do Docker

1. Contêineres docker: diretórios contendo tudo que constitui sua aplicação
2. docker images: imagens instantâneas dos contêineres ou do S.O. básico (Ubuntu por exemplo)
3. Dockerfiles: scripts que automatizam o processo de construção de imagens

# Elementos do Docker

Os seguintes elementos são usados pelas aplicações que formam o projeto docker.

### Contêineres Docker

Todo o processo de portar aplicações usando docker depende, exclusivamente, do envio de contêineres.

Os contêineres docker são basicamente, diretórios que podem ser empacotados (agrupados com tar por exemplo) como qualquer outro, e então, compartilhados e executados entre várias máquinas e plataformas (hosts). A única dependência é ter os hosts ajustados para executar os contêineres (ou seja, ter o docker instalado). A contenção aqui é obtida através de Contêineres Linux (LXC).

### LXC (Contêineres Linux)

Contêineres Linux podem ser definidos como uma combinação de várias funcionalidades de kernel (ou seja, coisas que o kernel pode fazer), que permitem o gerenciamento de aplicações (e recursos que elas utilizam) contidas dentro de seus próprios ambientes. Fazendo o uso de algumas funcionalidades (por exemplo namespaces, chroots, cgroups e perfis SELinux), o LXC contém os processos das aplicações e auxilia com seu gerenciamento, através da limitação de recursos, não permitindo que alcance além do seu próprio sistema de arquivos (acesso ao espaço de nomes - namespace - do pai), etc.

**Docker** , com seus contêineres, faz uso do LXC, contudo, também traz consigo muito mais.

### Contêineres Docker

Os contêineres docker possuem várias características principais.

Eles permitem;

- Portabilidade de aplicação
- Isolamento de processos
- Prevenção de violação externa
- Gerenciamento de consumo de recursos

e mais, requerendo muito menos recursos do que máquinas virtuais tradicionais usadas para a implantação de aplicações isoladas.

Eles **não** permitem;

- Mexer com outros processos
- Causar “inferno de dependências”
- Ou não trabalhar com um sistema diferente
- Ser vulnerável a ataques e abusar de todos os recursos do sistema

e (também) mais.

Sendo baseado e dependendo do LXC, a partir de um aspecto técnico, estes contêineres são como um diretório (moldado e formatado). Isso permite portabilidade e construção gradual de contêineres.

Cada contêiner possui camadas como uma cebola e cada ação tomada dentro de um contêiner consiste em colocar outro bloco (que na verdade se traduz em uma simples mudança no sistema de arquivos) em cima do bloco anterior. E várias ferramentas e configurações fazem este trabalho de forma completamente harmoniosa (por exemplo o union file-system).

O que esta forma de ter contêineres permite é o imenso benefício de facilmente lançar e criar novos contêineres e imagens, que se mantém leves (graças a forma gradual e em camadas como elas são construídas). Como tudo é baseado em sistema de arquivos, tirar instantâneos (snapshots) e realizar reversões no tempo são processos baratos ( ou seja, realizado facilmente / não pesado em recursos), muito parecido com sistemas de controle de versão (VCS).

Cada **contêiner docker** inicia de uma **imagem docker** que forma a base para outras aplicações e camadas que virão.

### Imagens Docker

As imagens docker constituem a base para os contêineres docker de onde tudo começa a se formar. Elas são muito similares às imagens de disco padrão de sistema operacional que são utilizadas para executar aplicações em servidores e computadores de mesa.

Tendo essas imagens (por exemplo uma base Ubuntu) permite-se a portabilidade perfeita entre sistemas.  
Eles constituem uma base sólida, consistente e confiável com tudo o que é necessário para executar as aplicações. Quando tudo é auto suficiente e o risco de atualizações ou modificações em nível de sistema é eliminado, o contêiner torna-se imune a riscos externos que poderiam colocá-lo fora de ordem - evitando o “inferno de dependências”.

Quanto mais camadas (ferramentas, aplicações, etc) são adicionadas em cima da base, novas imagens podem ser formadas aplicando-se estas alterações. Quando um novo contêiner é criado a partir de uma imagem salva (ou seja, com as alterações aplicadas), as coisas continuam de onde pararam. E o [sistema de arquivos union](http://en.wikipedia.org/wiki/UnionFS), traz todas as camadas juntas como uma entidade única quando você trabalha com um contêiner.

Essas imagens de base podem ser explicitamente declaradas quando se trabalha com o **docker CLI** para criar diretamente um novo contêiner ou, elas podem ser especificadas dentro de um **Dockerfile** para construção de imagem automatizada.

### Dockerfiles

**Dockerfiles** são scripts contendo uma série sucessiva de instruções, orientações e comandos que devem ser executados para formar uma nova imagem docker. Cada comando executado traduz-se para uma nova camada da cebola, formando o produto final. Elas basicamente substituem o processo de se fazer tudo manualmente e repetidamente. Quando um **Dockerfile** conclui a execução, você acaba tendo formado uma imagem, que então, você utiliza para iniciar ( ou seja, criar) um novo contêiner.

# Como instalar o Docker

No início, o docker estava disponível apenas no Ubuntu. Atualmente, com sua versão mais recente (0.7.1. de 5 de Dezembro), é possível implantar o docker em sistemas baseados no RHEL (por exemplo, CentOS) bem como outros.

_Lembre-se de que você pode iniciar rapidamente utilizando a imagem da Digital Ocean, pronta para usar, construída sobre um Ubuntu 13.04._

Vamos passar rapidamente às instruções de instalação para Ubuntu

### Instruções de instalação para Ubuntu

A maneira mais simples de obter o docker, além de usar a imagem da aplicação pré construída, é ir com um VPS (Virtual Private Server) Ubuntu de 64 Bits, versão 13.04.

The simplest way to get docker, other than using the pre-built application image, is to go with a 64-bit Ubuntu 13.04 VPS

Atualize seu droplet:

    sudo aptitude update
    sudo aptitude -y upgrade

Certifique-se de que o suporte ao aufs está disponível:

    sudo aptitude install linux-image-extra-`uname -r`

Adicione a chave do repositório do docker ao apt-key para verificação de pacotes:

    sudo sh -c "wget -qO- https://get.docker.io/gpg | apt-key add -"

Adicione o repositório do docker ao sources do aptitude:

    sudo sh -c "echo deb http://get.docker.io/ubuntu docker main\
    > /etc/apt/sources.list.d/docker.list"

Atualize o repositório com o novo acréscimo:

    sudo aptitude update

Finalmente, baixe e instale o docker:

    sudo aptitude install lxc-docker

O firewall padrão do Ubuntu (UFW: Uncomplicated Firewall) bloqueia todo o encaminhamento de pacotes por padrão, o qual é necessário para o docker.

Habilite o encaminhamento com UFW:

Edite a configuração do UFW utilizando o editor de texto nano.

    sudo nano /etc/default/ufw

Desça no arquivo e procure a linha iniciando com DEFAULTFORWARDPOLICY.

Substitua:

    DEFAULT_FORWARD_POLICY="DROP"

Por:

    DEFAULT_FORWARD_POLICY="ACCEPT"

Pressione CTRL+X e confirme com Y para salvar e sair.

Finalmente, recarregue o UFW:

    sudo ufw reload

_Para um conjunto completo de instruções, verifique a documentação de instalação do docker [aqui](http://docs.docker.io/en/latest/installation/ubuntulinux/#ubuntu-raring-13-04-64-bit)._

# Como usar o Docker

Uma vez que tiver o docker instalado, sua experiência de uso intuitiva o torna muito fácil de trabalhar. Neste momento, você deve ter o daemon do docker executando em segundo plano. Se não, utilize o seguinte comando para executar o daemon do docker.

Para executar o daemon do docker:

    sudo docker -d &

Sintaxe de uso:

Usar o docker (via CLI) consiste em passar a ele uma cadeia de opções e comandos seguidos por argumentos. Por favor, observe que o docker necessita de privilégios sudo para funcionar.

    sudo docker [option] [command] [arguments]

**Nota:** As instruções e explicações abaixo são fornecidas para serem utilizadas com um guia e para dar a você uma ideia geral de usar e trabalhar com o docker. O melhor caminho para tornar-se familiar com ele é praticando em um novo VPS. Não tenha medo de quebrar algo - de fato, faça coisas que quebrem! Com o docker, você pode salvar seu progresso e continuar a partir de lá muito facilmente.

### Iniciando

Vamos começar vendo todos os comandos disponíveis que o docker tem.

Pergunte ao docker por uma lista de todos os comandos disponíveis:

    sudo docker

_Todos os comandos disponíveis atualmente (na versão 0.7.1):_

    attach Attach to a running container
    build Build a container from a Dockerfile
    commit Create a new image from a container's changes
    cp Copy files/folders from the containers filesystem to the host path
    diff Inspect changes on a container's filesystem
    events Get real time events from the server
    export Stream the contents of a container as a tar archive
    history Show the history of an image
    images List images
    import Create a new filesystem image from the contents of a tarball
    info Display system-wide information
    insert Insert a file in an image
    inspect Return low-level information on a container
    kill Kill a running container
    load Load an image from a tar archive
    login Register or Login to the docker registry server
    logs Fetch the logs of a container
    port Lookup the public-facing port which is NAT-ed to PRIVATE_PORT
    ps List containers
    pull Pull an image or a repository from the docker registry server
    push Push an image or a repository to the docker registry server
    restart Restart a running container
    rm Remove one or more containers
    rmi Remove one or more images
    run Run a command in a new container
    save Save an image to a tar archive
    search Search for an image in the docker index
    start Start a stopped container
    stop Stop a running container
    tag Tag an image into a repository
    top Lookup the running processes of a container
    version Show the docker version information
    wait Block until a container stops, then print its exit code

Verifique informações de sistema e versão do docker:

    # Para informações gerais de sistema no docker:
    sudo docker info
    
    # Para versão do docker:
    sudo docker version

### Trabalhando com imagens

Como discutimos extensamente, a chave para começar a trabalhar com qualquer contêiner docker é utilizando imagens. Existem muitas imagens disponíveis gratuitamente através do **docker image index** e o **CLI** permite acesso simplificado para consultar o repositório de imagens e para baixar novas.

_Quando estiver pronto, você pode também compartilhar sua imagem lá da mesma forma. Veja a seção sobre “push” mais abaixo para mais detalhes._

Procurando uma imagem docker:

    # Uso: sudo docker search [nome da imagem]
    sudo docker search ubuntu

Isto irá lhe fornecer uma lista muito longa de todas a imagens disponíveis que correspondem à consulta **Ubuntu**.

### Baixando (PULLing) uma imagem:

Esteja você construindo / criando um contêiner ou antes de fazê-lo, você precisará ter uma imagem presente na máquina host onde os contêineres existirão. De forma a baixar as imagens (talvez após o “search”) você pode executar **pull** para obter uma.

    # Uso: sudo docker pull [nome da imagem]
    sudo docker pull ubuntu

### Listando imagens:

Todas as imagens em seu sistema, incluindo aquelas que você criou através de commit ou salvamento (veja abaixo para detalhes), podem ser listadas utilizando “images”. Isto lhe fornece uma lista completa de todas as imagens disponíveis.

    # Examplo: sudo docker images
    sudo docker images
    
    REPOSITORY TAG IMAGE ID CREATED VIRTUAL SIZE
    my_img latest 72461793563e 36 seconds ago 128 MB
    ubuntu 12.04 8dbd9e392a96 8 months ago 128 MB
    ubuntu latest 8dbd9e392a96 8 months ago 128 MB
    ubuntu precise 8dbd9e392a96 8 months ago 128 MB
    ubuntu 12.10 b750fe79269d 8 months ago 175.3 MB
    ubuntu quantal b750fe79269d 8 months ago 175.3 MB

### Salvando alterações em uma imagem

À medida que você trabalha com o contêiner e continua a realizar ações nele (por exemplo, baixar e instalar software, configurar arquivos, etc), para ter seu estado mantido, você precisa fazer “commit” ou salvar as alterações.  
O salvamento garante que tudo continua de onde estava na próxima vez que você usar a imagem.

    # Uso: sudo docker commit [ID do contêiner] [nome da imagem]
    sudo docker commit 8dbd9e392a96 my_img

### Compartilhando (PUSHing) imagens:

Embora isso seja uma pouco cedo neste momento - em nosso artigo, quando você tiver criado seu próprio contêiner, o qual você vai querer compartilhar com o resto do mundo, você pode usar **push** para ter **a sua** imagem listada no índice, onde todos poderão baixar e utilizar.

_Por favor, lembre-se de fazer o “commit” ou salvar todas as suas alterações_

    # Uso: sudo docker push [usuário/nome da imagem]  
    sudo docker push my_username/my_first_image

**Nota** : Você precisa registrar-se em [index.docker.io](https://index.docker.io/) para fazer o upload ou push de imagens no índice do docker.

## Trabalhando com Contêineres

Quando você executa (run) qualquer processo utilizando uma imagem, em retorno, você terá um contêiner. Quando o processo **não** está executando ativamente, este contêiner será um contêiner **non-running**.  
No entanto, todos eles residem em seu sistema até que você remova-os através do comando **rm**.

### Listando todos os contêineres atuais:

Por padrão, você poderá usar o seguinte comando para listar todos os contêineres em execução ( **running** ):

    sudo docker ps

Para obter uma lista de ambos, os que estão executando ( **running** ) e os que estão como **non-running** , utilize:

    sudo docker ps -l 

## Criando um novo Contêiner

Não é possível criar um contêiner sem executar nada (ou seja, comandos). Para criar uma novo contêiner, você precisa usar uma imagem base e especificar um comando para executar:

    # Uso: sudo docker run [nome da imagem] [comando a executar]
    sudo docker run my_img echo "hello"
    
    # Para nomear um contêiner em vez de ter longos IDs
    # Uso: sudo docker run -name [nome] [nome da imagem] [comando]
    sudo docker run -name my_cont_1 my_img echo "hello"

_Isto irá imprimir “hello” e você vai estar de volta onde você estava. (ou seja, no shell do seu host)_

_Como você não pode alterar o comando que você executou depois de ter criado um contêiner (daí, especificando um durante a “criação”), é uma pratica comum utilizar gerenciadores de processos e mesmo scripts de inicialização customizados para ser capaz de executar diferentes comandos._

### Executando um contêiner:

Quando você criou um contêiner e ele parou (seja devido à finalização de seu processo ou por você pará-lo explicitamente), você pode usar “run” para ter o contêiner trabalhando novamente com o mesmo comando utilizado para criá-lo.

    # Uso: sudo docker run [ID do contêiner]
    sudo docker run c629b7d70666

_Lembra-se de como localizar um contêiner? Veja a seção acima para listá-los._

### Parando um contêiner:

Para parar um processo de contêiner em execução:

    # Uso: sudo docker stop [ID do contêiner]
    sudo docker stop c629b7d70666

### Salvando (committing) um contêiner:

Se você quiser salvar o progresso e as alterações que você fez com o contêiner, você pode usar “commit” como explicado acima, para salvá-lo como uma “imagem”.

_Este comando transforma seu contêiner em uma \*_imagem\*_._

Lembre-se de que com o docker, salvamentos são fáceis e econômicos. Não hesite em criar imagens para salvar seu progresso com um contêiner ou para restaurá-lo quando você precisar (por exemplo, como instantâneos - snapshots - no tempo).

### Removendo / Deletando um contêiner

Utilizando o ID de um contêiner, você pode deletá-lo com o **rm**.

    # Uso: sudo docker rm [ID do contêiner]
    sudo docker rm c629b7d70666

Você pode aprender mais sobre o Docker lendo sua [documentação oficial](http://docs.docker.io/en/latest/)

_\*\*Lembre-se__: As coisas estão progredindo muito rapidamente com o Docker. O impulso alimentado pela comunidade é incrível e várias grandes empresas estão tentando juntar-se para oferecer suporte. Contudo, o produto não está rotulado como pronto para produção ou \*_production ready **_, \*portanto, não recomendado para ser 100% confiável em implantações de missão crítica - \*_ainda** _. \*Certifique-se de verificar as versões à medida que elas são disponibilizadas e continue mantendo-se por dentro de tudo que acontece no docker._
