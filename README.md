# RapidGo Serverless Backend

Plataforma colombiana de domicilios con backend serverless en Microsoft Azure. Conecta clientes, repartidores y comercios locales mediante una arquitectura orientada a eventos, escalable automáticamente y optimizada para notificaciones push en tiempo real.

---

## Modelo C4

El modelo C4 representa la arquitectura del sistema en cuatro niveles de abstracción, facilitando la comunicación entre los equipos técnicos y de negocio.

### C1 – Diagrama de Contexto

Interacción del sistema RapidGo con los actores principales (cliente, repartidor, administrador) y servicios externos (React Native, FCM, APNs, pasarela de pagos).

![Diagrama de Contexto C1](assets/Diagramas/c1-contexto.png)

### C2 – Diagrama de Contenedores

Componentes principales de la arquitectura: API Management, Azure Functions, Cosmos DB, Blob Storage y Notification Hubs.

![Diagrama de Contenedores C2](assets/Diagramas/c2-contenedores.png)

### C3 – Diagrama de Componentes

Descomposición interna de la capa de lógica de negocio, mostrando las funciones implementadas y sus relaciones.

![Diagrama de Componentes C3](assets/Diagramas/c3-componentes.png)

---

## Decisiones Arquitectónicas (ADR)

Las decisiones arquitectónicas fundamentales se documentan en archivos individuales dentro de [`assets/ADRS/`](assets/ADRS/). Cada ADR incluye el contexto, las alternativas evaluadas, la decisión adoptada y sus consecuencias.

| # | Título | Archivo |
|---|---|---|
| ADR-001 | Uso de Azure Functions (Serverless) sobre Azure App Service | [`assets/ADRS/ADR 1.md`](assets/ADRS/ADR_1.md) |
| ADR-002 | Cosmos DB como sistema de almacenamiento principal | [`assets/ADRS/ADR 2.md`](assets/ADRS/ADR_2.md) |
| ADR-003 | API Management como gateway de entrada | [`assets/ADRS/ADR 3.md`](assets/ADRS/ADR_3.md) |
| ADR-004 | Azure Blob Storage sobre Azure Files para almacenamiento | [`assets/ADRS/ADR 4.md`](assets/ADRS/ADR_4.md) |
| ADR-005 | Azure Notification Hubs sobre Azure Communication Services | [`assets/ADRS/ADR 5.md`](assets/ADRS/ADR_5.md) |

Cada archivo contiene la evaluación técnica completa con tabla de puntuación por requerimiento no funcional y justificación detallada.

---

---

## Arquitectura Cloud

La solución se fundamenta en una arquitectura serverless nativa de Azure. Las funciones del backend se ejecutan bajo demanda mediante servicios administrados, eliminando la gestión manual de servidores y adaptando la capacidad del sistema a la carga de trabajo en tiempo real.

Principios arquitectónicos:

- **Arquitectura orientada a eventos**: cada operación del sistema (registro de pedido, cambio de estado, notificación) se modela como un evento que dispara funciones específicas.
- **Escalabilidad automática**: Azure Functions escala horizontalmente según el volumen de solicitudes sin intervención manual.
- **Pago por uso**: solo se facturan los recursos consumidos durante la ejecución, eliminando costos fijos de infraestructura ociosa.
- **Alta disponibilidad**: los servicios administrados de Azure garantizan SLAs de disponibilidad y replicación geográfica opcional.
- **Desacoplamiento de servicios**: cada componente del sistema es independiente, permitiendo desarrollar, desplegar y escalar cada uno por separado.
- **Backend serverless**: la lógica de negocio se implementa mediante Azure Functions, eliminando la necesidad de aprovisionar o mantener servidores.

---

## Arquitectura de Solución

### Azure Functions

**Propósito**: ejecutar la lógica de negocio del sistema en un entorno serverless.

Las funciones implementan los casos de uso principales como `registrarPedido`, `actualizarEstadoPedido`, `consultarHistorialPedidos` y `enviarNotificacionCliente`. Cada función se activa mediante peticiones HTTP a través de API Management o mediante cambios en los datos.

**Beneficios técnicos**: escalado automático, aislamiento por función, integración nativa con el ecosistema Azure y facturación por ejecución.

### Azure API Management

**Propósito**: actuar como punto de entrada único para todas las solicitudes de la aplicación móvil.

Gestiona el enrutamiento, la autenticación, el rate limiting y la transformación de peticiones antes de que lleguen a las Azure Functions. Expone una fachada REST consistente hacia los clientes.

**Beneficios técnicos**: seguridad centralizada, control de tráfico, documentación interactiva de la API y compatibilidad con políticas de transformación.

### Azure Cosmos DB

**Propósito**: almacenar y consultar los datos de la plataforma (pedidos, usuarios, comercios) con baja latencia.

Se utiliza como base de datos NoSQL con modelo de datos flexible, ideal para los documentos JSON que maneja la aplicación.

**Beneficios técnicos**: latencias de milisegundos de un solo dígito, distribución global multi-región, escalado elástico del rendimiento y SLAs integrales.

### Azure Blob Storage

**Propósito**: almacenar archivos no estructurados como imágenes de productos, comprobantes de entrega y recursos estáticos de la plataforma.

**Beneficios técnicos**: almacenamiento durable y redundante, escalabilidad masiva, acceso seguro mediante SAS tokens y costos optimizados por nivel de acceso.

### Azure Notification Hubs

**Propósito**: gestionar el envío de notificaciones push a los dispositivos móviles de clientes y repartidores.

Se integra con Firebase Cloud Messaging (FCM) para dispositivos Android y con Apple Push Notification Service (APNs) para iOS, permitiendo un único punto de administración para todas las notificaciones.

**Beneficios técnicos**: envío masivo escalable, soporte multiplataforma (FCM, APNs), personalización por etiqueta y segmentación de audiencias.

## Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Backend serverless | Azure Functions (Node.js) |
| API Gateway | Azure API Management |
| Base de datos | Azure Cosmos DB (NoSQL) |
| Almacenamiento de archivos | Azure Blob Storage |
| Notificaciones push | Azure Notification Hubs |
| Cliente móvil | React Native |
| Push Android | Firebase Cloud Messaging (FCM) |
| Push iOS | Apple Push Notification Service (APNs) |
| Pruebas de API | Postman |

---

## Diagrama de Arquitectura

Visión general de la arquitectura de la solución RapidGo Backend Serverless, mostrando el flujo de datos desde el usuario a través de los servicios Azure principales y los servicios complementarios de soporte.

![Diagrama de Arquitectura](assets/Diagramas/diagrama-arq.png)

---

*Tecnológico de Antioquia — Institución Universitaria*  
*Computación en la Nube | Semestre 2026-1*  
*Profesor: Julian David Florez Sanchez*

