# ADR-05: Notification Hubs vs Azure Communication Services para notificaciones push

## Contexto

**RapidGo** es una startup colombiana de domicilios que conecta clientes, restaurantes y repartidores mediante una aplicación móvil desarrollada en **React Native** disponible para **Android e iOS**.

Actualmente la plataforma procesa en promedio **1.200 pedidos diarios**, con picos de hasta **4.500 pedidos en horas de alta demanda**, y su modelo de negocio depende directamente de la disponibilidad del sistema. Cada minuto de caída representa pérdidas estimadas de **$180.000 COP** en horas pico.

Uno de los problemas identificados en la infraestructura actual es la **baja confiabilidad en la entrega de notificaciones push**, con una tasa aproximada del **67%**, lo que genera confusión en los clientes sobre el estado de sus pedidos.

En el flujo de negocio de RapidGo, las notificaciones son críticas para informar al cliente cuando cambia el estado del pedido:

- Pedido confirmado
- Pedido en camino
- Pedido entregado

Estas notificaciones deben enviarse en **tiempo real** a dispositivos:

- **Android**
- **iOS**

Dentro de la nueva arquitectura **serverless en Azure**, el sistema de notificaciones se integrará con los siguientes servicios del backend:

- **[Azure API Management](https://learn.microsoft.com/es-es/azure/api-management/api-management-key-concepts)** como punto de entrada de la API.
- **[Azure Functions](https://learn.microsoft.com/es-es/azure/azure-functions/functions-overview)** para ejecutar la lógica de negocio.
- **[Azure Cosmos DB](https://learn.microsoft.com/es-es/azure/cosmos-db/introduction)** para almacenar los pedidos.
- **[Azure Notification Hubs](https://learn.microsoft.com/es-es/azure/notification-hubs/notification-hubs-push-notification-overview)** para enviar notificaciones push.

Cuando el estado de un pedido cambie, una función del backend enviará automáticamente una notificación al dispositivo del cliente.

Además, la solución debe cumplir con los requerimientos no funcionales definidos por RapidGo:

- Alcanzar una **tasa de entrega superior al 95%**.
- Mantener **latencia baja** para actualizaciones en tiempo real.
- Integrarse con la aplicación móvil existente **sin modificar los contratos de la API**.
- Mantener **costos bajos durante la fase piloto (menos de $50 USD mensuales)**.
- Minimizar la carga operativa del equipo de infraestructura.

Para enviar notificaciones push en dispositivos móviles es necesario integrarse con los servicios de notificación de cada plataforma:

- **[Firebase Cloud Messaging (FCM)](https://learn.microsoft.com/es-es/azure/notification-hubs/notification-hubs-push-notification-overview)**
- **[Apple Push Notification Service (APNs)](https://learn.microsoft.com/es-es/azure/notification-hubs/notification-hubs-push-notification-overview)**

Por esta razón se evaluaron dos servicios disponibles dentro del ecosistema de Azure que permiten implementar capacidades de comunicación con los usuarios.

---

## Alternativas evaluadas

### 1. Azure Notification Hubs

#### Ventajas

**Azure Notification Hubs** es un servicio administrado diseñado específicamente para el envío de **notificaciones push a aplicaciones móviles** a gran escala.

En el contexto de RapidGo ofrece las siguientes ventajas:

- Proporciona integración nativa con los servicios de notificación de las plataformas móviles:

  - Android mediante **[Firebase Cloud Messaging (FCM)](https://learn.microsoft.com/es-es/azure/notification-hubs/notification-hubs-push-notification-overview)**
  - iOS mediante **[Apple Push Notification Service (APNs)](https://learn.microsoft.com/es-es/azure/notification-hubs/notification-hubs-push-notification-overview)**

- Permite enviar notificaciones desde un **único backend**, evitando tener que implementar lógica independiente para cada plataforma.

- Se integra fácilmente con arquitecturas **serverless**, permitiendo que **[Azure Functions](https://learn.microsoft.com/es-es/azure/azure-functions/functions-overview)** envíe notificaciones cuando cambie el estado de un pedido.

- Permite implementar **segmentación mediante etiquetas dinámicas (tags)** para enviar notificaciones específicas a cada usuario o pedido.

- Escala automáticamente para soportar **millones de dispositivos**, lo cual es importante si RapidGo expande su operación a más ciudades.

- Ofrece un **[Free Tier del servicio](https://azure.microsoft.com/en-us/pricing/details/notification-hubs/)** que permite enviar hasta **1 millón de notificaciones al mes**, lo cual se ajusta a las restricciones de presupuesto del proyecto piloto.

#### Desventajas

- Depende de servicios externos de notificación denominados **Platform Notification Services (PNS)** como:

  - **[Firebase Cloud Messaging (FCM)](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-fixer)**
  - **[Apple Push Notification Service (APNs)](https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-fixer)**

- La entrega final depende de la disponibilidad de los servicios de notificación de cada plataforma.

- Una vez enviada la notificación a los servicios de plataforma, **Azure pierde control sobre la entrega final al dispositivo**.

---

### 2. Azure Communication Services

**Azure Communication Services** es una plataforma de comunicación que permite integrar capacidades de mensajería, llamadas y chat en aplicaciones.

#### Ventajas

- Proporciona múltiples canales de comunicación en una sola plataforma:

  - SMS
  - Voz
  - Chat
  - Video

- Permite integrar funcionalidades de comunicación avanzadas mediante **[SDKs y APIs para múltiples plataformas](https://learn.microsoft.com/en-us/azure/communication-services/overview)** como:

  - JavaScript
  - .NET
  - Android
  - iOS

- Permite conectividad con la **[red telefónica pública (PSTN)](https://learn.microsoft.com/en-us/azure/communication-services/concepts/services)**, habilitando llamadas o envío de mensajes SMS a números telefónicos.

#### Desventajas

- No está especializado en el envío de **notificaciones push móviles**, que es el caso principal de RapidGo.

- Requiere mayor esfuerzo de integración para manejar notificaciones push en Android e iOS.

- Sus funcionalidades principales (SMS o telefonía) **no son necesarias para el flujo de negocio actual de RapidGo**, que solo requiere notificaciones dentro de la aplicación móvil.

- Puede incrementar la complejidad operativa y los costos del sistema durante la fase piloto.

---

## Decisión

Se elige **[Azure Notification Hubs](https://learn.microsoft.com/es-es/azure/notification-hubs/)** como servicio principal para el envío de **notificaciones push en la arquitectura serverless de RapidGo**.

---

## Justificación

La elección de **Azure Notification Hubs** se basa en que es un servicio diseñado específicamente para resolver el problema de **distribución masiva de notificaciones push en aplicaciones móviles**.

En el contexto del sistema RapidGo, este servicio permite:

- Enviar notificaciones a **Android e iOS desde un único backend**.
- Integrarse directamente con **[Azure Functions](https://learn.microsoft.com/es-es/azure/azure-functions/functions-overview)**, que ejecutará la lógica de negocio del sistema.
- Disparar notificaciones automáticamente cuando cambie el estado de un pedido.
- Cumplir el requerimiento de **entrega superior al 95%** mediante integración directa con **[FCM](https://learn.microsoft.com/es-es/azure/notification-hubs/notification-hubs-push-notification-overview)** y **[APNs](https://learn.microsoft.com/es-es/azure/notification-hubs/notification-hubs-push-notification-overview)**.

Además, su **[plan gratuito](https://azure.microsoft.com/en-us/pricing/details/notification-hubs/)** permite mantener los costos dentro del límite del proyecto piloto (**menos de $50 USD mensuales**).

Comparado con **[Azure Communication Services](https://learn.microsoft.com/en-us/azure/communication-services/overview)**, Notification Hubs ofrece una solución **más simple, especializada y económica** para el envío de notificaciones push, lo cual se alinea mejor con la arquitectura **serverless, escalable y de bajo costo** requerida por RapidGo.

---

## Consecuencias

### Ventajas

- Implementación sencilla dentro de la arquitectura serverless de RapidGo.
- Integración directa con **Android e iOS** mediante **FCM y APNs**.
- Escalabilidad automática para soportar el crecimiento de usuarios.
- Costos bajos durante la fase piloto gracias al **free tier del servicio**.
- Mejora la experiencia del usuario mediante **actualizaciones del pedido en tiempo real**.

### Trade-offs

- Dependencia de servicios externos de notificación como **FCM** y **APNs**.
- La entrega final al dispositivo depende de la disponibilidad de estos servicios.
- Requiere configuración inicial de credenciales y certificados para cada plataforma.
