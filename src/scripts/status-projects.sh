#!/bin/bash
# status-projects.sh - Show status of all AI agent projects via systemd

set -e

PROJECTS_DIR="/home/developer/code/tfgrid-ai-stack-projects"

echo "📊 AI Agent Projects Status"
echo "=============================="
echo ""

# Get list of running projects from systemd
RUNNING_SERVICES=$(systemctl list-units 'tfgrid-ai-project@*.service' --no-legend --no-pager 2>/dev/null | \
                   awk '{print $1}' | \
                   sed 's/tfgrid-ai-project@\(.*\)\.service/\1/' || echo "")

# Get list of all project directories
ALL_PROJECTS=()
if [ -d "$PROJECTS_DIR" ]; then
    for project_dir in "$PROJECTS_DIR"/*; do
        if [ -d "$project_dir" ] && [ -d "$project_dir/.agent" ]; then
            ALL_PROJECTS+=("$(basename "$project_dir")")
        fi
    done
fi

if [ ${#ALL_PROJECTS[@]} -eq 0 ]; then
    echo "No projects found"
    echo ""
    echo "Create a project: tfgrid-compose create"
    exit 0
fi

# Show each project
for PROJECT in "${ALL_PROJECTS[@]}"; do
    PROJECT_PATH="$PROJECTS_DIR/$PROJECT"
    
    # Check if running
    if echo "$RUNNING_SERVICES" | grep -q "^${PROJECT}$"; then
        STATUS="🟢 Running"
        PID=$(systemctl show -p MainPID --value "tfgrid-ai-project@${PROJECT}.service" 2>/dev/null || echo "?")
        STARTED=$(systemctl show -p ActiveEnterTimestamp --value "tfgrid-ai-project@${PROJECT}.service" 2>/dev/null || echo "unknown")
    else
        STATUS="⭕ Stopped"
        PID="-"
        STARTED="-"
    fi
    
    # Get time constraint
    if [ -f "$PROJECT_PATH/.agent/time_log.txt" ]; then
        TIME_CONSTRAINT=$(grep "Time Constraint:" "$PROJECT_PATH/.agent/time_log.txt" | cut -d: -f2- | xargs)
    else
        TIME_CONSTRAINT="indefinite"
    fi
    
    # Get last commit
    if [ -d "$PROJECT_PATH/.git" ]; then
        cd "$PROJECT_PATH"
        LAST_COMMIT=$(git log -1 --format="%cr" 2>/dev/null || echo "no commits")
        cd - > /dev/null
    else
        LAST_COMMIT="no commits"
    fi
    
    # Print project info
    echo "📁 $PROJECT"
    echo "   $STATUS"
    if [ "$PID" != "-" ]; then
        echo "   🆔 PID: $PID"
        echo "   🕒 Started: $STARTED"
    fi
    echo "   ⏱️  Time limit: $TIME_CONSTRAINT"
    echo "   📝 Last commit: $LAST_COMMIT"
    echo ""
done

echo "Commands:"
echo "  🚀 Start: tfgrid-compose run <project-name>"
echo "  🛑 Stop: tfgrid-compose stop <project-name>"
echo "  📊 Monitor: tfgrid-compose monitor <project-name>"
echo "  📝 Logs: tfgrid-compose logs <project-name>"
