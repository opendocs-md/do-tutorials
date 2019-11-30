---
author: Justin Ellingwood
date: 2015-06-26
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/o-ecossistema-do-docker-servico-de-descoberta-e-repositorios-de-configuracao-distribuidos-1-pt
---

# O Ecossistema do Docker: Serviço de Descoberta e Repositórios de Configuração Distribuídos

### Introdução

Os contêineres fornecem uma solução elegante para aqueles que procuram projetar e implementar aplicativos em larga escala. Embora o Docker forneça a tecnologia real de conteinerização, muitos outros projetos auxiliam no desenvolvimento de ferramentas necessárias para inicialização e comunicação apropriada no ambiente de implantação.

Uma das tecnologias centrais em que muitos ambientes Docker confiam é o serviço de descoberta. O serviço de descoberta permite que uma aplicação ou componente descubra informações sobre seu ambiente e sua vizinhança. Isso é geralmente implementado como um repositório distribuído de valores-chave, que também serve como uma localização mais geral para ditar os detalhes de configuração. A configuração de uma ferramenta de descoberta permite a você separar sua configuração de execução do contêiner real, permitindo reutilizar a mesma imagem em inúmeros ambientes.

Neste guia discutiremos os benefícios da descoberta de serviço dentro de um ambiente de Docker em cluster. Iremos focar principalmente nos conceitos gerais, fornecendo exemplos mais específicos quando apropriado.

## Descoberta de Serviço e Repositórios de Configuração Distribuídos

A ideia básica por trás da descoberta de serviço é que qualquer nova instância de uma aplicação deve ser capaz de identificar programaticamente os detalhes de seu ambiente atual. Isto é requerido para que a nova instância seja capaz de “plugar-se” ao ambiente de aplicação existente sem intervenção manual. Ferramentas de descoberta de serviço são geralmente implementadas como registradores globalmente acessíveis que armazenam informações sobre as instâncias ou serviços que estão atualmente executando. Na maior parte do tempo, de forma a tornar esta configuração tolerante a falhas e escalável, o registro é distribuído entre os hosts disponíveis na infraestrutura.

Embora o propósito principal das plataformas de descoberta de serviço seja servir detalhes de conexão para interligar componentes, elas podem ser utilizadas mais genericamente para armazenar qualquer tipo de configuração. Muitas implantações aproveitam-se dessa capacidade escrevendo seus dados de configuração na ferramenta de descoberta. Se os contêineres estão configurados de forma que eles olhem para estes detalhes, eles podem modificar seu comportamento baseado no que encontrarem.

## Como Funciona a Descoberta de serviço?

Cada ferramenta de descoberta de serviço fornece uma API que os componentes podem usar para definir ou recuperar dados. Devido a isto, para cada componente, o endereço do serviço de descoberta deve ser configurado fisicamente na própria aplicação/contêiner, ou ser fornecido como uma opção na execução. Tipicamente a descoberta de serviço é implementada como um repositório de valores-chave acessível através de métodos http padrão.

A forma com que um portal de serviço de descoberta funciona é que cada serviço, quando ele está online, registra-se a si mesmo com a ferramenta de descoberta. Ele grava quaisquer informações que um componente relacionado possa precisar de forma a consumir o serviço que ele fornece. Por exemplo, um banco de dados MySQL deve registrar o endereço IP e a porta na qual o daemon está rodando, e opcionalmente, o username e as credenciais necessárias para entrar.

Quando um consumidor desse serviço fica online, ele está apto a consultar o registrador do serviço de descoberta por informações em um endpoint pré-definido. Ele pode, então, interagir com os componentes que precisa baseado na informação que ele busca. Um bom exemplo disso é o balanceador de carga. Ele pode localizar todos os servidores back-end que ele precisa para alimentar o tráfego, consultando o portal de descoberta de serviço e ajustando sua configuração de acordo.

Isso leva os detalhes de configuração para fora dos próprios contêineres. Um dos benefícios disso é que torna os componentes de contêineres mais flexíveis e menos atrelados à configurações específicas. Outro benefício é que isso torna simples fazer com que seus componentes reajam à novas instâncias de um serviço relacionado, permitindo reconfiguração dinâmica.

## Como o Repositório de Configuração se Relaciona?

Uma grande vantagem de um sistema de serviço de descoberta globalmente distribuído é que ele pode armazenar qualquer outro tipo de dados de configuração que seus componentes possam precisar na execução. Isso significa que você pode extrair ainda mais configurações para fora do contêiner e para dentro do ambiente de execução.

Tipicamente, para fazer esse trabalho de forma mais eficaz, suas aplicações devem ser projetadas com padrões razoáveis que podem ser sobrepostos em tempo de execução, através da consulta ao repositório de configuração. Isto lhe permite utilizar o repositório de configuração de forma similar a que você utilizaria os flags de linha de comando. A diferença é que utilizando um repositório globalmente acessível, você pode oferecer as mesmas opções para cada instância do seu componente sem trabalho adicional.

## Como o repositório de Configuração Ajuda no Gerenciamento de Cluster?

Uma função dos repositórios distribuídos de valores-chave nas implantações Docker, que pode não ser aparente inicialmente é o armazenamento e gerenciamento da associação de cluster. Repositórios de configuração são o ambiente perfeito para o rastreamento da associação de hosts para fins de ferramentas de gestão.

Algumas das informações que podem ser armazenadas sobre hosts individuais em um repositório distribuído de valores-chave são:

- Endereços IP do host
- Informações de conexões para os próprios hosts
- Metadado arbitrário e rótulos que podem ser alvo para decisões de programação
- Papel no cluster (em caso de uso do modelo leader/follower)

Estes detalhes não devem ser algo que você precise se preocupar quando da utilização de uma plataforma de descoberta de serviço em circunstâncias normais, mas eles fornecem uma localização para as ferramentas de gerenciamento para consultar ou modificar informações sobre o próprio cluster.

## E Quanto a Detecção de Falhas?

A detecção de falhas pode ser implementada de várias maneiras. A preocupação é, se um componente falhar, o serviço de descoberta será atualizado para refletir o fato de que ele não está mais disponível. Esse tipo de informação é vital de forma a minimizar falhas de aplicação ou serviço.

Muitas plataformas de descoberta de serviço permitem que os valores sejam definidos com um tempo limite configurável. O componente pode definir um valor com um tempo limite, e “pingar” o serviço de descoberta em intervalos regulares para redefinir o tempo limite. Se o componente falha e o tempo limite é atingido, aquela informação de conexão da instância é removida do repositório. A duração do tempo limite é, em grande parte, uma função da rapidez com que a aplicação necessita responder a uma falha de um componente.

Isto também pode ser conseguido pela associação de um esqueleto de contêiner “auxiliar” à cada componente, cuja única responsabilidade é verificar a saúde de cada componente periodicamente e atualizar o registrador se o componente parar de funcionar. A preocupação com este tipo de arquitetura é que o contêiner auxiliar pode parar de funcionar, levando à informações incorretas no repositório. Alguns sistemas resolvem isso sendo capazes de definir verificações de saúde na ferramenta de descoberta de serviço. Desta forma, a plataforma de descoberta em si pode checar periodicamente se os componentes registrados ainda estão disponíveis.

## E Quanto à Reconfiguração de Serviços Quando os Detalhes Mudam?

Uma melhoria chave para o modelo básico de descoberta de serviço é a reconfiguração dinâmica. Enquanto a descoberta de serviço normal lhe permite influenciar a configuração inicial dos componentes verificando a informação de descoberta na inicialização, a reconfiguração dinâmica envolve a configuração dos seus componentes para reagir à novas informações no repositório de configuração. Por exemplo, se você implementar um balanceador de carga, um verificador de integridade em um servidor de backend pode indicar que um membro do conjunto caiu. A instância em execução do balanceador de carga precisa ser informada e precisa ser capaz de ajustar sua configuração, e recarregar para dar conta disso.

Isso pode ser implementado de diversas maneiras. Uma vez que o exemplo do balanceador de carga é um dos casos de uso primário dessa habilidade, uma gama de projetos existem que focam exclusivamente na reconfiguração do balanceador de carga quando alterações de configuração são detectadas. Ajuste de configuração HAProxy é comum devido à sua onipresença no espaço do balanceamento de carga.

Alguns projetos são mais flexíveis no fato de que eles podem ser usados para disparar alterações em qualquer tipo de software. Estas ferramentas consultam regularmente o serviço de descoberta e, quando uma alteração é detectada, usam sistemas de modelos para gerar arquivos de configuração que incorporam os valores encontrados no endpoint de descoberta. Depois que um novo arquivo de configuração é gerado, o serviço afetado é recarregado.

Este tipo de reconfiguração dinâmica requer mais planejamento e configuração durante o processo de construção, porque todos estes mecanismos devem existir dentro do contêiner do componente. Isto torna o próprio contêiner do componente responsável por ajustar suas configurações. Descobrir os valores necessários para gravar na descoberta de serviço e projetar uma estrutura de dados apropriada para um fácil consumo é outro desafio que este sistema requer, mas os benefícios e a flexibilidade podem ser substanciais.

## E Quanto à Segurança?

Uma preocupação que muitas pessoas tem quando estão aprendendo sobre repositório globalmente acessível pela primeira vez é, justamente, segurança. É realmente bom guardar informações em uma localização globalmente acessível?

A resposta a esta questão depende muito do que você está escolhendo colocar no repositório e quantas camadas de segurança você julga necessárias para proteger seus dados. Quase todas as plataformas de descoberta de serviço permitem criptografar conexões com SSL/TLS. Para alguns serviços, a privacidade pode não ser tão terrivelmente importante e colocar o serviço de descoberta em uma rede privada pode ser satisfatório. Contudo, a maioria das aplicações, provavelmente se beneficiariam de segurança adicional.

Há uma série de maneiras diferentes de lidar com esse problema, e vários projetos oferecem suas próprias soluções. Uma solução de projeto é continuar a permitir o acesso aberto à própria plataforma de descoberta, mas criptografar os dados gravados nela. O consumidor da aplicação deve ter a chave associada para descriptografar os dados que encontrar no repositório. Outras partes não serão capazes de acessar os dados não criptografados.

Para uma abordagem diferente, algumas ferramentas de descoberta de serviço implementam lista de controle de acesso de forma a dividir o espaço chave em zonas separadas. Elas podem então, designar propriedade ou acessos a áreas baseado nos requerimentos de acesso definidos por um espaço chave específico. Isto estabelece uma forma fácil de fornecer informação para certas partes enquanto a mantém privativa para outros. Cada componente pode ser configurado para ter acesso somente à informação que ele precisa explicitamente.

## Quais são Algumas Ferramentas Comuns de Descoberta de Serviço?

Agora que já discutimos algumas das características gerais das ferramentas de descoberta de serviço e de repositórios de valores-chave globalmente distribuídos, podemos mencionar alguns dos projetos que se relacionam com esses conceitos.

Algumas das ferramentas de descoberta de serviço mais comuns são:

- **etcd** : Esta ferramenta foi criada pelos desenvolvedores do CoreOS para fornecer descoberta de serviço e configuração globalmente distribuída para contêineres, bem como para os próprios hosts. Ela implementa uma API http e tem um cliente de linha de comando disponível em cada máquina host.

- **consul** : Esta plataforma de descoberta de serviço tem muitas características avançadas que a destacam, incluindo verificações de integridade configuráveis, funcionalidade ACL, configuração HAProxy, etc.

- **zookeeper** : Este exemplo é um pouco mais velho do que os dois anteriores, fornecendo uma plataforma mais madura à custa de alguns recursos mais recentes.

Alguns outros projetos que expandem a descoberta de serviço básica são:

- **crypt** : O Crypt permite aos componentes proteger as informações que eles gravam utilizando criptografia de chave pública. Aos componentes que se destinam a leitura dos dados pode ser dado a chave de decodificação. Todas as outras partes não serão capazes de ler os dados.

- **confd** : O Confd é um projeto que visa permitir a reconfiguração dinâmica de aplicações arbitrárias baseado em alterações no portal de descoberta de serviço. O sistema envolve uma ferramenta para vigiar endpoints relevantes por alterações, um sistema de modelos para construir novos arquivos de configuração baseados nas informações obtidas, e a capacidade de recarregar as aplicações afetadas.

- **vulcand** : O Vulcand serve como um balanceador de carga para grupos de componentes. Ele é compatível com o etcd e altera a sua configuração com base nas alterações detectadas no repositório.

- **marathon** : Embora o marathon seja principalmente um agendador (coberto mais tarde), ele também implementa uma capacidade básica de recarregar o HAProxy quando alterações são feitas nos serviços disponíveis que ele deve balancear.

- **frontrunner** : Este projeto se junta ao marathon para fornecer uma solução mais robusta para a atualização HAProxy.

- **synapse** : Este projeto introduz uma instância de HAProxy embutida que pode rotear o tráfego para os componentes.

- **nerve** : O Nerve é utilizado em conjunto com o synapse para fornecer verificação de integridade para instâncias de componentes individuais. Se o componentes torna-se indisponível, o nerve atualiza o synapse para trazer o componente fora de rotação.

## Conclusão

A descoberta de serviço e os repositórios de configuração globais permitem ao Docker adaptar-se ao seu ambiente atual e conectar-se aos componentes existentes. Este é um pré-requisito essencial para fornecer escalabilidade e implantação simples e automática, permitindo os componentes rastrear e responder à alterações dentro de seu ambiente.

No [próximo guia](the-docker-ecosystem-networking-and-communication), vamos discutir as formas com que os contêineres Docker e os hosts podem se comunicar com configurações de rede customizadas.
