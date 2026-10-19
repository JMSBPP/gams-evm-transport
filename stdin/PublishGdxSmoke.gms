$funcLibIn Commands ./lib/exec/CommandDispatcher.so
Function publishGdx /Commands.publishGdx/;

Set smokeSet /a,b,c/;
Parameter smokeParam(smokeSet) /a 1, b 2, c 3/;
execute_unload 'build/publishGdxSmoke.gdx', smokeSet, smokeParam;
$goto gdx_handoff

$label gdx_handoff
execute 'printf "%s\n" "build/publishGdxSmoke.gdx" > build/.gdx-publish-path';
Scalar publishStatus;
publishStatus = publishGdx;
abort$(publishStatus <> 0) 'publishGdx failed';
execute.checkErrorLevel 'test -f build/multicall-batch.json';
