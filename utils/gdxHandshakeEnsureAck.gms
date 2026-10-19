* $batInclude gdxHandshakeEnsureAck.gms <ackPath> "<message>"
* Execution-time: write ACK only if missing; never abort on absence.
file gdxHandshakeAckFile / '%1' /;
execute 'test -f "%1"';
if(errorLevel <> 0,
   put gdxHandshakeAckFile '%2' /;
   putclose gdxHandshakeAckFile;
);
