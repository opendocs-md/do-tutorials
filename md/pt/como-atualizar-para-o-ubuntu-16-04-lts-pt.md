---
author: Brennen Bearnes
date: 2017-02-15
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-atualizar-para-o-ubuntu-16-04-lts-pt
---

# Como Atualizar para o Ubuntu 16.04 LTS

### Introdução

**Atenção** : Uma versão anterior desse guia incluía uma menção aos sistemas Ubuntu 14.04. Embora uma atualização a partir do 14.04 _possa_ completar com sucesso, atualizações entre versões LTS não estão habilitadas por padrão até o primeiro ponto de versão, e é recomendado aguardar até o ponto de versão 16.04.1 para atualizar. Nos sistemas da DigitalOcean, um sistema atualizado 14.04 será deixado com um kernel mais antigo que pode não ser atualizável por algum tempo.

A próxima versão _Long Term Support_ do sistema operacional Ubuntu, versão 16.04 (Xenial Xerus), deve ser lançada em 21 de abril de 2016.

Embora ainda não tenha sido lançado no momento da redação deste artigo, já é possível atualizar um sistema 15.10 para a versão de desenvolvimento 16.04. Isso pode ser útil para testar tanto o processo de atualização quanto as próprias características do 16.04 antes da data oficial do lançamento.

Este guia irá explicar o processo para sistemas incluindo (mas não limitado a) Droplets DigitalOcean rodando Ubuntu 15.10.

**Atenção** : Como acontece com quase toda atualização entre as principais versões de um sistema operacional, este processo carrega um risco inerente de falha, perda de dados ou quebra de configuração de software. Backups completos e testes extensos são fortemente aconselhados.

## Pré-requisitos

Este guia assume que você tem um sistema rodando Ubuntu **15.10** , configurado com um usuário não-root com privilégios `sudo` para tarefas administrativas.

## Armadilhas Potenciais

Embora muitos sistemas possam ser atualizados sem incidentes, muitas vezes é mais seguro e mais previsível migrar para uma nova versão principal instalando a distribuição a partir do zero, configurando os serviços com testes cuidadosos ao longo do caminho, e migrando aplicações ou dados de usuários como um passo separado.

Você nunca deve atualizar um sistema de produção sem primeiro testar todo o seu software e os serviços implantados contra a atualização em um ambiente de teste. Tenha em mente que aquelas bibliotecas, linguagens e serviços de sistema podem ter mudado substancialmente. No Ubuntu 16.04, mudanças importantes desde a liberação do LTS anterior incluem a transição para o sistema init systemd no lugar do Upstart, uma ênfase no suporte ao Python 3, e PHP 7 no lugar do PHP 5.

Antes da atualização, considere a leitura das [Notas de Versão Xenial Xerus](https://wiki.ubuntu.com/XenialXerus/ReleaseNotes).

## Passo 1 – Fazer Backup do seu Sistema

Antes de tentar uma atualização principal em qualquer sistema, certifique-se de que você não perderá dados se a atualização der errado. A melhor forma de se conseguir isso é realizando um backup do seu sistema de arquivos inteiro. Se isso falhar, assegure-se de que você tem cópias dos diretórios home dos usuários, quaisquer arquivos de configuração, e dados armazenados por serviços como bancos de dados relacionais.

Em um Droplet DigitalOcean, a abordagem mais fácil é desligar o sistema e tirar um instantâneo (desligando garante que o sistema de arquivos estará mais consistente). Veja [How To Use DigitalOcean Snapshots to Automatically Backup your Droplets](how-to-use-digitalocean-snapshots-to-automatically-backup-your-droplets) para mais detalhes do processo de se tirar instantâneos. Quando você tiver verificado que a atualização foi realizada com sucesso, você pode deletar o instantâneo para que você não seja mais cobrado por ele.

Para métodos de backup que irão funcionar na maioria dos sistemas Ubuntu, veja [How To Choose an Effective Backup Strategy for your VPS](how-to-choose-an-effective-backup-strategy-for-your-vps).

## Passo 2 – Atualizar Pacotes Instalados Atualmente

Antes de iniciar a atualização de versão, é mais seguro instalar as versões mais recentes de todos os pacotes _para a versão atual_. Comece atualizando a lista de pacotes:

    sudo apt-get update

Depois, atualize os pacotes instalados para a suas últimas versões disponíveis:

    sudo apt-get upgrade

Será exibida uma lista de atualizações e será solicitado que você continue. Responda **y** para sim e pressione **Enter**.

Esse processo pode levar algum tempo. Quando terminar, utilize o comando `dist-upgrade`, que realizará atualizações envolvendo alterações de dependências, adição ou remoção de novos pacotes quando necessário. Isso irá lidar com um conjunto de atualizações que podem ter sido retidas pelo `apt-get upgrade`:

    sudo apt-get dist-upgrade

Novamente, responda **y** quando solicitado a continuar, e aguarde para que as atualizações terminem.

Agora que você tem uma instalação atualizada do Ubuntu 15.10, você pode utilizar `do-release-upgrade` para atualizar para a versão 16.04.

## Passo 3 – Utilizar a Ferramenta do-release-upgrade do Ubuntu para Realizar a Atualização

Primeiro, certifique-se de que você tem o pacote `update-manager-core` instalado:

    sudo apt-get install update-manager-core

Tradicionalmente, as versões do Debian são atualizáveis através da alteração do arquivo do Apt `/etc/apt/sources.list` que especifica os repositórios de pacotes, e utilizando `apt-get dist-upgrade` para realizar a atualização propriamente dita. O Ubuntu ainda é uma distribuição derivada do Debian, assim esse processo ainda funcionaria. Em vez disso, contudo, iremos utilizar `do-release-upgrade`, uma ferramenta fornecida pelo projeto Ubuntu, que lida com a checagem de uma nova versão, atualizando `sources.list`, e uma série de outras tarefas. Esse é o caminho oficial recomendado para atualizações para servidores, que deve ser realizada através de uma conexão remota.

Comece executando `do-release-upgrade` sem opções:

    sudo do-release-upgrade

Se o Ubuntu 16.04 não tiver sido lançado ainda, você deve ver o seguinte:

Saída de exemplo

    Checking for a new Ubuntu release
    No new release found

Para realizar a atualização para **16.04** antes do seu lançamento oficial, especifique a opção `-d` de forma a utilizar a versão de _desenvolvimento_:

    sudo do-release-upgrade -d

Se você está conectado em seu sistema via SSH, como é provável com um Droplet da DigitalOcean, você será perguntado se deseja continuar.

Em um Droplet, é seguro atualizar via SSH. Embora o `do-upgrade-release` não nos tenha informado disso, você pode utilizar o console disponível através do Painel de Controle da DigitalOcean para conectar em seu Droplet sem executar SSH.

Para máquinas virtuais ou servidores gerenciados hospedados por outros provedores, você deve ter em mente que perder a conexão SSH é um risco, particularmente se você não tiver outros meios de conectar-se remotamente ao console do sistema. Para outros sistemas sob o seu controle, lembre-se que é mais seguro realizar atualizações principais de sistema operacional quando você tem acesso físico à máquina.

No prompt, digite **y** e pressione **Enter** para continuar:

    Reading cache
    
    Checking package manager
    
    Continue running under SSH?
    
    This session appears to be running under ssh. It is not recommended
    to perform a upgrade over ssh currently because in case of failure it
    is harder to recover.
    
    If you continue, an additional ssh daemon will be started at port
    '1022'.
    Do you want to continue?
    
    Continue [yN] y

Em seguida, você será informado de que o `do-release-upgrade` está iniciando uma nova instância do `sshd` na porta 1022:

    Starting additional sshd 
    
    To make recovery in case of failure easier, an additional sshd will 
    be started on port '1022'. If anything goes wrong with the running 
    ssh you can still connect to the additional one. 
    If you run a firewall, you may need to temporarily open this port. As 
    this is potentially dangerous it's not done automatically. You can 
    open the port with e.g.: 
    'iptables -I INPUT -p tcp --dport 1022 -j ACCEPT' 
    
    To continue please press [ENTER]

Pressione **Enter**. Em seguida, você pode ser avisado que uma entrada de espelho não foi encontrada. Nos sistemas da DigitalOcean, é seguro ignorar esse aviso e prosseguir com a atualização, visto que um espelho local para a **16.04** está de fato disponível. Digite **y** :

    Updating repository information
    
    No valid mirror found 
    
    While scanning your repository information no mirror entry for the 
    upgrade was found. This can happen if you run an internal mirror or 
    if the mirror information is out of date. 
    
    Do you want to rewrite your 'sources.list' file anyway? If you choose 
    'Yes' here it will update all 'trusty' to 'xenial' entries. 
    If you select 'No' the upgrade will cancel. 
    
    Continue [yN] y

Uma vez que as listas de novos pacotes tenham sido baixadas e a alterações calculadas, você será perguntado se quer iniciar a atualização. Novamente, digite **y** para continuar:

    Do you want to start the upgrade?
    
    
    6 installed packages are no longer supported by Canonical. You can
    still get support from the community.
    
    9 packages are going to be removed. 104 new packages are going to be
    installed. 399 packages are going to be upgraded.
    
    You have to download a total of 232 M. This download will take about
    46 seconds with your connection.
    
    Installing the upgrade can take several hours. Once the download has
    finished, the process cannot be canceled.
    
     Continue [yN] Details [d]y

Os novos pacotes serão agora baixados, depois descompactados e instalados. Mesmo que seu sistema esteja em uma conexão rápida, isso irá levar algum tempo.

Durante a instalação você pode se deparar com diálogos interativos para várias questões. Por exemplo, você pode ser perguntado se quer reiniciar automaticamente os serviços quando necessário:

![](http://assets.digitalocean.com/articles/how-to-upgrade-to-ubuntu-1604/0.png)

Nesse caso, é seguro responder “Yes”. Em outros casos, você pode ser perguntado se deseja substituir um arquivo de configuração que você tenha modificado com a versão padrão do pacote que está sendo instalado. Isso geralmente é uma questão que provavelmente irá exigir um conhecimento sobre o software específico, o que está fora do escopo desse tutorial.

Uma vez que os novos pacotes tenham terminado de instalar, você será perguntado se está pronto para remover os pacotes obsoletos. Em um sistema regular sem configuração personalizada, deve ser seguro digitar **y** aqui. Em um sistema que você tenha modificado muito, você pode querer digitar **d** e inspecionar a lista de pacotes a serem removidos, no caso de incluir qualquer coisa que você precise reinstalar mais tarde.

    Remove obsolete packages? 
    
    
    53 packages are going to be removed. 
    
     Continue [yN] Details [d]y

Finalmente, assumindo que tudo correu bem, você será informado de que a atualização está completa e uma reinicialização é necessária. Digite **y** para continuar:

    System upgrade is complete.
    
    Restart required 
    
    To finish the upgrade, a restart is required. 
    If you select 'y' the system will be restarted. 
    
    Continue [yN] y

Em uma sessão SSH, você provavelmente verá algo assim:

    === Command detached from window (Thu Apr 7 13:13:33 2016) ===
    === Command terminated normally (Thu Apr 7 13:13:43 2016) ===

Você pode precisar pressionar uma tecla aqui para sair para seu prompt local, uma vez que a sua sessão SSH terá terminado no lado do servidor. Aguarde um momento para seu sistema reinicializar, e reconecte. No login, você deve ser saudado por uma mensagem confirmando que você está agora no Xenial Xerus:

    Welcome to Ubuntu Xenial Xerus (development branch) (GNU/Linux 4.4.0-17-generic x86_64)

## Conclusão

Agora você deve ter uma instalação de trabalho do Ubuntu 16.04. A partir daqui, é provável que você precise investigar as alterações de configuração necessárias para os serviços e aplicativos implantados. Nas próximas semanas, começaremos a postar guias da DigitalOcean específicos do Ubuntu 16.04 em uma ampla gama de tópicos.
