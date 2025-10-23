#!/usr/bin/env bash
# Health check script - Verify all services are running
# This runs after configuration to ensure everything is operational

set -e

echo "🏥 Running health checks for tfgrid-ai-stack services..."

VM_IP="${PRIMARY_IP}"
SSH_KEY_PATH="${SSH_KEY_PATH}"

# Check system services
echo "Checking system services..."
ssh -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no root@${VM_IP} << 'EOF'
# Check Docker
if ! systemctl is-active --quiet docker; then
    echo "❌ Docker is not running"
    exit 1
fi

# Check Nginx
if ! systemctl is-active --quiet nginx; then
    echo "❌ Nginx is not running"
    exit 1
fi

# Check Gitea
if ! systemctl is-active --quiet gitea; then
    echo "❌ Gitea is not running"
    exit 1
fi

echo "✅ System services are running"
EOF

# Check web endpoints
echo "Checking web endpoints..."
if ! curl -f -s -L "http://${VM_IP}/git/" > /dev/null; then
    echo "❌ Gitea web interface not accessible"
    exit 1
fi

if ! curl -f -s "http://${VM_IP}/api/health" > /dev/null; then
    echo "❌ AI Agent API not accessible"
    exit 1
fi

# Check systemd services
echo "Checking systemd services..."
if ! systemctl is-active --quiet gitea; then
    echo "❌ Gitea systemd service not running"
    exit 1
fi

if ! systemctl is-active --quiet ai-agent; then
    echo "❌ AI Agent systemd service not running"
    exit 1
fi

echo "✅ All services are healthy and accessible"