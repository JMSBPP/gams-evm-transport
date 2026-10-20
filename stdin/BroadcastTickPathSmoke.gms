$funcLibIn Commands ./lib/exec/CommandDispatcher.so
Function broadcast_tick_path /Commands.broadcast_tick_path/;

Set smokeSet /a,b,c/;
* Include a negative Val (TickPath-style) so signed setTick wrap is exercised.
Parameter smokeParam(smokeSet) /a 1, b -1440, c 3/;
execute_unload 'build/broadcastTickPathSmoke.gdx', smokeSet, smokeParam;
$goto gdx_handoff

$label gdx_handoff
execute 'printf "%s\n" "build/broadcastTickPathSmoke.gdx" > build/.gdx-publish-path';
Scalar publishStatus;
publishStatus = broadcast_tick_path;
abort$(publishStatus <> 0) 'broadcast_tick_path failed';
execute.checkErrorLevel 'test -f build/multicall-batch.json';
