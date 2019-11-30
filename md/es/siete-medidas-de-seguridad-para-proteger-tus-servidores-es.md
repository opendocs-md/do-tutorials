---
author: Justin Ellingwood
date: 2018-03-30
language: es
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/siete-medidas-de-seguridad-para-proteger-tus-servidores-es
---

# Siete medidas de seguridad para proteger tus servidores

### Introducción

Frecuentemente tu preocupación principal es la de activar y poner en marcha tu aplicación al momento de configurar la infraestructura. Sin embargo, el tener una aplicación que es funcional, pero que no tiene en cuenta las necesidades de seguridad asociadas a la infraestructura que se está utilizando, podría acarrear consecuencias devastadoras.

En esta guía hablaremos de algunas prácticas básicas de seguridad, es recomendable realizarlas antes o durante la configuración de tu aplicación.

## Llaves SSH

Las llaves SSH son un par de llaves criptográficas que pueden ser usadas para autenticarse en un servidor SSH; es un método alternativo al uso de contraseñas. La creación del par compuesto por llave pública y privada es llevada a cabo como un paso anterior a la autenticación. La llave privada la conserva el usuario de manera secreta y segura, mientras que la llave pública puede ser compartida con otros usuarios sin restricción.

![Diagrama de llaves SSH](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/translateddiagrams32918/SSH-Key-Authentication-Spanish@2x.png)

Para configurar la autenticación mediante llaves SSH, debes colocar la llave pública del usuario en un directorio específico dentro del servidor. Cuando el usuario se conecta al servidor, éste requerirá una prueba de que el cliente tiene la llave privada asociada. El cliente SSH hará uso de la llave privada, respondiendo de tal forma que comprobará que se es propietario de la llave privada. A continuación, el servidor permitirá al cliente la conexión sin el uso de contraseña. Si deseas aprender más acerca de cómo funcionan las llaves SSH, puedes referirte al siguiente [artículo](understanding-the-ssh-encryption-and-connection-process).

### ¿Cómo éstas mejoran la seguridad?

Al usar SSH, cualquier tipo de autentificación, incluyendo la autenticación mediante contraseña, estará totalmente encriptada. Ahora bien, al permitir autenticaciones basadas en contraseñas, usuarios maliciosos podrían realizar intentos repetitivos de acceso al servidor. Gracias al poder computacional actual, es posible acceder a un servidor mediante intentos automáticos de ingreso de contraseñas, una palabra clave tras otra, hasta hallar la que es válida para ese servidor.

### ¿Qué tan difícil es implementarlas?

Configurar llaves SSH es muy sencillo, y su uso es la práctica recomendada al acceder remotamente a un ambiente de servidores Linux o Unix. Un par de llaves SSH pueden ser generadas en tu propia máquina y puedes transferir la llave pública a tus servidores en pocos minutos.

Para aprender cómo configurar las llaves, puedes seguir [esta guía](how-to-set-up-ssh-keys--2). En el caso que aún sientas que debes usar autenticación mediante contraseña, puedes considerar implementar una solución como: [fail2ban](how-to-install-and-use-fail2ban-on-ubuntu-14-04) en tus servidores, de tal manera que limites la posibilidad de adivinar las contraseñas.

## Cortafuegos

Un cortafuegos es una pieza de software (o hardware) que controla cuáles servicios se encuentran expuestos a la red. Es decir, que bloquean o restringen el acceso a todo puerto exceptuando únicamente aquellos que deben estar habilitados para el público.

![Diagrama del cortafuegos](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/translateddiagrams32918/Firewall-Spanish@2x.png)

Típicamente, en un servidor se encuentran diferentes servicios ejecutándose por defecto. Éstos pueden ser categorizados dentro de los siguientes grupos:

- Servicios públicos que pueden ser accedidos sin restricción en internet, normalmente de manera anónima. Un buen ejemplo de ésto es el servidor web que probablemente da acceso a su sitio.
- Servicios privados que solo deberían ser accedidos por un grupo selecto de cuentas autorizadas o desde lugares específicos. Un ejemplo de éstos, puede ser el panel de control de una base de datos.
- Servicios internos que solo deberían ser accedidos desde el mismo servidor, sin exponer el servicio al mundo exterior. Por ejemplo, éstos podrían ser una base de datos que solo acepta conexiones locales.

El cortafuegos puede asegurar que tu software tiene las restricciones acorde con las anteriores categorías. Los servicios públicos pueden ser abiertos sin restricción y disponibles para todos, por su lado, los servicios privados se pueden restringir basándose en diferentes criterios. Los servicios internos se pueden configurar de tal manera que sean completamente inaccesibles al mundo exterior. Para los puertos que no se encuentren en uso, la configuración más común es un bloqueo completo al acceso.

### ¿Cómo éstos mejoran la seguridad?

El cortafuegos es una parte esencial de cualquier configuración de servidores. Incluso en el caso de que tus servicios implementen la seguridad o que estén supeditados solo a las interfaces donde quieres que se ejecuten, un cortafuegos siempre servirá como capa extra de protección.

Un cortafuegos bien configurado restringirá el acceso a todo, exceptuando los servicios específicos que requieres mantener abiertos. Al exponer solo el software necesario, se reducen los puntos en que puede ser atacado tu servidor, limitando así los componentes vulnerables a la explotación.

### ¿Qué tan difícil es implementarlos?

Existen muchos cortafuegos asequibles para sistemas Linux, algunos presentan una curva de aprendizaje mucho más pendiente que otros. Sin embargo, en general, la puesta a punto de un cortafuegos debería tomar solo algunos minutos.

Una opción simple es el [Cortafuegos UFW](how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server). Otra opción es usar: [iptables](how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04) o el [Cortafuegos CSF](how-to-install-and-configure-config-server-firewall-csf-on-ubuntu).

## VPN y redes privadas

Las redes privadas son las redes que se encuentran habilitadas únicamente para ciertos usuarios o servidores. Por ejemplo, en DigitalOcean, la red privada está disponible en algunas regiones con la misma amplitud que la red del Centro de Datos.

Una VPN, de la sigla en inglés asociada a Red Privada Virtual, es una de las formas de crear conexiones seguras entre computadores remotos, presentándose como si éstos se encontraran en una red privada local. Esto permite configurar tus servicios como si estuviesen en una red privada, así como de conectar servidores de manera segura.

![Diagrama VPN](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/translateddiagrams32918/Virtual-Private-Network-Spanish@2x.png)

### ¿Cómo éstas mejoran la seguridad?

De ser posible, siempre se prefieren las redes privadas en vez de las públicas, para las comunicaciones internas. Ahora bien, en vista que otros usuarios dentro del Centro de Datos tienen acceso a la misma red, aún debes implementar medidas adicionales para asegurar la comunicación entre tus servidores.

Usar una VPN es, en efecto, una forma de mapear una red privada que solo tus servidores pueden ver. Las comunicaciones serán completamente privadas y seguras. Otras aplicaciones pueden configurarse para llevar su tráfico a la interfaz virtual que el software de la VPN expone. De esta forma, solo los servicios que fueron diseñados para ser consumidos por los clientes en el internet público necesitarán ser expuestos en la red pública.

### ¿Qué tan difícil es implementarlas?

Utilizar redes privadas en un Centro de Datos que tiene esta capacidad es tan fácil como habilitar la interfaz durante la creación de tu servidor y configurar tus aplicaciones y cortafuegos para que usen la red privada. Ten en cuenta que una red cuyo alcance es tan amplio como la del Centro de Datos, comparte el espacio con los servidores que usan la misma red.

Para utilizar VPN, la puesta a punto inicial involucra algunas cosas de más, pero valdrán la pena gracias al incremento de seguridad en la mayoría de los casos de uso. Cada uno de los servidores dentro de la VPN debe tener los datos de configuración y de seguridad compartida, necesarios para instalar la conexión segura y establecer su configuración. Después de que la VPN se encuentre activa y funcional, las aplicaciones deberán configurarse para usar el túnel VPN. Para aprender cómo ajustar la VPN para conectar de manera segura tu infraestructura, dirígete a nuestro [tutorial de OpenVPN](how-to-secure-traffic-between-vps-using-openvpn).

## Infraestructura de llaves públicas y encripción SSL/TLS

La Infraestructura de Llaves Públicas o PKI, por su sigla en inglés, se refiere a un sistema diseñado para crear, administrar y validar certificados que identifiquen individuos y encripta la comunicación. Los certificados SSL o TLS pueden ser usados para autenticar diferentes entidades entre sí. Cuando la autentificación se ha llevado a cabo, también pueden ser usados para establecer una comunicación encriptada.

![Diagrama SSL](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/translateddiagrams32918/SSL-TLS-Encryption-Spanish@2x.png)

### ¿Cómo éstos mejoran la seguridad?

Establecer una autoridad certificadora y administrar certificados para tus servidores permite a cada una de las entidades dentro de tu infraestructura validar la identidad de otros miembros y encriptar su tráfico. Esto puede prevenir ataques de intermediario, donde un atacante imita un servidor de su infraestructura con el ánimo de interceptar tráfico.

Cada servidor puede configurarse para confiar en una autoridad certificadora central. De ese punto en adelante, se confiará implícitamente en cualesquier certificado firmado por esa autoridad. En caso que las aplicaciones y protocolos que uses para la comunicación soporten encriptación TLS/SSL, se puede ahorrar el exceso de información generado por un túnel VPN (que con frecuencia usa SSL internamente).

### ¿Qué tan difícil es implementarlos?

Configurar una autoridad certificadora y ajustar la infraestructura restante de llaves públicas puede involucrar un esfuerzo inicial considerable. Además, administrar certificados puede crear una carga administrativa adicional cuando sea necesario crear, firmar o revocar nuevos certificados.

Para muchos usuarios, el implementar una infraestructura completa de llaves públicas cobra sentido cuando su infraestructura necesita crecer. Asegurar las comunicaciones mediante una VPN puede ser una buena solución intermedia hasta que alcances el punto en el cual la PKI valga la pena en contraprestación de los costos administrativos adicionales.

## Auditoría de servicio

Hasta este punto, hemos discutido algunos elementos tecnológicos que puedes implementar para mejorar tu seguridad. Sin embargo, una parte importante de la seguridad responde al análisis de tus sistemas, entender los puntos susceptibles de ataque, y asegurar los componentes tanto como puedas.

La auditoría de servicio es un proceso para descubrir cuáles servicios están ejecutándose en los servidores de tu infraestructura. Regularmente, los sistemas operativos se encuentran configurados por defecto para ejecutar ciertos servicios al arranque. La instalación de software adicional, a veces puede incluir dependencias que se ejecutan, también, de manera automática.

![Diagrama de auditoría de servicio](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/translateddiagrams32918/Service-Checklist-Spanish@2x.png)

La auditoría de servicio permite saber cuáles servicios se están ejecutando en tu sistema, cuáles puertos usan para su comunicación, y cuáles protocolos se aceptan. Esta información te puede ayudar a configurar los parámetros de tu cortafuegos.

### ¿Cómo ésta mejora la seguridad?

Los servidores inician muchos procesos, unos con propósitos internos y otros con los de manejar clientes externos. Cada uno de esos representa una extensión de los puntos donde un usuario malicioso podría atacar. Entre más servicios conserves en ejecución, más alta es la posibilidad de la existencia de una vulnerabilidad en el software al que se tiene acceso.

Una vez tengas suficiente idea acerca de los servicios en ejecución dentro de tu máquina, puedes empezar a analizar estos servicios. Algunas preguntas que querrás hacerte para cada uno de ellos son:

- ¿Este servicio debe estar en ejecución?
- ¿El servicio está ejecutándose en interfaces donde no es necesario? ¿Debería estar ligado a una sola IP?
- ¿Las reglas de tu cortafuegos se estructuran para permitir el paso de tráfico legítimo de este servicio?
- ¿Las reglas de tu cortafuegos están bloqueando el tráfico ilegítimo?
- ¿Tienes un método que te permita recibir alertas de seguridad relacionadas con las vulnerabilidades de cada uno de estos servicios?

Este tipo de auditoría de servicio debería ser una práctica estándar al configurar cualquier servidor nuevo dentro de tu infraestructura.

### ¿Qué tan difícil es implementarlo?

Hacer una auditoría básica de servicio es increíblemente simple. Puedes encontrar cuáles servicios escuchan ciertos puertos en cada interfaz, utilizando el comando `netstat`. Un ejemplo simple que muestra el nombre del programa, PID, y la dirección para escuchar el tráfico TCP y UDP es:

    sudo netstat -plunt

Verá una salida semejante a lo siguiente:

    Active Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 887/sshd        
    tcp 0 0 0.0.0.0:80 0.0.0.0:* LISTEN 919/nginx       
    tcp6 0 0 :::22 :::* LISTEN 887/sshd        
    tcp6 0 0 :::80 :::* LISTEN 919/nginx

Necesitas prestar especial atención a las columnas: `Proto`, `Local Address` (Dirección local), and `PID/Program name` (PID/Nombre del programa). Si la dirección es `0.0.0.0`, deberás entender que el servicio está aceptando conexiones en todas las interfaces.

## Auditoría de archivos y Sistemas de Detección de Intrusos

La auditoría de archivos es el proceso de comparar el sistema actual contra un registro de los archivos y de las características de los archivos de su sistema, cuando se encuentra en un estado conocido. Esto se usa para detectar cambios que no han sido autorizados en el sistema.

![Diagrama de auditoría de archivos](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/translateddiagrams32918/Daily-File-System-Audi-Spanish@2x.png)

Un Sistema de Detección de Intrusos, IDS por su sigla en inglés, es un software que monitorea sistemas o redes buscando actividad no autorizada. Muchos IDS implementados en los servidores anfitriones usan auditoría de archivos como su método de observar si un sistema ha cambiado o no.

### ¿Cómo éstos mejoran la seguridad?

De manera similar a los auditores de nivel de servicio discutidos anteriormente, si deseas asegurar seriamente un sistema, es muy útil tener la posibilidad de auditarlo a nivel de archivos. Esto se puede realizar periódicamente por el administrador o como parte de un proceso automatizado dentro de un IDS.

Estas estrategias pertenecen al conjunto de procesos que permiten estar absolutamente seguro de que tu sistema no ha sido alterado por algún usuario o proceso. Por muchas razones, los intrusos desean permanecer escondidos de tal forma que puedan continuar explotando el servidor por un tiempo largo. Ellos probablemente reemplazarán archivos binarios con versiones comprometidas de los mismos. Auditar el sistema de archivos te dirá si alguno de esos archivos ha sido alterado, permitiéndote confiar en la integridad del ambiente de tu servidor.

### ¿Qué tan difícil es implementarlos?

Implementar un IDS o realizar auditorías de archivos puede ser un proceso muy intenso. La configuración inicial involucra reportarle al sistema de auditoría todo cambio no estandarizado que realices, además de definir rutas a ser ejecutadas para crear la lectura de la línea base.

También hace que las operaciones cotidianas sean más complicadas. Dificulta los procesos de actualización, ya que necesitarás revisar de nuevo el sistema antes de la actualización y recrear la línea base después del proceso, para hacer coherente las nuevas versiones de software. Además, deberás descargar los reportes a un lugar diferente buscando que un intruso no pueda alterarlos para cubrir sus huellas.

Si bien esto podría incrementar tu carga administrativa, ser capaz de escanear tu sistema con base en una copia conocida, es una de las únicas formas de asegurar que tus archivos no han sido alterados sin tu conocimiento. Algunos sistemas de auditoría de archivos y/o detección de intrusos son: [Tripwire](how-to-use-tripwire-to-detect-server-intrusions-on-an-ubuntu-vps) y [Aide](how-to-install-aide-on-a-digitalocean-vps).

## Ambientes aislados de ejecución

Los ambientes aislados de ejecución hacen referencia a cualquier método usado para que un componente individual se ejecute dentro de su propio espacio dedicado.

![Diagrama de ambientes aislados](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/translateddiagrams32918/SingleServer-vs-IsolatedAppDBServers-Spanish@2x.png)

Esto puede significar separar los componentes de tu aplicación en servidores propios a cada componente discreto o podría referirse a configurar la operación de sus servicios en ambientes o contenedores `chroot`. El nivel de aislamiento dependerá directamente de los requerimientos de tu aplicación y de las condiciones reales de tu infraestructura.

### ¿Cómo éstos mejoran la seguridad?

Aislar tus procesos en ambientes individuales de ejecución incrementa tu habilidad para aislar cualquier problema de seguridad que se pueda presentar. Similar a cómo los [mamparos](https://es.wikipedia.org/wiki/Mamparo) y compartimentos pueden contener una inundación por fractura del casco en un barco, separar sus componentes individuales puede limitar el acceso que intrusos tengan a otras partes de tu infraestructura.

### ¿Qué tan difícil es implementarlos?

Dependiendo del tipo de contención que escojas, aislar tus aplicaciones puede ser relativamente simple. Al empacar sus componentes individuales en contenedores, puedes rápidamente generar un grado de aislamiento; hay que notar que Docker no considera su sistema de contenedores como una característica de seguridad.

Creando un ambiente `chroot` para cada pieza se puede proveer un grado de aislamiento también, sin embargo, esto no representa un método infalible de aislamiento, ya que se conocen maneras de quebrar el ambiente `chroot`. El mejor nivel de aislamiento se da al mover los componentes a máquinas dedicadas, y en muchos casos es lo más fácil, pero esto podría incrementar los costos asociados a las máquinas adicionales.

## Conclusión

Las estrategias mencionadas anteriormente son solo algunas mejoras que pueden incrementar la calidad de la seguridad en tus sistemas. Es importante reconocer que, mejor tarde que nunca, la efectividad de las medidas de seguridad decrece entre más tiempo se retrase su implementación. La seguridad no puede ser implementada después de que sea necesaria, debe ser implementada desde el inicio y durante la prestación de servicios y aplicaciones.
