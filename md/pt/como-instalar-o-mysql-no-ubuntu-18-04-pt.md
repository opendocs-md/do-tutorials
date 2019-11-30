---
author: Mark Drake
date: 2018-05-10
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-mysql-no-ubuntu-18-04-pt
---

# Como Instalar o MySQL no Ubuntu 18.04

_Uma versão anterior desse tutorial foi escrita por [Hazel Virdó](https://www.digitalocean.com/community/users/hazelnut)_

### Introdução

[MySQL](https://www.mysql.com/) é um sistema de gerenciamento de banco de dados open-source, comumente instalado como parte da popular pilha [LAMP](how-to-install-linux-apache-mysql-php-lamp-stack-ubuntu-18-04) (Linux, Apache, MySQL, PHP/Python/Perl). Ele utiliza um banco de dados relacional e SQL (Linguagem de Consulta Estruturada) para gerenciar seus dados.

A versão curta da instalação é simples: atualize seu índice de pacotes, instale o `pacote mysql-server`, e então execute o script de segurança que vem incluído.

    sudo apt update
    sudo apt install mysql-server
    mysql_secure_installation

Este tutorial irá explicar como instalar o MySQL versão 5.7 em um servidor Ubuntu 18.04. Contudo, se você estiver querendo atualizar uma instalação MySQL existente, você pode ler [esse guia de atualização do MySQL 5.7](how-to-prepare-for-your-mysql-5-7-upgrade) em vez disso.

## Pré-requisitos

Para seguir esse tutorial, você vai precisar de:

- Um servidor Ubuntu 18.04 configurado seguindo [esse guia de configuração inicial de servidor](initial-server-setup-with-ubuntu-18-04), incluindo um usuário com sudo que não seja root e um firewall.

## Passo 1 — Instalando o MySQL

No Ubuntu 18.04, somente a última versão do MySQL está incluída no repositório de pacotes APT por padrão. No momento em que escrevo, ela é a MySQL 5.7.

Para instalá-la, atualize o índice de pacotes em seu servidor e instale o pacote padrão com `apt`:

    sudo apt update
    sudo apt install mysql-server

Isso irá instalar o MySQL, mas não solicitará que você configure uma senha ou faça quaisquer outras alterações de configuração. Como isso deixa a sua instalação do MySQL insegura, vamos abordar isso a seguir.

## Passo 2 — Configurando o MySQL

Para novas instalações, você vai querer executar o script de segurança que está incluído. Isso altera algumas das opções padrão menos seguras para coisas como logins de root e usuários de exemplo. Em versões mais antigas do MySQL, você precisava inicializar o diretório de dados manualmente também, mas isso é feito automaticamente agora.

Execute o script de segurança:

    sudo mysql_secure_installation

Isto irá levá-lo através de uma série de prompts onde você poderá realizar algumas alterações nas opções de segurança da sua instalação do MySQL. O primeiro prompt irá perguntar se você quer configurar o Plugin Validate Password, que pode ser utilizado para testar a força de sua senha do MySQL. Independentemente de sua escolha, o próximo prompt será para configurar a senha do usuário root do MySQL. Entre e então confirme uma senha segura de sua escolha.

A partir daí, você pode pressionar `Y` e então `ENTER` para aceitar as respostas padrão para todas as questões subsequentes. Isso irá remover alguns usuários anônimos e o banco de dados de teste, desativar login remoto para o root, e carregar todas essas novas regras para que o MySQL respeite imediatamente as alterações que você fez.

Para inicializar o diretório de dados do MySQL, você usaria `mysql_install_db` para versões anteriores à versão 5.7.6, e `mysqld --initialize` para versão 5.7.6 e posteriores. Contudo, se você instalou o MySQL da distribuição Debian, como descrito no Passo 1, o diretório de dados foi iniciado automaticamente; você não tem que fazer nada. Se você tentar executar o comando de qualquer maneira, você verá o seguinte erro:

Output

    2018-04-23T20:11:15.998193Z 0 [ERROR] --initialize specified but the data directory has files in it. Aborting.

Finalmente, vamos testar a instalação do MySQL.

## Passo 3 — Testando o MySQL

Independentemente de como você o instalou, o MySQL deve ter iniciado executando automaticamente. Para testar isso, verifique seu status.

    systemctl status mysql.service

Você verá uma saída similar à seguinte:

Output

    ● mysql.service - MySQL Community Server
       Loaded: loaded (/lib/systemd/system/mysql.service; enabled; vendor preset: en
       Active: active (running) since Wed 2018-04-23 21:21:25 UTC; 30min ago
     Main PID: 3754 (mysqld)
        Tasks: 28
       Memory: 142.3M
          CPU: 1.994s
       CGroup: /system.slice/mysql.service
               └─3754 /usr/sbin/mysqld

Se o MySQL não está executando, você pode iniciá-lo com `sudo systemctl start mysql`.

Para uma verificação adicional, você pode tentar se conectar ao banco de dados utilizando a ferramenta `mysqladmin`, que é um cliente que lhe permite executar comandos administrativos. Por exemplo, este comando diz para conectar como root (`-u root`), solicitar uma senha (`-p`), e retornar a versão.

    sudo mysqladmin -p -u root version

Você deverá ver uma saída similar a essa:

Output

    mysqladmin Ver 8.42 Distrib 5.7.21, for Linux on x86_64
    Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.
    
    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.
    
    Server version 5.7.21-1ubuntu1
    Protocol version 10
    Connection Localhost via UNIX socket
    UNIX socket /var/run/mysqld/mysqld.sock
    Uptime: 30 min 54 sec
    
    Threads: 1 Questions: 12 Slow queries: 0 Opens: 115 Flush tables: 1 Open tables: 34 Queries per second avg: 0.006

Isso significa que o MySQL está funcionando.

## Conclusão

Você agora tem uma configuração básica do MySQL instalada no seu servidor. Aqui estão alguns exemplos dos próximos passos que você pode seguir.

- [Implementar algumas medidas de segurança adicionais](how-to-secure-mysql-and-mariadb-databases-in-a-linux-vps)
- [Realocar o diretório de dados](how-to-move-a-mysql-data-directory-to-a-new-location-on-ubuntu-16-04)
- [Gerenciar seus servidores MySQL com o SaltStack](saltstack-infrastructure-creating-salt-states-for-mysql-database-servers)
- [Aprender mais sobre comandos do MySQL](a-basic-mysql-tutorial)
