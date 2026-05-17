#!/bin/bash
# Manual cleanup script for stuck Azure resources
# Usage: ./scripts/cleanup-stuck-resources.sh [resource-group-name]

set -e

RG_NAME="${1:-az-rapidgo-dev-rg}"
LOCATION="${2:-centralus}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 Manual Cleanup Script for Azure Resources"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Resource Group: $RG_NAME"
echo "Location: $LOCATION"
echo ""

# Step 1: Try to delete resource group
echo "STEP 1: Attempting to delete resource group..."
if az group exists --name "$RG_NAME" --query exists -o tsv | grep -q "true"; then
  echo "Resource group exists. Starting deletion..."
  
  # List resources first
  echo ""
  echo "Resources in group:"
  az resource list --resource-group "$RG_NAME" --query "[].{name:name, type:type}" -o table || true
  
  echo ""
  echo "Deleting resource group (this may take 20-30 minutes for Cosmos DB)..."
  az group delete --name "$RG_NAME" --yes --no-wait
  
  # Wait for deletion
  echo "Waiting for deletion to complete..."
  MAX_WAIT=360
  for i in $(seq 1 $MAX_WAIT); do
    if ! az group exists --name "$RG_NAME" --query exists -o tsv | grep -q "true"; then
      echo "✅ Resource group deleted successfully"
      break
    fi
    if [ $((i % 12)) -eq 0 ]; then
      echo "  Still deleting... $((i * 5 / 60)) minutes elapsed"
    fi
    sleep 5
  done
  
  if az group exists --name "$RG_NAME" --query exists -o tsv | grep -q "true"; then
    echo "❌ Resource group still exists after 30 minutes"
    echo "Attempting individual resource deletion..."
    
    # Try to delete individual resources
    RESOURCES=$(az resource list --resource-group "$RG_NAME" --query "[].id" -o tsv || true)
    for RESOURCE_ID in $RESOURCES; do
      echo "Deleting: $RESOURCE_ID"
      az resource delete --ids "$RESOURCE_ID" --verbose || echo "Failed to delete: $RESOURCE_ID"
      sleep 30
    done
  fi
else
  echo "✅ Resource group does not exist"
fi

echo ""

# Step 2: Purge soft-deleted resources
echo "STEP 2: Purging soft-deleted resources..."

# Cosmos DB
echo "Checking soft-deleted Cosmos DB..."
DELETED_COSMOS=$(az cosmosdb list-deleted --query "[?starts_with(name, 'azrapidgo') || starts_with(name, 'az-rapidgo')].{name:name, location:location}" -o json 2>/dev/null || echo "[]")
if [ "$DELETED_COSMOS" != "[]" ]; then
  echo "Found soft-deleted Cosmos DB:"
  echo "$DELETED_COSMOS" | jq -r '.[] | "  - \(.name) in \(.location)"'
  echo "$DELETED_COSMOS" | jq -r '.[] | "\(.name)|\(.location)"' | while IFS='|' read -r NAME LOC; do
    echo "Purging Cosmos DB: $NAME"
    az cosmosdb delete --name "$NAME" --resource-group "$RG_NAME" --yes 2>&1 || true
  done
else
  echo "✅ No soft-deleted Cosmos DB"
fi

# APIM
echo ""
echo "Checking soft-deleted APIM..."
DELETED_APIM=$(az apim deletedservice list --query "[?starts_with(serviceName, 'az-rapidgo')].{name:serviceName, location:location}" -o json 2>/dev/null || echo "[]")
if [ "$DELETED_APIM" != "[]" ]; then
  echo "Found soft-deleted APIM:"
  echo "$DELETED_APIM" | jq -r '.[] | "  - \(.name) in \(.location)"'
  echo "$DELETED_APIM" | jq -r '.[] | "\(.name)|\(.location)"' | while IFS='|' read -r NAME LOC; do
    echo "Purging APIM: $NAME"
    az apim deletedservice purge --service-name "$NAME" --location "$LOC" 2>&1 || true
  done
else
  echo "✅ No soft-deleted APIM"
fi

# Key Vault
echo ""
echo "Checking soft-deleted Key Vaults..."
DELETED_KV=$(az keyvault list-deleted --query "[?starts_with(name, 'az-rapidgo')].{name:name, location:properties.location}" -o json 2>/dev/null || echo "[]")
if [ "$DELETED_KV" != "[]" ]; then
  echo "Found soft-deleted Key Vaults:"
  echo "$DELETED_KV" | jq -r '.[] | "  - \(.name) in \(.location)"'
  echo "$DELETED_KV" | jq -r '.[] | "\(.name)|\(.location)"' | while IFS='|' read -r NAME LOC; do
    echo "Purging Key Vault: $NAME"
    az keyvault purge --name "$NAME" --location "$LOC" 2>&1 || true
  done
else
  echo "✅ No soft-deleted Key Vaults"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Cleanup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "If resources are still stuck, you may need to:"
echo "1. Wait 30-60 minutes for Azure to complete background operations"
echo "2. Check Azure Portal for any resources in 'Deleting' state"
echo "3. Contact Azure Support if resources remain stuck after 24 hours"
