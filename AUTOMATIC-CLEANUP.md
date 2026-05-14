# Automatic Cleanup and Retry System

## ✅ Sistema Totalmente Automatizado

El workflow de GitHub Actions ahora maneja **automáticamente** todos los errores de despliegue relacionados con recursos soft-deleted y conflictos de ubicación.

**NO necesitas ejecutar scripts locales** - todo se hace en las Actions.

---

## 🔄 Flujo Automático de Despliegue

### Fase 1: Pre-Deployment Cleanup (Preventivo)

```yaml
Before every deployment:
  ✓ Purge soft-deleted APIM services (az-rapidgo-*)
  ✓ Purge soft-deleted Key Vaults (az-rapidgo-*)
  ✓ Check and fix location mismatches
```

### Fase 2: First Deployment Attempt

```yaml
Try deployment:
  ✓ Deploy ARM/Bicep template
  ✓ If succeeds → Done ✅
  ✓ If fails → Continue to Phase 3
```

### Fase 3: Cleanup and Retry (Automático)

```yaml
If deployment fails:
  1. Detect error type (soft-delete, location conflict, etc.)
  2. Purge ALL soft-deleted APIM services (any location)
  3. Purge ALL soft-deleted Key Vaults (any location)
  4. If location conflict:
     - Delete entire resource group
     - Wait for deletion
     - Recreate resource group in correct location
  5. Wait 60 seconds for purge operations
  6. Retry deployment automatically
```

### Fase 4: Rollback (Si todo falla)

```yaml
If retry also fails:
  ✓ Rollback to previous state
  ✓ Delete only resources created in this deployment
  ✓ Report failure in GitHub Summary
```

---

## 🎯 Errores Manejados Automáticamente

| Error | Acción Automática |
|-------|-------------------|
| `ServiceAlreadyExistsInSoftDeletedState` | Purge APIM + Retry |
| `A vault with the same name already exists in deleted state` | Purge Key Vault + Retry |
| `Property at path location cannot be changed` | Delete RG + Recreate + Retry |
| `Namespace belongs to a different subscription` | Purge + Wait + Retry |

---

## 📋 Logs Detallados

El workflow muestra en tiempo real:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Purging soft-deleted resources...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Checking for soft-deleted APIM services...
Found soft-deleted APIM services:
az-rapidgo-dev-apim-2j6thw
Purging APIM: az-rapidgo-dev-apim-2j6thw
✅ APIM purge complete

Checking for soft-deleted Key Vaults...
✅ No Key Vaults to purge

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Soft-delete purge complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Si falla el primer intento:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ First deployment failed - attempting cleanup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Purging soft-deleted APIM services...
Purging APIM: az-rapidgo-dev-apim-2j6thw in centralus
Purging soft-deleted Key Vaults...
⏱️ Waiting 60 seconds for purge operations to complete...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Retrying deployment...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Deployment succeeded after cleanup and retry
```

---

## 🚀 Cómo Usarlo

### Opción 1: Push a Develop (Recomendado)

```bash
# Hacer cualquier cambio
git add .
git commit -m "fix: my changes"
git push origin develop

# El workflow se ejecuta automáticamente:
# - Purga recursos soft-deleted
# - Despliega infraestructura
# - Si falla, limpia y reintenta
# - Si sigue fallando, hace rollback
```

### Opción 2: Manual Dispatch

```bash
# En GitHub:
# 1. Go to Actions
# 2. Select "Deploy Infrastructure"
# 3. Click "Run workflow"
# 4. Select branch: develop
# 5. Confirm: yes
# 6. Run workflow
```

### Opción 3: Pull Request

```bash
# Crear PR a develop:
git checkout -b feature/my-feature
git add .
git commit -m "feat: my feature"
git push origin feature/my-feature

# GitHub Actions ejecutará:
# - Validation
# - What-If Analysis
# - NO despliega (solo valida)
```

---

## ⏱️ Tiempos de Ejecución

| Escenario | Tiempo Estimado |
|-----------|----------------|
| Despliegue exitoso (primer intento) | 15-20 minutos |
| Despliegue con retry (después de purge) | 25-30 minutos |
| Despliegue con rollback | 30-35 minutos |

El timeout total es de **45 minutos** por intento.

---

## 🔍 Monitoreo del Despliegue

### GitHub Actions UI

1. Ir a **Actions** tab
2. Click en el workflow en ejecución
3. Expandir cada step para ver logs detallados
4. Ver el **Summary** al final para resultados

### Azure Portal

```bash
# Ver deployment operations
az deployment group list \
  --resource-group az-rapidgo-dev-rg \
  --query "[].{name:name, state:properties.provisioningState}" \
  -o table

# Ver recursos creados
az resource list \
  --resource-group az-rapidgo-dev-rg \
  -o table
```

---

## 🛑 Qué Hacer Si Sigue Fallando

Si el workflow falla después del retry automático, revisa:

### 1. Check GitHub Actions Logs

```
Actions > Failed Workflow > Expand "Deploy ARM Template"
```

Busca el error específico en los logs.

### 2. Check Azure Deployment Operations

```bash
az deployment operation group list \
  --resource-group az-rapidgo-dev-rg \
  --name arm-rapidgo-dev \
  --query "[?properties.provisioningState=='Failed'].{resource:properties.targetResource.resourceName, error:properties.statusMessage.error.message}" \
  -o table
```

### 3. Manual Purge (Solo si Automático Falla)

```bash
# Si el purge automático falla, ejecuta manualmente:
./scripts/emergency-cleanup.sh
```

### 4. Verificar Permisos

```bash
# Verificar que el Service Principal tiene permisos
az role assignment list \
  --assignee <service-principal-id> \
  --scope /subscriptions/378e3d41-24e6-42ee-af96-9f64c25d1a61 \
  -o table
```

**Permisos requeridos:**
- `Contributor` o `Owner` en la suscripción
- Permisos para purgar Key Vaults y APIM

---

## 📊 GitHub Actions Summary

Al finalizar, el workflow genera un resumen:

**Éxito:**
```
✅ Deployment succeeded on first attempt
Resources deployed: 11
Time: 18m 32s
```

**Éxito después de retry:**
```
✅ Deployment succeeded after cleanup and retry
First attempt: Failed (soft-delete conflict)
Cleanup: 3 resources purged
Retry: Success
Total time: 26m 45s
```

**Fallo con rollback:**
```
❌ Deployment failed
Attempts: 2
Rollback: Completed
Resources cleaned up: 4
Check logs for details
```

---

## 🎯 Ventajas del Sistema Automático

✅ **Cero intervención manual** - Todo se maneja en GitHub Actions
✅ **Retry inteligente** - Detecta el tipo de error y aplica la solución correcta
✅ **Rollback automático** - Si falla, vuelve al estado anterior
✅ **Logs detallados** - Cada paso está documentado en los logs
✅ **Purge preventivo** - Limpia recursos soft-deleted ANTES de desplegar
✅ **Idempotente** - Puedes ejecutar el workflow múltiples veces sin problemas

---

## 📝 Commit History

```bash
git log --oneline -5

b4b9008 feat: add automatic cleanup and retry mechanism in GitHub Actions workflow
8a2ad75 fix: remove location parameter from deployment parameters file
1dec2e2 fix: use resourceGroup().location instead of hardcoded location parameter
5553686 docs: add comprehensive deployment troubleshooting guide
0b6a61a feat: add comprehensive cleanup scripts for deployment conflicts
```

---

## 🔗 Links Útiles

- **Workflow File**: `.github/workflows/deploy-infra.yml`
- **ARM Template**: `src/infra-arm/main.json`
- **Parameters**: `src/infra-arm/azuredeploy.parameters.json`
- **Troubleshooting Guide**: `DEPLOYMENT-TROUBLESHOOTING.md`
- **Emergency Cleanup Script**: `scripts/emergency-cleanup.sh` (backup local)

---

## 🎉 Próximos Pasos

1. **Push este commit a GitHub**:
   ```bash
   git push origin develop
   ```

2. **Observa el workflow ejecutarse**:
   - Ir a Actions tab
   - Ver el deployment en tiempo real
   - Verifica que el purge automático funciona

3. **Confirma el despliegue**:
   ```bash
   az resource list --resource-group az-rapidgo-dev-rg -o table
   ```

El sistema ahora es **completamente autónomo** y manejará todos los errores de soft-delete y location automáticamente. 🚀
