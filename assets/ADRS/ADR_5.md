# ADR-05: Azure Notification Hubs vs Azure Communication Services vs Amazon SNS para notificaciones push

## Contexto

La aplicación móvil de **RapidGo** necesita enviar **notificaciones push en tiempo real** a los clientes cuando cambia el estado de un pedido, por ejemplo:

- Pedido confirmado
- Pedido en preparación
- Pedido en camino
- Pedido entregado

Estas notificaciones deben enviarse a dispositivos móviles **Android e iOS** y deben funcionar incluso cuando la aplicación no esté abierta.

Las notificaciones push se entregan a través de servicios específicos de cada plataforma conocidos como **Platform Notification Systems**, como:

- [Apple Push Notification Service (APNs)](https://developer.apple.com/documentation/usernotifications)
- [Firebase Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging)

Estos sistemas mantienen la conexión con los dispositivos móviles y entregan los mensajes enviados desde el backend de la aplicación, tal como se describe en la documentación de [Azure Notification Hubs](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview).

Para resolver este problema se evaluaron tres servicios cloud capaces de manejar **notificaciones y mensajería a gran escala**:

- [Azure Notification Hubs](https://learn.microsoft.com/en-us/azure/notification-hubs/)
- [Azure Communication Services](https://learn.microsoft.com/en-us/azure/communication-services/overview)
- [Amazon Simple Notification Service (SNS)](https://docs.aws.amazon.com/sns/latest/dg/welcome.html)

---

# Alternativas evaluadas

---

# 1. Azure Notification Hubs

[Azure Notification Hubs](https://learn.microsoft.com/en-us/azure/notification-hubs/) es un servicio de Microsoft Azure diseñado específicamente para **enviar notificaciones push a dispositivos móviles desde cualquier backend**.

El servicio proporciona una infraestructura escalable para enviar notificaciones a millones de dispositivos utilizando una única API, como se describe en la documentación oficial de [Notification Hubs](https://azure.microsoft.com/en-us/products/notification-hubs/).

### Ventajas

- Diseñado específicamente para **notificaciones push móviles multiplataforma** según la documentación de  
  [Azure Notification Hubs Push Overview](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview).

- Permite enviar notificaciones a múltiples plataformas utilizando servicios como  
  [Apple Push Notification Service (APNs)](https://developer.apple.com/documentation/usernotifications) y  
  [Firebase Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging).

- Permite enviar notificaciones a **millones de dispositivos con baja latencia** mediante una sola llamada a la API, según la página oficial de  
  [Azure Notification Hubs](https://azure.microsoft.com/en-us/products/notification-hubs/).

- Permite segmentar usuarios mediante **tags o etiquetas dinámicas**, lo que facilita enviar notificaciones personalizadas a grupos de usuarios según la documentación de  
  [Notification Hubs tagging](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview).

- Puede integrarse fácilmente con backend services como  
  [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/),  
  [.NET](https://learn.microsoft.com/en-us/dotnet/),  
  [Node.js](https://nodejs.org/en),  
  o [Java](https://www.java.com/).

### Desventajas

- La entrega final depende de los servicios de notificación de cada plataforma como  
  [APNs](https://developer.apple.com/documentation/usernotifications) o  
  [FCM](https://firebase.google.com/docs/cloud-messaging), lo cual se explica en  
  [Azure Notification Hubs documentation](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview).

- Requiere gestionar registros de dispositivos y tokens generados por los servicios de notificación móviles.

---

# 2. Azure Communication Services

[Azure Communication Services](https://learn.microsoft.com/en-us/azure/communication-services/overview) es una plataforma que permite agregar **capacidades de comunicación en tiempo real** como chat, SMS, voz y video a las aplicaciones.

El servicio proporciona **APIs REST y SDKs** para integrar funcionalidades de comunicación dentro de aplicaciones web y móviles.

### Ventajas

- Permite integrar múltiples canales de comunicación en una aplicación como:

  - [SMS](https://learn.microsoft.com/en-us/azure/communication-services/concepts/sms/concepts)
  - [Chat](https://learn.microsoft.com/en-us/azure/communication-services/concepts/chat/concepts)
  - [Voice](https://learn.microsoft.com/en-us/azure/communication-services/concepts/voice-video-calling/about-call-types)
  - [Video](https://learn.microsoft.com/en-us/azure/communication-services/concepts/voice-video-calling/about-call-types)
  - [Email](https://learn.microsoft.com/en-us/azure/communication-services/concepts/email/email-overview)

- Proporciona SDKs para múltiples plataformas como  
  [JavaScript](https://learn.microsoft.com/en-us/azure/communication-services/overview),  
  Android, iOS y .NET.

- Permite integrar aplicaciones con la **red telefónica pública (PSTN)** según la documentación de  
  [Azure Communication Services](https://learn.microsoft.com/en-us/azure/communication-services/concepts/services).

### Desventajas

- No está diseñado específicamente para **notificaciones push móviles del sistema operativo**.

- Las comunicaciones como SMS o llamadas pueden generar **costos adicionales por mensaje o minuto**, según el modelo de precios de  
  [Azure Communication Services](https://azure.microsoft.com/en-us/pricing/details/communication-services/).

- Requiere mayor desarrollo para implementar una lógica equivalente a notificaciones push.

---

# 3. Amazon Simple Notification Service (SNS)

[Amazon Simple Notification Service (SNS)](https://docs.aws.amazon.com/sns/latest/dg/welcome.html) es un servicio de mensajería completamente gestionado que permite enviar mensajes mediante un modelo **publish/subscribe**.

También permite enviar **notificaciones push a dispositivos móviles** utilizando servicios de notificación como APNs o FCM.

### Ventajas

- Permite enviar notificaciones push a aplicaciones móviles mediante integración con  
  [Apple Push Notification Service (APNs)](https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html) y  
  [Firebase Cloud Messaging (FCM)](https://docs.aws.amazon.com/sns/latest/dg/sns-send-custom-platform-specific-payloads-mobile-devices.html).

- Permite enviar mensajes a múltiples destinos mediante **topics y suscripciones**, como se describe en  
  [Amazon SNS documentation](https://docs.aws.amazon.com/sns/latest/dg/welcome.html).

- Puede integrarse con otros servicios de AWS como  
  [AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html) y  
  [Amazon SQS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/welcome.html).

- Escala automáticamente para manejar grandes volúmenes de mensajes.

### Desventajas

- Introduce dependencia con el ecosistema **AWS**, mientras que la arquitectura de RapidGo está basada en **Microsoft Azure**.

- Integrar servicios AWS dentro de una arquitectura Azure puede incrementar la complejidad operativa.

- Requiere gestionar configuraciones adicionales de seguridad y credenciales entre proveedores cloud.

---

# Decisión

Se selecciona **[Azure Notification Hubs](https://learn.microsoft.com/en-us/azure/notification-hubs/)** como el servicio para el envío de **notificaciones push en RapidGo**.

---

# Justificación

[Azure Notification Hubs](https://azure.microsoft.com/en-us/products/notification-hubs/) está diseñado específicamente para el envío de **notificaciones push a dispositivos móviles a gran escala**, permitiendo enviar mensajes a millones de dispositivos utilizando una única API.

Además, el servicio permite integrar aplicaciones móviles con **[Apple Push Notification Service (APNs)](https://developer.apple.com/documentation/usernotifications)** y **[Firebase Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging)**, simplificando la gestión de dispositivos y la segmentación de usuarios.

Debido a que RapidGo utiliza una arquitectura basada en **Microsoft Azure**, el uso de Notification Hubs permite mantener coherencia tecnológica dentro del ecosistema cloud y reducir la complejidad operativa.

---

# Consecuencias

## Ventajas

- Arquitectura alineada con el ecosistema **Azure**.
- Escalabilidad para manejar grandes volúmenes de notificaciones.
- Entrega de notificaciones push en tiempo real a dispositivos móviles.

## Desventajas (Limitaciones)

- Dependencia de los servicios de notificación de cada plataforma como **APNs** y **FCM**.
- Requiere configuración inicial de certificados y credenciales de cada plataforma móvil.
