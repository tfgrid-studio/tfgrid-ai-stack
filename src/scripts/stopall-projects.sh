#!/bin/bash
# stopall-projects.sh - Stop all running AI agent loops via systemd

set -e

echo "🛑 Stopping All AI Agent Loops"
echo "=============================="
echo ""

# Get list of running projects from systemd
RUNNING_SERVICES=$(systemctl list-units 'tfgrid-ai-project@*.service' --no-legend --no-pager 2>/dev/null | \
                   awk '{print $1}' | \
                   sed 's/tfgrid-ai-project@\(.*\)\.service/\1/' || echo "")

if [ -z "$RUNNING_SERVICES" ]; then
    echo "✅ No running projects found"
    exit 0
fi

# Count projects
PROJECT_COUNT=$(echo "$RUNNING_SERVICES" | wc -l)

# Display running projects
echo "Found $PROJECT_COUNT running project(s):"
echo ""
for PROJECT in $RUNNING_SERVICES; do
    echo "  - $PROJECT"
done
echo ""

# Confirm (skip in non-interactive mode)
if [ -t 0 ]; then
    read -p "Stop all projects? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "❌ Cancelled"
        exit 0
    fi
    echo ""
fi

echo "🛑 Stopping all projects..."
echo ""

# Stop each project via systemd
for PROJECT in $RUNNING_SERVICES; do
    echo "  Stopping: $PROJECT"
    if systemctl stop "tfgrid-ai-project@${PROJECT}.service" 2>/dev/null; then
        echo "    ✅ Stopped"
    else
        echo "    ❌ Failed to stop"
    fi
done

echo ""
echo "✅ All projects stopped"
