# bstack, a project manager skill for T3 Code

Claude acts as the project manager. It agrees a plan with you, waits for your sign-off, then
delivers the work through T3 child agents: builders write the code, a reviewer from the other model
family checks it, a verifier signs it off, a technical writer checks it against the plan's design,
and the PM runs the gates and merges. It never writes implementation code itself.

**Requirements.** T3 Code, with Codex available in T3. bstack dispatches every role through T3
and stops if T3 is not there. The merge guard needs `jq`, `python3` or `node` to read its input,
and refuses every story merge without one. The default workflow needs Codex for the opposite-family review,
the design review and research. You may name other models for any dispatch. bstack leans on how T3 behaves
(where it puts a worktree, what a child's result carries, how a reused request key answers).
Dispatch, messaging and the model ids were last checked against T3 Code 0.1.9 nightly on
2026-11-10; the worktree behaviour on 2026-11-07; a child dispatching its own children, which the
board's chair relies on, on 2026-11-11; a thread launched into a nested project reading the
parent folder's `CLAUDE.md` but not the `AGENTS.md` it imports, which the home repo relies on, on
2026-11-17.

**Secrets stay on the machine.** A secret comes in through T3's `request_secret`, never a file.
On the way out, the PM installs a git pre-push hook that scans every pushed commit, and scans
every commit of a story before merging it. A hit blocks the push or merge and names the commit and
file, never the value. It lives in git, so it covers every agent and provider. Agents never bypass
it; only you may, with `git push --no-verify`.
- **What it catches.** Token formats that identify themselves, in added lines, file paths and
  commit messages: AWS access key ids, private key headers, GitHub, GitLab, Slack, npm, PyPI,
  Stripe live, SendGrid and Google API keys, `sk-` API keys and JWTs.
- **What it does not.** A secret with no telltale format: a password, an AWS secret access key, a
  database URL. It is a net for the common leak, not a guarantee.
- **False positives.** A token-shaped test fixture blocks too. You allow it with a line in
  `.scan-secrets-allow`, `<pattern name> <path glob>`; the PM proposes the line and adds it only
  on your yes. The scan reads that file from the base branch for a merge and from the remote's
  default branch for a push, never from the branch being checked, so no branch can allow its
  own hit.
- **Hook managers.** If husky, lefthook or anything else sets `core.hooksPath`, git skips the
  hook. The PM then proposes the one-line call that runs the scan from your manager's pre-push.

## Guardrails

A few rules hold whatever a project's `AGENTS.md`, plan or deadline says. The PM merges no story
while the integration gate is red (except the story that fixes it), merges nothing with an open
`block` or `major` finding, runs the gates itself on the merged tree and records the commit, keeps
the reviewer in the other model family, and shows you the open go/no-go items and what a date or
scope change skips before it agrees to one. Anything else (the verifier, tests first, the full
suite) can be waived only by a row in the plan's `## Waivers` table, which the retro shows you
every sprint.

Where a machine can check a rule, a script does:
- **Merge guard.** A Claude Code hook refuses `git merge … pm/<story>` unless the story records
  passing gates, review, verifier and technical writer at the branch head, the integration gate
  is not red, and it merges one story at a time. Only you can switch it off, by starting Claude
  Code with `BSTACK_NO_ENFORCE=1`.
- **`ledger.sh`.** One row per reviewed story's outcome, merged or not: its lineage, rounds,
  first-pass, reruns, wall time and model per role. It counts no tokens: tracking them would pull
  the PM's attention off the work.
- **`hygiene.sh`**, run by `/bstack:doctor`: an oversized `AGENTS.md`, an integration branch far
  ahead of main, a tag missing from main, leftovers of merged stories, loose PM scripts, and
  struck-through or superseded text left in the plan, spec or `AGENTS.md`.

Each sprint ends with the plan's user journeys run from a fresh state, then a demo: what you can
try and where. Before a release, you walk the release candidate yourself and accept its
differences by name; with a production release, go/no-go is binding, the new behaviour ships
switched off, and a step due at a set time runs on a timer you approve or by a person you name.

## Install

Run these two steps separately. Submit the first, wait for it to finish, then run the second. If you
paste both at once, the second line gets swallowed into the first command's argument.

**1. Add the marketplace**

```
/plugin marketplace add https://github.com/bendusz/bstack
```

**2. Install the plugin**

```
/plugin install bstack@bstack
```

Use the full `https://` URL; the `owner/repo` shorthand resolves to SSH, which fails without a
GitHub SSH key. If the plugin does not appear right away, restart the session.

**Coming from `deliver`?** The rename means a `deliver` install never updates to bstack on its
own. Remove it with `/plugin marketplace remove deliver` (that also uninstalls the `deliver`
plugin), then run the two steps above. Projects keep working; see the 1.0.0 and 1.2.0 entries in
[CHANGELOG.md](CHANGELOG.md) for what changes in a project.

## Use

Describe the work ("act as my PM to build a CLI todo app") or run `/bstack:pm <request>`.

1. **Plan.** The PM talks it through with you and writes `docs/plan.md`: scope, requirements and
   the low-level design (decisions, contracts, invariants, failure flows). When the project ends,
   the PM cuts the plan down to that design and it stays as the platform's documentation: a
   technical writer reads it without the code and lists what a rebuild would have to guess, and
   the PM fills that in. A `docs/spec.md` holds the product intent when it needs its own file.
2. **Sign-off, in conversation.** Nothing is built until you say "approved", recorded in
   `docs/approval.json`. Under a [home repo](#home-repo), its overseer may give that sign-off.
3. **Stories.** Each sprint becomes self-contained files under `docs/stories/`, tracing to the plan's IDs.
4. **Per-story loop on T3.** Claim, a design review when storage or data changes, tests first,
   build in a T3 worktree, gate, review, at most three fix rounds, verify, then a check of the
   diff against the design before the merge. Up to three independent
   stories build at once.
5. **Ship.** A `--no-ff` merge whose body is the story's record, or a PR when you ask. Each sprint
   ends with the journey gate, a retro that proposes `AGENTS.md` learnings as a diff, and a demo.
   A one-story fix skips the spec, sprints and retro.
6. **Accept and release.** You walk the release candidate and record your acceptance; a
   production release adds a binding go/no-go.

## Roles

Each role is a T3 `delegate_task` child. Its brief is a shared block, a short "soul" for the
role, and a fixed-key header; every child replies in the same line format. Every dispatch names
its model and effort, so a child never inherits the PM's. If a default is unavailable, the PM uses
the fallback and logs it.

| Role | Does | Default (fallback) |
|---|---|---|
| builder | Implements one story, a tests-only brief or a fix, in its own worktree | `claude-opus-5-5` high (Codex `gpt-6.2-astra` high) |
| design review | Reviews the plan of a storage, data-model, migration or versioning story before it is built | Codex `gpt-6.2-astra` xhigh (`claude-opus-5-5` high) |
| reviewer | Reviews the diff against the story; never the builder | The family that did not build: Codex `gpt-6.2-astra` xhigh after a Claude build, `claude-opus-5-5` high after an Astra build |
| verifier | Checks each acceptance criterion, the sprint's journeys and the release candidate | `claude-opus-5-5` high (Codex `gpt-6.2-sol` xhigh) |
| technical writer | Reads each story's diff against the plan's Design before the merge, and reads the shipped plan cold for what a rebuild would have to guess | `claude-sonnet-5-5` high (`claude-opus-5-5` medium) |
| researcher (optional) | Answers one external question, report under `docs/research/` | Codex `gpt-6.2-sol` high (`claude-opus-5-5` high) |
| spec-architect (optional) | Writes the SpecDD `.sdd` files for a sprint | `claude-opus-5-5` high (Codex `gpt-6.2-astra` high) |

The PM runs on whatever model you choose; the plan records it as `PM model:`. A home repo's
overseer starts each PM on `claude-fable-5-2` high (`claude-opus-5-5` high).

## Skills

Each is a skill: run it as `/bstack:<name>`, or describe the task and Claude picks it up.

| Skill | What it does |
|---|---|
| `/bstack:pm` | Act as the PM end to end: plan, sign-off, stories, loop, ship. |
| `/bstack:resume` | Pick up from git, the approval record, the story Execution blocks and the log. |
| `/bstack:doctor` | Check the T3 host, the toolchain, the project's gates, Codex, `log.sh`, the secret scan, the merge guard and project hygiene. |
| `/bstack:retro` | Run the sprint boundary's cross-story review and retrospective. |
| `/bstack:codex` | `review` a commit, worktree, branch or codebase with Codex, or `ask` it a question. |
| `/bstack:skeleton` | Write or extend the SpecDD skeleton for a sprint. |
| `/bstack:board` | Convene the board: a 0-10 status score with recommendations, or `ask` it a question. |
| `/bstack:home` | Set up a home repo over several product repositories and act as its overseer. |

## The board

`/bstack:board` seats four stakeholders, each a T3 child on its own model: a **sponsor**
(`claude-opus-5-5`, high), an **engineering** lead (Codex `gpt-6.2-astra`, xhigh), a **customer**
(`claude-fable-5-2`, medium) and an **operations** lead (Codex `gpt-6.2-sol`, xhigh), who runs
what ships. With no arguments they score how well placed the project is to reach
its next milestone, from 0 to 10, and recommend what to do; `/bstack:board ask <question>` puts a
question to them instead.

They write their first statements without seeing each other's. In a second round each reads the
other three, with the scores removed, and holds or changes its own. The board's score is the median,
shown with all four, and dissent stays on the record.

A fifth child chairs (`claude-opus-5-5`, medium). It runs the gates once for everyone, writes the
brief, holds both rounds, tallies and writes the minutes, and it has no vote. The session that
convenes the meeting hands the chair a stamp, the baseline and the seats, and gets back the verdict
in about twenty lines. So a PM in the middle of a sprint spends almost none of its context on the
meeting, and the brief and the tally come from an agent that did not run the project.

The board is advisory, and only you or a home repo's overseer convene it: one meeting is eight
member runs and a chair. `quick`
holds the first round only, and `sponsor=<model>:<effort>` reseats a member or the chair. Minutes
go to `docs/board/` in a project the PM manages, and to `tmp/board/` anywhere else.

## Home repo

`/bstack:home` turns a folder that holds several product repositories into a home repo, with
Claude as its overseer. The home repo delivers nothing: it has no plan, approval record or
stories. Each product keeps its own PM, in its own T3 project and thread, with its own gates and
merge guard.

- **Setup** registers each nested repository as a T3 project, asking first, and writes an
  `AGENTS.md` with one pointer per repository, a wiki index and a `.gitignore` for the nested
  repositories. A thread started in a nested repository works from its own project's
  instructions: Claude reads the lines of the home `CLAUDE.md` but not the `AGENTS.md` it imports,
  and Codex reads neither. So the home `CLAUDE.md` stays that one import line.
- **Requests.** Tell the overseer what a product needs. It keeps your words in `docs/requests/`,
  starts or messages that product's PM, and signs off the PM's plan when it covers what you
  asked. Before it approves a plan of more than one sprint it convenes the board. Scope and date
  changes, waivers, pushes, secrets, the release walk-through and go/no-go stay yours: it passes
  the PM's question to you as the PM wrote it.
- **Check-ups.** A scheduled check, every 20 minutes unless you choose otherwise, reads each
  product's gate, stories and PM thread, and acts on what changed.
- **Wiki.** `wiki/` holds what is true across the products: contracts between them, shared
  standards, the glossary and lessons that apply to more than one. Tell the overseer something
  to remember, ask it a question, or run `/bstack:home lint`.

## State and the decision log

Git is the record: the claim, each status change and the merge are commits. So files hold only
what is true now: when something changes, the PM and its children rewrite or delete the old text
instead of adding a note beside it, and the project's `AGENTS.md` says so. `docs/log.md` is the
decision log, one timestamped line per decision with the why, appended only through the bundled
`scripts/log.sh` and committed with the PM's next commit. SpecDD is optional and off by default:
opt in during planning and each sprint gets its `.sdd` contracts before any code. Projects started
on 0.29 or earlier: see the 0.30.0 entry in [CHANGELOG.md](CHANGELOG.md) for cleanup commands.

## poteto

`/plugin install poteto@bstack` adds Lauren Tan's [pstack](https://github.com/cursor/plugins/tree/main/pstack)
skills (`how`, `why`, `architect`, `arena`, `interrogate`, `blast-radius`, `unslop`, verification-skill
generators and 24 principles), ported to Claude Code under her MIT license. bstack uses them when
present and works without them. See [`plugins/poteto/README.md`](plugins/poteto/README.md).

## License

GPL-3.0-or-later; see [LICENSE](LICENSE). Copyright (c) 2026 bendusz. `poteto` stays under MIT.

What bstack writes into your project is yours. The plan, spec, stories, `AGENTS.md`, retros,
board minutes and `.sdd` files it creates from its templates are your work, under whatever licence
your project uses. The pre-push hook is an untracked local copy of `scan-secrets.sh`; it is not
part of your repository.
