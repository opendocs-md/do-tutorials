---
author: Justin Ellingwood
date: 2015-05-26
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/configuracao-inicial-de-servidor-com-ubuntu-14-04-pt
---

# Configuração Inicial de servidor com Ubuntu 14.04

### Introdução

Quando você cria inicialmente um novo servidor Ubuntu 14.04, existem alguns passos de configuração que você deve tomar no início como parte da configuração básica. Isto aumentará a segurança e a usabilidade do seu servidor e dará uma sólida fundação para as ações subsequentes.

## Passo Um - Login de Root

Para entrar no seu servidor, você precisa saber o endereço IP público e a senha para a conta do “root”. Se você já não estiver logado no sistema, você pode querer seguir este tutorial nessa série, [How to Connect to Your Droplet with SSH](how-to-connect-to-your-droplet-with-ssh), que cobre esse processo em detalhes.

Se você ainda não estiver conectado em seu servidor, vá em frente e acesse como usuário `root` utilizando o seguinte comando (substitua a palavra marcada com o endereço IP público do seu servidor).

    ssh root@SERVER_IP_ADDRESS

Complete o processo de login aceitando a mensagem de aviso de autenticidade do host, se ela aparecer, depois fornecendo sua senha de root (senha ou chave privada). Se é a primeira vez que faz logon em um servidor, com uma senha, você também será pedido para alterar a senha de root.

### Sobre o Root

O usuário root é o usuário administrativo em um ambiente Linux que possui privilégios muito amplos. Devido aos privilégios elevados da conta root, você é realmente _desencorajado_ de utilizá-la regularmente. Isto é porque parte do poder inerente à conta root é a capacidade de realizar alterações muito destrutivas, mesmo por acidente.

O próximo passo é configurar uma conta de usuário alternativa com um escopo reduzido de poderes para o trabalho diário. Vamos ensiná-lo como obter aumento de privilégios durante os momentos em que você precisar deles.

## Passo Dois - Criar um Novo Usuário

Uma vez conectado como `root`, estamos preparados para adicionar uma nova conta de usuário que utilizaremos para efetuar login de agora em diante.

Este exemplo cria um novo usuário chamado “demo”, mas você deve substituí-lo por um nome de usuário de sua escolha:

    adduser demo

Você será solicitado a responder algumas perguntas, começando com a senha da conta.

Entre com uma senha forte e, opcionalmente, preencha quaisquer informações adicionais se desejar. Isto não é requerido e você pode apenas teclar “ENTER” em qualquer campo que você quiser pular.

## Passo Três - Privilégios de Root

Agora, temos uma nova conta de usuário com privilégios básicos de conta. Contudo, podemos às vezes precisar fazer tarefas administrativas.

Para evitar de ter que desconectar nosso usuário normal e efetuar login com a conta de root, podemos configurar o que é conhecido como “super usuário” ou privilégios de root para nossa conta normal. Isto irá permitir nosso usuário normal executar comandos com privilégios administrativos colocando a palavra `sudo` antes de cada comando.

Para adicionar privilégios para nosso novo usuário, precisamos adicionar o novo usuário ao grupo “sudo”. Por padrão, no Ubuntu 14.04, os usuários que pertencem ao grupo “sudo” estão autorizados a utilizar o comando `sudo`.

Como `root`, execute este comando para adicionar seu novo usuário ao grupo sudo (substitua a palavra em destaque pelo seu novo usuário):

    gpasswd -a demo sudo

Agora seu usuário pode executar comandos com privilégios de super usuário! Para mais informações sobre como isto funciona, verifique [este tutorial de sudoers](how-to-edit-the-sudoers-file-on-ubuntu-and-centos).

## Passo Quatro - Adicionar Autenticação de Chave Pública (Recomendado)

O próximo passo para a proteção do seu servidor é configurar uma chave pública de autenticação para seu novo usuário. Configurando isto, você estará aumentando a segurança do seu servidor requisitando uma chave SSH privada para efetuar login.

### Gerar um Par de Chaves

Se você já não tiver um par de chaves SSH, que consiste de uma chave pública e uma privada, você precisa gerar um.  
Se você já tiver uma chave que queira utilizar, pule o passo _Copiar a Chave Pública_.

Para gerar um novo par de chaves, digite o seguinte comando no terminal de sua **máquina local** (ou seja, seu computador):

    ssh-keygen

Assumindo que seu usuário local chame-se “localuser”, você verá uma saída que se parece com o seguinte:

    ssh-keygen output
    
    Generating public/private rsa key pair.
    Enter file in which to save the key (/Users/localuser/.ssh/id_rsa):

Tecle ENTER para aceitar este nome de arquivo e o path (ou entre com um novo nome).

Depois, será solicitado uma senha para proteger sua chave. Você pode digitar uma senha ou deixar a senha em branco.

**Nota** : Se você deixar a senha em branco, você será capaz de utilizar a chave privada para autenticação sem entrar com uma senha. Se você colocar uma senha, você precisará tanto da chave privada quanto da senha para efetuar login. A proteção de suas chaves com uma senha é mais segura, mas os dois métodos tem seus usos e são mais seguros do que a autenticação básica com senha.

Isto gera uma chave privada, `id_rsa`, e uma chave pública, `id_rsa.pub`, no diretório `.ssh` do diretório home de localuser. Lembre-se de que a chave privada não deve ser compartilhada com ninguém que não deva ter acesso ao seus servidores!

### Copiar a Chave Pública

Depois da geração do par de chaves SSH, você vai querer copiar sua chave pública para seu novo servidor.

Assumindo que você gerou um par de chaves SSH utilizando o passo anterior, use o seguinte comando no terminal de sua **máquina local** para imprimir sua chave pública (`id_rsa.pub`):

    cat ~/.ssh/id_rsa.pub

Isto deve imprimir sua chave pública, que deve se parecer com algo como a seguir:

    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBGTO0tsVejssuaYR5R3Y/i73SppJAhme1dH7W2c47d4gOqB4izP0+fRLfvbz/tnXFz4iOP/H6eCV05hqUhF+KYRxt9Y8tVMrpDZR2l75o6+xSbUOMu6xN+uVF0T9XzKcxmzTmnV7Na5up3QM3DoSRYX/EP3utr2+zAqpJIfKPLdA74w7g56oYWI9blpnpzxkEd3edVJOivUkpZ4JoenWManvIaSdMTJXMy3MtlQhva+j9CgguyVbUkdzK9KKEuah+pFZvaugtebsU+bllPTB0nlXGIJk98Ie9ZtxuY3nCKneB+KjKiXrAvXUPCI9mWkYS/1rggpFmu3HbXBnWSUdf localuser@machine.local

Selecione a chave pública, e copie-a para sua área de transferência.

### Adicionar a Chave Pública para o Novo Usuário Remoto

Para permitir o uso da chave SSH para autenticar-se como o novo usuário remoto, você deve adicionar a chave pública a um arquivo especial no diretório home do usuário.

**No servidor** , como usuário `root`, entre com o seguinte comando para chavear para o novo usuário (substitua pelo seu próprio nome de usuário):

    su - demo

Agora você estará no diretório home do seu novo usuário.

Crie um novo diretório chamado .ssh e restrinja suas permissões com os seguintes comandos:

    mkdir .ssh
    chmod 700 .ssh

Agora abra um arquivo dentro de `.ssh` chamado authorized\_keys com um editor de textos. Utilizaremos o nano para editar o arquivo:

    nano .ssh/authorized_keys

Agora insira sua chave pública (que deve estar em sua área de transferência) colando-a dentro do editor.

Tecle `CTRL-X` para sair do arquivo, então `Y` para salvar as mudanças que você fez, depois tecle `ENTER` para confirmar o nome do arquvo.

Agora restrinja as permissões do arquivo _authorized\_keys_ com este comando:

    chmod 600 .ssh/authorized_keys

Digite este comando uma vez para voltar ao usuário `root`:

    exit

Agora você pode efetuar login SSH como seu novo usuário, usando a chave privada como autenticação.

Para ler mais sobre como a autenticação por chave funciona, leia este tutorial: [How To Configure SSH Key-Based Authentication on a Linux Server](how-to-configure-ssh-key-based-authentication-on-a-linux-server).

## Passo Cinco - Configurar o SSH

Agora que temos nossa nova conta, podemos proteger nosso servidor um pouco mais modificando sua configuração SSH (o programa que nos permite efetuar login remotamente).

Comece abrindo o arquivo de configuração com o seu editor de textos como root:

    nano /etc/ssh/sshd_config

### Altere a Porta SSH (Opcional)

A primeira opção que você pode querer alterar é a porta na qual o SSH funciona. Procure a linha que se parece com isto:

    Port 22

Se alterarmos este número para algo entre 1025 e 65536, o serviço SSH em nosso servidor irá olhar por conexões em uma porta diferente. Isto às vezes ajuda porque os usuários não autorizados às vezes tentam entrar em seu servidor atacando o SSH. Se você alterar a localização, eles precisarão completar o passo extra de farejar isto.

Se você alterar este valor, você precisará se lembrar que seu servidor está executando na nova porta. Para este guia, vou alterar a porta para `4444` como demonstração. Isto significa que quando eu conectar, terei que dizer ao cliente SSH para utilizar esta porta nova e fora do padrão. Chegaremos a isso mais tarde. Por agora, modifique o valor para sua seleção:

    Port 4444

### Restringir o Login de Root

Em seguida, temos de encontrar a linha que se parece com isto:

    PermitRootLogin yes

Aqui, temos a opção de desabilitar o login de root via SSH. Esta é geralmente a configuração mais segura, uma vez que agora podemos acessar nosso servidor através de nossa conta de usuário normal, e escalar os privilégios quando necessário.

Você pode modificar este linha para “no”, como abaixo, se quiser desabilitar o login de root:

PermitRootLogin no

Desabilitar o login remoto de root é altamente recomendado em todo servidor!

Quando tiver terminado de realizar suas alterações, salve e feche o arquivo utilizando o método que mostramos anteriormente (`CTRL-X`, depois `Y`, e depois `ENTER`).

### Passo Seis - Recarregar o SSH

Agora que fizemos nossas alterações, precisamos reiniciar o serviço SSH para que ele utilize nossa nova configuração.

Digite isto para reiniciar o SSH:

    service ssh restart

Agora, antes de sair do servidor, devemos **testar** nossa nova configuração. Não queremos desconectar antes que possamos confirmar que as novas conexões podem ser estabelecidas com sucesso.

Abra uma `nova` janela de terminal. Na nova janela, precisamos iniciar uma nova conexão com o nosso servidor. Desta vez, em vez de usar a conta de root, queremos usar a nova conta que criamos.

Se você alterou o número da porta na qual o SSH está rodando, você precisará informar ao seu cliente sobre a nova porta também. Você pode fazer isto utilizando a sintaxe -p 4444, onde “4444” é a porta que você configurou.

Para o servidor que eu lhe mostrei como configurar acima, eu gostaria de me conectar usando este comando. Substitua as suas informações onde for apropriado:

    ssh -p 4444 demo@SERVER_IP_ADDRESS

**Nota** : Se você estiver utilizando o PuTTY para conectar aos seus servidores, certifique-se de atualizar o número de porta da sessão para coincidir com as configurações atuais do seu servidor.

Você vai ser solicitado a inserir a senha do novo usuário que você configurou. Depois disso, você estará logado como seu novo usuário.

Lembre-se, se você precisar executar um comando com privilégios de root, digite “sudo” antes dele, como abaixo:

    sudo command_to_run

Se tudo estiver bem, você pode sair de sua sessão digitando:

    exit

## Para Onde ir a partir daqui?

Neste ponto, você tem uma base sólida para seu servidor. Você pode instalar qualquer software que você precisar em seu servidor agora.

Se você não estiver certo do que fazer com seu servidor, verifique o próximo tutorial nesta série para [Passos Adicionais Recomendados para Novos Servidores Ubuntu 14.04](additional-recommended-steps-for-new-ubuntu-14-04-servers). Ele cobre coisas como configurações básicas de firewall, NTP, e arquivos de swap. Ele também fornece links para tutoriais que mostram como configurar aplicações web básicas. Você também pode querer verificar [este guia](how-to-install-and-use-fail2ban-on-ubuntu-14-04) para aprender como habilitar `fail2ban` para reduzir a efetividade de ataques de força bruta.

Se você quer apenas explorar, dê uma olhada no resto da nossa [comunidade](https://digitalocean.com/community/articles) para encontrar mais tutoriais. Algumas ideias populares são a configuração de uma [pilha LAMP](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-14-04) ou uma [pilha LEMP](https://www.digitalocean.com/community/articles/how-to-install-linux-nginx-mysql-php-lemp-stack-on-ubuntu-14-04), que irá permitir a você hospedar websites.
