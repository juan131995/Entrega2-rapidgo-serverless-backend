# Deployment Troubleshooting Guide

## Common Deployment Errors and Solutions

### Error 1: "A vault with the same name already exists in deleted state"

**Cause:** Azure Key Vault has soft-delete enabled by default. When deleted, vaults remain in a "soft-deleted" state for 90 days.

**Solution:**

```bash
# Option 1: Run full cleanup script (RECOMMENDED)
./scripts/full-cleanup.sh

# Option 2: Purge specific resources only
./scripts/purge-deleted-resources.sh

# Option 3: Manual purge
az keyvault purge --name <vault-name> --location centralus
```

---

### Error 2: "Namespace belongs to a different subscription or resource group"

**Cause:** A Notification Hub namespace with the same name exists in another resource group or subscription.

**Solution:**

```bash
# Option 1: Run full cleanup script (RECOMMENDED)
./scripts/full-cleanup.sh

# Option 2: Fix namespace conflict only
./scripts/fix-namespace-conflict.sh

# Option 3: Manual deletion
az notification-hub namespace delete \
  --name az-rapidgo-dev-notif-ns \
  --resource-group <resource-group-name> \
  --yes
```

---

### Error 3: "ServiceAlreadyExists: Api service already exists"

**Cause:** API Management service name conflict (should be resolved by unique suffixes).

**Solution:**

The template now uses `uniqueString(resourceGroup().id)` to generate unique names.

If the error persists:

```bash
# Purge soft-deleted APIM services
./scripts/full-cleanup.sh

# Or manually:
az apim deletedservice purge \
  --service-name <apim-name> \
  --location centralus
```

---

### Error 4: "Property at path location cannot be changed"

**Cause:** Attempting to change the location of an existing resource.

**Solution:**

✅ **FIXED** - The template now uses `resourceGroup().location` instead of hardcoded location parameters.

If resources exist in a different location:
1. Delete the resource group
2. Create a new resource group in the desired location
3. Redeploy

```bash
# Delete resource group
az group delete --name az-rapidgo-dev-rg --yes --no-wait

# Create in new location
az group create --name az-rapidgo-dev-rg --location eastus

# Deploy
az deployment group create \
  --resource-group az-rapidgo-dev-rg \
  --template-file src/infra-arm/main.json \
  --parameters @src/infra-arm/parameters.dev.json \
  --parameters environmentName=dev
```

---

## Complete Cleanup Workflow

### Step 1: Run Full Cleanup

```bash
# Set environment variables (optional)
export AZURE_SUBSCRIPTION_ID="378e3d41-24e6-42ee-af96-9f64c25d1a61"
export LOCATION="centralus"
export RG_NAME="az-rapidgo-dev-rg"

# Run cleanup
./scripts/full-cleanup.sh
```

### Step 2: Wait for Purge Operations

⏱️ **Wait 5-10 minutes** for purge operations to complete.

### Step 3: Verify Cleanup

```bash
# Check for soft-deleted Key Vaults
az keyvault list-deleted

# Check for Notification Hub namespaces
az notification-hub namespace list

# Check for soft-deleted APIM services
az apim deletedservice list
```

### Step 4: Redeploy

```bash
# Via Azure CLI
az deployment group create \
  --resource-group az-rapidgo-dev-rg \
  --template-file src/infra-arm/main.json \
  --parameters @src/infra-arm/parameters.dev.json \
  --parameters environmentName=dev

# Or via GitHub Actions
# Push to develop branch to trigger deployment
git push origin develop
```

---

## Resource Naming Convention

All resources now use unique suffixes to prevent naming conflicts:

```
Pattern: <prefix>-<env>-<resource-type>-<unique-hash>

Examples:
  - az-rapidgo-dev-apim-a3b5c7       (API Management)
  - az-rapidgo-dev-notif-ns-a3b5c7   (Notification Hub Namespace)
  - az-rapidgo-dev-kv-a3b5c7         (Key Vault)
  - azrapidgodevdba3b5c7             (Cosmos DB Account)
```

The `<unique-hash>` is generated using:
```json
"uniqueSuffix": "[substring(uniqueString(resourceGroup().id), 0, 6)]"
```

This ensures:
- ✅ Global uniqueness across Azure
- ✅ Consistent naming within a resource group
- ✅ Different names across different resource groups

---

## Prevention Tips

### 1. Always use cleanup before major redeployments

```bash
./scripts/full-cleanup.sh
```

### 2. Check for existing resources before deploying

```bash
az resource list --resource-group az-rapidgo-dev-rg -o table
```

### 3. Use incremental deployment mode

The template uses `--mode Incremental` by default, which:
- ✅ Only adds/updates resources
- ✅ Doesn't delete existing resources
- ❌ Can cause conflicts if resource definitions change

For a clean slate, delete the resource group first.

### 4. Monitor deployment progress

```bash
# Watch deployment in real-time
az deployment group list \
  --resource-group az-rapidgo-dev-rg \
  --query "[].{name:name, state:properties.provisioningState, timestamp:properties.timestamp}" \
  -o table
```

---

## Quick Reference

| Error | Script | Manual Command |
|-------|--------|----------------|
| Key Vault soft-delete | `full-cleanup.sh` | `az keyvault purge --name <name> --location <loc>` |
| Namespace conflict | `full-cleanup.sh` | `az notification-hub namespace delete --name <name> --resource-group <rg> --yes` |
| APIM soft-delete | `full-cleanup.sh` | `az apim deletedservice purge --service-name <name> --location <loc>` |
| Location conflict | Delete + Recreate RG | `az group delete --name <rg> --yes` |

---

## Getting Help

If cleanup scripts fail:

1. **Check Azure Portal**: Some resources may have locks or dependencies
2. **Check subscription permissions**: Ensure you have `Owner` or `Contributor` role
3. **Wait longer**: Some purge operations can take 15-30 minutes
4. **Manual cleanup**: Use Azure Portal to identify and delete conflicting resources

For persistent issues, check:
- Resource locks: `az lock list --resource-group az-rapidgo-dev-rg`
- Role assignments: `az role assignment list --scope /subscriptions/<sub-id>/resourceGroups/<rg>`
- Diagnostic logs: Azure Portal > Resource Group > Activity Log
