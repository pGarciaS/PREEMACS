#!/bin/bash
# Thin wrapper around run_full_pipeline.sh: runs it in the FOREGROUND (no nohup/
# setsid/disown -- it exits when you close the terminal, same as running
# run_full_pipeline.sh directly), while also saving a copy of the output to a log
# file next to OUTPUT_DIR for later reference.
#
# Usage: same arguments as run_full_pipeline.sh (run with -h for full details) --
#   ./launch_full_pipeline.sh [--all-sessions] SUB_ID T1_PATH T2_PATH OUTPUT_DIR [FS_LICENSE]

set -e -o pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
	exec bash "$REPO/run_full_pipeline.sh" -h
fi

ARGS=("$@")
if [ "${1:-}" = "--all-sessions" ]; then
	ARGS=("${@:2}")
fi

if [ ${#ARGS[@]} -lt 4 ]; then
	echo "Usage: $(basename "$0") [--all-sessions] SUB_ID T1_PATH T2_PATH OUTPUT_DIR [FS_LICENSE]" >&2
	echo "Run with -h for full usage notes and examples." >&2
	exit 1
fi

OUTPUT_DIR=${ARGS[3]}
LOG=$OUTPUT_DIR/preemacs_pipeline.log

mkdir -p "$OUTPUT_DIR"

echo "Logging to: $LOG (and printing here)"
bash "$REPO/run_full_pipeline.sh" "$@" 2>&1 | tee "$LOG"
