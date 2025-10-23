#!/usr/bin/env bash
# Launch script - Open tfgrid-ai-stack web interface in browser
# This runs on the local machine after deployment

set -e

echo "🚀 Launching tfgrid-ai-stack web interface..."

# Get IP from argument, environment, or try to detect
DETECTED_IP="${1:-}"

# Try environment variables first
if [ -n "${PRIMARY_IP:-}" ]; then
    DETECTED_IP="${PRIMARY_IP}"
elif [ -n "${TFGRID_WIREGUARD_IP:-}" ]; then
    DETECTED_IP="${TFGRID_WIREGUARD_IP}"
fi

# Try to detect from SSH connection if running on VM
if [ -z "$DETECTED_IP" ] && [ -n "${SSH_CONNECTION:-}" ]; then
    # Extract client IP from SSH_CONNECTION (format: client_ip client_port server_ip server_port)
    DETECTED_IP=$(echo $SSH_CONNECTION | awk '{print $3}')
fi

# Fallback to localhost if still not found
if [ -z "$DETECTED_IP" ]; then
    echo "ℹ️  No IP provided, using localhost"
    DETECTED_IP="localhost"
fi

# Build URLs
WIREGUARD_URL="http://${DETECTED_IP}/git/"

if [ -n "${TFGRID_MYCELIUM_IP:-}" ]; then
    MYCELIUM_URL="http://[${TFGRID_MYCELIUM_IP}]/git/"
fi

# Use primary URL
APP_URL="$WIREGUARD_URL"

echo "🌐 Opening: $APP_URL"
echo ""
echo "📋 Available URLs:"
if [ -n "${WIREGUARD_URL:-}" ]; then
    echo "   • WireGuard: $WIREGUARD_URL"
fi
if [ -n "${MYCELIUM_URL:-}" ]; then
    echo "   • Mycelium:  $MYCELIUM_URL"
fi
echo ""
echo "🔗 Additional services:"
if [ -n "${PRIMARY_IP:-}" ] || [ -n "${TFGRID_WIREGUARD_IP:-}" ]; then
    BASE_IP="${PRIMARY_IP:-${TFGRID_WIREGUARD_IP}}"
    echo "   • AI Agent API: http://$BASE_IP/api/"
fi
if [ -n "${TFGRID_MYCELIUM_IP:-}" ]; then
    echo "   • AI Agent API (Mycelium): http://[${TFGRID_MYCELIUM_IP}]/api/"
fi
echo ""
echo "👤 Gitea Login Credentials:"
echo "   Username: gitadmin"
echo "   Password: changeme123"
echo "   ⚠️  Change password after first login!"
echo ""

# Try different browser commands
if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$APP_URL" 2>/dev/null &
elif command -v open >/dev/null 2>&1; then
    open "$APP_URL" 2>/dev/null &
elif command -v start >/dev/null 2>&1; then
    start "$APP_URL" 2>/dev/null &
else
    echo "📋 Copy this URL to your browser:"
    echo "   $APP_URL"
fi

echo "✅ Browser launched (or URL displayed above)"