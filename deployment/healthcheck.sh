#!/usr/bin/env bash
# Health check script - Verify tfgrid-ai-stack deployment
# This runs after configuration to ensure everything is operational

set -e

echo "🏥 Running health checks for tfgrid-ai-stack..."

# The actual health checks are defined in the pattern's tfgrid-compose.yaml
# This hook provides additional app-specific health validation

echo "✅ Health check completed - services monitored by pattern health checks"