#!/usr/bin/env bash
# Setup script - Deploy tfgrid-ai-stack components
# This runs after gateway pattern infrastructure is deployed

set -e

echo "🚀 Setting up tfgrid-ai-stack components..."

# Get gateway VM connection info
GATEWAY_IP="${PRIMARY_IP}"
GATEWAY_SSH_KEY="${SSH_KEY_PATH}"

# Deploy AI Agent component
echo "🤖 Deploying AI Agent..."
tfgrid-compose up tfgrid-ai-agent --pattern single-vm --name ai-agent-${DEPLOYMENT_NAME}

# Deploy Gitea component
echo "📦 Deploying Gitea..."
tfgrid-compose up tfgrid-gitea --pattern single-vm --name gitea-${DEPLOYMENT_NAME}

# Wait for components to be ready
echo "⏳ Waiting for components to initialize..."
sleep 30

echo "✅ Component deployment completed"