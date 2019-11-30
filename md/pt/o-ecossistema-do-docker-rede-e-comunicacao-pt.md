---
author: Justin Ellingwood
date: 2015-06-26
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/o-ecossistema-do-docker-rede-e-comunicacao-pt
---

# O Ecossistema do Docker: Rede e Comunicação

### Introdução

Ao construir sistemas distribuídos para servir contêineres Docker, comunicação e rede tornam-se extremamente importantes. A arquitetura orientada a serviço, inegavelmente, depende muito de comunicação entre os componentes, de forma a funcionar corretamente.

Neste guia, vamos discutir as diversas estratégias de rede e ferramentas utilizadas para moldar as redes utilizadas pelos contêineres em seu estado desejado. Algumas situações podem tirar vantagem de soluções nativas do Docker, enquanto outras podem utilizar projetos alternativos.

## Implementação Nativa de Rede do Docker

O Docker em si, fornece muitos dos fundamentos de rede necessários para a comunicação contêiner-para-contêiner e contêiner-para-host.

Quando o processo do Docker em si é iniciado, ele configura uma nova interface virtual de bridge chamada `docker0` no sistema host. Esta interface permite ao Docker alocar uma sub-rede virtual para utilizar entre os contêineres que ele irá executar. A bridge irá servir como ponto principal de interface entre a rede dentro do contêiner e a rede no host.

Quando um contêiner é inicializado pelo Docker, uma nova interface virtual é criada e é dado a ela um endereço dentro da faixa da sub-rede da bridge. O endereço IP é ligado à rede interna do contêiner, fornecendo à rede do contêiner um caminho para a bridge `docker0` no sistema host. O Docker automaticamente configura as regras do `iptables` para permitir encaminhamento e configura o mascaramento via NAT para tráfego originado na `docker0` destinado ao mundo externo.

### Como os Contêineres Expõem os Serviços para os Consumidores?

Outros contêineres no mesmo host estão aptos a acessarem serviços fornecidos pelos seus vizinhos sem qualquer configuração adicional. O sistema host irá simplesmente rotear as requisições originadas, e destinadas à interface `docker0` para a localização apropriada.

Os contêineres podem expor suas portas para o host, onde eles podem receber tráfego encaminhado a partir do mundo externo. As portas expostas podem ser mapeadas para o sistema host, seja selecionando uma porta específica, seja permitindo ao Docker escolher uma porta alta, aleatória e que não esteja em uso. O Docker cuida de quaisquer regras e configurações do `iptables` para rotear corretamente os pacotes nestas situações.

### Qual é a Diferença Entre Expor e Publicar uma Porta?

Ao criar imagens de contêiner ou executar um contêiner, você tem a opção de expor portas ou publicar portas. A diferença entre as duas coisas é significativa, mas pode não ser perceptível imediatamente.

Expor uma porta significa simplesmente que o Docker tomará conhecimento que a porta em questão é utilizada pelo contêiner. Isto pode então ser utilizado para propósitos de descoberta e para vinculação. Por exemplo, inspecionar um contêiner dará a você informações sobre as portas expostas. Quando contêineres estão vinculados, variáveis serão definidas no novo contêiner indicando as portas que estavam expostas no contêiner original.

Por padrão, os contêineres estão acessíveis ao sistema host e para quaisquer outros contêineres no host, independentemente se as portas estão expostas. Expor a porta simplesmente documenta o uso da porta e torna esta informação disponível para mapeamentos automáticos e vinculações.

Em contraste, publicar uma porta irá mapeá-la para a interface do host, tornando-a disponível para o mundo externo. As portas de um contêiner podem ser mapeadas para uma porta específica no host, ou o Docker poderá selecionar automaticamente um porta alta, sem uso, aleatoriamente.

### O Que São Docker Links?

O Docker fornece um mecanismo chamado “Docker links” para a configuração da comunicação entre contêineres. Se um novo contêiner é ligado ou vinculado a um contêiner existente, ao novo contêiner será dado informações de conexão para o contêiner existente através de variáveis de ambiente.

Isto fornece uma forma fácil de se estabelecer comunicação entre dois contêineres, dando ao novo contêiner informação explícita sobre como acessar o seu companheiro. As variáveis de ambiente são definidas de acordo com as portas expostas pelo outro contêiner. O endereço IP e outras informações serão preenchidas pelo próprio Docker.

## Projetos Para Expansão das Capacidades de Rede do Docker

O modelo de rede discutido acima fornece um bom ponto de partida para construção da rede. A comunicação entre contêineres no mesmo host é bastante simples e a comunicação entre hosts pode ocorrer sobre redes públicas regulares, uma vez que as portas estão mapeadas corretamente e a informação de conexão é fornecida à outra parte.

Contudo, muitas aplicações requerem ambientes de rede específicos para propósitos de segurança ou de funcionalidade. A funcionalidade nativa de rede do Docker é algo limitado nesses cenários. Por causa disto, muitos projetos foram criados para expandir o ecossistema de rede do Docker.

### Criação de Redes Sobrepostas para Abstrair a Topologia Subjacente

Uma melhoria funcional que vários projetos tem focado é o estabelecimento de redes sobrepostas. Um rede sobreposta é uma rede virtual construída sobre conexões de rede existentes.

O estabelecimento de redes sobrepostas permite a você criar um ambiente de rede mais previsível e uniforme entre os hosts. Isto pode simplificar a rede entre os contêineres independentemente de onde eles estão executando. Uma única rede virtual pode se espalhar por múltiplos hosts ou sub-redes específicas podem ser designadas para cada host dentro de uma rede unificada.

Um outro uso de uma rede sobreposta é na construção de fabric de clusters de computação. Na computação fabric, vários hosts são abstraídos e gerenciados como um única entidade, mais potente. A implementação de uma camada de computação fabric permite ao usuário final gerenciar o cluster por inteiro em vez de hosts individuais. A rede desempenha um grande papel nesse cluster.

### Configuração de Rede Avançada

Outros projetos expandem as capacidades de rede do Docker fornecendo mais flexibilidade.

A configuração padrão de rede do Docker é funcional, mas bastante simples. Essas limitações se manifestam mais plenamente quando se lida com a rede entre hosts, mas também pode impedir requisitos de rede mais personalizados dentro de um único host.

A funcionalidade adicional é fornecida através de capacidades adicionais de canalização. Estes projetos não fornecem uma configuração fora da caixa, mas eles permitem a você agrupar peças e criar cenários de rede complexos. Algumas das habilidades que você pode ganhar vão desde simplesmente estabelecer rede privada entre certos hosts, até configuração de bridges, vlans, sub-redes customizadas e gateways.

Existe também uma série de ferramentas e projetos que, mesmo não desenvolvidas com o Docker em mente, são geralmente utilizadas em ambientes Docker para fornecer a funcionalidade necessária. Em particular, tecnologias maduras de rede e tunelamento são geralmente utilizadas para fornecer comunicação segura entre hosts e entre contêineres.

## Quais São Alguns dos Projetos Comuns para Melhorar as Redes do Docker?

Existem alguns projetos diferentes focados no fornecimento de sobreposição de rede para hosts Docker. Os mais comuns são:

- **flannel** : Desenvolvido pelo time do CoreOS, este projeto foi inicialmente desenvolvido para fornecer a cada sistema host a sua própria sub-rede da rede compartilhada. Esta é uma condição necessária para que a ferramenta de orquestração dos Kubernetes do Google funcione, mas isso é útil em outras situações.

- **weave** : O Weave cria uma rede virtual que interliga cada máquina host em conjunto. Isto simplifica o roteamento de aplicação e dá a aparência de que cada contêiner está sendo conectado em um único switch de rede.

Em termos de rede avançada, os seguintes projetos visam preencher uma lacuna, fornecendo canalização adicional:

- **pipework** : Construído como uma medida paliativa até que a rede nativa do Docker se tornasse mais avançada, este projeto permite o fácil manuseio de configurações de rede arbitrariamente avançadas.

Um exemplo relevante de software existente, cooptado para adicionar funcionalidade ao Docker é:

- **tinc** : O Tinc é um software de VPN leve que é implementado utilizando túneis e criptografia. O Tinc é uma solução robusta que pode tornar a rede privada transparente para quaisquer aplicações.

## Conclusão

Fornecer serviços internos e externos através de componentes conteinerizados é um modelo muito poderoso, mas as considerações de rede tornam-se uma prioridade. Embora o Docker forneça algumas dessas funcionalidades nativamente através de interfaces virtuais, sub-redes, `iptables` e gerenciamento de tabela NAT, outros projetos foram criados para fornecer configurações mais avançadas.

No [próximo guia](the-docker-ecosystem-scheduling-and-orchestration), discutiremos como os agendadores e ferramentas de orquestração constroem em cima dessa fundação para fornecer funcionalidade de gerenciamento de cluster de contêineres.
