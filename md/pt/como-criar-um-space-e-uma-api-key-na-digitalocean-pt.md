---
author: Brian Boucheron
date: 2018-10-11
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-criar-um-space-e-uma-api-key-na-digitalocean-pt
---

# Como criar um Space e uma API Key na DigitalOcean

### Introdução

DigitalOcean Spaces é um serviço de armazenamento de objetos que torna mais fácil e econômico armazenar e fornecer grandes quantidades de dados. Spaces individuais podem ser criados e colocados em uso rapidamete, sem necessidade de configuração adicional.

Neste tutorial, iremos utilizar o Painel de Controle da DigitalOcean para criar um novo Space. Em seguida, iremos recuperar uma Chave de API ou API Key e um secret que podem ser utilizados para conceder acesso ao Space para quaisquer clientes ou bibliotecas compatíveis com S3.

## Pré-requisitos

Para completar este tutorial, você vai precisar de uma conta na DigitalOcean. Se você já não tiver uma, você pode registrar uma nova na [página de inscrição](https://cloud.digitalocean.com/registrations/new).

Faça o login no Painel de Controle da DigitalOcean para começar.

## Criando um Space

Para criar um novo Space, utilize o botão **Create** no canto superior direito do Painel de Controle. Clique no botão, em seguida escolha **Spaces** na lista suspensa:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/space-key/space-menu.png)

Se você nunca criou um Space antes, você também pode criar um diretamente da página do **Spaces**. Para fazer isso, clique **Spaces** na navegação principal do Painel de Controle, e então clique em **Create a space**. Qualquer uma das opções o levarão à tela **Create a Space** :

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/space-key/space-creator.png)

Primeiro, escolha um nome para o seu Space. Esse nome deve ser único entre todos os Spaces (ou seja, nenhum outro usuário do Spaces pode ter o mesmo nome em qualquer região), deve ter de 3 a 63 caracteres, e pode conter apenas letras minúsculas, números e traços.

Em seguida, escolha a região do datacenter onde você gostaria que seu Space estivesse. No momento em que esta captura de tela foi feita, `nyc3` e `ams3` eram as escolhas possíveis. Outras se tornarão dsponíveis ao longo do tempo.

Finalmente, escolha se deseja que os usuários não autenticados possam listar todos os arquivos em seu Space. Isso não afeta o acesso a arquivos individuais (que é definido em uma base por aquivo), mas apenas a capacidade de obter uma lista de todos os arquivos. A escolha padrão de **Private** é segura, a menos que você tenha alguns scripts ou clientes que precisem buscar listagens de arquivos sem uma chave de acesso ou access key.

Quando seu nome e as opções estiverem todos definidos, desça e clique no botão **Create a Space**. Seu Space será criado, e você será levado para a interface do navegador de arquivos:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/space-key/space-default.png)

Se este é o seu primeiro Space, você terá um arquivo **welcome.html** , do contrário, o Space estará vazio.

Tome nota da URL do seu Space. Está disponível logo abaixo do nome do Space na visualização do navegador de arquivos. Nesse caso de exemplo, a URL completa é **https://example-name.nyc3.digitaloceanspaces.com**. O nome do Space aqui (geralmente chamado de nome do bucket) é **example-name**. A URL do servidor (ou endereço) é a parte restante, consistindo do nome do datacenter seguido por **.digitaloceanspaces.com** : **[https://nyc3.digitaloceanspaces.com](https://nyc3.digitaloceanspaces.com/)**.

Existem algumas maneiras diferentes pelas quais os clientes e bibliotecas solicitarão essas informações. Alguns vão querer no mesmo formato dado no Painel de Controle. Alguns exigem que o nome do bucket siga a URL do servidor, como em [https://nyc3.digitaloceanspaces.com/](https://nyc3.digitaloceanspaces.com/)example-name. Outros ainda pedirão para você inserir o endereço do servidor e o nome do bucket ou Space separadamente. Consulte a documentação do seu cliente ou biblioteca para mais orientações nesse item.

A seguir, criaremos a chave que precisamos para acessar nossos Spaces a partir de clientes de terceiros.

## Criando uma Access Key

Para acessar seus arquivos de fora do Painel de Controle da DigitalOcean, precisamos gerar uma chave de acesso ou **access key** e um **secret**. Estes são um par de tokens aleatórios que servem como nome de usuário e senha para conceder acesso ao seu Space.

Primeiro, clique no link da **API** na navegação principal do Painel de Controle. A página resultante lista seus tokens de **API da DigitalOcean** e as chaves de acesso do **Spaces**. Role para baixo até a parte do Spaces:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/space-key/keys-default.png)

Se este é o seu primeiro Space, você não pode ter nenhuma chave listada. Clique no botão **Generate New Key**. A caixa de diálogo **New Spaces key** será exibida:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/space-key/new-key-dialog.png)

Digite um nome para a chave. Você pode criar quantas chaves quiser, portanto, lembre-se de que a única maneira de revogar o acesso a uma chave é excluí-la. Desse modo, você pode querer particionar as chaves por pessoa, por equipe ou pelo software cliente no qual você as estiver utilizando.

Neste caso, estamos criando uma chave chamada example-token. Clique no botão **Generate Key** para completar o processo. Você retornará à tela da API listando todas as suas chaves. Observe que a nova chave tem dois tokens longos exibidos:

![](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/space-key/new-key-display.png)

O primeiro é a sua **access key**. Isso não é secreto e continuará visível no Painel de Controle. A segunda string é o seu **secret** ou **secret key**. Isso só será exibido uma vez. Registre-a em um local seguro para uso posterior. Na próxima vez que você visitar a página da API, esse valor será eliminado e não há como recuperá-lo.

Diferentes clientes compatíveis com S3 podem ter nomes sutilmente diferentes para **access key** e **secret**. A terminologia usada é normalmente próxima o suficiente para deixar claro qual token deve ir para onde. Caso contrário, consulte a documentação do seu cliente ou biblioteca para obter mais informações.

## Conclusão

Neste tutorial criamos um novo Space na DigitalOcean e uma nova access key e secret. Agora sabemos nossa **URL de servidor** , **nome do bucket** (ou nome do Space), **access key** , e **secret**. Com essas informações você pode conectar praticamente qualquer cliente ou biblioteca compatível com S3 ao seu novo Space na DigitalOcean!

_Por Brian Boucheron_
