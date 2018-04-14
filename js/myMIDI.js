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
var vjPadNoteInfo = arrayOf(5).map(() => ({'notes':arrayOf(16).map(() => ({'vel':0, 'lastVel':0})), 'last':0}) )

var usingVJPad = window.location.href.split("?")[1].split("&")[1] == 'vjPad';

function onMIDISuccess(midiAccess) {
    console.log("MIDI ready!");
    midi = midiAccess; // store in the global (in real usage, would probably keep in an object instance)
    // midi.onstatechange = do something here like assign a function


    var midiName = window.location.href.split("?")[1].split("&")[1];
    usingVJPad = midiName == "vjPad";
    var midiDeviceName = usingVJPad ? "IAC Driver Bus 2" : null;
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
    console.log("MIDI EVENT", chan, midiNote, midiVel);
    switch (event.data[0] & 0xf0) {
        case 0x90:
            if (event.data[2] != 0) { // if velocity != 0, this is a note-on message
                // noteOn(event.data[1]);
                midiData[midiNote] = 1;
                chroma[midiNote%12] = 1; 
                onNoteSet.add(midiNote);
                noteInfo.velocity[midiNote] = event.data[2];
                if(usingVJPad){
                    vjPadNoteInfo[chan].last = midiNote
                    vjPadNoteInfo[chan].notes[midiNote].vel = event.data[2];
                    vjPadNoteInfo[chan].notes[midiNote].lastVel = event.data[2];
                    console.log("vjPad", chan, midiNote, event.data[2]);
                }
                break;
            }
            // if velocity == 0, fall thru: it's a note-off.  MIDI's weird, y'all.
            
        case 0x80:
            // noteOff(event.data[1]);
            midiData[midiNote] = 0;
            chroma[midiNote%12] = 0; 
            noteInfo.velocity[midiNote] = 0;
            onNoteSet.delete(midiNote);
            if(usingVJPad) vjPadNoteInfo[chan].notes[midiNote].vel = event.data[2];
            break;

        case 0xb0:
            midiData[event.data[1]] = event.data[2];
            break;
    }

    if ($('#oscPanel').length) //onscreen
    {
        $("#MIDIMessages").html(str);
    }
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
