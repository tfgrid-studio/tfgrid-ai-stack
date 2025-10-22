#!/usr/bin/env bash
# Health check script - Verify tfgrid-ai-stack components
# This runs after configuration to ensure all components are operational

set -e

echo "🏥 Running health checks for tfgrid-ai-stack components..."

# Check AI Agent component
echo "Checking AI Agent..."
if ! tfgrid-compose status ai-agent-${DEPLOYMENT_NAME} | grep -q "running"; then
    echo "❌ AI Agent is not running"
    exit 1
fi

# Check Gitea component
echo "Checking Gitea..."
if ! tfgrid-compose status gitea-${DEPLOYMENT_NAME} | grep -q "running"; then
    echo "❌ Gitea is not running"
    exit 1
fi

# Check gateway routing
echo "Checking gateway routing..."
if ! curl -f -s "http://${PRIMARY_IP}/git/" > /dev/null; then
    echo "❌ Gateway routing to Gitea failed"
    exit 1
fi

echo "✅ All components are healthy"