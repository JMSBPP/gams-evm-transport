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

Every one of these reads a file that lives in the sibling `cfmm-numopt` / GAMS-model tree
(`src/interfaces/...`, `src/models/...`), a Solidity-testing-track fixture under
`test/pos_spec/...`, or the `origin/develop` git ref this clone does not carry:

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
