---
author: Justin Ellingwood
date: 2018-10-09
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-e-configurar-o-gitlab-no-ubuntu-16-04-pt
---

# Como Instalar e Configurar o GitLab no Ubuntu 16.04

### Introdução

O GitLab CE, ou Community Edition, é uma aplicação open source usada principalmente para hospedar repositórios Git, com recursos adicionais relacionados ao desenvolvimento, como rastreamento de problemas. Ele é projetado para ser hospedado usando a sua própria infraestrutura, e fornece flexibilidade na implantação como um repositório interno para sua equipe de desenvolvimento, publicamente como uma forma de interagir com usuários, ou até mesmo aberto como forma de os colaboradores hospedarem seus próprios projetos.

O projeto do GitLab torna relativamente simples a configuração de uma instância do GitLab em seu próprio hardware com um mecanismo de fácil instalação. Neste guia vamos cobrir como instalar e configurar o GitLab em um servidor Ubuntu 16.04.

## Pré-Requisitos

Este tutorial irá assumir que você tem acesso a um novo servidor Ubuntu 16.04. [Os requisitos de hardware publicados do GitLab](http://docs.gitlab.com/ee/install/requirements.html#hardware-requirements) recomendam a utilização de um servidor com:

- 2 núcleos
- 4GB de RAM

Embora você possa substituir algum espaço de swap por RAM, isso não é recomendado. Para este guia assumiremos que você tem os recursos acima, no mínimo.

Para começar, você vai precisar de um usuário não-root com acesso `sudo` configurado no servidor. É também uma boa ideia configurar um firewall básico para fornecer uma camada adicional de segurança. Você pode seguir os passos em nosso tutorial [Configuração Inicial de servidor com Ubuntu 16.04](configuracao-inicial-de-servidor-com-ubuntu-16-04-pt) para obter essa configuração.

Quando tiver satisfeito os pré-requisitos acima, continue para iniciar o procedimento de instalação.

## Instalando as Dependências

Antes que possamos instalar o GitLab propriamente dito, é importante instalar alguns dos softwares que ele aproveita durante a instalação e que ele usa de forma contínua. Felizmente, todos os softwares necessários podem ser facilmente instalados a partir dos repositórios padrão do Ubuntu.

Já que esta é a nossa primeira vez usando o `apt` durante esta sessão, podemos atualizar o índice de pacotes local e depois instalar as dependências digitando:

    sudo apt-get update
    sudo apt-get install ca-certificates curl openssh-server postfix

Você provavelmente já terá alguns desses softwares instalados. Para a instalação do `postfix`, selecione **Internet Site** quando solicitado. Na próxima tela, entre com o nome de domínio do seu servidor ou seu endereço IP para configurar de que forma o sistema enviará e-mail.

## Instalando o GitLab

Agora que as dependências estão instaladas, podemos instalar o GitLab. Este é um processo direto que utiliza um script de instalação para configurar seu sistema com os repositórios do GitLab.

Vá para o diretório `/tmp` e então baixe o script de instalação:

    cd /tmp
    curl -LO https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh

Fique à vontade para examinar o script baixado para assegurar-se de que você esteja confortável com as ações que ele irá tomar. Você pode encontrar uma versão hospedada do script [aqui](https://packages.gitlab.com/gitlab/gitlab-ce/install):.

    less /tmp/script.deb.sh

Quando estiver satisfeito com a segurança do script, execute o instalador:

    sudo bash /tmp/script.deb.sh

Este script irá configurar seu servidor para utilizar os repositórios mantidos pelo GitLab. Isso lhe permite gerenciar o GitLab com as mesmas ferramentas de gerenciamento de pacotes que você usa para seus outros pacotes de sistema. Quando estiver completo, você pode instalar a aplicação real do GitLab com o `apt`:

    sudo apt-get install gitlab-ce

Isto irá instalar os componentes necessários em seu sistema.

## Ajustando as Regras de Firewall

Antes de configurar o GitLab, você precisará garantir que suas regras de firewall são permissivas o suficiente para permitir o tráfego web. Se você seguiu o guia vinculado nos pré-requisitos, você terá um firewall `ufw` ativado.

Veja o status atual do seu firewall ativo digitando:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)

Como você pode ver, as regras atuais permitem o tráfego SSH, mas o acesso a outros serviços está restrito. Como o Gitlab é uma aplicação web, devemos permitir acesso HTTP entrante. Se você tiver um nome de domínio associado com o seu servidor GitLab, o GitLab pode também solicitar e ativar um certificado gratuito TLS/SSL a partir do [projeto Let’s Encrypt](https://letsencrypt.org/) para proteger a instalação. Também queremos permitir o acesso HTTPS nesse caso.

um vez que o protocolo de mapeamento de portas para HTTP e HTTPS está disponível no arquivo `/etc/services`, podemos permitir tais tráfegos pelo nome. Se você ainda não ativou o tráfego do OpenSSH, permita também esse tráfego agora:

    sudo ufw allow http
    sudo ufw allow https
    sudo ufw allow OpenSSH

Se você verificar com o comando `ufw status` novamente, você deverá ver o acesso configurado para no mínimo esses dois serviços:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    80 ALLOW Anywhere                  
    443 ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    80 (v6) ALLOW Anywhere (v6)             
    443 (v6) ALLOW Anywhere (v6)

A saída acima indica que a interface web do GitLab estará acessível assim que configurarmos a aplicação.

## Editando o Arquivo de Configuração do GitLab

Antes de você poder usar a aplicação, você precisa atualizar um arquivo de configuração e executar um comando de reconfiguração. Primeiro, abra o arquivo de configuração do GitLab:

    sudo nano /etc/gitlab/gitlab.rb

Perto do topo está a linha de configuração `external_url`. Atualize-a para corresponder ao seu próprio domínio ou endereço IP. Se você tem um domínio, altere o `http` para `https` para que o GitLab redirecione automaticamente os usuários para o site protegido pelo certificado do Let´s Encrypt que estaremos solicitando.

/etc/gitlab/gitlab.rb

    
    # If your GitLab server does not have a domain name, you will need to use an IP
    # address instead of a domain and keep the protocol as `http`.
    external_url 'https://seu_dominio'

Em seguida, se seu servidor GitLab tem um nome de domínio, pesquise o arquivo pela configuração `letsencrypt['enable']`. Descomente a linha e defina-a para `true`. Isso dirá ao GitLab para solicitar um certificado Let´s Encrypt para seu domínio GitLab e configurar a aplicação para servir o tráfego com ele.

Abaixo disso, procure a configuração `letsencrypt['contact_emails']`. Esta configuração define uma lista de endereços de e-mail que o projeto Let´s Encrypt pode utilizar para lhe contatar se houver problemas com seu domínio. É uma boa idéia descomentar e preencher isso também para que você saiba de quaisquer problemas:

/etc/gitlab/gitlab.rb

    
    letsencrypt['enable'] = true
    letsencrypt['contact_emails'] = ['sammy@seu_domínio.com']

Salve e feche o arquivo. Agora, execute o seguinte comando para reconfigurar o GitLab:

    sudo gitlab-ctl reconfigure

Isso irá inicializar o GitLab utilizando as informações que ele pode encontrar sobre seu servidor. Esse é um processo completamente automatizado, portanto você não vai ter que responder a nenhuma solicitação. Se você ativou a integração com o Let´s Encrypt, um certificado deve ser configurado para o seu domínio.

## Realizando a Configuração Inicial Através da Interface web

Agora que o GitLab está executando e o acesso está permitido, podemos realizar algumas configurações iniciais da aplicação através da interface web.

### Efetuando o Login pela Primeira Vez

Visite o nome de domínio do seu servidor GitLab em seu navegador:

    http://domínio_gitlab_ou_IP

Se você ativou o Let’s Encrypt e usou `https` em seu `external_url`, você deve ser redirecionado para uma conexão HTTPS segura.

Em sua primeira visita, você deve ver uma solicitação inicial para definir uma senha para a conta administrativa:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/gitlab_initial_password2.png)

Na solicitação inicial de senha, forneça e confirme uma senha segura para a conta administrativa. Clique no botão **Change your password** quando tiver terminado.

Você será redirecionado à página convencional de login do GitLab:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/gitlab_first_signin2.png)

Aqui, você pode efetuar o login com a senha que você acabou de definir. As credenciais são:

- Username: **root**

- Password: [a senha que você definiu]

Entre com esses valores nos campos para os usuários existentes e clique no botão **Sign in**. Você será autenticado no aplicativo e levado a uma página de entrada que solicitará que você comece a adicionar projetos:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/landing_page2.png)

Agora você pode fazer algumas mudanças simples para configurar o GitLab da maneira que você quiser.

### Ajustando suas Configurações de Perfil

Uma das primeiras coisas que você deve fazer após uma nova instalação é colocar o seu perfil na melhor forma. O GitLab seleciona alguns padrões razoáveis, mas estes geralmente não são apropriados quando você começa a usar o software.

Para fazer as modificações necessárias, clique no ícone do usuário no canto superior direito da interface. No menu suspenso exibido, selecione **Settings** :

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/profile_settings_button2.png)

Você será levado para a seção de perfil ou **Profile** nas suas configurações:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/profile_settings2.png)

Ajuste **Name** e **Email** trocando “Administrator” e “[admin@example.com](mailto:admin@example.com)” para algo mais adequado. O nome que você selecionou será mostrado para os outros usuários, equanto o e-mail será utilizado para detecção padrão do avatar, notificações, ações no Git através da interface, etc.

Clique no botão **Update Profile setting** na parte inferior quando terminar:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/update_profile_settings_button2.png)

Um e-mail de confirmação será enviado ao endereço que você forneceu.  
Siga as instruções no e-mail para confirmar sua conta para que você possa começar a utilização do GitLab.

### Alterando o Nome da Sua Conta

A seguir, clique no item **Account** na barra de menu à esquerda:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/account_menu_item2.png)

Aqui, você pode encontrar seu token de API privada ou configurar a autenticação de dois fatores. Contudo, a funcionalidade a qual estamos interessados no momento é a seção **Change username**.

Por padrão, à primeira conta administrativa é dado o nome **root**. Como esse é um nome conhecido de conta, é mais seguro alterar esse nome para um diferente. Você ainda terá privilégios administrativos; a única coisa que irá mudar é o nome:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/change_username2.png)

Clique no botão **Update username** para fazer a alteração:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/update_username_button2.png)

Na próxima vez que você fizer o login no GitLab, lembre-se de utilizar seu novo nome de usuário.

### Adicionando uma Chave SSH à sua Conta

Em muitos casos, você irá querer usar chaves SSH com Git para interagir com seus projetos GitLab. Para fazer isso, você precisa adicionar sua chave pública à sua conta do GitLab.

Se você já tem um par de chaves SSH criado em seu **computador local** , você geralmente pode ver a chave pública digitando:

    cat ~/.ssh/id_rsa.pub

Você deverá ver um grande pedaço de texto, como este:

    Outputssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMuyMtMl6aWwqBCvQx7YXvZd7bCFVDsyln3yh5/8Pu23LW88VXfJgsBvhZZ9W0rPBGYyzE/TDzwwITvVQcKrwQrvQlYxTVbqZQDlmsC41HnwDfGFXg+QouZemQ2YgMeHfBzy+w26/gg480nC2PPNd0OG79+e7gFVrTL79JA/MyePBugvYqOAbl30h7M1a7EHP3IV5DQUQg4YUq49v4d3AvM0aia4EUowJs0P/j83nsZt8yiE2JEYR03kDgT/qziPK7LnVFqpFDSPC3MR3b8B354E9Af4C/JHgvglv2tsxOyvKupyZonbyr68CqSorO2rAwY/jWFEiArIaVuDiR9YM5 sammy@mydesktop

Copie esse texto e volte para a página de configurações do perfil na interface web do gitLab.

Se, em vez disso, você receber uma mensagem parecida como isto, você ainda não tem um par SSH configurado em sua máquina:

    Outputcat: /home/sammy/.ssh/id_rsa.pub: No such file or directory

Se for o caso, você pode criar um par de chaves SSH digitando:

    ssh-keygen

Aceite os padrões e, opcionalmente, forneça uma senha para proteger a chave localmente:

    OutputGenerating public/private rsa key pair.
    Enter file in which to save the key (/home/sammy/.ssh/id_rsa):
    Enter passphrase (empty for no passphrase):
    Enter same passphrase again:
    Your identification has been saved in /home/sammy/.ssh/id_rsa.
    Your public key has been saved in /home/sammy/.ssh/id_rsa.pub.
    The key fingerprint is:
    SHA256:I8v5/M5xOicZRZq/XRcSBNxTQV2BZszjlWaIHi5chc0 sammy@gitlab.docsthat.work
    The key's randomart image is:
    +---[RSA 2048]----+
    | ..%o==B|
    | *.E =.|
    | . ++= B |
    | ooo.o . |
    | . S .o . .|
    | . + .. . o|
    | + .o.o ..|
    | o .++o . |
    | oo=+ |
    +----[SHA256]-----+

Depois de ter isso, você pode exibir sua chave pública como acima, digitando:

    cat ~/.ssh/id_rsa.pub

    Outputssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMuyMtMl6aWwqBCvQx7YXvZd7bCFVDsyln3yh5/8Pu23LW88VXfJgsBvhZZ9W0rPBGYyzE/TDzwwITvVQcKrwQrvQlYxTVbqZQDlmsC41HnwDfGFXg+QouZemQ2YgMeHfBzy+w26/gg480nC2PPNd0OG79+e7gFVrTL79JA/MyePBugvYqOAbl30h7M1a7EHP3IV5DQUQg4YUq49v4d3AvM0aia4EUowJs0P/j83nsZt8yiE2JEYR03kDgT/qziPK7LnVFqpFDSPC3MR3b8B354E9Af4C/JHgvglv2tsxOyvKupyZonbyr68CqSorO2rAwY/jWFEiArIaVuDiR9YM5 sammy@mydesktop

Copie o bloco de texto exibido e volte para as configurações do perfil na interface web do GitLab.

Clique no item **SSH keys** no menu à esquerda:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/ssh_keys_menu_item2.png)

No espaço fornecido cole a chave pública que você copiou da sua máquina local. Dê a ela um título descritivo, e clique no botão **Add key** :

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/add_ssh_key2.png)

Agora você deve conseguir gerenciar seus projetos e repositórios do GitLab a partir de sua máquina local sem ter que fornecer suas credenciais de conta do GitLab.

## Restringindo ou Desabilitando Inscrições Públicas (Opcional)

Você deve ter notado que é possível que alguém se inscreva para uma conta quando visitar a página de destino da sua instância do GitLab. Isso pode ser o que você deseja se estiver hospedando um projeto público. No entanto, muitas vezes, configurações mais restritivas são desejáveis.

Para começar, vá até a área administrativa clicando no ícone de **chave inglesa** na barra de menu principal na parte superior da página:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/admin_area_button2.png)

Na página seguinte, você pode ver uma visão geral da sua instância do GitLab como um todo. Para ajustar as configurações, clique no item **Settings** na parte inferior do menu à esquerda.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/admin_settings_button2.png)

Você será levado para as configurações globais da sua instância do GitLab. Aqui, você pode ajustar várias configurações que afetam se novos usuários podem se inscrever e qual será o nível de acesso deles.

### Desabilitando Inscrições

Se você deseja desabilitar completamente as inscrições (você ainda pode criar manualmente as contas para novos usuários), desça até a seção **Sign-up Restrictions**.

Desmarque a caixa de seleção **Sign-up enabled** :

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/deselect_sign-ups_enabled.png)

Role para baixo até o final e clique no botão **Save** :

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/save_settings_button2.png)

A seção de inscrição agora deve estar removida da página inicial do GitLab.

### Restringindo Inscrições Por Domínio

Se você estiver usando o GitLab como parte de uma organização que fornece endereços de e-mail associados a um domínio, poderá restringir as inscrições por domínio em vez de desativá-las completamente.

Na seção **Sign-up Restrictions** , primeiro selecione a caixa **Send confirmation email on sign-up** permitindo somente que os usuários façam login depois de confirmarem seus e-mails.

Em seguida, adicione o seu domínio ou domínios à caixa **Whitelisted domains for sign-ups** , uma por linha. Você pode utilizar o asterisco “\*” para especificar domínios curinga.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/restrict_sign-ups_by_domain.png)

Role para baixo até o final e clique no botão **Salvar** :

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/save_settings_button2.png)

A seção de inscrição agora deve estar removida da página inicial do GitLab.

### Restringindo a Criação de Projetos

Por padrão, novos usuários podem criar até 10 projetos. Se você deseja permitir que novos usuários externos tenham visibilidade e participação, mas quer restringir seus acessos ao criar novos projetos, você pode fazer isto na seção **Account and Limit Settings**.

Lá dentro, você pode alterar o limite padrão de projetos em **Default projects limit** para 0 para desativar completamente a criação de projetos por novos usuários.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/set_projects_to_zero.png)

Novos usuários ainda podem ser adicionados a projetos manualmente e terão acesso a projetos internos ou públicos criados por outros usuários.

Role para baixo até o final e clique no botão **Salvar** :

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/gitlab_install_1604/save_settings_button2.png)

Agora, novos usuários poderão criar contas, mas não poderão criar projetos.

## Criando um Cron Job para Renovar Automaticamente os Certificados Let’s Encrypt

Por padrão, os certificados Let’s Encrypt são válidos por 90 dias. Se você ativou o Let’s Encrypt para o seu domínio do GitLab anteriormente, você precisará garantir que seus certificados sejam renovados regularmente para evitar interrupções no serviço. O GitLab fornece o comando `gitlab-ctl renew-le-certs` para solicitar novos certificados quando seus ativos atuais se aproximarem da expiração.

Para automatizar este processo, podemos criar um cron job para executar automaticamente este comando regularmente. O comando somente irá renovar o certificado quando ele estiver perto da expiração, para que possamos executá-lo com segurança regularmente

Para começar, crie e abra um arquivo em `/etc/cron.daily/gitlab-le` em seu editor de textos:

    sudo nano /etc/cron.daily/gitlab-le

Dentro dele, cole o seguinte script:

/etc/cron.daily/gitlab-le

    
    #!/bin/bash
    
    set -e
    
    /usr/bin/gitlab-ctl renew-le-certs > /dev/null

Salve e feche o arquivo quando tiver terminado.

Marque o arquivo como executável digitando:

    sudo chmod +x /etc/cron.daily/gitlab-le

Agora, o GitLab deve verificar automaticamente todos os dias se seu certificado Let’s Encrypt precisa ser renovado. Em caso afirmativo, o comando renovará o certificado automaticamente.

## Conclusão

Agora você deve ter uma instância do GitLab em funcionamento hospedada em seu próprio servidor. Você pode começar a importar ou criar novos projetos e configurar o nível apropriado de acesso para sua equipe. O GitLab está regularmente adicionando recursos e atualizando sua plataforma, por isso confira a página inicial do projeto para se manter atualizado sobre quaisquer melhorias ou avisos importantes.

_Por Justin Ellingwood_
