var midi = null; // global MIDIAccess object
var midiIn = null;
var midiOut = null;
var midiData = Array.apply(null, Array(128)).map(function() {
    return 0; });
var arrayOf = n => Array.from(new Array(n), () => 0);
var chroma = Array.from(new Array(12), () => 0);
var onNoteSet = new Set();
var pitchClassToColor = {};
var noteInfo = {velocity: {}};
var vjPadNoteInfo = arrayOf(16).map(() => ({'notes':arrayOf(128).map(() => ({'vel':0, 'lastVel':0})), 'last':0}) )

var usingVJPad = window.location.href.split("?")[1].split("&")[1] == 'vjPad';
var usingXkey = window.location.href.split("?")[1].split("&")[1] == 'Xkey';

var noteOnEventCount = 0;
var noteOffEventCount = 0;
var lastNoteOnTime = arrayOf(128);
var lastNoteValue = 0;
var lastVelocity = 0;
var lastNoteOffTime = arrayOf(128);
var midiOnEventFlag = false;
var midiOffEventFlag = false;
var midiCC = arrayOf(128);
var noteEvents = [];


var velocitySequence = new Array();
var lastMatchedPattern = -1;



var midiEventHandlers = {};
var midiFeatures = arrayOf(10);
var pitchSequences = arrayOf(16).map(n => []); //sequence per midi channel 

//lets you write a regex but use "-a" as a shorthand for a midi-note wildcard.
//this function recompiles the regex into a standard one
var buildRegex = rgx => new RegExp(rgx.toString().slice(1, -1).replace(/-a/g, "(-\\d{1,3})")+"$");
var br = buildRegex;
var patterns = [
    // {chan:0, paramNum: 1, paramTarget: 0, fadeTime: 3, lastMatched: -1, seq: [80, 79, 77]},
    // {chan:0, paramNum: 1, paramTarget: 0, fadeTime: 3, lastMatched: -1, regex: br(/-80-a{1,3}-79-a{1,3}-77/)},
    // {chan:0, paramNum: 3, paramTarget: .3, fadeTime: 3, lastMatched: -1, seq: [46]},
    // {chan:0, paramNum: 3, paramTarget: .4, fadeTime: 3, lastMatched: -1, regex: br(/-46-a{1,10}-48/)},
    // {chan:0, paramNum: 3, paramTarget: .5, fadeTime: 3, lastMatched: -1, regex: br(/-46-a{1,3}-48-a{1,3}-48/)},
    // {chan:1, paramNum: 5, paramTarget: .4, fadeTime: 1, lastMatched: -1, regex: br(/-60-a{1,3}-62-a{1,3}-63/)},
    // {chan:1, paramNum: 6, paramTarget: .9, fadeTime: 0.5, lastMatched: -1, regex: br(/-62-a{1,3}-64/)},
    // {chan:1, paramNum: 5, paramTarget: .4, fadeTime: 0.5, lastMatched: -1, regex: br(/-63-a{1,3}-68-a{1,3}-67/)},

    // {chan:0, paramNum: 0, paramTarget: .8, fadeTime: .8, lastMatched: -1, regex: br(/-50/)},
    {chan:0, paramNum: 1, paramTarget: .8, fadeTime: .8, lastMatched: -1, regex: br(/-52/)},    
    {chan:0, paramNum: 1, paramTarget: .8, fadeTime: .8, lastMatched: -1, regex: br(/-52/)},
    {chan:0, paramNum: 2, paramTarget: 1, fadeTime: 4, lastMatched: -1, regex: br(/-57-59-60/)},
    {chan:0, paramNum: 0, paramTarget: .4, fadeTime: 2, lastMatched: -1, regex: br(/-60-57/)},
    {chan:0, paramNum: 0, paramTarget: .4, fadeTime: 2, lastMatched: -1, regex: br(/-55/)},
    {chan:0, paramNum: 3, paramTarget: .9, fadeTime: 6, lastMatched: -1, regex: br(/-69-67-65/)},
];
//single note sequence, (or a particular chord/cadence) for impact shots
//drum patterns, esp if playing in layers, as one shots for "pulse"
/*have each note (or each prefix, or segment ending on a target note) of an ascending phrase be mapped to higher and higher
values of the same parameter, so the speed at which you go thru maps to the animation
*/
/*make your animation such that certain patterns/parameters are localized to different areas of the screen,
or are mapped to different moving objects/areas
*/
/*can combine the previous two ideas to have some patterns move an area, and some patterns animate it - a "gesture"*/
/*think of playing with matematical combinations of some parameters (with different targets and decay times) as
a single "number" - eg motion via (param1+param2+param3) - could get interesting "dancy" movement if the tirggers are set up right
*/
/*
control uniforms via parameters - different time streams (finally allowing you to properly slow down/speed up time), random walks
where force is the random variable (for different forces, switch probabilities, etc)
*/
/*if you have a loop and want an animation to start at the "beginning" - rotate the template of the sequence to have the first note
at the end. 
*/
/*watch out for race conditions - eg, two sequences both and during an animation frame, so one of the two doesn't get triggered.*/
/*you'll need different types of patterns for live melody playing vs stacked loops - might even have to play around with different t
ypes of match functions (eg, naive sequence match => regex => sequence state machine)
*/
/*rather than having a phrase detection jump to a target and then ramp back to the default, could have it trigger a ramp from the current
value to a target over time - this would work better for when you want a certain animation "texture" to sustain over a musical 
"texture" i.e set of loops - it only changes when specific other sequences are triggered that distrub the texture*/
/*
multiple types of pattern triggers 
- jump and return (the implemented idea)
- ramp-to-target (described above) 
- what else?
*/
/*
copied from phone notes
Music-visuals -
- musical sequences that toggle other sequences on and off 
- Can also procedurally generate sequence-param mappings (can even have them "suggested" to you via light up play on keyboard). 
- Have a hyper keyboard that generates phrases - the side buttons can be used to play generated phrases or record input to be transformed 
*/
/*
don't forget the bigger picture - responive movement to musical improve that reflects 
"something deeper" (which used to be narrative but now could be anything deeper - maybe "gesture" in the dance sense)
*/
/*
Strategies for having visuals "move" with the music (related how the music itself changes) (not mutually exclusive)
- sectional - big differences between parts - maybe even no shared "subparts" between sections
    would need to "cue" this, both visually and musically - eg a "scene" change in the looper, and then
    switching to a different shader and/or changing the pattern triggers + what parameters they control 
- thematic - elements of visuals follows some imporant melodies/themes 
- textural - no easily identifiabe "parts" of the moving image that respond independently to music,
    e.g., different balls moving with different instruments
- gestural - following "musical arcs" of some sort on a note by note level - either melodic contours 
    or something else (like what?)

could have a theme template and 
*/
var paramsToPatterns = arrayOf(10).map((elem, ind) => patterns.map((p, i) => [i, p.paramNum]).filter(ip => ip[1] == ind).map(ip => ip[0]));
var mix = (a, b, m) => (1-m)*a + m*b;
var channelHasNewNotesForAnimation = arrayOf(16).map(n => false); //"dirty checking" for new notes played on a midi channel

function matchPattern(){
    var patternMatches = [];
    var now = Date.now()/1000;

    for(var i = 0; i < patterns.length; i++){
        var pat = patterns[i];
        if(!pat) {
            patternMatches.push("noPattern");
            continue;
        }
        if(!channelHasNewNotesForAnimation[pat.chan]) {
            patternMatches.push(false);
        } else {
            var pitchSequence = pitchSequences[pat.chan];
            var patternIsMatched = true;
            if(pat.regex){
                var pitchSeqString = "-"+pitchSequence.slice(Math.max(0, pitchSequence.length-200)).join("-");
                patternIsMatched = pat.regex.test(pitchSeqString);
            } else {
                var patternSeq = pat.seq;
                var patternEndInd = patternSeq.length - 1;
                var pitchSeqEndInd = pitchSequence.length - 1;
                for(var j = 0; j < patternSeq.length; j++){
                    var seqSymbol = patternSeq[patternEndInd-j];
                    var patternIsMatched = patternIsMatched && ((pitchSequence[pitchSeqEndInd-j] == seqSymbol) || seqSymbol == -1);
                }
            }
            
            patternMatches.push(patternIsMatched);
            if(patternIsMatched) patterns[i].lastMatched = now + i*0.0001; //add epsilon so that later defined patterns in list have priority
        }
    }

    channelHasNewNotesForAnimation = channelHasNewNotesForAnimation.map(elem => false);

    patternMatches.forEach(function(isMatched, ind){
        if(isMatched === "noPattern") return;
        var param = patterns[ind].paramNum;
        var target = patterns[ind].paramTarget;
        if(isMatched){
            setSliderVal(param, target);
        } else {
            var latestPatternTriggeredForParam = patterns.map((p, i) => ({p, i})).filter(pat => pat.p.paramNum === param).sort((p1, p2) => -(p1.p.lastMatched-p2.p.lastMatched))[0].i
            var lastPat = patterns[latestPatternTriggeredForParam];

            if(latestPatternTriggeredForParam === ind && lastPat.lastMatched > 0){
                var lastPat = patterns[latestPatternTriggeredForParam];
                var rampCompletion = (now - lastPat.lastMatched)/lastPat.fadeTime;
                if(rampCompletion < 1){
                    var valInterpolation = mix(lastPat.paramTarget, sliderConfig[lastPat.paramNum].conf.value, rampCompletion);
                    setSliderVal(param, valInterpolation);
                }
            }
        }
    });

}

function onMIDISuccess(midiAccess) {
    console.log("MIDI ready!");
    midi = midiAccess; // store in the global (in real usage, would probably keep in an object instance)
    // midi.onstatechange = do something here like assign a function


    var midiName = window.location.href.split("?")[1].split("&")[1];
    usingVJPad = midiName == "vjPad";
    var midiDeviceName = usingVJPad ? "IAC Driver Bus 2" : null;
    midiDeviceName = usingXkey ? "Xkey" : midiDeviceName;
    console.log(midiDeviceName, midiName);  

    var useAllDevices = true;  
    useAllDevices = !usingVJPad;

    listInputsAndOutputs(midi);
    startLoggingMIDIInput(midiDeviceName, useAllDevices);
}

function onMIDIFailure(msg) {
    console.log("Failed to get MIDI access - " + msg);
}

function populateMIDIInSelect() {

    $('#selectMIDIIn').find('option').remove().end();
    $('#selectMIDIIn').selectmenu('refresh');

    for (var entry of midi.inputs) {
        var input = entry[1];

        if (midiIn && midiIn == input.name) {
            $('#selectMIDIIn').append('<option val="' + input.id + '" selected="selected">' + input.name + '</option>');
        } else {
            $('#selectMIDIIn').append('<option val="' + input.id + '">' + input.name + '</option>');
        }
    }
    $('#selectMIDIIn').selectmenu('refresh');
}

function midiConnectionStateChange(e) {
    console.log("connection: " + e.port.name + " " + e.port.connection + " " + e.port.state);
    populateMIDIInSelect();
}

function listInputsAndOutputs(midiAccess) {
    for (var entry of midiAccess.inputs) {
        var input = entry[1];
        console.log("Input port [type:'" + input.type + "'] id:'" + input.id +
            "' manufacturer:'" + input.manufacturer + "' name:'" + input.name +
            "' version:'" + input.version + "'");
    }

    for (var entry of midiAccess.outputs) {
        var output = entry[1];
        console.log("Output port [type:'" + output.type + "'] id:'" + output.id +
            "' manufacturer:'" + output.manufacturer + "' name:'" + output.name +
            "' version:'" + output.version + "'");
    }
}


function midiCCSliderChange(ccNum, val){
    if(3 <= ccNum && ccNum <= 6){
        $("#sliderVal"+(ccNum-3)).val(val/127);
        sliders[ccNum-3].value = val/127;
    }
}

function onMIDIMessage(event) {
    var str = "MIDI message received at timestamp " + event.timestamp + "[" + event.data.length + " bytes]: ";
    for (var i = 0; i < event.data.length; i++) {
        str += "0x" + event.data[i].toString(16) + " ";
    }
    // console.log(str);
    var midiNote = event.data[1];
    var midiVel = event.data[2]

    // Mask off the lower nibble (MIDI channel, which we don't care about)
    // var channel = ev.data[0] & 0xf;
    var chan = event.data[0] & 0x0f;
    //console.log("MIDI EVENT", chan, midiNote, midiVel);

    var eventKey; //string determining message type/number for callbacks mapped to midi messages
    var eventTime = (Date.now() - mTime) * 0.001;
    switch (event.data[0] & 0xf0) {
        case 0x90:
            if (event.data[2] != 0) { // if velocity != 0, this is a note-on message
                // noteOn(event.data[1]);
                midiData[midiNote] = 1;
                chroma[midiNote%12] = 1; 
                onNoteSet.add(midiNote);
                noteInfo.velocity[midiNote] = event.data[2];
                pitchSequences[chan].push(midiNote);
                velocitySequence.push(midiVel);
                noteEvents.push({type:'on', note: midiNote, vel: midiVel, chan: chan, time: eventTime});
                if(usingVJPad){
                    vjPadNoteInfo[chan].last = midiNote
                    vjPadNoteInfo[chan].notes[midiNote].vel = event.data[2];
                    vjPadNoteInfo[chan].notes[midiNote].lastVel = event.data[2];
                    // console.log("vjPad", chan, midiNote, event.data[2]);
                }
                lastNoteValue = midiNote;
                noteOnEventCount++;
                lastNoteOnTime[midiNote] = eventTime;
                eventKey = "on";
                channelHasNewNotesForAnimation[chan] = true;
                break;
            }
            // if velocity == 0, fall thru: it's a note-off.  MIDI's weird, y'all.
            
        case 0x80:
            // noteOff(event.data[1]);
            midiData[midiNote] = 0;
            chroma[midiNote%12] = 0; 
            noteInfo.velocity[midiNote] = 0;
            onNoteSet.delete(midiNote);
            noteEvents.push({type:'off', note: midiNote, vel: midiVel, chan: chan, time: eventTime});
            lastNoteOffTime[midiNote] = eventTime;
            if(usingVJPad) vjPadNoteInfo[chan].notes[midiNote].vel = event.data[2];
            noteOffEventCount++
            eventKey = "off";
            break;

        case 0xb0:
            midiData[event.data[1]] = event.data[2];
            midiCC[midiNote] = midiVel;
            eventKey = "cc";
            midiCCSliderChange(midiNote, midiVel)
            break;
    }
    // console.log(noteOnEventCount, noteOffEventCount);
    var matchInd = matchPattern();
    lastMatchedPattern = matchInd < 0 ? lastMatchedPattern : matchInd;

    if ($('#oscPanel').length) //onscreen
    {
        $("#MIDIMessages").html(str);
    }

    // midiFeatures = computeFeatures(noteEvents, onNoteSet, lastNoteOnTime)
    if(midiEventHandlers[eventKey]) midiEventHandlers[eventKey](midiNote, midiVel);
}

// function noteOn(noteNumber) {

// }

// function noteOff(noteNumber) {

// }

function startLoggingMIDIInput(indexOfPort, listenForAll=false) {
    if (midi) {
        for (var entry of midi.inputs) {
            var input = entry[1];
            if (input.name == indexOfPort || listenForAll) {
                input.onmidimessage = onMIDIMessage;
                console.log("Connected to: " + input.name);
                midiIn = input.name;
            } else {
                input.onmidimessage = null;
                console.log("No connection to: " + input.name);
            }
        }
        createMIDIUniforms();
    }
}

function sendMiddleC(midiAccess, portID) {
    var noteOnMessage = [0x90, 60, 0x7f]; // note on, middle C, full velocity
    var output = midiAccess.outputs.get(portID);
    output.send(noteOnMessage); //omitting the timestamp means send immediately.
    output.send([0x80, 60, 0x40], window.performance.now() + 1000.0); // Inlined array creation- note off, middle C,  
    // release velocity = 64, timestamp = now + 1000ms.
}

//converts a binary pitch chroma into a an RGB vector (4 bit color depth)
function chromaToColor(chromaArray){
    var color = [0, 0, 0];
    for(var i = 0; i < 12; i++){
        color[Math.floor(i/4)] += (chromaArray[i] === 1 ? Math.pow(2,(i%4)) : 0) / 16;
    }
    return color;
}

/*take all note that are on -> transform them into a sorted list(low to high)
-> map them to their pitchClass -> map pitch classes to colors
*/
function getNoteColors(){
    return noteArray = Array.from(onNoteSet).sort().map(n => pitchClassToColor[n%12]);
}

function getNoteVelocities(){
    return Array.from(onNoteSet).sort().map(n => noteInfo.velocity[n]);
}

(function(){
    var r = [0.1, 0.5, 1];
    var g = [0.1, 1];
    var b = [0.1, 1];
    var ind = 0;
    for(var i = 0; i < r.length; i++){
        for(var j = 0; j < g.length; j++){
            for(var k = 0; k < b.length; k++){
                pitchClassToColor[ind] = [r[i], g[j], b[k]];
                ind++;
            }
        }
    }

})();



window.addEventListener('load', function() {
    if (navigator.requestMIDIAccess)
        navigator.requestMIDIAccess().then(onMIDISuccess, onMIDIFailure);

    // System Exclusive? 
    // navigator.requestMIDIAccess( { sysex: true } ).then( onMIDISuccess, onMIDIFailure );
});
