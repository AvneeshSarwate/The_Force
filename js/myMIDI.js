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

var midiDeviceName = null;

var velocitySequence = new Array();
var lastMatchedPattern = -1;



var midiEventHandlers = {};
var midiFeatures = arrayOf(10);
var pitchSequences = arrayOf(16).map(n => []); //sequence per midi channel 

//defined in midiPatterns.js
var patterns = [];


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
        if(patterns[ind].responseFunc && isMatched){
            patterns[ind].responseFunc(now);
        }
        else { 
            if(isMatched){ //TODO - remove hardcoding for param5 for responsevis1
                setSliderVal(param, param == 5 ? 0 : target);
            } else {
                var latestPatternTriggeredForParam = patterns.map((p, i) => ({p, i})).filter(pat => pat.p.paramNum === param).sort((p1, p2) => -(p1.p.lastMatched-p2.p.lastMatched))[0].i
                var lastPat = patterns[latestPatternTriggeredForParam];

                if(latestPatternTriggeredForParam === ind && lastPat.lastMatched > 0){
                    var lastPat = patterns[latestPatternTriggeredForParam];
                    var rampCompletion = (now - lastPat.lastMatched)/lastPat.fadeTime;
                    if(rampCompletion < 1){
                        var valInterpolation = mixn(lastPat.paramTarget, sliderConfig[lastPat.paramNum].conf.value, rampCompletion);
                        if(isNaN(valInterpolation)){
                            console.log("nan val", param);
                        }
                        setSliderVal(param, lastPat.curve ? lastPat.curve(rampCompletion) : valInterpolation);
                    }
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
    var midiDeviceNombre = usingVJPad ? "IAC Driver Bus 2" : null;
    midiDeviceNombre = usingXkey ? "Xkey" : midiDeviceNombre;

    midiDeviceName = midiDeviceName ? midiDeviceName : midiDeviceNombre;

    console.log(midiDeviceNombre, midiName);  

    var useAllDevices = true;  
    useAllDevices = !midiDeviceName;

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
    // console.log("MIDI EVENT", chan, midiNote, midiVel);

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
    if(midiEventHandlers[eventKey]) midiEventHandlers[eventKey](midiNote, midiVel, chan);
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
