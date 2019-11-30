---
author: Mitchell Anicas
date: 2016-12-12
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/configuracao-inicial-de-servidor-com-ubuntu-16-04-pt
---

# Configuração Inicial de servidor com Ubuntu 16.04

### Introdução

Quando você cria inicialmente um novo servidor Ubuntu 16.04, existem alguns passos de configuração que você deve tomar no início como parte da configuração básica. Isto aumentará a segurança e a usabilidade do seu servidor e dará uma sólida fundação para as ações subsequentes

## Passo Um - Login de Root

Para entrar no seu servidor, você precisa saber o endereço IP público do mesmo. Você também vai precisar da senha ou, se você instalou uma chave SSH para autenticação, a chave privada para a conta do usuário “root”. Se você já não estiver logado no sistema, você pode querer seguir esse tutorial nessa série, [How to Connect to Your Droplet with SSH](how-to-connect-to-your-droplet-with-ssh), que cobre esse processo em detalhes.

Se você ainda não estiver conectado em seu servidor, vá em frente e acesse como usuário `root` utilizando o seguinte comando (substitua a palavra marcada com o endereço IP público do seu servidor).

    ssh root@ip_do_seu_servidor

Complete o processo de login aceitando a mensagem de aviso de autenticidade do host, se ela aparecer, depois fornecendo sua senha de root (senha ou chave privada). Se é a primeira vez que faz logon em um servidor, com uma senha, você também será solicitado a alterar a senha de root.

### Sobre o Root

O usuário root é o usuário administrativo em um ambiente Linux que possui privilégios muito amplos. Devido aos privilégios elevados da conta root, você é realmente _desencorajado_ de utilizá-la regularmente. Isto é porque parte do poder inerente à conta root é a capacidade de realizar alterações muito destrutivas, mesmo por acidente.

O próximo passo é configurar uma conta de usuário alternativa com um escopo reduzido de poderes para o trabalho diário. Vamos ensiná-lo como obter aumento de privilégios durante os momentos em que você precisar deles.

## Passo Dois - Criar um Novo Usuário

Uma vez conectado como `root`, estamos preparados para adicionar uma nova conta de usuário que utilizaremos para efetuar logon de agora em diante.

Este exemplo cria um novo usuário chamado “sammy”, mas você deve substituí-lo por um nome de usuário de sua escolha:

    adduser sammy

Você será solicitado a responder algumas perguntas, começando com a senha da conta.

Entre com uma senha forte e, opcionalmente, preencha quaisquer informações adicionais se desejar. Isto não é requerido e você pode apenas teclar `ENTER` em qualquer campo que você quiser pular.

## Passo Três - Privilégios de Root

Agora, temos uma nova conta de usuário com privilégios básicos de conta. Contudo, podemos às vezes precisar fazer tarefas administrativas.

Para evitar de ter que desconectar nosso usuário normal e efetuar login novamente com a conta de root, podemos configurar o que é conhecido como “super usuário” ou privilégios de root para nossa conta normal. Isto irá permitir nosso usuário normal executar comandos com privilégios administrativos colocando a palavra `sudo` antes de cada comando.

Para adicionar privilégios para nosso novo usuário, precisamos adicionar o novo usuário ao grupo “sudo”. Por padrão, no Ubuntu 16.04, os usuários que pertencem ao grupo “sudo” estão autorizados a utilizar o comando `sudo`.

Como `root`, execute este comando para adicionar seu novo usuário ao grupo sudo (substitua a palavra em destaque pelo seu novo usuário):

    usermod -aG sudo sammy

Agora seu usuário pode executar comandos com privilégios de super usuário! Para mais informações sobre como isto funciona, verifique [este tutorial de sudoers](how-to-edit-the-sudoers-file-on-ubuntu-and-centos).

Se você quiser aumentar a segurança do seu servidor, siga o restante dos passos nesse tutorial.

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

**Nota** : Se você deixar a senha em branco, você será capaz de utilizar a chave privada para autenticação sem entrar com uma senha. Se você colocar uma senha, você precisará tanto da chave privada quanto da senha para efetuar login. A proteção de suas chaves com uma senha é mais segura, mas os dois métodos tem seus usos e são mais seguros do que a autenticação básica com senha somente.

Isto gera uma chave privada, `id_rsa`, e uma chave pública, `id_rsa.pub`, no diretório `.ssh` do diretório home de _localuser_. Lembre-se de que a chave privada não deve ser compartilhada com ninguém que não deva ter acesso ao seus servidores!

### Copiar a Chave Pública

Depois da geração do par de chaves SSH, você vai querer copiar sua chave pública para seu novo servidor. Vamos cobrir duas formas simples de se fazer isso.

#### Opção 1: Usar ssh-copy-id

Se a sua máquina local possui o script `ssh-copy-id` instalado, você pode usá-lo para instalar sua chave pública para qualquer usuário para o qual você tenha as credenciais de login.

Execute o script `ssh-copy-id` especificando o usuário e o endereço IP do servidor onde você deseja instalar a chave, como abaixo:

    ssh-copy-id sammy@ip_do_seu_servidor

Depois de fornecer sua senha no prompt, sua chave pública será adicionada ao arquivo `.ssh/authorized_keys` do usuário remoto. A chave privada correspondente pode agora ser utilizada para fazer login no servidor.

#### Opção 2: Instalar a chave manualmente

Assumindo que você gerou um par de chaves SSH utilizando o passo anterior, use o seguinte comando no terminal de sua **máquina local** para imprimir sua chave pública (`id_rsa.pub`):

    cat ~/.ssh/id_rsa.pub

Isto deve imprimir sua chave pública, que deve se parecer com algo como a seguir:

id\_rsa.pub contents

    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBGTO0tsVejssuaYR5R3Y/i73SppJAhme1dH7W2c47d4gOqB4izP0+fRLfvbz/tnXFz4iOP/H6eCV05hqUhF+KYRxt9Y8tVMrpDZR2l75o6+xSbUOMu6xN+uVF0T9XzKcxmzTmnV7Na5up3QM3DoSRYX/EP3utr2+zAqpJIfKPLdA74w7g56oYWI9blpnpzxkEd3edVJOivUkpZ4JoenWManvIaSdMTJXMy3MtlQhva+j9CgguyVbUkdzK9KKEuah+pFZvaugtebsU+bllPTB0nlXGIJk98Ie9ZtxuY3nCKneB+KjKiXrAvXUPCI9mWkYS/1rggpFmu3HbXBnWSUdf localuser@machine.local

Selecione a chave pública, e copie-a para sua área de transferência.

Para permitir o uso da chave SSH para autenticar-se como o novo usuário remoto, você deve adicionar a chave pública a um arquivo especial no diretório home do usuário.

**No servidor** , como usuário **root** , entre com o seguinte comando para chavear para o novo usuário (substitua pelo seu próprio nome de usuário):

    su - sammy

Agora você estará no diretório home do seu novo usuário.

Crie um novo diretório chamado `.ssh` e restrinja suas permissões com os seguintes comandos:

    mkdir ~/.ssh
    chmod 700 ~/.ssh

Agora abra um arquivo dentro de `.ssh` chamado `authorized_keys` com um editor de textos. Utilizaremos o `nano` para editar o arquivo:

    nano ~/.ssh/authorized_keys

Agora insira sua chave pública (que deve estar em sua área de transferência) colando-a dentro do editor.

Tecle `CTRL-X` para sair do arquivo, então `Y` para salvar as mudanças que você fez, depois tecle `ENTER` para confirmar o nome do arquvo.

Agora restrinja as permissões do arquivo _authorized\_keys_ com este comando:

    chmod 600 ~/.ssh/authorized_keys

Digite este comando **uma vez** para voltar ao usuário `root`:

    exit

Agora sua chave pública está instalada, e você pode utilizar as chaves SSH para fazer login como seu usuário.

Para ler mais sobre como a autenticação por chave funciona, leia este tutorial: [How To Configure SSH Key-Based Authentication on a Linux Server](how-to-configure-ssh-key-based-authentication-on-a-linux-server).

Agora, vamos mostrá-lo como aumentar a segurança do seu servidor através da desabilitação da autenticação por senha.

## Passo Cinco - Desabilitar a Autenticação por Senha (Recomendado)

Agora que o seu novo usuário pode utilizar chaves SSH para fazer logon, você pode aumentar a segurança do seu servidor desabilitando a autenticação por senha somente. Fazendo isso você irá restringir o acesso SSH ao seu servidor para autenticação por chave pública exclusivamente. Isto é, a única maneira de fazer logon em seu servidor (além do console) é possuir a chave privada que faz par com a chave pública que foi instalada.

**Nota** : Somente desative a autenticação por senha se você tiver instalado a chave pública para seu usuário como recomendado na seção anterior, passo quatro. Do contrário, você vai se bloquear fora do seu servidor!

Para desabilitar a autenticação por senha no seu servidor, siga esses passos.

Como **root** ou **seu novo usuário sudo** , abra a configuração do daemon do SSH:

    sudo nano /etc/ssh/sshd_config

Procure a linha que especifica `PasswordAuthentication`, descomente-a retirando o # que a precede, e depois altere seu valor para “no”. Deve se parecer com isto depois de você ter feito a alteração:

sshd\_config — Disable password authentication

    PasswordAuthentication no

Aqui estão duas outras configurações que são importantes para autenticação exclusiva por chaves e são definidas por padrão. Se você não tiver modificado esse arquivo anteriormente, você _não_ precisa alterar essas configurações:

sshd\_config — Important defaults

    PubkeyAuthentication yes
    ChallengeResponseAuthentication no

Quando tiver terminado de realizar suas alterações, salve e feche o arquivo utilizando o método que mostramos anteriormente (`CTRL-X`, depois `Y`, e depois `ENTER`).

Digite isto para recarregar o daemon SSH:

    sudo systemctl reload sshd

A autenticação por senha está desativada agora. Seu servidor agora está acessível somente com autenticação de chave SSH.

## Passo Seis - Teste de Logon

Agora, antes de você fazer logoff do servidor, você deve testar a sua nova configuração. Não se desconecte até que você confirme que consegue fazer logon com sucesso via SSH.

Em um novo terminal em sua **máquina local** , faça login no seu servidor utilizando a nova conta que criamos. Para isso, utilize esse comando (substitua pelo seu nome de usuário e endereço IP de servidor):

    ssh sammy@ip_do_seu_servidor

Se você adicionou a autenticação de chave pública para seu usuário, como descrito nos passos quatro e cinco, sua chave privada será utilizada como autenticação. Do contrário, você será solicitado a digitar a senha do seu usuário.

**Nota sobre a autenticação de chaves** : Se você criou seu par de chaves com uma senha, você será solicitado a digitar a senha para a sua chave. Do contrário, se o seu par não tem senha, você será conectado no servidor sem senha.

Uma vez que a autenticação é fornecida ao servidor, você estará conectado como seu novo usuário.

Lembre-se, se você precisar executar um comando com privilégios de root, digite “sudo” antes dele, como abaixo:

    sudo comando_a_executar

## Passo Sete - Configurar um Firewall Básico

Os servidores Ubuntu 16.04 podem utilizar o firewall UFW para garantir que somente as conexões para certos serviços sejam permitidas. Podemos configurar um firewall básico muito facilmente usando essa aplicação.

Diferentes aplicações podem registrar seus perfis com o UFW na instalação. Esses perfis permitem ao UFW gerenciar essas aplicações pelo nome. O OpenSSH, serviço que nos permite conectar ao nosso servidor agora, possui um perfil registrado com o UFW.

Você pode ver isso digitando:

    sudo ufw app list

    OutputAvailable applications:
      OpenSSH

Precisamos nos certificar de que o firewall permita conexões SSH de forma que possamos nos conectar da próxima vez. Podemos permitir essas conexões digitando:

    sudo ufw allow OpenSSH

Posteriormente, podemos ativar o firewall digitando:

    sudo ufw enable

Digite “y” e pressione ENTER para prosseguir. Você pode ver que as conexões SSH estão ainda permitidas digitando:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)

Se você instalar e configurar serviços adicionais, você precisará ajustar as configurações do firewall para permitir tráfego entrante. Você pode aprender algumas operações comuns do UFW [nesse guia](ufw-essentials-common-firewall-rules-and-commands).

## Para Onde ir a partir daqui?

Neste ponto, você tem uma base sólida para seu servidor. Você pode instalar qualquer software que você precisar em seu servidor agora.
