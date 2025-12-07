# TFGrid AI Stack

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/tfgrid-studio/tfgrid-ai-stack)](https://github.com/tfgrid-studio/tfgrid-ai-stack/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/tfgrid-studio/tfgrid-ai-stack)](https://github.com/tfgrid-studio/tfgrid-ai-stack/issues)

AI-powered development platform with integrated Git hosting and deployment.

## Overview

TFGrid AI Stack is an app that deploys a complete AI-powered development platform on a single VM. It automatically installs and configures three integrated components:

- **Nginx Reverse Proxy**: Public API gateway with routing, SSL termination, and monitoring
- **AI Agent Service**: AI-powered project creation and code generation (Node.js API)
- **Gitea Git Server**: Git repository hosting with web interface

All components run on the same VM and are accessible through clean URLs on a single domain.

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
[Single VM]
├── Nginx Reverse Proxy ← routing, SSL, monitoring
├── AI Agent Service ← project creation & code generation
└── Gitea Git Server ← repository hosting & web interface
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
- `vm_cpu/memory/disk`: Single VM resources (all services co-located)

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
├── tfgrid-compose.yaml    # App definition (single-vm pattern)
├── deployment/            # Component orchestration hooks
│   ├── setup.sh          # Install all components on single VM
│   ├── configure.sh      # Configure nginx routing
│   └── healthcheck.sh    # Verify component health
├── scripts/              # AI project management scripts
├── README.md             # This file
└── LICENSE               # Apache 2.0
```

## Development

This app is maintained by TFGrid Studio. It integrates components from:
- [tfgrid-ai-agent](https://github.com/tfgrid-studio/tfgrid-ai-agent) - AI coding assistant logic
- [tfgrid-gitea](https://github.com/tfgrid-studio/tfgrid-gitea) - Git hosting setup
- Single-VM pattern from [tfgrid-compose](https://github.com/tfgrid-studio/tfgrid-compose) - Infrastructure

## Documentation

- [Pattern Documentation](https://docs.tfgrid.studio/patterns/tfgrid-ai-stack)
- [API Reference](https://docs.tfgrid.studio/patterns/tfgrid-ai-stack/api)
- [Troubleshooting](https://docs.tfgrid.studio/patterns/tfgrid-ai-stack/troubleshooting)

## Support

- **📚 Documentation:** [docs.tfgrid.studio](https://docs.tfgrid.studio)
- **🐛 Issues:** [GitHub Issues](https://github.com/tfgrid-studio/tfgrid-ai-stack/issues)
- **💬 Discussions:** [GitHub Discussions](https://github.com/orgs/tfgrid-studio/discussions)
- **📧 Contact:** [tfgrid.studio/contact](https://tfgrid.studio/contact)