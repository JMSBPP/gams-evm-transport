# CommandList External Function library (publishGdx API artifact for consumers)
dispatcher:
    mkdir -p lib/exec
    cc -fPIC -shared -o lib/exec/CommandDispatcher.so stdin/CommandDispatcher.c -Istdin

gams: dispatcher
    gams stdin/ExogenousInstanceRequest.gms

ping:
    #!/usr/bin/env python3
    import os, subprocess, sys, tempfile
    d = tempfile.mkdtemp()
    subprocess.check_call([sys.executable, "-m", "venv", d])
    py = os.path.join(d, "Scripts" if os.name == "nt" else "bin", "python")
    subprocess.check_call([
        py, "-c",
        "import subprocess; subprocess.check_call(['idris2','--source-dir','src','-q','-x','ping','src/Ping.idr'])",
    ])

# Regenerate schema/MulticallBatch.idr via pack dependency json-schema (madman-bob/idris2-json-schema)
gdx-schema:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p schema
    pack run json-schema -- schema/MulticallBatch.json
    # Generator emits module Main under schema/; clean API lives in src/MulticallBatch.idr

publish-gdx:
    idris2 --source-dir src --output-dir build -o publish-gdx src/PublishGdx.idr
    build/publish-gdx

gdx-consume-test:
    #!/usr/bin/env bash
    set -euo pipefail
    idris2 --source-dir src --source-dir test/src --output-dir build -o gdx-consume-test test/src/Main.idr
    build/gdx-consume-test

publish-gdx-smoke: dispatcher
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p build
    rm -f build/multicall-batch.json build/.gdx-publish-path
    gams stdin/PublishGdxSmoke.gms action=ce
    test -f build/multicall-batch.json
    grep -q '"calls"' build/multicall-batch.json

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
