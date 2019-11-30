---
author: finid, Brian Hogan
date: 2019-02-28
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-provisionar-e-gerenciar-hosts-remotos-do-docker-com-docker-machine-no-ubuntu-18-04-pt
---

# Como Provisionar e Gerenciar Hosts Remotos do Docker com Docker Machine no Ubuntu 18.04

## Introdução

[Docker Machine](https://docs.docker.com/machine/) é uma ferramenta que facilita o provisionamento e o gerenciamento de vários hosts Docker remotamente a partir do seu computador pessoal. Esses servidores são comumente chamados de hosts Dockerizados e são usados para executar containers do Docker.

Embora o Docker Machine possa ser instalado em um sistema local ou remoto, a abordagem mais comum é instalá-lo em seu computador local (instalação nativa ou máquina virtual) e usá-lo para provisionar servidores remotos Dockerizados.

Embora o Docker Machine possa ser instalado na maioria das distribuições Linux, bem como no MacOS e no Windows, neste tutorial, você o instalará em sua máquina local executando Ubuntu 18.04 e o usará para provisionar Droplets Dockerizados na DigitalOcean. Se você não tem uma máquina local Ubuntu 18.04, você pode seguir estas instruções em qualquer servidor Ubuntu 18.04.

## Pré-requisitos

Para seguir este tutorial, você vai precisar do seguinte:

- Uma máquina local ou servidor executando o Ubuntu 18.04 com o Docker instalado. Veja [Como Instalar e Usar o Docker no Ubuntu 18.04](como-instalar-e-usar-o-docker-no-ubuntu-18-04-pt) para instruções.

- Um token de API da DigitalOcean. Se você não tiver um, gere-o usando [este guia](how-to-use-the-digitalocean-api-v2). Quando você gerar um token, certifique-se de que ele tenha um escopo de leitura e gravação. Esse é o padrão, portanto, se você não alterar nenhuma opção enquanto estiver gerando, ela terá recursos de leitura e gravação. 

## Passo 1 — Instalando o Docker Machine

Para usar a Docker Machine, você deve primeiro instalá-lo localmente. No Ubuntu, isso significa baixar um punhado de scripts do repositório oficial do Docker no GitHub.

Para baixar e instalar o binário do Docker Machine, digite:

    wget https://github.com/docker/machine/releases/download/v0.15.0/docker-machine-$(uname -s)-$(uname -m)

O nome do arquivo deve ser `docker-machine-Linux-x86_64`. Renomeie-o para `docker-machine` para torná-lo mais fácil de trabalhar:

    mv docker-machine-Linux-x86_64 docker-machine

Torne-o executável:

    chmod +x docker-machine

Mova ou copie-o para o diretório `/usr/local/bin` para que ele esteja disponível como um comando do sistema:

    sudo mv docker-machine /usr/local/bin

Verifique a versão, o que indicará que ele está corretamente instalado:

    docker-machine version

Você verá uma saída semelhante a esta, exibindo o número da versão e a compilação:

    Outputdocker-machine version 0.15.0, build b48dc28d

O Docker Machine está instalado. Vamos instalar algumas ferramentas auxiliares adicionais para facilitar o trabalho com o Docker Machine.

## Passo 2 — Instalando Scripts Adicionais do Docker Machine

Existem três scripts Bash no repositório GitHub do Docker Machine que você pode instalar para facilitar o trabalho com os comandos `docker` e `docker-machine`. Quando instalados, esses scripts fornecem o recurso de auto-completar comandos e de personalização do prompt.

Nesta etapa, você irá instalar esses três scripts no diretório `/etc/bash_completion.d` em sua máquina local, baixando-os diretamente do repositório GitHub do Docker Machine.

**Nota:** Antes de baixar e instalar um script da internet em um local disponível do sistema, você deve inspecionar o conteúdo do script primeiro, visualizando a URL de origem em seu navegador.

O primeiro script permite que você veja a máquina ativa no seu prompt. Isso é útil quando você está trabalhando e alternando entre várias máquinas Dockerizadas. O script é chamado de `docker-machine-prompt.bash`. Baixe-o

    sudo wget https://raw.githubusercontent.com/docker/machine/master/contrib/completion/bash/docker-machine-prompt.bash -O /etc/bash_completion.d/docker-machine-prompt.bash

Para completar a instalação deste arquivo, você terá que modificar o valor da variável `PS1` no seu arquivo `.bashrc`. A variável `PS1` é uma variável de shell especial usada para modificar o prompt de comando do Bash. Abra o `~/.bashrc` em seu editor:

    nano ~/.bashrc

Dentro desse arquivo, existem três linhas que começam com `PS1`. Elas devem se parecer com estas:

~/.bashrc

    
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    
    ...
    
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
    
    ...
    
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"

Para cada linha, insira `$(__docker_machine_ps1 " [%s]")` perto do final, conforme mostrado no exemplo a seguir:

    ~/.bashrc
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__docker_machine_ps1 " [%s]")\$ '
    
    ...
    
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(__docker_machine_ps1 " [%s]")\$ '
    
    ...
    
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$(__docker_machine_ps1 " [%s]")$PS1"

Salve e feche o arquivo.

O segundo script é chamado de `docker-machine-wrapper.bash`. Ele adiciona um subcomando `use` ao comando `docker-machine`, facilitando significativamente a alternância entre os hosts Docker. Para baixá-lo, digite:

    sudo wget https://raw.githubusercontent.com/docker/machine/master/contrib/completion/bash/docker-machine-wrapper.bash -O /etc/bash_completion.d/docker-machine-wrapper.bash

O terceiro script é chamado de `docker-machine.bash`. Ele adiciona o auto-completar ao bash para os comandos `docker-machine`. Baixe-o usando:

    sudo wget https://raw.githubusercontent.com/docker/machine/master/contrib/completion/bash/docker-machine.bash -O /etc/bash_completion.d/docker-machine.bash

Para aplicar as alterações feitas até agora, feche e reabra seu terminal. Se você estiver logado na máquina via SSH, saia da sessão e faça o login novamente, e você terá o auto-completar de comandos para os comandos `docker` e `docker-machine`.

Vamos testar as coisas criando um novo host Docker com o Docker Machine.

## Passo 3 — Provisionando um Host Dockerizado Usando o Docker Machine

Agora que você tem o Docker e o Docker Machine em execução em sua máquina local, é possível provisionar um Droplet Dockerizado em sua conta da DigitalOcean usando o comando `docker-machine create` do Docker Machine. Se você ainda não o fez, atribua seu token da API da DigitalOcean a uma variável de ambiente:

    export DOTOKEN=seu-token-de-api

**NOTA:** Este tutorial usa DOTOKEN como a variável bash para o token da API da DigitalOcean. O nome da variável não precisa ser DOTOKEN e não precisa estar em maiúsculas.

Para tornar a variável permanente, coloque-a em seu arquivo `~/.bashrc`. Este passo é opcional, mas é necessário se você quiser que o valor persista entre sessões de shell.

Abra esse arquivo com o `nano`:

    nano ~/.bashrc

Adicione esta linha ao arquivo:

~/.bashrc

    export DOTOKEN=seu-token-de-api

Para ativar a variável na sessão de terminal atual, digite:

    source ~/.bashrc

Para chamar o comando `docker-machine create` com sucesso, você deve especificar o _driver_ que deseja usar, bem como o nome da máquina. O driver é o adaptador para a infraestrutura que você vai criar. Existem drivers para provedores de infraestrutura de nuvem, bem como drivers para várias plataformas de virtualização.

Vamos usar o driver `digitalocean`. Dependendo do driver selecionado, você precisará fornecer opções adicionais para criar uma máquina. O driver `digitalocean` requer o token da API (ou a variável que o fornece) como seu argumento, junto com o nome da máquina que você deseja criar.

Para criar sua primeira máquina, digite este comando para criar um Droplet na DigitalOcean chamado `docker-01`:

    docker-machine create --driver digitalocean --digitalocean-access-token $DOTOKEN docker-01

Você verá esta saída enquanto o Docker Machine cria o Droplet:

    Output ...
    Installing Docker...
    Copying certs to the local machine directory...
    Copying certs to the remote machine...
    Setting Docker configuration on the remote daemon...
    Checking connection to Docker...
    Docker is up and running!
    To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env ubuntu1804-docker

O Docker Machine cria um par de chaves SSH para o novo host para que ele possa acessar o servidor remotamente. O Droplet é provisionado com um sistema operacional e o Docker é instalado. Quando o comando estiver concluído, o seu Droplet Docker estará em funcionamento.

Para ver a máquina recém-criada a partir da linha de comando, digite:

    docker-machine ls

A saída será semelhante a esta, indicando que o novo host Docker está em execução:

    OutputNAME ACTIVE DRIVER STATE URL SWARM DOCKER ERRORS
    docker-01 - digitalocean Running tcp://209.97.155.178:2376 v18.06.1-ce

Agora vamos ver como especificar o sistema operacional quando criamos uma máquina.

## Passo 4 — Especificando o SO Básico e as Opções de Droplet ao Criar um Host Dockerizado

Por padrão, o sistema operacional básico usado ao criar um host Dockerizado com o Docker Machine é _supostamente_ o Ubuntu LTS mais recente. No entanto, no momento desta publicação, o comando `docker-machine create` ainda está usando o Ubuntu 16.04 LTS como o sistema operacional base, embora o Ubuntu 18.04 seja a edição mais recente do LTS. Portanto, se você precisar rodar o Ubuntu 18.04 em uma máquina recém-provisionada, você terá que especificar o Ubuntu junto com a versão desejada passando a flag `--digitalocean-image` para o comando`docker-machine create`.

Por exemplo, para criar uma máquina usando o Ubuntu 18.04, digite:

    docker-machine create --driver digitalocean --digitalocean-image ubuntu-18-04-x64 --digitalocean-access-token $DOTOKEN docker-ubuntu-1804

Você não está limitado a uma versão do Ubuntu. Você pode criar uma máquina usando qualquer sistema operacional suportado na DigitalOcean. Por exemplo, para criar uma máquina usando o Debian 8, digite:

    docker-machine create --driver digitalocean --digitalocean-image debian-8-x64 --digitalocean-access-token $DOTOKEN docker-debian

Para provisionar um host Dockerizado usando o CentOS 7 como o SO base, especifique `centos-7-0-x86` como o nome da imagem, da seguinte forma:

    docker-machine create --driver digitalocean --digitalocean-image centos-7-0-x64 --digitalocean-access-token $DOTOKEN docker-centos7

O sistema operacional básico não é a única opção que você tem. Você também pode especificar o tamanho do Droplet. Por padrão, é o menor Droplet, que tem 1 GB de RAM, uma única CPU e um SSD de 25 GB.

Encontre o tamanho do Droplet que você deseja usar procurando o slug correspondente na [documentação da API da DigitalOcean](https://developers.digitalocean.com/documentation/v2/#sizes/).

Por exemplo, para provisionar uma máquina com 2 GB de RAM, duas CPUs e um SSD de 60 GB, use o slug `s-2vcpu-2gb`:

    docker-machine create --driver digitalocean --digitalocean-size s-2vcpu-2gb --digitalocean-access-token $DOTOKEN docker-03

Para ver todas as flags específicas para criar um Docker Machine usando o driver da DigitalOcean, digite:

    docker-machine create --driver digitalocean -h

**Dica:** Se você atualizar a página de Droplet do seu painel da DigitalOcean, verá as novas máquinas que você criou usando o comando `docker-machine`.

Agora vamos explorar alguns dos outros comandos do Docker Machine.

## Passo 5 — Executando Comandos Adicionais do Docker Machine

Você viu como provisionar um host Dockerizado usando o subcomando `create` e como listar os hosts disponíveis para o Docker Machine usando o subcomando `ls`. Nesta etapa, você aprenderá alguns subcomandos mais úteis.

Para obter informações detalhadas sobre um host Dockerizado, use o subcomando `inspect`, da seguinte forma:

    docker-machine inspect docker-01

A saída inclui linhas como as da saída mostrada abaixo. A linha `Image` revela a versão da distribuição Linux usada, e a linha `Size` indica o slug do tamanho:

    Output...
    {
        "ConfigVersion": 3,
        "Driver": {
            "IPAddress": "203.0.113.71",
            "MachineName": "docker-01",
            "SSHUser": "root",
            "SSHPort": 22,
            ...
            "Image": "ubuntu-16-04-x64",
            "Size": "s-1vcpu-1gb",
            ...
        },
    
    ---
    

Para imprimir a configuração de conexão de um host, digite:

    docker-machine config docker-01

A saída será smelhante a esta:

    Output--tlsverify
    --tlscacert="/home/kamit/.docker/machine/certs/ca.pem"
    --tlscert="/home/kamit/.docker/machine/certs/cert.pem"
    --tlskey="/home/kamit/.docker/machine/certs/key.pem"
    -H=tcp://203.0.113.71:2376

A última linha na saída do comando `docker-machine config` revela o endereço IP do host, mas você também pode obter essa informação digitando:

    docker-machine ip docker-01

Se você precisar desligar um host remoto, você pode usar `docker-machine` para pará-lo:

    docker-machine stop docker-01

Verifique se está parado:

    docker-machine ls

A saída mostra que o status da máquina mudou:

    OuputNAME ACTIVE DRIVER STATE URL SWARM DOCKER ERRORS
    docker-01 - digitalocean Stopped Unknown

Para iniciá-la novamente, use o subcomando `start`:

    docker-machine start docker-01

Em seguida, revise seu status novamente:

    docker-machine ls

Você verá que o `STATE` agora está definido como `Running` para o host:

    OuputNAME ACTIVE DRIVER STATE URL SWARM DOCKER ERRORS
    
    docker-01 - digitalocean Running tcp://203.0.113.71:2376 v18.06.1-ce

Em seguida, vamos ver como interagir com o host remoto usando o SSH.

## Passo 6 — Executando Comandos em um Host Dockerizado via SSH

Neste ponto, você está recebendo informações sobre suas máquinas, mas você pode fazer mais do que isso. Por exemplo, você pode executar comandos nativos do Linux em um host Docker usando o subcomando `ssh` do `docker-machine` a partir do seu sistema local. Esta seção explica como executar comandos `ssh` via `docker-machine`, bem como abrir uma sessão SSH para um host Dockerizado.

Supondo que você provisionou uma máquina com o Ubuntu como sistema operacional, execute o seguinte comando em seu sistema local para atualizar o banco de dados de pacotes no host Docker:

    docker-machine ssh docker-01 apt-get update

Você pode até mesmo aplicar atualizações disponíveis usando:

    docker-machine ssh docker-01 apt-get upgrade

Não tem certeza de qual kernel seu host Docker remoto está usando? Digite o seguinte:

    docker-machine ssh docker-01 uname -r

Finalmente, você pode efetuar login no host remoto com o comando `docker machine ssh`:

    docker-machine ssh docker-01

Você estará logado como usuário **root** e verá algo semelhante ao seguinte:

    Welcome to Ubuntu 16.04.5 LTS (GNU/Linux 4.4.0-131-generic x86_64)
    
     * Documentation: https://help.ubuntu.com
     * Management: https://landscape.canonical.com
     * Support: https://ubuntu.com/advantage
    
      Get cloud support with Ubuntu Advantage Cloud Guest:
        http://www.ubuntu.com/business/services/cloud
    
    14 packages can be updated.
    10 updates are security updates.

Faça o logout digitando `exit` para retornar à sua máquina local.

Em seguida, direcionaremos comandos do Docker em nosso host remoto.

## Passo 7 — Ativando um Host Dockerizado

A ativação de um host Docker conecta seu cliente Docker local a esse sistema, o que possibilita a execução de comandos `docker` comuns no sistema remoto.

Primeiro, use o Docker Machine para criar um novo host do Docker chamado `docker-ubuntu` usando o Ubuntu 18.04:

    docker-machine create --driver digitalocean --digitalocean-image ubuntu-18-04-x64 --digitalocean-access-token $DOTOKEN docker-ubuntu

Para ativar um host Docker, digite o seguinte comando:

    eval $(docker-machine env machine-name)

Alternativamente, você pode ativá-lo usando este comando:

    docker-machine use machine-name

**Uma dica** ao trabalhar com vários hosts Docker, é que o comando `docker-machine use` é o método mais fácil de alternar de um para o outro.

Depois de digitar qualquer um desses comandos, seu prompt será alterado para indicar que o cliente Docker está apontando para o host do Docker remoto. Ele terá essa forma. O nome do host estará no final do prompt:

    username@localmachine:~ [docker-01]$

Agora, qualquer comando `docker` que você digitar neste prompt de comando será executado naquele host remoto.

Execute `docker-machine ls` novamente:

    docker-machine ls

Você verá um asterisco sob a coluna `ACTIVE` para `docker-01`:

    OutputNAME ACTIVE DRIVER STATE URL SWARM DOCKER ERRORS
    docker-01 * digitalocean Running tcp://203.0.113.71:2376 v18.06.1-ce

Para sair do host Docker remoto, digite o seguinte:

    docker-machine use -u

Seu prompt não mostrará mais o host ativo.

Agora vamos criar containers na máquina remota.

## Passo 8 — Criando Containers Docker em um Host Dockerizado Remoto

Até agora, você provisionou um Droplet Dockerizado na sua conta DigitalOcean e o ativou — ou seja, seu cliente Docker está apontando para ele. O próximo passo lógico é criar containers nele. Por exemplo, vamos tentar executar o container Nginx oficial.

Utilize `docker-machine use` para selecionar sua máquina remota:

    docker-machine use docker-01

Em seguida, execute este comando para executar um container Nginx nessa máquina:

    docker run -d -p 8080:80 --name httpserver nginx

Neste comando, estamos mapeando a porta `80` no container Nginx para a porta `8080` no host Dockerizado para que possamos acessar a página padrão do Nginx de qualquer lugar.

Depois que o container for construído, você poderá acessar a página padrão do Nginx apontando seu navegador para `http://docker_machine_ip:8080`.

Enquanto o host Docker ainda estiver ativado (conforme visto pelo seu nome no prompt), você poderá listar as imagens nesse host:

    docker images

A saída inclui a imagem Nginx que você acabou de usar:

    Output
    REPOSITORY TAG IMAGE ID CREATED SIZE
    nginx latest 71c43202b8ac 3 hours ago 109MB

Você também pode listar os containers ativos ou em execução no host:

    docker ps

Se o container Nginx que você executou nesta etapa for o único container ativo, a saída ficará assim:

    OutputCONTAINER ID IMAGE COMMAND CREATED STATUS
     PORTS NAMES
    d3064c237372 nginx "nginx -g 'daemon of…" About a minute ago Up About a minute
     0.0.0.0:8080->80/tcp httpserver

Se você pretende criar containers em uma máquina remota, seu cliente Docker deve estar apontando para ele — isto é, deve ser a máquina ativa no terminal que você está usando. Caso contrário, você estará criando o container em sua máquina local. Novamente, deixe seu prompt de comando ser seu guia.

O Docker Machine pode criar e gerenciar hosts remotos e também pode removê-los.

## Passo 9 – Removendo Hosts Docker

Você pode usar o Docker Machine para remover um host Docker que você criou. Use o comando `docker-machine rm` para remover o host `docker-01` que você criou:

    docker-machine rm docker-01

O Droplet é excluído junto com a chave SSH criada para ele. Liste os hosts novamente:

    docker-machine ls

Desta vez, você não verá o host `docker-01` listado na saída. E se você criou apenas um host, você não verá saída alguma.

Certifique-se de executar o comando `docker-machine use -u` para apontar seu daemon do Docker local de volta para sua máquina local.

## Passo 10 — Desativando o Relatório de Falhas (Opcinal)

Por padrão, sempre que uma tentativa de provisionar um host Dockerizado usando o Docker Machine falha, ou o Docker Machine trava, algumas informações de diagnóstico são enviadas para uma conta Docker em [Bugsnag](https://www.bugsnag.com/). Se você não está confortável com isso, você pode desabilitar o relatório criando um arquivo vazio chamado `no-error-report` no diretório `.docker/machine` do seu computador local.

Para criar o arquivo, digite:

    touch ~/.docker/machine/no-error-report

Verifique o arquivo em busca de mensagens de erro para falhas de provisionamento ou travamento do Docker Machine.

## Conclusão

Você instalou o Docker Machine e o usou para provisionar vários hosts Docker na DigitalOcean remotamente a partir do seu sistema local. A partir daqui, você deve ser capaz de provisionar quantos hosts Dockerizados forem necessários em sua conta DigitalOcean.

Para mais informações sobre o Docker Machine, visite a [página de documentação oficial](https://docs.docker.com/machine/overview/). Os três scripts Bash baixados neste tutorial estão hospedados [nessa página do GitHub](https://github.com/docker/machine/tree/master/contrib/completion/bash).

Por finid e Brian Hogan
