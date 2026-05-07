# Secretos requeridos en GitHub Actions

La arquitectura usa **Azure Key Vault** para almacenar los connection strings de Cosmos DB, Blob Storage y Notification Hubs. Las Azure Functions acceden a estos secretos mediante referencia directa (`@Microsoft.KeyVault`) usando su managed identity.

## Secretos en GitHub

Agregar en: Settings → Secrets and variables → Actions

| Secreto | Descripción | Origen | Requerido en |
|---|---|---|---|
| `AZURE_CREDENTIALS` | JSON del Service Principal para autenticación en Azure | `az ad sp create-for-rbac` | deploy-infra.yml, deploy-functions.yml |
| `FIREBASE_SERVICE_ACCOUNT` | JSON completo de la service account de Firebase Admin SDK | Firebase Console → Project Settings → Service Accounts → Generate new private key | deploy-infra.yml (configura FCM v1 en Notification Hub) |

> **Nota:** Ya no se requiere `FCM_API_KEY` (legacy server key). Ahora se usa autenticación OAuth 2.0 con service account de Firebase.
>
> Tampoco se requieren `NOTIFICATION_HUB_CONNECTION_STRING` ni `BLOB_STORAGE_CONNECTION_STRING` — el ARM Template genera ambos y los almacena directamente en Key Vault.

## Cómo crear el Service Principal

```bash
# Iniciar sesión en Azure (usar el tenant correcto de la suscripcion)
az login --tenant 26abf082-b7c9-4c86-970d-314f452912da

# Crear Service Principal con rol Contributor
az ad sp create-for-rbac \
  --name "rapidgo-github-actions" \
  --role Contributor \
  --scopes /subscriptions/ecc83844-137a-4e51-8773-52dc8e36390e

# Copiar el JSON completo que devuelve este comando como valor de AZURE_CREDENTIALS
```

## Cómo obtener FIREBASE_SERVICE_ACCOUNT

1. Ir a [Firebase Console](https://console.firebase.google.com/)
2. Seleccionar el proyecto **rapid-go-app-1**
3. Ir a **Project Settings** → **Service Accounts**
4. Click en **"Generate new private key"**
5. Descargar el archivo JSON
6. Copiar el contenido completo del JSON como valor de `FIREBASE_SERVICE_ACCOUNT` en GitHub Secrets

El JSON tiene esta estructura:
```json
{
  "type": "service_account",
  "project_id": "rapid-go-app-1",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@rapid-go-app-1.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

## Qué hace cada secreto durante el deployment

### `AZURE_CREDENTIALS`
Se usa en ambos workflows para autenticarse en Azure via `azure/login@v2`.

### `FIREBASE_SERVICE_ACCOUNT`
Se usa en `deploy-infra.yml` después del deployment ARM para configurar las credenciales **FCM v1** en Azure Notification Hubs mediante la API de Azure Resource Manager:

```bash
az rest --method put \
  --url "https://management.azure.com/.../pnsCredentials?api-version=2023-01-01-preview" \
  --body "{
    \"properties\": {
      \"fcmV1Credential\": {
        \"properties\": {
          \"clientEmail\": \"...\",
          \"privateKey\": \"...\",
          \"projectId\": \"rapid-go-app-1\"
        }
      }
    }
  }"
```

Esto permite que Notification Hubs envíe notificaciones push a dispositivos Android sin necesidad de la legacy Server Key.

## Secretos almacenados en Azure Key Vault

Durante el deployment con ARM, el template `main.json` crea automáticamente un Key Vault llamado `az-rapidgo-{env}-kv-{hash}` y almacena los siguientes secretos:

| Secreto en Key Vault | Descripción | Origen |
|---|---|---|
| `cosmos-db-connection-string` | Connection string de Cosmos DB con clave primaria | Generado por ARM |
| `blob-storage-connection-string` | Connection string de Blob Storage | Generado por ARM |
| `notification-hub-connection-string` | Connection string del Notification Hub | Generado por ARM |

### Política de acceso

El Key Vault está configurado con:
- **`enabledForTemplateDeployment: true`** — permite al ARM Template crear secretos durante el deployment.
- **Access policy para la Function App** — la managed identity (system-assigned) de la Function App tiene permisos `Get` y `List` sobre los secretos.

### Verificar los secretos en Key Vault

```bash
# Listar secretos en el vault
az keyvault secret list \
  --vault-name $(az keyvault list --resource-group az-rapidgo-dev-rg --query '[0].name' -o tsv) \
  --query '[].id' -o tsv

# Ver el valor de un secreto especifico
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
