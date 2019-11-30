---
author: Lisa Tagliaferri
date: 2019-01-25
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-configurar-o-jupyter-notebook-com-python-3-no-ubuntu-18-04-pt
---

# Como Configurar o Jupyter Notebook com Python 3 no Ubuntu 18.04

### Introdução

O [Jupyter Notebook](http://jupyter.org/) é uma aplicação web open-source que lhe permite criar e compartilhar código interativo, visualizações e muito mais. Esta ferramenta pode ser usada com várias linguagens de programação, incluindo Python, Julia, R, Haskell e Ruby. Ele é frequentemente usado para trabalhar com dados, modelagem estatística e aprendizado de máquina.

Este tutorial irá orientá-lo na configuração do Jupyter Notebook para ser executado em um servidor Ubuntu 18.04, além de ensinar como se conectar e usar o notebook. Jupyter Notebooks (ou simplesmente Notebooks) são documentos produzidos pelo aplicativo Jupyter Notebook, que contém tanto código de computador quanto elementos de rich text (parágrafos, equações, figuras, links, etc.) que ajudam a apresentar e compartilhar pesquisas reproduzíveis.

Ao final deste guia, você será capaz de executar código Python 3 usando o Jupyter Notebook em execução em um servidor remoto.

## Pré-requisitos

Para completar este guia, você deve ter uma nova instância de servidor Ubuntu 18.04, configurado com um firewall básico e um usuário não-root com privilégios sudo. Você pode aprender como configurar isso através de nosso [tutorial de configuração inicial de servidor](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt).

## Passo 1 — Configurar o Python

Para começar o processo, vamos instalar as dependências que precisamos para o nosso ambiente de programação Python a partir dos repositórios do Ubuntu. O Ubuntu 18.04 vem pré-instalado com o Python 3.6. Vamos utilizar o gerenciador de pacotes Python, pip, para instalar componentes adicionais um pouco mais tarde.

Primeiro precisamos atualizar o índice local de pacotes do `apt` e depois baixar e instalar os pacotes:

    sudo apt update

Em seguida, instale o pip e os arquivos de cabeçalho do Python, que são utilizados por algumas das dependências do Jupyter:

    sudo apt install python3-pip python3-dev

Podemos passar agora a configurar um ambiente virtual Python no qual instalaremos o Jupyter.

## Passo 2 — Criar um Ambiente Virtual do Python para o Jupyter

Agora que temos o Python 3, seus arquivos de cabeçalho e o pip pronto para usar, podemos criar um ambiente virtual Python para gerenciar nossos projetos. Vamos instalar o Jupyter neste ambiente virtual.

Para fazer isso, primeiro precisamos acessar o comando `virtualenv`, que podemos instalar com o pip.

Atualize o pip e instale o pacote digitando:

    sudo -H pip3 install --upgrade pip
    sudo -H pip3 install virtualenv

A flag `-H` garante que a política de segurança configure a variável de ambiente `home` para o diretório home do usuário de destino.

Com o `virtualenv` instalado, podemos começar a formar nosso ambiente. Crie e mova-se para um diretório onde possamos manter nossos arquivos de projeto. Chamaremos o nosso de `meu_projeto`, mas você pode usar um nome que seja significativo para você e no qual você esteja trabalhando.

    mkdir ~/meu_projeto
    cd ~/meu_projeto

Dentro do diretório do projeto, criaremos um ambiente virtual do Python. Para o propósito deste tutorial, vamos chamá-lo de `meu_projeto_env`, mas você pode chamá-lo de algo que seja relevante para o seu projeto.

    virtualenv meu_projeto_env

Isso irá criar um diretório chamado `meu_projeto_env` dentro do diretório `meu_projeto`. Dentro, ele instalará uma versão local do Python e uma versão local do pip. Podemos usar isso para instalar e configurar um ambiente Python isolado para o Jupyter.

Antes de instalarmos o Jupyter, precisamos ativar o ambiente virtual. Você pode fazer isso digitando:

    source meu_projeto_env/bin/activate

Seu prompt deve mudar para indicar que você agora está operando dentro de um ambiente virtual do Python. Vai parecer algo assim: (`meu_projeto_env)usuário@host:~/meu_projeto$`.

Agora você está pronto para instalar o Jupyter nesse ambiente virtual.

## Passo 3 — Instalar o Jupyter

Com o seu ambiente virtual ativo, instale o Jupyter com a instância local do pip.

**Nota:** Quando o ambiente virtual está ativado (quando o seu prompt tem (`meu_projeto_env`) precedendo-o), use`pip` em vez de `pip3`, mesmo se você estiver usando o Python 3. A cópia do ambiente virtual da ferramenta é sempre denominada `pip`, independentemente da versão do Python.

    pip install jupyter

Neste ponto, você instalou com sucesso todo o software necessário para executar o Jupyter. Agora podemos iniciar o servidor do Notebook.

## Passo 4 — Executar o Jupyter Notebook

Agora você tem tudo o que precisa para rodar o Jupyter Notebook! Para executá-lo, execute o seguinte comando:

    jupyter notebook

Um registro das atividades do Jupyter Notebook será impresso no terminal. Quando você executa o Jupyter Notebook, ele é executado em um número de porta específico. O primeiro Notebook que você executa geralmente usa a porta `8888`. Para verificar o número de porta específico em que o Jupyter Notebook está sendo executado, consulte a saída do comando usado para iniciá-lo:

    Output[I 21:23:21.198 NotebookApp] Writing notebook server cookie secret to /run/user/1001/jupyter/notebook_cookie_secret
    [I 21:23:21.361 NotebookApp] Serving notebooks from local directory: /home/sammy/meu_projeto
    [I 21:23:21.361 NotebookApp] The Jupyter Notebook is running at:
    [I 21:23:21.361 NotebookApp] http://localhost:8888/?token=1fefa6ab49a498a3f37c959404f7baf16b9a2eda3eaa6d72
    [I 21:23:21.361 NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
    [W 21:23:21.361 NotebookApp] No web browser found: could not locate runnable browser.
    [C 21:23:21.361 NotebookApp]
    
        Copy/paste this URL into your browser when you connect for the first time,
        to login with a token:
            http://localhost:8888/?token=1fefa6ab49a498a3f37c959404f7baf16b9a2eda3eaa6d72

Se você estiver executando o Jupyter Notebook em um computador local (não em um servidor), poderá navegar até a URL exibida para se conectar ao Jupyter Notebook. Se você estiver executando o Jupyter Notebook em um servidor, será necessário conectar-se ao servidor usando o tunelamento SSH, conforme descrito na próxima seção.

Neste ponto, você pode manter a conexão SSH aberta e manter o Jupyter Notebook em execução ou sair do aplicativo e executá-lo novamente assim que configurar o tunelamento SSH. Vamos escolher parar o processo do Jupyter Notebook. Vamos executá-lo novamente assim que tivermos o tunelamento SSH configurado. Para parar o processo do Jupyter Notebook, pressione `CTRL+C`, digite `Y` e, em seguida, `ENTER` para confirmar. A seguinte saída será mostrada:

    Output[C 21:28:28.512 NotebookApp] Shutdown confirmed
    [I 21:28:28.512 NotebookApp] Shutting down 0 kernels

Agora, vamos configurar um túnel SSH para que possamos acessar o Notebook.

## Passo 5 - Conectar ao Servidor Usando o Tunelamento SSH

Nesta seção, aprenderemos como conectar-se à interface web do Jupyter Notebook usando o tunelamento SSH. Como o Jupyter Notebook será executado em uma porta específica no servidor (tais como `:8888`, `:8889` etc.), o tunelamento SSH permite que você se conecte à porta do servidor com segurança.

As próximas duas subseções descrevem como criar um túnel SSH a partir de 1) um Mac ou Linux e 2) Windows. Por favor, consulte a subseção para o seu computador local.

### Tunelamento SSH com um Mac ou Linux

Se você estiver usando um Mac ou Linux, as etapas para criar um túnel SSH são semelhantes ao uso do SSH para efetuar login no seu servidor remoto, exceto que existem parâmetros adicionais no comando `ssh`. Esta subseção descreverá os parâmetros adicionais necessários no comando `ssh` para fazer um túnel com sucesso.

O tunelamento SSH pode ser feito executando o seguinte comando SSH em uma nova janela de terminal local:

    ssh -L 8888:localhost:8888 usuário_do_servidor@ip_do_seu_servidor

O comando `ssh` abre uma conexão SSH, mas `-L` especifica que a porta no host local (cliente) deve ser encaminhada para o host e porta no lado remoto (servidor). Isso significa que, o que quer que esteja rodando no segundo número de porta (ex: `8888`) no servidor aparecerá no primeiro número de porta (ex: `8888`) em seu computador local.

Opcionalmente, altere a porta `8888` para uma de sua escolha, para evitar o uso de uma porta que já esteja em uso por outro processo.

`usuário_do_servidor` é o seu usuário (ex: sammy) no servidor que você criou, e `ip_do_seu_servidor` é o endereço IP do seu servidor.

Por exemplo, para o usuário `sammy` e o endereço de servidor `203.0.113.0`, o comando seria:

    ssh -L 8888:localhost:8888 sammy@203.0.113.0

Se nenhum erro aparecer depois de executar o comando `ssh -L`, você pode entrar em seu ambiente de programação e executar o Jupyter Notebook:

    jupyter notebook

Você receberá uma saída com uma URL. Em um navegador web em sua máquina local, abra a interface web do Jupyter Notebook com a URL que começa com `http://localhost:8888`. Assegure-se de que o número do token esteja incluído ou insira a string do número do token quando solicitado em `http://localhost:8888`.

### Tunelamento SSH com Windows e Putty

Se você estiver usando o Windows, poderá criar um túnel SSH usando o [Putty](https://www.putty.org/).

Primeiro, insira a URL do servidor ou o endereço IP como o nome do host, como mostrado:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jupyter_notebook/set_hostname_putty.png)

Em seguida, clique em **SSH** na parte inferior do painel esquerdo para expandir o menu e, em seguida, clique em **Tunnels**. Digite o número da porta local que você deseja usar para acessar o Jupyter em sua máquina local. Escolha `8000` ou superior para evitar portas usadas por outros serviços, e defina o destino como `localhost:8888` onde `:8888` é o número da porta na qual o Jupyter Notebook está sendo executado.

Agora, clique no botão **Add** , e as portas deverão aparecer na lista **Forwarded ports**

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jupyter_notebook/forwarded_ports_putty.png)

Por fim, clique no botão **Open** para conectar-se ao servidor via SSH e tunelar as portas desejadas. Navegue até `http://localhost:8000` (ou qualquer porta que você escolheu) em um navegador da web para se conectar ao Jupyter Notebook em execução no servidor. Assegure-se de que o número do token esteja incluído ou insira a string do número do token quando solicitado em `http://localhost:8000`.

## Passo 6 — Usando o Jupyter Notebook

Esta seção aborda os conceitos básicos do uso do Jupyter Notebook. Se você ainda não tem o Jupyter Notebook em execução, inicie-o com o comando `jupyter notebook`.

Agora você deve estar conectado a ele usando um navegador web. O Jupyter Notebook é uma ferramenta muito poderosa com muitos recursos. Esta seção descreverá alguns dos recursos básicos para você começar a usar o Notebook. O Jupyter Notebook mostrará todos os arquivos e pastas no diretório a partir do qual ele é executado. Portanto, quando você estiver trabalhando em um projeto, certifique-se de iniciá-lo no diretório do projeto.

Para criar um novo arquivo do Notebook, selecione **New** \> **Python 3** no menu suspenso superior direito:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/eng_python/JupyterNotebookPy3/jupyter-notebook-new.png)

Isso irá abrir um Notebook. Agora podemos executar o código Python na célula ou alterar a célula para markdown. Por exemplo, altere a primeira célula para aceitar Markdown clicando em **Cell** \> **Cell Type** \> **Markdown** na barra de navegação superior. Agora podemos escrever notas usando Markdown e até incluir equações escritas em [LaTeX](https://www.latex-project.org/) colocando-as entre os símbolos `$$`. Por exemplo, digite o seguinte na célula depois de alterá-la para markdown:

    # Primeira Equação
    
    Vamos agora implementar a seguinte equação:
    $$ y = x^2$$
    
    Onde $x = 2$

Para transformar o markdown em rich text, pressione `CTRL+ENTER`, e o resultado deve ser o seguinte:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jupyter_notebook/jupyter_markdown.png)

Você pode usar as células markdown para fazer anotações e documentar seu código. Vamos implementar essa equação e imprimir o resultado. Clique na célula superior e pressione `ALT+ENTER` para adicionar uma célula abaixo dela. Digite o seguinte código na nova célula.

    x = 2
    y = x**2
    print(y)

Para executar o código, pressione `CTRL+ENTER`. Você receberá os seguintes resultados:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/jupyter_notebook/jupyter_python.png)

Agora você tem a capacidade de [importar modulos](how-to-import-modules-in-python-3) e usar o Notebook como você faria com qualquer outro ambiente de desenvolvimento Python!

## Conclusão

Parabéns! Agora você deve ser capaz de escrever códigos reproduzíveis em Python e notas no Markdown usando o Jupyter Notebook. Para obter um tour rápido pelo Jupyter Notebook dentro da interface, selecione **Help** \> **User Interface Tour** no menu de navegação superior para saber mais.

A partir daqui, você pode iniciar um projeto de análise e visualização de dados lendo [Data Analysis and Visualization with pandas and Jupyter Notebook in Python 3](data-analysis-and-visualization-with-pandas-and-jupyter-notebook-in-python-3).

Se você tem interesse em pesquisar mais, leia nossa série sobre [Visualização e Previsão de Séries Temporais](https://www.digitalocean.com/community/tutorial_series/time-series-visualization-and-forecasting).

_Por Lisa Tagliaferri_
