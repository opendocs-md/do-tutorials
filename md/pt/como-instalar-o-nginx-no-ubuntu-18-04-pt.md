---
author: Justin Ellingwood, Kathleen Juell
date: 2018-05-16
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-nginx-no-ubuntu-18-04-pt
---

# Como Instalar o Nginx no Ubuntu 18.04

_Uma versão anterior desse tutorial foi escrita por [Justin Ellingwood](https://www.digitalocean.com/community/users/jellingwood)_

### Introdução

O Nginx é um dos servidores web mais populares no mundo e é responsável por hospedar alguns dos maiores e mais acessados sites na internet. Ele possui recursos mais amigáveis do que o Apache em muitos casos e pode ser utilizado como servidor web ou proxy reverso.

Neste guia, vamos discutir como instalar o Nginx em seu servidor Ubuntu 18.04.

## Pré-requisitos

Antes de começar esse guia, você deve ter um usuário comum, que não seja o root e com privilégios `sudo` configurado em seu servidor. Você pode aprender como configurar uma conta de usuário comum seguindo nosso guia de [Configuração Inicial de servidor com Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04).

Quando você tiver uma conta disponível, entre com seu usuário que não seja root para começar.

## Passo 1 – Instalando o Nginx

Devido ao Nginx estar disponível nos repositórios padrão do Ubuntu, é possível instalá-lo a partir desses repositórios utilizando o sistema `apt` de empacotamento.

Como esta é nossa primeira interação com o sistema de gerenciamento de pacotes `apt` nessa seção, vamos atualizar nosso índice local de pacotes para que possamos acessar as listas de pacotes mais recentes. Depois, podemos instalar o `nginx`:

    sudo apt update
    sudo apt install nginx

Após aceitar o procedimento, o `apt` irá instalar o Nginx e quaisquer outras dependências necessárias em seu servidor.

## Passo 2 – Ajustando o Firewall

Antes de podermos testar o Nginx, precisamos reconfigurar nosso software de firewall para permitir acesso ao serviço. O Nginx se registra como um serviço com o `ufw` após a instalação, tornando bem fácil permitir o acesso ao Nginx.

Podemos listar as configurações das aplicações com as quais o `ufw`sabe como trabalhar digitando:

    sudo ufw app list

Você deve obter uma listagem dos perfis de aplicativo:

    OutputAvailable applications:
      Nginx Full
      Nginx HTTP
      Nginx HTTPS
      OpenSSH

Como você pode ver, existem três perfis disponíveis para o Nginx:

- **Nginx Full** : Esse perfil abre ambas as portas 80 (normal, tráfego não criptografado) e porta 443 (TLS/SSL, tráfego criptografado)
- **Nginx HTTP** : Esse perfil abre apenas a porta 80 (normal, tráfego não criptografado)
- **Nginx HTTPS** : Esse perfil abre apenas a porta 443 (TLS/SSL, tráfego criptografado)

É recomendado que você habilite o perfil mais restritivo que ainda permita o tráfego que você tenha configurado. Como não configuramos o SSL para nosso servidor ainda nesse guia, precisaremos permitir apenas tráfego na porta 80.

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

## Passo 3 – Verificando seu Servidor Web

Ao final do processo de instalação, o Ubuntu 18.04 inicia o Nginx. O servidor web já deve estar em funcionamento.

Podemos verificar com o sistema de init `systemd` para ter certeza de que o serviço está executando ao digitar:

    systemctl status nginx

    Output● nginx.service - A high performance web server and a reverse proxy server
       Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
       Active: active (running) since Fri 2018-04-20 16:08:19 UTC; 3 days ago
         Docs: man:nginx(8)
     Main PID: 2369 (nginx)
        Tasks: 2 (limit: 1153)
       CGroup: /system.slice/nginx.service
               ├─2369 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
               └─2380 nginx: worker process

Como você pode ver acima, o serviço parece ter sido iniciado com sucesso. Entretanto, a melhor forma de testar isso é, na verdade, requisitando uma página ao Nginx.

Você pode acessar a página inicial padrão do Nginx para confirmar que o software está executando apropriadamente ao navegar no endereço IP do seu servidor. Se você não sabe o endereço IP do seu servidor, você pode obtê-lo de algumas diferentes maneiras.

Tente digitar isso no prompt de comando do seu servidor:

    ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'

Esse comando vai lhe retornar algumas linhas. Você pode tentar cada uma delas em seu navegador web para ver se as mesmas funcionam.

Uma alternativa seria digitar isso, que deve lhe dar o seu endereço IP público como ele é visto a partir de outra localização na internet:

    curl -4 icanhazip.com

Quando você tiver o endereço IP do seu servidor, insira-o na barra de endereço do seu navegador:

    http://ip_do_seu_servidor

Você deve ver a página inicial padrão do Nginx:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_1604/default_page.png)

Essa página é incluída com o Nginx para mostrá-lo que o servidor está funcionando corretamente.

## Passo 4 – Gerenciando o Processo do Nginx

Agora que você tem seu servidor web funcionando, vamos revisar alguns comandos básicos de gerenciamento.

Para parar seu servidor web, digite:

    sudo systemctl stop nginx

Para iniciar o servidor web quando ele estiver parado, digite:

    sudo systemctl start nginx

Para parar e depois iniciar o serviço novamente, digite:

    sudo systemctl restart nginx

Se você estiver simplesmente realizando alterações de configuração, o Nginx muitas vezes recarrega sem perder as conexões. Para fazer isso, digite:

    sudo systemctl reload nginx

Por padrão, o Nginx é configurado para iniciar automaticamente quando o servidor é inicializado. Se isso não é o que você quer, você pode desabilitar esse comportamento digitando:

    sudo systemctl disable nginx

Para reativar o serviço para iniciar na inicialização do servidor, você pode digitar:

    sudo systemctl enable nginx

## Passo 5 – Configurando Blocos do Servidor (recomendado)

Ao utilizar o servidor web Nginx, os blocos do servidor (similares aos virtual hosts no Apache) podem ser usados para encapsular detalhes de configuração e hospedar mais de um domínio a partir de um único servidor. Vamos configurar um domínio chamado **exemplo.com** , mas você deve **substituí-lo por seu próprio nome de domínio**. Para aprender mais sobre a configuração de um nome de domínio com a DigitalOcean, veja nossa [Introdução ao DNS da DigitalOcean](an-introduction-to-digitalocean-dns).

O Nginx no Ubuntu 18.04 tem um bloco de servidor ativado por padrão que é configurado para servir documentos de um diretório em `/var/www/html`. Apesar disso funcionar bem para um único site, pode ficar difícil se você estiver hospedando vários sites. Em vez de modificar `/var/www/html`, vamos criar uma estrutura de diretórios dentro de `/var/www` para o nosso site **example.com** , deixando `/var/www/html` no lugar como o diretório padrão a ser servido se uma requisição de cliente não corresponder a nenhum outro site.

Crie o diretório para **example.com** como a seguir, usando o flag `-p` para criar qualquer diretório pai necessário:

    sudo mkdir -p /var/www/example.com/html

A seguir, atribua a propriedade do diretório com a variável de ambiente `$USER`:

    sudo chown -R $USER:$USER /var/www/example.com/html

As permissões de sua pasta raiz web devem estar corretas se você não tiver modificado o seu valor de `umask`, mas você pode certificar-se digitando:

    sudo chmod -R 755 /var/www/example.com

Em seguida, crie uma página de exemplo `index.html` utilizando o `nano` ou o seu editor favorito:

    nano /var/www/`example.com`/html/index.html

Dentro, adicione o seguinte exemplo HTML:

/var/www/example.com/html/index.html

    
    
    <html>
        <head>
            <title>Welcome to Example.com!</title>
        </head>
        <body>
            <h1>Success! The example.com server block is working!</h1>
        </body>
    </html>
    

Salve e feche o arquivo quando tiver concluído.

Para que o Nginx sirva esse conteúdo, é necessário criar um bloco de servidor com as diretivas corretas. Em vez de modificar o arquivo de configuração padrão diretamente, vamos criar um novo em `/etc/nginx/sites-available/example.com`:

    sudo nano /etc/nginx/sites-available/example.com

Cole dentro o seguinte bloco de configuração, que é similar ao padrão, mas atualizado para nosso novo diretório e nome de domínio:

/etc/nginx/sites-available/example.com

    
    server {
            listen 80;
            listen [::]:80;
    
            root /var/www/example.com/html;
            index index.html index.htm index.nginx-debian.html;
    
            server_name example.com www.example.com;
    
            location / {
                    try_files $uri $uri/ =404;
            }
    }
    

Observe que atualizamos a configuração `root` para corresponder ao nosso novo diretório e `server_name` ao nosso nome de domínio.

A seguir, vamos ativar o arquivo através da criação de um link dele para o diretório `sites-enabled`, a partir do qual o Nginx lê durante a inicialização:

    sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/

Dois blocos de servidor estão agora ativados e configurados para responder às requisições nas suas diretivas `listen` e `server_name` (você pode ler mais sobre como o Nginx processa essas diretivas [aqui](understanding-nginx-server-and-location-block-selection-algorithms)):

- `example.com`: Irá responder às requisições para `example.com` e `www.example.com`.
- `default`: Irá responder a quaisquer requisições na porta 80 que não correspondam aos outros dois blocos.

Para evitar um possível problema de memória com hash bucket que pode surgir da adição de nomes de servidor adicionais, é necessário ajustar um único valor no arquivo `/etc/nginx/nginx.conf`. Abra o arquivo:

    sudo nano /etc/nginx/nginx.conf

Localize a diretiva `server_names_hash_bucket_size` e remova o símbolo `#` para descomentar a linha:

/etc/nginx/nginx.conf

    
    ...
    http {
        ...
        server_names_hash_bucket_size 64;
        ...
    }
    ...
    

Depois, teste para certificar-se de que não existem erros de sintaxe em quaisquer de seus arquivos do Nginx:

    sudo nginx -t

Salve e feche o arquivo quando tiver terminado.

Se não houver problemas, reinicie o Nginx para ativar suas alterações:

    sudo systemctl restart nginx

O Nginx deve agora estar servindo ao seu nome de domínio. Você pode testar isso através da navegação para http://example.com, onde você deverá ver algo assim:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_server_block_1404/first_block.png)

## Step 6 – Familiarizando-se com os Arquivos e Diretórios Importantes do Nginx

Agora que você sabe como gerenciar o serviço Nginx em si, você deve tomar alguns minutos para se familiarizar com alguns diretórios e arquivos importantes.

### Conteúdo

- `/var/www/html`: O conteúdo web de fato, que por padrão consiste somente da página inicial do Nginx que você viu anteriormente, é servido pelo diretório `/var/www/html`. Isso pode ser mudado alterando-se arquivos de configuração do Nginx.

### Configuração do Servidor

- `/etc/nginx`: O diretório de configuração do Nginx. Todos os arquivos de configuração do Nginx residem aqui.
- `/etc/nginx/nginx.conf`: O arquivo principal de configuração do Nginx. Ele pode ser modificado para realizar alterações na configuração global do Nginx.
- `/etc/nginx/sites-available`: O diretório onde “blocos de servidor” por site podem ser armazenados. O Nginx não utilizará os arquivos de configuração encontrados nesse diretório a menos que eles estejam vinculados ao diretório `sites-enabled`. Tipicamente, toda configuração de blocos de servidor é feita nesse diretório, e depois habilitada vinculando-se ao outro diretório.
- `/etc/nginx/sites-enabled/`: O diretório onde “blocos de servidor” habilitados por site são armazenados. Tipicamente, estes são criados através da vinculação aos arquivos de configuração encontrados no diretório `sites-available`.
- `/etc/nginx/snippets`: Esse diretório contém fragmentos de configuração que podem ser incluídos em outras partes da configuração do Nginx. Segmentos de configuração potencialmente repetíveis são bons candidatos para refatoração em snippets.

### Logs do Servidor

- `/var/log/nginx/access.log`: Toda requisição ao seu servidor web é gravada nesse arquivo de log a menos que o Nginx esteja configurado para fazer o contrário.
- `/var/log/nginx/error.log`: Quaisquer erros do Nginx serão gravados nesse log.

## Conclusão

Agora que você tem o seu servidor instalado, você tem muitas opções para o tipo de conteúdo a servir e as tecnologias que você quer utilizar para criar uma experiência mais rica.

Se você gostaria de construir uma pilha de aplicação mais completa, verifique esse artigo em [como configurar uma pilha LEMP no Ubuntu 16.04](how-to-install-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04).
