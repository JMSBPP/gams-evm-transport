dispatcher:
    mkdir -p lib/exec
    cc -fPIC -shared -o lib/exec/CommandDispatcher.so stdin/CommandDispatcher.c

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
