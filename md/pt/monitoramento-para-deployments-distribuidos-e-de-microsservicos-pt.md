---
author: Justin Ellingwood
date: 2019-06-11
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/monitoramento-para-deployments-distribuidos-e-de-microsservicos-pt
---

# Monitoramento para Deployments Distribuídos e de Microsserviços

### Introdução

O monitoramento de sistemas e da infraestrutura é uma responsabilidade central de equipes de operações de todos os tamanhos. A indústria desenvolveu coletivamente muitas estratégias e ferramentas para ajudar a monitorar servidores, coletar dados importantes e responder a incidentes e condições em alteração em ambientes variados. No entanto, à medida que as metodologias de software e os projetos de infraestrutura evoluem, o monitoramento deve se adaptar para atender a novos desafios e fornecer insights em um território relativamente desconhecido.

Até agora, nesta série, discutimos [o que são métricas, monitoramento e alertas](an-introduction-to-metrics-monitoring-and-alerting), e as qualidades de bons sistemas de monitoramento. Conversamos sobre [coletar métricas de sua infraestrutura e aplicações](gathering-metrics-from-your-infrastructure-and-applications) e os sinais importantes para monitorar toda a sua infraestrutura. Em nosso último guia, cobrimos como [colocar em prática métricas e alertas](putting-monitoring-and-alerting-into-practice) entendendo os componentes individuais e as qualidades do bom projeto de alertas.

Neste guia, vamos dar uma olhada em como o monitoramento e a coleta de métricas são alterados para arquiteturas e microsserviços altamente distribuídos. A crescente popularidade da computação em nuvem, dos clusters de big data e das camadas de orquestração de instâncias forçou os profissionais de operações a repensar como projetar o monitoramento em escala e a enfrentar problemas específicos com uma melhor instrumentação. Vamos falar sobre o que diferencia os novos modelos de deployment e quais estratégias podem ser usadas para atender a essas novas demandas.

## Quais Desafios Criam as Arquiteturas Altamente Distribuídas?

Para modelar e espelhar os sistemas monitorados, a infraestrutura de monitoramento sempre foi um pouco distribuída. No entanto, muitas práticas modernas de desenvolvimento — incluindo projetos em torno de microsserviços, containers e instâncias de computação intercambiáveis e efêmeras — alteraram drasticamente o cenário de monitoramento. Em muitos casos, os principais recursos desses avanços são os fatores que tornam o monitoramento mais difícil. Vamos analisar algumas das maneiras pelas quais elas diferem dos ambientes tradicionais e como isso afeta o monitoramento.

### O Trabalho é Dissociado dos Recursos Subjacentes

Algumas das mudanças mais fundamentais na forma como muitos sistemas se comportam são devido a uma explosão em novas camadas de abstração em torno das quais o software pode ser projetado. A tecnologia de containers mudou o relacionamento entre o software deployado e o sistema operacional subjacente. Os aplicações com deploy em containers têm relacionamentos diferentes com o mundo externo, com outros programas e com o sistema operacional do host, do que com as aplicações cujo deploy foi feito por meios convencionais. As abstrações de kernel e rede podem levar a diferentes entendimentos do ambiente operacional, dependendo de qual camada você verificar.

Esse nível de abstração é incrivelmente útil de várias maneiras, criando estratégias de deployment consistentes, facilitando a migração do trabalho entre hosts e permitindo que os desenvolvedores controlem de perto os ambientes de runtime de suas aplicações. No entanto, esses novos recursos surgem às custas do aumento da complexidade e de um relacionamento mais distante com os recursos que suportam cada processo.

### Aumento na Comunicação Baseada em Rede

Uma semelhança entre paradigmas mais recentes é uma dependência crescente da comunicação de rede interna para coordenar e realizar tarefas. O que antes era o domínio de uma única aplicação, agora pode ser distribuído entre muitos componentes que precisam coordenar e compartilhar informações. Isso tem algumas repercussões em termos de infraestrutura de comunicação e monitoramento.

Primeiro, como esses modelos são construídos na comunicação entre serviços pequenos e discretos, a saúde da rede se torna mais importante do que nunca. Em arquiteturas tradicionais, mais monolíticas, tarefas de coordenação, compartilhamento de informações e organização de resultados foram amplamente realizadas em aplicações com lógica de programação regular ou através de uma quantidade comparativamente pequena de comunicação externa. Em contraste, o fluxo lógico de aplicações altamente distribuídas usa a rede para sincronizar, verificar a integridade dos pares e passar informações. A saúde e o desempenho da rede impactam diretamente mais funcionalidades do que anteriormente, o que significa que é necessário um monitoramento mais intensivo para garantir a operação correta.

Embora a rede tenha se tornado mais crítica do que nunca, a capacidade de monitorá-la é cada vez mais desafiadora devido ao número estendido de participantes e linhas de comunicação individuais. Em vez de rastrear interações entre algumas aplicações, a comunicação correta entre dezenas, centenas ou milhares de pontos diferentes torna-se necessária para garantir a mesma funcionalidade. Além das considerações de complexidade, o aumento do volume de tráfego também sobrecarrega os recursos de rede disponíveis, aumentando ainda mais a necessidade de um monitoramento confiável.

### Funcionalidade e Responsabilidade Particionada para um Nível Maior

Acima, mencionamos de passagem a tendência das arquiteturas modernas de dividir o trabalho e a funcionalidade entre muitos componentes menores e discretos. Esses projetos podem ter um impacto direto no cenário de monitoramento porque tornam a clareza e a compreensão especialmente valiosas, mas cada vez mais evasivas.

Ferramentas e instrumentação mais robustas são necessárias para garantir um bom funcionamento. No entanto, como a responsabilidade de concluir qualquer tarefa é fragmentada e dividida entre diferentes workers (possivelmente em muitos hosts físicos diferentes), entender onde a responsabilidade reside em questões de desempenho ou erros pode ser difícil. Solicitações e unidades de trabalho que tocam dezenas de componentes, muitos dos quais são selecionados de um pool de possíveis candidatos, podem tornar impraticável a visualização do caminho da solicitação ou a análise da causa raiz usando mecanismos tradicionais.

### Unidades de Vida Curta e Efêmera

Uma batalha adicional na adaptação do monitoramento convencional é monitorar sensivelmente as unidades de vida curta ou efêmeras. Independentemente de as unidades de interesse serem instâncias de computação em nuvem, instâncias de container ou outras abstrações, esses componentes geralmente violam algumas das suposições feitas pelo software de monitoramento convencional.

Por exemplo, para distinguir entre um node problemático e uma instância intencionalmente destruída para reduzir a escala, o sistema de monitoramento deve ter um entendimento mais íntimo de sua camada de provisionamento e gerenciamento do que era necessário anteriormente. Para muitos sistemas modernos, esses eventos ocorrem com muito mais frequência, portanto, ajustar manualmente o domínio de monitoramento a cada vez não é prático. O ambiente de deployment muda mais rapidamente com esses projetos, portanto, a camada de monitoramento deve adotar novas estratégias para permanecer valiosa.

Uma questão que muitos sistemas devem enfrentar é o que fazer com os dados das instâncias destruídas. Embora as work units possam ser aprovisionadas e desprovisionadas rapidamente para acomodar demandas variáveis, é necessário tomar uma decisão sobre o que fazer com os dados relacionados às instâncias antigas. Os dados não perdem necessariamente seu valor imediatamente porque o worker subjacente não está mais disponível. Quando centenas ou milhares de nodes podem entrar e sair todos os dias, pode ser difícil saber como melhorar a construção de uma narrativa sobre a integridade operacional geral de seu sistema a partir dos dados fragmentados de instâncias de vida curta.

## Quais Alterações são Necessárias para Escalar seu Monitoramento?

Agora que identificamos alguns dos desafios únicos das arquiteturas e microsserviços distribuídos, podemos falar sobre como os sistemas de monitoramento podem funcionar dentro dessas realidades. Algumas das soluções envolvem reavaliar e isolar o que é mais valioso sobre os diferentes tipos de métricas, enquanto outras envolvem novas ferramentas ou novas formas de entender o ambiente em que elas habitam.

### Granularidade e Amostragem

O aumento no volume total de tráfego causado pelo elevado número de serviços é um dos problemas mais simples de se pensar. Além do aumento nos números de transferência causados por novas arquiteturas, a própria atividade de monitoramento pode começar a atolar a rede e roubar recursos do host. Para lidar melhor com o aumento de volume, você pode expandir sua infraestrutura de monitoramento ou reduzir a resolução dos dados com os quais trabalha. Vale à pena olhar ambas as abordagens, mas vamos nos concentrar na segunda, pois representa uma solução mais extensível e amplamente útil.

Alterar suas taxas de amostragem de dados pode minimizar a quantidade de dados que seu sistema precisa coletar dos hosts. A amostragem é uma parte normal da coleção de métricas que representa com que frequência você solicita novos valores para uma métrica. Aumentar o intervalo de amostragem reduzirá a quantidade de dados que você precisa manipular, mas também reduzirá a resolução — o nível de detalhes — de seus dados. Embora você deva ter cuidado e compreender sua resolução mínima útil, ajustar as taxas de coleta de dados pode ter um impacto profundo em quantos clientes de monitoramento seu sistema pode atender adequadamente.

Para diminuir a perda de informações resultante de resoluções mais baixas, uma opção é continuar a coletar dados em hosts na mesma frequência, mas compilá-los em números mais digeríveis para transferência pela rede. Computadores individuais podem agregar e calcular valores médios de métricas e enviar resumos para o sistema de monitoramento. Isso pode ajudar a reduzir o tráfego da rede, mantendo a precisão, já que um grande número de pontos de dados ainda é levado em consideração. Observe que isso ajuda a reduzir a influência da coleta de dados na rede, mas não ajuda, por si só, com a pressão envolvida na coleta desses números no host.

### Tome Decisões com Base em Dados Agregados de Várias Unidades

Como mencionado acima, um dos principais diferenciais entre sistemas tradicionais e arquiteturas modernas é a quebra de quais componentes participam no processamento de solicitações. Em sistemas distribuídos e microsserviços, é muito mais provável que uma unidade de trabalho ou worker seja dado a um grupo de workers por meio de algum tipo de camada de agendamento ou arbitragem. Isso tem implicações em muitos dos processos automatizados que você pode construir em torno do monitoramento.

Em ambientes que usam grupos de workers intercambiáveis, as políticas de verificação de integridade e de alerta podem ter relações complexas com a infraestrutura que eles monitoram. As verificações de integridade em workers individuais podem ser úteis para desativar e reciclar unidades defeituosas automaticamente. No entanto, se você tiver a automação em funcionamento, em escala, não importa muito se um único servidor web falhar em um grande pool ou grupo. O sistema irá se auto-corrigir para garantir que apenas as unidades íntegras estejam no pool ativo recebendo solicitações.

Embora as verificações de integridade do host possam detectar unidades defeituosas, a verificação da integridade do pool em si é mais apropriada para alertas. A capacidade do pool de satisfazer a carga de trabalho atual tem maior importância na experiência do usuário do que os recursos de qualquer worker individual. Os alertas com base no número de membros íntegros, na latência do agregado do pool ou na taxa de erros do pool podem notificar os operadores sobre problemas mais difíceis de serem mitigados automaticamente e mais propensos a causar impacto nos usuários.

### Integração com a Camada de Provisionamento

Em geral, a camada de monitoramento em sistemas distribuídos precisa ter um entendimento mais completo do ambiente de deploy e dos mecanismos de provisionamento. O gerenciamento automatizado do ciclo de vida se torna extremamente valioso devido ao número de unidades individuais envolvidas nessas arquiteturas. Independentemente de as unidades serem containers puros, containers em uma estrutura de orquestração ou nodes de computação em um ambiente de nuvem, existe uma camada de gerenciamento que expõe informações de integridade e aceita comandos para dimensionar e responder a eventos.

O número de peças em jogo aumenta a probabilidade estatística de falha. Com todos os outros fatores sendo iguais, isso exigiria mais intervenção humana para responder e mitigar esses problemas. Como o sistema de monitoramento é responsável por identificar falhas e degradação do serviço, se ele puder conectar-se às interfaces de controle da plataforma, isso pode aliviar uma grande classe desses problemas. Uma resposta imediata e automática desencadeada pelo software de monitoramento pode ajudar a manter a integridade operacional do seu sistema.

Essa relação estreita entre o sistema de monitoramento e a plataforma de deploy não é necessariamente obrigatória ou comum em outras arquiteturas. Mas os sistemas distribuídos automatizados visam ser auto-reguláveis, com a capacidade de dimensionar e ajustar com base em regras pré-configuradas e status observado. O sistema de monitoramento, neste caso, assume um papel central no controle do ambiente e na decisão sobre quando agir.

Outro motivo pelo qual o sistema de monitoramento deve ter conhecimento da camada de provisionamento é lidar com os efeitos colaterais de instâncias efêmeras. Em ambientes onde há rotatividade frequente nas instâncias de trabalho, o sistema de monitoramento depende de informações de um canal paralelo para entender quando as ações foram intencionais ou não. Por exemplo, sistemas que podem ler eventos de API de um provisionador podem reagir de maneira diferente quando um servidor é destruído intencionalmente por um operador do que quando um servidor repentinamente não responde sem nenhum evento associado. A capacidade de diferenciar esses eventos pode ajudar seu monitoramento a permanecer útil, preciso e confiável, mesmo que a infraestrutura subjacente possa mudar com frequência.

### Rastreio Distribuído

Um dos aspectos mais desafiadores de cargas de trabalho altamente distribuídas é entender a interação entre os diferentes componentes e isolar a responsabilidade ao tentar a análise da causa raiz. Como uma única solicitação pode afetar dúzias de pequenos programas para gerar uma resposta, pode ser difícil interpretar onde os gargalos ou alterações de desempenho se originam. Para fornecer melhores informações sobre como cada componente contribui para a latência e sobrecarga de processamento, surgiu uma técnica chamada rastreamento distribuído.

O rastreamento distribuído é uma abordagem dos sistemas de instrumentação que funciona adicionando código a cada componente para iluminar o processamento da solicitação à medida que ela percorre seus serviços. Cada solicitação recebe um identificador exclusivo na borda de sua infraestrutura que é transmitido conforme a tarefa atravessa sua infraestrutura. Cada serviço usa essa ID para relatar erros e os registros de data e hora de quando viu a solicitação pela primeira vez e quando ela foi entregue para a próxima etapa. Ao agregar os relatórios dos componentes usando o ID da solicitação, um caminho detalhado com dados de tempo precisos pode ser rastreado através de sua infraestrutura.

Esse método pode ser usado para entender quanto tempo é gasto em cada parte de um processo e identificar claramente qualquer aumento sério na latência. Essa instrumentação extra é uma maneira de adaptar a coleta de métricas a um grande número de componentes de processamento. Quando mapeado visualmente com o tempo no eixo x, a exibição resultante mostra o relacionamento entre diferentes estágios, por quanto tempo cada processo foi executado e o relacionamento de dependência entre os eventos que devem ser executados em paralelo. Isso pode ser incrivelmente útil para entender como melhorar seus sistemas e como o tempo está sendo gasto.

## Melhorando a Capacidade de Resposta Operacional para Sistemas Distribuídos

Discutimos como as arquiteturas distribuídas podem tornar a análise da causa raiz e a clareza operacional difíceis de se obter. Em muitos casos, mudar a forma como os humanos respondem e investigam questões é parte da resposta a essas ambiguidades. Configurar as ferramentas para expor as informações de uma maneira que permita analisar a situação metodicamente pode ajudar a classificar as várias camadas de dados disponíveis. Nesta seção, discutiremos maneiras de se preparar para o sucesso ao solucionar problemas em ambientes grandes e distribuídos.

### Definindo Alertas para os Quatro Sinais de Ouro em Todas as Camadas

O primeiro passo para garantir que você possa responder a problemas em seus sistemas é saber quando eles estão ocorrendo. Em nosso guia [Coletando Métricas de sua Infraestrutura e Aplicações](gathering-metrics-from-your-infrastructure-and-applications), apresentamos os quatro sinais de ouro - indicadores de monitoramento identificados pela equipe de SRE do Google como os mais vitais para rastrear. Os quatro sinais são:

- latência
- tráfego
- taxa de erro
- saturação

Esses ainda são os melhores locais para começar quando estiver instrumentando seus sistemas, mas o número de camadas que devem ser observadas geralmente aumenta para sistemas altamente distribuídos. A infraestrutura subjacente, o plano de orquestração e a camada de trabalho precisam de um monitoramento robusto com alertas detalhados definidos para identificar alterações importantes.

### Obtendo uma Visão Completa

Depois que seus sistemas identificarem uma anomalia e notificarem sua equipe, esta precisa começar a coletar dados. Antes de continuar a partir desta etapa, eles devem ter uma compreensão de quais componentes foram afetados, quando o incidente começou e qual condição de alerta específica foi acionada.

A maneira mais útil de começar a entender o escopo de um incidente é começar em um nível alto. Comece a investigar verificando dashboards e visualizações que coletam e generalizam informações de seus sistemas. Isso pode ajudá-lo a identificar rapidamente os fatores correlacionados e a entender o impacto imediato que o usuário enfrenta. Durante esse processo, você deve conseguir sobrepor informações de diferentes componentes e hosts.

O objetivo deste estágio é começar a criar um inventário mental ou físico de itens para verificar com mais detalhes e começar a priorizar sua investigação. Se você puder identificar uma cadeia de problemas relacionados que percorrem diferentes camadas, a camada mais baixa deve ter precedência: as correções para as camadas fundamentais geralmente resolvem os sintomas em níveis mais altos. A lista de sistemas afetados pode servir como uma lista de verificação informal de locais para validar as correções posteriormente quando a mitigação é implementada.

### Detalhando Problemas Específicos

Quando você perceber que tem uma visão razoável do incidente, faça uma pesquisa detalhada sobre os componentes e sistemas da sua lista em ordem de prioridade. As métricas detalhadas sobre unidades individuais ajudarão você a rastrear a rota da falha até o recurso responsável mais baixo. Ao examinar painéis de controle e entradas de log mais refinados, consulte a lista de componentes afetados para tentar entender melhor como os efeitos colaterais estão sendo propagados pelo sistema. Com microsserviços, o número de componentes interdependentes significa que os problemas se espalham para outros serviços com mais frequência.

Este estágio é focado em isolar o serviço, componente ou sistema responsável pelo incidente inicial e identificar qual problema específico está ocorrendo. Isso pode ser um código recém-implantado, uma infraestrutura física com defeito, um erro ou bug na camada de orquestração ou uma alteração na carga de trabalho que o sistema não pôde manipular normalmente. Diagnosticar o que está acontecendo e porquê permite descobrir como mitigar o problema e recuperar a saúde operacional. Entender até que ponto a resolução deste problema pode corrigir problemas relatados em outros sistemas pode ajudá-lo a continuar priorizando as tarefas de mitigação.

### Mitigando e Resolvendo os Problemas

Depois que os detalhes forem identificados, você poderá resolver ou mitigar o problema. Em muitos casos, pode haver uma maneira óbvia e rápida de restaurar o serviço fornecendo mais recursos, revertendo ou redirecionando o tráfego para uma implementação alternativa. Nestes cenários, a resolução será dividida em três fases:

- Execução de ações para contornar o problema e restaurar o serviço imediato
- Resolução do problema subjacente para recuperar a funcionalidade total e a integridade operacional
- Avaliação completa do motivo da falha e implementação de correções de longo prazo para evitar recorrência

Em muitos sistemas distribuídos, a redundância e os componentes altamente disponíveis garantirão que o serviço seja restaurado rapidamente, embora seja necessário mais trabalho em segundo plano para restaurar a redundância ou tirar o sistema de um estado degradado. Você deve usar a lista de componentes impactados compilados anteriormente como uma base de medição para determinar se a mitigação inicial resolve problemas de serviço em cascata. À medida que a sofisticação dos sistemas de monitoramento evolui, ele também pode automatizar alguns desses processos de recuperação mais completos enviando comandos para a camada de provisionamento para lançar novas instâncias de unidades com falha ou para eliminar unidades que não se comportam corretamente.

Dada a automação possível nas duas primeiras fases, o trabalho mais importante para a equipe de operações geralmente é entender as causas-raiz de um evento. O conhecimento obtido a partir desse processo pode ser usado para desenvolver novos gatilhos e políticas para ajudar a prever ocorrências futuras e automatizar ainda mais as reações do sistema. O software de monitoramento geralmente obtém novos recursos em resposta a cada incidente para proteger contra os cenários de falha recém-descobertos. Para sistemas distribuídos, rastreamentos distribuídos, entradas de log, visualizações de séries temporais e eventos como deploys recentes podem ajudá-lo a reconstruir a sequência de eventos e identificar onde o software e os processos humanos podem ser aprimorados.

Devido à complexidade específica inerente aos grandes sistemas distribuídos, é importante tratar o processo de resolução de qualquer evento significativo como uma oportunidade para aprender e ajustar seus sistemas. O número de componentes separados e os caminhos de comunicação envolvidos forçam uma grande dependência da automação e das ferramentas para ajudar a gerenciar a complexidade. A codificação de novas lições nos mecanismos de resposta e conjuntos de regras desses componentes (bem como nas políticas operacionais que sua equipe segue) é a melhor maneira de seu sistema de monitoramento manter a pegada de gerenciamento de sua equipe sob controle.

## Conclusão

Neste guia, falamos sobre alguns dos desafios específicos que as arquiteturas distribuídas e os projetos de microsserviço podem introduzir para o software de monitoramento e visibilidade. As maneiras modernas de se construir sistemas quebram algumas suposições dos métodos tradicionais, exigindo abordagens diferentes para lidar com os novos ambientes de configuração. Exploramos os ajustes que você precisará considerar ao passar de sistemas monolíticos para aqueles que dependem cada vez mais de workers efêmeros, baseados em nuvem ou em containers e alto volume de coordenação de rede. Posteriormente, discutimos algumas maneiras pelas quais a arquitetura do sistema pode afetar a maneira como você responde a incidentes e a resolução.
