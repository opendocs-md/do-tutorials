---
author: Mark Drake
date: 2019-01-11
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/uma-introducao-as-consultas-no-mysql-pt
---

# Uma Introdução às consultas no MySQL

### Introdução

Bancos de dados são um componente chave em muitos websites e aplicações, e estão no centro de como os dados são armazenados e trocados pela Internet. Um dos aspectos mais importantes do gerenciamento de banco de dados é a prática de recuperar dados de um banco de dados, seja em uma base ad hoc ou parte de um processo codificado em um aplicativo. Existem várias maneiras de recuperar informações de um banco de dados, mas um dos métodos mais utilizados é realizado através do envio de _consultas_ pela linha de comandos.

Em sistemas de gerenciamento de bancos de dados relacionais, uma consulta é qualquer comando usado para recuperar dados de uma tabela. Na Linguagem de Consulta Estruturada ou Structured Query Language (SQL), consultas são feitas quase sempre usando o comando `SELECT`.

Neste guia, discutiremos a sintaxe básica das consultas SQL, bem como algumas das funções e operadores mais comumente empregados. Vamos também praticar a criação de consultas SQL usando alguns dados de amostra em um banco de dados MySQL.

O [MySQL](https://www.mysql.com/) é um sistema de gerenciamento de banco de dados relacional open-source. Sendo um dos bancos de dados SQL mais amplamente implantados, o MySQL prioriza velocidade, confiabilidade e usabilidade. Em geral, ele segue o padrão SQL ANSI, embora haja alguns casos em que o MySQL executa operações de maneira diferente do padrão reconhecido.

## Pré-requisitos

Em geral, os comandos e conceitos apresentados neste guia podem ser usados em qualquer sistema operacional baseado em Linux executando qualquer software de banco de dados SQL. No entanto, ele foi escrito especificamente com um servidor Ubuntu 18.04 executando o MySQL em mente. Para configurar isso, você precisará do seguinte:

- Uma máquina Ubuntu 18.04 com um usuário não-root com privilégios sudo. Isso pode ser configurado usando o nosso tutorial [Configuração Inicial de servidor com Ubuntu 18.04](configuracao-inicial-de-servidor-com-ubuntu-18-04-pt). 

- MySQL instalado na máquina. Nosso guia sobre [Como Instalar o MySQL no Ubuntu 18.04](como-instalar-o-mysql-no-ubuntu-18-04-pt) pode ajudá-lo a configurar isso.

Com esta configuração pronta, podemos começar o tutorial.

## Criando um Banco de Dados de Amostra

Antes de começarmos a fazer consultas no SQL, vamos primeiro criar um banco de dados e algumas tabelas, em seguida, preencher essas tabelas com alguns dados de amostra. Isso permitirá que você ganhe experiência prática quando começar a fazer consultas mais tarde.

Para o banco de dados de amostra que usaremos ao longo deste guia, imagine o seguinte cenário:

_Você e vários de seus amigos celebram seus aniversários juntos. Em cada ocasião, os membros do grupo vão para a pista de boliche local, participam de um torneio amistoso e, em seguida, todos vão para sua casa, onde você prepara a refeição favorita do aniversariante._

_Agora que essa tradição já dura algum tempo, você decidiu começar a acompanhar os registros desses torneios. Além disso, para tornar o planejamento das refeições mais fácil, você decide criar um registro dos aniversários dos seus amigos e de suas entradas, acompanhamentos e sobremesas favoritas. Em vez de manter essas informações em um livro físico, você decide exercitar suas habilidades de banco de dados gravando-as em um banco de dados MySQL._

Para começar, abra um prompt de MySQL como seu usuário **root** do MySQL:

    sudo mysql

**Note:** Se você seguiu o pré-requisito do tutorial sobre [Como Instalar o MySQL no Ubuntu 18.04](como-instalar-o-mysql-no-ubuntu-18-04-pt), você pode ter configurado seu usuário root para autenticar usando uma senha. Neste caso, você irá se conectar ao prompt do MySQL com o seguinte comando:

    mysql -u root -p

Em seguida, crie o banco de dados executando:

    CREATE DATABASE `aniversarios`;

Depois, selecione este banco de dados digitando:

    USE aniversarios;

A seguir, crie duas tabelas dentro desse banco de dados. Vamos utilizar a primeira tabela para acompanhar os registros dos seus amigos na pista de boliche. O seguinte comando criará uma tabela chamada `torneios` com colunas para o `nome` de cada um de seus amigos, o número de torneios que eles ganharam (`vitorias`), a `melhor` pontuação deles em todo o tempo, e que tamanho de sapato de boliche eles usam (`tamanho`):

    CREATE TABLE torneios ( 
    nome varchar(30), 
    vitorias real, 
    melhor real, 
    tamanho real 
    );

Depois de executar o comando `CREATE TABLE` e preenchê-lo com títulos das colunas, você receberá a seguinte saída:

    OutputQuery OK, 0 rows affected (0.00 sec)

Preencha a tabela `torneios` com alguns dados de amostra:

    INSERT INTO torneios (nome, vitorias, melhor, tamanho) 
    VALUES ('Dolly', '7', '245', '8.5'), 
    ('Etta', '4', '283', '9'), 
    ('Irma', '9', '266', '7'), 
    ('Barbara', '2', '197', '7.5'), 
    ('Gladys', '13', '273', '8');

Você receberá uma saída como esta:

    OutputQuery OK, 5 rows affected (0.01 sec)
    Records: 5 Duplicates: 0 Warnings: 0

Depois disso, crie outra tabela dentro do mesmo banco de dados que usaremos para armazenar informações sobre as refeições de aniversário favoritas dos seus amigos. O seguinte comando cria uma tabela chamada `refeicoes` com colunas para o `nome` de cada um dos seus amigos, a `data_nascimento`, a `entrada` favorita de cada um, o `acompanhamento` preferido, e a `sobremesa` favorita:

    CREATE TABLE refeicoes ( 
    nome varchar(30), 
    data_nascimento date, 
    entrada varchar(30), 
    acompanhamento varchar(30), 
    sobremesa varchar(30) 
    );

Da mesma forma, para esta tabela, você receberá um feedback confirmando que o comando foi executado com sucesso:

    OutputQuery OK, 0 rows affected (0.01 sec)

Preencha esta tabela com alguns dados de amostra também:

    INSERT INTO refeicoes (nome, data_nascimento, entrada, acompanhamento, sobremesa) 
    VALUES ('Dolly', '1946-01-19', 'steak', 'salad', 'cake'), 
    ('Etta', '1938-01-25', 'chicken', 'fries', 'ice cream'), 
    ('Irma', '1941-02-18', 'tofu', 'fries', 'cake'), 
    ('Barbara', '1948-12-25', 'tofu', 'salad', 'ice cream'), 
    ('Gladys', '1944-05-28', 'steak', 'fries', 'ice cream');

    OutputQuery OK, 5 rows affected (0.00 sec)
    Records: 5 Duplicates: 0 Warnings: 0

Uma vez que esse comando tenha sido concluído com êxito, você acabou de configurar seu banco de dados. A seguir, vamos falar sobre a estrutura básica de comando das consultas `SELECT`.

## Entendendo Comandos SELECT

Conforme mencionado na introdução, consultas SQL quase sempre começam com o comando `SELECT`. `SELECT` é usado em consultas para especificar quais colunas de uma tabela devem ser retornadas no conjunto de resultados ou result-set. As consultas também quase sempre incluem `FROM`, que é usado para especificar qual tabela o comando consultará.

Geralmente, as consultas SQL seguem essa sintaxe:

    SELECT coluna_a_selecionar FROM tabela_a_selecionar WHERE certas_condições_a_aplicar;

A título de exemplo, o seguinte comando retornará a coluna `nome` inteira da tabela `refeicoes`:

    SELECT nome FROM refeicoes;

    [seconday_label Output]
    +---------+
    | nome |
    +---------+
    | Dolly |
    | Etta |
    | Irma |
    | Barbara |
    | Gladys |
    +---------+
    5 rows in set (0.00 sec)

Você pode selecionar várias colunas da mesma tabela, separando seus nomes com uma vírgula, desta forma:

    SELECT nome, data_nascimento FROM refeicoes;

    Output+---------+-----------------+
    | nome | data_nascimento |
    +---------+-----------------+
    | Dolly | 1946-01-19 |
    | Etta | 1938-01-25 |
    | Irma | 1941-02-18 |
    | Barbara | 1948-12-25 |
    | Gladys | 1944-05-28 |
    +---------+-----------------+
    5 rows in set (0.00 sec)

Em vez de nomear uma coluna específica ou um conjunto de colunas, você pode seguir o operador `SELECT` com um asterisco (`*`) que serve como um curinga representando todas as colunas em uma tabela. O seguinte comando retorna todas as colunas da tabela `torneios`:

    SELECT * FROM torneios;

    Output+---------+----------+--------+---------+
    | nome | vitorias | melhor | tamanho |
    +---------+----------+--------+---------+
    | Dolly | 7 | 245 | 8.5 |
    | Etta | 4 | 283 | 9 |
    | Irma | 9 | 266 | 7 |
    | Barbara | 2 | 197 | 7.5 |
    | Gladys | 13 | 273 | 8 |
    +---------+----------+--------+---------+
    5 rows in set (0.00 sec)

`WHERE` é usado em consultas para filtrar registros que atendem a uma condição especificada, e todas as linhas que não atendem a essa condição são eliminadas do resultado. Uma cláusula `WHERE` geralmente segue esta sintaxe:

    . . . WHERE nome_da_coluna operador_de_comparação valor

O operador de comparação em uma cláusula `WHERE` define como a coluna especificada deve ser comparada com o valor. Aqui estão alguns operadores comuns de comparação em SQL:

| **Operador** | **O que ele faz** |
| --- | --- |
| `=` | testa a igualdade |
| `!=` | testa a desigualdade |
| `<` | testa menor que |
| `>` | testa maior que |
| `<=` | testa menor que ou igual a |
| `>=` | testa maior que ou igual a |
| `BETWEEN` | testa se um valor está dentro de um determinado intervalo |
| `IN` | testa se o valor de uma linha está contido em um conjunto de valores especificados |
| `EXISTS` | testa se existem linhas, dadas as condições especificadas |
| `LIKE` | testa se um valor corresponde a uma string especificada |
| `IS NULL` | testa valores `NULL` |
| `IS NOT NULL` | testa todos os valores que não sejam `NULL` |

Por exemplo, se você quiser encontrar o tamanho do sapato de Irma, use a seguinte consulta:

    SELECT tamanho FROM torneios WHERE nome = 'Irma';

    Output+---------+
    | tamanho |
    +---------+
    | 7 |
    +---------+
    1 row in set (0.00 sec)

O SQL permite o uso de caracteres curinga, e eles são especialmente úteis quando usados em cláusulas `WHERE`. Os sinais de porcentagem (`%`) representam zero ou mais caracteres desconhecidos, e os sublinhados ou underscores (`_`) representam um único caractere desconhecido. Eles são úteis se você estiver tentando encontrar uma informação específica em uma tabela, mas não tiver certeza de qual é exatamente essa informação. Para ilustrar, digamos que você tenha esquecido a entrada favorita de alguns de seus amigos, mas você está certo de que este prato principal começa com um “t”. Você pode encontrar seu nome executando a seguinte consulta:

    SELECT entrada FROM refeicoes WHERE entrada LIKE 't%';

    Output+---------+
    | entrada |
    +---------+
    | tofu |
    | tofu |
    +---------+
    2 rows in set (0.00 sec)

Com base na saída acima, vemos que a entrada que esquecemos é `tofu`.

Pode haver momentos em que você está trabalhando com bancos de dados que possuem colunas ou tabelas com nomes relativamente longos ou difíceis de ler. Nesses casos, você pode tornar esses nomes mais legíveis criando um alias ou apelido com a palavra-chave `AS`. Apelidos criados com `AS` são temporários e existem apenas durante a consulta para a qual eles foram criados:

    SELECT nome AS n, data_nascimento AS d, sobremesa AS s FROM refeicoes;

    Output+---------+------------+-----------+
    | n | d | s |
    +---------+------------+-----------+
    | Dolly | 1946-01-19 | cake |
    | Etta | 1938-01-25 | ice cream |
    | Irma | 1941-02-18 | cake |
    | Barbara | 1948-12-25 | ice cream |
    | Gladys | 1944-05-28 | ice cream |
    +---------+------------+-----------+
    5 rows in set (0.00 sec)

Aqui, dissemos ao SQL para exibir a coluna `nome` como `n`, a coluna `data_nascimento` como `d` e a coluna `sobremesa` como `s`.

Os exemplos que mostramos até aqui incluem algumas das palavras-chave e cláusulas mais usadas em consultas SQL. Elas são úteis para consultas básicas, mas não são úteis se você estiver tentando realizar um cálculo ou derivar um _valor escalar_ (um valor único, em oposição a um conjunto de vários valores diferentes) com base em seus dados. É aqui que as funções de agregação entram em ação.

## Funções de Agregação

Muitas vezes, ao trabalhar com dados, você não necessariamente quer ver os dados em si. Em vez disso, você quer informações _sobre_ os dados. A sintaxe SQL inclui várias funções que permitem interpretar ou executar cálculos em seus dados apenas emitindo uma consulta `SELECT`. Estas são conhecidas como funções de agregação.

A função `COUNT` conta e retorna o número de linhas que correspondem a um determinado critério. Por exemplo, se você quiser saber quantos dos seus amigos preferem o tofu para a entrada de aniversário, você pode fazer essa consulta:

    SELECT COUNT(entrada) FROM refeicoes WHERE entrada = 'tofu';

    Output+----------------+
    | COUNT(entrada) |
    +----------------+
    | 2 |
    +----------------+
    1 row in set (0.00 sec)

A função `AVG` retorna o valor médio (média) de uma coluna. Usando nossa tabela de exemplo, você pode encontrar a melhor pontuação média entre seus amigos com esta consulta:

    SELECT AVG(melhor) FROM torneios;

    Output+-------------+
    | AVG(melhor) |
    +-------------+
    | 252.8 |
    +-------------+
    1 row in set (0.00 sec)

`SUM` é usado para encontrar a soma total de uma determinada coluna. Por exemplo, se você quiser ver quantos jogos você e seus amigos jogaram ao longo dos anos, você pode executar essa consulta:

    SELECT SUM(vitorias) FROM torneios;

    Output+---------------+
    | SUM(vitorias) |
    +---------------+
    | 35 |
    +---------------+
    1 row in set (0.00 sec)

Observe que as funções `AVG` e`SUM` só funcionarão corretamente quando usadas com dados numéricos. Se você tentar usá-los em dados não numéricos, isso resultará em um erro ou apenas `0`, dependendo de qual SGBD você está usando:

    SELECT SUM(entrada) FROM refeicoes;

    Output+--------------+
    | SUM(entrada) |
    +--------------+
    | 0 |
    +--------------+
    1 row in set, 5 warnings (0.00 sec)

`MIN` é usado para encontrar o menor valor dentro de uma coluna especificada. Você poderia usar essa consulta para ver qual o pior registro geral de boliche até agora (em termos de número de vitórias):

    SELECT MIN(vitorias) FROM torneios;

    [secondarylabel Output]
    +---------------+
    | MIN(vitorias) |
    +---------------+
    | 2 |
    +---------------+
    1 row in set (0.00 sec)

Da mesma forma, `MAX` é usado para encontrar o maior valor numérico em uma determinada coluna. A consulta a seguir mostrará o melhor registro geral de boliche:

    SELECT MAX(vitorias) FROM torneios;

    Output+---------------+
    | MAX(vitorias) |
    +---------------+
    | 13 |
    +---------------+
    1 row in set (0.00 sec)

Ao contrário de `SUM` e`AVG`, as funções `MIN` e`MAX` podem ser usadas para tipos de dados numéricos e alfabéticos. Quando executado em uma coluna contendo valores de string, a função `MIN` mostrará o primeiro valor alfabeticamente:

    SELECT MIN(nome) FROM refeicoes;

    Output+-----------+
    | MIN(nome) |
    +-----------+
    | Barbara |
    +-----------+
    1 row in set (0.00 sec)

Da mesma forma, quando executado em uma coluna contendo valores de string, a função `MAX` mostrará o último valor em ordem alfabética:

    SELECT MAX(nome) FROM refeicoes;

    Output+-----------+
    | MAX(nome) |
    +-----------+
    | Irma |
    +-----------+
    1 row in set (0.00 sec)

As funções agregadas têm muitos usos além do que foi descrito nesta seção. Elas são particularmente úteis quando usadas com a cláusula `GROUP BY`, que é abordada na próxima seção junto com várias outras cláusulas de consulta que afetam como os result-sets são classificados.

## Manipulando Saídas da Consulta

Além das cláusulas `FROM` e`WHERE`, existem várias outras cláusulas que são usadas para manipular os resultados de uma consulta `SELECT`. Nesta seção, explicaremos e forneceremos exemplos para algumas das cláusulas de consulta mais comumente usadas.

Uma das cláusulas de consulta mais usadas, além de `FROM` e `WHERE`, é a cláusula `GROUP BY`. Ela é normalmente usada quando você está executando uma função de agregação em uma coluna, mas em relação aos valores correspondentes em outra.

Por exemplo, digamos que você queria saber quantos de seus amigos preferem cada uma das três entradas que você faz. Você pode encontrar essa informação com a seguinte consulta:

    SELECT COUNT(nome), entrada FROM refeicoes GROUP BY entrada;

    Output+-------------+----------+
    | COUNT(nome) | entrada |
    +-------------+----------+
    | 1 | chicken |
    | 2 | steak |
    | 2 | tofu |
    +-------------+----------+
    3 rows in set (0.00 sec)

A cláusula `ORDER BY` é usada para classificar os resultados da consulta. Por padrão, os valores numéricos são classificados em ordem crescente e os valores de texto são classificados em ordem alfabética. Para ilustrar, a consulta a seguir lista as colunas `nome` e `data_nascimento`, mas classifica os resultados por data\_nascimento:

    SELECT nome, data_nascimento FROM refeicoes ORDER BY data_nascimento;

    Output+---------+-----------------+
    | nome | data_nascimento |
    +---------+-----------------+
    | Etta | 1938-01-25 |
    | Irma | 1941-02-18 |
    | Gladys | 1944-05-28 |
    | Dolly | 1946-01-19 |
    | Barbara | 1948-12-25 |
    +---------+-----------------+
    5 rows in set (0.00 sec)

Observe que o comportamento padrão de `ORDER BY` é classificar o result-set em ordem crescente. Para reverter isso e ter o resultado classificado em ordem decrescente, feche a consulta com `DESC`:

    SELECT nome, data_nascimento FROM refeicoes ORDER BY data_nascimento DESC;

    Output+---------+-----------------+
    | nome | data_nascimento |
    +---------+-----------------+
    | Barbara | 1948-12-25 |
    | Dolly | 1946-01-19 |
    | Gladys | 1944-05-28 |
    | Irma | 1941-02-18 |
    | Etta | 1938-01-25 |
    +---------+-----------------+
    5 rows in set (0.00 sec)

Como mencionado anteriormente, a cláusula `WHERE` é usada para filtrar resultados com base em condições específicas. No entanto, se você usar a cláusula `WHERE` com uma função de agregação, ela retornará um erro, como é o caso da seguinte tentativa de encontrar quais acompanhamentos são os favoritos de pelo menos três de seus amigos:

    SELECT COUNT(nome), acompanhamento FROM refeicoes WHERE COUNT(nome) >= 3;

    OutputERROR 1111 (HY000): Invalid use of group function

A cláusula `HAVING` foi adicionada ao SQL para fornecer funcionalidade semelhante à da cláusula `WHERE`, além de ser compatível com funções de agregação. É útil pensar na diferença entre essas duas cláusulas como sendo que `WHERE` se aplica a registros individuais, enquanto`HAVING` se aplica a grupos de registros. Para este fim, sempre que você emitir uma cláusula `HAVING`, a cláusula `GROUP BY` também deve estar presente.

O exemplo a seguir é outra tentativa de descobrir quais são os acompanhamentos favoritos de pelo menos três de seus amigos, embora este retorne um resultado sem erro:

    SELECT COUNT(nome), acompanhamento FROM refeicoes GROUP BY acompanhamento HAVING COUNT(nome) >= 3;

    Output+-------------+----------------+
    | COUNT(nome) | acompanhamento |
    +-------------+----------------+
    | 3 | fries |
    +-------------+----------------+
    1 row in set (0.00 sec)

As funções de agregação são úteis para resumir os resultados de uma determinada coluna em uma dada tabela. No entanto, há muitos casos em que é necessário consultar o conteúdo de mais de uma tabela. Na próxima seção analisaremos algumas maneiras de fazer isso.

## Consultando Várias Tabelas

Mais frequentemente, um banco de dados contém várias tabelas, cada uma contendo diferentes conjuntos de dados. O SQL fornece algumas maneiras diferentes de executar uma única consulta em várias tabelas.

A cláusula `JOIN` pode ser usada para combinar linhas de duas ou mais tabelas em um resultado de consulta. Ele faz isso localizando uma coluna relacionada entre as tabelas e classifica os resultados adequadamente na saída.

Os comandos `SELECT` que incluem uma cláusula `JOIN` geralmente seguem esta sintaxe:

    SELECT tabela1.coluna1, tabela2.coluna2
    FROM tabela1
    JOIN tabela2 ON tabela1.coluna_relacionada=tabela2.coluna_relacionada;

Note que como cláusulas `JOIN` comparam o conteúdo de mais de uma tabela, o exemplo anterior especifica em qual tabela selecionar cada coluna, precedendo o nome da coluna com o nome da tabela e um ponto. Você pode especificar de qual tabela uma coluna deve ser selecionada para qualquer consulta, embora isso não seja necessário ao selecionar de uma única tabela, como fizemos nas seções anteriores. Vamos examinar um exemplo usando nossos dados de amostra.

Imagine que você queria comprar para cada um de seus amigos um par de sapatos de boliche como presente de aniversário. Como as informações sobre datas de nascimento e tamanhos de calçados dos seus amigos são mantidas em tabelas separadas, você pode consultar as duas tabelas separadamente e comparar os resultados de cada uma delas. Com uma cláusula `JOIN`, no entanto, você pode encontrar todas as informações desejadas com uma única consulta:

    SELECT torneios.nome, torneios.tamanho, refeicoes.data_nascimento 
    FROM torneios 
    JOIN refeicoes ON torneios.nome=refeicoes.nome;

    Output+---------+---------+------------------+
    | nome | tamanho | data_nascimento |
    +---------+---------+------------------+
    | Dolly | 8.5 | 1946-01-19 |
    | Etta | 9 | 1938-01-25 |
    | Irma | 7 | 1941-02-18 |
    | Barbara | 7.5 | 1948-12-25 |
    | Gladys | 8 | 1944-05-28 |
    +---------+---------+------------------+
    5 rows in set (0.00 sec)

A cláusula `JOIN` usada neste exemplo, sem nenhum outro argumento, é uma cláusula _inner_ `JOIN`. Isso significa que ela seleciona todos os registros que possuem valores correspondentes nas duas tabelas e os imprime no result-set, enquanto todos os registros que não tem correspondência são excluídos. Para ilustrar essa ideia, vamos adicionar uma nova linha a cada tabela que não tenha uma entrada correspondente na outra:

    INSERT INTO torneios (nome, vitorias, melhor, tamanho) 
    VALUES ('Bettye', '0', '193', '9');

    INSERT INTO refeicoes (nome, data_nascimento, entrada, acompanhamento, sobremesa) 
    VALUES ('Lesley', '1946-05-02', 'steak', 'salad', 'ice cream');

Então, execute novamente a instrução `SELECT` anterior com a cláusula `JOIN`:

    SELECT torneios.nome, torneios.tamanho, refeicoes.data_nascimento 
    FROM torneios 
    JOIN refeicoes ON torneios.nome=refeicoes.nome;

    Output+---------+---------+-----------------+
    | nome | tamanho | data_nascimento |
    +---------+---------+-----------------+
    | Dolly | 8.5 | 1946-01-19 |
    | Etta | 9 | 1938-01-25 |
    | Irma | 7 | 1941-02-18 |
    | Barbara | 7.5 | 1948-12-25 |
    | Gladys | 8 | 1944-05-28 |
    +---------+---------+-----------------+
    5 rows in set (0.00 sec)

Observe que, como a tabela `torneios` não tem entrada para Lesley e a tabela `refeicoes` não tem entrada para Bettye, esses registros estão ausentes desta saída.

É possível, no entanto, retornar todos os registros de uma das tabelas usando uma cláusula _outer_ `JOIN`. No MySQL, as cláusulas `JOIN` são escritas como `LEFT JOIN` ou `RIGHT JOIN`.

Uma cláusula `LEFT JOIN` retorna todos os registros da tabela da “esquerda” e apenas os registros correspondentes da tabela da direita. No contexto de outer joins, a tabela da esquerda é aquela referenciada pela cláusula `FROM` e a tabela da direita é qualquer outra tabela referenciada após o comando `JOIN`.

Execute a consulta anterior novamente, mas desta vez use uma cláusula `LEFT JOIN`:

    SELECT torneios.nome, torneios.tamanho, refeicoes.data_nascimento 
    FROM torneios 
    LEFT JOIN refeicoes ON torneios.nome=refeicoes.nome;

Este comando retornará todos os registros da tabela da esquerda (neste caso, `torneios`), mesmo que não tenha um registro correspondente na tabela da direita. Toda vez que não houver um registro correspondente da tabela da direita, ele será retornado como `NULL` ou apenas como um valor em branco, dependendo do seu SGBD:

    Output+---------+---------+-----------------+
    | nome | tamanho | data_nascimento |
    +---------+---------+-----------------+
    | Dolly | 8.5 | 1946-01-19 |
    | Etta | 9 | 1938-01-25 |
    | Irma | 7 | 1941-02-18 |
    | Barbara | 7.5 | 1948-12-25 |
    | Gladys | 8 | 1944-05-28 |
    | Bettye | 9 | NULL |
    +---------+---------+-----------------+
    6 rows in set (0.00 sec)

Agora execute a consulta novamente, desta vez com uma cláusula `RIGHT JOIN`:

    SELECT torneios.nome, torneios.tamanho, refeicoes.data_nascimento 
    FROM torneios 
    RIGHT JOIN refeicoes ON torneios.nome=refeicoes.nome;

Isso retornará todos os registros da tabela da direita (`refeicoes`). Como a data de nascimento de Lesley está registrada na tabela da direita, mas não há uma linha correspondente para ela na tabela da esquerda, as colunas `nome` e `tamanho` retornarão como valores `NULL` nessa linha:

    Output+---------+---------+-----------------+
    | nome | tamanho | data_nascimento |
    +---------+---------+-----------------+
    | Dolly | 8.5 | 1946-01-19 |
    | Etta | 9 | 1938-01-25 |
    | Irma | 7 | 1941-02-18 |
    | Barbara | 7.5 | 1948-12-25 |
    | Gladys | 8 | 1944-05-28 |
    | NULL | NULL | 1946-05-02 |
    +---------+---------+-----------------+
    6 rows in set (0.00 sec)

Observe que joins à esquerda e à direita podem ser escritos como `LEFT OUTER JOIN` ou `RIGHT OUTER JOIN`, embora a parte `OUTER` da cláusula esteja implícita. Da mesma forma, especificar `INNER JOIN` produzirá o mesmo resultado que apenas escrever `JOIN`.

Como uma alternativa ao uso de `JOIN` para consultar registros de várias tabelas, você pode usar a cláusula `UNION`.

O operador `UNION` funciona de forma ligeiramente diferente de uma cláusula `JOIN`: em vez de imprimir resultados de várias tabelas como colunas únicas usando um único comando `SELECT`, o `UNION` combina os resultados de dois comandos `SELECT` em uma única coluna.

Para ilustrar, execute a seguinte consulta:

    SELECT nome FROM torneios UNION SELECT nome FROM refeicoes;

Esta consulta removerá quaisquer entradas duplicadas, que é o comportamento padrão do operador `UNION`:

    Output+---------+
    | nome |
    +---------+
    | Dolly |
    | Etta |
    | Irma |
    | Barbara |
    | Gladys |
    | Bettye |
    | Lesley |
    +---------+
    7 rows in set (0.00 sec)

Para retornar todas as entradas (incluindo as duplicadas), use o operador `UNION ALL`:

    SELECT nome FROM torneios UNION ALL SELECT nome FROM refeicoes;

    Output+---------+
    | nome |
    +---------+
    | Dolly |
    | Etta |
    | Irma |
    | Barbara |
    | Gladys |
    | Bettye |
    | Dolly |
    | Etta |
    | Irma |
    | Barbara |
    | Gladys |
    | Lesley |
    +---------+
    12 rows in set (0.00 sec)

Os nomes e números das colunas na tabela de resultados refletem o nome e o número de colunas consultadas pelo primeiro comando `SELECT`. Note que ao usar `UNION` para consultar múltiplas colunas de mais de uma tabela, cada comando `SELECT` deve consultar o mesmo número de colunas, as respectivas colunas devem ter tipos de dados similares, e as colunas em cada comando `SELECT` devem estar na mesma ordem. O exemplo a seguir mostra o que pode resultar se você usar uma cláusula `UNION` em dois comandos `SELECT` que consultam um número diferente de colunas:

    SELECT nome FROM refeicoes UNION SELECT nome, vitorias FROM torneios;

    OutputERROR 1222 (21000): The used SELECT statements have a different number of columns

Outra maneira de consultar várias tabelas é através do uso de _subconsultas_ ou _subqueries_. As subqueries (também conhecidas como _consultas internas ou aninhadas_) são consultas incluídas em outra consulta. Elas são úteis nos casos em que você está tentando filtrar os resultados de uma consulta com base no resultado de uma função de agregação separada.

Para ilustrar essa ideia, digamos que você queira saber quais dos seus amigos ganharam mais partidas do que Bárbara. Em vez de consultar quantos jogos Bárbara venceu e, em seguida, executar outra consulta para ver quem ganhou mais jogos do que isso, você pode calcular ambos com uma única consulta:

    SELECT nome, vitorias FROM torneios 
    WHERE vitorias > (
    SELECT vitorias FROM torneios WHERE nome = 'Barbara'
    );

    Output+--------+----------+
    | nome | vitorias |
    +--------+----------+
    | Dolly | 7 |
    | Etta | 4 |
    | Irma | 9 |
    | Gladys | 13 |
    +--------+----------+
    4 rows in set (0.00 sec)

A subquerie nesse comando foi executada apenas uma vez; ele só precisava encontrar o valor da coluna `vitorias` na mesma linha que `Barbara` na coluna `nome`, e os dados retornados pela subquerie e pela consulta externa são independentes um do outro. Existem casos, no entanto, em que a consulta externa deve primeiro ler todas as linhas de uma tabela e comparar esses valores com os dados retornados pela subquerie para retornar os dados desejados. Nesse caso, a subquerie é referida como uma subquerie correlacionada.

O comando a seguir é um exemplo de uma subquerie correlacionada. Esta consulta procura descobrir quais dos seus amigos ganharam mais jogos do que a média para aqueles com o mesmo tamanho de calçado:

    SELECT nome, tamanho FROM torneios AS t 
    WHERE vitorias > (
    SELECT AVG(vitorias) FROM torneios WHERE tamanho = t.tamanho
    );

Para que a consulta seja concluída, ela deve primeiro coletar as colunas `nome` e `tamanho` da consulta externa. Em seguida, ele compara cada linha desse result-set com os resultados da consulta interna, que determina o número médio de vitórias para indivíduos com tamanhos de sapatos idênticos. Como você só tem dois amigos com o mesmo tamanho de calçado, só pode haver uma linha no result-set:

    Output+------+---------+
    | nome | tamanho |
    +------+---------+
    | Etta | 9 |
    +------+---------+
    1 row in set (0.00 sec)

Conforme mencionado anteriormente, as subquerie podem ser usadas para consultar resultados de várias tabelas. Para ilustrar isso com um exemplo final, digamos que você queria fazer um jantar surpresa para o melhor jogador de todos os tempos do grupo. Você pode encontrar qual dos seus amigos tem o melhor registro de boliche e retornar sua refeição favorita com a seguinte consulta:

    SELECT nome, entrada, acompanhamento, sobremesa 
    FROM refeicoes 
    WHERE nome = (SELECT nome FROM torneios 
    WHERE vitorias = (SELECT MAX(vitorias) FROM torneios));

    Output+--------+---------+-----------------+------------+
    | nome | entrada | acompanhamento | sobremesa |
    +--------+---------+-----------------+------------+
    | Gladys | steak | fries | ice cream |
    +--------+---------+-----------------+------------+
    1 row in set (0.00 sec)

Observe que esse comando não inclui apenas uma subquerie, mas também contém uma subquerie dentro dessa subquerie.

## Conclusão

A realização de consultas é uma das tarefas mais comuns no domínio do gerenciamento de banco de dados. Existem várias ferramentas de administração de banco de dados, como [phpMyAdmin](https://www.phpmyadmin.net/) or [pgAdmin](https://www.pgadmin.org/), que permitem realizar consultas e visualizar os resultados, mas a execução de comandos `SELECT` a partir da linha de comando ainda é um fluxo de trabalho amplamente praticado que também pode fornecer maior controle.

Se você é novato no trabalho com SQL, lhe encorajamos a usar nosso [Guia de Consulta Rápida SQL](como-gerenciar-um-banco-de-dados-sql-pt) como referência e a revisar a [documentação oficial do MySQL](https://dev.mysql.com/doc/refman/5.7/en/). Além disso, se você quiser saber mais sobre bancos de dados relacionais e SQL, os seguintes tutoriais podem ser de seu interesse:

- [Understanding SQL And NoSQL Databases And Different Database Models](understanding-sql-and-nosql-databases-and-different-database-models)

- [How To Create a Multi-Node MySQL Cluster on Ubuntu 18.04](how-to-create-a-multi-node-mysql-cluster-on-ubuntu-18-04)

- [How To Reset Your MySQL or MariaDB Root Password on Ubuntu 18.04](how-to-reset-your-mysql-or-mariadb-root-password-on-ubuntu-18-04)

_Por Mark Drake_
