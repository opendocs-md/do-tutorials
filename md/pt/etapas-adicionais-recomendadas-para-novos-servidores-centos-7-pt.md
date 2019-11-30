---
author: Justin Ellingwood
date: 2019-08-12
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/etapas-adicionais-recomendadas-para-novos-servidores-centos-7-pt
---

# Etapas Adicionais Recomendadas para Novos Servidores CentOS 7

### Introdução

Depois de definir a configuração mínima para um novo servidor, existem algumas etapas adicionais que são altamente recomendadas na maioria dos casos. Neste guia, continuaremos a configuração de nossos servidores, abordando alguns procedimentos recomendados, mas opcionais.

## Pré-requisitos e Objetivos

Antes de iniciar este guia, você deve passar pelo guia de [Configuração Inicial do Servidor com o CentOS 7](configuracao-inicial-do-servidor-com-o-centos-7-pt). Isso é necessário para configurar suas contas de usuário, configurar a elevação de privilégios com o `sudo` e bloquear o SSH por segurança.

Depois de concluir o guia acima, você pode continuar com este artigo. Neste guia, nos concentraremos na configuração de alguns componentes opcionais, mas recomendados. Isso envolverá a configuração do nosso sistema com um firewall e um arquivo de swap, e configurar a sincronização do Network Time Protocol.

## Configurando um Firewall Básico

Os firewalls fornecem um nível básico de segurança para o seu servidor. Esses aplicativos são responsáveis por negar tráfego a todas as portas do servidor com exceções das portas/serviços que você aprovou. O CentOS vem com um firewall chamado `firewalld`. Uma ferramenta chamada `firewall-cmd` pode ser usada para configurar suas políticas de firewall. Nossa estratégia básica será bloquear tudo o que não tivermos uma boa razão para manter em aberto. Primeiro instale o `firewalld`:

    sudo yum install firewalld

O serviço `firewalld` tem a capacidade de fazer modificações sem perder as conexões atuais, assim podemos ativá-lo antes de criar nossas exceções:

    sudo systemctl start firewalld

Agora que o serviço está funcionando, podemos usar o utilitário `firewall-cmd` para obter e definir informações de política para o firewall. O aplicativo `firewalld` usa o conceito de “zonas” para rotular a confiabilidade dos outros hosts em uma rede. Essa rotulagem nos dá a capacidade de atribuir regras diferentes, dependendo de quanto confiamos em uma rede.

Neste guia, estaremos ajustando somente as políticas para a zona padrão ou default. Quando recarregarmos nosso firewall, essa será a zona aplicada às nossas interfaces. Devemos começar adicionando exceções ao nosso firewall para serviços aprovados. O mais essencial deles é o SSH, já que precisamos manter o acesso administrativo remoto ao servidor.

Se você **não** modificou a porta em que o daemon SSH está sendo executado, é possível ativar o serviço pelo nome digitando:

    sudo firewall-cmd --permanent --add-service=ssh

Se você **alterou** a porta SSH do seu servidor, você terá que especificar a nova porta explicitamente. Você também precisará incluir o protocolo que o serviço utiliza. Somente digite o seguinte caso seu servidor SSH já tenha sido reiniciado para usar a nova porta:

    sudo firewall-cmd --permanent --remove-service=ssh
    sudo firewall-cmd --permanent --add-port=4444/tcp

Isso é o mínimo necessário para manter o acesso administrativo ao servidor. Se você planeja executar serviços adicionais, também precisa abrir o firewall para esses serviços.

Se você planeja executar um servidor web HTTP convencional, você precisará habilitar o serviço `http`:

    sudo firewall-cmd --permanent --add-service=http

Se você planeja executar um servidor web com SSL/TLS ativado, você também deve permitir o tráfego de `https`:

    sudo firewall-cmd --permanent --add-service=https

Se você precisar que o email SMTP esteja ativado, você pode digitar:

    sudo firewall-cmd --permanent --add-service=smtp

Para ver quaisquer serviços adicionais que você possa ativar por nome, digite:

    sudo firewall-cmd --get-services

Quando terminar, você poderá ver a lista das exceções que serão implementadas digitando:

    sudo firewall-cmd --permanent --list-all

Quando você estiver pronto para implementar as mudanças, recarregue o firewall:

    sudo firewall-cmd --reload

Se, após o teste, tudo funcionar conforme o esperado, você deverá certificar-se de que o firewall será iniciado na inicialização:

    sudo systemctl enable firewalld

Lembre-se de que você terá que abrir explicitamente o firewall (com serviços ou portas) para quaisquer serviços adicionais que você venha a configurar posteriormente.

## Configurar Fuso Horário e Sincronização do Network Time Protocol

O próximo passo é ajustar as configurações de localização do seu servidor e configurar a sincronização do Network Time Protocol (NTP).

O primeiro passo garantirá que seu servidor esteja operando no fuso horário correto. O segundo passo configurará seu servidor para sincronizar o relógio do sistema com o horário padrão mantido por uma rede global de servidores NTP. Isso ajudará a evitar algum comportamento inconsistente que pode surgir com relógios fora de sincronia.

### Configurar Fusos Horários

Nosso primeiro passo é definir o fuso horário do nosso servidor. Este é um procedimento muito simples que pode ser realizado usando o comando `timedatectl`:

Primeiro, dê uma olhada nos fusos horários disponíveis digitando:

    sudo timedatectl list-timezones

Isto lhe dará uma lista dos fusos horários disponíveis para o seu servidor. Quando você encontrar a configuração de região/fuso horário que estiver correta para o seu servidor, defina-a digitando:

    sudo timedatectl set-timezone região/fuso_horário

Por exemplo, para configurá-lo para o horário do leste dos Estados Unidos, você pode digitar:

    sudo timedatectl set-timezone America/New_York

Seu sistema será atualizado para usar o fuso horário selecionado. Você pode confirmar isso digitando:

    sudo timedatectl

### Configurar a Sincronização NTP

Agora que você tem o seu fuso horário definido, devemos configurar o NTP. Isso permitirá que seu computador fique em sincronia com outros servidores, levando a uma maior previsibilidade nas operações que dependem da hora correta.

Para a sincronização NTP, usaremos um serviço chamado `ntp`, que podemos instalar a partir dos repositórios padrão do CentOS:

    sudo yum install ntp

Em seguida, você precisa iniciar o serviço para esta sessão. Também habilitaremos o serviço para que ele seja iniciado automaticamente sempre que o servidor for inicializado:

    sudo systemctl start ntpd
    sudo systemctl enable ntpd

Seu servidor agora corrigirá automaticamente o relógio do sistema para se alinhar aos servidores globais.

## Criar um Arquivo de Swap

Adicionar “swap” a um servidor Linux permite que o sistema mova as informações acessadas por um programa em execução com menos frequência da RAM para um local no disco. Acessar os dados armazenados no disco é muito mais lento do que acessar a RAM, mas ter o swap disponível pode ser a diferença entre o aplicativo permanecer ativo e a falha. Isso é especialmente útil se você planeja hospedar bancos de dados em seu sistema.

Conselhos sobre o melhor tamanho para um espaço de swap variam significativamente dependendo da fonte consultada. Geralmente, um valor igual ou o dobro da quantidade de RAM do seu sistema é um bom ponto de partida.

Aloque o espaço que você deseja usar para o seu arquivo de swap usando o utilitário `fallocate`. Por exemplo, se precisarmos de um arquivo de 4 Gigabytes, podemos criar um arquivo de swap localizado em `/swapfile` digitando:

    sudo fallocate -l 4G /swapfile

Depois de criar o arquivo, precisamos restringir o acesso a ele para que outros usuários ou processos não consigam ver o que é gravado lá:

    sudo chmod 600 /swapfile

Agora temos um arquivo com as permissões corretas. Para dizer ao nosso sistema para formatar o arquivo para swap, podemos digitar:

    sudo mkswap /swapfile

Agora, diga ao sistema que ele pode usar o arquivo de swap digitando:

    sudo swapon /swapfile

Nosso sistema está usando o arquivo de swap para esta sessão, mas precisamos modificar um arquivo de sistema para que nosso servidor faça isso automaticamente na inicialização. Você pode fazer isso digitando:

    sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

Com essa adição, seu sistema deve usar seu arquivo de swap automaticamente a cada inicialização.

## Para Onde Ir a partir Daqui?

Agora você tem uma configuração inicial muito decente para o seu servidor Linux. A partir daqui, existem alguns lugares que você pode ir. Primeiro, você pode querer tirar um instantâneo ou snapshot do seu servidor em sua configuração atual.

### Tirando um Snapshot da sua Configuração atual

Se você está satisfeito com sua configuração e deseja usar isso como uma base para futuras instalações, você pode tirar um snapshot do seu servidor através do painel de controle da DigitalOcean. A partir de outubro de 2016, os snapshots custam $0.05 por gigabyte por mês, com base na quantidade de espaço utilizado no sistema de arquivos.

Para fazer isso, desligue seu servidor pela linha de comando. Embora seja possível fazer um snapshot de um sistema em execução, o desligamento garante que os arquivos no disco estejam todos em um estado consistente:

    sudo poweroff

Agora, no painel de controle da DigitalOcean, você pode tirar um snapshot visitando a guia “Snapshots” do seu servidor:

![DigitalOcean snapshot](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/1404_optional_recommended/snapshots.png)

Depois de tirar seu snapshot, você poderá usar essa imagem como base para instalações futuras, selecionando o snapshot a partir da guia “My Snapshots” para imagens durante o processo de criação:

![DigitalOcean use snapshot](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/1404_optional_recommended/use_snapshot.png)

### Recursos Adicionais e Próximos Passos

A partir daqui, o seu caminho depende inteiramente do que você deseja fazer com o seu servidor. A lista de guias abaixo não é de forma alguma exaustiva, mas representa algumas das configurações mais comuns que os usuários recorrem:

- [Setting up a LAMP (Linux, Apache, MySQL/MariaDB, PHP) stack](how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7)
- [Setting up a LEMP (Linux, Nginx, MySQL/MariaDB, PHP) stack](how-to-install-linux-nginx-mysql-php-lemp-stack-on-centos-7)
- [Installing the WordPress CMS](how-to-install-wordpress-on-centos-7)
- [Installing Node.js](how-to-install-node-js-on-a-centos-7-server)
- [Installing Puppet to manage your infrastructure](how-to-install-puppet-in-standalone-mode-on-centos-7)

## Conclusão

Nesse ponto, você deve saber como configurar uma base sólida para seus novos servidores. Espero que você também tenha uma boa ideia para os próximos passos. Sinta-se à vontade para explorar o site para mais ideias que você pode implementar em seu servidor.
