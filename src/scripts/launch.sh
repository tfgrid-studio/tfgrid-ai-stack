#!/usr/bin/env bash
# Launch script - Open tfgrid-ai-stack web interface in browser
# This runs on the local machine after deployment

set -e

echo "🚀 Launching tfgrid-ai-stack web interface..."

# Get deployment info from environment or tfgrid-compose
if [ -n "${PRIMARY_IP:-}" ]; then
    WIREGUARD_URL="http://${PRIMARY_IP}/git/"
elif [ -n "${TFGRID_WIREGUARD_IP:-}" ]; then
    WIREGUARD_URL="http://${TFGRID_WIREGUARD_IP}/git/"
fi

if [ -n "${TFGRID_MYCELIUM_IP:-}" ]; then
    MYCELIUM_URL="http://[${TFGRID_MYCELIUM_IP}]/git/"
fi

# Prefer WireGuard URL, fallback to Mycelium
if [ -n "${WIREGUARD_URL:-}" ]; then
    APP_URL="$WIREGUARD_URL"
elif [ -n "${MYCELIUM_URL:-}" ]; then
    APP_URL="$MYCELIUM_URL"
else
    echo "❌ Could not determine application URL"
    echo "   Make sure you're running this from tfgrid-compose"
    exit 1
fi

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