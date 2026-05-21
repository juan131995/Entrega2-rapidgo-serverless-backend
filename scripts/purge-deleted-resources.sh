#!/bin/bash

# Script to purge soft-deleted Azure resources
# This resolves naming conflicts during deployment

set -e

echo "=========================================="
echo "Purging Soft-Deleted Azure Resources"
echo "=========================================="

SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-378e3d41-24e6-42ee-af96-9f64c25d1a61}"
LOCATION="${LOCATION:-centralus}"

echo "Subscription: $SUBSCRIPTION_ID"
echo "Location: $LOCATION"
echo ""

# 1. Purge soft-deleted Key Vaults
echo "1️⃣  Purging soft-deleted Key Vaults..."
echo "------------------------------------------"

DELETED_VAULTS=$(az keyvault list-deleted --subscription "$SUBSCRIPTION_ID" --query "[?properties.location=='$LOCATION'].name" -o tsv 2>/dev/null || echo "")

if [ -z "$DELETED_VAULTS" ]; then
  echo "✅ No soft-deleted Key Vaults found in $LOCATION"
else
  echo "Found soft-deleted Key Vaults:"
  echo "$DELETED_VAULTS"
  echo ""

  for VAULT_NAME in $DELETED_VAULTS; do
    echo "Purging Key Vault: $VAULT_NAME"
    az keyvault purge \
      --name "$VAULT_NAME" \
      --location "$LOCATION" \
      --subscription "$SUBSCRIPTION_ID" \
      --no-wait 2>/dev/null && echo "✅ Purged: $VAULT_NAME" || echo "⚠️  Failed to purge: $VAULT_NAME"
  done
fi

echo ""

# 2. Clean up orphaned Notification Hub Namespaces
echo "2️⃣  Checking for orphaned Notification Hub Namespaces..."
echo "------------------------------------------"

# List all Service Bus namespaces (Notification Hubs use Service Bus internally)
ORPHANED_NS=$(az servicebus namespace list --subscription "$SUBSCRIPTION_ID" \
  --query "[?starts_with(name, 'az-rapidgo')].{name:name, rg:resourceGroup, location:location}" -o json 2>/dev/null || echo "[]")

if [ "$ORPHANED_NS" = "[]" ]; then
  echo "✅ No orphaned Service Bus namespaces found"
else
  echo "Found Service Bus namespaces:"
  echo "$ORPHANED_NS" | jq -r '.[] | "  - \(.name) in \(.rg) (\(.location))"'
  echo ""
  echo "⚠️  If these are causing conflicts, delete them manually:"
  echo "$ORPHANED_NS" | jq -r '.[] | "  az servicebus namespace delete --name \(.name) --resource-group \(.rg)"'
fi

echo ""

# 3. Check Notification Hub Namespaces specifically
echo "3️⃣  Checking Notification Hub Namespaces..."
echo "------------------------------------------"

NH_NAMESPACES=$(az notification-hub namespace list --subscription "$SUBSCRIPTION_ID" \
  --query "[?starts_with(name, 'az-rapidgo')].{name:name, rg:resourceGroup, location:location}" -o json 2>/dev/null || echo "[]")

if [ "$NH_NAMESPACES" = "[]" ]; then
  echo "✅ No Notification Hub namespaces found"
else
  echo "Found Notification Hub namespaces:"
  echo "$NH_NAMESPACES" | jq -r '.[] | "  - \(.name) in \(.rg) (\(.location))"'
  echo ""
  echo "⚠️  These may be causing the 'belongs to a different subscription or resource group' error"
  echo "Run these commands to delete them:"
  echo "$NH_NAMESPACES" | jq -r '.[] | "  az notification-hub namespace delete --name \(.name) --resource-group \(.rg)"'
fi

echo ""

# 4. Purge soft-deleted API Management services
echo "4️⃣  Purging soft-deleted API Management services..."
echo "------------------------------------------"

DELETED_APIM=$(az apim deletedservice list --subscription "$SUBSCRIPTION_ID" \
  --query "[?location=='$LOCATION' && starts_with(serviceName, 'az-rapidgo')].serviceName" -o tsv 2>/dev/null || echo "")

if [ -z "$DELETED_APIM" ]; then
  echo "✅ No soft-deleted APIM services found in $LOCATION"
else
  echo "Found soft-deleted APIM services:"
  echo "$DELETED_APIM"
  echo ""

  for APIM_NAME in $DELETED_APIM; do
    echo "Purging APIM service: $APIM_NAME"
    az apim deletedservice purge \
      --service-name "$APIM_NAME" \
      --location "$LOCATION" \
      --subscription "$SUBSCRIPTION_ID" \
      --no-wait 2>/dev/null && echo "✅ Purged: $APIM_NAME" || echo "⚠️  Failed to purge: $APIM_NAME"
  done
fi

echo ""

# 5. Summary
echo "=========================================="
echo "✅ Purge operations initiated"
echo "=========================================="
echo ""
echo "Note: Purge operations run asynchronously."
echo "Wait 5-10 minutes before redeploying."
echo ""
echo "To check status:"
echo "  az keyvault list-deleted --subscription $SUBSCRIPTION_ID"
echo "  az apim deletedservice list --subscription $SUBSCRIPTION_ID"
echo ""
