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
in the brief.
_Avoid_: persona, personality, system prompt

**Role skill**:
A skill that makes the session a role and holds that role's soul: `pm`, `overseer`.
_Avoid_: persona skill, agent

**Setup skill**:
A skill that prepares a folder and takes on no role: `setup-project`, `setup-home`.
_Avoid_: init, bootstrap

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
