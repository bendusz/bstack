# Scaffold: what a project needs before any story

`/bstack:setup-project` follows this before a plan exists, and the PM after sign-off
(`planning.md` `## 5`). Only add what is absent. Never overwrite a user-authored file without
showing a diff and asking.
- `AGENTS.md` from `<plugin>/templates/AGENTS.md.template`, when the folder has code or a signed
  plan to describe: facts only (commands, layout, non-default conventions, gotchas), aiming at 30
  to 40 lines. Replace every template comment rather than copying it, since Codex reads a comment
  as an instruction. Every child loads this file, so test each line: would removing it cause
  mistakes? Never copy procedure or hard rules into it, nor a line saying the project runs on
  bstack. Keep the template's first Conventions line as written; propose it as a diff to an
  `AGENTS.md` that lacks it. Before a plan, its Commands are what the manifests and lockfiles
  name, `N/A` where there is none. Never ask what is being built.
- `CLAUDE.md` from `<plugin>/templates/CLAUDE.md.template`, the `@AGENTS.md` bridge.
  If `CLAUDE.md` exists without `AGENTS.md`, propose moving its content into a new `AGENTS.md`
  and making `CLAUDE.md` the bridge; show the diff and ask. If both exist and `CLAUDE.md` is not
  a bridge, leave both and tell the user.
- A folder with no code and no signed plan gets neither file: there is nothing to describe, and
  the bridge would import a file that is not there. The PM writes both after sign-off.
- `.gitignore` includes `tmp/`, appended, never clobbered. `tmp/` is scratch and never enters git.
- The pre-push secret scan, untracked, for every worktree: `pre-push` in the `hooks` directory of
  `git rev-parse --git-common-dir`. Absent: copy `<plugin>/scripts/scan-secrets.sh` there and
  `chmod 755` it (a copy: the plugin path changes on update). Present without its
  `# bstack secret-scan pre-push` line: show it, ask, unless it has the old
  `# deliver secret-scan pre-push` line: ours, outdated; offer to refresh it.
- If `git config core.hooksPath` prints a path, git ignores that directory and a hook manager owns
  pre-push. Install the copy all the same, then propose the one call that runs it, as a diff to
  the manager's tracked file, and ask:
  - husky, first line of `.husky/pre-push`:
    `bash "$(git rev-parse --git-common-dir)/hooks/pre-push" "$@"`
  - lefthook, a `pre-push` command with `use_stdin: true` and
    `run: bash "$(git rev-parse --git-common-dir)/hooks/pre-push" {0}`
  - any other manager: the same call from its pre-push, with the hook's arguments and stdin.

  Until the user accepts, pushes go out unscanned: tell them so. The PM logs it as well.
- Never create `.scan-secrets-allow` at scaffold. It gets a line only when the user approves one
  for a false positive (`loop.md` step 8).
- Commit only the files you created or changed, never `git add -A`, on the branch your caller
  names: the PM, the integration branch; `/bstack:setup-project`, the branch checked out. If git
  has no `user.name` or `user.email`, ask before committing.
