# Scripts de Gestión Azure - RapidGo

Scripts de utilidad para gestionar la infraestructura de RapidGo en Azure.

## 📋 Scripts Disponibles

### 1. `test-region.sh` ⚡ NUEVO

Prueba si una región específica funciona creando recursos reales de prueba.

**Uso:**
```bash
./scripts/test-region.sh <region>
```

**Ejemplos:**
```bash
# Probar Central US (más común en Azure Student)
./scripts/test-region.sh centralus

# Probar West US
./scripts/test-region.sh westus

# Probar West Europe
./scripts/test-region.sh westeurope
```

**Cuándo usar:**
- Cuando recibes error `RequestDisallowedByAzure`
- Para verificar qué región funciona REALMENTE en tu suscripción
- Antes de hacer commit para evitar fallos

**Lo que hace:**
1. Crea un Resource Group de prueba
2. Intenta crear un Storage Account
3. Intenta crear un Cosmos DB
4. Si ambos funcionan → región válida ✅
5. Limpia todos los recursos de prueba

**⏱️ Duración:** ~2-3 minutos

---

### 2. `check-available-regions.sh`

Verifica las regiones de Azure disponibles en tu suscripción.

**Uso:**
```bash
./scripts/check-available-regions.sh
```

**Cuándo usar:**
- Cuando recibes error `RequestDisallowedByAzure`
- Para elegir la mejor región antes de desplegar
- Para verificar cuotas regionales

**Salida:**
- Lista de todas las regiones disponibles
- Regiones recomendadas para RapidGo
- Instrucciones para cambiar la región

---

### 2. `rollback-deployment.sh`

Elimina completamente un deployment de RapidGo (Resource Group + todos los recursos).

**Uso:**
```bash
./scripts/rollback-deployment.sh [environment]
```

**Parámetros:**
- `environment` - Opcional. Por defecto: `dev`. Valores: `dev`, `nonprod`, `prod`

**Ejemplos:**
```bash
# Eliminar deployment de dev
./scripts/rollback-deployment.sh dev

# Eliminar deployment de prod
./scripts/rollback-deployment.sh prod
```

**Cuándo usar:**
- Cuando el deployment falla y quieres limpiar
- Para eliminar un ambiente completo
- Para liberar recursos antes de re-desplegar

**⚠️  Precaución:**
- Este script **ELIMINA TODO** el Resource Group
- Requiere confirmación interactiva
- La eliminación no es reversible
- Los datos en Cosmos DB y Blob Storage se perderán

**Lo que hace:**
1. Verifica autenticación en Azure
2. Lista todos los recursos que serán eliminados
3. Pide confirmación explícita (`yes`)
4. Ejecuta la eliminación en background
5. Puede tardar varios minutos

---

### 3. `cleanup-orphaned-resources.sh` ⚠️

Busca y elimina recursos huérfanos de RapidGo que quedaron fuera del Resource Group.

**Uso:**
```bash
./scripts/cleanup-orphaned-resources.sh
```

**Cuándo usar:**
- Error: "Property at path location cannot be changed"
- Recursos con nombres globales ya existen (Storage, Key Vault)
- Después de un rollback fallido
- Para limpiar completamente la suscripción

**⚠️  EXTREMA PRECAUCIÓN:**
- Este script busca recursos en TODA la suscripción
- Puede eliminar recursos que NO están en Resource Groups de RapidGo
- Requiere confirmación explícita (`DELETE-ALL`)
- NO es reversible

**Lo que busca:**
- Storage Accounts con patrón `az*blob*` o `az*rapidgo*`
- Cosmos DB con patrón `azrapidgo*`
- Key Vaults con patrón `az-*-kv-*`
- API Management con patrón `az-rapidgo-*`

**Ejemplo de salida:**
```
📦 Storage Accounts:
   • azdevblob2isklemyx7sri (RG: az-rapidgo-dev-rg, Location: eastus)

🗄️  Cosmos DB:
   • azrapidgodevdb2isklemyx7sri (RG: az-rapidgo-dev-rg, Location: eastus)

¿Deseas eliminar TODOS los recursos huérfanos? (escribe 'DELETE-ALL' para confirmar):
```

---

### 4. `list-deployments.sh`

Lista todos los Resource Groups y deployments de RapidGo en tu suscripción.

**Uso:**
```bash
./scripts/list-deployments.sh
```

**Cuándo usar:**
- Para ver el estado de todos los environments
- Para verificar qué recursos están desplegados
- Para obtener nombres exactos de Resource Groups

**Salida:**
- Lista de todos los Resource Groups de RapidGo
- Número de recursos en cada RG
- Últimos 5 deployments por RG
- Estado de cada deployment

**Ejemplo de salida:**
```
📦 Resource Groups de RapidGo:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Name                   Location    Environment
az-rapidgo-dev-rg      eastus      dev
az-rapidgo-prod-rg     eastus      prod
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Deployments en: az-rapidgo-dev-rg
   Recursos: 12

Name                        State       Timestamp
arm-rapidgo-dev             Succeeded   2024-05-07T10:30:00
```

---

## 🔄 Flujo de Trabajo Completo

### Primer Despliegue

```bash
# 1. Verificar regiones disponibles
./scripts/check-available-regions.sh

# 2. Push para desplegar (GitHub Actions)
git add .
git commit -m "deploy: despliegue inicial de infraestructura"
git push

# 3. Monitorear el despliegue
./scripts/list-deployments.sh
```

### Si el Despliegue Falla

```bash
# 1. Verificar estado
./scripts/list-deployments.sh

# 2. Ejecutar rollback (el workflow lo hace automáticamente, pero puedes hacerlo manual)
./scripts/rollback-deployment.sh dev

# 3. Verificar limpieza
./scripts/list-deployments.sh

# 4. Corregir el problema (región, cuotas, etc.)

# 5. Re-desplegar
git push
```

### Cambiar de Región

```bash
# 1. Ver regiones disponibles
./scripts/check-available-regions.sh

# 2. Eliminar deployment actual (si existe)
./scripts/rollback-deployment.sh dev

# 3. Editar parámetros
nano src/infra-arm/azuredeploy.parameters.json
# Cambiar "location": { "value": "nueva-region" }

# 4. Commit y push
git add src/infra-arm/azuredeploy.parameters.json
git commit -m "fix: cambiar región a nueva-region"
git push
```

### Limpiar Todo

```bash
# Eliminar todos los environments
./scripts/rollback-deployment.sh dev
./scripts/rollback-deployment.sh nonprod
./scripts/rollback-deployment.sh prod

# Verificar limpieza
./scripts/list-deployments.sh
```

---

## 🔧 Requisitos

Todos los scripts requieren:

- **Azure CLI** instalado (`az --version`)
- **Autenticación activa** (`az login`)
- **Permisos** de Contributor en la suscripción
- **Bash** shell (macOS/Linux o Git Bash en Windows)

### Instalación de Azure CLI

```bash
# macOS
brew update && brew install azure-cli

# Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Windows (PowerShell como Admin)
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
```

### Autenticación

```bash
# Login interactivo
az login

# Login con Service Principal (para CI/CD)
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID

# Verificar autenticación
az account show
```

---

## 📝 Notas Importantes

### Rollback Automático en GitHub Actions

El workflow ya incluye rollback automático:

- **Validación falla** → Elimina RG vacío
- **Deployment falla** → Lista recursos y elimina RG completo
- **No requiere intervención manual**

### Costos

Ejecutar `rollback-deployment.sh` detiene inmediatamente los costos de:
- ✅ API Management (mayor costo)
- ✅ Cosmos DB
- ✅ Storage Accounts
- ✅ Notification Hubs
- ✅ Application Insights

### Logs de Deployment

Para ver logs detallados de un deployment fallido:

```bash
# Ver último deployment
az deployment group list \
  --resource-group az-rapidgo-dev-rg \
  --query "[0]" -o json

# Ver errores específicos
az deployment operation group list \
  --resource-group az-rapidgo-dev-rg \
  --name arm-rapidgo-dev \
  --query "[?properties.provisioningState=='Failed']" -o table
```

---

## 🆘 Troubleshooting

### Script no ejecutable

```bash
chmod +x scripts/*.sh
```

### Az CLI no encontrado

```bash
# Verificar instalación
which az

# Reinstalar si es necesario
brew reinstall azure-cli  # macOS
```

### Autenticación expirada

```bash
az logout
az login
```

### Eliminación lenta

La eliminación de Resource Groups puede tardar 5-15 minutos. Es normal.

Para forzar eliminación:
```bash
az group delete --name az-rapidgo-dev-rg --yes --force-deletion-types Microsoft.Compute/virtualMachines
```

---

## 🔗 Referencias

- [Azure CLI Documentation](https://learn.microsoft.com/cli/azure/)
- [Azure Resource Manager](https://learn.microsoft.com/azure/azure-resource-manager/)
- [GitHub Actions for Azure](https://github.com/Azure/actions)
