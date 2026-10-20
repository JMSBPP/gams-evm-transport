# gams-evm-transport

GAMS extrinsic `broadcast_tick_path` builds a web3 `MulticallBatch` from a GDX file and applies every Tick `setTick` call in **one** Multicaller `aggregate` transaction. Exit `0` (**Consumed**) means on-chain apply succeeded—not merely that `build/multicall-batch.json` was written. On Success the service prints the Multicaller tx hash (`broadcast_tick_path ok 0x… calls=n`).

## Prerequisites

| Tool | Role |
|------|------|
| [GAMS](https://www.gams.com/) 54+ | Model + extrinsic `broadcast_tick_path` |
| [Idris 2](https://idris2.readthedocs.io/) | `just broadcast_tick_path` consumer service |
| [just](https://github.com/casey/just) | Recipes (`dispatcher`, `broadcast_tick_path`, …) |
| [Foundry](https://book.getfoundry.sh/) (`anvil`, `forge`) | Local chain + Tick/Multicaller deploy |
| `gdxdump` | Shipped with GAMS; used by the Idris GDX path |
| `curl` | JSON-RPC from Idris |

Run all `just` recipes from the **repository root**.

## What Consumed means

1. Read GDX path from `build/.gdx-publish-path`
2. `gdxdump` CSV → ordered `{target, data}[]` (`MulticallBatch`)
3. Param rows → Tick `setTick(uint256)` calldata (sets skipped)
4. Write `build/multicall-batch.json` (artifact)
5. `eth_sendTransaction` Multicaller `aggregate` with every target = Tick
6. Print the tx hash and call count; exit `0` only if that RPC/tx succeeds

Signed param values (e.g. `-1440`) are accepted and encoded as two’s-complement wrap into `uint256` (same bits as Solidity `uint256(int256(n))`).

## Consumer quick start

The only hard requirement is global env: `APP_ADDRESS`, `MULTICALLER_ADDRESS`, and (if not default) `ANVIL_RPC_URL`. `broadcast_tick_path` fail-closes if those addresses are missing.

### Call `broadcast_tick_path` from GAMS

From a model whose working directory is the repo root (so `just broadcast_tick_path` and `build/` resolve):

```gms
$funcLibIn Commands ./lib/exec/CommandDispatcher.so
Function broadcast_tick_path /Commands.broadcast_tick_path/;

* … fill sets/parameters …
execute_unload 'build/my.gdx', mySet, myParam;

execute 'printf "%s\n" "build/my.gdx" > build/.gdx-publish-path';
Scalar publishStatus;
publishStatus = broadcast_tick_path;
abort$(publishStatus <> 0) 'broadcast_tick_path failed';
```

Reference smoke: [`stdin/BroadcastTickPathSmoke.gms`](stdin/BroadcastTickPathSmoke.gms).

```bash
just broadcast_tick_path-smoke
```

### Inspect the batch artifact (optional)

On success, `build/multicall-batch.json` looks like:

```json
{"calls":[{"target":"0x…","data":"0xfb972e51…"}, …]}
```

Useful for off-chain inspection; **not** sufficient for Consumed by itself. The processed Multicaller tx hash is on stdout.

## Environment variables

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `APP_ADDRESS` | yes | — | App contract for `setTick` / aggregate targets |
| `MULTICALLER_ADDRESS` | yes | — | Vectorized Multicaller for `aggregate` |
| `ANVIL_RPC_URL` | no | `http://127.0.0.1:8545` | JSON-RPC endpoint |
| `ANVIL_FROM` | no | Anvil account #0 | `eth_sendTransaction` `from` |
| `ANVIL_PRIVATE_KEY` | deploy only | Anvil #0 key | Foundry deploy broadcast |

## GDX → calldata rules (Tick demo)

- **Parameters** → one `setTick` call per param row (order preserved)
- **Sets** → skipped
- Val must be a signed decimal integer string (`3`, `-1440`); otherwise the row is dropped
- Empty batch after filtering → Failed (nonzero)

Domain adapters (e.g. TickPath handoff labels) live in the consumer repo; this transport only needs a GDX path in `build/.gdx-publish-path`.

## Related recipes

| Recipe | What it does |
|--------|----------------|
| `just dispatcher` | Build `CommandDispatcher.so` |
| `just broadcast_tick_path` | Run Idris broadcast service once (needs path file + env) |
| `just broadcast_tick_path-smoke` | End-to-end GAMS smoke (needs Anvil + addresses) |
| `just gdx-consume-test` | Idris unit tests (ABI / GdxCsv / batch) |
| `just evm-tick-test` | Foundry mid-tx Tick + Multicaller tests |
| `just anvil-tick-smoke` | Deploy + Idris aggregate smoke (hardcoded ticks) |

GAMS unload helpers: see [`utils/README.md`](utils/README.md) (`GdxWriter`, `GdxComptimeHandshake`).

## Spec pointer

Formal EF / Consumed contract: [`.spec/GamsStdInFetcher.spec/Functional.spec/Types.spec`](.spec/GamsStdInFetcher.spec/Functional.spec/Types.spec) (`broadcast_tick_path` section).
