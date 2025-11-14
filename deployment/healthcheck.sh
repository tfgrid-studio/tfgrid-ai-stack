#!/usr/bin/env bash
# Health check script - Verify all services are running
# This runs directly on the VM after setup to ensure everything is operational

set -e

echo "🏥 Running health checks for tfgrid-ai-stack services..."

# Get VM IP (try multiple methods)
VM_IP=""
if [ -n "$PRIMARY_IP" ]; then
    VM_IP="$PRIMARY_IP"
elif [ -n "$primary_ip" ]; then
    VM_IP="$primary_ip"
else
    # Fallback: get local IP
    VM_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "127.0.0.1")
fi

echo "Using VM_IP: $VM_IP"

# Check system services (running locally on this VM)
echo "Checking system services..."

# Check Docker
if ! systemctl is-active --quiet docker 2>/dev/null; then
    echo "❌ Docker is not running"
    exit 1
else
    echo "✅ Docker is running"
fi

# Check Nginx
if ! systemctl is-active --quiet nginx 2>/dev/null; then
    echo "❌ Nginx is not running"
    exit 1
else
    echo "✅ Nginx is running"
fi

# Check Gitea
if ! systemctl is-active --quiet gitea 2>/dev/null; then
    echo "❌ Gitea is not running"
    exit 1
else
    echo "✅ Gitea is running"
fi

# Check Docker containers
echo "Checking Docker containers..."
if ! docker ps > /dev/null 2>&1; then
    echo "❌ Docker daemon not responding"
    exit 1
else
    echo "✅ Docker daemon is responding"
fi

# Check web endpoints (with retries)
echo "Checking web endpoints..."

# Function to check endpoint with retries
check_endpoint() {
    local url="$1"
    local name="$2"
    local max_attempts=5
    local attempt=1
    
    echo "Checking $name at $url..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s -L --max-time 10 "$url" > /dev/null 2>&1; then
            echo "✅ $name is accessible"
            return 0
        else
            echo "  Attempt $attempt/$max_attempts failed, retrying..."
            sleep 2
            ((attempt++))
        fi
    done
    
    echo "❌ $name is not accessible at $url"
    return 1
}

# Check Gitea web interface
if ! check_endpoint "http://localhost/git/" "Gitea web interface"; then
    exit 1
fi

# Check Nginx gateway
if ! check_endpoint "http://localhost/" "Nginx gateway"; then
    exit 1
fi

# Check AI Agent API (if available)
if curl -f -s "http://localhost:3000/api/health" > /dev/null 2>&1; then
    echo "✅ AI Agent API is accessible"
else
    echo "⚠️  AI Agent API not accessible (may still be starting up)"
fi

echo "🎉 Health checks passed!"
echo ""
echo "Services available at:"
echo "  • Gateway: http://$VM_IP/"
echo "  • Git: http://$VM_IP/git/"
echo "  • Monitoring: http://$VM_IP:3000/grafana (if enabled)"

echo "✅ All services are healthy and accessible"
