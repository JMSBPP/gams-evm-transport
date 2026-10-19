# Anvil Tick Multicall Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans or subagent-driven-development. Checkbox steps for tracking.

**Goal:** Real ABI calldata for `setTick`/`readTick` and Multicaller `aggregate`, Idris Anvil RPC smoke, and Foundry/Plank deploy+assert of mid-tx tick reads.

**Architecture:** HEVM `EVM.ABI` as reference only — port the minimum encode surface to Idris. Plank `src/Tick.plk` (transient storage) + Vectorized Multicaller: `targets` all = Tick, `data` = Idris-encoded blobs. Foundry subdir templated on plank-foundry-deployer. Idris encodes and submits to Anvil; Foundry owns deploy and mid-tx assert.

**Spec:** [docs/superpowers/specs/2026-10-19-gdx-anvil-tick-multicall-design.md](../specs/2026-10-19-gdx-anvil-tick-multicall-design.md)

**Tech:** Idris2, Anvil HTTP JSON-RPC, Foundry, Plank, [Vectorized Multicaller](https://github.com/Vectorized/multicaller) `aggregate`.

## Global constraints

- No full HEVM / no Haskell hevm as runtime dep.
- Do not change GdxWriter / handshake utils.
- Keep GAMS `publishGdx` Consumed = MulticallBatch file complete; Anvil smoke is additional `just` recipe until explicitly wired.
- Golden calldata must match `cast calldata` for `setTick(uint256)`.

---

### Task 1: Idris minimal ABI (HEVM-shaped)

**Files:** Create `src/Abi.idr`, `src/AbiMethod.idr`; Test: `test/src/AbiTest.idr`.

**Produces:**
- Precomputed selectors for `setTick(uint256)`, `readTick()`, Multicaller `aggregate(address[],bytes[],uint256[],address)` (verify with `cast sig`; document regen).
- `encodeUint256 : Integer -> String`
- `abiMethodSetTick : Integer -> String` → full `0x` calldata
- `abiMethodReadTick : String`
- `abiMethodAggregate : List String -> List String -> List Integer -> String -> String` (targets, data, values, refundTo) — Tick demo: same Tick address repeated in targets

- [x] Failing tests: `abiMethodSetTick 1` equals `cast calldata "setTick(uint256)" 1` golden
- [x] Implement encode helpers + `aggregate` ABI layout
- [x] Tests green; commit

### Task 2: Wire GDX path to setTick calldata

**Files:** Modify `src/GdxCsv.idr`.

**Produces:** Param rows → `abiMethodSetTick` (parse Val as Integer); set rows skipped for Tick demo; `target` from `TICK_ADDRESS` env when set.

- [x] Failing test: param `3` → golden `setTick(3)`
- [x] Implement; commit

### Task 3: Idris Anvil JSON-RPC client (minimal)

**Files:** Create `src/AnvilRpc.idr`, `src/AnvilTickSmoke.idr`; `just anvil-tick-smoke`.

**Produces:** `eth_call` / `eth_sendTransaction` via curl+JSON to `ANVIL_RPC_URL`; smoke reads `TICK_ADDRESS` / `MULTICALLER_ADDRESS`, `aggregate` with targets all = Tick and ≥2 Idris `setTick` datas, exit 0 on success.

- [x] Implement; fail closed if Anvil down; commit

### Task 4: Foundry subdirectory + Plank Tick + Multicaller

**Files:** Create `evm/` (foundry.toml, Multicaller dep/deploy, tests); Plank source `src/Tick.plk`.

**Locked:** Tick is **Plank** (`src/Tick.plk`), not Solidity. Transient storage for mid-tx reads. Batching via **Multicaller** `aggregate`: same Tick in every `targets[i]`, Idris bytes in `data[i]`.

**Produces:**
- `src/Tick.plk`: `setTick(uint256)`, `readTick() → uint256` against transient storage; **`SetTick(uint256 tick)` event** on each `setTick`
- Multicaller available on Anvil (canonical CREATE2 or forge deploy)
- Deploy + write `build/anvil-addresses.json` (`TICK_ADDRESS`, `MULTICALLER_ADDRESS`)
- Test mid-tx reads via transient storage: after setTick(1) read==1; after setTick(2) read==2
- Assert `SetTick` logs for each set in the aggregate (forge `vm.expectEmit` / receipt topics)

- [x] Scaffold; implement; `just evm-tick-test`; commit

### Task 5: Integrate + docs

- [x] Wire just recipes; update Types.spec/README; push PR follow-on to #13/#14

## Verification

| Check | Command |
|-------|---------|
| ABI goldens | abi / gdx-consume tests |
| Forge mid-tx | `just evm-tick-test` |
| Idris RPC | `just anvil-tick-smoke` |
