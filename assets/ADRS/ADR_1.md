# ADR 001: Uso de Azure Functions (Serverless) para la Lógica de Negocio

Uso de [Azure Functions (Serverless)](https://learn.microsoft.com/es-es/azure/azure-functions/functions-overview) sobre [Azure App Service](https://learn.microsoft.com/es-es/azure/app-service/overview) para la lógica de negocio de RapidGo.

## Contexto
RapidGo enfrenta una fase piloto con un presupuesto limitado ($50 USD/mes) y un equipo de infraestructura de una sola persona. Se requiere una solución que minimice la carga operativa y escale según la demanda de pedidos sin necesidad de administrar servidores. Además, el equipo domina Python y Node.js, por lo que la solución debe soportar estos lenguajes de forma nativa.

## Alternativas evaluadas

### 1. [Azure App Service (Plan Básico/Estándar)](https://learn.microsoft.com/es-es/azure/app-service/overview)
Ofrece un entorno de hosting dedicado y mayor control sobre el servidor. Sin embargo, implica un costo fijo mensual que podría exceder el presupuesto de $50 USD si se requiere alta disponibilidad, y demanda mayor gestión de parches y escalado manual.

* **Ventajas:** 
  * Proporciona un [entorno de hosting dedicado (PaaS)](https://learn.microsoft.com/es-es/azure/app-service/overview) con aislamiento de recursos.
  * Otorga un [mayor control sobre la configuración del servidor](https://learn.microsoft.com/es-es/azure/app-service/configure-common?tabs=portal) y del entorno de ejecución de las aplicaciones web.
* **Desventajas:** 
  * Conlleva un [costo fijo mensual predecible pero obligatorio](https://azure.microsoft.com/es-es/pricing/details/app-service/linux/), lo que compromete severamente el presupuesto restrictivo de $50 USD/mes.
  * Exige una [gestión e intervención manual para el escalado](https://learn.microsoft.com/es-es/azure/app-service/manage-scale-up) y mayor atención operativa en la administración de parches si se requiere garantizar alta disponibilidad.

### 2. [Azure Functions (Plan de Consumo)](https://learn.microsoft.com/es-es/azure/azure-functions/consumption-plan)
Modelo serverless donde solo se paga por el tiempo de ejecución. Ofrece una capa gratuita amplia (primer millón de ejecuciones), ideal para el presupuesto limitado, y elimina la administración de infraestructura.

* **Ventajas:** 
  * El modelo operativo se basa en [pago por uso estricto](https://learn.microsoft.com/es-es/azure/azure-functions/functions-consumption-costs?tabs=consumption-plan%2Cportal), lo que asegura un ahorro crítico para el presupuesto limitado de la fase piloto.
  * Cuenta con una [concesión mensual gratuita de 1 millón de solicitudes](https://azure.microsoft.com/es-es/pricing/details/functions/), minimizando los costos iniciales de RapidGo.
  * Consiste en un [modelo totalmente administrado](https://learn.microsoft.com/es-es/azure/azure-functions/functions-overview#serverless-compute-on-azure-functions) que abstrae por completo la administración de infraestructura de servidores.
* **Desventajas:** 
  * Se encuentra sujeto al fenómeno de [latencia por arranque en frío (Cold Start)](https://learn.microsoft.com/es-es/azure/azure-functions/event-driven-scaling#cold-starts) cuando los recursos de cómputo se han asignado a cero tras periodos prolongados de inactividad.

### 3. [Azure Virtual Machines (IaaS)](https://learn.microsoft.com/es-es/azure/virtual-machines/overview)
Consiste en el aprovisionamiento de servidores virtuales donde se tiene control total del sistema operativo. Es la alternativa con mayor carga operativa, ya que el único encargado de infraestructura debería gestionar manualmente la seguridad, actualizaciones del SO y el escalado. Además, genera un costo constante por hora que no se ajusta a cero ante la falta de pedidos, poniendo en riesgo el presupuesto de $50 USD/mes.

* **Ventajas:** 
  * Ofrece un [control total sobre el sistema operativo](https://learn.microsoft.com/es-es/azure/virtual-machines/overview), permitiendo instalar cualquier dependencia personalizada que el equipo requiera.
* **Desventajas:** 
  * Representa la alternativa con la [máxima carga operativa de administración de servidores](https://learn.microsoft.com/es-es/azure/virtual-machines/automatic-vm-guest-patching), obligando al único encargado de infraestructura a realizar tareas manuales de parches de seguridad y configuraciones de red.
  * Implica una [facturación constante basada en el costo por hora](https://azure.microsoft.com/es-es/pricing/details/virtual-machines/linux/), lo que imposibilita un escalado dinámico a cero cuando no se registran pedidos en la plataforma, superando con facilidad el presupuesto definido.

## Decisión
Se elige [Azure Functions bajo el Plan de Consumo](https://learn.microsoft.com/es-es/azure/azure-functions/consumption-plan). La justificación técnica se basa en la capacidad de [escalado automático a cero](https://learn.microsoft.com/es-es/azure/azure-functions/event-driven-scaling) (ahorro de costos cuando no hay pedidos) y la [integración nativa con los lenguajes del equipo (Node.js/Python)](https://learn.microsoft.com/es-es/azure/azure-functions/supported-languages). Desde el negocio, permite cumplir con la restricción presupuestaria de la fase piloto y reduce la carga sobre el único encargado de infraestructura al ser un servicio totalmente administrado.

## Consecuencias

### Ventajas
* **Costo operativo:** Cercano a $0 durante el inicio del piloto gracias a la [capa gratuita y el modelo de facturación por consumo](https://learn.microsoft.com/es-es/azure/azure-functions/functions-consumption-costs?tabs=consumption-plan%2Cportal).
* **Escalabilidad:** [Escalabilidad infinita y automática](https://learn.microsoft.com/es-es/azure/azure-functions/functions-concepts?pivots=programming-language-python) ante picos de demanda de usuarios sin intervención manual.
* **Compatibilidad:** Compatibilidad total con la API actual de React Native y los flujos de trabajo de desarrollo del equipo.

### Trade-offs
* **Riesgo de "Cold Start":** Latencia en la primera petición tras inactividad, el cual se mitigará mediante optimización de código en Python/Node.js para mantener los tiempos de respuesta dentro de los contratos actuales.
