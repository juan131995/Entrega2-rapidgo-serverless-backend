# Infraestructura ARM - RapidGo

Plantillas ARM para desplegar la infraestructura serverless de RapidGo en Azure.

## Estructura

```
src/infra-arm/
├── main.json                      # Plantilla principal consolidada
├── azuredeploy.parameters.json    # Parámetros de despliegue
└── README.md                      # Esta documentación
```

## Recursos Desplegados

| Recurso | Descripción | SKU/Tier |
|---------|-------------|----------|
| **Storage Account** (Blob) | Almacenamiento de archivos de entregas | Standard_LRS |
| **Cosmos DB** | Base de datos NoSQL con contenedor `pedidos` | Free Tier (opcional) |
| **Notification Hubs** | Notificaciones push (FCM v1) | Free |
| **Key Vault** | Gestión de secretos y conexiones | Standard |
| **Function App** | Azure Functions (Node.js/Python) | Consumption (Y1) |
| **App Service Plan** | Plan para Function App | Dynamic (Y1) |
| **Application Insights** | Monitoreo y telemetría | - |
| **API Management** | Gateway API con JWT validation | Developer |

## Configuración de Región

### Error: "RequestDisallowedByAzure"

Si recibes este error, significa que la región configurada no está permitida en tu suscripción.

**Solución:**

1. Ejecuta el script para ver regiones disponibles:
   ```bash
   ./scripts/check-available-regions.sh
   ```

2. Edita `azuredeploy.parameters.json` y cambia `location`:
   ```json
   {
     "location": {
       "value": "eastus"  // ← Cambia aquí
     }
   }
   ```

3. Haz commit y push para re-desplegar.

### Regiones Recomendadas

- **eastus** - East US (Virginia) - Por defecto
- **eastus2** - East US 2 (Virginia)
- **westus2** - West US 2 (Washington)
- **westeurope** - West Europe (Países Bajos)
- **southcentralus** - South Central US (Texas)

## Despliegue Manual

```bash
# 1. Crear grupo de recursos
az group create \
  --name az-rapidgo-dev-rg \
  --location eastus

# 2. Validar plantilla
az deployment group validate \
  --resource-group az-rapidgo-dev-rg \
  --template-file src/infra-arm/main.json \
  --parameters src/infra-arm/azuredeploy.parameters.json

# 3. Desplegar
az deployment group create \
  --resource-group az-rapidgo-dev-rg \
  --name rapidgo-infra-deployment \
  --template-file src/infra-arm/main.json \
  --parameters src/infra-arm/azuredeploy.parameters.json \
  --mode Incremental
```

## Despliegue Automático (GitHub Actions)

El despliegue se ejecuta automáticamente mediante GitHub Actions:

**Trigger automático:**
- Push a `main` o `develop` con cambios en `src/infra-arm/**`

**Trigger manual:**
- Ve a Actions → "Deploy Infrastructure - ARM Templates" → Run workflow
- Configura parámetros (environment, location, confirm)

### Secretos Requeridos

| Secret | Descripción |
|--------|-------------|
| `AZURE_CREDENTIALS` | Service Principal con permisos de Contributor |
| `FIREBASE_SERVICE_ACCOUNT` | Service Account JSON de Firebase (para FCM v1) |

## Parámetros Configurables

### En `azuredeploy.parameters.json`:

```json
{
  "environmentName": {
    "value": "dev"  // dev, nonprod, prod
  },
  "location": {
    "value": "eastus"  // Región de Azure
  },
  "functionAppRuntime": {
    "value": "node"  // node o python
  },
  "cosmosDBFreeTier": {
    "value": true  // Solo 1 por suscripción
  },
  "skuAPIM": {
    "value": "Developer"  // Developer, Basic, Standard
  }
}
```

## Outputs

Después del despliegue exitoso, obtienes:

```json
{
  "functionAppDefaultHostName": "az-rapidgo-dev-functions.azurewebsites.net",
  "apimGatewayUrl": "https://az-rapidgo-dev-apim.azure-api.net",
  "cosmosDbEndpoint": "https://azrapidgodevdb...documents.azure.com:443/",
  "blobStorageEndpoint": "https://azdevblob...blob.core.windows.net/",
  "notificationHubEndpoint": "sb://az-rapidgo-dev-notif-ns.servicebus.windows.net/",
  "resourceGroupName": "az-rapidgo-dev-rg"
}
```

## Troubleshooting

### Error: "Cosmos DB free tier already exists"

**Solución:** Cambia `cosmosDBFreeTier` a `false` en los parámetros.

### Error: "Key Vault name already exists"

**Solución:** Los nombres de Key Vault son globales. Cambia `environmentName` a algo único.

### Error: "API Management provisioning takes 30+ minutes"

**Esperado:** API Management en tier Developer puede tardar hasta 45 minutos.

## Limpieza

Para eliminar todos los recursos:

```bash
az group delete --name az-rapidgo-dev-rg --yes --no-wait
```

## Referencias

- [ARM Templates Documentation](https://learn.microsoft.com/azure/azure-resource-manager/templates/)
- [Azure Functions](https://learn.microsoft.com/azure/azure-functions/)
- [Cosmos DB](https://learn.microsoft.com/azure/cosmos-db/)
- [API Management](https://learn.microsoft.com/azure/api-management/)
