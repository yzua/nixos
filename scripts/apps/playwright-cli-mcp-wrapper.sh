#!/usr/bin/env bash
set -euo pipefail

export PLAYWRIGHT_MCP_BROWSER=chromium
export PLAYWRIGHT_MCP_EXECUTABLE_PATH=/run/current-system/sw/bin/chromium
exec "$HOME/.bun/bin/playwright-cli" "$@"
