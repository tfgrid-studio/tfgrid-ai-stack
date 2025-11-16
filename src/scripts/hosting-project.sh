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

# Function to initialize project cache
# Usage: init_project_cache "project-path"
# Creates .agent/project-cache.yaml with initial metadata
init_project_cache() {
    local project_path="$1"

    local cache_file="$project_path/.agent/project-cache.yaml"
    local project_name=$(basename "$project_path")

    # Detect project metadata
    local project_type=$(detect_project_type "$project_path")
    local organization=$(get_project_org "$project_path")
    local git_hash=$(cd "$project_path" && git rev-parse HEAD 2>/dev/null || echo "unknown")
    local file_count=$(find "$project_path/src" -type f 2>/dev/null | wc -l || echo "0")
    local analysis_time=$(date -u +%Y-%m-%dT%H:%M:%SZ +%3N)

    # Create cache structure
    cat > "$cache_file" << EOF
# Project metadata cache for tfgrid-ai-stack
# Generated: $analysis_time
# This file enables fast publishing by caching expensive analysis operations

project:
  name: "$project_name"
  type: "$project_type"
  organization: "$organization"
  path: "$project_path"

change_detection:
  git_hash: "$git_hash"
  analysis_time: "$analysis_time"
  file_count: $file_count

hosting:
  strategy: "$(determine_hosting_strategy "$project_type")"
  hostable: $(is_project_hostable "$project_path" >/dev/null 2>&1 && echo "true" || echo "false")
  last_published: null
  publish_count: 0

analysis:
  hostable_reasons: |
$(is_project_hostable "$project_path" 2>&1 || echo "Analysis pending")
EOF

    echo "✅ Project cache initialized: $cache_file"
}

# Function to determine hosting strategy based on project type
# Usage: determine_hosting_strategy "project-type"
determine_hosting_strategy() {
    local project_type="$1"

    case "$project_type" in
        "react"|"vue"|"nextjs"|"nuxt"|"static")
            echo "nginx-static"
            ;;
        "api")
            echo "nginx-proxy"
            ;;
        "built-static")
            echo "nginx-built-static"
            ;;
        "unknown"|"buildable")
            echo "nginx-generic"
            ;;
        *)
            echo "nginx-default"
            ;;
    esac
}

# Function to check if project cache is valid (not stale)
# Usage: is_cache_valid "project-path" "force-check"
# Returns: 0 if valid, 1 if needs refresh
is_cache_valid() {
    local project_path="$1"
    local force_check="${2:-false}"

    local cache_file="$project_path/.agent/project-cache.yaml"

    # If no cache exists or force check requested
    if [ ! -f "$cache_file" ] || [ "$force_check" = "true" ]; then
        return 1
    fi

    # Check if git hash changed
    local cached_hash=$(yq eval '.change_detection.git_hash // "unknown"' "$cache_file" 2>/dev/null || echo "unknown")
    local current_hash=$(cd "$project_path" && git rev-parse HEAD 2>/dev/null || echo "unknown")

    if [ "$cached_hash" != "$current_hash" ] && [ "$current_hash" != "unknown" ]; then
        return 1
    fi

    # Check if file count changed (indicates new files)
    local cached_count=$(yq eval '.change_detection.file_count // 0' "$cache_file" 2>/dev/null || echo "0")
    local current_count=$(find "$project_path/src" -type f 2>/dev/null | wc -l || echo "0")

    if [ "$cached_count" != "$current_count" ]; then
        return 1
    fi

    return 0
}

# Function to update project cache after publish
# Usage: update_cache_after_publish "project-path" "deployment-ip"
update_cache_after_publish() {
    local project_path="$1"
    local deployment_ip="$2"

    local cache_file="$project_path/.agent/project-cache.yaml"

    if [ ! -f "$cache_file" ]; then
        init_project_cache "$project_path"
        return
    fi

    # Update publish metadata
    local publish_time=$(date -u +%Y-%m-%dT%H:%M:%SZ +%3N)
    local current_count=$(yq eval '.hosting.publish_count // 0' "$cache_file" 2>/dev/null || echo "0")
    local new_count=$((current_count + 1))

    # Update cache with yq
    yq eval ".hosting.last_published = \"$publish_time\" | .hosting.publish_count = $new_count | .change_detection.analysis_time = \"$publish_time\"" "$cache_file" > "$cache_file.tmp" && mv "$cache_file.tmp" "$cache_file"

    echo "✅ Project cache updated after publish: $cache_file"
}

# Function to get cached project metadata
# Usage: get_cached_metadata "project-path" "field-path"
# Example: get_cached_metadata "/path/to/project" ".project.type"
get_cached_metadata() {
    local project_path="$1"
    local field_path="$2"

    local cache_file="$project_path/.agent/project-cache.yaml"

    if [ -f "$cache_file" ]; then
        yq eval "$field_path" "$cache_file" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Function to invalidate project cache (force refresh)
# Usage: invalidate_project_cache "project-path"
invalidate_project_cache() {
    local project_path="$1"
    local cache_file="$project_path/.agent/project-cache.yaml"

    if [ -f "$cache_file" ]; then
        rm "$cache_file"
        echo "✅ Project cache invalidated: $cache_file"
    fi
}

# Export functions
export -f detect_project_type
export -f get_project_org
export -f is_project_hostable
export -f get_project_hosting_status
export -f ensure_hosting_directories
export -f init_project_cache
export -f determine_hosting_strategy
export -f is_cache_valid
export -f update_cache_after_publish
export -f get_cached_metadata
export -f invalidate_project_cache
