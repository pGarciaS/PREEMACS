#!/bin/bash
# End-to-end PREEMACS pipeline: M1 -> BM -> generateN4 -> MRIQC -> M3, one continuous
# pass on a single fresh subject. Each --app call inherits its own script's internal
# `set -e`; this wrapper's own `set -e` stops the whole chain the moment any stage's
# `apptainer run` returns non-zero, so a later stage never silently runs on top of a
# stage that actually failed.
#
# Usage:
#   ./run_full_pipeline.sh [--all-sessions] SUB_ID T1_PATH T2_PATH OUTPUT_DIR [FS_LICENSE]
#
#   --all-sessions  Only matters when T1_PATH/T2_PATH is a directory (see below).
#                    Search it RECURSIVELY, so all runs (volumes) from every session under a BIDS
#                    subject folder (sub-X/ses-*/anat/) are found and averaged
#                    together. Without this flag, only that one directory's direct
#                    contents are used (e.g. point it at a single ses-X/anat/ to
#                    average only that session's runs). This changes what actually
#                    gets averaged into the final image, so you should pick wisely.
#   SUB_ID       Subject ID (e.g. sub-01)
#   T1_PATH      A single T1 .nii.gz file, OR a directory. If the directory (or its
#                subtree, with --all-sessions) contains BIDS-style *T1w*.nii.gz
#                files, exactly those are used as the runs to average (T2w files in
#                the same directory, e.g. a mixed BIDS anat/ folder, are correctly
#                ignored). Otherwise every *.nii.gz found is treated as a run.
#   T2_PATH      Same, for T2 (matches *T2w*.nii.gz).
#   OUTPUT_DIR   Where results go. This script creates OUTPUT_DIR/preemacs (M1/BM/
#                generateN4/MRIQC output) and OUTPUT_DIR/freesurfer (M3's own
#                FreeSurfer subject tree) -- kept separate because recon-all refuses
#                to run on a subject folder that already exists, and the PREEMACS
#                output folder always does by the time M3 runs.
#   FS_LICENSE   Path to your FreeSurfer license.txt. Optional if $FS_LICENSE is
#                already set in your environment.
#
# Examples:
#   ./run_full_pipeline.sh sub-01 /data/raw/sub-01_T1w.nii.gz /data/raw/sub-01_T2w.nii.gz \
#       /data/results/sub-01 ~/licenses/freesurfer_license.txt
#
#   # Average every run in one session of a BIDS dataset:
#   ./run_full_pipeline.sh sub-01 /data/bids/sub-01/ses-01/anat /data/bids/sub-01/ses-01/anat \
#       /data/results/sub-01
#
#   # Average every run across ALL sessions:
#   ./run_full_pipeline.sh --all-sessions sub-01 /data/bids/sub-01 /data/bids/sub-01 \
#       /data/results/sub-01

set -e -o pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
	sed -n '2,43p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
	exit 0
fi

ALL_SESSIONS=0
if [ "${1:-}" = "--all-sessions" ]; then
	ALL_SESSIONS=1
	shift
fi

if [ $# -lt 4 ]; then
	echo "Usage: $(basename "$0") [--all-sessions] SUB_ID T1_PATH T2_PATH OUTPUT_DIR [FS_LICENSE]" >&2
	echo "Run with -h for full usage notes and examples." >&2
	exit 1
fi

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIF=$REPO/preemacs.sif

ID=$1
T1_INPUT=$2
T2_INPUT=$3
OUTPUT_DIR=$4
FS_LICENSE=${5:-${FS_LICENSE:-}}

[ -e "$SIF" ] || { echo "ERROR: $SIF not found -- build it first (see README.md)." >&2; exit 1; }
[ -e "$T1_INPUT" ] || { echo "ERROR: T1_PATH does not exist: $T1_INPUT" >&2; exit 1; }
[ -e "$T2_INPUT" ] || { echo "ERROR: T2_PATH does not exist: $T2_INPUT" >&2; exit 1; }
[ -n "$FS_LICENSE" ] || { echo "ERROR: no FreeSurfer license given (5th argument or \$FS_LICENSE)." >&2; exit 1; }
[ -e "$FS_LICENSE" ] || { echo "ERROR: FS_LICENSE does not exist: $FS_LICENSE" >&2; exit 1; }

OUTDIR=$OUTPUT_DIR/preemacs
FSDIR=$OUTPUT_DIR/freesurfer
NTHREADS=$(( $(nproc) * 7 / 10 ))

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "=== PREEMACS full pipeline starting ==="
log "Subject: $ID"
log "T1: $T1_INPUT"
log "T2: $T2_INPUT"
log "PREEMACS output dir: $OUTDIR"
log "FreeSurfer subjects dir: $FSDIR"
log "Threads capped at: $NTHREADS"

mkdir -p "$OUTDIR" "$FSDIR"

module load singularity/1.2.0

# M1's -t1_path/-t2_path must be DIRECTORIES (every *.nii.gz inside is one run,
# averaged together). resolve_modality_binds turns a file or a directory into a
# list of --bind flags that build exactly that directory inside the container --
# always as individual per-file binds (never the whole host directory at once),
# so it also works correctly when the source directory mixes T1w/T2w together
# (a BIDS anat/ folder) or spans multiple sessions (with --all-sessions).
resolve_modality_binds() {
	local input=$1 tag=$2 dest=$3 recursive=$4
	local -a files=()
	if [ -f "$input" ]; then
		files=("$input")
	elif [ -d "$input" ]; then
		local -a maxd=(); [ "$recursive" = 1 ] || maxd=(-maxdepth 1)
		while IFS= read -r -d '' f; do files+=("$f"); done < <(find "$input" "${maxd[@]}" -iname "*${tag}*.nii.gz" -print0 | sort -z)
		if [ ${#files[@]} -eq 0 ]; then
			# No BIDS-suffix match: fall back to every .nii.gz found (a directory
			# the caller already pre-separated by modality, with arbitrary names).
			while IFS= read -r -d '' f; do files+=("$f"); done < <(find "$input" "${maxd[@]}" -iname "*.nii.gz" -print0 | sort -z)
		fi
	else
		echo "ERROR: not a file or directory: $input" >&2
		exit 1
	fi
	if [ ${#files[@]} -eq 0 ]; then
		echo "ERROR: no .nii.gz files found for $tag under: $input$( [ "$recursive" = 1 ] && echo ' (searched recursively)' )" >&2
		exit 1
	fi
	local -a binds=() seen=()
	local f base name
	for f in "${files[@]}"; do
		base=$(basename "$f"); name=$base; local i=1
		while [[ " ${seen[*]-} " == *" $name "* ]]; do name="${i}_${base}"; i=$((i+1)); done
		seen+=("$name")
		binds+=(--bind "$f":"$dest/$name")
	done
	printf '%s\n' "${binds[@]}"
}
mapfile -t T1_BIND < <(resolve_modality_binds "$T1_INPUT" T1w /data/in_t1 "$ALL_SESSIONS")
mapfile -t T2_BIND < <(resolve_modality_binds "$T2_INPUT" T2w /data/in_t2 "$ALL_SESSIONS")
log "T1 runs: $(( ${#T1_BIND[@]} / 2 ))"
log "T2 runs: $(( ${#T2_BIND[@]} / 2 ))"

log "=== STAGE 1/5: M1 (conform, register, crop) ==="
apptainer run --app M1 \
  --bind "$FS_LICENSE":/opt/freesurfer/license.txt \
  --env FS_LICENSE=/opt/freesurfer/license.txt \
  "${T1_BIND[@]}" \
  "${T2_BIND[@]}" \
  --bind "$OUTDIR":/data/out \
  "$SIF" \
  -id "$ID" \
  -t1_path /data/in_t1 \
  -t2_path /data/in_t2 \
  -out_path /data/out/
log "STAGE 1/5 (M1) done"

log "=== STAGE 2/5: BM (brain extraction) ==="
apptainer run --app BM \
  --bind "$FS_LICENSE":/opt/freesurfer/license.txt \
  --env FS_LICENSE=/opt/freesurfer/license.txt \
  --bind "$OUTDIR":/data/out \
  "$SIF" \
  "$ID" \
  /data/out
log "STAGE 2/5 (BM) done"

log "=== STAGE 3/5: generateN4 (bias field correction) ==="
apptainer run --app generateN4 \
  --bind "$OUTDIR":/data/out \
  "$SIF" \
  -dataDir /data/out \
  -maskDir /data/out \
  -id "$ID" \
  -outDir /data/out/N4
log "STAGE 3/5 (generateN4) done"

log "=== STAGE 4/5: MRIQC (anatomical QC metrics) ==="
apptainer run --app MRIQC \
  --bind "$OUTDIR":/data/out \
  "$SIF" \
  -dataDir /data/out \
  -templateDir /opt/preemacs/templates \
  -n4dir /data/out/N4 \
  -id "$ID"
log "STAGE 4/5 (MRIQC) done"

log "=== STAGE 5/5: M3 (FreeSurfer recon + T2 pial + parcellation) ==="
apptainer run --app M3 \
  --bind "$FS_LICENSE":/opt/freesurfer/license.txt \
  --env FS_LICENSE=/opt/freesurfer/license.txt \
  --bind "$OUTDIR":/data/out \
  --bind "$FSDIR":/data/fs \
  --env SUBJECTS_DIR=/data/fs \
  --env OMP_NUM_THREADS=$NTHREADS \
  --env ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NTHREADS \
  --env LC_ALL=C \
  "$SIF" \
  "$ID" \
  /data/out
log "STAGE 5/5 (M3) done"

log "=== PREEMACS full pipeline COMPLETE for $ID ==="
log "PREEMACS output: $OUTDIR/$ID"
log "FreeSurfer surfaces/labels: $FSDIR/$ID/{surf,label}"
