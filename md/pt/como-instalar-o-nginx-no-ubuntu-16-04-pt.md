---
author: Justin Ellingwood
date: 2016-12-23
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-nginx-no-ubuntu-16-04-pt
---

# Como Instalar o Nginx no Ubuntu 16.04

### Introdução

O Nginx é um dos servidores web mais populares no mundo e é responsável por hospedar alguns dos maiores e mais acessados sites na internet. Ele possui mais facilidades de recursos do que o Apache em muitos casos e pode ser utilizado como servidor web ou proxy reverso.

Neste guia, vamos discutir como colocar o Nginx instalado em seu servidor Ubuntu 16.04.

## Pré-requisitos

Antes de começar esse guia, você deve ter um usuário regular, não-root com privilégios `sudo` configurado em seu servidor. Você pode aprender como configurar uma conta de usuário regular seguindo nosso guia de [Configuração Inicial de servidor com Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).

Quando você tiver uma conta disponível, entre com seu usuário não-root para começar.

## Passo 1: Instalar o Nginx

O Nginx está disponível nos repositórios padrão do Ubuntu, então a instalação é bastante simples.

Como esta é nossa primeira interação com o sistema de gerenciamento de pacotes `apt` nessa seção, vamos atualizar nosso índice local de pacotes para que possamos acessar as listas de pacotes mais recentes. Depois, podemos instalar o `nginx`:

    sudo apt-get update
    sudo apt-get install nginx

Após a aceitação do procedimento, o `apt-get` irá instalar o Nginx e quaisquer outras dependências necessárias em seu servidor.

## Passo 2: Ajustar o Firewall

Antes de podermos testar o Nginx, precisamos reconfigurar nosso software de firewall para permitir acesso ao serviço. O Nginx se registra como um serviço com o `ufw`, nosso firewall, após a instalação. Isso torna bastante fácil permitir o acesso do Nginx.

Podemos listar as configurações das aplicações que o `ufw`sabe como trabalhar digitando:

    sudo ufw app list

Você deve obter uma lista dos perfis de aplicativo:

    OutputAvailable applications:
      Nginx Full
      Nginx HTTP
      Nginx HTTPS
      OpenSSH

Como você pode ver, existem três perfis disponíveis para o Nginx:

- **Nginx Full** : Esse perfil abre ambas as portas 80 (normal, tráfego não criptografado) e porta 443 (TLS/SSL, tráfego criptografado)
- **Nginx HTTP** : Esse perfil abre apenas a porta 80 (normal, tráfego não criptografado)
- **Nginx HTTPS** : Esse perfil abre apenas a porta 443 (TLS/SSL, tráfego criptografado)

É recomendado que você habilite o perfil mais restritivo que ainda permita o tráfego que você tenha configurado. Como não configuramos o SSL para nosso servidor ainda, nesse guia, precisaremos permitir apenas tráfego na porta 80.

Você pode habilitar isso digitando:

    sudo ufw allow 'Nginx HTTP'

Você pode verificar a alteração digitando:

    sudo ufw status

Você deve ver o tráfego HTTP permitido na saída mostrada:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Nginx HTTP ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Nginx HTTP (v6) ALLOW Anywhere (v6)

## Passo 3: Checar o seu Servidor Web

Ao final do processo de instalação, o Ubuntu 16.04 inicia o Nginx. O servidor web já deve estar em funcionamento.

Podemos checar com o sistema de init `systemd` para ter certeza de que o serviço está executando ao digitar:

    systemctl status nginx

    Output● nginx.service - A high performance web server and a reverse proxy server
       Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
       Active: active (running) since Mon 2016-04-18 16:14:00 EDT; 4min 2s ago
     Main PID: 12857 (nginx)
       CGroup: /system.slice/nginx.service
               ├─12857 nginx: master process /usr/sbin/nginx -g daemon on; master_process on
               └─12858 nginx: worker process

Como você pode ver, o serviço parece ter sido iniciado com sucesso. Entretanto, a melhor forma de testar isso é na verdade, requisitando uma página ao Nginx.

Você pode acessar a página inicial padrão do Nginx para confirmar que o software está executando apropriadamente. Você pode acessar isso através do nome de domínio ou do endereço IP do seu servidor.

Se você não tiver um nome de domínio configurado para seu servidor, você pode aprender [como configurar um domínio na DigitalOcean](https://digitalocean.com/community/articles/how-to-set-up-a-host-name-with-digitalocean) aqui.

Se você não quiser configurar um nome de domínio para seu servidor, você pode utilizar o endereço IP público do mesmo. Se você não sabe qual é o endereço IP do seu servidor, você pode obtê-lo de algumas maneiras diferentes na linha de comando.

Tente digitar isso no prompt de comandos do seu servidor:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Esse comando vai lhe retornar algumas linhas. Você pode tentar cada uma delas em seu navegador web para ver se as mesmas funcionam.

Uma alternativa seria digitar isso, que deve lhe dar o seu endereço IP público como ele é visto a partir de outra localização na internet:

    sudo apt-get install curl
    curl -4 icanhazip.com

Quando tiver endereço IP ou nome de domínio do seu servidor, insira-o na barra de endereço do seu navegador:

    http://domínio_do_servidor_ou_IP

Você deve ver a página inicial padrão do Nginx, que deve se parecer com algo assim:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_1604/default_page.png)

Essa página é incluída com o Nginx simplesmente para mostrá-lo que o servidor está executando corretamente.

## Passo 4: Gerenciar os Processos do Nginx

Agora que você tem seu servidor web funcionando, podemos partir para os comandos básicos de gerenciamento.

Para parar seu servidor web, você pode digitar:

    sudo systemctl stop nginx

Para iniciar o servidor web quando ele estiver parado, digite:

    sudo systemctl start nginx

Para parar e depois iniciar o serviço novamente, digite:

    sudo systemctl restart nginx

Se você estiver simplesmente realizando alterações de configuração, o Nginx muitas vezes recarrega sem perder as conexões. Para fazer isso, esse comando pode ser utilizado:

    sudo systemctl reload nginx

Por padrão, o Nginx é configurado para iniciar automaticamente quando o servidor é inicializado. Se isso não é o que você quer, você pode desabilitar esse comportamento digitando:

    sudo systemctl disable nginx

Para reativar o serviço para iniciar na inicialização do servidor, você pode digitar:

    sudo systemctl enable nginx

## Passo 5: Familiarize-se com os Arquivos e Diretórios Importantes do Nginx

Agora que você sabe como gerenciar o serviço em si, você deve tomar alguns minutos para se familiarizar com alguns diretórios e arquivos importantes.

### Conteúdo

- `/var/www/html`: O conteúdo web de fato, que por padrão consiste somente da página inicial do Nginx que você viu anteriormente, é servido pelo diretório `/var/www/html`. Isso pode ser mudado alterando-se arquivos de configuração do Nginx.

### Configuração do Servidor

- `/etc/nginx`: O diretório de configuração do Nginx. Todos os arquivos de configuração do Nginx residem aqui.
- `/etc/nginx/nginx.conf`: O arquivo principal de configuração do Nginx. Ele pode ser modificado para realizar alterações na configuração global do Nginx.
- `/etc/nginx/sites-available`: O diretório onde “blocos de servidor” por site podem ser armazenados. O Nginx não utilizará os arquivos de configuração encontrados nesse diretório a menos que eles estejam vinculados ao diretório `sites-enabled` (veja abaixo). Tipicamente, toda configuração de blocos de servidor é feita nesse diretório, e depois habilitada vinculando-se ao outro diretório.
- `/etc/nginx/sites-enabled/`: O diretório onde “blocos de servidor” habilitados por site são armazenados. Tipicamente, estes são criados através da vinculação aos arquivos de configuração encontrados no diretório `sites-available`.
- `/etc/nginx/snippets`: Esse diretório contém trechos de configuração que podem ser incluídos em outras partes da configuração do Nginx. Segmentos de configuração potencialmente repetíveis são bons candidatos para refatoração em trechos.

### Logs do Servidor

- `/var/log/nginx/access.log`: Toda requisição ao seu servidor web é gravada nesse arquivo de log a menos que o Nginx esteja configurado para fazer o contrário.
- `/var/log/nginx/error.log`: Quaisquer erros do Nginx serão gravados nesse log.

## Conclusão

Agora que você tem o seu servidor instalado, você tem muitas opções para o tipo de conteúdo a servir e as tecnologias que você quer utilizar para criar uma experiência mais rica.

Aprenda [como utilizar blocos de servidor do Nginx](how-to-set-up-nginx-server-blocks-virtual-hosts-on-ubuntu-16-04) aqui. Se você gostaria de construir uma pilha de aplicação mais completa, verifique esse artigo em [como configurar uma pilha LEMP no Ubuntu 16.04](how-to-install-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04).
