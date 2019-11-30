---
author: Hazel Virdó, Kathleen Juell
date: 2018-05-16
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-proteger-o-nginx-com-o-let-s-encrypt-no-ubuntu-18-04-pt
---

# Como Proteger o Nginx com o Let's Encrypt no Ubuntu 18.04

_Uma versão anterior desse tutorial foi escrita por [Hazel Virdó](https://www.digitalocean.com/community/users/hazelnut)_

### Introdução

O Let’s Encrypt é uma Autoridade de Certificação (CA) que fornece uma maneira fácil de obter e instalar [certificados gratuitos TLS/SSL](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs), permitindo assim, HTTPS criptografado em servidores web. Ele simplifica o processo através do fornecimento de software cliente, que tenta automatizar a maioria (se não todos) dos passos requeridos. Atualmente, o processo inteiro de obtenção e instalação de um certificado é totalmente automatizado, tanto no Apache quanto no Nginx.

Neste tutorial, vamos utilizar o Certbot para obter um certificado SSL gratuito para o Nginx no Ubuntu 18.04 e configurar o seu certificado para renovar automaticamente.

Este tutorial utilizará um arquivo de bloco do servidor Nginx separado em vez do arquivo padrão. [Recomendamos](how-to-install-nginx-on-ubuntu-18-04#step-5-setting-up-server-blocks-(recommended)) a criação de novos arquivos de bloco do servidor Nginx para cada domínio porque isso ajuda a evitar erros comuns e a manter os arquivos padrão como uma configuração de reserva.

## Pré-requisitos

Para seguir este tutorial, você vai precisar de:

- Um servidor Ubuntu 18.04 configurado seguindo esse [tutorial de configuração inicial de servidor com Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04), incluindo um usuário que não seja root e um firewall.

- Um nome de domínio totalmente registrado. Vamos utilizar **example.com** durante todo o tutorial. Você pode comprar um nome de domínio no [Namecheap](https://namecheap.com/), obter um gratuito no [Freenom](http://www.freenom.com/en/index.html), ou utilizar um registrador de domínios à sua escolha.

- Ambos os registros de DNS a seguir configurados para o seu servidor. Você pode seguir [essa introdução ao DNS da DigitalOcean](an-introduction-to-digitalocean-dns) para detalhes de como adicioná-los.

- Nginx instalado seguindo [Como Instalar o Nginx no Ubuntu 18.04](how-to-install-nginx-on-ubuntu-18-04). Certifique-se de que você tem um bloco de servidor para o seu domínio. Este tutorial irá utilizar `/etc/nginx/sites-available/example.com` como um exemplo.

## Passo 1 — Instalando o Certbot

O primeiro passo para utilizar o Let’s Encrypt para obter um certificado SSL é instalar o software Certbot em seu servidor.

O Certbot está em pleno desenvolvimento, dessa forma, os pacotes fornecidos pelo Ubuntu tendem a estar desatualizados. Contudo, os desenvolvedores do Certbot mantém um repositório de software Ubuntu com versões atualizadas, então vamos usar esse repositório.

Primeiro, adicione o repositório:

    sudo add-apt-repository ppa:certbot/certbot

Você vai precisar pressionar `ENTER` para aceitar. Depois, atualize a lista de pacotes para pegar as novas informações de pacotes do repositório:

    sudo apt update

E, finalmente, instale o pacote Nginx do Certbot com o `apt`:

    sudo apt install python-certbot-nginx

O Certbot está pronto para uso agora, mas para que ele configure o SSL para o Nginx, precisamos verificar algumas configurações do Nginx.

## Passo 2 — Confirmando a Configuração do Nginx

O Certbot precisa ser capaz de encontrar o bloco `server` correto em sua configuração Nginx para que ele possa configurar automaticamente o SSL. Especificamente, ele faz isso buscando por uma diretiva `server_name` que corresponda ao domínio para o qual você requisitou o certificado.

Se você seguiu o [passo de configuração do bloco de servidor no tutorial de instalação do Nginx](how-to-install-nginx-on-ubuntu-18-04#step-5-setting-up-server-blocks-(recommended)), você deve ter um bloco de servidor para o seu domínio em `/etc/nginx/sites-available/example.com` com a diretiva `server_name` configurada apropriadamente.

Para verificar, abra o arquivo de bloco do servidor para o seu domínio usando o `nano` ou o seu editor de textos favorito:

    sudo nano /etc/nginx/sites-available/example.com

Encontre a linha `server_name` existente. Ela deve ser algo assim:

/etc/nginx/sites-available/example.com

    
    ...
    server_name example.com www.example.com;
    ...
    

Se ela existir, saia do seu editor e vá para o próximo passo.

Caso contrário, atualize a linha para corresponder. Depois salve o arquivo, saia do seu editor, e verifique a sintaxe da edição da sua configuração:

    sudo nginx -t

Se você receber um erro, reabra o arquivo de bloco do servidor e verifique se há erros de digitação ou caracteres ausentes. Quando a sintaxe do seu arquivo de configuração estiver correta, recarregue o Nginx para carregar a nova configuração:

    sudo systemctl reload nginx

O Certbot agora pode encontrar o bloco `server` correto e atualizá-lo.

Agora, vamos atualizar o firewall para permitir tráfego HTTPS.

## Passo 3 — Permitindo HTTPS Através do Firewall

Se você tem um firewall `ufw` ativado, como recomendado nos guias de pré-requisitos, você vai precisar ajustar as configurações para permitir o tráfego HTTPS. Felizmente, o Nginx registra alguns perfis com o `ufw` na instalação.

Você pode ver a configuração atual digitando:

    sudo ufw status

Isso provavelmente será assim, significando que somente o tráfego HTTPS está permitido para o servidor web:

Output

    Status: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Nginx HTTP ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Nginx HTTP (v6) ALLOW Anywhere (v6)
    

Para permitir adicionalmente o tráfego HTTPS, permita o perfil Nginx Full e exclua a permissão redundante do perfil Nginx HTTP:

    sudo ufw allow 'Nginx Full'
    sudo ufw delete allow 'Nginx HTTP'

Seu status deverá se parecer com isso:

    sudo ufw status

Output

    
    Status: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    Nginx Full ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    Nginx Full (v6) ALLOW Anywhere (v6)
    

Em seguida, vamos executar o Certbot e buscar nossos certificados.

## Passo 4 — Obtendo um Certificado SSL

O Certbot fornece uma variedade de maneiras de se obter certificados SSL através de plugins. O plugin Nginx cuida da reconfiguração do Nginx e do recarregamento da configuração sempre que necessário. Para utilizar esse plugin, digite o seguinte:

    sudo certbot --nginx -d example.com -d www.example.com

Isto executa o `certbot` com o plugin `--nginx`, usando `-d` para especificar os nomes para os quais queremos que os certificados sejam válidos.

Se esta é a primeira vez que você executa o `certbot`, você será solicitado a entrar com um endereço de e-mail e concordar com os termos do serviço. Depois de fazer isto, `certbot` vai se comunicar com o servidor do Let’s Encrypt, então executa um desafio para verificar que você controla o domínio para o qual você está solicitando um certificado.

Se isso for bem sucedido, o `certbot` perguntará como você gostaria de definir suas configurações de HTTPS.

Output

    Please choose whether or not to redirect HTTP traffic to HTTPS, removing HTTP access.
    -------------------------------------------------------------------------------
    1: No redirect - Make no further changes to the webserver configuration.
    2: Redirect - Make all requests redirect to secure HTTPS access. Choose this for
    new sites, or if you're confident your site works on HTTPS. You can undo this
    change by editing your web server's configuration.
    -------------------------------------------------------------------------------
    Select the appropriate number [1-2] then [enter] (press 'c' to cancel):

Selecione a sua escolha e pressione `ENTER`. A configuração será atualizada, e o Nginx irá recarregar para pegar as novas configurações. O `certbot` irá terminar com uma mensagem informando que o processo foi bem-sucedido e onde os seus certificados estão armazenados:

Output

    IMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at:
       /etc/letsencrypt/live/example.com/fullchain.pem
       Your key file has been saved at:
       /etc/letsencrypt/live/example.com/privkey.pem
       Your cert will expire on 2018-07-23. To obtain a new or tweaked
       version of this certificate in the future, simply run certbot again
       with the "certonly" option. To non-interactively renew *all* of
       your certificates, run "certbot renew"
     - Your account credentials have been saved in your Certbot
       configuration directory at /etc/letsencrypt. You should make a
       secure backup of this folder now. This configuration directory will
       also contain certificates and private keys obtained by Certbot so
       making regular backups of this folder is ideal.
     - If you like Certbot, please consider supporting our work by:
    
       Donating to ISRG / Let's Encrypt: https://letsencrypt.org/donate
       Donating to EFF: https://eff.org/donate-le
    

Seus certificados estão baixados, instalados, e carregados. Tente recarregar seu site web utilizando `https://` e observe o indicador de segurança do seu navegador. Ele deve indicar que o site está adequadamente seguro, normalmente com um ícone de um cadeado verde. Se você testar seu servidor usando o [teste de servidor do SSL Labs](https://www.ssllabs.com/ssltest/), ele lhe dará uma nota A.

Vamos terminar testando o processo de renovação.

## Passo 5 — Verificando a Auto-Renovação do Certbot

Os certificados Let’s Encrypt são válidos por apenas noventa dias. Isto é para encorajar os usuários a automatizar seus processos de renovação de certificado. O pacote `certbot` que instalamos cuida disto para nós ao adicionar um script ao `/etc/cron.d`. Este script executa duas vezes ao dia e irá renovar automaticamente qualquer certificado dentro de trinta dias da expiração.

Para testar o processo de renovação, você pode fazer um “dry” com `certbot`:

    sudo certbot renew --dry-run

Se você não visualizar nenhum erro, está tudo pronto. Quando necessário, o Certbot irá renovar seus certificados e recarregar o Nginx para pegar as alterações. Se o processo de renovação automatizado falhar, Let’s Encrypt enviará uma mensagem ao e-mail que você especificou, lhe avisando quando seu certificado estiver prestes a expirar.

## Conclusão

Neste tutorial, você instalou o cliente Let’s Encrypt `certbot`, baixou certificados SSL para o seu domínio, configurou o Nginx para utilizar estes certificados, e configurou a renovação automática do certificado. Se você tiver outras dúvidas sobre o uso do Certbot, [sua documentação](https://certbot.eff.org/docs/) é um bom lugar para iniciar.
