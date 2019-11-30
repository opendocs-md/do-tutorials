---
author: Erika Heidi
date: 2019-09-10
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-fazer-o-benchmark-de-um-servidor-redis-no-ubuntu-18-04-pt
---

# Como Fazer o Benchmark de um Servidor Redis no Ubuntu 18.04

### Introdução

O Benchmarking é uma prática importante quando se trata de analisar o desempenho geral dos servidores de banco de dados. É útil para identificar gargalos e oportunidades de melhoria nesses sistemas.

O [Redis](https://redis.io/) é um armazenamento de estrutura dados em memória que pode ser usado como banco de dados, cache e intermediador de mensagens ou message broker. Ele suporta desde estruturas de dados simples a complexas, incluindo hashes, strings, conjuntos classificados, bitmaps, dados geoespaciais, entre outros tipos. Neste guia, demonstraremos como fazer o benchmark de um servidor Redis em execução no Ubuntu 18.04, usando algumas ferramentas e métodos distintos.

## Pré-requisitos

Para seguir este guia, você precisará de:

- Um servidor Ubuntu 18.04 com um usuário não-root e um firewall básico configurado. Para configurar isso, você pode seguir nosso guia de [Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt).  
- O Redis instalado em seu servidor, conforme explicado em nosso guia [How to Install and Secure Redis on Ubuntu 18.04](how-to-install-and-secure-redis-on-ubuntu-18-04). 

**Nota:** Os comandos demonstrados neste tutorial foram executados em um servidor Redis dedicado rodando em um Droplet da DigitalOcean de 4 GB.

## Usando a ferramenta incluída `redis-benchmark`

O Redis vem com uma ferramenta de benchmark chamada `redis-benchmark`. Este programa pode ser usado para simular um número arbitrário de clientes se conectando ao mesmo tempo e executando ações no servidor, medindo quanto tempo leva para que as solicitações sejam concluídas. Os dados resultantes vão lhe fornecer uma ideia do número médio de solicitações que o seu servidor Redis é capaz de processar por segundo.

A lista a seguir detalha algumas das opções de comando comuns usadas com o `redis-benchmark`:

- `-h`: Host do Redis. O padrão é `127.0.0.1`.
- `-p`: Porta do Redis. O padrão é `6379`.
- `-a`: Se o seu servidor exigir autenticação, você poderá usar esta opção para fornecer a senha.
- `-c`: Número de clientes (conexões paralelas) a serem simulados. O valor padrão é 50.
- `-n`: Quantas requisições a fazer. O padrão é 100000.
- `-d`: Tamanho dos dados para os valores de `SET` e `GET`, medidos em bytes. O padrão é 3.
- `-t`: Execute apenas um subconjunto de testes. Por exemplo, você pode usar `-t get,set` para fazer o benchmark dos comandos `GET` e `SET`.
- `-q`: Modo silencioso, mostra apenas a informação sobre média de _requisições por segundo_.

Por exemplo, se você deseja verificar o número médio de solicitações por segundo que o seu servidor Redis local pode suportar, você pode usar:

    redis-benchmark -q 

Você obterá resultados semelhantes a este, mas com números diferentes:

    OutputPING_INLINE: 85178.88 requests per second
    PING_BULK: 83056.48 requests per second
    SET: 72202.16 requests per second
    GET: 94607.38 requests per second
    INCR: 84961.77 requests per second
    LPUSH: 78988.94 requests per second
    RPUSH: 88652.48 requests per second
    LPOP: 87950.75 requests per second
    RPOP: 80971.66 requests per second
    SADD: 80192.46 requests per second
    HSET: 84317.03 requests per second
    SPOP: 78125.00 requests per second
    LPUSH (needed to benchmark LRANGE): 84175.09 requests per second
    LRANGE_100 (first 100 elements): 52383.45 requests per second
    LRANGE_300 (first 300 elements): 21547.08 requests per second
    LRANGE_500 (first 450 elements): 14471.78 requests per second
    LRANGE_600 (first 600 elements): 9383.50 requests per second
    MSET (10 keys): 71225.07 requests per second
    

Você também pode limitar os testes a um subconjunto de comandos de sua escolha usando o parâmetro `-t`. O comando a seguir mostra as médias apenas dos comandos `GET` e`SET`:

    redis-benchmark -t set,get -q

    OutputSET: 76687.12 requests per second
    GET: 82576.38 requests per second

As opções padrão usarão 50 conexões paralelas para criar 100000 requisições ao servidor Redis. Se você deseja aumentar o número de conexões paralelas para simular um pico de uso, pode usar a opção `-c` para isso:

    redis-benchmark -t set,get -q -c 1000

Como isso usará 1000 conexões simultâneas em vez das 50 padrão, você deve esperar uma diminuição no desempenho:

    OutputSET: 69444.45 requests per second
    GET: 70821.53 requests per second

Se você quiser informações detalhadas na saída, poderá remover a opção `-q`. O comando a seguir usará 100 conexões paralelas para executar 1000000 requisições SET no servidor:

    redis-benchmark -t set -c 100 -n 1000000

Você obterá uma saída semelhante a esta:

    Output====== SET ======
      1000000 requests completed in 11.29 seconds
      100 parallel clients
      3 bytes payload
      keep alive: 1
    
    95.22% <= 1 milliseconds
    98.97% <= 2 milliseconds
    99.86% <= 3 milliseconds
    99.95% <= 4 milliseconds
    99.99% <= 5 milliseconds
    99.99% <= 6 milliseconds
    100.00% <= 7 milliseconds
    100.00% <= 8 milliseconds
    100.00% <= 8 milliseconds
    88605.35 requests per second
    

As configurações padrão usam 3 bytes para valores de chave. Você pode mudar isso com a opção `-d`. O comando a seguir fará o benchmark dos comandos `GET` e `SET` usando valores de chave de 1 MB:

    redis-benchmark -t set,get -d 1000000 -n 1000 -q

Como o servidor está trabalhando com um payload muito maior dessa vez, espera-se uma diminuição significativa do desempenho:

    OutputSET: 1642.04 requests per second
    GET: 822.37 requests per second

É importante perceber que, embora esses números sejam úteis como uma maneira rápida de avaliar o desempenho de uma instância Redis, eles não representam a taxa de transferência máxima que uma instância Redis pode suportar. Usando _[pipelining](https://redis.io/topics/pipelining)_, as aplicações podem enviar vários comandos ao mesmo tempo para melhorar o número de requisições por segundo que o servidor pode manipular. Com o `redis-benchmark`, você pode usar a opção `-P` para simular aplicações do mundo real que fazem uso desse recurso do Redis.

Para comparar a diferença, primeiro execute o comando `redis-benchmark` com valores padrão e sem pipelining, para os testes `GET` e `SET`:

    redis-benchmark -t get,set -q

    OutputSET: 86281.27 requests per second
    GET: 89847.26 requests per second

O próximo comando executará os mesmos testes, mas fará o pipeline de 8 comandos juntos:

    redis-benchmark -t get,set -q -P 8

    OutputSET: 653594.81 requests per second
    GET: 793650.75 requests per second

Como você pode ver na saída, há uma melhoria substancial no desempenho com o uso de pipelining.

## Checando a Latência com `redis-cli`

Se você deseja uma medição simples do tempo médio que uma requisição leva para receber uma resposta, você pode usar o cliente Redis para verificar a latência média do servidor. No contexto do Redis, latência é uma medida de quanto tempo um comando `ping` leva para receber uma resposta do servidor.

O comando a seguir mostrará estatísticas de latência em tempo real para seu servidor Redis:

    redis-cli --latency

Você obterá uma saída semelhante a esta, mostrando um número crescente de amostras e uma latência média variável:

    Outputmin: 0, max: 1, avg: 0.18 (970 samples)

Este comando continuará sendo executado indefinidamente. Você pode pará-lo com um `CTRL+C`.

Para monitorar a latência por um determinado período, você pode usar:

    redis-cli --latency-history

Isso irá acompanhar as médias de latência ao longo do tempo, com um intervalo configurável definido como 15 segundos por padrão. Você obterá uma saída semelhante a esta:

    Outputmin: 0, max: 1, avg: 0.18 (1449 samples) -- 15.01 seconds range
    min: 0, max: 1, avg: 0.16 (1449 samples) -- 15.00 seconds range
    min: 0, max: 1, avg: 0.17 (1449 samples) -- 15.00 seconds range
    min: 0, max: 1, avg: 0.17 (1444 samples) -- 15.01 seconds range
    min: 0, max: 1, avg: 0.17 (1446 samples) -- 15.01 seconds range
    min: 0, max: 1, avg: 0.17 (1449 samples) -- 15.00 seconds range
    min: 0, max: 1, avg: 0.16 (1444 samples) -- 15.00 seconds range
    min: 0, max: 1, avg: 0.17 (1445 samples) -- 15.01 seconds range
    min: 0, max: 1, avg: 0.16 (1445 samples) -- 15.01 seconds range
    ...

Como o servidor Redis em nosso exemplo está ocioso, não há muita variação entre as amostras de latência. Se você tem um pico de uso, no entanto, isso deve ser refletido como um aumento na latência dentro dos resultados.

Se você deseja medir apenas a latência do _sistema_, pode usar `--intrinsic-latency` para isso. A latência intrínseca é inerente ao ambiente, dependendo de fatores como hardware, kernel, vizinhança do servidor e outros fatores que não são controlados pelo Redis.

Você pode ver a latência intrínseca como uma linha de base para o desempenho geral do Redis. O comando a seguir verificará a latência intrínseca do sistema, executando um teste por 30 segundos:

    redis-cli --intrinsic-latency 30

Você deve obter uma saída semelhante a esta:

    Output…
    
    498723744 total runs (avg latency: 0.0602 microseconds / 60.15 nanoseconds per run).
    Worst run took 22975x longer than the average latency.

Comparar os dois testes de latência pode ser útil para identificar gargalos de hardware ou sistema que podem afetar o desempenho do seu servidor Redis. Considerando que a latência total de uma requisição para o nosso servidor de exemplo tem uma média de 0,18 microssegundos para concluir, uma latência intrínseca de 0,06 microssegundos significa que um terço do tempo total da requisição é gasto pelo sistema em processos que não são controlados pelo Redis.

## Usando a Ferramenta Memtier Benchmark

O [Memtier](https://github.com/RedisLabs/memtier_benchmark) é uma ferramenta de benchmark de alto rendimento para Redis e [Memcached](https://memcached.org/) criada pelo Redis Labs. Embora muito parecido com o `redis-benchmark` em vários aspectos, o Memtier possui várias opções de configuração que podem ser ajustadas para emular melhor o tipo de carga que você pode esperar no seu servidor Redis, além de oferecer suporte a cluster.

Para instalar o Memtier em seu servidor, você precisará compilar o software a partir do código-fonte. Primeiro, instale as dependências necessárias para compilar o código:

    sudo apt-get install build-essential autoconf automake libpcre3-dev libevent-dev pkg-config zlib1g-dev

Em seguida, vá para o seu diretório home e clone o projeto `memtier_benchmark` do [repositório Github](https://github.com/RedisLabs/memtier_benchmark):

    cd
    git clone https://github.com/RedisLabs/memtier_benchmark.git

Navegue para o diretório do projeto e execute o comando `autoreconf` para gerar os scripts de configuração do aplicativo:

    cd memtier_benchmark
    autoreconf -ivf

Execute o script `configure` para gerar os artefatos do aplicativo necessários para a compilação:

    ./configure

Agora execute `make` para compilar o aplicativo:

    make

Após a conclusão da compilação, você pode testar o executável com:

    ./memtier_benchmark --version

Isso lhe fornecerá a seguinte saída:

    Outputmemtier_benchmark 1.2.17
    Copyright (C) 2011-2017 Redis Labs Ltd.
    This is free software. You may redistribute copies of it under the terms of
    the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
    There is NO WARRANTY, to the extent permitted by law.

A lista a seguir contém algumas das opções mais comuns usadas com o comando `memtier_benchmark`:

- `-s`: Host do Servidor. O padrão é **localhost**.
- `-p`: Porta do Servidor. O padrão é `6379`.
- `-a`: Autentica requisições usando a senha fornecida.
- `-n`: Número de requisições por cliente (o padrão é 10000).
- `-c`: Número de clientes (o padrão é 50).
- `-t`: Número de threads (o padrão é 4).
- `--pipeline`: Ativar pipelining.
- `--ratio`: Relação entre os comandos `SET` e `GET`, o padrão é 1:10.
- `--hide-histogram`: Oculta informações detalhadas de saída.

A maioria dessas opções é muito semelhante às opções presentes no `redis-benchmark`, mas o Memtier testa o desempenho de uma maneira diferente. Para simular melhor os ambientes comuns do mundo real, o benchmark padrão realizado pelo `memtier_benchmark` testará apenas as solicitações `GET` e `SET`, na proporção de 1 a 10. Com 10 operações GET para cada operação SET no teste, esse arranjo é mais representativo de uma aplicação web comum usando o Redis como banco de dados ou cache. Você pode ajustar o valor da taxa com a opção `--ratio`.

O comando a seguir executa o `memtier_benchmark` com as configurações padrão, fornecendo apenas informações de saída de alto nível:

    ./memtier_benchmark --hide-histogram

**Nota** : se você configurou seu servidor Redis para exigir autenticação, você deve fornecer a opção `-a` junto com sua senha Redis ao comando `memtier_benchmark`:

    ./memtier_benchmark --hide-histogram -a sua_senha_redis

Você verá resultados semelhantes a este:

    Output...
    
    4 Threads
    50 Connections per thread
    10000 Requests per client
    
    
    ALL STATS
    =========================================================================
    Type Ops/sec Hits/sec Misses/sec Latency KB/sec 
    -------------------------------------------------------------------------
    Sets 8258.50 --- --- 2.19800 636.05 
    Gets 82494.28 41483.10 41011.18 2.19800 4590.88 
    Waits 0.00 --- --- 0.00000 --- 
    Totals 90752.78 41483.10 41011.18 2.19800 5226.93 

De acordo com esta execução do `memtier_benchmark`, nosso servidor Redis pode executar cerca de 90 mil operações por segundo na proporção 1:10 `SET`/`GET`.

É importante observar que cada ferramenta de benchmark possui seu próprio algoritmo para teste de desempenho e apresentação de dados. Por esse motivo, é normal ter resultados ligeiramente diferentes no mesmo servidor, mesmo utilizando configurações semelhantes.

## Conclusão

Neste guia, demonstramos como executar testes de benchmark em um servidor Redis usando duas ferramentas distintas: o `redis-benchmark` incluído e a ferramenta `memtier_benchmark` desenvolvida pelo Redis Labs. Também vimos como verificar a latência do servidor usando `redis-cli`. Com base nos dados obtidos com esses testes, você entenderá melhor o que esperar do servidor Redis em termos de desempenho e quais são os gargalos da sua configuração atual.
