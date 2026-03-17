#!/usr/bin/env bash
# Adapter: copilot
# Capabilities: auto-approve, background
#
# Unified interface for invoking GitHub Copilot CLI.
#
# Usage:
#   scripts/launch/adapters/copilot.sh [options]
#
# Options:
#   --prompt "..."         Task prompt (mutually exclusive with --prompt-file)
#   --prompt-file file.md  Read prompt from file (mutually exclusive with --prompt)
#   --max-turns N          Max iterations, 0=unlimited (required) (Not currently supported with Copilot CLI)
#   --log output.log       Log file path (required)
#   --background           Run in background, print PID to stdout (default: foreground)
#   --help                 Show this help

set -euo pipefail

PROMPT=""
PROMPT_FILE=""
MAX_TURNS=""
LOG_FILE=""
BACKGROUND=false

for arg in "$@"; do
  case "$arg" in
    --prompt=*)      PROMPT="${arg#*=}" ;;
    --prompt-file=*) PROMPT_FILE="${arg#*=}" ;;
    --max-turns=*)   MAX_TURNS="${arg#*=}" ;;
    --log=*)         LOG_FILE="${arg#*=}" ;;
    --background)    BACKGROUND=true ;;
    --help|-h)
      sed -n '2,/^$/{ s/^# //; s/^#//; p }' "$0"
      exit 0
      ;;
    *) echo "copilot adapter: unknown option: $arg" >&2; exit 1 ;;
  esac
done

# ── Validate arguments ──

if [[ -n "$PROMPT" && -n "$PROMPT_FILE" ]]; then
  echo "copilot adapter: --prompt and --prompt-file are mutually exclusive" >&2
  exit 1
fi

if [[ -z "$PROMPT" && -z "$PROMPT_FILE" ]]; then
  echo "copilot adapter: one of --prompt or --prompt-file is required" >&2
  exit 1
fi

if [[ -z "$MAX_TURNS" ]]; then
  echo "copilot adapter: --max-turns is required" >&2
  exit 1
fi

if [[ -z "$LOG_FILE" ]]; then
  echo "copilot adapter: --log is required" >&2
  exit 1
fi

# ── Resolve prompt ──

if [[ -n "$PROMPT_FILE" ]]; then
  if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "copilot adapter: prompt file not found: $PROMPT_FILE" >&2
    exit 1
  fi
  PROMPT="$(cat "$PROMPT_FILE")"
fi

# ── Run ──
#
# Note: Copilot CLI does not expose a --max-turns flag.
# We keep this option for adapter parity and rely on Copilot defaults when running.

if $BACKGROUND; then
  nohup copilot \
    --allow-all \
    -p "$PROMPT" \
    > "$LOG_FILE" 2>&1 &
  echo $!
else
  copilot \
    --allow-all \
    -p "$PROMPT" \
    > "$LOG_FILE" 2>&1
fi