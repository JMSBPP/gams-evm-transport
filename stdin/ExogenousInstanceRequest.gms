$funcLibIn Commands ./lib/exec/CommandDispatcher.so

Sets A "setA", B "setB";
$onText
Functions requestSet /CommandsDispatcher.getSet/;
A = requestSet("setA");
$offText

$onEmbeddedCode Connect:
- PythonCode:
    code: |
      import subprocess; subprocess.check_call(["just", "ping"])
$offEmbeddedCode
