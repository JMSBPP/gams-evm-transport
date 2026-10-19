# Design: GDX MulticallBatch → Anvil Tick via ABI + Plank/Foundry

**Date:** 2026-10-19  
**Status:** Approved (chat)  
**Builds on:** Issue #13 / PR #14 (`MulticallBatch` file handoff)

## Problem

`publishGdx` today builds a web3-shaped `{target, data}[]` but `data` is smoke UTF-8 hex, `target` is a placeholder, and nothing is sent to a chain. We need real ABI calldata and a deploy/send/assert path against Anvil.

## Goals

1. **Idris:** Minimal HEVM-inspired ABI encode (`abiMethod`, `uint256`, `bytes`, `address[]`, `bytes[]`, `uint256[]`) sufficient for `setTick` / `readTick` / Multicaller `aggregate`.
2. **Idris:** Anvil JSON-RPC smoke (`eth_call` / `eth_sendTransaction`) using that encoding.
3. **Foundry subdirectory** (template: plank-foundry-deployer): Plank `src/Tick.plk` (transient storage) + Multicaller; assert mid-transaction `readTick` sees updates.
4. Integration: forge broadcasts addresses; Idris smoke consumes them; golden calldata vectors shared.

## Non-goals

- Full HEVM port or Haskell dependency in-tree.
- Changing GdxWriter / GdxComptimeHandshake.
- Domain TickPath / plank Tx beyond this Tick demo.
- Replacing the GAMS EF sidecar contract.

## Architecture

```text
GDX → gdxdump CSV → tick values
       → Idris Abi (HEVM-min) → MulticallBatch / aggregate data[] (setTick blobs)
       → Idris Anvil JSON-RPC smoke → Multicaller.aggregate(targets=Tick…, data=…)
Foundry/Plank subdir → deploy Tick + Multicaller on Anvil
                     → assert mid-tx readTick
```

### Tick (Plank EVM)

- Source: `src/Tick.plk` (Plank, not Solidity).
- State: `tick` in a **transient storage** slot (EIP-1153); mid-tx `readTick` sees updates within the same transaction.
- API: `setTick(uint256)`, `readTick() → uint256`.
- Events: `setTick` emits `SetTick(uint256 tick)` (indexed or not — Plank default; plan locks signature for forge/cast checks).
- Deployed via `PlankDeployer` FFI pattern from plank-foundry-deployer.

### Multicall (Vectorized Multicaller)

- Use [Vectorized Multicaller](https://github.com/Vectorized/multicaller) (canonical CREATE2, or forge-deployed for Anvil): `aggregate(address[] targets, bytes[] data, uint256[] values, address refundTo)`.
- For Tick demo: every `targets[i]` is the **same Tick address**; `data[i]` is Idris-encoded ABI calldata (`setTick` / `readTick`); `values` all zero; `refundTo` as needed (e.g. `address(0)`).
- Mid-tx observation: Tick uses transient storage, so interleaved `readTick` entries in the same `aggregate` observe intermediate values; no post-tx storage probe required for the progression assert.
- Idris MulticallBatch / RPC smoke builds the Multicaller call (not a thin `TickMulticall` wrapper).

### Idris ABI (HEVM reference)

Reference: [hevm `EVM.ABI`](https://hackage.haskell.org/package/hevm/docs/EVM-ABI.html) — `abiMethod`, `encodeAbiValue`, int-likes left-padded to 32 bytes, dynamic `bytes`/`bytes[]` head/tail layout.

Minimum surface:

| Op | Encoding |
|----|----------|
| `setTick(uint256)` | `selector` + ABI uint256 |
| `readTick()` | `selector` |
| `aggregate(address[],bytes[],uint256[],address)` | Multicaller entry: parallel arrays; Tick demo repeats Tick in `targets` |

Replace [`GdxCsv.encodeData`](../../../src/GdxCsv.idr) smoke path when producing Tick multicalls.

### Idris Anvil RPC

- Endpoint: Anvil HTTP (e.g. `http://127.0.0.1:8545`).
- Load Tick + Multicall addresses from env or forge broadcast artifact.
- Send multicall; fail smoke on RPC error or revert.
- Recipe: `just anvil-tick-smoke` (distinct from GAMS `publish-gdx-smoke` until wired).

### Foundry subdirectory

- New tree under repo (e.g. `evm/`) modeled on plank-foundry-deployer: `PlankDeployer`, forge-std, anvil.
- Plank Tick at `src/Tick.plk` (transient storage); Multicaller for batching.
- Tests deploy, `aggregate` with repeated Tick + `setTick` datas, assert `readTick` progression mid-tx via transient storage.

## Success criteria

- [ ] Golden hex for `setTick(1)` matches `cast calldata "setTick(uint256)" 1` (or HEVM equivalent).
- [ ] Idris Anvil smoke: multicall ≥2 `setTick`s succeeds against live Anvil + deployed contracts.
- [ ] Foundry test: mid-tx read observes tick updates as specified; `SetTick` events emitted for each `setTick`.
- [ ] Docs/Types.spec note: file `MulticallBatch` vs on-chain smoke are separate Consumed vs optional RPC verify.

## Open implementation details (fixed in plan)

- **Locked:** Vectorized **Multicaller** `aggregate(targets, data, values, refundTo)`. Tick is Plank `src/Tick.plk` (transient storage). Idris fills `data[]`; Anvil smoke / Foundry tests pass `targets = [Tick, Tick, …]`.
