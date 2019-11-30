---
author: Hanif Jetha
date: 2018-05-10
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-configurar-chaves-ssh-no-ubuntu-18-04-pt
---

# Como Configurar Chaves SSH no Ubuntu 18.04

### Introdução

SSH, ou shell seguro, é um protocolo criptografado usado para administrar e comunicar com servidores. Ao trabalhar com um servidor Ubuntu, é provável que você passe a maior parte do tempo em uma sessão de terminal, conectado ao seu servidor através do SSH.

Neste guia, vamos focar na configuração de chaves SSH para uma instalação genérica do Ubuntu 18.04. Chaves SSH fornecem uma forma fácil e segura de efetuar login em seu servidor e é recomendado para todos os usuários.

## Passo 1 — Criar o Par de Chaves RSA

O primeiro passo é criar um par de chaves na máquina cliente (normalmente o seu computador):

    ssh-keygen

Por padrão o `ssh-keygen` irá criar um par de chaves RSA de 2048 bits, que é seguro o suficiente para a maioria dos casos (você pode opcionalmente passar o flag `-b 4096` para criar uma chave mais extensa de 4096 bits.

Após digitar o comando, você deve ver a seguinte saída:

    OutputGenerating public/private rsa key pair.
    Enter file in which to save the key (/sua_pasta_home/.ssh/id_rsa):

Pressione enter para salvar o par de chaves dentro do subdiretório `.ssh/` em sua pasta home, ou especifique um caminho alternativo.

Se você tiver gerado um par de chaves SSH anteriormente, você pode ver o seguinte prompt:

    Output/home/sua_pasta_home/.ssh/id_rsa already exists.
    Overwrite (y/n)?

Se você escolher sobrepor a chave no disco, você **não** poderá autenticar usando a chave anterior mais. Seja bastante cuidadoso quando selecionar yes, uma vez que esse é um processo destrutivo e que não pode ser revertido.

Você deve então ver o seguinte prompt:

    OutputEnter passphrase (empty for no passphrase):

Aqui você pode opcionalmente entrar com uma frase de segurança, o que é altamente recomendado. A frase de segurança adiciona uma camada a mais de segurança para prevenir usuários não autorizados de efetuar login. Para aprender mais sobre segurança, consulte nosso tutorial sobre [Como Configurar Autenticação SSH Baseada em Chaves em um Servidor Linux](how-to-configure-ssh-key-based-authentication-on-a-linux-server).

Então você deve ver a seguinte saída:

    OutputYour identification has been saved in /sua_pasta_home/.ssh/id_rsa.
    Your public key has been saved in /sua_pasta_home/.ssh/id_rsa.pub.
    The key fingerprint is:
    a9:49:2e:2a:5e:33:3e:a9:de:4e:77:11:58:b6:90:26 username@remote_host
    The key's randomart image is:
    +--[RSA 2048]----+
    | ..o |
    | E o= . |
    | o. o |
    | .. |
    | ..S |
    | o o. |
    | =o.+. |
    |. =++.. |
    |o=++. |
    +-----------------+

Agora você tem uma chave pública e uma privda que você poderá utilizar para autenticar. O próximo passo é colocar a chave pública no seu servidor para que você possa usar a autenticação SSH baseada em chaves para eftuar login.

## Passo 2 — Copiar a Chave Pública para o Servidor Ubuntu

A forma mais rápida de copiar sua chave pública para o host Ubuntu é utilizar um utilitário chamado `ssh-copy-id`. Devido à sua simplicidade, este método é altamente recomendado se estiver disponível. Se você não tem o `ssh-copy-id` disponível em sua máquina cliente, você pode usar um dos dois métodos alternativos fornecidos nessa sessão (copiando via SSH baseado em senha, ou copiando manualmente a chave).

### Copiando a Chave Pública Usando o `ssh-copy-id`

A ferramenta `ssh-copy-id` está incluída por padrão em vários sistemas operacionais, assim você deve tê-lo disponível em seu sistema local. Para este método funcionar, você já deve ter o acesso SSH baseado em senha para o seu servidor.

Para usar o utilitário, você precisa simplesmente especificar o host remoto que você gostaria de se conectar e a conta de usuário a qual você tem acesso SSH por senha. Esta é a conta para a qual a sua chave pública será copiada.

A sintaxe é:

    ssh-copy-id nome_de_usuário@host_remoto

Você pode ver a segunte mensagem:

    OutputThe authenticity of host '203.0.113.1 (203.0.113.1)' can't be established.
    ECDSA key fingerprint is fd:fd:d4:f9:77:fe:73:84:e1:55:00:ad:d6:6d:22:fe.
    Are you sure you want to continue connecting (yes/no)? yes

Isto significa que seu computador local não reconhece o host remoto. Isto ocorrerá na primeira vez que você se conectar a um novo host. Digite “yes” e pressione `ENTER`para continuar.

Após isso, o utilitário irá escanear sua conta local pela chave `id_rsa.pub` que criamos mais cedo. Quando ele encontra a chave, ele irá solicitar a você a senha da conta de usuário remota:

    Output/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
    /usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
    nome_de_usuário@203.0.113.1's password:

Digite a senha (sua digitação não será mostrada por questões de segurança) e pressione `ENTER`. O utilitário irá conectar-se à conta no host remoto utilizando a senha que você forneceu. Então, ele irá copiar o conteúdo da sua chave `~/.ssh/id_rsa.pub` dentro de um arquivo no diretório `~/.ssh` do home da conta remota chamado `authorized_keys`.

Você deve ver a seguinte saída:

    OutputNumber of key(s) added: 1
    
    Now try logging into the machine, with: "ssh 'nome_de_usuário@203.0.113.1'"
    and check to make sure that only the key(s) you wanted were added.

Neste ponto, sua chave `id_rsa.pub` foi carregada para a conta no host remoto. Você pode continuar com o [Passo 3](how-to-set-up-ssh-keys-on-ubuntu-1604#step-3-%E2%80%94-authenticate-to-ubuntu-server-using-ssh-keys).

### Copiando a Chave Pública Usando SSH

Se você não tem o `ssh-copy-id` disponível, mas tem o acesso SSH baseado em senha a uma conta em seu servidor, você pode carregar suas chaves utilizando um método SSH convencional.

Podemos fazer isso usando o comando `cat` para ler o conteúdo da chave pública em seu computador local e fazer um redirecionamento disso através de uma conexão SSH ao servidor remoto.

Do outro lado, podemos nos certificar que o diretório `~/.ssh` existe e tem as permissões corretas sob a conta que estamos utilizando.

Podemos então, dar saída do conteúdo que redirecionamos para dentro de um arquivo chamado `authorized_keys` dentro desse diretório. Utilizaremos o símbolo de redirecionamento `>>` para acrescentar o conteúdo em vez de sobrescrevê-lo. Isso nos permitirá adicionar chaves sem a destruição das chaves previamente adicionadas.

O comando completo se parece com isso:

    cat ~/.ssh/id_rsa.pub | ssh nome_de_usuário@host_remoto "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod -R go= ~/.ssh && cat >> ~/.ssh/authorized_keys"

Você pode ver a seguinte mensagem:

    OutputThe authenticity of host '203.0.113.1 (203.0.113.1)' can't be established.
    ECDSA key fingerprint is fd:fd:d4:f9:77:fe:73:84:e1:55:00:ad:d6:6d:22:fe.
    Are you sure you want to continue connecting (yes/no)? yes

Isto significa que seu computador local não reconhece o host remoto. Isto ocorrerá na primeira vez que você se conectar a um novo host. Digite “yes” e pressione `ENTER`para continuar.

Depois, você deverá ser solicitado a entrar com a senha da conta do usuário remoto:

    Outputnome_de_usuário@203.0.113.1's password:

Depois de entrar com sua senha, o conteúdo da sua chave `id_rsa.pub` será copiado para o final do arquivo `authorized_keys` da conta de usuário remota. Continue com o [Passo 3](how-to-set-up-ssh-keys-on-ubuntu-1604#step-3-%E2%80%94-authenticate-to-ubuntu-server-using-ssh-keys) se isso foi bem sucedido.

### Copiando a Chave Pública Manualmente

Se você não tem acesso SSH ao servidor baseado em senha disponível, você terá que completar o processo acima manualmente.

Vamos acrescentar maualmente o conteúdo do seu arquivo `id_rsa.pub` ao arquivo `~/.ssh/authorized_keys` na sua máquina remota.

Para mostrar o conteúdo da sua chave `id_rsa.pub`, digite isto em seu computador local:

    cat ~/.ssh/id_rsa.pub

Você verá o conteúdo da chave, que deverá se parecer com isto:

    Outputssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqql6MzstZYh1TmWWv11q5O3pISj2ZFl9HgH1JLknLLx44+tXfJ7mIrKNxOOwxIxvcBF8PXSYvobFYEZjGIVCEAjrUzLiIxbyCoxVyle7Q+bqgZ8SeeM8wzytsY+dVGcBxF6N4JS+zVk5eMcV385gG3Y6ON3EG112n6d+SMXY0OEBIcO6x+PnUSGHrSgpBgX7Ks1r7xqFa7heJLLt2wWwkARptX7udSq05paBhcpB0pHtA1Rfz3K2B+ZVIpSDfki9UVKzT8JUmwW6NNzSgxUfQHGwnW7kj4jp4AT0VZk3ADw497M2G/12N0PPB5CnhHf7ovgy6nL1ikrygTKRFmNZISvAcywB9GVqNAVE+ZHDSCuURNsAInVzgYo9xgJDW8wUw2o8U77+xiFxgI5QSZX3Iq7YLMgeksaO4rBJEa54k8m5wEiEE1nUhLuJ0X/vh2xPff6SQ1BL/zkOhvJCACK6Vb15mDOeCSq54Cr7kvS46itMosi/uS66+PujOO+xt/2FWYepz6ZlN70bRly57Q06J+ZJoc9FfBCbCyYH7U/ASsmY095ywPsBo1XQ9PqhnN1/YOorJ068foQDNVpm146mUpILVxmq41Cj55YKHEazXGsdBIbXWhcrRf4G2fJLRcGUr9q8/lERo9oxRm5JFX6TCmj6kmiFqv+Ow9gI0x8GvaQ== demo@test

Acesse seu host remoto utilizando qualquer método que você tiver disponível.

Uma vez que você tiver acesso à sua conta no servidor remoto, você deve certificar-se de que o diretório `~/.ssh` existe. Esse comando irá criar o diretório se necessário, ou não fazer nada se ele já existir:

    mkdir -p ~/.ssh

Agora você pode criar ou modificar o arquivo `authorized_keys` dentro desse diretório. Você pode adicionar o conteúdo do seu arquivo `id_rsa.pub` ao final do arquivo `authorized_keys`, criando-o se necessário, utilizando este comando:

    echo string_da_chave_pública >> ~/.ssh/authorized_keys

No comando acima, substitua a string_da_chave_pública_ com a saída do comando `cat ~/.ssh/idrsa.pub`que você executou em seu sistema local. Ele deve iniciar com`ssh-rsa AAAA…`.

Finalmente, vamos garantir que o diretório `~/.ssh` e o arquivo `authorized_keys` tenham as permissões apropriadas configuradas:

    chmod -R go= ~/.ssh

Isto remove recursivamente todas as permissões “group” e “other” para o diretório `~/.ssh/`.

Se você estiver utilizando a conta `root` para configurar chaves para uma conta de usuário, é importante também que o diretório `~/.ssh` pertença ao usuário e não ao `root`:

    chown -R sammy:sammy ~/.ssh

Neste tutorial nosso usuário chama-se sammy, mas você deve substituir o nome de usuário apropriado no comando acima.

Podemos agora tentar a autenticação sem senha com nosso servidor Ubuntu.

## Passo 3 — Autenticar no Servidor Ubuntu Usando Chaves SSH

Se você completou com sucesso um dos procedimentos acima, você deve ser capaz de logar no host remoto _sem_ a senha da conta remota.

O processo básico é o mesmo:

    ssh nome_de_usuário@host_remoto

Se esta é a primeira vez que você se conecta a este host (se você usou o último método acima), você pode ver algo assim:

    OutputThe authenticity of host '203.0.113.1 (203.0.113.1)' can't be established.
    ECDSA key fingerprint is fd:fd:d4:f9:77:fe:73:84:e1:55:00:ad:d6:6d:22:fe.
    Are you sure you want to continue connecting (yes/no)? <^>yes<~>

Isto significa que seu computador local não reconhece o host remoto. Digite “yes” e pressione `ENTER`para continuar.

Se você não forneceu a frase secreta para sua chave privada, você estará logado imediatamente. Se você forneceu uma frase secreta para a chave privada quando você a criou, você será solicitado a entrar com ela agora (observe que sua digitação não será mostrada no terminal devido a questões de segurança). Depois da autenticação, uma nova sessão de shell deve abrir para você com a conta configurada no servidor Ubuntu.

Se a autenticação baseada em chave ocorreu com sucesso, continue para aprender como proteger ainda mais o seu sistema desativando a autenticação por senha.

## Passo 4 — Desativar a Autenticação por Senha no seu Servidor

Se você foi capaz de se logar em sua conta usando SSH sem uma senha, você configurou com sucesso a autenticação SSH baseada em chaves para sua conta. Contudo, seu mecanismo de autenticação baseado em senha ainda está ativo, significando que seu servidor ainda está exposto a ataques de força bruta.

Antes de completar os passos nessa sessão, certifique-se de que, ou você tem a autenticação SSH baseada em chaves para a conta root nesse servidor, ou preferencialmente, que você tem a autenticação SSH baseada em chaves para uma conta que não seja root e que tenha privilégios `sudo`. Esse passo irá bloquear logins baseados em senha, portanto, garantir que você ainda será capaz de obter acesso administrativo é crucial.

Uma vez que você confirmou que sua conta remota possui privilégios administrativos, efetue login no seu servidor com as chaves SSH, ou como root ou com uma conta com privilégios `sudo`. Depois, abra o arquivo de configuração do serviço SSH:

    sudo nano /etc/ssh/sshd_config

Dentro do arquivo, pesquise por uma diretiva chamada `PasswordAuthentication`. Isso deve estar comentado. Descomente a linha e defina o valor para “no”. Isso irá desativar sua capacidade de logar via SSH usando senhas de conta:

/etc/ssh/sshd\_config

    ...
    PasswordAuthentication no
    ...

Salve e feche o arquivo quando tiver terminado pressionando `CTRL + X`, e depois `Y` para confirmar o salvamento do arquivo, e finalmente `ENTER` para sair do nano. Para implementar essas mudanças de fato, precisamos reiniciar o serviço `sshd`:

    sudo systemctl restart ssh

Como uma precaução, abra uma nova janela de terminal e teste se o serviço SSH está funcionando corretamente antes de fechar esta sessão.

    ssh nome_de_usuário@host_remoto

Uma vez que tiver verificado o seu serviço SSH, você pode fechar com segurança todas as sessões atuais do servidor.

O serviço ou daemon SSH no seu servidor Ubuntu agora somente responde a chaves SSH. A autenticação baseada em senha foi desativada com sucesso.

## Conclusão

Agora você deve ter a autenticação SSH baseada em chaves configurada em seu servidor, permitindo efetuar login sem fornecer uma senha de conta.

Se você gostaria de saber mais sobre como trabalhar com SSH, dê uma olhada no nosso [Guia Essential do SSH](ssh-essentials-working-with-ssh-servers-clients-and-keys).
