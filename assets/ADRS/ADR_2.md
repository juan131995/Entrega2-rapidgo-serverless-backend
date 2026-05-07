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
- Garantiza integridad transaccional (**ACID**).

#### Desventajas

- Escalar para soportar ráfagas abruptas de **500 req/s** puede requerir tiers de cómputo que superen el presupuesto de **$50 USD**.
- Manejar atributos variables de distintos comercios requiere:
  - Alteraciones estructurales (`ALTER TABLE`)
  - Diseños complejos tipo **EAV (Entity-Attribute-Value)**

---

### 2. Azure Cosmos DB (Free Tier)

#### Ventajas

- Su naturaleza **NoSQL orientada a documentos JSON** es ideal para manejar atributos dinámicos y variables.
- El **Free Tier** garantiza:
  - **1.000 RU/s**
  - **25 GB de almacenamiento**
- Cumple el requerimiento de:
  - **500 req/s**
  - Límite presupuestal
- Su integración con **Azure Functions** mediante:
  - Bindings
  - Change Feed
- Facilita arquitecturas reactivas.

#### Desventajas

- Requiere un cambio de paradigma:
  - De relacional a NoSQL
- Exige un proceso de ingeniería de datos (**ETL**) para:
  - Desnormalizar
  - Migrar los 3 años de histórico desde MySQL hacia documentos JSON

---

## Decisión

Se elige **Azure Cosmos DB** utilizando su **API for NoSQL** bajo el esquema del **Free Tier**.

---

## Justificación

Aunque implica abandonar el modelo relacional actual, Cosmos DB soluciona los dos problemas más críticos de RapidGo:

1. **Escalabilidad extrema** en horas pico
2. **Reducción radical de costos**

A nivel de negocio, almacenar los pedidos como documentos JSON nativos permite que la aplicación móvil (escrita en **React Native**) reciba y envíe estructuras de datos de forma mucho más ágil sin un ORM pesado en el medio.

La integración nativa de Cosmos DB con Azure Functions mediante **Change Feed** es la decisión clave que permitirá:

- Aislar la lógica de notificaciones (`notificarCliente`)
- Desacoplar el flujo de guardado de datos
- Garantizar actualizaciones en tiempo real mediante **Notification Hubs**
- Mantener una latencia general de API menor a **800 ms**

---

## Consecuencias

### Positivas

- Reducción del costo de persistencia a **$0 USD** durante el piloto usando el tier gratuito.
- Tiempos de respuesta de lectura/escritura de un solo dígito en milisegundos.

---

## Trade-offs asumidos

- El equipo, con experiencia principalmente en:
  - Node.js
  - Python
- Deberá invertir tiempo en aprender:
  - Modelado NoSQL
  - Diseño por particiones
  - Estrategias de desnormalización

---

## Mitigación

Se deberá diseñar un script de migración **one-off (ETL)** en Python para transformar el esquema relacional de los últimos 3 años de MySQL hacia colecciones JSON particionadas por:

- `id_usuario`
- o `fecha`

antes del paso a producción.