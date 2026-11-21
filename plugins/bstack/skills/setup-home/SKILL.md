---
name: setup-home
description: Use when the user invokes /bstack:setup-home or asks to set up a home repo over several product repositories, or to make a folder that holds several repositories their home. Registers the products with T3 Code, writes the home repo's files, brings products already in flight under it and schedules the overseer's check. It takes on no role; the overseer skill works in the home repo afterwards.
---

If you were dispatched as a child agent (your task begins 'You are a bstack … child'), do not use this skill.

`<plugin>` below means `${CLAUDE_PLUGIN_ROOT}`, this plugin's install directory. It is not a shell
variable: write the path out in every command.

# Set up a home repo

A home repo is a folder that holds several product repositories and delivers none of them. Set
this folder up as one. You are not its overseer: load no other bstack skill, and send a PM only
the one message step 6 gives.

In a folder that is already a home repo (`## Repos` in its `AGENTS.md`), a run adds what is new
and asks nothing the home repo already answers. Step 3 asks only about repositories with no
pointer, and step 4 also registers a pointer that is not a T3 project. Skip step 5 where
`## Board` has its hours, and step 7 where `list_scheduled_tasks` has a task with that prompt.

1. Load your tools with one `ToolSearch select:` call, the `mcp__t3-code__` prefix on each:
   `t3_project_list`, `t3_project_create`, `t3_thread_list`, `t3_thread_update`,
   `t3_thread_send`, `schedule_task`, `list_scheduled_tasks`. Call `t3_project_list`. If T3 is
   absent, say "bstack requires T3 Code" and stop.
2. If this folder is not a git repository, offer `git init` and ask first.
3. List every git repository directly under this folder, with its remote and last commit date.
   Ask the user which ones the home repo oversees.
4. Name the chosen repositories that are not T3 projects yet (none in `t3_project_list` has their
   absolute path as `workspaceRoot`). On the user's yes, `t3_project_create` each with that
   `workspaceRoot` and its folder name as `title`: a nested folder is not a project until it is
   registered.
5. Ask how often the board reviews each product while it builds: 4 hours after sign-off and
   then every 8 hours by default, or never. Say what it costs: one meeting is eight member runs
   and a chair, and it is held only when a story has merged since the last one.
6. Write, adding only what is absent:
   - `AGENTS.md` from `<plugin>/templates/home-AGENTS.md.template`, one pointer per repository,
     with the board's hours under `## Board`.
   - `CLAUDE.md` from `<plugin>/templates/CLAUDE.md.template`.
   - `.gitignore`: one line per nested repository, and `tmp/`.
   - `wiki/index.md` from `<plugin>/templates/wiki-index.md.template`.
   - For each chosen repository whose `docs/approval.json` says `approved`, a product in flight:
     `docs/requests/<repo>-adopted.md`, with a first line `Request for <repo>` and then
     `The request is the Scope and Requirements of its docs/plan.md at <plan_commit>.` Then tell
     its PM: the newest thread in its project titled exactly `PM <repo>` (`t3_thread_list`,
     `projectId`, `titleContains: "PM <repo>"`). Ask the user which thread that is when none is
     so titled, and rename it so with `t3_thread_update`. Send
     `bstack overseer: the user has put this product under a home repo. From now on your questions, PLAN READY and each sprint boundary come to me.`
   The home repo gets no `docs/approval.json`, `docs/plan.md` or stories: those belong to a
   product, and the merge guard acts only where an approval record is.
7. Ask how often to check on the products, 20 minutes by default, or never. Then `schedule_task`
   with prompt `/bstack:overseer check`, `schedule` `{"type":"interval","everyMs":<ms>}`,
   `bindToCurrentThread: true` and `freshSession: true`, so each check starts clean and reads
   where things stand from disk. Tell the user when the next one runs.
8. Commit what you created and log it: `bash "<plugin>/scripts/log.sh" "home set up: <n> repos, check every <interval>"`.
9. Tell the user the home repo is set up and that `/bstack:overseer` is how they work in it.

