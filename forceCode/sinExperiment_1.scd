(
var sinwav = {|fr,ph,am,sh, time| (sin((pi*fr*time)+ph)*am)+sh};
var coswav = {|fr,ph,am,sh, time| (cos((pi*fr*time)+ph)*am)+sh};

var sqr = {|time| var tm = time%2; if(tm<1, 1, -1)};
var sqrwav = {|fr,ph,am,sh, time| (sqr.((fr*time)+ph)*am)+sh};

var saw = {|time| var tm = time%2; tm-1};
var sawwav = {|fr,ph,am,sh, time| (saw.((fr*time)+ph)*am)+sh};

var tri = {|time| var tm = time%2; case {tm<0.5} {2*tm} {tm<1.5} {2-(2*tm)} {tm>=1.5} {2*tm-4}};
var triwav = {|fr,ph,am,sh, time| (tri.((fr*time)+ph)*am)+sh};


n = NetAddr("localhost", 7500);

t = TempoClock.new(0.125);
~w1 = 0.01;
~w2 = 0.01;
Task({
    {
        n.sendMsg("/msg2", (t.beats).sin, (t.beats).cos, 0, 0);
        (0..4).do({|i|
            n.sendMsg("/p"++i, (t.beats+i).sin, (t.beats-i).cos, 0, 0);
        });
        [t.beats.sin, t.beats.cos].postln;
        ~w1.wait;
    }.loop
}, t).play;

Task({
    {
        n.sendMsg("/takeSnapshot", (t.beats).sin, (t.beats).cos, 0, 0);
        [t.beats, "snapshot"].postln;
        ~w2.wait;
    }.loop
}, t).play;

)

(
n = NetAddr("localhost", 7500);

t = TempoClock.new(1);

Task({
    var ind = 0.0;
    {
        ind = (ind+1.0) % 3.0;
        n.sendMsg("/rot", ind + 0.01, 0, 0, 0);
        ind.postln;
        0.1.wait;
    }.loop
}, t).play;

)

SuperDirt.start
Platform.userExtensionDir
Quarks.gui
SuperDirt.browse