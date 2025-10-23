#!/bin/bash
# Authenticate with Qwen using OAuth
# Stores credentials in /home/developer/.qwen/

echo "🔐 Qwen Authentication"
echo "====================="
echo ""
echo "📋 OAuth Authentication Steps:"
echo ""
echo "  1. An authorization URL will appear below"
echo "  2. COPY the URL and open it in your LOCAL browser"
echo "  3. Sign in with your Google account"
echo "  4. Come back and press ENTER after completing OAuth"
echo ""
echo "💡 The URL looks like:"
echo "   https://chat.qwen.ai/authorize?user_code=XXXXXXXX&client=qwen-code"
echo ""
read -p "Press Enter when ready to start (or Ctrl+C to cancel)..."
echo ""

# Check if expect is installed
if ! command -v expect &> /dev/null; then
    echo "📦 Installing expect (required for OAuth automation)..."
    apt-get update -qq && apt-get install -y expect
    echo "✅ expect installed"
    echo ""
fi

# Clean previous auth
su - developer -c 'rm -rf ~/.qwen' 2>/dev/null || true

# Start qwen with expect in background to capture OAuth URL
su - developer -c 'cat > /tmp/qwen-auth.sh' <<'SCRIPT'
#!/bin/bash
expect <<'END_EXPECT' > /tmp/qwen_oauth.log 2>&1 &
set timeout 180
log_user 1

spawn qwen
expect {
    "How would you like to authenticate" {
        send "1\r"
        expect {
            "authorize" {
                # Keep session alive until killed
                expect timeout
            }
        }
    }
}
END_EXPECT
SCRIPT

chmod +x /tmp/qwen-auth.sh
su - developer -c 'bash /tmp/qwen-auth.sh' &

# Wait for OAuth URL to appear
echo "Starting OAuth flow..."
sleep 8

# Display the OAuth output (static, no flickering)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 OAuth URL (copy and open in your browser):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show the full log for debugging
if su - developer -c 'test -f /tmp/qwen_oauth.log' 2>/dev/null; then
    # Try to extract just the OAuth URL (must contain 'authorize')
    URL=$(su - developer -c 'cat /tmp/qwen_oauth.log 2>/dev/null | grep -oE "https://[^[:space:]]*authorize[^[:space:]]*" | head -1')
    if [ -n "$URL" ]; then
        echo "$URL"
    else
        # Show full log if URL extraction failed
        echo "DEBUG: Searching for authorize URL in log:"
        su - developer -c 'cat /tmp/qwen_oauth.log 2>/dev/null | grep -i authorize | head -20'
    fi
else
    echo "⚠️  Log file not created. Checking if expect is installed..."
    if ! command -v expect &> /dev/null; then
        echo "❌ 'expect' is not installed on the VM!"
        echo ""
        echo "Installing expect..."
        apt-get update -qq && apt-get install -y expect
        echo "✅ expect installed. Please run 'tfgrid-compose login' again."
        exit 1
    else
        echo "⚠️  OAuth flow didn't start. Check /tmp/qwen_oauth.log on VM for details."
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "✅ Press ENTER after completing OAuth in your browser..."
echo ""

# Kill the qwen/expect processes
pkill -u developer -f qwen 2>/dev/null || true
pkill -u developer -f expect 2>/dev/null || true

echo "Verifying authentication..."
if su - developer -c 'test -f ~/.qwen/settings.json' 2>/dev/null; then
    echo "✅ Qwen is now authenticated!"
    echo ""
    echo "Next steps:"
    echo "  tfgrid-compose create    # Create a new project"
else
    echo "⚠️  Authentication verification failed."
    echo ""
    echo "Troubleshooting:"
    echo "  1. Try running 'tfgrid-compose login' again"
    echo "  2. Ensure you completed the OAuth flow in your browser"
fi
