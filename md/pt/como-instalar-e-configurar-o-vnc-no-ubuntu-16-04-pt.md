---
author: finid
date: 2016-12-20
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-e-configurar-o-vnc-no-ubuntu-16-04-pt
---

# Como Instalar e Configurar o VNC no Ubuntu 16.04

### Introdução

VNC, ou “Virtual Network Computing”, é um sistema de conexão que lhe permite utilizar o seu teclado e mouse para interagir com um ambiente gráfico de desktop em um servidor remoto. Ele torna mais fácil gerenciar arquivos, software e configurações em um servidor remoto para usuários que ainda não estejam confortáveis com a linha de comando.

Neste guia, iremos configurar o VNC em um servidor Ubuntu 16.04 e nos conectar a ele com segurança através de um túnel SSH. O servidor VNC que estaremos utilizando é o TightVNC, um pacote de controle remoto rápido e leve. Essa escolha irá assegurar que sua conexão VNC será suave e estável mesmo em conexões de internet mais lentas.

## Pré-requisitos

Para completar esse tutorial, você vai precisar de:

- Um Droplet Ubuntu 16.04 configurado através do [tutorial de Configuração Inicial de servidor com Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04), que inclui ter um usuário sudo não-root.

- Um computador local com um cliente VNC instalado que suporte conexões VNC através de túneis SSH. Se você estiver usando Windows, poderá utilizar TightVNC, RealVNC, ou UltraVNC. Usuários de Mac OS X podem utilizar o programa embutido de Compartilhamento de Tela, ou podem utilizar um app multi-plataforma como o RealVNC. Usuários de Linux podem utilizar muitas opções: `vinagre`, `krdc`, RealVNC, TightVNC, entre outros. 

## Passo 1 — Instalando o Ambiente de Desktop e o Servidor VNC

Por padrão, um Droplet Ubuntu 16.04 não vem com um ambiente gráfico de desktop ou um servidor VNC instalado, assim vamos começar instalando-os. Especificamente, vamos instalar pacotes para o mais recente ambiente desktop Xfce e o pacote TightVNC disponível no repositório oficial do Ubuntu.

Em seu servidor, instale os pacotes Xfce e TightVNC.

    sudo apt install xfce4 xfce4-goodies tightvncserver

Para completar a configuração inicial do servidor VNC depois da instalação, utilize o comando `vncserver` para configurar uma senha segura.

    vncserver

Você será solicitado a digitar e verificar uma senha, e também uma senha de visualização somente. Usuários que fizerem login com a senha de visualização somente não serão capazes de controlar a instância VNC com seu mouse e teclado. Essa é uma opção útil se você quiser demonstrar algo para outras pessoas usando o servidor VNC, mas não é necessária.

A execução do `vncserver` completa a instalação do VNC através da criação de arquivos de configuração padrão e de informações de conexão para nosso servidor utilizar. Com esses pacotes instalados, você está agora pronto para configurar seu servidor VNC.

## Passo 2 — Configurando o Servidor VNC

Primeiro, precisamos dizer ao nosso servidor VNC quais comandos executar quando ele iniciar. Esses comandos estão localizados em um arquivo de configuração chamado `xstartup` na pasta `.vnc` abaixo do seu diretório home. O script de inicialização foi criado quando você executou `vncserver` no passo anterior, mas precisamos modificar alguns dos comandos para o desktop Xfce.

Quando o VNC é configurado pela primeira vez, ele inicia uma instância padrão do servidor na porta 5901. Essa porta é chamada de porta de exibição, e é referenciada pelo VNC como `:1`. O VNC pode iniciar múltiplas instâncias em outras portas de exibição, como `:2`, `:3`, etc. Ao trabalhar com servidores VNC, lembre-se de que `:X` é uma porta de exibição que refere-se a `5900+X`.

Como vamos mudar o modo como o servidor VNC está configurado, precisaremos primeiro parar a instância do servidor VNC que está executando na porta 5901.

    vncserver -kill :1

A saída deve se parecer com essa, com um PID diferente:

    OutputKilling Xtightvnc process ID 17648

Antes de começar a configurar o novo arquivo `xstartup`, vamos salvar o original.

    mv ~/.vnc/xstartup ~/.vnc/xstartup.bak

Agora, crie um novo arquivo `xstartup` com o `nano` ou o seu editor de textos favorito.

    nano ~/.vnc/xstartup

Cole esses comandos no arquivo para que eles sejam executados automaticamente quando você iniciar ou reiniciar o servidor VNC, depois salve e feche o arquivo.

    ~/.vnc/xstartup#!/bin/bash
    xrdb $HOME/.Xresources
    startxfce4 &

O primeiro comando no arquivo, `xrdb $HOME/.Xresources`, informa ao framework gráfico do VNC para ler o arquivo `.Xresources` do servidor do usuário. `.Xresources` é onde um usuário pode realizar alterações em certas configurações do desktop gráfico, como as cores do terminal, temas do cursor, e renderização de fonte. O segundo comando simplesmente informa ao servidor para iniciar o Xfce, que é onde você vai encontrar todo o software gráfico que você precisa para gerenciar confortavelmente o seu servidor.

Para garantir que o servidor VNC será capaz de usar esse novo arquivo de inicialização corretamente, precisaremos conceder privilégios executáveis a ele.

    sudo chmod +x ~/.vnc/xstartup

Agora, reinicie o servidor VNC.

    vncserver

O servidor deve ser iniciado com uma saída semelhante a essa:

    OutputNew 'X' desktop is your_server_name.com:1
    
    Starting applications specified in /home/sammy/.vnc/xstartup
    Log file is /home/sammy/.vnc/liniverse.com:1.log

## Passo 3 — Testando o Desktop VNC

Nesse passo, vamos testar a conectividade do seu servidor VNC.

Primeiro, precisamos criar uma conexão SSH no seu computador local que faz o redirecionamento seguro da conexão ao `localhost` para o VNC. Você pode fazer isso através do terminal no Linux ou OS X com o seguinte comando. Lembre-se de substituir `nome_de_usuário` e `endereço_ip_do_servidor` com o nome de usuário não-root e o endereço IP do seu servidor.

    ssh -L 5901:127.0.0.1:5901 -N -f -l nome_de_usuário endereço_ip_do_servidor

Se você estiver utilizando um cliente SSH gráfico, como o PuTTY, use `endereço_ip_do_servidor` como IP de conexão, e configure `localhost:5901` como nova porta redirecionada nas configurações de túnel SSH do programa.

Em seguida, você pode utilizar o cliente VNC para tentar uma conexão com o servidor VNC em `localhost:5901`. Você será solicitado a se autenticar. A senha correta para utilizar é aquela que você configurou no Passo 1.

Uma vez conectado, você deve ver o desktop Xfce padrão. Deve ser algo assim:

![](http://i.imgur.com/X4eEcuV.png)

Você pode acessar arquivos em seu diretório home com o gerenciador de arquivos ou através da linha de comando, como visto abaixo:

![](http://i.imgur.com/n5VPuSa.png)

## Passo 4 — Criando um Arquivo de Serviço VNC

Em seguida, configuraremos o servidor VNC como um serviço systemd. Isso permitirá iniciar, parar, e reiniciar o serviço quando necessário, assim como qualquer outro serviço systemd.

Primeiro, crie um novo arquivo de unidade chamado `/etc/systemd/system/vncserver@.service` usando o seu editor de textos favorito:

    sudo nano /etc/systemd/system/vncserver@.service

Copie e cole o seguinte dentro dele. Assegure-se de alterar o valor de **User** e o nome do usuário no valor de **PIDFILE** para corresponder ao seu nome de usuário.

    /etc/systemd/system/vncserver@.service[Unit]
    Description=Start TightVNC server at startup
    After=syslog.target network.target
    
    [Service]
    Type=forking
    User=sammy
    PAMName=login
    PIDFile=/home/sammy/.vnc/%H:%i.pid
    ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
    ExecStart=/usr/bin/vncserver -depth 24 -geometry 1280x800 :%i
    ExecStop=/usr/bin/vncserver -kill :%i
    
    [Install]
    WantedBy=multi-user.target

Salve e feche o arquivo.

Depois, torne seu sistema ciente do novo arquivo de unidade.

    sudo systemctl daemon-reload

Habilite o arquivo de unidade.

    sudo systemctl enable vncserver@1.service

Pare a instância atual do servidor VNC se ela ainda estiver executando.

    vncserver -kill :1

Em seguida, inicie-o como você iniciaria qualquer outro serviço systemd.

    sudo systemctl start vncserver@1

Você pode verificar que ele iniciou com esse comando:

    sudo systemctl status vncserver@1

Se ele iniciou corretamente, a saída deve ser algo assim:

Output

    vncserver@1.service - TightVNC server on Ubuntu 16.04
       Loaded: loaded (/etc/systemd/system/vncserver@.service; enabled; vendor preset: enabled)
       Active: active (running) since Mon 2016-04-25 03:21:34 EDT; 6s ago
      Process: 2924 ExecStop=/usr/bin/vncserver -kill :%i (code=exited, status=0/SUCCESS)
    
    ...
    
     systemd[1]: Starting TightVNC server on Ubuntu 16.04...
     systemd[2938]: pam_unix(login:session): session opened for user finid by (uid=0)
     systemd[2949]: pam_unix(login:session): session opened for user finid by (uid=0)
     systemd[1]: Started TightVNC server on Ubuntu 16.04.

## Conclusão

Agora você deve ter um servidor VNC seguro instalado e funcionando no seu servidor Ubuntu 16.04. Você será capaz de gerenciar seus arquivos, software, e configurações com uma interface gráfica familiar e fácil de utilizar.
