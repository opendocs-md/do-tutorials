---
author: Justin Ellingwood
date: 2015-05-26
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-utilizar-o-sftp-para-transferir-arquivos-com-seguranca-com-um-servidor-remoto-pt
---

# Como Utilizar o SFTP para Transferir Arquivos com Segurança com um Servidor Remoto

## **O Que é SFTP**?

FTP, ou “File Transfer Protocol” é um método popular de transferência de arquivos entre sistemas remotos.

SFTP, que significa SSH File Transfer Protocol, ou Secure File Transfer Protocol, é um protocolo separado, empacotado com SSH que funciona de forma similar em cima de uma conexão segura. A vantagem é a capacidade de prover uma conexão segura para transferir arquivos, e cruzar o sistema de arquivo tanto na máquina local quanto na remota.

Em quase todos os casos, SFTP é preferível ao FTP devido às suas características de segurança embutida e a capacidade de pegar uma carona na conexão SSH. O FTP é um protocolo inseguro que deve ser utilizado somente em casos limitados ou em redes nas quais você confia.

Embora o SFTP seja integrado em várias ferramentas gráficas, este guia irá demonstrar como utilizá-lo através de sua interface interativa de linha de comando.

## Como Conectar com SFTP

Por padrão, o SFTP utiliza o protocolo SSH para autenticar e estabelecer uma conexão segura. Por causa disto, os mesmos métodos de autenticação disponíveis estão presentes no SSH.

Embora as senhas sejam fáceis de utilizar e de configurar por padrão, recomendamos que você crie chaves SSH e transfira sua chave pública para qualquer sistema que você precisa acessar. Isto é muito mais seguro e você pode economizar tempo a longo prazo.

Por favor, consulte este guia para [configurar chaves SSH](https://www.digitalocean.com/community/articles/how-to-set-up-ssh-keys--2) de modo a acessar seu servidor se não tiver feito isto ainda.

Se você pode se conectar à máquina utilizando SSH, então você concluiu todos os requisitos necessários para utilizar o SFTP para gerenciar arquivos. Teste o acesso SSH com o seguinte comando:

    ssh username@remote_hostname_or_IP

Se isso funcionar, saia digitando:

    exit

Podemos estabelecer uma conexão SSH e então, abrir uma sessão SFTP utilizando esta conexão através do seguinte comando:

    sftp username@remote_hostname_or_IP

Você irá se conectar ao sistema remoto e o seu prompt mudará para um prompt SFTP.

## Obter ajuda no SFTP

O comando mais útil a aprender primeiro é o comando help. Ele lhe dá acesso a um resumo da ajuda do SFTP.  
Você pode chamá-lo digitando qualquer um desses comandos no prompt:

    help
    
    ?

Esta é uma lista de comandos disponíveis:

    Available commands:
    bye Quit sftp
    cd path Change remote directory to 'path'
    chgrp grp path Change group of file 'path' to 'grp'
    chmod mode path Change permissions of file 'path' to 'mode'
    chown own path Change owner of file 'path' to 'own'
    df [-hi] [path] Display statistics for current directory or
                                       filesystem containing 'path'
    exit Quit sftp
    get [-Ppr] remote [local] Download file
    help Display this help text
    lcd path Change local directory to 'path'
    . . .

Exploraremos alguns destes comandos que você está vendo nas seções seguintes.

## Navegando com o SFTP

Podemos navegar pela hierarquia de arquivo do sistema remoto utilizando uma série de comandos que funcionam de maneira similar aos seus equivalentes no shell.

Primeiro, vamos nos orientar procurando em qual diretório estamos atualmente no sistema remoto. Assim como em uma sessão típica de shell, podemos digitar o seguinte para obter o diretório atual:

    pwd
    
    Remote working directory: /home/demouser

Podemos ver o conteúdo do diretório atual do sistema remoto com outro comando familiar:

    ls
    
    Summary.txt info.html temp.txt testDirectory

Observe que os comandos dentro da interface do SFTP são comandos normais do shell e não são tão completos, mas eles implementam alguns dos flags mais importantes:

    ls -la
    
    drwxr-xr-x 5 demouser demouser 4096 Aug 13 15:11 .
    drwxr-xr-x 3 root root 4096 Aug 13 15:02 ..
    -rw------- 1 demouser demouser 5 Aug 13 15:04 .bash_history
    -rw-r--r-- 1 demouser demouser 220 Aug 13 15:02 .bash_logout
    -rw-r--r-- 1 demouser demouser 3486 Aug 13 15:02 .bashrc
    drwx------ 2 demouser demouser 4096 Aug 13 15:04 .cache
    -rw-r--r-- 1 demouser demouser 675 Aug 13 15:02 .profile
    . . .

Para ir para outro diretório, podemos digitar este comando:

    cd testDirectory

Podemos agora navegar pelo sistema de arquivos remoto, mas e se precisarmos acessar nosso sistema de arquivos local? Podemos direcionar comandos para o sistema de arquivos local, precedendo-os com um “l” de local.

Todos os comandos discutidos possuem seus equivalentes locais. Podemos imprimir o diretório de trabalho local:

    lpwd
    
    Local working directory: /Users/demouser

Podemos listar o conteúdo do diretório atual na máquina local:

    lls
    
    Desktop local.txt test.html
    Documents analysis.rtf zebra.html

Podemos também mudar o diretório com o qual desejamos interagir no sistema local:

    lcd Desktop

## Transferindo Arquivos com SFTP

A navegação nos sistemas de arquivos remoto e local seria de pouca utilidade se não fôssemos capazes de transferir arquivos entre os dois.

### Transferindo Arquivos Remotos para o Sistema Local

Se quisermos realizar um download do nosso host remoto, podemos fazê-lo digitando o seguinte comando:

    get remoteFile
    
    Fetching /home/demouser/remoteFile to remoteFile
    /home/demouser/remoteFile 100% 37KB 36.8KB/s 00:01

Como você pode ver, por padrão, o comando “get” baixa um arquivo remoto para um arquivo com o mesmo nome no sistema de arquivos local.

Podemos copiar o arquivo remoto para um nome diferente, especificando o nome logo após:

    get remoteFile localFile

O comando “get” também possui algumas opções. Por exemplo, podemos copiar um diretório e todo o seu conteúdo especificando a opção de recursão:

    get -r someDirectory

Podemos dizer ao SFTP para manter permissões apropriadas e horários de acesso utilizando os flags “-P” ou “-p”:

    get -Pr someDirectory

### Transferindo Arquivos Locais para o Sistema Remoto

A transferência de arquivos para o sistema remoto é facilmente realizada utilizando-se o comando apropriadamente denominado “put”:

    put localFile
    
    Uploading localFile to /home/demouser/localFile
    localFile 100% 7607 7.4KB/s 00:00

Os mesmos flags ou opções que funcionam com “get” aplicam-se ao “put”. Assim, para copiar um diretório local inteiro, você pode digitar:

    put -r localDirectory

Uma ferramenta familiar que é útil quando for baixar e carregar arquivos é o comando “df”, que funciona de maneira similar à versão de linha de comando. Utilizando-a, você pode checar se possui espaço suficiente para completar a transferência que você está interessado:

    df -h
    
    Size Used Avail (root) %Capacity
    19.9GB 1016MB 17.9GB 18.9GB 4%

Por favor, observe que não existem variações locais para este comando, mas podemos contornar isso digitando o comando “!”.

O comando “!” nos coloca em um shell local, onde podemos executar qualquer comando disponível no nosso sistema local. Podemos checar a utilização do disco digitando:

    !
    df -h
    
    Filesystem Size Used Avail Capacity Mounted on
    /dev/disk0s2 595Gi 52Gi 544Gi 9% /
    devfs 181Ki 181Ki 0Bi 100% /dev
    map -hosts 0Bi 0Bi 0Bi 100% /net
    map auto_home 0Bi 0Bi 0Bi 100% /home

Qualquer outro comando local irá funcionar conforme esperado. Para retornar à sua sessão SFTP, digite:

    exit

Você deve ver agora o prompt do SFTP.

## Manipulações Simples de Arquivos com SFTP

O SFTP permite a você realizar o tipo de manutenção básica que é útil no trabalho com hierarquias de arquivos.

Por exemplo, você pode alterar o proprietário de um arquivo no sistema remoto com:

    chown userID file

Observe agora que, diferentemente do comando “chmod”, o comando SFTP não aceita nomes de usuário, mas em vez disso, utiliza UIDs.  
Infelizmente, não há uma maneira fácil de saber o UID apropriado através da interface do SFTP.

Uma maneira de contornar isto pode ser conseguida com:

    get /etc/passwd
    !less passwd
    
    root:x:0:0:root:/root:/bin/bash
    daemon:x:1:1:daemon:/usr/sbin:/bin/sh
    bin:x:2:2:bin:/bin:/bin/sh
    sys:x:3:3:sys:/dev:/bin/sh
    sync:x:4:65534:sync:/bin:/bin/sync
    games:x:5:60:games:/usr/games:/bin/sh
    man:x:6:12:man:/var/cache/man:/bin/sh
    . . .

Observe como, em vez de usar o comando “!” por si só, o utilizamos como um prefixo para um comando de shell local.  
Isto funciona para executar qualquer comando disponível na sua máquina local e poderia ser utilizado com o comando local “df” anteriormente.

O UID estará na terceira coluna do arquivo, conforme delimitado pelos caracteres de dois pontos.

Similarmente, podemos alterar o grupo proprietário de um arquivo com:

    chgrp groupID file

Novamente, não existe uma maneira fácil de listar os grupos do sistema remoto. Podemos contornar isto com o seguinte comando:

    get /etc/group
    !less group
    
    root:x:0:
    daemon:x:1:
    bin:x:2:
    sys:x:3:
    adm:x:4:
    tty:x:5:
    disk:x:6:
    lp:x:7:
    . . .

A terceira coluna detém o ID do grupo associado com o nome na primeira coluna. Isto é o que estamos procurando.

Felizmente, o comando “chmod” funciona conforme esperado no sistema de arquivos remoto:

    chmod 777 publicFile
    
    Changing mode on /home/demouser/publicFile

Não existe comando para manipulação de permissões locais, mas você pode definir o umask local, de forma que quaisquer arquivos copiados para o sistema de arquivos local tenha as permissões apropriadas.

Isto pode ser feito com o comando “lumask”:

    lumask 022
    
    Local umask: 022

Agora, todos os arquivos regulares baixados (visto que o flag “-p” não é utilizado) terão permissões 644.

O SFTP permite que você crie diretórios em ambos os sistemas, local e remoto com “lmkdir” e “mkdir” respectivamente. Estes trabalham conforme esperado.

O restante dos comandos de arquivos focam somente o sistema de arquivos remoto:

    ln
    rm
    rmdir

Estes comandos replicam o comportamento básico das versões de shell. Se você precisa realizar estas ações no sistema de arquivos local, lembre-se de que você pode cair em um shell digitando este comando:

    !

Ou execute um comando simples no sistema local precedendo o comando com “!” como em:

    !chmod 644 somefile

Quando tiver concluído sua sessão SFTP, utilize “exit” ou “bye” para fechar a conexão.

    bye

## Conclusão

Embora o SFTP seja uma ferramenta simples, ele é muito útil para administração de servidores e transferência de arquivos entre eles.

Se você estiver acostumado a utilizar FTP ou SCP para realizar suas transferências, o SFTP é um bom caminho para aproveitar os pontos fortes dos dois. Embora ele não seja apropriado para todas as situações, é uma ferramenta flexível para ter em seu repertório.
