# SDD ledger — plan: /home/jmsbpp/cfmm/gams-evm-transport/docs/superpowers/plans/2026-08-26-gams-evm-transport-migration.md
Workspace: /tmp/claude-1000/-home-jmsbpp-cfmm-gams-evm-transport/f7e9c387-2b04-40e0-8831-28dc2640b594/scratchpad/sdd
Spec: docs/superpowers/specs/2026-08-26-gams-evm-transport-migration-design.md (rev 3, read)

## Setup rulings
- Ruling: SDD workspace lives in the session scratchpad, not <repo-root>/.superpowers — the repo root at start is the HOME git repo (/home/jmsbpp) and the target repo does not exist until Task 0 replaces ~/cfmm/gams-evm-transport with a clone. Cost if wrong: artifacts not co-located with the repo; none lost.
- Ruling: no feature branch / worktree — the plan creates a NEW repo and commits its 6 follow-up commits on `main` (spec §3-4, user approved twice). Cost if wrong: history on main is linear and reviewable; a branch would add nothing.
- Ruling: Task 0 Step 8 (peer message "rpc-api captured") is executed by the controller, not the implementer subagent (peer messaging is a controller tool). Cost if wrong: none.
- Ruling: Task 0 has no git BASE (repo created in-task). Its review package = filter-repo tip .. HEAD of the local clone (covers the .gitignore commit) plus the implementer's verification transcript in the report file.

## Pre-flight scan (pairs sharing a file/interface)
| pair | produces / consumes | finding |
|---|---|---|
| T0 / T7 | .gitignore created in T0 Step 6; T7 Step 1 only reviews it | consistent |
| T1 / T2 | T1 rewrites cabal (name, license, hs-source-dirs); T2 never touches cabal; T2 interface exempts the 12 cabal `--` comment lines T1 leaves | consistent |
| T2 / T3 / T4 | all edit test/Main.hs sequentially: T2 literals+`purge_roots`/`repo_roots`; T3 `fixture_dir_rule_assertions`+census lists+import list; T4 `gated`+path fns+core_checks | no overlapping hunks; names consistent |
| T3 → T4 | T3 produces `plank_root :: IO (Maybe FilePath)`; T4 `core_checks` consumes it | matches |
| T3 → T6 | `PLANK_ROOT` semantics (unset/empty = absent) mirrored in rig/plank-root.sh | matches |
| T5 → T8 | T5 re-captures gams-conformance.json (`.golden.sha256`, `.model_sources[0].sha256`); T8 CI compares exactly those keys | matches |
| T6 → T8 | rig-e2e calls check-upstream/verify-import/deploy-rig/--stop with PLANK_ROOT from runner .env; T6 makes --stop PLANK_ROOT-free | matches |
| T2 → T7 | partition file path docs/superpowers/plans/2026-08-26-partition.md written in T2, committed in T7 | matches |
| T0 → T4,T6 | `$S/plank` develop clone created T0 Step 7, used by T4 Step 4 and T6 Step 3 | matches |
Per-task self-consistency: T0 expectation 227 commits stated in both Step 4 and Global Constraints; T4 `gated` signature identical in interface, Step 1 and Step 3; T5 `$G` defined in Step 2 before use in Step 4; T8 env created (Step 2) before push (Step 5). Clean.

## Progress
Task 0: implementer DONE (filter-repo tip dba1240, 227 commits; local .gitignore commit b230455; $S/plank origin/develop d2b1c51; repo PUBLIC). Controller-verified repo state independently. Peer session told "rpc-api captured" (msg 4565b1f8). Review dispatched (base dba1240..b230455 + repo-state checks).
Task 0: review Approved. ⚠️ resolved — Ruling: extra dirt in ~/cfmms-playground/cfmm-replicationPlank (modified eta.md/peers.tsv, untracked 225*/lean/) is not from Task 0 (read-only commands only; peer session plank-b9 is reorganizing that repo concurrently) — no action; cost if wrong: none for this repo.
Task 0: minor (deferred): report table should state HEAD=228 (227 + .gitignore) explicitly.
Task 0: complete (commits dba1240..b230455, review clean)
Task 1: BASE b230455; implementer dispatched (Backend Architect, sonnet).
Peer plank-b9: cfmm-wt/rpc_api worktree holds 7 uncommitted files (offchain/rig/loop-conformance.json M, fixtures/volume_path.json M, stack.yaml/.lock, Setup.hs, CHANGELOG.md ??, submodule ptr). Ruling: told peer NOT to discard; asked for tag archive/feat-rpc-api-wip. Follow-up: once tagged, diff loop-conformance.json vs this repo's rig/ copy and surface to the user (Task 9 close-out). Cost if wrong: an extra tag.
Peer: feat/rpc-api deleted; tags archive/feat-rpc-api=29ce4b7, archive/feat-rpc-api-wip=9457137 on origin. Diffed wip: loop-conformance.json is a later live re-capture (2026-08-25, block 14 vs committed 08-24 block 17; same shape; fixture sha differs); stack.yaml/.lock/Setup.hs/CHANGELOG.md are `stack init`/`cabal init` boilerplate. Ruling: import NOTHING now — the suite asserts over the committed 08-24 artifact and the repo is cabal-only by decision; surface the newer loop-conformance capture to the user at close-out (Task 9) as an optional re-pin from the wip tag. Cost if wrong: one artifact commit later.
Task 1: implementer DONE_WITH_CONCERNS (c227dd8). Rulings: (a) plan sed omitted 9 internal build-depends refs to the package name — implementer's extra narrowly-scoped sed is correct and required (plan defect); (b) `gams-evm-transport --help` exit 1 from pre-existing `offchain/rig/rig-pins.json` literal — Task 2 removes it; Task 2 must re-run the --help gate (carried into Task 2 dispatch); (c) plan-mandated `git add -A` swept untracked docs/ (spec+plan) into the rename commit — accepted, not rewritten (local-only but keep history honest; Task 7 commits doc updates). Cost if wrong: one mixed-concern commit.
Task 1: review Approved. ⚠️ old-name tokens survive in test/Main.hs (2), rig/gen-peer-bytes.hs (4), rig/peer-haskell-bytes.json (1) — Ruling: Task 2 (which already rewrites test/Main.hs and rig/) renames the .hs occurrences; the .json provenance string is left unless a check compares it (Task 2 implementer decides with evidence). Cost if wrong: a stale token.
Task 1: complete (commits b230455..c227dd8, review clean)
Task 2: BASE c227dd8
Task 2: implementer DONE (e21a787). Rulings: (a) `gams-evm-transport --help` exits 1 structurally (driver has no --help path and requires rig-manifest.json) — plan gate 4 for the main exe is replaced by "builds + `loop --help` exits 0"; spec §5.4 same. Cost if wrong: none. (b) sc4_cast_agreement passes bare when `cast` is on PATH — still tier-2 gated in Task 4 (CI runner has cast too, but the gate is about the dependency, not this host). (c) partition doc wording mis-attributes src/interfaces/*.plk to cfmm-numopt — they are monorepo paths; Task 4 corrects the wording when it consumes the list.
Task 2 partition rulings for Task 4: (d) `no_credential_is_present_in_a_tracked_file` floor 96 counted the gitignored rig/rig-manifest.json — Task 4 re-measures the floor to 95 with a comment naming that file (the check's own message invites this). (e) `the_ungated_renderer_has_exactly_one_consumer` and `the_endpoint_site_census_grows_with_the_tree` pass repo_roots straight to `grep -r`, which exits 2 on the absent README.md — Task 4 filters roots through a `doesPathExist`-based `existing_roots :: IO [FilePath]` before those greps (README.md arrives in Task 7). (f) `gams_conformance_is_present_and_fresh` stale — expected; Task 5 re-captures. Cost if wrong: a floor one too low / a check that silently narrows if a root vanishes — mitigated by the census asserting members, not counts.
Task 2: review dispatched (c227dd8..e21a787, 60 files).
Task 2: review Approved. ⚠️ resolved — provenance prose in 5 rig/*.json rewritten (offchain/ prefix); no check hash-compares those fields; module-digest staleness is Task 5's re-capture. Minor (deferred): report says "list in the conversation" — not auditable from the report; diff is the evidence.
Task 2: complete (commits c227dd8..e21a787, review clean)
Task 3: BASE e21a787
Task 3: implementer DONE (89f1981). Ruling: unprobed_overrides reason string expanded beyond the brief's literal to clear the census's 200-char thin-reason floor — brief text kept as the lead sentence; accepted (plan defect). Review dispatched.
Task 3: review Approved. Minor (deferred): stale census header prose at test/Main.hs ~4762 ("THE FIVE OVERRIDES…/Six assertions…") predates the task; follow-up.
Task 3: complete (commits e21a787..89f1981, review clean)
Task 4: BASE 89f1981
Task 4: implementer DONE (2d2ee3d). Bare 231/232 (only gams_conformance stale), 61 SKIPPED; PLANK_ROOT run 230/232. Rulings: (h) implementer extended `existing_roots` to the credential scan too — correct (grep -r exits 2 on an absent root); accepted. (i) monorepo-contract drift: consumer constant moved on develop (AlgebraIntegralMevTaxModelOneShocks.t.sol VOLUME_PATH_JSON → MevTaxVolumePathV4.t.sol FIXTURE, same value) — re-point `consumer_test_path`/`consumer_path_constant` in the Task 4 fix round (re-pointed, not deleted; the contract value still holds). Cost if wrong: the check tracks the wrong consumer file — visible on the next PLANK_ROOT run.
Task 4: review dispatched (89f1981..2d2ee3d).
Task 4: review Approved (0 findings). Minor (deferred): `main` recomputes rig_tests_enabled already computed in core_checks. Fix round 1 dispatched for ruling (i) (re-point consumer_test_path/consumer_path_constant); FIX_BASE 2d2ee3d.
Task 4: fix round 1/5 — re-point landed (20e9256; check passes under PLANK_ROOT; bare unchanged 231/232). Controller found the partition doc self-referencing a stale sha (2c8902f); implementer resumed for a doc-only commit; re-review to cover 2d2ee3d..HEAD.
Task 4: fix round 1/5 (2 addressed pending re-review, 0 open — re-point + doc sha; commits 2d2ee3d..1a117cb). Re-review dispatched.
Task 4: fix round 1/5 (2 addressed, 0 open; commits 2d2ee3d..1a117cb)
Task 4: complete (commits 89f1981..1a117cb, review clean)
Task 5: BASE 1a117cb
Task 5: implementer DONE (a19f3e8); golden identical; bare 232/232. Review dispatched.
Task 5: review Approved. Minor (deferred): public-HTTPS submodule init not tested from a clean external clone (CI build-test does this on first run).
Task 5: complete (commits 1a117cb..a19f3e8, review clean)
Task 6: BASE a19f3e8
Task 6: implementer dispatched (DevOps Automator, sonnet).
Task 6: implementer DONE (8454981) but bare suite 231/232 (`the_pinned_read_held_while_the_unpinned_read_moved`) because the brief-mandated import-ref.txt re-pin desynced chain-read-conformance.json. Ruling: plan defect — import-ref.txt moves only with a full re-capture (rig-e2e); revert the re-pin (import-ref.txt + rig-pins.json generatedFrom back to 2039f27), document the coupling. Cost if wrong: import-ref lags develop until the first rig-e2e run — which is the honest state. Also accepted: implementer re-based two monorepo-side fixture paths in capture-loop.sh/capture-batch-return.sh (needed). Fix round 1 dispatched (FIX_BASE 8454981); task review to follow over a19f3e8..HEAD.
Task 6: fix round 1/5 (1 addressed, 0 open — re-pin reverted, bare 232/232; commits 8454981..a2c2f64). Task review dispatched over a19f3e8..a2c2f64.
Task 6: review Approved. Minor (deferred): deploy-rig.sh computes TRANSPORT_ROOT twice (own line + sourced plank-root.sh); brief said six B_* reads, actual seven.
Task 6: complete (commits a19f3e8..a2c2f64, review clean)
Task 7: BASE a2c2f64
Task 7: implementer DONE (1c372ec), bare 232/232. Review dispatched.
Task 7: review Approved. Minor (deferred): lib/ group rows are paraphrases of haddock essays, not quotes.
Task 7: complete (commits a2c2f64..1c372ec, review clean)
Task 8: BASE 1c372ec. Steps 1-3 to implementer; Step 4 (runner, sudo) is the user's; Step 5 (push + first run) after the user confirms the runner.
Task 8: steps 1-3 DONE (3f1091e); env transport-gate created with required reviewer; actionlint clean. Review dispatched.
Task 8: review Approved (steps 1-3). Minor (deferred): CI golden step silences gams' own exit (failure still caught by the sha step under pipefail, worse diagnostics); transport-gate has can_admins_bypass=true (GitHub default).
Task 8: steps 1-3 complete (commits 1c372ec..3f1091e, review clean); steps 4-5 pending USER (runner registration) then push + first run.
Final whole-branch review dispatched over dba1240..3f1091e (12 commits) before any push.
Task 8 step 4: USER registered runner cfmm-build-transport (online, labels self-hosted,Linux,X64,cfmm-build; PLANK_ROOT=~/actions-runner-transport/plank @ d2b1c51). Step 5 (push + first run) waits on the final review.
FINAL REVIEW: Needs fixes (no correctness/security defect). Rulings: (A) spec gate 4 satisfied by adding --help to app/Main.hs (supersedes the Task-2 ruling that dropped the gate); (B) README names ETH_RPC_URL via a declared EndpointSite; (C) CI DSN assembled at run time; (D) rig-e2e validates committed artifacts at rig/import-ref.txt's ref — check-upstream removed from CI (re-pin is the manual cycle); (E) monorepo name → cfmm-vol-markets; (F,G,H) minors fixed; sc4_cast_agreement tier-2 stays (spec-sanctioned); docs with local paths accepted; can_admins_bypass default accepted. Corrected records: Task 6 minor "TRANSPORT_ROOT twice" CLOSED as not a defect (load-bearing for --stop); Task 8 minor mechanism corrected: gams failure is caught by bash -e, not pipefail. ONE fix dispatch (FIX_BASE 3f1091e); one scoped re-review; no second wave.
Final fix wave DONE (3f1091e..6028d89, 5 commits; bare 232/232; --help 0). Scoped re-review dispatched.
Final fix wave re-review: all A-H ADDRESSED, no new breakage. Out-of-scope minors (deferred → Task 9 issue 6): docker run hardcodes POSTGRES_PASSWORD=postgres; `else pure ()` in --help branch.
Task 8 step 5: PUSHED main dba1240..6028d89 (17 commits); haskell.yml dispatched, run 32986773735 waiting on transport-gate approval (USER); background watch running.
Task 9: implementer dispatched (7 issues: 6 in gams-evm-transport, 1 in cfmm-vol-markets).
Task 9: complete (7 issues: gams-evm-transport #1-#6, cfmm-vol-markets #52).
Task 8: complete — first run 32986773735 GREEN (approve+build-test); recorded and pushed.
