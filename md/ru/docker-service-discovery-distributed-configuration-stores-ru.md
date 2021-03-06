---
author: Justin Ellingwood
date: 2015-06-29
language: ru
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/docker-service-discovery-distributed-configuration-stores-ru
---

# Экосистема Docker: обнаружение сервисов (Service Discovery) и распределённые хранилища конфигураций (Distributed Configuration Stores)

## Серия туториалов

Этот туториал является 3-ой частью из 5-ти в серии статей **Экосистема Docker**.

### Введение

Контейнеры предоставляют элегантное решение для тех, кто собирается проектировать и разворачивать масштабируемые приложения. В то время, как Docker реализует технологию контейнеризации, многие другие проекты помогают в развитии инструментов, необходимых для непосредственного процесса разработки.

Одной из ключевых технологий, на которую опираются многие инструменты работающие с Docker, является обнаружение сервисов (Service discovery). Обнаружение сервисов позволяет приложению или компоненту получать информацию об их окружении и “соседях”. Как правило, данный функционал реализуется при помощи распределённого хранилища “ключ-значение” (“key-value”), которое также может служить для хранения деталей конфигурации. Настройка инструмента обнаружения сервисов позволяет Вам разделить runtime-конфигурацию и сам контейнер, что позволяет использовать один и тот же образ в нескольких окружениях.

В данном руководстве мы обсудим преимущества обнаружения сервисов в кластеризованном Docker-окружении. Мы сфокусируемся на основных концепциях, но так же приведём и более конкретный примеры, где это будет уместно.

## Обнаружение сервисов и глобально доступные хранилища конфигураций (Globally Accessible Configuration Stores)

Главная идея, лежащая в основе обнаружения сервисов, состоит в том, что любой новый экземпляр приложения должен быть в состоянии программно определить детали своего текущего окружения. Это необходимо для того, чтобы новый экземпляр мог подключиться к существующему окружению приложения без ручного вмешательства. Инструменты обнаружения сервисов обычно реализованы в виде глобально доступных реестров, которые хранят информацию об экземплярах приложений и сервисов, запущенных в данный момент. Большую часть времени реестр распределён по доступным в инфраструктуре хостам, чтобы сделать систему устойчивой к ошибкам (fault tolerant) и масштабируемой.

Хотя основная цель инструментов по обнаружения сервисов состоит в предоставлении деталей подключения для связи компонентов вместе, они так же могут использоваться для хранения любого типа конфигурационной информации. Многие приложения используют эту возможность в своих целях, сохраняя свою конфигурационную информацию с помощью инструмента обнаружения сервисов. Если контейнеры сконфигурированы таким образом, что они знают о необходимости проверять эти детали, они могут модифицировать своё поведение на основе найденных данных.

## Как работает обнаружение сервисов?

Каждый инструмент обнаружения сервисов предоставляет API, который компоненты могут использовать для записи или получения данных. По этой причине для каждого компонента адрес обнаружения служб (service discovery address) должен быть либо жестко прописан в самом приложении/контейнере, либо предоставляться во время исполнения (runtime). Обычно, обнаружения сервисов реализовано в виде хранилища “ключ-значение”, доступного через стандартные методы http.

Инструмент обнаружения сервисов работает следующим образом: при запуске какого-либо сервиса, этот сервис регистрирует себя с помощью инструмента обнаружении сервисов. Инструмент обнаружения сервисов записывает всю информацию об этом сервисе, которая может понадобиться другим сервисам, работающим с данным, вновь запущенным, сервисом. Например, база данных MySQL может зарегистрировать IP-адрес и порт, на котором запущен демон, и, опционально, имя пользователя и учетные данные для входа.

При запуске потребителя первого сервиса, этот потребитель может запросить в реестре обнаружения сервисов информацию о первом сервисе. После этого потребитель может взаимодействовать с необходимыми компонентами, основываясь на полученной информации. Хорошим примером является балансировщик нагрузки (load balancer). Он может найти все backend-сервера, на которые можно распределять трафик, посылая запрос к службе обнаружения сервисов и изменяя свою конфигурацию соответствующим образом.

Таким образом, детали конфигурации оказываются вынесены за пределы самих контейнеров. Одним из преимуществ этого является бОльшая гибкость контейнеров и меньшая привязка к конкретной конфигурации. Другое преимущество - за счет возможности динамического переконфигурирования компонентам проще начать взаимодействие с новыми экземплярами связанных сервисов.

## Как конфигурационное хранилище связано с обнаружением сервисов?

Ключевое преимущество глобально распределенной системы обнаружения сервисов состоит в том, что она может хранить любой другой тип конфигурационных данных, который может понадобиться Вашим компонентам во время выполнения. Это означает, что Вы можете вынести больше конфигурации из контейнера в среду выполнения более высокого уровня.

Обычно, для наиболее эффективной работы Ваши приложения должны быть спроектированы с разумными значения по умолчанию, которые могут быть переопределены во время выполнения приложений путем запросов к конфигурационному хранилищу. Это позволяет Вам использовать конфигурационное хранилище схожим образом с использованием флагов в командной строке. Различие заключается в том, что используя глобально доступное хранилище, Вы можете задать одинаковые настройки каждому экземпляру компонента без дополнительной работы.

## Как конфигурационное хранилище помогает в управлении кластером?

Одна из функций распределенных хранилищ “ключ-значение” при развёртывании Docker, которая может быть не сразу очевидна, это хранение и управление данными о хостах кластера. Конфигурационные хранилища - прекрасный способ для отслеживания членства хоста в кластере для инструментов управления.

Вот пример информации о хосте, которая может храниться в распределенном хранилище “ключ-значение”:

- IP-адрес хоста.
- Информация о подключении для самих хостов.
- Произвольные метаданные и ярлыки, которые могут использоваться планировщиком (scheduler).
- Роль в кластере (если используется схема “ведущий-ведомый”).

Эти данные, возможно, не то, о чём Вам надо заботиться при использовании системы обнаружения сервисов в обычных обстоятельствах, но они предоставляют инструментам управления возможность получать и модифицировать информацию о самом кластере.

## Что насчёт обнаружения отказов (Failure Detection)?

Обнаружение отказов может быть реализовано несколькими способами. Суть заключается в том, что в случае отказа компонента система обнаружения сервисов должна узнать об этом и отражать факт, что указанный компонент больше не доступен. Данный тип информации жизненно необходим для минимизации отказов приложения или сервиса.

Многие системы обнаружения сервисов позволяют задавать значения с настраиваемым тайм-аутом. Компонент может установить значения с тайм-аутом и регулярно пинговать обнаружение сервисов. Если происходит отказ компонента, и достигается тайм-аут, информация о подключении для этого компонента удаляется из хранилища. Длительность тайм-аута, в основном, зависит от того, как быстро приложение должно реагировать на отказ компонента.

Это также может быть достигнуто путём привязки к каждому компоненту вспомогательного контейнера, единственная цель которого - периодически проверять работоспособность компонента и обновлять реестр в случае его отказа. Проблемой данного типа архитектуры является возможность отказа вспомогательного контейнера, что может привести к некорректной информации в хранилище. Некоторые системы решают эту задачу возможностью проверки работоспособности компонентов при помощи инструмента обнаружения сервисов. В этом случае, сама система обнаружения может периодически проверять, является ли зарегистрированный компонент по-прежнему доступным.

## Что насчёт перенастройки сервисов при изменении параметров?

Одно из ключевых улучшений базовой модели обнаружения сервисов - динамическая перенастройка. В то время, как обычное обнаружение сервисов позволяет Вам влиять на изначальную конфигурацию компонентов, проверяя информацию при запуске, динамическая перенастройка включает конфигурирование Ваших компонентов для реагирования на новую информацию в конфигурационном хранилище. Например, если вы реализуете балансировщик нагрузки (load balancer), проверка работоспособности бэкэнд-серверов может показать, что один из них упал. Запущенный экземпляр балансировщика нагрузки должен быть проинформирован об этом и должен иметь возможность обновить свою конфигурацию.

Это может быть реализовано несколькими способами. Поскольку пример с балансировщиком нагрузки является одним из основных сценариев использования данного функционала, существует несколько проектов, фокусирующихся исключительно на перенастройке балансировщика нагрузки при обнаружении изменений конфигурации. Поправка конфигурации HAProxy является типичным примером, ввиду его распространенности в сфере балансировки нагрузки.

Некоторые проекты являются более гибкими в том смысле, что они могут использоваться для вызова изменений в любом типе программного обеспечения. Эти инструменты регулярно опрашивают систему обнаружения сервисов и, при обнаружении изменений, используют системы шаблонов для генерации конфигурационных файлов с учетом последних изменений. После генерации нового конфигурационного файла затронутый сервис перезагружается.

Такой тип динамической перенастройки требует больше планирования и конфигурации на этапе сборки, т.к. все эти механизмы должны существовать в контейнере компонента. Это делает сам контейнер ответственным за исправление своей конфигурации. Определение того, какие значения необходимо записать в систему обнаружения сервисов, и проектирование подходящих структур данных - отдельная непростая задача, но преимущества и гибкость такого подхода могут быть существенными.

## Что насчет безопасности?

Одним из вопросов, беспокоящих большинство людей, когда они впервые слышат о глобально доступном конфигурационном хранилище, небезосновательно является безопасность. Нормально ли это - хранить информацию о подключении в доступном откуда угодно месте?

Ответ на этот вопрос во многом зависит от того, какие данные Вы помещаете в хранилище, и сколько уровней безопасности Вы считаете необходимыми для защиты своих данных. Почти все системы обнаружения сервисов позволяют шифровать соединения через SSL/TLS. Для некоторых сервисов приватность может быть не очень важна, и помещения системы обнаружения служб в приватную сеть может быть достаточно. Однако, для большинства сервисов, скорее всего, будет лучше предусмотреть дополнительные меры безопасности.

Есть несколько разных подходов в этой проблеме, и разные проекты предлагают свои собственные решения. Решение одного из проектов - предоставлять открытый доступ к самой системе обнаружения сервисов, но шифровать записываемые в нее данные. Приложение-потребитель данных должно иметь соответствующий ключ для расшифровки данных, полученных из хранилища. Третья сторона не сможет получить доступ к расшифрованным данным.

Другой подход заключается в ведении списков контроля доступа для разделения всего набора ключей в хранилище на отдельные зоны. Система обнаружения сервисов при этом может назначать владельцев и предоставлять доступ к разным ключам на основании требований, определённых для каждой конкретной зоны. Это позволяет предоставлять доступ к информации одним пользователя, сохраняя при этом её недоступной для других пользователей. Каждый компонент может быть сконфигурирован таким образом, чтобы иметь доступ только к необходимой ему информации.

## Какие инструменты обнаружения сервисов наиболее популярны?

Теперь, когда мы обсудили некоторые общие особенности инструментов обнаружения сервисов и глобально распределенных хранилищ “ключ-значение”, мы можем упомянуть некоторые проекты, связанные с этими концепциями.

Вот список некоторых из наиболее распространённых инструментов обнаружения сервисов:

- **etcd** : Этот инструмент был создан разработчиками CoreOS для предоставления обнаружения сервисов и глобально распределенной конфигурации как для контейнеров, так и для самих хост-систем. Он реализует http API и имеет клиент для командной строки, доступный на каждой хост-машине.
- **consul** : Эта система обнаружения сервисов имеет много продвинутых возможностей, выделяющих ее из других, включая конфигурируемые проверки работоспособности, функционал ACL (access control list - список контроля доступа), конфигурацию HAProxy и т.д.
- **zookeeper** : Данный продукт несколько старше двух предыдущих и представляет собой более зрелую систему, не имеющую при этом некоторых возможностей упомянутых ранее продуктов.

Некоторые другие проекты, расширяющие базовые возможности инструментов обнаружения сервисов:

- **crypt** : Позволяет компонентам защищать информацию, которую они записывают, при помощи шифрования публичным ключом. Компоненты, которые должны читать данные, могут быть снабжены ключом для расшифровки. Остальные будут неспособны прочитать данные.
- **confd** : Данные проект нацелен на возможность реконфигурации произвольных приложений на основе изменения в системе обнаружения сервисов. Система включает в себя инструмент для наблюдения за интересующими изменениями, систему шаблонов для сборки новых конфигурационных файлов на основе полученной информации и способность перезагружать затронутые изменениями приложения.
- **vulcand** : Работает как балансировщик нагрузки для групп компонентов. Он знает о существовании etcd и изменяет свою конфигурацию на основании изменений в хранилище.
- **marathon** : Хотя данный инструмент в основном является планировщиком (scheduler), он также реализует базовые возможности перезагрузки HAProxy в случае возникновения изменений в сервисах, между которыми он должен проводить балансировку.
- **frontrunner** : Данный проект работает в сцепке с marathon для предоставления более надежного решения по обновлению HAProxy.
- **synapse** : Проект представляет встроенный экземпляр HAProxy, который может маршрутизировать трафик между компонентами.
- **nerve** : Используется в сочетании с synapse для предоставления возможности проверки работоспособности экземпляров отдельного компонента. Если компонент становится недоступен, nerve обновляет synapse для удаления компонента из списка доступных.

## Заключение

Обнаружения сервисов и глобальные конфигурационные хранилища позволяют Docker-контейнерам адаптироваться к их текущему окружению и включаться в существующую систему компонентов. Это необходимое условие для предоставления простой автоматической масштабируемости и развёртывания путем предоставления компонентам возможности отслеживать изменения в их окружении и реагировать на них.

В [следующем руководстве](the-docker-ecosystem-networking-and-communication) мы обсудим способы взаимодействия Docker-контейнеров и хостов при помощи настраиваемых сетевых конфигураций.
