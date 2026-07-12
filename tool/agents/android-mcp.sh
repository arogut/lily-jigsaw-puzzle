#!/bin/bash
# MCP wrapper for @mobilenext/mobile-mcp.
#
# WSL2 setup: the emulator runs on the Windows host. ADB traffic is forwarded
# via the WSL2 default gateway, so ANDROID_ADB_SERVER_ADDRESS is derived at
# runtime from the routing table. See README.md for full setup instructions.
#
# Required: ANDROID_HOME must be set (e.g. export ANDROID_HOME=~/Android/Sdk),
#           or the Android SDK must be at ~/Android/Sdk.
#           Node.js / npx must be on PATH (install via nvm or system package).

ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export ANDROID_HOME
export PATH="$PATH:$ANDROID_HOME/platform-tools"

# WSL2: resolve the Windows host IP from the default gateway.
if ip route &>/dev/null 2>&1; then
  export ANDROID_ADB_SERVER_ADDRESS
  ANDROID_ADB_SERVER_ADDRESS=$(ip route | grep default | awk '{print $3}')
  export ANDROID_ADB_SERVER_PORT=5037
fi

# Load nvm if npx is not already on PATH.
if ! command -v npx &>/dev/null && [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]; then
  # shellcheck source=/dev/null
  source "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
fi

exec npx -y @mobilenext/mobile-mcp@latest
