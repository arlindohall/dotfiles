#!/bin/bash
# claude mcp help
# Usage: claude mcp add [options] <name> <commandOrUrl> [args...]
#
# Add a server
#
# Options:
#   -s, --scope <scope>          Configuration scope (local, user, or project) (default: "local")
#   -t, --transport <transport>  Transport type (stdio, sse, http) (default: "stdio")
#   -e, --env <env...>           Set environment variables (e.g. -e KEY=value)
#   -H, --header <header...>     Set WebSocket headers (e.g. -H "X-Api-Key: abc123" -H "X-Custom: value")
#   -h, --help                   Display help for command

claude_command="claude"
while [[ $# -gt 0 ]]; do
  case "$1" in
  --claude-command)
    shift
    claude_command="$1"
    shift
    ;;
  *)
    echo "Unknown arg $1"
    shift
    ;;
  esac
done

. "$HOME/bin/.claude-env"

if ! test "$VAULT_API_TOKEN"; then
  echo "VAULT_API_TOKEN is not set"
  exit 1
fi
if ! test "$OBSERVE_API_TOKEN"; then
  echo "OBSERVE_API_TOKEN is not set"
  exit 1
fi

echo "VAULT_API_TOKEN: $VAULT_API_TOKEN"
echo "OBSERVE_API_TOKEN: $OBSERVE_API_TOKEN"

$claude_command mcp add \
  vault \
  /opt/homebrew/bin/uvx shopify-mcp-bridge \
  --transport stdio \
  --env MCP_TARGET_URL="https://vault.shopify.io/mcp" \
  --env MCP_API_TOKEN="$VAULT_API_TOKEN"

$claude_command mcp add \
  shopify-internal \
  /opt/dev/bin/devx mcp

$claude_command mcp add \
  observe-mcp \
  /opt/homebrew/bin/uvx shopify-mcp-bridge \
  --transport stdio \
  --env MCP_TARGET_URL="https://observe-ai.shopifycloud.com/mcp" \
  --env MCP_MINERVA_CLIENT_ID="$OBSERVE_API_TOKEN"
