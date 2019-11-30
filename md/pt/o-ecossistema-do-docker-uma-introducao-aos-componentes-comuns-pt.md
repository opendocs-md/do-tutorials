---
author: Justin Ellingwood
date: 2015-06-26
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/o-ecossistema-do-docker-uma-introducao-aos-componentes-comuns-pt
---

# O Ecossistema do Docker: Uma Introdução aos Componentes Comuns

### Introdução

A Conteinerização é o processo de distribuição e implantação de aplicativos de uma forma portátil e previsível. Ele faz isso empacotando componentes e suas dependências em um ambiente de processos padronizado, isolado e leve chamado contêiner. Muitas empresas estão agora interessadas em projetar aplicações e serviços que sejam facilmente implantados em sistemas distribuídos, permitindo o sistema escalar facilmente e sobreviver a falhas de máquina e de aplicação. O Docker, uma plataforma de conteinerização desenvolvida para simplificar e padronizar a implantação em vários ambientes, foi em grande parte, fundamental em estimular a adoção desse estilo de desenho e gerenciamento de serviços. Uma grande quantidade de software foi criado para compilar sobre este ecossistema de gestão de contêineres distribuídos.

## Docker e Conteinerização

O Docker é o software de conteinerização mais comum em uso atualmente. Embora outros sistemas de conteinerização existam, o Docker torna simples a criação e o gerenciamento de contêiner e integra com muitos projetos open source.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_ecosystem/Container-Overview.png)

Nesta imagem, você pode começar a ver (em uma visão simplificada) como os contêineres se relacionam com o sistema host. Os contêineres isolam aplicações individuais e utilizam recursos do sistema operacional que foram abstraídos pelo Docker. Na visão explodida na direita, podemos ver que os contêineres podem ser construídos por “camadas”, com vários contêineres compartilhando camadas subjacentes, diminuindo o uso de recursos.

As principais vantagens do Docker são:

- Utilização leve de recursos: Em vez da virtualização de um sistema operacional inteiro, os contêineres isolam no nível de processos e utilizan o kernel do host.
- Portabilidade: Todas as dependências para uma aplicação conteinerizada são empacotadas dentro do contêiner, permitindo-a executar em qualquer host Docker.
- Previsibilidade: O host não se importa com o que está sendo executado dentro do contêiner e o contêiner não se importa em qual host ele está executando. As interfaces são padronizadas e as interações são previsíveis.

Tipicamente, ao projetar uma aplicação ou serviço para usar o Docker, o melhor é quebrar as funcionalidades em contêineres individuais, uma decisão de projeto conhecida como arquitetura orientada a serviços. Isto lhe dá a capacidade de escalar facilmente ou atualizar os componentes independentemente no futuro. Ter esta flexibilidade é uma das muitas razões pelas quais as pessoas estão interessadas no Docker para desenvolvimento e implantação.

Para saber mais sobre conteinerização de aplicações com o Docker, clique [aqui](the-docker-ecosystem-an-overview-of-containerization).

## Descoberta de Serviços e Repositórios Globais de Configuração

A descoberta de serviço é um componente de uma estratégia global que visa tornar as implantações de contêineres escalável e flexível. A descoberta de serviço é utilizada para que os contêineres possam descobrir sobre o ambiente em que foram introduzidos sem a intervenção do administrador. Eles podem encontrar informações de conexão para os componentes com os quais devem interagir, e podem registrar-se de forma que outras ferramentas saibam que eles estão disponíveis. Estas ferramentas também funcionam tipicamente como repositórios de configuração globalmente distribuídos, onde as definições de configuração arbitrárias podem ser definidas para os serviços que operam em sua infraestrutura.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_ecosystem/Discover-Flow.png)

Na imagem acima, você pode ver um fluxo de exemplo no qual uma aplicação registra suas informações de conexão com o sistema de descoberta de serviço. Uma vez registrado, outras aplicações podem consultar o serviço de descoberta para descobrir como se conectar à aplicação.

Estas ferramentas são geralmente implementadas como repositórios de valores-chave simples que são distribuídos entre os hosts em um ambiente em cluster. Geralmente, os repositórios de valores-chave fornecem uma API HTTP para o acesso e definição de valores. Algumas incluem medidas de segurança adicionais como entradas criptografadas ou mecanismos de controle de acesso. Os repositórios distribuídos são essenciais para o gerenciamento dos hosts clusterizados de Docker, adicionalmente à sua função primária de fornecer detalhes de auto-configuração para novos contêineres.

Algumas das responsabilidades dos repositórios do serviço de descoberta são:

- Permitir aos aplicativos obter os dados necessários para conectar com os serviços dos quais eles dependem.
- Permitir aos serviços registrar suas informações de conexão para o propósito acima.
- Fornecimento de uma localização globalmente acessível para armazenar dados de configuração arbitrária.
- Armazenamento de informações sobre membros do cluster conforme necessário para qualquer software de gerenciamento de cluster. 

Algumas ferramentas de descoberta de serviço populares e projetos relacionados são:

- [etcd](how-to-use-etcdctl-and-etcd-coreos-s-distributed-key-value-store): descoberta de serviço / repositório de valores-chave globalmente distribuído
- [consul](an-introduction-to-using-consul-a-service-discovery-system-on-ubuntu-14-04): descoberta de serviço / repositório de valores-chave globalmente distribuído
- [zookeeper](an-introduction-to-mesosphere#a-basic-overview-of-apache-mesos): descoberta de serviço / repositório de valores-chave globalmente distribuído
- [crypt](http://xordataexchange.github.io/crypt/): projeto para criptografar entradas etcd
- [confd](how-to-use-confd-and-etcd-to-dynamically-reconfigure-services-in-coreos): observa mudanças nos repositórios de valores-chave e dispara a reconfiguração dos serviços com os novos valores

Para aprender mais sobre descoberta de serviço com Docker, visite nosso guia [aqui](the-docker-ecosystem-service-discovery-and-distributed-configuration-stores).

## Ferramentas de Rede

Aplicações conteinerizadas levam, elas próprias, a um projeto orientado a serviços que encoraja a quebra de funcionalidades em componentes discretos. Embora isto torne o gerenciamento e a escalabilidade mais fáceis, exige ainda mais garantia sobre a funcionalidade e a confiabilidade da rede entre os componentes. O Docker em si, fornece as estruturas básicas de rede necessária para a comunicação contêiner-para-contêiner e contêiner-para-host.

As capacidades de rede nativas do Docker fornecem dois mecanismos para interligar os contêineres. O primeiro é para expor as portas de um contêiner e, opcionalmente, mapear para o sistema host para roteamento externo. Você pode selecionar a porta do host para qual mapear ou permitir ao Docker escolher aleatoriamente uma porta alta, não utilizada. Esta é a maneira genérica de fornecer acesso a um contêiner que funciona bem para a maioria dos propósitos.

O outro método é permitir aos contêineres comunicarem-se utilizando “links” do Docker. Um contêiner interligado vai obter informação de conexão sobre seus pares, permitindo conectar-se automaticamente se ele estiver configurado para prestar atenção a essas variáveis. Isto permite o contato entre contêineres no mesmo host sem ter que saber de antemão a porta ou endereço onde o serviço estará localizado.

Este nível básico de rede é adequado para ambientes de host-simples ou estritamente gerenciados. Contudo, o ecossistema do Docker tem produzido uma variedade de projetos que focam na expansão da funcionalidade de rede disponível para operadores e desenvolvedores. Algumas funcionalidades de rede disponíveis através de ferramentas adicionais incluem:

- Sobreposição de rede para simplificar e unificar o espaço de endereço através de múltiplos hosts.
- Redes virtuais privadas adaptadas para fornecer comunicação segura entre os vários componentes.
- Atribuição de sub-rede por host ou por aplicação.
- Estabelecimento de interfaces macvlan para comunicação.
- Configuração de endereços MAC customizados, gateways, etc. para seus contêineres.

Alguns projetos que estão envolvidos com a melhoria da rede Docker são:

- flannel: Rede sobreposta fornecendo a cada host uma sub-rede separada.
- weave: Rede sobreposta retratando todos os contêineres em uma única rede.
- pipework: Kit de ferramentas de redes para configurações de rede arbitrariamente avançadas.

Para um olhar mais profundo nas diferentes abordagens de rede com Docker, clique [aqui](the-docker-ecosystem-networking-and-communication).

## Agendamento, Gerenciamento de Cluster, e Orquestração

Outro componente necessário durante a construção de um ambiente de contêiner em cluster é um agendador. Agendadores são responsáveis pela inicialização de contêineres nos hosts disponíveis.

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/docker_ecosystem/Example-Schedule-App-F.png)

A imagem acima demonstra uma decisão simplificada de agendamento. O pedido é feito através de uma API ou de uma ferramenta de gerenciamento. A partir daqui, o agendador avalia as condições do pedido e do estado dos hosts disponíveis. Neste exemplo, ele busca informações sobre a densidade do contêiner a partir de um repositório distribuído de dados / serviço de descoberta (como discutido acima), de modo que possa colocar a nova aplicação no host menos ocupado.

Esse processo de seleção de host é uma das responsabilidades principais do agendador. Geralmente, ele tem funções que automatizam esse processo com o administrador tendo a opção de especificar certas restrições. Algumas destas restrições podem ser:

- Programar o contêiner no mesmo host como outro contêiner dado.
- Certificar-se de que o contêiner não seja colocado no mesmo host como um outro contêiner dado.
- Colocar o contêiner em um host com um rótulo correspondente ou com metadados.
- Colocar o contêiner no host menos ocupado.
- Executar o contêiner em todos os hosts no cluster.

O agendador é responsável por carregar os contêineres nos hosts relevantes e iniciar, parar e gerenciar o ciclo de vida do processo.

Como o agendador deve interagir com cada host no grupo, funções de gerenciamento de cluster estão também tipicamente incluídas. Estas permitem ao agendador obter informações sobre membros e realizar tarefas de administração. A orquestração neste contexto, refere-se à combinação de agendamento de contêiner e gerenciamento de hosts.

Alguns projetos populares que funcionam como agendadores e ferramentas de gerenciamento de cluster são:

- [fleet](how-to-use-fleet-and-fleetctl-to-manage-your-coreos-cluster): agendador e ferramenta de gerenciamento de cluster.
- [marathon](an-introduction-to-mesosphere#a-basic-overview-of-marathon): agendador e ferramenta de gerenciamento de cluster.
- [Swarm](https://github.com/docker/swarm/): agendador e ferramenta de gerenciamento de serviço.
- [mesos](an-introduction-to-mesosphere#a-basic-overview-of-apache-mesos): serviço de abstração de host que consolida recursos de host para o agendador.
- [kubernetes](an-introduction-to-kubernetes): agendador avançado capaz de gerenciar grupos de contêineres.
- [compose](https://github.com/docker/docker/issues/9694): ferramenta de orquestração de contêiner para criação de grupos de contêineres.

Para saber mais sobre agendamento básico, agrupamento de contêiner, e software de gerenciamento de cluster para o Docker, clique [aqui](the-docker-ecosystem-scheduling-and-orchestration).

## Conclusão

Por agora, você deve estar familiarizado com a função geral da maioria dos softwares associados com o ecossistema do Docker. O Docker em si, juntamente com todos os projetos de apoio, fornece uma estratégia de software de gerenciamento, projeto, e desenvolvimento que habilita uma escalabilidade massiva. Ao compreender e aproveitar as capacidades dos vários projetos, você pode executar a implantação de aplicações complexas que são flexíveis o suficiente para levar em conta requerimentos variáveis de operação.
