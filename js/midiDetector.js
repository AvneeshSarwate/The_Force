

/* features
average speed between hits
exact pitch sequence matching
time since each note



*/



function getSeenPitches(windowedEventList, onNotes){
    var seenNotes = new Set();
    windowedEventList.forEach(function(evt){
        if(evt.type === 'on') seenNotes.add(evt.note);
    });
    seenNotes = seenNotes.union(onNotes);
    return seenNotes;
}

var midiTimeWindow = 20;
function windowEventList(eventList, windowTime){
    var len = eventList.length;
    var offset = 0;
    var currentTime = (Date.now() - mTime) * 0.001;
    while(len-offset-1 > -1 && eventList[len-offset-1].time >= currentTime - windowTime){
        offset++;
    }
    return eventList.slice(len-offset);
}

function splitHands(windowedEventList, onNotes){
    var seenNotes = getSeenPitches(windowedEventList, onNotes);
    seenNotes = Array.from(seenNotes).sort();

    var distToNextNote = [];
    for(var i = 0; i < seenNotes.length-1; i++){
        distToNextNote.push([i, seenNotes[i+1]-seenNotes[i]]);
    } 

    distToNextNote.sort(elem => elem[1]);
    var maxDiffIndex = distToNextNote[distToNextNote.length-1][0];
    var lowerHandMax = seenNotes[maxDiffIndex];
}

function avgSlope(windowedEventList, handNotes){
    var lastNote, nextNote;
    var slopes = [];
    for(var i = 0; i < windowedEventList.length-1; i++){
        var evt = windowedEventList[i];
        // if(evt.type === "off" || (handNotes ? !handNotes.has(evt.note) : true)) continue;
        if(evt.type === "off") continue;
        lastNote = nextNote;
        nextNote = evt.note;
        if(lastNote && nextNote) {
            slopes.push(Math.sign(nextNote-lastNote));
        }
    }
    if(slopes.length < 2) return 0;
    return slopes.reduce((a, b) => a+b, 0)/slopes.length;
}

var sumArr = a => a.reduce((n, m) => n+m, 0);

function hitListToNoteList(windowedEventList){
    var noteTracker = {};
    var noteObjs = [];
    windowedEventList.forEach(function(evt){
        var evtKey = evt.note +'' +evt.chan;
        if(evt.type == "on") noteTracker[evtKey] = [evt.time, evt.vel];
        if(evt.type ==="off" && noteTracker[evtKey]){
            var storedVal = noteTracker[evtKey];
            noteObjs.push({note: evt.note, vel: storedVal[1], chan: evt.chan, time: storedVal[0], dur: evt.time-storedVal[0] });
            delete noteTracker[evtKey];
        } 
    });
    return noteObjs.sort(n => n.time);
}

var jumpThreshold = 1;
function largeJumpTriggered(windowedEventList, onNotes, thresh){
    var lastEvt = windowedEventList[windowedEventList.length-1];
    if(lastEvt.type !== "on") return false;
    var latestPitch = lastEvt.note;
    var onPitches = windowedEventList.filter(evt => evt.type === "on").map(evt => evt.note).concat(Array.from(onNotes));
    var numPitches = onPitches.length;
    var pitchAvg = sumArr(onPitches)/numPitches;
    var pitchStdDev = sumArr(onPitches.map(n => (n-pitchAvg)**2))/(numPitches-1) ** 0.5;
    return Math.abs(latestPitch - pitchAvg) > pitchStdDev * thresh;
}

var lengthThreshold = 4;
function avgNoteLength(windowedEventList, onNotes, onTimes, ignoreThresh){
    var now = (Date.now() - mTime)/1000;
    var sortedNotes = hitListToNoteList(windowedEventList);
    if(sortedNotes.length < 1) return 0;
    var onNoteFilteredTimes = Array.from(onNotes).map(n => now - onTimes[n]).filter(t => t < ignoreThresh);
    var sumLen = sumArr(sortedNotes.map(n => n.dur)) + sumArr(onNoteFilteredTimes);
    return sumLen/(sortedNotes.length + onNoteFilteredTimes.length);
}

function tonalAvg(windowedEventList, onNotes){
    var diatonic = [0, 2, 4, 5, 7, 9, 11];
    var seenNotes = getSeenPitches(windowedEventList, onNotes);
    var tonicRatios = [];
    if(seenNotes.length < 1) return 0;
    for(var i = 0; i < 12; i++){
        var keyChroma = new Set(diatonic.map(p => (i+p)%12));
        var inKey = 0;
        var outKey = 0;
        seenNotes.forEach(function(note){
            if(keyChroma.has(note%12)) inKey++;
            else outKey++;
        });
        var denom = inKey+outKey;
        tonicRatios.push(denom === 0 ? 0 : inKey/(denom));
    }

    return Math.max(...tonicRatios);
}

var printFeatures = true;
function computeFeatures(noteEvts, onNotes, onNoteTimes, triggerCallbackFunc){
    var features = arrayOf(10);
    var windowedEvents = windowEventList(noteEvts, midiTimeWindow);

    features[0] = avgNoteLength(windowedEvents, onNotes, onNoteTimes, lengthThreshold);
    features[1] = avgSlope(windowedEvents);
    features[2] = tonalAvg(windowedEvents, onNotes);

    if(largeJumpTriggered(windowedEvents, onNotes, jumpThreshold) && triggerCallbackFunc) triggerCallbackFunc();
    if(printFeatures) console.log(features, windowedEvents);
    return features;
}