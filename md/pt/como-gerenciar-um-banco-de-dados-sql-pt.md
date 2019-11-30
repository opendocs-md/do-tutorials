---
author: Mark Drake
date: 2018-12-07
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-gerenciar-um-banco-de-dados-sql-pt
---

# Como Gerenciar um Banco de Dados SQL

## Um Guia de Consulta Rápida SQL

### Introdução

Os bancos de dados SQL vêm instalados com todos os comandos necessários para adicionar, modificar, excluir e consultar seus dados. Este guia de consulta rápida fornece uma referência para alguns dos comandos SQL mais usados.

**Como Utilizar Este Guia:**

- Este guia está no formato de consulta rápida com trechos de linha de comando independentes

- Salte para qualquer seção que seja relevante para a tarefa que você está tentando concluir

- Quando você vir `texto destacado` nos comandos deste guia, tenha em mente que este texto deve se referir às colunas, tabelas e dados em seu próprio banco de dados.

- Em todo este guia, os valores de dados de exemplo fornecidos são todos agrupados em apóstrofos (`'`). No SQL, é necessário envolver quaisquer valores de dados que consistam em strings em apóstrofos. Isso não é necessário para dados numéricos, mas também não causará problemas se você incluir apóstrofos.

Por favor, observe que, embora o SQL seja reconhecido como padrão, a maioria dos programas de banco de dados SQL possui suas próprias extensões proprietárias. Este guia utiliza o MySQL como exemplo de sistema gerenciador de banco de dados relacional (SGBD), mas os comandos executados irão funcionar com outros programs de banco de dados relacionais, incluindo PostgreSQL, MariaDB, and SQLite. Onde existem diferenças significativas entre os SGDBs, incluímos os comandos alternativos.

## Abrindo o Prompt do Banco de Dados (usando Autenticação Socket/Trust)

Por padrão no Ubuntu 18.04, o usuário root do MySQL pode se autenticar sem uma senha utilizando o seguinte comando:

    sudo mysql

Para abrir um prompt no PostgreSQL, use o seguinte comando. Este exemplo irá logar você como o usuário **postgres** , que é a função de superusuário incluída, mas você pode substituir isso por qualquer função já criada:

    sudo -u postgres psql

## Abrindo o Prompt do Banco de Dados (usando Autenticação por Senha)

Se seu usuário **root** do MySQL está configurado para se autenticar com uma senha, você pode fazer isso com o seguinte comando:

    mysql -u root -p

Se você já tiver configurado uma conta de usuário não-root para seu banco de dados, você também poderá usar esse método para efetuar login como esse usuário:

    mysql -u usuário -p

O comando acima irá solicitar a sua senha após executá-lo. Se voce gostaria de fornecer sua senha como parte do comando, siga imediatamente a opção `-p` com a sua senha, sem espaço entre elas:

    mysql -u root -psenha

## Criando um Banco de Dados

O seguinte comando cria um banco de dados com configurações padrão.

    CREATE DATABASE nome_do_banco_de_dados;

Se você quer que seu banco de dados utilize um conjunto de caracteres e collation diferentes do padrão, você pode especificá-los usando esta sintaxe:

    CREATE DATABASE nome_do_banco_de_dados CHARACTER SET character_set COLLATE collation;

## Listando Bancos de Dados

Para ver quais bancos de dados existem em sua instalação de MySQL ou MariaDB, execute o seguinte comando:

    SHOW DATABASES;

No PostgreSQL, você pode ver quais bancos de dados foram criados com o seguinte comando:

    \list

## Excluindo um Banco de Dados

Para excluir um banco de dados, incluindo quaisquer tabelas e dados contidos nele, execute um comando que segue esta estrutura:

    DROP DATABASE IF EXISTS banco_de_dados;

## Criando um Usuário

Para criar um perfil de usuário para o seu banco de dados sem especificar nenhum privilégio para ele, execute o seguinte comando:

    CREATE USER nome_do_usuário IDENTIFIED BY 'senha';

O PostgreSQL usa uma sintaxe similar, mas ligeiramente diferente:

    CREATE USER nome_do_usuário WITH PASSWORD 'senha';

Se você quiser criar um novo usuário e conceder-lhe privilégios em um comando, você pode fazer isso usando um comando `GRANT`. O seguinte comando cria um novo usuário e concede a ele privilégios totais em todos os bancos de dados e tabelas do SGBD:

    GRANT ALL PRIVILEGES ON *.* TO 'nome_do_usuário'@'localhost' IDENTIFIED BY 'senha';

Observe a palavra-chave `PRIVILEGES` no comando `GRANT` anterior. na maioria dos SGBDs, esta palavra-chave é opcional, e esse comando pode ser escrito equivalentemente como:

    GRANT ALL ON *.* TO 'nome_do_usuário'@'localhost' IDENTIFIED BY 'senha';

Esteja ciente, porém, que a palavra-chave `PRIVILEGES` é necessária para a concessão de privilégios como este, quando [o modo Strict SQL](https://dev.mysql.com/doc/refman/8.0/en/sql-mode.html#sql-mode-strict) está ligado.

## Excluindo um Usuário

Utilize a seguinte sintaxe para excluir um perfil de usuário do banco de dados:

    DROP USER IF EXISTS nome_do_usuário;

Observe que esse comando não excluirá por padrão nenhuma tabela criada pelo usuário excluído, e tentativas de acessar essas tabelas podem resultar em erros.

## Selecionando um Banco de Dados

Antes de poder criar uma tabela, primeiro você precisa informar ao SGBD o banco de dados no qual você gostaria de criá-la. No MySQL e MariaDB, faça isto com a seguinte sintaxe:

    USE banco_de_dados;

No PostgreSQL, você deve utilizar o seguinte comando para selecionar seu banco de dados desejado:

    \connect banco_de_dados

## Criando uma Tabela

A seguinte estrutura de comando cria uma nova tabela com o nome tabela, e inclui duas colunas, cada uma com seu tipo de dado específico:

    CREATE TABLE tabela ( coluna_1 coluna_1_tipo_de_dado, coluna_2 coluna_2_tipo_de_dado );

## Excluindo uma Tabela

Para excluir uma tabela inteira, incluindo todos os seus dados, execute o seguinte:

    DROP TABLE IF EXISTS tabela

## Inserindo Dados em uma Tabela

Utilize a seguinte sintaxe para popular uma tabela com uma linha de dados:

    INSERT INTO tabela ( coluna_A, coluna_B, coluna_C ) VALUES ( 'dado_A', 'dado_B', 'dado_C' );

Você pode também popular uma tabela com várias linhas de dados usando um único comando, assim:

    INSERT INTO tabela ( coluna_A, coluna_B, coluna_C ) VALUES ( 'dado_1A', 'dado_1B', 'dado_1C' ), ( 'dado_2A', 'dado_2B', 'dado_2C' ), ( 'dado_3A', 'dado_3B', 'dado_3C' );

## Excluindo Dados de uma Tabela

Para excluir uma linha de dados de uma tabela, utilize a seguinte estrutura de comando. Observe que valor deve ser o valor contido na coluna especificada na linha que você quer excluir:

    DELETE FROM tabela WHERE coluna='valor';

**Nota:** Se você não incluir uma cláusula `WHERE` em um comando `DELETE` como no exemplo seguinte, ele excluirá todos os dados contidos em uma tabela, mas não as colunas ou a própria tabela:

    DELETE FROM tabela;

## Alterando Dados em uma Tabela

Use a seguinte sintaxe para atualizar os dados contidos em uma dada linha. Observe que a cláusula `WHERE` no final do comando informa ao SQL qual linha atualizar. valor é o valor contido na coluna\_A que se alinha com a linha que você deseja alterar.

**Nota:** Se você deixar de incluir uma cláusula `WHERE` em um comando `UPDATE`, o comando substituirá os dados contidos em todas as linhas da tabela.

    UPDATE tabela SET coluna_1 = valor_1, coluna_2 = valor_2 WHERE coluna_A=valor;

## Inserindo uma Coluna

A seguinte sintaxe de comando adicionará uma nova coluna a uma tabela:

    ALTER TABLE tabela ADD COLUMN tipo_de_dado coluna;

## Excluindo uma Coluna

Um comando seguindo essa estrutura excluirá uma coluna de uma tabela:

    ALTER TABLE tabela DROP COLUMN coluna;

## Realizando Consultas Básicas

Para visualizar todos os dados de uma única coluna em uma tabela, use a seguinte sintaxe:

    SELECT coluna FROM tabela;

Para consultar várias colunas da mesma tabela, separe os nomes das colunas com uma vírgula:

    SELECT coluna_1, coluna_2 FROM tabela;

Você também pode consultar todas as colunas de uma tabela, substituindo os nomes das colunas por um asterisco (\*). No SQL, asteriscos agem como um curinga para representar “todos”:

    SELECT * FROM tabela;

## Usando Cláusulas WHERE

Você pode restringir os resultados de uma consulta adicionando a cláusula `WHERE` ao comando `SELECT`, assim:

    SELECT coluna FROM tabela WHERE condições_que_se_aplicam;

Por exemplo, você pode consultar todos os dados de uma única linha com uma sintaxe como a seguinte. Observe que valor deve ser um valor contido tanto na coluna especificada quanto na linha que você quer consultar:

    SELECT * FROM tabela WHERE coluna = valor;

## Trabalhando com Operadores de Comparação

Um operador de comparação em uma cláusula `WHERE` define como a coluna especificada deve ser comparada com o valor. Aqui estão alguns operadores comuns de comparação SQL:

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

## Trabalhando com Curingas

O SQL permite o uso de caracteres curinga. Eles são úteis se você estiver tentando encontrar uma entrada específica em uma tabela, mas não tiver certeza de qual é exatamente essa entrada.

Asteriscos (`*`) são marcadores que representam “todos”. Isso irá consultar todas as colunas de uma tabela:

    SELECT * FROM tabela;

O símbolo de porcentagem (`%`) representa zero ou mais caracteres desconhecidos.

    SELECT * FROM tabela WHERE coluna LIKE val%;

Os underscores (`_`) são usados para representar um único caractere desconhecido:

    SELECT * FROM tabela WHERE coluna LIKE v_lue;

## Contando Entradas em uma Coluna

A função `COUNT` é utilizada para encontrar o número de entradas em uma determinada coluna. A seguinte sintaxe retornará o número total de valores contidos em coluna:

    SELECT COUNT(coluna) FROM tabela;

Você pode restringir os resultados de uma função `COUNT` adicionando a cláusula `WHERE`, assim:

    SELECT COUNT(coluna) FROM table WHERE coluna=valor;

## Encontrando o Valor Médio em uma Coluna

A função `AVG` é usada para encontrar o valor médio (nesse caso, a média) entre os valores contidos em uma coluna específica. Observe que a função `AVG` só funcionará com colunas contendo valores numéricos; quando usada em uma coluna contendo valores de string, pode retornar um erro ou `0`:

    SELECT AVG(coluna) FROM tabela;

## Encontrando a Soma de Valores em uma Coluna

A função `SUM` é usado para encontrar a soma total de todos os valores numéricos contidos em uma coluna:

    SELECT SUM(coluna) FROM tabela;

Assim como na função `AVG`, se você executar a função `SUM` em uma coluna contendo valores de string, ela pode retornar um erro ou apenas `0`, dependendo do seu SGBD.

## Encontrando o Maior Valor em uma Coluna

Para encontrar o maior valor numérico em uma coluna ou o último valor em ordem alfabética, utilize a função `MAX`:

    SELECT MAX(coluna) FROM tabela;

## Encontrando o Menor Valor em uma Coluna

Para encontrar o menor valor numérico em uma coluna ou o primeiro valor em ordem alfabética, use a função `MIN`:

    SELECT MIN(coluna) FROM tabela;

## Ordenando Resultados com Cláusulas ORDER BY

Uma cláusula `ORDER BY` é usada para ordenar os resultados da consulta. A seguinte sintaxe de consulta retorna os valores de coluna_1_ e coluna2 e ordena os resultados pelos valores contidos em coluna\_1 em ordem crescente ou, para valores de string, em ordem alfabética:

    SELECT coluna_1, coluna_2 FROM tabela ORDER BY coluna_1;

Para realizar a mesma ação, mas ordenar os resultados em ordem alfabética decrescente ou reversa, anexe a consulta com `DESC`:

    SELECT coluna_1, coluna_2 FROM tabela ORDER BY coluna_1 DESC;

## Ordenando Resultados com Cláusulas GROUP BY

A cláusula `GROUP BY` é semelhante à cláusula `ORDER BY`, mas é usada para ordenar os resultados de uma consulta que inclui uma função de agregação, como `COUNT`, `MAX`, `MIN`, ou `SUM`. Sozinhas, as funções de agregação descritas na seção anterior retornarão apenas um único valor. No entanto, você pode visualizar os resultados de uma função de agregação executada em cada valor correspondente em uma coluna, ao incluir uma cláusula `GROUP BY`.

A seguinte sintaxe contará o número de valores correspondentes em coluna\_2 e os agrupará em ordem crescente ou alfabética:

    SELECT COUNT(coluna_1), coluna_2 FROM tabela GROUP BY coluna_2;

Para realizar a mesma ação, mas ordenar os resultados em ordem alfabética decrescente ou reversa, adicione `DESC` à consulta:

    SELECT COUNT(coluna_1), coluna_2 FROM tabela GROUP BY coluna_2 DESC;

## Consultando Várias Tabelas com Cláusulas JOIN

As cláusulas `JOIN` são usadas para criar result-sets ou conjuntos de resultados que combinam linhas de duas ou mais tabelas. Uma cláusula `JOIN` só funcionará se as duas tabelas tiverem uma coluna com nome e tipo de dados idênticos, como neste exemplo:

    SELECT tabela_1.coluna_1, tabela_2.coluna_2 FROM tabela_1 JOIN tabela_2 ON tabela_1.coluna_comum=tabela_2.coluna_comum;

Este é um exemplo de uma cláusula `INNER JOIN`. Um `INNER JOIN` retornará todos os registros que tiverem valores correspondentes nas duas tabelas, mas não mostrará registros que não tenham valores correspondentes.

É possível retornar todos os registros de uma das duas tabelas, incluindo valores que não têm ocorrência correspondente na outra tabela, utilizando uma cláusula _outer_ `JOIN`. As cláusulas outer `JOIN` são escritas ou como `LEFT JOIN` ou `RIGHT JOIN`.

Uma cláusula `LEFT JOIN` retorna todos os registros da tabela da “esquerda” e apenas os registros correspondentes da tabela da “direita”. No contexto das cláusulas outer `JOIN`, a tabela da esquerda é aquela referenciada na cláusula `FROM`, e a tabela da direita é qualquer outra tabela referenciada após a declaração `JOIN`. A consulta seguinte mostrará todos os registros de `tabela_1` e apenas os valores correspondentes de `tabela_2`. Quaisquer valores que não tenham uma correspondência em `tabela_2` aparecerão como `NULL` no result-set:

    SELECT tabela_1.coluna_1, tabela_2.coluna_2 FROM tabela_1 LEFT JOIN tabela_2 ON tabela_1.coluna_comum=tabela_2.coluna_comum;

Uma cláusula `RIGHT JOIN` funciona da mesma forma que um `LEFT JOIN`, mas imprime todos os resultados da tabela da direita e apenas os valores correspondentes da tabela da esquerda:

    SELECT tabela_1.coluna_1, tabela_2.coluna_2 FROM tabela_1 RIGHT JOIN tabela_2 ON tabela_1.coluna_comum=tabela_2.coluna_comum;

## Combinando Vários Comandos SELECT com Cláusulas UNION

Um operador `UNION` é útil para combinar os resultados de dois (ou mais) comandos `SELECT` em um único result-set:

    SELECT coluna_1 FROM tabela UNION SELECT coluna_2 FROM tabela;

Além disso, a cláusula `UNION` pode combinar dois (ou mais) comandos `SELECT` consultando diferentes tabelas em um mesmo result-set:

    SELECT coluna FROM tabela_1 UNION SELECT coluna FROM tabela_2;

## Conclusão

Este guia aborda alguns dos comandos mais comuns no SQL usados para gerenciar bancos de dados, usuários e tabelas e consultar o conteúdo contido nessas tabelas. No entanto, existem muitas combinações de cláusulas e operadores que produzem result-set exclusivos. Se você está procurando um guia mais abrangente para trabalhar com SQL, recomendamos que você confira a [Referência de SQL do Banco de Dados Oracle](https://docs.oracle.com/cd/B19306_01/server.102/b14200/toc.htm).

Além disso, se houver comandos SQL comuns que você gostaria de ver neste guia, pergunte ou faça sugestões nos comentários abaixo.

_Por Mark Drake_
