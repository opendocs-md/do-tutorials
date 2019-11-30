---
author: Brian Boucheron
date: 2018-07-26
language: pt
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/servicos-de-armazenamento-de-objetos-versus-armazenamento-em-blocos-pt
---

# Serviços de Armazenamento de Objetos versus Armazenamento em Blocos

### Introdução

O armazenamento de dados flexível e escalável é um requisito básico para a maioria dos aplicativos e serviços que estão sendo desenvolvidos com técnicas e ferramentas modernas. Seja armazenando grandes ou pequenas quantidades de imagens, vídeos ou pequenos blocos de texto, os desenvolvedores de aplicativos precisam de uma solução para o armazenamento e a recuperação do conteúdo gerado por usuários, logs, backups e assim por diante.

Com os deployments complexos atuais, containers, e infraestrutura efêmera, os dias de simplesmente salvar arquivos no disco em um único servidor acabaram. Provedores de nuvem desenvolveram serviços para preencher as necessidades de armazenamento dos deployments de aplicações modernas, e eles se encaixam principalmente em duas categorias: armazenamento de objetos e armazenamento em blocos.

Vamos dar uma olhada em ambos e discutir as vantagens, desvantagens e casos de uso para cada um.

## O que é o Armazenamento em Blocos

Os serviços de armazenamento em blocos ou block storage são relativamente simples e familiares. Eles fornecem um dispositivo de armazenamento em blocos tradicional — como um disco rígido — através da rede. Os provedores de nuvem geralmente têm produtos que podem provisionar um dispositivo de armazenamento em blocos de qualquer tamanho e anexá-lo à sua máquina virtual.

A partir disso, você poderia tratá-lo como um disco normal. Você pode formatá-lo com um sistema de arquivos e armazenar arquivos nele, combinar vários dispositivos em um RAID, ou configurar um banco de dados para gravar diretamente no dispositivo de blocos, evitando completamente a sobrecarga do sistema de arquivos. Além disso, os dispositivos de armazenamento em blocos conectados à rede geralmente têm algumas vantagens exclusivas em relação aos discos rígidos normais:

- Você pode tirar snapshots ou instantâneos ao vivo de todo o dispositivo para fins de backup
- Dispositivos de armazenamento em blocos podem ser redimensionados para acomodar as necessidades de crescimento
- Você pode facilmente desanexar e mover dispositivos de armazenamento em blocos entre as máquinas

Esta é uma configuração muito flexível que pode ser útil para a maioria dos aplicativos de qualquer tipo. Vamos resumir algumas vantagens e desvantagens da tecnologia.

**Algumas vantagens do armazenamento em blocos são:**

- O Armazenamento em blocos é um paradigma familiar. Pessoas e softwares entendem e suportam arquivos e sistemas de arquivos quase que universalmente
- Dispositivos de blocos são bem suportados. Toda linguagem de programação pode ler e gravar arquivos facilmente
- Permissões de sistema de arquivos e controles de acesso são familiares e bem entendidos
- Os dispositivos de armazenamento em bloco fornecem I/O de baixa latência, sendo então, adequados para uso por bancos de dados.

**As desvantagens do armazenamento em blocos são:**

- O armazenamento em blocos está ligado a um servidor de cada vez
- Blocos e sistemas de arquivos tem metadados limitados sobre os blobs de informações que eles estão armazenando (data da criação, proprietário, tamanho). Qualquer informação adicional sobre o que você está armazenando tem que ser tratada no nível da aplicação e do banco de dados, o que é uma complexidade adicional para um desenvolvedor se preocupar
- Você precisa pagar por todo o espaço de armazenamento em blocos que você alocou, mesmo que você não o esteja usando
- Você só pode acessar o armazenamento em blocos através de um servidor em execução
- O armazenamento em blocos precisa de mais trabalho e configuração manual se comparado ao armazenamento de objetos (escolha de sistemas de arquivos, permissões, versionamento, backups, etc).

Devido às suas características de I/O rápida, os serviços de armazenamento em blocos são adequados para armazenar dados em bancos de dados tradicionais. Além disso, muitos aplicativos legados que exigem armazenamento normal do sistema de arquivos precisarão usar um dispositivo de armazenamento em blocos.

Se o seu provedor de nuvem não oferece um serviço de armazenamento em blocos, você pode executar o seu próprio serviço usando [OpenStack Cinder](https://www.openstack.org/software/releases/ocata/components/cinder), [Ceph](http://ceph.com/), ou o serviço iSCSI integrado disponível em muitos dispositivos NAS.

## O que é o Armazenamento de Objetos

No mundo moderno da computação em nuvem, o armazenamento de objetos ou object storage é o armazenamento e a recuperação de blobs (grandes objetos binários) não estruturados de dados e metadados utilizando uma API HTTP. Em vez da quebra dos arquivos em blocos para armazená-los em disco usando um sistema de arquivos, lidamos com objetos inteiros armazenados na rede. Esses objetos podem ser um arquivo de imagem, logs, arquivos HTML ou qualquer bloco de bytes auto contido. Eles são _não estruturados_ porque não há um esquema ou formato específico que eles precisem seguir.

O Armazenamento de Objetos decolou porque simplificou muito a experiência do desenvolvedor. Como a API consiste de solicitações HTTP padrão, bibliotecas são rapidamente desenvolvidas para a maioria das linguagens de programação. O salvamento de um blob de dados tornou-se tão fácil quanto uma solicitação HTTP PUT ao object store. A recuperação de arquivo e metadados é uma solicitação GET normal. Além disso, a maioria dos serviços de armazenamento de objetos também pode servir os arquivos publicamente para seus usuários, eliminando a necessidade de manter um servidor web para hospedar recursos estáticos.

Além do mais, os serviços de armazenamento de objetos cobram apenas pelo espaço de armazenamento que você usa (alguns também cobram por solicitação HTTP e por largura de banda de transferência). Isso é um benefício para pequenos desenvolvedores, que podem obter armazenamento de classe mundial e hospedagem de recursos a custos que aumentam com o uso.

Entretanto, o armazenamento de objetos não é a solução ideal para todas as situações. Vamos olhar um resumo dos benefícios e desvantagens.

**Algumas vantagens do armazenamento de objetos são:**

- Uma API HTTP simples, com clientes disponíveis para todos os principais sistemas operacionais e linguagens de programação 
- Uma estrutura de custos na qual que você paga apenas pelo que usa
- Um serviço interno de publicação de recursos significando um servidor a menos que você precisa gerenciar
- Alguns provedores armazenamento de objetos oferecem integração com CDN, que armazena seus recursos em cache em todo o mundo para fazer downloads e carregamentos de página mais rápidos para seus usuários
- O versionamento opcional significa que você pode recuperar versões antigas de objetos para se proteger da sobrescrita acidental de dados
- Os serviços de armazenamento de objetos podem escalar facilmente de necessidades modestas para casos de uso realmente intensos, sem que o desenvolvedor tenha que lançar mais recursos ou rearquitetar a aplicação para lidar com a carga
- Usar um serviço de armazenamento de objetos significa que você não precisa manter discos rígidos e matrizes RAID, pois isso é feito pelo provedor de serviços.
- A capacidade de armazenar trechos de metadados junto com seu blob de dados pode simplificar ainda mais a arquitetura do seu aplicativo

**Algumas desvantagens do armazenamento de objetos são:**

- Você não pode utilizar serviços de armazenamento de objetos para manter um banco de dados tradicional, devido à alta latência desses serviços
- O armazenamento de objetos não permite que você altere apenas um fragmento de dados, você deve ler e escrever um objeto inteiro de uma só vez. Por exemplo, em um sistema de arquivos, você pode facilmente adicionar uma única linha ao final de um arquivo de log. Em um sistema de armazenamento de objetos, você precisaria recuperar o objeto, adicionar a nova linha e gravar todo o objeto de volta. Isso torna o armazenamento de objetos menos ideal para dados que mudam com muita frequência
- Sistemas operacionais não podem montar facilmente um armazenamento de objetos como um disco normal. Existem alguns clientes e adaptadores para ajudar nisso, mas em geral, usar e navegar em um armazenamento de objetos não é tão simples quanto folhear diretórios em um navegador de arquivos

Devido a essas propriedades, o armazenamento de objetos é útil para hospedar recursos estáticos, salvamento de conteúdo criado por usuários tais como imagens e filmes, armazenamento de arquivos de backup, armazenamento de logs, por exemplo.

Existem algumas soluções de armazenamento de objetos que você pode hospedar, embora você tenha que abrir mão de alguns dos benefícios de uma solução hospedada (como não ter que se preocupar com discos rígidos e problemas de dimensionamento). Você pode experimentar o [Minio](https://www.minio.io/), um popular servidor de armazenamento de objetos escrito na linguagem Go, o [Ceph](http://ceph.com/), ou o [OpenStack Swift](https://www.openstack.org/software/releases/ocata/components/swift).

## Conclusão

A escolha de uma solução de armazenamento pode ser uma decisão complexa para desenvolvedores. Neste artigo discutimos as vantagens e desvantagens tanto dos serviços de armazenamento em blocos quanto dos serviços de armazenamento de objetos. É provável que qualquer aplicativo suficientemente complexo precisará dos dois tipos de armazenamento para atender a todas as suas necessidades.
