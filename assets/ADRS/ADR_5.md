# ADR-05: Azure Notification Hubs vs Azure Communication Services vs Amazon SNS para notificaciones push

## Contexto

La aplicación móvil de RapidGo necesita enviar **notificaciones push en tiempo real** a los clientes cuando cambia el estado de un pedido, por ejemplo:

- Pedido confirmado
- Pedido en preparación
- Pedido en camino
- Pedido entregado

Estas notificaciones deben enviarse a dispositivos móviles **Android e iOS** y deben funcionar incluso cuando la aplicación no esté abierta.

Las notificaciones push se entregan a través de servicios específicos de cada plataforma conocidos como **Platform Notification Systems**, como:

- Apple Push Notification Service (APNs)
- Firebase Cloud Messaging (FCM)

Estos sistemas mantienen la conexión con los dispositivos móviles y entregan los mensajes enviados desde el backend de la aplicación. :contentReference[oaicite:0]{index=0}

Para resolver este problema se evaluaron tres servicios cloud capaces de manejar notificaciones y mensajería a gran escala:

- Azure Notification Hubs
- Azure Communication Services
- Amazon Simple Notification Service (SNS)

---

# Alternativas evaluadas

---

# 1. Azure Notification Hubs

Azure Notification Hubs es un servicio de Microsoft Azure diseñado específicamente para **enviar notificaciones push a dispositivos móviles desde cualquier backend**. :contentReference[oaicite:1]{index=1}

El servicio proporciona una infraestructura escalable para enviar notificaciones a millones de dispositivos utilizando una única API. :contentReference[oaicite:2]{index=2}

## Ventajas

- Diseñado específicamente para **notificaciones push móviles multiplataforma**.  
  https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview

- Permite enviar notificaciones a múltiples plataformas utilizando servicios como:

  - Apple Push Notification Service (APNs)
  - Firebase Cloud Messaging (FCM)

  https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview

- Permite enviar notificaciones a **millones de dispositivos con baja latencia** mediante una sola llamada a la API.  
  https://azure.microsoft.com/en-us/products/notification-hubs/

- Permite segmentar usuarios mediante **tags o etiquetas dinámicas**, lo que facilita enviar notificaciones personalizadas a grupos de usuarios.  
  https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview

- Puede integrarse fácilmente con backend services como:

  - Azure Functions
  - .NET
  - Node.js
  - Java

  https://learn.microsoft.com/en-us/azure/notification-hubs/

## Desventajas

- La entrega final depende de los servicios de notificación de cada plataforma como APNs o FCM.  
  https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview

- Requiere gestionar registros de dispositivos y tokens generados por los servicios de notificación móviles.

---

# 2. Azure Communication Services

Azure Communication Services es una plataforma que permite agregar **capacidades de comunicación en tiempo real** como chat, SMS, voz y video a las aplicaciones. :contentReference[oaicite:3]{index=3}

El servicio proporciona APIs REST y SDKs para integrar funcionalidades de comunicación dentro de aplicaciones web y móviles. :contentReference[oaicite:4]{index=4}

## Ventajas

- Permite integrar múltiples canales de comunicación en una aplicación:

  - SMS
  - chat
  - llamadas de voz
  - videollamadas
  - correo electrónico

  https://learn.microsoft.com/en-us/azure/communication-services/overview

- Proporciona SDKs para múltiples plataformas como:

  - JavaScript
  - Android
  - iOS
  - .NET

  https://learn.microsoft.com/en-us/azure/communication-services/overview

- Permite integrar aplicaciones con la **red telefónica pública (PSTN)** para realizar llamadas o enviar SMS.  
  https://learn.microsoft.com/en-us/azure/communication-services/overview

## Desventajas

- No está diseñado específicamente para **notificaciones push móviles del sistema operativo**.

- Las comunicaciones como SMS o llamadas pueden generar **costos adicionales por mensaje o minuto**.

- Requiere mayor desarrollo para implementar una lógica equivalente a notificaciones push.

---

# 3. Amazon Simple Notification Service (SNS)

Amazon SNS es un servicio de mensajería totalmente gestionado que permite enviar mensajes a múltiples suscriptores mediante un modelo **publish/subscribe**.  

También permite enviar notificaciones push a dispositivos móviles utilizando servicios de notificación como APNs o FCM. :contentReference[oaicite:5]{index=5}

## Ventajas

- Permite enviar notificaciones push directamente a aplicaciones móviles mediante integración con:

  - Apple Push Notification Service (APNs)
  - Firebase Cloud Messaging (FCM)

  https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html

- Permite enviar mensajes a múltiples destinos utilizando **topics y suscripciones**.  
  https://docs.aws.amazon.com/sns/latest/dg/welcome.html

- Puede integrarse con otros servicios de AWS como:

  - AWS Lambda
  - Amazon SQS

  https://docs.aws.amazon.com/sns/latest/dg/welcome.html

- Escala automáticamente para manejar grandes volúmenes de mensajes.

## Desventajas

- Introduce dependencia con el ecosistema **AWS**, mientras que la arquitectura de RapidGo está basada en Azure.

- Integrar servicios AWS dentro de una arquitectura Azure puede incrementar la complejidad operativa.

- Requiere gestionar configuraciones adicionales de seguridad y credenciales entre proveedores cloud.

---

# Decisión

Se selecciona **Azure Notification Hubs** como el servicio para el envío de notificaciones push en RapidGo.

---

# Justificación

Azure Notification Hubs está diseñado específicamente para el envío de **notificaciones push a dispositivos móviles a gran escala**, proporcionando una infraestructura que permite enviar mensajes a millones de dispositivos utilizando una única API. :contentReference[oaicite:6]{index=6}

Además, el servicio permite integrar fácilmente aplicaciones móviles con servicios de notificación de las plataformas como **APNs y FCM**, simplificando la gestión de dispositivos y la segmentación de usuarios. :contentReference[oaicite:7]{index=7}

Debido a que RapidGo utiliza una arquitectura basada en **Microsoft Azure**, el uso de Azure Notification Hubs permite mantener la coherencia tecnológica dentro del ecosistema cloud y reducir la complejidad operativa.

---
# Consecuencias

## Ventajas

- Arquitectura alineada con el ecosistema Azure.
- Escalabilidad para manejar grandes volúmenes de notificaciones.
- Entrega de notificaciones push en tiempo real a dispositivos móviles.

## Desventajas (Limitaciones)

- Dependencia de los servicios de notificación de cada plataforma (APNs y FCM).
- Requiere configuración inicial de certificados y credenciales de cada plataforma móvil.
