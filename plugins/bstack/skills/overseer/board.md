# The overseer's board meetings

The overseer convenes a product's board by dispatching its chair, one `delegate_task` from the
home repo's thread. The chair and its seats start in the home repo and work in the product by
its absolute path. Rule 8 of the overseer's skill says when a `status` meeting is due, and rule
4 when an `ask` is.

## Convene
1. **Seats.** The five targets are the `## Seats` table of `<plugin>/skills/board/SKILL.md`:
   read that table and nothing else of the file. Every model and effort in it must be in
   `orchestrator_capabilities`, called once. If one is not, hold no meeting and list it under
   `Needs you`: the user names a replacement or agrees to meet without that seat.
2. **Baseline.** Take one stamp, `YYYYMMDD-HHMMSS`. The branch, the sha, clean or dirty and the
   integration branch are the product's `head:` line in the reader's report.
3. **Hold,** for a `status` meeting. Send the PM
   `bstack overseer: board meeting. Merge nothing and leave the checked-out branch where it is until the verdict, or until <HH:MM, two hours from now> if none has come.`
4. **Dispatch the chair:** `target` the chair's, `isolation: "shared"`, `role: "general"`,
   `title` `board chair <mode> <repo>`, `clientRequestId` `board-<stamp>-chair`. Its `task` is
   these lines and nothing else: no summary of the product, no view of its health, no hint of
   what you expect. The chair reads its soul itself; do not read `souls.md`.
   ```
   You are a bstack board chair child, not the PM and not a member. Do not invoke the PM skill or any other bstack skill.
   Read <plugin>/skills/board/souls.md now, in full. Its "Chair soul" and "Holding the meeting" are your instructions; "Stakes" has each seat's stake; "Member soul" is what you paste to each seat. Then hold this meeting. If you cannot read that file, return `Board: failed, cannot read souls.md` and stop.

   Meeting
   - Stamp: <stamp> · Mode: <status | ask> · Rounds: 2
   - Question: <verbatim, ask mode only>
   - Repository: <the product's absolute root> · Branch: <branch> · Baseline: <sha>, <clean | dirty>
   - Managed: yes, integration branch <name>
   - Goal and milestone: from the plan
   - Minutes: <the product's absolute root>/docs/board/<stamp>-<mode>.md
   - sponsor: <target JSON>
   - engineering: <target JSON>
   - customer: <target JSON>
   - operations: <target JSON>
   - Host: this task and every seat you dispatch start in <the home repo's absolute path>, the folder that holds the Repository, not in the Repository. Work in the Repository by its absolute path (`git -C <path>`, absolute file paths), and give each seat that path and this line.
   ```
5. **Record.** Write `meeting open <YYYY-MM-DD HH:MM> <the chair's taskId>` in the product's
   line of `docs/watch.md`, log `board <repo>: <mode> meeting opened` and commit. The chair's
   completion wakes this thread.

## Close
The turn the chair's completion wakes closes the meeting, or the next check that finds
`meeting open` in a watch line: `task_status` with the `taskId` there gives the chair's return.
`waiting: round <n>` is not a return; leave the meeting open.
- **A verdict** begins `Board:`, with a score, a position, or `Board: no score` with the
  recommendations there are. Send it to the PM as the chair wrote it:
  `bstack overseer: board verdict: <the chair's return>`, and after it
  `The minutes are at docs/board/<stamp>-<mode>.md, uncommitted: log the chair's Log: line and commit both as docs(board): <mode> <stamp>. Merge again.`
  A recommendation marked `Decides: PM` stays inside the plan, so adopting it adds nothing the
  user did not ask for: tell the PM to adopt it with a `decided:` (rule 6), or say why not. One marked `Decides: user` changes the scope, the
  architecture or the plan. That is a change of direction and the user's alone: list it under
  `Needs you` as the chair wrote it (rule 5), and neither you nor the PM acts on it meanwhile.
  The PM carries on with the plan as signed off. Write `board <n>/10` and `meeting none` in
  the watch line and log `board <repo>: <score>, <n> min`, from the time it opened to the
  chair's return. An `ask` on a plan is then one input to your sign-off (rule 3).
- **No verdict.** The chair failed, returned `Board: failed` or anything else, or is still
  running two hours after it opened. Send
  `bstack overseer: board meeting over, no verdict. Merge again.`, write
  `meeting failed <the time it opened>` in the watch line and log why. The next `status`
  meeting is due by the hours, not at once.
