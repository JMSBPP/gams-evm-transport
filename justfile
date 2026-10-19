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
    # Idris2 accepts one --source-dir; link library modules into test/src for imports.
    for m in Abi AbiMethod MulticallBatch GdxCsv; do
      ln -sfn "../../src/${m}.idr" "test/src/${m}.idr"
    done
    idris2 --source-dir test/src --output-dir build -o gdx-consume-test test/src/Main.idr
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

# Foundry/Plank Tick + Multicaller mid-tx tests
evm-tick-test:
    #!/usr/bin/env bash
    set -euo pipefail
    cd evm
    forge test --match-contract TickTest -vv

# Build Idris Anvil smoke binary
anvil-tick-smoke-build:
    idris2 --source-dir src --output-dir build -o anvil-tick-smoke src/AnvilTickSmoke.idr

# Deploy Tick+Multicaller to Anvil and run Idris aggregate smoke
anvil-tick-smoke: anvil-tick-smoke-build
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p build
    if ! curl -sS -X POST -H 'Content-Type: application/json' \
         --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}' \
         "${ANVIL_RPC_URL:-http://127.0.0.1:8545}" >/dev/null 2>&1; then
      echo "Anvil not reachable at ${ANVIL_RPC_URL:-http://127.0.0.1:8545}; start anvil first" >&2
      exit 1
    fi
    cd evm
    forge script script/DeployTick.s.sol:DeployTick --rpc-url "${ANVIL_RPC_URL:-http://127.0.0.1:8545}" \
      --broadcast --private-key "${ANVIL_PRIVATE_KEY:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}" -vv
    cd ..
    TICK_ADDRESS=$(python3 -c 'import json;print(json.load(open("build/anvil-addresses.json"))["TICK_ADDRESS"])')
    MULTICALLER_ADDRESS=$(python3 -c 'import json;print(json.load(open("build/anvil-addresses.json"))["MULTICALLER_ADDRESS"])')
    export TICK_ADDRESS MULTICALLER_ADDRESS
    export ANVIL_RPC_URL="${ANVIL_RPC_URL:-http://127.0.0.1:8545}"
    build/anvil-tick-smoke
