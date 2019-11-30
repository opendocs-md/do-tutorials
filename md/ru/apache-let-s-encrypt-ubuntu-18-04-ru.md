---
author: Kathleen Juell, Erika Heidi
date: 2018-08-03
language: ru
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/apache-let-s-encrypt-ubuntu-18-04-ru
---

# Как повысить безопасность Apache с помощью Let's Encrypt в Ubuntu 18.04

### Введение

Let’s Encrypt представляет собой центр сертификации (Certificate Authority, CA), позволяющий получать и устанавливать бесплатные [сертификаты TLS/SSL](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs), тем самым позволяя использовать шифрованный HTTPS на веб-серверах. Процесс получения сертификатов упрощается за счёт наличия клиента Certbot, который пытается автоматизировать большую часть (если не все) необходимых операций. В настоящее время весь процесс получения и установки сертификатов полностью автоматизирован и для Apache и для Nginx.

В этом руководстве мы используем Certbot для получения бесплатного SSL сертификата для Apache на Ubuntu 18.04, а также настроим автоматическое продление этого сертификата.

В этом руководстве мы будем использовать файл отдельного виртуального хоста Apache вместо дефолтного файла конфигурации. [Мы рекомендуем](how-to-install-the-apache-web-server-on-ubuntu-18-04#step-5-%E2%80%94-setting-up-virtual-hosts-recommended) создавать новый файлы виртуальных хостов Apache для каждого доменного имени, потому что это помогает избегать распространённых ошибок и использовать дефолтные файлы в качестве примера корректной конфигурации, когда что-нибудь пойдёт не так.

## Перед установкой

Перед тем, как начать следовать описанным в этой статье шагам, убедитесь, что у вас есть:

- Сервер с Ubuntu 18.04, настроенный согласно [руководству по первичной настройке сервера с Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04), включая настройку не-рутового (non-root) пользователя с привилегиями `sudo` и настройку файрвола.
- Зарегистрированное доменное имя. В этом руководстве мы будем использовать **example.com**. Вы можете приобрести доменное имя на [Namecheap](https://namecheap.com/), получить бесплатное доменное имя на [Freenom](http://www.freenom.com/en/index.html) или использовать любой другой регистратор доменных имён.
- Для вашего сервера настроены обе записи DNS, указанные ниже. Для их настройки вы можете использовать наше [введение в работу с DNS в DigitalOcean](an-introduction-to-digitalocean-dns).
  - Запись `A` для `example.com`, указывающая на публичный IP адрес вашего сервера.
  - Запись `A` для `www.example.com`, указывающая на публичный IP адрес вашего сервера.
- Apache, установленный согласно инструкциям из руководства [Как установить Apache в Ubuntu 18.04](how-to-install-the-apache-web-server-on-ubuntu-18-04). Убедитесь, что у вас есть настроенный [файл виртуального хоста](how-to-install-the-apache-web-server-on-ubuntu-18-04#step-5-%E2%80%94-setting-up-virtual-hosts-recommended) для вашего домена. В этом руководстве мы будем использовать `/etc/apache2/sites-available/example.com.conf` в качестве примера.

## Шаг 1 - Установка Certbot

Перед началом использования Let’s Encrypt для получения SSL сертификаты установим Certbot на ваш сервер.

Certbot находится в активной разработке, поэтому пакеты Certbot, предоставляемые Ubuntu, обычно являются устаревшими. Тем не менее, разработчики Certbot поддерживают свой репозиторий пакетов для Ubuntu с актуальными версиями, поэтому мы будем использовать именно этот репозиторий.

Сначала добавим репозиторий:

    sudo add-apt-repository ppa:certbot/certbot

Далее нажмите `ENTER`.

Установим пакет Certbot для Apache с помощью `apt`:

    sudo apt install python-certbot-apache

Теперь Certbot готов к использованию, но для того, чтобы он мог настроить SSL для Apache, нам сперва необходимо проверить кое-какие настройки Apache.

## Шаг 2 - Настройка SSL сертификата

Certbot должен иметь возможность найти корректный виртуальный хост в вашей конфигурации Apache для того, чтобы автоматически конфигурировать SSL. Для этого он будет искать директиву `ServerName`, которая совпадает с доменным именем, для которого вы запросите сертификат.

Если вы следовали инструкциям по [настройке виртуального хоста в руководстве по установке Apache](how-to-install-the-apache-web-server-on-ubuntu-18-04#step-5-%E2%80%94-setting-up-virtual-hosts-recommended), у вас должен быть виртуальный хост для вашего домена по адресу `/etc/apache2/sites-available/example.com.conf` с уже правильно настроенной директивой `ServerName`.

Для проверки откройте файл серверного блока в `nano` или любом другом текстовом редакторе:

    sudo nano /etc/apache2/sites-available/example.com.conf

Найдите строку с `ServerName`. Она должна выглядеть примерно так:

/etc/apache2/sites-available/example.com.conf

    ...
    ServerName example.com;
    ...

Если она выглядит таким образом, закройте файл и переходите к следующему шагу.

Если она не выглядит так, как описано выше, обновите директиву `ServerName`. Затем сохраните и закройте файл, после чего проверьте корректность синтаксиса вашего конфигурационного файла командой:

    sudo apache2ctl configtest

Если вы получили ошибку, откройте файл серверного блока и проверьте его на наличие опечаток или пропущенных символов. После того, как ваш конфигурационный файл будет проходить проверку на корректность, перезагрузите Apache для применения новой конфигурации:

    sudo systemctl reload apache2

Теперь Certbot может находить и обновлять корректный виртуальный хост.

Далее обновим настройки файрвола для пропуска HTTPS трафика.

## Шаг 3 - Разрешение HTTPS в файрволе

Если у вас включен файрвол `ufw`, как рекомендуется в руководстве по первичной настройке сервера, вам необходимо внести некоторые изменения в его настройки для разрешения трафика HTTPS. К счастью, Apache регистрирует необходимые профили в `ufw` в момент установки.

Вы можете ознакомиться с текущими настройками командой:

    sudo ufw status

Скорее всего вывод будет выглядеть следующим образом:

    ВыводStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Apache ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Apache (v6) ALLOW Anywhere (v6)

Как видно из вывода, разрешён только трафик HTTP.

Для того, чтобы разрешить трафик HTTPS, разрешим профиль `Apache Full` и удалим избыточный профиль `Apache`:

    sudo ufw allow 'Apache Full'
    sudo ufw delete allow 'Apache'

Проверим внесённые изменения:

    sudo ufw status

Теперь настройки `ufw` должны выглядеть следующим образом:

    ВыводStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Apache Full ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Apache Full (v6) ALLOW Anywhere (v6)  

Теперь мы можем запустить Certbot и получить наши сертификаты.

## Шаг 4 - Получение SSL сертификата

Certbot предоставляет несколько способов получения сертификатов SSL с использованием плагинов. Плагин для Apache берёт на себя настройку Apache и перезагрузку конфигурации, когда это необходимо. Для использования плагина выполним команду:

    sudo certbot --apache -d example.com -d www.example.com

Эта команда запускает `certbot` с плагином `--apache`, ключи `-d` определяют имена доменов, для которых должен быть выпущен сертификат.

Если это первый раз, когда вы запускаете `certbot`, вам будет предложено ввести адрес электронной почты и согласиться с условиями использования сервиса. После этого `certbot` свяжется с сервером Let’s Encrypt, а затем проверит, что вы действительно контролируете домен, для которого вы запросили сертификат.

Если всё прошло успешно, `certbot` спросит, как вы хотите настроить конфигурацию HTTPS.

    ВыводPlease choose whether or not to redirect HTTP traffic to HTTPS, removing HTTP access.
    -------------------------------------------------------------------------------
    1: No redirect - Make no further changes to the webserver configuration.
    2: Redirect - Make all requests redirect to secure HTTPS access. Choose this for
    new sites, or if you're confident your site works on HTTPS. You can undo this
    change by editing your web server's configuration.
    -------------------------------------------------------------------------------
    Select the appropriate number [1-2] then [enter] (press 'c' to cancel):

Выберите подходящий вариант и нажмите `ENTER`. Конфигурация будет обновлена, а Apache перезапущен для применения изменений. `certbot` выдаст сообщение о том, что процесс прошёл успешно, и где хранятся ваши сертификаты:

    ВыводIMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at:
       /etc/letsencrypt/live/example.com/fullchain.pem
       Your key file has been saved at:
       /etc/letsencrypt/live/example.com/privkey.pem
       Your cert will expire on 2018-07-23. To obtain a new or tweaked
       version of this certificate in the future, simply run certbot again
       with the "certonly" option. To non-interactively renew *all* of
       your certificates, run "certbot renew"
     - Your account credentials have been saved in your Certbot
       configuration directory at /etc/letsencrypt. You should make a
       secure backup of this folder now. This configuration directory will
       also contain certificates and private keys obtained by Certbot so
       making regular backups of this folder is ideal.
     - If you like Certbot, please consider supporting our work by:
    
       Donating to ISRG / Let's Encrypt: https://letsencrypt.org/donate
       Donating to EFF: https://eff.org/donate-le

Ваши сертификаты загружены, установлены и работают. Попробуйте перезагрузить ваш сайт с использованием `https://` и вы увидите значок безопасности в браузере. Он означает, что соединение с сайтом зашифровано, обычно он выглядит, как зелёная иконка замка. Если вы проверите ваш сервер тестом [SSL Labs Server Test](https://www.ssllabs.com/ssltest/), он получит оценку **A**.

Закончим тестированием процесса обновления сертификата.

## Шаг 5 - Проверка автоматического обновления сертификата

Сертификаты Let’s Encrypt действительны только 90 дней. Это сделано для того, чтобы пользователи автоматизировали процесс обновления сертификатов. Пакет `certbot`, который мы установили, делает это путём добавления скрипта обновления в `/etc/cron.d`. Этот скрипт запускается раз в день и автоматически обновляет любые сертификаты, которые закончатся в течение ближайших 30 дней.

Для тестирования процесса обновления мы можем сделать “сухой” запуск (dry run) `certbot`:

    sudo certbot renew --dry-run

Если вы не видите каких-либо ошибок в результате выполнения этой команды, то всё в полном порядке. При необходимости Certbot будет обновлять ваши сертификаты и перезагружать Apache для применения изменений. Если автоматическое обновление по какой-либо причине закончится ошибкой, Let’s Encrypt отправит электронное письмо на указанный вами адрес электронной почты с информацией о сертификате, который скоро закончится.

## Заключение

В этом руководстве мы рассмотрели процесс установки клиента Let’s Encrypt `certbot`, загрузили SSL сертификаты для вашего домена, настроили Apache для использования этих сертификатов и настроили процесс автоматического обновления сертификатов. Если у вас есть вопросы по работе с Certbot, рекомендуем ознакомиться с [документацией Certbot](https://certbot.eff.org/docs/).
