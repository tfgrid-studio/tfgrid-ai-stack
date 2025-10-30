#!/bin/bash
# t-hosting.sh - Gateway Hosting CLI wrapper
# Provides easy access to hosting management commands

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTING_SCRIPT="$SCRIPT_DIR/publish-project.sh"
NGINX_EXTEND_SCRIPT="$SCRIPT_DIR/extend-nginx-config.sh"

# Function to display help
show_help() {
    echo "🌐 TFGrid AI Stack - Gateway Hosting"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Usage: t <command> [options]"
    echo ""
    echo "Hosting Management:"
    echo "  publish <name>         - Publish project for web hosting"
    echo "  unpublish <name>       - Remove project from web hosting"
    echo "  status <name>          - Show hosting status"
    echo ""
    echo "Infrastructure:"
    echo "  setup-hosting         - Extend nginx with hosting support"
    echo "  hosting-health        - Check hosting infrastructure"
    echo ""
    echo "Examples:"
    echo "  t publish my-react-app"
    echo "  t unpublish my-react-app"
    echo "  t status my-react-app"
    echo "  t setup-hosting"
    echo ""
    echo "Enhanced Project Status:"
    echo "  tfgrid-compose status  - Shows project status with hosting info"
    echo ""
}

# Function to check hosting infrastructure
check_hosting_health() {
    echo "🔍 Checking Gateway Hosting Infrastructure"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check nginx
    if sudo systemctl is-active --quiet nginx; then
        echo "✅ Nginx: Running"
    else
        echo "❌ Nginx: Not running"
    fi
    
    # Check nginx config
    if sudo nginx -t >/dev/null 2>&1; then
        echo "✅ Nginx Config: Valid"
    else
        echo "❌ Nginx Config: Invalid"
    fi
    
    # Check if hosting config is present
    if grep -q "DUAL-PURPOSE hosting" /etc/nginx/sites-available/ai-stack 2>/dev/null; then
        echo "✅ Hosting Routes: Configured"
    else
        echo "❌ Hosting Routes: Not configured"
    fi
    
    # Check hosting directories
    if [ -d "/etc/tfgrid-ai-stack/hosting" ]; then
        echo "✅ Hosting Config: Directory exists"
    else
        echo "❌ Hosting Config: Directory missing"
    fi
    
    # Check if hosting API is available
    if curl -s http://localhost:8081/health >/dev/null 2>&1; then
        echo "✅ Hosting API: Running"
    else
        echo "❌ Hosting API: Not running (optional)"
    fi
    
    echo ""
    echo "💡 If hosting routes are not configured, run: t setup-hosting"
}

# Function to setup hosting infrastructure
setup_hosting() {
    echo "🚀 Setting up Gateway Hosting Infrastructure"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if running as root or with sudo
    if [ "$EUID" -ne 0 ]; then
        echo "⚠️  This script requires sudo privileges"
        echo "🔧 Running setup with sudo..."
    fi
    
    # Run nginx configuration extension
    if [ -f "$NGINX_EXTEND_SCRIPT" ]; then
        sudo bash "$NGINX_EXTEND_SCRIPT"
    else
        echo "❌ Nginx extension script not found"
        exit 1
    fi
    
    # Create hosting directories
    echo "📁 Creating hosting directories..."
    sudo mkdir -p /etc/tfgrid-ai-stack/hosting
    sudo mkdir -p /etc/tfgrid-ai-stack/projects
    sudo chmod 755 /etc/tfgrid-ai-stack/hosting
    sudo chmod 755 /etc/tfgrid-ai-stack/projects
    
    echo "✅ Hosting directories created"
    
    # Check hosting API
    echo ""
    echo "🔍 Checking hosting API..."
    if command -v node >/dev/null 2>&1; then
        if [ -f "$SCRIPT_DIR/../agent/hosting-api.js" ]; then
            echo "✅ Hosting API script found"
            echo ""
            echo "📝 To start hosting API:"
            echo "   cd $SCRIPT_DIR/../agent"
            echo "   npm install express"
            echo "   node hosting-api.js"
        else
            echo "⚠️  Hosting API script not found"
        fi
    else
        echo "⚠️  Node.js not found - hosting API requires Node.js"
    fi
    
    echo ""
    echo "🎉 Gateway hosting infrastructure setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Publish a project: t publish <project-name>"
    echo "  2. Check project status: t status <project-name>"
    echo "  3. View enhanced status: tfgrid-compose status"
}

# Main script logic
case "${1:-}" in
    "publish"|"unpublish"|"status")
        if [ ! -f "$HOSTING_SCRIPT" ]; then
            echo "❌ Hosting script not found: $HOSTING_SCRIPT"
            exit 1
        fi
        
        # Source hosting functions and run the command
        source "$HOSTING_SCRIPT" 2>/dev/null || true
        bash "$HOSTING_SCRIPT" "$@"
        ;;
        
    "setup-hosting")
        setup_hosting
        ;;
        
    "hosting-health")
        check_hosting_health
        ;;
        
    "help"|"-h"|"--help"|"")
        show_help
        ;;
        
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac