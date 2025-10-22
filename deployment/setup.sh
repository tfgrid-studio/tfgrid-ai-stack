#!/usr/bin/env bash
# Setup script - Install and configure all tfgrid-ai-stack services
# This runs after single-vm pattern infrastructure is deployed

set -e

echo "🚀 Setting up tfgrid-ai-stack services on single VM..."

# VM connection info
VM_IP="${PRIMARY_IP}"
SSH_KEY_PATH="${SSH_KEY_PATH}"

# Install Docker and dependencies
echo "📦 Installing Docker and dependencies..."
ssh -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no root@${VM_IP} << 'EOF'
apt update
apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx ufw

# Enable Docker
systemctl enable docker
systemctl start docker

# Configure firewall
ufw allow ssh
ufw allow 80
ufw allow 443
ufw --force enable

echo "✅ Docker and dependencies installed"
EOF

# Install Gitea
echo "📦 Installing Gitea..."
ssh -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no root@${VM_IP} << 'EOF'
# Create Gitea directories
mkdir -p /opt/gitea
cd /opt/gitea

# Download and run Gitea
wget -O gitea https://dl.gitea.com/gitea/1.21/gitea-1.21.11-linux-amd64
chmod +x gitea

# Create Gitea user
useradd --system --shell /bin/bash --home /opt/gitea --create-home --comment "Git Version Control" git

# Configure Gitea
mkdir -p /etc/gitea
chown -R git:git /opt/gitea /etc/gitea

cat > /etc/systemd/system/gitea.service << 'SERVICEEOF'
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target

[Service]
RestartSec=2s
Type=simple
User=git
Group=git
WorkingDirectory=/opt/gitea
ExecStart=/opt/gitea/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=git HOME=/opt/gitea GITEA_WORK_DIR=/opt/gitea

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable gitea
systemctl start gitea

echo "✅ Gitea installed and started"
EOF

# Install AI Agent
echo "🤖 Installing AI Agent..."
ssh -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no root@${VM_IP} << 'EOF'
# Create AI Agent directories
mkdir -p /opt/ai-agent
cd /opt/ai-agent

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

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
npm init -y
npm install express
node server.js &

echo "✅ AI Agent installed and started"
EOF

# Configure Nginx reverse proxy
echo "🌐 Configuring Nginx reverse proxy..."
ssh -i "${SSH_KEY_PATH}" -o StrictHostKeyChecking=no root@${VM_IP} << 'EOF'
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
EOF

echo "✅ All services installed and configured"