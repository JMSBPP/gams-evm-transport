# GAMS utils

## GdxWriter

Execution-time GDX unload helper. Unload runs via `execute_unload` — **not** compile-time `$gdx*`.

### API

```gms
$include GdxWriter.gms

* fill symbols at execution time …
gdxWrite('build/foo.gdx') Sym1, Sym2;
```

Expands to `execute_unload 'build/foo.gdx', Sym1, Sym2;`. Paths resolve against the GAMS working directory. Run with `action=ce` so unload executes.

### Two-pass consumer pattern

1. **Pass 1 (execution):** fill sets/parameters → `gdxWrite` → GDX on disk.
2. **Later:** recompile with `$gdxIn` / `$load`, or let an external process read the GDX.

For GDX-gated `$load` plus an ACK file for external waiters, use **GdxComptimeHandshake** below.

### Smoke test

From repo root:

```bash
just gdx-writer-smoke
```

Expects exit 0 and `utils/build/gdx_writer_smoke.gdx`.

## GdxComptimeHandshake

Two-pass helper: fill → GDX (via GdxWriter) → compile-time `$load` → ACK so an external job can wait on “comptime load succeeded.”

`$include GdxComptimeHandshake.gms` pulls in GdxWriter. Domain adapters (e.g. TickPath) stay in the consumer repo.

### Two-pass gate

```gms
$include GdxComptimeHandshake.gms

$if not exist build/foo.gdx $goto pass1

$gdxIn build/foo.gdx
* declare symbols, then:
$load Sym1 Sym2
$gdxIn
$batInclude gdxHandshakeWriteAck.gms build/foo.ack "GdxComptimeHandshake pass2 ACK: loaded build/foo.gdx"
$goto done

$label pass1
* fill symbols …
gdxWrite('build/foo.gdx') Sym1, Sym2;
* optional: re-invoke GAMS on this file so pass 2 runs
$batInclude gdxHandshakeEnsureAck.gms build/foo.ack "GdxComptimeHandshake pass1 ACK: build/foo.gdx written"
$label done
```

### `$batInclude` APIs

| Include | When | Behavior |
|---------|------|----------|
| `gdxHandshakeWriteAck.gms <ack> "<msg>"` | Pass 2 after `$load` | Compile-time `$echo` ACK |
| `gdxHandshakeEnsureAck.gms <ack> "<msg>"` | Pass 1 after unload/re-invoke | Write ACK only if missing; **never abort** on absence |

### ACK contract

- Waiter policy: **ACK file presence** (not GAMS exit code).
- Prefer pass-2 ACK when re-invoke succeeds; pass-1 message is fallback only.
- Typical messages:
  - Pass 2: `GdxComptimeHandshake pass2 ACK: loaded <gdx-path>`
  - Pass 1: `GdxComptimeHandshake pass1 ACK: <gdx-path> written`

### Smoke test

From repo root:

```bash
just gdx-comptime-handshake-smoke
```

Expects exit 0, `utils/build/handshake_smoke.gdx`, and `utils/build/handshake_smoke.ack` (pass-2 ACK line after re-invoke).
