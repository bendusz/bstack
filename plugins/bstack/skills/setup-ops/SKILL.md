---
name: setup-ops
description: Use when the user invokes /bstack:setup-ops or asks to set a repository up for operation, to put a built product under an operator, or to write its runbook, goals or guardrails. Reads how the product is run from the repository, agrees its goals and the limits on the operator with the user, writes the charter and the runbook under docs/ops/ and schedules the operator's rounds. It takes on no role and operates nothing; the operator skill works in the repository afterwards.
---

If you were dispatched as a child agent (your task begins 'You are a bstack … child'), do not use this skill.

`<plugin>` below means `${CLAUDE_PLUGIN_ROOT}`, this plugin's install directory. It is not a shell
variable: write the path out in every command.

# Set up operation

Prepare this repository for an operator: the agent that runs and uses a product once it is
built. You are not that operator. Load no other bstack skill, and run nothing that changes the
product, its data or anything outside this checkout: while you set up, you only look.

Where `docs/ops/charter.md` already exists, a run adds what is absent and asks nothing the
charter already answers.

1. Load your tools with one `ToolSearch select:` call, the `mcp__t3-code__` prefix on each:
   `orchestrator_capabilities`, `list_scheduled_tasks`, `t3_thread_list`, `t3_thread_launch`.
   Call `orchestrator_capabilities`. Without T3 Code, say "bstack requires T3 Code" and stop.
2. Find the root with `git rev-parse --show-toplevel`; everything below is on the root. In a
   subdirectory, name the root and ask before going on. Stop, writing nothing, where there is
   no git repository, or the root is a home repo (`## Repos` in its `AGENTS.md`): operation is
   set up in a product's own repository.
3. Read how the product is run. Never ask the user what the repository can say:
   - `AGENTS.md` and `docs/plan.md`: the Commands, the Design, and each `## Acceptance` journey
     with its recipe.
   - `docs/approval.json`: a `shipped` record names the version in operation. A record that
     has never said `shipped` means nothing is in operation yet: say so and ask whether to go on.
   - `docs/go-no-go.md` and its evidence: the service units, the rollback that was rehearsed,
     the timed steps.
   - The manifests, scripts and deploy files: `package.json` scripts, a `Makefile`, a
     `Procfile`, compose files, CI and deploy workflows, cron and systemd units.
4. Agree with the user what the files cannot say, one question at a time, each with your
   proposal from what you read:
   - **Goals.** What must hold while it runs and which jobs recur. Each goal needs a check a
     command can decide; propose one from each Acceptance journey and each scheduled job, and
     ask which are `critical`.
   - **Where.** The environment the operator works on and how it reaches it.
   - **Limits.** What the operator may do unasked (`## Free`), what waits for a yes each time
     (`## Ask first`) and what no agent ever runs (`## Never`). Propose all three. Anything
     that touches live data, money, a person or another system starts under `## Ask first` or
     `## Never`; the user moves it to `## Free`, never you.
   - **Rounds.** How often the operator checks the goals: every 30 minutes by default, or only
     when asked.
5. Write, adding only what is absent:
   - `docs/ops/charter.md` from `<plugin>/templates/ops-charter.md.template`.
   - `docs/ops/runbook.md` from `<plugin>/templates/ops-runbook.md.template`. Every command in
     it is one you read in the repository. Mark `unconfirmed` any you could not find there, and
     never invent one.
   Replace every template comment. Then check what the guard will read:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ops-guard.sh" --list docs/ops/charter.md` prints one
   pattern a line, and must print every one you wrote. Test each printed pattern against the
   command it is meant to stop and against one it must let through:
   `grep -Eq -e '<pattern>' <<<'<command>'`.
6. Show the user both files. The charter is theirs: commit only on their "approved", and only these
   two: `git add docs/ops/charter.md docs/ops/runbook.md`, then
   `git commit -m "ops: charter and runbook" -- docs/ops/charter.md docs/ops/runbook.md`. From that
   commit on, the plugin's ops guard refuses the `## Never` commands for every agent here, and
   any commit of theirs that takes a line out of `## Never`.
7. With rounds on a schedule, and no task in `list_scheduled_tasks` with prompt
   `/bstack:operator round` bound to a thread of this project: the rounds get a thread of their
   own. `t3_thread_launch` one into this project, titled `OPS <repo>`, with the message
   `/bstack:operator schedule <minutes>`; the operator schedules its rounds there, and a home
   repo's overseer finds it by that title. Never bind the rounds to this thread or rename it:
   it may be the PM's.
8. Tell the user what you wrote, which recipes are `unconfirmed`, when the first round runs,
   and that `/bstack:operator` is how they work with the product from here.
