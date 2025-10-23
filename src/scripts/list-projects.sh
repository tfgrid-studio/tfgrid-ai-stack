#!/bin/bash
# list-projects.sh - Show status of all AI agent projects via API

set -e

echo "📊 AI Agent Projects Status"
echo "=============================="
echo ""

# Call AI Agent API to list projects
RESPONSE=$(curl -s http://localhost:8080/api/projects 2>/dev/null || echo "")

if [ -z "$RESPONSE" ] || echo "$RESPONSE" | grep -q '"error"'; then
    echo "No projects found or AI Agent not responding"
    echo ""
    echo "Create a project: tfgrid-compose create"
    exit 0
fi

# Parse JSON response (simple approach)
echo "$RESPONSE" | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"$//' | while read -r PROJECT; do
    echo "📁 $PROJECT"
    echo "   Status: Available"
    echo ""
done

echo "Commands:"
echo "  🚀 Start: tfgrid-compose run <project-name>"
echo "  🛑 Stop: tfgrid-compose stop <project-name>"
echo "  📊 Monitor: tfgrid-compose monitor <project-name>"
echo "  📝 Logs: tfgrid-compose logs <project-name>"