#!/bin/bash
# AI Agent Loop Script
# This script runs Qwen in an infinite loop for continuous automated programming

# Note: NOT using 'set -e' here because we want the loop to continue even if individual Qwen commands fail

# Signal handling for graceful shutdown
trap 'echo "Received shutdown signal, exiting gracefully..."; exit 0' SIGTERM SIGINT

# Accept project directory as argument (optional)
PROJECT_DIR="${1:-$(pwd)}"

# Change to project directory first
cd "$PROJECT_DIR" || {
    echo "❌ Error: Cannot access project directory: $PROJECT_DIR"
    exit 1
}

echo "Starting AI Agent Loop..."
echo "Working directory: $(pwd)"
echo "Starting at: $(date)"
echo "PID: $$"
echo "------------------------"

# Configuration (all paths relative to project directory)
PROMPT_FILE="prompt.md"
LOG_FILE="agent-output.log"
ERROR_LOG="agent-errors.log"
AGENT_DIR=".agent"

# Create agent directory if it doesn't exist
mkdir -p "$AGENT_DIR"

# Initialize TODO tracking
TODO_FILE="$AGENT_DIR/TODO.md"
if [ ! -f "$TODO_FILE" ]; then
    echo "# AI Agent TODO List

## Status
- Running: Yes
- Last Action: Initialization

## TODO
- [ ] Initial setup complete
- [ ] Begin main task

" > "$TODO_FILE"
fi

echo "Prompt file: $PROMPT_FILE"
echo "Logging to: $LOG_FILE"
echo "------------------------"

# Main loop

while true; do
    # Log iteration start time for time tracking
    ITERATION_START=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$(date): Starting iteration" >> "$LOG_FILE"
    echo "$ITERATION_START" > "$AGENT_DIR/last_iteration_start.txt"
    
    # Run Qwen with the current prompt - allow all tools (yolo mode) with proper configuration
    # If time management instructions exist, prepend them to the prompt
    TIME_MGMT_FILE="$AGENT_DIR/time_management_instructions.md"
    if [ -f "$TIME_MGMT_FILE" ]; then
        # Concatenate time management instructions with user prompt
        if cat "$TIME_MGMT_FILE" "$PROMPT_FILE" | qwen --approval-mode yolo --sandbox false 2>>"$ERROR_LOG" >> "$LOG_FILE"; then
            QWEN_SUCCESS=true
        else
            QWEN_SUCCESS=false
        fi
    else
        # No time management - just use prompt
        if cat "$PROMPT_FILE" | qwen --approval-mode yolo --sandbox false 2>>"$ERROR_LOG" >> "$LOG_FILE"; then
            QWEN_SUCCESS=true
        else
            QWEN_SUCCESS=false
        fi
    fi
    
    if [ "$QWEN_SUCCESS" = true ]; then
        # On success, commit changes
        git add .
        if git diff --cached --quiet; then
            echo "$(date): No changes to commit" >> "$LOG_FILE"
        else
            git commit -m "Agent: Automated update at $(date)" >> "$LOG_FILE" 2>&1
            echo "$(date): Changes committed successfully" >> "$LOG_FILE"

            # Push to Gitea if remote configured
            if git remote get-url origin >/dev/null 2>&1; then
                if git push origin main >> "$LOG_FILE" 2>&1; then
                    echo "$(date): ✅ Pushed to Gitea" >> "$LOG_FILE"
                else
                    echo "$(date): ⚠️ Push to Gitea failed, continuing" >> "$LOG_FILE"
                fi
            fi
        fi
    else
        # On error, log and continue
        echo "$(date): Qwen execution failed, continuing loop" >> "$LOG_FILE"
        echo "$(date): Error details logged to $ERROR_LOG" >> "$LOG_FILE"
    fi
    
    # Small delay to avoid overwhelming the API
    sleep 10
    
    # Update TODO status
    STATUS_MSG="Last run: $(date)"
    sed -i "s/Last Action:.*/Last Action: $STATUS_MSG/" "$TODO_FILE"
    
    # Check if we should stop (optional stop condition)
    # This could be based on a file, a condition in the TODO, etc.
    if [ -f "$AGENT_DIR/STOP" ]; then
        echo "$(date): Stop signal received, exiting loop" >> "$LOG_FILE"
        break
    fi
done

echo "AI agent loop stopped at: $(date)"
echo "Final status: $([ -f "$AGENT_DIR/STOP" ] && echo "Stopped by signal" || echo "Completed naturally")"