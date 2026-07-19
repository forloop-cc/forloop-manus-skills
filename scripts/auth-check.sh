#!/usr/bin/env bash
#
# auth-check.sh — ForLoop CLI authentication check
#
# Verifies the authentication state and prints remediation guidance
# if the user is not authenticated.
#
# Usage:
#   ./scripts/auth-check.sh
#
# Exit codes:
#   0 = authenticated
#   1 = not authenticated
#   2 = forloop CLI not found

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if forloop CLI exists
if ! command -v forloop >/dev/null 2>&1; then
    echo -e "${RED}ForLoop CLI is not installed.${NC}"
    echo ""
    echo "Installation:"
    echo "  npm install -g @forloop-cc/forloop-cli"
    echo ""
    echo "Run preflight.sh for a full environment check."
    exit 2
fi

echo "============================================"
echo " ForLoop Authentication Check"
echo "============================================"
echo ""

AUTH_OUTPUT=$(forloop auth status 2>&1) || true

if echo "$AUTH_OUTPUT" | grep -qi "not authenticated"; then
    echo -e "Status: ${RED}Not authenticated${NC}"
    echo ""
    echo "To authenticate with ForLoop:"
    echo ""
    echo "  1. Get your API token:"
    echo "     https://forloop.cc/profile?tab=api-tokens"
    echo ""
    echo "  2. Create a token with these scopes:"
    echo "     - sprint:read"
    echo "     - sprint:write"
    echo "     - story:read"
    echo "     - story:write"
    echo "     - agent:query"
    echo "     - profile:read"
    echo ""
    echo "  3. Authenticate:"
    echo "     forloop auth login --api-key floop_xxxxx"
    echo ""
    echo "  Note: Never share your token. It starts with 'floop_'."
    echo ""
    exit 1
else
    echo -e "Status: ${GREEN}Authenticated${NC}"
    echo ""
    echo "$AUTH_OUTPUT" | head -5
    echo ""
    echo "You're ready to use the ForLoop CLI for planning."
    exit 0
fi
