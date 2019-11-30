---
author: Lisa Tagliaferri, Jeremy Morris
date: 2019-05-16
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-instalar-e-utilizar-o-tensorflow-no-ubuntu-18-04-pt
---

# Como Instalar e Utilizar o TensorFlow no Ubuntu 18.04

### Introdução

O [TensorFlow](https://www.tensorflow.org/) é um software open-source de aprendizado de máquina ou machine learning usado para treinar redes neurais. As redes neurais do TensorFlow são expressas sob a forma de [gráficos de fluxo de dados stateful](https://www.tensorflow.org/programmers_guide/graphs). Cada nó no gráfico representa as operações realizadas por redes neurais em matrizes multidimensionais. Essas matrizes multidimensionais são comumente conhecidas como “tensores”, daí o nome TensorFlow.

O TensorFlow é um sistema de software de [deep learning](https://en.wikipedia.org/wiki/Deep_learning). Ele funciona bem para a recuperação de informações, conforme demonstrado pelo Google na forma como eles pesquisam o ranking em seu sistema de inteligência artificial de machine learning, [RankBrain](https://en.wikipedia.org/wiki/RankBrain). O TensorFlow pode realizar reconhecimento de imagem, conforme mostrado no [Inception](https://arxiv.org/abs/1409.4842) do Google, bem como reconhecimento de áudio em linguagem humana. Também é útil na resolução de outros problemas não específicos de machine learning, como [equações diferenciais parciais](https://www.tensorflow.org/tutorials/pdes).

A arquitetura do TensorFlow permite o deployment em várias CPUs ou GPUs em um desktop, servidor ou dispositivo móvel. Existem também extensões para integração com [CUDA](https://developer.nvidia.com/cuda-zone), uma plataforma de computação paralela da Nvidia. Isso fornece aos usuários que estão fazendo deploy em uma GPU acesso direto ao conjunto de instruções virtuais e outros elementos da GPU que são necessários para tarefas computacionais paralelas.

Neste tutorial, vamos instalar a versão “CPU support only” do TensorFlow. Essa instalação é ideal para pessoas que querem instalar e usar o TensorFlow, mas que não têm uma placa de vídeo Nvidia ou não precisam executar aplicações críticas em termos de desempenho.

Você pode instalar o TensorFlow de várias maneiras. Cada método tem um caso de uso e um ambiente de desenvolvimento diferentes:

- **Python e Virtualenv** : Nesta abordagem, você instala o TensorFlow e todos os pacotes necessários para utilizá-lo em um ambiente virtual do Python. Isso isola seu ambiente do TensorFlow de outros programas do Python na mesma máquina.
- **Native pip** : Neste método, você instala o TensorFlow em seu sistema de maneira global. Isso é recomendado para pessoas que querem disponibilizar o TensorFlow para todos em um sistema multiusuário. Esse método de instalação não isola o TensorFlow em um ambiente de contenção e pode interferir em outras instalações ou bibliotecas do Python.
- **Docker** : O Docker é um ambiente runtime de container e isola completamente seu conteúdo dos pacotes preexistentes em seu sistema. Nesse método, você usa um container do Docker que contém o TensorFlow e todas as suas dependências. Esse método é ideal para incorporar o TensorFlow a uma arquitetura de aplicações maior que já usa o Docker. No entanto, o tamanho da imagem do Docker será bem grande.

Neste tutorial, você instalará o TensorFlow em um ambiente virtual do Python com `virtualenv`. Essa abordagem isola a instalação do TensorFlow e coloca tudo em funcionamento rapidamente. Depois de concluir a instalação, você fará a sua validação executando um pequeno programa do TensorFlow e, em seguida, utilizará o TensorFlow para realizar o reconhecimento de imagem.

## Pré-requisitos

Antes de começar este tutorial, você precisará do seguinte:

- Um servidor Ubuntu 18.04 com pelo menos 1GB de RAM configurado seguindo o guia de [Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt), incluindo um usuário sudo não-root e um firewall. Você precisará de pelo menos 1 GB de RAM para executar com sucesso o último exemplo deste tutorial.
- Python 3.3 ou superior e `virtualenv` instalado. Siga o guia [How To Install Python 3 on Ubuntu 18.04](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-18-04-server) para configurar o Python e o `virtualenv`.
- Git instalado, que você pode fazer seguindo [How To Install Git on Ubuntu 18.04](how-to-install-git-on-ubuntu-18-04). Você usará isso para baixar um repositório de exemplos.

## Passo 1 — Instalando o TensorFlow

Nesta etapa, vamos criar um ambiente virtual e instalar o TensorFlow.

Primeiro, crie um diretório de projeto. Vamos chamá-lo de `tf-demo` para fins de demonstração, mas escolha um nome de diretório que seja significativo para você:

    mkdir ~/tf-demo

Navegue até o seu diretório `tf-demo` recém-criado:

    cd ~/tf-demo

Em seguida, crie um novo ambiente virtual chamado `tensorflow-dev`, por exemplo. Execute o seguinte comando para criar o ambiente:

    python3 -m venv tensorflow-dev

Isto cria um novo diretório `tensorflow-dev` que conterá todos os pacotes que você instalar enquanto este ambiente estiver ativado. Também inclui o `pip` e uma versão independente do Python.

Agora ative seu ambiente virtual:

    source tensorflow-dev/bin/activate

Uma vez ativado, você verá algo semelhante a isso no seu terminal:

    (tensorflow-dev)nome_de_usuário@hostname:~/tf-demo $

Agora você pode instalar o TensorFlow em seu ambiente virtual.

Execute o seguinte comando para instalar e atualizar para a versão mais recente do TensorFlow disponível em [PyPi](https://pypi.python.org/pypi):

    pip install --upgrade tensorflow

O TensorFlow será instalado, e você deverá obter uma saída que indique que a instalação, juntamente com quaisquer pacotes dependentes, foi bem-sucedida.

    Output...
    Successfully installed absl-py-0.7.1 astor-0.7.1 gast-0.2.2 grpcio-1.19.0 h5py-2.9.0 keras-applications-1.0.7 keras-preprocessing-1.0.9 markdown-3.0.1 mock-2.0.0 numpy-1.16.2 pbr-5.1.3 protobuf-3.7.0 setuptools-40.8.0 tensorboard-1.13.1 tensorflow-1.13.1 tensorflow-estimator-1.13.0 termcolor-1.1.0 werkzeug-0.15.0 wheel-0.33.1
    ...
    
    Successfully installed bleach-1.5.0 enum34-1.1.6 html5lib-0.9999999 markdown-2.6.9 numpy-1.13.3 protobuf-3.5.0.post1 setuptools-38.2.3 six-1.11.0 tensorflow-1.4.0 tensorflow-tensorboard-0.4.0rc3 werkzeug-0.12.2 wheel-0.30.0

Você pode desativar seu ambiente virtual a qualquer momento usando o seguinte comando:

    deactivate

Para reativar o ambiente posteriormente, navegue até o diretório do projeto e execute `source tensorflow-dev/bin/activate`.

Agora que você instalou o TensorFlow, vamos garantir que a instalação esteja funcionando.

## Passo 2 — Validando a Instalação

Para validar a instalação do TensorFlow, vamos executar um programa simples como um usuário não-root. Usaremos o exemplo canônico de iniciante de “Hello, world!” como uma forma de validação. Em vez de criar um arquivo em Python, criaremos esse programa usando o [console interativo do Python](how-to-work-with-the-python-interactive-console).

Para escrever o programa, inicie seu interpretador Python:

    python

Você verá o seguinte prompt aparecer no seu terminal:

    >>>

Este é o prompt do interpretador Python e indica que ele está pronto para que você comece a inserir algumas instruções do Python.

Primeiro, digite esta linha para importar o pacote TensorFlow e disponibilizá-lo como a variável local `tf`. Pressione `ENTER` depois de digitar a linha de código:

    import tensorflow as tf

Em seguida, adicione esta linha de código para definir a mensagem “Hello, world!”:

    hello = tf.constant("Hello, world!")

Em seguida, crie uma nova sessão do TensorFlow e atribua-a à variável `sess`:

    sess = tf.Session()

**Nota** : Dependendo do seu ambiente, você poderá ver esta saída:

    Output2019-03-20 16:22:45.956946: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use SSE4.1 instructions, but these are available on your machine and could speed up CPU computations.
    2019-03-20 16:22:45.957158: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use SSE4.2 instructions, but these are available on your machine and could speed up CPU computations.
    2019-03-20 16:22:45.957282: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use AVX instructions, but these are available on your machine and could speed up CPU computations.
    2019-03-20 16:22:45.957404: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use AVX2 instructions, but these are available on your machine and could speed up CPU computations.
    2019-03-20 16:22:45.957527: W tensorflow/core/platform/cpu_feature_guard.cc:45] The TensorFlow library wasn't compiled to use FMA instructions, but these are available on your machine and could speed up CPU computations.

Isso lhe diz que você tem um [conjunto de instruções](https://en.wikipedia.org/wiki/Instruction_set_architecture) que tem o potencial para ser otimizado para um melhor desempenho com o TensorFlow. Se você vir isso, poderá ignorar com segurança e continuar.

Por fim, insira essa linha de código para imprimir o resultado da execução da sessão `hello` do TensorFlow que você construiu nas suas linhas de código anteriores:

No Python 3, `sess.run()` irá retornar uma byte string, que será renderizada como `b'Hello, world!'` se você executar `print(sess.run(hello))` sozinho. Para retornar `Hello, world!` como uma string, vamos adicionar o método `decode()`.

    print(sess.run(hello).decode())

Você verá essa saída no seu console:

    OutputHello, world!

Isso indica que tudo está funcionando e que você pode começar a usar o TensorFlow.

Saia do console interativo do Python pressionando `CTRL+D` ou digitando `quit()`.

A seguir, vamos usar a API de reconhecimento de imagem do TensorFlow para nos familiarizarmos com o TensorFlow.

## Passo 3 — Usando o TensorFlow para Reconhecimento de Imagem

Agora que o TensorFlow está instalado e você o validou executando um programa simples, podemos dar uma olhada em seus recursos de reconhecimento de imagem.

Para classificar uma imagem, você precisa treinar um modelo. Então você precisa escrever algum código para usar o modelo. Para aprender mais sobre conceitos de machine learning, considere a leitura de “[An Introduction to Machine Learning](an-introduction-to-machine-learning).”

O TensorFlow fornece um [repositório de modelos e exemplos](https://github.com/tensorflow/models), incluindo código e um modelo treinado para classificar imagens.

Use o Git para clonar o repositório de modelos do TensorFlow do GitHub no diretório do seu projeto:

    git clone https://github.com/tensorflow/models.git

Você receberá a seguinte saída enquanto o Git clona o repositório em uma nova pasta chamada `models`:

    OutputCloning into 'models'...
    remote: Enumerating objects: 32, done.
    remote: Counting objects: 100% (32/32), done.
    remote: Compressing objects: 100% (26/26), done.
    remote: Total 24851 (delta 17), reused 12 (delta 6), pack-reused 24819
    Receiving objects: 100% (24851/24851), 507.78 MiB | 32.73 MiB/s, done.
    Resolving deltas: 100% (14629/14629), done.
    Checking out files: 100% (2858/2858), done.

Mude para o diretório `models/tutorials/image/imagenet`:

    cd models/tutorials/image/imagenet

Este diretório contém o arquivo `classify_image.py` que usa o TensorFlow para reconhecer imagens. Este programa faz o download de um modelo treinado a partir de `tensorflow.org` em sua primeira execução. O download desse modelo exige que você tenha 200 MB de espaço livre disponível no disco.

Neste exemplo, vamos classificar uma [imagem pré-fornecida de um Panda](https://www.tensorflow.org/images/cropped_panda.jpg). Execute este comando para executar o programa classificador de imagens:

    python classify_image.py

Você receberá uma saída semelhante a esta:

    Outputgiant panda, panda, panda bear, coon bear, Ailuropoda melanoleuca (score = 0.89107)
    indri, indris, Indri indri, Indri brevicaudatus (score = 0.00779)
    lesser panda, red panda, panda, bear cat, cat bear, Ailurus fulgens (score = 0.00296)
    custard apple (score = 0.00147)
    earthstar (score = 0.00117)

Você classificou sua primeira imagem usando os recursos de reconhecimento de imagem do TensorFlow.

Se você quiser usar outra imagem, você pode fazer isso adicionando o argumento `-- image_file` ao seu comando `python3 classify_image.py`. Para o argumento, você passaria o caminho absoluto do arquivo de imagem.

## Conclusão

Neste tutorial, você instalou o TensorFlow em um ambiente virtual do Python e validou o funcionamento do TensorFlow executando alguns exemplos. Agora você possui ferramentas que possibilitam a exploração de tópicos adicionais, incluindo [Redes Neurais Convolucionais](https://en.wikipedia.org/wiki/Convolutional_neural_network) e [Word Embeddings ou Vetores de Palavras](https://papers.nips.cc/paper/5021-distributed-representations-of-words-and-phrases-and-their-compositionality.pdf).

O [guia do programador](https://www.tensorflow.org/programmers_guide/) do TensorFlow fornece um recurso útil e uma referência para o desenvolvimento do TensorFlow. Você também pode explorar o [Kaggle](https://www.kaggle.com/), um ambiente competitivo para a aplicação prática de conceitos de machine learning que o colocam contra outros entusiastas de machine learning, ciência de dados e estatística. Eles têm um [wiki](https://www.kaggle.com/wiki/Home) robusto onde você pode explorar e compartilhar soluções, algumas das quais estão na vanguarda das técnicas estatísticas e de machine learning.
