# AI-Agent Templates

This directory contains project templates for the enhanced AI-Agent workflow.

## Available Templates

### 1. Generic Template (`generic/`)
A basic template for general-purpose AI agent projects.

### 2. React to Vue Conversion (`react-to-vue/`)
Template specifically designed for converting React codebases to Vue 3 Composition API.

### 3. Python to TypeScript Conversion (`python-to-ts/`)
Template for converting Python codebases to TypeScript.

## Usage

Templates are used automatically by the `create-project.sh` script based on user selection.

To create a new project with a specific template:

```bash
make create
# Follow the interactive prompts to select a template
```

## Custom Templates

You can create custom templates by:

1. Creating a new directory in `templates/`
2. Adding the required files and structure
3. Updating the `create-project.sh` script to include your template

## Template Structure

Each template should include:
- `prompt.md` - Initial prompt for this AI agent agent
- `.qwen/config.json` - Qwen configuration
- `.gitignore` - Git ignore rules
- `README.md` - Project documentation template
- `.agent/TODO.md` - Initial TODO tracking file