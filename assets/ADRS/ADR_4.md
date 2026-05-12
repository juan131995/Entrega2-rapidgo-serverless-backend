# ADR-04: Azure Blob Storage vs Azure Files para el almacenamiento de la aplicación movil RapidGO.
## Contexto

RapidGo requiere almacenar todo el contenido multimedia en su aplicación movil al momento de que los usuarios realicen sus pedidos, incluyendo contenido multimedia tanto de las tiendas como de los repartidores e imagenes y videos de los productos comestibles.


Adicionalmente:

- Los archivos multimedia (fotos y videos) deben visualizarse desde un dispositivo movil con conexión a internet.
- La latencia debe ser la mínima para el optimo funcionamiento de la aplicación movil.

---

## Alternativas evaluadas

### 1. Azure Blob Storage

#### Ventajas

- Permite el almacenamiento de imágenes y archivos multimedia como videos.
- Fortalece la seguridad de la app móvil al acceder por url con protocolos.
- Dispone de una disponibilidad del 99.9% y una replicación eficaz en distintas regiones con mejor disponibilidad. ([**ACID**](https://learn.microsoft.com/es-es/azure/azure-sql/database/features-comparison)).
- Optimiza el rendimiento y minimiza la latencia al momento de usar la app móvil.
- Se puede elegir diferentes capas de almacenamiento para optimizar costos y rendimientos según las necesidades, ([**desde $0,15 por cada gb que se utilice**](https://azure.microsoft.com/es-es/pricing/details/storage/blobs/?msockid=3670edb92d7a635123a4f9272c7b6214)
  
#### Desventajas

- No soporta la estructura de carpetas tradicional sino el manejo de contenedores de almacenamiento de objetos.

---

### 2. Azure Files

#### Ventajas

- Maneja el orden jerárquico de carpetas, subcarpetas y archivos para el almacenamiento.
- Combina un servidor de almacenamiento local con el almacenamiento en la nube en azure, permitiendo que ambos trabajen como uno.

#### Desventajas

- Al usar el protocolo SMB no optimiza su uso para ser un backend de una app móvil de alto rendimiento.
  - De relacional a NoSQL
- Su arquitectura está diseñada para un sistema de archivos tradicional (carpetas), no como un servicio para tráfico HTTP masivo.
- Al utilizar un sistema de archivos tradicional se requiere más recursos a comparación del uso de un solo contenedor.
- Azure Files está diseñado como un servicio de archivos compartidos empresariales. Un CDN es para distribuir contenido web multimedia utilizando HTTP/HTTPS.

---

## Decisión

Se elige [**Azure Blob Storage**](https://learn.microsoft.com/es-es/azure/cosmos-db/) utilizando su [**API for NoSQL**](https://learn.microsoft.com/es-es/azure/cosmos-db/nosql/) bajo el esquema del [**Free Tier**](https://learn.microsoft.com/es-es/azure/cosmos-db/free-tier).

---

## Justificación

Aunque implica abandonar el modelo relacional actual, Cosmos DB soluciona los dos problemas más críticos de RapidGo:

1. **Escalabilidad extrema** en horas pico
2. **Reducción radical de costos**

A nivel de negocio, almacenar los pedidos como documentos JSON nativos permite que la aplicación móvil (escrita en **React Native**) reciba y envíe estructuras de datos de forma mucho más ágil sin un ORM pesado en el medio.

La integración nativa de Cosmos DB con [Azure Functions](https://learn.microsoft.com/es-es/azure/azure-functions/) mediante [**Change Feed**](https://learn.microsoft.com/es-es/azure/azure-functions/functions-bindings-cosmosdb-v2-trigger) es la decisión clave que permitirá:

- Aislar la lógica de notificaciones (`notificarCliente`)
- Desacoplar el flujo de guardado de datos
- Garantizar actualizaciones en tiempo real mediante [**Notification Hubs**](https://learn.microsoft.com/es-es/azure/notification-hubs/)
- Mantener una [latencia general de API](https://learn.microsoft.com/es-es/azure/cosmos-db/nosql/performance-tips) menor a **800 ms**
