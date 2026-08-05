#!/usr/bin/env bash
#
# apply-labels.sh — sync governance/labels.yml to the plant FAMILY repos.
#
# SAFETY / SCOPE
#   * Operates ONLY on the explicit, hard-coded list below. It NEVER enumerates the org
#     (no `gh repo list traitecoevo`). This is deliberate: the taxonomy is family-scoped.
#   * Idempotent: uses `gh label create --force`, which creates a label or updates it in place
#     (colour + description) if it already exists. Running twice is a no-op on the second run.
#   * Dry-run by DEFAULT. It prints what it WOULD do and changes nothing unless you pass --apply.
#   * It does not delete labels. Removing the GitHub default labels (enhancement/duplicate/...) is a
#     manual decision — see the commented note at the bottom.
#
# USAGE
#   ./apply-labels.sh            # dry run: show every label x repo it would sync
#   ./apply-labels.sh --apply    # actually create/update labels (run only after sign-off)
#   ./apply-labels.sh --apply --only plant,regnans   # restrict to a subset of the list
#
# Requires: gh (authenticated to traitecoevo), python3 with pyyaml.

set -euo pipefail

# --- The hard-coded family repo list (edit deliberately; never auto-generate) ----------------
# Scope = the plant model-core, docs, and viz repos, plus floracle. NOT the whole org.
# Keep this list explicit; never `gh repo list traitecoevo`.
FAMILY_REPOS=(
  # model core
  traitecoevo/plant
  traitecoevo/phylloptim
  traitecoevo/odelia
  traitecoevo/regnans
  traitecoevo/logpile
  traitecoevo/phytofile
  traitecoevo/plant-meta
  # docs / visualisation
  traitecoevo/overstorey
  traitecoevo/standviz
  # applications
  traitecoevo/floracle
)

# --- DELIBERATELY EXCLUDED from the family taxonomy (do NOT add to FAMILY_REPOS without sign-off) --
#   traitecoevo/mulgafutures      # project tracker with its OWN board + bespoke work-package taxonomy
#   traitecoevo/mulga_plots_data  # private data repo; no real issue workflow yet
# See AGENTS.md "Governance scope". Add only if these adopt board #5 and the generic workflow.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABELS_YML="${SCRIPT_DIR}/labels.yml"

APPLY=false
ONLY=""
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=true ;;
    --only) ONLY="__NEXT__" ;;
    *) if [ "$ONLY" = "__NEXT__" ]; then ONLY="$arg"; else echo "Unknown arg: $arg" >&2; exit 2; fi ;;
  esac
done

command -v gh >/dev/null      || { echo "ERROR: gh not found" >&2; exit 1; }
command -v python3 >/dev/null || { echo "ERROR: python3 not found" >&2; exit 1; }
[ -f "$LABELS_YML" ]          || { echo "ERROR: $LABELS_YML not found" >&2; exit 1; }

# Optionally restrict to a comma-separated subset (bare repo names or full owner/name).
REPOS=()
if [ -n "$ONLY" ] && [ "$ONLY" != "__NEXT__" ]; then
  IFS=',' read -ra want <<< "$ONLY"
  for r in "${FAMILY_REPOS[@]}"; do
    for w in "${want[@]}"; do
      [ "$r" = "$w" ] || [ "$r" = "traitecoevo/$w" ] && REPOS+=("$r")
    done
  done
  [ ${#REPOS[@]} -gt 0 ] || { echo "ERROR: --only matched nothing in the family list" >&2; exit 1; }
else
  REPOS=("${FAMILY_REPOS[@]}")
fi

# Emit "name<TAB>color<TAB>description" lines from labels.yml.
read_labels() {
  python3 - "$LABELS_YML" <<'PY'
import sys, yaml
with open(sys.argv[1]) as f:
    doc = yaml.safe_load(f)
for lab in doc.get("labels", []):
    name = lab["name"]; color = str(lab.get("color","")).lstrip("#"); desc = lab.get("description","")
    print(f"{name}\t{color}\t{desc}")
PY
}

# bash 3.2 (macOS default) has no `mapfile`, so stage the parsed labels in a temp file.
LABELS_TSV="$(mktemp)"
trap 'rm -f "$LABELS_TSV"' EXIT
read_labels > "$LABELS_TSV"
LABEL_COUNT=$(grep -c . "$LABELS_TSV" || true)

echo "Loaded ${LABEL_COUNT} labels from $LABELS_YML"
echo "Target repos (${#REPOS[@]}):"; printf '  - %s\n' "${REPOS[@]}"
$APPLY || echo $'\n*** DRY RUN — nothing will change. Re-run with --apply to sync. ***'
echo

# --- Migration map: rename existing labels in place so already-tagged issues carry over -------
# Applied per repo ONLY when the OLD label exists and the NEW one does not. After a rename, phase 2
# (--force create) fixes colour/description. bug/epic/question keep their names (phase 2 restyles).
# enhancement -> task (the GitHub default "New feature or request"; most are discrete work —
# re-tag true epics by hand). The plant core (plant/overstorey/regnans) already uses
# bug/task/epic, so no rename fires there — phase 2 just recolours them to the shared palette.
RENAME_MAP=(
  "enhancement=>task"
)
# NOT in the taxonomy and NOT remapped (apply-labels.sh does not delete): good first issue,
# help wanted, duplicate, invalid, wontfix, documentation (community/default labels we dropped);
# 'in progress' / 'low priority' (board-mirroring — the board owns Status; no Priority field today);
# repo-local customs ('new data' in phytofile) are left alone. Delete unwanted ones deliberately
# (see bottom).

for repo in "${REPOS[@]}"; do
  echo "==> $repo"
  existing="$(gh label list --repo "$repo" --limit 200 --json name -q '.[].name' 2>/dev/null)"

  # Phase 1: rename legacy labels into the new scheme.
  for pair in "${RENAME_MAP[@]}"; do
    old="${pair%%=>*}"; new="${pair##*=>}"
    printf '%s\n' "$existing" | grep -Fxq -- "$old" || continue          # old not present
    if printf '%s\n' "$existing" | grep -Fxq -- "$new"; then
      echo "    NOTE: both '$old' and '$new' exist — merge manually (not auto-deleting '$old')"
      continue
    fi
    if $APPLY; then
      gh label edit "$old" --repo "$repo" --name "$new" >/dev/null && echo "    renamed: '$old' -> '$new'"
      existing="$(printf '%s\n%s' "$existing" "$new")"                   # so later rules see it
    else
      echo "    would rename: '$old' -> '$new'"
    fi
  done

  # Phase 2: create/update the full taxonomy (idempotent).
  while IFS=$'\t' read -r name color desc; do
    [ -n "$name" ] || continue
    if $APPLY; then
      gh label create "$name" --repo "$repo" --color "$color" --description "$desc" --force >/dev/null \
        && echo "    synced: $name"
    else
      echo "    would sync: $name (#$color) — $desc"
    fi
  done < "$LABELS_TSV"
done

echo
$APPLY && echo "Done. Renamed legacy labels + synced ${LABEL_COUNT} labels to ${#REPOS[@]} repo(s)." \
       || echo "Dry run complete. Would rename legacy labels + sync ${LABEL_COUNT} labels x ${#REPOS[@]} repos."

# --- Optional cleanup (NOT automated) --------------------------------------------------------
# Legacy labels mapped above are RENAMED (issues carry over). Labels NOT in the map are left as-is
# (e.g. 'good first issue', 'duplicate', 'invalid', 'wontfix', 'documentation', 'low priority',
# 'in progress', 'new data'). To remove an unwanted default that has no issues, delete deliberately:
#   gh label delete <name> --repo traitecoevo/<repo> --yes
