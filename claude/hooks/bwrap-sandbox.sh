#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash)
# Wraps every executed Bash command in bwrap with ~/.claude masked out
# (empty tmpfs), so the command cannot read or write anything under it —
# including .credentials.json, settings.json, or this hook script itself.
set -euo pipefail

# Fail closed: if anything here breaks (jq/bwrap missing, bad input, etc.) deny the command rather.
fail_closed() {
  trap - ERR
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Hook self-protection: internal error, denying by default."}}'
  exit 0
}
trap fail_closed ERR

if ! command -v bwrap >/dev/null 2>&1; then
  fail_closed
fi

input="$(cat)"
tool_name="$(jq -r '.tool_name // empty' <<<"$input")"

if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

command="$(jq -r '.tool_input.command // empty' <<<"$input")"
claude_dir="$HOME/.claude"

# base64-encode the original command so it can be safely single-quoted
# inside the wrapped command regardless of what quoting it contains.
encoded="$(printf '%s' "$command" | base64 -w0)"

wrapped_command="bwrap --dev-bind / / --tmpfs \"$claude_dir\" --die-with-parent -- sh -c 'echo $encoded | base64 -d | bash'"

jq -n --arg cmd "$wrapped_command" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    updatedInput: {command: $cmd}
  }
}'
