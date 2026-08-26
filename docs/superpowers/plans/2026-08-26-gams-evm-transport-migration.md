# gams-evm-transport Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the `offchain/` Haskell bridge off monorepo branch `feat/rpc-api` into the new public repo `JMSBPP/gams-evm-transport`, history preserved, building and testing on its own with `cfmm-numopt` as the prover source.

**Architecture:** `git filter-repo` re-roots `offchain/` to the repo root with the cabal file beside it. Six follow-up commits rename the package, re-point every `offchain/` literal, add a `PLANK_ROOT` resolver so monorepo-contract tests and rig scripts run against an external monorepo checkout instead of silently failing, pin `cfmm-numopt` as a submodule and re-capture the conformance artifacts, then add CI mirroring the sibling repos' `approve` gate.

**Tech Stack:** Haskell (GHC 9.10.3, cabal 3.16.1 via ghcup), `git-filter-repo`, `gh` CLI, GAMS 54.1 + CONOPT (`/usr/gams/gams54.1_linux_x64_64_sfx`, Demo licence), GitHub Actions self-hosted runner, bash.

**Spec:** `docs/superpowers/specs/2026-08-26-gams-evm-transport-migration-design.md`

**Executing specialist per task** (AI-agency catalog): named in each task header. Reviewers after every task: Reality Checker + the task's specialist.

## Global Constraints

- Source of truth: monorepo clone `/home/jmsbpp/cfmms-playground/cfmm-replicationPlank`, branch `feat/rpc-api` @ `29ce4b7`. **Never** checkout, commit, or modify that working tree; read with `git show feat/rpc-api:<path>`.
- Monorepo remote: `PLANK_URL=https://github.com/JMSBPP/cfmm-vol-markets.git` (renamed from `cfmm-replicationPlank` on 2026-08-26; the old URL redirects). `feat/rpc-api` is held there, with an `archive/feat-rpc-api` tag, until this plan messages the peer session "rpc-api captured" (Task 0 Step 8). New repo: `JMSBPP/gams-evm-transport`, **public**.
- Monorepo checkouts used by this plan: for `PLANK_ROOT` always a **dedicated clone at `origin/develop`** (`$S/plank`, created in Task 0 Step 7) — never `~/cfmms-playground/cfmm-replicationPlank` (on `feat/gams-solidity-difftest`, dirty, no `node_modules`).
- Model SHAs (verified): monorepo `feat/rpc-api` `volume_path.gms` = `79940449…` (no width guard); `cfmm-numopt` `6d766a7` = `d454654c…` (has `abort$(nEv*25 > 4000)`). `rig/gams-conformance.json` records `79940449…` until Task 5 re-captures.
- Package/executable/test-suite name: `gams-evm-transport`. Licence field `MIT`; `LICENSE` file (MIT © 2026 wvs-finance) untouched.
- GHC `9.10.3` exactly (`base ^>=4.20.2.0`). Build always as `cabal build --enable-tests -j all`. Zero `-Wall` warnings under `lib/ app/ test/`.
- `cabal test` is run from the repo root (a check runs `git status --porcelain` at cwd).
- Assertions in `test/Main.hs` are **re-pointed or gated, never deleted**.
- Submodule `cfmm-numopt` pinned at `main` (`6d766a7`); `rig/volume-path-golden.json` must reproduce byte-for-byte under it, else STOP and report.
- Local checkout: `/home/jmsbpp/cfmm/gams-evm-transport` (inside the home git repo; excluded there, never staged there).
- Scratchpad for throwaway clones: `/tmp/claude-1000/-home-jmsbpp-cfmm-gams-evm-transport/f7e9c387-2b04-40e0-8831-28dc2640b594/scratchpad`.
- Commits end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- Anything needing sudo or a systemd unit is **prepared as a command block for the user**, not run.

---

## File map

| Path (new repo) | Responsibility | Task |
|---|---|---|
| `gams-evm-transport.cabal` | package; renamed from `cfmm-replicationPlank-rpc-api.cabal` | 1 |
| `lib/Loop/Config.hs` | gains `PLANK_ROOT` resolver + `fixture_dir_with_root` | 3 |
| `lib/{Gams,Store}/Config.hs`, `lib/Rig/Manifest.hs`, `lib/Driver/Capture.hs`, `lib/Chain/{Endpoint,Read}.hs`, `app/*Conformance.hs`, `app/CheatSwapProof.hs` | `offchain/` literals → new paths | 2 |
| `test/Main.hs` | literals, purge roots, gating helpers | 2, 4 |
| `cabal.project.freeze` | pinned build plan | 2 |
| `.gitmodules`, `cfmm-numopt/` | prover source | 5 |
| `rig/gams-conformance.json`, `rig/fee-split-conformance.json` | re-captured | 5 |
| `rig/*.sh`, `rig/README.md` | `PLANK_ROOT` | 6 |
| `README.md`, `LOOP.md`, `.gitignore` | docs | 7 |
| `.github/workflows/haskell.yml` | CI | 8 |

---

### Task 0: Repo surgery — filter-repo, create remote, local checkout
**Specialist:** Git Workflow Master

**Files:** none in-repo; produces the repo itself.

**Interfaces:** Produces `main` with ≈219 commits, tree = ex-`offchain/` at root + `cfmm-replicationPlank-rpc-api.cabal` + `LICENSE`; local clone at `/home/jmsbpp/cfmm/gams-evm-transport` with `docs/` restored (untracked).

- [ ] **Step 1: Exclude the nested checkout from the home repo**

```bash
grep -qx 'cfmm/' /home/jmsbpp/.git/info/exclude || echo 'cfmm/' >> /home/jmsbpp/.git/info/exclude
git -C /home/jmsbpp status --porcelain -- cfmm/ | head -1   # expected: empty
```

- [ ] **Step 2: Single-branch scratch clone**

```bash
S=/tmp/claude-1000/-home-jmsbpp-cfmm-gams-evm-transport/f7e9c387-2b04-40e0-8831-28dc2640b594/scratchpad
PLANK_URL=https://github.com/JMSBPP/cfmm-vol-markets.git
git clone --no-tags --single-branch --branch feat/rpc-api "$PLANK_URL" "$S/src"
git -C "$S/src" rev-parse --short HEAD      # expected: 29ce4b7
git -C "$S/src" tag | wc -l                 # expected: 0 (--no-tags; otherwise v3.0 drags 131 monorepo commits along)
```

- [ ] **Step 3: Filter and re-root**

```bash
cd "$S/src"
git filter-repo \
  --path offchain/ --path cfmm-replicationPlank-rpc-api.cabal --path LICENSE \
  --path-rename offchain/:
# no --refs: full mode rewrites every ref and removes `origin` itself (partial mode keeps both)
git branch -m feat/rpc-api main
git remote remove origin 2>/dev/null || true
git for-each-ref --format='%(refname)'      # expected: only refs/heads/main
git remote -v                               # expected: empty
```

- [ ] **Step 4: Verify the filter**

```bash
git rev-list --count main                    # expected: 227 (full-history count; 219 was the path-simplified count — record actual)
git log --oneline -- lib/Gams/ | wc -l       # expected: 13
git log --oneline -- lib/Gams/Run.hs         # expected: 1 line, "feat(24-03) ..."
ls                                           # expected: LICENSE LOOP.md app cfmm-replicationPlank-rpc-api.cabal lib migrations rig spec test todo.md
mkdir -p "$S/ref" && git -C /home/jmsbpp/cfmms-playground/cfmm-replicationPlank archive feat/rpc-api offchain | tar -x -C "$S/ref"
diff -rq "$S/ref/offchain" . --exclude=.git --exclude=LICENSE --exclude=cfmm-replicationPlank-rpc-api.cabal
# expected: no output
```
If any expectation fails: stop, report, do not push.

- [ ] **Step 5: Create the public remote and push**

```bash
gh repo create JMSBPP/gams-evm-transport --public \
  --description "GAMS <-> EVM transport: invokes the CFMM prover, decodes its byte-exact JSON, publishes fixtures for forge" \
  --source="$S/src" --remote=origin --push
gh repo view JMSBPP/gams-evm-transport --json visibility,defaultBranchRef -q '.visibility+" "+.defaultBranchRef.name'
# expected: PUBLIC main
```

- [ ] **Step 6: Local checkout with docs restored, and `.gitignore` before any build**

```bash
cd /home/jmsbpp/cfmm && mv gams-evm-transport/docs "$S/docs-keep" && rmdir gams-evm-transport
git clone https://github.com/JMSBPP/gams-evm-transport.git
mv "$S/docs-keep" gams-evm-transport/docs
cd gams-evm-transport
cat > .gitignore <<'GI'
dist-newstyle/
.stack-work/
rig/rig-manifest.json
*.lst
225*/
**/volume_path.json
**/volume_path.txt
GI
git check-ignore -q rig/volume-path-golden.json && echo "BUG: golden ignored" || echo ok   # ok (different basename)
git add .gitignore && git commit -m "chore: .gitignore (build output, rig manifest, GAMS run artifacts)

The monorepo's root .gitignore was outside the filter-repo path set.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git status --porcelain     # expected: ?? docs/
```

- [ ] **Step 7: Dedicated monorepo clone for `PLANK_ROOT`**

```bash
git clone --branch develop "$PLANK_URL" "$S/plank"
git -C "$S/plank" rev-parse --short origin/develop     # record (d2b1c51 at plan time)
ls "$S/plank/src/interfaces/pos_spec/VolOrderManagerInterface.plk" "$S/plank/test/models/mev_tax_model_one"
```
`node_modules`/submodules are NOT needed for Tasks 4 and 6; only `rig-e2e` (Task 8) installs them.

- [ ] **Step 8: Tell the monorepo session the branch is captured**

Only after Step 4's checks all held AND Step 5's push is visible (`gh api repos/JMSBPP/gams-evm-transport/commits/main -q .sha` equals `git -C "$S/src" rev-parse main`): send "rpc-api captured — JMSBPP/gams-evm-transport main = <sha>, 227 commits, diff vs feat/rpc-api:offchain/ empty" to the peer session (address `uds:/run/user/1000/cc-socks/46825.sock`, name `plank-b9`). Until that message is sent, `feat/rpc-api` must not be deleted.

---

### Task 1: Rename the package
**Specialist:** Backend Architect

**Files:**
- Rename: `cfmm-replicationPlank-rpc-api.cabal` → `gams-evm-transport.cabal`
- Modify: `gams-evm-transport.cabal` (`name:`, `license:`, `extra-doc-files`, `executable`, `test-suite`, `hs-source-dirs`)
- Modify: `rig/README.md:28,191,193,232,257,259`

**Interfaces:** Produces cabal targets `gams-evm-transport` (exe), `loop`, `gams-conformance`, `fee-split-conformance`, `store-conformance`, `chain-read-conformance`, `cheat-swap-proof`, `spike-end-to-end`, `gams-evm-transport-test`.

- [ ] **Step 1: Record the pre-state**

```bash
cd /home/jmsbpp/cfmm/gams-evm-transport
grep -rn "cfmm-replicationPlank-rpc-api" --include='*.cabal' --include='*.md' --include='*.sh' --include='*.hs' . | wc -l   # record N
```

- [ ] **Step 2: Rename and edit the cabal file**

```bash
git mv cfmm-replicationPlank-rpc-api.cabal gams-evm-transport.cabal
sed -i \
  -e 's/^name:               cfmm-replicationPlank-rpc-api$/name:               gams-evm-transport/' \
  -e 's/^license:            BSD-3-Clause$/license:            MIT/' \
  -e '/^extra-doc-files:    CHANGELOG.md$/d' \
  -e 's/^executable cfmm-replicationPlank-rpc-api$/executable gams-evm-transport/' \
  -e 's/^test-suite cfmm-replicationPlank-rpc-api-test$/test-suite gams-evm-transport-test/' \
  -e 's|hs-source-dirs:   offchain/lib/|hs-source-dirs:   lib/|' \
  -e 's|hs-source-dirs:   offchain/app$|hs-source-dirs:   app|' \
  -e 's|hs-source-dirs:   offchain/test$|hs-source-dirs:   test|' \
  gams-evm-transport.cabal
grep -nE "^(name|license|executable|test-suite|    hs-source-dirs)" gams-evm-transport.cabal
```
Expected: `name: gams-evm-transport`, `license: MIT`, exe stanza `gams-evm-transport`, test-suite `gams-evm-transport-test`, every `hs-source-dirs` without `offchain/`. If any `hs-source-dirs` line has different spacing, fix it by hand — `grep -n offchain gams-evm-transport.cabal` must print only comment lines.

- [ ] **Step 3: Rewrite the README tokens**

```bash
sed -i 's/cfmm-replicationPlank-rpc-api/gams-evm-transport/g' rig/README.md
grep -rn "cfmm-replicationPlank-rpc-api" . --exclude-dir=.git --exclude-dir=dist-newstyle | grep -v '^\./gams-evm-transport.cabal:.*--'
```
Expected: no output (the cabal file's own `--` comment lines referencing the old name are the only permitted survivors; list them in the commit message if any).

- [ ] **Step 4: Build**

```bash
cabal update && cabal build --enable-tests -j all 2>&1 | tail -3
cabal run -v0 gams-evm-transport -- --help; echo "exit=$?"
cabal run -v0 loop -- --help; echo "exit=$?"
```
Expected: build succeeds; both `--help` exit 0. If `cabal build` fails on the solver (`crypton` bounds), report the exact error; do not relax bounds.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "chore: rename package to gams-evm-transport

name/executable/test-suite renamed; license field corrected to MIT to match
the LICENSE file (BSD-3 was cabal-init boilerplate); extra-doc-files dropped
(CHANGELOG.md never existed); hs-source-dirs re-rooted after the offchain/
split.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: Re-root every `offchain/` literal; measure the bare test partition
**Specialist:** Backend Architect

**Files:**
- Modify: `lib/Gams/Config.hs:95,119`, `lib/Store/Config.hs:65,81`, `lib/Rig/Manifest.hs:209,212,287,309,311,324,325,444`, `lib/Driver/Capture.hs:334,604,605`, `lib/Chain/Read.hs:600`, `lib/Chain/Endpoint.hs:145,316-358`, `app/ChainReadConformance.hs:107,110,208,277,411,412,416`, `app/CheatSwapProof.hs:83,86,432,433`, `app/GamsConformance.hs:128,132,133,216,469`, `app/FeeSplitConformance.hs:160,184,208`, `app/StoreConformance.hs:127`, `test/Main.hs` (79 `"offchain/` literals + `walk_files "offchain"` / `purge_scan "offchain"` at ~1543-1544), haddock prose in every `lib/**/*.hs`, `LOOP.md`, `rig/*.sh`, `rig/README.md`, `spec/types.md`, `todo.md`
- Create: `cabal.project.freeze`

**Interfaces:** Produces a tree with **zero** occurrences of the string `offchain` outside git history and the 12 `--` comment lines of the cabal file (147, 247, 356, 439, 442, 474, 478, 511, 512, 534, 561, 629 — historical notes, left as-is); `purge_roots`, `repo_roots :: [FilePath]` in `test/Main.hs`.

- [ ] **Step 1: Mechanical rewrite across the tree**

```bash
cd /home/jmsbpp/cfmm/gams-evm-transport
# 1a. standalone haddock "@offchain\/@" sentences (~20): rewrite BY HAND first, else the sed below leaves "@@"
grep -rn 'offchain\\/@' lib app test rig | grep -v 'offchain\\/[a-zA-Z]'
# 1b. path forms — plain and haddock-escaped. NOTE: the escaped form drops the prefix entirely
#     ("@offchain\/lib\/X@" -> "@lib\/X@"); do NOT replace it with "\/" (that reads as absolute /lib).
grep -rl 'offchain' lib app test rig LOOP.md spec todo.md | xargs sed -i \
  -e 's#offchain/lib/#lib/#g' -e 's#offchain/app/#app/#g' -e 's#offchain/test/#test/#g' \
  -e 's#offchain/rig/#rig/#g' -e 's#offchain/migrations#migrations#g' -e 's#offchain\\/##g'
grep -rn 'offchain' lib app test rig LOOP.md spec todo.md
```
Expected: remaining hits are (i) prose sentences (`LOOP.md:3` "Location: offchain/LOOP.md", "widening this set to @offchain@") — rewrite by hand (`Location: LOOP.md — next to the code`; `widening this set to the whole tree`); (ii) the four bare `"offchain"` scan roots in `test/Main.hs` handled in Step 2: `sc3_literal_purge` (~1545-1546), `no_credential_is_present_in_a_tracked_file` (~8620-8621), `ungated_renderer_token` grep (~15884), `endpoint_census` grep root (~16063). Re-run the grep until only those four remain, then do Step 2. Spot-check the haddocks: `grep -rn '@\\/' lib | head` must print nothing (that is the corrupted form).

- [ ] **Step 2: Scan roots (`test/Main.hs`) — four scans, two explicit lists**

```haskell
-- | The EXECUTABLE surface: what the literal purge scans. Explicit, because the repository
-- root now also holds the cfmm-numopt submodule (.gms, Makefile, CI), docs/ and .github/,
-- none of which is this package's code and none of which should silently widen or narrow
-- the scan.
purge_roots :: [FilePath]
purge_roots = ["lib", "app", "test", "rig", "migrations"]

-- | EVERYTHING THIS PACKAGE TRACKS, for the scans whose subject is "any tracked file": the
-- credential scan, the ungated-renderer-token scan and the endpoint census (whose declared
-- sites include spec/types.md, LOOP.md and rig/README.md). The submodule is excluded because
-- its files are cfmm-numopt's to scan; docs/ and .github/ because they hold no code, no
-- credential and no endpoint site -- and a census that walked them would have to declare
-- every prose mention there too.
repo_roots :: [FilePath]
repo_roots = purge_roots ++ ["spec", "LOOP.md", "todo.md", "README.md"]
```
`walk_files` on a file path must return `[path]` (it already does: `doesDirectoryExist` false → leaf). Use `purge_roots` in `sc3_literal_purge`; `repo_roots` in `no_credential_is_present_in_a_tracked_file`, the `ungated_renderer_token` grep (pass the roots as grep operands after the pattern), and `endpoint_census`. `README.md` does not exist until Task 7 — `walk_files` must tolerate a missing root: guard with `doesPathExist` and skip. After the change `endpoint_census` must still pass (its hit set vs `Chain.Endpoint.endpoint_sites` is unchanged in members, only in prefix). Then in `sc3_literal_purge`:

and in the check body:

```haskell
  files   <- concat <$> mapM walk_files purge_roots
  (code, out, err) <- purge_scan purge_roots
```

with `purge_scan` taking `[FilePath]`:

```haskell
purge_scan :: [FilePath] -> IO (ExitCode, String, String)
purge_scan roots =
  readProcessWithExitCode
    "grep"
    (["-rnE", purge_pattern] ++ roots ++ map ("--include=*" ++) purge_scanned_extensions)
    ""
```
Update the failure message that said `"offchain/ holds file types..."` to `"the purge roots hold file types..."`. `purge_positive_control` calls `purge_scan` on a temp dir — pass `[dir]`.

- [ ] **Step 3: Build clean**

```bash
cabal build --enable-tests -j all 2>&1 | tee /tmp/claude-1000/-home-jmsbpp-cfmm-gams-evm-transport/f7e9c387-2b04-40e0-8831-28dc2640b594/scratchpad/build.log | tail -3
grep -cE '^(lib|app|test)/[^ ]*:[0-9]+:[0-9]+: warning:' /tmp/claude-1000/-home-jmsbpp-cfmm-gams-evm-transport/f7e9c387-2b04-40e0-8831-28dc2640b594/scratchpad/build.log
```
Expected: build OK, warning count `0`.

- [ ] **Step 4: Measure the bare partition (no rig, no Postgres, no PLANK_ROOT, no chain)**

```bash
env -u PLANK_ROOT -u PGSTORE_DSN -u RIG_TESTS cabal test 2>&1 | tee ../bare-test.log | tail -5
grep -E "FAILED:" ../bare-test.log
```
Record the failing check names into `docs/superpowers/plans/2026-08-26-partition.md` under four headings, by reading each failure message:
- **path-literal** (message names a path under `lib/ app/ rig/ test/` that exists) → fix now, they are Step-1 misses;
- **monorepo-contract** (message names `src/…`, `test/models/…`, `test/pos_spec/…`, `origin/develop`, `import-ref`) → Task 4;
- **rig/foundry** (`rig-manifest.json`, `cast`, `manifest`, chain reads) → Task 4 tier 2;
- **postgres** (`PGSTORE_DSN`, `connect`) → Task 4 tier 2.
Expected known members: monorepo-contract ⊇ {`the_default_fixture_path_is_the_consumers_own_constant`, checks reading `realized_vol_iface`, `dynamic_fee_hook_iface`, `volorder_iface`, `shocklib_path`, `golden_file`}; rig ⊇ {`sc3_load_succeeds`, `sc4_cast_agreement`}.

- [ ] **Step 5: Freeze the plan and commit**

```bash
cabal freeze && git add cabal.project.freeze
git add -A && git commit -m "chore: re-root paths after the offchain/ split

Every offchain/ literal in code, tests, scripts and prose now names the
repository-root layout. sc3_literal_purge walks an explicit root list
(lib app test rig migrations) so the cfmm-numopt submodule, docs/ and
.github/ never enter the scan. Bare-suite partition recorded in
docs/superpowers/plans/2026-08-26-partition.md. cabal.project.freeze pins
the plan that built clean on GHC 9.10.3.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: `PLANK_ROOT` resolver and fixture-dir resolution in `Loop.Config`
**Specialist:** Backend Architect

**Files:**
- Modify: `lib/Loop/Config.hs` (export list ~46-52; block at 137-190)
- Modify: `test/Main.hs` (`fixture_dir_rule_assertions` ~4354; `value_overrides` list near it; `config_modules` unchanged)
- Modify: `LOOP.md` §2 table

**Interfaces:**
- Produces `Loop.Config.plank_root_env_var :: String` (= `"PLANK_ROOT"`), `plank_root_from :: Maybe String -> Maybe FilePath`, `plank_root :: IO (Maybe FilePath)`, `fixture_dir_with_root :: Maybe FilePath -> Maybe String -> FilePath`. `fixture_dir_from` and `default_fixture_dir` keep their exact current signatures and values.
- Task 4 and Task 6 consume `plank_root`.

- [ ] **Step 1: Write the failing assertions (add to `fixture_dir_rule_assertions`)**

```haskell
  _ <- expect (plank_root_from Nothing == Nothing && plank_root_from (Just "") == Nothing)
         (plank_root_env_var ++ " absent or empty must resolve to Nothing; got "
           ++ show (plank_root_from Nothing, plank_root_from (Just "")))
  _ <- expect (plank_root_from (Just "/srv/plank") == Just "/srv/plank")
         (plank_root_env_var ++ " set must resolve verbatim")
  _ <- expect (fixture_dir_with_root Nothing Nothing == default_fixture_dir)
         "no root, no override: the consumer-relative default, unchanged"
  _ <- expect (fixture_dir_with_root (Just "/srv/plank") Nothing == "/srv/plank" </> default_fixture_dir)
         "root set, no override: the default joined under PLANK_ROOT"
  _ <- expect (fixture_dir_with_root (Just "/srv/plank") (Just "/tmp/x") == "/tmp/x")
         "FIXTURE_DIR wins over PLANK_ROOT"
  _ <- expect (fixture_dir_with_root (Just "/srv/plank") (Just "") == "/srv/plank" </> default_fixture_dir)
         "empty FIXTURE_DIR is absent, so the root default applies"
```

- [ ] **Step 2: Run to verify it fails**

```bash
cabal build --enable-tests -j all 2>&1 | grep -E "not in scope|error" | head -3
```
Expected: `Variable not in scope: plank_root_from` (compile failure is the red state).

- [ ] **Step 3: Implement in `lib/Loop/Config.hs`**

Add to the export list under "Where the fixture is published":
```haskell
  , plank_root_env_var
  , plank_root_from
  , plank_root
  , fixture_dir_with_root
```
Add after `fixture_dir_from`:
```haskell
-- | The monorepo checkout this bridge PUBLISHES INTO and whose contracts the suite asserts
-- against. Stated once, here, in the shape of every other override of this subsystem: a name
-- constant, a pure rule over what @lookupEnv@ hands back, an @IO@ resolver that reads the name.
--
-- It is OPTIONAL on purpose. Unset, the bridge and the suite still build, run and pass for
-- everything that is this repository's own; what needs the monorepo is gated on it and says so
-- by name. Set, it must be a checkout of JMSBPP/cfmm-replicationPlank with an @origin@ remote.
plank_root_env_var :: String
plank_root_env_var = "PLANK_ROOT"

-- | Absent and empty both mean "no monorepo here" -- 'fixture_dir_from' explains why the empty
-- case cannot be told apart from the absent one from inside this process.
plank_root_from :: Maybe String -> Maybe FilePath
plank_root_from (Just raw) | not (null raw) = Just raw
plank_root_from _                           = Nothing

plank_root :: IO (Maybe FilePath)
plank_root = plank_root_from <$> lookupEnv plank_root_env_var

-- | THE RESOLUTION ORDER: an explicit @FIXTURE_DIR@ wins; else the consumer's own default
-- joined under @PLANK_ROOT@; else that default relative to the working directory, where the
-- LOOP-04 precondition (exit 40, directory missing) fires exactly as documented.
fixture_dir_with_root :: Maybe FilePath -> Maybe String -> FilePath
fixture_dir_with_root _ (Just raw) | not (null raw) = raw
fixture_dir_with_root (Just root) _                  = root </> default_fixture_dir
fixture_dir_with_root Nothing _                      = default_fixture_dir
```
and change the resolver:
```haskell
fixture_dir :: IO FilePath
fixture_dir = fixture_dir_with_root <$> plank_root <*> lookupEnv fixture_dir_env_var
```

- [ ] **Step 4: Register the override in the suite's census**

The census is `store_overrides_are_probed_or_named_as_gaps` (~4760): it greps `config_modules` with `config_env_var_declaration_pattern = "^[a-z_]+_env_var :: String$"` (~4685) and requires every hit to be in `config_env_vars` (~4643) AND in exactly one of `advertised_overrides` (`OverrideProbe`, ~4258 — `FIXTURE_DIR` lives here), `value_overrides` (~4408, only `loop_poll_ms`), or `unprobed_overrides` (named gaps). `plank_root_from` refuses nothing, so it is not a `ValueOverride`; add it to `unprobed_overrides` with the reason string `"PLANK_ROOT: resolved verbatim and refuses nothing; its only effect is fixture_dir_with_root, which fixture_dir_rule_assertions drives directly with both Nothing and Just"`, and add `plank_root_env_var` to `config_env_vars`. Add `plank_root_env_var`, `plank_root_from`, `plank_root`, `fixture_dir_with_root` to the explicit `import Loop.Config (...)` list at `test/Main.hs:229`. Run:

```bash
cabal build --enable-tests -j all 2>&1 | tail -1 && env -u PLANK_ROOT cabal test 2>&1 | grep -E "store_overrides_are_probed|every_advertised_override|fixture_dir|passed"
```
Expected: no failure naming `PLANK_ROOT`, `fixture_dir` or the census; the total-passed count equals Task 2's bare count (the monorepo-contract failures are still present — Task 4).

- [ ] **Step 5: Document and commit**

Insert into the `LOOP.md` §2 table after the `PGSTORE_DSN` row:
```
| `PLANK_ROOT` | *(unset)* | Optional. A checkout of `JMSBPP/cfmm-replicationPlank` with an `origin` remote. When set, the default publication directory is resolved under it and the monorepo-contract checks in `cabal test` run instead of being skipped by name. |
```
and change the `FIXTURE_DIR` row's default to `` `$PLANK_ROOT/test/models/mev_tax_model_one/fixtures` when `PLANK_ROOT` is set, else the same path relative to cwd (issue #25's contract) ``.

```bash
git add -A && git commit -m "feat(loop): PLANK_ROOT names the monorepo; FIXTURE_DIR resolves under it

default_fixture_dir stays the consumer's own constant (asserted). Resolution:
FIXTURE_DIR > \$PLANK_ROOT/default > default relative to cwd (exit 40 as before).

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Gate the monorepo-contract and tier-2 checks
**Specialist:** Backend Architect

**Files:**
- Modify: `test/Main.hs` — `core_checks` (~20665), path constants at 783, 786, 1583, 2600, 14451, 14460, 19812, 19816 and the `git` calls in `the_default_fixture_path_is_the_consumers_own_constant` (~19865-19873) and `path_on_upstream`; checks listed in the partition file.

**Interfaces:** Produces `gated :: String -> String -> Maybe a -> (a -> Check) -> Check` (name, reason, resolved need, check builder) and `rig_tests_env_var = "RIG_TESTS"`. Skipped checks print `SKIPPED (<reason>): <name>` and count as passed.

- [ ] **Step 1: Write the gating helper**

```haskell
-- | A check that needs something this repository does not carry: the monorepo checkout
-- (@PLANK_ROOT@) or a standing rig + Postgres (@RIG_TESTS=1@). When the need is unmet the
-- check is REPLACED by one that prints its own name with the reason and passes -- a printed
-- skip, never a silent one. When met, the real check runs with the resolved value. The name
-- is passed explicitly so the skip line and the real check agree on it by construction.
gated :: String -> String -> Maybe a -> (a -> Check) -> Check
gated name reason Nothing _ =
  Check name (putStrLn ("SKIPPED (" ++ reason ++ "): " ++ name) >> pure (Right ()))
gated _ _ (Just a) mk = mk a

rig_tests_env_var :: String
rig_tests_env_var = "RIG_TESTS"

rig_tests_enabled :: IO Bool
rig_tests_enabled = (== Just "1") <$> lookupEnv rig_tests_env_var
```
Note: `mk` receives the root only to build paths; `check_name` must be a literal in every gated check (it already is: every `Check "name" ...` uses a string literal).

- [ ] **Step 2: Re-point the monorepo path constants to functions of the root**

For each constant, change the type and every use site (compiler finds them):
```haskell
realized_vol_iface :: FilePath -> FilePath
realized_vol_iface root = root </> "src/interfaces/market_state_measurements/RealizedVolatilityInterface.plk"
dynamic_fee_hook_iface :: FilePath -> FilePath
dynamic_fee_hook_iface root = root </> "src/interfaces/protocol_integrations/DynamicFeeHookInterface.plk"
volorder_iface :: FilePath -> FilePath
volorder_iface root = root </> "src/interfaces/pos_spec/VolOrderManagerInterface.plk"
golden_file :: FilePath -> FilePath
golden_file root = root </> "test/pos_spec/fixtures/vol_order_return_golden.json"
shocklib_path :: FilePath -> FilePath
shocklib_path root = root </> "src/models/mev_tax_model_one/libraries/ShockLib.plk"
```
`upstream_ref`, `consumer_test_path`, `consumer_absent_path` stay strings; the two `readProcessWithExitCode "git" [...]` calls and `path_on_upstream` gain `"-C", root` as their first two arguments. Each affected check becomes `root -> Check`.

- [ ] **Step 3: Wire the gates in `core_checks`**

```haskell
core_checks = do
  root    <- plank_root
  rig_on  <- rig_tests_enabled
  let rig = if rig_on then Just () else Nothing
      contract n = gated n "PLANK_ROOT unset" root
      tier2    n = gated n "RIG_TESTS unset" rig
  ...
          , tier2 "sc4_cast_agreement" (\() -> sc4_cast_agreement pins)
          , tier2 "sc3_load_succeeds"  (\() -> sc3_load_succeeds)
          , contract "the_default_fixture_path_is_the_consumers_own_constant"
                     the_default_fixture_path_is_the_consumers_own_constant
          -- ... one `contract "<name>" <check>` / `tier2 "<name>" (\() -> <check>)` line per
          -- name in the partition file's monorepo-contract / rig / postgres lists
```
Import `plank_root` from `Loop.Config`. Every name in the partition file's *monorepo-contract* and *rig/foundry*/*postgres* lists must appear wrapped; nothing else is wrapped.

- [ ] **Step 4: Verify both modes**

```bash
env -u PLANK_ROOT -u RIG_TESTS cabal test 2>&1 | tee ../bare2.log | tail -3
grep -c "^SKIPPED" ../bare2.log          # expected: = |monorepo-contract| + |tier2| from the partition file
grep "FAILED" ../bare2.log               # expected: none
PLANK_ROOT="$S/plank" cabal test 2>&1 | tee ../root.log | tail -3     # the dedicated develop clone from Task 0 Step 7
grep -c "^SKIPPED (PLANK_ROOT" ../root.log   # expected: 0
```
For the `PLANK_ROOT` run, monorepo-contract checks must **pass** (that checkout has `origin/develop` and the `src/` tree). If one fails with a message about content (not a path), it is a genuine contract drift — record it in the partition file; do not gate it away.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "test: gate monorepo-contract checks on PLANK_ROOT and rig checks on RIG_TESTS

Skips are printed by name and counted; nothing is deleted. Bare suite is
green; PLANK_ROOT=<monorepo> runs the contract checks against it.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: `cfmm-numopt` submodule, golden reproduction, conformance re-capture
**Specialist:** DevOps Automator (GAMS toolchain + artifacts); Reality Checker reviews the golden equality claim

**Files:**
- Create: `.gitmodules`, `cfmm-numopt/` (gitlink)
- Modify: `lib/Gams/Config.hs:78` (`default_gams_model`) and its haddock at 66-76
- Modify (regenerated): `rig/gams-conformance.json`, `rig/fee-split-conformance.json`

**Interfaces:** `default_gams_model = "cfmm-numopt/model/mev_tax_model_one/volume_path.gms"`.

- [ ] **Step 1: Add the submodule at `main`**

```bash
git submodule add https://github.com/JMSBPP/cfmm-numopt.git cfmm-numopt
git -C cfmm-numopt checkout 6d766a7 && git -C cfmm-numopt rev-parse --short HEAD   # 6d766a7
sha256sum cfmm-numopt/model/mev_tax_model_one/volume_path.gms | cut -c1-8               # d454654c
```

- [ ] **Step 2: Prove the golden reproduces under the new model (STOP gate)**

```bash
G=$(jq -r '.golden.sha256' rig/gams-conformance.json); echo "committed golden sha: $G"
D=$(mktemp -d); cp cfmm-numopt/model/mev_tax_model_one/volume_path.gms "$D/" && cd "$D"
gams volume_path.gms action=ce lo=0 curdir="$D" >/dev/null 2>&1; echo "gams rc=$?"
sha256sum volume_path.json | cut -d' ' -f1; cd - >/dev/null
cmp "$D/volume_path.json" rig/volume-path-golden.json && echo GOLDEN-IDENTICAL; rm -rf "$D"
```
(Verified at plan time: the model's `$setGlobal` defaults equal `GamsConformance.golden_shock`, and a bare run reproduces `e7b14f38…`.)
Expected: `gams rc=0`, `GOLDEN-IDENTICAL`, and the sha equals `$G`. **If not identical: stop the task, report both hashes and a `diff`, and do not proceed** — pinning `efc2162` is the user's decision.

- [ ] **Step 3: Point the default at the submodule**

In `lib/Gams/Config.hs` replace the haddock at 66-76 and the constant:
```haskell
-- | The prover lives in the numerical-optimization layer, JMSBPP/cfmm-numopt, mounted here as
-- the @cfmm-numopt@ submodule and pinned by SHA. The default is that path; an uninitialised
-- submodule fails resolution NAMING the path, which is the failure that tells an operator to
-- run @git submodule update --init cfmm-numopt@ rather than quietly resolving something else.
--
-- The basename matters twice over. It is the file that is invoked, and it is the JOB NAME the
-- banner must carry for 'Gams.Version.parse_gams_version' to accept the version it reports -- so
-- the model path and the version's subject are the same fact, resolved once.
default_gams_model :: FilePath
default_gams_model = "cfmm-numopt/model/mev_tax_model_one/volume_path.gms"
```
```bash
cabal build --enable-tests -j all 2>&1 | tail -1
```

- [ ] **Step 4: Re-capture both conformance artifacts on this host**

```bash
export GAMS_MODEL="$PWD/cfmm-numopt/model/mev_tax_model_one/volume_path.gms"   # both scripts REQUIRE it and exit 1 otherwise
bash rig/capture-gams-conformance.sh 2>&1 | tail -5
bash rig/capture-fee-split.sh 2>&1 | tail -5
unset GAMS_MODEL
jq -r '.action_c.artifact_present, .action_c.exit' rig/gams-conformance.json      # false, 0
jq -r '.golden.sha256' rig/gams-conformance.json                                  # = $G
jq -r '.model_sources[].sha256' rig/gams-conformance.json                          # d454654c…
git diff --stat rig/
```
If a capture script refuses (e.g. it `cd`s to `git rev-parse --show-toplevel` and expects `offchain/`), the Task-2 rewrite missed it — fix the script, not the artifact.

- [ ] **Step 5: Suite green with the new artifacts**

```bash
env -u PLANK_ROOT cabal test 2>&1 | grep -E "gams_conformance|fee_split|FAILED|passed"
```
Expected: `gams_conformance_is_present_and_fresh` and the fee-split checks pass; no FAILED.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: cfmm-numopt submodule supplies the prover model

Pinned at cfmm-numopt main 6d766a7. rig/volume-path-golden.json reproduces
byte-for-byte under it (sha ...). gams-conformance.json and
fee-split-conformance.json re-captured on this host with
rig/capture-gams-conformance.sh and rig/capture-fee-split.sh: they carry the
new model sha, the post-re-root module digests and this host's gams_path.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 6: Rig scripts resolve `PLANK_ROOT`
**Specialist:** DevOps Automator

**Files:**
- Create: `rig/plank-root.sh` (sourced helper)
- Modify: `rig/deploy-rig.sh:24`, `rig/verify-rig.sh:20`, `rig/check-upstream.sh:9`, `rig/verify-import.sh:9`, `rig/generate-pins.sh:32-33`, `rig/capture-loop.sh:84`, `rig/capture-chain-read.sh:42`, `rig/capture-cheat-swap-proof.sh:36`, `rig/capture-batch-return.sh:46`; `rig/README.md` clean-machine sequence
- Not modified: `rig/endpoint.sh`, `rig/capture-gams-conformance.sh`, `rig/capture-fee-split.sh`, `rig/capture-store-conformance.sh` (they need only this repo)

**Interfaces:** sourcing `rig/plank-root.sh` sets `TRANSPORT_ROOT` (this repo) and `PLANK_ROOT` (validated) and leaves cwd at `TRANSPORT_ROOT`.

- [ ] **Step 1: The helper**

```bash
cat > rig/plank-root.sh <<'SH'
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
SH
```

- [ ] **Step 2: Wire each script**

In each listed script replace the `cd "$(git rev-parse --show-toplevel)"` line (or `generate-pins.sh`'s `cd "$(dirname "$0")/../.."; ROOT="$PWD"`) with:
```bash
. "$(dirname "$0")/plank-root.sh"
```
**Exception — `deploy-rig.sh`:** it already sources `rig/endpoint.sh` near the top and handles `--stop` (only needs `endpoint.sh` + `cast`) before any forge work. Source `plank-root.sh` **after** the `--stop` branch, so `deploy-rig.sh --stop` (the EXIT trap and the `always()` teardown) works with `PLANK_ROOT` unset. Its monorepo-relative sites, all of which move under `$PLANK_ROOT`: six `forge script foundry-scripts/…` (lines ~497-569), `rm -rf broadcast/…`, the six `B_*=broadcast/…/run-latest.json` reads, `npm`/`node_modules` checks; its outputs `rig/rig-manifest.json` and `rig/import-ref.txt` stay `$TRANSPORT_ROOT/rig/…`, and `. rig/endpoint.sh` becomes `. "$TRANSPORT_ROOT/rig/endpoint.sh"`. `verify-import.sh`: `PATHS="$TRANSPORT_ROOT/rig/import-paths.txt"`, `PIN="$PLANK_ROOT/.planning/phases/20-deploy-rig-source-of-truth-import/IMPORT-PIN.md"`, diff runs in `$PLANK_ROOT`. `generate-pins.sh`: inputs (`src/…`, `notes/DATA_CONTRACT.md`, `IMPORT-PIN.md`) under `$PLANK_ROOT`, outputs under `$TRANSPORT_ROOT/rig/`. Then prefix every other monorepo-relative operation: `forge script …` / `npm ci` / `git rev-parse origin/develop` / `git show "$DEV:…"` / reads of `src/…`, `foundry-scripts/…`, `.planning/…` → run inside `( cd "$PLANK_ROOT" && … )` or with `git -C "$PLANK_ROOT"`, `"$PLANK_ROOT/src/…"`. Outputs (`rig/rig-manifest.json`, `rig/import-ref.txt`, `rig/rig-pins.json`, `rig/*.json`) stay `"$TRANSPORT_ROOT/rig/…"`. In `generate-pins.sh` set `ROOT="$PLANK_ROOT"` for inputs and write outputs under `$TRANSPORT_ROOT`.

- [ ] **Step 3: Verify without a rig (refusal path) and with one (if available)**

```bash
for s in deploy-rig verify-rig check-upstream verify-import generate-pins capture-loop capture-chain-read capture-cheat-swap-proof capture-batch-return; do
  env -u PLANK_ROOT bash rig/$s.sh >/dev/null 2>&1; echo "$s rc=$?"; done       # all rc=64
PLANK_ROOT=/nonexistent bash rig/check-upstream.sh; echo rc=$?                    # 64
env -u PLANK_ROOT bash rig/deploy-rig.sh --stop; echo "stop rc=$?"                        # 0: --stop must not need PLANK_ROOT
PLANK_ROOT="$S/plank" bash rig/check-upstream.sh && PLANK_ROOT="$S/plank" bash rig/verify-import.sh; echo rc=$?
cat rig/import-ref.txt; git -C "$S/plank" rev-parse origin/develop
```
Expected: `rc=0`; `rig/import-ref.txt` now equals `origin/develop` (`d2b1c518…` at plan time — it WAS `2039f27`, so it changes; commit it as the re-pin it is). If `verify-import.sh` fails because `IMPORT-PIN.md` or an imported path is absent on `develop`, that is monorepo drift: record it in the partition file under "monorepo-contract drift" and leave the script honest — do not stub the check. `deploy-rig.sh` end-to-end is **not** run here — it owns anvil on 8545 and needs the lock; it is exercised by `rig-e2e` (Task 8).

- [ ] **Step 4: README sequence and commit**

Rewrite `rig/README.md` "Clean-machine sequence" to: clone the monorepo → `export PLANK_ROOT=…` → `( cd "$PLANK_ROOT" && npm ci --ignore-scripts && git -c submodule.lib/panoptic-helper.update=none submodule update --init --recursive && forge build )` → `rig/check-upstream.sh && rig/verify-import.sh && rig/deploy-rig.sh && rig/verify-rig.sh` → `cabal build --enable-tests -j all && RIG_TESTS=1 cabal test` → `RIG_SEED=… cabal run gams-evm-transport`. State that CI's `rig-e2e` writes `broadcast/` and runs `npm ci` inside `$PLANK_ROOT`, so the runner's `PLANK_ROOT` is a dedicated checkout.

```bash
git add -A && git commit -m "chore(rig): scripts resolve the monorepo through PLANK_ROOT

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: README, `.gitignore`, spec + plan committed
**Specialist:** Technical Writer

**Files:**
- Create: `README.md`, `.gitignore`
- Modify: `LOOP.md:3` (location line)
- Add: `docs/superpowers/specs/2026-08-26-gams-evm-transport-migration-design.md`, `docs/superpowers/plans/2026-08-26-gams-evm-transport-migration.md`, `docs/superpowers/plans/2026-08-26-partition.md`

- [ ] **Step 1: `.gitignore` review** — it was created in Task 0 Step 6; confirm `git status --porcelain` shows nothing unexpected after the Task 5 captures (`git status --porcelain | grep -vE '^(A|M) '` empty).

- [ ] **Step 2: `README.md`** — sections, in order: one-paragraph purpose (from the spec §1 first paragraph); the three-repo table (spec §1); "What is here" (`lib/` module groups one line each, `app/` executables by cabal stanza name, `rig/` artifacts, `migrations/`, `cfmm-numopt/`); environment table (`ETH_RPC_URL`, `PGSTORE_DSN`, `PLANK_ROOT`, `FIXTURE_DIR`, `LOOP_POLL_MS`, `GAMS_BIN`, `GAMS_MODEL`, `RIG_TESTS` — copy defaults from `LOOP.md` §2); build/test (`cabal build --enable-tests -j all`, `cabal test`, `PLANK_ROOT=… cabal test`, `RIG_TESTS=1 cabal test`); toolchain pins (GHC 9.10.3, GAMS 54.1 / CONOPT 4.39, Demo licence, `git submodule update --init cfmm-numopt`); pointer to `LOOP.md` and `rig/README.md`; provenance line ("history split from `cfmm-replicationPlank` `feat/rpc-api` @ 29ce4b7 with `git filter-repo`").

- [ ] **Step 3: Verify and commit**

```bash
git add -A && git status --porcelain | grep -v '^A ' ; git commit -m "docs: README, .gitignore, migration spec and plan

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: CI workflow, runner registration, approval environment
**Specialist:** DevOps Automator

**Files:**
- Create: `.github/workflows/haskell.yml`
- User-run: runner registration + systemd unit; GitHub environment `transport-gate`

- [ ] **Step 1: Workflow**

```yaml
name: haskell
on:
  pull_request:
    branches: [main]          # PR-only, like develop-gate: one approval per change, not two
  workflow_dispatch:
    inputs:
      rig_e2e:
        description: "also run the rig end-to-end job"
        type: boolean
        default: false
concurrency:
  group: haskell-${{ github.ref }}
  cancel-in-progress: true
permissions:
  contents: read

jobs:
  approve:
    runs-on: ubuntu-latest
    environment: transport-gate
    timeout-minutes: 5
    steps:
      - run: echo "approved — the self-hosted jobs may start"

  build-test:
    needs: [approve]
    runs-on: [self-hosted, cfmm-build]
    timeout-minutes: 45
    env:
      GIT_TERMINAL_PROMPT: "0"
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true          # cfmm-numopt only; its lean4-spec is not recursed
          persist-credentials: false
      - run: echo "$HOME/.ghcup/bin" >> "$GITHUB_PATH"
      - run: |
          [ "$(ghc --numeric-version 2>/dev/null)" = "9.10.3" ] || ghcup install ghc 9.10.3 --set
          command -v cabal >/dev/null || ghcup install cabal recommended --set
          ghc --version && cabal --version && cabal update
      - name: build, -Wall gate
        run: |
          set -o pipefail
          cabal build --enable-tests -j all 2>&1 | tee "$RUNNER_TEMP/cabal-build.log"
          WARN_RE='^(lib|app|test)/[^ ]*:[0-9]+:[0-9]+: warning:'
          probe=lib/WallGateProbe.hs
          printf 'module WallGateProbe where\nwallGateProbe = ()\n' > "$probe"
          probe_out=$(ghc -Wall -fno-code -v0 -outputdir "$RUNNER_TEMP/wall-probe" "$probe" 2>&1 || true)
          rm -f "$probe"
          printf '%s\n' "$probe_out" | grep -qE "$WARN_RE" || { echo "::error::-Wall positive control failed"; printf '%s\n' "$probe_out"; exit 1; }
          compiled=$(grep -cE '^\[ *[0-9]+ of [0-9]+\] Compiling' "$RUNNER_TEMP/cabal-build.log" || true)
          expected=$(find lib app test -name '*.hs' | wc -l)
          [ "$compiled" -ge "$expected" ] || { echo "::error::compiled $compiled < $expected .hs files (warm dist-newstyle?)"; exit 1; }
          ! grep -qE "$WARN_RE" "$RUNNER_TEMP/cabal-build.log" || { grep -nE "$WARN_RE" "$RUNNER_TEMP/cabal-build.log"; exit 1; }
      - name: tier-1 suite (no rig, no Postgres, no monorepo)
        run: env -u PLANK_ROOT -u RIG_TESTS cabal test
      - name: prover conformance subset against the pinned submodule
        run: |
          D=$(mktemp -d); cp cfmm-numopt/model/mev_tax_model_one/volume_path.gms "$D/"
          ( cd "$D" && gams volume_path.gms action=ce lo=0 curdir="$D" >/dev/null 2>&1 )
          got=$(sha256sum "$D/volume_path.json" | cut -d' ' -f1)
          want=$(jq -r '.golden.sha256' rig/gams-conformance.json)
          msha=$(sha256sum cfmm-numopt/model/mev_tax_model_one/volume_path.gms | cut -d' ' -f1)
          mrec=$(jq -r '.model_sources[0].sha256' rig/gams-conformance.json)
          [ "$got" = "$want" ] || { echo "::error::golden drift: $got != $want"; exit 1; }
          [ "$msha" = "$mrec" ] || { echo "::error::model drift: submodule $msha != recorded $mrec"; exit 1; }
          rm -rf "$D"
          git status --porcelain | grep -q . && { echo "::error::suite left the tree dirty"; git status --porcelain; exit 1; } || true

  rig-e2e:
    if: github.event_name == 'workflow_dispatch' && inputs.rig_e2e
    needs: [build-test]
    runs-on: [self-hosted, cfmm-build]
    timeout-minutes: 90       # flock may wait up to 30 min; develop-gate budgets 60 for the rig alone
    env:
      GIT_TERMINAL_PROMPT: "0"
      PGSTORE_DSN: "postgresql://postgres:postgres@127.0.0.1:55433/postgres"
    steps:
      - uses: actions/checkout@v4
        with: { submodules: true, persist-credentials: false }
      - run: echo "$HOME/.ghcup/bin" >> "$GITHUB_PATH"
      - run: |
          [ -n "${PLANK_ROOT:-}" ] || { echo "::error::PLANK_ROOT is not set in the runner's .env"; exit 1; }
          echo "PLANK_ROOT=$PLANK_ROOT"
      - name: prepare the dedicated monorepo checkout (the same steps develop-gate runs)
        run: |
          cd "$PLANK_ROOT"
          git fetch origin && git checkout -q --detach origin/develop
          git submodule update --init lib/panoptic-v2-core
          git -C lib/panoptic-v2-core config submodule.lib/panoptic-helper.update none
          git submodule update --init --recursive
          make plank-toolchain
          npm ci --ignore-scripts
      - name: postgres (port 55433 — same as rig/capture-store-conformance.sh; never run both at once on this host)
        run: |
          docker rm -f gams-evm-transport-pg >/dev/null 2>&1 || true
          docker run -d --name gams-evm-transport-pg -e POSTGRES_PASSWORD=postgres -p 127.0.0.1:55433:5432 postgres:18-alpine
          for i in $(seq 1 30); do docker exec gams-evm-transport-pg pg_isready -U postgres && break; sleep 1; done
          docker exec gams-evm-transport-pg pg_isready -U postgres || { echo "::error::postgres never became ready"; exit 1; }
      - name: rig under the shared 8545 lock
        run: |
          exec 9>>"$HOME/.cfmm-rig-8545.lock"
          flock -w 1800 9 || { echo "::error::rig lock held by: $(cat "$HOME/.cfmm-rig-8545.lock")"; exit 1; }
          echo "gams-evm-transport rig-e2e, run ${GITHUB_RUN_ID:-?}, pid $$" > "$HOME/.cfmm-rig-8545.lock"
          : > "$RUNNER_TEMP/rig-owned-8545"
          trap 'bash rig/deploy-rig.sh --stop || true' EXIT
          cabal build --enable-tests -j all
          bash rig/check-upstream.sh && bash rig/verify-import.sh
          bash rig/deploy-rig.sh && bash rig/verify-rig.sh
          RIG_TESTS=1 cabal test
      - if: always()
        run: |
          [ -f "$RUNNER_TEMP/rig-owned-8545" ] && bash rig/deploy-rig.sh --stop || true
          docker rm -f gams-evm-transport-pg >/dev/null 2>&1 || true
```

- [ ] **Step 2: Create the approval environment FIRST (before any push that carries the workflow)**

```bash
gh api -X PUT repos/JMSBPP/gams-evm-transport/environments/transport-gate \
  -f 'reviewers[][type]=User' -F "reviewers[][id]=$(gh api users/JMSBPP -q .id)"
gh api repos/JMSBPP/gams-evm-transport/environments/transport-gate -q '.protection_rules[].type'   # required_reviewers
```
A workflow pushed before this exists makes GitHub auto-create the environment with **no** reviewers, and `approve` passes unattended.

- [ ] **Step 3: Lint and commit (no push yet)**

```bash
docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:latest -color 2>&1 | tail -5 \
  || python3 -c "import yaml; yaml.safe_load(open('.github/workflows/haskell.yml')); print('yaml ok (actionlint unavailable)')"
git add .github && git commit -m "ci: haskell.yml — approve gate, build-test on the self-hosted runner, dispatch-only rig-e2e

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

- [ ] **Step 4: Runner registration (present to the user; do not run)**

```bash
# third repo-scoped runner on this host (USER RUNS — sudo for the unit)
TOKEN=$(gh api -X POST repos/JMSBPP/gams-evm-transport/actions/runners/registration-token -q .token)
mkdir -p ~/actions-runner-transport && cd ~/actions-runner-transport
tar xzf ~/actions-runner/actions-runner.tar.gz      # 2.336.0, current latest (~/actions-runner-cfmm/runner.tar.gz is 2.335.1)
./config.sh --unattended --url https://github.com/JMSBPP/gams-evm-transport --token "$TOKEN" \
  --name cfmm-build-transport --labels cfmm-build --work _work
echo "PLANK_ROOT=/home/jmsbpp/actions-runner-transport/plank" >> .env
git clone --branch develop "$PLANK_URL" plank          # dedicated: CI writes broadcast/ and node_modules here
sudo ./svc.sh install jmsbpp && sudo ./svc.sh start   # unit: actions.runner.JMSBPP-gams-evm-transport.cfmm-build-transport.service
gh api repos/JMSBPP/gams-evm-transport/actions/runners -q '.runners[] | .name+" "+.status'   # cfmm-build-transport online
```

- [ ] **Step 5: Push, then first green run**

After the user reports the runner online: `git push origin main`, then `gh workflow run haskell.yml --ref main`, approve in the `transport-gate` environment, then `gh run watch`. Expected: `approve` and `build-test` green; `rig-e2e` skipped. Record the run id in `docs/superpowers/plans/2026-08-26-partition.md`. Do **not** dispatch `rig_e2e=true` in this plan.

---

### Task 9: Close-out
**Specialist:** Git Workflow Master

- [ ] **Step 1: Follow-up issues in the new repo** (`gh issue create`, one each): "loop: first live end-to-end run (LOOP.md §7)"; "retire pre-Loop drivers (VolOrder/PriceSetter/Stochastic*/CheatSwap) if no forge consumer remains"; "Store.Postgres: keep or drop"; "rig-e2e: first green dispatch, then promote to merge gate".
- [ ] **Step 2: Monorepo note** — `gh issue create -R JMSBPP/cfmm-vol-markets --title "feat/rpc-api superseded by JMSBPP/gams-evm-transport"` with the filter-repo provenance (`29ce4b7`, 227 commits, tag `archive/feat-rpc-api`). Branch removal is the peer session's job after the Task 0 Step 8 message.
- [ ] **Step 3: Memory** — update `project_cfmm_numopt.md` sibling note: new repo, PLANK_ROOT convention, runner name.
