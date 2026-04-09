---
name: create-tasks
version: 1.0.0
description: |
  Convert an engineering/design plan into Taskmaster tasks. Takes the current plan
  context, generates a PRD document, then runs the full Taskmaster pipeline:
  parse-prd, analyze-complexity, expand. Use when asked to "create tasks",
  "break this into tasks", "taskmaster this plan", "generate tasks from plan",
  "convert plan to tasks", or "plan to tasks". (fstack)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

# /create-tasks — Plan → Taskmaster Pipeline

This skill converts an engineering or design plan into structured Taskmaster tasks,
ready for autonomous execution via `/execute-tasks`.

## Step 0: Prerequisites

Run the prerequisite check:

```bash
bash ~/.claude/skills/fstack/bin/fstack-ensure-taskmaster.sh
```

If `TASKMASTER_VERSION` is missing, tell the user to install task-master:
```bash
npm install -g task-master-ai
```

If `TASKMASTER_INIT` is `no`, initialize the project:
```bash
task-master init -y
```

If `TASKS_TOTAL` is greater than 0, warn the user that existing tasks were found.
Use AskUserQuestion:
> This project already has {TASKS_TOTAL} tasks ({TASKS_DONE} done, {TASKS_PENDING} pending).
> Creating new tasks will overwrite them.

Options:
- A) Overwrite existing tasks (use --force)
- B) Append new tasks to existing ones (use --append)
- C) Cancel — keep existing tasks

If C, stop and tell the user to run `/execute-tasks` instead if they want to work on existing tasks.

## Step 1: Locate the Plan

Search for plan content in this priority order:

1. **Claude Code plan files** — check for recent plan files:
   ```bash
   ls -t ~/.claude/plans/*.md 2>/dev/null | head -5
   ```
   Read the most recent plan file that looks relevant (match project name or recent timestamp).

2. **gstack design docs** — check for gstack project design output:
   ```bash
   eval "$(~/.claude/skills/gstack/bin/gstack-slug 2>/dev/null)" 2>/dev/null || true
   ls -t ~/.gstack/projects/${SLUG:-unknown}/*-design-*.md 2>/dev/null | head -3
   ls -t ~/.gstack/projects/${SLUG:-unknown}/*-review-*.md 2>/dev/null | head -3
   ```

3. **Project root docs** — check for plan/design files in the project:
   ```bash
   ls PLAN.md DESIGN.md ARCHITECTURE.md PRD.md prd.md docs/PLAN.md docs/PRD.md 2>/dev/null
   ```

4. **Conversation context** — if the user just finished a `/plan-eng-review` or
   `/plan-design-review`, the plan content is in the conversation. Use it directly.

5. **Ask user** — if no plan is found, use AskUserQuestion:
   > I couldn't find a plan document. Where is your plan?

   Options:
   - A) Let me paste the plan content
   - B) Point me to a file path
   - C) Generate a plan from the current codebase context

   If C: read the project's README.md, CLAUDE.md, and key source files to understand
   the project, then generate a plan outline. Confirm with the user before proceeding.

Read the plan content completely. You need to understand it well to generate a good PRD.

## Step 2: Generate PRD

Convert the plan into a structured PRD that Taskmaster can parse effectively.
Write it to `.taskmaster/prd.md`.

The PRD must follow this structure for optimal task generation:

```markdown
# Project: {project name}

## Overview
{1-2 paragraph summary of what the project does and what this plan accomplishes}

## Goals
{Numbered list of concrete, measurable deliverables extracted from the plan}

## Technical Requirements

### Architecture
{System architecture, key components, data flow — from the plan's architecture section}

### Data Model
{Database schemas, data structures, API contracts — if present in the plan}

### Key Dependencies
{External libraries, services, APIs the implementation depends on}

## Implementation Plan

### Phase 1: {phase name}
**Requirements:**
- {Specific requirement with file paths and function names where applicable}
- {Another requirement}

**Acceptance Criteria:**
- {How to verify this phase is complete — must be testable}

### Phase 2: {phase name}
...

{Add as many phases as the plan has distinct stages}

## Non-functional Requirements
- **Testing:** {test strategy from the plan}
- **Performance:** {performance requirements if any}
- **Security:** {security considerations if any}

## Out of Scope
{What this plan explicitly does NOT cover}
```

**Critical rules for PRD generation:**
- Preserve ALL technical specificity from the plan: file paths, function names,
  data structures, API endpoints. Vague PRDs produce vague tasks.
- Each phase should map to 2-5 tasks. If a phase would generate more, split it.
- Acceptance criteria must be verifiable by running code or tests, not subjective.
- Count the total number of distinct implementation steps to calibrate `--num-tasks`.

## Step 3: Run Taskmaster Pipeline

Execute the full pipeline. The `--force` or `--append` flag depends on Step 0.

```bash
# Count implementation steps to calibrate task count
# Default to 10 if unsure, but adjust based on plan complexity
NUM_TASKS={calculated from plan phases, typically 2-5 per phase}

# Parse PRD into tasks
task-master parse-prd --input=.taskmaster/prd.md --num-tasks=$NUM_TASKS --force

# Analyze complexity to decide which tasks need expansion
task-master analyze-complexity

# Expand complex tasks into subtasks
task-master expand --all

# Generate individual task files
task-master generate
```

If any command fails, read the error output carefully. Common issues:
- Missing API key: check `.env` for `ANTHROPIC_API_KEY`
- Invalid PRD format: adjust the PRD and re-run `parse-prd`
- Network error: retry once, then tell the user

## Step 4: Present Results

After the pipeline completes, show the user a formatted summary:

```bash
task-master list --with-subtasks
```

Read `.taskmaster/tasks/tasks.json` and present:

1. **Task Overview Table:**
   | # | Task | Priority | Complexity | Subtasks | Dependencies |
   Each row = one task with key metadata.

2. **Dependency Chain:** Which tasks block which — highlight the critical path.

3. **Complexity Distribution:** How many tasks are high/medium/low complexity.

4. **Estimated Execution Order:** The sequence `/execute-tasks` will follow.

Then use AskUserQuestion:
> Here are the generated tasks. Review the breakdown above.

Options:
- A) Looks good — ready to execute (suggest running `/execute-tasks`)
- B) Adjust tasks — let me modify some before executing
- C) Re-generate with different parameters
- D) Just save — I'll execute later

If B: ask which tasks to adjust, make changes via `task-master update-task`, then re-display.
If C: ask what to change (more/fewer tasks, different focus), regenerate PRD, re-run pipeline.
If D: confirm tasks are saved and remind user to run `/execute-tasks` when ready.

## Completion

When done, report:
- Total tasks created
- Total subtasks generated
- PRD file location: `.taskmaster/prd.md`
- Tasks file location: `.taskmaster/tasks/tasks.json`
- Next step: run `/execute-tasks` to start implementing
