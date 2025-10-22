# TFGrid AI Stack

AI-powered development platform with integrated Git hosting and deployment.

## Overview

TFGrid AI Stack is an app that deploys a complete AI-powered development platform using the gateway pattern. It automatically deploys and configures three components:

- **Gateway VM**: Public API gateway with nginx routing, SSL termination, and monitoring
- **AI Agent VM**: AI-powered project creation and code generation (deployed as tfgrid-ai-agent)
- **Gitea VM**: Git repository hosting with web interface (deployed as tfgrid-gitea)

All components are connected via private networking and accessible through clean URLs on a single domain.

## Quick Start

Deploy the complete AI development environment:

```bash
tfgrid-compose up tfgrid-ai-stack
```

## Features

- 🤖 **AI-Powered Development**: Create projects with AI assistance
- 📦 **Integrated Git Hosting**: Built-in Gitea for version control
- 🌐 **Public Deployment**: Automatic web deployment with SSL
- 📊 **Monitoring**: Prometheus + Grafana dashboards
- 🔒 **Secure Networking**: WireGuard VPN for inter-VM communication
- ⚡ **One-Click Deployment**: Single command setup
- 🔄 **Automated Backups**: Scheduled backups with retention policies

## Architecture

```
Internet
    ↓
[Gateway VM] ← nginx routing, SSL, monitoring
    ↓ (WireGuard VPN)
├── [AI Agent VM] ← tfgrid-ai-agent app
└── [Gitea VM] ← tfgrid-gitea app
```

### URL Structure
```
https://yourdomain.com/
├── /                    → Gateway dashboard/API
├── /git/               → Gitea web interface
├── /api/               → AI Agent API endpoints
├── /monitoring/        → Prometheus/Grafana
└── /project1/          → AI-generated projects
```

## Usage

### Deploy
```bash
tfgrid-compose up tfgrid-ai-stack
```

### Create a Project
```bash
tfgrid-compose exec tfgrid-ai-stack create "portfolio website"
```

### List Projects
```bash
tfgrid-compose exec tfgrid-ai-stack projects
```

### Access Services
```bash
# Get deployment URLs
tfgrid-compose address tfgrid-ai-stack

# SSH into VMs
tfgrid-compose ssh tfgrid-ai-stack
```

### Management Commands
```bash
# Monitor project logs
tfgrid-compose exec tfgrid-ai-stack monitor <project-name>

# Delete a project
tfgrid-compose exec tfgrid-ai-stack delete <project-name>

# Manual backup
tfgrid-compose exec tfgrid-ai-stack backup

# Restore from backup
tfgrid-compose exec tfgrid-ai-stack restore <backup-file>
```

## Configuration

The pattern supports extensive customization through variables:

### Domain & SSL
- `domain`: Custom domain name for public access
- `ssl_email`: Email for SSL certificate (required if domain set)

### Resource Allocation
- `gateway_cpu/memory/disk`: Gateway VM resources
- `ai_agent_cpu/memory/disk`: AI Agent VM resources
- `gitea_cpu/memory/disk`: Gitea VM resources

### Security & Limits
- `api_rate_limit`: API rate limiting
- `max_concurrent_projects`: Concurrent project creation limit

### Backup Settings
- `backup_retention_days`: Backup retention period
- `backup_schedule`: Cron schedule for automated backups

## Requirements

- ThreeFold Grid account with sufficient TFT
- tfgrid-compose CLI installed
- SSH key configured

## Resources

- **CPU**: 8 cores total (default)
- **Memory**: 16GB total (default)
- **Disk**: 200GB total (default)
- **Cost**: ~$15-20/month (varies by node pricing)

## App Structure

```
tfgrid-ai-stack/
├── tfgrid-compose.yaml    # App definition (uses gateway pattern)
├── deployment/            # Component orchestration hooks
│   ├── setup.sh          # Deploy ai-agent + gitea components
│   ├── configure.sh      # Configure nginx routing
│   └── healthcheck.sh    # Verify component health
├── scripts/              # AI project management scripts
├── README.md             # This file
└── LICENSE               # Apache 2.0
```

## Development

This app is maintained by TFGrid Studio. It orchestrates the deployment of:
- [tfgrid-ai-agent](https://github.com/tfgrid-studio/tfgrid-ai-agent) - AI coding assistant
- [tfgrid-gitea](https://github.com/tfgrid-studio/tfgrid-gitea) - Git hosting
- Gateway pattern from [tfgrid-compose](https://github.com/tfgrid-studio/tfgrid-compose) - Infrastructure

## Documentation

- [Pattern Documentation](https://docs.tfgrid.studio/patterns/tfgrid-ai-stack)
- [API Reference](https://docs.tfgrid.studio/patterns/tfgrid-ai-stack/api)
- [Troubleshooting](https://docs.tfgrid.studio/patterns/tfgrid-ai-stack/troubleshooting)

## Support

This is an official TFGrid Studio application. For support:
- Documentation: https://docs.tfgrid.studio
- Issues: https://github.com/tfgrid-studio/tfgrid-compose/issues