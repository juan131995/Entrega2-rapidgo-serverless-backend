#!/bin/bash

# Complete cleanup script for RapidGo deployment conflicts
# Resolves: Key Vault soft-delete conflicts and Namespace conflicts

set -e

SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-378e3d41-24e6-42ee-af96-9f64c25d1a61}"
LOCATION="${LOCATION:-centralus}"
RG_NAME="${RG_NAME:-az-rapidgo-dev-rg}"

echo "=========================================="
echo "RapidGo - Complete Resource Cleanup"
echo "=========================================="
echo "Subscription: $SUBSCRIPTION_ID"
echo "Location: $LOCATION"
echo "Resource Group: $RG_NAME"
echo ""

# Function to check if a command succeeded
check_result() {
  if [ $? -eq 0 ]; then
    echo "✅ $1"
  else
    echo "⚠️  $1 (may not exist or already deleted)"
  fi
}

# ==========================================
# 1. PURGE SOFT-DELETED KEY VAULTS
# ==========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  PURGING SOFT-DELETED KEY VAULTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DELETED_VAULTS=$(az keyvault list-deleted \
  --subscription "$SUBSCRIPTION_ID" \
  --query "[?properties.location=='$LOCATION' && starts_with(name, 'az-rapidgo')].name" \
  -o tsv 2>/dev/null || echo "")

if [ -z "$DELETED_VAULTS" ]; then
  echo "✅ No soft-deleted Key Vaults to purge"
else
  echo "Found soft-deleted Key Vaults:"
  for VAULT in $DELETED_VAULTS; do
    echo "  - $VAULT"
  done
  echo ""

  for VAULT in $DELETED_VAULTS; do
    echo "Purging: $VAULT"
    az keyvault purge \
      --name "$VAULT" \
      --location "$LOCATION" \
      --subscription "$SUBSCRIPTION_ID" 2>/dev/null
    check_result "Purged Key Vault: $VAULT"
  done
fi

echo ""

# ==========================================
# 2. DELETE NOTIFICATION HUB NAMESPACES
# ==========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  DELETING NOTIFICATION HUB NAMESPACES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Find all Notification Hub namespaces starting with az-rapidgo
NH_LIST=$(az notification-hub namespace list \
  --subscription "$SUBSCRIPTION_ID" \
  --query "[?starts_with(name, 'az-rapidgo')].{name:name, rg:resourceGroup}" \
  -o json 2>/dev/null || echo "[]")

if [ "$NH_LIST" = "[]" ]; then
  echo "✅ No Notification Hub namespaces to delete"
else
  echo "Found Notification Hub namespaces:"
  echo "$NH_LIST" | jq -r '.[] | "  - \(.name) in \(.rg)"'
  echo ""

  echo "$NH_LIST" | jq -r '.[] | "\(.name)|\(.rg)"' | while IFS='|' read -r NAME RG; do
    echo "Deleting: $NAME from $RG"
    az notification-hub namespace delete \
      --name "$NAME" \
      --resource-group "$RG" \
      --subscription "$SUBSCRIPTION_ID" \
      --yes 2>/dev/null
    check_result "Deleted: $NAME"
  done
fi

echo ""

# ==========================================
# 3. PURGE SOFT-DELETED API MANAGEMENT
# ==========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  PURGING SOFT-DELETED APIM SERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DELETED_APIM=$(az apim deletedservice list \
  --subscription "$SUBSCRIPTION_ID" \
  --query "[?location=='$LOCATION' && starts_with(serviceName, 'az-rapidgo')].serviceName" \
  -o tsv 2>/dev/null || echo "")

if [ -z "$DELETED_APIM" ]; then
  echo "✅ No soft-deleted APIM services to purge"
else
  echo "Found soft-deleted APIM services:"
  for APIM in $DELETED_APIM; do
    echo "  - $APIM"
  done
  echo ""

  for APIM in $DELETED_APIM; do
    echo "Purging: $APIM"
    az apim deletedservice purge \
      --service-name "$APIM" \
      --location "$LOCATION" \
      --subscription "$SUBSCRIPTION_ID" 2>/dev/null
    check_result "Purged APIM: $APIM"
  done
fi

echo ""

# ==========================================
# 4. DELETE ORPHANED COSMOS DB ACCOUNTS
# ==========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  CHECKING COSMOS DB ACCOUNTS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

COSMOS_LIST=$(az cosmosdb list \
  --subscription "$SUBSCRIPTION_ID" \
  --query "[?starts_with(name, 'azrapidgo')].{name:name, rg:resourceGroup}" \
  -o json 2>/dev/null || echo "[]")

if [ "$COSMOS_LIST" != "[]" ]; then
  echo "Found Cosmos DB accounts:"
  echo "$COSMOS_LIST" | jq -r '.[] | "  - \(.name) in \(.rg)"'
  echo ""
  echo "⚠️  These will be reused if in the correct resource group"
  echo "   Delete manually if needed:"
  echo "$COSMOS_LIST" | jq -r '.[] | "     az cosmosdb delete --name \(.name) --resource-group \(.rg) --yes"'
else
  echo "✅ No Cosmos DB accounts found"
fi

echo ""

# ==========================================
# 5. SUMMARY
# ==========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ CLEANUP COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Deleted/Purged resources:"
echo "  ✓ Soft-deleted Key Vaults"
echo "  ✓ Notification Hub Namespaces"
echo "  ✓ Soft-deleted APIM services"
echo ""
echo "⏱️  Wait 5-10 minutes before redeploying"
echo ""
echo "To verify cleanup:"
echo "  az keyvault list-deleted --subscription $SUBSCRIPTION_ID"
echo "  az notification-hub namespace list --subscription $SUBSCRIPTION_ID"
echo "  az apim deletedservice list --subscription $SUBSCRIPTION_ID"
echo ""
echo "Then redeploy:"
echo "  az deployment group create \\"
echo "    --resource-group $RG_NAME \\"
echo "    --template-file src/infra-arm/main.json \\"
echo "    --parameters @src/infra-arm/parameters.dev.json \\"
echo "    --parameters environmentName=dev"
echo ""
