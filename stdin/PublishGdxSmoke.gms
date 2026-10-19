$funcLibIn Commands ./lib/exec/CommandDispatcher.so
Function publishGdx /Commands.publishGdx/;

Scalar smokeVal /1/;
execute_unload 'build/publishGdxSmoke.gdx', smokeVal;
$goto gdx_handoff

$label gdx_handoff
execute 'printf "%s\n" "build/publishGdxSmoke.gdx" > build/.gdx-publish-path';
Scalar publishStatus;
publishStatus = publishGdx;
abort$(publishStatus <> 0) 'publishGdx failed';
