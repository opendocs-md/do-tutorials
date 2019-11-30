---
author: Justin Duke
date: 2018-07-02
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-fazer-crawling-em-uma-pagina-web-com-scrapy-e-python-3-pt
---

# Como Fazer Crawling em uma Página Web com Scrapy e Python 3

### Introdução

Web scraping, às vezes chamado de web crawling ou web spidering, ou “programaticamente revisar uma coleção de páginas web e fazer uma extração de dados”, é uma ferramenta poderosa para o trabalho com dados na web.

Com um web scraper, você pode minerar dados sobre um conjunto de produtos, obter uma grande massa de texto ou dados quantitativos para brincar, obter dados de um site sem uma API oficial, ou apenas satisfazer sua própria curiosidade pessoal.

Neste tutorial, você aprenderá sobre os fundamentos do processo de scraping e spidering ao explorar um divertido conjunto de dados. Vamos utilizar o [BrickSet](http://brickset.com/), um site gerenciado pela comunidade que contém informações sobre conjuntos LEGO. Ao final deste tutorial, você terá um web scraper em Python totalmente funcional que percorre uma série de páginas no Brickset e extrai dados sobre conjuntos LEGO de cada página, exibindo os dados em sua tela.

O scraper será facilmente expansível para que você possa usá-lo como uma base para seus próprios projetos, extraindo dados da web.

## Pré-requisitos

Para concluir este tutorial, você precisará de um ambiente de desenvolvimento local para o Python 3. Você pode seguir o tutorial [How To Install and Set Up a Local Programming Environment for Python 3](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3) para configurar tudo o que você precisa.

## Passo 1 — Criando um Scraper Básico

O scraping é um processo em dois passos:

1. Você encontra e faz o download de páginas web sistematicamente.
2. Você pega essas páginas web e extrai informações delas.

Ambos os passos podem ser implementados de várias maneiras em várias linguagens.

Você pode construir um scraper a partir do zero usando [módulos](how-to-import-modules-in-python-3) ou bibliotecas fornecidos pela sua linguagem de programação, porém você tem que lidar com algumas dores de cabeça em potencial à medida que seu scraper se torna mais complexo. Por exemplo, você precisará lidar com a concorrência para poder fazer crawling em mais de uma página por vez. Você provavelmente vai querer descobrir como transformar seus dados extraídos em diferentes formatos, como CSV, XML ou JSON. E às vezes você terá que lidar com sites que exigem configurações e padrões de acesso específicos.

Você terá mais sorte se construir seu scraper em cima de uma biblioteca existente que lide com esses problemas para você. Para este tutorial, vamos usar Python e [Scrapy](http://doc.scrapy.org/en/1.1/intro/overview.html) para construir nosso scraper.

O Scrapy é uma das bibliotecas de scraping mais populares e poderosas do Python; ele usa uma abordagem de “pilhas incluídas” para scraping, o que significa que ele lida com muitas das funcionalidades comuns que todos os scrapers precisam para que os desenvolvedores não tenham que reinventar a roda a cada vez. Isso torna o scraping um processo rápido e divertido!

O Scrapy, como a maioria dos pacotes do Python, está no PyPI (também conhecido como `pip`). PyPI, o Índice de Pacotes Python, é um repositório comunitário de todo o software Python publicado.

Se você tem uma instalação do Python como a descrita no pré-requisito para este tutorial, você já tem o `pip` instalado em sua máquina, assim você pode instalar o Scrapy com o seguinte comando:

    pip install scrapy

Se você tiver problemas com a instalação, ou se quiser instalar o Scrapy sem usar o `pip`, confira os [documentos oficiais de instalação](https://doc.scrapy.org/en/1.1/intro/install.html).

Com o Scrapy instalado, vamos criar uma nova pasta para o nosso projeto. Você pode fazer isso no terminal executando:

    mkdir brickset-scraper

Agora, navegue até o novo diretório que você acabou de criar:

    cd brickset-scraper

Em seguida, crie um novo arquivo Python para o nosso scraper chamado `scraper.py`. Colocaremos todo o nosso código neste arquivo para este tutorial. Você pode criar este arquivo no terminal com o comando `touch`, assim:

    touch scraper.py

Ou você pode criar o arquivo usando o editor de texto ou o gerenciador gráfico de arquivos.

Vamos começar fazendo um scraper muito básico que usa o Scrapy como base. Para fazer isso, criaremos uma [classe Python](how-to-construct-classes-and-define-objects-in-python-3) que é uma subclasse de `scrapy.Spider`, uma classe básica de spider fornecida pelo Scrapy. Esta classe terá dois atributos obrigatórios:

- `name` - apenas um nome para o spider.
- `start_urls` - uma [lista](understanding-lists-in-python-3) de URLs a partir da qual você começa a fazer crawling. Começaremos com uma URL.

Abra o arquivo `scrapy.py` em seu editor de texto e adicione este código para criar o spider básico:

scraper.py

    
    import scrapy
    
    
    class BrickSetSpider(scrapy.Spider):
        name = "brickset_spider"
        start_urls = ['http://brickset.com/sets/year-2016']

Vamos dividir isso explicando linha por linha:

Primeiro, [importamos](how-to-import-modules-in-python-3) o `scrapy` para que possamos usar as classes que o pacote fornece.

Em seguida, pegamos a classe `Spider` fornecida pelo Scrapy e criamos uma _subclasse_ chamada `BrickSetSpider`. Pense em uma subclasse como uma forma mais especializada de sua classe pai. A subclasse `Spider` possui métodos e comportamentos que definem como seguir URLs e extrair dados das páginas que encontrar, mas não sabe onde procurar ou quais dados procurar. Ao torná-lo uma subclasse , podemos fornecer a ele essa informação.

Então damos ao spider o nome `brickset_spider`.

Por fim, damos ao nosso scraper uma única URL para começar: [http://brickset.com/sets/year-2016](http://brickset.com/sets/year-2016). Se você abrir essa URL no seu navegador, ela o levará a uma página de resultados de pesquisa, mostrando a primeira de muitas páginas contendo conjuntos LEGO.

Agora vamos testar o scraper. Você normalmente executa arquivos Python executando um comando como `python caminho/para/arquivo.py`. No entanto, o Scrapy vem com [sua própria interface de linha de comando](https://doc.scrapy.org/en/latest/topics/commands.html) para agilizar o processo de iniciar um scraper. Inicie seu scraper com o seguinte comando:

    scrapy runspider scraper.py

Você verá algo assim:

    Output2016-09-22 23:37:45 [scrapy] INFO: Scrapy 1.1.2 started (bot: scrapybot)
    2016-09-22 23:37:45 [scrapy] INFO: Overridden settings: {}
    2016-09-22 23:37:45 [scrapy] INFO: Enabled extensions:
    ['scrapy.extensions.logstats.LogStats',
     'scrapy.extensions.telnet.TelnetConsole',
     'scrapy.extensions.corestats.CoreStats']
    2016-09-22 23:37:45 [scrapy] INFO: Enabled downloader middlewares:
    ['scrapy.downloadermiddlewares.httpauth.HttpAuthMiddleware',
     ...
     'scrapy.downloadermiddlewares.stats.DownloaderStats']
    2016-09-22 23:37:45 [scrapy] INFO: Enabled spider middlewares:
    ['scrapy.spidermiddlewares.httperror.HttpErrorMiddleware',
     ...
     'scrapy.spidermiddlewares.depth.DepthMiddleware']
    2016-09-22 23:37:45 [scrapy] INFO: Enabled item pipelines:
    []
    2016-09-22 23:37:45 [scrapy] INFO: Spider opened
    2016-09-22 23:37:45 [scrapy] INFO: Crawled 0 pages (at 0 pages/min), scraped 0 items (at 0 items/min)
    2016-09-22 23:37:45 [scrapy] DEBUG: Telnet console listening on 127.0.0.1:6023
    2016-09-22 23:37:47 [scrapy] DEBUG: Crawled (200) <GET http://brickset.com/sets/year-2016> (referer: None)
    2016-09-22 23:37:47 [scrapy] INFO: Closing spider (finished)
    2016-09-22 23:37:47 [scrapy] INFO: Dumping Scrapy stats:
    {'downloader/request_bytes': 224,
     'downloader/request_count': 1,
     ...
     'scheduler/enqueued/memory': 1,
     'start_time': datetime.datetime(2016, 9, 23, 6, 37, 45, 995167)}
    2016-09-22 23:37:47 [scrapy] INFO: Spider closed (finished)

É um monte de saída, então vamos dividi-la.

- O scraper inicializou e carregou componentes e extensões adicionais que ele precisa para lidar com a leitura de dados das URLs.
- Ele utilizou a URL que fornecemos na lista `start_urls` e pegou o HTML, da mesma forma que seu navegador faria.
- Ele repassou aquele HTML ao método `parse`, que não faz nada por padrão. Como nunca escrevemos nosso próprio método `parse`, o spider finaliza sem fazer qualquer trabalho.

Agora vamos extrair alguns dados da página.

## Passo 2 — Extraindo Dados de Uma Página

Criamos um programa muito básico que baixa uma página, mas ele não faz qualquer scraping ou spidering ainda. Vamos dar-lhe alguns dados para extrair.

Se você olhar para [a página que queremos fazer o scraping](http://brickset.com/sets/year-2016), você verá que ela tem a seguinte estrutura:

- Há um cabeçalho que está presente em todas as páginas.
- Há alguns dados de pesquisa de nível superior, incluindo o número de correspondências, que é o que estamos procurando, e os breadcrumbs de navegação do site.
- Em seguida, há os próprios conjuntos, exibidos no que parece ser uma tabela ou uma lista ordenada. Cada conjunto tem um formato similar.

Ao escrever um scraper, é uma boa ideia olhar para o fonte do arquivo HTML e familiarizar-se com a estrutura. Então aqui está ele, com algumas coisas removidas para melhorar a legibilidade:

    brickset.com/sets/year-2016<body>
      <section class="setlist">
        <article class='set'>
          <a class="highslide plain mainimg" href=
          "http://images.brickset.com/sets/images/10251-1.jpg?201510121127"
          onclick="return hs.expand(this)"><img src=
          "http://images.brickset.com/sets/small/10251-1.jpg?201510121127"
          title="10251-1: Brick Bank"></a>
          <div class="highslide-caption">
            <h1><a href='/sets/10251-1/Brick-Bank'>Brick Bank</a></h1>
            <div class='tags floatleft'>
              <a href='/sets/10251-1/Brick-Bank'>10251-1</a> <a href=
              '/sets/theme-Advanced-Models'>Advanced Models</a> <a class=
              'subtheme' href=
              '/sets/theme-Advanced-Models/subtheme-Modular-Buildings'>Modular
              Buildings</a> <a class='year' href=
              '/sets/theme-Advanced-Models/year-2016'>2016</a>
            </div>
            <div class='floatright'>
              &copy;2016 LEGO Group
            </div>
            <div class="pn">
              <a href="#" onclick="return hs.previous(this)" title=
              "Previous (left arrow key)">&#171; Previous</a> <a href="#"
              onclick="return hs.next(this)" title=
              "Next (right arrow key)">Next &#187;</a>
            </div>
          </div>
          ...
        </article>
        <article class='set'>
    
          ...
    
        </article>
    </section>
    </body>

Fazer scraping nessa página é um processo em dois passos:

1. Primeiro, pegue cada conjunto LEGO procurando as partes da página que possuem os dados que queremos.
2. Depois, para cada conjunto, pegue os dados que queremos dele, puxando os dados fora das tags HTML.

O `scrapy` pega os dados beseado nos _seletores_ que fornecemos. Seletores são padrões que podemos utilizar para encontrar um ou mais elementos em uma página para que possamos então, trabalhar com os dados dentro do elemento. O `scrapy` suporta tanto os seletores CSS quanto os seletores [XPath](https://en.wikipedia.org/wiki/XPath).

Vamos utilizar seletores CSS por agora, uma vez que o CSS é a opção mais fácil e possui um ajuste perfeito para encontrar todos os conjuntos na página. Se você olhar o HTML da página, você verá que cada conjunto é especificado com a classe `set`. Já que estamos procurando por uma classe, usaríamos `.set` para nosso seletor de CSS. Tudo o que temos a fazer é passar esse seletor para o objeto `response`, dessa forma:

scraper.py

    
    class BrickSetSpider(scrapy.Spider):
        name = "brickset_spider"
        start_urls = ['http://brickset.com/sets/year-2016']
    
        def parse(self, response):
            SET_SELECTOR = '.set'
            for brickset in response.css(SET_SELECTOR):
                pass

Este código pega todos os conjuntos na página e faz um loop sobre eles para extrair os dados. Agora vamos extrair os dados desses conjuntos para que possamos exibi-los.

Um outra olhada no [fonte](view-source:brickset.com/sets/year-2016) da página que estamos analisando nos diz que o nome e cada conjunto está armazenado dentro de uma tag `a` dentro de uma tag `h1` para cada conjunto.

    brickset.com/sets/year-2016<h1><a href='/sets/10251-1/Brick-Bank'>Brick Bank</a></h1>

O objeto `brickset` no qual estamos fazendo o loop tem seu próprio método`css`, então podemos passar um seletor para localizar elementos filhos. Modifique seu código da seguinte maneira para localizar o nome do conjunto e exibi-lo:

scraper.py

    
    class BrickSetSpider(scrapy.Spider):
        name = "brickset_spider"
        start_urls = ['http://brickset.com/sets/year-2016']
    
        def parse(self, response):
            SET_SELECTOR = '.set'
            for brickset in response.css(SET_SELECTOR):
    
                <^>NAME_SELECTOR = 'h1 a ::text'
                yield {
                    'name': brickset.css(NAME_SELECTOR).extract_first(),
                }<^>

**Nota:** A vírgula final depois de `extract_first()` não é um erro de digitação. Vamos adicionar mais coisas a esta seção em breve, então deixamos a vírgula lá para facilitar a adição nessa seção posteriormente.

Você notará duas coisas acontecendo neste código:

- Acrescentamos `::text` ao nosso seletor para o nome. Esse é um pseudo-seletor de CSS que busca o texto dentro da tag `a` em vez da própria tag.
- Chamamos `extract_first()` no objeto retornado por `brickset.css(NAME_SELECTOR)` porque queremos apenas o primeiro elemento que corresponda ao seletor. Isto nos dá uma [string](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3), em vez de um lista de elementos.

Salve o arquivo e execute o scraper novamente:

    scrapy runspider scraper.py

Desta vez você verá os nomes dos conjuntos aparecerem na saída:

    Output...
    [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'name': 'Brick Bank'}
    [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'name': 'Volkswagen Beetle'}
    [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'name': 'Big Ben'}
    [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'name': 'Winter Holiday Train'}
    ...

Vamos continuar expandindo isso adicionando novos seletores para imagens, peças e figuras em miniatura, ou _minifigs_ que vêm com um conjunto.

Dê uma nova olhada no HTML para um conjunto específico

    brickset.com/sets/year-2016<article class="set">
      <a class="highslide plain mainimg" href="http://images.brickset.com/sets/images/10251-1.jpg?201510121127" onclick="return hs.expand(this)">
        <img src="http://images.brickset.com/sets/small/10251-1.jpg?201510121127" title="10251-1: Brick Bank"></a>
      ...
      <div class="meta">
        <h1><a href="/sets/10251-1/Brick-Bank"><span>10251:</span> Brick Bank</a> </h1>
        ...
        <div class="col">
          <dl>
            <dt>Pieces</dt>
            <dd><a class="plain" href="/inventories/10251-1">2380</a></dd>
            <dt>Minifigs</dt>
            <dd><a class="plain" href="/minifigs/inset-10251-1">5</a></dd>
            ...
          </dl>
        </div>
        ...
      </div>
    </article>

Podemos ver algumas coisas ao examinar este código:

- A imagem para este conjunto está armazenada no atributo `src` de uma tag `img` dentro de uma tag `a` no início do conjunto. Podemos utilizar outro seletor CSS para buscar esse valor exatamente como fizemos quando pegamos o nome de cada conjunto.
- Obter o número de peças é um pouco mais complicado. Há uma tag `dt` que contém o texto `Pieces`, e depois uma tag `dd` que a segue que contém o número real de peças. Utilizaremos o [XPath](https://en.wikipedia.org/wiki/XPath), uma linguagem de consulta para analisar XML, para pegar isto, porque isto é muito complexo para ser representado usando seletores CSS.
- Obter o número de minifigs em um conjunto é semelhante a obter o número de peças. Há uma tag `dt` que contém o texto `Minifigs`, seguida de uma tag `dd` logo depois disso, com o número de peças.

Então, vamos modificar o scraper para obter esta nova informação:

scraper.py

    
    class BrickSetSpider(scrapy.Spider):
        name = 'brick_spider'
        start_urls = ['http://brickset.com/sets/year-2016']
    
        def parse(self, response):
            SET_SELECTOR = '.set'
            for brickset in response.css(SET_SELECTOR):
    
                NAME_SELECTOR = 'h1 a ::text'
                PIECES_SELECTOR = './/dl[dt/text() = "Pieces"]/dd/a/text()'
                MINIFIGS_SELECTOR = './/dl[dt/text() = "Minifigs"]/dd[2]/a/text()'
                IMAGE_SELECTOR = 'img ::attr(src)'
                yield {
                    'name': brickset.css(NAME_SELECTOR).extract_first(),
                    'pieces': brickset.xpath(PIECES_SELECTOR).extract_first(),
                    'minifigs': brickset.xpath(MINIFIGS_SELECTOR).extract_first(),
                    'image': brickset.css(IMAGE_SELECTOR).extract_first(),
                }

Salve as suas alterações e execute o scraper novamente:

    scrapy runspider scraper.py

Agora você verá esses novos dados na saída do programa:

Output

    2016-09-22 23:52:37 [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    ^>{'minifigs': '5', 'pieces': '2380', 'name': 'Brick Bank', 'image': 'http://images.brickset.com/sets/small/10251-1.jpg?201510121127'}<^>
    2016-09-22 23:52:37 [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'minifigs': None, 'pieces': '1167', 'name': 'Volkswagen Beetle', 'image': 'http://images.brickset.com/sets/small/10252-1.jpg?201606140214'}
    2016-09-22 23:52:37 [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'minifigs': None, 'pieces': '4163', 'name': 'Big Ben', 'image': 'http://images.brickset.com/sets/small/10253-1.jpg?201605190256'}
    2016-09-22 23:52:37 [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'minifigs': None, 'pieces': None, 'name': 'Winter Holiday Train', 'image': 'http://images.brickset.com/sets/small/10254-1.jpg?201608110306'}
    2016-09-22 23:52:37 [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'minifigs': None, 'pieces': None, 'name': 'XL Creative Brick Box', 'image': '/assets/images/misc/blankbox.gif'}
    2016-09-22 23:52:37 [scrapy] DEBUG: Scraped from <200 http://brickset.com/sets/year-2016>
    {'minifigs': None, 'pieces': '583', 'name': 'Creative Building Set', 'image': 'http://images.brickset.com/sets/small/10702-1.jpg?201511230710'}

Agora vamos transformar esse scraper em um spider que segue links.

## Passo 3 — Fazendo Crawling em Múltiplas Páginas

Extraímos com sucesso os dados dessa página inicial, mas não estamos avançando para ver o restante dos resultados. O objetivo de um spider é detectar e percorrer links para outras páginas e coletar dados dessas páginas também.

Você vai notar que a parte superior e inferior de cada página tem um pequeno caracter de maior que (`>`), que leva até a próxima página de resultados. Aqui está o HTML para isso:

    [seconday_label brickset.com/sets/year-2016]
    <ul class="pagelength">
    
      ...
    
      <li class="next">
        <a href="http://brickset.com/sets/year-2017/page-2">&#8250;</a>
      </li>
      <li class="last">
        <a href="http://brickset.com/sets/year-2016/page-32">&#187;</a>
      </li>
    </ul>
    

Como você pode ver, há uma tag `li` com a classe `next`, e dentro dessa tag, há uma tag `a` com um link para a próxima página. Tudo que temos a fazer é dizer ao scraper para seguir aquele link se ele existir.

Modifique o seu código como a seguir:

scraper.py

    
    class BrickSetSpider(scrapy.Spider):
        name = 'brick_spider'
        start_urls = ['http://brickset.com/sets/year-2016']
    
        def parse(self, response):
            SET_SELECTOR = '.set'
            for brickset in response.css(SET_SELECTOR):
    
                NAME_SELECTOR = 'h1 a ::text'
                PIECES_SELECTOR = './/dl[dt/text() = "Pieces"]/dd/a/text()'
                MINIFIGS_SELECTOR = './/dl[dt/text() = "Minifigs"]/dd[2]/a/text()'
                IMAGE_SELECTOR = 'img ::attr(src)'
                yield {
                    'name': brickset.css(NAME_SELECTOR).extract_first(),
                    'pieces': brickset.xpath(PIECES_SELECTOR).extract_first(),
                    'minifigs': brickset.xpath(MINIFIGS_SELECTOR).extract_first(),
                    'image': brickset.css(IMAGE_SELECTOR).extract_first(),
                }
    
            NEXT_PAGE_SELECTOR = '.next a ::attr(href)'
            next_page = response.css(NEXT_PAGE_SELECTOR).extract_first()
            if next_page:
                yield scrapy.Request(
                    response.urljoin(next_page),
                    callback=self.parse
                )

Primeiro, definimos um seletor para o link “next page”, extraímos a primeira correspondência e verificamos se ela existe. O `scrapy.Request` é um valor que retornamos dizendo “Ei, rastreie esta página”, e `callback=self.parse` diz “uma vez que você tenha obtido o HTML desta página, retorne-o para este método para que possamos analisá-lo, extrair os dados e encontrar a próxima página.”

Isso significa que, quando formos para a próxima página, procuraremos um link para a próxima página lá, e nessa página procuraremos um link para a próxima página, e assim por diante, até que não encontremos um link para a próxima página. Esta é a peça-chave do web scraping: encontrar e seguir links. Neste exemplo, que é muito linear; uma página tem um link para a próxima página até que tenhamos acessado a última página, mas você pode seguir links para tags ou outros resultados de pesquisa ou qualquer outro URL que desejar.

Agora, se você salvar seu código e executar o spider novamente, verá que ele não interrompe ao percorrer a primeira página de conjuntos. Ele continua passando por todas as 779 correspondências nas 23 páginas! Em uma visão macro das coisas, não é uma grande quantidade de dados, mas agora você conhece o processo pelo qual você encontra automaticamente novas páginas para fazer o scraping.

Aqui está o nosso código completo para este tutorial, utilizando o highlighting específico do Python:

scraper.py

    
    import scrapy
    
    
    class BrickSetSpider(scrapy.Spider):
        name = 'brick_spider'
        start_urls = ['http://brickset.com/sets/year-2016']
    
        def parse(self, response):
            SET_SELECTOR = '.set'
            for brickset in response.css(SET_SELECTOR):
    
                NAME_SELECTOR = 'h1 a ::text'
                PIECES_SELECTOR = './/dl[dt/text() = "Pieces"]/dd/a/text()'
                MINIFIGS_SELECTOR = './/dl[dt/text() = "Minifigs"]/dd[2]/a/text()'
                IMAGE_SELECTOR = 'img ::attr(src)'
                yield {
                    'name': brickset.css(NAME_SELECTOR).extract_first(),
                    'pieces': brickset.xpath(PIECES_SELECTOR).extract_first(),
                    'minifigs': brickset.xpath(MINIFIGS_SELECTOR).extract_first(),
                    'image': brickset.css(IMAGE_SELECTOR).extract_first(),
                }
    
            NEXT_PAGE_SELECTOR = '.next a ::attr(href)'
            next_page = response.css(NEXT_PAGE_SELECTOR).extract_first()
            if next_page:
                yield scrapy.Request(
                    response.urljoin(next_page),
                    callback=self.parse
                )

## Conclusão

Neste tutorial, você construiu um spider totalmente funcional que extrai dados de páginas web em menos de trinta linhas de código. É um ótimo começo, mas há muitas coisas divertidas que você pode fazer com esse spider. Aqui estão algumas maneiras de expandir o código que você escreveu. Eles vão te dar alguns dados para a prática do scrap.

1. No momento, estamos analisando apenas os resultados de 2016, como você deve ter percebido da parte `2016` de `http://brickset.com/sets/year-2016` - Como você faria o crawling dos resultados de outros anos?
2. Há um preço de varejo incluído na maioria dos conjuntos. Como você extrai os dados dessa célula? Como você obteria um número bruto disso? **Dica:** você encontrará os dados em um `dt` assim como o número de peças e minifigs.
3. A maioria dos resultados possui tags que especificam dados semânticos sobre os conjuntos ou o seu contexto. Como fazer crawling neles, já que existem várias tags para um único conjunto?

Isso deve ser suficiente para você pensar e experimentar. Se precisar de mais informações sobre o Scrapy, verifique [a documentação ofical do Scrapy](https://scrapy.org/doc/). Para mais informações sobre como trabalhar com dados da web, veja nosso tutorial sobre [“Como fazer scrapping em Páginas Web com Beautiful Soup e Python 3”](how-to-scrape-web-pages-with-beautiful-soup-and-python-3).
