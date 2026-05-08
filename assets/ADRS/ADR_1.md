# ADR 001: Uso de Azure Functions (Serverless) para la Lógica de Negocio

## Estado
Propuesto (Mayo 2026)

## Contexto
RapidGo se encuentra en una fase piloto crítica con las siguientes restricciones:
* **Presupuesto:** Limitado a un máximo de $50 USD mensuales.
* **Talento Humano:** El equipo de infraestructura consta de una sola persona.
* **Tecnología:** El equipo de desarrollo tiene experiencia sólida en **Python** y **Node.js**.
* **Requerimientos:** Se necesita una solución que minimice la carga operativa (mantenimiento de servidores) y que sea capaz de escalar de forma elástica según el volumen de pedidos.

## Alternativas Evaluadas

### 1. [Azure App Service (Plan Básico/Estándar)](https://learn.microsoft.com/es-es/azure/app-service/overview)
Ofrece un entorno de hosting dedicado con mayor control sobre la configuración del servidor.
* **Desventaja:** Implica un costo fijo mensual que consume gran parte del presupuesto de $50 USD, independientemente del tráfico. Requiere mayor gestión de parches, actualizaciones y configuración manual del escalado para garantizar alta disponibilidad.

### 2. [Azure Functions (Plan de Consumo)](https://learn.microsoft.com/es-es/azure/azure-functions/consumption-plan)
Modelo *serverless* donde la infraestructura se abstrae totalmente y solo se factura por el tiempo de ejecución efectivo.
* **Ventaja:** Ofrece una capa gratuita sumamente generosa (primer millón de ejecuciones mensuales), lo cual es ideal para la fase inicial del piloto. Elimina la necesidad de administrar el sistema operativo o parches de seguridad del servidor.

## Decisión
Se ha seleccionado **[Azure Functions bajo el Plan de Consumo](https://learn.microsoft.com/es-es/azure/azure-functions/functions-overview)** para implementar la lógica de negocio de RapidGo.

### Justificación Técnica
* **Escalado a Cero:** Cuando no hay pedidos, el costo es de $0 USD, permitiendo preservar el presupuesto para otras áreas.
* **Soporte Nativo:** Es totalmente compatible con el stack actual del equipo (Node.js y Python).
* **Carga Operativa:** Al ser un servicio totalmente administrado, el encargado de infraestructura puede enfocarse en el despliegue y la seguridad en lugar del mantenimiento del servidor.

## Consecuencias

### Ventajas
* **Eficiencia de Costos:** Se estima un gasto operativo cercano a $0 USD durante los primeros meses gracias a la capa gratuita de Azure.
* **Elasticidad:** Capacidad de manejar picos repentinos de demanda de usuarios sin intervención manual.
* **Interoperabilidad:** Compatibilidad total con la API consumida por la aplicación móvil en React Native.

### Trade-offs (Compromisos)
* **Cold Start (Arranque en frío):** Existe un riesgo de latencia en la primera petición después de un periodo de inactividad. 
    * *Mitigación:* Se implementarán optimizaciones de código en Python/Node.js y técnicas de "warming" si es necesario para mantener la experiencia de usuario dentro de los estándares aceptables.

---
**Enlaces de referencia:**
- [Información de costos de Azure Functions](https://learn.microsoft.com/es-es/azure/azure-functions/functions-consumption-costs?tabs=consumption-plan%2Cportal)
- [Documentación oficial de Azure App Service](https://learn.microsoft.com/es-es/azure/app-service/overview)
