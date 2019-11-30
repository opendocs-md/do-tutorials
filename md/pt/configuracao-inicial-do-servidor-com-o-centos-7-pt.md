---
author: Mitchell Anicas
date: 2019-08-02
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/configuracao-inicial-do-servidor-com-o-centos-7-pt
---

# Configuração Inicial do Servidor com o CentOS 7

### Introdução

Quando você cria inicialmente um novo servidor, existem alguns passos de configuração que você deve tomar no início como parte da configuração básica. Isto aumentará a segurança e a usabilidade do seu servidor e dará uma sólida fundação para as ações subsequentes.

## Passo Um — Efetuando login como Root

Para fazer login em seu servidor, você precisará saber o endereço IP público dele e a senha da conta do usuário “root”. Se você ainda não fez login no seu servidor, talvez queira seguir o primeiro tutorial desta série, [Como se Conectar ao seu Drolet com SSH](how-to-connect-to-your-droplet-with-ssh), que cobre este processo detalhadamente.

Se você ainda não está conectado ao seu servidor, vá em frente e faça login como o usuário `root` usando o seguinte comando (substitua a palavra realçada pelo endereço IP público do seu servidor):

    ssh root@ENDEREÇO_IP_DO_SERVIDOR

Conclua o processo de login aceitando o aviso sobre a autenticidade do host, se ele aparecer, e em seguida, fornecendo sua autenticação para o root (senha ou chave privada). Se esta for a primeira vez que você efetua login no servidor com uma senha, você também será solicitado a alterar a senha do root.

### Sobre o Root

O usuário root é o usuário administrativo em um ambiente Linux que possui privilégios muito amplos. Devido aos privilégios elevados da conta root, na verdade você é _desencorajado_ de utilizá-la regularmente. Isto é porque parte do poder inerente à conta root é a capacidade de realizar alterações muito destrutivas, mesmo por acidente.

O próximo passo é configurar uma conta de usuário alternativa com um escopo reduzido de poderes para o trabalho diário. Vamos ensiná-lo como obter aumento de privilégios durante os momentos em que você precisar deles.

## Passo Dois — Criando um Novo Usuário

Uma vez conectado como `root`, estamos preparados para adicionar uma nova conta de usuário que utilizaremos para efetuar logon de agora em diante.

Este exemplo cria um novo usuário chamado “demo”, mas você deve substituí-lo por um nome de usuário de sua escolha:

    adduser demo

Em seguida, atribua uma senha ao novo usuário (novamente, substitua “demo” pelo nome de usuário que você acabou de criar):

    passwd demo

Digite uma senha forte e repita-a novamente para verificá-la.

## Passo Três — Privilégios de Root

Agora, temos uma nova conta de usuário com privilégios regulares de conta. No entanto, às vezes podemos precisar fazer tarefas administrativas.

Para evitar de ter que desconectar nosso usuário regular e efetuar logon novamente com a conta de root, podemos configurar o que é conhecido como “super usuário” ou privilégios de root para nossa conta regular. Isso irá permitir nosso usuário regular executar comandos com privilégios administrativos colocando a palavra `sudo` antes de cada comando.

Para adicionar esses privilégios para o nosso novo usuário, precisamos adicionar o novo usuário ao grupo “wheel”. Por padrão, no CentOS 7, os usuários que pertencem ao grupo “wheel” estão autorizados a utilizar o comando `sudo`.

Como `root`, execute este comando para adicionar seu novo usuário ao grupo _wheel_ (substitua a palavra em destaque pelo seu novo usuário):

    gpasswd -a demo wheel

Agora seu usuário pode executar comandos com privilégios de super usuário! Para mais informações sobre como isso funciona, confira [nosso tutorial sobre sudoers](how-to-edit-the-sudoers-file-on-ubuntu-and-centos).

## Passo Quatro — Adicionar Autenticação de Chave Pública (Recomendado)

O próximo passo para proteger seu servidor é configurar a autenticação de chave pública para o novo usuário. Configurar isso aumentará a segurança do seu servidor, exigindo uma chave SSH privada para efetuar logon.

### Gerar um Par de Chaves

Se você ainda não tem um par de chaves SSH, que consiste em uma chave pública e uma privada, você precisa gerar um. Se você já tiver uma chave que deseje usar, vá para o passo _Copiar a Chave Pública_.

Para gerar um novo par de chaves, digite o seguinte comando no terminal da sua **máquina local** :

    ssh-keygen

Supondo que seu usuário local chame-se “localuser”, você verá uma saída parecida com a seguinte:

    ssh-keygen outputGenerating public/private rsa key pair.
    Enter file in which to save the key (/Users/localuser/.ssh/id_rsa):

Pressione `Enter` para aceitar este nome de arquivo e o caminho (ou digite um novo nome).

Em seguida, você será solicitado a inserir uma senha para proteger a chave. Você pode inserir uma senha ou deixar a senha em branco.

**Nota:** Se você deixar a senha em branco, poderá usar a chave privada para autenticação sem inserir uma senha. Se você inserir uma senha, precisará da chave privada _e_ da senha para efetuar logon. Proteger suas chaves com senhas é mais seguro, mas ambos os métodos têm seus usos e são mais seguros do que a autenticação básica de senha.

Isto gera uma chave privada, `id_rsa`, e uma chave pública, `id_rsa.pub`, no diretório `.ssh` do diretório home do _localuser_. Lembre-se de que a chave privada não deve ser compartilhada com ninguém que não deva ter acesso aos seus servidores!

### Copiar a Chave Pública

Depois de gerar um par de chaves SSH, você deverá copiar sua chave pública para o novo servidor. Vamos cobrir duas maneiras fáceis de fazer isso.

**Nota** : O método `ssh-copy-id` não funcionará na DigitalOcean se uma chave SSH for selecionada durante a criação do Droplet. Isso ocorre porque a DigitalOcean desativa a autenticação por senha se uma chave SSH estiver presente, e o `ssh-copy-id` depende da autenticação por senha para copiar a chave.

Se você estiver usando a DigitalOcean e selecionou uma chave SSH durante a criação do Droplet, use a opção 2.

### Opção 1: Usar ssh-copy-id

Se a sua máquina local tiver o script `ssh-copy-id` instalado, você poderá usá-lo para instalar sua chave pública para qualquer usuário para o qual tenha credenciais de logon.

Execute o script `ssh-copy-id` especificando o usuário e o endereço IP do servidor no qual você deseja instalar a chave, desta forma:

    ssh-copy-id demo@ENDEREÇO_IP_DO_SERVIDOR

Depois de fornecer sua senha no prompt, sua chave pública será adicionada ao arquivo `.ssh/authorized_keys` do usuário remoto. A chave privada correspondente agora pode ser usada para efetuar logon no servidor.

### Opção 2: Instalar Manualmente a Chave

Supondo que você gerou um par de chaves SSH usando o passo anterior, use o seguinte comando **no terminal da sua máquina local** para imprimir sua chave pública (`id_rsa.pub`):

    cat ~/.ssh/id_rsa.pub

Isso deve imprimir sua chave SSH pública, que deve ser algo como o seguinte:

    id_rsa.pub contentsssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBGTO0tsVejssuaYR5R3Y/i73SppJAhme1dH7W2c47d4gOqB4izP0+fRLfvbz/tnXFz4iOP/H6eCV05hqUhF+KYRxt9Y8tVMrpDZR2l75o6+xSbUOMu6xN+uVF0T9XzKcxmzTmnV7Na5up3QM3DoSRYX/EP3utr2+zAqpJIfKPLdA74w7g56oYWI9blpnpzxkEd3edVJOivUkpZ4JoenWManvIaSdMTJXMy3MtlQhva+j9CgguyVbUkdzK9KKEuah+pFZvaugtebsU+bllPTB0nlXGIJk98Ie9ZtxuY3nCKneB+KjKiXrAvXUPCI9mWkYS/1rggpFmu3HbXBnWSUdf localuser@machine.local

Selecione a chave pública e copie-a para a sua área de transferência.

#### Adicionar Chave Pública ao Novo Usuário Remoto

Para habilitar o uso da chave SSH para autenticação usando o novo usuário remoto, você deve adicionar a chave pública a um arquivo especial no diretório home do usuário.

**No servidor** , como usuário `root`, digite o seguinte comando para alternar para o novo usuário (substitua pelo seu próprio nome de usuário):

    su - demo

Agora você estará no diretório home do seu novo usuário.

Crie um novo diretório chamado `.ssh` e restrinja suas permissões com os seguintes comandos:

    mkdir .ssh
    chmod 700 .ssh

Agora abra um arquivo em _.ssh_ chamado `authorized_keys` com um editor de texto. Vamos uilizar o _vi_ para editar o arquivo:

    vi .ssh/authorized_keys

Entre no modo de insersão, pressionando `i`, em seguida insira sua chave pública (que deve estar em sua área de transferência) colando-a no editor. Agora pressione `ESC` para sair do modo de inserção.

Digite `:x` e depois `ENTER` para salvar e sair do arquivo.

Agora, restrinja as permissões do arquivo _authorized\_keys_ com este comando:

    chmod 600 .ssh/authorized_keys

Digite este comando _uma vez_ para retornar ao usuário `root`:

    exit

Agora você pode fazer logon SSH como seu novo usuário, usando a chave privada como autenticação.

Para ler mais sobre como funciona a autenticação de chaves, leia este tutorial: [Como Configurar a Autenticação Baseada em Chave SSH em um Servidor Linux](how-to-configure-ssh-key-based-authentication-on-a-linux-server).

## Passo Cinco — Configurar o Daemon SSH

Agora que temos nossa nova conta, podemos proteger um pouco mais o nosso servidor modificando sua configuração do daemon SSH (o programa que nos permite efetuar logon remotamente) para proibir o acesso SSH remoto à conta **root**.

Comece abrindo o arquivo de configuração com o seu editor de texto como root:

    vi /etc/ssh/sshd_config

Aqui, temos a opção de desativar o logon de root via SSH. Esta é geralmente uma configuração mais segura, já que agora podemos acessar nosso servidor através de nossa conta de usuário normal e escalar privilégios quando necessário.

Para desabilitar os logons remotos com o root, precisamos encontrar uma linha que se parece com essa:

/etc/ssh/sshd\_config (before)

    #PermitRootLogin yes

Dica: Para procurar por esta linha, digite `/PermitRoot` e depois `ENTER`. Isso deve trazer o cursor para o caractere “P” nessa linha.

Descomente a linha excluindo o símbolo “#” (pressione `Shift-x`).

Agora mova o cursor para o “yes” pressionando `c`.

Então, substitua “yes” pressionando `cw` e, em seguida, digite “no”. Pressione `ESC` quando tiver terminado de editar. Deve ficar assim:

/etc/ssh/sshd\_config (after)

    PermitRootLogin no

Desativar o logon remoto pelo root é altamente recomendado em todos os servidores!

Digite `:x` e depois `ENTER` para salvar e sair do arquivo.

### Recarregue o SSH

Agora que fizemos nossas alterações, precisamos reiniciar o serviço SSH para que ele use nossa nova configuração.

Digite isto para reiniciar o SSH:

    systemctl reload sshd

Agora, antes de sairmos do servidor, devemos **testar** nossa nova configuração. Não devemos desconectar até que possamos confirmar que novas conexões podem ser estabelecidas com sucesso.

Abra uma **nova** janela de terminal. Na nova janela, precisamos iniciar uma nova conexão com nosso servidor. Desta vez, em vez de usar a conta root, queremos usar a nova conta que criamos.

Para o servidor que configuramos acima, conecte-se usando este comando. Substitua sua própria informação onde for apropriado:

    ssh demo@SERVER_IP_ADDRESS

**Nota:** Se você estiver usando o PuTTY para se conectar aos seus servidores, certifique-se de atualizar o número da _porta_ da sessão para corresponder à configuração atual do seu servidor.

Você será solicitado a informar a senha do novo usuário que você configurou. Depois disso, você estará logado como seu novo usuário.

Lembre-se, se você precisar executar um comando com privilégios de root, digite “sudo” antes dele, desta forma:

    sudo comando_a_executar

Se tudo estiver bem, você pode sair de suas sessões digitando:

    exit

## Para Onde ir a partir daqui?

Neste ponto, você tem uma base sólida para seu servidor. Você pode instalar qualquer software que você precisar em seu servidor agora.

Se você não tiver certeza do que deseja fazer com seu servidor, confira o próximo tutorial desta série para [Etapas Adicionais Recomendadas para Novos Servidores CentOS 7](additional-recommended-steps-for-new-centos-7-servers). Ele cobre coisas como habilitar o `fail2ban` para reduzir a eficácia de ataques de força bruta, configurações básicas de firewall, NTP e arquivos de swap. Ele também fornece links para tutoriais que mostram como configurar aplicações web comuns.

Se você quer apenas explorar, dê uma olhada no restante da nossa [comunidade](https://digitalocean.com/community/articles) para encontrar mais tutoriais. Algumas ideias populares são Configurando uma [pilha LAMP](how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7) ou uma [pilha LEMP](how-to-install-linux-nginx-mysql-php-lemp-stack-on-centos-7), que permitirá que você hospede websites.
