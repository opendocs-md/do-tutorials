---
author: ElliotForbes
date: 2019-07-22
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-fazer-o-deploy-de-uma-aplicacao-go-resiliente-no-kubernetes-da-digitalocean-pt
---

# Como Fazer o Deploy de uma Aplicação Go Resiliente no Kubernetes da DigitalOcean

_O autor escolheu o [Girls Who Code](https://www.brightfunds.org/organizations/girls-who-code) para receber uma doação como parte do programa [Write for DOnations](https://do.co/w4do-cta)._

### Introdução

O [Docker](https://www.docker.com/) é uma ferramenta de [containerização](https://en.wikipedia.org/wiki/OS-level_virtualisation) utilizada para fornecer às aplicações um sistema de arquivos que armazena tudo o que eles precisam para executar, garantindo que o software tenha um ambiente de runtime consistente e se comporte da mesma maneira, independentemente de onde esteja implantado ou _deployado_. O [Kubernetes](https://kubernetes.io/) é uma plataforma em nuvem para automatizar o deployment, a escalabilidade e o gerenciamento de aplicações containerizadas.

Ao aproveitar o Docker, você pode fazer o deploy de uma aplicação em qualquer sistema que ofereça suporte ao Docker com a confiança de que ele sempre funcionará conforme o esperado. O Kubernetes, por sua vez, permite que você faça o deploy de sua aplicação em vários nodes em um cluster. Além disso, ele lida com as principais tarefas, como lançar novos containers em caso de queda de qualquer um dos seus containers. Juntas, essas ferramentas simplificam o processo de deployment de uma aplicação, permitindo que você se concentre no desenvolvimento.

Neste tutorial, você vai criar uma aplicação de exemplo escrita em [Go](https://golang.org/) e a colocará em funcionamento localmente em sua máquina de desenvolvimento. Em seguida, você irá containerizar a aplicação com o Docker, fazer o deploy em um cluster Kubernetes e vai criar um balanceador de carga que servirá como ponto de entrada voltado ao público para a sua aplicação.

## Pré-requisitos

Antes de começar este tutorial, você precisará do seguinte:

- Um servidor de desenvolvimento ou máquina local a partir da qual você fará o deploy da aplicação. Embora as instruções deste guia funcionem em grande parte para a maioria dos sistemas operacionais, este tutorial pressupõe que você tenha acesso a um sistema Ubuntu 18.04 configurado com um usuário não-root com privilégios sudo, conforme descrito em nosso tutorial [Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt).
- A ferramenta de linha de comando `docker` instalada em sua máquina de desenvolvimento. Para instalar isto, siga os **Passos 1 e 2** do nosso tutorial sobre [Como Instalar e Usar o Docker no Ubuntu 18.04](como-instalar-e-usar-o-docker-no-ubuntu-18-04-pt).
- A ferramenta de linha de comando `kubectl` instalada em sua máquina de desenvolvimento. Para instalá-la, siga [este guia da documentação oficial do Kubernetes](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux).
- Uma conta gratuita no Docker Hub para a qual você enviará sua imagem do Docker. Para configurar isso, visite o [website do Docker Hub](https://hub.docker.com/), clique no botão **Get Started** no canto superior direito da página e siga as instruções de registro.
- Um cluster Kubernetes. Você pode provisionar um [cluster Kubernetes na DigitalOcean](https://www.digitalocean.com/products/kubernetes/) seguindo nosso [Guia de início rápido do Kubernetes](https://www.digitalocean.com/docs/kubernetes/quickstart/). Você ainda pode concluir este tutorial se provisionar seu cluster em outro provedor de nuvem. Sempre que você adquirir seu cluster, certifique-se de definir um arquivo de configuração e garantir que você possa se conectar ao cluster a partir do seu servidor de desenvolvimento.

## Passo 1 — Criando uma Aplicação Web de Exemplo em Go

Nesta etapa, você criará uma aplicação de exemplo escrita em Go. Após containerizar este app com o Docker, ele servirá `My Awesome Go App` em resposta a solicitações para o endereço IP do seu servidor na porta `3000`.

Comece atualizando as listas de pacotes do seu servidor, se você não tiver feito isso recentemente:

    sudo apt update

Em seguida, instale o Go executando:

    sudo apt install golang

Depois, verifique se você está em seu diretório home e crie um novo diretório que vai conter todos os seus arquivos do projeto:

    cd && mkdir go-app

Em seguida, navegue até este novo diretório:

    cd go-app/

Use o `nano` ou seu editor de texto preferido para criar um arquivo chamado `main.go`, que conterá o código da sua aplicação Go:

    nano main.go

A primeira linha em qualquer arquivo-fonte do Go é sempre uma instrução `package` que define a qual pacote de código o arquivo pertence. Para arquivos executáveis como este, a declaração `package` deve apontar para o pacote `main`:

go-app/main.go

    package main

Depois disso, adicione uma instrução `import` onde você pode listar todas as bibliotecas que a aplicação precisará. Aqui, inclua `fmt`, que lida com entrada e saída de texto formatada, e `net/http`, que fornece implementações de cliente e servidor HTTP:

go-app/main.go

    package main
    
    import (
      "fmt"
      "net/http"
    )

Em seguida, defina uma função `homePage` que terá dois argumentos: `http.ResponseWriter` e um ponteiro para `http.Request`. Em Go, uma interface `ResponseWriter` é usada para construir uma resposta HTTP, enquanto `http.Request` é um objeto que representa uma solicitação de entrada. Assim, este bloco lê solicitações HTTP de entrada e, em seguida, constrói uma resposta:

go-app/main.go

    . . .
    
    import (
      "fmt"
      "net/http"
    )
    
    func homePage(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "My Awesome Go App")
    }

Depois disso, adicione uma função `setupRoutes` que mapeará as solicitações de entrada para as funções planejadas do handler HTTP. No corpo desta função `setupRoutes`, adicione um mapeamento da rota `/` para sua função `homePage` recém-definida. Isso diz à aplicação para imprimir a mensagem `My Awesome Go App` mesmo para solicitações feitas a endpoints desconhecidos:

go-app/main.go

    . . .
    
    func homePage(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "My Awesome Go App")
    }
    
    func setupRoutes() {
      http.HandleFunc("/", homePage)
    }

E finalmente, adicione a seguinte função `main`. Isso imprimirá uma string indicando que sua aplicação foi iniciada. Ela então chamará a função `setupRoutes` antes de começar a ouvir e servir sua aplicação Go na porta `3000`.

go-app/main.go

    . . .
    
    func setupRoutes() {
      http.HandleFunc("/", homePage)
    }
    
    func main() {
      fmt.Println("Go Web App Started on Port 3000")
      setupRoutes()
      http.ListenAndServe(":3000", nil)
    }

Após adicionar essas linhas, é assim que o arquivo final ficará:

go-app/main.go

    package main
    
    import (
      "fmt"
      "net/http"
    )
    
    func homePage(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "My Awesome Go App")
    }
    
    func setupRoutes() {
      http.HandleFunc("/", homePage)
    }
    
    func main() {
      fmt.Println("Go Web App Started on Port 3000")
      setupRoutes()
      http.ListenAndServe(":3000", nil)
    }

Salve e feche este arquivo. Se você criou este arquivo usando `nano`, faça-o pressionando `CTRL + X`, `Y`, depois `ENTER`.

Em seguida, execute a aplicação usando o seguinte comando `go run`. Isto irá compilar o código no seu arquivo `main.go` e irá executá-lo localmente em sua máquina de desenvolvimento:

    go run main.go

    OutputGo Web App Started on Port 3000

Esta saída confirma que a aplicação está funcionando conforme o esperado. Ela será executada indefinidamente, entretanto, feche-a pressionando `CTRL + C`.

Ao longo deste guia, você usará essa aplicação de exemplo para experimentar com o Docker e o Kubernetes. Para esse fim, continue lendo para saber como containerizar sua aplicação com o Docker.

## Passo 2 — Dockerizando sua Aplicação Go

Em seu estado atual, a aplicação Go que você acabou de criar está sendo executada apenas em seu servidor de desenvolvimento. Nesta etapa, você tornará essa nova aplicação portátil ao containerizá-la com o Docker. Isso permitirá que ela seja executada em qualquer máquina que ofereça suporte a containers Docker. Você irá criar uma imagem do Docker e a enviará para um repositório público central no Docker Hub. Dessa forma, seu cluster Kubernetes pode baixar a imagem de volta e fazer o deployment dela como um container dentro do cluster.

O primeiro passo para a containerização de sua aplicação é criar um script especial chamado de [_Dockerfile_](https://docs.docker.com/search/?q=dockerfile). Um Dockerfile geralmente contém uma lista de instruções e argumentos que são executados em ordem sequencial para executar automaticamente determinadas ações em uma imagem base ou criar uma nova.

**Nota:** Nesta etapa, você vai configurar um container Docker simples que criará e executará sua aplicação Go em um único estágio. Se, no futuro, você quiser reduzir o tamanho do container onde suas aplicações Go serão executadas em produção, talvez seja interessante dar uma olhada no [_mutli-stage builds_](https://docs.docker.com/develop/develop-images/multistage-build/) ou compilação em múltiplos estágios.

Crie um novo arquivo chamado `Dockerfile`:

    nano Dockerfile

Na parte superior do arquivo, especifique a imagem base necessária para a aplicação Go:

go-app/Dockerfile

    FROM golang:1.12.0-alpine3.9

Em seguida, crie um diretório `app` dentro do container que vai conter os arquivos-fonte da aplicação:

go-app/Dockerfile

    FROM golang:1.12.0-alpine3.9
    RUN mkdir /app

Abaixo disso, adicione a seguinte linha que copia tudo no diretório `raiz` dentro do diretório `app`:

go-app/Dockerfile

    FROM golang:1.12.0-alpine3.9
    RUN mkdir /app
    ADD . /app

Em seguida, adicione a seguinte linha que altera o diretório de trabalho para `app`, significando que todos os comandos a seguir neste Dockerfile serão executados a partir desse local:

go-app/Dockerfile

    FROM golang:1.12.0-alpine3.9
    RUN mkdir /app
    ADD . /app
    WORKDIR /app

Adicione uma linha instruindo o Docker a executar o comando `go build -o main`, que compila o executável binário da aplicação Go:

go-app/Dockerfile

    FROM golang:1.12.0-alpine3.9
    RUN mkdir /app
    ADD . /app
    WORKDIR /app
    RUN go build -o main .

Em seguida, adicione a linha final, que irá rodar o executável binário:

go-app/Dockerfile

    FROM golang:1.12.0-alpine3.9
    RUN mkdir /app
    ADD . /app
    WORKDIR /app
    RUN go build -o main .
    CMD ["/app/main"]

Salve e feche o arquivo depois de adicionar essas linhas.

Agora que você tem esse `Dockerfile` na raiz do seu projeto, você pode criar uma imagem Docker baseada nele usando o seguinte comando `docker build`. Este comando inclui a flag `-t` que, quando passado o valor `go-web-app`, nomeará a imagem Docker como `go-web-app` e irá marcar ou colocar uma _tag_ nela.

**Nota** : No Docker, as tags permitem que você transmita informações específicas para uma determinada imagem, como o seu número de versão. O comando a seguir não fornece uma tag específica, portanto, o Docker marcará a imagem com sua tag padrão: `latest`. Se você quiser atribuir uma tag personalizada a uma imagem, você adicionaria o nome da imagem com dois pontos e a tag de sua escolha, assim:

    docker build -t sammy/nome_da_imagem:nome_da_tag .

Marcar ou “taggear” uma imagem como essa pode lhe dar maior controle sobre suas imagens. Por exemplo, você poderia fazer o deploy de uma imagem marcada como `v1.1` em produção, mas fazer o deploy de outra marcada como `v1.2` em seu ambiente de pré-produção ou teste.

O argumento final que você vai passar é o caminho: `.`. Isso especifica que você deseja criar a imagem Docker a partir do conteúdo do diretório de trabalho atual. Além disso, certifique-se de atualizar `sammy` para o seu nome de usuário do Docker Hub:

    docker build -t sammy/go-web-app .

Este comando de compilação vai ler todas as linhas do seu `Dockerfile`, executá-las em ordem e armazenará em cache, permitindo que futuras compilações sejam executadas muito mais rapidamente:

    Output. . .
    Successfully built 521679ff78e5
    Successfully tagged go-web-app:latest

Quando este comando terminar a compilação, você poderá ver sua imagem quando executar o comando `docker images` da seguinte forma:

    docker images

    OutputREPOSITORY TAG IMAGE ID CREATED SIZE
    sammy/go-web-app latest 4ee6cf7a8ab4 3 seconds ago 355MB

Em seguida, use o seguinte comando para criar e iniciar um container com base na imagem que você acabou de criar. Este comando inclui a flag `-it`, que especifica que o container será executado no modo interativo. Ele também possui a flag `-p` que mapeia a porta na qual a aplicação Go está sendo executada em sua máquina de desenvolvimento — porta `3000` — para a porta `3000` em seu container Docker.

    docker run -it -p 3000:3000 sammy/go-web-app

    OutputGo Web App Started on Port 3000

Se não houver mais nada em execução nessa porta, você poderá ver a aplicação em ação abrindo um navegador e navegando até a seguinte URL:

    http://ip_do_seu_servidor:3000

**Nota:** Se você estiver seguindo este tutorial em sua máquina local em vez de um servidor, visite a aplicação acessando a seguinte URL:

    http://localhost:3000

![Your containerized Go App](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/resilient_go_kubernetes/resilient_screenshot_1.png)

Depois de verificar se a aplicação funciona como esperado no seu navegador, finalize-a pressionando `CTRL + C` no seu terminal.

Quando você faz o deploy de sua aplicação containerizada em seu cluster Kubernetes, você vai precisar conseguir extrair a imagem de um local centralizado. Para esse fim, você pode enviar sua imagem recém-criada para o repositório de imagens do Docker Hub.

Execute o seguinte comando para efetuar login no Docker Hub a partir do seu terminal:

    docker login

Isso solicitará seu nome de usuário e sua senha do Docker Hub. Depois de inseri-los corretamente, você verá `Login Succeeded` na saída do comando.

Após o login, envie sua nova imagem para o Docker Hub usando o comando `docker push`, assim:

    docker push sammy/go-web-app

Quando esse comando for concluído com êxito, você poderá abrir sua conta do Docker Hub e ver sua imagem do Docker lá.

Agora que você enviou sua imagem para um local central, está pronto para fazer o seu deployment em seu cluster do Kubernetes. Primeiro, porém, vamos tratar de um breve processo que tornará muito menos tedioso executar comandos `kubectl`.

## Passo 3 — Melhorando a Usabilidade para o `kubectl`

Nesse ponto, você criou uma aplicação Go funcional e fez a containerização dela com o Docker. No entanto, a aplicação ainda não está acessível publicamente. Para resolver isso, você fará o deploy de sua nova imagem Docker em seu cluster Kubernetes usando a ferramenta de linha de comando `kubectl`. Antes de fazer isso, vamos fazer uma pequena alteração no arquivo de configuração do Kubernetes que o ajudará a tornar a execução de comandos `kubectl` menos trabalhosa.

Por padrão, quando você executa comandos com a ferramenta de linha de comando `kubectl`, você deve especificar o caminho do arquivo de configuração do cluster usando a flag `--kubeconfig`. No entanto, se o seu arquivo de configuração é chamado `config` e está armazenado em um diretório chamado `~/.kube`, o `kubectl` saberá onde procurar pelo arquivo de configuração e poderá obtê-lo sem a flag `--kubeconfig` apontando para ele.

Para esse fim, se você ainda não tiver feito isso, crie um novo diretório chamado `~/.kube`:

    mkdir ~/.kube

Em seguida, mova o arquivo de configuração do cluster para este diretório e renomeie-o como `config` no processo:

    mv clusterconfig.yaml ~/.kube/config

Seguindo em frente, você não precisará especificar a localização do arquivo de configuração do seu cluster quando executar o `kubectl`, pois o comando poderá encontrá-lo agora que está no local padrão. Teste esse comportamento executando o seguinte comando `get nodes`:

    kubectl get nodes

Isso exibirá todos os _nodes_ que residem em seu cluster Kubernetes. No contexto do Kubernetes, um node é um servidor ou uma máquina de trabalho na qual pode-se fazer o deployment de um ou mais pods:

    OutputNAME STATUS ROLES AGE VERSION
    k8s-1-13-5-do-0-nyc1-1554148094743-1-7lfd Ready <none> 1m v1.13.5
    k8s-1-13-5-do-0-nyc1-1554148094743-1-7lfi Ready <none> 1m v1.13.5
    k8s-1-13-5-do-0-nyc1-1554148094743-1-7lfv Ready <none> 1m v1.13.5

Com isso, você está pronto para continuar e fazer o deploy da sua aplicação em seu cluster Kubernetes. Você fará isso criando dois objetos do Kubernetes: um que fará o deploy da aplicação em alguns pods no cluster e outro que criará um balanceador de carga, fornecendo um ponto de acesso à sua aplicação.

## Passo 4 — Criando um Deployment

[Recursos RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer) compõem todas as entidades persistentes dentro de um sistema Kubernetes, e neste contexto elas são comumente chamadas de _Kubernetes objects_. É útil pensar nos objetos do Kubernetes como as ordens de trabalho que você envia ao Kubernetes: você lista quais recursos você precisa e como eles devem funcionar, e então o Kubernetes trabalhará constantemente para garantir que eles existam em seu cluster.

Um tipo de objeto do Kubernetes, conhecido como _deployment_, é um conjunto de pods idênticos e indistinguíveis. No Kubernetes, um [_pod_](https://kubernetes.io/docs/concepts/workloads/pods/pod/) é um agrupamento de um ou mais containers que podem se comunicar pela mesma rede compartilhada e interagir com o mesmo armazenamento compartilhado. Um deployment executa mais de uma réplica da aplicação pai de cada vez e substitui automaticamente todas as instâncias que falham, garantindo que a aplicação esteja sempre disponível para atender às solicitações do usuário.

Nesta etapa, você criará um arquivo de descrição de objetos do Kubernetes, também conhecido como _manifest_, para um deployment. Esse manifest conterá todos os detalhes de configuração necessários para fazer o deploy da sua aplicação Go em seu cluster.

Comece criando um manifest de deployment no diretório raiz do seu projeto: `go-app/`. Para projetos pequenos como este, mantê-los no diretório raiz minimiza a complexidade. Para projetos maiores, no entanto, pode ser benéfico armazenar seus manifests em um subdiretório separado para manter tudo organizado.

Crie um novo arquivo chamado `deployment.yml`:

    nano deployment.yml

Diferentes versões da API do Kubernetes contêm diferentes definições de objetos, portanto, no topo deste arquivo você deve definir a `apiVersion` que você está usando para criar este objeto. Para o propósito deste tutorial, você estará usando o agrupamento `apps/v1`, pois ele contém muitas das principais definições de objeto do Kubernetes que você precisará para criar um deployment. Adicione um campo abaixo de `apiVersion`, descrevendo o `kind` ou tipo de objeto do Kubernetes que você está criando. Neste caso, você está criando um `Deployment`:

go-app/deployment.yml

    ---
    apiVersion: apps/v1
    kind: Deployment

Em seguida, defina o `metadata` para o seu deployment. Um campo `metadata` é necessário para todos os objetos do Kubernetes, pois contém informações como o `name` ou nome exclusivo do objeto. Este `name` é útil, pois permite distinguir diferentes deployments e identificá-los usando nomes inteligíveis:

go-app/deployment.yml

    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
        name: go-web-app

Em seguida, você construirá o bloco `spec` do seu `deployment.yml`. Um campo `spec` é um requisito para todos os objetos do Kubernetes, mas seu formato exato é diferente para cada tipo de objeto. No caso de um deployment, ele pode conter informações como o número de _réplicas_ que você deseja executar. No Kubernetes, uma réplica é o número de pods que você deseja executar em seu cluster. Aqui, defina o número de `replicas` para `5`:

go-app/deployment.yml

    . . .
    metadata:
        name: go-web-app
    spec:
      replicas: 5

Depois, crie um bloco `selector` aninhado sob o bloco `spec`. Isso servirá como um _seletor de label_ ou _seletor de etiquetas_ para seus pods. O Kubernetes usa seletores de label para definir como o deployment encontra os pods que ele deve gerenciar.

Dentro deste bloco `selector`, defina `matchLabels` e adicione a label `name`. Essencialmente, o campo `matchLabels` diz ao Kubernetes para quais pods o deployment se aplica. Neste exemplo, o deployment será aplicado a todos os pods com o nome `go-web-app`:

go-app/deployment.yml

    . . .
    spec:
      replicas: 5
      selector:
        matchLabels:
          name: go-web-app

Depois disso, adicione um bloco `template`. Cada deployment cria um conjunto de pods usando as labels especificadas em um bloco `template`. O primeiro subcampo deste bloco é o `metadata`, que contém as `labels` que serão aplicadas a todos os pods deste deployment. Essas labels são pares de chave/valor que são usados como atributos de identificação de objetos do Kubernetes. Quando você definir seu serviço mais tarde, você pode especificar que deseja que todos os pods com essa label `name` sejam agrupados sob esse serviço. Defina esta label `name` para `go-web-app`:

go-app/deployment.yml

    . . .
    spec:
      replicas: 5
      selector:
        matchLabels:
          name: go-web-app
      template:
        metadata:
          labels:
            name: go-web-app

A segunda parte deste bloco `template` é o bloco `spec`. Este é diferente do bloco `spec` que você adicionou anteriormente, já que este se aplica somente aos pods criados pelo bloco `template`, em vez de todo o deployment.

Dentro deste bloco `spec`, adicione um campo `containers` e mais uma vez defina um atributo `name`. Este campo `name` define o nome de qualquer container criado por este deployment específico. Abaixo disso, defina a imagem ou `image` que você deseja baixar e fazer o deploy. Certifique-se de alterar `sammy` para seu próprio nome de usuário do Docker Hub:

go-app/deployment.yml

    . . .
      template:
        metadata:
          labels:
            name: go-web-app
        spec:
          containers:
          - name: application
            image: sammy/go-web-app

Depois disso, adicione um campo `imagePullPolicy` definido como `IfNotPresent`, que direcionará o deployment para baixar uma imagem apenas se ainda não tiver feito isso antes. Então, por último, adicione um bloco `ports`. Lá, defina o `containerPort` que deve corresponder ao número da porta que sua aplicação Go está escutando. Neste caso, o número da porta é `3000`:

go-app/deployment.yml

    . . .
        spec:
          containers:
          - name: application
            image: sammy/go-web-app
            imagePullPolicy: IfNotPresent
            ports:
              - containerPort: 3000

A versão completa do seu arquivo `deployment.yml` ficará assim:

go-app/deployment.yml

    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: go-web-app
    spec:
      replicas: 5
      selector:
        matchLabels:
          name: go-web-app
      template:
        metadata:
          labels:
            name: go-web-app
        spec:
          containers:
          - name: application
            image: sammy/go-web-app
            imagePullPolicy: IfNotPresent
            ports:
              - containerPort: 3000

Salve e feche o arquivo.

Em seguida, aplique seu novo deployment com o seguinte comando:

    kubectl apply -f deployment.yml

**Nota:** Para mais informações sobre todas as configurações disponíveis para seus deployments, confira a documentação oficial do Kubernetes aqui: [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

Na próxima etapa, você criará outro tipo de objeto do Kubernetes que gerenciará como você vai acessar os pods existentes em seu novo deployment. Esse serviço criará um balanceador de carga que, então, vai expor um único endereço IP, e as solicitações para esse endereço IP serão distribuídas para as réplicas em seu deployment. Esse serviço também manipulará regras de encaminhamento de porta para que você possa acessar sua aplicação por HTTP.

## Passo 5 — Criando um Serviço

Agora que você tem um deployment bem sucedido do Kubernetes, está pronto para expor sua aplicação ao mundo externo. Para fazer isso, você precisará definir outro tipo de objeto do Kubernetes: um _service_. Este serviço irá expor a mesma porta em todos os nodes do cluster. Então, seus nodes encaminharão qualquer tráfego de entrada nessa porta para os pods que estiverem executando sua aplicação.

**Nota:** Para maior clareza, vamos definir esse objeto de serviço em um arquivo separado. No entanto, é possível agrupar vários manifests de recursos no mesmo arquivo YAML, contanto que estejam separados por `---`. Veja [esta página da documentação do Kubernetes](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#organizing-resource-configurations) para maiores detalhes.

Crie um novo arquivo chamado `service.yml`:

    nano service.yml

Inicie este arquivo novamente definindo os campos `apiVersion` e `kind` de maneira similar ao seu arquivo `deployment.yml`. Desta vez, aponte o campo `apiVersion` para `v1`, a API do Kubernetes comumente usada para serviços:

go-app/service.yml

    ---
    apiVersion: v1
    kind: Service

Em seguida, adicione o nome do seu serviço em um bloco `metadata` como você fez em `deployment.yml`. Pode ser qualquer coisa que você goste, mas para clareza, vamos chamar de `go-web-service`:

go-app/service.yml

    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: go-web-service

Em seguida, crie um bloco `spec`. Este bloco `spec` será diferente daquele incluído em seu deployment, e ele conterá o tipo ou `type` deste serviço, assim como a configuração de encaminhamento de porta e o `seletor`.

Adicione um campo definindo o `type` deste serviço e defina-o para `LoadBalancer`. Isso provisionará automaticamente um balanceador de carga que atuará como o principal ponto de entrada para sua aplicação.

**Atenção:** O método para criar um balanceador de carga descrito nesta etapa só funcionará para clusters Kubernetes provisionados por provedores de nuvem que também suportam balanceadores de carga externos. Além disso, esteja ciente de que provisionar um balanceador de carga de um provedor de nuvem incorrerá em custos adicionais. Se isto é uma preocupação para você, você pode querer olhar a exposição de um endereço IP externo usando um [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/).

go-app/service.yml

    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: go-web-service
    spec:
      type: LoadBalancer

Em seguida, adicione um bloco `ports` onde você definirá como deseja que seus apps sejam acessados. Aninhado dentro deste bloco, adicione os seguintes campos:

- `name`, apontando para `http`
- `port`, apontando para a porta `80`
- `targetPort`, apontando para a porta `3000`

Isto irá pegar solicitações HTTP de entrada na porta `80` e encaminhá-las para o `targetPort` de `3000`. Este `targetPort` é a mesma porta na qual sua aplicação Go está rodando:

go-app/service.yml

    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: go-web-service
    spec:
      type: LoadBalancer
      ports:
      - name: http
        port: 80
        targetPort: 3000

Por último, adicione um bloco `selector` como você fez no arquivo `deployments.yml`. Este bloco `selector` é importante, pois mapeia quaisquer pods _deployados_ chamados `go-web-app` para este serviço:

go-app/service.yml

    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: go-web-service
    spec:
      type: LoadBalancer
      ports:
      - name: http
        port: 80
        targetPort: 3000
      selector:
        name: go-web-app

Depois de adicionar essas linhas, salve e feche o arquivo. Depois disso, aplique este serviço ao seu cluster do Kubernetes novamente usando o comando `kubectl apply` assim:

    kubectl apply -f service.yml

Esse comando aplicará o novo serviço do Kubernetes, além de criar um balanceador de carga. Esse balanceador de carga servirá como o ponto de entrada voltado ao público para a sua aplicação em execução no cluster.

Para visualizar a aplicação, você precisará do endereço IP do novo balanceador de carga. Encontre-o executando o seguinte comando:

    kubectl get services

    OutputNAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
    go-web-service LoadBalancer 10.245.107.189 203.0.113.20 80:30533/TCP 10m
    kubernetes ClusterIP 10.245.0.1 <none> 443/TCP 3h4m

Você pode ter mais de um serviço em execução, mas encontre o que está com a label `go-web-service`. Encontre a coluna `EXTERNAL-IP` e copie o endereço IP associado ao `go-web-service`. Neste exemplo de saída, este endereço IP é `203.0.113.20`. Em seguida, cole o endereço IP na barra de URL do seu navegador para visualizar a aplicação em execução no seu cluster Kubernetes.

**Nota:** Quando o Kubernetes cria um balanceador de carga dessa maneira, ele faz isso de forma assíncrona. Consequentemente, a saída do comando `kubectl get services` pode mostrar o endereço `EXTERNAL-IP` do `LoadBalancer` restante em um estado `<pending>` por algum tempo após a execução do comando `kubectl apply`. Se for esse o caso, aguarde alguns minutos e tente executar novamente o comando para garantir que o balanceador de carga foi criado e está funcionando conforme esperado.

O balanceador de carga receberá a solicitação na porta `80` e a encaminhará para um dos pods em execução no seu cluster.

![Your working Go App!](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/resilient_go_kubernetes/resilient_screenshot_2.png)

Com isso, você criou um serviço Kubernetes acoplado a um balanceador de carga, oferecendo um ponto de entrada único e estável para a aplicação.

## Conclusão

Neste tutorial, você criou uma aplicação Go, containerizada com o Docker e, em seguida, fez o deploy dela em um cluster Kubernetes. Em seguida, você criou um balanceador de carga que fornece um ponto de entrada resiliente para essa aplicação, garantindo que ela permaneça altamente disponível, mesmo se um dos nodes do cluster falhar. Você pode usar este tutorial para fazer o deploy da sua própria aplicação Go em um cluster Kubernetes ou continuar aprendendo outros conceitos do Kubernetes e do Docker com a aplicação de exemplo que você criou no Passo 1.

Seguindo em frente, você pode [mapear o endereço IP do seu balanceador de carga para um nome de domínio que você controla](how-to-point-to-digitalocean-nameservers-from-common-domain-registrars) para que você possa acessar a aplicação por meio de um endereço web legível em vez do IP do balanceador de carga. Além disso, os seguintes tutoriais de Kubernetes podem ser de seu interesse:

- [How to Automate Deployments to DigitalOcean Kubernetes with CircleCI](how-to-automate-deployments-to-digitalocean-kubernetes-with-circleci)
- [White Paper: Running Cloud Native Applications on DigitalOcean Kubernetes](white-paper-running-cloud-native-applications-on-digitalocean-kubernetes)

Por fim, se você quiser saber mais sobre o Go, recomendamos que você confira nossa série sobre [Como Programar em Go](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-go).
