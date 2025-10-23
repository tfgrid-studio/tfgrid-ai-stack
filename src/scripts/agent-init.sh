#!/bin/bash
# AI Agent Project Initializer
# Sets up a new project for using the AI agent loop technique with Qwen

set -e

# Check if qwen is installed
if ! command -v qwen &> /dev/null; then
    echo "Qwen CLI is not installed. Please install it first:"
    echo "  npm install -g @qwen-code/qwen-code@latest"
    exit 1
fi

# Get project name from command line argument
PROJECT_NAME="$1"
if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name>"
    echo "Example: $0 my-react-to-vue-project"
    exit 1
fi

# Create project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Create basic directory structure
mkdir -p source-repo target-repo .agent

# Create default prompt file
cat > prompt.md << 'EOF'
Your job is to work on this codebase and maintain the repository.

Current status: Starting the project

Make a commit and push your changes after every single file edit.

Use the .agent/ directory as a scratchpad for your work. Store long term plans and todo lists there.

Follow existing code patterns and conventions.
EOF

# Create default Qwen configuration
mkdir -p .qwen
cat > .qwen/config.json << 'EOF'
{
  "model": "qwen-max",
  "temperature": 0.2,
  "max_tokens": 4000,
  "context_window": 32000,
  "tools": {
    "sandbox": false,
    "allowed": ["write_file", "edit", "read_file", "web_fetch", "todo_write", "task", "glob", "run_shell_command"]
  },
  "approvalMode": "yolo"
}
EOF

# Create .qwenignore file
cat > .qwenignore << 'EOF'
node_modules/
.git/
dist/
build/
*.log
.env
.env.local
TODO_BACKUP/
.agent/TODO_BACKUP.md
EOF

# Create initial TODO file
cat > .agent/TODO.md << 'EOF'
# AI Agent TODO List

## Status
- Running: No
- Last Action: Initialization
- Iteration: 0

## TODO
- [ ] Define specific task for the AI agent
- [ ] Update prompt.md with detailed instructions
- [ ] Initialize source repository if needed
- [ ] Prepare target repository structure
- [ ] Start AI agent loop when ready

## Progress Log
- $(date): Project initialized

EOF

# Create a README for the project
cat > README.md << 'EOF'
# AI Agent Project: [Project Name]

This project uses the AI agent loop technique with Qwen to [describe what you're doing].

## Setup

1. Update `prompt.md` with your specific instructions
2. Initialize your source/target repositories as needed
3. Run this AI agent loop:

```bash
../agent-loop.sh
```

## Current Status

Update this section with progress.

## TODO

See `.agent/TODO.md` for the agent's tracking file.
EOF

# Make scripts executable
chmod +x *.sh 2>/dev/null || true

echo "AI agent project '$PROJECT_NAME' initialized successfully!"
echo ""
echo "Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. Update prompt.md with your specific instructions"
echo "3. Set up your source and target repositories"
echo "4. Run this AI agent loop: ../agent-loop.sh"
echo ""
echo "For advanced usage: ../agent-loop-advanced.sh"