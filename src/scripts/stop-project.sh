#!/bin/bash
# stop-project.sh - Stop AI agent loop via systemd service

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-project.sh"

PROJECT_NAME="$1"

# If no argument, try to get from context
if [ -z "$PROJECT_NAME" ]; then
    CONTEXT_FILE="$HOME/.config/tfgrid-compose/context.yaml"
    
    if [ -f "$CONTEXT_FILE" ]; then
        PROJECT_NAME=$(grep "^active_project:" "$CONTEXT_FILE" 2>/dev/null | awk '{print $2}')
    fi
    
    if [ -z "$PROJECT_NAME" ]; then
        echo "❌ No project specified and no project selected"
        echo ""
        echo "Either:"
        echo "  1. Run: tfgrid-compose select-project"
        echo "  2. Or: tfgrid-compose stop <project-name>"
        exit 1
    fi
fi

echo "🛑 Stopping AI agent loop for project: $PROJECT_NAME"
echo ""

# Check if running
if ! systemctl is-active --quiet "tfgrid-ai-project@${PROJECT_NAME}.service"; then
    echo "⚠️  Project is not running"
    exit 0
fi

# Stop via systemd
if systemctl stop "tfgrid-ai-project@${PROJECT_NAME}.service" 2>/dev/null; then
    echo "✅ AI agent loop stopped for: $PROJECT_NAME"
else
    echo "❌ Failed to stop service"
    echo ""
    echo "Check status with: systemctl status tfgrid-ai-project@${PROJECT_NAME}.service"
    exit 1
fi

# Also create STOP file as backup signal
AGENT_DIR="$PROJECT_PATH/.agent"
mkdir -p "$AGENT_DIR"
touch "$AGENT_DIR/STOP"

echo "✅ Stop signal sent to project: $PROJECT_NAME"
echo ""
echo "📊 Check status: tfgrid-compose projects"