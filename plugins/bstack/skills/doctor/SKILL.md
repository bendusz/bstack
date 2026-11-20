---
name: doctor
description: Check readiness before implementation, covering the T3 host, the toolchain, whether the project's gates pass, Codex availability, log.sh and the pre-push secret scan. In a repository set up for operation, check the ops guard, the operator's rounds and the runbook. In a home repo, check that the overseer's scheduled check is still running and every product is visible to it.
argument-hint: "[sub-path or component]"
---

If you were dispatched as a child agent (your task begins 'You are a bstack … child'), do not use this skill.

`references/…` below means `${CLAUDE_PLUGIN_ROOT}/skills/pm/references/…`, and
`<plugin>` in any reference means `${CLAUDE_PLUGIN_ROOT}`. Neither is a shell variable: write the
path out in every command.

In a home repo (its `AGENTS.md` has `## Repos`), run `## Home` at the end instead of what
follows: a home repo has no plan, gates or merge guard of its own.

Run the `bstack:pm` skill's procedure (load that skill first) for a readiness check.
Install or upgrade nothing, and write no file of your own. Running a gate may leave the artifacts
a normal run produces (build output, caches, coverage); leave them as the run left them.

Scope: $ARGUMENTS  (optional, a sub-path or component; default is the whole repo)

Check, in order, each with its evidence:
1. **T3 host.** Load `ToolSearch select:mcp__t3-code__orchestrator_capabilities` and call it once
   (`references/host.md` `## Probe`). If it is absent or fails, report
   `MISSING: bstack requires T3 Code` and stop: the other checks mean nothing without it.
2. **Toolchain**, `OK`, `MISSING` or `UNKNOWN`. The runtimes, package manager and dependencies
   behind the plan's `## Commands` (or, before a plan exists, what the manifests and lockfiles
   name): each resolves on `PATH`, with its version from a `--version` probe, and install has been
   run (`node_modules`, a venv, a lockfile in sync). This shows the tools exist, not that gates pass.
   `UNKNOWN` too when the gates need installed dependencies and the plan's `setup` is missing or
   `N/A`: every builder starts in a fresh worktree that could not run them.
3. **Gates**, `PASS`, `FAIL`, `UNKNOWN` or `N/A`. Run each of the plan's `test`, `lint` and `build`
   commands for real, from the repository root, exactly as the plan writes it. A version or help
   probe is not evidence here.
   - `PASS`: it exited 0. `FAIL`: it did not; quote the command, the exit code and the first
     error lines.
   - `UNKNOWN`: it cannot run safely here, for example it needs a service, credentials or a
     destructive step. Say what it needs and what stays unverified. Never fake the missing piece.
   - `N/A`: the plan says `N/A`. Before a plan exists, every gate is `UNKNOWN: no plan yet`.
   - `run` is not a gate: step 2 covers the program it starts.
4. **Codex**, `OK` or `MISSING`. `orchestrator_capabilities` lists the `codex` provider with the
   models `references/roles.md` `## Models` names. Without it there is no opposite-family reviewer
   for a Claude build, so the default workflow cannot run: report `MISSING` as a blocker. Recommend
   restoring Codex in T3, or an explicit change of workflow the user approves and the log records.
   Never move a Codex default to a Claude model on your own: same-family review breaks the
   hard rule that the reviewer is never the builder.
5. **Decision log**, `OK` or `MISSING`. `"${CLAUDE_PLUGIN_ROOT}/scripts/log.sh"` exists and is
   executable (`test -x`). Do not call it: a call writes a line.
6. **Secret scan**, `OK`, `MISSING`, `OUTDATED` or `BYPASSED`. Check `pre-push` in the `hooks`
   directory of `git rev-parse --git-common-dir`. If `git config core.hooksPath` prints a path,
   git ignores that hook: `BYPASSED` unless the `pre-push` under that path calls it; name the path
   and offer the one-line call `references/scaffold.md` gives.
   `OK`: executable and byte-equal (`cmp`) to
   `"${CLAUDE_PLUGIN_ROOT}/scripts/scan-secrets.sh"`. `OUTDATED`: it has the
   `# bstack secret-scan pre-push` line, or the old `# deliver secret-scan pre-push` one, but
   differs; offer to refresh it with that copy.
   `MISSING`: absent, not executable, or another hook without either line (show it; never replace it
   unasked). Install it as `references/scaffold.md` says.

7. **Merge guard**, `OK`, `OFF` or `BROKEN`. Feed it a payload it must refuse:
   `printf '{"cwd":"%s","tool_input":{"command":"BSTACK_NO_ENFORCE=1 git merge pm/S0-0-doctor"}}' "$PWD" | bash "${CLAUDE_PLUGIN_ROOT}/scripts/merge-guard.sh"`
   Exit 2 naming "the user's switch" is `OK`; anything else is `BROKEN`, with the output quoted
   (no jq, python3 or node is the usual cause). `OFF` when `printenv BSTACK_NO_ENFORCE` prints
   `1`: story merges go unchecked, and only the user unsets it. This proves the script, not that
   Claude Code loaded the hook: `/hooks` lists it.
8. **Hygiene**, warnings only. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/hygiene.sh"` from the main
   checkout and quote every `WARN` line: `AGENTS.md` over 32 KiB, an integration branch too far or
   too long ahead of main, a tag missing from main, branches or worktrees of merged stories, PM
   scripts outside a tracked `ops/pm/`, struck-through or superseded text left in the plan, spec
   or `AGENTS.md`. Each names its fix.
9. **Operation**, only where `docs/ops/charter.md` exists. Load `list_scheduled_tasks` for it.
   - **Ops guard**, `OK`, `NONE`, `OFF` or `BROKEN`. Feed it a payload it must refuse:
     `printf '{"cwd":"%s","tool_input":{"command":"BSTACK_NO_ENFORCE=1 true"}}' "$PWD" | bash "${CLAUDE_PLUGIN_ROOT}/scripts/ops-guard.sh"`
     Exit 2 naming "the user's switch" is `OK`. Exit 0 is `NONE`: the committed charter has no
     `## Never` pattern, so nothing is refused. Anything else is `BROKEN`, with the output
     quoted. `OFF` as in step 7.
   - **Rounds**, `OK`, `MISSING`, `PAUSED`, `OVERDUE` or `ON REQUEST`. The charter's `Rounds:`
     gives the interval; `on request` is `ON REQUEST`. Otherwise `list_scheduled_tasks` holds a
     task with prompt `/bstack:operator round` bound to a thread of this project: none is
     `MISSING`, one not enabled is `PAUSED`, and `OVERDUE` is a `docs/ops/status.txt` whose time
     is older than twice the interval. In each of those no goal is being checked, and nothing
     else will say so.
   - **Runbook**, `OK` or `STALE`. `STALE` when its `Version:` differs from `shipped_sha` in
     `docs/approval.json`, or a recipe is marked `unconfirmed`: name each.

End with a one-line verdict: ready only when the host, toolchain, Codex, log, secret scan and
merge guard checks are `OK` and every gate is `PASS` or `N/A`. Otherwise name the blockers and
what each needs. Hygiene warnings and the operation lines never block; list them after the
verdict, with what each needs: `/bstack:setup-ops` schedules the rounds, and `/bstack:operator
round` brings the runbook up to date.

## Home
Whether the overseer is still watching. Schedule, register and write nothing. Check, in order,
each with its evidence:
1. **T3 host**, as step 1 above, loading `list_scheduled_tasks` and `t3_project_list` with it.
2. **Scheduled check**, `OK`, `MISSING`, `PAUSED`, `OVERDUE` or `OUTDATED`. `list_scheduled_tasks`
   holds one task whose prompt is `/bstack:overseer check`. None is `MISSING`, and one that is not
   enabled is `PAUSED`: no product is being watched, and nothing else will say so. `OVERDUE`: the
   first line of `docs/watch.md`, `Checked <time>, took <n> min`, is older than twice the task's
   interval, or absent although a check has been due. `OK` names the interval and the sessions a
   day it starts (72 at 20 minutes). Two such tasks double that: name both.
   `OUTDATED`: in its place is a task whose prompt is `/bstack:home check`. That skill is gone, so
   the task runs nothing and no product is being watched, enabled and on time or not.
   `/bstack:overseer` offers to repair it and keeps its interval. Beside a healthy
   `/bstack:overseer check` task the old one is a leftover: name it, and the check is still `OK`.
3. **Check length**, `OK` or `SLOW`. `SLOW` when `took <n> min` is at or over the interval.
4. **Products**, one line for each pointer under `## Repos`: `OK`; `MISSING`, with no git
   repository at its path; or `UNREGISTERED`, with no T3 project whose `workspaceRoot` is that
   path.
5. **Board hours.** Name the `Status meeting:` line under `## Board` and what it costs: nine
   runs a meeting, and how many meetings a day those hours allow each product that is building
   (three at the default).

End with a one-line verdict: watching only when the host and the scheduled check are `OK` and
every product is `OK`. Otherwise name what each needs; `/bstack:setup-home` schedules a
check and registers a product, asking first, and `/bstack:overseer` repairs an `OUTDATED` check.
