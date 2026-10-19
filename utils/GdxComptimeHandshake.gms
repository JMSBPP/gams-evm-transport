$onText
==========================================================================
------------------> GdxComptimeHandshake < -----------------------------
  Two-pass Set/parameter → GDX → compile-time $load + ACK for waiters.

  Pass 2 (GDX exists): $gdxIn / $load → $batInclude gdxHandshakeWriteAck
  Pass 1 (no GDX): fill → gdxWrite → optional re-invoke → ensure ACK
    (never abort solely because ACK is missing).

  ACK contract (waiter = file presence, not GAMS exit code):
    Pass2: "GdxComptimeHandshake pass2 ACK: loaded <gdx-path>"
    Pass1 fallback: "GdxComptimeHandshake pass1 ACK: <gdx-path> written"

  Depends on GdxWriter (execution-time unload). Domain adapters stay
  in the consumer repo.
==========================================================================
$offText

$if set gdxComptimeHandshakeIncluded $goto gdx_comptime_handshake_done
$set gdxComptimeHandshakeIncluded

$include GdxWriter.gms

$label gdx_comptime_handshake_done
