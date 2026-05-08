# Convención de Nombres - RapidGo Azure Resources

## 📋 Patrón General

Todos los recursos siguen el patrón: `azrapidgo-{environment}-{resource-type}-{uniqueSuffix}`

Donde:
- `azrapidgo` = Prefijo de la aplicación
- `{environment}` = dev, prod, nonprod
- `{resource-type}` = Tipo de recurso (func, blob, db, etc.)
- `{uniqueSuffix}` = Hash de 6 caracteres para garantizar unicidad global

---

## ⚠️ Restricciones de Azure

### Recursos SIN guiones (solo letras minúsculas y números)

Azure tiene restricciones estrictas para ciertos recursos que **NO permiten guiones**:

| Recurso | Patrón | Ejemplo (prod) | Límite |
|---------|--------|----------------|--------|
| **Storage Account (Functions)** | `azrapidgo{env}func{hash}` | `azrapidgoprodfuncabc123` | 24 caracteres |
| **Storage Account (Blob)** | `azrapidgo{env}blob{hash}` | `azrapidgoprodblobabc123` | 24 caracteres |
| **Cosmos DB Account** | `azrapidgo{env}db{hash}` | `azrapidgoprodobabc123` | 44 caracteres |

**Razón:** Azure Storage y Cosmos DB requieren nombres DNS válidos sin guiones para el endpoint.

---

## ✅ Recursos CON guiones (más legibles)

| Recurso | Patrón | Ejemplo (prod) |
|---------|--------|----------------|
| **Function App** | `az-rapidgo-{env}-functions` | `az-rapidgo-prod-functions` |
| **App Service Plan** | `az-rapidgo-{env}-plan` | `az-rapidgo-prod-plan` |
| **API Management** | `az-rapidgo-{env}-apim` | `az-rapidgo-prod-apim` |
| **Key Vault** | `az-rapidgo-{env}-kv-{hash}` | `az-rapidgo-prod-kv-abc123` |
| **Notification Hub Namespace** | `az-rapidgo-{env}-notif-ns` | `az-rapidgo-prod-notif-ns` |
| **Notification Hub** | `az-rapidgo-{env}-notifications` | `az-rapidgo-prod-notifications` |
| **Application Insights** | `az-rapidgo-{env}-functions-insights` | `az-rapidgo-prod-functions-insights` |
| **Resource Group** | `az-rapidgo-{env}-rg` | `az-rapidgo-prod-rg` |

---

## 🔢 Generación del Sufijo Único

El sufijo único se genera con:

```json
"uniqueSuffix": "[substring(uniqueString(resourceGroup().id), 0, 6)]"
```

Esto garantiza:
- ✅ **Unicidad global** (basado en el Resource Group ID)
- ✅ **Consistencia** (mismo sufijo para todos los recursos del mismo deployment)
- ✅ **Repetibilidad** (re-desplegar genera el mismo sufijo)

---

## 📦 Ejemplo Completo: Environment "prod"

### Resource Group
```
az-rapidgo-prod-rg
```

### Storage & Compute
```
azrapidgoprodfuncabc123          # Storage Account para Functions
azrapidgoprodblobabc123          # Storage Account para Blob Storage
az-rapidgo-prod-functions        # Function App
az-rapidgo-prod-plan             # App Service Plan
az-rapidgo-prod-functions-insights # Application Insights
```

### Database
```
azrapidgoprodabc123              # Cosmos DB Account
az-rapidgo-prod-db               # Cosmos DB Database
pedidos                          # Cosmos DB Container
```

### API & Notifications
```
az-rapidgo-prod-apim             # API Management
az-rapidgo-prod-notif-ns         # Notification Hub Namespace
az-rapidgo-prod-notifications    # Notification Hub
```

### Security
```
az-rapidgo-prod-kv-abc123        # Key Vault (máx 24 caracteres)
```

---

## 🔄 Cambiar de Environment

Para cambiar entre environments, edita `azuredeploy.parameters.json`:

```json
{
  "environmentName": {
    "value": "prod"  // dev, prod, nonprod
  }
}
```

Esto generará automáticamente nombres consistentes:
- `dev` → `az-rapidgo-dev-*`, `azrapidgodev*`
- `prod` → `az-rapidgo-prod-*`, `azrapidgoprod*`
- `nonprod` → `az-rapidgo-nonprod-*`, `azrapidgononprod*`

---

## 🎯 Ventajas de esta Convención

| Ventaja | Descripción |
|---------|-------------|
| **Consistencia** | Todos los recursos siguen el mismo patrón |
| **Trazabilidad** | Fácil identificar a qué app y environment pertenecen |
| **Unicidad global** | El sufijo único evita conflictos |
| **Cumplimiento** | Respeta todas las restricciones de Azure |
| **Automatización** | Dinámico basado en el environment |
| **Escalabilidad** | Soporta múltiples environments sin conflictos |

---

## 📚 Referencias de Azure

- [Naming rules for Azure resources](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules)
- [Storage Account naming](https://learn.microsoft.com/azure/storage/common/storage-account-overview#storage-account-name)
- [Cosmos DB naming](https://learn.microsoft.com/azure/cosmos-db/how-to-manage-database-account#create-an-account)
- [Key Vault naming](https://learn.microsoft.com/azure/key-vault/general/about-keys-secrets-certificates#objects-identifiers-and-versioning)
