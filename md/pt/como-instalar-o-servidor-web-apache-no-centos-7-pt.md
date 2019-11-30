---
author: Haley Mills
date: 2019-08-12
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-o-servidor-web-apache-no-centos-7-pt
---

# Como Instalar o Servidor Web Apache no CentOS 7

### Introdução

O servidor HTTP [Apache](https://www.apache.org/) é o servidor web mais utilizado no mundo. Ele fornece muitos recursos poderosos incluindo módulos dinamicamente carregáveis, suporte robusto a mídia, e integração extensiva com outros softwares populares.

Neste guia, você instalará um servidor web Apache com virtual hosts em seu servidor CentOS 7.

## Pré-requisitos

Você precisará do seguinte para concluir este guia:

- Um usuário não-root com privilégios sudo definidos em seu servidor, configurado seguindo o guia de [Configuração Inicial do Servidor com o CentOS 7](configuracao-inicial-do-servidor-com-o-centos-7-pt).

- Um firewall básico configurado seguindo o guia [Etapas adicionais recomendadas para novos servidores CentOS 7](additional-recommended-steps-for-new-centos-7-servers-pt)

## Passo 1 — Instalando o Apache

O Apache está disponível nos repositórios de software padrão do CentOS, o que significa que você pode instalá-lo com o gerenciador de pacotes `yum`.

Agindo como o usuário não-root, com privilégios sudo configurado nos pré-requisitos, atualize o índice de pacotes local `httpd` do Apache para refletir as alterações mais recentes do upstream:

    sudo yum update httpd

Depois que os pacotes forem atualizados, instale o pacote Apache:

    sudo yum install httpd

Após confirmar a instalação, o `yum` instalará o Apache e todas as dependências necessárias. Quando a instalação estiver concluída, você estará pronto para iniciar o serviço.

## Passo 2 — Verificando seu Servidor Web

O Apache não inicia automaticamente no CentOS depois que a instalação é concluída. Você precisará iniciar o processo do Apache manualmente:

    sudo systemctl start httpd

Verifique se o serviço está sendo executado com o seguinte comando:

    sudo systemctl status httpd

Você verá um status `active` quando o serviço estiver em execução:

    OutputRedirecting to /bin/systemctl status httpd.service
    ● httpd.service - The Apache HTTP Server
       Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
       Active: active (running) since Wed 2019-02-20 01:29:08 UTC; 5s ago
         Docs: man:httpd(8)
               man:apachectl(8)
     Main PID: 1290 (httpd)
       Status: "Processing requests..."
       CGroup: /system.slice/httpd.service
               ├─1290 /usr/sbin/httpd -DFOREGROUND
               ├─1291 /usr/sbin/httpd -DFOREGROUND
               ├─1292 /usr/sbin/httpd -DFOREGROUND
               ├─1293 /usr/sbin/httpd -DFOREGROUND
               ├─1294 /usr/sbin/httpd -DFOREGROUND
               └─1295 /usr/sbin/httpd -DFOREGROUND
    ...

Como você pode ver nesta saída, o serviço parece ter sido iniciado com sucesso. No entanto, a melhor maneira de testar isso é solicitar uma página do Apache.

Você pode acessar a página inicial padrão do Apache para confirmar que o software está sendo executado corretamente através do seu endereço IP. Se você não souber o endereço IP do seu servidor, poderá obtê-lo de algumas maneiras diferentes a partir da linha de comando.

Digite isto no prompt de comando do seu servidor:

    hostname -I

Esse comando exibirá todos os endereços de rede do host, assim você receberá um retorno com alguns endereços IP separados por espaços. Você pode experimentar cada um em seu navegador para ver se eles funcionam.

Alternativamente, você pode usar o `curl` para solicitar seu IP através do `icanhazip.com`, que lhe dará seu endereço IPv4 público como visto de outro local na internet:

    curl -4 icanhazip.com

Quando você tiver o endereço IP do seu servidor, insira-o na barra de endereços do seu navegador:

    http://ip_do_seu_servidor

Você verá a página padrão do Apache do CentOS 7:

![Default Apache page for CentOS 7](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/CART-65406/apache_default_page.png)

Esta página indica que o Apache está funcionando corretamente. Ela também inclui algumas informações básicas sobre arquivos importantes do Apache e sobre localizações de diretórios. Agora que o serviço está instalado e em execução, você pode usar diferentes comandos `systemctl` para gerenciar o serviço.

## Passo 3 — Gerenciando o Processo do Apache

Agora que você tem seu servidor web funcionando, vamos passar por alguns comandos básicos de gerenciamento.

Para parar seu servidor web, digite:

    sudo systemctl stop httpd

Para iniciar o servidor web quando ele estiver parado, digite:

    sudo systemctl start httpd

Para parar e iniciar o serviço novamente, digite:

    sudo systemctl restart httpd

Se você estiver simplesmente fazendo alterações de configuração, o Apache pode muita vezes recarregar sem perder conexões. Para fazer isso, use este comando:

    sudo systemctl reload httpd

Por padrão, o Apache é configurado para iniciar automaticamente quando o servidor é inicializado. Se isso não é o que você deseja, desabilite esse comportamento digitando:

    sudo systemctl disable httpd

Para reativar o serviço para iniciar na inicialização, digite:

    sudo systemctl enable httpd

O Apache agora será iniciado automaticamente quando o servidor inicializar novamente.

A configuração padrão do Apache permitirá que seu servidor hospede um único site. Se você planeja hospedar vários domínios em seu servidor, precisará configurar virtual hosts em seu servidor Apache.

## Passo 4 — Configurando Virtual Hosts (Recomendado)

Ao utilizar o servidor web Apache, você pode usar _virtual hosts_ (similares aos blocos do servidor no Nginx) para encapsular detalhes de configuração e hospedar mais de um domínio a partir de um único servidor. Neste passo você irá configurar um domínio chamado `example.com`, mas você deve substituí-lo por seu próprio nome de domínio. Para aprender mais sobre a configuração de um nome de domínio com a DigitalOcean, veja nossa [Introdução ao DNS da DigitalOcean](an-introduction-to-digitalocean-dns).

O Apache no CentOS 7 tem um bloco de servidor ativado por padrão que é configurado para servir documentos a partir do diretório `/var/www/html`. Apesar disso funcionar bem para um único site, pode ficar difícil se você estiver hospedando vários sites. Em vez de modificar `/var/www/html`, você irá criar uma estrutura de diretórios dentro de `/var/www` para o site `example.com`, deixando `/var/www/html` no lugar como o diretório padrão a ser servido se uma requisição de cliente não corresponder a nenhum outro site.

Crie o diretório `html` para `example.com` como segue, usando a flag `-p` para criar qualquer diretório pai que for necessário:

    sudo mkdir -p /var/www/example.com/html

Crie um diretório adicional para armazenar arquivos de log para o site:

    sudo mkdir -p /var/www/example.com/log

Em seguida, atribua a propriedade do diretório `html` com a variável de ambiente `$USER`:

    sudo chown -R $USER:$USER /var/www/example.com/html

Certifique-se de que seu web root ou pasta raiz para web tenha o conjunto de permissões padrão:

    sudo chmod -R 755 /var/www

Em seguida, crie uma página de exemplo `index.html` usando o `vi` ou seu editor favorito:

    sudo vi /var/www/example.com/html/index.html

Pressione `i` para alternar para o modo `INSERT` e adicione o seguinte exemplo de HTML ao arquivo:

/var/www/example.com/html/index.html

    <html>
      <head>
        <title>Welcome to Example.com!</title>
      </head>
      <body>
        <h1>Success! The example.com virtual host is working!</h1>
      </body>
    </html>

Salve e feche o arquivo pressionando `ESC`, digitando `:wq` e pressionando `ENTER`.

Com o diretório do seu site e o arquivo de index de exemplo no lugar, você está quase pronto para criar os arquivos do virtual host. Os arquivos do virtual host especificam a configuração de seus sites independentes e informam ao servidor Apache como responder a várias solicitações de domínio.

Antes de criar seus virtual hosts, você precisará criar um diretório `sites-available` para armazená-los. Você também criará o diretório `sites-enabled` que informa ao Apache que um virtual host está pronto para servir aos visitantes. O diretório `sites-enabled` conterá links simbólicos para os virtual hosts que queremos publicar. Crie ambos os diretórios com o seguinte comando:

    sudo mkdir /etc/httpd/sites-available /etc/httpd/sites-enabled

Em seguida, você dirá ao Apache para procurar por virtual hosts no diretório `sites-enabled`. Para fazer isso, edite o arquivo de configuração principal do Apache e adicione uma linha declarando um diretório opcional para arquivos de configuração adicionais:

    sudo vi /etc/httpd/conf/httpd.conf

Adicione esta linha ao final do arquivo:

    IncludeOptional sites-enabled/*.conf

Salve e feche o arquivo quando terminar de adicionar essa linha. Agora que você tem seus diretórios de virtual host no lugar, você criará seu arquivo de virtual host.

Comece criando um novo arquivo no diretório `sites-available`:

    sudo vi /etc/httpd/sites-available/example.com.conf

Adicione o seguinte bloco de configuração e altere o domínio `example.com` para o seu nome de domínio:

/etc/httpd/sites-available/example.com.conf

    <VirtualHost *:80>
        ServerName www.example.com
        ServerAlias example.com
        DocumentRoot /var/www/example.com/html
        ErrorLog /var/www/example.com/log/error.log
        CustomLog /var/www/example.com/log/requests.log combined
    </VirtualHost>

Isso dirá ao Apache onde encontrar diretamente a raiz que contém os documentos web publicamente acessíveis. Ele também informa ao Apache onde armazenar logs de erros e de solicitações para esse site específico.

Salve e feche o arquivo quando terminar.

Agora que você criou os arquivos do virtual host, você os habilitará para que o Apache saiba como servi-los aos visitantes. Para fazer isso, crie um link simbólico para cada virtual host no diretório `sites-enabled`:

    sudo ln -s /etc/httpd/sites-available/example.com.conf /etc/httpd/sites-enabled/example.com.conf

Seu virtual host agora está configurado e pronto para servir conteúdo. Antes de reiniciar o serviço Apache, vamos garantir que o SELinux tenha as políticas corretas em vigor para seus virtual hosts.

## Passo 5 — Ajustando Permissões do SELinux para Virtual Hosts (Recomendado)

O [SELinux](https://www.digitalocean.com/community/tutorial_series/an-introduction-to-selinux-on-centos-7) está configurado para funcionar com a configuração padrão do Apache. Como você configurou um diretório de log personalizado no arquivo de configuração de virtual hosts, você receberá um erro se tentar iniciar o serviço Apache. Para resolver isso, você precisa atualizar as políticas do SELinux para permitir que o Apache grave nos arquivos necessários. O SELinux traz maior segurança ao seu ambiente CentOS 7, portanto, não é recomendado desativar completamente o módulo do kernel.

Existem diferentes maneiras de definir políticas com base nas necessidades do seu ambiente, pois o SELinux permite que você personalize seu nível de segurança. Esta etapa abordará dois métodos de ajuste das políticas do Apache: universalmente e em um diretório específico. Ajustar políticas em diretórios é mais seguro e, portanto, é a abordagem recomendada.

### Ajustando Políticas do Apache Universalmente

Definir a política do Apache universalmente dirá ao SELinux para tratar todos os processos do Apache de forma idêntica usando o booleano `httpd_unified`. Embora essa abordagem seja mais conveniente, ela não fornecerá o mesmo nível de controle que uma abordagem centrada em uma diretiva de arquivo ou diretório.

Execute o seguinte comando para definir uma política universal para o Apache:

    sudo setsebool -P httpd_unified 1

O comando `setsebool` altera os valores booleanos do SELinux. A flag `-P` atualizará o valor de tempo de inicialização, fazendo com que essa mudança persista durante as reinicializações. `httpd_unified` é o booleano que irá dizer ao SELinux para tratar todos os processos do Apache como do mesmo tipo, então você habilitou-o com um valor de `1`.

### Ajustando as Políticas do Apache em um Diretório

Configurar individualmente as permissões do SELinux para o diretório `/var/www/example.com/log` lhe dará mais controle sobre suas políticas do Apache, mas também pode exigir mais manutenção. Como essa opção não está definindo políticas universalmente, você precisará definir manualmente o tipo de contexto para todos os novos diretórios de log especificados em suas configurações de virtual host.

Primeiro, verifique o tipo de contexto que o SELinux deu ao diretório `/var/www/example.com/log`:

    sudo ls -dZ /var/www/example.com/log/

Este comando lista e imprime o contexto do SELinux do diretório. Você verá uma saída semelhante à seguinte:

    Outputdrwxr-xr-x. root root unconfined_u:object_r:httpd_sys_content_t:s0 /var/www/example.com/log/

O contexto atual é `httpd_sys_content_t`, que informa ao SELinux que o processo do Apache só pode ler arquivos criados neste diretório. Neste tutorial, você irá alterar o tipo de contexto do diretório `/var/www/example.com/log` para `httpd_log_t`. Esse tipo permitirá ao Apache gerar e agregar arquivos de log da aplicação web:

    sudo semanage fcontext -a -t httpd_log_t "/var/www/example.com/log(/.*)?"

Em seguida, use o comando `restorecon` para aplicar essas mudanças e fazer com que elas persistam durante as reinicializações:

    sudo restorecon -R -v /var/www/example.com/log

A flag `-R` executa este comando recursivamente, o que significa que ele atualizará quaisquer arquivos existentes para usar o novo contexto. A flag `-v` imprimirá as mudanças de contexto feitas pelo comando. Você verá a seguinte saída confirmando as alterações:

    Outputrestorecon reset /var/www/example.com/log context unconfined_u:object_r:httpd_sys_content_t:s0->unconfined_u:object_r:httpd_log_t:s0

Você pode listar os contextos mais uma vez para ver as alterações:

    sudo ls -dZ /var/www/example.com/log/

A saída reflete o tipo de contexto atualizado:

    Outputdrwxr-xr-x. root root unconfined_u:object_r:httpd_log_t:s0 /var/www/example.com/log

Agora que o diretório `/var/www/example.com/log` está usando o tipo `httpd_log_t`, você está pronto para testar sua configuração de virtual host.

## Passo 6 — Testando o Virtual Host (Recomendado)

Uma vez que o contexto do SELinux tenha sido atualizado com quaisquer dos métodos, o Apache poderá gravar no diretório `/var/www/example.com/log`. Agora você pode reiniciar o serviço Apache com sucesso:

    sudo systemctl restart httpd

Liste o conteúdo do diretório `/var/www/example.com/log` para ver se o Apache criou os arquivos de log:

    ls -lZ /var/www/example.com/log

Você verá que o Apache foi capaz de criar os arquivos `error.log` e `requests.log` especificados na configuração do virtual host:

    Output-rw-r--r--. 1 root root 0 Feb 26 22:54 error.log
    -rw-r--r--. 1 root root 0 Feb 26 22:54 requests.log

Agora que você tem seu virtual host configurado e as permissões do SELinux atualizadas, o Apache agora servirá seu nome de domínio. Você pode testar isso navegando até `http://example.com`, onde você deve ver algo assim:

![Success! The example.com virtual host is working!](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/CART-65406/virtual_host_success.png)

Isso confirma que seu virtual host foi configurado e está servindo o conteúdo com êxito. Repita os Passos 4 e 5 para criar novos virtual hosts com permissões do SELinux para domínios adicionais.

## Conclusão

Neste tutorial, você instalou e gerenciou o servidor web Apache. Agora que você tem seu servidor web instalado, você tem muitas opções para o tipo de conteúdo que você pode servir e as tecnologias que você pode usar para criar uma experiência mais rica.

Se você quiser criar uma pilha ou stack de aplicação mais completa, consulte este artigo sobre como configurar uma [pilha LAMP no CentOS 7](how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7#step-four-%E2%80%94-test-php-processing-on-your-web-server).
