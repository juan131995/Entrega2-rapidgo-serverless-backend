# ADR-03: Uso de API Management sobre exposición directa de las Functions para la lógica de negocio de RapidGo

## Contexto

RapidGo es una startup colombiana de domicilios que opera en Medellín, Manizales y Pereira, conectando clientes con comercios locales mediante una **aplicación móvil** en React Native. Actualmente, la empresa enfrenta retos críticos debido a una arquitectura monolítica en Node.js que genera **saturación en horas pico**, **latencias superiores** a 8 segundos y **costos fijos** ineficientes. Entre los problemas identificados, destacan la **deuda técnica en autenticación** y la falta de un punto de **entrada centralizado** que facilite la integración de futuros clientes.

A nivel de requerimientos y restricciones para el piloto, el sistema debe cumplir con:

- Disponibilidad (99.9%): Un máximo de 44 minutos de inactividad mensual.  
- Latencia: Inferior a 800 ms en el percentil P95.
- Escalabilidad: Soportar hasta 500 req/s sin intervención manual.
- Modelo de costos: Restricción presupuestaria de un máximo de $50 USD mensuales.
- Despliegue: Esquema de Zero-Downtime para no afectar a los usuarios y repartidores activos. 
- Seguridad: Resolver la deuda técnica en autenticación centralizando la validación de tokens.  

---

## Alternativas evaluadas


### Alternativa 1: Exposición Directa de Azure Functions

#### Ventajas

- Simplicidad arquitectónica
- Costo mínimo
- **Menor latencia**
- Despliegue rápido

#### Desventajas

- **Gestión de seguridad dispersa**
- **Acoplamiento**

---

### Alternativa 2: Implementación de Azure API Management

#### Ventajas

- Abstracción de Backend (**desacoplamiento**)
- **Seguridad y Políticas**
- Optimización

#### Desventajas

- Configuración adicional
- Mayor complejidad inicial
- **Ligero aumento en latencia**

---

### Alternativa 3: Amazon API Gateway + AWS Lambda

#### Ventajas

- Gateway centralizado para APIs
- **Validación de JWT y políticas de seguridad**
- Desacoplamiento entre clientes y backend

#### Desventajas

- Mayor complejidad multi-cloud
- Requiere experiencia en ecosistema AWS
- **Incremento de costos operativos**


- **Disponibilidad (99.9%):** RapidGo requiere un máximo de 44 minutos de inactividad mensual, por lo que Azure Functions ofrece escalado automático y alta disponibilidad administrada por Azure, lo que ayuda a cumplir este objetivo. Además, al ser serverless: “Puede usar la infraestructura en la nube para proporcionar todos los recursos actualizados necesarios para mantener sus aplicaciones en funcionamiento.”, sin embargo; exponer Functions directamente implica que cada Function debe manejar autenticación individualmente ya que no existe un punto central de control y no hay mecanismos nativos avanzados de protección frente a abuso. Esto incrementa el riesgo operacional y dificulta garantizar estabilidad bajo alta carga. En el caso de AWS API Gateway ofrece una disponibilidad similar, sin embargo, al estar el resto de la infraestructura de RapidGo en Azure, introducir una nube distinta aumentaría la complejidad de red y los puntos de falla potenciales.

- **Latencia (< 800ms P95):** Azure Functions maneja menor cantidad de saltos de red y comunicación directa con el cliente, sin embargo; las Functions deben validar JWT internamente, la lógica de seguridad se repite y esto puede aumentar el tiempo de procesamiento por request, además en picos de tráfico podrían ocurrir sobrecarga por solicitudes maliciosas o excesivas. Tanto AWS API Gateway como Azure API Management ofrecen validación centralizada y gestionan las sobrecargas.

- **Escalabilidad (500 req/s sin intervención manual):** Azure Functions fue diseñada precisamente para este escenario. Microsoft indica que Functions ofrece un “escalado rápido controlado por eventos”, esto favorece el cumplimiento del requerimiento. Sin embargo, el problema no es únicamente escalar, sino controlar el escalamiento. Sin API Management o AWS API Gateway, no existen cuotas, no existe throttling y no hay límites por usuario. Esto significa que cualquier cliente podría generar tráfico excesivo y provocar sobrecostos, saturación del backend y degradación del servicio. No obstante, la gestión de límites en AWS es más granular y compleja de configurar para un equipo que ya domina el ecosistema de Microsoft.

- **Modelo de costos (pago por uso):** La exposición directa de Azure Functions representa la alternativa más económica, ya que el Consumption Plan cobra únicamente por ejecución y aprovecha la capa gratuita incluida en Azure, alineándose directamente con el requerimiento de eliminar el costo fijo del servidor dedicado. Esta característica es especialmente importante para RapidGo debido a la restricción presupuestaria de máximo $50 USD mensuales durante la fase piloto. Sin embargo, aunque API Management introduce un costo adicional, el caso propone explícitamente el uso del Developer Tier para pruebas y desarrollo, lo que mantiene el gasto dentro del presupuesto permitido. Por tanto, la exposición directa optimiza mejor los costos iniciales, mientras que API Management sacrifica parte de esa economía a cambio de capacidades avanzadas de seguridad, monitoreo y gobernanza. En el caso de AWS API Gateway cobra $3.50 USD por millón de peticiones (más transferencia de datos). Si bien es pago por uso, el costo es menos predecible que el Developer Tier de Azure APIM, el cual permite un control de gasto más rígido dentro de los $50 USD mensuales.

- **Despliegue Zero-Downtime:** Azure Functions facilita despliegues rápidos y desacoplados gracias a su modelo serverless administrado, evitando interrupciones prolongadas asociadas a servidores tradicionales. No obstante, cuando las Functions se exponen directamente, cualquier cambio interno puede impactar inmediatamente a los clientes móviles, incrementando el riesgo de incompatibilidades. API Management mejora este aspecto al actuar como fachada del backend, permitiendo “evolucionar la arquitectura de back-end sin afectar a los consumidores de API”. Esto posibilita mantener contratos estables mientras se actualizan internamente las Functions, reduciendo significativamente el riesgo de afectar pedidos en curso durante despliegues y contribuyendo mejor al objetivo de zero-downtime. AWS soporta despliegues tipo Canary de forma nativa muy robusta. Sin embargo, Azure APIM ofrece una integración más directa con los 'Deployment Slots' de las Functions de Azure, facilitando la transición sin afectar a los repartidores activos.

- **Seguridad y autenticación:** La exposición directa de Azure Functions presenta una debilidad importante respecto al contexto de RapidGo, ya que el sistema actual posee “deuda técnica en autenticación” y, sin un gateway centralizado, cada Function tendría que validar JWT individualmente. Esto implica duplicación de lógica, mayor complejidad de mantenimiento y riesgo de inconsistencias de seguridad. En contraste, API Management y AWS Gateway fueron diseñados específicamente para la administración de APIs y, según Microsoft, la puerta de enlace “comprueba las claves de API y otras credenciales, como los JWT”. Además, al funcionar como fachadas centralizadas, permiten desacoplar la seguridad de la lógica de negocio y aplicar políticas uniformes de autenticación, autorización y limitación de tráfico. Por ello, tanto API Management como AWS API Gateway responden mucho mejor a las necesidades de seguridad y mantenibilidad de RapidGo. Teniendo en cuenta que Azure APIM es preferible porque permite centralizar la validación de los JWT actuales sin necesidad de migrar la base de usuarios a otra nube.

---

## Decisión

Se decidió implementar Azure API Management como gateway de entrada único para la arquitectura serverless de RapidGo, evitando la exposición directa de las Azure Functions. Aunque la exposición directa ofrecía ventajas en simplicidad y reducción de costos, API Management responde de manera más adecuada a los requerimientos no funcionales y a los problemas actuales identificados en el sistema. Desde el punto de vista técnico, API Management y Amazon API Gateway permiten centralizar la autenticación mediante validación de JWT, aplicar cuotas y límites de frecuencia, controlar el tráfico hacia las Functions y desacoplar la aplicación móvil del backend. Microsoft y AWS establecen que la puerta de enlace de API Management “actúa como fachada de los servicios back-end”, permitiendo evolucionar internamente la arquitectura sin afectar a los consumidores de la API. Esto resulta especialmente importante porque RapidGo debe mantener compatibilidad con la app móvil existente y reducir la deuda técnica en autenticación presente en el monolito actual. Además, API Management mejora la observabilidad y el monitoreo al emitir métricas y registros centralizados, contribuyendo al cumplimiento de los objetivos de disponibilidad y estabilidad operacional.

Comparativamente, AWS propone un enfoque equivalente mediante Amazon API Gateway y AWS Lambda. Esta arquitectura también utiliza un gateway centralizado para administrar autenticación, limitación de tráfico, monitoreo y exposición controlada de funciones serverless, evidenciando que el uso de una capa de API Management es una práctica estándar en arquitecturas cloud modernas. Sin embargo, debido a que RapidGo ya se encuentra alineado con servicios del ecosistema Azure, incorporar API Gateway implicaría aumentar la complejidad operativa, introducir una arquitectura multi-cloud innecesaria y requerir conocimientos adicionales sobre AWS. En consecuencia, aunque Amazon API Gateway ofrece capacidades similares, Azure API Management representa una alternativa más coherente con la estrategia tecnológica, las restricciones del equipo y los objetivos de mantenibilidad definidos para RapidGo.

Desde la perspectiva de negocio, esta decisión permite construir una arquitectura más preparada para el crecimiento futuro de RapidGo, soportando escenarios como APIs públicas, integraciones B2B y nuevos clientes web o móviles sin rediseñar completamente la plataforma. Aunque API Management introduce un costo adicional frente a la exposición directa de Functions, el uso del Developer Tier mantiene la solución dentro de la restricción presupuestaria del proyecto piloto y reduce riesgos operativos asociados a fallos de seguridad, saturación del backend o cambios incompatibles en la API. En consecuencia, se concluye que la incorporación de Azure API Management como gateway centralizado permite mejorar la seguridad, gobernanza y escalabilidad de las Azure Functions, alineándose mejor con los requerimientos técnicos y de negocio de RapidGo.

---

## Consecuencias

La decisión de incorporar Azure API Management como gateway centralizado permite responder de mejor manera a los requerimientos no funcionales definidos para RapidGo. En términos de disponibilidad y estabilidad, el uso de API Management mejora el control del tráfico mediante cuotas y límites de frecuencia, reduciendo el riesgo de saturación de las Azure Functions durante picos de hasta 500 solicitudes por segundo. Además, al centralizar la autenticación JWT, se disminuye la deuda técnica existente y se mejora la seguridad general de la plataforma, evitando implementar validaciones repetidas en cada Function. También se obtiene un mayor desacoplamiento entre la aplicación móvil y el backend, lo que facilita mantener compatibilidad con los contratos actuales de la API y realizar despliegues zero-downtime sin afectar pedidos en curso. Desde el punto de vista operacional, la integración de monitoreo y registros centralizados mejora la observabilidad del sistema y simplifica la administración para el único integrante encargado de infraestructura.

Respecto a las restricciones del proyecto, la solución continúa siendo compatible con el conocimiento actual del equipo, ya que las Azure Functions pueden seguir desarrollándose en Node.js o Python, mientras que API Management funciona como un servicio administrado independiente del lenguaje utilizado. Además, aunque API Management introduce un costo adicional frente a la exposición directa de Functions, el uso del Developer Tier permite mantener el gasto dentro del límite presupuestario de $50 USD mensuales durante la fase piloto. Como trade-off principal, la arquitectura se vuelve más compleja al incorporar un nuevo componente que requiere configuración de políticas, rutas y seguridad. También se agrega una pequeña sobrecarga de latencia debido a la presencia de la puerta de enlace entre el cliente y las Functions. Sin embargo, estos costos y complejidades se consideran aceptables frente a los beneficios obtenidos en seguridad, escalabilidad, mantenibilidad y continuidad operativa del negocio.

Aunque AWS API Gateway ofrece capacidades funcionalmente equivalentes a Azure API Management, su adopción en este contexto incrementaría la complejidad sin aportar beneficios diferenciales significativos. Por lo tanto, refuerza la decisión de mantener Azure API Management como la opción más coherente y eficiente dentro de la arquitectura del sistema.
