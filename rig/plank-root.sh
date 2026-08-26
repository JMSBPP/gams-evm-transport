#!/usr/bin/env bash
# SOURCED, never executed. Resolves the two roots every rig script needs:
#   TRANSPORT_ROOT  this repository (where rig/*.json are written)
#   PLANK_ROOT      a checkout of JMSBPP/cfmm-replicationPlank with an `origin` remote
# Its Haskell twin is Loop.Config.plank_root: same variable, same "unset or empty means absent"
# rule. Here absence is FATAL because every caller of this file needs forge/anvil sources that
# only the monorepo carries.
TRANSPORT_ROOT="$(git rev-parse --show-toplevel)"
cd "$TRANSPORT_ROOT"
if [ -z "${PLANK_ROOT:-}" ]; then
  echo "FATAL: PLANK_ROOT is unset. Point it at a checkout of JMSBPP/cfmm-replicationPlank." >&2
  exit 64
fi
if [ ! -f "$PLANK_ROOT/foundry.toml" ] || ! git -C "$PLANK_ROOT" remote get-url origin >/dev/null 2>&1; then
  echo "FATAL: PLANK_ROOT=$PLANK_ROOT is not a monorepo checkout (needs foundry.toml and an origin remote)." >&2
  exit 64
fi
PLANK_ROOT="$(cd "$PLANK_ROOT" && pwd -P)"
export TRANSPORT_ROOT PLANK_ROOT
