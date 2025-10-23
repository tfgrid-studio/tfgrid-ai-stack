#!/bin/bash
# edit-project.sh - Edit a project prompt to change AI behavior
# Part of the AI-Agent framework

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-project.sh"

PROJECT_NAME="$1"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name>"
    exit 1
fi

# Find project in workspace
PROJECT_PATH=$(find_project_path "$PROJECT_NAME")

if [ -z "$PROJECT_PATH" ]; then
    echo "❌ Error: Project '$PROJECT_NAME' not found"
    echo ""
    echo "Available projects:"
    list_projects_brief
    exit 1
fi

echo "✏️  Editing project: $PROJECT_NAME"
echo "──────────────────────────────"
echo ""

cd "$PROJECT_PATH"

# Check current version
if [ -f ".agent/time_log.txt" ]; then
    CURRENT_VERSION=$(grep "Project Version:" .agent/time_log.txt 2>/dev/null | cut -d':' -f2 | tr -d ' ' || echo "1")
    CURRENT_TIME_CONSTRAINT=$(grep "Time Constraint:" .agent/time_log.txt | cut -d':' -f2- | xargs || echo "indefinite")
else
    CURRENT_VERSION="1"
    CURRENT_TIME_CONSTRAINT="indefinite"
fi

NEXT_VERSION=$((CURRENT_VERSION + 1))

# Check if project is running
PROJECT_PID=$(pgrep -f "agent-loop.sh.*$PROJECT_NAME" || echo "")

echo "Current configuration:"
echo "  Status: $([ -n "$PROJECT_PID" ] && echo "Running (PID: $PROJECT_PID)" || echo "Stopped")"
echo "  Time constraint: $CURRENT_TIME_CONSTRAINT"
echo "  Version: $CURRENT_VERSION"
echo ""
echo "Current prompt:"
echo "─────────────────────────────────"
cat prompt.md
echo "─────────────────────────────────"
echo ""

# Check for uncommitted changes
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    echo "⚠️  Warning: You have uncommitted changes in this project."
    echo ""
    git status --short
    echo ""
    
    # Step 1: Proceed anyway?
    read -p "Proceed with editing anyway? (y/N): " proceed
    if [ "$proceed" != "y" ] && [ "$proceed" != "Y" ]; then
        echo "❌ Edit cancelled"
        exit 1
    fi
    
    # Step 2: Auto-commit?
    read -p "Auto-commit these changes before editing? (y/N): " commit
    if [ "$commit" = "y" ] || [ "$commit" = "Y" ]; then
        git add .
        git commit -m "Work in progress before project edit (v$NEXT_VERSION)" || true
        echo "✅ Changes committed"
    else
        echo "⚠️  Continuing without committing (changes will remain uncommitted)"
    fi
    echo ""
fi

# Stop project if running
if [ -n "$PROJECT_PID" ]; then
    echo "🛑 Project is running. Stopping it now..."
    cd "$(dirname "$0")"
    ./stop-project.sh "$PROJECT_NAME" || true
    cd "$PROJECT_PATH"
    echo "✅ Project stopped"
    echo ""
    sleep 1
fi

# Prompt editing mode
echo "📝 How would you like to edit the prompt?"
echo "1) Rewrite completely (paste new prompt, overwrites current)"
echo "2) Edit in place (opens prompt.md in your editor)"
echo "3) Keep current prompt (only change time constraint)"
echo "4) Cancel"
echo ""
read -p "Select (1-4): " EDIT_MODE

PROMPT_MODIFIED=false
EDIT_MODE_TEXT=""

case $EDIT_MODE in
    1)
        echo ""
        echo "📋 Enter your new prompt (press Ctrl+D when done):"
        echo ""
        NEW_PROMPT=$(cat)
        
        # Keep the default prefix
        cat > prompt.md << EOF
Your job is to work on this codebase and maintain the repository.

Make a commit and push your changes after every single file edit.

Use the .agent/ directory as a scratchpad for your work. Store long term plans and todo lists there.

Follow existing code patterns and conventions.

CURRENT STATUS: Starting the project

The specific project requirements:

$NEW_PROMPT
EOF
        echo ""
        echo "✅ Prompt rewritten"
        PROMPT_MODIFIED=true
        EDIT_MODE_TEXT="Rewrite"
        ;;
    2)
        echo ""
        echo "Opening prompt.md in ${EDITOR:-nano}..."
        ${EDITOR:-nano} prompt.md
        echo "✅ Prompt edited"
        PROMPT_MODIFIED=true
        EDIT_MODE_TEXT="Edit in place"
        ;;
    3)
        echo "✅ Keeping current prompt"
        EDIT_MODE_TEXT="No change"
        ;;
    4)
        echo "❌ Edit cancelled"
        exit 0
        ;;
    *)
        echo "❌ Invalid selection"
        exit 1
        ;;
esac

echo ""

# Time constraint
echo "⏱️  Change time constraint? (current: $CURRENT_TIME_CONSTRAINT)"
echo "Examples: 30m, 1h, 2h30m, indefinite"
read -p "Enter new duration or press ENTER to keep current: " TIME_DURATION

TIME_TEXT=""
TIME_CHANGED=false

if [ -z "$TIME_DURATION" ]; then
    TIME_TEXT="$CURRENT_TIME_CONSTRAINT"
    echo "✅ Keeping time constraint: $CURRENT_TIME_CONSTRAINT"
else
    # Parse time duration (same logic as create-project.sh)
    if [[ "$TIME_DURATION" =~ ^[Ii]nf ]]; then
        TIME_TEXT="indefinite"
        TIME_CHANGED=true
    elif [[ "$TIME_DURATION" =~ ^([0-9]+)h([0-9]+)m$ ]]; then
        HOURS="${BASH_REMATCH[1]}"
        MINUTES="${BASH_REMATCH[2]}"
        TIME_TEXT="in $HOURS hour(s) and $MINUTES minute(s) of time"
        TIME_CHANGED=true
    elif [[ "$TIME_DURATION" =~ ^([0-9]+)h(our)?s?$ ]]; then
        HOURS="${BASH_REMATCH[1]}"
        TIME_TEXT="in $HOURS hour(s) of time"
        TIME_CHANGED=true
    elif [[ "$TIME_DURATION" =~ ^([0-9]+)m(in)?(ute)?s?$ ]]; then
        MINUTES="${BASH_REMATCH[1]}"
        TIME_TEXT="in $MINUTES minute(s) of time"
        TIME_CHANGED=true
    else
        echo "❌ Error: Invalid duration format '$TIME_DURATION'"
        echo "   Using current constraint: $CURRENT_TIME_CONSTRAINT"
        TIME_TEXT="$CURRENT_TIME_CONSTRAINT"
    fi
fi

echo ""

# Regenerate time management instructions if time constraint changed or was set
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
    echo "✅ Time management instructions regenerated"
else
    # Remove time management for indefinite
    if [ -f ".agent/time_management_instructions.md" ]; then
        rm -f .agent/time_management_instructions.md
        echo "✅ Time management instructions removed (indefinite mode)"
    fi
fi

# Update time_log.txt with new version and start time
CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
cat > .agent/time_log.txt << EOF
Project Start Time: $CURRENT_TIME
Time Constraint: $TIME_TEXT
Project Version: $NEXT_VERSION
Last Edited: $CURRENT_TIME
EOF

# Log edit to history
if [ ! -f ".agent/edit_history.log" ]; then
    echo "# Project Edit History" > .agent/edit_history.log
    echo "" >> .agent/edit_history.log
fi

cat >> .agent/edit_history.log << EOF
================================================================================
Edit Version: $NEXT_VERSION
Edit Date: $CURRENT_TIME
Previous Time Constraint: $CURRENT_TIME_CONSTRAINT
New Time Constraint: $TIME_TEXT
Prompt Modified: $PROMPT_MODIFIED
Editor Mode: $EDIT_MODE_TEXT
Notes: Project configuration updated
================================================================================

EOF

echo ""
echo "✅ Configuration updated (Version $NEXT_VERSION):"
echo "  - Prompt: $([ "$PROMPT_MODIFIED" = true ] && echo "Modified ($EDIT_MODE_TEXT)" || echo "Unchanged")"
echo "  - Time constraint: $CURRENT_TIME_CONSTRAINT → $TIME_TEXT"
echo "  - Edit logged in .agent/edit_history.log"
echo ""

# Commit configuration changes
echo "📝 Committing configuration changes..."
git add prompt.md .agent/time_log.txt .agent/edit_history.log
if [ "$TIME_TEXT" != "indefinite" ]; then
    git add .agent/time_management_instructions.md
fi

git commit -m "Project edit v$NEXT_VERSION: Updated configuration" || echo "⚠️  No changes to commit"
echo ""

# Ask to restart
read -p "🚀 Start project with new configuration? (y/N): " start
if [ "$start" = "y" ] || [ "$start" = "Y" ]; then
    echo ""
    echo "Starting AI agent..."
    cd "$(dirname "$0")"
    ./run-project.sh "$PROJECT_NAME"
    echo ""
    echo "📊 Project now at Version $NEXT_VERSION"
    echo "📝 Check .agent/edit_history.log for full history"
else
    echo ""
    echo "✅ Project configuration updated but not started"
    echo "📊 Project now at Version $NEXT_VERSION"
    echo "Start later with: make run"
fi
