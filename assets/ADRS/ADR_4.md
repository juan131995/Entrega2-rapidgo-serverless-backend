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
- Dispone de una disponibilidad del 99.9% y una replicación eficaz en distintas regiones con mejor disponibilidad. 
- Optimiza el rendimiento y minimiza la latencia al momento de usar la app móvil.
- Se puede elegir diferentes capas de almacenamiento para optimizar costos y rendimientos según las necesidades, [**desde $0,15 por cada gb que se utilice**](https://azure.microsoft.com/es-es/pricing/details/storage/blobs/?msockid=3670edb92d7a635123a4f9272c7b6214)
  
#### Desventajas

- No soporta la estructura de carpetas tradicional sino el manejo de contenedores de almacenamiento de objetos.

---

### 2. Azure Files

#### Ventajas

- Maneja el orden jerárquico de carpetas, subcarpetas y archivos para el almacenamiento.
- Combina un servidor de almacenamiento local con el almacenamiento en la nube en azure, permitiendo que ambos trabajen como uno.

#### Desventajas

- Al usar el protocolo SMB no optimiza su uso para ser un backend de una app móvil de alto rendimiento.
- Su arquitectura está diseñada para un sistema de archivos tradicional (carpetas), no como un servicio para tráfico HTTP masivo.
- Al utilizar un sistema de archivos tradicional se requiere más recursos a comparación del uso de un solo contenedor.
- Azure Files está diseñado como un servicio de archivos compartidos empresariales. Un CDN es para distribuir contenido web multimedia utilizando HTTP/HTTPS.

### 3. Amazon EFS

#### Ventajas
- Permite un sistema de archivos completamente administrado y escalable en la nube, donde AWS gestiona la infraestructura de almacenamiento, hardware, actualizaciones y mantenimiento del sistema de archivos.

- Utiliza el protocolo NFS (Network File System), permitiendo que múltiples instancias o servidores accedan simultáneamente al mismo sistema de archivos compartido dentro de la infraestructura de Amazon Web Services.
- 
- El almacenamiento escala automáticamente a medida que se agregan o eliminan archivos, proporcionando capacidad de almacenamiento dinámica sin necesidad de aprovisionar manualmente recursos.
  
-  Ofrece alta disponibilidad y durabilidad, ya que los sistemas de archivos regionales almacenan datos redundantes en múltiples Availability Zones dentro de una región, permitiendo continuidad del servicio incluso si una zona falla.

#### Desventajas
-  Está diseñado principalmente para aplicaciones que requieren acceso desde servidores o instancias de cómputo, como Amazon EC2, contenedores o servicios serverless, donde el sistema de archivos se monta mediante el protocolo NFS dentro de una red privada (VPC).
  
-  No está optimizado para la distribución directa de contenido multimedia mediante HTTP/HTTPS, ya que Amazon Elastic File System funciona como un sistema de archivos de red que se monta en servidores utilizando el protocolo NFS v4, en lugar de servir archivos directamente a clientes web o aplicaciones móviles.
  
-  Puede generar mayor latencia cuando se utiliza como backend para servir archivos directamente a usuarios finales, debido a que el acceso a los datos está diseñado para realizarse desde instancias de cómputo dentro de la infraestructura de AWS, las cuales luego procesan o distribuyen los archivos hacia los clientes.
  
-  Su integración es más natural dentro del ecosistema de Amazon Web Services, ya que está pensado para trabajar directamente con servicios como Amazon EC2, Amazon Elastic Kubernetes Service, AWS Lambda o Amazon Elastic Container Service, lo que hace que su adopción sea más natural en arquitecturas basadas en AWS que en entornos centrados en Azure.

---

## Decisión

Se elige [**Azure Blob Storage**](https://azure.microsoft.com/es-es/products/storage/blobs/?msockid=3670edb92d7a635123a4f9272c7b6214) como almacenamiento principal para la aplicación movil de RapidGo.

---

## Justificación

Azure Blob Storage soluciona los dos problemas más críticos de RapidGo:

1. Disponibilidad y escalamiento que supera el 99.9%.
2. Latencia mínima gracias a la integración de CDNs.

Al usar Blob Storage, todo el contenido multimedia, tanto imagenes como archivos se cargaran al instante sin provocar algun retraso para el uso de los clientes en su día a día, además de ofrecer zonas de redundancia o replicación en caso de que una zona falle.

Con la integración de CDNs, el usuario que necesite utilizar la app tendrá la latencia mínima al momento de visualizar el contenido multimedia gracias a que se descargará todo desde el servidor más cercano.
