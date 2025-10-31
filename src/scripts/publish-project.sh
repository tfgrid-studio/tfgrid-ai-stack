#!/bin/bash
# publish-project.sh - AI-powered project publishing
# Calls Qwen AI agent to intelligently publish projects for web hosting

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-project.sh"
source "$SCRIPT_DIR/hosting-project.sh"

PROJECT_NAME="$1"

# If no argument, interactive mode
if [ -z "$PROJECT_NAME" ]; then
    # Interactive mode - prompt for project selection
    echo "📁 Select a project to publish:"
    echo ""
    
    # Get available projects
    mapfile -t projects < <(list_projects_brief)
    
    if [ ${#projects[@]} -eq 0 ]; then
        echo "No projects available to publish"
        echo ""
        echo "Create a project: tfgrid-compose create"
        return 1
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
        return 1
    fi
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#projects[@]} ]; then
        echo "❌ Invalid selection"
        return 1
    fi
    
    # Get selected project name (remove the "- " prefix)
    PROJECT_NAME=$(echo "${projects[$((choice-1))]}" | sed 's/^- //')
fi

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

# Create publishing prompt for AI agent
cat > .agent/publish-prompt.md << EOF
# AI Agent Publishing Task

You are tasked with intelligently publishing this project for web hosting.

## Project Information
- **Project Name**: $PROJECT_NAME
- **Project Path**: $PROJECT_PATH
- **Organization**: $ORG_NAME
- **Project Type**: $(detect_project_type "$PROJECT_PATH")

## Your Mission
1. **Analyze the project structure** and determine optimal hosting configuration
2. **Detect the correct organization** from the project's Git remote URL
3. **Set up web hosting** by creating proper nginx configuration
4. **Ensure proper file permissions** for web access
5. **Create deployment URLs** for both Git and web access

## Specific Requirements
- **Organization**: Use "$ORG_NAME" (not "default")
- **Git URL**: http://10.1.3.2/git/$ORG_NAME/$PROJECT_NAME
- **Web URL**: http://10.1.3.2/web/$ORG_NAME/$PROJECT_NAME
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

# Execute Qwen AI with the publish context
su - developer -c "cd '$PROJECT_PATH' && qwen-code --approval-mode yolo --sandbox false --iterations 1 --prompt '.agent/publish-prompt.md'"

echo ""
echo "🎉 AI Agent publishing process completed!"
echo ""
echo "🌐 Your project should now be accessible at:"
echo "   Git:  http://10.1.3.2/git/$ORG_NAME/$PROJECT_NAME"
echo "   Web:  http://10.1.3.2/web/$ORG_NAME/$PROJECT_NAME"
echo ""