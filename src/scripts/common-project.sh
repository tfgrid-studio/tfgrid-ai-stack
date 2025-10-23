#!/bin/bash
# common-project.sh - Common functions for project management
# Source this file in project management scripts

# Function to find a project by name in the workspace
# Usage: find_project_path "project-name"
# Returns: Full path to project directory, or empty if not found
find_project_path() {
    local project_name="$1"
    local workspace_base="${PROJECT_WORKSPACE:-/home/developer/code}"
    
    # Search for project with .agent directory
    local project_path=$(find "$workspace_base" -maxdepth 4 -type d -name ".agent" 2>/dev/null | while read -r agent_dir; do
        local dir=$(dirname "$agent_dir")
        if [ "$(basename "$dir")" = "$project_name" ]; then
            echo "$dir"
            break
        fi
    done)
    
    echo "$project_path"
}

# Function to validate project exists
# Usage: validate_project "project-name"
# Returns: 0 if exists, 1 if not found
validate_project() {
    local project_name="$1"
    local project_path=$(find_project_path "$project_name")
    
    if [ -z "$project_path" ]; then
        echo "❌ Error: Project '$project_name' not found" >&2
        echo "" >&2
        echo "Available projects:" >&2
        list_projects_brief >&2
        return 1
    fi
    
    return 0
}

# Function to list projects briefly
list_projects_brief() {
    local workspace_base="${PROJECT_WORKSPACE:-/home/developer/code}"
    local found=false
    
    find "$workspace_base" -maxdepth 4 -type d -name ".agent" 2>/dev/null | while read -r agent_dir; do
        local dir=$(dirname "$agent_dir")
        local name=$(basename "$dir")
        echo "  - $name"
        found=true
    done
    
    if [ "$found" = false ]; then
        echo "  (no projects found)"
    fi
}

# Export functions
export -f find_project_path
export -f validate_project
export -f list_projects_brief
