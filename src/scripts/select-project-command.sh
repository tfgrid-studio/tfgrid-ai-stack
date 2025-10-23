#!/bin/bash
# select-project-command.sh - Interactive project selector for tfgrid-compose
# Saves selection to context for use with other commands

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-project.sh"

PROJECTS_DIR="/home/developer/code/tfgrid-ai-stack-projects"

# Allow direct selection via argument
DIRECT_SELECT="$1"

if [ -n "$DIRECT_SELECT" ]; then
    # Direct selection mode
    PROJECT_PATH=$(find_project_path "$DIRECT_SELECT")
    
    if [ -z "$PROJECT_PATH" ]; then
        echo "❌ Error: Project '$DIRECT_SELECT' not found"
        echo ""
        echo "Available projects:"
        list_projects_brief
        exit 1
    fi
    
    # Output the project name (tfgrid-compose will save it to context)
    echo "$DIRECT_SELECT"
    exit 0
fi

# Interactive selection mode
echo ""
echo "📁 Select a project:"
echo ""

projects=()
i=1

# List all projects with their status
for project_dir in "$PROJECTS_DIR"/*; do
    if [ -d "$project_dir" ]; then
        project_name=$(basename "$project_dir")
        
        # Check if running via systemd
        if systemctl is-active --quiet "tfgrid-ai-project@${project_name}.service" 2>/dev/null; then
            status="🟢 Running"
        else
            status="⭕ Stopped"
        fi
        
        echo "  $i) $project_name ($status)"
        projects+=("$project_name")
        ((i++))
    fi
done

if [ ${#projects[@]} -eq 0 ]; then
    echo "  No projects found"
    echo ""
    echo "Create one with: tfgrid-compose create <project-name>"
    exit 1
fi

echo ""
read -p "Enter number [1-${#projects[@]}] or 'q' to quit: " choice

if [[ "$choice" == "q" ]] || [[ "$choice" == "Q" ]]; then
    exit 1
fi

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#projects[@]} ]; then
    echo "❌ Invalid selection"
    exit 1
fi

selected_project="${projects[$((choice-1))]}"

# Output the selected project name (tfgrid-compose will save it to context)
echo "$selected_project"
