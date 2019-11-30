---
author: Justin Ellingwood, Vadym Kalsin
date: 2019-03-01
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-elasticsearch-logstash-e-kibana-elastic-stack-no-ubuntu-18-04-pt
---

# Como Instalar Elasticsearch, Logstash e Kibana (Elastic Stack) no Ubuntu 18.04

_O autor selecionou [o Internet Archive](https://www.brightfunds.org/organizations/internet-archive) para receber uma doação como parte do programa [Write for DOnations](https://do.co/w4do-cta)_

### Introdução

O Elastic Stack — anteriormente conhecido como _ELK Stack_ — é uma coleção de software open-source produzido pela [Elastic](https://www.elastic.co/) que lhe permite pesquisar, analisar e visualizar logs gerados a partir de qualquer fonte, em qualquer formato, em uma prática conhecida como _centralização de logs_. A centralização de logs pode ser muito útil ao tentar identificar problemas com seus servidores ou aplicativos, pois permite que você pesquise todos os seus logs em um único local. Ela é útil também porque permite identificar problemas que envolvem vários servidores, correlacionando seus logs durante um período de tempo específico.

O Elastic Stack possui quatro componentes principais:

- [**Elasticsearch**](https://www.elastic.co/products/elasticsearch): um mecanismo de pesquisa _[RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer)_ distribuído que armazena todos os dados coletados.

- [**Logstash**](https://www.elastic.co/products/logstash): o componente de processamento de dados do Elastic Stack que envia dados de entrada para o Elasticsearch.

- [**Kibana**](https://www.elastic.co/products/kibana): uma interface web para a pesquisa e a visualização de logs.

- [**Beats**](https://www.elastic.co/products/beats): carregadores de dados leves e de propósito único que podem enviar dados de centenas ou milhares de máquinas para o Logstash ou para o Elasticsearch.

Neste tutorial você irá instalar o [Elastic Stack](https://www.elastic.co/elk-stack) em um servidor Ubuntu 18.04. Você irá aprender como instalar todos os componentes do Elastic Stack — incluindo o [Filebeat](https://www.elastic.co/products/beats/filebeat), um Beat usado para encaminhar e centralizar logs e arquivos — e configurá-los para reunir e visualizar os logs do sistema. Além disso, como o Kibana normalmente está disponível apenas no `localhost`, usaremos o [Nginx](https://www.nginx.com/) para fazer proxy dele, de modo que ele seja acessível em um navegador web. Instalaremos todos esses componentes em um único servidor, o qual nos referiremos como nosso _servidor Elastic Stack_.

**Nota:** Ao instalar o Elastic Stack, você deve usar a mesma versão em toda a pilha ou stack. Neste tutorial vamos instalar as versões mais recentes de toda a stack, que são, no momento desta publicação, Elasticsearch 6.4.3, Kibana 6.4.3, Logstash 6.4.3 e Filebeat 6.4.3.

## Pré-requisitos

Para completar este tutorial, você irá precisar do seguinte:

- Um servidor Ubuntu configurado seguindo nosso [Guia de Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt), incluindo um usuário não-root com privilégios sudo e um firewall configurado com `ufw`. A quantidade de CPU, RAM e armazenamento que o seu servidor Elastic Stack exigirá depende do volume de logs que você pretende reunir. Para este tutorial, usaremos um VPS com as seguintes especificações para o nosso servidor Elastic Stack:

- Java 8 — que é exigido pelo Elasticsearch e pelo Logstash — instalado em seu servidor. Observe que o Java 9 não é suportado. Para istalar isso, siga a seção “[Installing the Oracle JDK](how-to-install-java-with-apt-on-ubuntu-18-04#installing-the-oracle-jdk)” do nosso guia sobre como instalar o Java 8 no Ubuntu 18.04. 

- Nginx instalado em seu servidor, que vamos configurar mais tarde neste guia como um proxy reverso para o Kibana. Siga nosso guia sobre [Como Instalar o Nginx no Ubuntu 18.04](como-instalar-o-nginx-no-ubuntu-18-04-pt) para configurar isso.

Além disso, como o Elastic Stack é usado para acessar informações valiosas sobre seu servidor, as quais você não deseja que usuários não autorizados acessem, é importante manter seu servidor seguro instalando um certificado TLS/SSL. Isso é opcional mas é **fortemente recomendado**.

No entanto, como você acabará fazendo alterações no bloco do servidor Nginx ao longo deste guia, provavelmente faria mais sentido para você concluir o guia [Como Proteger o Nginx com o Let’s Encrypt no Ubuntu 18.04](como-proteger-o-nginx-com-o-let-s-encrypt-no-ubuntu-18-04-pt) no final do segundo passo deste tutorial. Com isso em mente, se você planeja configurar o Let’s Encrypt no seu servidor, você precisará do seguinte, antes de fazer isso:

- Um domínio completamente qualificado (FQDN). Este tutorial irá utilizar `example.com` durante todo o processo. Você pode comprar um nome de domínio em [Namecheap](https://namecheap.com/), obter um gratuitamente em [Freenom](http://www.freenom.com/en/index.html), ou utilizar o registrador de domínio de sua escolha. 

- Ambos os registros DNS a seguir configurados para o seu servidor. Você pode seguir [esta introdução ao DigitalOcean DNS](an-introduction-to-digitalocean-dns) para detalhes sobre como adicioná-los. 

## Passo 1 — Instalando e Configurando o Elasticsearch

Os componentes do Elastic Stack não estão disponíveis nos repositórios de pacotes padrão do Ubuntu. Eles podem, no entanto, ser instalados com o APT após adicionar a lista de origens de pacotes da Elastic.

Todos os pacotes do Elastic Stack são assinados com a chave de assinatura do Elasticsearch para proteger seu sistema contra falsificação de pacotes. Os pacotes que foram autenticados usando a chave serão considerados confiáveis pelo seu gerenciador de pacotes. Nesta etapa, você importará a chave GPG pública do Elasticsearch e adicionará a lista de origens de pacotes da Elastic para instalar o Elasticsearch.

Para começar, execute o seguinte comando para importar a chave GPG pública do Elasticsearch para o APT:

    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

Em seguida, adicione a lista de origens da Elastic ao diretório `sources.list.d`, onde o APT irá procurar por novas origens:

    echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list

Em seguida, atualize suas listas de pacotes para que o APT leia a nova origem da Elastic:

    sudo apt update

Em seguida, instale o Elasticsearch com este comando:

    sudo apt install elasticsearch

Quando o Elasticsearch terminar a instalação, use seu editor de texto preferido para editar o arquivo de configuração principal do Elasticsearch, `elasticsearch.yml`. Aqui, usaremos o `nano`:

    sudo nano /etc/elasticsearch/elasticsearch.yml

**Nota:** O arquivo de configuração do Elasticsearch está no formato YAML, o que significa que a identação é muito importante! Certifique-se de não adicionar espaços extras ao editar esse arquivo.

O Elasticsearch escuta o tráfego vindo de qualquer lugar na porta `9200`. Você vai querer restringir o acesso externo à sua instância do Elasticsearch para impedir que pessoas de fora leiam seus dados ou desliguem o cluster do Elasticsearch por meio da API REST. Encontre a linha que especifica `network.host`, descomente-a e substitua seu valor por `localhost` para que fique assim:

/etc/elasticsearch/elasticsearch.yml

    . . .
    network.host: localhost
    . . .

Salve e feche o `elasticsearch.yml` pressionando `CTRL+X`, seguido de `Y` e depois`ENTER` se você estiver usando o `nano`. Em seguida, inicie o serviço Elasticsearch com o `systemctl`:

    sudo systemctl start elasticsearch

Depois, execute o seguinte comando para permitir que o Elasticsearch seja iniciado toda vez que o servidor for inicializado:

    sudo systemctl enable elasticsearch

Você pode testar se o serviço do Elasticsearch está sendo executado enviando uma solicitação HTTP:

    curl -X GET "localhost:9200"

Você verá uma resposta mostrando algumas informações básicas sobre o seu nó local, semelhante a esta:

    Output{
      "name" : "ZlJ0k2h",
      "cluster_name" : "elasticsearch",
      "cluster_uuid" : "beJf9oPSTbecP7_i8pRVCw",
      "version" : {
        "number" : "6.4.2",
        "build_flavor" : "default",
        "build_type" : "deb",
        "build_hash" : "04711c2",
        "build_date" : "2018-09-26T13:34:09.098244Z",
        "build_snapshot" : false,
        "lucene_version" : "7.4.0",
        "minimum_wire_compatibility_version" : "5.6.0",
        "minimum_index_compatibility_version" : "5.0.0"
      },
      "tagline" : "You Know, for Search"
    }

Agora que o Elasticsearch está instalado e funcionando, vamos instalar o Kibana, o próximo componente do Elastic Stack.

## Passo 2 — Instalando e Configurando o Painel do Kibana

De acordo com a [documentação oficial](https://www.elastic.co/guide/en/elastic-stack/current/installing-elastic-stack.html), você deve instalar o Kibana somente após instalar o Elasticsearch. A instalação nesta ordem garante que os componentes dos quais cada produto depende estão corretamente posicionados.

Como você já adicionou a origem de pacotes do Elastic no passo anterior, você pode simplesmente instalar os componentes restantes do Elastic Stack usando o `apt`:

    sudo apt install kibana

Em seguida, ative e inicie o serviço Kibana:

    sudo systemctl enable kibana
    sudo systemctl start kibana

Como o Kibana está configurado para escutar somente no `localhost`, devemos configurar um [proxy reverso](digitalocean-community-glossary#reverse-proxy) para permitir acesso externo a ele. Utilizaremos o Nginx para esse propósito, que já deve estar instalado no seu servidor.

Primeiro, use o comando `openssl` para criar um usuário administrativo do Kibana que será usado para acessar a interface web do mesmo. Como exemplo, nomearemos essa conta como `kibanaadmin`, mas para garantir maior segurança, recomendamos que você escolha um nome que não seja óbvio para seu usuário e que seja difícil de adivinhar.

O comando a seguir criará o usuário e a senha do usuário administrativo do Kibana e os armazenará no arquivo `htpasswd.users`. Você irá configurar o Nginx para requerer este nome de usuário e senha e ler este arquivo momentaneamente:

    echo "kibanaadmin:`openssl passwd -apr1`" | sudo tee -a /etc/nginx/htpasswd.users

Digite e confirme uma senha no prompt. Lembre-se ou anote este login, pois você precisará dele para acessar a interface web do Kibana.

Em seguida, criaremos um arquivo de bloco do servidor Nginx. Como exemplo, vamos nos referir a este arquivo como `example.com`, embora você possa achar útil dar um nome mais descritivo ao seu. Por exemplo, se você tiver um FQDN e registros DNS configurados para este servidor, poderá nomear esse arquivo após seu FQDN:

    sudo nano /etc/nginx/sites-available/example.com

Adicione o seguinte bloco de código ao arquivo, certificando-se de atualizar `example.com` para corresponder ao FQDN do seu servidor ou ao seu endereço IP público. Este código configura o Nginx para direcionar o tráfego HTTP do seu servidor para o aplicativo Kibana, que está escutando em `localhost:5601`. Além disso, configura o Nginx para ler o arquivo `htpasswd.users` e requerer autenticação básica.

Observe que, se você seguiu o [o tutorial de pré-requisitos do Nginx](como-instalar-o-nginx-no-ubuntu-18-04-pt) até o final, você já deve ter criado esse arquivo e preenchido com algum conteúdo. Nesse caso, exclua todo o conteúdo existente no arquivo antes de adicionar o seguinte:

/etc/nginx/sites-available/example.com

    
    server {
        listen 80;
    
        server_name example.com;
    
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/htpasswd.users;
    
        location / {
            proxy_pass http://localhost:5601;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }

Quando terminar, salve e feche o arquivo.

Em seguida, ative a nova configuração criando um link simbólico para o diretório `sites-enabled`. Se você já criou um arquivo de bloco do servidor com o mesmo nome no pré-requisito do Nginx, não será necessário executar este comando:

    sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/example.com

Em seguida, verifique a configuração para erros de sintaxe:

    sudo nginx -t

Se algum erro for relatado em sua saída, volte e verifique se o conteúdo que você colocou no seu arquivo de configuração foi adicionado corretamente. Uma vez que você veja `syntax is ok` na saída, vá em frente e reinicie o serviço Nginx:

    sudo systemctl restart nginx

Se você seguiu o guia de configuração inicial do servidor, você deverá ter um firewall UFW ativado. Para permitir conexões ao Nginx, podemos ajustar as regras digitando:

    sudo ufw allow 'Nginx Full'

**Nota:** Se você seguiu o tutorial de pré-requisitos do Nginx, você pode ter criado uma regra UFW permitindo o perfil `Nginx HTTP` através do firewall. Como o perfil `Nginx Full` permite o tráfego HTTP e HTTPS através do firewall, você pode excluir com segurança a regra criada no tutorial de pré-requisitos. Faça isso com o seguinte comando:

    sudo ufw delete allow 'Nginx HTTP'

O Kibana agora pode ser acessado pelo seu FQDN ou pelo endereço IP público do seu servidor Elastic Stack. Você pode verificar a página de status do servidor Kibana, navegando até o seguinte endereço e digitando suas credenciais de login quando solicitado:

    http://ip_do_seu_servidor/status

Essa página de status exibe informações sobre o uso de recursos do servidor e lista os plug-ins instalados.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/elastic_1804/kibana_status_page_md.png)

**Note:** Conforme mencionado na seção de Pré-requisitos, é recomendável ativar o SSL/TLS em seu servidor. Você pode seguir [este tutorial](como-proteger-o-nginx-com-o-let-s-encrypt-no-ubuntu-18-04-pt) agora para obter um certificado SSL grátis para o Nginx no Ubuntu 18.04. Depois de obter seus certificados SSL/TLS, você pode voltar e concluir este tutorial.

Agora que o painel do Kibana está configurado, vamos instalar o próximo componente: Logstash.

## Passo 3 — Instalando e Configurando o Logstash

Embora seja possível que o Beats envie dados diretamente para o banco de dados do Elasticsearch, recomendamos o uso do Logstash para processar os dados. Isso permitirá coletar dados de diferentes origens, transformá-los em um formato comum e exportá-los para outro banco de dados.

Instale o Logstash com este comando:

    sudo apt install logstash

Depois de instalar o Logstash, você pode continuar a configurá-lo. Os arquivos de configuração do Logstash são escritos no formato JSON e residem no diretório `/etc/logstash/conf.d`. Ao configurá-lo, é útil pensar no Logstash como um pipeline que coleta dados em uma extremidade, os processa de uma forma ou de outra e os envia para o destino (nesse caso, o destino é o Elasticsearch). Um pipeline do Logstash tem dois elementos obrigatórios, `input` e `output`, e um elemento opcional, `filter`. Os plugins de input ou de entrada consomem dados de uma fonte, os plug-ins filter ou de filtro processam os dados, e os plugins de output ou de saída gravam os dados em um destino.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/elastic_1804/logstash_pipeline_updated.png)

Crie um arquivo de configuração chamado `02-beats-input.conf` onde você irá configurar sua entrada para o Filebeat:

    sudo nano /etc/logstash/conf.d/02-beats-input.conf

Insira a seguinte configuração de `input`. Isto especifica uma entrada `beats` que irá escutar na porta TCP `5044`.

/etc/logstash/conf.d/02-beats-input.conf

    
    input {
      beats {
        port => 5044
      }
    }

Salve e feche o arquivo. Em seguida, crie um arquivo de configuração chamado `10-syslog-filter.conf`, onde adicionaremos um filtro para logs do sistema, também conhecido como _syslogs_:

    sudo nano /etc/logstash/conf.d/10-syslog-filter.conf

Insira a seguinte configuração do filtro syslog. Este exemplo de configuração de logs do sistema foi retirado da [documentação oficial do Elastic](https://www.elastic.co/guide/en/logstash/6.x/logstash-config-for-filebeat-modules.html#parsing-system). Esse filtro é usado para analisar os logs de entrada do sistema para torná-los estruturados e utilizáveis pelos painéis predefinidos do Kibana:

/etc/logstash/conf.d/10-syslog-filter.conf

    
    filter {
      if [fileset][module] == "system" {
        if [fileset][name] == "auth" {
          grok {
            match => { "message" => ["%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} sshd(?:\[%{POSINT:[system][auth][pid]}\])?: %{DATA:[system][auth][ssh][event]} %{DATA:[system][auth][ssh][method]} for (invalid user )?%{DATA:[system][auth][user]} from %{IPORHOST:[system][auth][ssh][ip]} port %{NUMBER:[system][auth][ssh][port]} ssh2(: %{GREEDYDATA:[system][auth][ssh][signature]})?",
                      "%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} sshd(?:\[%{POSINT:[system][auth][pid]}\])?: %{DATA:[system][auth][ssh][event]} user %{DATA:[system][auth][user]} from %{IPORHOST:[system][auth][ssh][ip]}",
                      "%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} sshd(?:\[%{POSINT:[system][auth][pid]}\])?: Did not receive identification string from %{IPORHOST:[system][auth][ssh][dropped_ip]}",
                      "%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} sudo(?:\[%{POSINT:[system][auth][pid]}\])?: \s*%{DATA:[system][auth][user]} :( %{DATA:[system][auth][sudo][error]} ;)? TTY=%{DATA:[system][auth][sudo][tty]} ; PWD=%{DATA:[system][auth][sudo][pwd]} ; USER=%{DATA:[system][auth][sudo][user]} ; COMMAND=%{GREEDYDATA:[system][auth][sudo][command]}",
                      "%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} groupadd(?:\[%{POSINT:[system][auth][pid]}\])?: new group: name=%{DATA:system.auth.groupadd.name}, GID=%{NUMBER:system.auth.groupadd.gid}",
                      "%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} useradd(?:\[%{POSINT:[system][auth][pid]}\])?: new user: name=%{DATA:[system][auth][user][add][name]}, UID=%{NUMBER:[system][auth][user][add][uid]}, GID=%{NUMBER:[system][auth][user][add][gid]}, home=%{DATA:[system][auth][user][add][home]}, shell=%{DATA:[system][auth][user][add][shell]}$",
                      "%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} %{DATA:[system][auth][program]}(?:\[%{POSINT:[system][auth][pid]}\])?: %{GREEDYMULTILINE:[system][auth][message]}"] }
            pattern_definitions => {
              "GREEDYMULTILINE"=> "(.|\n)*"
            }
            remove_field => "message"
          }
          date {
            match => ["[system][auth][timestamp]", "MMM d HH:mm:ss", "MMM dd HH:mm:ss" ]
          }
          geoip {
            source => "[system][auth][ssh][ip]"
            target => "[system][auth][ssh][geoip]"
          }
        }
        else if [fileset][name] == "syslog" {
          grok {
            match => { "message" => ["%{SYSLOGTIMESTAMP:[system][syslog][timestamp]} %{SYSLOGHOST:[system][syslog][hostname]} %{DATA:[system][syslog][program]}(?:\[%{POSINT:[system][syslog][pid]}\])?: %{GREEDYMULTILINE:[system][syslog][message]}"] }
            pattern_definitions => { "GREEDYMULTILINE" => "(.|\n)*" }
            remove_field => "message"
          }
          date {
            match => ["[system][syslog][timestamp]", "MMM d HH:mm:ss", "MMM dd HH:mm:ss" ]
          }
        }
      }
    }

Salve e feche o arquivo quando terminar.

Por fim, crie um arquivo de configuração chamado `30-elasticsearch-output.conf`:

    sudo nano /etc/logstash/conf.d/30-elasticsearch-output.conf

Insira a seguinte configuração para `output`. Essencialmente, esta saída configura o Logstash para armazenar os dados do Beats no Elasticsearch, que está sendo executado em `localhost:9200`, em um índice ou index nomeado após o uso do Beat. O Beat usado neste tutorial é o Filebeat:

/etc/logstash/conf.d/30-elasticsearch-output.conf

    
    output {
      elasticsearch {
        hosts => ["localhost:9200"]
        manage_template => false
        index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
      }
    }

Salve e feche o arquivo.

Se você quiser adicionar filtros para outros aplicativos que usam a entrada Filebeat, certifique-se de nomear os arquivos de forma que eles sejam classificados entre a configuração de entrada e a de saída, o que significa que os nomes dos arquivos devem começar com um número de dois dígitos entre `02` e `30`.

Teste sua configuração do Logstash com este comando:

    sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t

Se não houver erros de sintaxe, sua saída exibirá `Configuration OK` após alguns segundos. Se você não vir isso na sua saída, verifique se há erros que apareçam na sua saída e atualize sua configuração para corrigi-los.

Se seu teste de configuração for bem-sucedido, inicie e ative o Logstash para colocar as mudanças de configuração em vigor:

    sudo systemctl start logstash
    sudo systemctl enable logstash

Agora que o Logstash está sendo executado corretamente e está totalmente configurado, vamos instalar o Filebeat.

## Passo 4 — Instalando e Configurando o Filebeat

O Elastic Stack usa vários carregadores de dados leves chamados Beats para coletar dados de várias fontes e transportá-los para o Logstash ou para o Elasticsearch. Aqui estão os Beats que estão atualmente disponíveis na Elastic:

- [Filebeat](https://www.elastic.co/products/beats/filebeat): coleta e envia arquivos de log.

- [Metricbeat](https://www.elastic.co/products/beats/metricbeat): coleta métricas de seus sistemas e serviços.

- [Packetbeat](https://www.elastic.co/products/beats/packetbeat): coleta e analisa dados da rede.

- [Winlogbeat](https://www.elastic.co/products/beats/winlogbeat): coleta logs de eventos do Windows.

- [Auditbeat](https://www.elastic.co/products/beats/auditbeat): coleta dados da estrutura de auditoria do Linux e monitora a integridade dos arquivos.

- [Heartbeat](https://www.elastic.co/products/beats/heartbeat): monitora serviços para verificar sua disponibilidade com sondagem ativa.

Neste tutorial, usaremos o Filebeat para encaminhar logs locais para o nosso Elastic Stack.

Instale o Filebeat usando o `apt`:

    sudo apt install filebeat

Em seguida, configure o Filebeat para se conectar ao Logstash. Aqui, vamos modificar o arquivo de configuração de exemplo que vem com o Filebeat.

Abra o arquivo de configuração do Filebeat:

    sudo nano /etc/filebeat/filebeat.yml

**Nota:** Assim como no Elasticsearch, o arquivo de configuração do Filebeat está no formato YAML. Isso significa que a identação adequada é crucial, portanto, certifique-se de usar o mesmo número de espaços indicados nestas instruções.

O Filebeat suporta várias saídas, mas normalmente você só envia eventos diretamente para o Elasticsearch ou para o Logstash para processamento adicional. Neste tutorial, usaremos o Logstash para executar processamento adicional nos dados coletados pelo Filebeat. O Filebeat não precisará enviar nenhum dado diretamente para o Elasticsearch, então vamos desativar essa saída. Para fazer isso, encontre a seção `output.elasticsearch` e comente as seguintes linhas, precedendo-as com um `#`:

/etc/filebeat/filebeat.yml

    
    ...
    #output.elasticsearch:
      # Array of hosts to connect to.
      #hosts: ["localhost:9200"]
    ...

Em seguida, configure a `seção output.logstash`. Descomente as linhas `output.logstash`: e `hosts:` `["localhost:5044"]` removendo o `#`. Isto irá configurar o Filebeat para se conectar ao Logstash no seu servidor Elastic Stack na porta `5044`, a porta para a qual especificamos uma entrada do Logstash anteriormente:

/etc/filebeat/filebeat.yml

    
    output.logstash:
      # The Logstash hosts
      hosts: ["localhost:5044"]

Salve e feche o arquivo.

A funcionalidade do Filebeat pode ser estendida com os [módulos do Filebeat](https://www.elastic.co/guide/en/beats/filebeat/6.4/filebeat-modules.html). Neste tutorial vamos usar o módulo [system](https://www.elastic.co/guide/en/beats/filebeat/6.4/filebeat-module-system.html), que coleta e analisa logs criados pelo serviço de logs do sistema em distribuições comuns do Linux.

Vamos habilitar isso:

    sudo filebeat modules enable system

Você pode ver uma lista de módulos ativados e desativados executando:

    sudo filebeat modules list

Você verá uma lista semelhante à seguinte:

    OutputEnabled:
    system
    
    Disabled:
    apache2
    auditd
    elasticsearch
    icinga
    iis
    kafka
    kibana
    logstash
    mongodb
    mysql
    nginx
    osquery
    postgresql
    redis
    traefik

Por padrão, o Filebeat é configurado para usar os caminhos padrão para os logs de syslog e de autorização. No caso deste tutorial, você não precisa alterar nada na configuração. Você pode ver os parâmetros do módulo no arquivo de configuração `/etc/filebeat/modules.d/system.yml`.

Em seguida, carregue o modelo de [_index do Elasticsearch_](https://www.elastic.co/guide/en/elasticsearch/reference/current/_basic_concepts.html#_index). Um index do Elasticsearch é uma coleção de documentos que possuem características semelhantes. Os index são identificados com um nome, que é usado para se referir ao index ao executar várias operações dentro dele. O modelo de index será aplicado automaticamente quando um novo index for criado.

Para carregar o modelo, use o seguinte comando:

    sudo filebeat setup --template -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'

    OutputLoaded index template

O Filebeat vem com painéis de amostra do Kibana que lhe permitem visualizar dados do Filebeat no Kibana. Antes de poder usar os painéis, você precisa criar o padrão de index e carregar os painéis no Kibana.

À medida que os painéis são carregados, o Filebeat se conecta ao Elasticsearch para verificar as informações da versão. Para carregar painéis quando o Logstash está ativado, é necessário desativar a saída do Logstash e ativar a saída do Elasticsearch:

    sudo filebeat setup -e -E output.logstash.enabled=false -E output.elasticsearch.hosts=['localhost:9200'] -E setup.kibana.host=localhost:5601

Você verá uma saída que se parece com isto:

    Output2018-09-10T08:39:15.844Z INFO instance/beat.go:273 Setup Beat: filebeat; Version: 6.4.2
    2018-09-10T08:39:15.845Z INFO elasticsearch/client.go:163 Elasticsearch url: http://localhost:9200
    2018-09-10T08:39:15.845Z INFO pipeline/module.go:98 Beat name: elk
    2018-09-10T08:39:15.845Z INFO elasticsearch/client.go:163 Elasticsearch url: http://localhost:9200
    2018-09-10T08:39:15.849Z INFO elasticsearch/client.go:708 Connected to Elasticsearch version 6.4.2
    2018-09-10T08:39:15.856Z INFO template/load.go:129 Template already exists and will not be overwritten.
    Loaded index template
    Loading dashboards (Kibana must be running and reachable)
    2018-09-10T08:39:15.857Z INFO elasticsearch/client.go:163 Elasticsearch url: http://localhost:9200
    2018-09-10T08:39:15.865Z INFO elasticsearch/client.go:708 Connected to Elasticsearch version 6.4.2
    2018-09-10T08:39:15.865Z INFO kibana/client.go:113 Kibana url: http://localhost:5601
    2018-09-10T08:39:45.357Z INFO instance/beat.go:659 Kibana dashboards successfully loaded.
    Loaded dashboards
    2018-09-10T08:39:45.358Z INFO elasticsearch/client.go:163 Elasticsearch url: http://localhost:9200
    2018-09-10T08:39:45.361Z INFO elasticsearch/client.go:708 Connected to Elasticsearch version 6.4.2
    2018-09-10T08:39:45.361Z INFO kibana/client.go:113 Kibana url: http://localhost:5601
    2018-09-10T08:39:45.455Z WARN fileset/modules.go:388 X-Pack Machine Learning is not enabled
    Loaded machine learning job configurations

Agora você pode iniciar e ativar o Filebeat:

    sudo systemctl start filebeat
    sudo systemctl enable filebeat

Se você configurou seu Elastic Stack corretamente, o Filebeat começará a enviar seus registros de log e autorização para o Logstash, que então carregará esses dados no Elasticsearch.

Para verificar se o Elasticsearch está realmente recebendo esses dados, consulte o index do Filebeat com este comando:

    curl -XGET 'http://localhost:9200/filebeat-*/_search?pretty'

Você verá uma saída semelhante a esta:

    Output...
    {
      "took" : 32,
      "timed_out" : false,
      "_shards" : {
        "total" : 3,
        "successful" : 3,
        "skipped" : 0,
        "failed" : 0
      },
      "hits" : {
        "total" : 1641,
        "max_score" : 1.0,
        "hits" : [
          {
            "_index" : "filebeat-6.4.2-2018.10.10",
            "_type" : "doc",
            "_id" : "H_bZ62UBB4D0uxFRu_h3",
            "_score" : 1.0,
            "_source" : {
              "@version" : "1",
              "message" : "Oct 10 06:22:36 elk systemd[1]: Reached target Local File Systems (Pre).",
              "@timestamp" : "2018-10-10T08:43:56.969Z",
              "host" : {
                "name" : "elk"
              },
              "source" : "/var/log/syslog",
              "input" : {
                "type" : "log"
              },
              "tags" : [
                "beats_input_codec_plain_applied"
              ],
              "offset" : 296,
              "prospector" : {
                "type" : "log"
              },
              "beat" : {
                "version" : "6.4.2",
                "hostname" : "elk",
                "name" : "elk"
              }
            }
          },
    ...

Se a sua saída mostrar 0 total hits, o Elasticsearch não está carregando nenhum registro sob o index que você pesquisou, e você precisará revisar sua configuração para verificar erros. Se você recebeu a saída esperada, continue para a próxima etapa, na qual veremos como navegar em alguns dos painéis do Kibana.

## Passo 5 — Explorando os Painéis do Kibana

Vamos dar uma olhada no Kibana, a interface web que instalamos anteriormente.

Em um navegador web, vá para o FQDN ou endereço IP público do seu servidor Elastic Stack. Depois de inserir as credenciais de login que você definiu no Passo 2, você verá a página inicial do Kibana:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/elastic_1804/kibana_homepage_md.png)

Clique no link **Discover** na barra de navegação à esquerda. Na página **Discover** , selecione o padrão de index predefinido **filebeat-\*** para ver os dados do Filebeat. Por padrão, isso mostrará todos os dados do log nos últimos 15 minutos. Você verá um histograma com eventos de log, e algumas mensagens de log como abaixo:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/elastic_1804/discover_page_md.png)

Aqui, você pode pesquisar e navegar pelos seus logs e também personalizar seu painel. Neste ponto, porém, não haverá muita coisa porque você está apenas coletando syslogs do seu servidor Elastic Stack.

Use o painel esquerdo para navegar até a página **Dashboard** e pesquise pelos painéis do **Filebeat System**. Uma vez lá, você pode procurar os painéis de amostra que vêm com o módulo `system` do Filebeat.

Por exemplo, você pode visualizar estatísticas detalhadas com base em suas mensagens do syslog:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/elastic_1804/syslog_dashboard_md.png)

Você também pode ver quais usuários usaram o comando `sudo` e quando:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/elastic_1804/sudo_dashboard_md.png)

Kibana tem muitos outros recursos, como gráficos e filtragem, então sinta-se livre para explorar.

## Conclusão

Neste tutorial, você aprendeu como instalar e configurar o Elastic Stack para coletar e analisar logs do sistema. Lembre-se de que você pode enviar praticamente qualquer tipo de log ou dados indexados para o Logstash usando o [Beats](https://www.elastic.co/products/beats), mas os dados se tornam ainda mais úteis se forem analisados e estruturados com um filtro Logstash, pois isso transforma os dados em um formato consistente que pode ser lido facilmente pelo Elasticsearch.

Por Justin Ellingwood e Vadym Kalsin
