---
author: Mitchell Anicas
date: 2018-03-30
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/una-introduccion-a-oauth-2-es
---

# Una introducción a OAuth 2

### Introducción

OAuth 2 es una estructura (framework) de autorización que le permite a las aplicaciones obtener acceso limitado a cuentas de usuario en un servicio HTTP, como Facebook, GitHub y DigitalOcean. Delega la autenticación del usuario al servicio que aloja la cuenta del mismo y autoriza a las aplicaciones de terceros el acceso a dicha cuenta de usuario. OAuth 2 proporciona flujos de autorización para aplicaciones web y de escritorio; y dispositivos móviles.

Esta guía informativa está dirigida a desarrolladores de aplicaciones; y proporciona una descripción general de los roles de OAuth 2, tipos de autorización, casos de uso y flujos.

¡Empecemos con los roles de OAuth!

## Roles de OAuth

OAuth define cuatro roles:

- Propietario del recurso
- Cliente
- Servidor de recursos
- Servidor de autorización

Detallaremos cada rol en las siguientes subdivisiones.

### Propietario del recurso: _Usuario_

El propietario del recurso es el “usuario” que da la autorización a una aplicación, para acceder a su cuenta. El acceso de la aplicación a la cuenta del usuario se limita al “alcance” de la autorización otorgada (e.g. acceso de lectura o escritura).

### Servidor de Recursos / Autorización: _API_

El servidor de recursos aloja las cuentas de usuario protegidas, y el servidor de autorizaciones verifica la identidad del usuario y luego genera tokens de acceso a la aplicación.

Desde el punto de vista del desarrollador de una aplicación, la API del servicio atiende tanto a los roles de recursos como a los de autorización. Nos referiremos a ambos roles combinados, como al rol de servicio o de API.

### Cliente: _Aplicación_

El cliente es la _aplicación_ que desea acceder a la cuenta del _usuario_. Antes de que pueda hacerlo, debe ser autorizado por el usuario, y dicha autorización debe ser validada por la API.

## Flujo de protocolo abstracto

Ahora que tienes una idea de cuáles son los roles de OAuth, veamos un diagrama de cómo interactúan generalmente entre sí:

![Flujo de protocolo abstracto](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/translateddiagrams32918/Abstract-Protocol-Flow-Spanish@2x.png)

A continuación se encuentra una explicación más detallada de los pasos en el diagrama:

1. La _aplicación_ solicita autorización para acceder a los recursos de servicio del _usuario_
2. Si el _usuario_ autoriza la solicitud, la _aplicación_ recibe la autorización
3. La _aplicación_ solicita al _servidor de autorización_ (API), presentando la autenticación de su identidad y la autorización otorgada La aplicación solicita al servidor de autorización (API) un token de acceso presentando la autenticación de su propia identidad y la autorización otorgada
4. Si la identidad de la aplicación es autenticada y la autorización es válida, el _servidor de autorización_ (API) emite un token de acceso a la aplicación. La autorización finaliza
5. La _aplicación_ solicita el recurso al _servidor de recursos_ (API) y presenta el token de acceso para autenticarse
6. Si el token de acceso es válido, el _servidor de recursos_ (API) provee el recurso a la _aplicación_

El flujo real de este proceso variará dependiendo del tipo autorización que esté en uso, sin embargo, esta es la idea general. Examinaremos diferentes tipos de autorizaciones en una sección posterior.

## Registro de la aplicación

Antes de utilizar OAuth, debes registrar tu aplicación con el servicio. Esto se hace a través de un formulario de registro en la parte del “desarrollador” o “API” del sitio web del servicio, en el cual proporcionarás la siguiente información (y posiblemente detalles de tu aplicación):

- Nombre de la aplicación
- Sitio web de la aplicación
- _Redirect URI_ o _Callback URL_

_Redirect URI_ es donde el servicio reorientará al usuario después de que se autorice (o deniegue) su solicitud y, por consiguiente, la parte de su aplicación que manejará códigos de autorización o tokens de acceso.

### Identificador del cliente y secreto de cliente

Una vez esté registrada tu aplicación, el servicio emitirá “credenciales del cliente” en forma de un _identificador de cliente_ y un _secreto de cliente_. El identificador (ID) de cliente es una cadena pública que utiliza la API de servicio para identificar la aplicación y para generar las URL de autorización que se presentan a los usuarios. Una vez la aplicación solicita el acceso a la cuenta de un usuario, el secreto de cliente se utiliza para autenticar la identidad de la aplicación al API de servicio; y se deberá mantener la confidencialidad entre la aplicación y la API.

## Obtención de la autorización

En el “flujo de protocolo abstracto” presentado anteriormente, los primeros cuatro pasos abarcan la obtención de una autorización y el token de acceso. El tipo de otorgamiento de la autorización depende del método utilizado por la aplicación para solicitar dicha autorización y de los tipos de autorización soportados por la API. OAuth 2 define cuatro tipos de autorización, cada uno de los cuales es útil en casos distintos:

- **Código de autorización** : usado con aplicaciones del lado del servidor
- **Implícito** : utilizado con aplicaciones móviles o aplicaciones web (aplicaciones que se ejecutan en el dispositivo del usuario)
- **Credenciales de contraseña del propietario del recurso** : utilizado con aplicaciones confiables, como aquellas pertenecientes al servicio
- **Credenciales del cliente** : usadas con el acceso API de aplicaciones

En las siguiente secciones describiremos con mayor detalle los tipos de otorgamiento, sus casos de uso y flujos.

## Tipo de otorgamiento: Código de autorización

El tipo de otorgamiento más usado es el **código de autorización** , ya que ha sido optimizado para _aplicaciones del lado del servidor_, en donde el código fuente no está expuesto públicamente y se puede mantener la confidencialidad del _secreto de cliente_. Este es un flujo basado en la reorientación (redirection), que significa que la aplicación debe ser capaz de interactuar con el _agente de usuario_ (i.e. el navegador web del usuario) y recibir códigos de autorización API que se enrutan a través del agente de usuario.

Ahora describiremos el flujo del código de autorización:

![Flujo de código de autorización](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/translateddiagrams32918/Authorization-Code-Flow-Spanish@2x.png)

### Paso 1: Enlace de código de autorización

Primero se le da al usuario un enlace de código de autorización similar al siguiente:

    https://cloud.digitalocean.com/v1/oauth/authorize?response_type=code&client_id=CLIENT_ID&redirect_uri=CALLBACK_URL&scope=read

A continuación se presenta una explicación de los componentes del enlace:

- **[https://cloud.digitalocean.com/v1/oauth/authorize](https://cloud.digitalocean.com/v1/oauth/authorize)**: El punto de conexión de la API de autorización
- **client\_id=client\_id** : el _ID de cliente_ (cómo la API identifica la aplicación)
- **redirect\_uri=CALLBACK\_URL** : donde el servicio reorienta al agente-usuario después de que se otorgue un código de autorización
- **response\_type=code** : especifica que tu aplicación está solicitando un código de autorización
- **scope=read** : especifica el nivel de acceso que la aplicación está solicitando

### Paso 2: El usuario autoriza a la aplicación

Cuando el usuario hace clic en el enlace, debe primero iniciar sesión en el servicio para autenticar su identidad (a menos que ya haya iniciado sesión). Luego, el servicio solicitará autorizar o denegar el acceso de la aplicación a su cuenta. A continuación se presenta un ejemplo de solicitud de autorización:

![Enlace de código de autorización](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/oauth/authcode.png)

Esta captura específica de pantalla es de la autorización de DigitalOcean; y podemos ver que “Thedropletbook App” está solicitando autorización para el acceso de “lectura” a la cuenta de “[manicas@digitalocean.com](mailto:manicas@digitalocean.com)”.

### Paso 3: La aplicación recibe el código de autorización

If the user clicks “Authorize Application”, the service redirects the user-agent to the application redirect URI, which was specified during the client registration, along with an _authorization code_. The redirect would look something like this (assuming the application is “dropletbook.com”):

Si el usuario hace clic en “Authorize Application”, el servicio reorienta el agente-usuario al “redirect URI” de la aplicación, que se especificó durante el registro del cliente, junto con un código de autorización. La reorientación sería algo así (suponiendo que la aplicación es “dropletbook.com”):

    https://dropletbook.com/callback?code=AUTHORIZATION_CODE

### Paso 4: La aplicación solicita token de acceso

La aplicación solicita un token de acceso de la API, pasándole el código de autorización junto con los detalles de autenticación, incluido el secreto del cliente, a la terminal del token de la API. A continuación se presenta un ejemplo de una solicitud POST para la conexión del token de DigitalOcean:

    https://cloud.digitalocean.com/v1/oauth/token?client_id=CLIENT_ID&client_secret=CLIENT_SECRET&grant_type=authorization_code&code=AUTHORIZATION_CODE&redirect_uri=CALLBACK_URL

### Paso 5: La aplicación recibe el token de acceso

Si la autorización es válida, la API enviará una respuesta a la aplicación, con el token de acceso (y, opcionalmente, un token de actualización). La respuesta completa se verá más o menos así:

    {"access_token":"ACCESS_TOKEN","token_type":"bearer","expires_in":2592000,"refresh_token":"REFRESH_TOKEN","scope":"read","uid":100101,"info":{"name":"Mark E. Mark","email":"mark@thefunkybunch.com"}}

¡Ahora la aplicación está autorizada! Ella puede utilizar el token para acceder a la cuenta del usuario a través de la API de servicio, limitada al alcance del acceso, hasta que el token caduque o se revoque. Si se generó un token de actualización, éste se puede usar para solicitar nuevos tokens de acceso cuando el token original ha caducado.

## Tipo de otorgamiento: Implicito

El tipo de otorgamiento **implícito** se utiliza para aplicaciones móviles y aplicaciones web (i.e. aplicaciones que se ejecutan en un navegador web), donde no se garantiza la confidencialidad del secreto de cliente. El tipo de otorgamiento implícito también es un flujo basado en la reorientación, pero el token de acceso se entrega al agente-usuario para reenviarlo a la aplicación, por lo que puede estar expuesto al usuario y a otras aplicaciones en el dispositivo del usuario. Además, este flujo no autentica la identidad de la aplicación y depende del _redirect URI_ (que se registró con el servicio) para cumplir este propósito.

El tipo de otorgamiento implícito no admite tokens de actualización.

El flujo de otorgamiento implícito básicamente funciona de la siguiente manera: se le solicita al usuario que autorice la aplicación, luego el servidor de autorización pasa el token de acceso al agente-usuario, quien a su vez se lo pasa a la aplicación. Si tienes curiosidad acerca de los detalles, sigue leyendo.

![Flujo implícito](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/translateddiagrams32918/Implicit-Flow-Spanish@2x.png)

### Paso 1: Enlace de autorización implícita

Con el tipo de solicitud implícita, se le presenta al usuario un enlace de autorización que solicita un token de la API. Este enlace se parece al enlace del código de autorización, excepto que está solicitando un _token_ en lugar de un código (ten en cuenta el _tipo de respuesta_ “token”):

    https://cloud.digitalocean.com/v1/oauth/authorize?response_type=token&client_id=CLIENT_ID&redirect_uri=CALLBACK_URL&scope=read

### Paso 2: El usuario autoriza a la aplicación

Cuando el usuario hace clic en el enlace, primero debe iniciar sesión en el servicio para autenticar su identidad (a menos que previamente haya iniciado sesión). Luego, el servicio le solicitará que _autorice_ o _deniegue_ el acceso de la aplicación a su cuenta. A continuación se presenta un ejemplo de autorización de aplicación:

![Enlace de código de autorización](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/oauth/authcode.png)

Podemos ver que “Thedropletbook App” solicita autorización de acceso de “lectura” a la cuenta de “[manicas@digitalocean.com](mailto:manicas@digitalocean.com)”.

### Paso 3: El agente-usuario recibe el token de acceso con _Redirect URI_

Si el usuario hace clic en “Authorize Application”, el servicio reorienta el usuario-agente al _redirect URI_ de la aplicación e incluye un fragmento de URI que contiene el token de acceso. Se vería como algo así:

    https://dropletbook.com/callback#token=ACCESS_TOKEN

### Paso 4: El agente-usuario sigue al _Redirect URI_

El agente-usuario sigue al _redirect URI_ pero conserva el token de acceso.

### Paso 5: La aplicación envía el script de extracción de tokens de acceso

La aplicación devuelve una página web que contiene una secuencia de comandos que puede extraer el token de acceso del _redirect URI_ completo que ha conservado el usuario-agente.

### Paso 6: Token de acceso transferido a la aplicación

El agente-usuario ejecuta el script proporcionado y pasa a la aplicación el token de acceso extraído.

¡Ahora la aplicación está autorizada! Ésta puede usar el token para acceder a la cuenta del usuario a través de la API de servicio, limitada al alcance del acceso, hasta que el token caduque o se revoque.

## Tipo de otorgamiento: Credenciales de contraseña del propietario del recurso

Con el tipo de otorgamiento de **credenciales de contraseña del propietario del recurso** , el usuario proporciona sus credenciales de servicio (nombre de usuario y contraseña) directamente a la aplicación, la cual utiliza dichas credenciales para obtener del servicio un token de acceso. Este tipo de autorización solo debe habilitarse en el servidor de autorización, si otros flujos no son viables. Además, solo debe utilizarse si la aplicación es confiable para el usuario (e.g. es propiedad del servicio o del sistema operativo de escritorio del usuario).

### Flujo de credenciales de contraseña

Después de que el usuario proporcione sus credenciales a la aplicación, ésta solicitará un token de acceso desde el servidor de autorizaciones. La solicitud POST puede ser similar a lo siguiente:

    https://oauth.example.com/token?grant_type=password&username=USERNAME&password=PASSWORD&client_id=CLIENT_ID

Si se comprueban las credenciales del usuario, el servidor de autorización devuelve un token de acceso a la aplicación. ¡Ahora la aplicación está autorizada!

**Nota:** DigitalOcean actualmente no soporta el tipo de solicitud de credenciales de contraseña, así que el enlace apunta a un servidor de autorización imaginario, en “oauth.example.com”.

## Tipo de otorgamiento: Credenciales del cliente

El tipo de otorgamiento de **credenciales del cliente** proporciona a la aplicación una forma de acceder a su propia cuenta de servicio. Si una aplicación desea actualizar su descripción registrada o redirigir el URI, o acceder a otros datos almacenados en su cuenta de servicio a través de la API serían ejemplos de cuándo podría ser útil este tipo de otorgamiento.

### Flujo de credenciales del Cliente

La aplicación solicita un token de acceso enviando sus credenciales, su ID de cliente y su secreto de cliente, al servidor de autorización. Un ejemplo de solicitud POST podría ser similar a lo siguiente::

    https://oauth.example.com/token?grant_type=client_credentials&client_id=CLIENT_ID&client_secret=CLIENT_SECRET

Si se comprueban las credenciales de la aplicación, el servidor de autorización devuelve un token de acceso a la aplicación. ¡Ahora la aplicación está autorizada para usar su propia cuenta!

**Nota:** DigitalOcean no soporta actualmente el otorgamiento de credenciales de cliente, por lo que el enlace apunta a un servidor de autorización imaginario en “oauth.example.com”.

## Ejemplo de uso del token de acceso

Una vez que la aplicación tiene un token de acceso, puede utilizarlo para acceder a la cuenta del usuario a través de la API, limitado al alcance del acceso, hasta que el token caduque o sea revocado.

A continuación se encuentra un ejemplo de una solicitud API, usando `curl`. Observa que éste incluye el token de acceso:

    curl -X POST -H "Authorization: Bearer ACCESS_TOKEN""https://api.digitalocean.com/v2/$OBJECT" 

Suponiendo que el token de acceso es válido, la API procesará la solicitud de acuerdo con sus especificaciones API. Si el token de acceso ha caducado o no es válido, la API devolverá un error de “invalid\_request”.

## Flujo de actualización de token

Hacer una solicitud desde el API, utilizando un token de acceso que ha caducado, generará un error de token inválido “Invalid Token Error”. Si cuando se emitió el token de acceso original se incluyó un token de actualización, entonces éste puede ser usado para solicitar un token de acceso nuevo desde el servidor de autorización.

Aquí se proporciona un ejemplo de una solicitud POST, usando un token de actualización para obtener un nuevo token de acceso:

    https://cloud.digitalocean.com/v1/oauth/token?grant_type=refresh_token&client_id=CLIENT_ID&client_secret=CLIENT_SECRET&refresh_token=REFRESH_TOKEN

## Conclusión

Con esto concluye esta guía de OAuth 2. Ahora debes tener una buena idea de cómo funciona OAuth 2 y cuándo se debe utilizar un flujo de autorización específico.

Si quieres aprender más acerca de OAuth 2, consulta estos valiosos recursos:

- [Cómo utilizar la autenticación de OAuth con DigitalOcean como usuario o desarrollador](how-to-use-oauth-authentication-with-digitalocean-as-a-user-or-developer)
- [Cómo usar la API DigitalOcean v2](how-to-use-the-digitalocean-api-v2)
- [La estructura (Framework) de autorización de OAuth 2.0](http://tools.ietf.org/html/rfc6749)
