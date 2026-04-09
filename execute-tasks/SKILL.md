---
name: execute-tasks
version: 1.0.0
description: |
  Execute Taskmaster tasks one by one. Reads the next available task, implements it
  (writes code, runs tests, marks done), and loops. Handles blocked tasks, errors,
  and user checkpoints. Use when asked to "execute tasks", "work through tasks",
  "implement the tasks", "start building", "run taskmaster tasks", "do the tasks",
  or "execute the plan". (fstack)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - Agent
---

# /execute-tasks — Autonomous Task Execution Loop

This skill reads Taskmaster tasks and implements them one by one — reading code,
writing code, running tests, marking tasks done, and moving to the next one.

## Step 0: Prerequisites

Run the prerequisite check:

```bash
bash ~/.claude/skills/fstack/bin/fstack-ensure-taskmaster.sh
```

**Required state:**
- `TASKMASTER_VERSION` must be present
- `TASKMASTER_INIT` must be `yes`
- `TASKS_TOTAL` must be greater than 0

If no tasks exist, tell the user:
> No tasks found. Run `/create-tasks` first to generate tasks from a plan.

Then stop.

If tasks exist, display the current status:
> **Task Status:** {TASKS_TOTAL} total | {TASKS_DONE} done | {TASKS_PENDING} pending | {TASKS_IN_PROGRESS} in-progress

If there are `in-progress` tasks, ask via AskUserQuestion:
> There are {IN_PROGRESS} tasks marked as in-progress. These may be from a previous session.

Options:
- A) Resume — continue working on them
- B) Reset to pending — start fresh on those tasks

If B: for each in-progress task, run `task-master set-status --id=<ID> --status=pending`.

## Step 1: Understand the Project

Before implementing any tasks, build context:

1. Read `CLAUDE.md` or `README.md` if present — understand project conventions
2. Check the test setup: look for `package.json` scripts, `pytest.ini`, `Makefile`, etc.
3. Read `.taskmaster/tasks/tasks.json` to understand the full task dependency graph
4. Identify the test command for later use:
   ```bash
   # Detect test runner
   if [ -f package.json ]; then
     node -e "const p=require('./package.json'); console.log(p.scripts?.test || 'no test script')"
   elif [ -f pytest.ini ] || [ -f pyproject.toml ]; then
     echo "pytest"
   elif [ -f Makefile ]; then
     grep -q "^test:" Makefile && echo "make test"
   fi
   ```

## Step 2: The Execution Loop

Repeat this loop until all tasks are done or the user stops:

### 2a. Get Next Task

```bash
task-master next
```

Parse the output to identify:
- Task ID
- Task title
- Task description and details
- Subtasks (if any)
- Dependencies (should all be satisfied since `next` only returns unblocked tasks)

**If `next` returns no task but pending tasks exist:**
This means all remaining tasks are blocked by unfinished dependencies. Detect this:

```bash
task-master list --status=pending
```

Report to user via AskUserQuestion:
> All remaining tasks are blocked by dependencies. Here are the blocked tasks
> and what they're waiting for: {list blocked tasks and their unmet dependencies}

Options:
- A) Skip a dependency — mark a blocking task as done without implementing it
- B) Let me resolve this manually
- C) Stop execution for now

**If no pending tasks remain:** All tasks are done. Go to Step 3 (Completion).

### 2b. Mark In-Progress

```bash
task-master set-status --id={TASK_ID} --status=in-progress
```

### 2c. Implement the Task

Read the full task details:
```bash
task-master show {TASK_ID}
```

**Implementation approach:**

1. **Read the task carefully.** Understand what needs to be built, what files are involved,
   and what the acceptance criteria are.

2. **If the task has subtasks**, implement them in order. Each subtask is a smaller unit
   of work. Mark subtasks done as you complete them.

3. **Explore the codebase** before writing code. Read the files that the task references.
   Understand the existing patterns, imports, and conventions.

4. **Write the code.** Follow existing project conventions. Use existing utilities and
   patterns found in the codebase rather than inventing new ones.

5. **Run tests** after implementation:
   ```bash
   # Use the test command detected in Step 1
   {TEST_COMMAND}
   ```

6. **If tests fail:**
   - Read the failure output carefully
   - Attempt to fix (max 2 attempts)
   - If still failing after 2 attempts, use AskUserQuestion:
     > Task #{TASK_ID} "{title}" — tests are failing after implementation.
     > Error: {test error summary}

     Options:
     - A) Let me fix the tests manually, then continue
     - B) Skip tests for this task and mark as done
     - C) Defer this task and move to the next one
     - D) Stop execution

7. **If implementation is unclear or blocked:**
   - First: re-read the task details and subtasks for missed context
   - Second: check if related tasks (dependencies) provide hints
   - Third: use AskUserQuestion:
     > Task #{TASK_ID} "{title}" — I need clarification.
     > What I understand: {your understanding}
     > What's unclear: {the specific question}

     Options:
     - A) Here's more context: {free text}
     - B) Skip this task for now
     - C) Stop execution

### 2d. Mark Done

```bash
task-master set-status --id={TASK_ID} --status=done
```

### 2e. Git Checkpoint

After completing each task, suggest a commit:

> Completed task #{TASK_ID}: "{title}". Want me to commit these changes?

If the user says yes (or has previously said "commit after each task"), create a commit:
```bash
git add -A
git commit -m "task #{TASK_ID}: {title}"
```

If the user declines, continue without committing. Remember their preference for
subsequent tasks in this session — do not ask again if they said no.

### 2f. Progress Checkpoint (every 3 tasks)

After every 3 completed tasks, pause and report progress via AskUserQuestion:

> **Progress Update:**
> - Completed: {list of tasks just done}
> - Remaining: {count} tasks pending
> - Next up: Task #{next_id} — "{next_title}"

Options:
- A) Continue to next task
- B) Pause here — I'll resume later
- C) Show me the full task list status

If B: stop the loop, remind user they can run `/execute-tasks` again to resume.
If C: run `task-master list --with-subtasks`, display, then re-ask A/B.

## Step 3: Completion Report

When all tasks are done (or user stops), produce a final summary:

**If all tasks completed:**
> **All {TOTAL} tasks completed!**
>
> **Implemented:**
> {numbered list of completed tasks with brief description}
>
> **Files Modified:**
> {list of files changed during this session}
>
> **Next steps:**
> - Run `/ship` to create a PR with all changes
> - Run tests one more time to verify everything works together

**If stopped mid-way:**
> **Execution paused.** {DONE} of {TOTAL} tasks completed.
>
> **Completed this session:**
> {list of tasks done in this session}
>
> **Remaining:**
> {list of pending tasks}
>
> **Deferred:**
> {list of deferred tasks and why}
>
> Run `/execute-tasks` again to resume from where you left off.

## Error Recovery

**If the session is interrupted** (crash, user closes terminal):
- Tasks already marked `done` stay done
- The in-progress task stays as `in-progress`
- Running `/execute-tasks` again will detect this and offer to resume or reset

**If a task breaks previously working code:**
- The per-task commits (if enabled) allow easy rollback: `git revert <commit>`
- The deferred status lets you skip problematic tasks without losing track

**If Taskmaster CLI errors:**
- Check `.env` for API keys if the error mentions authentication
- Check `.taskmaster/config.json` for model configuration
- Run `task-master models` to verify AI model settings
