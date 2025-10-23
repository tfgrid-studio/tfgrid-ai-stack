#!/bin/bash
# restart-project.sh - Restart AI agent loop for a project via systemd

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-project.sh"

PROJECT_NAME="$1"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name>"
    exit 1
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

echo "🔄 Restarting project: $PROJECT_NAME"
echo ""

# Use 'at now' to schedule the restart in a completely detached process
echo "systemctl restart tfgrid-ai-project@${PROJECT_NAME}.service" | at now 2>/dev/null

echo "✅ Project restart initiated"
echo "🔍 Project: $PROJECT_NAME"
echo ""
echo "📊 Monitor: tfgrid-compose monitor $PROJECT_NAME"
echo "📝 Logs: tfgrid-compose logs $PROJECT_NAME"
echo "📊 Check status: tfgrid-compose projects"
