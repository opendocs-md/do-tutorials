---
author: Hazel Virdó, Kathleen Juell
date: 2018-06-21
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/como-asegurar-nginx-con-let-s-encrypt-en-ubuntu-18-04-es
---

# Cómo asegurar Nginx con Let’s Encrypt en Ubuntu 18.04

_Una versión previa de este tutorial fue escrito por [Hazel Virdó](https://www.digitalocean.com/community/users/hazelnut)_

### Introducción

Let’s Encrypt es una Autoridad Certificadora (CA) que provee una manera sencilla de obtener e instalar de manera gratuita [certificados TLS/SSL](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs), por lo tanto, habilitaría el HTTPS en servidores web. Además, simplifica el proceso, ya que provee un software cliente, Certbot, que automatiza la mayoría (si no todos) los pasos requeridos. Actualmente, todo el proceso de la obtención e instalación de un certificado se encuentra completamente automatizada tanto para Apache como para Nginx.

En este tutorial, usarás Certbot para obtener un certificado SSL gratuito que podrá ser usado en Nginx, instalado en Ubuntu 18.04 y configurado de tal manera que su renovación se realizará de forma automática.

Este tutorial usará un archivo de bloque separado para el servidor Nginx, en vez de utilizar el archivo por defecto. [Recomendamos](how-to-install-nginx-on-ubuntu-18-04#step-5-setting-up-server-blocks-(recommended)) la creación de un archivo de bloque nuevo para cada uno de los dominios, porque ayuda a evitar errores comunes, además de mantener los archivos predeterminados en caso de ser necesitados para una configuración alterna en caso de emergencia.

## Prerrequisitos

Para poder completar este tutorial, necesitarás contar con lo siguiente:

- Una instalación del servidor Ubuntu 18.04, ajustada de acuerdo con el tutorial de la [configuración inicial de servidores para Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04), incluyendo un cortafuegos y una cuenta que no sea la de superusuario que tenga privilegios sudo.

- Un nombre de dominio registrado y funcional. Durante este tutorial se usará **example.com**. Puedes comprar un dominio en [Namecheap](https://namecheap.com), obtener uno gratuito en [Freenom](http://www.freenom.com/en/index.html), o utilizar el proveedor de dominio de tu preferencia.

- La configuración de los siguientes dos registros DNS para tu servidor. Puedes seguir la [introducción al DNS de DigitalOcean](an-introduction-to-digitalocean-dns), para obtener detalles y el proceso para adicionarlos:

- Nginx instalado, habiendo seguido nuestra guía: [cómo instalar Nginx en Ubuntu 18.04](how-to-install-nginx-on-ubuntu-18-04). Debes asegurarte de tener un [bloque de servidor](how-to-install-nginx-on-ubuntu-18-04#step-5-setting-up-server-blocks-(recommended)) para tu dominio. Este tutorial usará `/etc/nginx/sites-available/example.com` como ejemplo.

## Paso 1 — Instalar Certbot

El primer paso para obtener un certificado SSL mediante Let’s Encrypt, consiste en instalar el software de Certbot en tu servidor.

El desarrollo de Certbot se encuentra muy activo, lo que conlleva que los paquetes proveídos por Ubuntu tiendan a estar desactualizados. Sin embargo, los desarrolladores de Certbot mantienen un repositorio de software para Ubuntu con las versiones actualizadas, es por eso que nosotros usaremos ese repositorio, en cambio de los paquetes predeterminados.

Primero, adiciona el repositorio:

    sudo add-apt-repository ppa:certbot/certbot

Necesitarás presionar `Enter` para aceptar. Luego, actualiza la lista de paquetes para recolectar la información de los paquetes del nuevo repositorio:

    sudo apt update

Y finalmente, instala el paquete Nginx de Certbot con el `apt`:

    sudo apt install python-certbot-nginx

Ahora, Certbot está listo para ser usado, pero para configurar el SSL para trabajar con Nginx, necesitamos verificar la configuración de él.

## Paso 2 — Confirmar la configuración del Nginx

Certbot necesita estar habilitado para encontrar el bloque de `servidor` en tu configuración de Nginx, de tal manera que que pueda configurar el SSL de forma automática. Específicamente, lo hace mediante la búsqueda de la directiva `server_name` que contiene el dominio del cual solicitaste el certificado.

Si seguiste el [paso para establecer el bloque de servidor dentro del tutorial de instalación de Nginx](how-to-install-nginx-on-ubuntu-18-04#step-5-setting-up-server-blocks-(recommended)), deberías tener un bloque de servidor para tu dominio en `/etc/nginx/sites-available/example.com` con la directiva `server_name` ya asignada apropiadamente.

Para verificarlo, abre el archivo de bloques de servidor para tu dominio usando `nano` o tu editor de texto preferido:

    sudo nano /etc/nginx/sites-available/example.com

Busca la línea: `server_name`, que debería verse semejante a lo siguiente:

/etc/nginx/sites-available/example.com

    ...
    server_name example.com www.example.com;
    ...

Si la línea concuerda con lo anterior, sal del archivo y continúa con el siguiente paso.

Si no, actualiza el archivo para que concuerde. Salva el archivo, sal del editor y verifica la sintaxis de la edición que acabas de realizar:

    sudo nginx -t

Si se despliega un error, abre de nuevo el archivo y recórrelo en la búsqueda de caracteres faltantes o de errores tipográficos. Tan pronto como la sintaxis de tu archivo de configuración sea la correcta, recarga Nginx para activar la nueva configuración:

    sudo systemctl reload nginx

Certbot podrá ahora encontrar el bloque de `servidor` correcto y podrá actualizarlo.

A continuación, actualizaremos el cortafuegos para permitir el tráfico HTTPS.

## Paso 3 — Permitir HTTPS a través del cortafuegos

Si se tiene el cortafuegos `ufw` habilitado, tal como se recomendó en las guías de prerrequisitos, necesitarás ajustar la configuración para permitir el tráfico HTTPS. Afortunadamente, Nginx registra pocos perfiles durante su instalación.

Puedes ver el ajuste actual del cortafuegos al digitar:

    sudo ufw status

Probablemente, la salida se parecerá a algo como lo siguiente, lo cual implicaría que el tráfico HTTP es el único permitido en el servidor web:

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere                  
    Nginx HTTP ALLOW Anywhere                  
    OpenSSH (v6) ALLOW Anywhere (v6)             
    Nginx HTTP (v6) ALLOW Anywhere (v6)

Para permitir adicionalmente, el tráfico HTTPS, debes habilitar el perfil completo de Nginx y borrar los perfiles redundantes:

    sudo ufw allow 'Nginx Full'
    sudo ufw delete allow 'Nginx HTTP'

En este momento, el estado debería desplegarse de la siguiente forma:

    sudo ufw status

    OutputStatus: active
    
    To Action From
    -- ------ ----
    OpenSSH ALLOW Anywhere
    Nginx Full ALLOW Anywhere
    OpenSSH (v6) ALLOW Anywhere (v6)
    Nginx Full (v6) ALLOW Anywhere (v6)

A continuación, ejecutaremos Certbot para obtener nuestros certificados.

## Paso 4 — Obtener el certificado SSL

Certbot provee diferentes maneras para obtener certificados SSL. Al usar el conector a Nginx, éste se encargará de reconfigurarlo, así como también, de recargar la configuración en caso de ser necesario. Para usar este conector, digita lo siguiente:

    sudo certbot --nginx -d example.com -d www.example.com

Esto ejecuta `certbot` con el conector `--nginx`, usando `-d` para especificar los nombres sobre los cuales queremos que el certificado sea válido.

Si ésta es la primera vez que se ejecuta `certbot`, se te solicitará que ingreses una dirección de correo electrónico y que aceptes los términos de servicio. Al hacerlo, `certbot` se comunicará con el servidor Let’s Encrypt, para intentar verificar que tú controlas el dominio para el cual se está solicitando el certificado.

En caso de éxito, `certbot` te preguntará cómo configurar los ajustes para HTTPS:

    OutputPlease choose whether or not to redirect HTTP traffic to HTTPS, removing HTTP access.
    -------------------------------------------------------------------------------
    1: No redirect - Make no further changes to the webserver configuration.
    2: Redirect - Make all requests redirect to secure HTTPS access. Choose this for
    new sites, or if you're confident your site works on HTTPS. You can undo this
    change by editing your web server's configuration.
    -------------------------------------------------------------------------------
    Select the appropriate number [1-2] then [enter] (press 'c' to cancel):

El mensaje anterior te permitirá escoger entre redireccionar o no el tráfico de HTTP a HTTPS, limitando el acceso HTTP; mediante las siguientes opciones:

    OutputPor favor seleccione si desea, o no, redireccionar el tráfico de HTTP a HTTPS, limitando el acceso HTTP.
    -------------------------------------------------------------------------------
    1: No redireccionar - No se realizarán más cambios a la configuración del servidor web.
    2: Redireccionar - Enviar todas las solicitudes hacia el acceso seguro HTTPS.
    Seleccione esta opción si su sitio es nuevo o Usted se encuentra
    seguro que su sitio funcionará en un ambiente HTTPS.
    Esto se puede deshacer, editando la configuración de su servidor web.
    -------------------------------------------------------------------------------
    Seleccione el número de su opción: [1-2] después pulse [Enter] (o presione 'c' para cancelar):

Después de seleccionar su opción, pulse `Enter`. La configuración será actualizada, y Nginx se recargará para activar los nuevos ajustes. `certbot` concluirá con un mensaje informando que el proceso fue exitoso y la localización de tus certificados:

    OutputIMPORTANT NOTES:
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
    

Tus certificados ya deberían haber sido transferidos, instalados y cargados. Intenta recargar tu sitio web usando el prefijo `https://` y observa el indicador de seguridad de tu navegador. Debería indicar que el sitio se encuentra asegurado de manera apropiada, usualmente se indica con el icono de un candado verde. Si pruebas tu sitio usando el [test del servidor del laboratorio SSL](https://www.ssllabs.com/ssltest/), debería obtener el grado **A**.

Terminemos, probando el proceso de renovación.

## Paso 5 — Verificar la renovación automática de Certbot

Los certificados de Let’s Encrypt son válidos por noventa días únicamente. Esto se hace con el fin de incentivar a los usuarios para que automaticen el proceso de renovación de certificados. El paquete `certbot` que instalamos ya se ha ocupado de adicionar un archivo de comandos de renovación en `/etc/cron.d`. Este archivo de comandos se ejecuta dos veces al día y renovará automáticamente los certificados que presenten una fecha de expiración dentro de los siguientes treinta días.

Para probar el proceso de renovación, puedes hacer un ensayo mediante `certbot`:

    sudo certbot renew --dry-run

Si no se despliegan errores, el proceso se encuentra funcional. De ser necesario, Certbot renovará tus certificados y recargará Nginx para activar los cambios. Si el proceso automático de renovación alguna vez fallase, Let’s Encrypt enviará un mensaje al correo electrónico que especificaste, alertando que tu certificado se encuentra próximo a expirar.

## Conclusión

En este tutorial, instalaste el cliente de Let’s Encrypt: `certbot`, transferiste los certificados SSL para tu dominio, configuraste Nginx para usar estos certificados, y configuraste la renovación automática de los mismos. Si tienes más preguntas acerca del uso de Certbot, [su documentación](https://certbot.eff.org/docs/) es un buen lugar para empezar.
