# ADR-02: Cosmos DB vs Azure SQL Database para la persistencia de pedidos

## Contexto

RapidGo requiere procesar hasta **4.500 pedidos en picos de demanda** y garantizar una **latencia de API inferior a 800 ms**, escalando hasta **500 requests/segundo** sin intervención manual.

Adicionalmente:

- El presupuesto inicial de infraestructura en Azure está limitado a **$50 USD mensuales**.
- El sistema actual opera sobre una base de datos relacional **MySQL** con **3 años de datos históricos**.
- La naturaleza del negocio implica almacenar atributos variables según el tipo de comercio:
  - Restaurantes
  - Tiendas locales

---

## Alternativas evaluadas

### 1. Azure SQL Database (Serverless / Free Tier)

#### Ventajas

- Mantiene el paradigma relacional actual, eliminando la curva de aprendizaje del equipo.
- Facilita la migración directa de los 3 años de datos históricos desde MySQL.
- Garantiza integridad transaccional ([**ACID**](https://learn.microsoft.com/es-es/azure/azure-sql/database/features-comparison)).

#### Desventajas

- Escalar para soportar ráfagas abruptas de **500 req/s** puede requerir [tiers de cómputo](https://learn.microsoft.com/es-es/azure/azure-sql/database/serverless-tier-overview#performance-configuration) que superen el presupuesto de **$50 USD**.
- Manejar atributos variables de distintos comercios requiere:
  - Alteraciones estructurales (`ALTER TABLE`)
  - Diseños complejos tipo **EAV (Entity-Attribute-Value)**

---

### 2. Azure Cosmos DB (Free Tier)

#### Ventajas

- Su naturaleza [**NoSQL orientada a documentos JSON**](https://learn.microsoft.com/es-es/azure/cosmos-db/nosql/modeling-data) es ideal para manejar atributos dinámicos y variables.
- El [**Free Tier**](https://learn.microsoft.com/es-es/azure/cosmos-db/free-tier) garantiza:
  - **1.000 RU/s**
  - **25 GB de almacenamiento**
- Cumple el requerimiento de:
  - **500 req/s**
  - Límite presupuestal
- Su integración con **Azure Functions** mediante:
  - [Bindings](https://learn.microsoft.com/es-es/azure/azure-functions/functions-bindings-cosmosdb-v2)
  - [Change Feed](https://learn.microsoft.com/es-es/azure/cosmos-db/change-feed)
- Facilita arquitecturas reactivas.

#### Desventajas

- Requiere un cambio de paradigma:
  - De relacional a NoSQL
- Exige un proceso de ingeniería de datos (**ETL**) para:
  - [Desnormalizar](https://learn.microsoft.com/es-es/azure/cosmos-db/nosql/modeling-data#embedding-data)
  - [Migrar](https://learn.microsoft.com/es-es/azure/cosmos-db/migrate-data) los 3 años de histórico desde MySQL hacia documentos JSON

---

### 3. Azure Database for PostgreSQL Flexible Server

#### Ventajas

- Compatible con MySQL, lo que facilita la migración de los 3 años de datos históricos con herramientas como [pgloader](https://pgloader.io/) o scripts de exportación/importación.
- Ofrece escalabilidad automática de cómputo y almacenamiento, con opción de [pausar el servidor](https://learn.microsoft.com/es-es/azure/postgresql/flexible-server/concepts-server-pause) en horas de baja demanda para reducir costos.
- Soporte nativo para tipos **JSONB**, permitiendo almacenar atributos variables de comercios sin alterar el esquema relacional principal.
- Integración directa con Azure Functions mediante [bindings de PostgreSQL](https://learn.microsoft.com/es-es/azure/azure-functions/functions-bindings-postgresql).

#### Desventajas

- Sigue siendo un modelo relacional, por lo que las consultas sobre atributos dinámicos pueden volverse complejas y menos performantes que en un modelo documental nativo.
- La escalabilidad horizontal para soportar **500 req/s** en picos requiere configuración manual de réplicas de lectura o sharding, lo que aumenta la carga operativa del equipo de infraestructura (una sola persona).
- No cuenta con un **Change Feed** nativo como Cosmos DB, lo que dificulta la implementación de arquitecturas reactivas para notificaciones en tiempo real sin agregar componentes adicionales (como Debezium o triggers personalizados).

---

## Decisión

Se elige [**Azure Cosmos DB**](https://learn.microsoft.com/es-es/azure/cosmos-db/) utilizando su [**API for NoSQL**](https://learn.microsoft.com/es-es/azure/cosmos-db/nosql/) bajo el esquema del [**Free Tier**](https://learn.microsoft.com/es-es/azure/cosmos-db/free-tier).

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

---

## Consecuencias

### Ventajas obtenidas

- **Escalabilidad automática y elástica**: Cosmos DB escala horizontalmente sin intervención manual, soportando picos de **500 req/s** durante días festivos sin degradación del servicio.
- **Cumplimiento del presupuesto**: El Free Tier cubre completamente la fase piloto (<$50 USD/mes), eliminando el costo fijo de $4.200.000 COP del servidor dedicado anterior.
- **Latencia consistente**: Respuestas en milisegundos de un solo dígito, reduciendo las cancelaciones espontáneas por lentitud del sistema (actualmente 12% del tráfico).
- **Arquitectura reactiva nativa**: El Change Feed permite desacoplar la lógica de notificaciones, garantizando una tasa de entrega >95% mediante Notification Hubs.
- **Flexibilidad de esquema**: Los atributos variables por tipo de comercio se modelan naturalmente en JSON, sin necesidad de migraciones de esquema ni diseños EAV complejos.

### Trade-offs

- **Curva de aprendizaje NoSQL**: El equipo debe adaptarse al modelo documental y a las mejores prácticas de desnormalización, requiriendo capacitación inicial en modelado de datos para Cosmos DB.
- **Migración de datos históricos**: Los 3 años de datos en MySQL requieren un proceso ETL para transformar tablas relacionales en documentos JSON, lo que implica un esfuerzo inicial de ingeniería de datos.
- **Consistencia eventual vs fuerte**: Aunque Cosmos DB ofrece 5 niveles de consistencia, se priorizará **Session** o **Bounded Staleness** para optimizar latencia y costo, aceptando consistencia eventual en lecturas no críticas.
- **Vendor lock-in moderado**: La dependencia de la API for NoSQL y el Change Feed de Cosmos DB reduce la portabilidad hacia otros proveedores cloud, aunque la arquitectura serverless mitiga este riesgo al mantener la lógica de negocio en Azure Functions independientes.
- **Costos por RU/s en escala masiva**: Si los pedidos superan consistentemente las 1.000 RU/s del Free Tier, será necesario migrar a un plan de pago por uso, aunque el modelo de facturación por RU consumida sigue siendo más eficiente que el costo fijo anterior.
