1,A model requests an instance of its exogenous parameters and its indexes.

Let's tackle indexes first. What is the index key like ?
1. model defines its index keys
   1.1 model creates its index keys
\[
       \begin{aligned}
           I_K : [i_1, i_2]    
       \end{aligned}
\]

   1.2 model requests an index key
I_K = \{i,j\}


## [int querylibrary(int funcnr, int query, int *iv, const char **pv)](@stdin/CommandDispatcher.c)

is a description callback.

- GAMS calls `querylibrary` once per question.  ----> What is a question ?
- `querylibrary` writes the answer  through `iv` and `pv` ---> where does it write it ?
- `querylibrary`reports success or failure with its return value.

- The arguments and the result codes are defined in `extrfunc.h`, which the trigonometric example `tricclibql.c` implements. --> We need to study that case , is there a `*.h` library we can import then 
- `funcnr`::  selects what is being described:
   - `funcnr <= 0` asks about the library as a whole.
   - `funcnr = {1, 2, 3, …}` asks about that function.
         > Function numbers are assigned by the library and must match the count it reports.

- `query (funcnr)` :: selects which fact GAMS wants.
> The same integer means different questions depending on `funcnr`.

For a library query the codes are `EXTRFUNC_LIBQUERY`. For a function query they are `EXTRFUNC_FUNCQUERY`.

- `iv (query)` ::  GAMS passes a pointer. The callback stores one integer there.
> What that integer means depends on `query`.

- `pv` ::  GAMS passes a pointer to a C string pointer.
   - The callback stores either a string or `NULL`.
   - The string must stay valid after the call returns; the example uses string literals.

When `funcnr <= 0`, `query` is one of these:

| `query` | Name | `*iv` | `*pv` |
| --- | --- | --- | --- |
| 0 | API version | API version; the trigonometric library writes `2` | `NULL` |
| 1 | Library version and vendor | library version number | vendor name |
| 2 | Number of functions | how many functions the library provides | a short description of the library |
| 3 | License check | `0` if no GAMS license check is required, otherwise nonzero | `NULL` |

When `funcnr` is a function number, `query` is one of these:

| `query` | Name | `*iv` | `*pv` |
| --- | --- | --- | --- |
| 1 | Function name | unused (`0` in the example) | the name used after the dot in `Function f /Commands.name/` |
| 2 | Description | unused | explanatory text |
| 3 | Not in equations | `1` if the function must not appear in an equation, `0` if it may | `NULL` |
| 4 | Continuous derivative | `1` if the derivative is continuous, `0` otherwise | `NULL` |
| 5 | Zero at the origin | `1` if the function value is zero at the origin | `NULL` |
| 6 | Minimum arguments | smallest number of arguments | `NULL` |
| 7 | Maximum arguments | largest number of arguments, at most 20 | `NULL` |
| 8 | Highest derivative | `0` value only, `1` gradient, `2` Hessian | `NULL` |
| 1001–1020 | Argument 1 through 20 | `1` if that argument may be an endogenous variable, `0` if it must be a constant | the argument’s name |

The example begins every call with `*iv = -1` and `*pv = "Bad parameter(s)"`, then overwrites both when it recognizes the question.

## [broadcast_tick_path](@stdin/CommandDispatcher.c)

Extrinsic function `Function broadcast_tick_path /Commands.broadcast_tick_path/;` (library function number 1).

- Not usable in equations (`NOTINEQU = 1`).
- Zero numeric arguments (`ARGMIN = ARGMAX = 0`, `MAXDERIV = 0`). GAMS extrinsic callbacks only pass `double` arguments, so the GDX path is **not** an EF argument.
- Path contract: immediately before the call, the caller writes a single-line path (absolute or cwd-relative) to `build/.gdx-publish-path`.
- Evaluation blocks until an opaque external service reports consumed (via `just broadcast_tick_path`); the scalar return is `0` = Consumed, nonzero = Failed.
- **Consumed** means the full job finished: GDX path from sidecar → `gdxdump` CSV → ordered `MulticallBatch` (`{target, data}[]`) **and** one Multicaller `aggregate` tx successfully applied every batch call (`applyOnChain` Success). Param rows encode as Tick `setTick(uint256)` calldata; set rows skipped for the Tick demo. Signed param Vals (optional leading `-`) encode as two's-complement wrap into uint256 (\(n \bmod 2^{256}\)), same bits as Solidity `uint256(int256(n))`. Intermediate steps (file presence, dump alone, JSON alone) are **not** success.
- On success the service writes `build/multicall-batch.json` (artifact), completes on-chain apply, and prints `broadcast_tick_path ok <txHash> calls=<n>` (`eth_sendTransaction` result). Requires live RPC + `APP_ADDRESS` / `MULTICALLER_ADDRESS` (env or deploy addresses).
- Generic smoke handoff label: `gdx_handoff` (domain adapters may use names like `tickpath_handoff`).
- Interchange: GAMS 54 `gdxdump` CSV (locked after spike for index-ordered elements).
- Tick demo contracts: Plank `src/Tick.plk` (transient storage + `SetTick` event); Vectorized Multicaller for batching (`just evm-tick-test`).
