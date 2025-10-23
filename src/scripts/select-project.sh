#!/bin/bash
# select-project.sh - Reusable project selection helper
# Provides numbered list with smart selection (number, name, or default)

# Function to list and select a project
# Usage: select_project "prompt message" ["default_action"]
# Returns: Selected project name in PROJECT_NAME variable
select_project() {
    local prompt_msg="${1:-Select project}"
    local default_action="${2:-}"
    
    # Determine workspace base directory
    local workspace_base="${PROJECT_WORKSPACE:-/home/developer/code}"
    
    # Get list of projects across all git sources
    local projects=()
    while IFS= read -r project_dir; do
        if [ -d "$project_dir" ]; then
            local project_name=$(basename "$project_dir")
            if [ "$project_name" != "ai-agent" ]; then
                projects+=("$project_name")
            fi
        fi
    done < <(find "$workspace_base" -maxdepth 4 -name ".agent" -type d -exec dirname {} \;)
    
    # Check if any projects exist
    if [ ${#projects[@]} -eq 0 ]; then
        echo "❌ No projects found"
        echo ""
        echo "Create one with: make create"
        return 1
    fi
    
    # Show numbered list
    echo "Available projects:"
    for i in "${!projects[@]}"; do
        local num=$((i + 1))
        if [ $num -eq 1 ]; then
            echo "  $num. ${projects[$i]} [default]"
        else
            echo "  $num. ${projects[$i]}"
        fi
    done
    echo ""
    
    # Prompt for selection
    local selection
    if [ ${#projects[@]} -eq 1 ]; then
        read -p "$prompt_msg [${projects[0]}]: " selection
    else
        read -p "$prompt_msg (1-${#projects[@]}) or type name [1]: " selection
    fi
    
    # Handle default (empty input = first project)
    if [ -z "$selection" ]; then
        PROJECT_NAME="${projects[0]}"
        return 0
    fi
    
    # Check if input is a number
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        local idx=$((selection - 1))
        if [ $idx -ge 0 ] && [ $idx -lt ${#projects[@]} ]; then
            PROJECT_NAME="${projects[$idx]}"
            return 0
        else
            echo "❌ Invalid selection: $selection"
            return 1
        fi
    fi
    
    # Check if input is a valid project name
    for project in "${projects[@]}"; do
        if [ "$project" = "$selection" ]; then
            PROJECT_NAME="$selection"
            return 0
        fi
    done
    
    echo "❌ Project not found: $selection"
    return 1
}

# If script is run directly (for testing)
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    select_project "Select project"
    if [ $? -eq 0 ]; then
        echo "Selected: $PROJECT_NAME"
    fi
fi
