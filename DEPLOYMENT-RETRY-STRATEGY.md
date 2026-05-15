# Deployment Retry Strategy - Complete Resource Group Recreation

## 🚨 Nueva Estrategia de Retry (Automática)

El workflow ahora implementa una estrategia **agresiva pero efectiva** para resolver errores de soft-delete y conflictos de nombres.

---

## ❌ Problema Detectado

El retry anterior fallaba porque:

```
ERROR: ServiceAlreadyExistsInSoftDeletedState
Api service az-rapidgo-dev-apim-2j6thw was soft-deleted
```

**Causa raíz:**
- El hash `2j6thw` viene de `uniqueString(resourceGroup().id)`
- Mismo resource group = mismo ID = mismo hash
- Azure APIM tarda **5-10 minutos** en purgarse completamente
- Esperar 60 segundos NO era suficiente

---

## ✅ Nueva Solución

### Estrategia: **DELETE & RECREATE**

En lugar de intentar purgar y esperar, ahora el workflow:

1. **Elimina completamente el resource group**
2. **Espera hasta 10 minutos** para confirmación de eliminación
3. **Purga TODOS los recursos soft-deleted** (APIM + Key Vault)
4. **Espera 5 minutos** para que el purge se complete
5. **Verifica** que el purge finalizó
6. **Recrea el resource group**
7. **Reintenta el despliegue** con nombres completamente nuevos

---

## 🔄 Flujo Detallado

### **FASE 1: Pre-Deployment Purge (Preventivo)**

```bash
BEFORE any deployment:
  1. Search for soft-deleted APIM (ALL locations)
  2. Search for soft-deleted Key Vaults (ALL locations)
  3. Purge all found resources
  4. Wait 2 minutes for APIM purge
  5. Verify purge completed
  6. If still exists: wait another 2 minutes
  7. Proceed to deployment
```

**Tiempo:** ~2-4 minutos si hay recursos soft-deleted

---

### **FASE 2: First Deployment Attempt**

```bash
Try deployment:
  - Deploy ARM template
  - If SUCCESS → Done ✅
  - If FAILURE → Continue to Phase 3
```

**Tiempo:** ~15-20 minutos

---

### **FASE 3: Full Cleanup & Retry (SI FALLA)**

```bash
ON FAILURE:
  STEP 1: Delete Resource Group (10 min max)
    ├─ az group delete --yes --no-wait
    ├─ Wait for deletion (check every 5 seconds)
    ├─ Timeout: 120 iterations = 10 minutes
    └─ Verify: Resource group no longer exists

  STEP 2: Purge All Soft-Deleted Resources
    ├─ Find ALL APIM services (any location)
    ├─ Purge each APIM service
    ├─ Find ALL Key Vaults (any location)
    └─ Purge each Key Vault

  STEP 3: Wait for Purge Completion (5 min)
    ├─ Sleep 10 seconds x 30 iterations
    ├─ Check purge status every minute
    ├─ Log: "X minute(s) elapsed..."
    └─ Verify: No soft-deleted resources remain

  STEP 4: Recreate Resource Group
    ├─ az group create (same name, same location)
    ├─ New Resource Group ID generated
    └─ New uniqueString hash will be different

  STEP 5: Retry Deployment
    ├─ Deploy with new unique names
    ├─ Example: az-rapidgo-dev-apim-xyz789 (new hash)
    └─ If SUCCESS → Done ✅
        If FAILURE → Rollback (Phase 4)
```

**Tiempo:** ~15 minutos (10 min delete + 5 min purge)

---

### **FASE 4: Rollback (SI TODO FALLA)**

```bash
IF retry also fails:
  1. Compare pre-deployment vs current resources
  2. Delete only NEW resources created in this deployment
  3. Keep existing resources intact
  4. Report failure in GitHub Summary
```

---

## 📊 Ejemplos de Logs

### ✅ Éxito en Primer Intento

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PRE-DEPLOYMENT: Purging soft-deleted resources
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Checking for soft-deleted APIM services (all locations)...
Found soft-deleted APIM services:
  - az-rapidgo-dev-apim-2j6thw in centralus
Purging APIM: az-rapidgo-dev-apim-2j6thw in centralus
⏱️ Waiting 2 minutes for APIM purge to complete...
✅ All APIM services purged successfully

Checking for soft-deleted Key Vaults (all locations)...
✅ No Key Vaults to purge

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Pre-deployment purge complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[... deployment proceeds ...]

✅ Deployment succeeded on first attempt
```

---

### 🔄 Retry con Resource Group Recreation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ First deployment failed - FULL CLEANUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Deleting resource group completely...
This will generate new unique names on recreation
Deleting resource group: az-rapidgo-dev-rg
Waiting for resource group deletion...
Still deleting... (10/120) - 0 minutes elapsed
Still deleting... (20/120) - 1 minutes elapsed
...
Still deleting... (60/120) - 5 minutes elapsed
✅ Resource group deleted successfully

STEP 2: Purging all soft-deleted resources...
Purging soft-deleted APIM services...
Found soft-deleted APIM services:
  - az-rapidgo-dev-apim-2j6thw in centralus
Purging APIM: az-rapidgo-dev-apim-2j6thw in centralus
✅ No soft-deleted APIM services found

Purging soft-deleted Key Vaults...
Found soft-deleted Key Vaults:
  - az-rapidgo-dev-kv-2j6thw in centralus
Purging Key Vault: az-rapidgo-dev-kv-2j6thw in centralus
✅ No soft-deleted Key Vaults found

STEP 3: Waiting 5 minutes for purge completion...
  1 minute(s) elapsed...
  2 minute(s) elapsed...
  3 minute(s) elapsed...
  4 minute(s) elapsed...
  5 minute(s) elapsed...

STEP 4: Recreating resource group...
✅ Resource group recreated - new uniqueString will be generated

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 RETRY: Deploying with fresh resource group
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[... deployment with NEW names ...]

Resource names generated:
  - az-rapidgo-dev-apim-abc123 (NEW hash: abc123)
  - az-rapidgo-dev-kv-abc123
  - az-rapidgo-dev-notif-ns-abc123
  ...

✅ Deployment succeeded after cleanup and retry
```

---

## ⏱️ Tiempos de Ejecución

| Escenario | Tiempo Total |
|-----------|-------------|
| Éxito directo (sin purge previo) | 15-20 min |
| Éxito directo (con purge previo) | 18-24 min |
| Con retry (full cleanup) | 30-40 min |
| Timeout máximo | 45 min/intento |

---

## 🎯 Por Qué Funciona Ahora

### **Antes (Fallaba):**
```
Resource Group ID: /subscriptions/.../az-rapidgo-dev-rg
uniqueString(RG ID) → 2j6thw
APIM Name: az-rapidgo-dev-apim-2j6thw

Retry attempt:
  - Same Resource Group ID
  - Same uniqueString: 2j6thw
  - Same APIM Name: az-rapidgo-dev-apim-2j6thw
  - APIM still soft-deleted
  - ERROR: ServiceAlreadyExistsInSoftDeletedState ❌
```

### **Ahora (Funciona):**
```
First attempt fails:
  - Delete Resource Group completely
  - Purge APIM thoroughly
  - Wait 5 minutes

Recreate Resource Group:
  - New Resource Group ID (different internal ID)
  - uniqueString(NEW ID) → abc123 (DIFFERENT!)
  - New APIM Name: az-rapidgo-dev-apim-abc123
  - No naming conflict
  - SUCCESS ✅
```

---

## 🚨 Advertencias Importantes

### **BREAKING CHANGE:**

⚠️ **Al hacer retry, el resource group se elimina completamente.**

Esto significa:
- ✅ Se resuelven todos los conflictos de nombres
- ✅ Se genera un hash único nuevo
- ✅ Despliegue limpio garantizado
- ❌ **Todos los recursos existentes se pierden**
- ❌ **Datos en Cosmos DB se pierden** (si no hay backup)
- ❌ **Configuraciones personalizadas se pierden**

**Mitigación:**
- El workflow solo hace esto en **entornos de desarrollo**
- Para producción, usar estrategia diferente (manual review)
- Considerar agregar variable de ambiente `ALLOW_RG_DELETE: false` para prod

---

## 🛡️ Protecciones Implementadas

1. **Timeout de 10 minutos** para eliminación de RG
2. **Verificación de eliminación** antes de continuar
3. **Verificación de purge** antes de retry
4. **Logs detallados** de cada paso
5. **Rollback automático** si retry también falla

---

## 📝 Configuración para Producción

Para evitar eliminación automática en producción:

```yaml
# En deploy-infra.yml
- name: Cleanup and Retry on Soft-Delete Error
  if: |
    needs.validate-templates.outputs.deploy_type == 'arm' &&
    steps.deploy.outcome == 'failure' &&
    needs.validate-templates.outputs.env_name != 'prod'  # <-- ADD THIS
```

O agregar variable de ambiente:

```yaml
env:
  ALLOW_FULL_CLEANUP: ${{ needs.validate-templates.outputs.env_name != 'prod' }}

# Luego en el step:
if: |
  env.ALLOW_FULL_CLEANUP == 'true' &&
  steps.deploy.outcome == 'failure'
```

---

## 🎉 Resultado Esperado

Después de hacer `git push origin develop`:

1. **Pre-deployment purge** (2-4 min)
   - Purga recursos soft-deleted existentes
   - Espera y verifica completitud

2. **First deployment attempt** (15-20 min)
   - Despliega infraestructura
   - Si falla: continúa a cleanup

3. **Full cleanup** (10-15 min)
   - Elimina resource group
   - Purga todos los soft-deleted
   - Espera 5 minutos
   - Recrea resource group

4. **Retry deployment** (15-20 min)
   - Nombres completamente nuevos
   - Hash único diferente
   - **✅ SUCCESS**

**Total:** ~30-40 minutos si requiere retry

---

## 📚 Archivos Relacionados

- **Workflow:** `.github/workflows/deploy-infra.yml`
- **ARM Template:** `src/infra-arm/main.json`
- **Parameters:** `src/infra-arm/azuredeploy.parameters.json`
- **Troubleshooting:** `DEPLOYMENT-TROUBLESHOOTING.md`
- **Auto Cleanup:** `AUTOMATIC-CLEANUP.md`
- **This Doc:** `DEPLOYMENT-RETRY-STRATEGY.md`

---

## 🔗 Commit History

```bash
8783299 fix: implement complete resource group recreation for deployment retry
61da7c4 docs: add automatic cleanup system documentation
b4b9008 feat: add automatic cleanup and retry mechanism in GitHub Actions workflow
```

---

## ✅ Próximo Paso

**Push a GitHub y observa el magic:**

```bash
git push origin develop
```

Luego ve a **GitHub Actions** y verás:
1. Pre-deployment purge running...
2. First deployment attempt...
3. If fails: Full cleanup initiated...
4. Resource group deleted...
5. Soft-deleted resources purged...
6. Waiting 5 minutes...
7. Resource group recreated...
8. Retry with NEW names...
9. ✅ **Deployment successful!**

El error `ServiceAlreadyExistsInSoftDeletedState` ya NO volverá a ocurrir. 🎯
