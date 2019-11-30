---
author: Justin Ellingwood
date: 2015-06-26
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/o-ecossistema-do-docker-agendamento-e-orquestracao-pt
---

# O Ecossistema do Docker: Agendamento e Orquestração

### Introdução

A ferramenta Docker fornece todas as funções necessárias para construir, carregar, baixar, iniciar, e parar contêineres. Ela é bastante adequada para o gerenciamento de processos em ambientes de host único com um número mínimo de contêineres.

Contudo, muitos usuários de Docker estão alavancando a plataforma como uma ferramenta para dimensionar facilmente um grande número de contêineres entre vários hosts diferentes. Hosts de Docker em cluster apresentam desafios especiais de gerenciamento que requerem um conjunto diferente de ferramentas.

Neste guia, vamos discutir agendadores do Docker e ferramentas de orquestração. Estas representam a interface primária de gerenciamento de contêiner para administradores de implantações distribuídas.

## Agendamento de Contêineres, Orquestração e Gerenciamento de Cluster

Quando as aplicações são escaladas por muitos sistemas host, a capacidade de gerenciar cada sistema host e abstrair a complexidade da plataforma subjacente torna-se atraente. Orquestração é um termo abrangente que refere-se ao agendamento de contêiner, gerenciamento de cluster, e possivelmente o provisionamento de hosts adicionais.

Neste ambiente, “agendamento” refere-se à capacidade de um administrador carregar um arquivo de serviço em um sistema host, o qual estabelece como executar um contêiner específico. Embora o agendamento refira-se ao ato específico de carregamento da definição do serviço, de uma forma geral, agendadores são responsáveis por conectar em um sistema de inicialização do host para gerenciar serviços em qualquer capacidade necessária.

Gerenciamento de cluster é o processo de se controlar um grupo de hosts. Isso pode envolver a adição e remoção de hosts do cluster, obtenção de informações sobre o estado atual de hosts e contêineres, e inicialização e encerramento de processos. O gerenciamento de cluster está intimamente ligado ao agendamento porque o agendador deve ter acesso a cada host no cluster de forma a agendar os serviços. Por esta razão, a mesma ferramenta é geralmente utilizada para ambos os propósitos.

De modo a executar e gerenciar os contêineres em hosts por todo o cluster, o agendador deve interagir com o sistema init individual de cada host. Ao mesmo tempo, para facilitar o gerenciamento, o agendador apresenta uma visão unificada do estado dos serviços por todo o cluster. Isto acaba funcionando como um sistema init em cluster. Por esta razão, muitos agendadores espelham a estrutura de comandos do init dos sistemas que eles estão abstraindo.

Uma das maiores responsabilidades dos agendadores é a seleção de host. Se um administrador decide executar um serviço (contêiner) no cluster, o agendador geralmente fica encarregado de selecionar automaticamente um host. O administrador pode opcionalmente fornecer restrições de agendamento de acordo com suas necessidades ou desejos, mas o agendador é, em última instância, responsável pela execução com base nesses requisitos.

## Como o Agendador Toma decisões de Agendamento?

Os agendadores geralmente definem uma política padrão de agendamento. Isto determina como os serviços são agendados quando nenhuma entrada é fornecida pelo administrador. Por exemplo, um agendador poderia escolher colocar novos serviços em hosts com o menor número de serviços atualmente ativos.

Os agendadores tipicamente fornecem mecanismos de sobreposição que os administradores podem usar para afinar o processo de seleção para satisfazer requerimentos específicos. Por exemplo, se dois contêineres devem sempre executar no mesmo host porque eles operam como uma unidade, essa afinidade pode geralmente ser declarada durante o agendamento. Da mesma forma, se dois contêineres, não devem ser colocados no mesmo host, por exemplo para assegurar alta disponibilidade de duas instâncias do mesmo serviço, isto pode ser definido também.

Outras restrições que o agendador deve prestar atenção podem ser representadas por um metadado arbitrário. Hosts individuais podem ser rotulados e marcados pelos agendadores. Isto pode ser necessário, por exemplo, se um host contém o volume de dados necessário a uma aplicação. Alguns serviços podem precisar ser implantados em todo host individual no cluster. A maioria dos agendadores permitem que você faça isso.

## Quais Funções de Gerenciamento de Cluster os Agendadores Fornecem?

O agendamento está geralmente ligado a funções de gerenciamento de cluster porque ambas as funções requerem a capacidade de operar em hosts específicos e no cluster como um todo.

Software de gerenciamento de cluster pode ser utilizado para consultar informações sobre membros de um cluster, adicionar ou remover membros, ou mesmo conectar-se a hosts individuais para uma administração mais granular. Estas funções podem ser incluídas no agendador, ou podem ser responsabilidade de outro processo.

Frequentemente, o gerenciamento de cluster é também associado com ferramenta de descoberta de serviço ou repositório distribuído de valores-chave. Estes são particularmente bem adequados para armazenar este tipo de informação porque a informação está dispersa pelo próprio cluster e a plataforma já existe para a sua função primária.

Por causa disso, se o próprio agendador não fornece métodos, algumas operações de gerenciamento de cluster podem ter que ser realizadas através da modificação de valores no repositório de configuração utilizando as APIs fornecidas. Por exemplo, alterações de associações do cluster podem precisar ser tratadas através de mudanças brutas para o serviço de descoberta.

O repositório de valores-chave é também usualmente a localização onde o metadado sobre hosts individuais podem ser armazenados. Como mencionado anteriormente, rotular hosts permite que você direcione indivíduos ou grupos para decisões de agendamento.

### Como as Implantações Multi-Contêiner Encaixam-se no Agendamento?

Às vezes, mesmo que cada componente de uma aplicação tenha sido quebrado em serviços discretos, eles devem ser gerenciados como uma unidade. Há momentos em que não faria sentido nem mesmo implantar um serviço sem outro por causa das funções que cada um fornece.

O agendamento avançado, que leva em conta o agrupamento de contêiner está disponível através de alguns projetos diferentes. Existem alguns benefícios que os usuários ganham ao ter acesso a essa funcionalidade.

O gerenciamento de grupos de contêineres permite que um administrador lide com uma coleção de contêineres como uma única aplicação. Executar componentes estreitamente integrados como uma unidade simplifica o gerenciamento de aplicação sem sacrificar os benefícios da compartimentalização de funcionalidades individuais. Com efeito, isto permite que os administradores mantenham os ganhos adquiridos pela conteinerização e pela arquitetura orientada a serviço, enquanto minimiza a sobrecarga de gerenciamento adicional.

Juntar as aplicações pode significar simplesmente agendá-las juntas e fornecer a capacidade de iniciá-las e pará-las ao mesmo tempo. Pode também permitir cenários mais complexos como a configuração de sub-redes para cada grupo de aplicações ou escalar conjuntos inteiros de contêineres onde somente era possível escalar a nível do contêiner.

### O Que é Provisionamento?

Um conceito relacionado ao gerenciamento de cluster é o provisionamento. Provisionamento é o processo de se colocar novos hosts on-line e configurá-los de maneira básica de forma a deixá-los prontos para trabalhar. Com as implantações de Docker, isto normalmente implica configurar o Docker e definir o novo host para juntar-se a um cluster existente.

Embora o resultado final de provisionar um host sempre seja que o novo sistema esteja disponível para trabalhar, as metodologias variam significativamente dependendo das ferramentas usadas e o tipo de host. Por exemplo,se o host será uma máquina virtual, ferramentas como o vagrant podem ser usadas para lançar um novo host. Muitos provedores de nuvem permitem a criação de novos hosts utilizando APIs. Em contraste, provisionar um hardware físico provavelmente exigiria algumas etapas manuais. Ferramentas de gerenciamento de configuração como o Chef, Puppet, Ansible, ou Salt podem ser envolvidas de maneira a cuidar da configuração inicial do host e fornecer a ele, informações que ele precisa para conectar a um cluster existente.

O Provisionamento pode ser deixado como um processo iniciado via administrador, ou também é possível que ele possa ser ligado às ferramentas de gerenciamento de cluster para o escalonamento automático. Este último método envolve a definição de processos para requisitar hosts adicionais bem como as condições sob as quais isto deve ser automaticamente disparado. Por exemplo, se sua aplicação estiver sofrendo por um alto carregamento, você pode desejar que seu sistema lance hosts adicionais e escale horizontalmente os contêineres pela nova infraestrutura de maneira a aliviar o congestionamento.

### Quais são os Agendadores mais comuns?

Em termos de agendamento básico e gerenciamento de cluster, alguns projetos populares são:

- **fleet** : O Fleet é o componente de agendamento e gerenciamento de cluster do CoreOS. Ele lê as informações de conexão de cada host no cluster pelo etcd e fornece serviços de gerenciamento semelhantes ao systemd.
- **marathon** : O Marathon é o componente de agendamento e gerenciamento de serviço de uma instalação do Mesosphere. Ele trabalha com o mesos para controlar serviços de longa execução e fornece uma interface web para controle de processos e gerenciamento de contêiner.
- **Swarm** : Docker’s Swarm é um agendador que o projeto Docker anunciou em Dezembro de 2014. Ele espera fornecer um agendador robusto que poderá lançar contêineres em hosts provisionados com Docker, utilizando sintaxe nativa do Docker.

Como parte da estratégia de gerenciamento de cluster, as configurações do Mesosphere confiam nos seguintes componentes:

- **mesos** : O Apache mesos é uma ferramenta que abstrai e gerencia os recursos de todos os hosts em um cluster. Ele apresenta uma coleção de recursos para os componentes construídos sobre ele (como o marathon). Descreve-se como análogo a um “kernel” para configurações em cluster.

Em termos de agendamento avançado e controle de grupos de contêineres como uma única unidade, os seguintes projetos estão disponíveis:

- **kubernetes** : Agendadores avançados do Google, os kubernetes permitem muito mais controle sobre os contêineres que estão executando em sua infraestrutura. Os contêineres podem ser rotulados, agrupados, e terem suas próprias sub-redes para comunicação.
- **compose** : O projeto Docker compose foi criado para permitir o gerenciamento de grupos de contêineres utilizando arquivos de configurações declarativas. Ele utiliza os Docker Links para aprender sobre as relações de dependência entre contêineres.

## Conclusão

Gerenciamento de cluster e agendadores de tarefas são elementos chave na implementação de serviços contêinerizados em um conjunto de hosts distribuídos. Eles fornecem o principal ponto de gerenciamento para realmente começar a controlar os serviços que estão suportando suas aplicações. Através do uso dos agendadores efetivamente, você pode fazer mudanças drásticas em seus aplicativos com muito pouco esforço.
