# ADR 001: Uso de Azure Functions (Serverless) para la Lógica de Negocio

## Contexto
RapidGo enfrenta una fase piloto con un presupuesto limitado ($50 USD/mes) y un equipo de infraestructura de una sola persona. Se requiere una solución que minimice la carga operativa y escale según la demanda de pedidos sin necesidad de administrar servidores. Además, el equipo domina Python y Node.js, por lo que la solución debe soportar estos lenguajes de forma nativa.

## Alternativas evaluadas

### 1. [Azure App Service (Plan Básico/Estándar)](https://learn.microsoft.com/es-es/azure/app-service/overview)
Ofrece un entorno de hosting dedicado y mayor control sobre el servidor. Sin embargo, implica un costo fijo mensual que podría exceder el presupuesto de $50 USD si se requiere alta disponibilidad, y demanda mayor gestión de parches y escalado manual.

### 2. [Azure Functions (Plan de Consumo)](https://learn.microsoft.com/es-es/azure/azure-functions/consumption-plan)
Modelo serverless donde solo se paga por el tiempo de ejecución. Ofrece una capa gratuita amplia (primer millón de ejecuciones), ideal para el presupuesto limitado, y elimina la administración de infraestructura.

### 3. [Azure Virtual Machines (IaaS)](https://learn.microsoft.com/es-es/azure/virtual-machines/overview)
Consiste en el aprovisionamiento de servidores virtuales donde se tiene control total del sistema operativo. Es la alternativa con mayor carga operativa, ya que el único encargado de infraestructura debería gestionar manualmente la seguridad, actualizaciones del SO y el escalado. Además, genera un costo constante por hora que no se ajusta a cero ante la falta de pedidos, poniendo en riesgo el presupuesto de $50 USD/mes.

## Decisión
Se elige [Azure Functions bajo el Plan de Consumo](https://learn.microsoft.com/es-es/azure/azure-functions/consumption-plan). La justificación técnica se basa en la capacidad de escalado automático a cero (ahorro de costos cuando no hay pedidos) y la integración nativa con los lenguajes del equipo (Node.js/Python). Desde el negocio, permite cumplir con la restricción presupuestaria de la fase piloto y reduce la carga sobre el único encargado de infraestructura al ser un servicio totalmente administrado.

## Consecuencias

### Ventajas
* **Costo operativo:** Cercano a $0 durante el inicio del piloto gracias a la [capa gratuita y el modelo de facturación por consumo](https://learn.microsoft.com/es-es/azure/azure-functions/functions-consumption-costs?tabs=consumption-plan%2Cportal).
* **Escalabilidad:** [Escalabilidad infinita y automática](https://learn.microsoft.com/es-es/azure/azure-functions/functions-concepts?pivots=programming-language-python) ante picos de demanda de usuarios sin intervención manual.
* **Compatibilidad:** Compatibilidad total con la API actual de React Native y los flujos de trabajo de desarrollo del equipo.

### Trade-offs
* **Riesgo de "Cold Start":** Latencia en la primera petición tras inactividad, el cual se mitigará mediante optimización de código en Python/Node.js para mantener los tiempos de respuesta dentro de los contratos actuales.

---
**Enlaces oficiales de referencia:**
- [Información general de Azure Functions](https://learn.microsoft.com/es-es/azure/azure-functions/functions-overview)
- [Planes de hospedaje de Azure Functions](https://learn.microsoft.com/es-es/azure/azure-functions/consumption-plan)
- [Documentación de Azure Virtual Machines](https://learn.microsoft.com/es-es/azure/virtual-machines/overview)
