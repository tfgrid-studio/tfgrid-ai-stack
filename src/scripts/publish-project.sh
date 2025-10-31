#!/bin/bash
# publish-project.sh - Publish projects for web hosting
# Implements the gateway hosting functionality

set -e

# Source hosting functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-project.sh"
source "$SCRIPT_DIR/hosting-project.sh"

# Configuration
PROJECTS_DIR="${PROJECT_WORKSPACE:-/home/developer/code}/tfgrid-ai-stack-projects"
HOSTING_CONFIG_DIR="/etc/tfgrid-ai-stack/hosting"
PROJECT_HOSTING_CONFIG_DIR="/etc/tfgrid-ai-stack/projects"
NGINX_CONFIG_FILE="/etc/nginx/sites-available/ai-stack"
BACKUP_DIR="/tmp/ai-stack-nginx-backup"

# Function to log messages
log() {
    local level="$1"
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

# Function to backup nginx configuration
backup_nginx_config() {
    log "INFO" "Backing up nginx configuration..."
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp "$NGINX_CONFIG_FILE" "$BACKUP_DIR/ai-stack-backup-$(date +%s).conf"
    log "INFO" "Nginx configuration backed up"
}

# Function to restore nginx configuration from backup
restore_nginx_config() {
    local latest_backup=$(ls -t "$BACKUP_DIR"/ai-stack-backup-*.conf 2>/dev/null | head -1)
    
    if [ -n "$latest_backup" ] && [ -f "$latest_backup" ]; then
        log "ERROR" "Restoring nginx configuration from backup..."
        sudo cp "$latest_backup" "$NGINX_CONFIG_FILE"
        sudo nginx -t && sudo systemctl reload nginx
        log "INFO" "Nginx configuration restored"
        return 0
    else
        log "ERROR" "No backup found to restore"
        return 1
    fi
}

# Function to generate nginx location config for a project
generate_nginx_location() {
    local org_name="$1"
    local project_name="$2"
    local project_type="$3"
    local project_path="$4"
    
    case "$project_type" in
        "react"|"vue"|"nextjs"|"nuxt")
            echo "    # $project_name hosting - ${project_type} application"
            echo "    location ~ ^/web/$org_name/$project_name/ {"
            echo "        alias $project_path;"
            echo "        try_files \$uri \$uri/ /web/$org_name/$project_name/index.html;"
            echo ""
            echo "        # Cache static assets"
            echo "        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {"
            echo "            expires 1y;"
            echo "            add_header Cache-Control \"public, immutable\";"
            echo "        }"
            echo "    }"
            ;;
        "static"|"built-static")
            echo "    # $project_name hosting - static site"
            echo "    location ~ ^/web/$org_name/$project_name/ {"
            echo "        alias $project_path;"
            echo "        index index.html;"
            echo ""
            echo "        # Cache static files"
            echo "        location ~* \.(html|htm|css|js|png|jpg|jpeg|gif|ico|svg)$ {"
            echo "            expires 1h;"
            echo "        }"
            echo "    }"
            ;;
        "api")
            echo "    # $project_name hosting - API server"
            echo "    location ~ ^/web/$org_name/$project_name/ {"
            echo "        proxy_pass http://localhost:3000/;"
            echo "        proxy_set_header Host \$host;"
            echo "        proxy_set_header X-Real-IP \$remote_addr;"
            echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
            echo "        proxy_set_header X-Forwarded-Proto \$scheme;"
            echo "        proxy_buffering off;"
            echo "    }"
            ;;
        "buildable")
            echo "    # $project_name hosting - buildable project"
            echo "    location ~ ^/web/$org_name/$project_name/ {"
            echo "        alias $project_path;"
            echo "        try_files \$uri \$uri/ /web/$org_name/$project_name/index.html;"
            echo "    }"
            ;;
        *)
            echo "    # $project_name hosting - fallback configuration"
            echo "    location ~ ^/web/$org_name/$project_name/ {"
            echo "        alias $project_path;"
            echo "        index index.html;"
            echo "    }"
            ;;
    esac
}

# Function to update nginx configuration with new project
update_nginx_config() {
    local org_name="$1"
    local project_name="$2"
    local project_type="$3"
    local project_path="$4"
    
    log "INFO" "Updating nginx configuration..."
    
    # Ensure nginx config directory exists
    ensure_hosting_directories
    
    # Generate the location block
    local location_config=$(generate_nginx_location "$org_name" "$project_name" "$project_type" "$project_path")
    
    # Create project-specific config file
    local config_file="$PROJECT_HOSTING_CONFIG_DIR/$org_name-$project_name.conf"
    echo "$location_config" | sudo tee "$config_file" > /dev/null
    
    # Backup current nginx config
    backup_nginx_config
    
    # Check if project config is already included in ai-stack config
    local include_statement="include $config_file;"
    
    if ! grep -q "$include_statement" "$NGINX_CONFIG_FILE"; then
        # Add include statement to the server block
        # Find the location of the existing project routing and add our config after it
        local insertion_point=$(grep -n "EXISTING PROJECT ROUTING" "$NGINX_CONFIG_FILE" | cut -d: -f1)
        
        if [ -n "$insertion_point" ]; then
            # Insert after the existing project routing
            local line_after_insertion=$((insertion_point + 10)) # Adjust based on the number of lines in the existing routing
            sudo sed -i "${line_after_insertion}i\\$include_statement" "$NGINX_CONFIG_FILE"
        else
            # Add before the closing brace
            sudo sed -i "/location ~ \^\\/project/ a\\$include_statement" "$NGINX_CONFIG_FILE"
        fi
    fi
    
    # Test nginx configuration
    if sudo nginx -t; then
        log "INFO" "Nginx configuration test passed"
        sudo systemctl reload nginx
        log "INFO" "Nginx reloaded successfully"
    else
        log "ERROR" "Nginx configuration test failed, restoring backup"
        restore_nginx_config
        return 1
    fi
    
    log "INFO" "Nginx configuration updated successfully"
    return 0
}

# Function to build project if needed
build_project() {
    local project_path="$1"
    local project_type="$2"
    
    log "INFO" "Building project (type: $project_type)..."
    
    case "$project_type" in
        "react"|"vue"|"nextjs"|"nuxt")
            if [ -f "$project_path/package.json" ]; then
                cd "$project_path"
                
                # Check if node_modules exists
                if [ ! -d "$project_path/node_modules" ]; then
                    log "INFO" "Installing dependencies..."
                    npm install
                fi
                
                # Build the project
                log "INFO" "Running build command..."
                if npm run build; then
                    log "INFO" "Build completed successfully"
                    echo "success" > "$project_path/.hosting/build-status"
                else
                    log "ERROR" "Build failed"
                    echo "failed" > "$project_path/.hosting/build-status"
                    return 1
                fi
            else
                log "WARNING" "No package.json found, skipping build"
            fi
            ;;
        "static"|"built-static")
            log "INFO" "Static site - no build needed"
            echo "static" > "$project_path/.hosting/build-status"
            ;;
        "api")
            log "INFO" "API project - manual server startup required"
            echo "api" > "$project_path/.hosting/build-status"
            ;;
        *)
            log "INFO" "Unknown project type - no build performed"
            echo "manual" > "$project_path/.hosting/build-status"
            ;;
    esac
    
    return 0
}

# Function to get available projects from AI Agent API
get_available_projects() {
    local api_response
    
    echo "Fetching available projects..." >&2
    api_response=$(curl -s http://localhost:8080/api/projects 2>/dev/null || echo "")
    
    if [ -z "$api_response" ] || echo "$api_response" | grep -q '"error"'; then
        echo "No projects found or AI Agent not responding" >&2
        return 1
    fi
    
    # Parse JSON response to extract project names
    echo "$api_response" | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"$//'
}

# Function for interactive project selection
interactive_select_project() {
    echo ""
    echo "📁 Select a project to publish:"
    echo ""
    
    # Get available projects
    mapfile -t projects < <(get_available_projects)
    
    if [ ${#projects[@]} -eq 0 ]; then
        echo "No projects available to publish"
        echo ""
        echo "Create a project: tfgrid-compose create"
        return 1
    fi
    
    # List projects with numbers
    local i=1
    for project in "${projects[@]}"; do
        echo "  $i) $project"
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
    
    selected_project="${projects[$((choice-1))]}"
    echo "$selected_project"
    return 0
}

# Function to publish a project
publish_project() {
    local project_name="$1"
    
    if [ -z "$project_name" ]; then
        # Interactive mode - prompt for project selection
        project_name=$(interactive_select_project)
        if [ $? -ne 0 ]; then
            return 1
        fi
        echo ""
        echo "📤 Selected project: $project_name"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
    
    log "INFO" "Starting publish process for project: $project_name"
    
    # Validate project exists
    local project_path=$(find_project_path "$project_name")
    if [ -z "$project_path" ]; then
        log "ERROR" "Project '$project_name' not found"
        return 1
    fi
    
    log "INFO" "Project found at: $project_path"
    
    # Get project information
    local org_name=$(get_project_org "$project_path")
    local project_type=$(detect_project_type "$project_path")
    
    log "INFO" "Organization: $org_name"
    log "INFO" "Project type: $project_type"
    
    # Check if project is hostable
    if ! is_project_hostable "$project_path"; then
        log "ERROR" "Project is not hostable"
        return 1
    fi
    
    # Create hosting directory
    mkdir -p "$project_path/.hosting"
    
    # Build project if needed
    if ! build_project "$project_path" "$project_type"; then
        log "ERROR" "Project build failed"
        return 1
    fi
    
    # Update nginx configuration
    if ! update_nginx_config "$org_name" "$project_name" "$project_type" "$project_path"; then
        log "ERROR" "Failed to update nginx configuration"
        return 1
    fi
    
    # Record publish time
    echo "$(date)" > "$project_path/.hosting/published-at"
    
    # Success!
    local server_ip=$(hostname -I | cut -d' ' -f1)
    
    echo ""
    echo "🎉 Project published successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📂 Project: $project_name"
    echo "🏢 Organization: $org_name"
    echo "🔧 Type: $project_type"
    echo "📅 Published: $(date)"
    echo ""
    echo "🌐 Access URLs:"
    echo "   Git: http://$server_ip/git/$org_name/$project_name"
    echo "   Web: http://$server_ip/web/$org_name/$project_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    return 0
}

# Function to unpublish a project
unpublish_project() {
    local project_name="$1"
    
    if [ -z "$project_name" ]; then
        echo "❌ Error: Project name is required"
        echo "Usage: t unpublish <project-name>"
        return 1
    fi
    
    log "INFO" "Starting unpublish process for project: $project_name"
    
    # Validate project exists
    local project_path=$(find_project_path "$project_name")
    if [ -z "$project_path" ]; then
        log "ERROR" "Project '$project_name' not found"
        return 1
    fi
    
    # Get project information
    local org_name=$(get_project_org "$project_path")
    local config_file="$PROJECT_HOSTING_CONFIG_DIR/$org_name-$project_name.conf"
    
    # Check if project is actually hosted
    if [ ! -f "$config_file" ]; then
        log "WARNING" "Project '$project_name' is not currently hosted"
        return 1
    fi
    
    # Backup nginx config
    backup_nginx_config
    
    # Remove project config file
    sudo rm -f "$config_file"
    log "INFO" "Removed project configuration file"
    
    # Remove include statement from nginx config
    local include_statement="include $config_file;"
    if grep -q "$include_statement" "$NGINX_CONFIG_FILE"; then
        sudo sed -i "/$include_statement/d" "$NGINX_CONFIG_FILE"
        log "INFO" "Removed nginx include statement"
    fi
    
    # Test and reload nginx
    if sudo nginx -t; then
        sudo systemctl reload nginx
        log "INFO" "Nginx reloaded successfully"
    else
        log "ERROR" "Nginx configuration test failed, restoring backup"
        restore_nginx_config
        return 1
    fi
    
    # Remove hosting metadata
    rm -rf "$project_path/.hosting"
    
    echo ""
    echo "🗑️  Project unpublished successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📂 Project: $project_name"
    echo "🏢 Organization: $org_name"
    echo "📅 Unpublished: $(date)"
    echo ""
    echo "🔗 Git access still available:"
    echo "   http://$(hostname -I | cut -d' ' -f1)/git/$org_name/$project_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    return 0
}

# Main script logic
case "${1:-}" in
    "publish")
        shift
        publish_project "$@"
        ;;
    "unpublish")
        shift
        unpublish_project "$@"
        ;;
    "status")
        shift
        if [ -n "$1" ]; then
            get_project_hosting_status "$1"
        else
            echo "❌ Error: Project name required"
            echo "Usage: t hosting status <project-name>"
        fi
        ;;
    *)
        echo "Gateway Hosting Management"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Usage: t <command> [project-name]"
        echo ""
        echo "Commands:"
        echo "  publish [name]     - Publish project for web hosting (interactive if no name)"
        echo "  unpublish <name>   - Remove project from web hosting"
        echo "  status <name>      - Show hosting status"
        echo ""
        echo "Examples:"
        echo "  t publish          - Interactive mode (prompts for project)"
        echo "  t publish mathweb  - Non-interactive mode"
        echo "  t unpublish mathweb"
        echo "  t status mathweb"
        ;;
esac