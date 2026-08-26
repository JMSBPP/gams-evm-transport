# Design: `gams-evm-transport` — migrating the `offchain/` Haskell bridge out of the monorepo

**Date:** 2026-08-26 · **Status:** rev 3 — spec reviewed twice, plan reviewed once (Reality Checker + DevOps Automator each time); all BLOCKERs/MAJORs resolved

## 1. Context

The CFMM replication work is being split out of the monorepo
`JMSBPP/cfmm-replicationPlank` into layered repositories:

| Layer | Repo | Language |
|---|---|---|
| Formalization | `JMSBPP/cfmm-vol-markets-spec` (ex `cfmm-lean4-spec`) | Lean 4 |
| Numerical optimization | `JMSBPP/cfmm-numopt` (ex `cfmm-gams`) | GAMS only |
| **Transport (this repo)** | `JMSBPP/gams-evm-transport` | Haskell |
| Consumers | forge tests / scripts in the monorepo and successors | Solidity |

`gams-evm-transport` is the middle layer between GAMS and the EVM: it invokes the
GAMS/CONOPT prover, decodes its byte-exact JSON artifact, reads pool state from an
EVM node over JSON-RPC, and publishes `volume_path.json` for forge consumers.

### What exists today (verified 2026-08-26)

Branch `feat/rpc-api` of the monorepo, tip `29ce4b7`, contains:

- `offchain/` — ~37.8k lines of Haskell: `lib/` (module groups `Gams.*`, `Store.*`,
  `Chain.*`, `Loop.*`, `Fee.Split`, `VolOrder.*`, `PriceSetter.*`, `CheatSwap.*`,
  `StochasticPriceGen.*`, `StochasticOrderGen.*`, `RealizedVol.Decode`, `Rig.Manifest`,
  `Driver.*`), `app/` (8 executables: `Main`, `LoopMain`, `ChainReadConformance`,
  `CheatSwapProof`, `FeeSplitConformance`, `GamsConformance`, `StoreConformance`,
  `SpikeEndToEnd`), `test/Main.hs`, `migrations/001..005.sql`, `rig/` (shell scripts +
  committed conformance/capture JSON), `LOOP.md`, `spec/types.md`, `todo.md`.
- `cfmm-replicationPlank-rpc-api.cabal` at the monorepo root, `hs-source-dirs` pointing
  into `offchain/`. `license: BSD-3-Clause`. `base ^>=4.20.2.0` → GHC 9.10.3.
  External deps: `web3-{ethereum,solidity,provider,crypto}`, `jsonrpc-tinyclient`,
  `memory-hexstring`, `postgresql-simple`, `postgresql-migration`, `aeson`, `mwc-random`,
  `crypton`, and boot packages.
- `econometrics/` — a separate stack project (EIV/NLS/panel estimation). **Out of scope.**
- `.github/workflows/develop-gate.yml` — the monorepo gate; its haskell job stands up the
  full forge rig (npm ci, plank toolchain, anvil, six forge scripts) before `cabal test`,
  under `flock $HOME/.cfmm-rig-8545.lock` with an EXIT-trap `--stop` and an `always()`
  teardown guarded by a `$RUNNER_TEMP` marker. Its `-Wall` positive-control probe is written
  under the scanned prefix. An `approve` job on `ubuntu-latest` with `environment:` gates it.
- Cabal `extra-doc-files: CHANGELOG.md` names a file that does not exist on the branch.
- Executable stanzas: `cfmm-replicationPlank-rpc-api` (main; `app/Sample.hs` is one of its
  `other-modules`), `chain-read-conformance`, `cheat-swap-proof`, `store-conformance`,
  `gams-conformance`, `fee-split-conformance`, `spike-end-to-end`, `loop`.

`cfmm-numopt/main` (`6d766a7`) `model/mev_tax_model_one/volume_path.gms` is **not**
byte-identical to the monorepo copy (monorepo `7994…`, numopt `d454…`): numopt added a
`abort$(nEv*25 > 4000)` JSON-width guard on 2026-08-26 (`7b65ac3`). The identical
ancestor is `efc2162`. `rig/gams-conformance.json` records `model_sources[].sha256 =
7994…` **and** digests of `lib/Gams/{Argv,Artifact}.hs`, plus a timestamp and absolute
`/home/jmsbpp/cfmms-playground/cfmm-wt/...` paths. `Gams.Version` recomputes the model
digest per run; the pin lives in the artifact.

Both self-hosted runners on this host are **repo-scoped** (`cfmm-build-1` → monorepo,
`cfmm-build-gams` → cfmm-numopt, labels `self-hosted,Linux,X64,cfmm-build`). `JMSBPP` is a
user account: no org-level runners exist.

`~/cfmm/` lies inside the home-directory git repo (`git -C ~ rev-parse --show-toplevel` =
`/home/jmsbpp`). `~/cfmm/gams-evm-transport` currently holds only `docs/` (this spec).

The offchain/ is no longer a dir name since the project is self-cntained stack package
Code literals naming `offchain/` (not comments) exist in **11 files**: `lib/Chain/Endpoint.hs`
(`shell_resolver`, the `endpoint_sites` census the suite asserts), `lib/Rig/Manifest.hs`
(`default_pins_path`, `default_manifest_path`), `lib/Driver/Capture.hs`, `lib/Store/Config.hs`
(`default_store_conformance_path`), `lib/Chain/Read.hs`, `lib/Gams/Config.hs`,
`app/{ChainReadConformance,CheatSwapProof,GamsConformance,FeeSplitConformance,StoreConformance}.hs`.
`test/Main.hs` additionally: `sc3_literal_purge` walks the literal root `"offchain"`;
tests read `src/interfaces/**/*.plk`, `src/models/mev_tax_model_one/libraries/ShockLib.plk`,
`test/pos_spec/fixtures/vol_order_return_golden.json`, `origin/develop:test/models/…/*.t.sol`
(via `git show`), shell out to `cast`, and `sc3_load_succeeds` deliberately fails (not skips)
without the rig. `rig/check-upstream.sh` and `verify-import.sh` diff against the monorepo's
`origin/develop` and `.planning/phases/20-*/IMPORT-PIN.md` — they need the monorepo's git
remote, not merely a worktree.

The string `cabal run cfmm-replicationPlank-rpc-api` occurs only in `rig/README.md` (also as
`cabal build lib:cfmm-replicationPlank-rpc-api` and `--ghc-arg=cfmm-replicationPlank-rpc-api`);
`LOOP.md` and `rig/*.sh` use `cabal run -v0 <exe>`.

Repo-relative defaults that break on re-root:

| Symbol | Today | Why it breaks |
|---|---|---|
| `Gams.Config.default_gams_model` | `model/mev_tax_model_one/volume_path.gms` | model now lives in `cfmm-numopt` |
| `Gams.Config.default_gams_conformance_path` | `offchain/rig/gams-conformance.json` | `offchain/` prefix disappears |
| `Gams.Config.default_fee_split_conformance_path` | `offchain/rig/fee-split-conformance.json` | same |
| `Loop.Config.default_fixture_dir` | `test/models/mev_tax_model_one/fixtures` | monorepo forge tree (consumer contract; asserted by the suite) |
| `rig/deploy-rig.sh`, `check-upstream.sh` | `forge script foundry-scripts/...` | not in this repo |

Local toolchain on the research machine: GHC 9.10.3 + cabal 3.16.1 via ghcup; GAMS 54.1
+ CONOPT at `/usr/gams/gams54.1_linux_x64_64_sfx` (Demo licence); self-hosted runner
`cfmm-build` on the same host.

### Decisions taken with the user

1. **Scope = all of `offchain/`** plus the cabal file and licence. `econometrics/` stays out.
2. **History preserved** via `git filter-repo`, re-rooted so `offchain/` becomes the root.
3. **Name = `gams-evm-transport`** for repo, cabal package, and main executable.
4. **GAMS model via `cfmm-numopt` submodule** pinned at `main`; the conformance artifacts
   are **re-captured** against it (see 4.3). Forge side is env-only: `PLANK_ROOT` points at
   a monorepo checkout; `FIXTURE_DIR` overrides the publish dir.
5. **Licence = MIT**, file and holder (`Copyright (c) 2026 wvs-finance`) kept verbatim; the
   cabal field is corrected from the `cabal init` default `BSD-3-Clause` to `MIT`.
6. **Repo is public**, with the same hosted-runner `approve` environment gate the sibling
   repos use, because a self-hosted runner + public PRs would otherwise execute fork code
   on the research machine.

## 2. Target layout

```
gams-evm-transport/
├── gams-evm-transport.cabal        # renamed; hs-source-dirs: lib/ app/ test/
├── LICENSE                         # MIT © 2026 wvs-finance, verbatim
├── README.md                       # NEW
├── LOOP.md  todo.md  spec/types.md # moved; path references updated
├── lib/  app/  test/               # ex offchain/{lib,app,test}
├── migrations/001..005.sql
├── rig/                            # ex offchain/rig; scripts resolve PLANK_ROOT
├── cfmm-numopt/                    # submodule → JMSBPP/cfmm-numopt @ pinned SHA
├── docs/superpowers/{specs,plans}/2026-08-26-gams-evm-transport-migration-*.md
├── .gitmodules  .gitignore
└── .github/workflows/haskell.yml
```

`.gitignore`: `dist-newstyle/`, `rig/rig-manifest.json`, `*.lst`, `225*`, run-directory
`volume_path.json`. **Not** ignored: `rig/driver-run-capture.json`, `rig/loop-conformance.json`
and the other `rig/*.json` (tracked, asserted by the suite). The monorepo's `docs/*` ignore
line is **not** inherited (it would hide `docs/superpowers/`).

Nothing else from the monorepo comes: no `econometrics/`, `foundry-scripts/`, `.planning/`,
`.agents/`, `lib/`, `model/`, `test/`, `src/`.

## 3. Migration mechanics

1. `git clone --no-tags --single-branch --branch feat/rpc-api <monorepo-url> <scratch>` (tip
   `29ce4b7`); `--no-tags` because tag `v3.0` would otherwise carry 131 monorepo commits.
2. `git filter-repo --path offchain/ --path cfmm-replicationPlank-rpc-api.cabal --path LICENSE --path-rename offchain/:`
   in **full** mode (no `--refs`: partial mode keeps `origin` and untouched refs, and
   `gh repo create --remote=origin` then refuses). `git-filter-repo` is at `~/.local/bin`.
3. `git branch -m feat/rpc-api main`; `git remote remove origin` if still present; confirm no
   other refs remain. `.gitignore` is created in the first local commit (the monorepo's root
   `.gitignore` is outside the path set) before any `cabal build`.
   The monorepo was renamed `JMSBPP/cfmm-vol-markets` on 2026-08-26 (old URL redirects); that
   is the clone URL. `feat/rpc-api` is held there (tag `archive/feat-rpc-api`) until this
   migration confirms capture to the monorepo session.
4. Verify (all must hold before push):
   - `git rev-list --count main` = 227 (full-history count after filtering; the path-simplified
     count 219 drops merges filter-repo keeps) — record the exact number;
   - `git log --oneline -- lib/Gams/` shows 13 commits; `lib/Gams/Run.hs` its single `feat(24-03)` commit;
   - `git archive feat/rpc-api offchain | tar -x -C <tmp>` then `diff -r <tmp>/offchain <scratch>` is empty
     except the cabal file and LICENSE now at root, `.git`, and nothing else.
5. `gh repo create JMSBPP/gams-evm-transport --public --source=<scratch> --push` (gh auth
   has `repo,workflow`).
6. Local checkout: move the existing `~/cfmm/gams-evm-transport/docs/` aside, `git clone`
   into `~/cfmm/gams-evm-transport`, restore `docs/` (it lands in commit 4.5). Add
   `cfmm/` to the **home repo's** `.git/info/exclude` so the nested clone is never staged there.

## 4. Post-migration commits (one commit each, on top of preserved history)

### 4.1 `chore: rename package to gams-evm-transport`
- cabal `name:`, main `executable cfmm-replicationPlank-rpc-api` → `executable gams-evm-transport`,
  `test-suite cfmm-replicationPlank-rpc-api-test` → `gams-evm-transport-test`; file renamed
  `gams-evm-transport.cabal`.
- `rig/README.md`: every `cfmm-replicationPlank-rpc-api` token (`cabal run …`,
  `cabal build lib:…`, `--ghc-arg=…`). `LOOP.md` and `rig/*.sh` contain none (verified); the
  plan greps the whole tree anyway and fails if a stale token survives.
- `license: MIT` (was `BSD-3-Clause` boilerplate); `LICENSE` file untouched. Drop
  `extra-doc-files: CHANGELOG.md`.

### 4.2 `chore: re-root paths after the offchain/ split`
- `hs-source-dirs: offchain/lib` → `lib`, `offchain/app` → `app`, `offchain/test` → `test`.
- All 11 files listed in §1 with `offchain/` code literals: `offchain/rig/…` → `rig/…`,
  `offchain/lib/…` → `lib/…`. The `Chain.Endpoint.endpoint_sites` census keeps its
  semantics (same three shell sites, new paths).
- `Loop.Config`: `default_fixture_dir` **stays** — it is the consumer's own constant and is
  asserted (`fixture_dir_from Nothing == default_fixture_dir`, `default_fixture_path`).
  Resolution order becomes: `FIXTURE_DIR` if set → else `$PLANK_ROOT/<default_fixture_dir>`
  if `PLANK_ROOT` set → else `default_fixture_dir` relative to cwd, at which point the
  existing `Loop.Publish` precondition (exit **40**, missing directory) fires as documented.
  No exit-code meaning changes. `LOOP.md` §2 table gains `PLANK_ROOT`.
- `Loop.Config` resolves `PLANK_ROOT` **once** (`plank_root_env_var`, `plank_root_from`,
  `plank_root`, `fixture_dir_with_root`), the `Store.Config` shape (name constant, pure rule,
  resolver), registered in the suite's override census as a named unprobed override; every monorepo-tree read in `test/Main.hs`, the
  `.t.sol`/`origin/develop` read, and the `cast` shell-out become a **fourth test class,
  monorepo-contract**, gated on it: when unset, the suite prints each skipped test by
  name and passes the gate; when set, they run against `$PLANK_ROOT` unchanged.
  `sc3_load_succeeds` (deliberately fails without the rig) stays in tier 2 (§5).
- `sc3_literal_purge`: walk root list becomes explicit — `lib app test rig migrations` —
  and never `cfmm-numopt/`, `.github/`, `docs/`.
- Assertions are **re-pointed or gated, never deleted**. The only rewrites are the path
  literals above and the gate wrapper.
- Module haddocks citing `offchain/...` are updated in the same commit. This changes the
  digests of `lib/Gams/{Argv,Artifact}.hs` that `rig/gams-conformance.json` records —
  which is why 4.3 re-captures.

### 4.3 `feat: cfmm-numopt submodule supplies the prover model`
- `git submodule add https://github.com/JMSBPP/cfmm-numopt cfmm-numopt`, pinned at
  **`main` (`6d766a7` or later)**. The model differs from the monorepo copy only by the
  JSON-width guard (§1); `rig/volume-path-golden.json` must be reproduced **byte-for-byte**
  by the new model on the self-test fixture — that is the check that the guard changed
  nothing observable. If it does not reproduce, stop and report; do not pin `efc2162` silently.
- `Gams.Config.default_gams_model = "cfmm-numopt/model/mev_tax_model_one/volume_path.gms"`.
- No cwd work needed (verified): `Gams.Run` spawns in an exclusive temp run dir with
  `curdir=<run_dir>`, `Gams.Invoke` `makeAbsolute`s the model, and the prover has no
  `$include` (numopt README).
- **Re-capture** `rig/gams-conformance.json` and `rig/fee-split-conformance.json` on this
  host with `rig/capture-gams-conformance.sh` / `capture-fee-split.sh` (they embed the new
  model sha, the post-4.2 module digests, this host's `gams_path`, a fresh timestamp).
  Committed in this same commit with the capture command in the message.

### 4.4 `chore: rig scripts decouple from the monorepo via PLANK_ROOT`
- `rig/deploy-rig.sh`, `verify-rig.sh`, `capture-*.sh`: resolve `PLANK_ROOT`; refuse with a
  named message when unset or when `$PLANK_ROOT/foundry.toml` is absent; `cd "$PLANK_ROOT"`
  for every forge/npm/cast step; write `rig/rig-manifest.json` back into **this** repo.
  `endpoint.sh` unchanged (its Haskell twin `Chain.Endpoint` keeps the same default).
- `check-upstream.sh`, `verify-import.sh`, `generate-pins.sh`: they read the monorepo's
  `origin/develop` and `.planning/…/IMPORT-PIN.md`; they run `git -C "$PLANK_ROOT"` and
  require that checkout to have an `origin` remote — documented, and tier 2 only.
- Side effects are named in `rig/README.md`: CI's `rig-e2e` writes `broadcast/` and runs
  `npm ci` **inside `$PLANK_ROOT`**, so `PLANK_ROOT` on the runner is a dedicated checkout,
  never a developer's.
- `rig/README.md` clean-machine sequence rewritten for the two-checkout setup.

### 4.5 `docs: README`
- The three-repo map, what the bridge does (one paragraph from `LOOP.md`), env table
  (`ETH_RPC_URL`, `PGSTORE_DSN`, `PLANK_ROOT`, `FIXTURE_DIR`, `LOOP_POLL_MS`, `GAMS_BIN`,
  `GAMS_MODEL`), build/test commands, what the `rig/*.json` conformance
  artifacts are, toolchain pins (GHC 9.10.3, GAMS 54.1/CONOPT 4.39, Demo licence).

### 4.6 `ci: haskell.yml`
See §5.

## 5. Verification gates

### Local, before the first push
1. filter-repo checks of §3.4.
2. `cabal build --enable-tests -j all` on GHC 9.10.3, zero `-Wall` warnings — the monorepo
   gate's warning grep, regex scoped `^(lib|app|test)/`; the positive-control probe file is
   written under `lib/` so the control itself is inside the scanned prefix.
3. `cabal test` **without** rig, chain, Postgres, or `PLANK_ROOT`. Failures are partitioned
   into four classes: path-literal breakage (fixed in 4.2), **monorepo-contract** (gated on
   `PLANK_ROOT`, 4.2), needs rig/foundry (`cast`, `manifest_file`, `sc3_load_succeeds`),
   needs Postgres. The last two are **tier 2**, gated by `RIG_TESTS=1`. Every gate that is
   off prints the names it skipped — never a silent pass. The measured partition is recorded
   in the plan, with counts.
4. `cabal run gams-evm-transport -- --help` and `cabal run loop -- --help` exit 0.
5. Two halves, neither byte-for-byte: (a) the suite's own `gams_conformance_is_present_and_fresh`
   recomputes the module digests recorded in `rig/gams-conformance.json`; (b) CI runs the
   pinned submodule model bare and compares the emitted `volume_path.json` sha256 to
   `.golden.sha256` and the submodule model's sha256 to `.model_sources[0].sha256`, then
   asserts `git status` is clean. Timestamps and absolute paths are never compared.
6. `test/Main.hs` runs `git status --porcelain` at cwd: `cabal test` is run from the repo root.

### CI — `.github/workflows/haskell.yml`
- **Runner registration (prerequisite, user-run):** a third repo-scoped runner on this host,
  `config.sh --url https://github.com/JMSBPP/gams-evm-transport --labels cfmm-build`, its
  own systemd unit (same shape as `actions.runner.JMSBPP-cfmm-gams.cfmm-build-gams.service`),
  `PLANK_ROOT` set in the runner's `.env` to a dedicated monorepo checkout. Without it the
  job queues forever. Claude prepares the commands; the user runs them (sudo).
- **`approve`** job on `ubuntu-latest` with `environment: transport-gate` — identical shape
  to `develop-gate`/`gams-gate`; every self-hosted job `needs: [approve]`. Required because
  the repo is public and `cabal build` executes package code. The environment with its
  required reviewer is created **before** the workflow is first pushed (GitHub auto-creates a
  referenced environment with no rules otherwise).
- **`build-test`** (`pull_request` to `main` + `workflow_dispatch`; PR-only so a merged change is approved once, as `develop-gate` does): `[self-hosted, cfmm-build]`; checkout `submodules: true`
  (only `cfmm-numopt`; its `lean4-spec` is not recursed), `persist-credentials: false`;
  ghcup pin GHC 9.10.3 (`$HOME/.ghcup/bin` → `GITHUB_PATH`); `cabal update`;
  `cabal build --enable-tests -j all` + warning grep + compiled-modules count; tier-1
  `cabal test`; gate 5. Timeout 45 min (`~/.cabal/store` is 2.4 GB and persists outside the
  workspace; only the first run is cold).
- **`rig-e2e`** (`workflow_dispatch` only): `flock $HOME/.cfmm-rig-8545.lock` held across
  deploy+verify+test in one `run:` step, EXIT-trap `deploy-rig.sh --stop`, `always()`
  teardown guarded by a `$RUNNER_TEMP` marker — the monorepo gate's shape, because three
  runners now share port 8545 as user `jmsbpp`. It first prepares `$PLANK_ROOT` the way
  `develop-gate` does (fetch + detach at `origin/develop`, guarded submodule init,
  `make plank-toolchain`, `npm ci`). Postgres: `docker run --name
  gams-evm-transport-pg -p 127.0.0.1:55433:5432 postgres:18-alpine` (the capture script's
  port; the host's `mamertomics-monorepo-postgres-1` is on 5432). Then `RIG_TESTS=1
  cabal test`. **Not a merge gate** until it has been green once.

## 6. Out of scope / follow-ups (filed as issues in the new repo)
- Making `loop` run live end-to-end (`LOOP.md` §7: never executed).
- Retiring the pre-Loop drivers (`VolOrder.*`, `PriceSetter.*`, `Stochastic*`, `CheatSwap.*`)
  if the forge consumers no longer need them.
- Whether `Store.Postgres` stays or the JSON store suffices.
- Closing `feat/rpc-api` in the monorepo as superseded once this repo is green.

## 7. Risks
- **Partition is unknown until measured** (gate 3). If most of the suite is monorepo-contract
  or tier 2, `build-test` is thin; that is reported with counts, not hidden.
- **Golden may not reproduce under the new model** (4.3). Then the migration stops at 4.3 and
  reports; pinning `efc2162` is a user decision, not a fallback.
- **Submodule pin drift** later: gate 5's model-sha comparison catches it.
- **`cabal` solver**: `web3-*` packages pin `crypton <1.1`; the plan is known to resolve on
  9.10.3. A `cabal.project.freeze` is committed from the first successful local build.
- **Three runners on one host**: only `rig-e2e` touches 8545, and only under the shared lock.
