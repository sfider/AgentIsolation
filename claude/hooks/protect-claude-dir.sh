#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write)
# Denies any Edit/Write tool call targeting ~/.claude/settings*.json or
# ~/.claude/hooks/*, since those tools bypass the Bash/bwrap mask above.
set -euo pipefail

input="$(cat)"
path="$(jq -r '.tool_input.file_path // .tool_input.path // empty' <<<"$input")"
claude_dir="$HOME/.claude"

case "$path" in
  "$claude_dir"/settings*.json|"$claude_dir"/hooks/*)
    jq -n '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "Hook self-protection: edits to ~/.claude settings/hooks are blocked."
      }
    }'
    ;;
  *)
    exit 0
    ;;
esac
