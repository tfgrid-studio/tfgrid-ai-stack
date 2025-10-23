#!/usr/bin/env bash
# Setup script - Install and configure all tfgrid-ai-stack services
# This runs directly on the VM after tfgrid-compose has established SSH access

set -e

echo "🚀 Setting up tfgrid-ai-stack services on single VM..."
echo "Current working directory: $(pwd)"
echo "Available files in /tmp/app-source/:"
ls -la /tmp/app-source/ 2>/dev/null || echo "No /tmp/app-source found"
echo "Testing basic commands..."
echo "  whoami: $(whoami)"
echo "  id: $(id)"
echo "  pwd: $(pwd)"
echo "  ls /tmp/: $(ls /tmp/ 2>/dev/null | head -5)"
echo "Basic commands completed"

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

# Create organized scripts directory structure
mkdir -p /opt/tfgrid-ai-stack/scripts/gitea
mkdir -p /opt/tfgrid-ai-stack/scripts/ai-agent

# Copy scripts to the installation directory for tfgrid-compose absolute path references
# tfgrid-compose flattens src/scripts/ to scripts/ in deployment directory, but commands expect absolute paths

# Create installation directory
mkdir -p /opt/tfgrid-ai-stack/scripts

# Copy all scripts from deployment scripts/ to installation directory
cp -r scripts/* /opt/tfgrid-ai-stack/scripts/ 2>/dev/null || echo "ℹ️  No scripts to copy from deployment directory"

# Make all scripts executable
chmod +x /opt/tfgrid-ai-stack/scripts/*.sh 2>/dev/null || true

# Make all scripts executable
chmod +x /opt/tfgrid-ai-stack/scripts/gitea/*.sh 2>/dev/null || true
chmod +x /opt/tfgrid-ai-stack/scripts/ai-agent/*.sh 2>/dev/null || true

# Create Gitea configuration for auto-setup
echo "⚙️ Creating Gitea configuration..."

# Determine ROOT_URL based on available IPs - must match reverse proxy path
ROOT_URL="http://localhost/git/"
if [ -n "${PRIMARY_IP:-}" ]; then
    ROOT_URL="http://${PRIMARY_IP}/git/"
fi

cat > /etc/gitea/app.ini << EOF
WORK_PATH = /var/lib/gitea

[server]
HTTP_PORT = 3000
ROOT_URL = ${ROOT_URL}

[database]
DB_TYPE = sqlite3
PATH = /var/lib/gitea/data/gitea.db

[security]
INSTALL_LOCK = true
SECRET_KEY = $(openssl rand -hex 32)
INTERNAL_TOKEN = $(openssl rand -hex 32)

[service]
DISABLE_REGISTRATION = false
REQUIRE_SIGNIN_VIEW = false

[oauth2]
JWT_SECRET = $(openssl rand -hex 32)
EOF

# Set proper ownership
chown gitea:gitea /etc/gitea/app.ini

# Install systemd service for Gitea
echo "🔧 Installing Gitea systemd service..."
cat > /etc/systemd/system/gitea.service << 'SERVICEEOF'
[Unit]
Description=Gitea (Git with a cup of tea)
After=syslog.target
After=network.target

[Service]
RestartSec=2s
Type=simple
User=gitea
Group=gitea
WorkingDirectory=/var/lib/gitea
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=gitea HOME=/var/lib/gitea GITEA_WORK_DIR=/var/lib/gitea

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload || (echo "❌ systemctl daemon-reload failed"; exit 1)
echo "  Enabling Gitea service..."
systemctl enable gitea || (echo "❌ Failed to enable gitea"; exit 1)
echo "  Starting Gitea service..."
systemctl start gitea || (echo "❌ Failed to start gitea"; exit 1)

# Wait for Gitea to initialize database
echo "⏳ Waiting for Gitea to initialize database..."
sleep 15

# Verify Gitea is responding
echo "🔍 Checking if Gitea is responding..."
timeout 30 bash -c 'until curl -f http://localhost:3000/api/v1/version >/dev/null 2>&1; do sleep 2; done' || {
    echo "❌ Gitea failed to start properly"
    systemctl status gitea
    exit 1
}

# Create admin user
echo "👤 Creating Gitea admin user..."
sudo -u gitea /usr/local/bin/gitea admin user create \
    --username "gitadmin" \
    --password "changeme123" \
    --email "admin@localhost" \
    --admin \
    --config /etc/gitea/app.ini \
    || echo "⚠️ Admin user may already exist"

# Restart Gitea to apply configuration changes
echo "🔄 Restarting Gitea to apply configuration..."
systemctl restart gitea
sleep 5

echo "✅ Gitea installed and configured"
echo "🌐 Gitea accessible at: http://localhost:3000/"
echo "👤 Admin user: gitadmin"
echo "🔑 Admin password: changeme123"

# Install AI Agent
echo "🤖 Installing AI Agent..."
# Create AI Agent directories
mkdir -p /opt/tfgrid-ai-stack/ai-agent
cd /opt/tfgrid-ai-stack/ai-agent

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

# Create full AI Agent service with project management API
cat > /opt/tfgrid-ai-stack/ai-agent/server.js << 'JSEOF'
const express = require('express');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs').promises;

const app = express();
app.use(express.json());

// Project workspace
const PROJECTS_DIR = '/opt/ai-agent/projects';

// Ensure projects directory exists
fs.mkdir(PROJECTS_DIR, { recursive: true }).catch(console.error);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// List all projects
app.get('/api/projects', async (req, res) => {
  try {
    const projects = [];
    const entries = await fs.readdir(PROJECTS_DIR, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.isDirectory()) {
        const projectPath = path.join(PROJECTS_DIR, entry.name);
        const statusFile = path.join(projectPath, '.project-status.json');

        let status = 'unknown';
        try {
          const statusData = await fs.readFile(statusFile, 'utf8');
          const statusJson = JSON.parse(statusData);
          status = statusJson.status || 'unknown';
        } catch (e) {
          // Status file doesn't exist or is invalid
        }

        projects.push({
          name: entry.name,
          path: projectPath,
          status: status,
          created: await getDirCreationTime(projectPath)
        });
      }
    }

    res.json({ projects });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create new project
app.post('/api/projects', async (req, res) => {
  try {
    const { name, description, template } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Project name is required' });
    }

    const projectPath = path.join(PROJECTS_DIR, name);

    // Check if project already exists
    try {
      await fs.access(projectPath);
      return res.status(409).json({ error: 'Project already exists' });
    } catch (e) {
      // Project doesn't exist, good
    }

    // Create project directory
    await fs.mkdir(projectPath, { recursive: true });

    // Initialize project status
    const statusData = {
      name,
      description: description || '',
      status: 'created',
      created: new Date().toISOString(),
      template: template || 'generic'
    };

    await fs.writeFile(
      path.join(projectPath, '.project-status.json'),
      JSON.stringify(statusData, null, 2)
    );

    // Initialize git repository
    await runCommand('git', ['init'], { cwd: projectPath });
    await runCommand('git', ['config', 'user.name', 'AI Agent'], { cwd: projectPath });
    await runCommand('git', ['config', 'user.email', 'ai@localhost'], { cwd: projectPath });

    res.json({
      project: name,
      path: projectPath,
      status: 'created',
      message: 'Project created successfully'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get project status
app.get('/api/projects/:name', async (req, res) => {
  try {
    const { name } = req.params;
    const projectPath = path.join(PROJECTS_DIR, name);

    // Check if project exists
    try {
      await fs.access(projectPath);
    } catch (e) {
      return res.status(404).json({ error: 'Project not found' });
    }

    // Read project status
    const statusFile = path.join(projectPath, '.project-status.json');
    let statusData = { name, status: 'unknown' };

    try {
      const statusContent = await fs.readFile(statusFile, 'utf8');
      statusData = { ...statusData, ...JSON.parse(statusContent) };
    } catch (e) {
      // Status file doesn't exist or is invalid
    }

    res.json(statusData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Start project (run agent loop)
app.post('/api/projects/:name/run', async (req, res) => {
  try {
    const { name } = req.params;
    const projectPath = path.join(PROJECTS_DIR, name);

    // Check if project exists
    try {
      await fs.access(projectPath);
    } catch (e) {
      return res.status(404).json({ error: 'Project not found' });
    }

    // Update status to running
    await updateProjectStatus(name, 'running');

    // Start agent loop in background
    const scriptPath = '/opt/tfgrid-ai-stack/scripts/ai-agent/agent-loop.sh';
    const child = spawn('bash', [scriptPath, name], {
      cwd: projectPath,
      detached: true,
      stdio: 'ignore'
    });

    child.unref();

    res.json({
      project: name,
      status: 'running',
      message: 'Agent loop started'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Stop project
app.post('/api/projects/:name/stop', async (req, res) => {
  try {
    const { name } = req.params;

    // Find and kill agent processes for this project
    const result = await runCommand('pkill', ['-f', `agent-loop.sh ${name}`]);

    // Update status
    await updateProjectStatus(name, 'stopped');

    res.json({
      project: name,
      status: 'stopped',
      message: 'Agent loop stopped'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete project
app.delete('/api/projects/:name', async (req, res) => {
  try {
    const { name } = req.params;
    const projectPath = path.join(PROJECTS_DIR, name);

    // Stop any running processes first
    try {
      await runCommand('pkill', ['-f', `agent-loop.sh ${name}`]);
    } catch (e) {
      // Ignore if no processes running
    }

    // Remove project directory
    await fs.rm(projectPath, { recursive: true, force: true });

    res.json({
      project: name,
      message: 'Project deleted successfully'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Helper functions
async function getDirCreationTime(dirPath) {
  try {
    const stats = await fs.stat(dirPath);
    return stats.birthtime || stats.ctime;
  } catch (e) {
    return new Date().toISOString();
  }
}

async function updateProjectStatus(projectName, status) {
  try {
    const projectPath = path.join(PROJECTS_DIR, projectName);
    const statusFile = path.join(projectPath, '.project-status.json');

    let statusData = { name: projectName };
    try {
      const existing = await fs.readFile(statusFile, 'utf8');
      statusData = { ...statusData, ...JSON.parse(existing) };
    } catch (e) {
      // File doesn't exist
    }

    statusData.status = status;
    statusData.updated = new Date().toISOString();

    await fs.writeFile(statusFile, JSON.stringify(statusData, null, 2));
  } catch (error) {
    console.error('Failed to update project status:', error);
  }
}

function runCommand(cmd, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { ...options, stdio: 'pipe' });
    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data) => stdout += data.toString());
    child.stderr.on('data', (data) => stderr += data.toString());

    child.on('close', (code) => {
      if (code === 0) {
        resolve({ stdout, stderr });
      } else {
        reject(new Error(`Command failed: ${stderr || stdout}`));
      }
    });

    child.on('error', reject);
  });
}

app.listen(8080, () => {
  console.log('AI Agent API server listening on port 8080');
  console.log('Projects directory:', PROJECTS_DIR);
  console.log('Scripts directory:', '/opt/tfgrid-ai-stack/scripts/ai-agent');
});
JSEOF

# Install dependencies and run
echo "📦 Installing AI Agent dependencies..."
npm init -y || (echo "❌ npm init failed"; exit 1)
npm install express || (echo "❌ npm install failed"; exit 1)

# Create systemd service for AI Agent
echo "🔧 Creating AI Agent systemd service..."
cat > /etc/systemd/system/ai-agent.service << 'AGENTSERVICEEOF'
[Unit]
Description=AI Agent Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/tfgrid-ai-stack/ai-agent
ExecStart=/usr/bin/node /opt/tfgrid-ai-stack/ai-agent/server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
AGENTSERVICEEOF

systemctl daemon-reload
systemctl enable ai-agent
systemctl start ai-agent

echo "✅ AI Agent installed and started as systemd service"

# Create systemd service template for AI agent projects
echo "🔧 Creating AI agent project systemd service template..."
cat > /etc/systemd/system/tfgrid-ai-project@.service << 'PROJECTSERVICEEOF'
[Unit]
Description=TFGrid AI Project %i
After=network.target ai-agent.service
Requires=ai-agent.service

[Service]
Type=simple
User=developer
WorkingDirectory=/home/developer/code/tfgrid-ai-agent-projects/%i
ExecStart=/opt/tfgrid-ai-stack/scripts/ai-agent/agent-loop.sh %i
Restart=always
RestartSec=10
Environment=PROJECT_WORKSPACE=/home/developer/code
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
PROJECTSERVICEEOF

systemctl daemon-reload
echo "✅ AI agent project service template created"

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
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Prefix /git;
        proxy_buffering off;
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

# Test nginx configuration
nginx -t || (echo "❌ Nginx configuration test failed"; exit 1)

# Reload nginx
systemctl reload nginx

echo "✅ Nginx configured and tested"

echo "✅ All services installed and configured"
echo ""
echo "🎉 tfgrid-ai-stack deployment complete!"
echo ""
echo "🌐 Access your services:"
echo "   • Gitea (Git hosting): http://${PRIMARY_IP:-localhost}/git/"
echo "   • AI Agent API: http://${PRIMARY_IP:-localhost}/api/"
echo ""
echo "👤 Gitea Admin Login:"
echo "   • Username: gitadmin"
echo "   • Password: changeme123"
echo "   • Email: admin@localhost"
echo ""
echo "⚠️  IMPORTANT: Change the admin password after first login!"
echo ""
echo "📚 Next steps:"
echo "   • Open http://${PRIMARY_IP:-localhost}/git/ in your browser"
echo "   • Log in with gitadmin/changeme123"
echo "   • Create your first repository"
echo "   • Start building with AI assistance!"