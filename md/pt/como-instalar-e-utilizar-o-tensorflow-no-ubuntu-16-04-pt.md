---
author: Jeremy Morris
date: 2018-07-26
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-e-utilizar-o-tensorflow-no-ubuntu-16-04-pt
---

# Como Instalar e Utilizar o TensorFlow no Ubuntu 16.04

### Introdução

O [TensorFlow](https://www.tensorflow.org/) é um software open-source para machine learning criado pelo Google para treinar redes neurais. As redes neurais do TensorFlow são expressas na forma de [grafos de fluxo de dados com estado](https://www.tensorflow.org/programmers_guide/graphs). Cada nó no gráfico representa a operação realizada por redes neurais em matrizes multidimensionais. Estas matrizes multidimensionais são comumente conhecidas como “tensors” ou “tensores”, daí o nome TensorFlow.

O TensorFlow é um sistema de software de [deep learning](https://en.wikipedia.org/wiki/Deep_learning) ou aprendizagem profunda. O TensorFlow funciona bem para a recuperação de informações, conforme demonstrado pelo Google na forma como eles fazem a classificação em seu sistema de inteligência artificial de machine-learning, [RankBrain](https://en.wikipedia.org/wiki/RankBrain). O TensorFlow pode realizar reconhecimento de imagem, como mostrado no [Inception](https://arxiv.org/abs/1409.4842) do Google, bem como reconhecimento da linguagem humana em áudio. Ele também é útil na solução de outros problemas não específicos para machine-learning, como as [equações diferenciais parciais](https://www.tensorflow.org/tutorials/pdes).

A arquitetura do TensorFlow permite a implantação em várias CPUs ou GPUs em um desktop, servidor ou dispositivo móvel. Existem também extensões para integração com [CUDA](https://developer.nvidia.com/cuda-zone), uma plataforma de computação paralela da Nvidia. Isso dá aos usuários que estão implantando em uma GPU, acesso direto ao conjunto de instruções virtuais e outros elementos da GPU que são necessários para tarefas computacionais paralelas.

Neste tutorial, você vai instalar a versão “Suporte apenas à CPU” do TensorFlow. Essa instalação é ideal para pessoas que desejam instalar e usar o TensorFlow, mas que não possuem uma placa de vídeo Nvidia ou não precisam executar aplicações de desempenho crítico.

Você pode instalar o TensorFlow de diversas formas. cada método tem um caso de uso e um ambiente de desenvolvimento diferentes:

- **Python e Virtualenv** : Nessa abordagem, você instala o TensorFlow e todos os pacotes necessários para utilizar o TensorFow em um ambiente virtual Python. Isso isola o seu ambiente TensorFlow de outros programas em Python na mesma máquina.
- **pip nativo** : Nesse método, você instala o TensorFlow globalmente em seu sistema. Isso é recomendado para pessoas que querem disponibilizar o TensorFlow para todos em um sistema multiusuário. Esse método de instalação não separa o TensorFlow em um ambiente isolado e pode interferir em outras instalações ou bibliotecas do Python.
- **Docker** : O Docker é um ambiente de execução de container e isola completamente o seu conteúdo dos pacotes preexistentes em seu sistema. Nesse método, você usa um container Docker que contém o TensorFlow e todas as suas dependências. Esse método é ideal para incorporar o TensorFlow a uma arquitetura de aplicações maior que já esteja usando o Docker. No entanto, o tamanho da imagem do Docker será bem grande.

Neste tutorial, você vai instalar o TensorFlow em um ambiente virtual Python com o `virtualenv`. Essa abordagem, isola a instalação do TensorFlow e coloca as coisas em funcionamento rapidamente. Depois de concluir a instalação, você fará a validação executando um pequeno programa do TensorFlow e, em seguida, usando o TensorFlow para executar o reconhecimento de imagem.

## Pré-requisitos

Antes de começar esse tutorial, você precisará do seguinte:

- Um servidor Ubuntu 16.04 com pelo menos 1GB de RAM configurado seguindo o [guia Configuração Inicial de servidor com Ubuntu 16.04](configuracao-inicial-de-servidor-com-ubuntu-16-04-pt), incluindo um usuário com privilégios sudo que não seja root e um firewall. Você precisará de pelo menos 1 GB de RAM para executar com sucesso o último exemplo neste tutorial. 

- Python 3.3 ou superior e o `virtualenv` instalado. Siga [How to Install Python 3 on Ubuntu 16.04](how-to-install-python-3-and-set-up-a-local-programming-environment-on-ubuntu-16-04) para configurar o Python e o `virtualenv`. 

- Git instalado, o que você pode fazer seguindo [How To Install Git on Ubuntu 16.04](how-to-install-git-on-ubuntu-16-04). Você usará isso para baixar um repositório de exemplos.

## Passo 1 — Instalando o TensorFlow

Nesse passo vamos criar um ambiente virtual e instalar o TensorFlow.

Primeiro, crie um diretório de projeto chamado `tf-demo`:

    mkdir ~/tf-demo

Navegue até o seu diretório `tf-demo` recém criado:

    cd ~/tf-demo

Em seguida crie um novo ambiente virtual chamado `tensorflow-dev`. Execute o seguinte comando para criar o ambiente:

    python3 -m venv tensorflow-dev

Isso cria um novo diretório `tensorflow-dev` que conterá todos os pacotes que você instalar enquanto esse ambiente estiver ativado. Ele também inclui o `pip` e uma versão standalone do Python.

Agora, ative seu ambiente virtual:

    source tensorflow-dev/bin/activate

Uma vez ativado, você verá algo semelhante a isso no seu terminal:

    (tensorflow-dev)username@hostname:~/tf-demo $

Agora, você pode instalar o TensorFlow em seu ambiente virtual.

Execute o seguinte comando para instalar e atualizar para a versão mais nova do TensorFlow disponível no [PyPi](https://pypi.python.org/pypi):

    pip3 install --upgrade tensorflow

O TensorFlow irá instalar:

    OutputCollecting tensorflow
      Downloading tensorflow-1.4.0-cp36-cp36m-macosx_10_11_x86_64.whl (39.3MB)
        100% |████████████████████████████████| 39.3MB 35kB/s
    
    ...
    
    Successfully installed bleach-1.5.0 enum34-1.1.6 html5lib-0.9999999 markdown-2.6.9 numpy-1.13.3 protobuf-3.5.0.post1 setuptools-38.2.3 six-1.11.0 tensorflow-1.4.0 tensorflow-tensorboard-0.4.0rc3 werkzeug-0.12.2 wheel-0.30.0
    

Se você quiser desativar seu ambiente virtual a qualquer momento, o comando é:

    deactivate

Para reativar seu abiente mais tarde, navegue até o diretório do seu projeto e execute source tensorflow-dev/bin/activate.

Agora que você instalou o TensorFlow, vamos nos certificar de que a instalação dele está funcionando.

## Passo 2 — Validando a Instalação

Para validar a instalação do TensorFlow, vamos executar um programa simples nele como um usuário não-root. Vamos utilizar o clássico exemplo de iniciante “Hello, world!” como uma forma de validação. Em vez de criar um arquivo Python, criaremos esse programa usando o [Console Interativo do Python](how-to-work-with-the-python-interactive-console).

Para escrever o programa, inicie o seu interpretador Python:

    python

Você verá o seguinte prompt aparecer em seu terminal:

    >>>

Esse é o prompt para o interpretador Python, e ele indica que está pronto para que você comece a digitar algumas declarações Python.

Primeiro, digite essa linha para importar o pacote do TensorFlow e torná-lo disponível como a variável local `tf`. Pressione `ENTER` depois de digitar a linha de código:

    import tensorflow as tf

Em seguida, adicione esta linha de código para definir a mensagem “Hello, world!”:

    hello = tf.constant("Hello, world!")

Depois, crie uma nova sessão do TensorFlow e a atribua à variável `sess`:

    sess = tf.Session()

**Nota** : Dependendo do seu ambiente, você poderá ver esta saída:

    Output2017-06-18 16:22:45.956946: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use SSE4.1 instructions, but these are available on your machine and could speed up CPU computations.
    2017-06-18 16:22:45.957158: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use SSE4.2 instructions, but these are available on your machine and could speed up CPU computations.
    2017-06-18 16:22:45.957282: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use AVX instructions, but these are available on your machine and could speed up CPU computations.
    2017-06-18 16:22:45.957404: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use AVX2 instructions, but these are available on your machine and could speed up CPU computations.
    2017-06-18 16:22:45.957527: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use FMA instructions, but these are available on your machine and could speed up CPU computations.
    

Isso lhe diz que você tem um [instruction set](https://en.wikipedia.org/wiki/Instruction_set_architecture) que tem o potencial de ser otimizado para um desempenho melhor com o TensorFlow. Se você vir isso, poderá ignorá-lo com segurança e continuar.

Por fim, insira essa linha de código para imprimir o resultado da execução da sessão `hello` do TensorFlow que você construiu em suas linhas de código anteriores:

    print(sess.run(hello))

Você verá esta saída em seu console:

    OutputHello, world!
    

Isso indica que tudo está funcionando e que você pode começar a utilizar o TensorFlow para fazer algo mais interessante.

Saia do console interativo do Python pressionando `CTRL+D`.

Agora vamos usar a API de reconhecimento de imagem do TensorFlow para nos familiarizarmos mais com o TensorFlow.

## Passo 3 — Usando o TensorFlow para Reconhecimento de Imagem

Agora que o TensorFlow está instalado e que você o validou através da execução de um programa simples, vamos dar uma olhada nos recursos de reconhecimento de imagem do TensorFlow.

Para classificar uma imagem, você precisa treinar um modelo. Depois você precisa escrever algum código para usar o modelo. Para aprender mais sobre esses conceitos dê uma olhada em [An Introduction to Machine Learning](an-introduction-to-machine-learning).

O TensorFlow fornece um [repositório de modelos e exemplos](https://github.com/tensorflow/models), incluindo código e um modelo treinado para classificar imagens.

Utilize o Git para clonar o repositório de modelos do TensorFlow a partir do GitHub dentro do seu diretório de projeto:

    git clone https://github.com/tensorflow/models.git

Você verá a seguinte saída enquanto o Git baixa o repositório em uma nova pasta chamada `models`:

    OutputCloning into 'models'...
    remote: Counting objects: 8785, done.
    remote: Total 8785 (delta 0), reused 0 (delta 0), pack-reused 8785
    Receiving objects: 100% (8785/8785), 203.16 MiB | 24.16 MiB/s, done.
    Resolving deltas: 100% (4942/4942), done.
    Checking connectivity... done.
    

Vá para o diretório `models/tutorials/image/imagenet`:

    cd models/tutorials/image/imagenet

Este diretório contém o arquivo `classify_image.py` que usa o TensorFlow para reconhecer imagens. Este programa faz o download de um modelo treinado de `tensorflow.org` em sua primeira execução. O download desse modelo requer que você tenha 200 MB de espaço livre disponível no disco.

Neste exemplo, vamos classificar uma [imagem pré-fabricada de um Panda](https://www.tensorflow.org/images/cropped_panda.jpg). Execute este comando para rodar o programa classificador de imagens:

    python classify_image.py

Você verá uma saída semelhante a esta:

    Outputgiant panda, panda, panda bear, coon bear, Ailuropoda melanoleuca (score = 0.89107)
    indri, indris, Indri indri, Indri brevicaudatus (score = 0.00779)
    lesser panda, red panda, panda, bear cat, cat bear, Ailurus fulgens (score = 0.00296)
    custard apple (score = 0.00147)
    earthstar (score = 0.00117)
    

Você classificou sua primeira imagem usando os recursos de reconhecimento de imagem do TensorFlow.

Se você quiser usar outra imagem, faça isso adicionando o argumento `-- image_file` ao seu comando `python3 classify_image.py`. Para o argumento, você passaria o caminho absoluto do arquivo da imagem.

## Conclusão

Você instalou o TensorFlow em um ambiente virtual Python e validou o funcionamento do TensorFlow executando alguns exemplos. Agora você possui ferramentas que o possibilitam a exploração de tópicos adicionais, incluindo [Convolutional Neural Networks](https://en.wikipedia.org/wiki/Convolutional_neural_network) e [Word Embeddings](https://papers.nips.cc/paper/5021-distributed-representations-of-words-and-phrases-and-their-compositionality.pdf).

[O guia do programador](https://www.tensorflow.org/programmers_guide/) do TensorFlow é um ótimo recurso e referência para o desenvolvimento nesse software. Você pode explorar o [Kaggle](https://www.kaggle.com/), um ambiente competitivo para aplicação prática de conceitos de machine learning que o colocam contra outros entusiastas de machine learning, ciência de dados e estatística. Eles têm um excelente [wiki](https://www.kaggle.com/wiki/Home) onde você pode ver e compartilhar soluções, algumas das quais estão na vanguarda das técnicas estatísticas e de machine learning.
