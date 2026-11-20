---
name: setup-project
description: Use when the user invokes /bstack:setup-project or asks to prepare, set up or initialise a repository for bstack without planning anything yet. Registers the folder with T3 Code and adds the scaffold a bstack project needs (AGENTS.md, the CLAUDE.md bridge, the tmp/ ignore line, the pre-push secret scan). It plans nothing, takes on no role and dispatches nothing.
---

If you were dispatched as a child agent (your task begins 'You are a bstack … child'), do not use this skill.

`references/…` below means `${CLAUDE_PLUGIN_ROOT}/skills/pm/references/…`, and `<plugin>` in any
reference means `${CLAUDE_PLUGIN_ROOT}`. Neither is a shell variable: write the path out in every
command.

# Set up a project

Prepare this repository for bstack. You are not the PM: load no other bstack skill, ask nothing
about what is being built, and write no `docs/plan.md`, `docs/approval.json`, story, spec or log
line. `docs/log.md` is the PM's; what you have to report, tell the user.

1. Load `ToolSearch select:mcp__t3-code__orchestrator_capabilities,mcp__t3-code__t3_project_list,mcp__t3-code__t3_project_create`
   and probe the host (`references/host.md` `## Probe`). Without T3 Code, say "bstack requires T3
   Code" and stop.
2. Find the repository's root with `git rev-parse --show-toplevel`. Every check below is on the
   root. If the session is in a subdirectory of it, name the root and ask before going on. Not a
   git repository: offer `git init`, and ask first; declined, stop.
3. Stop, writing nothing, when the root is one of these:
   - a home repo (`## Repos` in its `AGENTS.md`): name `/bstack:setup-home`.
   - a project a PM already manages (`docs/approval.json` exists): its scaffold is that PM's, and
     a commit here could void a release candidate. Name `/bstack:doctor`.
4. If no entry of `t3_project_list` has the root as `workspaceRoot`, offer `t3_project_create`
   with it. Declined: go on, and say an overseer cannot reach the project until it is one.
5. Follow `references/scaffold.md`, committing on the branch that is checked out.
6. Say what you created and what was already there. Then name what comes next:
   `/bstack:doctor` to check readiness, and `/bstack:pm <request>` to plan. The merge guard
   checks nothing here until planning commits an approval record.
