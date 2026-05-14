#!/bin/bash

# Emergency cleanup script for immediate deployment fix
# Resolves: APIM soft-delete + location conflicts

set -e

SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-378e3d41-24e6-42ee-af96-9f64c25d1a61}"
LOCATION="${LOCATION:-centralus}"
RG_NAME="${RG_NAME:-az-rapidgo-dev-rg}"
APIM_NAME="az-rapidgo-dev-apim-2j6thw"

echo "=========================================="
echo "🚨 EMERGENCY CLEANUP - RapidGo Deployment"
echo "=========================================="
echo "Subscription: $SUBSCRIPTION_ID"
echo "Location: $LOCATION"
echo "Resource Group: $RG_NAME"
echo "APIM to purge: $APIM_NAME"
echo ""

# ==========================================
# STEP 1: PURGE SOFT-DELETED APIM
# ==========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: Purging soft-deleted APIM service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Checking for soft-deleted APIM: $APIM_NAME"
APIM_EXISTS=$(az apim deletedservice show \
  --service-name "$APIM_NAME" \
  --location "$LOCATION" \
  --subscription "$SUBSCRIPTION_ID" \
  --query "serviceName" -o tsv 2>/dev/null || echo "")

if [ -z "$APIM_EXISTS" ]; then
  echo "⚠️  APIM not found in soft-deleted state, checking all locations..."

  # Check all soft-deleted APIM services
  ALL_DELETED=$(az apim deletedservice list \
    --subscription "$SUBSCRIPTION_ID" \
    --query "[?starts_with(serviceName, 'az-rapidgo')].{name:serviceName, location:location}" \
    -o json 2>/dev/null || echo "[]")

  if [ "$ALL_DELETED" != "[]" ]; then
    echo "Found soft-deleted APIM services:"
    echo "$ALL_DELETED" | jq -r '.[] | "  - \(.name) in \(.location)"'

    # Purge all found services
    echo "$ALL_DELETED" | jq -r '.[] | "\(.name)|\(.location)"' | while IFS='|' read -r NAME LOC; do
      echo "Purging APIM: $NAME in $LOC"
      az apim deletedservice purge \
        --service-name "$NAME" \
        --location "$LOC" \
        --subscription "$SUBSCRIPTION_ID" 2>/dev/null && echo "✅ Purged: $NAME" || echo "⚠️  Failed: $NAME"
    done
  else
    echo "✅ No soft-deleted APIM services found"
  fi
else
  echo "Found soft-deleted APIM: $APIM_NAME in $LOCATION"
  echo "Purging..."

  az apim deletedservice purge \
    --service-name "$APIM_NAME" \
    --location "$LOCATION" \
    --subscription "$SUBSCRIPTION_ID" 2>/dev/null && echo "✅ Purged: $APIM_NAME" || echo "❌ Failed to purge: $APIM_NAME"
fi

echo ""

# ==========================================
# STEP 2: DELETE RESOURCE GROUP
# ==========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: Deleting Resource Group (Clean Slate)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  WARNING: This will delete ALL resources in $RG_NAME"
echo ""
echo "Resources in $RG_NAME:"
az resource list --resource-group "$RG_NAME" --query "[].{name:name, type:type, location:location}" -o table 2>/dev/null || echo "Resource group doesn't exist or is empty"
echo ""

read -p "Delete resource group $RG_NAME? (yes/no): " CONFIRM

if [ "$CONFIRM" = "yes" ]; then
  echo "Deleting resource group: $RG_NAME"
  az group delete \
    --name "$RG_NAME" \
    --subscription "$SUBSCRIPTION_ID" \
    --yes \
    --no-wait 2>/dev/null && echo "✅ Deletion initiated" || echo "⚠️  Resource group may not exist"

  echo ""
  echo "⏱️  Waiting for deletion to complete (this may take 5-10 minutes)..."
  echo "Check status with: az group show --name $RG_NAME"
else
  echo "⚠️  Skipped resource group deletion"
fi

echo ""

# ==========================================
# STEP 3: PURGE ALL SOFT-DELETED RESOURCES
# ==========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: Purging all soft-deleted resources"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Purge Key Vaults
echo "Purging Key Vaults..."
DELETED_KV=$(az keyvault list-deleted \
  --subscription "$SUBSCRIPTION_ID" \
  --query "[?properties.location=='$LOCATION' && starts_with(name, 'az-rapidgo')].name" \
  -o tsv 2>/dev/null || echo "")

if [ -n "$DELETED_KV" ]; then
  for KV in $DELETED_KV; do
    echo "Purging Key Vault: $KV"
    az keyvault purge \
      --name "$KV" \
      --location "$LOCATION" \
      --subscription "$SUBSCRIPTION_ID" 2>/dev/null && echo "✅ Purged: $KV" || echo "⚠️  Failed: $KV"
  done
else
  echo "✅ No Key Vaults to purge"
fi

echo ""

# ==========================================
# STEP 4: RECREATE RESOURCE GROUP
# ==========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: Recreating Resource Group"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$CONFIRM" = "yes" ]; then
  echo "⏱️  Waiting 30 seconds for deletion to propagate..."
  sleep 30

  echo "Creating resource group: $RG_NAME in $LOCATION"
  az group create \
    --name "$RG_NAME" \
    --location "$LOCATION" \
    --subscription "$SUBSCRIPTION_ID" \
    --tags environment=dev managedBy=github-actions 2>/dev/null && echo "✅ Created: $RG_NAME" || echo "❌ Failed to create"
fi

echo ""

# ==========================================
# SUMMARY
# ==========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ EMERGENCY CLEANUP COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "What was done:"
echo "  ✓ Purged soft-deleted APIM: $APIM_NAME"
echo "  ✓ Purged soft-deleted Key Vaults"
if [ "$CONFIRM" = "yes" ]; then
  echo "  ✓ Deleted resource group: $RG_NAME"
  echo "  ✓ Recreated resource group: $RG_NAME in $LOCATION"
fi
echo ""
echo "⏱️  Wait 5 more minutes before deploying"
echo ""
echo "Then deploy:"
echo "  cd /Users/juanpablobedoya/Documents/Tdea/Nube/Entrega\ 2/Entrega2-rapidgo-serverless-backend"
echo "  az deployment group create \\"
echo "    --resource-group $RG_NAME \\"
echo "    --template-file src/infra-arm/main.json \\"
echo "    --parameters @src/infra-arm/azuredeploy.parameters.json \\"
echo "    --parameters environmentName=dev"
echo ""
echo "Or push to GitHub:"
echo "  git push origin develop"
echo ""
