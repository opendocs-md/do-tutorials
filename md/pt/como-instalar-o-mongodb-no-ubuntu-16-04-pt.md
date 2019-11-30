---
author: Mateusz Papiernik
date: 2016-12-23
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-mongodb-no-ubuntu-16-04-pt
---

# Como Instalar o MongoDB no Ubuntu 16.04

### Introdução

O MongoDB é um banco de dados livre e open-source de documentos NoSQL utilizado comumente nas modernas aplicações web. Este tutorial irá ajudá-lo a configurar o MongoDB em seu servidor para um ambiente de produção de aplicações.

No momento dessa publicação, os pacotes MongoDB oficiais do Ubuntu 16.04 ainda não haviam sido atualizados para utilizar o novo sistema init `systemd` [que é habilitado por padrão no Ubuntu 16.04](what-s-new-in-ubuntu-16-04#the-systemd-init-system). A execução do MongoDB utilizando esses pacotes em um Ubuntu 16.04 limpo envolve seguir um passo adicional para configurar o MongoDB como um serviço `systemd` que irá inicializar no boot.

## Pré-requisitos

Para seguir esse tutorial, você vai precisar de:

- Um servidor Ubuntu 16.04 configurado seguindo esse [tutorial de configuração inicial de servidor](initial-server-setup-with-ubuntu-16-04), incluindo um usuário sudo não-root.

## Passo 1 — Adicionando o Repositório MongoDB

O MongoDB já está incluído nos repositórios de pacotes do Ubuntu, mas o repositório oficial do MongoDB fornece versões mais atualizadas e é a maneira recomendada de instalar o software. Nesse passo, iremos adicionar esse repositório oficial ao nosso servidor.

O Ubuntu garante a autenticidade dos pacotes de software através da verificação de que eles estejam assinados com chaves GPG, dessa forma primeiro temos que importar a chave para o repositório MongoDB oficial.

    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927

Depois da importação da chave com sucesso, você verá:

Output

    gpg: Total number processed: 1
    gpg: imported: 1 (RSA: 1)

A seguir, temos que adicionar os detalhes do repositório MongoDB de forma que o `apt` saiba de onde baixar os pacotes.

Execute o seguinte comando para criar um arquivo de lista para o MongoDB.

    echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list

Depois de adicionar os detalhes do repositório, precisamos atualizar a lista de pacotes.

    sudo apt-get update

## Passo 2 — Instalando e Verificando o MongoDB

Agora podemos instalar o pacote do MongoDB propriamente dito.

    sudo apt-get install -y mongodb-org

Esse comando irá instalar vários pacotes contendo a última versão estável do MongoDB com ferramentas úteis de gerenciamento para o servidor MongoDB.

De forma a colocar o MongoDB corretamente como um serviço no Ubuntu 16.04, precisamos adicionalmente criar um _arquivo de unidade_ descrevendo o serviço. Um arquivo de unidade diz ao `systemd` como gerenciar um recurso. O tipo mais comum de unidade é um serviço, que determina como iniciar ou parar o serviço, quando ele deve ser iniciado no boot, e se ele é dependente de outros softwares para executar.

Vamos criar um arquivo de unidade para gerenciar o serviço MongoDB. Crie um arquivo de configuração de nome `mongodb.service` no diretório `/etc/systemd/system` utilizando o `nano` ou o seu editor de textos favorito.

    sudo nano /etc/systemd/system/mongodb.service

Cole nele o seguinte conteúdo, depois salve e feche o arquivo.

/etc/systemd/system/mongodb.service

    [Unit]
    Description=High-performance, schema-free document-oriented database
    After=network.target
    
    [Service]
    User=mongodb
    ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf
    
    [Install]
    WantedBy=multi-user.target

Esse arquivo tem uma estrutura simples:

- A seção **Unit** contém uma visão geral (isto é, uma descrição legível para o serviço MongoDB) bem como dependências que devem ser satisfeitas antes do serviço ser iniciado. No nosso caso, o MongoDB depende da rede já estar disponível, por isso `network.target` está aqui.

- A seção **Service** informa como o serviço deve ser iniciado. A diretiva `User` especifica que o servidor vai executar sob o usuário `mongodb`, e a diretiva `ExecStart` define o comando de inicialização para o servidor MongoDB. 

- A última seção, **Install** , diz ao `systemd` quando o serviço deve ser automaticamente iniciado. O `multi-user.target` é uma sequência padrão de inicialização de sistema, o que significa que o servidor será iniciado durante o boot. 

A seguir, inicie o serviço recém-criado com `systemctl`.

    sudo systemctl start mongodb

Embora não haja uma saída para esse comando, você também pode utilizar o `systemctl` para verificar que o serviço iniciou de maneira apropriada.

    sudo systemctl status mongodb

Output

    ● mongodb.service - High-performance, schema-free document-oriented database
       Loaded: loaded (/etc/systemd/system/mongodb.service; enabled; vendor preset: enabled)
       Active: active (running) since Mon 2016-04-25 14:57:20 EDT; 1min 30s ago
     Main PID: 4093 (mongod)
        Tasks: 16 (limit: 512)
       Memory: 47.1M
          CPU: 1.224s
       CGroup: /system.slice/mongodb.service
               └─4093 /usr/bin/mongod --quiet --config /etc/mongod.conf

O último passo é habilitar o MongoDB para iniciar quando o sistema inicializar.

    sudo systemctl enable mongodb

Agora o servidor MongoDB está configurado e executando, e você pode gerenciar o serviço MongoDB utilizando o comando `systemctl` (exemplo: `sudo systemctl mongodb stop`, `sudo systemctl mongodb start`).

## Passo 3 — Ajustando o Firewall (Opcional)

Assumindo que você seguiu as instruções do [tutorial de configuração inicial de servidor](initial-server-setup-with-ubuntu-16-04) para habilitar o firewall no seu servidor, seu servidor MongoDB será inacessível pela Internet.

Se sua intenção é utilizar o servidor MongoDB somente localmente com aplicações executando no mesmo servidor, essa é uma configuração recomendada e segura. Contudo, se você gostaria de ser capaz de conectar ao seu servidor MongoDB pela internet, temos que permitir as conexões de entrada no `ufw`.

Para permitir acesso ao MongoDB em sua porta padrão `27017` para todos, você pode utilizar `sudo ufw allow 27017`. Contudo, a habilitação do acesso internet para o servidor MongoDB em uma instalação padrão oferece acesso irrestrito a todo o servidor de banco de dados.

Na maioria dos casos, o MongoDB deve ser acessado somente por algumas localizações confiáveis, como um outro servidor hospedando uma aplicação. Para cumprir essa tarefa, você pode permitir acesso à porta padrão do MongoDB enquanto especifica o endereço IP de outro servidor que será explicitamente permitido para se conectar.

    sudo ufw allow from seu_outro_endereço_IP_do_servidor/32 to any port 27017

Você pode verificar a alteração nas configurações de firewall com o `ufw`.

    sudo ufw status

Você deve ver o tráfego permitido para a porta `27017` na saída. Se você tiver decidido a permitir apenas certos endereços IP se conectarem ao servidor MongoDB, o endereço IP do local permitido será listado em vez de _Anywhere_ na saída.

Output

    Status: active
    
    To Action From
    -- ------ ----
    27017 ALLOW Anywhere
    OpenSSH ALLOW Anywhere
    27017 (v6) ALLOW Anywhere (v6)
    OpenSSH (v6) ALLOW Anywhere (v6)

Mais configurações de firewall para restrição de acesso ao servidor estão descritas em [UFW Essentials: Common Firewall Rules and Commands](ufw-essentials-common-firewall-rules-and-commands).

## Conclusão

Você pode encontrar mais instruções detalhadas a respeito da instalação e configuração do MongoDB [nesses artigos da comunidade DigitalOcean](https://www.digitalocean.com/community/search?q=mongodb).
