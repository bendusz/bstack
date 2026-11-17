---
name: home
description: Use when the user invokes /bstack:home or asks to set up a home repo over several product repositories, for where all their products stand, to pass work or a message to the PMs of those products, or to add to or query the wiki that spans them. Acts as the overseer; it plans, builds and merges nothing.
argument-hint: "[setup | check | lint | <request>]"
---

If you were dispatched as a child agent (your task begins 'You are a bstack … child'), do not use this skill.

`<plugin>` below means `${CLAUDE_PLUGIN_ROOT}`, this plugin's install directory. It is not a shell
variable: write the path out in every command.

# Home

A home repo is a folder that holds several product repositories and delivers none of them. You
are its overseer. First read `${CLAUDE_PLUGIN_ROOT}/skills/home/soul.md`: who you are, your tools
and your rules. Then take the section the moment needs.

Arguments: $ARGUMENTS

- `setup`, or a folder whose `AGENTS.md` has no `## Repos`: `## Setup`.
- `check`: `## Check`.
- `lint`, or anything for the wiki: `## Wiki`.
- Work or a message for a product: `## A request for a product`.

## Setup
1. Load your tools and call `t3_project_list`. If T3 is absent, say "bstack requires T3 Code" and
   stop.
2. If this folder is not a git repository, offer `git init` and ask first.
3. List every git repository directly under this folder, with its remote and last commit date.
   Ask the user which ones the home repo oversees.
4. Name the chosen repositories that are not T3 projects yet (none in `t3_project_list` has their
   absolute path as `workspaceRoot`). On the user's yes, `t3_project_create` each with that
   `workspaceRoot`: a nested folder is not a project until it is registered.
5. Write, adding only what is absent:
   - `AGENTS.md` from `<plugin>/templates/home-AGENTS.md.template`, one pointer per repository.
   - `CLAUDE.md` from `<plugin>/templates/CLAUDE.md.template`.
   - `.gitignore`: one line per nested repository, and `tmp/`.
   - `wiki/index.md` from `<plugin>/templates/wiki-index.md.template`.
   The home repo gets no `docs/approval.json`, `docs/plan.md` or stories: those belong to a
   product, and the merge guard acts only where an approval record is.
6. Ask how often to check on the products, 20 minutes by default, or never. Then `schedule_task`
   with prompt `/bstack:home check`, `schedule` `{"type":"interval","everyMs":<ms>}`,
   `bindToCurrentThread: true` and `freshSession: true`, so each check starts clean and reads
   where things stand from disk. Tell the user when the next one runs.
7. Commit what you created and log it: `bash "<plugin>/scripts/log.sh" "home set up: <n> repos, check every <interval>"`.

## A request for a product
1. Write the request to `docs/requests/<repo>-<slug>.md`: a first line `Request for <repo>`, then
   the user's words exactly. Commit it. It is what a plan is signed off against.
2. Send it to the product's PM (soul, rule 1). To a new thread the message is
   `/bstack:pm bstack overseer: The user's request, word for word: "<request>". Say PLAN READY <plan commit> when the plan is ready for sign-off.`
   To a PM that is already running, `t3_thread_send` the same text without `/bstack:pm`.
3. Log it. The next check reads the PM's answer; `t3_thread_wait` only while the user is waiting
   with you.
4. Once the product's completion report says it shipped, `git rm` the request file.

## Check
For each repository under `## Repos`:
1. Read where it stands. Its checkout holds `docs/gate.txt`, each story's `pm-exec` line,
   `docs/handoff.md` and the tail of `docs/log.md`; T3 holds its PM thread's status and
   `t3_pending_request` list. No `docs/approval.json` means bstack does not manage it: its line
   is `unmanaged`.
2. Compare with its line in `docs/watch.md`:
   `<repo> | gate <PASS|FAIL|none> | <n> merged, <n> building, <n> blocked | waiting: <what, or none>`
3. Act on what changed. `PLAN READY` is a sign-off (soul, rules 3 and 4). A PM's question is
   answered or passed on (rules 5 and 6).
4. Rewrite `docs/watch.md` and commit it when a line changed.

## Wiki
`wiki/` holds what is true across the products: contracts between them, shared standards, the
glossary, and the retro lessons that apply to more than one. Sources stay untouched in
`wiki/raw/`. Each page is `wiki/<topic>.md` and says what is true now; `wiki/index.md` lists
every page with one line.
- **Ingest** a source or something the user tells you: write or update the pages it bears on,
  update the index, and log one line.
- **Query:** answer from the pages and name them. An answer worth keeping becomes a page.
- **Lint**, when asked: pages that contradict each other, pages the index lacks, and claims a
  product's files now contradict. Fix what the record settles; ask about the rest.
