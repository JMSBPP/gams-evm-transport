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
