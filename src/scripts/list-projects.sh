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

    # Check for Gitea integration
    PROJECT_PATH="/home/developer/code/tfgrid-ai-stack-projects/$PROJECT"
    if [ -f "$PROJECT_PATH/.agent/gitea.json" ]; then
        WEB_URL=$(jq -r '.web_url' "$PROJECT_PATH/.agent/gitea.json" 2>/dev/null)
        ORG=$(jq -r '.organization' "$PROJECT_PATH/.agent/gitea.json" 2>/dev/null)
        if [ -n "$WEB_URL" ]; then
            # Convert internal URL to nginx-proxied URL
            PUBLIC_URL=$(echo "$WEB_URL" | sed 's|http://localhost:3000|http://localhost/git|')
            echo "   🌐 Gitea: $PUBLIC_URL"
            echo "   🏢 Organization: $ORG"
        fi
    fi
    echo ""
done

echo "Commands:"
echo "  🚀 Start: tfgrid-compose run <project-name>"
echo "  🛑 Stop: tfgrid-compose stop <project-name>"
echo "  📊 Monitor: tfgrid-compose monitor <project-name>"
echo "  📝 Logs: tfgrid-compose logs <project-name>"