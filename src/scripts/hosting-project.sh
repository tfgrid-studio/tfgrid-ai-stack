#!/bin/bash
# hosting-project.sh - Project hosting management functions
# Enhanced project management with web hosting capabilities

set -e

# Source common project functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-project.sh"

# Configuration
HOSTING_CONFIG_DIR="/etc/tfgrid-ai-stack/hosting"
PROJECT_HOSTING_CONFIG_DIR="/etc/tfgrid-ai-stack/projects"
NGINX_CONFIG_FILE="/etc/nginx/sites-available/ai-stack"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled/ai-stack"

# Function to ensure hosting config directories exist
ensure_hosting_directories() {
    sudo mkdir -p "$HOSTING_CONFIG_DIR"
    sudo mkdir -p "$PROJECT_HOSTING_CONFIG_DIR"
    sudo chmod 755 "$HOSTING_CONFIG_DIR"
    sudo chmod 755 "$PROJECT_HOSTING_CONFIG_DIR"
}

# Function to detect project type
# Usage: detect_project_type "project-path"
# Returns: project type (react, vue, static, api, unknown)
detect_project_type() {
    local project_path="$1"
    
    if [ ! -d "$project_path" ]; then
        echo "unknown"
        return 1
    fi
    
    # Check for package.json first
    if [ -f "$project_path/package.json" ]; then
        local package_json="$project_path/package.json"
        
        # Check for React
        if grep -q '"react"' "$package_json" 2>/dev/null || \
           grep -q '"react-dom"' "$package_json" 2>/dev/null || \
           grep -q 'react-router' "$package_json" 2>/dev/null; then
            echo "react"
            return 0
        fi
        
        # Check for Vue
        if grep -q '"vue"' "$package_json" 2>/dev/null || \
           grep -q '@vue' "$package_json" 2>/dev/null || \
           grep -q 'nuxt' "$package_json" 2>/dev/null; then
            echo "vue"
            return 0
        fi
        
        # Check for Next.js
        if grep -q '"next"' "$package_json" 2>/dev/null; then
            echo "nextjs"
            return 0
        fi
        
        # Check for Express API
        if grep -q '"express"' "$package_json" 2>/dev/null || \
           grep -q 'app.listen' "$project_path"/*.js 2>/dev/null || \
           [ -f "$project_path/index.js" ] && grep -q 'express' "$project_path/index.js" 2>/dev/null; then
            echo "api"
            return 0
        fi
        
        # Check for Nuxt.js
        if grep -q '"nuxt"' "$package_json" 2>/dev/null; then
            echo "nuxt"
            return 0
        fi
        
        # If it has scripts but no specific framework, assume it's a buildable project
        if grep -q '"build"' "$package_json" 2>/dev/null; then
            echo "buildable"
            return 0
        fi
    fi
    
    # Check for static HTML files
    if [ -f "$project_path/index.html" ] || \
       [ -f "$project_path/public/index.html" ]; then
        echo "static"
        return 0
    fi
    
    # Check for built dist/build folders (potential static sites)
    if [ -d "$project_path/dist" ] || [ -d "$project_path/build" ]; then
        echo "built-static"
        return 0
    fi
    
    # Check for Vue files
    if find "$project_path" -name "*.vue" -type f | head -1 | grep -q . 2>/dev/null; then
        echo "vue"
        return 0
    fi
    
    # If no specific type detected, check if it's a web project (has HTML, CSS, JS files)
    if find "$project_path" -type f \( -name "*.html" -o -name "*.css" -o -name "*.js" \) | head -1 | grep -q . 2>/dev/null; then
        echo "static"
        return 0
    fi
    
    echo "unknown"
    return 0
}

# Function to get project organization/owner
# Usage: get_project_org "project-path"
# Returns: organization name (defaults to "default")
get_project_org() {
    local project_path="$1"
    
    # Try to get from git remote if available
    if [ -d "$project_path/.git" ]; then
        local git_url=$(cd "$project_path" && git remote get-url origin 2>/dev/null || echo "")
        
        if [ -n "$git_url" ]; then
            # Extract org from Git URL patterns
            # Pattern 1: http://server/git/org/repo or http://server:port/git/org/repo
            if [[ "$git_url" =~ /git/([^/]+)/[^/]+$ ]]; then
                echo "${BASH_REMATCH[1]}"
                return 0
            # Pattern 2: GitHub HTTPS - https://github.com/org/repo
            elif [[ "$git_url" =~ github\.com[:/]([^/]+)/ ]]; then
                echo "${BASH_REMATCH[1]}"
                return 0
            # Pattern 3: GitHub SSH - git@github.com:org/repo
            elif [[ "$git_url" =~ git@github\.com:([^/]+)/ ]]; then
                echo "${BASH_REMATCH[1]}"
                return 0
            # Pattern 4: Generic git URL - extract second-to-last path component
            elif [[ "$git_url" =~ /([^/]+)/[^/]+\.git$ ]]; then
                echo "${BASH_REMATCH[1]}"
                return 0
            fi
        fi
    fi
    
    # Fallback to "default" org
    echo "default"
    return 0
}

# Function to check if project is hostable
# Usage: is_project_hostable "project-path"
# Returns: 0 if hostable, 1 if not
is_project_hostable() {
    local project_path="$1"
    local project_type=$(detect_project_type "$project_path")
    
    case "$project_type" in
        "react"|"vue"|"nextjs"|"nuxt"|"static"|"built-static")
            return 0
            ;;
        "api")
            echo "⚠️  API projects may require additional configuration for hosting"
            return 0
            ;;
        "unknown"|"buildable")
            echo "⚠️  Project type unclear, manual configuration may be required"
            return 0
            ;;
        *)
            echo "❌ Project type '$project_type' is not supported for hosting"
            return 1
            ;;
    esac
}

# Function to get hosting status for a project
# Usage: get_project_hosting_status "project-name"
# Returns: hosting status information
get_project_hosting_status() {
    local project_name="$1"
    local project_path=$(find_project_path "$project_name")
    
    if [ -z "$project_path" ]; then
        echo "❌ Project not found"
        return 1
    fi
    
    local org_name=$(get_project_org "$project_path")
    local project_type=$(detect_project_type "$project_path")
    local hosting_config="$PROJECT_HOSTING_CONFIG_DIR/$org_name-$project_name.conf"
    
    echo "📊 Project: $project_name"
    echo "🏢 Organization: $org_name"
    echo "🔧 Type: $project_type"
    
    if [ -f "$hosting_config" ]; then
        echo "🌐 Hosting: ENABLED"
        
        # Get build status if available
        if [ -f "$project_path/.hosting/build-status" ]; then
            local build_status=$(cat "$project_path/.hosting/build-status")
            echo "📦 Build Status: $build_status"
        fi
        
        # Get last publish time
        if [ -f "$hosting_config" ]; then
            local publish_time=$(stat -c %y "$hosting_config" | cut -d. -f1)
            echo "📅 Published: $publish_time"
        fi
        
        # Generate URLs
        echo ""
        echo "🔗 URLs:"
        echo "   Git: http://$(hostname -I | cut -d' ' -f1)/git/$org_name/$project_name"
        echo "   Web: http://$(hostname -I | cut -d' ' -f1)/web/$org_name/$project_name"
        
    else
        echo "🌐 Hosting: NOT ENABLED"
        echo ""
        echo "💡 To enable hosting: t publish $project_name"
    fi
    
    return 0
}

# Export functions
export -f detect_project_type
export -f get_project_org
export -f is_project_hostable
export -f get_project_hosting_status
export -f ensure_hosting_directories