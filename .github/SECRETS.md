# Secretos requeridos en GitHub Actions

La arquitectura usa **Azure Key Vault** para almacenar los connection strings de Cosmos DB, Blob Storage, Notification Hubs y la clave FCM. Las Azure Functions acceden a estos secretos mediante referencia directa (`@Microsoft.KeyVault`) usando su managed identity, sin necesidad de tener los valores en app settings.

## Secretos en GitHub

Agregar en: Settings → Secrets and variables → Actions

| Secreto | Descripción | Origen | Requerido en |
|---|---|---|---|
| `AZURE_CREDENTIALS` | JSON del Service Principal para autenticación en Azure | `az ad sp create-for-rbac` | deploy-infra.yml, deploy-functions.yml |
| `FCM_API_KEY` | Server Key de Firebase Cloud Messaging para notificaciones push Android | Consola Firebase → Configuración del proyecto → Cloud Messaging | deploy-infra.yml (se almacena en Key Vault durante el deployment) |

> **Nota:** Los secretos `NOTIFICATION_HUB_CONNECTION_STRING` y `BLOB_STORAGE_CONNECTION_STRING` ya no son necesarios. El ARM Template genera automáticamente ambos connection strings y los almacena en Key Vault.

## Cómo crear el Service Principal

```bash
# Iniciar sesión en Azure
az login

# Crear Service Principal con rol Contributor (alcance suscripción)
az ad sp create-for-rbac \
  --name "rapidgo-github-actions" \
  --role Contributor \
  --scopes /subscriptions/SUBSCRIPTION_ID \
  --sdk-auth

# Copiar el JSON completo que devuelve este comando como valor de AZURE_CREDENTIALS
```

## Cómo obtener FCM_API_KEY

1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Seleccionar el proyecto de RapidGo
3. Ir a Configuración del proyecto → Cloud Messaging
4. Copiar la **Clave del servidor** (Server Key)
5. Agregarla como `FCM_API_KEY` en GitHub Secrets

## Secretos almacenados en Azure Key Vault

Durante el deployment con ARM, el template `main.json` crea automáticamente un Key Vault llamado `az-rapidgo-{env}-kv-{hash}` y almacena los siguientes secretos:

| Secreto en Key Vault | Descripción | Origen |
|---|---|---|
| `cosmos-db-connection-string` | Connection string de Cosmos DB con clave primaria | Generado por ARM desde `Microsoft.DocumentDB/databaseAccounts` |
| `blob-storage-connection-string` | Connection string de Blob Storage con clave de acceso | Generado por ARM desde `Microsoft.Storage/storageAccounts` |
| `notification-hub-connection-string` | Connection string del Notification Hub (Listen/Send) | Generado por ARM desde `Microsoft.NotificationHubs/namespaces/notificationHubs` |
| `fcm-api-key` | Server Key de Firebase Cloud Messaging | Proviene del GitHub Secret `FCM_API_KEY` |

### Política de acceso

El Key Vault está configurado con:
- **`enabledForTemplateDeployment: true`** — permite al ARM Template crear y leer secretos durante el deployment.
- **Access policy para la Function App** — la managed identity (system-assigned) de la Function App tiene permisos `Get` y `List` sobre los secretos. Esta política se agrega automáticamente al final del deployment via ARM.

### Verificar los secretos en Key Vault

```bash
# Listar secretos en el vault
az keyvault secret list \
  --vault-name $(az keyvault list --resource-group az-rapidgo-dev-rg --query '[0].name' -o tsv) \
  --query '[].id' -o tsv

# Ver el valor de un secreto específico
az keyvault secret show \
  --vault-name $(az keyvault list --resource-group az-rapidgo-dev-rg --query '[0].name' -o tsv) \
  --name cosmos-db-connection-string \
  --query 'value' -o tsv
```

## Cómo agregar un nuevo ambiente

Para agregar un nuevo ambiente (ej. `nonprod`, `prod`):

1. Crear un nuevo Resource Group en Azure:
   ```bash
   az group create \
     --name az-rapidgo-{env}-rg \
     --location brazilsouth \
     --tags Environment={env} ManagedBy=github-actions
   ```

2. Ejecutar el workflow **Deploy Infrastructure - ARM Templates** via `workflow_dispatch` con `environmentName={env}`.

3. Opcional: agregar el mapeo branch → ambiente en ambos workflows (`deploy-infra.yml` y `deploy-functions.yml`):
   ```yaml
   - name: Set environment name
     id: env
     run: |
       if [ "${{ github.ref }}" == "refs/heads/main" ]; then
         echo "name=nonprod" >> $GITHUB_OUTPUT
       elif [ "${{ github.ref }}" == "refs/heads/release" ]; then
         echo "name=prod" >> $GITHUB_OUTPUT
       ...
   ```

4. Cada ambiente tiene su propio Key Vault, sus propios secretos y su propia Function App — todo aislado por Resource Group.
