gdx-writer-smoke:
    #!/usr/bin/env bash
    set -euo pipefail
    cd utils
    mkdir -p build
    rm -f build/gdx_writer_smoke.gdx
    gams GdxWriterSmoke.gms action=ce o=build/GdxWriterSmoke.lst scrdir=build lo=2
    test -f build/gdx_writer_smoke.gdx

gdx-comptime-handshake-smoke:
    #!/usr/bin/env bash
    set -euo pipefail
    cd utils
    mkdir -p build
    rm -f build/handshake_smoke.gdx build/handshake_smoke.ack
    gams GdxComptimeHandshakeSmoke.gms action=ce o=build/GdxComptimeHandshakeSmoke.lst scrdir=build lo=2
    test -f build/handshake_smoke.gdx
    test -f build/handshake_smoke.ack
