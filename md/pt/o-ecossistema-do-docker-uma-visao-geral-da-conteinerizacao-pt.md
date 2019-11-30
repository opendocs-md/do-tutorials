---
author: Justin Ellingwood
date: 2015-06-26
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/o-ecossistema-do-docker-uma-visao-geral-da-conteinerizacao-pt
---

# O Ecossistema do Docker: Uma Visão geral da Conteinerização

### Introdução

Muitas vezes há muitos obstáculos que se interpõem no caminho de se mover facilmente seu aplicativo através do ciclo de desenvolvimento e, eventualmente, para a produção. Além do trabalho real de desenvolver seu aplicativo para responder de forma apropriada em cada ambiente, você também pode se deparar com problemas com rastreamento de dependências, escalabilidade de sua aplicação, e atualização de componentes individuais sem afetar a aplicação inteira.

A conteinerização do Docker e o projeto orientado a serviço tenta resolver muitos desses problemas. As aplicações podem ser quebradas em componentes funcionais, gerenciáveis, empacotados individualmente com todas as suas dependências, e implantados facilmente em arquiteturas irregulares. A escalabilidade e a atualização de componentes é simplificada também.

Neste guia, vamos discutir os benefícios da conteinerização e como o Docker pode ajudar a resolver muitos dos problemas que mencionamos acima. O Docker é o componente central nas implantações de contêiner distribuídos que fornecem fácil gerenciamento e escalabilidade.

## Uma Breve História da Conteinerização no Linux

Conteinerização e isolamento não são conceitos novos no mundo da computação. Alguns sistemas operacionais Unix-like alavancaram tecnologias maduras de conteinerização por mais de uma década.

No Linux, LXC, o bloco construtivo que formou a fundação para as últimas tecnologias de conteinerização foi adicionada ao kernel em 2008. LXC combinou o uso de cgroups do kernel (permite o isolamento e rastreamento da utilização de recursos) e namespaces (permite que os grupos sejam separados de forma que cada um não “veja” o outro) para implementar o isolamento leve de processos.

Mais tarde, o Docker foi introduzido como uma maneira de simplificar as ferramentas necessárias para criar e gerenciar contêineres. Ele utilizou inicialmente o LXC como seu driver de execução padrão (desde então tem desenvolvido uma biblioteca chamada `libcontainer` para esta finalidade). O Docker, embora não tenha introduzido muitas novas ideias, tornou-as acessíveis para a maioria dos desenvolvedores e administradores, através da simplificação do processo e da padronização de uma interface. Ele estimulou um interesse renovado em conteinerização no mundo Linux entre os desenvolvedores.

Enquanto alguns dos temas que vamos discutir neste artigo são mais gerais, estaremos focando principalmente em conteinerização Docker, devido à sua enorme popularidade e sua adoção padrão

## O que a Conteinerização traz para o Cenário

Os contêineres chegam com vários benefícios muito atrativos tanto para desenvolvedores quanto para administradores de sistema / equipes de operação.

Alguns dos maiores benefícios estão listados abaixo.

### Abstração do sistema host separada da aplicação conteinerizada

Os contêineres são feitos para serem completamente padronizados. Isso significa que o contêiner conecta-se ao host e a qualquer coisa fora do contêiner utilizando interfaces definidas. Um aplicação conteinerizada não deve confiar em ou estar preocupada com detalhes sobre os recursos do host subjacente ou com sua arquitetura. Isso simplifica premissas de desenvolvimento sobre o ambiente operacional. Da mesma forma, para o host, todo contêiner é uma caixa preta. Ele não se importa com os detalhes da aplicação que está dentro.

### Fácil Escalabilidade

Um dos benefícios da abstração entre o sistema host e o contêiner é que, dado um projeto correto de aplicação, a escalabilidade pode ser simples e direta. Projeto orientado a serviço (discutido mais tarde) combinado com aplicações conteinerizadas fornecem as bases para a escalabilidade fácil.

Um desenvolvedor pode executar alguns contêineres em sua estação de trabalho, enquanto este sistema pode ser escalado horizontalmente em uma área de preparação ou teste. Quando os contêineres entram em produção, eles podem escalar novamente.

### Gerenciamento Simples de Dependências e Versionamento de Aplicação

Os contêineres permitem que um desenvolvedor empacote uma aplicação ou um componente de aplicação juntamente com todas as sua dependências como um unidade. O sistema host não tem que se importar com as dependências necessárias para executar uma aplicação específica. Como ele pode executar o Docker, ele deve ser capaz de executar todos os contêineres Docker.

Isto torna fácil o gerenciamento de dependências e também simplifica o gerenciamento de versão das aplicações. Os sistemas host e as equipes de operação não são mais responsáveis por gerenciar as dependências necessárias de uma aplicação porque, além da dependência de contêineres relacionados, elas devem estar todas contidas dentro do próprio contêiner.

### Ambientes de execução extremamente leves e isolados

Embora os contêineres não forneçam o mesmo nível de isolamento e gerenciamento de recursos das tecnologias de virtualização, o que eles ganham em contrapartida é um ambiente de execução extremamente leve. Os contêineres são isolados no nível de processos, compartilhando o kernel do host. Isto significa que o contêiner em si não inclui um sistema operacional completo, levando a tempos de inicialização quase instantâneos. Os desenvolvedores podem facilmente executar centenas de contêineres a partir de suas estações de trabalho sem qualquer problema.

### Camadas Compartilhadas

Os contêineres são leves no sentido de que eles estão alocados em “camadas”. Se múltiplos contêineres estão baseados na mesma camada, eles podem compartilhar a camada subjacente sem duplicação, levando a um uso de espaço em disco mínimo para imagens posteriores.

### Agregabilidade e Previsibilidade

Os arquivos do Docker permitem aos usuários definir ações exatas para criar uma nova imagem de contêiner. Isto lhe permite escrever seu ambiente de execução como se ele fosse código, armazenando-o em um controle de versões se desejado. O mesmo arquivo Docker construído no mesmo ambiente irá sempre produzir uma imagem de contêiner idêntica.

## Utilizando Dockerfiles para compilações Consistentes, Repetitivas

Embora seja possível criar imagens de contêiner utilizando um processo interativo, é geralmente melhor colocar os passos de configuração dentro de um Dockerfile uma vez que os passos necessários são conhecidos. Dockerfiles são arquivos de compilação simples que descrevem como criar uma imagem de contêiner a partir de um ponto inicial conhecido.

Dockerfiles são incrivelmente úteis e bastante fáceis de dominar. Alguns dos benefícios que eles fornecem são:

- **Versionamento Fácil** : Dockerfiles em si podem ser sincronizados para um controle de versão para rastrear e reverter quaisquer erros.
- **Previsibilidade** : Imagens de compilação do Dockerfiles ajuda a remover erros humanos a partir do processo de criação de imagem.
- **Responsabilidade** : Se você planeja compartilhar sua imagens, normalmente é uma boa ideia fornecer o Dockerfile que criou a imagem como uma forma de outros usuários auditarem o processo. Ele normalmente fornece o histórico de comandos dos passos utilizados para criar a imagem.
- **Flexibilidade** : A criação de imagens a partir de um Dockerfile permite que você substitua os padrões que a compilação interativa fornece. Isto significa que você não tem que fornecer tantas opções de tempo de execução para obter a imagem funcionando como pretendido.

Dockerfiles são uma grande ferramenta para automação da construção de imagens de contêineres para estabelecer um processo replicável.

## A Arquitetura das Aplicações Conteinerizadas

Ao projetar aplicações para serem implantadas dentro de contêineres, uma das primeiras áreas de preocupação é a arquitetura real da aplicação. Geralmente, aplicações conteinerizadas trabalham melhor quando implementam um projeto orientado a serviço.

Aplicações orientadas a serviço quebram a funcionalidade do sistema em componentes discretos que comunicam-se entre si através de interfaces bem definidas. A tecnologia de contêiner em si encoraja este tipo de projeto porque ele permite a cada componente escalar ou atualizar independentemente.

Aplicações que implementam este tipo de projeto devem ter as seguintes qualidades:

- Elas não devem se importar ou confiar em quaisquer especificidades do sistema host
- Cada componente deve fornecer APIs consistentes que os consumidores podem utilizar para acessar o serviço
- Cada serviço deve pegar pistas das variáveis de ambiente durante a configuração inicial
- Dados de aplicação devem ser armazenados fora do contêiner em volumes montados ou em contêineres de dados

Estas estratégias permitem a cada componente ser trocado independentemente ou atualizado enquanto a API é mantida. Elas também prestam-se a focar na direção da escalabilidade horizontal devido ao fato de que cada componente pode ser escalado de acordo com o gargalo que está sendo experimentado.

Em vez de codificar de maneira estática valores específicos, cada componente geralmente pode definir valores razoáveis. O componente pode utilizar estes valores como valores de recuperação de falhas, mas devem preferir valores que possam ser obtidos do seu ambiente. Isto é geralmente conseguido através da ajuda das ferramentas de descoberta de serviço, que os componentes podem consultar durante seu processo de inicialização.

Tirando as configurações para fora do contêiner real e colocando-as no ambiente permite mudanças fáceis no comportamento da aplicação sem a reconstrução da imagem do contêiner. Também permite que uma única configuração possa influenciar várias instâncias de um componente. Em geral, o projeto orientado a serviço combina bem com estratégias de configuração de ambiente, porque ambos permitem implantações mais flexíveis e escalabilidade mais direta.

## Usando um Registrador Docker para Gerenciamento de Contêiner

Uma vez que sua aplicação está dividida em componentes funcionais e configurada para responder apropriadamente a outros contêineres e flags de configuração dentro do ambiente, o próximo passo usualmente é tornar suas imagens de contêiner disponíveis através de um registrador. Fazendo o upload das imagens de contêiner para um registrador permite que hosts de Docker baixem a imagem e lancem instâncias de contêiner simplesmente sabendo o nome da imagem.

Existem vários registradores de Docker disponíveis para esse propósito. Alguns são registradores públicos onde qualquer um pode ver e utilizar as imagens que foram registradas, enquanto outros são privados. As imagens podem ser rotuladas de modo que elas sejam fáceis de direcionar para downloads ou atualização.

## Conclusão

O Docker fornece os blocos construtivos fundamentais necessários às implantações de contêineres distribuídos. Através do empacotamento dos componentes da aplicação em seus próprios contêineres, a escalabilidade horizontal torna-se um simples processo de lançar ou desligar múltiplas instâncias de cada componente. Docker fornece as ferramentas necessárias não apenas para construir contêineres, mas também para gerenciar e compartilhá-los com novos usuários ou hosts.

Embora as aplicações conteinerizadas forneçam o processo de isolamento e empacotamento necessário para ajudar na implantação, existem muitos outros componentes necessários para gerenciar e escalar adequadamente os contêineres em um cluster de hosts distribuídos. Em nosso [próximo guia](the-docker-ecosystem-service-discovery-and-distributed-configuration-stores), discutiremos como o serviço de descoberta e os repositórios de configuração globalmente distribuídos contribuem nas implantações de contêineres em cluster.
