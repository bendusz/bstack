# bstack, a project manager skill for T3 Code

Claude acts as the project manager. It agrees a plan with you, waits for your sign-off, then
delivers the work through T3 child agents: builders write the code, a reviewer from the other model
family checks it, a verifier signs it off, a technical writer checks it against the plan's design,
and the PM runs the gates and merges. It never writes implementation code itself.

**Requirements**
- **T3 Code.** bstack dispatches every role through T3 and stops if T3 is not there.
- **Codex, available in T3.** The default workflow needs it for the opposite-family review, the
  design review and research. You may name other models for any dispatch.
- **`jq`, `python3` or `node`.** The merge guard needs one of them to read its input and refuses
  every story merge without one; the ops guard needs the same.

bstack leans on how T3 behaves
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
- **Ops guard.** A second hook refuses any command that a repository's `docs/ops/charter.md`
  lists under `## Never`, in every Claude Code session working there or reaching into it from
  another folder. It also refuses an agent's commit that takes a line out of that list: only
  you commit that. A child on another provider, such as a Codex builder, runs no Claude Code
  hook and is not covered. The same switch turns it off.
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

**Coming from 1.x?** 2.0.0 took two names away. `/bstack:home setup` is `/bstack:setup-home`,
every other `/bstack:home <x>` is `/bstack:overseer <x>`, and the `project-manager` skill is
`/bstack:pm`. A home repo needs one step: run `/bstack:overseer` there and say yes when it asks
about the scheduled check. Until then the task runs a skill that no longer exists and no product
is checked. Then run `/bstack:doctor` in the home repo. It reports the scheduled check as `OK`,
and after the next run the first line of `docs/watch.md` carries a new time. The Upgrade list of
the 2.0.0 entry in [CHANGELOG.md](CHANGELOG.md) has the rest.

## Use

Describe the work ("act as my PM to build a CLI todo app") or run `/bstack:pm <request>`. On a
project that is already signed off, `/bstack:pm` picks it up where it stands, and on a product
that has shipped it starts a new plan for the request.

In a repository bstack has not worked in, start with these three, in order:

1. `/bstack:setup-project` registers the folder with T3 and adds `AGENTS.md`, the `CLAUDE.md`
   bridge and the secret scan.
2. `/bstack:doctor` checks the T3 host, Codex, the toolchain and the gates before anything is
   built.
3. `/bstack:pm <request>` plans the request with you.

The first two are optional. Without them the PM adds the same files after sign-off, and a
missing tool or a failing gate shows up once the work has started.

From the request, the work goes through six steps:

1. **Plan.** The PM talks it through with you and writes `docs/plan.md`: scope, requirements and
   the low-level design (decisions, contracts, invariants, failure flows). When the project ends,
   the PM cuts the plan down to that design and it stays as the platform's documentation: a
   technical writer reads it without the code and lists what a rebuild would have to guess, and
   the PM fills that in. A `docs/spec.md` holds the product intent when it needs its own file.
   Before you see a plan of more than one story, a researcher lists the maintained libraries
   and services that already provide each part the design builds itself.
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
   production release adds a binding go/no-go. Once it has shipped, the approval record says
   `shipped`, and nothing more is built until a new plan is signed off. To have it run and
   used from then on, see [Operation](#operation).

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
| researcher | Answers one external question, and checks every plan of more than one story for parts a library already provides; report under `docs/research/` | Codex `gpt-6.2-sol` high (`claude-opus-5-5` high) |
| spec-architect (optional) | Writes the SpecDD `.sdd` files for a sprint | `claude-opus-5-5` high (Codex `gpt-6.2-astra` high) |

The PM runs on whatever model you choose; the plan records it as `PM model:`. A home repo's
overseer starts each PM on `claude-fable-5-2` high (`claude-opus-5-5` high).

### Where each soul is

A soul is who an agent is and the rules it holds. A session has its own from the role skill that
made it that role. A child has only what its dispatch carries.

| Agent | Soul | How the agent gets it |
|---|---|---|
| PM | The body of [`pm/SKILL.md`](plugins/bstack/skills/pm/SKILL.md) | `/bstack:pm` loads it |
| overseer | [`## Overseer soul`](plugins/bstack/skills/overseer/SKILL.md#overseer-soul), with the `## Rules` below it | `/bstack:overseer` loads it |
| operator | [`## Operator soul`](plugins/bstack/skills/operator/SKILL.md#operator-soul) | `/bstack:operator` loads it |
| builder | [`## builder`](plugins/bstack/skills/pm/references/roles.md#builder) | The PM puts it in the brief, after [`## Common`](plugins/bstack/skills/pm/references/roles.md#common) |
| reviewer | [`## reviewer`](plugins/bstack/skills/pm/references/roles.md#reviewer). The design review, the retro's cross-story review and `/bstack:codex review` use it too | In the brief, after `## Common` |
| verifier | [`## verifier`](plugins/bstack/skills/pm/references/roles.md#verifier) | In the brief, after `## Common` |
| technical writer | [`## technical-writer`](plugins/bstack/skills/pm/references/roles.md#technical-writer) | In the brief, after `## Common` |
| researcher | [`## researcher`](plugins/bstack/skills/pm/references/roles.md#researcher) | In the brief, after `## Common` |
| spec-architect | [`## spec-architect`](plugins/bstack/skills/pm/references/roles.md#spec-architect) | In the brief, after `## Common` |
| board chair | [`## Chair soul`](plugins/bstack/skills/board/souls.md#chair-soul), with [`## Holding the meeting`](plugins/bstack/skills/board/souls.md#holding-the-meeting) below it | The chair reads the file itself, from the path in its task |
| board sponsor, engineering, customer, operations | One [`## Member soul`](plugins/bstack/skills/board/souls.md#member-soul) for all four, with the seat's name and its line of [`## Stakes`](plugins/bstack/skills/board/souls.md#stakes) filled in | The chair puts it in each seat's task |

## Skills

Each is a skill: run it as `/bstack:<name>`, or describe the task and Claude picks it up. A role
skill makes the session that role. A setup skill prepares a folder and takes on no role.

| Skill | What it does |
|---|---|
| `/bstack:pm` | Role: the PM. Plans a request end to end, or picks a signed-off project up where it stands. |
| `/bstack:overseer` | Role: the overseer of a home repo. Checks the products, passes on requests, starts new products and keeps the wiki. |
| `/bstack:operator` | Role: the operator. Runs and uses a product that is built: checks its goals, does its jobs, and reports what operating cannot put right. |
| `/bstack:setup-project` | Setup: registers a repository with T3 and adds `AGENTS.md`, the `CLAUDE.md` bridge and the secret scan, before any plan. |
| `/bstack:setup-home` | Setup: turns a folder that holds several product repositories into a home repo. |
| `/bstack:setup-ops` | Setup: reads how a product is run, agrees its goals and the operator's limits with you, writes the charter and the runbook and schedules the rounds. |
| `/bstack:resume` | Pick up from git, the approval record, the story Execution blocks and the log. |
| `/bstack:doctor` | Check the T3 host, the toolchain, the project's gates, Codex, `log.sh`, the secret scan, the merge guard and project hygiene. Where a repository is set up for operation, check the ops guard, the operator's rounds and the runbook. In a home repo, check that the overseer's scheduled check is running and each product is visible to it. |
| `/bstack:retro` | Run the sprint boundary's cross-story review and retrospective. |
| `/bstack:codex` | `review` a commit, worktree, branch or codebase with Codex, or `ask` it a question. |
| `/bstack:skeleton` | Write or extend the SpecDD skeleton for a sprint. |
| `/bstack:board` | Convene the board: a 0-10 status score with recommendations, or `ask` it a question. |

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

`/bstack:setup-home` turns a folder that holds several product repositories into a home repo,
and `/bstack:overseer` makes Claude its overseer. The home repo delivers nothing: it has no plan, approval record or
stories. Each product keeps its own PM, in its own T3 project and thread, with its own gates and
merge guard. The overseer answers for you wherever the answer is not yours alone, so a product
you are not watching keeps moving.

- **Setup** registers each nested repository as a T3 project, asking first, and writes an
  `AGENTS.md` with one pointer per repository, a wiki index and a `.gitignore` for the nested
  repositories. A product that is already building comes under the overseer too: setup asks
  which thread is its PM, renames it `PM <repo>` and tells that PM where its questions go. A thread started in a nested repository works from its own project's
  instructions: Claude reads the lines of the home `CLAUDE.md` but not the `AGENTS.md` it imports,
  and Codex reads neither. So the home `CLAUDE.md` stays that one import line.
- **New products.** Give the overseer a scope and a name. It creates the folder and its git
  repository, registers the T3 project, files your words as the request and starts the PM. It
  adds no remote and pushes nothing.
- **Requests.** Tell the overseer what a product needs. It keeps your words in `docs/requests/`,
  starts or messages that product's PM, and signs off the PM's plan when it covers what you
  asked and, in a plan of more than one story, names the libraries considered for each part the
  product builds itself, or says the research found none. Before it approves a plan of more
  than one sprint it convenes the board.
- **Answers.** A PM's question goes to the overseer. It quotes your request or the wiki when
  they answer it. Otherwise it reads the product's plan, decides how a requirement you stated
  is met, tells the PM and records the decision in the request file. A preference you state
  that covers every product goes into the wiki as a standard. It accepts each sprint's demo and starts the next
  sprint in a new PM thread.
- **Yours alone.** A scope or date change, a waiver, a push, a secret, money, the release
  walk-through, a go/no-go and anything that cannot be undone. So is a change of direction: a
  board recommendation that changes the scope, the architecture or the plan, or any change that
  replaces what merged stories built, whoever proposes it. Each waits for you in the PM's or the
  chair's words, and the PM carries on with the plan as signed off. A PM's own escalation
  names a default and a time. If you have not answered by then, that default applies, and it
  leaves the scope and the date as signed off: changing either takes your own words.
- **The board.** While a product builds, the overseer convenes a status meeting 4 hours after
  sign-off and every 8 hours after that, and only when a story has merged since the last one.
  Setup asks for other hours, or never. The PM holds merges while the board reads the tree, for
  at most two hours; a meeting that fails releases the hold. The verdict goes to the PM. The
  overseer may tell the PM to adopt a recommendation that stays inside the plan.
- **Check-ups.** A scheduled check, every 20 minutes unless you choose otherwise, reads each
  product's gate, stories and PM thread, and acts on what changed. It keeps `docs/watch.md`:
  what needs you, what was decided for you and one line per product. `/bstack:overseer seen`
  clears the decided list once you have read it. Its first line is the time of the last check.
- **What it costs.** Each check is a fresh session that reads every product: 72 a day at 20
  minutes, whether or not anything changed. A board meeting is nine runs, eight member runs and
  a chair, and at the default hours a product that is building gets at most three a day.
- **Is it still watching?** `/bstack:doctor` in the home repo says whether the scheduled check
  is there, enabled and on time, and whether each product is still a repository and a T3
  project. Nothing else tells you that the checks have stopped.
- **Wiki.** `wiki/` holds what is true across the products: contracts between them, shared
  standards, the glossary and lessons that apply to more than one. Tell the overseer something
  to remember, ask it a question, or run `/bstack:overseer lint`.

## Operation

Once a product is built, `/bstack:setup-ops` puts it under an operator and `/bstack:operator`
makes Claude that operator. The PM builds; the operator runs and uses what is built, and changes
no code.

- **The charter**, `docs/ops/charter.md`, is yours. It holds the goals, each with a command
  that decides whether it is met, and three lists: what the operator does unasked, what waits
  for your yes each time, and what no agent ever runs. The ops guard enforces the last list in
  Claude Code sessions. The operator proposes a change to the charter as a diff and never
  widens it itself.
- **The runbook**, `docs/ops/runbook.md`, is the operator's: where the product runs, each job's
  recipe, the rollback, and each failure it has met with the remedy that worked. Setup writes
  it from what the repository says, and the operator keeps it true.
- **Rounds.** On a schedule you choose, the operator runs each goal's check and each job that
  is due, and writes one line to `docs/ops/status.txt`: `OK`, `DEGRADED` or `DOWN`. A miss it
  can put right by operating, it does. A defect it reports as `FIX NEEDED`; the fix is a new
  plan for the PM, and starting it is yours. A critical goal it cannot restore is an `INCIDENT`.
- **Under a home repo** the overseer passes on a request to run or use a product, shows each
  product's operating status beside its delivery status, and puts every incident, fix and
  ask-first question in front of you.

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
