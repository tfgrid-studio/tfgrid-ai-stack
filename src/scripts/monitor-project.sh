#!/bin/bash
# monitor-project.sh - Monitor a project's agent loop output (systemd-aware)
# Part of the enhanced AI-Agent workflow

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
    
# If no argument, interactive mode - prompt for project selection
if [ -z "$PROJECT_NAME" ]; then
    # Get available projects
    mapfile -t projects < <(list_projects_brief)
    
    if [ ${#projects[@]} -eq 0 ]; then
        echo "❌ No projects available to monitor"
        echo ""
        echo "Create a project: tfgrid-compose create"
        exit 1
    fi
    
    # List projects with numbers
    echo "📁 Select a project to monitor:"
    echo ""
    local i=1
    for project in "${projects[@]}"; do
        # Remove the "- " prefix
        project_name=$(echo "$project" | sed 's/^- //')
        echo "  $i) $project_name"
        ((i++))
    done
    
    echo ""
    read -p "Enter number [1-${#projects[@]}] or 'q' to quit: " choice
    
    if [[ "$choice" == "q" ]] || [[ "$choice" == "Q" ]]; then
        exit 0
    fi
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#projects[@]} ]; then
        echo "❌ Invalid selection"
        exit 1
    fi
    
    # Get selected project name (remove the "- " prefix)
    PROJECT_NAME=$(echo "${projects[$((choice-1))]}" | sed 's/^- //')
fi
    if [ -z "$PROJECT_NAME" ]; then
        echo "❌ No project specified and no project selected"
        echo ""
        echo "Either:"
        echo "  1. Run: tfgrid-compose select-project"
        echo "  2. Or: tfgrid-compose monitor <project-name>"
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

echo "📊 Monitoring project: $PROJECT_NAME"
echo "==============================="

# Check systemd status
if systemctl is-active --quiet "tfgrid-ai-project@${PROJECT_NAME}.service"; then
    PID=$(systemctl show -p MainPID --value "tfgrid-ai-project@${PROJECT_NAME}.service")
    MEMORY=$(systemctl show -p MemoryCurrent --value "tfgrid-ai-project@${PROJECT_NAME}.service")
    MEMORY_MB=$((MEMORY / 1024 / 1024))
    echo "🟢 Status: Running (PID: $PID, Memory: ${MEMORY_MB}MB)"
else
    echo "⭕ Status: Stopped"
fi
echo ""

cd "$PROJECT_PATH"

if [ -f "agent-output.log" ]; then
    echo "📄 Recent output log entries:"
    tail -20 agent-output.log
    echo ""
fi

if [ -f "agent-errors.log" ]; then
    ERROR_COUNT=$(wc -l < agent-errors.log 2>/dev/null || echo "0")
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "⚠️  Error log entries ($ERROR_COUNT lines):"
        tail -10 agent-errors.log
        echo ""
    fi
fi

if [ -f ".agent/TODO.md" ]; then
    echo "📋 Current TODO status:"
    grep -A 5 "## Status" .agent/TODO.md | head -6
    echo ""
fi

echo "💾 Git status:"
git status --porcelain | wc -l | xargs -I {} echo "{} uncommitted changes"

echo "📈 Project directory size:"
du -sh . | cut -f1