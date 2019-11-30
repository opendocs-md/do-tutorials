---
author: Justin Ellingwood
date: 2015-02-19
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-comecar-com-o-freebsd-10-1-pt
---

# Como começar com o FreeBSD 10.1

Este tutorial é a parte 2 de 7 na série: [Getting Started with FreeBSD](a-comparative-introduction-to-freebsd-for-linux-users#tutorial_series_36)

### Introdução

O FreeBSD é um sistema operacional seguro e de alto desempenho, que é adequado para uma variedade de papéis de servidor. Neste guia, cobriremos algumas informações básicas sobre como começar com um servidor FreeBSD.

## Passo Um - Fazer login com SSH

O primeiro passo que você precisa tomar para começar a configurar seu servidor FreeBSD é fazer login.

Na DigitalOcean, você deve fornecer uma chave SSH pública quando criar um servidor FreeBSD. Esta chave é adicionada à instância do servidor, permitindo que você realize um login seguro a partir de seu computador pessoal utilizando a chave privada associada. Para aprender mais sobre como utilizar chaves SSH com FreeBSD na DigitalOcean, [siga este guia](how-to-configure-ssh-key-based-authentication-on-a-freebsd-server).

Para acessar o seu servidor, você precisará saber o endereço IP público dele. Para os Droplets da DigitalOcean, você pode encontrar esta informação no painel de controle. A conta de usuário principal disponível nos servidores FreeBSD criados através da DigitalOcean é chamada `freebsd`. Esta conta de usuário é configurada com privilégios de sudo, permitindo a você realizar tarefas administrativas completas.

Para acessar seu servidor FreeBSD, utilize o comando ssh. Você precisará especificar o conta de usuário freebsd juntamente com o endereço IP público de seu servidor:

    ssh freebsd@endereço_IP_do_servidor

Você será autenticado e conectado automaticamente. Você cairá em uma interface de linha de comando.

## Alterando o Prompt do Shell tsch e Seus Padrões (Opcional)

Quando você está logado, você será apresentado a um prompt de comando mínimo que se parece com isto:

    >

Este é o prompt padrão para o `tsch`, o shell padrão de linha de comando do FreeBSD. A fim de ajudar-nos a permanecer orientados dentro do sistema de arquivos à medida que navegamos por ele, iremos implementar um prompt mais útil através da modificação do arquivo de configuração do nosso shell.

Um arquivo de configuração de exemplo está incluído no nosso sistema de arquivos. Vamos copiá-lo dentro de nosso diretório home, para que possamos modificá-lo como desejamos:

    cp /usr/share/skel/dot.cshrc ~/.cshrc

Depois que o arquivo for copiado dentro do nosso diretório home, podemos editá-lo. O editor `vi` é incluído no sistema por padrão. Se você quiser um editor mais simples, você pode experimentar o editor `ee`:

    vi ~/.cshrc

O arquivo inclui alguns padrões razoáveis, incluindo um prompt mais funcional. Algumas áreas que você poderia querer modificar são as entradas sentenv:

    . . .
    
    setenv EDITOR vi
    setenv PAGER more
    
    . . .

Se você não estiver familiarizado com o editor `vi` e gostaria de um ambiente de edição mais fácil, você deve alterar a variável de ambiente `EDITOR` para algo como `ee`. A maioria dos usuários vai querer mudar a variável PAGER para less em vez de more. Isso permitirá que você role para cima e para baixo nas páginas do manual, sem sair do paginador:

    setenv EDITOR ee
    setenv PAGER less

O outro item que devemos adicionar a este arquivo de configuração é um bloco de código que irá mapear corretamente as nossas teclas do teclado dentro da sessão do `tcsh`. Sem essas linhas, “Delete” e outras teclas não funcionarão corretamente. Esta informação é encontrada [nesta página](http://www.ibb.net/%7Eanne/keyboard/keyboard.html#Tcsh), mantida por Anne Baretta. No final do arquivo, copie e cole estas linhas:

    if ($term == "xterm" || $term == "vt100" \
                || $term == "vt102" || $term !~ "con*") then
              # bind keypad keys for console, vt100, vt102, xterm
              bindkey "\e[1~" beginning-of-line # Home
              bindkey "\e[7~" beginning-of-line # Home rxvt
              bindkey "\e[2~" overwrite-mode # Ins
              bindkey "\e[3~" delete-char # Delete
              bindkey "\e[4~" end-of-line # End
              bindkey "\e[8~" end-of-line # End rxvt
    endif

Quando você terminar, salve e feche o arquivo.

Para fazer sua sessão atual refletir estas alterações imediatamente, você pode varrer o conteúdo do arquivo agora:

    source ~/.cshrc

Seu prompt deve mudar imediatamente para algo parecido com isto:

    freebsd@hostname:~ %

Pode não ser imediatamente aparente, mas as teclas “Home”, “Insert”, “Delete”, e “End” também funcionam como esperado agora.

Uma coisa a notar nesse ponto é que se você estiver utilizando os shells `tcsh` ou `csh`, você precisará executar o comando `rehash` sempre que forem feitas quaisquer alterações que possam afetar o caminho executável. Os cenários comuns onde isto pode acontecer são quando instalamos ou desinstalamos aplicações.

Após instalar programas, você pode precisar digitar isto, de forma que o shell encontre os arquivos da nova aplicação.

    rehash

## Alterando o Shell Padrão (Opcional)

A configuração acima dá a você um bom ambiente `tcsh`. Se você estiver mais familiarizado com o shell `bash` e prefira utilizá-lo com seu shell padrão, você pode realizar facilmente este ajuste.

Primeiro, você precisa instalar o shell `bash` digitando:

    sudo pkg install bash

Após a conclusão da instalação, precisamos adicionar uma linha ao nosso arquivo `/etc/fstab` para montar o descritor de arquivos do sistema de arquivos, que é necessário ao `bash`. Você pode fazer isto facilmente digitando:

    sudo sh -c 'echo "fdesc /dev/fd fdescfs rw 0 0" >> /etc/fstab'

Isto irá adicionar a linha necessária ao final do arquivo `/etc/fstab`. Após isto, podemos montar o sistema de arquivos digitando:

    sudo mount -a

Isto irá montar o sistema de arquivos, nos permitindo iniciar o `bash`. Você pode fazer isto digitando:

    bash

Para alterar seu shell padrão para `bash`, você pode digitar:

    sudo chsh -s /usr/local/bin/bash freebsd

Da próxima vez que você acessar, o shell `bash` será iniciado automaticamente em vez do `tcsh`.

Se você deseja alterar o paginador ou editor padrão no shell `bash`, você pode fazê-lo em um arquivo chamado `~/.bash_profile`. Ele não existe por padrão, portanto precisamos criá-lo:

    vi ~/.bash_profile

Dentro do arquivo, para mudar o paginador ou editor padrão, você pode adicionar seleções como esta:

    export PAGER=less
    export EDITOR=vi

Você pode fazer muito mais alterações se desejar. Salve e feche o arquivo quando tiver terminado.

Para implementar suas alterações imediatamente, varra o arquivo:

    source ~/.bash_profile

## Conclusão

Por agora, você deve saber como acessar um servidor FreeBSSD e como configurar um ambiente shell razoável. Um bom próximo passo é completar alguns [passos adicionais recomendados para novos servidores FreeBSD 10.1](recommended-steps-for-new-freebsd-10-1-servers).

Depois, existem muitas direções diferentes para onde você pode ir. Algumas escolhas populares são:

- [A Comparative Introduction to FreeBSD for Linux Users](a-comparative-introduction-to-freebsd-for-linux-users)
- [An Introduction to Basic FreeBSD Maintenance](an-introduction-to-basic-freebsd-maintenance)
- [Installing Apache, MySQL, and PHP on FreeBSD 10.1](how-to-install-an-apache-mysql-and-php-famp-stack-on-freebsd-10-1)
- [Installing Nginx, MySQL and PHP on FreeBSD 10.1](how-to-install-an-nginx-mysql-and-php-femp-stack-on-freebsd-10-1)
- [Installing WordPress with Apache on FreeBSD 10.1](how-to-install-wordpress-with-apache-on-freebsd-10-1)
- [Installing WordPress with Nginx on FreeBSD 10.1](how-to-install-wordpress-with-nginx-on-a-freebsd-10-1-server)
- [How To Install Java on FreeBSD 10.1](how-to-install-java-on-freebsd-10-1)

Uma vez que você se familiarize com o FreeBSD e configure-o para suas necessidades, você será capaz de tirar proveito de sua flexibilidade, segurança e desempenho.
