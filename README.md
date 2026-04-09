# fstack

Hi, I'm Felps. I've been developing systems with Claude AI and I'm really into using [gstack](https://github.com/garrytan/gstack) and [Taskmaster](https://github.com/eyaltoledano/claude-task-master), so I decided to fill the gap between these two wonderful tools. gstack helps you plan while Taskmaster helps you manage tasks. With fstack I put these two worlds together and add the missing execution part, where Claude actually builds the code, task by task. Enjoy!

---

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
git clone https://github.com/garrytan/gstack.git ~/.claude/skills/gstack

# 2. Install fstack
git clone https://github.com/felps-code/fstack.git ~/.claude/skills/fstack
cd ~/.claude/skills && ln -s fstack/create-tasks create-tasks && ln -s fstack/execute-tasks execute-tasks

# 3. Install Taskmaster CLI
npm install -g task-master-ai
```

Restart Claude Code after installing for skills to be discovered.

To update later:
```bash
cd ~/.claude/skills/fstack && git pull
```

## Usage with gstack

[gstack](https://github.com/garrytan/gstack) is an open source software factory by Garry Tan that turns Claude Code into a virtual engineering team — 23 specialist skills organized around a sprint cycle: **Think → Plan → Build → Review → Test → Ship → Reflect**.

fstack plugs into the middle of that cycle. gstack handles the thinking, planning, reviewing, and shipping. fstack handles the structured execution — breaking the plan into tasks and implementing them one by one.

### The gstack sprint cycle + fstack

| Phase | Skill | Source |
|-------|-------|--------|
| **Think** | `/office-hours` — YC-style brainstorm, forcing questions that expose demand reality | gstack |
| **Plan** | `/plan-ceo-review` — Challenge scope, find the 10-star product | gstack |
| **Plan** | `/plan-eng-review` — Lock architecture, data flow, edge cases, test coverage | gstack |
| **Plan** | `/plan-design-review` — Rate every design dimension 0-10 | gstack |
| **Build** | `/create-tasks` — Convert the reviewed plan into Taskmaster tasks | **fstack** |
| **Build** | `/execute-tasks` — Implement all tasks autonomously | **fstack** |
| **Review** | `/review` — Pre-landing code review (SQL safety, trust boundaries) | gstack |
| **Test** | `/qa` — Real browser testing, find and fix bugs | gstack |
| **Ship** | `/ship` — Bump version, changelog, push, create PR | gstack |
| **Ship** | `/land-and-deploy` — Merge PR, wait for CI, verify production | gstack |
| **Reflect** | `/retro` — Weekly engineering retrospective | gstack |

### Example: building a feature end-to-end

Here's what a real session looks like — from idea to shipped PR:

```
You:  I want to add Stripe billing to my SaaS app

      > /office-hours
      
      gstack asks 6 forcing questions: Who is desperate for this? What do
      they do today? What's the narrowest possible wedge? You answer each
      one. It sharpens the idea into a concrete scope.

      > /plan-ceo-review

      Rethinks the problem from first principles. Challenges premises.
      Proposes a 10-star version. You pick HOLD SCOPE or expand selectively.

      > /plan-eng-review

      Locks the architecture: API routes, database schema, webhook handling,
      error cases, test strategy. Walks through issues interactively.
      You approve the plan.

      > /create-tasks

      fstack reads the approved plan, generates a PRD, runs Taskmaster:
      
      ✓ Generated PRD at .taskmaster/prd.md
      ✓ Parsed into 8 tasks
      ✓ Complexity analysis: 3 high, 4 medium, 1 low
      ✓ Expanded into 23 subtasks
      
      | #  | Task                          | Priority | Complexity | Subtasks |
      |----|-------------------------------|----------|------------|----------|
      | 1  | Set up Stripe SDK + config    | high     | 3          | 3        |
      | 2  | Create pricing plans schema   | high     | 5          | 4        |
      | 3  | Build checkout flow           | high     | 7          | 5        |
      | 4  | Implement webhook handler     | high     | 6          | 3        |
      | 5  | Add subscription management   | medium   | 5          | 3        |
      | 6  | Build billing portal page     | medium   | 4          | 2        |
      | 7  | Add usage metering            | medium   | 4          | 2        |
      | 8  | Write integration tests       | low      | 2          | 1        |
      
      "Review the task breakdown. Ready to execute?"
      → You say: "Looks good"

      > /execute-tasks

      fstack starts the loop:
      
      Task #1: Set up Stripe SDK + config
      → npm install stripe, creates lib/stripe.ts, adds env vars
      → Tests pass ✓
      → "Commit? (y/n)" → y
      
      Task #2: Create pricing plans schema  
      → Reads existing DB schema, adds plans + subscriptions tables
      → Runs migrations, seeds test data
      → Tests pass ✓
      → Committed.

      Task #3: Build checkout flow
      → Creates API route, builds React component, handles errors
      → Tests fail (missing mock) → fixes mock → Tests pass ✓
      → Committed.

      ... (continues through all 8 tasks) ...

      Progress: 8/8 tasks completed.
      Files modified: 24 files across 6 directories.
      "All tasks done! Run /ship to create a PR."

      > /review

      gstack reviews the full diff: SQL safety, trust boundaries,
      conditional side effects. Auto-fixes what it can, asks you
      about the rest.

      > /qa

      Opens a real browser, clicks through the checkout flow, tests
      webhook handling, verifies the billing portal. Finds 2 bugs,
      fixes them, re-verifies.

      > /ship

      Bumps VERSION, updates CHANGELOG, pushes to branch, creates PR.
      Done.
```

### Step by step

#### Step 1: Think and plan (gstack)

Start with `/office-hours` to brainstorm, then use the plan review skills to refine:

```
> /office-hours          # brainstorm the idea
> /plan-ceo-review       # challenge scope
> /plan-eng-review       # lock architecture
```

Each skill is interactive — it asks questions, rates dimensions, makes recommendations. You approve or push back until the plan is solid. Or skip gstack entirely and provide your own plan file (`PLAN.md`, `DESIGN.md`, or paste it in).

#### Step 2: Create tasks (fstack)

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

#### Step 3: Execute tasks (fstack)

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

#### Step 4: Review, test, and ship (gstack)

```
> /review       # code review the diff
> /qa           # real browser testing
> /ship         # bump version, push, create PR
```

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
