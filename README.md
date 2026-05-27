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

Se integra con Firebase Cloud Messaging (FCM V1) para dispositivos Android, permitiendo un único punto de administración para todas las notificaciones push.

**Beneficios técnicos**: envío masivo escalable, soporte multiplataforma (FCM, APNs), personalización por etiqueta y segmentación de audiencias.

### Azure Key Vault

**Propósito**: almacenar y gestionar de forma segura los secretos de la aplicación: cadenas de conexión de Cosmos DB, Blob Storage y Notification Hubs.

Las Azure Functions acceden a los secretos mediante referencias Key Vault (`@Microsoft.KeyVault(...)`) y una identidad administrada asignada al sistema (MSI), sin que ningún secreto quede expuesto en el código fuente o en las variables de entorno en texto plano.

---

## Diagrama de Arquitectura

Visión general de la arquitectura de la solución RapidGo Backend Serverless, mostrando el flujo de datos desde el usuario a través de los servicios Azure principales y los servicios complementarios de soporte.

![Diagrama de Arquitectura](assets/Diagramas/diagrama-arq.png)

---

## Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Backend serverless | Azure Functions (Node.js 18) |
| API Gateway | Azure API Management (Developer SKU) |
| Base de datos | Azure Cosmos DB (API SQL / NoSQL) |
| Almacenamiento de archivos | Azure Blob Storage |
| Notificaciones push | Azure Notification Hubs (Free SKU) |
| Gestión de secretos | Azure Key Vault |
| Monitoreo | Azure Application Insights + Log Analytics |
| Push Android | Firebase Cloud Messaging V1 (FCM V1) |
| Pruebas de API | Postman |
| IaC | ARM Templates (JSON) |
| CI/CD | GitHub Actions |

---

## Estructura del Repositorio

```
.
├── .github/
│   └── workflows/
│       ├── main-pipeline.yml          # Orquestador principal de infraestructura
│       ├── deploy-resource-group.yml  # Job 01: Resource Group
│       ├── deploy-storage.yml         # Job 02: Blob Storage
│       ├── deploy-cosmosdb.yml        # Job 03: Cosmos DB
│       ├── deploy-notification-hub.yml# Job 04: Notification Hubs
│       ├── deploy-keyvault.yml        # Job 05: Key Vault + secretos
│       ├── deploy-functions-infra.yml # Job 06: Function App + MSI
│       ├── deploy-apim.yml            # Job 07: API Management
│       └── deploy-functions.yml       # Despliegue del código de funciones
├── src/
│   ├── infra-arm/
│   │   ├── storage/template.json
│   │   ├── cosmosdb/template.json
│   │   ├── notification-hub/template.json
│   │   ├── keyvault/template.json
│   │   ├── functions/template.json
│   │   └── apim/template.json
│   ├── rapidgo-functions/
│   │   ├── registro-pedido/           # POST /api/v1/registro-pedido
│   │   ├── act-estado/                # PUT  /api/v1/act-estado/{pedidoId}
│   │   ├── historial/                 # GET  /api/v1/historial
│   │   ├── notificacion/              # POST /api/v1/notificacion
│   │   ├── gestion-usuarios/          # GET|POST|PUT /api/v1/usuarios/{id?}
│   │   ├── shared/
│   │   │   ├── cosmos.js              # Cliente Cosmos DB compartido
│   │   │   └── notification.js        # Cliente Notification Hubs compartido
│   │   ├── host.json
│   │   └── package.json
│   └── RapidGo-dev.postman_collection.json
└── assets/
    ├── Diagramas/
    └── ADRS/
```

---

## Pipeline de CI/CD

El despliegue de infraestructura se ejecuta mediante `main-pipeline.yml`, activado manualmente (`workflow_dispatch`). El grafo de dependencias es:

```
setup
  └── 01-resource-group
        ├── 02-storage        ─┐
        ├── 03-cosmosdb       ─┼── 05-keyvault ── 06-functions ── 07-apim
        └── 04-notification   ─┘
```

El despliegue del código de funciones (`deploy-functions.yml`) se activa automáticamente en cada `push` a `main` o `develop` cuando hay cambios en `src/rapidgo-functions/`.

### Secret requerido

| Secret | Descripción |
|--------|-------------|
| `AZURE_CREDENTIALS` | JSON de credenciales del Service Principal de Azure |

---

## Modelo de Datos (Cosmos DB)

Todos los documentos se almacenan en un único contenedor con clave de partición `/tipo`.

### Documento: Pedido

```json
{
  "id": "uuid-v4",
  "tipo": "pedido",
  "usuarioId": "usuario-001",
  "origen": {
    "direccion": "Calle 50 #40-10, Medellín",
    "lat": 6.2442,
    "lng": -75.5812
  },
  "destino": {
    "direccion": "El Poblado, Medellín",
    "lat": 6.2087,
    "lng": -75.5742
  },
  "producto": {
    "nombre": "Hamburguesa doble",
    "descripcion": "Con papas y gaseosa"
  },
  "estado": "pendiente",
  "createdAt": "2026-05-21T14:35:03.400Z",
  "updatedAt": "2026-05-21T14:35:03.400Z"
}
```

### Documento: Usuario

```json
{
  "id": "uuid-v4",
  "tipo": "usuario",
  "nombre": "Juan Pérez",
  "email": "juan@ejemplo.com",
  "telefono": "+57 300 000 0000",
  "rol": "cliente",
  "createdAt": "2026-05-21T14:00:00.000Z",
  "updatedAt": "2026-05-21T14:00:00.000Z"
}
```

### Máquina de Estados del Pedido

```
pendiente ──► asignado ──► recogido ──► enCamino ──► entregado
    │              │            │            │
    └──────────────┴────────────┴────────────┴──► cancelado
```

Las transiciones válidas son:

| Estado actual | Estados permitidos |
|---|---|
| `pendiente` | `asignado`, `cancelado` |
| `asignado` | `recogido`, `cancelado` |
| `recogido` | `enCamino`, `cancelado` |
| `enCamino` | `entregado`, `cancelado` |
| `entregado` | — |
| `cancelado` | — |

---

## API Reference

Todas las peticiones pasan por el **API Gateway (APIM)**. La URL base es:

```
https://rg-dev-v1-apim-260521053489.azure-api.net/api/v1
```

Todas las peticiones deben incluir el header:

```
Ocp-Apim-Subscription-Key: <clave-de-suscripcion-apim>
```

---

### POST /registro-pedido

Registra un nuevo pedido en el sistema. Devuelve el documento completo creado en Cosmos DB con estado `pendiente`.

**Request body**

```json
{
  "usuarioId": "usuario-001",
  "origen": {
    "direccion": "Calle 50 #40-10, Medellín",
    "lat": 6.2442,
    "lng": -75.5812
  },
  "destino": {
    "direccion": "El Poblado, Medellín",
    "lat": 6.2087,
    "lng": -75.5742
  },
  "producto": {
    "nombre": "Hamburguesa doble",
    "descripcion": "Con papas y gaseosa"
  }
}
```

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `usuarioId` | string | Sí | Identificador del usuario que realiza el pedido |
| `origen` | object | Sí | Dirección y coordenadas de recogida |
| `destino` | object | Sí | Dirección y coordenadas de entrega |
| `producto` | object | Sí | Nombre y descripción del producto |

**Respuestas**

| Código | Descripción |
|---|---|
| `201` | Pedido creado exitosamente. Body: documento completo del pedido |
| `400` | Faltan campos requeridos |
| `500` | Error interno del servidor |

---

### PUT /act-estado/{pedidoId}

Actualiza el estado de un pedido existente. Valida que la transición sea válida según la máquina de estados.

**Parámetros de ruta**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `pedidoId` | string | ID único del pedido (UUID) |

**Request body**

```json
{
  "estado": "asignado"
}
```

| Campo | Tipo | Requerido | Valores válidos |
|---|---|---|---|
| `estado` | string | Sí | `asignado`, `recogido`, `enCamino`, `entregado`, `cancelado` |

**Respuestas**

| Código | Descripción |
|---|---|
| `200` | Estado actualizado. Body: documento completo del pedido actualizado |
| `400` | Transición inválida o campo faltante. Body incluye las transiciones permitidas |
| `404` | Pedido no encontrado |
| `500` | Error interno del servidor |

**Ejemplo de error de transición inválida**

```json
{
  "error": "Transicion invalida: no se puede cambiar de \"asignado\" a \"enCamino\"",
  "permitidas": ["recogido", "cancelado"]
}
```

---

### GET /historial

Consulta el historial de pedidos. Permite filtrar por usuario y/o estado. Los resultados se ordenan por fecha de creación descendente.

**Query parameters**

| Parámetro | Tipo | Requerido | Descripción |
|---|---|---|---|
| `usuarioId` | string | No | Filtra pedidos del usuario especificado |
| `estado` | string | No | Filtra por estado (`pendiente`, `asignado`, etc.) |

**Ejemplo de request**

```
GET /api/v1/historial?usuarioId=usuario-001
GET /api/v1/historial?usuarioId=usuario-001&estado=enCamino
GET /api/v1/historial
```

**Respuestas**

| Código | Descripción |
|---|---|
| `200` | Lista de pedidos (array, puede estar vacío) |
| `500` | Error interno del servidor |

---

### POST /notificacion

Envía una notificación push a través de Azure Notification Hubs (FCM V1). Si se especifican `tokens`, la notificación se envía directamente a esos dispositivos; si no, se envía como broadcast.

**Request body**

```json
{
  "pedidoId": "uuid-del-pedido",
  "titulo": "Tu pedido está en camino",
  "mensaje": "El repartidor está a 5 minutos",
  "tokens": []
}
```

| Campo | Tipo | Requerido | Descripción |
|---|---|---|---|
| `pedidoId` | string | Sí | ID del pedido asociado a la notificación |
| `titulo` | string | Sí | Título de la notificación push |
| `mensaje` | string | Sí | Cuerpo del mensaje de la notificación |
| `tokens` | array | No | Lista de tokens FCM de dispositivos destino. Si está vacío, se hace broadcast |

**Respuestas**

| Código | Descripción |
|---|---|
| `200` | Notificación enviada. Body incluye `trackingId` de Notification Hubs |
| `400` | Faltan campos requeridos |
| `502` | Error al comunicarse con Notification Hubs |
| `500` | Error interno del servidor |

**Ejemplo de respuesta exitosa**

```json
{
  "message": "Notificacion enviada correctamente",
  "trackingId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

---

### POST /usuarios

Crea un nuevo usuario en el sistema.

**Request body**

```json
{
  "nombre": "Juan Pérez",
  "email": "juan@ejemplo.com",
  "telefono": "+57 300 000 0000",
  "rol": "cliente"
}
```

| Campo | Tipo | Requerido | Valores válidos |
|---|---|---|---|
| `nombre` | string | Sí | Nombre completo |
| `email` | string | Sí | Correo electrónico |
| `telefono` | string | No | Número de teléfono |
| `rol` | string | Sí | `cliente`, `repartidor`, `admin` |

**Respuestas**: `201` (creado), `400` (campos inválidos), `500` (error)

---

### GET /usuarios/{id?}

Obtiene un usuario por ID, o lista todos los usuarios (con filtro opcional por rol).

**Query parameters (solo para listado)**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `rol` | string | Filtra por rol: `cliente`, `repartidor`, `admin` |

**Respuestas**: `200` (usuario o lista), `404` (no encontrado), `500` (error)

---

### PUT /usuarios/{id}

Actualiza los datos de un usuario existente (nombre, email, teléfono o rol).

**Respuestas**: `200` (actualizado), `400` (rol inválido), `404` (no encontrado), `500` (error)

---

## Políticas de APIM

El API Gateway aplica las siguientes políticas a todas las peticiones:

- **Rate limiting**: 500 llamadas por 60 segundos por suscripción
- **Header forwarding**: agrega `X-Forwarded-For` con la IP del cliente
- **Header cleanup**: elimina `X-Powered-By` de las respuestas
- **Timeout de backend**: 120 segundos máximo por petición
- **Autenticación JWT** (comentada, lista para activar con Auth0)

---

## Colección Postman

La colección de Postman para probar todos los endpoints está disponible en:

**[`src/RapidGo-dev.postman_collection.json`](src/RapidGo-dev.postman_collection.json)**

### Configuración del entorno

Antes de ejecutar las peticiones, configura las siguientes variables de entorno en Postman:

| Variable | Valor |
|---|---|
| `apim_url` | `https://rg-dev-v1-apim-260521053489.azure-api.net/api/v1` |
| `apim_key` | Clave de suscripción del API Management (sección *Suscripciones* en el portal) |
| `pedido_id` | Se asigna automáticamente al ejecutar la petición **01 - Registrar Pedido** |

### Flujo de prueba recomendado

Ejecutar las peticiones en orden para seguir el ciclo de vida completo de un pedido:

| # | Petición | Método | Endpoint | Descripción |
|---|---|---|---|---|
| 01 | Registrar Pedido | `POST` | `/registro-pedido` | Crea un pedido y guarda `pedido_id` automáticamente |
| 02 | Actualizar Estado (asignado) | `PUT` | `/act-estado/{{pedido_id}}` | Asigna el pedido a un repartidor |
| 03 | Actualizar Estado (recogido) | `PUT` | `/act-estado/{{pedido_id}}` | El repartidor recoge el pedido |
| 04 | Actualizar Estado (enCamino) | `PUT` | `/act-estado/{{pedido_id}}` | El pedido va en camino |
| 05 | Enviar Notificacion | `POST` | `/notificacion` | Envía notificación push al cliente vía FCM V1 |
| 06 | Consultar Historial | `GET` | `/historial?usuarioId=usuario-001` | Consulta todos los pedidos del usuario |

> El paso **03 (recogido)** es obligatorio antes del **04 (enCamino)**. La máquina de estados no permite saltar de `asignado` directamente a `enCamino`.

---

*Tecnológico de Antioquia — Institución Universitaria*
*Computación en la Nube | Semestre 2026-1*
*Profesor: Julian David Florez Sanchez*
