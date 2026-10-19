$title GdxComptimeHandshakeSmoke
$include GdxComptimeHandshake.gms

$if not exist build/handshake_smoke.gdx $goto hs_pass1

$gdxIn build/handshake_smoke.gdx
Set DemoSet(*);
Parameter DemoParam(*);
$load DemoSet DemoParam
$gdxIn
$batInclude gdxHandshakeWriteAck.gms build/handshake_smoke.ack "GdxComptimeHandshake pass2 ACK: loaded build/handshake_smoke.gdx"
$goto hs_done

$label hs_pass1
Set DemoSet / a, b /;
Parameter DemoParam(DemoSet);
DemoParam('a') = 1;
DemoParam('b') = 2;
gdxWrite('build/handshake_smoke.gdx') DemoSet, DemoParam;
execute.checkErrorLevel 'gams GdxComptimeHandshakeSmoke.gms action=ce o=build/GdxComptimeHandshakeSmoke_pass2.lst scrdir=build lo=2';
$batInclude gdxHandshakeEnsureAck.gms build/handshake_smoke.ack "GdxComptimeHandshake pass1 ACK: build/handshake_smoke.gdx written"
$label hs_done
