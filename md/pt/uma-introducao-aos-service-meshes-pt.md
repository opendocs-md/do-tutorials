---
author: Kathleen Juell
date: 2019-04-25
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/uma-introducao-aos-service-meshes-pt
---

# Uma Introdução aos Service Meshes

### Introdução

Um service mesh é uma camada de infraestrutura que permite gerenciar a comunicação entre os microsserviços da sua aplicação. À medida que mais desenvolvedores trabalham com microsserviços, os service meshes evoluíram para tornar esse trabalho mais fácil e mais eficaz consolidando tarefas administrativas e de gerenciamento comuns em uma configuração distribuída.

Aplicar uma abordagem de microsserviço à arquitetura de aplicações envolve dividir sua aplicação em uma coleção de serviços fracamente acoplados. Essa abordagem oferece certos benefícios: as equipes podem iterar projetos e escalar rapidamente, usando uma variedade maior de ferramentas e linguagens. Por outro lado, os microsserviços representam novos desafios para a complexidade operacional, consistência de dados e segurança.

Service meshes são projetados para resolver alguns desses desafios, oferecendo um nível granular de controle sobre como os serviços se comunicam uns com os outros. Especificamente, eles oferecem aos desenvolvedores uma maneira de gerenciar:

- Descoberta de serviço
- Roteamento e configuração de tráfego
- Criptografia e autenticação/autorização
- Métricas e monitoramento

Embora seja possível executar essas tarefas de forma nativa com orquestradores de containers como o [Kubernetes](https://kubernetes.io/), essa abordagem envolve uma maior quantidade de tomadas de decisão e administração antecipadas quando comparada com o que as soluções de service mesh como o [Istio](https://istio.io/) e o [Linkerd](https://linkerd.io/) oferecem por fora. Nesse sentido, service meshes podem agilizar e simplificar o processo de trabalho com componentes comuns em uma arquitetura de microsserviço. Em alguns casos, eles podem até ampliar a funcionalidade desses componentes.

## Por que Service Meshes?

Service meshes são projetados para resolver alguns dos desafios inerentes às arquiteturas de aplicações distribuídas.

Essas arquiteturas cresceram a partir do modelo de aplicação de três camadas, que dividia as aplicações em uma camada web, uma camada de aplicação e uma camada de banco de dados. Ao escalar, esse modelo se mostrou desafiador para organizações que experimentam um rápido crescimento. Bases de código de aplicações monolíticas podem se tornar bagunçadas, conhecidas como [“big balls of mud”](http://www.laputan.org/mud/), impondo desafios para o desenvolvimento e o deployment.

Em resposta a esse problema, organizações como Google, Netflix e Twitter desenvolveram bibliotecas “fat client” internas para padronizar as operações de runtime entre os serviços. Essas bibliotecas forneceram balanceamento de carga, circuit breaker , roteamento e telemetria — precursores para recursos de service mesh. No entanto, eles também impuseram limitações às linguagens que os desenvolvedores poderiam usar e exigiram mudanças nos serviços quando eles próprios foram atualizados ou alterados.

Um design de microsserviço evita alguns desses problemas. Em vez de ter uma base de código grande e centralizada de aplicações, você tem uma coleção de serviços gerenciados discretamente que representam um recurso da sua aplicação. Os benefícios de uma abordagem de microsserviço incluem:

- Maior agilidade no desenvolvimento e no deployment, já que as equipes podem trabalhar e fazer deploy de diferentes recursos de aplicações de forma independente.
- Melhores opções para CI/CD, já que microsserviços individuais podem ser testados e terem deploys refeitos independentemente.
- Mais opções para linguagens e ferramentas. Os desenvolvedores podem usar as melhores ferramentas para as tarefas em questão, em vez de se restringirem a uma determinada linguagem ou conjunto de ferramentas.
- Facilidade de escalar.
- Melhorias no tempo de atividade, experiência do usuário e estabilidade.

Ao mesmo tempo, os microsserviços também criaram desafios:

- Sistemas distribuídos exigem diferentes maneiras de pensar sobre latência, roteamento, fluxos de trabalho assíncronos e falhas.
- As configurações de microsserviço podem não atender necessariamente aos mesmos requisitos de consistência de dados que as configurações monolíticas.
- Níveis maiores de distribuição exigem designs operacionais mais complexos, particularmente quando se trata de comunicação de serviço a serviço.
- A distribuição de serviços aumenta a área de superfície para vulnerabilidades de segurança.

Service meshes são projetados para resolver esses problemas, oferecendo controle coordenado e granular sobre como os serviços se comunicam. Nas seções a seguir, veremos como service meshes facilitam a comunicação de serviço a serviço por meio da descoberta de serviços, roteamento e balanceamento interno de carga, configuração de tráfego, criptografia, autenticação e autorização, métricas e monitoramento. Vamos utilizar a [aplicação de exemplo Bookinfo](https://istio.io/docs/examples/bookinfo/) do Istio — quatro microsserviços que juntos exibem informações sobre determinados livros — como um exemplo concreto para ilustrar como os service meshes funcionam.

## Descoberta de Serviço

Em um framework distribuído, é necessário saber como se conectar aos serviços e saber se eles estão ou não disponíveis. Os locais das instâncias de serviço são atribuídos dinamicamente na rede e as informações sobre eles estão em constante mudança, à medida que os containers são criados e destruídos por meio do escalonamento automático, upgrades e falhas.

Historicamente, existiram algumas ferramentas para fazer a descoberta de serviços em uma estrutura de microsserviço. Repositórios de chave-valor como o [etcd](https://coreos.com/etcd/) foram emparelhados com outras ferramentas como o [Registrator](https://github.com/gliderlabs/registrator) para oferecer soluções de descoberta de serviços. Ferramentas como o [Consul](https://www.consul.io/) iteraram isso combinando um armazenamento de chave-valor com uma interface de DNS que permite aos usuários trabalhar diretamente com seu servidor ou nó DNS.

Tomando uma abordagem semelhante, o Kubernetes oferece descoberta de serviço baseada em DNS por padrão. Com ele, você pode procurar serviços e portas de serviço e fazer pesquisas inversas de IP usando convenções comuns de nomenclatura de DNS. Em geral, um registro A para um serviço do Kubernetes corresponde a esse padrão: `serviço.namespace.svc.cluster.local`. Vamos ver como isso funciona no contexto do aplicativo Bookinfo. Se, por exemplo, você quisesse informações sobre o serviço `details` do aplicativo Bookinfo, poderia ver a entrada relevante no painel do Kubernetes:

![Details Service in Kubernetes Dash](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/service_mesh_intro/details_svc_k8.png)

Isto lhe dará informações relevantes sobre o nome do serviço, namespace e `ClusterIP`, que você pode usar para se conectar ao seu serviço, mesmo que os containers individuais sejam destruídos e recriados.

Um service mesh como o Istio também oferece recursos de descoberta de serviço. Para fazer a descoberta de serviços, o Istio confia na comunicação entre a API do Kubernetes, o próprio plano de controle do Istio, gerenciado pelo componente de gerenciamento de tráfego [Pilot](https://istio.io/docs/concepts/what-is-istio/#pilot), e seu plano de dados, gerenciado pelos proxies sidecar [Envoy](https://www.envoyproxy.io/). O Pilot interpreta os dados do servidor da API do Kubernetes para registrar as alterações nos locais do Pod. Em seguida, ele converte esses dados em uma representação canônica Istio e os encaminha para os proxies sidecar.

Isso significa que a descoberta de serviço no Istio é independente de plataforma, o que podemos ver usando o [add-on Grafana](https://istio.io/docs/tasks/telemetry/using-istio-dashboard/) do Istio para olhar o serviço `details` novamente no painel de serviço do Istio:

![Details Service Istio Dash](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/service_mesh_intro/details_svc_istio.png)

Nossa aplicação está sendo executada em um cluster Kubernetes, então, mais uma vez, podemos ver as informações relevantes do DNS sobre o Serviço `details`, juntamente com outros dados de desempenho.

Em uma arquitetura distribuída, é importante ter informações atualizadas, precisas e fáceis de localizar sobre serviços. Tanto o Kubernetes quanto os service meshes, como o Istio, oferecem maneiras de obter essas informações usando convenções do DNS.

## Configuração de Roteamento e Tráfego

Gerenciar o tráfego em uma estrutura distribuída significa controlar como o tráfego chega ao seu cluster e como ele é direcionado aos seus serviços. Quanto mais controle e especificidade você tiver na configuração do tráfego externo e interno, mais você poderá fazer com sua configuração. Por exemplo, nos casos em que você está trabalhando com deployments piloto (canary), migrando aplicativos para novas versões ou testando serviços específicos por meio de injeção de falhas, ter a capacidade de decidir quanto tráfego seus serviços estão obtendo e de onde ele vem será a chave para o sucesso de seus objetivos.

O Kubernetes oferece diferentes ferramentas, objetos e serviços que permitem aos desenvolvedores controlar o tráfego externo para um cluster: [`kubectl proxy`](https://kubernetes.io/docs/tasks/access-kubernetes-api/http-proxy-access-api/), [`NodePort`](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport), [Load Balancers](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer), e [Ingress Controllers and Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-controllers). O `kubectl proxy` e o `NodePort` permitem expor rapidamente seus serviços ao tráfego externo: O `kubectl proxy` cria um servidor proxy que permite acesso ao conteúdo estático com um caminho HTTP, enquanto o `NodePort` expõe uma porta designada aleatoriamente em cada node. Embora isso ofereça acesso rápido, as desvantagens incluem ter que executar o `kubectl` como um usuário autenticado, no caso do `kubectl proxy`, e a falta de flexibilidade nas portas e nos IPs do node, no caso do `NodePort`. E, embora um Balanceador de Carga otimize a flexibilidade ao se conectar a um serviço específico, cada serviço exige seu próprio Balanceador de Carga, o que pode custar caro.

Um Ingress Resource e um Ingress Controller juntos oferecem um maior grau de flexibilidade e configuração em relação a essas outras opções. O uso de um Ingress Controller com um Ingress Resource permite rotear o tráfego externo para os serviços e configurar o roteamento interno e o balanceamento de carga. Para usar um Ingress Resource, você precisa configurar seus serviços, o Ingress Controller e o `LoadBalancer` e o próprio Ingress Resource, que especificará as rotas desejadas para os seus serviços. Atualmente, o Kubernetes suporta seu próprio [Controlador Nginx](https://github.com/kubernetes/ingress-nginx/blob/master/README.md), mas há outras opções que você pode escolher também, gerenciadas pelo [Nginx](https://www.nginx.com/products/nginx/kubernetes-ingress-controller), [Kong](https://konghq.com/blog/kubernetes-ingress-controller-for-kong/), e outros.

O Istio itera no padrão Controlador/Recurso do Kubernetes com [Gateways do Istio](https://istio.io/docs/reference/config/istio.networking.v1alpha3/#Gateway) e [VirtualServices](https://istio.io/docs/reference/config/istio.networking.v1alpha3/#VirtualService). Como um Ingress Controller, um gateway define como o tráfego de entrada deve ser tratado, especificando as portas e os protocolos expostos a serem usados. Ele funciona em conjunto com um VirtualService, que define rotas para serviços dentro da malha ou mesh. Ambos os recursos comunicam informações ao Pilot, que encaminha essas informações para os proxies Envoy. Embora sejam semelhantes ao Ingress Controllers and Resources, os Gateways e os VirtualServices oferecem um nível diferente de controle sobre o tráfego: em vez de [combinar camadas e protocolos Open Systems Interconnection (OSI)](https://en.wikipedia.org/wiki/OSI_model), Gateways e VirtualServices permitem diferenciar entre as camadas OSI nas suas configurações. Por exemplo, usando VirtualServices, as equipes que trabalham com especificações de camada de aplicação podem ter interesses diferenciados das equipes de operações de segurança que trabalham com diferentes especificações de camada. Os VirtualServices possibilitam separar o trabalho em recursos de aplicações distintos ou em diferentes domínios de confiança e podem ser usados para testes como canary, rollouts graduais, testes A/B, etc.

Para visualizar a relação entre os serviços, você pode usar o [add-on Servicegraph](https://istio.io/docs/tasks/telemetry/servicegraph/) do Istio, que produz uma representação dinâmica da relação entre os serviços usando dados de tráfego em tempo real. A aplicação Bookinfo pode se parecer com isso sem qualquer roteamento personalizado aplicado:

![Bookinfo service graph](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/service_mesh_intro/istio_mini_graph.png)

Da mesma forma, você pode usar uma ferramenta de visualização como o [Weave Scope](https://www.weave.works/docs/scope/latest/introducing/) para ver a relação entre seus serviços em um determinado momento. A aplicação Bookinfo sem roteamento avançado pode ter esta aparência:

![Weave Scope Service Map](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/service_mesh_intro/weave_scope_service_dash.png)

Ao configurar o tráfego de aplicações em uma estrutura distribuída, há várias soluções diferentes — de opções nativas do Kubernetes até service meshes como o Istio — que oferecem várias opções para determinar como o tráfego externo chegará até seus recursos de aplicação e como esses recursos se comunicarão entre si.

## Criptografia e Autenticação/Autorização

Um framework distribuído apresenta oportunidades para vulnerabilidades de segurança. Em vez de se comunicarem por meio de chamadas internas locais, como aconteceria em uma configuração monolítica, os serviços em uma arquitetura de microsserviço transmitem informações, incluindo informações privilegiadas, pela rede. No geral, isso cria uma área de superfície maior para ataques.

Proteger os clusters do Kubernetes envolve uma variedade de procedimentos; Vamos nos concentrar em autenticação, autorização e criptografia. O Kubernetes oferece abordagens nativas para cada um deles:

- [**Autenticação**](https://kubernetes.io/docs/reference/access-authn-authz/authentication/): As solicitações de API no Kubernetes estão vinculadas a contas de usuário ou serviço, que precisam ser autenticadas. Existem várias maneiras diferentes de gerenciar as credenciais necessárias: Tokens estáticos, tokens de bootstrap, certificados de cliente X509 e ferramentas externas, como o [OpenID Connect](https://openid.net/connect/). 
- [**Autorização**](https://kubernetes.io/docs/reference/access-authn-authz/authorization/): O Kubernetes possui diferentes módulos de autorização que permitem determinar o acesso com base em funções como papéis, atributos e outras funções especializadas. Como todas as solicitações ao servidor da API são negadas por padrão, cada parte de uma solicitação da API deve ser definida por uma política de autorização.
- **Criptografia** : Pode referir-se a qualquer um dos seguintes: conexões entre usuários finais e serviços, dados secretos, terminais no plano de controle do Kubernetes e comunicação entre componentes worker do cluster e componentes master. O Kubernetes tem diferentes soluções para cada um deles: 
  - [Ingress Controllers and Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/), que pode ser usado em conjunto com add-ons como o [cert-manager](https://github.com/jetstack/cert-manager) para gerenciar certificados TLS.
  - [Criptografia de dados secretos em repouso](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) para criptografar os recursos de segredos no `etcd`.
  - [TLS bootstrapping](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet-tls-bootstrapping/) para inicializar certificados de cliente para kubelets e proteger a comunicação entre nodes de trabalho e o `kube-apisever`. Você também pode usar uma rede de sobreposição como a [Weave Net](https://www.weave.works/docs/net/latest/concepts/encryption-implementation/) para [fazer isso](https://www.weave.works/docs/net/latest/concepts/encryption-implementation/).

A configuração de políticas e protocolos de segurança individuais no Kubernetes requer investimento administrativo. Um service mesh como o Istio pode consolidar algumas dessas atividades.

O Istio foi projetado para automatizar parte do trabalho de proteção dos serviços. Seu plano de controle inclui vários componentes que lidam com segurança:

- **Citadel** : gerencia chaves e certificados.
- **Pilot** : supervisiona as políticas de autenticação e nomenclatura e compartilha essas informações com os proxies Envoy.
- **Mixer** : gerencia autorização e auditoria.

Por exemplo, quando você cria um serviço, o Citadel recebe essa informação do `kube-apiserver` e cria certificados e chaves [SPIFFE](https://spiffe.io/) para este serviço. Em seguida, ele transfere essas informações para Pods e sidecars Envoy para facilitar a comunicação entre os serviços.

Você também pode implementar alguns recursos de segurança [habilitando o TLS mútuo](https://istio.io/docs/concepts/security/#mutual-tls-authentication) durante a instalação do Istio. Isso inclui identidades de serviço fortes para comunicação interna nos clusters e entre clusters, comunicação segura de serviço para serviço e de usuários para serviço, e um sistema de gerenciamento de chaves capaz de automatizar a criação, a distribuição e a rotação de chaves e certificados.

Ao iterar em como o Kubernetes lida com autenticação, autorização e criptografia, service meshes como o Istio são capazes de consolidar e estender algumas das melhores práticas recomendadas para a execução de um cluster seguro do Kubernetes.

## Métricas e Monitoramento

Ambientes distribuídos alteraram os requisitos para métricas e monitoramento. As ferramentas de monitoramento precisam ser adaptativas, respondendo por mudanças frequentes em serviços e endereços de rede, e abrangentes, permitindo a quantidade e o tipo de informações que passam entre os serviços.

O Kubernetes inclui algumas ferramentas internas de monitoramento por padrão. Esses recursos pertencem ao seu [pipeline de métricas de recursos](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/#resource-metrics-pipeline), que garante que o cluster seja executado conforme o esperado. O componente [cAdvisor](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/#cadvisor) coleta estatísticas de uso de rede, memória e CPU de containers e nodes individuais e passa essas informações para o kubelet; o kubelet, por sua vez, expõe essas informações por meio de uma API REST. O [servidor de métricas](https://kubernetes.io/docs/tasks/debug-application-cluster/core-metrics-pipeline/#metrics-server) obtém essas informações da API e as repassa para o [`kube-aggregator`](https://github.com/kubernetes/kube-aggregator) para formatação.

Você pode estender essas ferramentas internas e monitorar os recursos com uma solução completa de métricas. Usando um serviço como o [Prometheus](https://prometheus.io/) como um agregador de métricas, você pode criar uma solução diretamente em cima do pipeline de métricas de recursos do Kubernetes. O Prometheus integra-se diretamente ao cAdvisor através de seus próprios agentes, localizados nos nodes. Seu principal serviço de agregação coleta e armazena dados dos nodes e os expõe através de painéis e APIs. Opções adicionais de armazenamento e visualização também estão disponíveis se você optar por integrar seu principal serviço de agregação com ferramentas de backend de armazenamento, registro e visualização, como [InfluxDB](https://www.influxdata.com/time-series-platform/influxdb/), [Grafana](https://grafana.com/), [ElasticSearch](https://www.elastic.co/), [Logstash](https://www.elastic.co/products/logstash), [Kibana](https://www.elastic.co/products/kibana), e outros.

Em um service mesh como o Istio, a estrutura do pipeline completo de métricas faz parte do design da malha. Os sidecars do Envoy operando no nível do Pod comunicam as métricas ao [Mixer](https://istio.io/docs/concepts/policies-and-telemetry/), que gerencia políticas e telemetria. Além disso, os serviços Prometheus e Grafana estão habilitados por padrão (embora se você estiver instalando o Istio com o [Helm](https://helm.sh/) você precisará [especificar `granafa.enabled=true`](https://github.com/istio/istio/tree/master/install/kubernetes/helm/istio#configuration) durante a instalação). Como no caso do pipeline completo de métricas, você também pode [configurar outros serviços e deployments](https://istio.io/docs/tasks/telemetry/fluentd/) para opções de registro e visualização.

Com essas ferramentas de métrica e visualização, você pode acessar informações atuais sobre serviços e cargas de trabalho em um local central. Por exemplo, uma visão global do aplicativo BookInfo pode ter esta aparência no painel Grafana do Istio:

![Bookinfo services from Grafana dash](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/service_mesh_intro/grafana_bookinfo_istio_mesh_dash.png)

Ao replicar a estrutura de um pipeline completo de métricas do Kubernetes e simplificar o acesso a alguns de seus componentes comuns, service meshes como o Istio agilizam o processo de coleta e visualização de dados ao trabalhar com um cluster.

## Conclusão

As arquiteturas de microsserviço são projetadas para tornar o desenvolvimento e o deployment de aplicações mais rápidos e confiáveis. No entanto, um aumento na comunicação entre serviços mudou as práticas recomendadas para determinadas tarefas administrativas. Este artigo discute algumas dessas tarefas, como elas são tratadas em um contexto nativo do Kubernetes e como elas podem ser gerenciadas usando service mesh - nesse caso, o Istio.

Para obter mais informações sobre alguns dos tópicos do Kubernetes abordados aqui, consulte os seguintes recursos:

- [How to Set Up an Nginx Ingress with Cert-Manager on DigitalOcean Kubernetes](how-to-set-up-an-nginx-ingress-with-cert-manager-on-digitalocean-kubernetes).
- [How To Set Up an Elasticsearch, Fluentd and Kibana (EFK) Logging Stack on Kubernetes](how-to-set-up-an-elasticsearch-fluentd-and-kibana-efk-logging-stack-on-kubernetes).
- [Uma Introdução ao Serviço de DNS do Kubernetes](uma-introducao-ao-servico-de-dns-do-kubernetes-pt).

Além disso, os hubs de documentação do [Kubernetes](https://kubernetes.io/docs/home/) e do [Istio](https://istio.io/docs/) são ótimos lugares para encontrar informações detalhadas sobre os tópicos discutidos aqui.
