---
author: Brian Boucheron
date: 2018-08-27
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/a-rede-do-kubernetes-nos-bastidores-pt
---

# A Rede do Kubernetes nos Bastidores

### Introdução

O Kubernetes é um poderoso sistema de orquestração de container que pode gerenciar o deployment e a operação de aplicações containerizadas em um cluster de servidores. Além de coordenar as cargas de trabalho do container, o Kubernetes fornece a infraestrutura e as ferramentas necessárias para manter a conectividade de rede entre suas aplicações e serviços.

A [Documentação de Rede do Cluster do Kubernetes](https://kubernetes.io/docs/concepts/cluster-administration/networking/) afirma que os requisitos básicos de uma rede Kubernetes são:

- todos os containers podem se comunicar com todos os outros containers sem NAT
- todos os nodes podem se comunicar com todos os containers (e vice-versa) sem NAT
- o IP com o qual um container se vê é o mesmo IP que os outros o veem

Neste artigo, discutiremos como o Kubernetes satisfaz esses requisitos de rede dentro de um cluster: como os dados se movem dentro de um pod, entre pods e entre nodes.

Também mostraremos como um **Serviço** do Kubernetes pode fornecer um único endereço IP estático e uma entrada de DNS para uma aplicação, facilitando a comunicação com serviços que podem ser distribuídos entre vários pods de dimensionamento e deslocamento constantes.

Se você não estiver familiarizado com a terminologia dos pods e nodes do Kubernetes ou com outros itens básicos, nosso artigo [An Introduction to Kubernetes](an-introduction-to-kubernetes) cobre a arquitetura geral e os componentes envolvidos.

Primeiro, vamos dar uma olhada na situação da rede dentro de um único pod.

## A Rede do Pod

No Kubernetes, um _pod_ é a unidade mais básica de organização: um grupo de containers fortemente acoplados que estão todos intimamente relacionados e executam uma única função ou serviço.

Em termos de rede, o Kubernetes trata pods de maneira semelhante a uma máquina virtual tradicional ou a um único host físico: cada pod recebe um único endereço IP exclusivo, e todos os containers dentro do pod compartilham esse endereço e se comunicam entre si através da interface de loopback **lo** usando o nome de host **localhost**. Isso é conseguido atribuindo todos os containers do pod à mesma pilha de rede.

Essa situação deve parecer familiar para qualquer pessoa que fez o deploy de vários serviços em um único host antes dos dias da containerização. Todos os serviços precisam usar uma porta exclusiva para ouvir, mas, por outro lado, a comunicação é descomplicada e tem pouca sobrecarga.

## A Rede de Pod para Pod

A maioria dos clusters do Kubernetes precisará fazer deploy de vários pods por node. A comunicação de pod para pod pode ocorrer entre dois pods no mesmo node ou entre dois nodes diferentes.

### Comunicação Pod a Pod em um Node

Em um único node, você pode ter vários pods que precisam se comunicar diretamente uns com os outros. Antes de rastrearmos a rota de um pacote entre os pods, vamos analisar a configuração de rede de um node. O diagrama a seguir fornece uma visão geral, que abordaremos em detalhes:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/k8s-networking/single.png)

Cada node tem uma interface de rede – **eth0** neste exemplo – anexada à rede de clusters do Kubernetes. Essa interface fica dentro do namespace de rede **root** do node. Este é o namespace padrão para dispositivos de rede no Linux.

Assim como os namespaces de processo permitem que os containers isolem as aplicações em execução umas das outras, namespaces de rede isolam dispositivos de rede tais como interfaces e bridges. Cada pod em um node é atribuído ao seu próprio namespace de rede isolado.

Os namespaces de pod são conectados de volta ao namespace **root** com um _par ethernet virtual_, essencialmente um pipe entre os dois namespaces com uma interface em cada extremidade (aqui estamos utilizando **veth1** no namespace **root** e **eth0** dentro do pod).

Finalmente, os pods são conectados entre si e à interface **eth0** do node através de uma bridge, **br0** (seu node pode usar algo como **cbr0** ou **docker0** ). Uma bridge funciona essencialmente como um switch Ethernet físico, usando ARP (protocolo de resolução de endereço) ou roteamento baseado em IP para procurar outras interfaces locais para onde direcionar o tráfego.

Agora vamos rastrear um pacote do **pod1** para o **pod2** :

- **pod1** cria um pacote com o IP do **pod2** como seu destino
- O pacote trafega pelo par de ethernet virtual para o namespace root da rede
- O pacote continua até a bridge **br0**
- Como o pod de destino está no mesmo node, a bridge envia o pacote para o par de ethernet virtual do **pod2**
- O pacote trafega através do par de ethernet virtual, no namespace de rede do **pod2** e na interface de rede **eth0** do pod.

Agora que rastreamos um pacote de pod para pod dentro de um node, vamos ver como o tráfego do pod viaja entre nodes.

### Comunicação Pod para Pod entre dois Nodes

Como cada pod em um cluster tem um IP exclusivo e cada pod pode se comunicar diretamente com todos os outros pods, um pacote que se move entre os pods em dois nodes distintos é muito semelhante ao cenário anterior.

Vamos rastrear um pacote do **pod1** para o **pod3** , que está em outro node:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/k8s-networking/double.png)

- **pod1** cria um pacote com o IP do **pod3** como seu destino
- O pacote trafega pelo par de ethernet virtual para o namespace root da rede
- O pacote continua até a bridge **br0**
- A bridge não encontra nenhuma interface local para onde rotear, assim o pacote é enviado para a rota padrão via **eth0**
- _Opcional:_ se o seu cluster exigir uma sobreposição de rede para rotear corretamente os pacotes para os nodes, o pacote poderá ser encapsulado em um pacote VXLAN (ou outra técnica de virtualização de rede) antes de ir para a rede. Alternativamente, a própria rede pode ser configurada com as rotas estáticas adequadas, nesse caso, o pacote trafega para eth0 e sai da rede inalterado.
- O pacote entra na rede do cluster e é roteado para o node correto.
- O pacote entra no node de destino na **eth0**
- _Opcional:_ se o seu pacote foi encapsulado, ele será desencapsulado neste momento
- O pacote continua para a bridge **br0**
- A bridge encaminha o pacote para o par de ethernet virtual do pod de destino
- O pacote passa pelo par de ethernet virtual para a interface **eth0** do pod

Agora que estamos familiarizados com a forma como os pacotes são roteados por meio dos endereços IP do pod, vamos dar uma olhada nos _serviços_ do Kubernetes e em como eles se baseiam nessa infraestrutura.

## A Rede de Pod para Serviço

Seria difícil enviar tráfego para uma aplicação específica usando apenas IPs de pod, pois a natureza dinâmica de um cluster do Kubernetes significa que os pods podem ser movidos, reiniciados, atualizados ou redimensionados para dentro e para fora. Além disso, alguns serviços terão muitas réplicas, por isso precisamos de alguma forma de balancear a carga entre eles.

O Kubernetes resolve esse problema com os Serviços. Um Serviço é um objeto da API que mapeia um único IP virtual (VIP) para um conjunto de IPs de pod. Além disso, o Kubernetes fornece uma entrada de DNS para o nome de cada serviço e IP virtual, para que os serviços possam ser facilmente acessados por nome.

O mapeamento de IPs virtuais para IPs de pods dentro do cluster é coordenado pelo processo `kube-proxy` em cada node. Esse processo configura ou o [iptables](a-deep-dive-into-iptables-and-netfilter-architecture) ou IPVS para traduzir automaticamente os VIPs em IPs de pods antes de enviar o pacote para a rede do cluster. Conexões individuais são rastreadas para que os pacotes possam ser devidamente decodificados quando retornarem. O IPVS e o iptables podem fazer o balanceamento de carga de um único IP virtual de serviço em vários IPs de pods, embora o IPVS tenha muito mais flexibilidade nos algoritmos de balanceamento de carga que ele pode usar.

**Nota:** Este processo de rastreamento de tradução e de conexão acontece inteiramente no kernel do Linux. O kube-proxy lê a API do Kubernetes e atualiza o ip no iptables e IPVS, mas ele não está no caminho dos dados para pacotes individuais. Isso é mais eficiente e de melhor desempenho do que as versões anteriores do kube-proxy, que funcionava como um proxy de mando do usuário.

Vamos seguir a rota que um pacote leva de um pod, **pod1** novamente, para um serviço, **service1** :

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/k8s-networking/double-service.png)

- **pod1** cria um pacote com o IP do **service1** como seu destino
- O pacote trafega pelo par de ethernet virtual para o namespace root da rede
- O pacote continua até a bridge **br0**
- A bridge não encontra nenhuma interface local para onde rotear o pacote, assim o pacote é enviado para a rota padrão via **eth0**
- Iptables ou IPVS, configurados pelo `kube-proxy`, acham o IP de destino do pacote e o traduzem de um IP virtual para um dos IPs do pod de serviço, usando quaisquer algoritmos de balanceamento de carga disponíveis ou especificados
- _Opcional:_ seu pacote pode ser encapsulado neste ponto, como discutido na seção anterior
- O pacote entra na rede do cluster e é roteado para o node correto.
- O pacote entra no node de destino na **eth0**
- _Opcional:_ se o seu pacote foi encapsulado, ele será desencapsulado neste momento
- O pacote continua até a bridge **br0**
- O pacote é enviado para o par de ethernet virtual via **veth1**
- O pacote passa pelo par de ethernet virtual e entra no namespace de rede do pod através de sua interface de rede **eth0**

Quando o pacote retorna para o **node1** , a tradução de VIP para IP do pod será revertida, e o pacote retornará através da bridge e da interface virtual para o pod correto.

## Conclusão

Neste artigo, analisamos a infraestrutura de rede interna de um cluster do Kubernetes. Discutimos os blocos construtivos que compõem a rede e detalhamos a jornada salto-por-salto de pacotes em diferentes cenários.

Para mais informações sobre o Kubernetes, dê uma olhada na [tag para nossos tutoriais de Kubernetes](https://www.digitalocean.com/community/tags/kubernetes?type=tutorials) e a [documentação oficial do Kubernetes](https://kubernetes.io/docs/home/).
