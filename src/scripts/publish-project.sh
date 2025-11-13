#!/bin/bash
# publish-project.sh - AI-powered project publishing
# Calls Qwen AI agent to intelligently publish projects for web hosting

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-project.sh"
source "$SCRIPT_DIR/hosting-project.sh"

PROJECT_NAME="$1"

# If no argument OR if "publish" is passed as project name, use interactive mode
# Main function for script execution
main() {
    if [ -z "$PROJECT_NAME" ] || [ "$PROJECT_NAME" = "publish" ]; then
        # Interactive mode - prompt for project selection
        echo "📁 Select a project to publish:"
        echo ""
        
        # Get available projects
        mapfile -t projects < <(list_projects_brief)
        
        if [ ${#projects[@]} -eq 0 ]; then
            echo "No projects available to publish"
            echo ""
            echo "Create a project: tfgrid-compose create"
            exit 1
        fi
        
        # List projects with numbers
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
            exit 1
        fi
        
        if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#projects[@]} ]; then
            echo "❌ Invalid selection"
            exit 1
        fi
        
        # Get selected project name (remove the "- " prefix)
        PROJECT_NAME=$(echo "${projects[$((choice-1))]}" | sed 's/^- //')
    fi
}

echo "🤖 AI-Powered Project Publisher"
echo "=================================="
echo ""

# Check authentication FIRST
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

# Find project in workspace
PROJECT_PATH=$(find_project_path "$PROJECT_NAME")

if [ -z "$PROJECT_PATH" ]; then
    echo "❌ Error: Project '$PROJECT_NAME' not found"
    echo ""
    echo "Available projects:"
    list_projects_brief
    exit 1
fi

echo "📂 Project: $PROJECT_NAME"
echo "📁 Location: $PROJECT_PATH"
echo ""

# Get project organization (from git remote)
ORG_NAME=$(get_project_org "$PROJECT_PATH")
echo "🏢 Organization: $ORG_NAME"

# Check if project is hostable
if ! is_project_hostable "$PROJECT_PATH"; then
    echo "❌ Project is not hostable"
    exit 1
fi

echo "✅ Project is hostable"
echo ""

# Create AI agent context for publishing
cd "$PROJECT_PATH"

# Get deployment IP dynamically (like other scripts)
if [ -n "${PRIMARY_IP:-}" ]; then
    DEPLOYMENT_IP="${PRIMARY_IP}"
elif [ -n "${TFGRID_WIREGUARD_IP:-}" ]; then
    DEPLOYMENT_IP="${TFGRID_WIREGUARD_IP}"
else
    # Try to get from state file if available
    if [ -f "/tmp/app-deployment/state.yaml" ]; then
        DEPLOYMENT_IP=$(grep "^primary_ip:" /tmp/app-deployment/state.yaml 2>/dev/null | awk '{print $2}')
    fi
    if [ -z "$DEPLOYMENT_IP" ] && [ -f "/tmp/app-deployment/../state.yaml" ]; then
        DEPLOYMENT_IP=$(grep "^primary_ip:" /tmp/app-deployment/../state.yaml 2>/dev/null | awk '{print $2}')
    fi
fi

# Use publish prompt template
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../../../templates/generic"

# Create directory for agent files
mkdir -p "$PROJECT_PATH/.agent"

# Copy and enhance the publish prompt template
cp "$TEMPLATE_DIR/publish-prompt.md" "$PROJECT_PATH/.agent/publish-prompt.md"

# Add dynamic deployment context to the template
cat >> "$PROJECT_PATH/.agent/publish-prompt.md" << EOF

## Dynamic Deployment Context
- **Deployment IP**: ${DEPLOYMENT_IP:-127.0.0.1}
- **GIT_BASE_URL**: http://${DEPLOYMENT_IP:-127.0.0.1}/git
- **WEB_BASE_URL**: http://${DEPLOYMENT_IP:-127.0.0.1}
- **Project Path**: ${ORG_NAME}/${PROJECT_NAME}
- **Full Git URL**: http://${DEPLOYMENT_IP:-127.0.0.1}/git/${ORG_NAME}/${PROJECT_NAME}
- **Full Web URL**: http://${DEPLOYMENT_IP:-127.0.0.1}/web/${ORG_NAME}/${PROJECT_NAME}/

## Project Context
- **Project Name**: $PROJECT_NAME
- **Organization**: $ORG_NAME
- **Project Type**: $(detect_project_type "$PROJECT_PATH")

## Your Mission
1. **Check the Git repository** at: http://${DEPLOYMENT_IP:-127.0.0.1}/git/${ORG_NAME}/${PROJECT_NAME}
2. **Analyze the project** to determine hosting strategy
3. **Fetch project files** from the git repository
4. **Publish to web** at: http://${DEPLOYMENT_IP:-127.0.0.1}/web/${ORG_NAME}/${PROJECT_NAME}/
5. **Ensure both URLs work**: Git and Web access
EOF
- **Git URL**: http://${DEPLOYMENT_IP:-127.0.0.1}/git/$ORG_NAME/$PROJECT_NAME
- **Web URL**: http://${DEPLOYMENT_IP:-127.0.0.1}/web/$ORG_NAME/$PROJECT_NAME
- **Project Type**: $(detect_project_type "$PROJECT_PATH")
- **Hosting Method**: Nginx reverse proxy configuration

## Actions to Perform
1. Create or update nginx configuration for this project
2. Ensure nginx includes the project config
3. Test nginx configuration
4. Reload nginx if configuration is valid
5. Set proper file permissions for web access
6. Verify web hosting setup

## Context Files
- Use any existing project files in this directory
- Check .git/config for remote URL if needed
- Use nginx configuration templates if available

## Expected Output
Provide a clear summary of:
- What nginx configuration was created/updated
- The final URLs where the project is hosted
- Any permissions or issues that needed fixing
- Confirmation that web hosting is working

Begin the intelligent publishing process now.
EOF

# Start AI agent publishing process
echo "🚀 Starting AI agent publishing process..."
echo ""
echo "The AI agent will:"
echo "  1. Analyze project structure and organization"
echo "  2. Create intelligent nginx configuration" 
echo "  3. Set up proper web hosting"
echo "  4. Verify deployment success"
echo ""

# Call the AI agent to handle publishing directly
# We call qwen with the publish prompt for intelligent publishing
echo "🧠 Calling Qwen AI for intelligent publishing..."
echo ""

# Execute Qwen AI with the publish context using the new prompt
su - developer -c "cd '$PROJECT_PATH' && qwen --approval-mode yolo --sandbox false < '.agent/publish-prompt.md'"

# Ensure the project is properly placed for web hosting
echo "🔧 Ensuring proper web hosting directory structure..."

# Get the real organization from git config with fallback
REAL_ORG=$(su - developer -c "cd '$PROJECT_PATH' && git config --get remote.origin.url" 2>/dev/null | sed 's|.*://[^/]*/||' | sed 's|/$||' | cut -d'/' -f1 || echo "tfgrid-ai-agent")

# Sanitize organization name
REAL_ORG=$(echo "$REAL_ORG" | tr -cd 'a-zA-Z0-9-_')

# Validate organization name
if [ -z "$REAL_ORG" ] || [ "$REAL_ORG" = "default" ]; then
    REAL_ORG="tfgrid-ai-agent"
fi

echo "📂 Project Organization: $REAL_ORG"

# Create the proper directory structure for web hosting
WEB_HOSTING_DIR="/home/developer/code/tfgrid-ai-stack-projects/$REAL_ORG/$PROJECT_NAME"
sudo mkdir -p "$WEB_HOSTING_DIR/src"
sudo mkdir -p "$WEB_HOSTING_DIR/.agent"

# Copy project files to web hosting directory
if [ -d "$PROJECT_PATH/src" ]; then
    sudo cp -r "$PROJECT_PATH/src/"* "$WEB_HOSTING_DIR/src/" 2>/dev/null || true
fi

# Copy the publish prompt to the web hosting directory for AI reference
sudo cp "$PROJECT_PATH/.agent/publish-prompt.md" "$WEB_HOSTING_DIR/.agent/" 2>/dev/null || true

# Set proper permissions for web serving
sudo chmod -R 644 "$WEB_HOSTING_DIR/src/" 2>/dev/null || true
sudo chmod -R 755 "$WEB_HOSTING_DIR/" 2>/dev/null || true
sudo chown -R www-data:www-data "$WEB_HOSTING_DIR/" 2>/dev/null || true

# Test the web hosting
echo "🧪 Testing web hosting configuration..."
if sudo curl -s "http://localhost/web/$REAL_ORG/$PROJECT_NAME/" >/dev/null 2>&1; then
    echo "✅ Web hosting is working!"
    echo "   Project accessible at: http://SERVER_IP/web/$REAL_ORG/$PROJECT_NAME/"
else
    echo "⚠️  Web hosting test failed - may need nginx reload"
    # Reload nginx to ensure configuration is updated
    sudo systemctl reload nginx 2>/dev/null || true
    sleep 2
    if sudo curl -s "http://localhost/web/$REAL_ORG/$PROJECT_NAME/" >/dev/null 2>&1; then
        echo "✅ Web hosting working after nginx reload!"
    fi
fi

echo "✅ Web hosting directory structure prepared"
echo "   Project will be available at: http://${DEPLOYMENT_IP}/web/$REAL_ORG/$PROJECT_NAME/"
echo "   Gitea is still accessible at: http://${DEPLOYMENT_IP}/git/"

echo ""
echo "🎉 AI Agent publishing process completed!"
echo ""
echo "🌐 Your project should now be accessible at:"
echo "   Git:  http://${DEPLOYMENT_IP}/git/$ORG_NAME/$PROJECT_NAME"
echo "   Web:  http://${DEPLOYMENT_IP}/web/$ORG_NAME/$PROJECT_NAME"
echo ""
