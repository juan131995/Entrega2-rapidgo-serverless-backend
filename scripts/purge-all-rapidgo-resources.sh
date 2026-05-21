#!/bin/bash
set -e

# =====================================================
# PURGE ALL RAPIDGO RESOURCES
# =====================================================
# This script removes ALL RapidGo resources including:
# - Resource Groups
# - Soft-deleted Key Vaults
# - Soft-deleted API Management instances
# - Orphaned Storage Accounts
#
# USE WITH CAUTION: This is destructive and irreversible
# =====================================================

echo "🔍 Starting comprehensive RapidGo resource cleanup..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =====================================================
# STEP 1: Delete all RapidGo Resource Groups
# =====================================================
echo "${YELLOW}[1/5] Checking for RapidGo Resource Groups...${NC}"

RGS=$(az group list --query "[?starts_with(name, 'rg-rapidgo')].name" -o tsv)

if [ -z "$RGS" ]; then
  echo "${GREEN}✅ No resource groups found${NC}"
else
  echo "${RED}Found resource groups:${NC}"
  echo "$RGS"
  echo ""

  for RG in $RGS; do
    echo "  🗑️  Deleting: $RG"
    az group delete --name "$RG" --yes --no-wait 2>/dev/null || echo "    ⚠️  Failed to delete $RG (may already be deleting)"
  done

  echo "${GREEN}✅ Deletion initiated for all resource groups${NC}"
  echo "   Note: Deletion happens asynchronously in the background"
fi

echo ""

# =====================================================
# STEP 2: Purge soft-deleted Key Vaults
# =====================================================
echo "${YELLOW}[2/5] Checking for soft-deleted Key Vaults...${NC}"

# Get all soft-deleted Key Vaults matching RapidGo patterns
KVS=$(az keyvault list-deleted --query "[?starts_with(name, 'rgkv') || starts_with(name, 'az-rapidgo')].{name:name, location:properties.location}" -o tsv 2>/dev/null || echo "")

if [ -z "$KVS" ]; then
  echo "${GREEN}✅ No soft-deleted Key Vaults found${NC}"
else
  echo "${RED}Found soft-deleted Key Vaults:${NC}"
  echo "$KVS"
  echo ""

  echo "$KVS" | while IFS=$'\t' read -r NAME LOCATION; do
    if [ ! -z "$NAME" ]; then
      echo "  🔥 Purging: $NAME (location: $LOCATION)"
      az keyvault purge --name "$NAME" --location "$LOCATION" 2>/dev/null || echo "    ⚠️  Failed to purge $NAME"
    fi
  done

  echo "${GREEN}✅ Key Vault purge completed${NC}"
fi

echo ""

# =====================================================
# STEP 3: Purge soft-deleted API Management instances
# =====================================================
echo "${YELLOW}[3/5] Checking for soft-deleted API Management instances...${NC}"

APIMS=$(az apim list-deleted --query "[?contains(name, 'rapidgo') || starts_with(name, 'rg-')].{name:name, location:location}" -o tsv 2>/dev/null || echo "")

if [ -z "$APIMS" ]; then
  echo "${GREEN}✅ No soft-deleted APIM instances found${NC}"
else
  echo "${RED}Found soft-deleted APIM instances:${NC}"
  echo "$APIMS"
  echo ""

  echo "$APIMS" | while IFS=$'\t' read -r NAME LOCATION; do
    if [ ! -z "$NAME" ]; then
      echo "  🔥 Purging: $NAME (location: $LOCATION)"
      az apim deletedservice purge --name "$NAME" --location "$LOCATION" 2>/dev/null || echo "    ⚠️  Failed to purge $NAME"
    fi
  done

  echo "${GREEN}✅ API Management purge completed${NC}"
fi

echo ""

# =====================================================
# STEP 4: Check for orphaned Storage Accounts
# =====================================================
echo "${YELLOW}[4/5] Checking for orphaned Storage Accounts...${NC}"

STORAGE=$(az storage account list --query "[?starts_with(name, 'rgf') || starts_with(name, 'rgb') || starts_with(name, 'rgc') || starts_with(name, 'azrapidgo')].{name:name, rg:resourceGroup, location:location}" -o tsv 2>/dev/null || echo "")

if [ -z "$STORAGE" ]; then
  echo "${GREEN}✅ No orphaned storage accounts found${NC}"
else
  echo "${YELLOW}Found storage accounts:${NC}"
  echo "$STORAGE"
  echo ""
  echo "  ℹ️  These should be deleted automatically with their resource groups"
  echo "  ℹ️  If they persist after RG deletion completes, delete manually with:"
  echo ""

  echo "$STORAGE" | while IFS=$'\t' read -r NAME RG LOCATION; do
    if [ ! -z "$NAME" ]; then
      echo "     az storage account delete --name $NAME --yes"
    fi
  done
fi

echo ""

# =====================================================
# STEP 5: Summary and verification
# =====================================================
echo "${YELLOW}[5/5] Verification...${NC}"
echo ""
echo "Waiting 10 seconds for Azure to process deletions..."
sleep 10

echo ""
echo "Current state:"
echo ""

echo "📦 Resource Groups:"
RG_COUNT=$(az group list --query "[?starts_with(name, 'rg-rapidgo')] | length(@)" -o tsv)
echo "   Found: $RG_COUNT"

echo ""
echo "🔑 Soft-deleted Key Vaults:"
KV_COUNT=$(az keyvault list-deleted --query "[?starts_with(name, 'rgkv') || starts_with(name, 'az-rapidgo')] | length(@)" -o tsv 2>/dev/null || echo "0")
echo "   Found: $KV_COUNT"

echo ""
echo "🌐 Soft-deleted APIM:"
APIM_COUNT=$(az apim list-deleted --query "[?contains(name, 'rapidgo') || starts_with(name, 'rg-')] | length(@)" -o tsv 2>/dev/null || echo "0")
echo "   Found: $APIM_COUNT"

echo ""
echo "${GREEN}════════════════════════════════════════════${NC}"
echo "${GREEN}✅ Cleanup process completed!${NC}"
echo "${GREEN}════════════════════════════════════════════${NC}"
echo ""

if [ "$RG_COUNT" -gt 0 ] || [ "$KV_COUNT" -gt 0 ] || [ "$APIM_COUNT" -gt 0 ]; then
  echo "${YELLOW}⚠️  Note: Some resources may still be deleting in the background.${NC}"
  echo "${YELLOW}   Wait 5-10 minutes and re-run this script to verify.${NC}"
  echo ""
  echo "To check deletion status:"
  echo "  az group list --query \"[?starts_with(name, 'rg-rapidgo')].{Name:name, State:properties.provisioningState}\" -o table"
else
  echo "${GREEN}🎉 All RapidGo resources have been cleaned up!${NC}"
  echo "${GREEN}   You can now deploy without conflicts.${NC}"
fi

echo ""
