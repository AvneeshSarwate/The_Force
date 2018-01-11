
(
var forcePort = NetAddr("localhost", 7500);
(1..4).do({|ind|
    OSCFunc({|msg, time, addr, recvPort|
        forcePort.sendRaw([msg[0], msg[2], msg[1], 0,0].asArray.asRawOSC);
    }, "/touch/"++ind);
});
)
