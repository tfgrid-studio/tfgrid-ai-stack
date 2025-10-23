#!/bin/bash
# run-project.sh - Start AI agent loop via systemd service
# Uses systemd template service for reliable process management

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
        echo "  2. Or: tfgrid-compose run <project-name>"
        exit 1
    fi
fi

# Find project in workspace
PROJECT_PATH=$(find_project_path "$PROJECT_NAME")

if [ -z "$PROJECT_PATH" ]; then
    echo "❌ Error: Project '$PROJECT_NAME' not found"
    echo ""
    echo "Available projects:"
    list_projects_brief
    exit 1
fi

echo "🚀 Starting AI agent loop for project: $PROJECT_NAME"
echo "=============================================="
echo ""

# Check if qwen is authenticated first
echo "🔍 Checking Qwen authentication..."
if ! su - developer -c 'test -f ~/.qwen/settings.json' 2>/dev/null; then
    echo ""
    echo "⚠️  Qwen is not authenticated!"
    echo ""
    echo "Please authenticate first by running:"
    echo "  tfgrid-compose login"
    echo ""
    exit 1
fi

echo "✅ Qwen authenticated"
echo ""

# Check if already running
if systemctl is-active --quiet "tfgrid-ai-project@${PROJECT_NAME}.service"; then
    echo "⚠️  Project is already running"
    PID=$(systemctl show -p MainPID --value "tfgrid-ai-project@${PROJECT_NAME}.service")
    echo "🆔 PID: $PID"
    echo ""
    echo "📊 To monitor: tfgrid-compose monitor $PROJECT_NAME"
    echo "📝 To view logs: tfgrid-compose logs $PROJECT_NAME"
    echo "🛑 To stop: tfgrid-compose stop $PROJECT_NAME"
    exit 0
fi

# Start the systemd service directly
echo "🔧 Starting systemd service..."
if systemctl start "tfgrid-ai-project@${PROJECT_NAME}.service"; then
    echo "✅ AI agent service started successfully"
else
    echo "❌ Failed to start AI agent service"
    exit 1
fi

echo "🔍 Project: $PROJECT_NAME"
echo ""
echo "📝 Logs:"
echo "  - View with: tfgrid-compose logs $PROJECT_NAME"
echo "  - Or: journalctl -u tfgrid-ai-project@${PROJECT_NAME}.service -f"
echo ""
echo "🛑 To stop: tfgrid-compose stop $PROJECT_NAME"
echo "📊 To monitor: tfgrid-compose monitor $PROJECT_NAME"
echo "📊 Check status: tfgrid-compose projects"