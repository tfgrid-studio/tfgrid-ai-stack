#!/bin/bash
# Check Qwen authentication status
# Shows if logged in and displays user info

echo "🔍 Qwen Authentication Status"
echo "=============================="
echo ""

# Check if settings file exists
if su - developer -c 'test -f ~/.qwen/settings.json' 2>/dev/null; then
    echo "✅ Authenticated"
    echo ""
    
    # Try to show some info from settings (safely)
    echo "📋 Details:"
    if su - developer -c 'test -r ~/.qwen/settings.json' 2>/dev/null; then
        # Show file modification time (when auth was done)
        AUTH_TIME=$(su - developer -c 'stat -c %y ~/.qwen/settings.json 2>/dev/null' | cut -d'.' -f1)
        echo "  Authenticated at: $AUTH_TIME"
        
        # Check qwen version
        QWEN_VERSION=$(qwen --version 2>&1 | head -1 || echo "unknown")
        echo "  Qwen CLI version: $QWEN_VERSION"
    fi
    
    echo ""
    echo "💡 You can now create and run projects:"
    echo "  tfgrid-compose create    # Create new project"
    echo "  tfgrid-compose projects  # List all projects"
else
    echo "❌ Not authenticated"
    echo ""
    echo "Please login first:"
    echo "  tfgrid-compose login"
    echo ""
    echo "This will open the OAuth flow to authenticate with your Google account."
fi
