#!/bin/bash

# Script to fix "Namespace belongs to a different subscription or resource group" error
# This happens when a namespace exists elsewhere with the same name

set -e

echo "=========================================="
echo "Fixing Notification Hub Namespace Conflict"
echo "=========================================="

SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-378e3d41-24e6-42ee-af96-9f64c25d1a61}"
PROBLEMATIC_NAME="az-rapidgo-dev-notif-ns"

echo "Searching for namespace: $PROBLEMATIC_NAME"
echo "Subscription: $SUBSCRIPTION_ID"
echo ""

# Search for the problematic namespace across all resource groups
echo "🔍 Searching across all resource groups..."
FOUND_NAMESPACES=$(az notification-hub namespace list \
  --subscription "$SUBSCRIPTION_ID" \
  --query "[?name=='$PROBLEMATIC_NAME'].{name:name, rg:resourceGroup, location:location, id:id}" \
  -o json 2>/dev/null || echo "[]")

if [ "$FOUND_NAMESPACES" = "[]" ]; then
  echo "✅ Namespace '$PROBLEMATIC_NAME' not found in this subscription"
  echo ""
  echo "The error might be due to:"
  echo "  1. Cached DNS records (wait 5-10 minutes)"
  echo "  2. Namespace exists in a different subscription"
  echo "  3. Soft-deleted resource that needs purging"
else
  echo "⚠️  Found namespace(s):"
  echo "$FOUND_NAMESPACES" | jq -r '.[] | "  Name: \(.name)\n  Resource Group: \(.rg)\n  Location: \(.location)\n  ID: \(.id)\n"'

  # Delete each found namespace
  echo "$FOUND_NAMESPACES" | jq -r '.[] | "\(.name)|\(.rg)"' | while IFS='|' read -r NAME RG; do
    echo "🗑️  Deleting namespace: $NAME from $RG"
    az notification-hub namespace delete \
      --name "$NAME" \
      --resource-group "$RG" \
      --subscription "$SUBSCRIPTION_ID" \
      --yes \
      --no-wait 2>/dev/null && echo "✅ Deletion initiated for: $NAME" || echo "❌ Failed to delete: $NAME"
  done
fi

echo ""

# Also check for any Service Bus namespaces (Notification Hubs use Service Bus)
echo "🔍 Checking Service Bus namespaces..."
SB_NAMESPACES=$(az servicebus namespace list \
  --subscription "$SUBSCRIPTION_ID" \
  --query "[?starts_with(name, 'az-rapidgo-dev-notif')].{name:name, rg:resourceGroup, location:location}" \
  -o json 2>/dev/null || echo "[]")

if [ "$SB_NAMESPACES" != "[]" ]; then
  echo "⚠️  Found related Service Bus namespaces:"
  echo "$SB_NAMESPACES" | jq -r '.[] | "  - \(.name) in \(.rg) (\(.location))"'
  echo ""
  echo "Delete them manually if needed:"
  echo "$SB_NAMESPACES" | jq -r '.[] | "  az servicebus namespace delete --name \(.name) --resource-group \(.rg) --yes"'
fi

echo ""
echo "=========================================="
echo "✅ Cleanup complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Wait 5-10 minutes for deletion to complete"
echo "  2. Re-run the deployment"
echo "  3. The new namespace will have a unique suffix (e.g., az-rapidgo-dev-notif-ns-abc123)"
echo ""
