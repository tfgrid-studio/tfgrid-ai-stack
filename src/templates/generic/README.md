# Generic AI Agent Project Template

This is a generic template for AI agent projects.

## 🚨 AI Agent Safety Guidelines

**CRITICAL:** This template includes safety guidelines to prevent the AI agent from getting stuck in blocking commands during troubleshooting.

### Never Use Blocking Commands:
- ❌ `journalctl -f` (use: `journalctl -n 50 --no-pager`)
- ❌ `tail -f /path/to/log` (use: `tail -n 50 /path/to/log`)
- ❌ `systemctl status` (use: `systemctl status --no-pager`)
- ❌ `ping -f` (use: `ping -c 10`)
- ❌ `watch command` (use: `timeout 30s command`)

### Always Add Safety Flags:
- ✅ `--no-pager` for status/viewing commands
- ✅ `-n 50` for log viewing (limits to 50 lines)
- ✅ `-c 10` for network tests (limits to 10 packets)
- ✅ `timeout 30s` for any potentially long-running command

These guidelines ensure the AI agent can troubleshoot effectively without getting stuck in infinite blocking commands.

## Files

- `prompt.md` - Main prompt for this AI agent agent (includes safety guidelines)
- `.qwen/config.json` - Qwen configuration
- `.gitignore` - Git ignore rules
- `.agent/TODO.md` - Task tracking file

## Usage

This template provides a basic structure that can be customized for any type of project while maintaining safety guidelines.