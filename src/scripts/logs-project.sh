#!/bin/bash
# logs-project.sh - View project logs (systemd-aware)
# Part of the AI-Agent framework

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-project.sh"

PROJECT_NAME="$1"
LINES="${2:-50}"  # Default 50 lines

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
        echo "  2. Or: tfgrid-compose logs <project-name>"
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

echo "📋 Viewing logs for: $PROJECT_NAME"
echo "   Location: $PROJECT_PATH"
echo ""

# Check if project is running via systemd
if systemctl is-active --quiet "tfgrid-ai-project@${PROJECT_NAME}.service"; then
    PID=$(systemctl show -p MainPID --value "tfgrid-ai-project@${PROJECT_NAME}.service")
    echo "   Status: 🟢 Running (PID: $PID)"
else
    echo "   Status: ⭕ Stopped"
fi

echo "   Press Ctrl+C to exit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check what log files exist
OUTPUT_LOG="$PROJECT_PATH/agent-output.log"
ERROR_LOG="$PROJECT_PATH/agent-errors.log"

# Follow mode (live tail) - use the project's log files
if [ -f "$OUTPUT_LOG" ]; then
    tail -f -n "$LINES" "$OUTPUT_LOG"
else
    echo "⚠️  No output log found yet"
    echo "   Waiting for logs to appear..."
    # Wait for file to be created, then tail it
    while [ ! -f "$OUTPUT_LOG" ]; do
        sleep 1
    done
    tail -f -n "$LINES" "$OUTPUT_LOG"
fi
