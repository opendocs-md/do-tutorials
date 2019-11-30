---
author: Brian King
date: 2018-07-17
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-utilizar-apis-web-no-python-3-es
---

# Como Utilizar APIs Web no Python 3

### Introdução

Uma API, ou Interface de Programação de Aplicações, torna fácil para os desenvolvedores integrar um app com outro. Elas expõem alguns dos funcionamentos internos de um programa de maneira limitada.

Você pode utilizar APIs para obter informações de outros programas ou para automatizar coisas que você faz normalmente em seu navegador. Às vezes você pode usar APIs para fazer coisas que você simplesmente não pode fazer de outra maneira. Um número surpreendente de propriedades web oferecem APIs juntamente com os websites ou apps móveis mais familiares, incluindo o Twitter, Facebook, GitHub, e DigitalOcean.

Se você já trabalhou em alguns tutoriais sobre [como programar em Python 3](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-python-3), e você está confortável com a sintaxe, estrutura, e algumas [funções](how-to-define-functions-in-python-3) internas do Python, você pode escrever programas em Python que aproveitam as suas APIs favoritas.

Neste guia, você aprenderá como usar o Python com a [API da DigitalOcean](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0ahUKEwjttPKwlJbVAhVILyYKHSdOCDIQFggmMAA&url=https%3A%2F%2Fdevelopers.digitalocean.com%2F&usg=AFQjCNH6P3GhnE-YCtIHW0RfVz6-WOX--g) para recuperar informações sobre sua conta na DigitalOcean. Em seguida, vamos ver como você pode aplicar o que aprendeu na [API do GitHub](https://developer.github.com/v3/).

Quando terminar, você entenderá os conceitos comuns em APIs web e terá um processo passo a passo, bem como exemplos de código de trabalho que você pode usar para testar APIs de outros serviços.

## Pré-requisitos

Antes de iniciar este guia você vai precisar do seguinte:

- Um ambiente de desenvolvimento local para Python 3. Você pode seguir o tutorial [How To Install and Set Up a Local Programming Environment for Python 3](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) para configurar tudo o que você precisar.
- Um editor de textos com o qual você esteja confortável. Se você ainda não tem um favorito, escolha um com realce de sintaxe. [Notepad++](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&sqi=2&ved=0ahUKEwjqr-mEq6LVAhUBjz4KHd8nAzEQFggiMAA&url=https%3A%2F%2Fnotepad-plus-plus.org%2F&usg=AFQjCNExci2YY1gy2cZYcnKLKfl2A9jWCg) para Windows, [BBEdit](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0ahUKEwil3PScq6LVAhWD6CYKHaWjD8oQFggmMAA&url=https%3A%2F%2Fwww.barebones.com%2Fproducts%2Fbbedit%2F&usg=AFQjCNEPJVqrxQA3XiwKthC8702r4oSf4A) para macOS, e [Sublime Text](how-to-use-web-apis-in-python-3) ou [Atom](https://atom.io/) para qualquer plataforma são todos boas escolhas. 
- Uma conta na DigitalOcean e a chave da API. Os primeiros parágrafos em [How To Use the DigitalOcean API v2](how-to-use-the-digitalocean-api-v2) mostram como fazer isso. 

## Passo 1 — Familiarizando-se com uma API

O primeiro passo na utilização de uma nova API é encontrar a documentação, e se orientar. A documentação da API da DigitalOcean começa em [https://developers.digitalocean.com/](https://developers.digitalocean.com/). Para encontrar APIs para outros serviços, pesquise pelo nome do site e “API” — nem todos os serviços promovem suas APIs em suas primeiras páginas.

Alguns serviços tem _API wrappers_. Um API wrapper é o código que você instala em seu sistema para facilitar a utilização das APIs em sua linguagem de programação escolhida. Este guia não utiliza quaisquer wrappers porque eles escondem muito do funcionamento interno das APIs, e geralmente não expõem tudo o que uma API pode fazer. Os wrappers podem ser ótimos quando você deseja fazer algo rapidamente, mas ter uma sólida compreensão do que as próprias APIs podem fazer ajudará você a decidir se os wrappers fazem sentido para seus objetivos.

Primeiro, veja a introdução sobre a API da DigitalOcean em [https://developers.digitalocean.com/documentation/v2/](https://developers.digitalocean.com/documentation/v2/) e tente entender apenas o básico sobre como enviar uma solicitação, e o que esperar na resposta. Neste ponto, você está tentando aprender apenas três coisas:

1- Como é uma solicitação? São todas apenas URLs? Para solicitações mais detalhadas, como os dados são formatados? São geralmente [JSON](an-introduction-to-json) ou parâmetros de querystring como um navegador web utiliza, mas alguns usam XML ou um formato personalizado.  
2- Como é uma resposta? Os documentos da API mostrarão exemplos de solicitações e respostas. Você obterá JSON, XML, ou ou algum outro tipo de resposta?   
3- O que vai nos cabeçalhos de solicitação ou resposta? Geralmente, o cabeçalho de solicitação inclui seu token de autenticação, e os cabeçalhos de resposta fornecem informações atualizadas sobre seu uso do serviço, como quão próximo você está do limite de taxa de solicitações.

A API da DigitalOcean usa _métodos_ HTTP (às vezes chamados de _verbos_) para indicar se você está tentando ler informações existentes, criar novas informações, ou deletar algo. Esta parte da documentação explica quais métodos são utilizados, e para quais propósitos. Geralmente, uma solicitação GET é mais simples do que um POST, mas quando você terminar esse tutorial, não notará muita diferença.

A próxima seção da documentação da API discute como o servidor responderá às suas solicitações. Em geral, uma solicitação é bem-sucedida ou falha. Quando ela falha, a causa ou é algo errado com a solicitação ou um problema com o servidor. Todas essas informações são comunicadas usando [códigos de status HTTP](how-to-troubleshoot-common-http-error-codes), que são números de 3 dígitos divididos em categorias.

- A série `200` significa “sucesso” - sua solicitação foi válida e a resposta é o que segue logicamente dela.
- A série `400` significa “solicitação inválida” — algo estava errado com a solicitação, então o servidor não a processou como você queria. Causas comuns para erros de nível HTTP `400` são solicitações mal formatadas e problemas de autenticação. 
- A série `500` significa “erro de servidor” — seu pedido pode ter sido OK, mas o servidor não pôde dar uma boa resposta agora por motivos que estão fora do seu controle. Estes erros devem ser raros, mas você precisa estar ciente da possibilidade para poder tratá-los em seu código. 

Seu código deve sempre verificar o código de status HTTP para qualquer resposta antes de tentar fazer qualquer coisa com ele. Se você não fizer isto, você estará perdendo tempo tentando solucionar problemas com informações incompletas.

Agora que você tem uma ideia geral de como enviar uma solicitação, e o que procurar na resposta, é hora de enviar a primeira solicitação.

## Passo 2 — Obtendo Informações da API Web

Sua conta na DigitalOcean inclui algumas informações administrativas que você pode não ter visto na interface de usuário Web. Uma API pode lhe oferecer uma visão diferente de informações familiares. Só de ver essa visualização alternativa pode, às vezes, gerar ideias sobre o que você pode querer fazer com uma API ou revelar serviços e opções desconhecidos.

Vamos começar criando um projeto para nossos scripts. Crie um novo diretório para o projeto chamado `apis`:

    mkdir apis

Em seguida, navegue para este novo diretório:

    cd apis

Crie um novo virtualenv para este projeto:

    python3 -m venv apis

Ative o virtualenv:

    source apis/bin/activate

Então instale a biblioteca [requests](http://docs.python-requests.org/en/master/), que iremos utilizar em nossos scripts para fazer solicitações HTTP:

    pip install requests

Com o ambiente configurado, crie um novo arquivo Python chamado `do_get_account.py` e abra-o em seu editor de textos. Comece este programa [importando bibliotecas](how-to-import-modules-in-python-3) para o trabalho com solicitações JSON e HTTP.

do\_get\_account.py

    
    import json
    import requests

Estas declarações `import` carregam códigos Python que facilitam o trabalho com o formato de dados JSON e o protocolo HTTP. Estamos utilizando estas bibliotecas porque não estamos interessados nos detalhes de como enviar solicitações HTTP ou como analisar e criar um JSON válido; queremos apenas utilizá-las para realizar essas tarefas. Todos os nossos scripts neste tutorial começarão assim.

Em seguida, queremos definir algumas [variáveis](how-to-use-variables-in-python-3) para armazenar informações que serão as mesmas em todas as solicitações. Isso nos poupa de ter que digitá-las repetidas vezes, e nos fornece um único local para fazer atualizações caso algo mude. Adicione estas linhas ao arquivo após as declarações `import`.

do\_get\_account.py

    
    ...
    api_token = 'seu_api_token'
    api_url_base = 'https://api.digitalocean.com/v2/'
    

A variável `api_token` é uma string que armazena o seu token de API da DigitalOcean. Substitua o valor no exemplo com o seu próprio token. A variável `api_url_base` é a string que inicia cada URL na API da DigitalOcean. Iremos acrescentar a ela conforme necessário posteriormente no código.

Em seguida, precisamos definir os cabeçalhos das solicitações HTTP da forma descrita na documentação da API. Adicione estas linhas ao arquivo para definir um [dicionário](understanding-dictionaries-in-python-3) contendo seus cabeçalhos de solicitação.

do\_get\_account.py

    
    ...
    headers = {'Content-Type': 'application/json',
               'Authorization': 'Bearer {0}'.format(api_token)}
    

Isso define dois cabeçalhos ao mesmo tempo. O cabeçalho `Content-Type` diz ao servidor para esperar dados no formato JSON no corpo da solicitação. O cabeçalho `Authorization` precisa incluir nosso token, então usamos a lógica de formatação de strings do Python para inserir nossa variável `api_token` na string enquanto criamos a string. Poderíamos ter colocado o token aqui como uma string literal, mas separá-lo tornará várias coisas mais fáceis no futuro:

- Se você precisar substituir o token, é mais fácil ver onde fazer isso quando ele é uma variável separada.
- Se você quiser compartilhar seu código com alguém, é mais fácil remover seu token de API, e mais fácil para seu amigo ver onde colocar o token dele.
- É auto documentado. Se o token da API for usado apenas como string literal, alguém que esteja lendo seu código poderá não entender o que está vendo.

Agora que temos esses detalhes de configuração cobertos, é hora de enviar a solicitação de fato. Sua inclinação pode ser apenas começar a criar e enviar as solicitações, mas há um jeito melhor. Se você colocar essa lógica em uma função que trata o envio da solicitação e lê a resposta, você terá que pensar um pouco mais claramente sobre o que está fazendo. Você também vai acabar tendo um código mais fácil de testar e mais fácil de reutilizar. Isso é o que vamos fazer.

Essa função usará as variáveis criadas para enviar a solicitação e retornar as informações da conta em um dicionário Python.

Para manter a lógica clara neste estágio inicial, não faremos nenhum tratamento detalhado de erros ainda, mas adicionaremos isso em breve.

Defina a função que busca as informações da conta. É sempre uma boa ideia nomear uma função depois do que ela faz: Esta função obtém informações da conta, então vamos chamá-la de `get_account_info`:

do\_get\_account.py

    
    ...
    def get_account_info():
    
        api_url = '{0}account'.format(api_url_base)
    
        response = requests.get(api_url, headers=headers)
    
        if response.status_code == 200:
            return json.loads(response.content.decode('utf-8'))
        else:
            return None
    

Construímos o valor para `api_url` usando o método de formatação de strings do Python, semelhante ao modo como o usamos nos cabeçalhos; anexamos a URL base da API na frente da string `account` para obter a URL `https://api.digitalocean.com/v2/account`, que é a URL que deve retornar as informações da conta.

A variável `response` armazena um objeto criado pelo [módulo](how-to-import-modules-in-python-3) Python `requests`. Essa linha envia a solicitação para a URL que criamos com os cabeçalhos que definimos no início do script e retorna a resposta da API.

Em seguida, olhamos para o código de status HTTP da resposta.

Se é `200`, uma resposta bem sucedida, então usamos a função `loads`do módulo `json` para carregar uma string como JSON. A string que carregamos é o conteúdo do objeto `response`, `response.content`. A parte `.decode('utf-8')` diz ao Python que esse conteúdo está codificado usando o conjunto de caracteres UTF-8, como todas as respostas da API da DigitalOcean serão. O módulo `json` cria um objeto a partir disso, que usamos como o valor de retorno para esta função.

Se a resposta _não_ foi `200`, então retornamos `None`, que é um valor especial no Python que podemos verificar quando chamamos essa função. Você vai notar que estamos apenas ignorando quaisquer erros neste momento. Isso é para manter a lógica do “sucesso” clara. Adicionaremos uma verificação de erros mais abrangente em breve.

Agora chame esta função, verifique se ela obteve uma boa resposta, e imprima os detalhes retornados pela API:

do\_get\_account.py

    
    ...
    account_info = get_account_info()
    
    if account_info is not None:
        print("Aqui estão suas informações: ")
        for k, v in account_info['account'].items():
            print('{0}:{1}'.format(k, v))
    
    else:
        print('[!] Solicitação inválida')
    

`account_info = get_account_info()` define a variável `account_info` para o que quer que tenha voltado da chamada para `get_account_info()`, então ou isso vai ser o valor especial `None` ou será a coleta de informações sobre a conta.

Se não for `None`, então imprimimos cada parte de informação em sua própria linha usando o método `items()`que todo dicionário Python possui.

Do contrário (isto é, se `account_info` é `None`), imprimimos uma mensagem de erro.

Vamos fazer uma pausa por um minuto aqui. Essa declaração `if` com um duplo negativo nela pode parecer estranha no começo, mas é um idioma comum em Python. Sua virtude está em manter o código que roda com sucesso muito próximo da [condicional](how-to-write-conditional-statements-in-python-3-2) em vez de ser após os casos de tratamento de erros.

Você pode fazer o contrário, se preferir, e pode ser um bom exercício escrever esse código por si próprio. Em vez de `if account_info is not None`: você pode começar com `if account_info is None`: e ver como o restante se encaixa.

Salve o script e experimente:

    python do_get_account.py

A saída será algo assim:

    OutputAqui estão suas informações: 
    droplet_limit:25
    email:sammy@digitalocean.com
    status:active
    floating_ip_limit:3
    email_verified:True
    uuid:123e4567e89b12d3a456426655440000
    status_message:
    

Agora você sabe como recuperar dados de uma API. Em seguida, vamos passar para algo um pouco mais interessante - a utilização de uma API para alterar dados.

## Passo 3 — Modificando Informações no Servidor

Depois de praticar com uma solicitação somente leitura, é hora de começar a fazer alterações. Vamos explorar isso usando Python e a API da DigitalOcean para adicionar uma chave SSH à sua conta na DigitalOcean.

Primeiro, dê uma olhada na documentação da API para chaves SSH, disponível em [https://developers.digitalocean.com/documentation/v2/#ssh-keys](https://developers.digitalocean.com/documentation/v2/#ssh-keys).

A API lhe permite listar as chaves SSH atuais em sua conta, e também lhe permite adicionar novas chaves. A solicitação para obter uma lista de chaves SSH é muito parecida com a de obter informações da conta. A resposta é diferente, no entanto: diferentemente de uma conta, você pode ter zero, uma ou várias chaves SSH.

Crie um novo arquivo para este script chamado `do_ssh_keys.py`, e comece exatamente como o último. Importe os módulos json e requests para que você não precise se preocupar com os detalhes do JSON ou do protocolo HTTP. Em seguida, adicione seu token de API da DigitalOcean como uma variável e defina os cabeçalhos da solictação em um dicionário.

do\_ssh\_keys.py

    
    import json
    import requests
    
    api_token = 'seu_api_token'
    api_url_base = 'https://api.digitalocean.com/v2/'
    headers = {'Content-Type': 'application/json',
               'Authorization': 'Bearer {0}'.format(api_token)}
    

A função que criaremos para obter as chaves SSH é semelhante à que usamos para obter informações da conta, mas desta vez vamos lidar com erros mais diretamente.

Primeiro, faremos a chamada da API e armazenaremos a resposta em uma variável de resposta `response`. No entanto, `api_url` não será o mesmo que no script anterior; desta vez ela precisa apontar para `https://api.digitalocean.com/v2/account/keys`.

Adicione este código ao script:

do\_ssh\_keys.py

    
    ...
    def get_ssh_keys():
    
        api_url = '{0}account/keys'.format(api_url_base)
    
        response = requests.get(api_url, headers=headers)
    

Agora vamos adicionar um tratamento de erros, observando o código de status HTTP na resposta. Se for `200`, retornaremos o conteúdo da resposta como um dicionário, como fizemos antes. Se for qualquer outra coisa, imprimiremos uma mensagem de erro explicativa associada ao tipo de código de status e, em seguida, retornaremos `None`.

Adicione estas linhas à função `get_ssh_keys`:

do\_ssh\_keys.py

    
    ...
    
        if response.status_code >= 500:
            print('[!] [{0}] Erro no Servidor'.format(response.status_code))
            return None
        elif response.status_code == 404:
            print('[!] [{0}] URL não encontrada: [{1}]'.format(response.status_code,api_url))
            return None  
        elif response.status_code == 401:
            print('[!] [{0}] Falha de autenticação'.format(response.status_code))
            return None
        elif response.status_code == 400:
            print('[!] [{0}] Solicitação inválida'.format(response.status_code))
            return None
        elif response.status_code >= 300:
            print('[!] [{0}] Redirecionamento inesperado'.format(response.status_code))
            return None
        elif response.status_code == 200:
            ssh_keys = json.loads(response.content.decode('utf-8'))
            return ssh_keys
        else:
            print('[?] Erro inesperado: [HTTP {0}]: Content: {1}'.format(response.status_code, response.content))
        return None
    

Esse código trata seis condições de erro diferentes, observando o código de status HTTP na resposta.

- Um código `500` ou superior indica um problema no servidor. Esses códigos devem ser raros e não são causados por problemas com a solicitação, portanto, imprimimos somente o código de status.
- Um código `404` significa “não encontrado”, que provavelmente deriva de um erro de digitação na URL. Para esse erro, imprimimos o código de status e a URL que levou até ele para que você possa ver por que ele falhou.
- Um código `401` significa que a autenticação falhou. A causa mais provável para isso é um `api_key` incorreto ou ausente.
- Um código no intervalo `300` indica um redirecionamento. A API da DigitalOcean não utiliza redirecionamentos, então isso nunca deve acontecer, mas como estamos lidando com erros, não custa nada verificar. Muitos bugs são causados por coisas que o programador acha que nunca deveriam acontecer.
- Um código `200` significa que a solicitação foi processada com sucesso. Por isso, não imprimimos nada. Apenas retornamos as chaves SSH como um objeto JSON, utilizando a mesma sintaxe que usamos no script anterior.
- Se o código de resposta foi qualquer outra coisa, imprimimos o código de status como um “erro inesperado”.

Isso deve tratar quaisquer erros que provavelmente receberemos ao chamar a API. Neste ponto, temos ou uma mensagem de erro e o objeto `None`, ou temos sucesso e um objeto JSON contendo zero ou mais chaves SSH. Nosso próximo passo é imprimi-los:

do\_ssh\_keys.py

    
    ...
    
    ssh_keys = get_ssh_keys()
    
    if ssh_keys is not None:
        print('Aqui estão suas chaves: ')
        for key, details in enumerate(ssh_keys['ssh_keys']):
            print('Key {}:'.format(key))
            for k, v in details.items():
                print(' {0}:{1}'.format(k, v))
    else:
        print('[!] A solicitação falhou')
    

Como a resposta contém uma [lista](understanding-lists-in-python-3) (ou array) de chaves SSH, queremos iterar sobre toda a lista para ver todas as chaves. Usamos o método `enumerate` do Python para isso. É similar ao método `items` disponível para dicionários, mas trabalha com listas.

Utilizamos `enumerate` e não apenas um [loop `for`](how-to-construct-for-loops-in-python-3#for-loops), porque queremos ser capazes de dizer o quão longe na lista estamos para qualquer chave dada.

As informações de cada chave são retornadas como um dicionário, então usamos o mesmo código `for k,v in details.items():` que usamos no dicionário de informações de conta no script anterior.

Execute este script e você obterá uma lista de chaves SSH que já estão em sua conta.

    python get_ssh_keys.py

A saída será algo assim, dependendo de quantas chaves SSH você já tem em sua conta.

    OutputAqui estão suas chaves: 
    Kcy 0:
      id:280518
      name:work
      fingerprint:96:f7:fb:9f:60:9c:9b:f9:a9:95:01:5c:5c:2c:d5:a0
      public_key:ssh-rsa AAAAB5NzaC1yc2cAAAADAQABAAABAQCwgr9Fzc/YTD/V2Ka5I52Rx4I+V2Ka5I52Rx4Ir5LKSCqkQ1Cub+... sammy@work
    Kcy 1:
      id:290536
      name:home
      fingerprint:90:1c:0b:ac:fa:b0:25:7c:af:ab:c5:94:a5:91:72:54
      public_key:ssh-rsa AAAAB5NzaC1yc2cAAAABJQAAAQcAtTZPZmV96P9ziwyr5LKSCqkQ1CubarKfK5r7iNx0RNnlJcqRUqWqSt... sammy@home
    

Agora que você pode listar as chaves SSH em sua conta, seu último script aqui será aquele que adiciona uma nova chave à lista.

Antes de podermos adicionar uma nova chave SSH, precisamos gerar uma. Para um tratamento mais completo desta etapa, dê uma olhada no tutorial [How to Set Up SSH Keys](how-to-set-up-ssh-keys--2).

Para nossos propósitos, porém, precisamos apenas de uma chave simples. Execute este comando para gerar uma nova chave no Linux, BSD ou MacOS. Você pode fazer isso em um Droplet existente, se quiser.

    ssh-keygen -t rsa

Quando solicitado, digite o arquivo para salvar a chave e não forneça uma frase secreta.

    OutputGenerating public/private rsa key pair.
    Enter file in which to save the key (/home/sammy/.ssh/id_rsa): /home/sammy/.ssh/sammy 
    Created directory '/home/sammy/.ssh'.
    Enter passphrase (empty for no passphrase): 
    Enter same passphrase again: 
    Your identification has been saved in /home/sammy/.ssh/sammy.
    Your public key has been saved in /home/sammy/.ssh/sammy.pub.
    ...
    

Observe onde o arquivo da chave pública foi salvo, porque você precisará dele para o script.

Inicie um novo script Python, e chame-o de `add_ssh_key.py`, e comece-o assim como os outros:

add\_ssh\_key.py

    
    
    import json
    import requests
    
    api_token = 'seu_api_token'
    api_url_base = 'https://api.digitalocean.com/v2/'
    headers = {'Content-Type': 'application/json',
               'Authorization': 'Bearer {0}'.format(api_token)}
    

Utilizaremos uma função para fazer nossa solicitação, mas esta será ligeiramente diferente.

Crie uma função chamada `add_ssh_key` que irá aceitar dois argumentos: o nome a utilizar para a nova chave SSH, e o nome do arquivo dessa chave em seu sistema local. A função irá [ler o arquivo](how-to-handle-plain-text-files-in-python-3), e fazer uma solicitação HTTP `POST`, em vez de um `GET`:

add\_ssh\_key.py

    
    ...
    
    def add_ssh_key(name, filename):
    
        api_url = '{0}account/keys'.format(api_url_base)
    
        with open(filename, 'r') as f:
            ssh_key = f.readline()
    
        ssh_key = {'name': name, 'public_key': ssh_key}
    
        response = requests.post(api_url, headers=headers, json=ssh_key)
    

A linha `with open(filename, 'r') as f:` abre o arquivo no modo somente leitura, e a linha seguinte lê a primeira (e única) linha do arquivo, armazenando-a na variável `ssh_key`.

Em seguida, fazemos um dicionário Python chamado `ssh_key` com os nomes e valores que a API espera.

Quando enviamos a solicitação, porém, há uma novidade aqui. É um `POST` em vez de um `GET`, e precisamos enviar a `ssh_key` no corpo da solicitação `POST`, codificada como JSON. O módulo `requests` irá tratar dos detalhes para nós; `requests.post` lhe diz para usar o método `POST`, e `json=ssh_key` lhe diz para enviar a variável `ssh_key` no corpo da solicitação, codificada como JSON.

De acordo com a API, a resposta será HTTP `201` para sucesso, em vez de`200`, e o corpo da resposta conterá os detalhes da chave que acabamos de incluir.

Adicione o seguinte código de tratamento de erros à função `add_ssh_key`. Ele é semelhante ao script anterior, exceto que desta vez temos que procurar pelo código `201` em vez de`200` para sucesso:

add\_ssh\_key.py

    
    ...
      if response.status_code >= 500:
          print('[!] [{0}] Erro no Servidor'.format(response.status_code))
          return None
      elif response.status_code == 404:
          print('[!] [{0}] URL não encontrada: [{1}]'.format(response.status_code,api_url))
          return None
      elif response.status_code == 401:
          print('[!] [{0}] Falha de autenticação'.format(response.status_code))
          return None
      elif response.status_code >= 400:
          print('[!] [{0}] Solicitação inválida'.format(response.status_code))
          print(ssh_key )
          print(response.content )
          return None
      elif response.status_code >= 300:
          print('[!] [{0}] Redirecionamento inesperado.'.format(response.status_code))
          return None
      elif response.status_code == 201:
          added_key = json.loads(response.content)
          return added_key
      else:
          print('[?] Erro inesperado: [HTTP {0}]: Content: {1}'.format(response.status_code, response.content))
          return None
    

Esta função, como as anteriores, retorna `None` ou o conteúdo da resposta, dessa forma usamos a mesma abordagem de antes para verificar o resultado.

Em seguida, chame a função e processe o resultado. Passe o caminho para a sua chave SSH recém-criada como o segundo argumento.

add\_ssh\_key.py

    
    ...
    add_response = add_ssh_key('tutorial_key', '/home/sammy/.ssh/sammy.pub')
    
    if add_response is not None:
        print('Sua chave foi adicionada: ' )
        for k, v in add_response.items():
            print(' {0}:{1}'.format(k, v))
    else:
        print('[!] A solicitação falhou')
    

Execute este script e você receberá uma resposta informando que sua nova chave foi adicionada.

    python add_ssh_key.py 

A saída será algo assim:

    OutputSua chave foi adicionada: 
      ssh_key:{'id': 9458326, 'name': 'tutorial_key', 'fingerprint': '64:76:37:77:c8:c7:26:05:f5:7b:6b:e1:bb:d6:80:da', 'public_key': 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCUtY9aizEcVJ65/O5CE6tY8Xodrkkdh9BB0GwEUE7eDKtTh4NAxVjXc8XdzCLKtdMwfSg9xwxSi3axsVWYWBUhiws0YRxxMNTHCBDsLFTJgCFC0JCmSLB5ZEnKl+Wijbqnu2r8k2NoXW5GUxNVwhYztXZkkzEMNT78TgWBjPu2Tp1qKREqLuwOsMIKt4bqozL/1tu6oociNMdLOGUqXNrXCsOIvTylt6ROF3a5UnVPXhgz0qGbQrSHvCEfuKGZ1kw8PtWgeIe7VIHbS2zTuSDCmyj1Nw1yOTHSAqZLpm6gnDo0Lo9OEA7BSFr9W/VURmTVsfE1CNGSb6c6SPx0NpoN sammy@tutorial-test'}
    

Se você se esqueceu de alterar a condição de “sucesso” para procurar por HTTP `201` em vez de `200`, você verá um erro relatado, mas a chave ainda terá sido adicionada. Seu tratamento de erros poderia lhe dizer que o código de status era `201`. Você deve reconhecer isso como um membro da série `200`, o que indica sucesso. Este é um exemplo de como o tratamento básico de erros pode simplificar a solução de problemas.

Após adicionar a chave com sucesso usando esse script, execute-o novamente para ver o que acontece quando você tenta adicionar uma chave que já está presente.

A API retornará uma resposta HTTP `422`, que seu script traduzirá para uma mensagem dizendo “A chave SSH já está em uso em sua conta.”:

    Output[!] [422] Solicitação inválida
    {'name': 'tutorial_key', 'public_key': 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCUtY9aizEcVJ65/O5CE6tY8Xodrkkdh9BB0GwEUE7eDKtTh4NAxVjXc8XdzCLKtdMwfSg9xwxSi3axsVWYWBUhiws0YRxxMNTHCBDsLFTJgCFC0JCmSLB5ZEnKl+Wijbqnu2r8k2NoXW5GUxNVwhYztXZkkzEMNT78TgWBjPu2Tp1qKREqLuwOsMIKt4bqozL/1tu6oociNMdLOGUqXNrXCsOIvTylt6ROF3a5UnVPXhgz0qGbQrSHvCEfuKGZ1kw8PtWgeIe7VIHbS2zTuSDCmyj1Nw1yOTHSAqZLpm6gnDo0Lo9OEA7BSFr9W/VURmTVsfE1CNGSb6c6SPx0NpoN sammy@tutorial-test'}
    b'{"id":"unprocessable_entity","message":"A chave SSH já está em uso em sua conta."}'
    [!] Request Failed
    

Agora execute seu script `get_ssh_keys.py` novamente e você verá sua chave recém-adicionada na lista.

Com pequenas modificações, esses dois scripts podem ser uma forma rápida de adicionar novas chaves SSH à sua conta da DigitalOcean sempre que você precisar. Funções relacionadas nesta API permitem que você renomeie ou exclua uma chave específica usando sua ID exclusiva de chave ou impressão digital.

Vamos dar uma olhada em outra API e ver como as habilidades que você acabou de aprender podem ser usadas.

## Passo 4 — Trabalhando com uma API Diferente

O GitHub tem uma API também. Tudo o que você aprendeu sobre o uso da API da DigitalOcean é diretamente aplicável ao uso da API do GitHub.

Familiarize-se com a API do GitHub da mesma forma que você fez com a da DigitalOcean. Pesquise a [documentação da API](https://developer.github.com/v3/), e localize a seção **Overview**. Você verá que a API do GitHub e a API da DigitalOcean compartilham algumas similaridades.

Primeiro, você perceberá que há uma raiz comum em todas as URLs da API: `https://api.github.com/`. Você sabe como usar isso como uma variável em seu código para otimizar e reduzir o potencial de erros.

A API do GitHub usa o JSON como seu formato de solicitação e resposta, assim como a DigitalOcean, assim você sabe como fazer essas solicitações e lidar com as respostas.

As respostas incluem informações sobre os limites de taxa de solicitações nos cabeçalhos de resposta HTTP, usando quase os mesmos nomes e exatamente os mesmos valores da DigitalOcean.

O GitHub usa o OAuth para autenticação e você pode enviar seu token em um cabeçalho de solicitação. Os detalhes desse token são um pouco diferentes, mas o modo como ele é usado é idêntico ao que você fez com a API da DigitalOcean.

Existem algumas diferenças também. O GitHub incentiva o uso de um cabeçalho de solicitação para indicar a versão da API que você deseja usar. Você sabe como adicionar cabeçalhos às solicitações no Python.

O GitHub também quer que você use uma string `User-Agent` exclusiva em solicitações, para que eles possam encontrá-lo mais facilmente se seu código estiver causando problemas. Você lidaria com isso através de um cabeçalho também.

A API do GitHub usa os mesmos métodos de solicitação HTTP, mas também usa um novo chamado `PATCH` para certas operações. A API do GitHub usa `GET` para ler informações,`POST` para adicionar um novo item e `PATCH` para modificar um item existente. Esta solicitação `PATCH` é o tipo de coisa que você vai querer ficar de olho na documentação da API.

Nem todas as chamadas da API do GitHub exigem autenticação. Por exemplo, você pode obter uma lista dos repositórios de um usuário sem precisar de um token de acesso. Vamos criar um script para fazer essa solicitação e exibir os resultados.

Vamos simplificar o tratamento de erros neste script e usar apenas uma declaração para lidar com todos os possíveis erros. Você nem sempre precisa de código para lidar com cada tipo de erro separadamente, mas é um bom hábito fazer algo com condições de erro, apenas para lembrar que as coisas nem sempre correm do jeito que você espera.

Crie um novo arquivo chamado `github_list_repos.py` em seu editor e adicione o seguinte conteúdo, que deve lhe parecer bastante familiar:

github\_list\_repos.py

    
    import json
    import requests
    
    api_url_base = 'https://api.github.com/'
    headers = {'Content-Type': 'application/json',
               'User-Agent': 'Python Student',
               'Accept': 'application/vnd.github.v3+json'}
    

As importações são as mesmas que temos utilizado. A `api_url_base` é onde todas as APIs do GitHub começam.

Os cabeçalhos incluem dois dos opcionais que o GitHub menciona em sua visão geral, além daquele que diz que estamos enviando dados em formato JSON em nossa solicitação.

Embora este seja um script pequeno, ainda definiremos uma função para manter nossa lógica modular e encapsular a lógica para fazer a solicitação. Muitas vezes, seus pequenos scripts vão se transformar em scripts maiores, por isso é bom ser cuidadoso com isso. Adicione uma função chamada `get_repos` que aceita um nome de usuário como seu argumento:

github\_list\_repos.py

    
    
    ...
    def get_repos(username):
    
        api_url = '{}orgs/{}/repos'.format(api_url_base, username)
    
        response = requests.get(api_url, headers=headers)
    
        if response.status_code == 200:
            return (response.content)
        else:
            print('[!] HTTP {0} calling [{1}]'.format(response.status_code, api_url))
            return None
    

Dentro da função, construímos a URL com a `api_url_base`, o nome do usuário no qual estamos interessados e as partes estáticas da URL que informam ao GitHub que queremos a lista de repositórios. Em seguida, verificamos o código de status HTTP da resposta para garantir que ele foi `200` (sucesso). Se foi bem sucedido, retornamos o conteúdo da resposta. Se não foi, então imprimimos o Código de Status real e o URL que criamos para que possamos ter uma ideia de onde podemos ter errado.

Agora, chame a função e passe o nome de usuário do GitHub que você deseja usar. Vamos usar `octokit` para este exemplo. Em seguida, imprima os resultados na tela:

github\_list\_repos.py

    
    
    ...
    repo_list = get_repos('octokit')
    
    if repo_list is not None:
        print(repo_list)
    else:
        print('No Repo List Found')
    

Salve o arquivo e execute o script para ver os repositórios do usuário que você especificou.

    python github_list_repos.py

Você verá muitos dados na saída porque não analisamos a resposta como JSON neste exemplo, nem filtramos os resultados para chaves específicas. Use o que você aprendeu nos outros scripts para fazer isso. Veja os resultados que você está obtendo e veja se você pode imprimir o nome do repositório.

Uma coisa boa sobre essas APIs do GitHub é que você pode acessar as solicitações para as quais você não precisa de autenticação diretamente no navegador. Isso permite que você compare as respostas com o que você está vendo em seus scripts. Tente visitar [https://api.github.com/orgs/octokit/repos](https://api.github.com/orgs/octokit/repos) em seu navegador para ver a resposta lá.

A essa altura, você sabe como ler a documentação e escrever o código necessário para enviar solicitações mais específicas para suportar os seus próprios objetivos com a API do GitHub.

Você pode encontrar o código completo para todos os exemplos desse tutorial [nesse repositório do GitHub](https://github.com/do-community/python3_web_api_tutorial).

## Conclusão

Neste tutorial, você aprendeu a usar web APIs para dois serviços diferentes com estilos ligeiramente diferentes. Você viu a importância de incluir código de tratamento de erros para facilitar a depuração e tornar os scripts mais robustos. Você utilizou os módulos `requests` e `json` do Python para isolá-lo dos detalhes dessas tecnologias e apenas fazer o seu trabalho, e você encapsulou o processamento de solicitações e respostas em uma função para tornar seus scripts mais modulares.

E, além disso, agora você tem um processo repetível para seguir ao aprender qualquer nova web API:

1. Encontre a documentação e leia a introdução para entender os fundamentos de como interagir com a API.
2. Obtenha um token de autenticação se precisar de um, e escreva um script modular com um tratamento básico de erros para enviar uma solicitação simples, responder a erros e processar a resposta.
3. Crie as solicitações que lhe darão as informações que você quer do serviço.

Agora, consolide esse conhecimento recém-adquirido e encontre outra API para utilizar, ou até mesmo outro recurso de uma das APIs que você usou aqui. Um projeto seu o ajudará a solidificar o que você aprendeu aqui.

Traduzido Por Fernando Pimenta
