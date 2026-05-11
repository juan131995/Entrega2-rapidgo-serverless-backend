#!/bin/bash
set -euo pipefail

###############################################################################
# validate-apim-policies.sh
# Validates APIM policy XML files against known constraints
# Usage: ./scripts/validate-apim-policies.sh [policy-file.xml]
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

POLICY_FILE="${1:-$PROJECT_ROOT/src/infra-bicep/modules/apim-policy.xml}"

echo "=========================================="
echo "  APIM Policy Validation"
echo "=========================================="

if [ ! -f "$POLICY_FILE" ]; then
    echo "ERROR: Policy file not found at $POLICY_FILE"
    exit 1
fi

echo "Validating: $POLICY_FILE"
echo ""

ERRORS=0

# Check 1: XML well-formedness
echo "Check 1: XML well-formedness..."
if command -v xmllint &> /dev/null; then
    if xmllint --noout "$POLICY_FILE" 2>/dev/null; then
        echo "  PASS: XML is well-formed"
    else
        echo "  FAIL: XML is not well-formed"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "  SKIP: xmllint not installed (install with: brew install libxml2)"
fi

# Check 2: No <jwt-validate> (should be <validate-jwt>)
echo "Check 2: validate-jwt element name..."
if grep -q "jwt-validate" "$POLICY_FILE"; then
    echo "  FAIL: Found 'jwt-validate' - should be 'validate-jwt'"
    ERRORS=$((ERRORS + 1))
else
    echo "  PASS: No 'jwt-validate' found"
fi

# Check 3: validate-jwt exists and is correct
echo "Check 3: validate-jwt policy..."
if grep -q "validate-jwt" "$POLICY_FILE"; then
    echo "  PASS: validate-jwt element found"
else
    echo "  WARN: No validate-jwt policy found"
fi

# Check 4: No <base /> in global context (service-level)
echo "Check 4: base element scope..."
# This check is for service-level policies only
# API-level policies CAN have <base />
if grep -q "<base" "$POLICY_FILE"; then
    echo "  INFO: base element found (valid for API-level policies)"
fi

# Check 5: rate-limit element
echo "Check 5: rate-limit policy..."
if grep -q "rate-limit" "$POLICY_FILE"; then
    echo "  PASS: rate-limit element found"
else
    echo "  WARN: No rate-limit policy found"
fi

# Check 6: Required sections exist
echo "Check 6: Required policy sections..."
for section in "inbound" "backend" "outbound" "on-error"; do
    if grep -q "<$section>" "$POLICY_FILE"; then
        echo "  PASS: <$section> section found"
    else
        echo "  FAIL: Missing <$section> section"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check 7: Root element is <policies>
echo "Check 7: Root element..."
if head -1 "$POLICY_FILE" | grep -q "<policies>"; then
    echo "  PASS: Root element is <policies>"
else
    echo "  FAIL: Root element should be <policies>"
    ERRORS=$((ERRORS + 1))
fi

# Check 8: No deprecated policies
echo "Check 8: Deprecated policies..."
DEPRECATED_PATTERNS="cache-lookup-value|cache-store-value|set-variable"
for pattern in $DEPRECATED_PATTERNS; do
    if grep -q "$pattern" "$POLICY_FILE"; then
        echo "  INFO: Found '$pattern' (verify if intended)"
    fi
done

echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo "  All checks passed!"
else
    echo "  $ERRORS check(s) failed"
fi
echo "=========================================="

exit $ERRORS
