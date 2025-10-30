#!/bin/bash
# extend-nginx-config.sh - Extend existing ai-stack nginx configuration with hosting support
# This script modifies the existing nginx config to add /web/org/repo-name routing

set -e

NGINX_CONFIG_FILE="/etc/nginx/sites-available/ai-stack"
NGINX_BACKUP_DIR="/tmp/ai-stack-nginx-backup"

echo "🔧 Extending TFGrid AI Stack nginx configuration with hosting support..."

# Ensure backup directory exists
sudo mkdir -p "$NGINX_BACKUP_DIR"

# Backup current configuration
if [ -f "$NGINX_CONFIG_FILE" ]; then
    BACKUP_FILE="$NGINX_BACKUP_DIR/ai-stack-backup-$(date +%s).conf"
    sudo cp "$NGINX_CONFIG_FILE" "$BACKUP_FILE"
    echo "📋 Current configuration backed up to: $BACKUP_FILE"
else
    echo "⚠️  Warning: Current nginx configuration not found at $NGINX_CONFIG_FILE"
    exit 1
fi

# Check if hosting configuration already exists
if grep -q "DUAL-PURPOSE hosting for AI-created projects" "$NGINX_CONFIG_FILE"; then
    echo "✅ Hosting configuration already exists in nginx config"
    echo "🔄 Reloading nginx..."
    sudo nginx -t && sudo systemctl reload nginx
    exit 0
fi

echo "📝 Adding hosting configuration to nginx..."

# Find the line after the existing project routing block
# Look for the line that contains "EXISTING PROJECT ROUTING (preserved)"
if grep -q "EXISTING PROJECT ROUTING" "$NGINX_CONFIG_FILE"; then
    # Insert after the existing project routing section
    INSERTION_LINE=$(grep -n "EXISTING PROJECT ROUTING" "$NGINX_CONFIG_FILE" | cut -d: -f1)
    INSERTION_LINE=$((INSERTION_LINE + 15))  # Skip past the existing routing block
else
    # If no existing project routing, find the server block closing
    INSERTION_LINE=$(grep -n "    }" "$NGINX_CONFIG_FILE" | tail -1 | cut -d: -f1)
fi

# Create the hosting configuration block
HOSTING_CONFIG='
    # NEW: DUAL-PURPOSE hosting for AI-created projects
    # Git access: /git/org/repo-name (existing, unchanged)  
    # Web hosting: /web/org/repo-name (NEW - when project supports hosting)
    
    # Phase 1: Organized routing with /web/org/repo-name
    location ~ ^/web/([^/]+)/([^/]+)/?$ {
        set $org_name $1;
        set $project_name $2;
        
        # Query AI Agent for project hosting capability
        # AI Agent determines if project supports web hosting
        # Returns 404 if not hostable, serves web app if hostable
        proxy_pass http://localhost:8080/api/project/$org_name/$project_name/hosting;
        proxy_set_header Host $host;
        proxy_set_header X-Org-Name $org_name;
        proxy_set_header X-Project-Name $project_name;
    }

    # NEW: Static assets for hosted projects
    location ~ ^/web/([^/]+)/([^/]+)/static/(.*)$ {
        set $org_name $1;
        set $project_name $2;
        set $asset_path $3;
        proxy_pass http://localhost:8080/api/project/$org_name/$project_name/static/$asset_path;
        proxy_set_header Host $host;
        proxy_set_header X-Org-Name $org_name;
        proxy_set_header X-Project-Name $project_name;
    }'

# Insert the hosting configuration
sudo sed -i "${INSERTION_LINE}i\\${HOSTING_CONFIG}" "$NGINX_CONFIG_FILE"

echo "🧪 Testing nginx configuration..."

# Test the nginx configuration
if sudo nginx -t; then
    echo "✅ Nginx configuration test passed"
    
    # Reload nginx
    echo "🔄 Reloading nginx..."
    sudo systemctl reload nginx
    
    echo ""
    echo "🎉 Nginx configuration extended successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Added /web/org/repo-name routing support"
    echo "✅ Integrated with existing ai-stack configuration"
    echo "✅ All existing routes preserved"
    echo ""
    echo "🌐 New capabilities enabled:"
    echo "   - Web hosting at /web/org/repo-name"
    echo "   - Static asset serving"
    echo "   - Dynamic project detection"
    echo ""
    echo "📝 Backup available at: $BACKUP_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
else
    echo "❌ Nginx configuration test failed"
    echo "🔄 Restoring backup..."
    sudo cp "$BACKUP_FILE" "$NGINX_CONFIG_FILE"
    sudo systemctl reload nginx
    echo "❌ Configuration rollback completed"
    exit 1
fi