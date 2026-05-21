#!/bin/bash
set -e

# Script to purge ALL soft-deleted Azure resources that can cause deployment conflicts
# Covers: API Management, Key Vault, Notification Hubs, Cognitive Services

SUBSCRIPTION_ID="378e3d41-24e6-42ee-af96-9f64c25d1a61"

echo "======================================================"
echo "🧹 Azure Soft-Delete Purge Tool (ALL RESOURCES)"
echo "======================================================"
echo ""
echo "This script will purge ALL soft-deleted resources that"
echo "can cause 'location cannot be changed' errors:"
echo ""
echo "  ✅ API Management"
echo "  ✅ Key Vaults"
echo "  ✅ Notification Hubs"
echo "  ✅ Cognitive Services"
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

TOTAL_FOUND=0
TOTAL_PURGED=0
TOTAL_FAILED=0

# ============================================================
# 1. API MANAGEMENT
# ============================================================
echo "======================================================"
echo "🔍 1. API MANAGEMENT - Checking for soft-deleted services..."
echo "======================================================"
echo ""

DELETED_APIMS=$(az rest \
    --method get \
    --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.ApiManagement/deletedservices?api-version=2023-05-01-preview" \
    --query "value[].{name:name, location:location, deletionDate:deletionDate}" \
    -o json 2>/dev/null || echo "[]")

APIM_COUNT=$(echo "$DELETED_APIMS" | jq '. | length')

if [ "$APIM_COUNT" -eq 0 ]; then
    echo "✅ No soft-deleted API Management services found"
else
    echo "Found $APIM_COUNT soft-deleted API Management service(s):"
    echo "$DELETED_APIMS" | jq -r '.[] | "  - \(.name) in \(.location) (deleted: \(.deletionDate))"'
    echo ""
    TOTAL_FOUND=$((TOTAL_FOUND + APIM_COUNT))

    read -p "❓ Purge these API Management services? (yes/no): " CONFIRM_APIM

    if [ "$CONFIRM_APIM" = "yes" ]; then
        echo ""
        echo "$DELETED_APIMS" | jq -c '.[]' | while read -r apim; do
            APIM_NAME=$(echo "$apim" | jq -r '.name')
            APIM_LOCATION=$(echo "$apim" | jq -r '.location')

            echo "  🗑️  Purging APIM: $APIM_NAME in $APIM_LOCATION..."

            if az rest \
                --method delete \
                --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.ApiManagement/locations/${APIM_LOCATION}/deletedservices/${APIM_NAME}?api-version=2023-05-01-preview" \
                &>/dev/null; then
                echo "  ✅ Successfully purged: $APIM_NAME"
            else
                echo "  ⚠️  Failed to purge: $APIM_NAME"
            fi
        done
    else
        echo "⏭️  Skipped API Management purge"
    fi
fi

echo ""

# ============================================================
# 2. KEY VAULTS
# ============================================================
echo "======================================================"
echo "🔍 2. KEY VAULT - Checking for soft-deleted vaults..."
echo "======================================================"
echo ""

DELETED_KVS=$(az keyvault list-deleted \
    --query "[].{name:name, location:properties.location, deletionDate:properties.deletionDate, scheduledPurge:properties.scheduledPurgeDate}" \
    -o json 2>/dev/null || echo "[]")

KV_COUNT=$(echo "$DELETED_KVS" | jq '. | length')

if [ "$KV_COUNT" -eq 0 ]; then
    echo "✅ No soft-deleted Key Vaults found"
else
    echo "Found $KV_COUNT soft-deleted Key Vault(s):"
    echo "$DELETED_KVS" | jq -r '.[] | "  - \(.name) in \(.location) (purge scheduled: \(.scheduledPurge))"'
    echo ""
    TOTAL_FOUND=$((TOTAL_FOUND + KV_COUNT))

    read -p "❓ Purge these Key Vaults? (yes/no): " CONFIRM_KV

    if [ "$CONFIRM_KV" = "yes" ]; then
        echo ""
        echo "$DELETED_KVS" | jq -c '.[]' | while read -r kv; do
            KV_NAME=$(echo "$kv" | jq -r '.name')
            KV_LOCATION=$(echo "$kv" | jq -r '.location')

            echo "  🗑️  Purging Key Vault: $KV_NAME in $KV_LOCATION..."

            if az keyvault purge --name "$KV_NAME" --location "$KV_LOCATION" &>/dev/null; then
                echo "  ✅ Successfully purged: $KV_NAME"
            else
                echo "  ⚠️  Failed to purge: $KV_NAME"
            fi
        done
    else
        echo "⏭️  Skipped Key Vault purge"
    fi
fi

echo ""

# ============================================================
# 3. NOTIFICATION HUBS
# ============================================================
echo "======================================================"
echo "🔍 3. NOTIFICATION HUBS - Checking for soft-deleted namespaces..."
echo "======================================================"
echo ""

# Notification Hubs don't have a direct soft-delete list API, but we can check for orphaned namespaces
# First, let's list all Notification Hub namespaces and check their state

DELETED_NH=$(az resource list \
    --resource-type "Microsoft.NotificationHubs/namespaces" \
    --query "[?starts_with(name, 'rg-') && (provisioningState=='Deleting' || provisioningState=='Failed')].{name:name, location:location, resourceGroup:resourceGroup, state:provisioningState}" \
    -o json 2>/dev/null || echo "[]")

NH_COUNT=$(echo "$DELETED_NH" | jq '. | length')

if [ "$NH_COUNT" -eq 0 ]; then
    echo "✅ No problematic Notification Hub namespaces found"
else
    echo "Found $NH_COUNT Notification Hub namespace(s) in bad state:"
    echo "$DELETED_NH" | jq -r '.[] | "  - \(.name) in \(.location) (state: \(.state), RG: \(.resourceGroup))"'
    echo ""
    TOTAL_FOUND=$((TOTAL_FOUND + NH_COUNT))

    read -p "❓ Delete these Notification Hub namespaces? (yes/no): " CONFIRM_NH

    if [ "$CONFIRM_NH" = "yes" ]; then
        echo ""
        echo "$DELETED_NH" | jq -c '.[]' | while read -r nh; do
            NH_NAME=$(echo "$nh" | jq -r '.name')
            NH_RG=$(echo "$nh" | jq -r '.resourceGroup')

            echo "  🗑️  Deleting Notification Hub namespace: $NH_NAME..."

            if az resource delete \
                --resource-group "$NH_RG" \
                --name "$NH_NAME" \
                --resource-type "Microsoft.NotificationHubs/namespaces" \
                --verbose &>/dev/null; then
                echo "  ✅ Successfully deleted: $NH_NAME"
            else
                echo "  ⚠️  Failed to delete: $NH_NAME (may need manual cleanup)"
            fi
        done
    else
        echo "⏭️  Skipped Notification Hub cleanup"
    fi
fi

echo ""

# ============================================================
# 4. COGNITIVE SERVICES (if used in the future)
# ============================================================
echo "======================================================"
echo "🔍 4. COGNITIVE SERVICES - Checking for soft-deleted accounts..."
echo "======================================================"
echo ""

DELETED_COG=$(az cognitiveservices account list-deleted \
    --query "[].{name:name, location:location, deletionDate:deletionDate}" \
    -o json 2>/dev/null || echo "[]")

COG_COUNT=$(echo "$DELETED_COG" | jq '. | length')

if [ "$COG_COUNT" -eq 0 ]; then
    echo "✅ No soft-deleted Cognitive Services accounts found"
else
    echo "Found $COG_COUNT soft-deleted Cognitive Services account(s):"
    echo "$DELETED_COG" | jq -r '.[] | "  - \(.name) in \(.location)"'
    echo ""
    TOTAL_FOUND=$((TOTAL_FOUND + COG_COUNT))

    read -p "❓ Purge these Cognitive Services accounts? (yes/no): " CONFIRM_COG

    if [ "$CONFIRM_COG" = "yes" ]; then
        echo ""
        echo "$DELETED_COG" | jq -c '.[]' | while read -r cog; do
            COG_NAME=$(echo "$cog" | jq -r '.name')
            COG_RG=$(echo "$cog" | jq -r '.resourceGroup // "deleted"')
            COG_LOCATION=$(echo "$cog" | jq -r '.location')

            echo "  🗑️  Purging Cognitive Services: $COG_NAME in $COG_LOCATION..."

            if az cognitiveservices account purge \
                --name "$COG_NAME" \
                --resource-group "$COG_RG" \
                --location "$COG_LOCATION" \
                &>/dev/null; then
                echo "  ✅ Successfully purged: $COG_NAME"
            else
                echo "  ⚠️  Failed to purge: $COG_NAME"
            fi
        done
    else
        echo "⏭️  Skipped Cognitive Services purge"
    fi
fi

echo ""

# ============================================================
# 5. ORPHANED RESOURCE GROUPS (RapidGo specific)
# ============================================================
echo "======================================================"
echo "🔍 5. RESOURCE GROUPS - Checking for orphaned RapidGo RGs..."
echo "======================================================"
echo ""

ORPHANED_RGS=$(az group list \
    --query "[?starts_with(name, 'rg-rapidgo-')].{name:name, location:location, state:properties.provisioningState}" \
    -o json 2>/dev/null || echo "[]")

RG_COUNT=$(echo "$ORPHANED_RGS" | jq '. | length')

if [ "$RG_COUNT" -eq 0 ]; then
    echo "✅ No orphaned RapidGo resource groups found"
else
    echo "Found $RG_COUNT RapidGo resource group(s):"
    echo "$ORPHANED_RGS" | jq -r '.[] | "  - \(.name) in \(.location) (state: \(.state))"'
    echo ""

    read -p "❓ Delete ALL these resource groups? (yes/no): " CONFIRM_RG

    if [ "$CONFIRM_RG" = "yes" ]; then
        echo ""
        echo "$ORPHANED_RGS" | jq -c '.[]' | while read -r rg; do
            RG_NAME=$(echo "$rg" | jq -r '.name')

            echo "  🗑️  Deleting resource group: $RG_NAME..."

            if az group delete --name "$RG_NAME" --yes --no-wait &>/dev/null; then
                echo "  ✅ Deletion initiated: $RG_NAME"
            else
                echo "  ⚠️  Failed to delete: $RG_NAME"
            fi
        done

        echo ""
        echo "  ⚠️  Note: Resource group deletions run in background."
        echo "      Wait 5-10 minutes, then re-run this script to verify."
    else
        echo "⏭️  Skipped resource group cleanup"
    fi
fi

echo ""

# ============================================================
# SUMMARY
# ============================================================
echo "======================================================"
echo "✅ Purge process completed!"
echo "======================================================"
echo ""
echo "Summary:"
echo "  - Total resources found: $TOTAL_FOUND"
echo ""

if [ "$TOTAL_FOUND" -eq 0 ]; then
    echo "🎉 Your subscription is clean!"
    echo "   No soft-deleted resources blocking deployments."
else
    echo "⚠️  Important:"
    echo "   - Some purges may take a few minutes to process"
    echo "   - Wait 5-10 minutes before retrying deployment"
    echo "   - Re-run this script to verify all resources are purged"
fi

echo ""
echo "Next steps:"
echo "  1. Wait 5-10 minutes for Azure to process deletions"
echo "  2. Retry deployment: git push origin develop"
echo "  3. If issues persist, run this script again"
echo ""
echo "======================================================"
