# gams-evm-transport

`gams-evm-transport` is the middle layer between GAMS and the EVM: it invokes the GAMS/CONOPT
prover, decodes its byte-exact JSON artifact, reads pool state from an EVM node over JSON-RPC, and
publishes `volume_path.json` for forge consumers. The CFMM replication work that produced it is
split across layered repositories:

| Layer | Repo | Language |
|---|---|---|
| Formalization | `JMSBPP/cfmm-vol-markets-spec` (ex `cfmm-lean4-spec`) | Lean 4 |
| Numerical optimization | `JMSBPP/cfmm-numopt` (ex `cfmm-gams`) | GAMS only |
| **Transport (this repo)** | `JMSBPP/gams-evm-transport` | Haskell |
| Consumers | forge tests / scripts in the monorepo and successors | Solidity |

## What is here

### `lib/` — module groups

| Group | What it does |
|---|---|
| `Gams.*` | Resolves the prover's environment and config, invokes the real GAMS/CONOPT binary as the one IO edge, classifies its exit code, and decodes the byte-exact JSON artifact into exact-precision integer arrays. |
| `Store.*` | The content-addressed cache in front of the solver: a pure content-key framer, a Postgres-backed store plus an in-memory reference implementation, and the store contract expressed as executable laws run against both. |
| `Chain.*` | The one place the RPC endpoint is decided; reads pool state pinned to a single block and decodes the mev-tax model's on-chain `Shock` event. |
| `Loop.*` | The resident daemon's composition: polls chain events from a persisted watermark, drives the solve/publish pipeline, records every event to the Postgres ledger, and states the daemon's complete environment and exit-code table. |
| `Fee.Split` | The fee splitter's exact-arithmetic core, checked admissible against the prover's own admissibility ellipse test. |
| `VolOrder.*` | Encodes, submits, and decodes the vol-order creation calls and their transaction receipts. |
| `PriceSetter.*` | Drives the price-setter hook's own, liquidity-free pool by writing slot0 directly via calldata built through `cast`. |
| `CheatSwap.*` | The cheat-swap price driver: overwrite the target pool's slot0, advance the block clock, swap, and read the hook's realized-vol writes back out of the receipt. |
| `StochasticPriceGen.*` | Simulates a GBM/CEV tick path and drives it on-chain through `PriceSetter` or `CheatSwap`. |
| `StochasticOrderGen.*` | Simulates a Poisson arrival process of vol orders and submits them in batches. |
| `RealizedVol.Decode` | Decodes `RealizedVol` log events only — by design there is no client that writes timepoints off-chain; the hook writes them when a price is moved. |
| `Rig.Manifest` | The loud-failing loader for the rig's split manifest: committed pins plus a gitignored, per-deploy manifest. |
| `Driver.*` | The demo driver's support: a reproducible, recordable random seed, and a step-by-step run record that stays readable even when a run dies halfway. |

### `app/` — executables, by cabal stanza name

| Stanza | What it does |
|---|---|
| `gams-evm-transport` | The demo driver. Exercises both price mechanisms and the order generator against a live rig and leaves a committed, replayable run record behind. |
| `loop` | The resident loop's executable — thin by construction, composed entirely from `lib/Loop/*`, exiting through the documented exit-code table (see `LOOP.md`). |
| `chain-read-conformance` | Captures the observational half of the block-pinning guarantee against a live chain, out of band from the test suite. |
| `cheat-swap-proof` | Capture tool proving the cheat-swap pattern targets the correct pool, by measurement against the real rig. |
| `store-conformance` | The one place that needs a real Postgres; records every database-facing behavior of `Store.Postgres`. |
| `gams-conformance` | The one place that needs a real solver; records golden bytes, the exit-code taxonomy, and environment sensitivity against the real GAMS/CONOPT toolchain. |
| `fee-split-conformance` | Records the differential between `Fee.Split`'s admissibility check and the prover's own admissibility ellipse, measured at its boundaries. |
| `spike-end-to-end` | Throwaway integration spike wiring the fee splitter, the real prover, and the content-addressed store together end to end. |

The test suite is the `gams-evm-transport-test` stanza — see **Build and test** below.

### `rig/`

Shell scripts that stand up and tear down the local rig (`deploy-rig.sh`, `verify-rig.sh`,
`check-upstream.sh`, `verify-import.sh`, the `capture-*.sh` tools, `generate-pins.sh`) plus the
committed conformance/capture JSON those tools and the executables above produce. See
`rig/README.md` for the clean-machine setup sequence — it is not duplicated here.

### `migrations/`

Five SQL migrations (`001`–`005`). The `loop` executable applies migrations `001`–`004` itself at
startup; `005` layers the loop ledger's fee-source column on top.

### `cfmm-numopt/`

A git submodule (`JMSBPP/cfmm-numopt`) supplying the GAMS model and CONOPT-facing artifacts that
`Gams.*` invokes and decodes. Not populated by a plain clone — see **Toolchain** below.

## Environment

One resolver per variable, each defined in the module named in `LOOP.md` §2. A malformed value is
refused with a named exit, never silently defaulted.

| Variable | Default | Notes |
|---|---|---|
| `ETH_RPC_URL` | `http://127.0.0.1:8545` | The one endpoint authority; the shell scripts under `rig/` state the same default, and the test suite asserts the two are byte-equal. See `LOOP.md` §2 for the resolver. |
| `PGSTORE_DSN` | *(empty — the loop will not start)* | **Required.** Store + ledger connection. The loop runs migrations `001`–`004` itself at startup. |
| `PLANK_ROOT` | *(unset)* | Optional. A checkout of `JMSBPP/cfmm-replicationPlank` with an `origin` remote. When set, the default publication directory resolves under it, and the monorepo-contract checks in `cabal test` run instead of being skipped by name. |
| `FIXTURE_DIR` | derived under `PLANK_ROOT` when set, else the same path relative to the working directory | Publication directory. The loop never creates it. |
| `LOOP_POLL_MS` | `1000` | Positive integer only. |
| `GAMS_BIN` | `gams` (on `PATH`) | Prover binary. |
| `GAMS_MODEL` | see `Gams.Config` | The `.gms` model path. |
| `RIG_TESTS` | *(unset)* | Set to `1` to enable the rig/Postgres tier-2 checks in `cabal test`. Requires a deployed rig — see `rig/README.md`. |

## Build and test

```bash
cabal build --enable-tests -j all

# Bare: 232/232. Checks that need PLANK_ROOT or RIG_TESTS print a SKIPPED line naming themselves
# and the unset variable, rather than silently passing.
cabal test

# Runs the monorepo-contract checks against a real checkout instead of skipping them.
PLANK_ROOT=<path to a cfmm-replicationPlank checkout at origin/develop> cabal test

# Runs the rig/Postgres tier-2 checks. Stand the rig up first with rig/deploy-rig.sh.
RIG_TESTS=1 cabal test
```

## Toolchain

- GHC 9.10.3, cabal 3.16
- GAMS 54.1 / CONOPT 4.39 (Demo licence)
- `git submodule update --init cfmm-numopt` — the GAMS model lives in the submodule, not in this
  repo

See `LOOP.md` for the resident daemon's full operator's manual (invocation, startup preconditions,
per-block output, exit codes) and `rig/README.md` for the clean-machine rig setup sequence.

## Provenance

History split from `cfmm-replicationPlank` (now `cfmm-vol-markets`) `feat/rpc-api` @ `29ce4b7`
with `git filter-repo`; 227 commits.
