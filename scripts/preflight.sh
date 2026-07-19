#!/usr/bin/env bash
#
# preflight.sh — ForLoop CLI environment verification
#
# Checks for forloop CLI, node, npm, and jq. Installs forloop at runtime
# if missing and npm is available. Verifies installation and auth.
#
# Usage:
#   ./scripts/preflight.sh
#   source ./scripts/preflight.sh  # exports FORLOOP_READY/FORLOOP_JQ_AVAILABLE on success
#
# Exit codes:
#   0 = all checks passed, ready for CLI-backed planning
#   1 = forloop not installed and cannot be installed
#   2 = forloop installed but not authenticated
#       or a required command failed during preflight
#
# Notes:
#   - Missing jq is a warning, not a hard failure.
#   - When sourced, failure returns to the caller instead of exiting the shell.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS="${GREEN}✓${NC}"
FAIL="${RED}✗${NC}"
WARN="${YELLOW}!${NC}"

FORLOOP_READY=0
FORLOOP_JQ_AVAILABLE=0
NEEDS_AUTH=0
IS_SOURCED=0

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    IS_SOURCED=1
fi

finish() {
    local code="$1"
    if [ "$IS_SOURCED" -eq 1 ]; then
        return "$code"
    fi
    exit "$code"
}

echo "============================================"
echo " ForLoop CLI Preflight Check"
echo "============================================"
echo ""

# --- Step 1: Check forloop CLI ---
echo -n "Checking forloop CLI... "
if command -v forloop >/dev/null 2>&1; then
    FORLOOP_VERSION=$(forloop --version 2>/dev/null || echo "unknown")
    echo -e "${PASS} Found (${FORLOOP_VERSION})"
else
    echo -e "${FAIL} Not found"

    # --- Step 2: Check node ---
    echo -n "Checking Node.js... "
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version 2>/dev/null)
        echo -e "${PASS} Found (${NODE_VERSION})"
    else
        echo -e "${FAIL} Not found"
        echo ""
        echo "Node.js is required to install the ForLoop CLI."
        echo "Download from: https://nodejs.org/ (LTS version recommended)"
        echo ""
        echo -e "${RED}Preflight failed: cannot install ForLoop CLI without Node.js${NC}"
        finish 1
    fi

    # --- Step 3: Check npm ---
    echo -n "Checking npm... "
    if command -v npm >/dev/null 2>&1; then
        NPM_VERSION=$(npm --version 2>/dev/null)
        echo -e "${PASS} Found (v${NPM_VERSION})"
    else
        echo -e "${FAIL} Not found"
        echo ""
        echo "npm is required to install the ForLoop CLI."
        echo "It should come bundled with Node.js. Reinstall Node.js if npm is missing."
        echo ""
        echo -e "${RED}Preflight failed: cannot install ForLoop CLI without npm${NC}"
        finish 1
    fi

    # --- Step 4: Install forloop ---
    echo ""
    echo "Installing @forloop-cc/forloop-cli..."
    if npm install -g @forloop-cc/forloop-cli 2>&1; then
        echo -e "${PASS} Installation successful"
    else
        echo -e "${FAIL} Installation failed"
        echo ""
        echo "Check your network connection and npm registry:"
        echo "  npm config get registry"
        echo "If behind a proxy, configure npm proxy settings."
        echo ""
        echo -e "${RED}Preflight failed: could not install ForLoop CLI${NC}"
        finish 1
    fi
fi

echo ""

# --- Step 5: Verify forloop works ---
echo -n "Verifying forloop --version... "
if FORLOOP_VERSION=$(forloop --version 2>/dev/null); then
    echo -e "${PASS} ${FORLOOP_VERSION}"
else
    echo -e "${FAIL} Command failed"
    finish 1
fi

# --- Step 6: Check jq ---
echo -n "Checking jq... "
if command -v jq >/dev/null 2>&1; then
    JQ_VERSION=$(jq --version 2>/dev/null)
    FORLOOP_JQ_AVAILABLE=1
    echo -e "${PASS} Found (${JQ_VERSION})"
else
    echo -e "${WARN} Not found"
    echo "  jq is recommended for parsing JSON CLI output."
    echo "  Without it, results must be parsed manually."
fi

# --- Step 7: Check auth ---
echo -n "Checking auth status... "
AUTH_OUTPUT=$(forloop auth status 2>&1) || true
if echo "$AUTH_OUTPUT" | grep -qi "not authenticated"; then
    echo -e "${FAIL} Not authenticated"
    NEEDS_AUTH=1
else
    echo -e "${PASS} Authenticated"
fi

echo ""
echo "----------------------------------------"
if [ $NEEDS_AUTH -eq 1 ]; then
    echo -e "${YELLOW}Preflight: CLI is ready but authentication is required.${NC}"
    echo ""
    echo "To authenticate:"
    echo "  1. Get your token at https://forloop.cc/profile?tab=api-tokens"
    echo "  2. Run: forloop auth login --api-key floop_xxxxx"
    echo ""
    FORLOOP_READY=0
    export FORLOOP_READY
    export FORLOOP_JQ_AVAILABLE
    finish 2
else
    echo -e "${GREEN}Preflight passed: ForLoop CLI is ready.${NC}"
    FORLOOP_READY=1
fi
export FORLOOP_READY
export FORLOOP_JQ_AVAILABLE
echo "----------------------------------------"
