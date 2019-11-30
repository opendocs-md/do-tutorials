---
author: Justin Ellingwood
date: 2018-08-15
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/arquitetando-aplicacoes-para-o-kubernetes-pt
---

# Arquitetando Aplicações para o Kubernetes

### Introdução

Projetar e executar aplicações com escalabilidade, portabilidade e robustez pode ser um desafio, especialmente à medida que a complexidade do sistema aumenta. A arquitetura de uma aplicação ou sistema impacta significativamente em como ele deve ser executado, o que ele espera de seu ambiente e o quanto está acoplado aos componentes relacionados. Seguir certos padrões durante a fase de projeto e aderir a certas práticas operacionais pode ajudar a combater alguns dos problemas mais comuns que as aplicações enfrentam ao executar em ambientes altamente distribuídos.

Embora os padrões de projeto de software e as metodologias de desenvolvimento possam produzir aplicações com as características corretas de escalabilidade, a infraestrutura e o ambiente influenciam a operação do sistema implantado. Tecnologias como o [Docker](https://www.docker.com/) e o [Kubernetes](https://kubernetes.io/) ajudam equipes a empacotar software e depois distribuir, fazer o deploy e escalar em plataformas de computadores distribuídos. Aprender a aproveitar melhor o poder dessas ferramentas pode ajudá-lo a gerenciar aplicações com maior flexibilidade, controle e capacidade de resposta.

Neste guia, vamos discutir alguns dos princípios e padrões que você pode adotar para ajudá-lo a dimensionar e gerenciar suas cargas de trabalho no Kubernetes. Embora o Kubernetes possa executar muitos tipos de cargas de trabalho, as escolhas feitas podem afetar a facilidade de operação e as possibilidades disponíveis no deploy. A maneira como você projeta e constrói suas aplicações, empacota seus serviços em containers e configura o gerenciamento do ciclo de vida e o comportamento dentro do Kubernetes pode, cada uma, influenciar sua experiência.

## Projetando para Escalabilidade das Aplicações

Ao produzir software, muitos requisitos afetam os padrões e a arquitetura que você escolhe empregar. Com o Kubernetes, um dos fatores mais importantes é a capacidade de **escalar horizontalmente** , ajustando o número de cópias idênticas da sua aplicação para distribuir a carga e aumentar a disponibilidade. Esta é uma alternativa à **escalabilidade vertical** , que tenta manipular os mesmos fatores através do deploy em máquinas com maiores ou menores recursos.

Em particular, **microservices** ou micro-serviços é um padrão de projeto de software que funciona bem para deployments escaláveis em clusters. Os desenvolvedores criam aplicações pequenas e compostas que se comunicam pela rede através de APIs REST bem definidas, em vez de grandes programas compostos que se comunicam através de mecanismos internos de programação. A decomposição de aplicações monolíticas em componentes discretos de propósito único torna possível dimensionar cada função de forma independente. Grande parte da complexidade e composição que normalmente existiria no nível da aplicação é transferida para o domínio operacional, onde pode ser gerenciada por plataformas como o Kubernetes.

Além dos padrões de software específicos, as aplicações **cloud native** ou nativas para nuvem são projetadas com algumas considerações adicionais em mente. Aplicações _cloud native_ são programas que seguem um padrão de arquitetura de microservices com resiliência integrada, observabilidade e recursos administrativos para se adaptar ao ambiente fornecido por plataformas em cluster na nuvem.

Por exemplo, aplicações _cloud native_ são construídas com métricas de relatórios de integridade para permitir que a plataforma gerencie eventos do ciclo de vida se uma instância se tornar inconsistente. Eles produzem (e tornam disponível para exportação) dados robustos de telemetria para alertar os operadores sobre problemas e permitir que eles tomem decisões esclarecidas. As aplicações são projetadas para lidar com reinicializações e falhas regulares, alterações na disponibilidade do back-end e alta carga, sem corromper os dados ou deixar de responder.

### Seguindo a Filosofia 12 Factor Application

Uma metodologia popular que pode ajudá-lo a se concentrar nas características mais importantes ao criar aplicações web prontas para a nuvem é a filosofia [Twelve-Factor App](https://12factor.net/). Escritos para ajudar os desenvolvedores e as equipes de operações a entender as principais qualidades compartilhadas pelos web services projetados para serem executados na nuvem, os princípios se aplicam muito bem ao software que funcionará em um ambiente em cluster como o Kubernetes. Embora os aplicativos monolíticos possam se beneficiar seguindo estas recomendações, as arquiteturas de microservices projetadas em torno desses princípios funcionam particularmente bem.

Um breve sumário dos Doze Fatores são:

1. **Base de código:** Gerencie todo o código em sistemas de controle de versão (como Git ou Mercurial). A base de código determina de forma abrangente o que é implantado.

2. **Dependências:** As dependências devem ser gerenciadas completa e explicitamente pela base de código, seja armazenada com o código ou com a versão fixada em um formato no qual um gerenciador de pacotes possa instalar.

3. **Configuração:** Separe os parâmetros de configuração da aplicação e defina-os no ambiente de deployment, em vez de mantê-los dentro da própria aplicação.

4. **Serviços de apoio:** Os serviços locais e remotos são abstraídos como recursos acessíveis pela rede, com detalhes de conexão definidos na configuração.

5. **Construa, libere, execute:** O estágio de construção da sua aplicação deve ser completamente separado dos processos de liberação e operação da mesma. O estágio de construção cria um artefato de deployment a partir do código-fonte, o estágio de liberação combina o artefato e a configuração, e o estágio de execução executa o release.

6. **Processos:** Aplicações são implementadas como processos que não devem contar com o armazenamento de estado localmente. O estado deve ser transferido para um serviço de apoio, conforme descrito no quarto fator.

7. **Ligações à portas:** As aplicações devem ligar-se nativamente a uma porta e ouvir conexões. Roteamento e encaminhamento de solicitações devem ser tratados externamente.

8. **Concorrência:** As aplicações devem confiar na escalabilidade através do modelo de processo. A execução de várias cópias de uma aplicação simultaneamente, potencialmente em vários servidores, permite o escalonamento sem ajustar o código da aplicação.

9. **Descartabilidade:** Os processos devem ser capazes de iniciar rapidamente e parar normalmente sem efeitos colaterais sérios.

10. **Paridade Desenv/prod:** Seus ambientes de teste, preparação e produção devem ter uma correspondência próxima e ser mantidos em sincronia. Diferenças entre ambientes são oportunidades para incompatibilidades e configurações não testadas aparecerem.

11. **Logs:** As aplicações devem transmitir os logs para a saída padrão, para que os serviços externos possam decidir a melhor forma de lidar com eles.

12. **Processos administrativos:** Processos de administração únicos devem ser executados em releases específicos e enviados com o código do processo principal.

Ao aderir às diretrizes fornecidas pelos Doze Fatores, você pode criar e executar aplicativos usando um modelo adequado ao ambiente de execução do Kubernetes. Os Doze Fatores encorajam os desenvolvedores a se concentrarem na responsabilidade principal de suas aplicações, a considerarem as condições operacionais e as interfaces entre os componentes e a usarem entradas, saídas e recursos de gerenciamento de processos padrão, para serem executados de maneira previsível no Kubernetes.

## Containerizando Componentes da Aplicação

O Kubernetes usa containers para executar aplicações empacotadas isoladas em seus nodes de cluster. Para executar no Kubernetes, suas aplicações devem ser encapsuladas em uma ou mais imagens de container e executadas usando um runtime de container como o Docker. Embora containerizar seus componentes seja um requisito para o Kubernetes, isso também ajuda a reforçar muitos dos princípios da metodologia de doze fatores para aplicações, discutidos acima, permitindo fácil escalonamento e gerenciamento.

Por exemplo, os containers fornecem isolamento entre o ambiente da aplicação e o sistema do host externo, suporta uma abordagem em rede, orientada a serviços para comunicação entre aplicações, e normalmente busca a configuração através de variáveis de ambiente e expõe logs gravados na saída de erro e na saída padrão. Os próprios containers encorajam a concorrência baseada em processos e ajudam a manter a paridade desenv/prod sendo escaláveis independentemente e agrupando o ambiente de runtime do processo. Essas características tornam possível empacotar suas aplicações para que elas funcionem sem problemas no Kubernetes.

### Diretrizes para Otimizar Containers

A flexibilidade da tecnologia de container permite muitas maneiras diferentes de encapsular uma aplicação. Contudo, alguns métodos funcionam melhor do que outros em um ambiente Kubernetes.

A maioria das boas práticas recomendadas na containerização de suas aplicações tem a ver com a construção de imagens, onde você define como seu software será configurado e executado dentro de um container. Em geral, manter tamanhos de imagem pequenos e compostos oferece vários benefícios. Imagens de tamanho otimizado podem reduzir o tempo e os recursos necessários para iniciar um novo container em um cluster, mantendo o perfil gerenciável e reutilizando as camadas existentes entre as atualizações de imagem.

Um bom primeiro passo ao criar imagens de container é fazer o seu melhor para separar suas etapas de criação da imagem final que será executada na produção. Construir software geralmente requer ferramental extra, toma tempo adicional e produz artefatos que podem ser inconsistentes de container para container ou desnecessários para o runtime de execução final, dependendo do ambiente. Uma maneira de separar claramente o processo de construção do runtime de execução é usar as [construções de vários estágios do Docker](https://docs.docker.com/develop/develop-images/multistage-build/). As configurações das construções de vários estágios permitem que você especifique uma imagem de base para usar durante o processo de construção e defina outra para usar no runtime. Isso possibilita a criação de software usando uma imagem com todas as ferramentas de compilação instaladas e copiar os artefatos resultantes para uma imagem simplificada que será usada a cada vez, posteriormente.

Com esse tipo de funcionalidade disponível, geralmente é uma boa ideia criar imagens de produção em cima de uma imagem matriz mínima. Se você quiser evitar completamente o inchaço encontrado em camadas da imagem matriz do estilo “distro” como `ubuntu:16.04` (que inclui um ambiente Ubuntu 16.04 bastante completo), você pode construir suas imagens com o `scratch` — A imagem de base mais minimalista do Docker — como matriz. Contudo, a camada base `scratch` não fornece acesso a muitas das ferramentas principais e muitas vezes quebrará as suposições sobre o ambiente que alguns softwares detêm. Como uma alternativa, a imagem `alpine` [Alpine Linux](https://alpinelinux.org/) ganhou poularidade por ser um ambiente de base sólido e mínimo, que fornece uma distribuição Linux minúscula, mas com recursos completos.

Para linguagens interpretadas como o Python ou Ruby, o paradigma muda levemente, já que não há um estágio de compilação e o interpretador deve estar disponível para executar o código em produção. No entanto, como as imagens magras ainda são ideais, muitas imagens otimizadas para linguagens específicas, construídas a partir do Alpine Linux estão disponíveis no [Docker Hub](https://hub.docker.com/). Os benefícios de se usar uma imagem menor para linguagens interpretadas são semelhantes aos das linguagens compiladas: O Kubernetes poderá buscar rapidamente todas as imagens de container necessárias para novos nodes para começar a fazer trabalho significativo.

## Decidindo sobre o Escopo para Containers e Pods

Embora suas aplicações devam ser containerizadas para executar em um cluster Kubernetes, os **pods** são a menor unidade de abstração que o Kubernetes pode gerenciar diretamente. Um pod é um objeto Kubernetes composto de um ou mais containers fortemente acoplados. os containers em um pod compartilham um ciclo de vida e são gerenciados juntos como uma única unidade. Por exemplo, o scheduling desses containers é feito sempre no mesmo node, são iniciados e parados em sincronia e compartilham recursos como sistemas de arquivos e espaço de IP.

No início, pode ser difícil descobrir a melhor maneira de dividir suas aplicações em containers e pods. Isso torna importante entender como o Kubernetes lida com esses componentes e o que cada camada de abstração fornece para seus sistemas. Algumas considerações podem ajudá-lo a identificar alguns pontos naturais de encapsulamento para sua aplicação com cada uma dessas abstrações.

Uma maneira de determinar um escopo efetivo para seus containers é procurar por limites naturais do desenvolvimento. Se seus sistemas operam utilizando a arquitetura de microservices, containers bem projetados são frequentemente construídos para representar unidades discretas de funcionalidade que podem ser usadas em uma variedade de contextos. Esse nível de abstração permite à sua equipe lançar alterações nas imagens de containers e, em seguida, fazer o deploy dessa nova funcionalidade em qualquer ambiente onde essas imagens sejam utilizadas. As aplicações podem ser construídas através da composição de containers individuais que preencham uma determinada função, mas podem não realizar um processo inteiro sozinhos.

Em contraste com o exposto cima, os pods são geralmente construídos pensando em quais partes do seu sistema podem se beneficiar mais do gerenciamento independente. Como o Kubernetes usa pods como sua menor abstração de interação com o usuário, essas são as unidades mais primitivas com as quais as ferramentas e a API do Kubernetes podem interagir e controlar diretamente. Você pode iniciar, parar e reiniciar pods, ou utilizar objetos de nível superior construídos em pods para introduzir recursos de replicação e gerenciamento do ciclo e vida. O Kubernetes não lhe permite gerenciar os containers dentro de um pod de forma independente, portanto, você não deve agrupar containers que possam se beneficiar de uma administração separada.

Como muitos dos recursos e abstrações do Kubernetes lidam diretamente com os pods, faz sentido agrupar itens que devem ser escalados juntos em um único pod e separar aqueles que devem ser escalados independentemente. Por exemplo, separar seus servidores web de seus servidores de aplicação em diferentes pods permite escalar cada camada de forma independente, conforme necessário. No entanto, o empacotamento de um servidor web e de um adaptador de banco de dados no mesmo conjunto pode fazer sentido se o adaptador fornecer a funcionalidade essencial que o servidor web precisa para funcionar corretamente.

### Melhorando a Funcionalidade do Pod através do Empacotamento de Containers de Apoio

Com isso em mente, quais tipos de containers devem ser agrupados em um único pod? Geralmente, um container primário é responsável pelo cumprimento das funções principais do pod, mas podem ser definidos containers adicionais que modifiquem ou estendam o container principal ou o ajudem a se conectar a um ambiente de deployment exclusivo.

Por exemplo, em um pod de servidor web, um container Nginx pode escutar solicitações e fornecer conteúdo enquanto um container associado atualiza arquivos estáticos quando um repositório é alterado. Pode ser tentador empacotar esses dois componentes em um único container, mas há benefícios significativos em implementá-los como containers separados. O container do servidor web e o atualizador do repositório podem ser usados independentemente em diferentes contextos. Eles podem ser mantidos por equipes diferentes e cada um deles podem ser desenvolvidos para generalizar seu comportamento para trabalhar com diferentes containers complementares.

Brendan Burns e David Oppenheimer identificaram três padrões primários para empacotar containers de apoio em seus artigos em [design patterns for container-based distributed systems](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/45406.pdf). Estes representam alguns dos casos de uso mais comuns para empacotamento de containers juntos em um pod:

- **Sidecar:** Neste padrão, o container secundário estende e aprimora a funcionalidade principal do container primário. Esse padrão envolve a execução de funções não padronizadas ou utilitárias em um container separado. Por exemplo, um container que encaminha logs ou monitora atualizações em valores de configuração pode aumentar a funcionalidade de um pod sem alterar significativamente seu foco principal.
- **Ambassador:** O padrão ambassador usa um container suplementar para abstrair recursos remotos para o container principal. O container principal se conecta diretamente ao container ambassador que, por sua vez, se conecta e abstrai os pools de recursos externos potencialmente complexos, como um cluster de Redis distribuído. O container principal não precisa saber ou se preocupar com o ambiente de deployment real para se conectar a serviços externos.
- **Adaptor:** O padrão adaptor é usado para converter os dados, protocolos ou interfaces do container primário para alinhar com os padrões esperados por terceiros. Containers Adaptor permitem o acesso uniforme a serviços centralizados, mesmo quando as aplicações que eles atendem podem suportar nativamente somente interfaces incompatíveis.

## Extraindo a Configuração em ConfigMaps e Secrets

Embora a configuração da aplicação possa ser posta em imagens de container, é melhor tornar seus componentes configuráveis no runtime para suportar deployments em vários contextos e permitir uma administração mais flexível. Para gerenciar parâmetros de configuração de runtime, o Kubernetes usa dois objetos chamados **ConfigMaps** e **Secrets**.

ConfigMaps é um mecanismo usado para armazenar dados que podem ser expostos a pods e outros objetos em runtime. Os dados armazenados dentro de ConfigMaps podem ser apresentados como variáveis de ambiente ou montados como arquivos no pod. Ao projetar suas aplicações para ler esses locais, você pode injetar a configuração no runtime usando o ConfigMaps e modificar o comportamento de seus componentes sem precisar reconstruir a imagem do container.

Secrets são um tipo similar de objeto Kubernetes usado para armazenar dados sigilosos com segurança e seletivamente permitir o acesso a pods e outros componentes conforme necessário. Os secrets são uma maneira conveniente de transmitir material confidencial para aplicações sem armazená-los como texto simples em locais facilmente acessíveis em sua configuração normal. Funcionalmente, eles trabalham da mesma maneira que os ConfigMaps, portanto, as aplicações podem consumir dados de ConfigMaps e Secrets usando os mesmos mecanismos.

ConfigMaps e Secrets o ajudam a evitar colocar a configuração diretamente nas definições de objeto do Kubernetes. Você pode mapear a chave de configuração em vez do valor, permitindo que você atualize a configuração dinamicamente, através da modificação do ConfigMap ou do Secret. Isso lhe dá a oportunidade de alterar o comportamento do runtime ativo dos pods e outros objetos do Kubernetes sem modificar as definições dos recursos do Kubernetes.

## Implementando as provas Readiness e Liveness

O Kubernetes inclui uma grande quantidade de funcionalidades prontas para uso para gerenciar ciclos de vida e garantir que suas aplicações estejam sempre íntegras e disponíveis. No entanto, para aproveitar esses recursos, o Kubernetes precisa entender como ele deve monitorar e interpretar a integridade da sua aplicação. Para fazer isto, o Kubernetes lhe permite definir provas **liveness** e **readiness**.

Provas Liveness permitem que o Kubernetes determine se uma aplicação em um container está no ar e funcionando ativamente. O Kubernetes pode executar comandos periodicamente dentro do container para verificar o comportamento básico da aplicação ou pode enviar solicitações de rede HTTP ou TCP para um local designado para determinar se o processo está disponível e é capaz de responder conforme o esperado. Se uma prova liveness falha, o Kubernetes reinicia o container para tentar restabelecer a funcionalidade dentro do pod.

Provas Readness são um ferramenta similar usada para determinar se um pod está pronto para servir o tráfego. As aplicações em um container podem precisar executar procedimentos de inicialização antes de estarem prontas para aceitar solicitações de clientes ou podem precisar ser recarregadas ao serem notificadas sobre uma nova configuração. Quando uma prova readness falha, em vez de reiniciar o container, O Kubernetes pára de enviar temporariamente solicitações ao pod. Isso permite que o pod complete suas rotinas de inicialização ou manutenção sem afetar a integridade do grupo como um todo.

Ao combinar as provas liveness e readiness, você pode instruir o Kubernetes a reiniciar automaticamente os pods ou removê-los dos grupos de back-end. Configurar sua infraestrutura para aproveitar esses recursos permite que o Kubernetes gerencie a disponibilidade e a integridade de suas aplicações sem trabalho operacional adicional.

## Usando Deployments para Gerenciar Escalabilidade e Disponibilidade

Mais cedo, ao discutir alguns fundamentos de projetos de pods, também mencionamos que outros objetos do Kubernetes são construídos com base nessas primitivas para fornecer funcionalidade mais avançada. Um **deployment** , um desses objetos compostos, é provavelmente o objeto Kubernetes mais comumente definido e manipulado.

Deployments são objetos compostos que se baseiam em outras primativas do Kubernetes para somar recursos adicionais. Eles adicionam recursos de gerenciamento de ciclo de vida a objetos intermediários chamados **replicasets** , como a capacidade de executar atualizações contínuas, rollback para versões anteriores e transição entre estados. Esses replicasets permitem que você defina modelos de pod para lançar e gerenciar várias cópias de um único projeto de pod. Isso ajuda você a escalar facilmente sua infraestrutura, gerenciar os requisitos de disponibilidade e reiniciar automaticamente os pods em caso de falha.

Esses recursos adicionais fornecem uma estrutura administrativa e recursos de autocorreção para a abstração de pods relativamente simples. Embora os pods sejam as unidades que executam as cargas de trabalho que você define, eles não são as unidades que você geralmente deve provisionar e gerenciar. Em vez disso, pense nos pods como um bloco construtivo que pode executar aplicativos de maneira robusta quando provisionados por meio de objetos de nível mais alto, como os deployments.

## Criando Regras de Serviços e de Ingresso para Gerenciar o Acesso às Camadas de Aplicação

Deployments lhe permitem provisionar e gerenciar conjuntos de pods intercambiáveis para escalar suas aplicações e atender às demandas do usuário. No entanto, o roteamento de tráfego para os pods provisionados é uma preocupação à parte. Como os pods são trocados como parte de atualizações contínuas, reiniciados ou movidos devido a falhas de host, os endereços de rede associados anteriormente ao grupo em execução serão alterados. Os **serviços** do Kubernetes lhe permitem gerenciar essa complexidade mantendo as informações de roteamento para pools dinâmicos de pods e controlando o acesso a várias camadas da sua infraestrutura.

No Kubernetes, serviços são mecanismos específicos que controlam como o tráfego é roteado para conjuntos de pods. Seja encaminhando tráfego de clientes externos ou gerenciando conexões entre vários componentes internos, os serviços permitem que você controle como o tráfego deve fluir. O Kubernetes atualizará e manterá todas as informações necessárias para encaminhar conexões para os pods relevantes, mesmo que o ambiente se altere e o cenário de rede mude.

### Acessando Serviços Internamente

Para usar os serviços efetivamente, primeiro você deve determinar os consumidores presumidos para cada grupo de pods. Se o seu serviço só será usado por outras aplicações implantadas em seu cluster do Kubernetes, o tipo de serviço **clusterIP** permite que você se conecte a um conjunto de pods usando um endereço IP estável que só pode ser roteado de dentro do cluster. Qualquer objeto com deploy no cluster pode se comunicar com o grupo de pods replicados enviando tráfego diretamente para o endereço IP do serviço. Esse é o tipo de serviço mais simples, que funciona bem para camadas internas das aplicações.

Um add-on opcional de DNS permite que o Kubernetes forneça nomes DNS para serviços. Isso permite que os pods e outros objetos se comuniquem com os serviços pelo nome, em vez do endereço IP. Esse mecanismo não altera significativamente o uso do serviço, mas os identificadores baseados em nome podem simplificar a conexão de componentes ou a definição de interações sem conhecer o endereço IP do serviço antecipadamente.

### Expondo Serviços para Consumo Público

Se a interface deve ser publicamente acessível, sua melhor opção geralmente é o tipo de serviço **load balancer**. Ele usa a API do seu provedor de nuvem específico para provisionar um balanceador de carga, que serve tráfego para os pods de serviço por meio de um endereço IP exposto publicamente. Isso lhe permite rotear solicitações externas para os pods em seu serviço, oferecendo um canal de rede controlado para sua rede interna de clusters.

Como o tipo de serviço load balancer cria um balanceador de carga para cada serviço, pode se tornar caro expor publicamente os serviços do Kubernetes usando esse método. Para ajudar a aliviar isso, os objetos **ingress** do Kubernetes podem ser usados para descrever como rotear diferentes tipos de solicitações para diferentes serviços com base em um conjunto predeterminado de regras. Por exemplo, solicitações para “example.com” poderiam ir para o serviço A, enquanto solicitações para “sammytheshark.com” poderiam ser roteadas para o serviço B. Os objetos ingress fornecem uma maneira de descrever como rotear logicamente um fluxo misto de solicitações para seus serviços de destino com base em padrões predefinidos.

Regras Ingress devem ser interpretadas por um **ingress controller** — normalmente algum tipo de balanceamento de carga, como o Nginx — implantado no cluster como um pod, que implementa as regras de entrada e encaminha o tráfego apropriadamente para os serviços do Kubernetes. Atualmente, o tipo de objeto ingress está na versão beta, mas há várias implementações de trabalho que podem ser usadas para minimizar o número de balanceadores de carga externos que os proprietários de cluster precisam executar.

## Usando Sintaxe Declarativa para Gerenciar o Estado do Kubernetes

O Kubernetes oferece bastante flexibilidade na definição e controle dos recursos implantados (com deploy realizado) em seu cluster. Utilizando ferramentas como o `kubectl`, você pode definir imperativamente objetos ad-hoc para fazer deploy imediatamente em seu cluster. Embora isso possa ser útil para fazer o deploy de recursos rapidamente ao aprender o Kubernetes, há desvantagens nessa abordagem que a tornam indesejável para a administração de produção a longo prazo.

Um dos principais problemas com o gerenciamento imperativo é que ele não deixa nenhum registro das alterações que você fez deploy em seu cluster. Isso dificulta ou impossibilita a recuperação no caso de falhas ou para acompanhar as mudanças operacionais à medida que são aplicadas aos seus sistemas.

Felizmente, o Kubernetes fornece uma sintaxe declarativa alternativa que lhe permite definir recursos em arquivos de texto e em seguida usar o `kubectl` para aplicar a configuração ou alteração. Armazenar esses arquivos de configuração em um repositório de controle de versão é uma maneira simples de monitorar alterações e integrar com os processos de revisão usados para outras áreas de sua organização. O gerenciamento baseado em arquivos também simplifica a adaptação de padrões existentes para novos recursos, copiando e editando definições existentes. Armazenar suas definições de objeto do Kubernetes em diretórios versionados permite manter um instantâneo do estado do cluster desejado em cada instante no tempo. Isso pode ter um valor inestimável durante operações de recuperação, migrações ou ao rastrear a causa raiz de alterações não intencionais introduzidas em seu sistema.

## Conclusão

Gerenciar a infraestrutura que executará suas aplicações e aprender como aproveitar melhor os recursos oferecidos pelos ambientes modernos de orquestração pode ser assustador. No entanto, muitos dos benefícios oferecidos por sistemas como o Kubernetes e tecnologias como containers ficam mais claros quando suas práticas de desenvolvimento e operações se alinham aos conceitos sobre os quais o ferramental é construído. Arquitetar seus sistemas usando os padrões nos quais o Kubernetes se destaca e entender como certos recursos podem aliviar alguns dos desafios associados a deployments altamente complexos pode ajudar a melhorar sua experiência com a execução na plataforma.
