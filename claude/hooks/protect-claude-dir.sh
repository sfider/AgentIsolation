#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit|NotebookEdit)
# Denies any file-writing tool call that resolves to ~/.claude/settings*.json,
# ~/.claude/hooks/*, or ~/.claude/.credentials.json, since those tools bypass
# the Bash/bwrap mask above.
#
# Paths are canonicalized with `realpath -m` before comparison so a relative
# path, a `..` component, or a symlink pointing into ~/.claude can't be used
# to slip past a plain string/glob match on the raw tool_input path.
set -euo pipefail

# Fail closed: if anything here breaks (jq missing, bad input, etc.) deny.
fail_closed() {
  trap - ERR
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Hook self-protection: internal error, denying by default."}}'
  exit 0
}
trap fail_closed ERR

input="$(cat)"
raw_path="$(jq -r '.tool_input.file_path // .tool_input.path // .tool_input.notebook_path // empty' <<<"$input")"

[[ -z "$raw_path" ]] && exit 0

claude_dir="$(realpath -m -- "$HOME/.claude")"
target="$(realpath -m -- "$raw_path")"

case "$target" in
  "$claude_dir"/settings*.json|"$claude_dir"/hooks/*|"$claude_dir"/.credentials.json)
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "Hook self-protection: writes to ~/.claude settings/hooks/credentials are blocked."
      }
    }'
    ;;
  *)
    exit 0
    ;;
esac
