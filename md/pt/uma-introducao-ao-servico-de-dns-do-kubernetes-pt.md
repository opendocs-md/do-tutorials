---
author: Brian Boucheron
date: 2018-11-05
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/uma-introducao-ao-servico-de-dns-do-kubernetes-pt
---

# Uma Introdução ao Serviço de DNS do Kubernetes

### Introdução

O Domain Name System ou Sistema de Nomes de Domínio (DNS) é um sistema para associar vários tipos de informação – como endereços IP – com nomes fáceis de lembrar. Por padrão, a maioria dos clusters de Kubernetes configura automaticamente um serviço de DNS interno para fornecer um mecanismo leve para a descoberta de serviços. O serviço de descoberta integrado torna fácil para as aplicações encontrar e se comunicar umas com as outras nos clusters de Kubernetes, mesmo quando os pods e serviços estão sendo criados, excluídos, e deslocados entre os nodes.

Os detalhes de implementação do serviço de DNS do Kubernetes mudaram nas versões recentes do Kubernetes. Neste artigo vamos dar uma olhada nas versões **kube-dns** e **CoreDNS** do serviço de DNS do Kubernetes. Vamos rever como eles operam e os registros DNS que o Kubernetes gera.

Para obter uma compreensão mais completa do DNS antes de começar, por favor leia _[Uma Introdução à Terminologia, Componentes e Conceitos do DNS](an-introduction-to-dns-terminology-components-and-concepts)_. Para qualquer tópico do Kubernetes com o qual você não esteja familiarizado, leia _[Uma Introdução ao Kubernetes](uma-introducao-ao-kubernetes-pt)_.

## O que o serviço DNS do Kubernetes fornece?

Antes da versão 1.11 do Kubernetes, o serviço de DNS do Kubernetes era baseado no **kube-dns**. A versão 1.11 introduziu o **CoreDNS** para resolver algumas preocupações de segurança e estabilidade com o kube-dns.

Independentemente do software que manipula os registros de DNS reais, as duas implementações funcionam de maneira semelhante:

- Um serviço chamado `kube-dns` e um ou mais pods são criados. 

- O serviço `kube-dns` escuta por eventos **service** e **endpoint** da API do Kubernetes e atualiza seus registros DNS quando necessário. Esses eventos são disparados quando você cria, atualiza ou exclui serviços do Kubernetes e seus pods associados.

- O kubelet define a opção `nameserver` do `/etc/resolv.conf` de cada novo pod para o IP do cluster do serviço `kube-dns`, com opções apropriadas de `search` para permitir que nomes de host mais curtos sejam usados: 

resolv.conf

    
    nameserver 10.32.0.10
    search namespace.svc.cluster.local svc.cluster.local cluster.local
    options ndots:5

- Aplicações executando em containers podem então resolver nomes de hosts como `example-service.namespace` nos endereços IP corretos do cluster. 

### Exemplo de registros DNS do Kubernetes

O registro de DNS `A` completo de um serviço do Kubernetes será semelhante ao seguinte exemplo:

    service.namespace.svc.cluster.local

Um pod teria um registro nesse formato, refletindo o endereço IP real do pod:

    10.32.0.125.namespace.pod.cluster.local

Além disso, os registros `SRV` são criados para as portas nomeadas do serviço Kubernetes:

    _port-name._protocol.service.namespace.svc.cluster.local

O resultado de tudo isso é um mecanismo de descoberta de serviço interno baseado em DNS, onde seu aplicativo ou microsserviço pode referenciar um nome de host simples e consistente para acessar outros serviços ou pods no cluster.

### Pesquisar Domínios e Resolver Nomes de Host Mais Curtos

Por causa dos sufixos de busca de domínio listados no arquivo `resolv.conf`, muitas vezes você não precisará usar o nome do host completo para entrar em contato com outro serviço. Se você estiver referenciando um serviço no mesmo namespace, poderá usar apenas o nome do serviço para contatá-lo:

    outro-service

Se o serviço estiver em um namespace diferente, adicione-o à consulta:

    outro-service.outro-namespace

Se você estiver referenciando um pod, precisará usar pelo menos o seguinte:

    pod-ip.outro-namespace.pod

Como vimos no arquivo `resolv.conf` padrão, apenas os sufixos `.svc` são automaticamente completados, então certifique-se de que você especificou tudo até o `.pod`.

Agora que sabemos os usos práticos do serviço DNS do Kubernetes, vamos analisar alguns detalhes sobre as duas diferentes implementações.

## Detalhes de implementação do DNS do Kubernetes

Como observado na seção anterior, a versão 1.11 do Kubernetes introduziu um novo software para lidar com o serviço `kube-dns`. A motivação para a mudança era aumentar o desempenho e a segurança do serviço. Vamos dar uma olhada na implementação original do `kube-dns` primeiro.

### kube-dns

O serviço `kube-dns` antes do Kubernetes 1.11 é composto de três containers executando em um pod `kube-dns` no namespace `kube-system`. Os três containers são:

- **kube-dns:** um container que executa o [SkyDNS](https://github.com/skynetservices/skydns), que realiza a resolução de consultas DNS

- **dnsmasq:** um resolvedor e cache de DNS leve e popular que armazena em cache as respostas do SkyDNS

- **sidecar:** um container sidecar que lida com relatórios de métricas e responde a verificações de integridade do serviço

As vulnerabilidades de segurança no Dnsmasq, e os problemas com desempenho ao escalar com o SkyDNS levaram à criação de um sistema substituto, o CoreDNS.

### CoreDNS

A partir do Kubernetes 1.11, um novo serviço de DNS do Kubernetes, o **CoreDNS** foi promovido à Disponibilidade Geral. Isso significa que ele está pronto para uso em produção e será o serviço DNS de cluster padrão para muitas ferramentas de instalação e provedores gerenciados do Kubernetes.

O CoreDNS é um processo único, escrito em Go, que cobre todas as funcionalidades do sistema anterior. Um único container resolve e armazena em cache as consultas DNS, responde a verificações de integridade e fornece métricas.

Além de abordar problemas relacionados a desempenho e segurança, o CoreDNS corrige alguns outros pequenos bugs e adiciona alguns novos recursos:

- Alguns problemas com incompatibilidades entre o uso de stubDomains e serviços externos foram corrigidos

- O CoreDNS pode melhorar o balanceamento de carga round-robin baseado em DNS ao randomizar a ordem na qual ele retorna determinados registros

- Um recurso chamado `autopath` pode melhorar os tempos de resposta do DNS ao resolver nomes de host externos, sendo mais inteligente ao iterar através de cada um dos sufixos de domínio de busca listados em `resolv.conf`

- Com o kube-dns `10.32.0.125.namespace.pod.cluster.local` sempre resolveria para `10.32.0.125`, mesmo que o pod não existisse realmente. O CoreDNS tem um modo “pods verificados” que somente resolverá com sucesso se o pod existir com o IP correto e no namespace correto.

Para mais informações sobre o CoreDNS e com ele se diferencia do kube-dns, você pode ler [o anúncio do Kubernetes CoreDNS GA](https://kubernetes.io/blog/2018/07/10/coredns-ga-for-kubernetes-cluster-dns/).

## Opções de Configuração Adicionais

Os operadores do Kubernetes geralmente desejam personalizar como seus pods e containers resolvem determinados domínios personalizados, ou precisam ajustar os servidores de nomes upstream ou os sufixos de domínio de busca configurados em `resolv.conf`. Você pode fazer isso com a opção `dnsConfig` na especificação do seu pod:

example\_pod.yaml

    
    apiVersion: v1
    kind: Pod
    metadata:
      namespace: example
      name: custom-dns
    spec:
      containers:
        - name: example
          image: nginx
      dnsPolicy: "None"
      dnsConfig:
        nameservers:
          - 203.0.113.44
        searches:
          - custom.dns.local

A atualização dessa configuração irá reescrever o `resolv.conf` do pod para ativar as alterações. A configuração mapeia diretamente para as opções padrão do `resolv.conf`, assim a configuração acima criaria um arquivo com as linhas `nameserver` `203.0.113.44` e `search custom.dns.local`

## Conclusão

Neste artigo, cobrimos as noções básicas sobre o que o serviço de DNS do Kubernetes fornece aos desenvolvedores, mostramos alguns exemplos de registros DNS para serviços e pods, discutimos como o sistema é implementado em diferentes versões do Kubernetes, e destacamos algumas opções de configuração adicionais disponíveis para personalizar como seus pods resolvem as consultas DNS.

Para mais informações sobre o serviço e DNS do Kubernetes, por favor, consulte [a documentação oficial do DNS do Kubernetes para Serviços e Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/).

_Por Brian Boucheron_
