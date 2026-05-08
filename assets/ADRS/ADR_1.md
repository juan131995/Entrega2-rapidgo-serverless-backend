# ADR 001: Uso de Azure Functions (Serverless) para la Lógica de Negocio

## Contexto
RapidGo se encuentra en una fase piloto crítica con las siguientes restricciones:
* **Presupuesto:** Máximo de $50 USD mensuales.
* **Infraestructura:** Equipo de una sola persona.
* **Stack Técnico:** Dominio de Python y Node.js.
* **Escalabilidad:** Necesidad de responder a la demanda variable de pedidos sin administración manual de servidores.

## Alternativas Evaluadas

### 1. [Azure App Service (Plan Básico/Estándar)](https://learn.microsoft.com/es-es/azure/app-service/overview)
Entorno de hosting dedicado (PaaS) para aplicaciones web.
* **Limitación:** Representa un costo fijo mensual que compromete el presupuesto de $50 USD. Aunque ofrece control, demanda tareas de mantenimiento (parches y escalado manual) que sobrecargan al único responsable de infraestructura.

### 2. [Azure Functions (Plan de Consumo)](https://learn.microsoft.com/es-es/azure/azure-functions/consumption-plan)
Arquitectura de cómputo basada en eventos (Serverless).
* **Ventaja:** El modelo de pago por ejecución y su capa gratuita (1 millón de solicitudes) permiten un ahorro crítico. La infraestructura es invisible para el desarrollador, facilitando el despliegue rápido en Python y Node.js.

### 3. [Azure Virtual Machines (IaaS)](https://learn.microsoft.com/es-es/azure/virtual-machines/overview)
Despliegue tradicional mediante la creación y gestión de servidores virtuales.
* **Desventaja (Peor opción):** Es la alternativa con mayor carga operativa; el equipo debería configurar el SO, instalar runtimes de Python/Node.js y gestionar la seguridad manualmente. Además, el costo por hora es constante incluso si no hay pedidos, superando fácilmente el presupuesto de la fase piloto sin ofrecer escalado automático nativo.

## Decisión
Se mantiene la elección de **[Azure Functions bajo el Plan de Consumo](https://learn.microsoft.com/es-es/azure/azure-functions/functions-overview)**. 

La combinación de **escalado automático a cero** y la **reducción drástica de tareas de administración** lo convierte en el servicio ideal para que el equipo pueda lanzar el piloto de RapidGo sin exceder los $50 USD mensuales ni saturar al único encargado de infraestructura.

## Consecuencias

### Ventajas
* **Eficiencia y Escalabilidad:** El uso de Azure Functions permite un [escalado dinámico y un modelo basado en eventos](https://learn.microsoft.com/es-es/azure/azure-functions/functions-concepts?pivots=programming-language-csharp) que se ajusta perfectamente a la demanda variable.
* **Costo:** Operatividad cercana a $0 USD durante el inicio del piloto gracias al [plan de consumo](https://learn.microsoft.com/es-es/azure/azure-functions/functions-consumption-costs).
* **Agilidad:** Integración nativa con la API de React Native y facilidad de despliegue para los lenguajes dominados por el equipo.

### Trade-offs
* **Latencia (Cold Start):** Posible demora en la ejecución inicial tras inactividad. Se mitigará mediante optimización de código para asegurar tiempos de respuesta ágiles.

---
**Documentación de referencia:**
- [Azure Functions Overview](https://learn.microsoft.com/es-es/azure/azure-functions/functions-overview)
- [Azure App Service Overview](https://learn.microsoft.com/es-es/azure/app-service/overview)
- [Azure Virtual Machines Overview](https://learn.microsoft.com/es-es/azure/virtual-machines/overview)
