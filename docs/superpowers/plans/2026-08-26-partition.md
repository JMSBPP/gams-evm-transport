# Bare test-suite partition (Task 2, Step 4)

Measured 2026-08-26 at commit range starting from `c227dd8` (Task 1 HEAD), after Task 2's
`offchain/` re-rooting, with:

```bash
env -u PLANK_ROOT -u PGSTORE_DSN -u RIG_TESTS cabal test
```

Result: **168/232 checks passed, 64 FAILED**. Zero build warnings; the executable and test
suite both compile clean (see `task-2-report.md`). Every failure below was read individually
from `/home/jmsbpp/cfmm/bare-test.log`; none were guessed from the check name alone.

Classification rule (given): a message that literally names `src/…`, `test/models/…`,
`test/pos_spec/…`, `origin/develop` or `import-ref` is **monorepo-contract**; a message that
literally names `rig-manifest.json`, `cast`, `manifest` or a chain read is **rig/foundry**; a
message that literally names `PGSTORE_DSN` or `connect` is **postgres**; a message naming a
`lib/ app/ rig/ test/` path that is wrong (a leftover Step-1 miss) is **path-literal**. Four
failures fit none of the three literal-keyword buckets and are **unclassified**, each quoted
verbatim below with the evidence for its real cause.

## path-literal (fix now, Step-1 misses) — 0

None found. The post-rewrite `grep -rn offchain lib app test rig LOOP.md spec todo.md` is
empty (see report), and no failure below names an incorrect `lib/app/rig/test` path.

## monorepo-contract (Task 4) — 50

Every one of these reads a file that lives in the sibling MONOREPO checkout, resolved under
`PLANK_ROOT` (`src/interfaces/...`, `src/models/...` -- corrected here at Task 4: these are
monorepo paths, not `cfmm-numopt` / GAMS-model paths; `cfmm-numopt` is this repository's own
GAMS-only numerical layer and carries no `src/interfaces` tree at all), a Solidity-testing-track
fixture under `test/pos_spec/...` (also monorepo-resolved), or the `origin/develop` git ref this
clone does not carry:

```
sc4_multiline_timepoint_written
sc4_idempotent_canonical_form
sc4_falsifiable
rpin01_encoder_selector_is_recomputed
rpin_e1_v2_decode_behavior
rpin04_topic0_is_recomputed
rpin04_positive_v2_decode
rpin04_v1_shape_is_rejected
rpin04_retired_topic0s_are_rejected
rpin05_live_bytes_match_the_external_golden
rpin04_e1_is_filtered_on_the_emitter
driv01_e3_decode_behavior
the_local_shocklib_emitter_matches_the_decoder
the_default_fixture_path_is_the_consumers_own_constant
sc4_pin_selector_beforeSwap
sc4_pin_selector_changeFeeConfiguration
sc4_pin_selector_create_order
sc4_pin_selector_create_orders
sc4_pin_selector_deposit
sc4_pin_selector_getAverageVolatility
sc4_pin_selector_getCurrentFee
sc4_pin_selector_getFeeConfig
sc4_pin_selector_getOrderPacked
sc4_pin_selector_getTickCumulative
sc4_pin_selector_getTimepointPacked
sc4_pin_selector_getTwapTick
sc4_pin_selector_initializeDynamicFee
sc4_pin_selector_initializeHook
sc4_pin_selector_initializeTWAP
sc4_pin_selector_lastIndex
sc4_pin_selector_oldestIndex
sc4_pin_selector_orderCount
sc4_pin_selector_owner
sc4_pin_selector_poolId
sc4_pin_selector_poolManager
sc4_pin_selector_previewDeposit
sc4_pin_selector_previewRiskPrice
sc4_pin_selector_readWindow
sc4_pin_selector_riskPrice
sc4_pin_selector_riskWeightedShares
sc4_pin_selector_setRiskPrice
sc4_pin_selector_totalDeposits
sc4_pin_selector_totalShares
sc4_pin_selector_writeTimepoint
sc4_pin_topic0_FeeApplied
sc4_pin_topic0_FeeConfigurationChanged
sc4_pin_topic0_Shock
sc4_pin_topic0_TimepointWritten
sc4_pin_topic0_VolOrderCreated
sc4_pin_topic0_WindowChanged
```

Matches the brief's expected members exactly: `the_default_fixture_path_is_the_consumers_own_constant`
(names `origin/develop`); the `realized_vol_iface` readers (`RealizedVolatilityInterface.plk`:
`sc4_multiline_timepoint_written`, `sc4_pin_selector_getTwapTick`, `driv01_e3_decode_behavior`,
etc.); the `dynamic_fee_hook_iface` readers (`DynamicFeeHookInterface.plk`:
`sc4_idempotent_canonical_form`, `sc4_pin_selector_beforeSwap`, etc.); the `volorder_iface`
readers (`VolOrderManagerInterface.plk`: `sc4_falsifiable`, `rpin01_encoder_selector_is_recomputed`,
etc.); `shocklib_path` (`ShockLib.plk`: `sc4_pin_topic0_Shock`,
`the_local_shocklib_emitter_matches_the_decoder`); and `golden_file`
(`rpin05_live_bytes_match_the_external_golden`, names `test/pos_spec/fixtures/...`).

## rig/foundry (Task 4 tier 2) — 10

Every one of these names `rig-manifest.json` (gitignored, written only by a live
`rig/deploy-rig.sh` run) as the blocking cause:

```
sc3_load_succeeds
sc3_corrupted_manifest_fails
rpin03_module_constant_is_the_deployed_spacing
rpin05_capture_is_present_and_fresh
driv01_cheat_swap_proof_is_present_and_fresh
driv01_run_capture_is_present_and_fresh
driv01_legacy_write_price_still_ran
driv02_run_capture_orders_are_fresh
the_live_loop_capture_records_a_run_that_solved_and_published
sentinel_falsification_harness
```

Matches the brief's expected `sc3_load_succeeds` member. **Deviation from the brief's other
expected member**: the brief also listed `sc4_cast_agreement` as an expected `rig` failure, but
in this sandbox it **PASSED**. Reading its body (`test/Main.hs:1111`), it does not need a
standing rig at all -- it shells to `cast --version` and, if that succeeds, compares `cast sig`
output against the *committed* `rig/rig-pins.json` (present in this checkout). `cast` (Foundry)
happens to be on `PATH` here, so the check ran and agreed. This is an environment difference,
not a Task-2 defect.

## postgres (Task 4 tier 2) — 0

None found. No failure message names `PGSTORE_DSN` or a connection attempt; `Store.Postgres`
is apparently never exercised by the bare partition's checks (or is gated out before it would
need to connect).

## unclassified — 4

These four do not literally name any of the three keyword sets above, so they are not
force-fit into a bucket. Message quoted verbatim, with the evidence for the real cause:

**1. `no_credential_is_present_in_a_tracked_file`**
> "the credential scan reached 95 files, below the floor of 96. grep exits 1 for \"found
> nothing\" AND for \"matched no files at all\", so a scan that has collapsed reports exactly
> what a clean scan reports. If files were removed on purpose, re-measure this floor and say
> so."

Evidence: `find lib app test rig migrations spec LOOP.md todo.md -type f \( -name '*.hs' -o
-name '*.sh' -o -name '*.sql' -o -name '*.json' \) | wc -l` = **95** in this checkout, exactly
one below the floor. `rig/rig-manifest.json` (`.json`, gitignored, absent in this bare
checkout) is the one `.json` file present in an environment with a standing rig and absent
here -- 96 was almost certainly measured with a rig up. Real cause: **rig/foundry**-adjacent
(the floor was set counting a file this bare partition cannot have), but the failure text
itself never names `rig-manifest.json`, so it is not force-classified there.

**2. `the_ungated_renderer_has_exactly_one_consumer`**
> "the consumer scan failed with exit 2: grep: README.md: No such file or directory"

**3. `the_endpoint_site_census_grows_with_the_tree`**
> "the census scan itself failed with exit 2: grep: README.md: No such file or directory"

Evidence for both: `repo_roots` (Step 2) correctly includes `"README.md"` per the brief, and
`walk_files` was given a `doesPathExist` guard so it tolerates the missing file -- but these two
checks call `grep -rlF ...` directly with `repo_roots` as literal grep operands (not through
`walk_files`), and GNU `grep -r` exits 2 with "No such file or directory" for a nonexistent
path argument. Task 7 creates `README.md`; until then, these two checks fail in the bare
partition by construction. Not a Step-1 path-literal miss (the referenced path is `README.md`,
not a wrong `lib/app/rig/test` literal), so not force-classified as path-literal either.

**4. `gams_conformance_is_present_and_fresh`**
> "the committed GAMS conformance capture is STALE. These modules have been edited since it was
> taken:
>       lib/Gams/Argv.hs: recorded=099d9a88729c0f2acd791478d9a8e81450551c82a4445fce4034ae08e702385f recomputed=dcc09db3af8e956a939be6862e5fc5ceb7865f89da4a0937da592a340ab648d8
>       lib/Gams/Artifact.hs: recorded=ac943852c4bc15acc901f6577256c234c3373d28bf06695559f825208a5632e4 recomputed=c9037435db231112831a4fe298a829015be03ee8026a8297968e03300855a10c
>       ... Re-take it: bash rig/capture-gams-conformance.sh"

Evidence: `git diff lib/Gams/Argv.hs lib/Gams/Artifact.hs` shows exactly the Step-1 haddock
rewrite (`offchain\/rig\/volume-path-golden.json` -> `rig\/volume-path-golden.json`,
`offchain\/lib\/Store\/` -> `lib\/Store\/`, and the `@offchain\/@` -> `this tree` sentence in
`Argv.hs`). Re-rooting the literal legitimately changed these files' bytes, so the sha256s
recorded in the committed `rig/gams-conformance.json` are now correctly reported stale -- this
is the check doing its job, not a defect. It literally names two existing `lib/...` paths,
which would satisfy the path-literal keyword rule mechanically, but there is nothing to "fix
now": the paths are correct and nothing is a leftover `offchain/` miss. Remediation
(`bash rig/capture-gams-conformance.sh`) needs a live GAMS/CONOPT toolchain, so in substance it
belongs with the rig/foundry tier, but its message never names `rig-manifest.json`, `cast` or
`manifest`, so it is reported here rather than silently folded into that bucket.

## Totals

| class | count |
|---|---|
| path-literal | 0 |
| monorepo-contract | 50 |
| rig/foundry | 10 |
| postgres | 0 |
| unclassified | 4 |
| **total FAILED** | **64** |

168 + 64 = 232, matching `cabal test`'s own summary line.

## monorepo-contract drift (Task 4, Step 4) — 1

Measured 2026-08-26 running `PLANK_ROOT="$S/plank" cabal test` against the dedicated
`origin/develop` clone at `d2b1c51` (Task 0 Step 7's clean checkout). All 50 monorepo-contract
checks and all 10 rig/foundry checks ran for real (zero `SKIPPED (PLANK_ROOT` lines; `RIG_TESTS`
was not set, so the 10 rig/foundry checks plus `sentinel_falsification_harness` still print
`SKIPPED (RIG_TESTS unset)`, which is expected and unrelated to this finding). 49 of the 50
monorepo-contract checks PASSED against real content. One FAILED, and its message names content,
not a path -- so per the brief this is recorded here rather than gated away:

**`the_default_fixture_path_is_the_consumers_own_constant`**
> "the extractor found 0 declarations of VOLUME_PATH_JSON in
> test/models/mev_tax_model_one/AlgebraIntegralMevTaxModelOneShocks.t.sol on origin/develop,
> expected exactly 1: []."

Evidence, read directly off the clone: `git -C "$S/plank" show
origin/develop:test/models/mev_tax_model_one/AlgebraIntegralMevTaxModelOneShocks.t.sol` no longer
declares `VOLUME_PATH_JSON` at all -- the file instead carries the comment "The VolumePath replay
moved to the v4 file MevTaxVolumePathV4.t.sol (the fixture is a v4 DynamicFeeHook pool;
@cryptoalgebra 0.8.20 and v4-core 0.8.26 cannot share this graph)". The constant moved with the
replay: `test/models/mev_tax_model_one/MevTaxVolumePathV4.t.sol` on `origin/develop` declares
`string constant FIXTURE = "test/models/mev_tax_model_one/fixtures/volume_path.json";` -- same
STRING VALUE, new NAME (`VOLUME_PATH_JSON` -> `FIXTURE`) and new FILE
(`AlgebraIntegralMevTaxModelOneShocks.t.sol` -> `MevTaxVolumePathV4.t.sol`). This side's own
`Loop.Config.default_fixture_path` (`default_fixture_dir </> fixture_file_name` =
`"test/models/mev_tax_model_one/fixtures/volume_path.json"`) still agrees with the VALUE, so
LOOP-04's byte-equality contract is not actually violated -- but `consumer_test_path` and
`consumer_path_constant` in `test/Main.hs` (28-04) still name the OLD file and the OLD constant
name, so the check that is supposed to catch exactly this kind of drift can no longer find its
own subject. This is a real, measured monorepo-contract drift, not a bug introduced by Task 4's
gating: the check was gated (gains `PLANK_ROOT`), ran for real against the live clone, and
reddened on its own evidence. Per the brief ("If one fails with a message about content (not a
path), it is a genuine contract drift -- record it in the partition file; do not gate it away"),
`the_default_fixture_path_is_the_consumers_own_constant` is left exactly as it is: RED against a
real `PLANK_ROOT`, GREEN (skipped) bare. Re-verifying and re-pointing `consumer_test_path` /
`consumer_path_constant` at `MevTaxVolumePathV4.t.sol` / `FIXTURE` is follow-up work outside Task
4's scope (the check's own assertion, not its gating, is what would need to change).

Re-pointed in fix round 1 (the commit titled `test: re-point the consumer-constant contract check at MevTaxVolumePathV4.t.sol/FIXTURE`); passes against origin/develop d2b1c51.

## monorepo-contract drift (rig scripts) — 1

Measured 2026-08-26 running Task 6 Step 3's verification loop against the same dedicated
`origin/develop` clone, `PLANK_ROOT="$S/plank"` at `d2b1c518f56dcc82c7cc72d29ab870a44b5be2a8`
(`origin/develop`'s current tip; matches the `d2b1c51` short form used above). `check-upstream.sh`
passed (`OPEN: ... 0x98d950ec present`) and re-pinned `rig/import-ref.txt` from `2039f278...` to
`d2b1c518...`. `verify-import.sh` then FAILED:

```
SC-1 FAIL sha256 notes/DATA_CONTRACT.md: pinned=b9f8a1198f39d2bcca28025941ca290feb67e6becccec83eed897a6e1cd259ea actual=18f00b14f034d17bf16019df39a75051bd3d3e400ed7d98f3d8b0092b4e687c4
```

This is check (b) (the sha256 recompute against
`.planning/phases/20-deploy-rig-source-of-truth-import/IMPORT-PIN.md`), not check (a) (the git
content diff): (a) passed silently because `$S/plank`'s working tree IS `origin/develop`'s tip, so
`git diff d2b1c518... -- <paths>` compares the tree to itself. `IMPORT-PIN.md` itself is present
(not absent) at 5494 bytes, but its committed sha256 for `notes/DATA_CONTRACT.md` was pinned back
when `import-ref.txt` held the older `2039f278...` ref — the file's content on `origin/develop` has
legitimately moved since that pin was taken, and `IMPORT-PIN.md` was never re-taken against the
newer tip. This is the same class of finding as the `default_fixture_path` entry above: a real,
measured monorepo-contract drift between the pinned evidence and the live `develop` branch, not a
defect in `verify-import.sh`'s wiring. `verify-import.sh` is correctly PLANK_ROOT-gated (Step 3's
`env -u PLANK_ROOT bash rig/verify-import.sh` exits 64; `PLANK_ROOT=/nonexistent` exits 64) and
correctly reads `IMPORT-PIN.md`, the import paths and the working-tree diff all from `$PLANK_ROOT`
— it is left exactly as written, honest and un-stubbed, per the brief ("if `verify-import.sh` fails
because … an imported path is absent on develop, that is monorepo drift: record it … and leave the
script honest — do not stub the check"). Re-taking `IMPORT-PIN.md` against the current
`origin/develop` tip (`bash rig/generate-pins.sh`'s sibling for the pin file, or whatever regenerates
`IMPORT-PIN.md` on the plank side) is follow-up work outside Task 6's scope — Task 6 wires the
`PLANK_ROOT` resolution the check runs under; it does not own `IMPORT-PIN.md`'s freshness, which is
plank's file (`rig/README.md`'s own rule: "`src/`, `foundry-scripts/`, `test/`, `Makefile`,
`foundry.toml` belong to other tracks: this rig RUNS them, it never edits them" — `IMPORT-PIN.md`
is the same class of artifact, committed on the plank side).

**Downstream of the same re-pin — the bare `cabal test` cascade.** Re-pinning `rig/import-ref.txt`
is exactly what `check-upstream.sh` is FOR, and the brief calls for committing it as the re-pin it
is. But `rig/import-ref.txt` is read by two OTHER committed artifacts' freshness checks
(`sc4_generated_from_is_the_imported_ref` against `rig/rig-pins.json`, and
`the_pinned_read_held_while_the_unpinned_read_moved` against `rig/chain-read-conformance.json`), and
re-pinning the ref without re-taking those two artifacts desyncs them — MEASURED: the bare suite
dropped from 232/232 (verified at clean HEAD, before this re-pin, via `git stash`) to 230/232 with
both named FAILs, each printing its own remediation:

```
FAIL sc4_generated_from_is_the_imported_ref: rig-pins.json (RIG_PINS) records generatedFrom
"2039f2783598866a337115df4a265a75e8842e82" but rig/import-ref.txt names "d2b1c518f56d...".
... Regenerate: bash rig/generate-pins.sh
FAIL the_pinned_read_held_while_the_unpinned_read_moved: the capture was produced from ref
"2039f2783598866a337115df4a265a75e8842e82" and the tree's rig/import-ref.txt says "d2b1c518f56d...".
Re-take it: bash rig/capture-chain-read.sh
```

The first is regenerable here: `generate-pins.sh` needs only `PLANK_ROOT` and `cast sig`/`cast
keccak` (pure hash computation, no live chain), and re-running it against `$PLANK_ROOT` at
`d2b1c518...` produced a `rig/rig-pins.json` DIFFERING FROM THE COMMITTED ONE IN EXACTLY ONE FIELD
— `generatedFrom` — confirmed by `diff <(jq -S 'del(.generatedFrom)' ...)` on both sides before
adopting it. No selector, topic0 or retired value moved between the two refs, so this regeneration
carried zero blast radius beyond the ref itself, and it is committed here.

The second is NOT regenerable within Task 6: `capture-chain-read.sh` needs a STANDING rig
(`cast block-number` must answer, and the capture MUTATES chain state), which means running
`deploy-rig.sh` end-to-end — explicitly out of scope for this task ("deploy-rig.sh end-to-end is
not run here — it is exercised by rig-e2e (Task 8)"). `the_pinned_read_held_while_the_unpinned_read_moved`
is therefore left FAILING, honestly, against the freshly re-pinned ref: **231/232** is the correct,
measured bare-suite result after Task 6's changes, not 232/232. `rig/chain-read-conformance.json`
needs a live re-take (`bash rig/deploy-rig.sh && bash rig/capture-chain-read.sh`) against a rig
built from `$PLANK_ROOT` at `d2b1c518...`, which is exactly what Task 8's `rig-e2e` is positioned to
do — this finding is left for that task rather than worked around here.

**Controller ruling — the re-pin above was measured and then REVERTED.** The reasoning in the two
paragraphs above is correct as a measurement (231/232 IS what a partial re-pin produces, and the
`rig-pins.json` regeneration IS zero-blast-radius by itself), but the brief's instruction to
commit the re-pin as a standalone Task 6 action was a plan defect: `rig/import-ref.txt` records
the ref the COMMITTED artifacts (`rig-pins.json`, `chain-read-conformance.json`, and everything
downstream of them) were captured from, so it may only move when ALL of them are re-captured
together — that is the `rig-e2e` cycle, Task 8's job, not a side effect of wiring `PLANK_ROOT`
resolution. The bare tier-1 suite is CI's merge gate and must be 232/232, unconditionally; the
"231/232, honestly reported" outcome recorded above is not an acceptable end state for a merge
gate no matter how well-evidenced the one remaining failure is.

Reverted with `git checkout a19f3e8 -- rig/import-ref.txt rig/rig-pins.json` — both files are now
byte-identical to their state at `a19f3e8` (Task 6's start-of-work HEAD): `git diff a19f3e8 --
rig/import-ref.txt rig/rig-pins.json` is empty. `rig/chain-read-conformance.json` was never
touched in either direction. Re-verified after the revert:

```
232/232 checks passed
SC-3 and SC-4 OK
Test suite gams-evm-transport-test: PASS
```

and the Step 3 refusal table (`env -u PLANK_ROOT bash rig/<s>.sh` for all 9 scripts, plus
`PLANK_ROOT=/nonexistent bash rig/check-upstream.sh` and `env -u PLANK_ROOT bash rig/deploy-rig.sh
--stop`) is unchanged from Task 6's original measurement — the `PLANK_ROOT` wiring itself is not
implicated by this revert; only the decision to *exercise* `check-upstream.sh`'s re-pinning
behavior as a standalone, committed action was wrong.

`check-upstream.sh` keeps its re-pinning behavior unchanged — that is correct and is what the
script is FOR — but `rig/README.md`'s clean-machine sequence now states explicitly that a
`check-upstream.sh` run which actually moves `import-ref.txt` must be followed, in the same
commit, by `generate-pins.sh` + a full rig stand-up + `capture-chain-read.sh` (and every other
ref-dependent capture) before that move is committed; a bare `check-upstream.sh` probe that finds
no drift, or whose result is discarded (`git checkout -- rig/import-ref.txt`), is fine on its own.
No dry-run flag was added to `check-upstream.sh` — the controller ruling was explicit that
documentation is the fix here, not new script behavior. Remediation for `rig/import-ref.txt`
actually moving to `d2b1c518...` (origin/develop's current tip, confirmed live during this task)
is the full `rig-e2e` cycle in Task 8.
