---
author: Brian Boucheron
date: 2018-08-27
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-inspecionar-a-rede-do-kubernetes-pt
---

# Como Inspecionar a Rede do Kubernetes

### Introducão

O Kubernetes é um sistema de orquestração de container que pode gerenciar aplicações containerizadas em um cluster de nodes de servidores. A manutenção da conectividade de rede entre todos os containers em um cluster requer algumas técnicas avançadas de rede. Neste artigo vamos cobrir brevemente algumas ferramentas e técnicas para inspecionar essa configuração de rede.

Estas ferramentas podem ser úteis se você estiver debugando problemas de conectividade, investigando problemas de taxa de transferência de rede, ou explorando o Kubernetes para aprender como ele funciona.

Se você quiser aprender mais sobre o Kubernetes em geral, nosso guia [An Introduction to Kubernetes](an-introduction-to-kubernetes) cobre o básico. Para uma visão específica de rede do Kubernetes, por favor leia [Kubernetes Networking Under the Hood](kubernetes-networking-under-the-hood).

## Começando

Este tutorial irá assumir que você tem um cluster Kubernetes, com o `kubectl` instalado localmente e configurado para se conectar ao cluster.

As seções seguintes contém muitos comandos que se destinam a serem executados em um node do Kubernetes. Eles se parecerão com isso:

    echo 'este é um comando de node'

Comandos que devem ser executados em sua máquina local terão a seguinte aparência:

    echo 'este é um comando local'

**Nota:** A maioria dos comandos neste tutorial precisará ser executada como usuário root. Se em vez disso você usar um usuário habilitado para o sudo em seus nodes de Kubernetes, por favor adicione `sudo` para executar comandos quando necessário.

## Encontrando o IP do Cluster de um Pod

Para encontrar o endereço IP de um pod do Kubermetes, utilize o comando `kubectl get pod` em sua máquina local, com a opção `-o wide`. Esta oção irá listar mais informações, incluindo o node onde o pod reside, e o IP do cluster do pod.

    kubectl get pod -o wide

    Output
    NAME READY STATUS RESTARTS AGE IP NODE
    hello-world-5b446dd74b-7c7pk 1/1 Running 0 22m 10.244.18.4 node-one
    hello-world-5b446dd74b-pxtzt 1/1 Running 0 22m 10.244.3.4 node-two

A coluna **IP** irá conter o endereço IP local do cluster para cada pod.

Se você não vir o pod que está procurando, certifique-se de que você está no namespace certo. Você pode listar todos os pods em todos os namespaces adicionando o flag `--all-namespaces`.

## Encontrando o IP de um Serviço

Você pode também encontrar o IP de um serviço utilizando o `kubectl`. Neste caso iremos listar todos os serviços em todos os namespaces:

    kubectl get service --all-namespaces

    Output
    Output
    NAMESPACE NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    default kubernetes ClusterIP 10.32.0.1 <none> 443/TCP 6d
    kube-system csi-attacher-doplugin ClusterIP 10.32.159.128 <none> 12345/TCP 6d
    kube-system csi-provisioner-doplugin ClusterIP 10.32.61.61 <none> 12345/TCP 6d
    kube-system kube-dns ClusterIP 10.32.0.10 <none> 53/UDP,53/TCP 6d
    kube-system kubernetes-dashboard ClusterIP 10.32.226.209 <none> 443/TCP 6d

O IP do serviço pode ser encontrado na coluna **CLUSTER-IP**.

## Encontrando e Inserindo Namespaces de Rede do Pod

Cada pod do Kubernetes é atribuído ao seu próprio namespace de rede. Namespaces de rede (ou netns) são primitivas de rede do Linux que fornecem isolação entre dispositivos de rede.

Isto pode ser útil para executar comandos a partir do netns do pod, para verificar resolução de DNS ou conectividade geral de rede. Para fazer isto, precisamos primeiro olhar para o ID de processo de um dos containers em um pod. Para o Docker, podemos fazer isto com uma série de dois comandos. Primeiro, liste os containers que estão executando em um node:

    docker ps

    Output
    CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES
    173ee46a3926 gcr.io/google-samples/node-hello "/bin/sh -c 'node se…" 9 days ago Up 9 days k8s_hello-world_hello-world-5b446dd74b-pxtzt_default_386a9073-7e35-11e8-8a3d-bae97d2c1afd_0
    11ad51cb72df k8s.gcr.io/pause-amd64:3.1 "/pause" 9 days ago Up 9 days k8s_POD_hello-world-5b446dd74b-pxtzt_default_386a9073-7e35-11e8-8a3d-bae97d2c1afd_0
    . . .

Encontre o **container ID** ou **name** de qualquer container no pod que você está interessado. Na saída acima estamos mostrando dois containers:

- O primeiro container é o app `hello-world` executando no pod `hello-world`
- O segundo é um container _pause_ executando no pod `hello-world`. Este container existe apenas para manter o namespace de rede do pod

Para obter o ID de processo de um dos containers, tome nota do container ID ou name, e utilize-o no seguinte comando `docker`:

    docker inspect --format '{{ .State.Pid }}' container-id-or-name

    Output14552

Um ID de processo (ou PID) será a saída. Agora podemos utilizar o programa `nsenter` para executar um comando no namespace de rede do processo:

    nsenter -t your-container-pid -n ip addr

Certifique-se de utilizar seu próprio PID, e substitua `ip addr` pelo comando que você gostaria de executar dentro do namespace de rede do pod.

**Nota:** Uma vantagem de se utilizar `nsenter` para executar comandos no namespace do pod – versus a utilização de algo como `docker exec` – é que você tem acesso a todos os comandos disponíveis no node, em vez do conjunto de comandos gralmente limitados instalados em containers.

## Encontrando a Interface Ethernet Virtual de um Pod

Cada namespace de rede do pod comunica-se com o netns raiz do node através de um pipe ethernet virtual. No lado do node, este pipe aparece como um dispositivo que geralmente começa com `veth` e termina em um identificador único, tal como `veth77f2275` ou `veth01`. Dentro do pod este pipe aparece como `eth0`.

Pode ser útil correlacionar qual dispositivo `veth` está emparelhado com um pod em particular. Para fazer isto, vamos listar todos os dispositivos de rede no node, em seguida listar os dispositivos no namespace de rede do pod. Podemos correlacionar os números dos dispositivos entre as duas listas para fazer a conexão.

Primeiro, execute `ip addr` no namespace de rede do pod utilizando o `nsenter`. Consulte a seção anterior [Encontrando e Inserindo Namespaces de Rede do Pod](como-inspecionar-a-rede-do-kubernetes-pt#encontrando-e-inserindo-namespaces-de-rede-do-pod) para detlahes de como fazer isto:

    nsenter -t pid-do-seu-container -n ip addr

    Output
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
           valid_lft forever preferred_lft forever
    10: eth0@if11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default
        link/ether 02:42:0a:f4:03:04 brd ff:ff:ff:ff:ff:ff link-netnsid 0
        inet 10.244.3.4/24 brd 10.244.3.255 scope global eth0
           valid_lft forever preferred_lft forever

O comando mostrará uma lista das interfaces do pod. Observe o número `if11` depois de `eth0@` na saída do exemplo. Isso significa que essa `eth0` do pod está ligada à décima primeira interface do node. Agora execute `ip addr` no namespace padrão do node para listar suas interfaces:

    ip addr

    Output
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
        link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        inet 127.0.0.1/8 scope host lo
           valid_lft forever preferred_lft forever
        inet6 ::1/128 scope host
           valid_lft forever preferred_lft forever
    
    . . .
    
    7: veth77f2275@if6: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master docker0 state UP group default
        link/ether 26:05:99:58:0d:b9 brd ff:ff:ff:ff:ff:ff link-netnsid 0
        inet6 fe80::2405:99ff:fe58:db9/64 scope link
           valid_lft forever preferred_lft forever
    9: vethd36cef3@if8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master docker0 state UP group default
        link/ether ae:05:21:a2:9a:2b brd ff:ff:ff:ff:ff:ff link-netnsid 1
        inet6 fe80::ac05:21ff:fea2:9a2b/64 scope link
           valid_lft forever preferred_lft forever
    11: veth4f7342d@if10: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master docker0 state UP group default
        link/ether e6:4d:7b:6f:56:4c brd ff:ff:ff:ff:ff:ff link-netnsid 2
        inet6 fe80::e44d:7bff:fe6f:564c/64 scope link
           valid_lft forever preferred_lft forever

A décima primeira interface é a `veth4f7342d` nessa saída do exemplo. Este é o pipe ethernet virtual para o pod que estamos inevstigando.

## Inspeção do Rastreamento de Conexão do Conntrack

Antes da versão 1.11, o Kubernetes usava o iptables NAT e o módulo conntrack do kernel para rastrear conexões. Para listar todas as conexões sendo rastreadas atualmente, utilize o comando `conntrack`:

    conntrack -L

Para assitir continuamente por novas conexões, utilize o flag `-E`:

    conntrack -E

Para listar conexões controladas pelo conntrack a um endereço de destino específico, utilize o flag `-d`:

    conntrack -L -d 10.32.0.1

Se os seus nodes estão tendo problemas para fazer conexões confiáveis aos serviços, é possível que sua tabela de rastreamento de conexões esteja cheia e que novas conexões estejam sendo descartadas. Se é esse o caso você pode ver mensagens como as seguintes em seus logs de sistema:

/var/log/syslog

    
    Jul 12 15:32:11 worker-528 kernel: nf_conntrack: table full, dropping packet.
    

Há uma configuração do sysctl para o número máximo de conexões a serem rastreadas. Você pode listar o valor atual com o seguinte comando:

    sysctl net.netfilter.nf_conntrack_max

    Output
    net.netfilter.nf_conntrack_max = 131072

Para definir um novo valor, utilize o flag `-w`:

    sysctl -w net.netfilter.nf_conntrack_max=198000

Para tornar essa configuração permanente, adicione-a ao arquivo `sysctl.conf`:

/etc/sysctl.conf

    
    . . .
    net.ipv4.netfilter.ip_conntrack_max = 198000

## Inspecionando as Regras do Iptables

Antes da versão 1.11, o Kubernetes usou o iptables NAT para implementar tradução de IP virtual e o balanceamento de carga para IPs de Serviço.

Para fazer um dump de todas as regras iptables em um node, utilize o comando `iptables-save`:

    iptables-save

Como a saída pode ser longa, você pode querer redirecionar para um arquivo (`iptables-save > output.txt`) ou um paginador (`iptables-save | less`) para avaliar suas regras mais facilmente.

Para listar apenas as regras NAT do Serviço do Kubernetes, utilize o comando `iptables` e o flag `-L` para especificar o canal correto:

    iptables -t nat -L KUBE-SERVICES

    Output
    Chain KUBE-SERVICES (2 references)
    target prot opt source destination
    KUBE-SVC-TCOU7JCQXEZGVUNU udp -- anywhere 10.32.0.10 /* kube-system/kube-dns:dns cluster IP */ udp dpt:domain
    KUBE-SVC-ERIFXISQEP7F7OF4 tcp -- anywhere 10.32.0.10 /* kube-system/kube-dns:dns-tcp cluster IP */ tcp dpt:domain
    KUBE-SVC-XGLOHA7QRQ3V22RZ tcp -- anywhere 10.32.226.209 /* kube-system/kubernetes-dashboard: cluster IP */ tcp dpt:https
    . . .

## Consultando o DNS do Cluster

Uma maneira de fazer o debug da resolução de DNS do cluster é fazer o deploy de um container para debug com todas as feramentas que você precisa, em seguida utilize `kubectl` para executar `nslookup` nele. Isso é descrito na [documentação oficial do Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/).

Outra maneira de consultar o DNS do cluster é a utilização do `dig` e `nsenter` a partir do node. Se o `dig` não está instalado, pode-se instalar com o `apt` em distribuições Linux baseadas em Debian.

    apt install dnsutils

Primeiro, encontre o IP do cluster do serviço **kube-dns** :

    kubectl get service -n kube-system kube-dns

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    kube-dns ClusterIP 10.32.0.10 <none> 53/UDP,53/TCP 15d

O IP do cluster está destacado acima. Em seguida, vamos utilizar `nsenter` para executar o `dig` no namespace do container. Veja a seção [_Encontrando e Inserindo Namespaces de Rede do Pod_](como-inspecionar-a-rede-do-kubernetes-pt#encontrando-e-inserindo-namespaces-de-rede-do-pod) para mais informações sobre isso.

    nsenter -t 14346 -n dig kubernetes.default.svc.cluster.local @10.32.0.10

Este comando dig procura o nome de domínio completo do Serviço de **service-name.namespace.svc.cluster.local** e especifica o IP do serviço DNS do cluster (`@10.32.0.10`).

## Olhando para os Detalhes do IPVS

A partir do Kubernetes 1.11, o `kube-proxy` pode configurar o IPVS para lidar com a tradução de IPs de serviços virtuais para IPs de pods. Você pode listar a tabela de tradução com `ipvsadm`:

    ipvsadm -Ln

    Output
    IP Virtual Server version 1.2.1 (size=4096)
    Prot LocalAddress:Port Scheduler Flags
      -> RemoteAddress:Port Forward Weight ActiveConn InActConn
    TCP 100.64.0.1:443 rr
      -> 178.128.226.86:443 Masq 1 0 0
    TCP 100.64.0.10:53 rr
      -> 100.96.1.3:53 Masq 1 0 0
      -> 100.96.1.4:53 Masq 1 0 0
    UDP 100.64.0.10:53 rr
      -> 100.96.1.3:53 Masq 1 0 0
      -> 100.96.1.4:53 Masq 1 0 0

Para mostrar um único IP de serviço, utilize a opção `-t` e especifique o IP desejado:

    ipvsadm -Ln -t 100.64.0.10:53
    

    Output
    Prot LocalAddress:Port Scheduler Flags
      -> RemoteAddress:Port Forward Weight ActiveConn InActConn
    TCP 100.64.0.10:53 rr
      -> 100.96.1.3:53 Masq 1 0 0
      -> 100.96.1.4:53 Masq 1 0 0
    

## Conclusão

Neste artigo, analisamos alguns comandos e técnicas para explorar e inspecionar os detalhes da rede do cluster do Kubernetes. Para mais informações sobre Kubernetes, dê uma olhada na nossa tag [de tutoriais de Kubernetes](https://www.digitalocean.com/community/tags/kubernetes?type=tutorials) e na [documentação oficial do Kubernetes](https://kubernetes.io/docs/home/).
