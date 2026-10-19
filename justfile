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

publish-gdx:
    idris2 --source-dir src --output-dir build -o publish-gdx src/PublishGdx.idr
    build/publish-gdx

publish-gdx-smoke: dispatcher
    mkdir -p build
    gams stdin/PublishGdxSmoke.gms action=ce

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
