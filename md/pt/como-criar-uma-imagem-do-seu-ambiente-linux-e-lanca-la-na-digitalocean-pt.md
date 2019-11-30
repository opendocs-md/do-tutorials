---
author: Hanif Jetha
date: 2018-11-27
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-criar-uma-imagem-do-seu-ambiente-linux-e-lanca-la-na-digitalocean-pt
---

# Como Criar uma Imagem do Seu Ambiente Linux e Lançá-la na DigitalOcean

### Introdução

O recurso [Custom Images](https://www.digitalocean.com/docs/images/custom-images/) ou Imagens Personalizadas da DigitalOcean lhe permite trazer seu disco virtual personalizado de Linux e Unix-like de um ambiente local ou de outra plataforma de nuvem para a DigitalOcean e utilizá-lo para iniciar Droplets na DigitalOcean.

Como descrito na [documentação do Custom Images](https://www.digitalocean.com/docs/images/custom-images/overview/), os seguintes tipos de imagens são suportados nativamente pela ferramenta de upload do Custom Images:

- [Raw (`.img`)](https://en.wikipedia.org/wiki/IMG_(file_format))

- [qcow2](https://en.wikipedia.org/wiki/Qcow)

- [VHDX](https://en.wikipedia.org/wiki/VHD_(file_format)#Virtual_Hard_Disk_(VHDX))

- [VDI](https://en.wikipedia.org/wiki/VirtualBox#VirtualBox_Disk_Image)

- [VMDK](https://en.wikipedia.org/wiki/VMDK)

Embora imagens com formato ISO não sejam oficialmente suportadas, você pode aprender como criar e carregar uma imagem compatível usando o VirtualBox seguindo o tutorial [How to Create a DigitalOcean Droplet from an Ubuntu ISO Format Image](how-to-create-a-digitalocean-droplet-from-an-ubuntu-iso-format-image).

Se você ainda não tem uma [imagem compatível](https://www.digitalocean.com/docs/images/custom-images/overview/#image-requirements) para carregar na DigitalOcean, você pode criar e comprimir uma imagem de disco do seu sistema Unix-like ou Linux, desde que ela tenha [o software e os drivers de pré-requisitos instalados](https://www.digitalocean.com/docs/images/custom-images/overview/#image-requirements).

Vamos começar assegurando que sua imagem atende ao requisitos do Custom Images. Para fazer isso, vamos configurar o sistema e instalar alguns pré-requisitos de software. Depois, vamos criar a imagem utilizando o utilitário de linha de comando `dd` e comprimí-la usando o `gzip`. Na sequência, vamos fazer o upload desse arquivo de imagem compactado para o DigitalOcean Spaces, de onde podemos importá-lo como uma Imagem Personalizada. Finalmente, vamos inicializar um droplet usando a imagem enviada

## Pré-requisitos

Se possível, você deve usar uma das imagens fornecidas pela DigitalOcean como base, ou uma imagem de nuvem oficial fornecida pela distribuição como o [Ubuntu Cloud](https://cloud-images.ubuntu.com/). Então você pode instalar softwares e aplicaçoes em cima dessa imagem de base para fazer uma nova imagem usando ferramentas como o [Packer](https://www.packer.io/) e o [VirtualBox](https://www.virtualbox.org/). Muitos provedores de nuvem e ambientes de virtualização também fornecem ferramentas para exportar discos virtuais para um dos formatos compatíveis listados acima, assim, se possível, você deve usá-las para simplificar o processo de importação. Nos casos em que você precisa criar manualmente uma imagem de disco do seu sistema você pode seguir as instruções nesse guia. Observe que essas instruções só foram testadas com um sistema Ubuntu 18.04 e as etapas podem variar dependendo do sistema operacional e da configuração do seu servidor.

Antes de começar com este tutorial, você deve ter o seguinte disponível para você:

- Um sistema Linux ou Unix-like que atenda a todos os requisitos listados na [documentação de produto](https://www.digitalocean.com/docs/images/custom-images/overview/#image-requirements) do Custom Images. Por exemplo, seu disco de boot deve ter:

- Um usuário não-root com privilégios administrativos disponível para você no sistema que você está fazendo imagem. Para criar um novo usuário e conceder a ele privilégios administrativos no Ubuntu 18.04, siga nosso tutorial de [Configuração Inicial de Servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt). Para aprender como fazer isto no Debian 9, consulte [Configuração Inicial de Servidor com Debian 9](initial-server-setup-with-debian-9).

- Um dispositivo de armazenamento adicional usado para armazenar a imagem de disco criada neste guia, preferivelmente tão grande quanto o disco que está sendo copiado. Isso pode ser um volume de armazenamento em blocos anexado, um drive externo USB, um espaço em disco adicional, etc.

- Um Space na DigitalOcean e o utilitário de transferência de arquivos `s3cmd` configurado para uso com o seu Space. Para aprender como criar um Space, consulte o [Guia Rápido](https://www.digitalocean.com/docs/spaces/quickstart/) do Spaces. Para aprender como configurar o `s3cmd` para uso com o seu Space, consulte o [Guia de Configuração do s3cmd 2.x](https://www.digitalocean.com/docs/spaces/resources/s3cmd/).

## Passo 1 — Instalando o Cloud-Init e ativando o SSH

Para começar, vamos instalar o pacote de inicialização do [cloud-Init](https://cloudinit.readthedocs.io/en/latest/). O cloud-init é um conjunto de scripts que executam no boot para configurar certas propriedades da instância de nuvem como a localidade padrão, hostname, chaves SSH e dispositivos de rede.

Os passos para a instalação do cloud-init vão variar dependendo do sistema operacional que você instalou. Em geral, o pacote `cloud-init` deve estar disponível no gerenciador de pacotes do seu SO, assim se você não estiver utilizando uma distribuição baseada no Debian, você deve substituir o `apt` nos seguintes passos pelo seu comando do gerenciador de pacotes específico da distribuição.

### Instalando o **`cloud-init`**

Neste guia, vamos utilizar um servidor Ubuntu 18.04 e então usaremos o `apt` para baixar e instalar o pacote `cloud-init`. Observe que o `cloud-init` pode já estar instalado em seu sistema (algumas distribuições Linux instalam o `cloud-init`por padrão). Para verificar, efetue o login em seu servidor e execute o seguinte comando:

    cloud-init

Se você vir a seguinte saída, o `cloud-init` já foi instalado no seu servidor e você pode continuar configurando-o para uso com a DigitalOcean:

    Outputusage: /usr/bin/cloud-init [-h] [--version] [--file FILES] [--debug] [--force]
                               {init,modules,single,query,dhclient-hook,features,analyze,devel,collect-logs,clean,status}
                               ...
    /usr/bin/cloud-init: error: the following arguments are required: subcommand

Se, em vez disso, você vir o seguinte, você precisa instalar o `cloud-init`:

    Outputcloud-init: command not found

Para instalar o `cloud-init`, atualize o índice de pacotes e em seguida instale o pacote usando o `apt`:

    sudo apt update
    sudo apt install cloud-init

Agora que instalamos o `cloud-init`, vamos configurá-lo para uso com a DigitalOcean, assegurando que ele utilize o datasource `ConfigDrive`. O datasource do cloud-init determina como o `cloud-init` procurará e atualizará a configuração e os metadados da instância. Os Droplets da DigitalOcean usam o datasource `ConfigDrive`, por isso, vamos verificar se ele vem em primeiro lugar na lista de datasources que o `cloud-init` pesquisa sempre que o Droplet inicializa.

### Reconfigurando o **`cloud-init`**

Por padrão, no Ubuntu 18.04, o `cloud-init` configura a si mesmo para utilizar o datasource `NoCloud` primeiro. Isso irá causar problemas ao executar a imagem na DigitalOcean, por isso precisamos reconfigurar o `cloud-init` para utilizar o datasource `ConfigDdrive` e garantir que o `cloud-init` execute novamente quando a imagem é lançada na DigitalOcean.

A partir da linha de comando, navegue até o diretório `/etc/cloud/cloud.cfg.d`:

    cd /etc/cloud/cloud.cfg.d

Use o comando `ls` para listar os arquivos de configuração do `cloud-init` presentes dentro do diretório:

    ls

    Output05_logging.cfg 50-curtin-networking.cfg 90_dpkg.cfg curtin-preserve-sources.cfg README

Dependendo da sua instalação, alguns desses arquivos podem não estar presentes. Se presente, exclua o arquivo `50-curtin-networking.cfg`, que configura as interfaces de rede para seu servidor Ubuntu. Quando a imagem é lançada na DigitalOcean, o `cloud-init` irá executar e reconfigurar estas interfaces automaticamente, portanto esse arquivo não é necessário. Se esse arquivo não for excluído, o Droplet da DigitalOcean criado a partir dessa imagem Ubuntu terá suas interfaces configuradas incorretamente e não serão acessíveis pela internet:

    sudo rm 50-curtin-networking.cfg

Em seguida, vamos executar `dpkg-reconfigure cloud-init` para remover o datasource `NoCloud`, garantindo que o cloud-init procure e localize o datasource `ConfigDrive` usado na DigitalOcean:

    sudo dpkg-reconfigure cloud-init

Você deve ver o seguinte menu gráfico:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/iso_custom_images/cloud_init.png)

O datasource `NoCloud` está inicialmente destacado. Pressione `ESPAÇO` para desmarcá-lo e, em seguida, pressione `ENTER`.

Finalmente, navegue até `/etc/netplan`:

    cd /etc/netplan

Remova o arquivo `50-cloud-init.yaml`, que foi gerado a partir do arquivo de rede `cloud-init` que removemos anteriormente:

    sudo rm 50-cloud-init.yaml

A etapa final é garantir que limpemos a configuração da execução inicial do `cloud-init` para que ela seja executada novamente quando a imagem for lançada na DigitalOcean.

Para fazer isso, execute `cloud-init clean`:

    sudo cloud-init clean

Neste ponto você instalou e configurou o `cloud-init` para uso com a DigitalOcean. Agora você pode seguir para ativar o acesso SSH ao seu droplet.

### Ativar o Acesso SSH

Depois que você instalou e configurou o `cloud-init`, o próximo passo é assegurar que você tenha um usuário e senha de administrador não-root disponível para você em sua máquina, conforme descrito nos pré-requisitos. Este passo é essencial para diagnosticar quaisquer erros que possam surgir após o upload da sua imagem e o lançamento do seu droplet. Se uma configuração de rede preexistente ou uma configuração incorreta do `cloud-init` tornar o seu Droplet inacessível na rede, você pode utilizar esse usuário em combinação ao [Console do Droplet da DigitalOcean](https://www.digitalocean.com/docs/droplets/how-to/connect-with-console/) para acessar seu sistema e diagnosticar quaisquer problemas que possam ter surgido.

Depois que você tiver configurado seu usuário administrativo não-root, a etapa final é garantir que você tenha um servidor SSH instalado e executando. O SSH geralmente vem pré-instalado em muitas distribuições populares do Linux. O procedimento para verificar se um processo está executando irá variar dependendo do sistema operacional do seu servidor. Se você não tiver certeza de como fazer isso, consulte a documentação do seu sistema operacional sobre o gerenciamento de serviços. No Ubuntu, você pode verificar que o SSH está funcionando utilizando este comando:

    sudo service ssh status

Você deve ver a seguinte saída:

    Output● ssh.service - OpenBSD Secure Shell server
       Loaded: loaded (/lib/systemd/system/ssh.service; enabled; vendor preset: enabled)
       Active: active (running) since Mon 2018-10-22 19:59:38 UTC; 8 days 1h ago
         Docs: man:sshd(8)
               man:sshd_config(5)
      Process: 1092 ExecStartPre=/usr/sbin/sshd -t (code=exited, status=0/SUCCESS)
     Main PID: 1115 (sshd)
        Tasks: 1 (limit: 4915)
       Memory: 9.7M
       CGroup: /system.slice/ssh.service
               └─1115 /usr/sbin/sshd -D

Se o SSH não estiver em execução, você pode instalá-lo usando o `apt` (nas distribuições baseadas em Debian):

    sudo apt install openssh-server

Por padrão, o servidor SSH vai iniciar no boot a menos que esteja configurado de outra forma. Isso é desejável ao executar o sistema na nuvem, já que a DigitalOcean pode copiar automaticamente sua chave pública e conceder acesso SSH imediato ao seu Droplet após a criação.

Depois que você criou um usuário administrativo não-root, ativou o SSH, e instalou o cloud-init, você está pronto para continuar criando uma imagem do seu disco de boot.

## Passo 2 — Criando uma Imagem de Disco

Neste passo, vamos criar uma imagem de disco de formato RAW usando o utilitário de linha de comando `dd`, e compactá-lo usando o `gzip`. Vamos então carregar a imagem para o Spaces da DigitalOcean usando o `s3cmd`.

Para começar, efetue login em seu servidor, e inspecione o arranjo de dispositivos de bloco para o seu sistema usando `lsblk`:

    lsblk

Você deverá ver algo como o seguinte:

    OutputNAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
    loop0 7:0 0 12.7M 1 loop /snap/amazon-ssm-agent/495
    loop1 7:1 0 87.9M 1 loop /snap/core/5328
    vda 252:0 0 25G 0 disk
    └─vda1 252:1 0 25G 0 part /
    vdb 252:16 0 420K 1 disk

Nesse caso, observamos que nosso disco principal de boot é o `/dev/vda`, um disco de 25GB, e a partição primária, montada no `/`, é a `/dev/vda1`. Na maioria dos casos o disco contendo a partição montada no `/` será o disco de origem para a imagem. Vamos usar o `dd` para criar uma imagem do `/dev/vda`.

Neste ponto, você deve decidir onde você quer armazenar a imagem de disco. Uma opção é anexar outro dispositivo de armazenamento em bloco, de preferência tão grande quanto o disco que você está fazendo a imagem. Em seguida, você pode salvar a imagem neste disco temporário anexado e enviá-la para o Spaces da DigitalOcean.

Se você tem acesso físico ao servidor, você pode adicionar um drive adicional à máquina ou anexar outro dispositivo de armazenamento, como um disco USB externo.

Outra opção, que iremos demonstrar nesse guia, é copiar a imagem por SSH para uma máquina local, a partir da qual você pode enviá-la para o Spaces.

Independentemente do método escolhido, verifique se o dispositivo de armazenamento no qual você salvou a imagem compactada tem espaço livre suficiente. Se o disco que você está fazendo imagem está quase vazio, você pode esperar que o arquivo de imagem compactado seja significativamente menor que o disco original.

**Atenção:** Antes de rodar o seguinte comando `dd`, certifique-se de que todos os aplicativos críticos tenham sido parados e seu sistema esteja o mais folgado possível. Copiar um disco sendo usado ativamente pode resultar em alguns arquivos corrompidos, portanto, certifique-se de interromper qualquer operação que use muitos dados e encerre o máximo possível de aplicativos em execução.

### Opção 1: Criando a Imagem Localmente

A sintaxe para o comando `dd` que vamos executar é a seguinte:

    dd if=/dev/vda bs=4M conv=sparse | pv -s 25G | gzip > /mnt/tmp_disk/ubuntu.gz

Neste caso, estamos selecionando `/dev/vda` como o disco de entrada para se fazer imagem, e definindo o tamanho dos blocos de entrada/saída para 4MB (sendo que o padrão é 512 bytes). Isso geralmente acelera um pouco as coisas. Além disso, estamos usando a flag `conv=sparse` para minimizar o tamanho do arquivo de saída pulando o espaço vazio. Para aprender mais sobre parâmetros do `dd`, consulte a sua [manpage](http://man7.org/linux/man-pages/man1/dd.1.html).

Em seguida, fazemos um pipe da saída para o utilitário de visualização de pipe `pv` para que possamos acompanhar o progresso da transferência visualmente (esse pipe é opcional e requer a instalação do `pv` usando o gerenciador de pacotes). Se você sabe o tamanho do disco inicial (nesse caso é 25GB), você pode adicionar `-s 25G` ao pipe do `pv` para ter uma estimativa de quando a transferência será concluída.

Fazemos então um pipe de tudo isso para o `gzip` e salvamos em um arquivo chamado `ubuntu.gz` no volume de armazenamento de bloco temporário que anexamos ao servidor. Substitua `/mnt/tmp_disk` com o caminho para o dispositivo de armazenamento externo que você anexou ao seu servidor.

### Opção 2: Criando a Imagem via SSH

Em vez de provisionar armazenamento adicional para sua máquina remota, você também pode executar a cópia via SSH se tiver espaço em disco suficiente disponível na sua máquina local. Observe que, dependendo da largura de banda disponível para você, isso pode ser lento e você pode incorrer em custos adicionais para a transferência de dados pela rede.

Para copiar e compactar o disco via SSH, execute o seguinte comando em sua máquina local:

    ssh usuário_remoto@ip_do_seu_servidor "sudo dd if=/dev/vda bs=4M conv=sparse | gzip -1 -" | dd of=ubuntu.gz

Neste caso, estamos fazendo SSH para o nosso servidor remoto executando o comando `dd` lá, e fazendo um pipe da saída para o `gzip`. Em seguida, transferimos a saída do `gzip` pela rede e a salvamos localmente como `ubuntu.gz`. Certifique-se de que você tenha o utilitário `dd` disponível em sua máquina local antes de executar esse comando:

    which dd

    Output/bin/dd

Crie o arquivo de imagem compactado usando qualquer um dos métodos acima. Isso pode levar várias horas, dependendo do tamanho do disco que você está criando e do método que você está usando para criar a imagem.

Depois de criar o arquivo de imagem compactado, você pode passar a enviá-lo para seus Spaces da DigitalOcean usando o `s3cmd`.

## Passo 3 — Fazendo Upload da Imagem para Spaces e Custom Images

Conforme descrito nos pré-requisitos, você deve ter o `s3cmd` instalado e configurado para uso com seu Space da DigitalOcean na máquina que contém sua imagem compactada.

Localize o arquivo de imagem compactado e faça o upload dele para seu Space usando o `s3cmd`:

**Nota:** Você deve substituir `your_space_name` pelo nome do seu Space e não a sua URL. Por exemplo, se a URL do seu Space é `https://example-space-name.nyc3.digitaloceanspaces.com`, então o nome do seu Space é `example-space-name`.

    s3cmd put /caminho_da_imagem/ubuntu.gz s3://your_space_name

Quando o upload estiver concluído, navegue até seu Space usando o [Painel de Controle](https://cloud.digitalocean.com/spaces) da DigitalOcean, e localize a imagem na lista de arquivos. Tornaremos a imagem publicamente acessível temporariamente para que o Custom Images possa acessá-la e salvar uma cópia.

À direita da lista de imagens, clique no menu suspenso **More** e, em seguida, clique em **Manage Permissions:**

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/custom_images_migration/public_image.png)

Em seguida, clique no botão de opção ao lado de **Public** e clique em **Update** para tornar a imagem publicamente acessível.

**Atenção:** Sua imagem estará temporariamente acessível publicamente para qualquer pessoa com o caminho do seu Space durante este processo. Se você gostaria de evitar tornar sua imagem temporariamente pública, você pode criar sua Imagem Personalizada usando a API da DigitalOcean. Certifique-se de definir sua imagem como **Private** usando o procedimento acima depois que sua imagem for transferida com sucesso para o Custom Images.

Busque a URL do Spaces para sua imagem passando o mouse sobre o nome da imagem no Painel de controle, e clique em **Copy URL** na janela que aparece.

Agora, navegue para **Images** na barra de navegação à esquerda, e depois para **Custom Images**.

A partir daqui, envie sua imagem usando esta URL, conforme detalhado na [Documentação de Produto](https://www.digitalocean.com/docs/images/custom-images/how-to/upload/) do Custom Images.

Você pode então [criar um Droplet a partir desta imagem](https://www.digitalocean.com/docs/images/custom-images/how-to/create-droplets/). Observe que você precisa adicionar uma chave SSH ao Droplet na criação. Para aprender como fazer isso, consulte [How to Add SSH Keys to Droplets](https://www.digitalocean.com/docs/droplets/how-to/add-ssh-keys/).

Uma vez que o seu Droplet inicializa, se você puder fazer SSH nele, você lançou com sucesso a sua Imagem Personalizada como um Droplet da DigitalOcean.

### Fazendo Debug

Se você tentar fazer SSH no seu Droplet e não conseguir conectar, certifique-se de que sua imagem atenda aos requisitos listados e tenha o `cloud-init` e o SSH instalados e configurados corretamente. Se você ainda não conseguir acessar o Droplet, você pode tentar utilizar o [Console do Droplet da DigitalOcean](https://www.digitalocean.com/docs/droplets/how-to/connect-with-console/) e o usuário não-root que você criou anteriormente para explorar o sistema e fazer o debug das configurações de sua rede, do `cloud-init` e do SSH. Outra maneira de fazer o debug de sua imagem é usar uma ferramenta de virtualização como o [Virtualbox](https://www.virtualbox.org/) para inicializar sua imagem de disco dentro de uma máquina virtual, e fazer o debug da configuração do seu sistema a partir da VM.

## Conclusão

Neste guia, você aprendeu como criar uma imagem de disco de um sistema Ubuntu 18.04 usando o utilitário de linha de comando `dd` e fazer o upload dela para a DigitalOcean como uma Custom Image ou Imagem Personalizada a partir da qual você pode lançar Droplets.

As etapas neste guia podem variar dependendo do seu sistema operacional, do hardware existente e da configuração do kernel, mas, em geral, as imagens criadas a partir de distribuições populares do Linux devem funcionar usando esse método. Certifique-se de seguir cuidadosamente as etapas de instalação e configuração do `cloud-init` e de garantir que o sistema atenda a todos os requisitos listados na seção [pré-requisitos](how-to-create-an-image-of-your-linux-environment-and-launch-it-on-digitalocean#prerequisites) acima.

Para aprender mais sobre Custom Images, consulte a [documentação de produto do Custom Images](https://www.digitalocean.com/docs/images/custom-images/).

_Por Hanif Jetha_
