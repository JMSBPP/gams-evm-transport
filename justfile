gdx-writer-smoke:
    #!/usr/bin/env bash
    set -euo pipefail
    cd utils
    mkdir -p build
    rm -f build/gdx_writer_smoke.gdx
    gams GdxWriterSmoke.gms action=ce o=build/GdxWriterSmoke.lst scrdir=build lo=2
    test -f build/gdx_writer_smoke.gdx
