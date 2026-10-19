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

Handshake / ACK for “comptime load succeeded” is **out of scope** here — see [issue #4](https://github.com/JMSBPP/gams-evm-transport/issues/4) (GdxComptimeHandshake).

### Smoke test

From repo root:

```bash
just gdx-writer-smoke
```

Expects exit 0 and `utils/build/gdx_writer_smoke.gdx`.
