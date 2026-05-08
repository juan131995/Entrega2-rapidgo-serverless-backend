# ADR-05: Notification Hubs vs Azure Communication Services para notificaciones push

## Contexto

La aplicación móvil de **RapidGo** necesita enviar **notificaciones push en tiempo real** a los clientes cuando cambia el estado de un pedido:

- Pedido confirmado
- Pedido en camino
- Pedido entregado

Estas notificaciones deben llegar a dispositivos:

- **Android**
- **iOS**

El sistema actual presenta problemas de confiabilidad en la entrega de notificaciones, generando confusión en los clientes sobre el estado de sus pedidos.

La nueva arquitectura **serverless en Azure** debe cumplir con los siguientes requerimientos:

- Alcanzar una **tasa de entrega superior al 95%**.
- Integrarse con la aplicación móvil desarrollada en **React Native**.
- Funcionar con los servicios de notificación de las plataformas:

  - **Firebase Cloud Messaging (FCM)**
  - **Apple Push Notification Service (APNs)**

---

## Alternativas evaluadas

### 1. Azure Notification Hubs

#### Ventajas

- Proporciona una plataforma diseñada específicamente para el envío de **notificaciones push a aplicaciones móviles**.

- Ofrece compatibilidad con múltiples plataformas mediante una interfaz unificada:

  - Android (FCM)
  - iOS (APNs)

- Permite implementar **patrones avanzados de envío de notificaciones**:

  - Difusión a múltiples dispositivos
  - Segmentación mediante etiquetas dinámicas

- Permite enviar notificaciones a **millones de dispositivos** sin rediseñar la infraestructura.

- Proporciona mecanismos de seguridad mediante:

  - **Shared Access Signature (SAS)**
  - Autenticación federada.

Referencia  
https://learn.microsoft.com/es-es/azure/notification-hubs/notification-hubs-push-notification-overview

#### Desventajas

- Depende de servicios externos de notificaciones:

  - **Platform Notification Services (PNS)**
  - **Apple Push Notification Service (APNs)**
  - **Firebase Cloud Messaging (FCM)**

- Existe posibilidad de pérdida de notificaciones debido a:

  - Errores en servicios de notificación externos
  - Configuraciones incorrectas

- Una vez enviada la notificación a los servicios de plataforma, **Azure pierde control sobre la entrega final al dispositivo**.

Referencia  
https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-fixer

---

### 2. Azure Communication Services

#### Ventajas

- Plataforma completa de comunicación que permite:

  - SMS
  - Voz
  - Chat
  - Video

- Disponibilidad de **SDKs y APIs** para múltiples plataformas:

  - JavaScript
  - .NET
  - Android
  - iOS

Referencia  
https://learn.microsoft.com/en-us/azure/communication-services/overview

- Permite integrarse con servicios de comunicación avanzados como la **red telefónica pública (PSTN)**.

Referencia  
https://learn.microsoft.com/en-us/azure/communication-services/concepts/services

#### Desventajas

- Las funcionalidades de **SMS y telefonía dependen de regulaciones regionales** y disponibilidad de números telefónicos.

Referencia  
https://learn.microsoft.com/en-us/azure/communication-services/concepts/sms/concepts

- Requiere mayor esfuerzo de desarrollo para integrar sus APIs dentro de la aplicación.

- Implica configuración adicional de infraestructura dentro de Azure.

Referencia  
https://learn.microsoft.com/en-us/azure/communication-services/overview

---

## Decisión

Se elige **Azure Notification Hubs** como servicio principal para el envío de **notificaciones push en RapidGo**.

---

## Justificación

Azure Notification Hubs está diseñado específicamente para resolver el problema de **distribución masiva de notificaciones push a aplicaciones móviles**, integrándose directamente con los servicios de notificación de cada plataforma.

Esto permite:

- Enviar notificaciones a **Android y iOS desde un único servicio**.
- Reducir la complejidad de implementación en el backend.
- Escalar el envío de notificaciones a **millones de dispositivos**.

Adicionalmente, el servicio ofrece un **Free Tier**, lo cual permite iniciar el proyecto con costos muy bajos durante las primeras etapas.

En el contexto de la arquitectura serverless de RapidGo, **Azure Notification Hubs se integrará con Azure Functions**, permitiendo:

- Desacoplar el envío de notificaciones del flujo principal de pedidos.
- Enviar notificaciones cuando cambie el estado de un pedido.
- Mejorar la experiencia del usuario mediante **actualizaciones en tiempo real**.

---

## Consecuencias

### Positivas

- Plataforma optimizada específicamente para **notificaciones push móviles**.
- Soporte nativo para **Android y iOS**.
- Alta **escalabilidad para millones de dispositivos**.
- Integración sencilla con **Azure Functions**.

### Negativas

- Dependencia de servicios externos como:

  - Firebase Cloud Messaging
  - Apple Push Notification Service

- Si en el futuro se requieren **SMS, llamadas o video**, será necesario integrar **Azure Communication Services u otros servicios adicionales**.

---

## Referencias

https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview

https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-fixer

https://azure.microsoft.com/en-us/pricing/details/notification-hubs/

https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-aspnet-backend-azure-functions
