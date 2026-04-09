#!/usr/bin/env bash
# Check that task-master CLI is installed and .taskmaster/ is initialized

set -euo pipefail

# Check task-master is available
if ! command -v task-master >/dev/null 2>&1; then
  echo "ERROR: task-master CLI not found."
  echo "Install it with: npm install -g task-master-ai"
  exit 1
fi

TM_VERSION=$(task-master --version 2>/dev/null || echo "unknown")
echo "TASKMASTER_VERSION: $TM_VERSION"

# Check if .taskmaster/ exists in current project
if [ -d .taskmaster ]; then
  echo "TASKMASTER_INIT: yes"
  # Check for existing tasks
  if [ -f .taskmaster/tasks/tasks.json ]; then
    TASK_COUNT=$(node -e "const t=require('./.taskmaster/tasks/tasks.json'); console.log(Array.isArray(t.tasks)?t.tasks.length:0)" 2>/dev/null || echo "0")
    DONE_COUNT=$(node -e "const t=require('./.taskmaster/tasks/tasks.json'); console.log(Array.isArray(t.tasks)?t.tasks.filter(x=>x.status==='done').length:0)" 2>/dev/null || echo "0")
    PENDING_COUNT=$(node -e "const t=require('./.taskmaster/tasks/tasks.json'); console.log(Array.isArray(t.tasks)?t.tasks.filter(x=>x.status==='pending').length:0)" 2>/dev/null || echo "0")
    IN_PROGRESS=$(node -e "const t=require('./.taskmaster/tasks/tasks.json'); console.log(Array.isArray(t.tasks)?t.tasks.filter(x=>x.status==='in-progress').length:0)" 2>/dev/null || echo "0")
    echo "TASKS_TOTAL: $TASK_COUNT"
    echo "TASKS_DONE: $DONE_COUNT"
    echo "TASKS_PENDING: $PENDING_COUNT"
    echo "TASKS_IN_PROGRESS: $IN_PROGRESS"
  else
    echo "TASKS_TOTAL: 0"
  fi
else
  echo "TASKMASTER_INIT: no"
fi
