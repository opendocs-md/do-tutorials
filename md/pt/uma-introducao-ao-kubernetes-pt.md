---
author: Justin Ellingwood
date: 2018-06-21
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/uma-introducao-ao-kubernetes-pt
---

# Uma Introdução ao Kubernetes

### Introdução

Kubernetes é um poderoso sistema open-source, inicialmente desenvolvido pelo Google, para o gerenciamento de aplicações em container em um ambiente clusterizado. Ele visa fornecer melhores maneiras de gerenciar componentes e serviços relacionados e distribuídos em diversas infraestruturas.

Neste guia, vamos discutir alguns conceitos básicos do Kubernetes. Vamos falar sobre a arquitetura do sistema, os problemas que ele resolve, e o modelo que ele utiliza para tratar deployments em container e escalabilidade.

## O que é o Kubernetes?

**Kubernetes** , em seu nível mais básico, é um sistema para executar e coordenar aplicações em container através de um cluster de máquinas. É uma plataforma desenhada para gerenciar completamente o ciclo de aplicações e serviços em container utilizando métodos que fornecem previsibilidade, escalabilidade, e alta disponibilidade.

Como usuário do Kubernetes, você pode definir como as suas aplicações devem rodar e as maneiras pelas quais elas devem ser capazes de interagir com outras aplicações ou com o mundo exterior. Você pode escalar seus serviços para cima ou para baixo, executar atualizações contínuas elegantemente, e trocar tráfego entre diferentes versões de suas aplicações para testar recursos ou reverter deployments problemáticos. O Kubernetes fornece interfaces e primitivas de plataformas combináveis que lhe permitem definir e gerenciar suas aplicações com alto grau de flexibilidade, potência, e confiabilidade.

## Arquitetura do Kubernetes

Para entender como o Kubernetes é capaz de fornecer esses recursos, é útil ter uma noção de como ele é projetado e organizado em alto nível. O Kubernetes pode ser visto como um sistema construído em camadas, com cada camada mais alta abstraindo a complexidade encontrada nos níveis mais baixos.

Em sua base, o Kubernetes reúne máquinas físicas ou virtuais individuais em um cluster usando uma rede compartilhada para comunicar entre cada servidor. Esse cluster é a plataforma física onde todos os componentes, recursos, e cargas de trabalho do Kubernetes são configurados.

Cada uma das máquinas do cluster recebe um papel dentro do ecossistema do Kubernetes. Um servidor (ou um pequeno grupo nos deployments de alta disponibilidade) funciona como o servidor **mestre**. Esse servidor age como um gateway e um cérebro para o cluster, expondo uma API para usuários e clientes, verificando a saúde de outros servidores, decidindo a melhor forma de dividir e atribuir trabalho (conhecido como “scheduling”), e orquestrando a comunicação entre outros componentes. O servidor mestre age como o primeiro ponto de contato com o cluster e é responsável pela maior parte da lógica centralizada que o Kubernetes fornece.

As outras máquinas no cluster são designadas como **nodes** ou **nós** : servidores responsáveis por aceitar e executar cargas de trabalho utilizando recursos locais e externos. Para ajudar no isolamento, gerenciamento, e flexibilidade, o Kubernetes executa aplicações e serviços em **containers** , então cada node precisa estar equipado com o runtime de container (como o Docker ou rkt). O node recebe instruções de trabalho do servidor mestre e cria ou destrói containers de acordo, ajustando as regras de rede para rotear e encaminhar o tráfego apropriadamente.

Como mencionado acima, as aplicações e serviços propriamente ditos estão executando no cluster dentro de containers. Os componentes subjacentes certificam-se de que o estado desejado das aplicações correspondam ao estado real do cluster. Os usuários interagem com o cluster através da comunicação com a API principal do servidor, seja diretamente ou através de clientes e bibliotecas. Para iniciar uma aplicação ou serviço, um plano declarativo é submetido em JSON ou YAML definindo o que criar e como ele deve ser gerenciado. O servidor mestre pega então o plano e descobre como executá-lo na infraestrutura através do exame dos requisitos e o estado atual do sistema. Esse grupo de aplicativos definidos pelo usuário, em execução de acordo com um plano especificado, representa a camada final do Kubernetes.

## Componentes do Servidor Mestre

Como descrito acima, o servidor mestre age como o plano de controle primário para os clusters do Kubernetes. Ele serve como o principal ponto de contato para administradores e usuários, e também fornece muitos sistemas em todo o cluster para os nodes de trabalho relativamente pouco sofisticados. No geral, os componentes no servidor mestre trabalham juntos para aceitar solicitações de usuários, determinar as melhores maneiras de agendar containers de carga de trabalho, autenticar clientes e nodes, ajustar a rede de todo o cluster, e gerenciar as responsabilidades de escalabilidade e verificação de saúde.

Estes componentes podem ser instalados em uma única máquina ou distribuídos por vários servidores. Vamos dar uma olhada em cada componente individual associado com o servidor mestre nesta seção.

### etcd

Um dos componentes fundamentais que o Kubernetes precisa para funcionar é um armazenamento de configuração disponível globalmente. O [projeto etcd](https://coreos.com/etcd/docs/latest/), desenvolvido pelo time da CoreOS, é um armazenamento de chave-valor leve e distribuído, que pode ser configurado para se estender por vários nodes.

O Kubernetes utiliza o `etcd` para armazenar dados de configuração que podem ser acessados por cada um dos nodes no cluster. Isso pode ser usado para descoberta de serviços e pode ajudar os componentes a se configurarem ou se reconfigurarem de acordo com informações atualizadas. Isso também ajuda a manter o estado do cluster com recursos como eleição de líder e bloqueio distribuído. Ao fornecer uma API HTTP/JSON simples, a interface para definir ou recuperar valores é muito direta.

Como a maioria dos outros componentes no plano de controle, o `etcd` pode ser configurado em um único servidor mestre ou, em cenários de produção, distribuído entre várias máquinas. O único requisito é que ele deve ser acessível via rede para cada uma das máquinas Kubernetes.

### kube-apiserver

Um dos serviços mais importantes do servidor mestre é o servidor de API. Este é o principal ponto de contato do cluster todo, pois permite que um usuário configure cargas de trabalho e unidades organizacionais do Kubernetes. Ele também é responsável por certificar-se de que o armazenamento `etcd` e os detalhes dos serviços dos containers implantados estão de acordo. Ele age como uma ponte entre vários componentes para manter a saúde do cluster e disseminar informações e comandos.

O servidor de API implementa uma interface RESTful, o que significa que várias ferramentas distintas e bibliotecas podem comunicar-se prontamente com ele. Um cliente chamado **kubectl** está disponível como um método padrão de interação com o cluster Kubernetes a partir de um computador local.

### kube-controller-manager

O controller manager é um serviço geral que tem muitas responsabilidades. Primeiramente, ele gerencia diferentes controladores que regulam o estado do cluster, gerencia o ciclo de vida das cargas de trabalho, e realiza tarefas rotineiras. Por exemplo, um controlador de replicação assegura que o número de réplicas (cópias idênticas) definidas para um pod corresponda ao número atualmente implantado no cluster. Os detalhes dessas operações são gravadas no `etcd`, onde o controller manager observa as alterações por meio do servidor da API.

Quando uma alteração é vista, o controlador lê as novas informações e implementa o procedimento que preenche o estado desejado. Isto pode envolver escalar uma aplicação para cima ou para baixo, ajustar endpoints, etc.

### kube-scheduler

O processo que de fato atribui cargas de trabalho a nodes específicos no cluster é o scheduler ou agendador. Este serviço lê os requisitos operacionais da carga de trabalho, analisa o ambiente de infraestrutura atual, e coloca o trabalho em um node ou nodes aceitáveis.

O scheduler é responsável por rastrear a capacidade disponível em cada host para certificar-se de que as cargas de trabalho não estão agendadas para além dos recursos disponíveis. O scheduler deve saber a capacidade total bem como os recursos já alocados para cargas de trabalho existentes em cada servidor.

### cloud-controller-manager

O Kubernetes pode ser implantado em muitos ambientes diferentes e pode interagir com vários provedores de infraestrutura para entender e gerenciar o estado dos recursos no cluster. Como o Kubernetes trabalha com representações genéricas de recursos como armazenamento anexável e balanceadores de carga, ele precisa de uma forma de mapear estes para os recursos reais fornecidos por provedores de nuvem heterogêneos.

Os cloud controller managers ou gerentes controladores de nuvem agem como a cola que permite o Kubernetes interagir com provedores com diferentes capacidades, recursos, e APIs enquanto mantém construções relativamente genéricas internamente. Isto permite ao Kubernetes atualizar suas informações de estado de acordo com as informações recolhidas a partir do provedor de nuvem, ajustar recursos de nuvem conforme as mudanças sejam necessárias no sistema, e criar e usar serviços de nuvem adicionais para satisfazer os requisitos de trabalho submetidos ao cluster.

## Componentes do Servidor de Nodes

No Kubernetes, os servidores que realizam trabalho através da execução de containers são conhecidos como **nodes**. Os servidores de nodes têm alguns requisitos necessários para se comunicar com os componentes do mestre, configuração da rede do container, e execução da carga de trabalho real atribuída a eles.

### Um Runtime de Container

O primeiro componente que cada node deve ter é um runtime de container. Geralmente, este requisito é satisfeito através da instalação e execução do [Docker](https://www.docker.com/), mas alternativas como o [rkt](https://coreos.com/rkt/) e o [runc](https://github.com/opencontainers/runc) também estão disponíveis.

O runtime de container é responsável por iniciar e gerenciar containers, aplicações encapsuladas em um ambiente operacional relativamente isolado, mas leve. Cada unidade de trabalho no cluster é, em seu nível básico, implementada como um ou mais containers que devem ser implantados. O runtime de container em cada node é o componente que finalmente executa os containers definidos na carga de trabalho submetida ao cluster.

### kubelet

O principal ponto de contato de cada node com o grupo de cluster é um pequeno serviço chamado **kubelet**. Este serviço é responsável por replicar informações de e para os serviços do plano de controle, bem como interagir com o armazenamento `etcd` para ler detalhes de configuração ou gravar novos valores.

O serviço `kubelet` comunica-se com os componentes do mestre para autenticar no cluster e receber comandos e trabalho. O trabalho é recebido na forma de um **manifesto** que define a carga de trabalho e os parâmetros operacionais. O processo do `kubelet` então assume a responsabilidade pela manutenção do estado do trabalho no servidor de node. Ele controla o runtime de container para lançar ou destruir containers quando necessário.

### kube-proxy

Para gerenciar sub-redes de hosts individuais e tornar os serviços disponíveis para outros componentes, um pequeno serviço de proxy chamado **kube-proxy** é executado em cada servidor de node. Este processo encaminha requisições aos containers corretos, e é geralmente responsável por certificar-se de que o ambiente de rede é previsível e acessível, mas isolado quando apropriado.

## Objetos e Cargas de Trabalho do Kubernetes

Enquanto os containers são o mecanismo subjacente utilizado para implantar aplicações, o Kubernetes usa camadas adicionais de abstração sobre a interface do container para fornecer escala, resiliência, e recursos de gerenciamento do ciclo de vida. Em vez de gerenciar os containers diretamente, os usuários definem e interagem com instâncias compostas de várias primitivas fornecidas pelo modelo de objeto do Kubernetes. Analisaremos os diferentes tipos de objetos que podem ser usados para definir essas cargas de trabalho abaixo.

### Pods

Um **pod** é a unidade mais básica com a qual o Kubernetes lida. Os containers propriamente ditos não são atribuídos a hosts. Em vez disso, um ou mais containers fortemente acoplados são encapsulados em um objeto chamado de pod.

Um pod geralmente representa um ou mais containers que devem ser controlados com uma única aplicação. Pods consistem em containers que operam em conjunto, compartilham um ciclo de vida, e devem sempre passar pelo scheduling no mesmo node. Eles são gerenciados inteiramente como uma unidade e compartilham seu ambiente, volumes, e espaço de IP. A despeito de sua implementação em container, você deve geralmente pensar no pod como uma aplicação única, monolítica, para melhor conceituar como o cluster gerenciará os recursos e o agendamento do pod.

Geralmente, os pods consistem de um container principal que satisfaz o propósito geral da carga de trabalho e, opcionalmente, de alguns containers auxiliares que facilitam tarefas estreitamente relacionadas. Estes são programas que se beneficiam de serem executados e gerenciados em seus próprios containers, mas estão intimamente ligados ao aplicativo principal. Por exemplo, um pod pode ter um container executando o servidor de aplicação primário e um container auxiliar puxando arquivos para o sistema de arquivos compartilhado, quando são detectadas mudanças em um repositório externo. O escalonamento horizontal é geralmente desencorajado no nível do pod porque existem outros objetos de alto nível mais adequados para a tarefa.

Geralmente, os usuários não devem gerenciar os próprios pods, porque eles não fornecem alguns dos recursos geralmente necessários em aplicações (como gerenciamento sofisticado do ciclo de vida e escalonamento). Em vez disso, os usuários são encorajados a trabalhar com objetos de alto nível que usam modelos de pod ou pods como componentes de base, mas que implementam funcionalidades adicionais.

### Controladores de Replicação e Conjuntos de Replicação

Frequentemente, ao trabalhar com o Kubernetes, em vez de trabalhar com pods únicos, você estará gerenciando grupos de pods idênticos e replicados. Estes são criados a partir de modelos de pod e podem ser escalados horizontalmente por controladores conhecidos como Replication Controllers e Replication Sets.

Um **Replication Controller** ou **controlador de replicação** é um objeto que define um modelo de pod e os parâmetros de controle para escalar réplicas idênticas ou decrementar o número de cópias em execução. Esta é uma maneira fácil de distribuir a carga e aumentar a disponibilidade nativamente dentro do Kubernetes. O replication controller sabe como criar novos pods quando necessário, porque um modelo que se assemelha a uma definição de pod está embutido dentro da configuração dele.

O replication controller é responsável por assegurar que o número de pods implantados no cluster corresponde ao número de pods em sua configuração. Se um pod ou host subjacente falhar, o controlador irá iniciar novos pods para compensar. Se o número de réplicas na configuração do controlador se alterar, o controlador inicializa ou destrói containers para corresponder ao número desejado. Os replication controllers também podem realizar atualizações contínuas passando um conjunto de pods para uma nova versão. um a um, minimizando o impacto na disponibilidade da aplicação.

**Replication Sets** ou **Conjuntos de Replicação** são uma iteração no design do replication controller com maior flexibilidade em como o controlador identifica os pods que ele deve gerenciar. Os replication sets estão começando a substituir os replication controllers por causa de seus recursos de seleção de réplicas que são maiores, mas eles não são capazes de fazer atualizações contínuas para colocar os backends em uma nova versão como os replication controllers fazem. Em vez disso, os replication sets destinam-se a ser usados dentro de unidades adicionais de nível superior que fornecem essa funcionalidade.

Assim como os pods, tanto os replication controllers quanto os replication sets raramente são as unidades com as quais você trabalhará diretamente. Enquanto eles constroem-se em cima do projeto do pod para adicionar escalonamento horizontal e garantias de confiabilidade, eles não possuem alguns dos recursos de gerenciamento de ciclo de vida refinados encontrados em objetos mais complexos.

### Deployments

**Deployments** são uma das cargas de trabalho mais comuns para se criar e gerenciar diretamente. Os deployments usam os replication sets como blocos construtivos, adicionando a funcionalidade de gerenciamento flexível do ciclo de vida ao mix.

Embora os deployments criados com replication sets possam parecer duplicar a funcionalidade oferecida pelos replication controllers, eles resolvem muitos dos pontos problemáticos que existiam na implementação de atualizações contínuas. Ao atualizar aplicativos com replication controllers, os usuários são obrigados a enviar um plano para um novo replication controller que substitua o controlador atual. Ao usar replication controllers, tarefas como histórico de rastreamento, recuperação de falhas de rede durante a atualização e reversão de alterações ruins são difíceis ou deixadas como responsabilidade do usuário.

Deployments são objetos de alto nível projetados para facilitar o gerenciamento do ciclo de vida de pods replicados. Os deployments podem ser modificadas facilmente alterando a configuração e o Kubernetes ajustará os replication sets, gerenciará transições entre diferentes versões de aplicações, e, opcionalmente, manterá o histórico de eventos e irá desfazer recursos automaticamente. Por causa desses recursos, os deployments provavelmente serão o tipo de objeto do Kubernetes com o qual você trabalhará com mais frequência.

### Stateful Sets

**Stateful Sets** ou **Conjuntos com preservação de estado** são pods controladores especializados que oferecem pedidos e garantias de exclusividade. Primeiramente, eles são usados para ter um controle mais refinado quando você tem requisitos especiais relacionados ao pedido de implantação, dados persistentes ou redes estáveis. Por exemplo, stateful sets são geralmente associados a aplicações orientadas a dados, como bancos de dados, que precisam de acesso aos mesmos volumes, mesmo se reprogramados para um novo node.

Stateful sets fornecem um identificador de rede estável através da criação de um nome exclusivo baseado em número para cada conjunto que persistirá, mesmo se o conjunto precisar ser movido para outro node. Da mesma forma, volumes de armazenamento persistentes podem ser transferidos com um pod quando o rescheduling é necessário. Os volumes persistem mesmo depois que o pod foi excluído para evitar perda acidental de dados.

Ao implantar ou ajustar a escala, os stateful sets executam operações de acordo com o identificador numerado em seu nome. Isso proporciona maior previsibilidade e controle sobre a ordem de execução, o que pode ser útil em alguns casos.

### Daemon Sets

**Daemon Sets** são outra forma especializada de controlador de pods que executa uma cópia de um pod em cada node no cluster (ou um subconjunto, se especificado). Isso geralmente é útil ao implantar pods que ajudam a executar a manutenção e fornecem serviços para os próprios nodes.

Por exemplo, coletar e encaminhar logs, agregar métricas e executar serviços que aumentam os recursos do próprio node são candidatos populares para daemon sets. Como os daemon sets geralmente fornecem serviços fundamentais e são necessários em toda a frota, eles podem ignorar restrições de scheduling de pods que impedem que outros controladores atribuam pods a determinados hosts. Por exemplo, devido às suas responsabilidades exclusivas, o servidor mestre é frequentemente configurado para não estar disponível para o scheduling normal de pods, mas os daemon sets têm a capacidade de substituir a restrição em uma base de pod-por-pod para garantir que os serviços essenciais estejam em execução.

### Jobs e Cron Jobs

As cargas de trabalho que descrevemos até agora assumiram um ciclo de vida de longa duração e voltado a serviços. O Kubernetes usa uma carga de trabalho chamada **jobs** para fornecer um fluxo de trabalho baseado em tarefas, no qual espera-se que os containers em execução saiam com êxito após algum tempo depois de concluírem o seu trabalho. Os jobs são úteis se você precisar executar processamento único ou em lote, em vez de executar um serviço contínuo.

Os **cron jobs** são construídos sobre os jobs. Como os daemons convencionais do `cron` nos sistemas Linux e Unix-like que executam scripts em uma agenda, os cron jobs no Kubernetes fornecem uma interface para executar jobs com um componente de agendamento. Os Cron jobs podem ser usados para agendar um trabalho para ser executado no futuro ou em uma base regular e recorrente. Os cron jobs do Kubernetes são basicamente uma reimplementação do comportamento clássico do cron, usando o cluster como uma plataforma, em vez de um único sistema operacional.

### Outros Componentes do Kubernetes

Além das cargas de trabalho que você pode executar em um cluster, o Kubernetes fornece várias outras abstrações que ajudam você a gerenciar seus aplicativos, controlar a rede e ativar a persistência. Vamos discutir alguns dos exemplos mais comuns aqui.

### Serviços

Até agora, temos usado o termo “serviço” no sentido convencional Unix-like: para denotar processos de longa duração, frequentemente conectados em rede, capazes de responder a solicitações. No entanto, no Kubernetes, um serviço é um componente que atua como um balanceador de carga básico interno e um embaixador para os pods. Um serviço agrupa coleções lógicas de pods que executam a mesma função para apresentá-las como uma entidade única.

Isso permite que você implante um serviço que possa rastrear e rotear todos os containers de backend de um determinado tipo. Os consumidores internos precisam apenas saber o endpoint estável fornecido pelo serviço. Enquanto isso, a abstração de serviço lhe permite dimensionar ou substituir as unidades de trabalho de backend conforme necessário. O endereço IP de um serviço permanece estável, independentemente das alterações nos pods para os quais ele é encaminhado. Ao implantar um serviço, você obtém facilmente a capacidade de descoberta e pode simplificar seus projetos de container.

Sempre que você precisar fornecer acesso a um ou mais pods para outro aplicativo ou para consumidores externos, você deverá configurar um serviço. Por exemplo, se você tiver um conjunto de pods executando servidores web que devem ser acessíveis pela Internet, um serviço fornecerá a abstração necessária. Da mesma forma, se seus servidores web precisarem armazenar e recuperar dados, você deverá configurar um serviço interno para fornecer acesso aos seus pods de banco de dados.

Embora os serviços, por padrão, só estejam disponíveis usando um endereço IP roteável internamente, eles podem ser disponibilizados fora do cluster, escolhendo uma das várias estratégias. A configuração do **NodePort** funciona abrindo uma porta estática na interface de rede externa de cada node. O tráfego para a porta externa será roteado automaticamente para os pods apropriados usando um serviço IP de cluster interno.

Alternativamente, o tipo de serviço **LoadBalancer** cria um balanceador de carga externo para rotear para o serviço usando a integração do balanceador de carga do Kubernetes do provedor de nuvem. O cloud controller manager criará o recurso apropriado e o configurará usando os endereços de serviço interno.

### Volumes e Volumes Persistentes

O compartilhamento confiável de dados e a garantia de sua disponibilidade entre reinicializações de containers é um desafio em muitos ambientes em container. Os runtimes de container geralmente fornecem algum mecanismo para anexar o armazenamento a um container que persiste além da vida útil do container, mas as implementações geralmente não possuem flexibilidade.

Para resolver isso, o Kubernetes usa sua própria abstração de **volumes** , que permite que os dados sejam compartilhados por todos os containers dentro de um pod e permaneçam disponíveis até que o pod seja encerrado. Isso significa que pods fortemente acoplados podem compartilhar facilmente arquivos sem mecanismos externos complexos. Falhas no container dentro do pod não afetarão o acesso aos arquivos compartilhados. Depois que o pod é encerrado, o volume compartilhado é destruído, portanto, não é uma boa solução para dados realmente persistentes.

**Volumes persistentes** são um mecanismo para abstrair armazenamento mais robusto que não está vinculado ao ciclo de vida do pod. Em vez disso, eles permitem que os administradores configurem recursos de armazenamento para o cluster que os usuários podem solicitar e reivindicar para os pods que estão executando. Depois que um pod é concluído com um volume persistente, a política de reivindicação do volume determina se o volume é mantido até ser excluído manualmente ou removido imediatamente junto com os dados. Dados persistentes podem ser usados para proteger contra falhas baseadas em node e para alocar quantidades maiores de armazenamento do que as disponíveis localmente.

### Labels e Annotations

Uma abstração organizacional do Kubernetes relacionada, mas fora dos outros conceitos, é a rotulagem. Um **label** no Kubernetes é uma tag semântica que pode ser anexada a objetos do Kubernetes para marcá-los como parte de um grupo. Estes podem ser selecionados para segmentar instâncias diferentes para gerenciamento ou roteamento. Por exemplo, cada um dos objetos baseados em controlador usa labels para identificar os pods nos quais eles devem operar. Os serviços usam labels para entender os pods de backend para os quais devem encaminhar solicitações.

Os labels são fornecidos como pares simples de chave-valor. Cada unidade pode ter mais de um label, mas cada unidade só pode ter uma entrada para cada chave. Normalmente, uma chave de “nome” é usada como um identificador de propósito geral, mas você também pode classificar objetos por outros critérios, como estágio de desenvolvimento, acessibilidade pública, versão da aplicação, etc.

**Annotations** são mecanismos semelhantes que permitem anexar informações arbitrárias de chave-valor a um objeto. Enquanto os labels devem ser usados para informações semânticas úteis para corresponder a um pod com critérios de seleção, as annotations são mais livres e podem conter dados menos estruturados. Em geral, as annotations são uma maneira de adicionar metadados ricos a um objeto que não é útil para fins de seleção.

## Conclusão

O Kubernetes é um projeto empolgante que permite aos usuários executar cargas de trabalho em containers altamente disponíveis e escaláveis em uma plataforma altamente abstrata. Embora a arquitetura e o conjunto de componentes internos do Kubernetes possam, a princípio, parecer assustadores, sua potência, flexibilidade e o robusto conjunto de recursos são inigualáveis no mundo do código aberto. Compreendendo como os blocos construtivos básicos se encaixam, você pode começar a projetar sistemas que aproveitem totalmente os recursos da plataforma para executar e gerenciar suas cargas de trabalho em escala.
