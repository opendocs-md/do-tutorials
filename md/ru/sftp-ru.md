---
author: Justin Ellingwood
date: 2015-02-04
language: ru
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/sftp-ru
---

# Как использовать SFTP для безопасного обмена файлами с удаленным сервером

### Что такое SFTP?

FTP (“File Transfer Protocol” - протокол передачи файлов) - это популярный способ передачи файлов между двумя удаленными системами.

SFTP (“SSH File Transfer Protocol” или “Secure File Transfer Protocol”) - это отдельный протокол с SSH, который работает аналогичным образом, но с использованием защищенного соединения. Его преимуществом является способность использовать защищенное соединение для передачи файлов и навигации по файловой системе на обеих системах - локальной и удаленной.

Почти во всех случаях, SFTP предпочтительнее FTP, из-за его встроенной поддержки шифрования. FTP - небезопасный протокол, который следует использовать лишь в ограниченных случаях или в сети, которой Вы доверяете.

Хотя SFTP встроен во многие приложения с графическим интерфейсом пользователя, в этом руководстве мы покажем, как использовать его с помощью интерактивного интерфейса командной строки.

## Как установить соединение через SFTP

По умолчанию, SFTP использует протокол SSH для авторизации и установки безопасного соединения. По этой причине в SFTP доступны те же методы авторизации, которые существуют в SSH.

Хотя пароли просты в использовании и используются по умолчанию, мы рекомендуем создать SSH ключи и передать Ваш открытый ключ на все системы, куда Вам нужен доступ. Данный способ гораздо более безопасен и в дальнейшем сэкономит Вам время.

Пожалуйста, посмотрите [руководство по настройке SSH-ключей](https://www.digitalocean.com/community/articles/how-to-set-up-ssh-keys--2) для доступа к Вашему серверу, если Вы еще этого не делали.

Если Вы можете зайти на машину по SSH, значит Вы выполнили все необходимые действия для использования SFTP для передачи файлов. Протестируйте доступ по SSH при помощи следующей команды:

    ssh username@remote_hostname_or_IP

Если все работает, выйдите обратно при помощи команды:

    exit

Мы можем установить SSH-соединение и затем открыть SFTP-сессию через это соединение с помощью следующей команды:

    sftp username@remote_hostname_or_IP

Вы подключитесь к удаленной системе и подсказка командной строки изменится на соответствующую для SFTP.

## Получение справки в SFTP

Самой полезной командой, которую стоит выучить первой, является команда `help` (помощь, справка). С её помощью Вы получите доступ к краткой справочной информации по SFTP. Вы можете вызвать её, используя любую из следующих команд:

    help

    ?

В результате на экране будет отображён список доступных команд:

    Available commands:
    bye Quit sftp
    cd path Change remote directory to 'path'
    chgrp grp path Change group of file 'path' to 'grp'
    chmod mode path Change permissions of file 'path' to 'mode'
    chown own path Change owner of file 'path' to 'own'
    df [-hi] [path] Display statistics for current directory or
                                       filesystem containing 'path'
    exit Quit sftp
    get [-Ppr] remote [local] Download file
    help Display this help text
    lcd path Change local directory to 'path'
    . . .

В следующих разделах мы расскажем подробнее о некоторых из этих командах.

## Навигация с помощью SFTP

Мы можем перемещаться по файловой иерархии удаленной системы при помощи ряда команд, которые функционируют так же, как их аналоги в shell.

Для начала, давайте поймём, в какой директории мы находимся в удаленной системе. Как и в обычной shell-сессии мы можем выполнить следующую команду для определения текущей директории:

    pwd

    Remote working directory: /home/demouser

Мы можем посмотреть содержимое текущей директории удаленной системы при помощи другой знакомой команды:

    ls

    Summary.txt info.html temp.txt testDirectory

Имейте ввиду, что команды в SFTP-интерфейсе не являются полноценными shell-командами и не так богаты опциями, но они имеют некоторые наиболее важные опциональные флаги:

    ls -la

    drwxr-xr-x 5 demouser demouser 4096 Aug 13 15:11 .
    drwxr-xr-x 3 root root 4096 Aug 13 15:02 ..
    -rw------- 1 demouser demouser 5 Aug 13 15:04 .bash_history
    -rw-r--r-- 1 demouser demouser 220 Aug 13 15:02 .bash_logout
    -rw-r--r-- 1 demouser demouser 3486 Aug 13 15:02 .bashrc
    drwx------ 2 demouser demouser 4096 Aug 13 15:04 .cache
    -rw-r--r-- 1 demouser demouser 675 Aug 13 15:02 .profile
    . . .

Для смены директории мы можем использовать команду:

    cd testDirectory

Теперь мы можем перемещаться по удаленной файловой системе, но что если нам необходим доступ к локальной файловой системе? Мы можем направить команды на локальную файловую систему путем добавления префикса “l”.

Все команды, которые мы рассмотрели, имеют локальные эквиваленты. Мы можем узнать текущую локальную директорию:

    lpwd

    Local working directory: /Users/demouser

Мы можем вывести список содержимого текущей директории на локальной машине:

    lls

    Desktop local.txt test.html
    Documents analysis.rtf zebra.html

Мы также можем изменить директорию, с которой мы хотим работать на локальной системе:

    lcd Desktop

## Передача файлов через SFTP

Навигация в удаленной и локальной файловых системах малополезна без возможности передачи файлов между ними.

### Передача удаленных файлов на локальную систему

Если мы хотим загрузить файлы с нашего удаленного хоста, мы можем сделать это следующей командой:

    get remoteFile

    Fetching /home/demouser/remoteFile to remoteFile
    /home/demouser/remoteFile 100% 37KB 36.8KB/s 00:01

По умолчанию, команда “get” загружает удаленный файл на локальную файловую систему с таким же именем файла.

Мы можем скопировать удаленный файл на локальную систему с другим именем файла путем добавления имени в конце:

    get remoteFile localFile

Команда “get” также имеет опциональные параметры. Например, мы можем скопировать директорию со всем ее содержимым путем добавления параметра рекурсии `-r`:

    get -r someDirectory

Мы может указать SFTP сохранить соответствующие привилегии и дату и время доступа путем добавления параметров “-P” или “-p”:

    get -Pr someDirectory

### Передача локальных файлов на удаленную систему

Передача файлов на удаленную систему осуществляется так же легко при помощи команды с соответствующим названием “put”:

    put localFile

    Uploading localFile to /home/demouser/localFile
    localFile 100% 7607 7.4KB/s 00:00

Такие же параметры, какие работают с “get”, есть и у “put”. Так что для копирования локальной директории целиком используйте:

    put -r localDirectory

Знакомая команда “df”, которая полезна при передаче файлов, работает аналогично с ее shell-версией. С ее помощью Вы можете проверить, достаточно ли места для передачи нужного Вам файла:

    df -h

        Size Used Avail (root) %Capacity
      19.9GB 1016MB 17.9GB 18.9GB 4%

Обратите внимание, что для этой команды не существует локальной версии (с префиксом “l”), но эту проблему можно обойти при помощи команды “!”.

Команда “!” переводит нас в локальный shell, где мы можем выполнить любую команду, доступную в нашей локальной системе. Проверить статистику использование диска можно следующим образом:

    !
    df -h

    Filesystem Size Used Avail Capacity Mounted on
    /dev/disk0s2 595Gi 52Gi 544Gi 9% /
    devfs 181Ki 181Ki 0Bi 100% /dev
    map -hosts 0Bi 0Bi 0Bi 100% /net
    map auto_home 0Bi 0Bi 0Bi 100% /home

Тем не менее, любая другая локальная команда будет работать. Для возврата к Вашей SFTP-сессии введите:

    exit

После этого подсказка командной строки изменится на соответствующую для SFTP.

## Простые операции с файлами через SFTP

SFTP позволяет производить базовые операции с файлами, которые полезны при работе с иерархией файлов.

Например, Вы можете изменить владельца файла на удаленной системе следующим образом:

    chown userID file

Обратите внимание, что, в отличие от системной команды “chmod”, SFTP-команда принимает в виде параметра не имя пользователя, а его идентификатор. К сожалению, не существует простого способа узнать идентификатор пользователя из SFTP-интерфейса.

Проблему можно обойти следующим образом:

    get /etc/passwd
    !less passwd

    root:x:0:0:root:/root:/bin/bash
    daemon:x:1:1:daemon:/usr/sbin:/bin/sh
    bin:x:2:2:bin:/bin:/bin/sh
    sys:x:3:3:sys:/dev:/bin/sh
    sync:x:4:65534:sync:/bin:/bin/sync
    games:x:5:60:games:/usr/games:/bin/sh
    man:x:6:12:man:/var/cache/man:/bin/sh
    . . .

Обратите внимание, как вместо самостоятельного использования команды “!”, мы использовали её в качестве префикса для локальной shell-команды. Данный способ работает для выполнеия любой команды, доступной на Вашей локальной машине, и может быть использован с локальной командой “df”, показанной ранее.

Идентификатор пользователя будет отображаться в третьем столбце файла (столбцы разделены двоеточием).

Аналогично мы можем изменить группу владельцев файла (`group owner`):

    chgrp groupID file

И опять, не существует простого способа получить список групп удаленной системы. Данную проблему можно обойти при помощи следующей команды:

    get /etc/group
    !less group

    root:x:0:
    daemon:x:1:
    bin:x:2:
    sys:x:3:
    adm:x:4:
    tty:x:5:
    disk:x:6:
    lp:x:7:
    . . .

Третий столбец содержит идентификатор группы, имя которой указано в первом столбце. Это как раз то, что мы ищем.

Команда “chmod” на удаленной файловой системе работает ожидаемым образом:

    chmod 777 publicFile

    Changing mode on /home/demouser/publicFile

Команды для изменения прав доступа к локальным файлам нет, но Вы можете настроить локальную umask (маска режима создания пользовательских файлов) так, чтобы любые файлы, копируемые в локальную систему, будут иметь соответствующие права доступа.

Это может быть сделано при помощи команды “lumask”:

    lumask 022

    Local umask: 022

Теперь все загруженные файлы (без использования параметра “-p”) будут иметь права доступа 664.

SFTP позволяет Вам создавать директории на обоих системах, локальной и удаленной, при помощи команд “lmkdir” и “mkdir” соответственно. Они работают обычным образом.

Следующие команды работают только на удаленной файловой системе:

    ln
    rm
    rmdir

Эти команды копируют основное поведение соответствующих shell-версий. Если Вам необходимо выполнить их на локальной файловой системе, помните, что вы можете перейти в shell при помощи команды:

    !

Или выполнить одну команду на локальной системе путем добавления “!” в качестве префикса следующим образом:

    !chmod 644 somefile

Когда Вы закончили работу с SFTP-сессией, используйте команды “exit” или “bye”, чтобы закрыть соединение.

    bye

## Заключение

Несмотря на то, что SFTP - простой инструмент, он очень полезен для администрирования серверов и передачи файлов между ними.

Если Вы привыкли использовать FTP или SCP для передачи файлов, SFTP - хороший способ сочетать сильные стороны обоих. Хотя он подходит не для всех ситуаций, это гибкий инструмент, который полезно иметь на вооружении.
