#!/usr/bin/env bash
# Launches the Human Protein Atlas MCP server over stdio.
# Clones and builds a pinned commit on first run, then reuses the cached build.
set -euo pipefail

REPO="https://github.com/Augmented-Nature/ProteinAtlas-MCP-Server.git"
COMMIT="830ae3674e9c7e448abb98b910f858cae2d82e2e"
DIR="${XDG_CACHE_HOME:-$HOME/.cache}/proteinatlas-mcp/$COMMIT"

if [ ! -f "$DIR/build/index.js" ]; then
  # stdout is the MCP channel, so send all setup output to stderr
  {
    rm -rf "$DIR"
    git clone --quiet "$REPO" "$DIR"
    git -C "$DIR" checkout --quiet "$COMMIT"
    (cd "$DIR" && npm ci --no-audit --no-fund && npm run build)
  } 1>&2
fi

# Behind an HTTPS proxy, axios's own proxy handling sends plain requests the
# proxy rejects (405). Disable it and let Node's built-in proxy support tunnel.
if [ -n "${HTTPS_PROXY:-${https_proxy:-}}" ]; then
  echo "import axios from 'axios'; axios.defaults.proxy = false;" > "$DIR/proxy-preload.mjs"
  export NODE_USE_ENV_PROXY=1
  exec node --no-warnings --import "$DIR/proxy-preload.mjs" "$DIR/build/index.js"
fi

exec node "$DIR/build/index.js"
