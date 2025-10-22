#!/usr/bin/env bash
# Launch script - Open tfgrid-ai-stack web interface in browser
# This runs on the local machine after deployment

set -e

echo "🚀 Launching tfgrid-ai-stack web interface..."

# Get deployment info from environment or tfgrid-compose
if [ -n "${PRIMARY_IP:-}" ]; then
    APP_URL="http://${PRIMARY_IP}/git/"
elif [ -n "${TFGRID_WIREGUARD_IP:-}" ]; then
    APP_URL="http://${TFGRID_WIREGUARD_IP}/git/"
elif [ -n "${TFGRID_MYCELIUM_IP:-}" ]; then
    APP_URL="http://[${TFGRID_MYCELIUM_IP}]/git/"
else
    echo "❌ Could not determine application URL"
    echo "   Make sure you're running this from tfgrid-compose"
    exit 1
fi

echo "🌐 Opening: $APP_URL"

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
    echo ""
    echo "👤 Login credentials:"
    echo "   Username: gitadmin"
    echo "   Password: changeme123"
fi

echo "✅ Browser launched (or URL displayed above)"