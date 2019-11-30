---
author: bsder
date: 2018-09-11
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-criar-um-cluster-kubernetes-1-11-usando-kubeadm-no-ubuntu-18-04-pt
---

# Como Criar um Cluster Kubernetes 1.11 Usando Kubeadm no Ubuntu 18.04

_O autor escolheu o [Free and Open Source Fund](https://www.brightfunds.org/funds/foss-nonprofits) para receber uma doação como parte do programa [Write for DOnations](https://do.co/w4do-cta)._

### Introdução

O [Kubernetes](https://kubernetes.io/) é um sistema de orquestração de container em escala. Inicialmente desenvolvido pelo Google baseado em suas experiências executando containers em produção. O Kubernetes é open source e desenvolvido ativamente por uma comunidade em todo o mundo.

O [Kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/) atomatiza a instalação e a configuração de componentes do Kubernetes tais como o servidor de API, o Controller Manager, e o Kube DNS. Contudo, ele não cria usuários ou lida com a instalação de dependências no nível do sistema operacional e sua configuração. Para essa tarefas preliminares, é possível utilizar uma ferramenta de gerência de configuração como o [Ansible](https://www.ansible.com/) ou o [SaltStack](https://saltstack.com/). A utilização dessas ferramentas torna a criação de clusters adicionais ou a recriação de clusters existentes muito mais simples e menos propensa a erros.

Neste guia, você vai configurar um cluster Kubernetes a partir do zero utilizando o Ansible e o Kubeadm, e a seguir fazer o deploy de uma aplicação Nginx containerizada nele.

## Objetivos

Seu cluster irá incluir os seguintes recursos físicos:

- **Um node master**

O node master (um _node_ no Kubernetes refere-se a um servidor) é responsável por gerenciar o estado do cluster. Ele roda o [Etcd](https://github.com/coreos/etcd), que armazena dados de cluster entre componentes que fazem o scheduling de cargas de trabalho para nodes worker ou nodes de trabalho.

- **Dois nodes worker**

Nodes worker são os servidores onde suas _cargas de trabalho_ (i.e. aplicações e serviços containerizados) irão executar. Um worker continuará a executar sua carga de trabalho uma vez que estejam atribuídos a ela, mesmo se o master for desativado quando o scheduling estiver concluído. A capacidade de um cluster pode ser aumentada adicionando workers.

Após a conclusão desse guia, você terá um cluster pronto para executar aplicações containerizadas, desde que os servidores no cluster tenham recursos suficientes de CPU e RAM para suas aplicações consumirem. Quase todas as aplicações Unix tradicionais, incluindo aplicações web, bancos de dados, daemons, e ferramentas de linha de comando podem ser containerizadas e feitas para rodar no cluster. O cluster em si consumirá cerca de 300-500MB de memória e 10% de CPU em cada node.

Uma vez que o cluster esteja configurado, você fará o deploy do servidor web [Nginx](https://nginx.org/en/) nele para assegurar que ele está executando as cargas de trabalho corretamente.

## Pré-requisitos

- Um par de chaves SSH em sua máquina Linux/macOS/BSD local. Se você não tiver usado chaves SSH antes, você pode aprender como configurá-las seguindo [esta explicação em como configurar chaves SSH em sua máquina local](ssh-essentials-working-with-ssh-servers-clients-and-keys#generating-and-working-with-ssh-keys). 

- Três servidores rodando Ubuntu 18.04 com pelo menos 1GB de RAM. Você deve ser capaz de fazer SSH em cada servidor como usuário root com o seu par de chaves SSH. 

- Ansible instalado em sua máquina local. Se você estiver executando Ubuntu 18.04 como seu SO, siga o a seção “Passo 1 - Instalando o Ansible” em [Como instalar e configurar o Ansible no Ubuntu 18.04](how-to-install-and-configure-ansible-on-ubuntu-18-04#step-1-%E2%80%94-installing-ansible) para instalar o Ansible. Para instruções de instalações em outras plataformas como o macOS ou CentOS, siga a [documentação oficial da instalação do Ansible](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-the-control-machine). 

- Familiaridade com o playbooks do Ansible. Para uma revisão, verifique [Configuration Management 101: Writing Ansible Playbooks](configuration-management-101-writing-ansible-playbooks). 

- Conhecimento de como lançar um container a partir de uma imagem Docker. Dê uma olhada no “Passo 5 — Executando um Container Docker” em [Como instalar e usar o Docker no Ubuntu 18.04](how-to-install-and-use-docker-on-ubuntu-18-04#step-5-%E2%80%94-running-a-docker-container) se precisar relembrar.

## Passo 1 — Configurando o Diretório da Área de Trabalho e o Arquivo de Inventário Ansible

Nessa seção, você vai criar um diretório em sua máquina local que irá servir como sua área de trabalho. Você configurará o Ansible localmente para que ele possa se comunicar e executar comandos em seus servidores remotos. Depois disso pronto, você irá criar um arquivo `hosts` contendo informações de inventário tais como os endereços IP de seus servidores e os grupos aos quais cada servidor pertence.

Dos seus três servidores, um será o master com um IP exibido como `master_ip`. Os outros dois servidores serão workers e terão os IPs `worker_1_ip` e `worker_2_ip`.

Crie um diretório chamado `~/kube-cluster` no diretório home de sua máquina local e faça um `cd` para dentro dele:

    mkdir ~/kube-cluster
    cd ~/kube-cluster

Esse diretório será sua área de trabalho para o restante desse tutorial e conterá todos os seus playbooks de Ansible. Ele também será o diretório no qual você irá executar todos os comandos locais.

Crie um arquivo chamado `~/kube-cluster/hosts` usando o `nano` ou o seu editor de textos favorito:

    nano ~/kube-cluster/hosts

Adicione o seguinte texto ao arquivo, que irá especificar informações sobre a estrutura lógica do cluster:

~/kube-cluster/hosts

    
    [masters]
    master ansible_host=master_ip ansible_user=root
    
    [workers]
    worker1 ansible_host=worker_1_ip ansible_user=root
    worker2 ansible_host=worker_2_ip ansible_user=root
    
    [all:vars]
    ansible_python_interpreter=/usr/bin/python3

Você deve se lembrar de que [_arquivos de inventário_](http://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) no Ansible são utilizados para especificar informações de servidor tais como endereços IP, usuários remotos, e agrupamentos de servidores para tratar como uma unidade única para a execução de comandos. O `~/kube-cluster/hosts` será o seu arquivo de inventário e você adicionou dois grupos Ansible a ele ( **masters** e **workers** ) especificando a estrutura lógica do seu cluster.

No grupo **masters** , existe uma entrada de servidor chamada “master” que lista o IP do node master (`master_ip`) e especifica que o Ansible deve executar comandos remotos como root.

De maneira similar, no grupo **workers** , existem duas entradas para os servidores workers (`worker_1_ip` e `worker_2_ip`) que também especificam o `ansible_user` como root.

A última linha do arquivo diz ao Ansible para utilizar os intepretadores Python dos servidores remotos para suas operações de gerenciamento.

Salve e feche o arquivo depois de ter adicionado o texto.

Tendo configurado o inventário do servidor com grupos, vamos passar a instalar dependências no nível do sistema operacional e a criar definições de configuração.

## Passo 2 — Criando um Usuário Não-Root em Todos os Servidores Remotos

Nesta seção você irá criar um usuário não-root com privilégios sudo em todos os servidores para que você possa fazer SSH manualmente neles como um usuário sem privilégios. Isso pode ser útil se, por exemplo, você gostaria de ver informações do sistema com comandos como `top/htop`, ver a lista de containers em execução, ou alterar arquivos de configuração de propriedade do root. Estas operações são rotineiramente executadas durante a manutenção de um cluster, e a utilização de um usuário que não seja root para tarefas desse tipo minimiza o risco de modificação ou exclusão de arquivos importantes ou a realização não intencional de operações perigosas.

Crie um arquivo chamado `~/kube-cluster/initial.yml` na área de trabalho:

    nano ~/kube-cluster/initial.yml

A seguir, adicione o seguinte play ao arquivo para criar um usuário não-root com privilégios sudo em todos os servidores. Um play no Ansible é uma coleção de passos a serem realizados que visam servidores e grupos específicos. O seguinte play irá criar um usuário sudo não-root:

~/kube-cluster/initial.yml

    
    - hosts: all
      become: yes
      tasks:
        - name: create the 'ubuntu' user
          user: name=ubuntu append=yes state=present createhome=yes shell=/bin/bash
    
        - name: allow 'ubuntu' to have passwordless sudo
          lineinfile:
            dest: /etc/sudoers
            line: 'ubuntu ALL=(ALL) NOPASSWD: ALL'
            validate: 'visudo -cf %s'
    
        - name: set up authorized keys for the ubuntu user
          authorized_key: user=ubuntu key="{{item}}"
          with_file:
            - ~/.ssh/id_rsa.pub

Aqui está um detalhamento do que este playbook faz:

- Cria um usuário não-root `ubuntu`.

- Configura o arquivo `sudoers` para permitir o usuário `ubuntu` executar comandos `sudo` sem uma solicitação de senha.

- Adiciona a chave pública em sua máquina local (normalmente `~/.ssh/id_rsa.pub`) para a lista de chaves autorizadas do usuário remoto `ubuntu`. Isto o permitirá fazer SSH para dentro de cada servidor como usuário `ubuntu`.

Salve e feche o arquivo depois que tiver adicionado o texto.

Em seguida, rode o playbook localmente executando:

    ansible-playbook -i hosts ~/kube-cluster/initial.yml

O comando será concluído dentro de dois a cinco minutos. Na conclusão, você verá uma saída semelhante à seguinte:

    OutputPLAY [all] ****
    
    TASK [Gathering Facts] ****
    ok: [master]
    ok: [worker1]
    ok: [worker2]
    
    TASK [create the 'ubuntu' user] ****
    changed: [master]
    changed: [worker1]
    changed: [worker2]
    
    TASK [allow 'ubuntu' user to have passwordless sudo] ****
    changed: [master]
    changed: [worker1]
    changed: [worker2]
    
    TASK [set up authorized keys for the ubuntu user] ****
    changed: [worker1] => (item=ssh-rsa AAAAB3...)
    changed: [worker2] => (item=ssh-rsa AAAAB3...)
    changed: [master] => (item=ssh-rsa AAAAB3...)
    
    PLAY RECAP ****
    master : ok=5 changed=4 unreachable=0 failed=0   
    worker1 : ok=5 changed=4 unreachable=0 failed=0   
    worker2 : ok=5 changed=4 unreachable=0 failed=0

Agora que a configuração preliminar está completa, você pode passar para a instalação de dependências específicas do Kubernetes.

## Step 3 — Instalando as Dependências do Kubernetes

Nesta seção, você irá instalar os pacotes no nível do sistema operacional necessários pelo Kubernetes com o gerenciador de pacotes do Ubuntu. Esses pacotes são:

- Docker - um runtime de container. Este é o componente que executa seus containers. Suporte a outros runtimes como o [rkt](https://coreos.com/rkt/) está em desenvolvimento ativo no Kubernetes. 

- `kubeadm` - uma ferramenta CLI que irá instalar e configurar os vários componentes de um cluster de uma maneira padrão.

- `kubelet` - um serviço/programa de sistema que roda em todos os nodes e lida com operações no nível do node.

- `kubectl` - uma ferramenta CLI usada para emitir comandos para o cluster através de seu servidor de API.

Crie um arquivo chamado `~/kube-cluster/kube-dependencies.yml` na área de trabalho:

    nano ~/kube-cluster/kube-dependencies.yml

Adicione os seguintes plays ao arquivo para instalar esses pacotes em seus servidores:

~/kube-cluster/kube-dependencies.yml

    
    - hosts: all
      become: yes
      tasks:
       - name: install Docker
         apt:
           name: docker.io
           state: present
           update_cache: true
    
       - name: install APT Transport HTTPS
         apt:
           name: apt-transport-https
           state: present
    
       - name: add Kubernetes apt-key
         apt_key:
           url: https://packages.cloud.google.com/apt/doc/apt-key.gpg
           state: present
    
       - name: add Kubernetes' APT repository
         apt_repository:
          repo: deb http://apt.kubernetes.io/ kubernetes-xenial main
          state: present
          filename: 'kubernetes'
    
       - name: install kubelet
         apt:
           name: kubelet
           state: present
           update_cache: true
    
       - name: install kubeadm
         apt:
           name: kubeadm
           state: present
    
    - hosts: master
      become: yes
      tasks:
       - name: install kubectl
         apt:
           name: kubectl
           state: present

O primeiro play no playbook faz o seguinte:

- Instala o Docker, o runtime de container.

- Instala o `apt-transport-https`, permitindo que você adicione fontes HTTPS externas à sua lista de fontes do APT.

- Adiciona a apt-key do repositório APT do Kubernetes para verificação de chave.

- Adiciona o repositório APT do Kubernetes à lista de fontes do APT dos seus servidores remotos.

- Instala `kubelet` e `kubeadm`.

O segundo play consiste de uma única tarefa que instala o `kubectl` no seu node master.

Salve e feche o arquivo quando você tiver terminado.

A seguir, rode o playbook executando localmente:

    ansible-playbook -i hosts ~/kube-cluster/kube-dependencies.yml

Na conclusão, você verá uma saída semelhante à seguinte:

    OutputPLAY [all] ****
    
    TASK [Gathering Facts] ****
    ok: [worker1]
    ok: [worker2]
    ok: [master]
    
    TASK [install Docker] ****
    changed: [master]
    changed: [worker1]
    changed: [worker2]
    
    TASK [install APT Transport HTTPS] *****
    ok: [master]
    ok: [worker1]
    changed: [worker2]
    
    TASK [add Kubernetes apt-key] *****
    changed: [master]
    changed: [worker1]
    changed: [worker2]
    
    TASK [add Kubernetes' APT repository] *****
    changed: [master]
    changed: [worker1]
    changed: [worker2]
    
    TASK [install kubelet] *****
    changed: [master]
    changed: [worker1]
    changed: [worker2]
    
    TASK [install kubeadm] *****
    changed: [master]
    changed: [worker1]
    changed: [worker2]
    
    PLAY [master] *****
    
    TASK [Gathering Facts] *****
    ok: [master]
    
    TASK [install kubectl] ******
    ok: [master]
    
    PLAY RECAP ****
    master : ok=9 changed=5 unreachable=0 failed=0   
    worker1 : ok=7 changed=5 unreachable=0 failed=0  
    worker2 : ok=7 changed=5 unreachable=0 failed=0

Após a execução, o Docker, o `kubeadm` e o `kubelet` estarão instalados em todos os seus servidores remotos. O `kubectl` não é um componente obrigatório e somente é necessário para a execução de comandos de cluster. A instalação dele somente no node master faz sentido nesse contexto, uma vez que você irá executar comandos `kubectl` somente a partir do master. Contudo, observe que os comandos `kubectl` podem ser executados a partir de quaisquer nodes worker ou a partir de qualquer máquina onde ele possa ser instalado e configurado para apontar para um cluster.

Todas as dependências de sistema agora estão instaladas. Vamos configurar o node master e inicializar o cluster.

## Passo 4 — Configurando o Node Master

Nesta seção, você irá configurar o node master. Antes da criação de quaisquer playbooks, contudo, vale a pena cobrir alguns conceitos como _Pods_ e _Plugins de Rede do Pod_, uma vez que seu cluster incluirá ambos.

Um pod é uma unidade atômica que executa um ou mais containers. Esses containers compartilham recursos tais como volumes de arquivo e interfaces de rede em comum. Os pods são a unidade básica de scheduling no Kubernetes: todos os containers em um pod têm a garantia de serem executados no mesmo node no qual foi feito o scheduling do pod.

Cada pod tem seu próprio endereço IP, e um pod em um node deve ser capaz de acessar um pod em outro node utilizando o IP do pod. Os containers em um único node podem se comunicar facilmente através de uma interface local. Contudo, a comunicação entre pods é mais complicada e requer um componente de rede separado que possa encaminhar o tráfego de maneira transparente de um pod em um node para um pod em outro node.

Essa funcionalidade é fornecida pelos plugins de rede para pods. Para este cluster vamos utilizar o [Flannel](https://github.com/coreos/flannel), uma opção estável e de bom desempenho.

Crie um playbook Ansible chamado `master.yml` em sua máquina local:

    nano ~/kube-cluster/master.yml

Adicione o seguinte play ao arquivo para inicializar o cluster e instalar o Flannel:

~/kube-cluster/master.yml

    
    - hosts: master
      become: yes
      tasks:
        - name: initialize the cluster
          shell: kubeadm init --pod-network-cidr=10.244.0.0/16 >> cluster_initialized.txt
          args:
            chdir: $HOME
            creates: cluster_initialized.txt
    
        - name: create .kube directory
          become: yes
          become_user: ubuntu
          file:
            path: $HOME/.kube
            state: directory
            mode: 0755
    
        - name: copy admin.conf to user's kube config
          copy:
            src: /etc/kubernetes/admin.conf
            dest: /home/ubuntu/.kube/config
            remote_src: yes
            owner: ubuntu
    
        - name: install Pod network
          become: yes
          become_user: ubuntu
          shell: kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml >> pod_network_setup.txt
          args:
            chdir: $HOME
            creates: pod_network_setup.txt

Aqui está um detalhamento deste play:

- A primeira tarefa inicializa o cluster executando `kubeadm init`. A passagem do argumento `--pod-network-cidr=10.244.0.0/16` especifica a sub-rede privada que os IPs do pod serão atribuídos. O Flannel utiliza a sub-rede acima por padrão; estamos dizendo ao `kubeadm` para utilizar a mesma sub-rede. 

- A segunda tarefa cria um diretório `.kube` em `/home/ubuntu`. Este diretório irá manter as informações de configuração tais como os arquivos de chaves do admin, que são requeridas para conectar no cluster, e o endereço da API do cluster.

- A terceira tarefa copia o arquivo `/etc/kubernetes/admin.conf` que foi gerado a partir do `kubeadm init` para o diretório home do seu usuário não-root. Isso irá permitir que você utilize o `kubectl` para acessar o cluster recém-criado.

- A última tarefa executa `kubectl apply` para instalar o `Flannel`. `kubectl apply -f descriptor.[yml|json]` é a sintaxe para dizer ao `kubectl` para criar os objetos descritos no arquivo `descriptor.[yml|json]`. O arquivo `kube-flannel.yml` contém as descrições dos objetos requeridos para a configuração do `Flannel` no cluster.

Salve e feche o arquivo quando você tiver terminado.

Rode o playbook localmente executando:

    ansible-playbook -i hosts ~/kube-cluster/master.yml

Na conclusão, você verá uma saída semelhante à seguinte:

    Output
    PLAY [master] ****
    
    TASK [Gathering Facts] ****
    ok: [master]
    
    TASK [initialize the cluster] ****
    changed: [master]
    
    TASK [create .kube directory] ****
    changed: [master]
    
    TASK [copy admin.conf to user's kube config] *****
    changed: [master]
    
    TASK [install Pod network] *****
    changed: [master]
    
    PLAY RECAP ****
    master : ok=5 changed=4 unreachable=0 failed=0

Para verificar o status do node master, faça SSH nele com o seguinte comando:

    ssh ubuntu@master_ip

Uma vez dentro do node master, execute:

    kubectl get nodes

Agora você verá a seguinte saída:

    OutputNAME STATUS ROLES AGE VERSION
    master Ready master 1d v1.11.1

A saída informa que o node `master` concluiu todas as tarefas de inicialização e está em um estado `Ready` do qual pode começar a aceitar nodes worker e executar tarefas enviadas ao Servidor de API. Agora você pode adicionar os workers a partir de sua máquina local.

## Passo 5 — Configurando os Nodes Worker

A adição de workers ao cluster envolve a execução de um único comando em cada um. Este comando inclui as informações necessárias sobre o cluster, tais como o endereço IP e a porta do Servidor de API do master, e um token seguro. Somentes os nodes que passam no token seguro estarão aptos a ingressar no cluster.

Navegue de volta para a sua área de trabalho e crie um playbook chamado `workers.yml`:

    nano ~/kube-cluster/workers.yml

Adicione o seguinte texto ao arquivo para adicionar os workers ao cluster:

~/kube-cluster/workers.yml

    
    - hosts: master
      become: yes
      gather_facts: false
      tasks:
        - name: get join command
          shell: kubeadm token create --print-join-command
          register: join_command_raw
    
        - name: set join command
          set_fact:
            join_command: "{{ join_command_raw.stdout_lines[0] }}"
    
    
    - hosts: workers
      become: yes
      tasks:
        - name: join cluster
          shell: "{{ hostvars['master'].join_command }} >> node_joined.txt"
          args:
            chdir: $HOME
            creates: node_joined.txt

Aqui está o que o playbook faz:

- O primeiro play obtém o comando de junção que precisa ser executado nos nodes workers. Este comando estará no seguinte formato: `kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>`. Assim que obtiver o comando real com os valores apropriados de **token** e **hash** , a tarefa define isso como um fact para que o próximo play possa acessar essa informação.

- O segundo play tem uma única tarefa que executa o comando de junção em todos os nodes worker. Na conclusão desta tarefa, os dois nodes worker farão parte do cluster.

Salve e feche o arquivo quando você tiver terminado.

Rode o playbook localmente executando:

    ansible-playbook -i hosts ~/kube-cluster/workers.yml

Na conclusão, você verá uma saída semelhante à seguinte:

    OutputPLAY [master] ****
    
    TASK [get join command] ****
    changed: [master]
    
    TASK [set join command] *****
    ok: [master]
    
    PLAY [workers] *****
    
    TASK [Gathering Facts] *****
    ok: [worker1]
    ok: [worker2]
    
    TASK [join cluster] *****
    changed: [worker1]
    changed: [worker2]
    
    PLAY RECAP *****
    master : ok=2 changed=1 unreachable=0 failed=0   
    worker1 : ok=2 changed=1 unreachable=0 failed=0  
    worker2 : ok=2 changed=1 unreachable=0 failed=0

Com a adição dos nodes worker, seu cluster está agora totalmente configurado e funcional, com os workers prontos para executar cargas de trabalho. Antes de fazer o scheduling de aplicações, vamos verificar se o cluster está funcionando conforme o esperado.

## Step 6 — Verificando o Cluster

Às vezes, um cluster pode falhar durante a configuração porque um node está inativo ou a conectividade de rede entre o master e o worker não está funcionando corretamente. Vamos verificar o cluster e garantir que os nodes estejam operando corretamente.

Você precisará verificar o estado atual do cluster a partir do node master para garantir que os nodes estejam prontos. Se você se desconectou do node master, pode voltar e fazer SSH com o seguinte comando:

    ssh ubuntu@master_ip

Em seguida, execute o seguinte comando para obter o status do cluster:

    kubectl get nodes

Você verá uma saída semelhante à seguinte:

    OutputNAME STATUS ROLES AGE VERSION
    master Ready master 1d v1.11.1
    worker1 Ready <none> 1d v1.11.1 
    worker2 Ready <none> 1d v1.11.1

Se todos os seus nodes têm o valor `Ready` para o `STATUS`, significa que eles são parte do cluster e estão prontos para executar cargas de trabalho.

Se, contudo, alguns dos nodes têm `NotReady` como o `STATUS`, isso pode significar que os nodes worker ainda não concluíram sua configuração. Aguarde cerca de cinco a dez minutos antes de voltar a executar `kubectl get nodes` e fazer a inspeção da nova saída. Se alguns nodes ainda têm `NotReady` como status, talvez seja necessário verificar e executar novamente os comandos nas etapas anteriores.

Agora que seu cluster foi verificado com sucesso, vamos fazer o scheduling de um exemplo de aplicativo Nginx no cluster.

## Step 7 — Executando Uma Aplicação no Cluster

Você pode fazer o deploy de qualquer aplicação containerizada no seu cluster. Para manter as coisas familiares, vamos fazer o deploy do Nginx utilizando _Deployments_ e _Services_ para ver como pode ser feito o deploy dessa aplicação no cluster. Você também pode usar os comandos abaixo para outros aplicativos em container, desde que você altere o nome da imagem do Docker e quaisquer flags relevantes (tais como `ports` e `volumes`).

Ainda no node master, execute o seguinte comando para criar um deployment chamado `nginx`:

    kubectl run nginx --image=nginx --port 80

Um deployment é um tipo de objeto do Kubernetes que garante que há sempre um número especificado de pods em execução com base em um modelo definido, mesmo se o pod falhar durante o tempo de vida do cluster. O deployment acima irá criar um pod com um container do registro do Docker [Nginx Docker Image](https://hub.docker.com/_/nginx/).

A seguir, execute o seguinte comando para criar um serviço chamado `nginx` que irá expor o app publicamente. Ele fará isso por meio de um _NodePort_, um esquema que tornará o pod acessível através de uma porta arbitrária aberta em cada node do cluster:

    kubectl expose deploy nginx --port 80 --target-port 80 --type NodePort

Services são outro tipo de objeto do Kubernetes que expõe serviços do cluster para os clientes, tanto internos quanto externos. Eles também são capazes de fazer balanceamento de solicitações para vários pods e são um componente integral no Kubernetes, interagindo frequentemente com outros componentes.

Execute o seguinte comando:

    kubectl get services

Isso produzirá uma saída semelhante à seguinte:

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    kubernetes ClusterIP 10.96.0.1 <none> 443/TCP 1d
    nginx NodePort 10.109.228.209 <none> 80:nginx_port/TCP 40m

A partir da terceira linha da saída acima, você pode obter a porta em que o Nginx está sendo executado. O Kubernetes atribuirá uma porta aleatória maior que `30000` automaticamente, enquanto garante que a porta já não esteja vinculada a outro serviço.

Para testar se tudo está funcionando, visite `http://worker_1_ip:nginx_port` ou `http://worker_2_ip:nginx_port` através de um navegador na sua máquina local. Você verá a familiar página de boas-vindas do Nginx.

Se você quiser remover o aplicativo Nginx, primeiro exclua o serviço `nginx` do node master:

    kubectl delete service nginx

Execute o seguinte para garantir que o serviço tenha sido excluído:

    kubectl get services

Você verá a seguinte saída:

    [secondary label Output]
    NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    kubernetes ClusterIP 10.96.0.1 <none> 443/TCP 1d

Para excluir o deployment:

    kubectl delete deployment nginx

Execute o seguinte para confirmar que isso funcionou:

    kubectl get deployments

    OutputNo resources found.

## Conclusão

Neste guia, você configurou com sucesso um cluster do Kubernetes no Ubuntu 18.04 usando Kubeadm e Ansible para automação.

Se você está se perguntando o que fazer com o cluster, agora que ele está configurado, um bom próximo passo seria sentir-se confortável para implantar suas próprias aplicações e serviços no cluster. Aqui está uma lista de links com mais informações que podem orientá-lo no processo:

- [Dockerizing applications](https://docs.docker.com/engine/examples/) - lista exemplos que detalham como containerizar aplicações usando o Docker.

- [Pod Overview](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) - descreve em detalhes como os Pods funcionam e seu relacionamento com outros objetos do Kubernetes. Os pods são onipresentes no Kubernetes, então compreendê-los facilitará seu trabalho.

- [Deployments Overview](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) - fornece uma visão geral dos deployments. É útil entender como os controladores, como os deployments, funcionam, pois eles são usados com frequência em aplicações stateless para escalonamento e na recuperação automatizada de aplicações não íntegras.

- [Services Overview](https://kubernetes.io/docs/concepts/services-networking/service/) - cobre os serviços ou services, outro objeto frequentemente usado em clusters do Kubernetes. Entender os tipos de serviços e as opções que eles têm é essencial para executar aplicações stateless e stateful.

Outros conceitos importantes que você pode analisar são [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/), [Ingresses](https://kubernetes.io/docs/concepts/services-networking/ingress/) e [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/), os quais são úteis ao realizar o deploy de aplicações em produção.

O Kubernetes tem muitas funcionalidades e recursos a oferecer. [A Documentação Oficial do Kubernetes](https://kubernetes.io/docs/) é o melhor lugar para aprender sobre conceitos, encontrar guias específicos de tarefas e procurar referências de API para vários objetos.

_Por bsder_
