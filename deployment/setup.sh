#!/usr/bin/env bash
# Setup script - Install and configure all tfgrid-ai-stack services
# This runs directly on the VM after tfgrid-compose has established SSH access

set -e

echo "🚀 Setting up tfgrid-ai-stack services on single VM..."
echo "Current working directory: $(pwd)"
echo "Available files in /tmp/app-source/:"
ls -la /tmp/app-source/ 2>/dev/null || echo "No /tmp/app-source found"

# Install Docker and dependencies
echo "📦 Installing Docker and dependencies..."
echo "  Running apt update..."
apt update -y || (echo "❌ apt update failed"; exit 1)
echo "  Installing packages..."
DEBIAN_FRONTEND=noninteractive apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx ufw || (echo "❌ apt install failed"; exit 1)
echo "  Docker installation completed"

# Enable Docker
systemctl enable docker
systemctl start docker

# Configure firewall
ufw allow ssh
ufw allow 80
ufw allow 443
ufw --force enable

echo "✅ Docker and dependencies installed"

# Install Gitea
echo "📦 Installing Gitea..."
# Install system dependencies
echo "📦 Installing system dependencies..."
apt-get update -y || (echo "❌ apt-get update failed"; exit 1)
DEBIAN_FRONTEND=noninteractive apt-get install -y git curl wget sqlite3 || (echo "❌ apt-get install failed"; exit 1)
echo "  System dependencies installed"

# Create gitea user
if ! id -u gitea >/dev/null 2>&1; then
    useradd -m -s /bin/bash gitea
    echo "✅ Created gitea user"
else
    echo "ℹ️  Gitea user already exists"
fi

# Download and install Gitea
echo "📦 Installing Gitea..."
GITEA_VERSION="1.24.6"
echo "  Downloading Gitea ${GITEA_VERSION}..."
curl -fsSL "https://github.com/go-gitea/gitea/releases/download/v${GITEA_VERSION}/gitea-${GITEA_VERSION}-linux-amd64" -o gitea || (echo "❌ Gitea download failed"; exit 1)
mv gitea /usr/local/bin/
chmod +x /usr/local/bin/gitea
echo "  Gitea installed"

# Create directories
mkdir -p /etc/gitea /var/lib/gitea/data /var/log/gitea
chown -R gitea:gitea /etc/gitea /var/lib/gitea /var/log/gitea

# Create gitea scripts directory
mkdir -p /opt/gitea/scripts

# Copy agent scripts (tfgrid-compose flattens src/ directory)
cp -r /tmp/app-source/scripts /opt/gitea/ 2>/dev/null || echo "ℹ️  No scripts to copy"

# Make scripts executable
chmod +x /opt/gitea/scripts/*.sh 2>/dev/null || true

# Install systemd services
echo "🔧 Installing systemd services..."
cp /tmp/app-source/systemd/gitea.service /etc/systemd/system/ 2>/dev/null || echo "ℹ️  No gitea systemd service to copy"
cp /tmp/app-source/systemd/ai-agent.service /etc/systemd/system/ 2>/dev/null || echo "ℹ️  No ai-agent systemd service to copy"
systemctl daemon-reload || (echo "❌ systemctl daemon-reload failed"; exit 1)
echo "  Enabling services..."
systemctl enable gitea || (echo "❌ Failed to enable gitea"; exit 1)
systemctl enable ai-agent || (echo "❌ Failed to enable ai-agent"; exit 1)
echo "  Starting services..."
systemctl start gitea || (echo "❌ Failed to start gitea"; exit 1)
systemctl start ai-agent || (echo "❌ Failed to start ai-agent"; exit 1)
echo "  Services started"

echo "✅ Gitea installed and started"

# Install AI Agent
echo "🤖 Installing AI Agent..."
# Create AI Agent directories
mkdir -p /opt/ai-agent
cd /opt/ai-agent

# Install Node.js and npm
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - || (echo "❌ Node.js setup failed"; exit 1)
DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs || (echo "❌ Node.js install failed"; exit 1)
echo "  Node.js installed"

# Clone and setup AI Agent (placeholder - replace with actual repo)
# git clone https://github.com/tfgrid-studio/tfgrid-ai-agent.git .
# cd tfgrid-ai-agent
# npm install
# npm run build

# For now, create a simple AI Agent service
cat > /opt/ai-agent/server.js << 'JSEOF'
const express = require('express');
const app = express();
app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.post('/create-project', (req, res) => {
  // Placeholder AI project creation
  res.json({ project: 'created', id: Date.now() });
});

app.listen(8080, () => console.log('AI Agent listening on port 8080'));
JSEOF

# Install dependencies and run
echo "📦 Installing AI Agent dependencies..."
npm init -y || (echo "❌ npm init failed"; exit 1)
npm install express || (echo "❌ npm install failed"; exit 1)
echo "  Starting AI Agent service..."
node server.js &
echo "  AI Agent started"

echo "✅ AI Agent installed and started"

# Configure Nginx reverse proxy
echo "🌐 Configuring Nginx reverse proxy..."
cat > /etc/nginx/sites-available/ai-stack << 'NGINXEOL'
server {
    listen 80;
    server_name _;

    # Gitea routing
    location /git/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # AI Agent API routing
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Project routing (dynamic)
    location ~ ^/project([0-9]+)/ {
        proxy_pass http://localhost:8080/project$1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Monitoring (placeholder)
    location /monitoring/ {
        return 200 "Monitoring dashboard coming soon";
    }

    # Default: Redirect to Gitea
    location / {
        return 302 /git/;
    }
}
NGINXEOL

# Enable site
ln -sf /etc/nginx/sites-available/ai-stack /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx

echo "✅ Nginx configured"

echo "✅ All services installed and configured"