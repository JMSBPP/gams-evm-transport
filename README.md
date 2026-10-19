# gams-evm-transport

GAMS extrinsic `publishGdx` builds a web3 `MulticallBatch` from a GDX file and applies every Tick `setTick` call in **one** Multicaller `aggregate` transaction. Exit `0` (**Consumed**) means on-chain apply succeeded—not merely that `build/multicall-batch.json` was written.

## Prerequisites

| Tool | Role |
|------|------|
| [GAMS](https://www.gams.com/) 54+ | Model + extrinsic `publishGdx` |
| [Idris 2](https://idris2.readthedocs.io/) | `just publish-gdx` consumer service |
| [just](https://github.com/casey/just) | Recipes (`dispatcher`, `publish-gdx`, …) |
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
6. Exit `0` only if that RPC/tx succeeds

Signed param values (e.g. `-1440`) are accepted and encoded as two’s-complement wrap into `uint256` (same bits as Solidity `uint256(int256(n))`).

## Consumer quick start

### 1. Build the extrinsic library

```bash
just dispatcher
# → lib/exec/CommandDispatcher.so
```

### 2. Start Anvil and deploy Tick + Multicaller

```bash
anvil --port 8545   # leave running

cd evm
forge script script/DeployTick.s.sol:DeployTick \
  --rpc-url "${ANVIL_RPC_URL:-http://127.0.0.1:8545}" \
  --broadcast \
  --private-key "${ANVIL_PRIVATE_KEY:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}" \
  -vv
cd ..
```

Deploy writes `build/anvil-addresses.json` with `TICK_ADDRESS` and `MULTICALLER_ADDRESS`.

### 3. Export addresses for publish

```bash
export ANVIL_RPC_URL="${ANVIL_RPC_URL:-http://127.0.0.1:8545}"
export TICK_ADDRESS=$(python3 -c 'import json;print(json.load(open("build/anvil-addresses.json"))["TICK_ADDRESS"])')
export MULTICALLER_ADDRESS=$(python3 -c 'import json;print(json.load(open("build/anvil-addresses.json"))["MULTICALLER_ADDRESS"])')
# optional: ANVIL_FROM (defaults to Anvil account #0)
```

`publishGdx` fail-closes if Tick/Multicaller addresses are missing.

### 4. Call `publishGdx` from GAMS

From a model whose working directory is the repo root (so `just publish-gdx` and `build/` resolve):

```gms
$funcLibIn Commands ./lib/exec/CommandDispatcher.so
Function publishGdx /Commands.publishGdx/;

* … fill sets/parameters …
execute_unload 'build/my.gdx', mySet, myParam;

execute 'printf "%s\n" "build/my.gdx" > build/.gdx-publish-path';
Scalar publishStatus;
publishStatus = publishGdx;
abort$(publishStatus <> 0) 'publishGdx failed';
```

Reference smoke: [`stdin/PublishGdxSmoke.gms`](stdin/PublishGdxSmoke.gms).

```bash
# with Anvil up and env from step 3:
just publish-gdx-smoke
```

### 5. Inspect the batch artifact (optional)

On success, `build/multicall-batch.json` looks like:

```json
{"calls":[{"target":"0x…","data":"0xfb972e51…"}, …]}
```

Useful for off-chain inspection; **not** sufficient for Consumed by itself.

## Environment variables

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `TICK_ADDRESS` | yes | — | Tick contract for `setTick` / aggregate targets |
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
| `just publish-gdx` | Run Idris publish service once (needs path file + env) |
| `just publish-gdx-smoke` | End-to-end GAMS smoke (needs Anvil + addresses) |
| `just gdx-consume-test` | Idris unit tests (ABI / GdxCsv / batch) |
| `just evm-tick-test` | Foundry mid-tx Tick + Multicaller tests |
| `just anvil-tick-smoke` | Deploy + Idris aggregate smoke (hardcoded ticks) |

GAMS unload helpers: see [`utils/README.md`](utils/README.md) (`GdxWriter`, `GdxComptimeHandshake`).

## Spec pointer

Formal EF / Consumed contract: [`.spec/GamsStdInFetcher.spec/Functional.spec/Types.spec`](.spec/GamsStdInFetcher.spec/Functional.spec/Types.spec) (`publishGdx` section).
