---
author: Hanif Jetha
date: 2018-10-17
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/usando-uma-cdn-para-acelerar-a-entrega-de-conteudo-estatico-pt
---

# Usando uma CDN para Acelerar a Entrega de Conteúdo Estático

### Introdução

Websites e aplicações modernas geralmente entregam uma quantidade significativa de conteúdo estático para os usuários finais. Este conteúdo inclui imagens, folhas de estilo, JavaScript, e vídeo. À medida que esses recursos estáticos aumentam em número e tamanho, o uso da largura de banda aumenta e o tempo de carregamento da página aumenta, deteriorando a experiência de navegação dos usuários e reduzindo a capacidade disponível dos servidores.

Para reduzir drasticamente o tempo de carregamento de página, aumentar a performance e reduzir seus custos com largura de banda e infraestrutura, você pode implementar uma CDN, ou rede de entrega de conteúdo para armazenar em cache esses recursos em um conjunto de servidores distribuídos geograficamente.

Neste tutorial, vamos fornecer uma visão geral de alto nível de CDNs e como elas funcionam, bem como os benefícios que elas podem trazer para suas aplicações web.

## O que é uma CDN?

Content delivery network ou rede de entrega de conteúdo é um grupo de servidores geograficamente distribuídos otimizados para entregar conteúdo estático aos usuários finais. Esse conteúdo estático pode ser praticamente qualquer tipo de dados, mas as CDNs são mais comumente usadas para entregar páginas web e seus arquivos relacionados, streaming de vídeo e áudio e grandes pacotes de software.

![](http://assets.digitalocean.com/articles/CDN/without-CDN.png)

Uma CDN consiste em múltiplos _pontos de presença_ (PoPs) em várias localidades, cada qual consistindo de vários servidores de _borda_ que armazenam em cache recursos de sua _origem_, ou servidor de hospedagem. Quando um usuário visita seu website e solicita recursos estáticos como iamgens ou arquivos de JavaScript, suas solicitações são encaminhadas pela CDN para o servidor de borda mais próximo, a partir do qual o conteúdo é servido. Se o servidor de borda não tem os recursos em cache ou o cache de recursos expirou, a CDN irá buscar e armazenar em cache a versão mais recente de outro servidor de borda da CDN mais próximo ou de seus servidores de origem. Se a borda da CDN tiver uma entrada de cache para seus recursos (o que ocorre na maior parte do tempo se seu site receber uma quantidade moderada de tráfego), ela retornará a cópia em cache para o usuário final.

![](http://assets.digitalocean.com/articles/CDN/CDN.png)

Isso permite que usuários geograficamente dispersos minimizem o número de saltos necessários para receber o conteúdo estático, buscando o conteúdo diretamente do cache de uma borda próxima. O resultado é latência e perda de pacotes significativamente reduzidos, tempos de carregamento de página mais rápidos e uma carga drasticamente reduzida na sua infraestrutura de origem.

Os provedores de CDN oferecem recursos adicionais como mitigação de [DDoS](digitalocean-community-glossary#ddos-attack) e limitação de taxa, análise de usuários e otimizações para casos de uso móvel ou de streaming com custo adicional.

## Como uma CDN funciona?

Quando um usuário visita seu website, ele primeiro recebe uma resposta de um servidor de DNS contendo o endereço IP do host do seu servidor web. Seu navegador então solicita o conteúdo da página web, que geralmente consite de uma variedade de arquivos estáticos, como páginas HTML, folhas de estilo CSS, código JavaScript e imagens.

Uma vez lançada a CDN e descarregados esses recursos estáticos em sevidores da CDN, “empurrando-os” manualmente ou fazendo com que a CDN “puxe” os recursos automaticamente (ambos os mecanismos são cobertos na [próxima seção](using-a-cdn-to-speed-up-static-content-delivery#push-vs-pull-zones)), você então instrui seu webserver a reescrever os links para conteúdo estático, de modo que esses links agora apontem para arquivos hospedados pela CDN. Se você estiver usando um CMS como o WordPress, essa reescrita de link pode ser implementada usando um plugin de terceiros como o [CDN Enabler](https://wordpress.org/plugins/cdn-enabler/).

Muitas CDNs fornecem suporte para domínios personalizados, permitindo que você crie um registro CNAME em seu domínio apontando para um endpoint da CDN. Depois que a CDN recebe uma solicitação do usuário nesse endpoint (localizado na borda, muito mais perto do usuário do que seus servidores de back-end), ela então encaminha a solicitação para o Ponto de Presença (PoP) localizado mais próximo do usuário. Este PoP geralmente consiste de um ou mais servidores de borda da CDN colocados em um ponto de troca de Internet (IxP), essencialmente um datacenter que os Provedores de Serviço de Internet (ISPs) utilizam para interconectar suas redes. O balanceador de carga interno da CDN então encaminha a solicitação para um servidor de borda localizado neste PoP, que então serve o conteúdo para o usuário.

Os mecanismos de cache variam entre os provedores de CDN, mas geralmente funcionam da seguinte maneira:

1. Quando a CDN recebe uma primeira solicitação para um recurso estático, como uma imagem PNG, ele não tem o recurso em cache e deve buscar uma cópia do recurso de um servidor de borda de CDN próximo ou do próprio servidor de origem. Isso é conhecido como cache “miss” e geralmente pode ser detectado inspecionando o cabeçalho de resposta HTTP, contendo `X-Cache: MISS`. Essa solicitação inicial será mais lenta que as solicitações futuras porque, depois de concluir essa solicitação, o recurso terá sido armazenado em cache na borda.

2. As solicitações futuras para esse recurso (“hits” do cache), encaminhadas para esse local de borda, agora serão atendidas a partir do cache, até a expiração (normalmente definida através de cabeçalhos HTTP). Essas respostas serão significativamente mais rápidas do que a solicitação inicial, reduzindo drasticamente as latências para os usuários e transferindo o tráfego web para a rede da CDN. Você pode verificar se a resposta foi atendida a partir de um cache CDN, inspecionando o cabeçalho de resposta HTTP, que agora deve conter `X-Cache: HIT`. 

Para saber mais sobre como uma CDN específica funciona e como foi implementada, consulte a documentação do seu provedor de CDN.

Na próxima seção, vamos introduzir os dois tipos populares de CDNs: As CDNs **push** e **pull**

## Zonas Push versus Zonas Pull

A maioria dos provedores de CDN oferecem duas maneiras de armazenar seus dados em cache: zonas pull e zonas push.

**Zonas Pull** envolvem a entrada do endereço do seu servidor de origem, e deixar a CDN buscar e armazenar em cache automaticamente todos os recursos estáticos disponíveis em seu site. Zonas Pull são comumente usadas para fornecer recursos web de pequeno a médio porte frequentemente atualizados, como arquivos HTML, CSS e arquivos JavaScript. Depois de fornecer à CDN o endereço do servidor de origem, a próxima etapa é geralmente reconfigurar links para recursos estáticos, de forma que eles agora apontem para o URL fornecido pela CDN. A partir desse ponto, o CDN manipulará as solicitações de recursos de entrada dos usuários e fornecerá conteúdo de seus caches geograficamente distribuídos e sua origem, conforme apropriado.

Para utilizar uma **Zona Push** , você faz o upload de seus dados para um bucket ou local de armazenamento designado, que a CDN então envia para caches em sua frota distribuída de servidores de borda. As zonas Push são normalmente usadas para arquivos maiores, atualizados com pouca frequência, como arquivamentos, pacotes de software, PDFs, vídeo e arquivos de áudio.

## Benefícios do Uso de uma CDN

Quase qualquer site pode colher os benefícios fornecidos pela implementação de uma CDN, mas geralmente as principais razões para implementá-la são descarregar a largura de banda de seus servidores de origem nos servidores CDN e reduzir a latência para usuários distribuídos geograficamente.

Vamos passar por estas e várias outras grandes vantagens oferecidas pelo uso de uma CDN logo abaixo.

### Descarregamento da Origem

Se você estiver se aproximando da capacidade de largura de banda em seus servidores, o descarregamento de recursos estáticos como imagens, vídeos, arquivos CSS e JavaScript reduzirá drasticamente o uso da largura de banda dos servidores. Redes de entrega de conteúdo são projetadas e otimizadas para servir conteúdo estático, e as solicitações de clientes para esse conteúdo serão encaminhadas e servidas por servidores CDN de borda. Isso traz o benefício adicional de reduzir a carga em seus servidores de origem, pois eles servem esses dados com uma frequência muito menor.

### Latência Mais Baixa para uma Melhor Experiência do Usuário

Se sua base de usuários estiver geograficamente dispersa e uma parte não trivial de seu tráfego vier de uma área geográfica distante, uma CDN poderá diminuir a latência ao colocar em cache os recursos estáticos em servidores de borda mais próximos dos seus usuários. Ao reduzir a distância entre os usuários e o conteúdo estático, você pode fornecer conteúdo para seus usuários com mais rapidez e melhorar a experiência aumentando as velocidades de carregamento de páginas.

Esses benefícios são compostos para websites que atendem principalmente a conteúdo de vídeo com uso intensivo de largura de banda, em que altas latências e lentidão no tempo de carregamento afetam diretamente a experiência do usuário e o engajamento de conteúdo.

### Gerenciar Picos de Tráfego e Evitar Tempo de Inatividade

As CDNs permitem lidar com grandes picos e rajadas de tráfego através do balanceamento da carga de solicitações em uma grande rede distribuída de servidores de borda. Ao descarregar e armazenar em cache o conteúdo estático em uma rede de entrega, você pode acomodar um número maior de usuários simultâneos com sua infraestrutura atual.

Para sites que usam um único servidor de origem, esses grandes picos de tráfego podem sobrecarregar o sistema, causando interrupções e tempo de inatividade não planejados. A transferência do tráfego para uma infraestrutura de CDN altamente disponível e redundante, projetada para lidar com níveis variáveis de tráfego web, pode aumentar a disponibilidade de seus recursos e do seu conteúdo.

### Reduzir Custos

Como a veiculação de conteúdo estático geralmente ocupa a maior parte do uso da largura de banda, o descarregamento desses recursos em uma rede de distribuição de conteúdo pode reduzir drasticamente os gastos mensais com infraestrutura. Além de reduzir os custos de largura de banda, uma CDN pode reduzir os custos de servidor através da redução da carga nos servidores de origem, permitindo escalar a infraestrutura existente. Por fim, alguns provedores de CDN oferecem faturamento mensal com preço fixo, permitindo que você transforme seu uso de largura de banda mensal variável em um gasto recorrente estável e previsível.

### Aumentar a Segurança

Outro caso de uso comum para CDNs é a mitigação de ataques de DDoS. Muitos provedores de CDN incluem recursos para monitorar e filtrar solicitações para servidores de borda. Esses serviços analisam o tráfego web em busca de padrões suspeitos, bloqueando o tráfego de ataque mal-intencionado e, ao mesmo tempo, permitindo o tráfego de usuários confiáveis. Os provedores de CDN geralmente oferecem uma variedade de serviços de mitigação de DDoS, desde proteção contra ataques comuns no nível de infra-estrutura ([camadas OSI 3 e 4](https://en.wikipedia.org/wiki/Denial-of-service_attack#Types)), até serviços de mitigação mais avançados e limitação de taxa.

Além disso, a maioria das CDNs permite configurar o SSL completo, para que você possa criptografar o tráfego entre a CDN e o usuário final, bem como o tráfego entre a CDN e seus servidores de origem, usando certificados SSL personalizados ou fornecidos pela própria CDN.

### Escolhendo a Melhor Solução

Se o seu gargalo for a carga da CPU no servidor de origem e não a largura de banda, uma CDN pode não ser a solução mais apropriada. Nesse caso, o cache local usando caches populares, como NGINX ou Varnish, pode reduzir significativamente a carga servindo os recursos a partir da memória do sistema.

Antes de lançar uma CDN, etapas adicionais de otimização — como minimizar e compactar arquivos JavaScript e CSS e ativar a compactação de solicitação HTTP do servidor Web — podem também ter um impacto significativo em tempos de carregamento de páginas e uso de largura de banda.

Uma ferramenta útil para avaliar a velocidade de carregamento de página e melhorá-la é o [PageSpeed Insights](https://developers.google.com/speed/pagespeed/insights/) do Google. Outra ferramenta útil que fornece um detalhamento em cascata de solicitações e tempos de resposta, bem como otimizações sugeridas é o [Pingdom](https://www.pingdom.com/).

## Conclusão

Uma rede de entrega de conteúdo pode ser uma solução rápida e eficaz para melhorar a escalabilidade e disponibilidade de seus websites. Ao armazenar em cache os recursos estáticos em uma rede geograficamente distribuída de servidores otimizados, você pode reduzir muito os tempos de carregamento de página e as latências para os usuários finais. Além disso, as CDNs permitem que você reduza significativamente o uso de largura de banda, absorvendo as solicitações dos usuários e respondendo a partir do cache na borda, reduzindo assim seus custos de largura de banda e infra-estrutura.

Com plugins e suporte de terceiros para os principais frameworks como WordPress, Drupal, Django e Ruby on Rails, além de recursos adicionais como mitigação de DDoS, SSL completo, monitoramento de usuários e compactação de recursos, as CDNs podem ser uma ferramenta de impacto para proteger e otimizar websites de alto tráfego.

_Por Hanif Jetha_
