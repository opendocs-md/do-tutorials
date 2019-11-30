---
author: Mitchell Anicas
date: 2014-12-03
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/5-configuracoes-comuns-de-servidor-para-sua-aplicacao-web-pt
---

# 5 configurações comuns de servidor para sua aplicação Web

### Introdução

Ao decidir qual arquitetura de servidor utilizar para seu ambiente, existem muitos fatores a considerar, tais como desempenho, escalabilidade, disponibilidade, confiabilidade, custo, e facilidade de gerenciamento.

Aqui está uma lista de configurações de servidor comumente utilizadas, com uma breve descrição de cada uma, incluindo prós e contras. Tenha em mente que todos os conceitos abordados aqui podem ser usados em várias combinações entre si, e que cada ambiente tem requisitos diferentes, assim não há uma configuração única, correta.

## 1. Tudo em um único servidor

O ambiente inteiro reside em um único servidor. Para uma aplicação web típica, que incluiria um servidor web, servidor de aplicação, e um servidor de banco de dados. Uma variação comum desta configuração é a pilha LAMP, que significa Linux, Apache, MySQL, e PHP, em um único servidor.

**Caso de Uso:** Bom para a configuração rápida de uma aplicação, uma vez que é a configuração mais simples possível, mas oferece pouco em termos de escalabilidade e isolamento de componente.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/single_server.png)

### Prós:

- Simples

### Contras:

- Aplicação e banco de dados disputam os mesmos recursos de servidor (CPU, Memória, I/O, etc.) que, além de possível baixo desempenho, pode tornar difícil de determinar a origem (aplicação ou banco de dados) do baixo desempenho.

- Não é facilmente escalável horizontalmente

### Tutoriais Relacionados:

- [How To Install LAMP On Ubuntu 14.04](https://www.digitalocean.com/community/articles/how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-14-04)

## 2. Servidor de banco de dados separado

O sistema gerenciador de banco de dados (SGBD) pode ser separado do resto do ambiente para eliminar a disputa de recurso entre a aplicação e a base de dados, e para aumentar a segurança removendo a base de dados da DMZ, ou internet pública.

**Caso de Uso:** Bom para configurar rapidamente uma aplicação, enquanto evita a aplicação e o banco de dados de disputarem os mesmos recursos de sistema.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/separate_database.png)

### Prós:

- As camadas de aplicação e de banco de dados não competem pelos mesmos recursos de servidor (CPU, Memória, I/O, etc.) 

- Você pode escalar verticalmente cada camada separadamente, adicionando mais recursos para qualquer servidor que necessita maior capacidade

- Dependendo da sua configuração, pode-se aumentar a segurança removendo seu banco de dados da DMZ

### Contras:

- Configuração um pouco mais complexa do que com um único servidor

- Problemas de desempenho podem surgir se a conexão de rede entre os dois servidores está com alta-latência (ou seja, os servidores estão distantes geograficamente um do outro), ou a largura de banda é muito baixa para a quantidade de dados a ser transferida.

### Tutoriais Relacionados:

- [How To Set Up a Remote Database to Optimize Site Performance with MySQL](https://www.digitalocean.com/community/articles/how-to-set-up-a-remote-database-to-optimize-site-performance-with-mysql)
- [How to Migrate A MySQL Database To A New Server On Ubuntu 14.04](https://www.digitalocean.com/community/articles/how-to-migrate-a-mysql-database-to-a-new-server-on-ubuntu-14-04)

## 3. Balanceador de Carga (Proxy Reverso)

Balanceadores de carga podem ser adicionados a um ambiente de servidor para melhorar o desempenho e a confiabilidade distribuindo a carga por múltiplos servidores. Se um dos servidores que tem balanceamento de carga falhar, os outros servidores irão tratar o tráfego de entrada até que o servidor defeituoso volte a funcionar novamente. Ele pode ser usado também para servir múltiplas aplicações através do mesmo domínio e porta, utilizando um proxy reverso de camada 7 (camada de aplicação).

Exemplos de softwares capazes de balancear carga via proxy reverso: HAProxy, Nginx, e Varnish.

**Caso de Uso:** Útil em um ambiente que requer escalabilidade pela adição de mais servidores, também conhecido como escalabilidade horizontal.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/load_balancer.png)

### Prós:

- Habilita a escalabilidade horizontal, ou seja, a capacidade do ambiente pode ser escalada adicionando-se mais servidores a ele
- Pode proteger contra ataques DDOS limitando conexões de clientes a uma razoável quantidade e frequência

### Contras:

- O balanceador de carga pode se tornar um gargalo se ele não tiver recursos suficientes, ou se ele estiver mal configurado
- Pode apresentar complexidades que requerem consideração adicional, tais como onde executar terminação SSL e como lidar com aplicações que requerem sessões persistentes

### Tutoriais Relacionados

- [An Introduction to HAProxy and Load Balancing Concepts](https://www.digitalocean.com/community/articles/an-introduction-to-haproxy-and-load-balancing-concepts)
- [How To Use HAProxy As A Layer 4 Load Balancer for WordPress Application Servers](https://www.digitalocean.com/community/articles/how-to-use-haproxy-as-a-layer-4-load-balancer-for-wordpress-application-servers-on-ubuntu-14-04)
- [How To Use HAProxy As A Layer 7 Load Balancer For WordPress and Nginx](https://www.digitalocean.com/community/articles/how-to-use-haproxy-as-a-layer-7-load-balancer-for-wordpress-and-nginx-on-ubuntu-14-04)

## 4. Acelerador HTTP (Proxy Reverso com Cache)

Um acelerador HTTP, ou Proxy HTTP Reverso com Cache, pode ser usado para reduzir o tempo que ele leva para servir conteúdo para um usuário através de uma variedade de técnicas. A principal técnica empregada com um acelerador HTTP é fazer cache de respostas do servidor web ou do servidor de aplicação em memória, assim requisições futuras para o mesmo conteúdo podem ser servidas rapidamente, com menos interações desnecessárias com os servidores web e de aplicação.

Exemplos de softwares capazes para aceleração HTTP: Varnish, Squid, Nginx.

**Caso de Uso:** Útil em ambientes com aplicações web dinâmicas de conteúdo pesado, ou com muitos arquivos comumente acessados.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/http_accelerator.png)

### Prós:

- Aumento do desempenho do site reduzindo a carga de CPU no servidor web, através de cache e compressão, aumentando assim a capacidade do usuário.
- Pode ser usado como balanceador de carga de proxy reverso
- Alguns softwares de cache podem proteger contra ataques DDOS

### Contras:

- Requer ajustes para obtenção de seu melhor desempenho
- Se a taxa de cache-hit é baixa, pode reduzir o desempenho

### Tutoriais Relacionados:

- [How To Install Wordpress, Nginx, PHP, and Varnish on Ubuntu 12.04](https://www.digitalocean.com/community/articles/how-to-install-wordpress-nginx-php-and-varnish-on-ubuntu-12-04)
- [How To Configure a Clustered Web Server with Varnish and Nginx](https://www.digitalocean.com/community/articles/how-to-configure-a-clustered-web-server-with-varnish-and-nginx-on-ubuntu-13-10)
- [How To Configure Varnish for Drupal with Apache on Debian and Ubuntu](https://www.digitalocean.com/community/articles/how-to-configure-varnish-for-drupal-with-apache-on-debian-and-ubuntu)

# 5. Replicação de Banco de Dados Mestre-Escravo

Uma forma de melhorar o desempenho de um sistema de banco de dados que executa muitas leituras em comparação com as gravações, como um CMS, é a replicação de banco de dados mestre-escravo. A replicação mestre-escravo requer um nodo mestre e um ou mais nodos escravos. Nesta configuração, todas as atualizações são enviadas ao nodo mestre e as leituras podem ser distribuídas entre todos os outros nodos.

**Caso de Uso:** Bom para aumentar o desempenho de leitura para a camada de banco de dados de uma aplicação.

Aqui está um exemplo de uma configuração mestre-escravo, com um único nodo escravo:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/master_slave_database_replication.png)

### Pros:

- Melhora o desempenho de leitura de banco de dados distribuindo as leituras pelo escravos
- Pode melhorar o desempenho de gravação utilizando o mestre exclusivamente para atualizações (ele não consome tempo para servir requisições de leitura)

### Contras:

- A aplicação que acessa o banco de dados deve ter um mecanismo para determinar para qual nodo de banco de dados ele deve enviar atualizações e requisições de leitura
- Atualizações nos escravos são assíncronas, então existe uma chance de que seu conteúdo esteja desatualizado
- Se o mestre falhar, nenhuma atualização poderá ser executada no banco de dados até que seu conteúdo seja corrigido
- Não existe um failover embutido em caso de falha no nodo mestre

### Tutoriais Relacionados:

- [How To Optimize WordPress Performance With MySQL Replication On Ubuntu 14.04](https://www.digitalocean.com/community/articles/how-to-optimize-wordpress-performance-with-mysql-replication-on-ubuntu-14-04)
- [How To Set Up Master Slave Replication in MySQL](https://www.digitalocean.com/community/articles/how-to-optimize-wordpress-performance-with-mysql-replication-on-ubuntu-14-04)

# Exemplo: Combinando Conceitos

É possível fazer balanceamento de carga dos servidores de cache, adicionalmente aos servidores de aplicação, e usar replicação de banco de dados em um só ambiente. O propósito de combinar estas técnicas é colher os benefícios de cada uma sem introduzir muitos problemas e complexidade. Aqui está um exemplo de como um ambiente de servidor deve se parecer:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/architecture/combined.png)

Suponhamos que o balanceador de carga está configurado para reconhecer requisições estáticas (como imagens, css, javascript, etc.) e enviar estas requisições diretamente aos servidores de cache, e enviar outras requisições para os servidores de aplicação.

Aqui está uma descrição do que aconteceria quando um usuário envia um pedido de conteúdo dinâmico:

1. O usuário requisita conteúdo dinâmico de [http://example.com/](http://example.com/) (balanceador de carga)
2. O balanceador de carga envia a requisição para o servidor de aplicação
3. O servidor de aplicação lê do banco de dados e retorna o conteúdo requisitado para o balanceador de carga
4. O balanceador de carga retorna o dado requisitado para o usuário

Se o usuário requisitar conteúdo estático:

1. O balanceador de carga verifica o servidor de cache para ver se o conteúdo requisitado está em cache (cache-hit) ou não (cache-miss)
2. Para cache-hit: retorna o conteúdo requisitado para o balanceador de carga e pula para o passo 7. Para cache-miss: o servidor de cache encaminha a requisição para o servidor de aplicação, através do balanceador de carga
3. O balanceador de carga encaminha a requisição através do servidor de aplicação
4. O servidor de aplicação lê do banco de dados e então retorna o conteúdo requisitado para o balanceador de carga
5. O balanceador de carga encaminha a resposta para o servidor de cache
6. O servidor de cache faz cache do conteúdo e o retorna para o balanceador de carga
7. O balanceador de carga retorna o dado requisitado para o usuário

Este ambiente tem ainda dois pontos únicos de falha (balanceador de carga e servidor de banco de dados mestre), mas ele fornece todos os outros benefícios de confiabilidade e desempenho que descrevemos em cada seção acima.

## Conclusão

Agora que você está familiarizado com algumas configurações básicas de servidor, você deve ter uma boa ideia de que tipo de configuração você gostaria de usar para a sua própria aplicação. Se você estiver trabalhando para melhorar seu próprio ambiente, lembre-se que um processo iterativo é melhor para evitar a introdução de muitas complexidades muito rapidamente.

Deixe-nos saber de quaisquer configurações você recomenda ou gostaria de aprender mais sobre, nos comentários abaixo!

Por Mitchell Anicas
