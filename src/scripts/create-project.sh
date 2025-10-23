#!/bin/bash
# AI-Agent Project Creator
# Sets up a new project for using the AI agent loop technique with Qwen
#
# Modes:
#   Interactive: Run without env vars, will prompt for all inputs
#   Non-interactive: Set NON_INTERACTIVE=1 and provide env vars:
#     - PROJECT_NAME, TIME_DURATION, PROMPT_TYPE, CUSTOM_PROMPT (or PROJECT_TYPE)

set -e

# Check if qwen is installed
if ! command -v qwen &> /dev/null; then
    echo "Qwen CLI is not installed. Please install it first:"
    echo "  npm install -g @qwen-code/qwen-code@latest"
    exit 1
fi

# Detect mode
if [ "${NON_INTERACTIVE:-0}" = "1" ]; then
    # Non-interactive mode - validate required env vars
    if [ -z "$PROJECT_NAME" ] || [ -z "$TIME_DURATION" ] || [ -z "$PROMPT_TYPE" ]; then
        echo "❌ Error: NON_INTERACTIVE mode requires: PROJECT_NAME, TIME_DURATION, PROMPT_TYPE"
        exit 1
    fi
    
    if [ "$PROMPT_TYPE" = "1" ] && [ -z "$CUSTOM_PROMPT" ]; then
        echo "❌ Error: PROMPT_TYPE=1 requires CUSTOM_PROMPT"
        exit 1
    fi
    
    if [ "$PROMPT_TYPE" = "2" ] && [ -z "$PROJECT_TYPE" ]; then
        echo "❌ Error: PROMPT_TYPE=2 requires PROJECT_TYPE (1-6)"
        exit 1
    fi
    
    echo "🚀 AI-Agent Project Creator (Non-Interactive Mode)"
    echo "===================================================="
    echo ""
else
    # Interactive mode
    echo "🚀 AI-Agent Project Creator"
    echo "=============================="
    echo ""
fi

# Check authentication FIRST before asking for any input
echo "🔍 Checking Qwen authentication..."
if ! su - developer -c 'test -f ~/.qwen/settings.json' 2>/dev/null; then
    echo ""
    echo "⚠️  Qwen is not authenticated!"
    echo ""
    echo "Please authenticate first by running:"
    echo "  tfgrid-compose login"
    echo ""
    exit 1
fi
echo "✅ Authenticated"
echo ""

# Get project name from argument, env var, or prompt
if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="$1"
fi

if [ -z "$PROJECT_NAME" ] && [ "${NON_INTERACTIVE:-0}" != "1" ]; then
    read -p "Enter project name: " PROJECT_NAME
    echo ""
fi

if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Error: Project name is required"
    exit 1
fi

# Determine workspace base directory
WORKSPACE_BASE="${PROJECT_WORKSPACE:-/home/developer/code}"

# Use tfgrid-ai-agent-projects directory for all AI agent projects
PROJECTS_DIR="$WORKSPACE_BASE/tfgrid-ai-agent-projects"

# Note: Git config for this context should be set via:
# tfgrid-compose git-config --context=tfgrid-ai-agent

# Create projects directory if it doesn't exist
mkdir -p "$PROJECTS_DIR"

# Check if project already exists in workspace
if [ -d "$PROJECTS_DIR/$PROJECT_NAME" ]; then
    echo "❌ Error: Project '$PROJECT_NAME' already exists in workspace"
    exit 1
fi

# Get time duration with validation
TIME_TEXT=""
while [ -z "$TIME_TEXT" ]; do
    # In non-interactive mode, TIME_DURATION is already set from env var
    if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
        echo "⏱️  How long should the AI agent run?"
        echo "Examples: 30m, 1h, 2h30m, indefinite"
        echo ""
        read -p "Enter duration: " TIME_DURATION
        echo ""
    fi
    
    # Parse time duration
    if [[ "$TIME_DURATION" =~ ^[Ii]nf ]]; then
        TIME_TEXT="indefinite"
    elif [[ "$TIME_DURATION" =~ ^([0-9]+)h([0-9]+)m$ ]]; then
        HOURS="${BASH_REMATCH[1]}"
        MINUTES="${BASH_REMATCH[2]}"
        TIME_TEXT="in $HOURS hour(s) and $MINUTES minute(s) of time"
    elif [[ "$TIME_DURATION" =~ ^([0-9]+)h(our)?s?$ ]]; then
        HOURS="${BASH_REMATCH[1]}"
        TIME_TEXT="in $HOURS hour(s) of time"
    elif [[ "$TIME_DURATION" =~ ^([0-9]+)m(in)?(ute)?s?$ ]]; then
        MINUTES="${BASH_REMATCH[1]}"
        TIME_TEXT="in $MINUTES minute(s) of time"
    else
        echo "❌ Error: Invalid duration format '$TIME_DURATION'"
        echo "   Valid formats: 30m, 1h, 2h30m, indefinite"
        echo ""
        # In non-interactive mode, exit on error
        if [ "${NON_INTERACTIVE:-0}" = "1" ]; then
            exit 1
        fi
        # In interactive mode, loop will continue
    fi
done

# Create project directory in projects subdirectory
echo "🔧 Creating project directory..."
mkdir -p "$PROJECTS_DIR/$PROJECT_NAME"
cd "$PROJECTS_DIR/$PROJECT_NAME"

# Initialize git repo
echo "🔧 Initializing git repository..."
git config --global init.defaultBranch main 2>/dev/null || true
git init
git checkout -b main 2>/dev/null || git checkout main 2>/dev/null || true

# Configure git user - read from developer's global config if running as root
# (create script may be called via SSH as root, but we want developer's config)
if [ "$USER" = "root" ] || [ "$EUID" -eq 0 ]; then
    # Running as root - read developer's git config
    GIT_USER_NAME=$(su - developer -c "git config --global user.name" 2>/dev/null || echo "")
    GIT_USER_EMAIL=$(su - developer -c "git config --global user.email" 2>/dev/null || echo "")
else
    # Running as developer or other user - read their config
    GIT_USER_NAME=$(git config --global user.name 2>/dev/null || echo "")
    GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
fi

# In interactive mode, show git config status
if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
    if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
        # Git is configured - show and allow override
        echo ""
        echo "👤 Git Configuration:"
        echo "   Name:  $GIT_USER_NAME"
        echo "   Email: $GIT_USER_EMAIL"
        echo "   ✅ Loaded from global config"
        echo ""
        
        # Loop until valid input
        while true; do
            read -p "Press Enter to continue, or type 'override' to change: " RESPONSE
            
            if [ -z "$RESPONSE" ]; then
                # User pressed Enter - use existing config
                echo ""
                git config user.name "$GIT_USER_NAME"
                git config user.email "$GIT_USER_EMAIL"
                break
            elif [[ "$RESPONSE" == "override" ]]; then
                # User wants to override
                echo ""
                echo "Enter new git identity:"
                read -p "   Name: " GIT_USER_NAME
                read -p "   Email: " GIT_USER_EMAIL
                echo ""
                
                if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
                    git config user.name "$GIT_USER_NAME"
                    git config user.email "$GIT_USER_EMAIL"
                    echo "   ✅ Using: $GIT_USER_NAME <$GIT_USER_EMAIL>"
                    echo ""
                fi
                break
            else
                # Invalid input - show error and re-ask
                echo ""
                echo "❌ Invalid input: '$RESPONSE'"
                echo "   Please press Enter to continue, or type 'override' to change"
                echo ""
            fi
        done
    else
        # Git NOT configured - prompt for it
        echo ""
        echo "👤 Git Configuration:"
        echo "   ⚠️  No global git config found"
        echo "   Tip: Set it with 'tfgrid-compose update-git-config tfgrid-ai-agent'"
        echo ""
        read -p "   Enter your name: " GIT_USER_NAME
        read -p "   Enter your email: " GIT_USER_EMAIL

        if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
            # Set for this project
            git config user.name "$GIT_USER_NAME"
            git config user.email "$GIT_USER_EMAIL"
            echo "   ✅ Git config set for this project"
        fi
    fi
elif [ -z "$GIT_USER_NAME" ]; then
    # Non-interactive mode: use default if not configured
    git config user.name "AI Agent"
    git config user.email "ai-agent@localhost"
fi

# Create basic directory structure
echo "🔧 Creating project structure..."
mkdir -p src target .agent docs .qwen

# Ask for prompt type (or use env var in non-interactive mode)
if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
    echo "📝 Choose prompt type:"
    echo "1) Custom prompt (paste your own)"
    echo "2) Generic template (select from options)"
    echo ""
    read -p "Select (1-2) [2]: " PROMPT_TYPE
    PROMPT_TYPE=${PROMPT_TYPE:-2}
    echo ""
fi

# Default prefix for all prompts
DEFAULT_PREFIX="Your job is to work on this codebase and maintain the repository.

Make a commit and push your changes after every single file edit.

Use the .agent/ directory as a scratchpad for your work. Store long term plans and todo lists there.

Follow existing code patterns and conventions.

CURRENT STATUS: Starting the project

The specific project requirements:"

# Handle custom prompt
if [ "$PROMPT_TYPE" = "1" ]; then
    if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
        echo "📋 Enter your custom prompt (press Ctrl+D when done):"
        echo ""
        CUSTOM_PROMPT=$(cat)
    fi
    # In non-interactive mode, CUSTOM_PROMPT is already set from env var
    
    # Build final prompt (without time management - that goes in .agent/)
    cat > prompt.md << EOF
$DEFAULT_PREFIX

$CUSTOM_PROMPT
EOF
    
    # Create time management instructions in .agent/ if not indefinite
    # This file is immutable and prepended at runtime by agent-loop.sh
    if [ "$TIME_TEXT" != "indefinite" ]; then
        cat > .agent/time_management_instructions.md << EOF
## CRITICAL TIME MANAGEMENT

**Time Constraint**: You have $TIME_TEXT to complete this work.

**At the START of EVERY iteration, you MUST:**

1. Check \`.agent/time_log.txt\` for:
   - Project Start Time: [timestamp]
   - Time Constraint: $TIME_TEXT

2. Calculate your deadline: Start Time + time constraint

3. Check \`.agent/last_iteration_start.txt\` - when did your LAST iteration start?

4. **If the last iteration started AFTER the deadline:**
   - You have exceeded your time budget
   - Immediately create the stop signal: \`touch .agent/STOP\`
   - Write a final summary in \`.agent/final_summary.md\` of what was completed
   - The loop will exit gracefully
   - DO NOT continue working

5. **If still within deadline:**
   - Note remaining time in your planning
   - Prioritize high-value tasks
   - Continue working efficiently

**This is a hard requirement. Check time at every iteration start.**

---

EOF
    fi
    
    echo ""
    echo "✅ Custom prompt configured"
else
    # Ask for project type (or use env var in non-interactive mode)
    if [ "${NON_INTERACTIVE:-0}" != "1" ]; then
        echo "📋 Select generic project template:"
        echo "1) Codebase Porting (e.g., React to Vue)"
        echo "2) Translation Services"
        echo "3) Editing & Proofreading"
        echo "4) Copywriting"
        echo "5) Website Creation"
        echo "6) Other/General Purpose"
        echo ""
        read -p "Select (1-6) [1]: " PROJECT_TYPE
        PROJECT_TYPE=${PROJECT_TYPE:-1}
        echo ""
    fi
    
    # Start with default prefix
    cat > prompt.md << EOF
$DEFAULT_PREFIX
EOF
    
    # Create time management instructions in .agent/ if not indefinite
    # This file is immutable and prepended at runtime by agent-loop.sh
    if [ "$TIME_TEXT" != "indefinite" ]; then
        cat > .agent/time_management_instructions.md << EOF
## CRITICAL TIME MANAGEMENT

**Time Constraint**: You have $TIME_TEXT to complete this work.

**At the START of EVERY iteration, you MUST:**

1. Check \`.agent/time_log.txt\` for:
   - Project Start Time: [timestamp]
   - Time Constraint: $TIME_TEXT

2. Calculate your deadline: Start Time + time constraint

3. Check \`.agent/last_iteration_start.txt\` - when did your LAST iteration start?

4. **If the last iteration started AFTER the deadline:**
   - You have exceeded your time budget
   - Immediately create the stop signal: \`touch .agent/STOP\`
   - Write a final summary in \`.agent/final_summary.md\` of what was completed
   - The loop will exit gracefully
   - DO NOT continue working

5. **If still within deadline:**
   - Note remaining time in your planning
   - Prioritize high-value tasks
   - Continue working efficiently

**This is a hard requirement. Check time at every iteration start.**

---

EOF
    fi
    
    # Add specific template content based on project type
    case $PROJECT_TYPE in
        1)
            # Codebase Porting
            cat >> prompt.md << 'EOF'

Port my-[SOURCE]-project to my-[TARGET]-project ([SOURCE] to [TARGET]).

You have access to the current my-[SOURCE]-project repository as well as the my-[TARGET]-project repository.

Use the my-[TARGET]-project/.agent/ directory as a scratchpad for your work. Store long term plans and todo lists there.

Please ask me for more details about the specific project requirements, source code location, and target requirements.
EOF
            ;;
        2)
            # Translation Services
            cat >> prompt.md << 'EOF'

Provide professional translation services for documents, websites, and multimedia content.

You have access to the source documents and need to translate them accurately while maintaining cultural appropriateness.

Please ask me for more details about the specific documents, languages, and requirements.
EOF
            ;;
        3)
            # Editing & Proofreading
            cat >> prompt.md << 'EOF'

Provide expert proofreading and editing services to ensure content is polished, accurate, and meets the highest quality standards.

You have access to the source documents and need to review them for grammar, style, consistency, and clarity.

Please ask me for more details about the specific documents and requirements.
EOF
            ;;
        4)
            # Copywriting
            cat >> prompt.md << 'EOF'

Create creative and compelling copy that engages your audience and drives action across all marketing channels.

You have access to the project requirements and need to craft copy that resonates with local audiences while maintaining your brand's voice and identity.

Please ask me for more details about the specific requirements and target audience.
EOF
            ;;
        5)
            # Website Creation
            cat >> prompt.md << 'EOF'

Create custom websites designed to showcase your brand and optimized for user experience and search engines.

You have access to the project requirements and need to build responsive, accessible, and conversion-focused websites.

Please ask me for more details about the specific requirements and design preferences.
EOF
            ;;
        *)
            # Other
            cat >> prompt.md << 'EOF'

Please ask me for more details about the specific project requirements.
EOF
            ;;
    esac
    
    echo "✅ Generic template configured"
fi

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

# Create .gitignore
cat > .gitignore << 'EOF'
# AI Agent metadata (system files)
.agent/TODO.md
.agent/time_log.txt
.agent/last_iteration_start.txt
.agent/time_management_instructions.md
.agent/final_summary.md
.agent/edit_history.log
.agent/STOP

# Logs
*.log

# System files
.DS_Store

# Node modules if using npm
node_modules/

# Python cache
__pycache__/
*.pyc

# Build outputs
dist/
build/
*.egg-info/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.cache/
EOF

# Create initial TODO file
cat > .agent/TODO.md << 'EOF'
# AI Agent TODO List

## Status
- Running: No
- Last Action: Project initialization

## TODO
- [ ] Define specific task for this AI agent agent
- [ ] Update prompt.md with detailed instructions
- [ ] Begin main task

## Progress Log
EOF
echo "- $(date): Project initialized" >> .agent/TODO.md

# Create time log file with current timestamp
CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
cat > .agent/time_log.txt << EOF
Project Start Time: $CURRENT_TIME
Time Constraint: $TIME_TEXT
EOF

# Create README
cat > README.md << EOF
# $PROJECT_NAME

This project was created with AI-Agent.

## Configuration

- **Time Constraint**: $TIME_TEXT
- **Prompt Type**: $([ "$PROMPT_TYPE" = "1" ] && echo "Custom" || echo "Generic Template")

## Setup

The project is ready to run! The prompt has been configured in \`prompt.md\`.

To start this AI agent:

\`\`\`bash
tfgrid-compose run $PROJECT_NAME
\`\`\`

To monitor progress:

\`\`\`bash
tfgrid-compose monitor $PROJECT_NAME
\`\`\`

## Current Status

Project initialized and ready to begin.

{{ ... }}

See \`.agent/TODO.md\` for the agent's tracking file.
EOF

# Initialize git repository
echo "🔧 Initializing git repository..."
git add .
git commit -m "Initial commit: Project '$PROJECT_NAME' created with AI-Agent"

# Fix ownership if running as root (ensure developer user can access everything)
if [ "$USER" = "root" ] || [ "$EUID" -eq 0 ]; then
    echo "🔧 Setting proper ownership..."
    chown -R developer:developer "$PROJECTS_DIR/$PROJECT_NAME"
fi

# Reload systemd daemon to pick up new service template instance
echo "🔧 Reloading systemd daemon..."
if systemctl daemon-reload 2>/dev/null; then
    echo "✅ Systemd daemon reloaded"
else
    echo "⚠️  Failed to reload systemd daemon"
fi

echo ""
echo "✅ Project '$PROJECT_NAME' created successfully!"
echo ""
echo "Configuration:"
echo "  - Time constraint: $TIME_TEXT"
echo "  - Prompt: $([ "$PROMPT_TYPE" = "1" ] && echo "Custom" || echo "Generic template")"
echo ""

# Ask if user wants to start the AI agent now (unless skipped by caller or in non-interactive mode)
if [ "${SKIP_AUTOSTART:-0}" != "1" ] && [ "${NON_INTERACTIVE:-0}" != "1" ]; then
    echo "🚀 Do you want to start the AI agent now for the project '$PROJECT_NAME'?"
    read -p "Start now? (y/N): " START_NOW
    echo ""

    if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
        echo "Starting AI agent for project '$PROJECT_NAME'..."
        echo ""
        # Use the run-project.sh script directly
        "$(dirname "${BASH_SOURCE[0]}")/run-project.sh" "$PROJECT_NAME"
    else
        echo "Next steps:"
        echo ""
        echo "To start the AI agent for this project:"
        echo "  tfgrid-compose run $PROJECT_NAME"
        echo ""
        echo "To monitor progress:"
        echo "  tfgrid-compose monitor $PROJECT_NAME"
        echo ""
        echo "To view logs:"
        echo "  tfgrid-compose logs $PROJECT_NAME"
        echo ""
        echo "To stop the AI agent:"
        echo "  tfgrid-compose stop $PROJECT_NAME"
        echo ""
    fi
fi