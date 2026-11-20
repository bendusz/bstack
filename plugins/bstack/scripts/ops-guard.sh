#!/usr/bin/env bash
# ops-guard.sh: Claude Code PreToolUse hook on Bash (hooks/hooks.json). In a repository set up
# for operation it refuses a command the user has ruled out for every agent: docs/ops/charter.md,
# read from HEAD, lists them under `## Never`, one list line each, as an extended regular
# expression in backticks followed by the reason. A command that matches one is refused.
#   - The charter is read from HEAD of the repository the call's cwd is in, so an uncommitted
#     edit changes nothing, and a worktree answers to the branch it has checked out.
#   - The whole command text is matched, so a message that quotes a refused command is refused
#     too, and the refusal says so. A pattern grep cannot compile matches nothing.
# It guards against mistakes, not an adversary with a shell.
# Exit 0 allows, exit 2 blocks with the reason on stderr. Bash 3.2 compatible.
# Only the user switches it off, by starting Claude Code with BSTACK_NO_ENFORCE=1.
set -uo pipefail
CHARTER=docs/ops/charter.md

block() { printf 'bstack ops guard: %s\n' "$1" >&2; exit 2; }
input=$(cat)

field() { # field <key>...: a string at that path in the hook input, else empty
  if command -v jq >/dev/null 2>&1; then
    local p; p=$(printf '.%s' "$@"); printf '%s' "$input" | jq -r "$p // empty | strings"
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -c 'import json,sys
d=json.load(sys.stdin)
for k in sys.argv[1:]: d=d.get(k) if isinstance(d,dict) else None
print(d if isinstance(d,str) else "")' "$@"
  elif command -v node >/dev/null 2>&1; then
    printf '%s' "$input" | node -e 'let s="";process.stdin.on("data",c=>s+=c).on("end",()=>{
let d=JSON.parse(s);for(const k of process.argv.slice(1))d=d&&typeof d==="object"?d[k]:undefined;
process.stdout.write(typeof d==="string"?d:"")})' "$@"
  else return 9; fi
}
never() { # never <dir>: the patterns of the charter's ## Never section at HEAD, one a line
  git -C "$1" show "HEAD:$CHARTER" 2>/dev/null | awk '
    /^## Never[[:space:]]*$/ { f = 1; next }
    /^## / { f = 0 }
    f && /^[[:space:]]*[-*][[:space:]]*`/ {
      s = $0; sub(/^[^`]*`/, "", s); i = index(s, "`")
      if (i > 1) print substr(s, 1, i - 1)
    }'
}

if ! cmd=$(field tool_input command); then
  # No JSON reader. Refuse only where there is something to guard.
  [ -n "$(never "$PWD")" ] || exit 0
  block "cannot read the hook input: install jq, python3 or node"
fi
cwd=$(field cwd); [ -n "$cwd" ] || cwd=$PWD
pats=$(never "$cwd")
[ -n "$pats" ] || exit 0
case $cmd in *BSTACK_NO_ENFORCE*) block "BSTACK_NO_ENFORCE is the user's switch; never set it in a command" ;; esac
[ "${BSTACK_NO_ENFORCE:-}" = 1 ] && exit 0

while IFS= read -r pat; do
  [ -n "$pat" ] || continue
  if printf '%s\n' "$cmd" | grep -Eq -e "$pat" 2>/dev/null; then
    block "refused: \`$pat\` is under ## Never in $CHARTER. No agent runs this here; the user does. Do not rephrase or wrap it to get past this. A command that only mentions it, such as a log line or a commit message, is refused too: say it in other words."
  fi
done <<EOF
$pats
EOF
exit 0
