# ADR-05: Notification Hubs vs Azure Communication Services para notificaciones push

## Título
Uso de Azure Notification Hubs sobre Azure Communication Services para notificaciones push en RapidGo

---

## Contexto

La aplicación móvil de RapidGo necesita enviar notificaciones push a clientes cuando cambia el estado de un pedido (confirmado, en camino, entregado). Estas notificaciones deben llegar en tiempo real a dispositivos Android y iOS para mejorar la experiencia del usuario.

El sistema actual presenta una baja confiabilidad en la entrega de notificaciones, lo que genera confusión en los clientes sobre el estado de sus pedidos.

La nueva arquitectura serverless en Azure debe permitir:

- Una tasa de entrega superior al 95%.
- Integrarse con la app móvil en React Native.
- Funcionar con Firebase Cloud Messaging (FCM) y Apple Push Notification Service (APNs).

---

## Alternativas evaluadas

### 1. Azure Notification Hubs

#### Ventajas

**Multiplataforma**
- Compatibilidad con todas las principales plataformas de notificación push.
- Una interfaz común para distribuir en todas las plataformas.

**Back-ends cruzados**
- Nube o local.
- .NET, Node.js, Java, Python, etc.

**Conjunto enriquecido de patrones de entrega**
- Difusión a una o varias plataformas.
- Inserción en segmentos con etiquetas dinámicas.

**Escalabilidad**
- Permite enviar mensajes rápidamente a millones de dispositivos sin rediseñar o particionar la infraestructura.

**Seguridad**
- Secreto de acceso compartido (SAS) o autenticación federada.

**Referencia**  
https://learn.microsoft.com/es-es/azure/notification-hubs/notification-hubs-push-notification-overview

#### Desventajas (Limitaciones)

- **Dependencia de servicios de notificación externos**  
  No envía directamente las notificaciones al dispositivo final, sino que intermedia con los servicios de notificación de las plataformas.

  - PNS (Platform Notification Services)  
  - APNs (Apple Push Notification Service)  
  - FCM (Firebase Cloud Messaging)

- **Posible pérdida de notificaciones**  
  Pueden ocurrir debido a errores en los servicios de notificaciones o configuraciones incorrectas.

- **Azure pierde control sobre la entrega final**  
  Una vez enviada al servicio de notificación de la plataforma, Azure no controla la entrega al dispositivo final.

**Referencia**  
https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-fixer

---

### 2. Azure Communication Services

#### Ventajas

- Plataforma completa de comunicación (SMS, voz, chat y video).

- Disponibilidad de SDKs y APIs para múltiples plataformas como:
  - JavaScript
  - .NET
  - Android
  - iOS

Esto facilita la integración en diferentes tipos de aplicaciones.

**Referencia**  
https://learn.microsoft.com/en-us/azure/communication-services/overview

- Integración con servicios de comunicación avanzados como conexión con la red telefónica pública (PSTN).

**Referencia**  
https://learn.microsoft.com/en-us/azure/communication-services/concepts/services

#### Desventajas (Limitaciones)

- **Dependencia de números telefónicos y regulaciones regionales**

Las funcionalidades de SMS y telefonía dependen del país o región y del número telefónico utilizado.

Esto puede limitar su disponibilidad dependiendo de la ubicación del servicio.

**Referencia**  
https://learn.microsoft.com/en-us/azure/communication-services/concepts/sms/concepts

- **Requiere desarrollo e integración en la aplicación**

Azure Communication Services proporciona APIs y SDKs que deben integrarse mediante desarrollo, lo que puede requerir esfuerzo técnico adicional.

**Referencia**  
https://learn.microsoft.com/en-us/azure/communication-services/overview

- **Dependencia de infraestructura y configuración de Azure**

Es necesario crear y configurar recursos dentro de Azure, incluyendo:

- Gestión de recursos
- Autenticación
- Configuración del entorno cloud

**Referencia**  
https://learn.microsoft.com/en-us/azure/communication-services/overview

---

## Decisión y Consecuencias

Se elige **Azure Notification Hubs** como solución principal para el envío de notificaciones push.

### Justificación técnica y de negocio

- Diseñado específicamente para el envío de notificaciones push a aplicaciones móviles.
- Integración directa con:

  - PNS (Platform Notification Services)  
  - APNs (Apple Push Notification Service)  
  - FCM (Firebase Cloud Messaging)

- Disponibilidad de un **plan gratuito (Free Tier)** que permite reducir costos en las primeras etapas del proyecto.

---

## Ventajas obtenidas

**Multiplataforma**
- Compatibilidad con todas las principales plataformas de notificación push.
- Interfaz común para distribuir notificaciones.

**Back-ends cruzados**
- Compatible con nube o local.
- Soporte para múltiples lenguajes: .NET, Node.js, Java, Python.

**Patrones de entrega avanzados**
- Difusión a múltiples plataformas.
- Segmentación mediante etiquetas dinámicas.

**Escalabilidad**
- Envío de mensajes a millones de dispositivos.

**Seguridad**
- Autenticación mediante SAS o autenticación federada.

---

## Desventajas

- Si en el futuro se requieren **SMS o llamadas**, se deberán integrar otros servicios adicionales.

- Dependencia de proveedores externos como:

  - Firebase
  - Apple

---

## Referencias

- https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-overview  
- https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-push-notification-fixer  
- https://azure.microsoft.com/en-us/pricing/details/notification-hubs/  
- https://learn.microsoft.com/en-us/azure/notification-hubs/notification-hubs-aspnet-backend-azure-functions
