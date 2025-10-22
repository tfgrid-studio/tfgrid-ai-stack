#!/usr/bin/env bash
# Configure script - Set up tfgrid-ai-stack services
# This runs after setup to configure services

set -e

echo "⚙️ Configuring tfgrid-ai-stack..."

# The actual service configuration is handled by the tfgrid-ai-stack pattern's Ansible playbooks
# This hook ensures app-specific configuration is complete

echo "✅ Configuration completed - services configured by pattern playbooks"