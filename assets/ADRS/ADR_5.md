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

Dentro de la nueva arquitectura **serverless en Microsoft Azure**, el sistema de notificaciones debe integrarse con el flujo principal del backend:

1. La aplicación móvil realiza solicitudes a través de **Azure API Management**.
2. Las operaciones del negocio se ejecutan en **Azure Functions**.
3. Los pedidos se almacenan en **Azure Cosmos DB**.
4. Cuando cambia el estado de un pedido, el backend debe enviar una notificación push al cliente.

Además, la solución debe cumplir con los requerimientos no funcionales definidos por RapidGo:

- Alcanzar una **tasa de entrega superior al 95%**.
- Mantener **latencia baja** para actualizaciones en tiempo real.
- Integrarse con la aplicación móvil existente **sin modificar los contratos de la API**.
- Mantener **costos bajos durante la fase piloto (menos de $50 USD mensuales)**.
- Minimizar la carga operativa del equipo de infraestructura, compuesto por **una sola persona**.

Para el envío de notificaciones push en plataformas móviles es necesario integrarse con los servicios de notificación de cada sistema operativo:

- **[Firebase Cloud Messaging (FCM)](https://learn.microsoft.com/es-es/azure/notification-hubs/notification-hubs-push-notification-overview)**
- **[Apple Push Notification Service (APNs)](https://learn.microsoft.com/es-es/azure/notification-hubs/notification-hubs-push-notification-overview)**

Por esta razón se evaluaron dos servicios disponibles en el ecosistema de Azure que permiten implementar capacidades de comunicación con los usuarios.

---

## Alternativas evaluadas

### 1. Azure Notification Hubs

#### Ventajas

**Azure Notification Hubs** es un servicio administrado diseñado específicamente para el envío de **notificaciones push a aplicaciones móviles** a gran escala.

En el contexto de RapidGo ofrece las siguientes ventajas:

- Proporciona integración nativa con los servicios de notificación de las plataformas móviles:

  - Android mediante **FCM**
  - iOS mediante **APNs**

- Permite enviar notificaciones desde un **único backend**, evitando tener que implementar lógica independiente para cada plataforma.

- Se integra fácilmente con arquitecturas **serverless**, permitiendo que **Azure Functions** envíe notificaciones cuando cambie el estado de un pedido.

- Permite utilizar **etiquetas (tags)** para segmentar notificaciones por usuario, dispositivo o pedido.

- Escala automáticamente para soportar **millones de dispositivos**, lo cual es importante si RapidGo expande su operación a más ciudades.

- Ofrece un **plan gratuito** que permite enviar hasta **1 millón de notificaciones al mes**, alineándose con la restricción de **bajo presupuesto del proyecto piloto**.

#### Desventajas

- Depende de servicios externos de notificaciones denominados **Platform Notification Services (PNS)** como:

  - **Firebase Cloud Messaging (FCM)**
  - **Apple Push Notification Service (APNs)**

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

- Permite integrar funcionalidades de comunicación avanzadas mediante APIs y SDKs disponibles para:

  - JavaScript
  - .NET
  - Android
  - iOS

- Permite conectividad con la **red telefónica pública (PSTN)**, habilitando llamadas o envío de mensajes SMS a números telefónicos.

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
- Integrarse directamente con **Azure Functions**, que ejecutará la lógica de negocio del sistema.
- Disparar notificaciones automáticamente cuando cambie el estado de un pedido.
- Cumplir el requerimiento de **entrega superior al 95%** mediante integración directa con los servicios de notificación de cada plataforma.

Además, su **plan gratuito** permite mantener los costos dentro del límite del proyecto piloto (**menos de $50 USD mensuales**), cumpliendo con las restricciones del caso.

Comparado con **Azure Communication Services**, Notification Hubs ofrece una solución **más simple, especializada y económica** para el envío de notificaciones push, lo cual se alinea mejor con la arquitectura **serverless, escalable y de bajo costo** requerida por RapidGo.

---

## Consecuencias

### Ventajas

- Implementación sencilla dentro de la arquitectura serverless de RapidGo.
- Integración directa con **Android e iOS** mediante los servicios oficiales de notificación.
- Escalabilidad automática para soportar el crecimiento de usuarios.
- Costos bajos durante la fase piloto gracias al **free tier** del servicio.
- Permite mejorar la experiencia del usuario mediante **actualizaciones del pedido en tiempo real**.

### Trade-offs

- Dependencia de servicios externos de notificación (FCM y APNs).
- La entrega final al dispositivo depende de la disponibilidad de estos servicios.
- Requiere configuración inicial de credenciales y certificados para cada plataforma.
