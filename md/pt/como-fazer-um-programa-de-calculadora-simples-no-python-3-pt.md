---
author: Lisa Tagliaferri
date: 2018-07-02
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-fazer-um-programa-de-calculadora-simples-no-python-3-pt
---

# Como Fazer um Programa de Calculadora Simples no Python 3

### Introdução

A linguagem de programação Python é uma grande ferramenta para utilizar ao trabalhar com números e avaliar expressões matemáticas. Esta qualidade pode ser utilizada para fazer programas úteis.

Este tutorial apresenta um exercício de aprendizado para ajudá-lo a fazer um programa simples de calculadora de linha de comando no Python 3. Embora tenhamos escolhido usar uma forma possível de criar esse programa, há muitas oportunidades para melhorar o código e criar uma calculadora mais robusta.

Estaremos utilizando [operadores matemáticos](how-to-do-math-in-python-3-with-operators), [variáveis](how-to-use-variables-in-python-3), [declarações condicionais](how-to-write-conditional-statements-in-python-3-2), [funções](how-to-define-functions-in-python-3), e lidando com a entrada do usuário para fazer nossa calculadora.

## Pré-requisitos

Para este tutorial, você deve ter o Python 3 instalado em seu computador local e ter um ambiente de programação configurado em sua máquina. Se você precisar instalar o Python ou configurar o ambiente, você pode fazer isso seguindo o [guia apropriado para o seu sistema operacional](https://www.digitalocean.com/community/tutorial_series/how-to-install-and-set-up-a-local-programming-environment-for-python-3).

## Passo 1 — Solicitar Entrada dos Usuários

As calculadoras funcionam melhor quando uma pessoa fornece equações para o computador resolver. Começaremos a escrever nosso programa no ponto em que a pessoa digita os números com os quais gostaria que o computador trabalhasse.

Para fazer isto, utilizaremos a função interna do Python `input()` que aceita entrada gerada pelo usuário através do teclado. Dentro dos parênteses da função `input()` podemos passar uma [string](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3) para solicitar ao usuário. Vamos atribuir a entrada do usuário a uma variável.

Para este programa, gostaríamos que o usuário inserisse dois números, então vamos fazer com que o programa solicite dois números. Ao solicitar informações, devemos incluir um espaço no final da nossa string para que haja um espaço entre a entrada do usuário e a string de solicitação.

    number_1 = input('Enter your first number: ')
    number_2 = input('Enter your second number: ')

Após escrever nossas duas linhas, devemos salvar o programa antes de executá-lo podemos chamar este programa de `calculator.py` e, em uma janela de terminal, podemos executar o programa em nosso ambiente de programação utilizando o comando `python calculator.py`. Você deve ser capaz de digitar na janela do terminal em resposta a cada solicitação.

    OutputEnter your first number: 5
    Enter your second number: 7

Se você executar esse programa algumas vezes e variar sua entrada, você perceberá que pode inserir o que quiser quando solicitado, incluindo palavras, símbolos, espaço em branco ou mesmo a tecla Enter. Isto é porque `input()` pega os dados inseridos como [strings](https://www.digitalocean.com/community/tutorial_series/working-with-strings-in-python-3) e não sabe que estamos procurando por um número.

Gostaríamos de usar um número neste programa por dois motivos: 1) para permitir que o programa execute cálculos matemáticos, e 2) para validar que a entrada do usuário é uma string numérica.

Dependendo das nossas necessidades na calculadora, podemos querer converter a string que vem da função `input()` para um inteiro ou um float. Para nós, números inteiros atendem ao nosso propósito, então vamos passar a função `input()` na função `int()` para [converter](how-to-convert-data-types-in-python-3) a entrada para o [tipo de dados inteiro](understanding-data-types-in-python-3#integers).

calculator.py

    
    number_1 = int(input('Enter your first number: '))
    number_2 = int(input('Enter your second number: '))
    

Agora, se entrarmos dois inteiros, não vamos nos deparar com um erro:

    OutputEnter your first number: 23
    Enter your second number: 674

Mas, se entrarmos com letras, símbolos, ou quaisquer outros não inteiros, encontraremos o seguinte erro:

    OutputEnter your first number: sammy
    Traceback (most recent call last):
      File "testing.py", line 1, in <module>
        number_1 = int(input('Enter your first number: '))
    ValueError: invalid literal for int() with base 10: 'sammy'

Até agora, configuramos duas variáveis para armazenar a entrada do usuário na forma de tipos de dados inteiros. Você também pode experimentar converter a entrada em floats.

## Passo 2 — Adicionando operadores

Antes que nosso programa esteja completo, adicionaremos um total de 4 [operadores matemáticos](how-to-do-math-in-python-3-with-operators): `+` para adição, `-` para subtração, `*` para multiplicação, e `/` para divisão.

À medida que construímos nosso programa, queremos ter certeza de que cada parte está funcionando corretamente, então aqui começaremos com a configuração de adição. Vamos adicionar os dois números dentro de uma função de impressão para que a pessoa que usa a calculadora possa ver a saída.

calculator.py

    
    number_1 = int(input('Enter your first number: '))
    number_2 = int(input('Enter your second number: '))
    
    print(number_1 + number_2)

Vamos executar o programa e digitar dois números quando solicitado, a fim de garantir que esteja funcionando conforme esperado:

    OutputEnter your first number: 8
    Enter your second number: 3
    11

A saída nos mostra que o programa está funcionando corretamente, então, vamos adicionar mais contexto para que o usuário fique totalmente informado durante todo o tempo de execução do programa. Para fazer isto, utilizaremos [formatadores de string](how-to-use-string-formatters-in-python-3) para nos ajudar a formatar nosso texto e e fornecer feedback. Queremos que o usuário receba uma confirmação sobre os números que ele está inserindo e o operador que está sendo usado, juntamente com o resultado produzido.

calculator.py

    
    number_1 = int(input('Enter your first number: '))
    number_2 = int(input('Enter your second number: '))
    
    print('{} + {} = '.format(number_1, number_2))
    print(number_1 + number_2)

Agora, quando executarmos o programa, teremos uma saída extra que permitirá ao usuário confirmar a expressão matemática que está sendo executada pelo programa.

    OutputEnter your first number: 90
    Enter your second number: 717
    90 + 717 = 
    807

O uso dos formatadores de string fornece aos usuários mais feedback.

Neste ponto, você pode adicionar o restante dos operadores ao programa com o mesmo formato que usamos para a adição:

calculator.py

    
    number_1 = int(input('Enter your first number: '))
    number_2 = int(input('Enter your second number: '))
    
    # Addition
    print('{} + {} = '.format(number_1, number_2))
    print(number_1 + number_2)
    
    # Subtraction
    print('{} - {} = '.format(number_1, number_2))
    print(number_1 - number_2)
    
    # Multiplication
    print('{} * {} = '.format(number_1, number_2))
    print(number_1 * number_2)
    
    # Division
    print('{} / {} = '.format(number_1, number_2))
    print(number_1 / number_2)

Adicionamos os operadores restantes, `-`, `*`, and `/` no programa acima. Se executarmos o programa neste ponto, o programa executará todas as operações acima. No entanto, queremos limitar o programa a executar apenas uma operação por vez. Para fazer isso, usaremos declarações condicionais.

## Passo 3 — Adicionando declarações condicionais

Com nosso programa `calculator.py`, queremos que o usuário possa escolher entre os diferentes operadores. Assim, vamos começar adicionando algumas informações na parte superior do programa, juntamente com uma escolha a ser feita, para que a pessoa saiba o que fazer.

Vamos escrever uma string em algumas linhas diferentes usando aspas triplas:

    ''
    Please type in the math operation you would like to complete:
    + for addition
    - for subtraction
    * for multiplication
    / for division
    '''

Estamos usando cada um dos símbolos de operador para que os usuários façam sua escolha, então, se o usuário quiser que uma divisão seja executada, ele digitará `/`. Poderíamos escolher qualquer símbolo que quisermos, como `1 para adição` ou `b para subtração`.

Como estamos solicitando a entrada dos usuários, queremos utilizar a função `input()`. Vamos colocar a string dentro da função `input()` e passar o valor dessa entrada para uma variável, a qual chamaremos de `operation`.

calculator.py

    
    operation = input('''
    Please type in the math operation you would like to complete:
    + for addition
    - for subtraction
    * for multiplication
    / for division
    ''')
    
    number_1 = int(input('Enter your first number: '))
    number_2 = int(input('Enter your second number: '))
    
    print('{} + {} = '.format(number_1, number_2))
    print(number_1 + number_2)
    
    print('{} - {} = '.format(number_1, number_2))
    print(number_1 - number_2)
    
    print('{} * {} = '.format(number_1, number_2))
    print(number_1 * number_2)
    
    print('{} / {} = '.format(number_1, number_2))
    print(number_1 / number_2)

Nesse ponto, se executarmos nosso programa não importa o que inserimos no primeiro prompt, então, vamos adicionar nossas declarações condicionais ao programa. Devido à forma como estruturamos o nosso programa, a declaração `if` estará onde a adição é executada, haverá 3 declarações else-if ou `elif` para cada um dos outros operadores, e a declaração `else` será colocada em prática pra tratar um erro se a pessoa não digitar um símbolo de operador.

calculator.py

    
    operation = input('''
    Please type in the math operation you would like to complete:
    + for addition
    - for subtraction
    * for multiplication
    / for division
    ''')
    
    number_1 = int(input('Enter your first number: '))
    number_2 = int(input('Enter your second number: '))
    
    if operation == '+':
        print('{} + {} = '.format(number_1, number_2))
        print(number_1 + number_2)
    
    elif operation == '-':
        print('{} - {} = '.format(number_1, number_2))
        print(number_1 - number_2)
    
    elif operation == '*':
        print('{} * {} = '.format(number_1, number_2))
        print(number_1 * number_2)
    
    elif operation == '/':
        print('{} / {} = '.format(number_1, number_2))
        print(number_1 / number_2)
    
    else:
        print('You have not typed a valid operator, please run the program again.')

Para percorrer este programa, primeiro ele solicita que o usuário coloque um símbolo de operação. Digamos que o usuário insira `*` para multiplicar. Em seguida, o programa pede 2 números e o usuário insere `58` e`40`. Neste ponto, o programa mostra a equação executada e o produto.

    OutputPlease type in the math operation you would like to complete:
    + for addition
    - for subtraction
    * for multiplication
    / for division
    *
    Please enter the first number: 58
    Please enter the second number: 40
    58 * 40 = 
    2320

Devido à forma como estruturamos o programa, se o usuário entrar com `%` quando perguntado sobre uma operação no primeiro prompt, ele não receberá um feedback para tentar novamente até que entre com números. Você pode querer considerar outras opções possíveis para tratar várias situações.

Neste ponto, temos um programa totalmente funcional, mas não podemos realizar uma segunda ou terceira operação sem executar o programa novamente, então, vamos adicionar mais algumas funcionalidades ao programa.

## Passo 4 — Definindo funções

Para lidar com a capacidade de executar o programa quantas vezes o usuário quiser, vamos definir algumas funções. Primeiro, vamos colocar nosso bloco de códigos atual em uma função. Chamaremos a função de `calculate()` e adicionaremos uma camada adicional de identação dentro da própria função. Para garantir que o programa seja executado, chamaremos a função na parte inferior do nosso arquivo também.

calculator.py

    # Define our function
    def calculate():
        operation = input('''
    Please type in the math operation you would like to complete:
    + for addition
    - for subtraction
    * for multiplication
    / for division
    ''')
    
        number_1 = int(input('Please enter the first number: '))
        number_2 = int(input('Please enter the second number: '))
    
        if operation == '+':
            print('{} + {} = '.format(number_1, number_2))
            print(number_1 + number_2)
    
        elif operation == '-':
            print('{} - {} = '.format(number_1, number_2))
            print(number_1 - number_2)
    
        elif operation == '*':
            print('{} * {} = '.format(number_1, number_2))
            print(number_1 * number_2)
    
        elif operation == '/':
            print('{} / {} = '.format(number_1, number_2))
            print(number_1 / number_2)
    
        else:
            print('You have not typed a valid operator, please run the program again.')
    
    # Call calculate() outside of the function
    calculate()

Em seguida, vamos criar uma segunda função composta de mais declarações condicionais. Neste bloco de código, queremos deixar o usuário escolher se deseja calcular novamente ou não. Podemos basear isso em nossas instruções condicionais da calculadora, mas nesse caso teremos somente um `if`, um `elif` e um `else` para tratar erros.

Chamaremos esta função de `again()`, e a adicionaremos abaixo do nosso bloco de código `def calculate():`.

calculator.py

    ... 
    # Define again() function to ask user if they want to use the calculator again
    def again():
    
        # Take input from user
        calc_again = input('''
    Do you want to calculate again?
    Please type Y for YES or N for NO.
    ''')
    
        # If user types Y, run the calculate() function
        if calc_again == 'Y':
            calculate()
    
        # If user types N, say good-bye to the user and end the program
        elif calc_again == 'N':
            print('See you later.')
    
        # If user types another key, run the function again
        else:
            again()
    
    # Call calculate() outside of the function
    calculate()

Embora haja algum tratamento de erros com a declaração else acima, provavelmente poderíamos fazer um pouco melhor para aceitar, digamos, `y` e `n` minúsculos além do `Y` e `N` maiúsculos. Para fazer isso, vamos adicionar a [função de string](an-introduction-to-string-methods-in-python-3) `str.upper()`:

calculator.py

    ...
    def again():
        calc_again = input('''
    Do you want to calculate again?
    Please type Y for YES or N for NO.
    ''')
    
        # Accept 'y' or 'Y' by adding str.upper()
        if calc_again.upper() == 'Y':
            calculate()
    
        # Accept 'n' or 'N' by adding str.upper()
        elif calc_again.upper() == 'N':
            print('See you later.')
    
        else:
            again()
    ...

Neste ponto, devemos adicionar a função `again()` ao final da função `calculate()` para que possamos acionar o código que pergunta ao usuário se deseja ou não continuar.

calculator.py

    def calculate():
        operation = input('''
    Please type in the math operation you would like to complete:
    + for addition
    - for subtraction
    * for multiplication
    / for division
    ''')
    
        number_1 = int(input('Please enter the first number: '))
        number_2 = int(input('Please enter the second number: '))
    
        if operation == '+':
            print('{} + {} = '.format(number_1, number_2))
            print(number_1 + number_2)
    
        elif operation == '-':
            print('{} - {} = '.format(number_1, number_2))
            print(number_1 - number_2)
    
        elif operation == '*':
            print('{} * {} = '.format(number_1, number_2))
            print(number_1 * number_2)
    
        elif operation == '/':
            print('{} / {} = '.format(number_1, number_2))
            print(number_1 / number_2)
    
        else:
            print('You have not typed a valid operator, please run the program again.')
    
        # Add again() function to calculate() function
        again()
    
    def again():
        calc_again = input('''
    Do you want to calculate again?
    Please type Y for YES or N for NO.
    ''')
    
        if calc_again.upper() == 'Y':
            calculate()
        elif calc_again.upper() == 'N':
            print('See you later.')
        else:
            again()
    
    calculate()

Agora você pode executar seu programa com `python calculator.py` na sua janela de terminal e poderá calcular quantas vezes quiser.

## Passo 5 — Melhorando o código

Agora temos um programa legal e totalmente funcional. No entanto, há muito mais que você pode fazer para melhorar esse código. Você pode adicionar uma função de boas-vindas, por exemplo, que recebe as pessoas no programa, na parte superior do código, dessa forma:

    def welcome():
        print('''
    Welcome to Calculator
    ''')
    ...
    # Don’t forget to call the function
    welcome()
    calculate()

Existem oportunidades para introduzir algo mais sobre tratamento de erros ao longo do programa. Para iniciantes, você pode garantir que o programa continue a rodar mesmo se o usuário digitar `plankton` quando for solicitado um número. Do jeito que programa está agora, se `number_1` e`number_2` não forem inteiros, o usuário receberá um erro e o programa será interrompido. Além disso, para casos em que o usuário seleciona o operador de divisão (`/`) e digita `0` como seu segundo número (`number_2`), o usuário receberá o erro `ZeroDivisionError: division by zero error`. Para isso, você pode querer usar o tratamento de exceções com a declaração `try ... except`.

Nós nos limitamos a 4 operadores, mas você pode colocar operadores adicionais, como em:

    ...
        operation = input('''
    Please type in the math operation you would like to complete:
    + for addition
    - for subtraction
    * for multiplication
    / for division
    ** for power
    % for modulo
    ''')
    ...
    # Don’t forget to add more conditional statements to solve for power and modulo

Adicionalmente, você pode querer reescrever parte do programa com uma instrução de loop.

Há muitas maneiras de lidar com erros e modificar e melhorar cada projeto de codificação. É importante ter em mente que não existe uma única maneira correta de resolver um problema que nos é apresentado.

## Conclusão

Este tutorial apresentou uma abordagem possível para construir uma calculadora na linha de comando. Depois de concluir este tutorial, você poderá modificar e melhorar o código e trabalhar em outros projetos que exigem entrada do usuário na linha de comando.

Estamos interessados em ver suas soluções para este projeto simples de calculadora de linha de comando! Por favor, sinta-se à vontade para postar seus projetos de calculadora nos comentários abaixo.

Em seguida, você pode querer criar um jogo baseado em texto como tic-tac-toe ou rock-paper-scissors.

Por Lisa Tagliaferri
