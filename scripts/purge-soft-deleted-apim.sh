#!/bin/bash
set -e

# Script to manually purge soft-deleted API Management services
# Run this if deployments fail with "Property at path location cannot be changed"

SUBSCRIPTION_ID="378e3d41-24e6-42ee-af96-9f64c25d1a61"

echo "======================================================"
echo "🧹 Azure API Management Soft-Delete Purge Tool"
echo "======================================================"
echo ""
echo "This script will purge ALL soft-deleted API Management"
echo "services in your subscription."
echo ""
echo "Subscription: $SUBSCRIPTION_ID"
echo ""

# Check if logged in
echo "Checking Azure login status..."
az account show &>/dev/null || {
    echo "❌ Not logged in to Azure. Please run: az login"
    exit 1
}

echo "✅ Logged in to Azure"
echo ""

# List soft-deleted APIM services
echo "🔍 Searching for soft-deleted API Management services..."
echo ""

DELETED_APIMS=$(az rest \
    --method get \
    --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.ApiManagement/deletedservices?api-version=2023-05-01-preview" \
    --query "value[].{name:name, location:location, deletionDate:deletionDate}" \
    -o json 2>/dev/null || echo "[]")

COUNT=$(echo "$DELETED_APIMS" | jq '. | length')

if [ "$COUNT" -eq 0 ]; then
    echo "✅ No soft-deleted API Management services found."
    echo "Your subscription is clean!"
    exit 0
fi

echo "Found $COUNT soft-deleted API Management service(s):"
echo ""
echo "$DELETED_APIMS" | jq -r '.[] | "  - \(.name) in \(.location) (deleted: \(.deletionDate))"'
echo ""

# Confirm purge
read -p "❓ Do you want to PERMANENTLY purge these services? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Purge cancelled."
    exit 0
fi

echo ""
echo "🗑️  Starting purge process..."
echo ""

# Purge each service
PURGED=0
FAILED=0

echo "$DELETED_APIMS" | jq -c '.[]' | while read -r apim; do
    APIM_NAME=$(echo "$apim" | jq -r '.name')
    APIM_LOCATION=$(echo "$apim" | jq -r '.location')

    echo "  Purging: $APIM_NAME in $APIM_LOCATION..."

    if az rest \
        --method delete \
        --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.ApiManagement/locations/${APIM_LOCATION}/deletedservices/${APIM_NAME}?api-version=2023-05-01-preview" \
        &>/dev/null; then
        echo "  ✅ Successfully purged: $APIM_NAME"
        PURGED=$((PURGED + 1))
    else
        echo "  ⚠️  Failed to purge: $APIM_NAME (may already be purged)"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

echo "======================================================"
echo "✅ Purge process completed!"
echo ""
echo "Successfully purged: $PURGED"
echo "Failed: $FAILED"
echo ""
echo "You can now retry your deployment."
echo "======================================================"
