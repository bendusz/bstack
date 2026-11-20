# bstack

The words this repository uses with one meaning, for anyone changing the plugin or reading a
project it manages.

## Language

**Legacy**:
Text that nothing reads to decide what happens next: no script, no step in a skill, and no
decision a person still has to make. Wanting to look back does not make text current; git serves
that.
_Avoid_: old, outdated, historical, superseded

**Current file**:
A file that says only what is true now. Every tracked file is one unless it is a chronological
file.
_Avoid_: living document, source of truth

**Chronological file**:
A file that grows by dated entries and is never the source for what is current.
_Avoid_: history, journal, record

**PM record**:
A file the PM writes to run a project, as opposed to a story's code.
_Avoid_: state file

**State**:
Where a project stands, as git and each story's execution line say it. A PM record can be wrong
about state; git cannot.
_Avoid_: status, progress

**Plan**:
What a project builds and how it behaves. Until the project ships it is the agreed target;
after that, what shipped. What is built so far is state, which the plan does not hold.
_Avoid_: source of truth, design doc

**Design**:
The part of the plan that fixes behaviour: decisions with the option each rejected, contracts,
invariants and flows. The `.sdd` files and the code follow it, never the reverse.
_Avoid_: architecture, LLD

**Contract line**:
A `Must`, `Must not`, `Exposes` or `Done when` line of a `.sdd` file: the Design as one module
holds it.
_Avoid_: spec line

**Gap**:
Behaviour the code settles that the Design does not state.
_Avoid_: drift, omission

**Contradiction**:
Code that does otherwise than a line of the Design or a contract line says.
_Avoid_: drift, mismatch

**Cold read**:
A read of the shipped plan by an agent that opens no code, to list what a rebuild would have to
guess.
_Avoid_: doc review

**Shipped**:
What a product is once its approval record says so: the user accepted the release candidate, it
went out the way they asked, and the cold read is done. The next request is a new plan.
_Avoid_: done, released, complete

**Sprint boundary**:
Everything between a sprint's last merge and the next sprint's first story: the journey gate, the
cross-story review, the retro, the record and the demo.
_Avoid_: sprint close, sprint end

**Retro**:
The part of the sprint boundary that asks what the sprint taught: its three questions and the
proposed `AGENTS.md` diff.
_Avoid_: retro for the whole sprint boundary

**Soul**:
Who an agent is and the rules it holds. A role skill keeps it in its body; a child gets its own
in its brief, or reads it from the file the brief names.
_Avoid_: persona, personality, system prompt

**Role skill**:
A skill that makes the session a role and holds that role's soul: `pm`, `overseer`, `operator`.
_Avoid_: persona skill, agent

**Setup skill**:
A skill that prepares a folder and takes on no role: `setup-project`, `setup-home`,
`setup-ops`.
_Avoid_: init, bootstrap

**Operator**:
The agent that runs and uses a product once it is built: it checks its goals, does its jobs,
puts right what operating can and reports what it cannot. It changes no code.
_Avoid_: SRE, admin, ops agent

**Charter**:
The user's file that bounds an operator, `docs/ops/charter.md`: the goals with their checks,
what the operator does unasked, what waits for a yes, and what no agent ever runs.
_Avoid_: policy, guardrails file, config

**Runbook**:
The operator's file of how the product is run, `docs/ops/runbook.md`: where it runs, each job's
recipe, the rollback and each known failure with its remedy.
_Avoid_: playbook, ops docs

**Round**:
One pass of the operator over the goals and jobs that are due, ending in a line of
`docs/ops/status.txt`.
_Avoid_: check (the overseer's), health check, tick

**Home repo**:
A folder that holds several product repositories and delivers none of them. It keeps pointers to
them, the wiki and the overseer's records.
_Avoid_: workspace, monorepo

**Overseer**:
The agent that runs a home repo. It creates a product from its scope, starts each product's PM,
passes on the user's words, signs off a plan that covers them, answers what a PM asks unless the
answer is the user's alone, accepts each sprint, convenes the board and keeps the wiki. It
plans, builds and merges nothing.
_Avoid_: lead, manager, orchestrator

**Request**:
The user's words for a piece of work, kept exactly as said in the home repo. A plan is signed
off against it. For a product that was signed off before it came under the home repo, the
request is a pointer to the Scope and Requirements of that plan.
_Avoid_: ticket, ask
