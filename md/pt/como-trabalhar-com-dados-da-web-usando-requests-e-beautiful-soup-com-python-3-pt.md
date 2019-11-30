---
author: Lisa Tagliaferri
date: 2018-07-09
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-trabalhar-com-dados-da-web-usando-requests-e-beautiful-soup-com-python-3-pt
---

# Como Trabalhar com Dados da Web Usando Requests e Beautiful Soup com Python 3

### Introdução

A Web nos fornece mais dados do que qualquer um de nós pode ler e entender, assim, muita vezes queremos trabalhar com essas informações programaticamente a fim de dar sentido a isso. Às vezes, esse dado nos é fornecido pelo criador do website via arquivos `.csv` ou valores separados por vírgula, ou através de uma API (Interface de Programação da Aplicação). Outras vezes, precisamos coletar texto da própria web.

Este tutorial irá mostrar como trabalhar com os pacotes Python [Requests](http://docs.python-requests.org/en/master/) e [Beautiful Soup](https://www.crummy.com/software/BeautifulSoup/) de forma a poder utilizar dados das páginas web. O módulo Requests lhe permite integrar seus programas Python com web services, enquanto o módulo Beautiful Soup é projetado para fazer com que a captura de tela ou screen-scraping seja feita rapidamente. Utilizando o console interativo do Python e essas duas bibliotecas, vamos ver como coletar uma página web e trabalhar com as informações textuais disponíveis lá.

## Pré-requisitos

Para completar este tutorial, você vai precisar de um ambiente de desenvolvimento Python 3. Você pode seguir o guia apropriado para o seu sistema operacional disponível na série [How To Install and Set Up a Local Programming Environment for Python 3](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) ou [How To Install Python 3 and Set Up a Programming Environment on an Ubuntu 16.04 Server](how-to-install-python-3-and-set-up-a-programming-environment-on-an-ubuntu-16-04-server) para configurar tudo o que você precisar.

Adicionalmente, você deverá estar familiarizado com:

- O [Console Interativo do Python](how-to-work-with-the-python-interactive-console)
- [Importação de Módulos no Python 3](how-to-import-modules-in-python-3)
- Estrutura e o uso de tags HTML

Com o seu ambiente de desenvolvimento configurado e esses conceitos de programação Python em mente, vamos começar a trabalhar com Requests e Beautiful Soup.

## Instalando o Requests

Vamos começar ativando nosso ambiente de programação Python. Certifique-se de que você está no diretório onde o seu ambiente de desenvolvimento está localizado, e execute o seguinte comando.

    . my_env/bin/activate

Para trabalhar com páginas web, vamos precisar solicitar a página. A biblioteca Requests lhe permite fazer uso de HTTP dentro de Programas Python em um formato legível.

Com o seu ambiente de programação ativado, vamos instalar o Requests com o pip:

    pip install requests

Enquanto a biblioteca Requests estiver sendo instalada, você receberá a seguinte saída:

    OutputCollecting requests
      Downloading requests-2.18.1-py2.py3-none-any.whl (88kB)
        100% |████████████████████████████████| 92kB 3.1MB/s 
    ...
    Installing collected packages: chardet, urllib3, certifi, idna, requests
    Successfully installed certifi-2017.4.17 chardet-3.0.4 idna-2.5 requests-2.18.1 urllib3-1.21.1

Se o Requests foi instalado anteriormente, você receberia um feedback similar ao seguinte em sua janela de terminal:

    OutputRequirement already satisfied
    ...

Com o Requests instalado em seu ambiente de programação, podemos seguir e instalar o próximo módulo.

## Instalando o Beautiful Soup

Assim como fizemos com o Requests, vamos instalar o Beautiful Soup com o pip. A versão atual do Beautiful Soup 4 pode ser instalada com o seguinte comando:

    pip install beautifulsoup4

Depois de executar este comando, você deverá ver uma saída parecida com a seguinte:

    OutputCollecting beautifulsoup4
      Downloading beautifulsoup4-4.6.0-py3-none-any.whl (86kB)
        100% |████████████████████████████████| 92kB 4.4MB/s 
    Installing collected packages: beautifulsoup4
    Successfully installed beautifulsoup4-4.6.0

Agora que tanto o Beautiful Soup quanto o Requests estão instalados, podemos passar a entender como trabalhar com as bibliotecas para fazer scraping em websites.

## Coletando uma Página Web com o Requests

Com as duas bibliotecas Python que usaremos agora instaladas, podemos nos familiarizar com a varredura de uma página web básica.

Vamos primeiro entrar no [Console Interativo do Python](how-to-work-with-the-python-interactive-console):

    python

A partir daqui, vamos importar o módulo Requests de forma que possamos coletar uma página web de exemplo:

    import requests
    

Vamos atribuir a URL (abaixo) da página web de exemplo, `mockturtle.html` à [variável](how-to-use-variables-in-python-3) `url`:

    url = 'https://assets.digitalocean.com/articles/eng_python/beautiful-soup/mockturtle.html'
    

Em seguida, podemos atribuir o resultado de uma solicitação dessa página à variável `page` com o [método `request.get()`](http://docs.python-requests.org/en/master/user/quickstart/#make-a-request). Passamos a URL da página (que atribuímos à variável `url`) para esse método.

    page = requests.get(url)
    

A variável `page` é atribuída a um objeto Response:

    >>> page
    <Response [200]>
    >>>

O objeto Response acima nos informa a propriedade `status_code` entre colchetes (nesse caso `200`). Este atributo pode ser chamado explicitamente:

    >>> page.status_code
    200
    >>> 

O código de retorno `200` nos diz que a página foi baixada com sucesso. Códigos que começam com o número `2` geralmente indicam sucesso, enquanto códigos que começam com `4` ou `5` indicam que um erro ocorreu. Você pode ler mais sobre códigos de status HTTP nas [Definições de Códigos de Status do W3C](https://www.w3.org/Protocols/HTTP/1.1/draft-ietf-http-v11-spec-01#Status-Codes).

Para trabalhar com dados da web, vamos querer acessar o conteúdo baseado em texto dos arquivos web. Podemos ler o conteúdo da resposta do servidor web com `page.text` (ou `page.content` se quisermos acessar a resposta em bytes).

    page.text

Ao pressionar `ENTER`, vamos receber a seguinte saída:

    Output'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"\n    
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n\n<html lang="en-US" 
    xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US">\n<head>\n <meta 
    http-equiv="content-type" content="text/html; charset=us-ascii" />\n\n <title>Turtle 
    Soup</title>\n</head>\n\n<body>\n <h1>Turtle Soup</h1>\n\n <p class="verse" 
    id="first">Beautiful Soup, so rich and green,<br />\n Waiting in a hot tureen!<br />\n Who for 
    such dainties would not stoop?<br />\n Soup of the evening, beautiful Soup!<br />\n Soup of 
    the evening, beautiful Soup!<br /></p>\n\n <p class="chorus" id="second">Beau--ootiful 
    Soo--oop!<br />\n Beau--ootiful Soo--oop!<br />\n Soo--oop of the e--e--evening,<br />\n  
    Beautiful, beautiful Soup!<br /></p>\n\n <p class="verse" id="third">Beautiful Soup! Who cares 
    for fish,<br />\n Game or any other dish?<br />\n Who would not give all else for two<br />\n  
    Pennyworth only of Beautiful Soup?<br />\n Pennyworth only of beautiful Soup?<br /></p>\n\n  
    <p class="chorus" id="fourth">Beau--ootiful Soo--oop!<br />\n Beau--ootiful Soo--oop!<br />\n  
    Soo--oop of the e--e--evening,<br />\n Beautiful, beauti--FUL SOUP!<br 
    /></p>\n</body>\n</html>\n'
    >>> 

Aqui vemos que o texto completo da página foi impresso, com todas as suas tags HTML. Contudo, é difícil ler porque não há muito espaçamento.

Na próxima seção, podemos aproveitar o módulo Beautiful Soup para trabalhar com esses dados textuais de uma forma mais amigável.

## Vasculhando uma Página Web com Beautiful Soup

A biblioteca Beautiful Soup cria uma árvore de análise a partir de documentos HTML e XML analisados (incluindo documentos com tags não fechadas ou [tag soup](https://en.wikipedia.org/wiki/Tag_soup) e outras marcações malformadas). Essa funcionalidade tornará o texto da página web mais legível do que o que vimos no módulo Requests.

Para começar, vamos importar o Beautiful Soup dentro do console Python:

    from bs4 import BeautifulSoup
    

Em seguida, vamos executar o documento `page.text` através do módulo para nos dar um objeto `BeautifulSoup` - ou seja, uma árvore de análise desta página analisada que obteremos ao executar o [`html.parser`](https://docs.python.org/3/library/html.parser.html) interno do Python em cima do HTML. O objeto construído representa o documento `mockturtle.html` como uma estrutura de dados aninhada. Isto é atribuído à variável `soup`.

    soup = BeautifulSoup(page.text, 'html.parser')
    

Para mostrar o conteúdo da página no terminal, podemos imprimi-lo com o método `prettify()` para transformar a árvore de análise Beautiful Soup em uma string Unicode bem formatada.

    print(soup.prettify())

Isso irá renderizar cada tag HTML em sua própria linha:

    Output<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html lang="en-US" xml:lang="en-US" xmlns="http://www.w3.org/1999/xhtml">
     <head>
      <meta content="text/html; charset=utf-8" http-equiv="content-type"/>
      <title>
       Turtle Soup
      </title>
     </head>
     <body>
      <h1>
       Turtle Soup
      </h1>
      <p class="verse" id="first">
       Beautiful Soup, so rich and green,
       <br/>
       Waiting in a hot tureen!
       <br/>
       Who for such dainties would not stoop?
       <br/>
       Soup of the evening, beautiful Soup!
     ...
    </html>

Na saída acima, podemos ver que há uma tag por linha e também que as tags estão aninhadas devido ao esquema de árvore utilizado pelo Beautiful Soup.

## Encontrando Instâncias de uma Tag

Podemos extrair uma única tag de uma página usando o método `find_all` do Beautiful Soup. Isso irá retornar todas as instâncias de uma dada tag dentro de um documento.

    soup.find_all('p')

A execução desse método em nosso objeto retorna o texto completo da música juntamente com as tags `<p>` relevantes, e quaisquer tags contidas nessa tag solicitada, que aqui inclui as tags de quebra de linha `<br/>`:

    Output[<p class="verse" id="first">Beautiful Soup, so rich and green,<br/>
      Waiting in a hot tureen!<br/>
      Who for such dainties would not stoop?<br/>
      Soup of the evening, beautiful Soup!<br/>
      Soup of the evening, beautiful Soup!<br/></p>, <p class="chorus" id="second">Beau--ootiful Soo--oop!<br/>
    ...
      Beau--ootiful Soo--oop!<br/>
      Soo--oop of the e--e--evening,<br/>
      Beautiful, beauti--FUL SOUP!<br/></p>]
    

Você notará na saída acima que os dados estão contidos entre colchetes `[]`. Isso significa que é um [tipo de dado de lista](understanding-lists-in-python-3) do Python.

Devido a ser uma lista, podemos chamar um item particular dentro dela (por exemplo, o terceiro elemento `<p>`), e utilizar o método `get_text()` para extrair todo o texto de dentro dessa tag:

    soup.find_all('p')[2].get_text()

A saída que recebemos será o que está no terceiro elemento `<p>`, nesse caso:

    Output'Beautiful Soup! Who cares for fish,\n Game or any other dish?\n Who would not give all else for two\n Pennyworth only of Beautiful Soup?\n Pennyworth only of beautiful Soup?'

Note que as quebras de linha `\n` também são mostradas na string retornada acima.

## Encontrando Tags por Classe e ID

Os elementos HTML que se referem a seletores CSS, como classe e ID, podem ser úteis de se observar ao se trabalhar com dados da web utilizando Beautiful Soup. Podemos focar em classes e IDs específicos utilizando o método `find_all()` e passando as strings de classe e ID como argumentos.

Primeiro, vamos encontrar todas as instâncias da classe `chorus`. No Beautiful Soup vamos atribuir a string para a classe ao argumento da palavra-chave `class_`:

    soup.find_all(class_='chorus')

Quando executarmos a linha acima, receberemos a seguinte lista como saída:

    Output[<p class="chorus" id="second">Beau--ootiful Soo--oop!<br/>
      Beau--ootiful Soo--oop!<br/>
      Soo--oop of the e--e--evening,<br/>
      Beautiful, beautiful Soup!<br/></p>, <p class="chorus" id="fourth">Beau--ootiful Soo--oop!<br/>
      Beau--ootiful Soo--oop!<br/>
      Soo--oop of the e--e--evening,<br/>
      Beautiful, beauti--FUL SOUP!<br/></p>]
    

As duas seções taggeadas com `<p>` com a classe de `chorus` foram impressas no terminal.

Podemos também especificar que queremos pesquisar pela classe `chorus` somente dentro das tags `<p>`, caso seja usado por mais de uma tag:

    soup.find_all('p', class_='chorus')

A execução da linha acima produzirá a mesma saída de antes.

Também podemos utilizar Beautiful Soup para focar em IDs associados com tags HTML. Neste caso iremos atribuir a string `'third'` ao argumento da palavra-chave `id`:

    soup.find_all(id='third')

Ao executarmos a linha acima, receberemos a seguinte saída:

    Output[<p class="verse" id="third">Beautiful Soup! Who cares for fish,<br/>
      Game or any other dish?<br/>
      Who would not give all else for two<br/>
      Pennyworth only of Beautiful Soup?<br/>
      Pennyworth only of beautiful Soup?<br/></p>]
    

O texto associado com a tag `<p>` com o id `third` é impresso no terminal juntamente com as tags relevantes.

## Conclusão

Este tutorial levou você a recuperar uma página web com o módulo Requests no Python e a fazer um scraping preliminar dos dados textuais dessa página para obter uma compreensão da biblioteca Beautiful Soup.

A partir daqui, você pode seguir e criar um programa de web scraping que criará um arquivo CSV a partir de dados coletados da web, seguindo o tutorial [How To Scrape Web Pages with Beautiful Soup and Python 3](how-to-scrape-web-pages-with-beautiful-soup-and-python-3).
