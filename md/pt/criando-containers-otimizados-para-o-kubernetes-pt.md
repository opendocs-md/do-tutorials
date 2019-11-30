---
author: Justin Ellingwood
date: 2019-06-26
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/criando-containers-otimizados-para-o-kubernetes-pt
---

# Criando Containers Otimizados para o Kubernetes

### Introdução

Imagens de container são o formato de empacotamento principal para a definição de aplicações no Kubernetes. Usadas como base para pods e outros objetos, as imagens desempenham um papel importante ao aproveitar os recursos do Kubernetes para executar aplicações com eficiência na plataforma. Imagens bem projetadas são seguras, altamente eficientes e focadas. Elas são capazes de reagir a dados de configuração ou instruções fornecidas pelo Kubernetes e também implementar endpoints que o sistema de orquestração usa para entender o estado interno da aplicação.

Neste artigo, vamos apresentar algumas estratégias para criar imagens de alta qualidade e discutir algumas metas gerais para ajudar a orientar suas decisões ao containerizar aplicações. Vamos nos concentrar na criação de imagens destinadas a serem executadas no Kubernetes, mas muitas das sugestões se aplicam igualmente à execução de containers em outras plataformas de orquestração ou em outros contextos.

## Características de Imagens de Container Eficientes

Antes de passarmos por ações específicas a serem tomadas ao criar imagens de container, falaremos sobre o que torna boa uma imagem de container. Quais devem ser seus objetivos ao projetar novas imagens? Quais características e quais comportamentos são mais importantes?

Algumas qualidades que podem ser indicadas são:

**Um propósito único e bem definido**

Imagens de container devem ter um único foco discreto. Evite pensar em imagens de container como máquinas virtuais, onde pode fazer sentido agrupar funcionalidades relacionadas. Em vez disso, trate suas imagens de container como utilitários Unix, mantendo um foco estrito em fazer bem uma pequena coisa. As aplicações podem ser coordenadas fora do escopo do container para compor funcionalidades complexas.

**Design genérico com a capacidade de injetar configuração em tempo de execução**

Imagens de container devem ser projetadas com a reutilização em mente quando possível. Por exemplo, a capacidade de ajustar a configuração em tempo de execução geralmente é necessária para atender aos requisitos básicos, como testar suas imagens antes de fazer o deploy em produção. Imagens pequenas e genéricas podem ser combinadas em diferentes configurações para modificar o comportamento sem criar novas imagens.

**Tamanho pequeno da imagem**

Imagens menores têm vários benefícios em ambientes em cluster, como o Kubernetes. Elas baixam rapidamente para novos nodes e geralmente têm um conjunto menor de pacotes instalados, o que pode melhorar a segurança. As imagens de container reduzidas simplificam o debug de problemas, minimizando a quantidade de software envolvida.

**Estado gerenciado externamente**

Containers em ambientes clusterizados experimentam um ciclo de vida muito volátil, incluindo desligamentos planejados e não planejados devido à escassez de recursos, dimensionamento ou falhas de node. Para manter a consistência, auxiliar na recuperação e na disponibilidade de seus serviços e evitar a perda de dados, é essencial armazenar o estado da aplicação em um local estável fora do container.

**Fácil de entender**

É importante tentar manter as imagens de container tão simples e fáceis de entender quanto possível. Ao solucionar problemas, a capacidade de raciocinar facilmente sobre o problema exibindo a configuração da imagem do container ou testando o comportamento dele pode ajudá-lo a alcançar uma resolução mais rapidamente. Pensar em imagens de container como um formato de empacotamento para sua aplicação, em vez de uma configuração de máquina, pode ajudá-lo a encontrar o equilíbrio certo.

**Siga as práticas recomendadas do software em container**

As imagens devem ter como objetivo trabalhar dentro do modelo de container, em vez de agir contra ele. Evite implementar práticas convencionais de administração de sistema, como incluir sistemas init completos e aplicações como daemon. Faça o log para a saída padrão, para que o Kubernetes possa expor os dados aos administradores, em vez de usar um daemon de log interno. Cada um desses itens difere das melhores práticas para sistemas operacionais completos.

**Aproveite totalmente os recursos do Kubernetes**

Além de estar em conformidade com o modelo de container, é importante entender e reconciliar o ambiente e as ferramentas que o Kubernetes fornece. Por exemplo, fornecer endpoints para verificações de prontidão e disponibilidade ou ajustar a operação com base nas alterações na configuração ou no ambiente pode ajudar suas aplicações a usar o ambiente de deploy dinâmico do Kubernetes a seu favor.

Agora que estabelecemos algumas das qualidades que definem imagens de container altamente funcionais, podemos mergulhar mais fundo em estratégias que ajudam você a atingir essas metas.

## Reutilizar Camadas de Base Compartilhadas Mínimas

Podemos começar examinando os recursos a partir dos quais as imagens de container são criadas: imagens de base. Cada imagem de container é construída ou a partir de uma _imagem pai_, uma imagem usada como ponto de partida ou da camada abstrata `scratch`, uma camada de imagem vazia sem sistema de arquivos. Uma _imagem de base_ é uma imagem de container que serve como fundação para futuras imagens, através da definição do sistema operacional básico e do fornecimento da funcionalidade principal. As imagens são compostas por uma ou mais camadas de imagem construídas umas sobre as outras para formar uma imagem final.

Nenhum utilitário padrão ou sistema de arquivos está disponível ao trabalhar diretamente a partir do `scratch`, o que significa que você só tem acesso a funcionalidades extremamente limitadas. Embora as imagens criadas diretamente a partir do `scratch` possam ser muito simples e minimalistas, seu objetivo principal é definir imagens de base. Normalmente, você deseja construir suas imagens de container sobre uma imagem pai que configura um ambiente básico no qual suas aplicações são executadas, para que você não precise construir um sistema completo para cada imagem.

Embora existam imagens base para uma variedade de distribuições Linux, é melhor ser deliberado sobre quais sistemas você escolhe. Cada nova máquina terá que baixar a imagem principal e as camadas complementares que você adicionou. Para imagens grandes, isso pode consumir uma quantidade significativa de largura de banda e aumentar significativamente o tempo de inicialização de seus containers em sua primeira execução. Não há como reduzir uma imagem pai usada como downstream no processo de criação de containers, portanto, começar com uma imagem pai mínima é uma boa ideia.

Ambientes ricos em recursos, como o Ubuntu, permitem que sua aplicação seja executada em um ambiente com o qual você esteja familiarizado, mas há algumas desvantagens a serem consideradas. As imagens do Ubuntu (e imagens de distribuição convencionais semelhantes) tendem a ser relativamente grandes (acima de 100 MB), o que significa que quaisquer imagens de container construídas a partir delas herdarão esse peso.

O Alpine Linux é uma alternativa popular para imagens de base porque ele compacta com sucesso muitas funcionalidades em uma imagem de base muito pequena (~ 5MB). Ele inclui um gerenciador de pacotes com repositórios consideráveis e possui a maioria dos utilitários padrão que você esperaria de um ambiente Linux mínimo.

Ao projetar suas aplicações, é uma boa ideia tentar reutilizar o mesmo pai para cada imagem. Quando suas imagens compartilham um pai, as máquinas que executam seus containers baixam a camada pai apenas uma vez. Depois disso, elas só precisarão baixar as camadas que diferem entre suas imagens. Isso significa que, se você tiver recursos ou funcionalidades comuns que gostaria de incorporar em cada imagem, criar uma imagem pai comum para herdar talvez seja uma boa ideia. Imagens que compartilham uma linhagem ajudam a minimizar a quantidade de dados extras que você precisa baixar em novos servidores.

## Gerenciando Camadas de Container

Depois que você selecionou uma imagem pai, você pode definir sua imagem de container acrescentando software adicional, copiando arquivos, expondo portas e escolhendo processos para serem executados. Certas instruções no arquivo de configuração da imagem (um `Dockerfile` se você estiver usando o Docker) adicionarão camadas complementares à sua imagem.

Por muitas das mesmas razões mencionadas na seção anterior, é importante estar ciente de como você adiciona camadas às suas imagens devido ao tamanho resultante, à herança e à complexidade do runtime. Para evitar a criação de imagens grandes e de difícil controle é importante desenvolver um bom entendimento de como as camadas de container interagem, como o mecanismo de criação faz o cache das camadas e como diferenças sutis em instruções semelhantes podem ter um grande impacto nas imagens que você cria.

### Entendendo as Camadas de Imagem e Construindo o Cache

O Docker cria uma nova camada de imagem toda vez que executa as instruções `RUN`, `COPY` ou `ADD`. Se você construir a imagem novamente, o mecanismo de construção verificará cada instrução para ver se ela possui uma camada de imagem armazenada em cache para a operação. Se ele encontrar uma correspondência no cache, ele usará a camada de imagem existente em vez de executar a instrução novamente e reconstruir a camada.

Esse processo pode reduzir significativamente os tempos de criação, mas é importante entender o mecanismo usado para evitar possíveis problemas. Para instruções de cópia de arquivos como `COPY` e `ADD`, o Docker compara os checksums dos arquivos para ver se a operação precisa ser executada novamente. Para instruções `RUN`, o Docker verifica se possui uma camada de imagem existente armazenada em cache para aquela sequência de comandos específica.

Embora não seja imediatamente óbvio, esse comportamento pode causar resultados inesperados se você não for cuidadoso. Um exemplo comum disso é a atualização do índice de pacotes local e a instalação de pacotes em duas etapas separadas. Estaremos usando o Ubuntu para este exemplo, mas a premissa básica se aplica igualmente bem às imagens de base para outras distribuições:

Dockerfile de exemplo de instalação de pacotes

    FROM ubuntu:18.04
    RUN apt -y update
    RUN apt -y install nginx
    . . .

Aqui, o índice de pacotes local é atualizado em uma instrução `RUN` (`apt -y update`) e o Nginx é instalado em outra operação. Isso funciona sem problemas quando é usado pela primeira vez. No entanto, se o Dockerfile for atualizado posteriormente para instalar um pacote adicional, pode haver problemas:

Dockerfile de exemplo de instalação de pacotes

    FROM ubuntu:18.04
    RUN apt -y update
    RUN apt -y install nginx php-fpm
    . . .

Nós adicionamos um segundo pacote ao comando de instalação executado pela segunda instrução. Se uma quantidade significativa de tempo tiver passado desde a criação da imagem anterior, a nova compilação poderá falhar. Isso ocorre porque a instrução de atualização de índice de pacotes (`RUN apt -y update`) _não_ foi alterada, portanto, o Docker reutiliza a camada de imagem associada a essa instrução. Como estamos usando um índice de pacotes antigo, a versão do pacote `php-fpm` que temos em nossos registros locais pode não estar mais nos repositórios, resultando em um erro quando a segunda instrução é executada.

Para evitar esse cenário, certifique-se de consolidar quaisquer etapas que sejam interdependentes em uma única instrução `RUN` para que o Docker reexecute todos os comandos necessários quando ocorrer uma mudança:

Dockerfile de exemplo de instalação de pacotes

    FROM ubuntu:18.04
    RUN apt -y update && apt -y install nginx php-fpm
    . . .

A instrução agora atualiza o cache do pacotes local sempre que a lista de pacotes é alterada.

### Reduzindo o Tamanho da Camada de Imagem Ajustando Instruções RUN

O exemplo anterior demonstra como o comportamento do cache do Docker pode subverter as expectativas, mas há algumas outras coisas que devem ser lembradas com relação à maneira como as instruções `RUN` interagem com o sistema de camadas do Docker. Como mencionado anteriormente, no final de cada instrução `RUN`, o Docker faz o commit das alterações como uma camada de imagem adicional. A fim de exercer controle sobre o escopo das camadas de imagens produzidas, você pode limpar arquivos desnecessários no ambiente final que serão comitados prestando atenção aos artefatos introduzidos pelos comandos que você executa.

Em geral, o encadeamento de comandos em uma única instrução `RUN` oferece um grande controle sobre a camada que será gravada. Para cada comando, você pode configurar o estado da camada (`apt -y update`), executar o comando principal (`apt install -y nginx php-fpm`) e remover quaisquer artefatos desnecessários para limpar o ambiente antes de ser comitado. Por exemplo, muitos Dockerfiles encadeiam `rm -rf /var/lib/apt/lists/*` ao final dos comandos `apt`, removendo os índices de pacotes baixados, para reduzir o tamanho final da camada:

Dockerfile de exemplo de instalação de pacotes

    FROM ubuntu:18.04
    RUN apt -y update && apt -y install nginx php-fpm && rm -rf /var/lib/apt/lists/*
    . . .

Para reduzir ainda mais o tamanho das camadas de imagem que você está criando, tentar limitar outros efeitos colaterais não intencionais dos comandos que você está executando pode ser útil. Por exemplo, além dos pacotes explicitamente declarados, o `apt` também instala pacotes “recomendados” por padrão. Você pode incluir `--no-install-recommends` aos seus comandos `apt` para remover esse comportamento. Você pode ter que experimentar para descobrir se você confia em qualquer uma das funcionalidades fornecidas pelos pacotes recomendados.

Usamos os comandos de gerenciamento de pacotes nesta seção como exemplo, mas esses mesmos princípios se aplicam a outros cenários. A idéia geral é construir as condições de pré-requisito, executar o comando mínimo viável e, em seguida, limpar quaisquer artefatos desnecessários em um único comando `RUN` para reduzir a sobrecarga da camada que você estará produzindo.

### Usando Multi-stage Builds

[**Multi-stage builds**](https://docs.docker.com/develop/develop-images/multistage-build/) foram introduzidos no Docker 17.05, permitindo aos desenvolvedores controlar mais rigidamente as imagens finais de runtime que eles produzem. Multi-stage builds ou Compilações em Vários Estágios permitem que você divida seu Dockerfile em várias seções representando estágios distintos, cada um com uma instrução `FROM` para especificar imagens pai separadas.

Seções anteriores definem imagens que podem ser usadas para criar sua aplicação e preparar ativos. Elas geralmente contêm ferramentas de compilação e arquivos de desenvolvimento necessários para produzir a aplicação, mas não são necessários para executá-la. Cada estágio subsequente definido no arquivo terá acesso aos artefatos produzidos pelos estágios anteriores.

A última declaração `FROM` define a imagem que será usada para executar a aplicação. Normalmente, essa é uma imagem reduzida que instala apenas os requisitos de runtime necessários e, em seguida, copia os artefatos da aplicação produzidos pelos estágios anteriores.

Este sistema permite que você se preocupe menos com a otimização das instruções `RUN` nos estágios de construção, já que essas camadas de container não estarão presentes na imagem de runtime final. Você ainda deve prestar atenção em como as instruções interagem com o cache de camadas nos estágios de construção, mas seus esforços podem ser direcionados para minimizar o tempo de construção em vez do tamanho final da imagem. Prestar atenção às instruções no estágio final ainda é importante para reduzir o tamanho da imagem, mas ao separar os diferentes estágios da construção do container, é mais fácil obter imagens simplificadas sem tanta complexidade no Dockerfile.

## Escopo de Funcionalidade ao Nível de Container e de Pod

Embora as escolhas que você faz em relação às instruções de criação de containers sejam importantes, decisões mais amplas sobre como containerizar seus serviços geralmente têm um impacto mais direto em seu sucesso. Nesta seção, falaremos um pouco mais sobre como fazer uma melhor transição de suas aplicações de um ambiente mais convencional para uma plataforma de container.

## Containerizando por Função

Geralmente, é uma boa prática empacotar cada parte de uma funcionalidade independente em uma imagem de container separada.

Isso difere das estratégias comuns empregadas nos ambientes de máquina virtual, em que os aplicativos são frequentemente agrupados na mesma imagem para reduzir o tamanho e minimizar os recursos necessários para executar a VM. Como os containers são abstrações leves que não virtualizam toda a pilha do sistema operacional, essa abordagem é menos atraente no Kubernetes. Assim, enquanto uma máquina virtual de stack web pode empacotar um servidor web Nginx com um servidor de aplicações Gunicorn em uma única máquina para servir uma aplicação Django, no Kubernetes eles podem ser divididos em containeres separados.

Projetar containers que implementam uma parte discreta de funcionalidade para seus serviços oferece várias vantagens. Cada container pode ser desenvolvido independentemente se as interfaces padrão entre os serviços forem estabelecidas. Por exemplo, o container Nginx poderia ser usado para fazer proxy para vários back-ends diferentes ou poderia ser usado como um balanceador de carga se tivesse uma configuração diferente.

Depois de fazer o deploy, cada imagem de container pode ser escalonada independentemente para lidar com várias restrições de recursos e de carga. Ao dividir suas aplicações em várias imagens de container, você ganha flexibilidade no desenvolvimento, na organização e no deployment.

## Combinando Imagens de Container em Pods

No Kubernetes, **pods** são a menor unidade que pode ser gerenciada diretamente pelo painel de controle. Os pods consistem em um ou mais containers juntamente com dados de configuração adicionais para informar à plataforma como esses componentes devem ser executados. Os containers em um pod são sempre lançados no mesmo worker node no cluster e o sistema reinicia automaticamente containers com falha. A abstração do pod é muito útil, mas introduz outra camada de decisões sobre como agrupar os componentes de suas aplicações.

Assim como as imagens de container, os pods também se tornam menos flexíveis quando muita funcionalidade é agrupada em uma única entidade. Os próprios pods podem ser escalados usando outras abstrações, mas os containers dentro deles não podem ser gerenciados ou redimensionados independentemente. Portanto, para continuar usando nosso exemplo anterior, os containers Nginx e Gunicorn separados provavelmente não devem ser empacotados juntos em um único pod, para que possam ser controlados e deployados separadamente.

No entanto, há cenários em que faz sentido combinar containers funcionalmente diferentes como uma unidade. Em geral, eles podem ser categorizadas como situações em que um container adicional suporta ou aprimora a funcionalidade central do container principal ou ajuda-o a adaptar-se ao seu ambiente de deployment. Alguns padrões comuns são:

- **Sidecar** : O container secundário estende a funcionalidade central do container principal, agindo em uma função de utilitário de suporte. Por exemplo, o container sidecar pode encaminhar logs ou atualizar o sistema de arquivos quando um repositório remoto é alterado. O container principal permanece focado em sua responsabilidade central, mas é aprimorado pelos recursos fornecidos pelo sidecar.
- **Ambassador** : Um container Ambassador é responsável por descobrir e conectar-se a recursos externos (geralmente complexos). O container principal pode se conectar a um container Ambassador em interfaces conhecidas usando o ambiente interno do pod. O Ambassador abstrai os recursos de back-end e o tráfego de proxies entre o container principal e o pool de recursos.
- **Adaptor** : Um container Adaptor é responsável por normalizar as interfaces primárias de container, os dados e os protocolos para alinhar com as propriedades esperadas por outros componentes. O container principal pode operar usando formatos nativos e o container Adaptor traduz e normaliza os dados para se comunicar com o mundo externo.

Como você deve ter notado, cada um desses padrões suporta a estratégia de criar imagens genéricas e padronizadas de container principais que podem ser implantadas em contextos e configurações variados. Os containers secundários ajudam a preencher a lacuna entre o container principal e o ambiente de deployment específico que está sendo usado. Alguns containers Sidecar também podem ser reutilizados para adaptar vários containers primários às mesmas condições ambientais. Esses padrões se beneficiam do sistema de arquivos compartilhado e do namespace de rede fornecidos pela abstração do pod, ao mesmo tempo em que permitem o desenvolvimento independente e o deploy flexível de containers padronizados.

## Projetando para Configuração de Runtime

Existe alguma tensão entre o desejo de construir componentes reutilizáveis e padronizados e os requisitos envolvidos na adaptação de aplicações ao seu ambiente de runtime. A configuração de runtime é um dos melhores métodos para preencher a lacuna entre essas preocupações. Componentes são criados para serem genéricos e flexíveis e o comportamento necessário é descrito no runtime, fornecendo ao software informações adicionais sobre a configuração. Essa abordagem padrão funciona para containers, assim como para aplicações.

Construir com a configuração de runtime em mente requer que você pense à frente durante as etapas de desenvolvimento de aplicação e de containerização. As aplicações devem ser projetadas para ler valores de parâmetros da linha de comando, arquivos de configuração ou variáveis de ambiente quando forem iniciados ou reiniciados. Essa lógica de análise e injeção de configuração deve ser implementada no código antes da containerização.

Ao escrever um Dockerfile, o container também deve ser projetado com a configuração de runtime em mente. Os containers possuem vários mecanismos para fornecer dados em tempo de execução. Os usuários podem montar arquivos ou diretórios do host como volumes dentro do container para ativar a configuração baseada em arquivo. Da mesma forma, as variáveis de ambiente podem ser passadas para o runtime interno do container quando o msmo é iniciado. As instruções de Dockerfile `CMD` e `ENTRYPOINT` também podem ser definidas de uma forma que permita que as informações de configuração de runtime sejam passadas como parâmetros de comando.

Como o Kubernetes manipula objetos de nível superior, como pods, em vez de gerenciar containeres diretamente, há mecanismos disponíveis para definir a configuração e injetá-la no ambiente de container em runtime. Kubernetes **ConfigMaps** e **Secrets** permitem que você defina os dados de configuração separadamente e projete os valores no ambiente de container como variáveis de ambiente ou arquivos em runtime. ConfigMaps são objetos de finalidade geral destinados a armazenar dados de configuração que podem variar de acordo com o ambiente, o estágio de teste etc. Secrets oferecem uma interface semelhante, mas são projetados especificamente para dados confidenciais, como senhas de contas ou credenciais de API.

Ao entender e utilizar corretamente as opções de configuração de runtime disponíveis em todas as camadas de abstração, você pode criar componentes flexíveis que retiram suas entradas dos valores fornecidos pelo ambiente. Isso possibilita reutilizar as mesmas imagens de container em cenários muito diferentes, reduzindo a sobrecarga de desenvolvimento, melhorando a flexibilidade da aplicação.

## Implementando o Gerenciamento de Processos com Containers

Ao fazer a transição para ambientes baseados em container, os usuários geralmente iniciam movendo as cargas de trabalho existentes, com poucas ou nenhuma alteração, para o novo sistema. Eles empacotam aplicações em containers agrupando as ferramentas que já estão usando na nova abstração. Embora seja útil utilizar seus padrões usuais para colocar as aplicações migradas em funcionamento, cair em implementações anteriores em containers pode, às vezes, levar a um design ineficaz.

### Tratando Containers como Aplicações, não como Serviços

Frequentemente surgem problemas quando os desenvolvedores implementam uma funcionalidade significativa de gerenciamento de serviços nos containers. Por exemplo, a execução de serviços systemd no container ou tornar daemons os servidores web pode ser considerada uma prática recomendada em um ambiente de computação normal, mas elas geralmente entram em conflito com as suposições inerentes ao modelo de container.

Os hosts gerenciam os eventos do ciclo de vida do container enviando sinais para o processo que opera como PID (ID do processo) 1 dentro do container. O PID 1 é o primeiro processo iniciado, que seria o sistema init em ambientes de computação tradicionais. No entanto, como o host só pode gerenciar o PID 1, usar um sistema init convencional para gerenciar processos dentro do container às vezes significa que não há como controlar a aplicação principal. O host pode iniciar, parar ou matar o sistema init interno, mas não pode gerenciar diretamente a aplicação principal. Os sinais às vezes propagam o comportamento pretendido para a aplicação em execução, mas isso adiciona complexidade e nem sempre é necessário.

Na maioria das vezes, é melhor simplificar o ambiente de execução dentro do container para que o PID 1 esteja executando a aplicação principal em primeiro plano. Nos casos em que vários processos devem ser executados, o PID 1 é responsável por gerenciar o ciclo de vida de processos subsequentes. Certas aplicações, como o Apache, lidam com isso nativamente gerando e gerenciando workers que lidam com conexões. Para outras aplicações, um script wrapper ou um sistema init muito simples como o [dumb-init](https://github.com/Yelp/dumb-init) ou o sistema init incluído [tini](https://github.com/krallin/tini) podem ser usados em alguns casos. Independentemente da implementação escolhida, o processo que está sendo executado como PID 1 no container deve responder adequadamente aos sinais `TERM` enviados pelo Kubernetes para se comportar como esperado.

### Gerenciando a Integridade do Container no Kubernetes

Os deployments e serviços do Kubernetes oferecem gerenciamento de ciclo de vida para processos de longa duração e acesso confiável e persistente a aplicações, mesmo quando os containers subjacentes precisam ser reiniciados ou as próprias implementações são alteradas. Ao retirar a responsabilidade de monitorar e manter a integridade do serviço do container, você pode aproveitar as ferramentas da plataforma para gerenciar cargas de trabalho saudáveis.

Para que o Kubernetes gerencie os containers adequadamente, ele precisa entender se as aplicações em execução nos containers são saudáveis e capazes de executar o trabalho. Para ativar isso, os containers podem implementar análises de integridade: endpoints de rede ou comandos que podem ser usados para relatar a integridade da aplicação. O Kubernetes verificará periodicamente as sondas de integridade definidas para determinar se o container está operando conforme o esperado. Se o container não responder adequadamente, o Kubernetes reinicia o container na tentativa de restabelecer a funcionalidade.

O Kubernetes também fornece sondas de prontidão, uma construção similar. Em vez de indicar se a aplicação em um container está íntegra, as sondas de prontidão determinam se a aplicação está pronta para receber tráfego. Isso pode ser útil quando uma aplicação em container tiver uma rotina de inicialização que deve ser concluída antes de estar pronta para receber conexões. O Kubernetes usa sondas ou testes de prontidão para determinar se deve adicionar um pod ou remover um pod de um serviço.

A definição de endpoints para esses dois tipos de sondagem pode ajudar o Kubernetes a gerenciar seus containers com eficiência e pode evitar que problemas no ciclo de vida do container afetem a disponibilidade do serviço. Os mecanismos para responder a esses tipos de solicitações de integridade devem ser incorporados à própria aplicação e devem ser expostos na configuração da imagem do Docker.

## Conclusão

Neste guia, abordamos algumas considerações importantes para se ter em mente ao executar aplicações em container no Kubernetes. Para reiterar, algumas das sugestões que examinamos foram:

- Use imagens pai mínimas e compartilháveis para criar imagens com o mínimo de inchaço e reduzir o tempo de inicialização
- Use multi-stage builds para separar os ambientes de criação e de runtime do container
- Combine as instruções do Dockerfile para criar camadas de imagem limpas e evitar erros de cache de imagem
- Containerize isolando a funcionalidade discreta para permitir a escalabilidade e o gerenciamento flexíveis
- Crie pods para ter uma responsabilidade única e focada
- Empacote os containers auxiliares para melhorar a funcionalidade do container principal ou para adaptá-lo ao ambiente de deployment
- Crie aplicações e containers para responder à configuração de runtime para permitir maior flexibilidade ao fazer deploy
- Execute aplicações como processos principais em containers, para que o Kubernetes possa gerenciar eventos do ciclo de vida
- Desenvolva endpoints de integridade e atividade dentro da aplicação ou container para que o Kubernetes possa monitorar a integridade do container

Durante todo o processo de desenvolvimento e deployment, você precisará tomar decisões que podem afetar a robustez e a eficácia do seu serviço. Compreender as maneiras pelas quais as aplicações conteinerizadas diferem das aplicações convencionais e aprender como elas operam em um ambiente de cluster gerenciado pode ajudá-lo a evitar algumas armadilhas comuns e permitir que você aproveite todos os recursos oferecidos pelo Kubernetes.
