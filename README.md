# fstack

Taskmaster integration skills for Claude Code. Bridges the gap between **planning** and **execution** — converts engineering plans into structured tasks, then implements them autonomously.

## What it does

**Without fstack:** Taskmaster is a task tracker. You manually write PRDs, run CLI commands, read each task, and code it yourself.

**With fstack:** Claude reads your plan, generates the PRD, creates all tasks, then writes the code for each task one by one — testing, committing, and moving on automatically.

Two skills:

| Skill | What it does |
|-------|-------------|
| `/create-tasks` | Plan → PRD → `parse-prd` → `analyze-complexity` → `expand` → task list for review |
| `/execute-tasks` | Loop: `next` → read task → write code → run tests → mark done → repeat |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI or desktop app
- [gstack](https://github.com/garrytan/gstack) (recommended, for planning skills)
- [Taskmaster](https://github.com/eyaltoledano/claude-task-master) CLI

## Installation

```bash
# 1. Install gstack (if you don't have it)
claude install-skill https://github.com/garrytan/gstack

# 2. Install fstack
claude install-skill https://github.com/felps-code/fstack

# 3. Install Taskmaster CLI
npm install -g task-master-ai
```

Restart Claude Code after installing for skills to be discovered.

## Usage

### The full workflow with gstack

```
/plan-eng-review     →  Review your engineering plan (gstack)
/create-tasks        →  Convert the reviewed plan into Taskmaster tasks (fstack)
/execute-tasks       →  Implement all tasks autonomously (fstack)
/ship                →  Create PR with all changes (gstack)
```

### Step 1: Plan (gstack)

Start with a plan. You can use gstack's planning skills or bring your own:

```
> /plan-eng-review
```

This produces a reviewed engineering plan with architecture, implementation steps, and test strategy. Other gstack planning skills work too:

- `/plan-ceo-review` — CEO/founder scope review
- `/plan-design-review` — designer's eye review
- `/office-hours` — brainstorm the idea first

Or skip gstack entirely and provide your own plan file (`PLAN.md`, `DESIGN.md`, or paste it in).

### Step 2: Create tasks (fstack)

```
> /create-tasks
```

This skill:
1. Finds your plan (from the review you just did, plan files, or asks you)
2. Converts it into a structured PRD at `.taskmaster/prd.md`
3. Runs `task-master parse-prd` to generate tasks
4. Runs `task-master analyze-complexity` to score each task
5. Runs `task-master expand --all` to break complex tasks into subtasks
6. Shows you the full task breakdown for review

You can adjust tasks before moving on — add, remove, or modify tasks until the breakdown looks right.

### Step 3: Execute tasks (fstack)

```
> /execute-tasks
```

This skill loops through all tasks:
1. Gets the next available task (respects dependency order)
2. Marks it as in-progress
3. Reads the task details, explores the codebase, implements the code
4. Runs tests to verify
5. Marks it as done
6. Offers to commit after each task
7. Checkpoints every 3 tasks so you can review progress

Handles errors automatically:
- **Blocked tasks** — detects unmet dependencies, asks you how to proceed
- **Test failures** — attempts 2 fixes, then asks you
- **Unclear tasks** — asks for clarification before guessing

**Resumable across sessions.** Task state lives in `.taskmaster/tasks/tasks.json`. If you stop mid-way, just run `/execute-tasks` again — it picks up where you left off.

### Step 4: Ship (gstack)

```
> /ship
```

Creates a PR with all the changes from the executed tasks.

## Using without gstack

fstack works standalone — gstack is optional. Without gstack:

- Provide your own plan file (PLAN.md, DESIGN.md, or paste content)
- Use `/create-tasks` to convert it to Taskmaster tasks
- Use `/execute-tasks` to implement them
- Create PRs manually with `gh pr create`

## Using with existing Taskmaster tasks

If you already have tasks from running Taskmaster manually:

```bash
# You already ran these yourself:
task-master parse-prd --input=my-prd.txt
task-master expand --all
```

Skip `/create-tasks` and go straight to:

```
> /execute-tasks
```

It will pick up your existing tasks and start implementing them.

## File structure

```
fstack/
├── .claude-plugin/
│   └── plugin.json                # Plugin manifest
├── create-tasks/
│   └── SKILL.md                   # /create-tasks skill definition
├── execute-tasks/
│   └── SKILL.md                   # /execute-tasks skill definition
└── bin/
    └── fstack-ensure-taskmaster.sh  # Prerequisite checker
```

Tasks are stored in your project's `.taskmaster/` directory (standard Taskmaster location).

## Troubleshooting

**Skills don't appear after install:**
Restart Claude Code. Skills are discovered on session start.

**`task-master: command not found`:**
```bash
npm install -g task-master-ai
```

**Tasks fail to generate (API key error):**
Taskmaster needs an API key. Add to your project's `.env`:
```
ANTHROPIC_API_KEY=sk-ant-...
```
Or configure a different provider: `task-master models --setup`

**Want to start over with fresh tasks:**
```bash
rm -rf .taskmaster/tasks/tasks.json
task-master init -y
```
Then run `/create-tasks` again.

## License

MIT
