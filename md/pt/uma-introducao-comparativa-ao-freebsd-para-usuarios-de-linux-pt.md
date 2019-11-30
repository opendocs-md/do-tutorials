---
author: Justin Ellingwood
date: 2015-02-19
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/uma-introducao-comparativa-ao-freebsd-para-usuarios-de-linux-pt
---

# Uma introdução comparativa ao FreeBSD para usuários de Linux

Este tutorial é a parte 1 de 7 na série: [Getting Started with FreeBSD](a-comparative-introduction-to-freebsd-for-linux-users#tutorial_series_36)

### Introdução

O FreeBSD é um sistema operacional do tipo Unix, livre e de código aberto, e uma plataforma popular de servidor. Embora o FreeBSD e outros sistemas baseados em BSD têm muito em comum com sistemas como o Linux, existem pontos onde estas duas famílias divergem em aspectos importantes.

Neste guia, vamos discutir brevemente alguns pontos em comum entre FreeBSD e Linux antes de passar para uma discussão mais extensa sobre as diferenças importantes entre eles. A maioria dos pontos abaixo podem ser aplicados corretamente à família maior dos sistemas derivados do BSD, mas em virtude do nosso foco, estaremos nos referindo principalmente ao FreeBSD como um representante da família.

## Características que o FreeBSD e o Linux compartilham

Antes de examinarmos as áreas onde o FreeBSD e o Linux diferem, vamos discutir em termos gerais, as coisas que esses sistemas têm em comum.

Enquanto o licenciamento específico que cada família emprega seja diferente (vamos discutir isto mais tarde), ambas as famílias de sistemas são livres e de código aberto. Os usuários podem ver e modificar os fontes como desejarem e o desenvolvimento é feito abertamente.

Ambas as distribuições, FreeBSD e as baseadas em Linux, são do tipo Unix em sua natureza. O FreeBSD tem raízes muito próximas dos sistemas Unix do passado, enquanto o Linux foi criado do zero como uma alternativa aberta de sistema tipo Unix. Esta associação informa sobre decisões no projeto dos sistemas, como os componentes devem interagir, e as expectativas gerais de como o sistema deve se parecer e o que deve realizar.

O comportamento tipo Unix comum é principalmente um resultado de ambas as famílias, sendo na sua maioria [compatível com POSIX](http://en.wikipedia.org/wiki/POSIX). A aparência geral e o projeto destes sistemas são bastante padronizados e utilizam padrões semelhantes. A hierarquia do sistema de arquivos é dividida de maneira similar, ambientes de shell são o método principal de interação para ambos os sistemas, e as APIs de programação compartilham características semelhantes.

Devido a estas considerações, distribuições FreeBSD e Linux são capazes de compartilhar muitas das mesmas ferramentas e aplicações. Alguns casos exigem que as versões ou sabores desses programas sejam diferentes entre os sistemas, mas os aplicativos podem ser portados mais facilmente do que com sistemas não-Unix.

Com estes pontos em mente, vamos agora passar a discutir as áreas onde estas duas famílias de sistemas operacionais divergem. Espero que essas semelhanças o ajudem a digerir com mais precisão as informações a respeito de suas diferenças.

## Diferenças de Licenciamento

Uma das diferenças mais fundamentais entre os sistemas FreeBSD e Linux trata-se do licenciamento.

O kernel do Linux, aplicações baseadas em GNU, e muitas porções de software originados no mundo Linux são licenciados sob alguma forma de GPL, ou GNU Licença Pública Geral. Esta licença é geralmente descrita com uma licença “copyleft”, que é uma forma de licenciamento que permite a liberdade para visualizar, distribuir, e modificar o código-fonte, enquanto exige que quaisquer trabalhos derivados mantenham aquele licenciamento.

O FreeBSD por sua vez, incluindo o kernel e qualquer ferramenta criada pelos contribuidores do FreeBSD, licencia seus softwares sob uma licença BSD. Este tipo de licença é mais permissiva do que a GPL na medida em que não exige que o trabalho derivado mantenha os termos de licenciamento. O que isto significa é que qualquer pessoa ou organização pode usar, distribuir, ou modificar o programa sem a necessidade de contribuir alterações de volta ou liberar a fonte do trabalho que eles estão criando. As únicas exigências são que os direitos autorais originais e uma cópia da licença BSD estejam incluídas no código-fonte ou na documentação (dependendo do método de liberação) do trabalho derivado e que um aviso de isenção, que limita a responsabilidade esteja incluído. A licença principal é bem curta e pode ser encontrada [aqui](http://choosealicense.com/licenses/bsd-2-clause/).

O apelo de cada um desses tipos de licenciamento é quase totalmente dependente da filosofia e das necessidades do usuário. As licenças GPL promovem compartilhamento e um ecossistema aberto acima de todas as outras considerações. Software proprietário tem que ter muito cuidado para não confiar em software baseado em GPL. Por outro lado, o software licenciado sob BSD pode ser livremente incorporado em aplicações proprietárias, de código-fonte fechado. Isso o torna mais atraente para muitas empresas e indivíduos com a esperança de rentabilizar o seu software, porque é possível vender o software diretamente e reter a fonte.

Os desenvolvedores tendem a preferir uma filosofia de licenciamento do que a outra, mas cada uma tem suas vantagens. Compreender o licenciamento desses sistemas pode nos ajudar a começar a entender algumas das escolhas e a filosofia que vão para dentro do seu desenvolvimento.

## A Linhagem do FreeBSD e suas Implicações

Outra diferença importante entre os sistemas FreeBSD e Linux é a linhagem e a história de cada sistema. Juntamente com as diferenças de licenciamento discutidas acima, esta é talvez o maior influenciador da filosofia a que cada grupo adere.

O Linux é um kernel desenvolvido por Linus Torvalds como um meio de substituir o sistema MINIX, voltado à educação, mas restritivo, que era utilizado na Universidade de Helsinki. Combinado com outros componentes, a maioria vindos da coleção GNU, um sistema operacional construído sobre o kernel Linux tem muitas propriedades do tipo Unix, apesar de não ser diretamente derivado de um SO Unix anterior. Como o Linux foi feito a partir do zero, sem algumas das escolhas de projeto herdadas e considerações legadas, ele pode diferenciar-se significativamente de sistemas com laços mais estreitos com o Unix.

O FreeBSD tem muitos laços diretos com sua herança Unix. BSD, ou Berkeley Software Distribution, foi uma distribuição de Unix criada na Universidade da Califórnia, Berkeley, que estendia o conjunto de características do sistema operacional Unix da AT&T e tinha condições de licenciamento agradáveis. Mais tarde, foi decidido tentar substituir o quanto possível o sistema operacional original AT&T com alternativas de código aberto de forma que os usuários não fossem obrigados a obter uma licença AT&T para utilizar o BSD. Eventualmente, todos os componentes do Unix AT&T original foram reescritos sob a licença BSD e portados para a arquitetura i386 como 386BSD. O FreeBSD foi bifurcado a partir desta base em um esforço para manter, melhorar, e modernizar o trabalho que já existia, e eventualmente foi realocado em uma versão incompleta chamada BSD-Lite por causa dos problemas de licenciamento.

Através do processo moroso e multi estágio de derivação, o FreeBSD se tornou livre em termos de licenciamento, mas mantendo laços muito próximos com seu passado. Os desenvolvedores que trabalham para criar o sistema se mantiveram investindo na forma Unix de fazer as coisas, provavelmente porque o FreeBSD sempre foi concebido para funcionar como um clone do Unix com licença aberta. Estas raízes influenciaram a direção de futuros desenvolvimentos e são a razão por trás de algumas das escolhas que vamos discutir.

## Uma Separação entre o núcleo do sistema operacional do Software Adicional

Um diferença fundamental em termos de esforço de desenvolvimento e projeto de sistema entre o FreeBSD e as distribuições Linux é o escopo do sistema. A equipe do FreeBSD desenvolve o kernel e o sistema operacional básico como uma unidade coesa, enquanto o Linux tecnicamente refere-se ao kernel, com os outros componentes vindos de uma variedade de fontes.

Isto pode parecer uma pequena diferença, mas, na verdade, afeta a forma como você interage e gerencia cada sistema. No Linux, uma distribuição pode agrupar juntos um seleto grupo pacotes, assegurando que eles operem juntos de forma tranquila. No entanto, a maioria dos componentes virão de uma ampla variedade de fontes e os desenvolvedores e mantenedores da distribuição terão a tarefa de moldá-los em um sistema que funcione corretamente.

Neste sentido, os componentes essenciais não são muito diferentes dos pacotes opcionais, disponíveis através dos repositórios da distribuição. As ferramentas de gerenciamento de pacotes da distribuição são utilizadas para rastrear e gerenciar estes componentes exatamente da mesma forma. Uma distribuição pode manter diferentes repositórios baseado em quais equipes são responsáveis por certos pacotes, de forma que a equipe principal de desenvolvimento deve preocupar-se apenas com um subconjunto de software disponível, mas isto é uma diferença organizacional e de foco e geralmente não resulta em diferenças no gerenciamento do software do ponto de vista do usuário.

Em contraste, o FreeBSD mantém um núcleo inteiro de sistema operacional. O kernel e uma coleção de software, muitos dos quais são criados pelos próprios desenvolvedores do FreeBSD, são mantidos como uma unidade. Não é simples trocar componentes que são parte desta coleção central porque ela é, nesse sentido, um conjunto monolítico de software. Isto permite à equipe do FreeBSD gerenciar muito de perto o sistema operacional principal, garantindo total integração e mais previsibilidade.

O software que está incluído no núcleo do sistema operacional é considerado completamente separado dos componentes oferecidos como adições opcionais. O FreeBSD oferece uma vasta coleção de software opcional, da mesma forma como as distribuições Linux fazem, mas ela é mantida separadamente. O sistema central é atualizado como uma unidade simples independente e o software opcional pode ser atualizado individualmente.

## Como as versões são formadas

A maioria das distribuições Linux são resultado da coleta de software a partir de uma variedade de fontes e modificados quando necessário. Os mantenedores de distribuições decidem quais componentes incluir na mídia de instalação, quais componentes incluir nos repositórios mantidos pela distribuição, etc. Depois de testar os componentes juntos, uma versão contendo o software testado é criada.

Na última seção, aprendemos que:

- Uma grande parte do sistema operacional FreeBSD é desenvolvida pela equipe da FreeBSD.
- O sistema operacional de base é o principal resultado a ser produzido.
- O software de base é considerado um conjunto coeso.

Essas qualidades conduzem a uma abordagem diferente para liberar software do que a maioria das distribuições Linux. Como o FreeBSD organiza as coisas no nível do sistema operacional, todos os componentes de base são mantidos dentro de um único repositório de código fonte. Isto tem algumas consequências importantes.

Antes de mais nada, uma vez que estas ferramentas são todas desenvolvidas em conjunto em um único repositório, uma versão é formada simplesmente selecionando uma revisão de um dos ramos do repositório. Isto é semelhante à maneira que a maioria dos softwares é liberada, em que um ponto estável é selecionado a partir de uma base de código organizada.

Como o sistema operacional base está todo sob um controle de versão ativo, isto também significa que os usuários podem “acompanhar” diferentes ramos ou níveis de estabilidade dependendo em quão bem testados eles quiserem que seus componentes de sistema sejam. Os usuários não têm de esperar por desenvolvedores para sancionar alterações, para obtê-las em seu sistema.

Isto é algo semelhante a usuários acompanhando diferentes repositórios organizados por estabilidade em certas distribuições Linux. No Linux você acompanha um repositório de pacotes, enquanto que no FreeBSD, você pode acompanhar um ramo de um repositório centralizado de fontes.

## Diferenças de Software e Projeto de Sistema

As diferenças restantes que discutiremos serão relacionadas ao software propriamente e às qualidades gerais do sistema.

### Pacotes Suportados e Instalações de Fontes

Uma das principais diferenças entre o FreeBSD e a maioria das distribuições Linux, a partir da perspectiva do usuário, é a disponibilidade e suporte em ambos, pacotes de software e software instalado através dos fontes.

Enquanto a maioria das distribuições Linux fornecem somente pacotes binários pré-compilados do software suportado na distribuição, o FreeBSD contém tanto pacotes pré-compilados quanto um sistema de construção para compilação e instalação a partir do código-fonte. Para a maioria dos softwares, isto permite a você escolher entre os pacotes pré-compilados, construídos com padrões razoáveis, e a capacidade de personalizar seu software durante o processo de compilação, construindo-o por sua conta. O FreeBSD faz isto através de um sistema que ele chama de “ports”.

O sistema de port do FreeBSD é uma coleção de software que o FreeBSD sabe como construir. Uma hierarquia organizada representando este software está disponível dentro do diretório `/usr/ports`, onde os usuários podem aprofundar para diretórios de cada aplicação. Estes diretórios contêm alguns arquivos que especificam a localização onde os arquivos fontes podem ser obtidos, bem como instruções para o compilador sobre como corrigir adequadamente os fontes para trabalhar corretamente com o FreeBSD.

As versões empacotadas de software são, na verdade, produzidas a partir do sistema de ports, fazendo do FreeBSD uma distribuição que prioriza os fontes e que possui pacotes disponíveis por conveniência. Seu sistema pode ser composto de softwares pré-empacotados e construídos através dos fontes, e o sistema de gerenciamento de software pode manipular adequadamente uma combinação destes dois tipos de métodos de instalação.

### Software Padrão versus Personalizado

Uma decisão que poderia parecer um pouco estranha para usuários familiarizados com algumas das mais populares distribuições Linux é que o FreeBSD geralmente opta em fornecer o software não modificado sempre que possível.

Muitas distribuições Linux fazem modificações no software de forma a torná-lo mais fácil de conectar com outros componentes e tentar fazer o gerenciamento ficar mais fácil também.

Enquanto muitos usuários consideram que estas alterações são úteis, há também inconvenientes para esta abordagem. Um problema em fazer modificações é que presume-se conhecer qual abordagem funciona melhor para os usuários. Isso também torna o software imprevisível para usuários provenientes de outras plataformas, uma vez que isso diverge das convenções do software original.

Os mantenedores do FreeBSD costumam modificar o software através de patches ou correções, mas estas são geralmente mudanças mais conservadoras do que as escolhas de pacotes de algumas distribuições Linux. Em geral, as modificações de software no ecossistema FreeBSD são aquelas necessárias para fazer o software compilar e executar corretamente em um ambiente FreeBSD, e aquelas requeridas para definir alguns padrões razoáveis. Os arquivos de configuração que são colocados no sistema de arquivos geralmente não são muito modificados, deste modo, um trabalho extra pode ser necessário de ser feito para obter componentes falando com outros.

### Sabores de FreeBSD para Ferramentas Comuns

Outro aspecto dos sistemas FreeBSD que pode causar confusão para usuários Linux é a disponibilidade de ferramentas familiares que operam um pouco diferente do que fariam em sistemas Linux.

O time do FreeBSD mantêm suas próprias versões de um grande número de ferramentas comuns. Enquanto muitas das ferramentas encontradas em sistemas Linux são da suíte GNU, o FreeBSD muitas vezes coloca suas próprias variantes para o seu sistema operacional.

Há algumas razões para esta decisão. Como o FreeBSD é responsável por desenvolver e manter o núcleo do sistema operacional, controlar o desenvolvimento destas aplicações e colocá-las sob uma licença BSD é essencial ou até mesmo útil. Algumas destas ferramentas também possuem laços funcionais para o BSD e o Unix de onde foram derivadas, ao contrário da suíte GNU, que, em geral, tende a ser menos compatível com versões anteriores.

Estas diferenças muitas vezes se manifestam nas opções e sintaxe dos comandos. Você pode ter executado um comando de certa forma em suas máquinas Linux, mas estes podem não funcionar da mesma forma em um servidor FreeBSD. É importante sempre verificar as páginas `man` dos comandos para familiarizar-se com as opções para as variantes do FreeBSD.

### O Shell Padrão

Um ponto relacionado que pode causar alguma confusão é que o shell padrão no FreeBSD não é o `bash`. Em vez disso, o FreeBSD utiliza o `tcsh` como seu shell padrão.

Este shell é uma versão melhorada do `csh`, que é o C shell desenvolvido para o BSD. O shell `bash` é um componente GNU, fazendo-o uma escolha pobre com um padrão para o FreeBSD. Embora ambos os shells geralmente funcionem de maneira semelhante na linha de comando, os scripts não devem ser feitos em tcsh. Utilizar o Bourne shell básico `sh` é mais confiável e evita algumas das armadilhas bem documentadas associadas com `tcsh` e scripts em `csh`.

Também vale à pena notar que é muito simples mudar o seu shell para `bash` se você estiver mais confortável nesse ambiente.

### Um Sistema de Arquivos mais Extratificado

Mencionamos diversas vezes acima que o FreeBSD distingue entre o sistema operacional base e os componentes opcionais, ou ports, que podem ser instalados em cima dessa camada.

Isto tem implicações em como o FreeBSD organiza componentes na estrutura do sistema de arquivos. No Linux, os executáveis estão tipicamente localizados nos diretórios `/bin`, `/sbin`, `/usr/sbin`, ou `/usr/bin`, dependendo do seu propósito e quão essenciais eles são para a funcionalidade central. O FreeBSD reconhece estas diferenças, mas também impõe outro nível de separação entre os componentes instalados como parte do sistema operacional e aqueles instalados como ports. O software base de sistema reside em um dos diretórios acima. Quaisquer programas que estejam instalados como um port ou pacote são colocados dentro de `/usr/local/bin` ou `/usr/local/sbin`.

O diretório `/usr/local` contém uma estrutura de diretórios que geralmente replica a estrutura encontrada no diretório `/` ou `/usr`. Quase todas as configurações para ports é feita através de arquivos localizados em `/usr/local/etc` enquanto que a configuração do sistema base é mantida em `/etc` como usual. Isto torna fácil reconhecer quando uma aplicação é parte do sistema de ports e ajuda a manter o sistema de arquivos limpo.

## Considerações Finais

O FreeBSD e o Linux têm muitas qualidades em comum, mas se você está vindo de uma experiência com Linux, é importante reconhecer e entender os modos pelos quais eles diferem. Onde seus caminhos diferem, ambos os sistemas têm suas vantagens, e os defensores de ambos os sistemas podem apontar razões para as escolhas que foram feitas.

Tratar o FreeBSD como um sistema operacional próprio em vez de insistir em vê-lo através das lentes do Linux o ajudará a evitar de lutar com o sistema operacional, e geralmente resultará em uma experiência melhor. Agora, esperamos que você tenha uma boa compreensão das diferenças a olhar, enquanto segue em frente.

Se você é novato em executar servidores FreeBSD, um bom passo adiante pode ser o nosso guia sobre [Como começar com o FreeBSD 10.1](how-to-get-started-with-freebsd-10-1).
