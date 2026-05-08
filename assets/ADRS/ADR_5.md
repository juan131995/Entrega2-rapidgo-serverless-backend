# ADR-05: Azure Notification Hubs vs Azure Communication Services vs Amazon SNS para notificaciones push

## Contexto

La aplicación móvil de **RapidGo** necesita enviar **notificaciones push en tiempo real** a los clientes cuando cambia el estado de un pedido:

- Pedido confirmado
- Pedido en camino
- Pedido entregado

Estas notificaciones deben llegar a dispositivos:

- **Android**
- **iOS**

El sistema actual presenta problemas de confiabilidad en la entrega de notificaciones, generando confusión en los clientes sobre el estado de sus pedidos.

La nueva arquitectura **serverless en la nube** debe cumplir con los siguientes requerimientos:

- Alcanzar una **tasa de entrega superior al 95%**.
- Integrarse con la aplicación móvil desarrollada en **React Native**.
- Escalar automáticamente durante picos de demanda.
- Integrarse con los servicios de notificación nativos de cada plataforma:

  - **[Firebase Cloud Messaging (FCM)](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview)**
  - **[Apple Push Notification Service (APNs)](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview)**

Dentro de la arquitectura de RapidGo, las notificaciones se enviarán cuando el backend detecte un **cambio en el estado del pedido**, con el objetivo de mejorar la **experiencia del usuario y la transparencia del servicio**.

Para resolver este problema se evaluaron tres servicios cloud capaces de manejar **notificaciones push a gran escala**.

---

# Alternativas evaluadas

---

# 1. Azure Notification Hubs

## Ventajas

- Servicio diseñado específicamente para **notificaciones push móviles** mediante integración directa con **[Platform Notification Services (PNS)](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview)**.

- Permite enviar notificaciones a aplicaciones **Android e iOS** utilizando:

  - **[Firebase Cloud Messaging (FCM)](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview)**
  - **[Apple Push Notification Service (APNs)](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview)**

- Permite segmentar usuarios mediante **[tags o etiquetas dinámicas](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview)**, lo que facilita enviar notificaciones específicas como:

  - notificaciones por usuario
  - notificaciones por pedido
  - notificaciones por región

- Permite escalar a **millones de dispositivos** sin necesidad de rediseñar la arquitectura.

- Puede integrarse fácilmente con **[Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/)** dentro de arquitecturas serverless.

- Ofrece seguridad mediante **[Shared Access Signature (SAS)](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview)**.

## Desventajas

- Depende de los servicios de notificación externos de las plataformas (**[PNS](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-fixer)**).

- La entrega final depende de la disponibilidad de:

  - **[APNs](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-fixer)**
  - **[FCM](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-fixer)**

- Una vez enviada la notificación a estos servicios, **Azure pierde control sobre la entrega final al dispositivo**.

---

# 2. Azure Communication Services

## Ventajas

- Plataforma de comunicación que soporta múltiples canales:

  - **[SMS](https://learn.microsoft.com/en-us/azure/communication-services/concepts/sms/concepts)**
  - **[Chat](https://learn.microsoft.com/en-us/azure/communication-services/concepts/chat/concepts)**
  - **[Voice](https://learn.microsoft.com/en-us/azure/communication-services/concepts/voice-video-calling/about-call-types)**
  - **[Video](https://learn.microsoft.com/en-us/azure/communication-services/concepts/voice-video-calling/about-call-types)**

- Ofrece **[SDKs oficiales](https://learn.microsoft.com/en-us/azure/communication-services/overview)** para múltiples lenguajes:

  - JavaScript
  - .NET
  - Android
  - iOS

- Permite integrar comunicaciones con la **[red telefónica pública (PSTN)](https://learn.microsoft.com/en-us/azure/communication-services/concepts/services)**.

## Desventajas

- No está diseñado específicamente para **notificaciones push móviles**.

- Requiere mayor esfuerzo de desarrollo para implementar lógica de mensajería equivalente a notificaciones push.

- Las funcionalidades de SMS dependen de **[disponibilidad regional y regulaciones](https://learn.microsoft.com/en-us/azure/communication-services/concepts/sms/concepts)**.

- Puede incrementar los costos al utilizar canales como SMS en lugar de notificaciones push.

---

# 3. Amazon Simple Notification Service (SNS)

## Ventajas

- Servicio de mensajería completamente gestionado que soporta **[publicación y suscripción de eventos](https://docs.aws.amazon.com/sns/latest/dg/welcome.html)**.

- Permite enviar notificaciones push a dispositivos móviles mediante integración con:

  - **[Firebase Cloud Messaging (FCM)](https://docs.aws.amazon.com/sns/latest/dg/sns-send-custom-platform-specific-payloads-mobile-devices.html)**
  - **[Apple Push Notification Service (APNs)](https://docs.aws.amazon.com/sns/latest/dg/mobile-push-apns.html)**

- Permite enviar notificaciones a múltiples endpoints mediante **[topics y suscripciones](https://docs.aws.amazon.com/sns/latest/dg/sns-create-topic.html)**.

- Escala automáticamente para enviar **millones de mensajes por segundo**.

- Permite integrarse fácilmente con otros servicios de AWS como:

  - **[AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)**
  - **[Amazon SQS](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/welcome.html)**

## Desventajas

- Introduce **dependencia con el ecosistema AWS**, mientras que RapidGo utiliza infraestructura basada en Azure.

- Integrarlo dentro de una arquitectura Azure puede requerir **configuraciones adicionales de red y seguridad**.

- Puede aumentar la complejidad operativa al utilizar servicios de múltiples proveedores cloud.

---

# Decisión

Se selecciona **[Azure Notification Hubs](https://learn.microsoft.com/en-us/azure/notification-hubs/)** como la solución principal para el envío de **notificaciones push en RapidGo**.

---

# Justificación

Azure Notification Hubs es la opción más adecuada para RapidGo debido a que está diseñado específicamente para **notificaciones push a aplicaciones móviles**, lo cual se ajusta directamente a las necesidades de la aplicación.

Además, permite:

- Integrarse fácilmente con **[Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/)** dentro de la arquitectura serverless del sistema.
- Enviar notificaciones a **Android y iOS desde un único servicio**.
- Manejar grandes volúmenes de notificaciones sin necesidad de administrar infraestructura adicional.
- Reducir la complejidad del backend mediante una **API unificada para múltiples plataformas**.

El servicio también ofrece un **[Free Tier](https://azure.microsoft.com/en-us/pricing/details/notification-hubs/)** que permite iniciar el proyecto con costos bajos en las primeras etapas.

Dentro del flujo de RapidGo, cuando el estado de un pedido cambie en el backend, una **Azure Function** publicará un evento que enviará una notificación al cliente correspondiente mediante Azure Notification Hubs, mejorando la **experiencia del usuario y la visibilidad del estado de los pedidos en tiempo real**.

---

# Consecuencias

## Positivas

- Mejora significativa en la **experiencia del cliente** mediante notificaciones en tiempo real.
- Arquitectura alineada con el ecosistema **Azure serverless**.
- Escalabilidad para manejar grandes volúmenes de pedidos y usuarios.
- Reducción de complejidad en el backend.

## Negativas

- Dependencia de servicios externos como **APNs y FCM** para la entrega final.
- Requiere correcta configuración de certificados y credenciales de las plataformas móviles.
