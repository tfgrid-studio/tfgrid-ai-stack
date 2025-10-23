#!/bin/bash
# AI-Agent Project Creator - API-based integration
# Calls the AI Agent API to create projects

set -e

echo "🚀 Creating AI project via API..."

# Get project name from arguments
PROJECT_NAME="$1"
if [ -z "$PROJECT_NAME" ]; then
    echo -n "Enter project name: "
    read -r PROJECT_NAME
fi

if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Project name is required"
    exit 1
fi

# Get project description
PROJECT_DESC="$2"
if [ -z "$PROJECT_DESC" ]; then
    echo -n "Enter project description (optional): "
    read -r PROJECT_DESC
fi

# Call AI Agent API to create project
echo "📡 Creating project via AI Agent API..."
RESPONSE=$(curl -s -X POST http://localhost:8080/api/projects \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$PROJECT_NAME\", \"description\": \"$PROJECT_DESC\"}")

# Check if request was successful
if echo "$RESPONSE" | grep -q '"project":'; then
    echo "✅ Project '$PROJECT_NAME' created successfully!"
    echo ""
    echo "📁 Project location: /opt/ai-agent/projects/$PROJECT_NAME"
    echo ""
    echo "🚀 Next steps:"
    echo "  • Run the project: tfgrid-compose run $PROJECT_NAME"
    echo "  • Monitor progress: tfgrid-compose monitor $PROJECT_NAME"
    echo "  • View in Gitea: http://your-ip/git/"
else
    echo "❌ Failed to create project"
    echo "Response: $RESPONSE"
    exit 1
fi
