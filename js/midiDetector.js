

/* features
average speed between hits
exact pitch sequence matching
time since each note



*/

var timeWindow = 20;

function getSeenPitches(windowedEventList, onNotes){
    var seenNotes = Set();
    windowedEventList.forEach(function(evt){
        if(evt.type === 'on') seenNotes.add(evt.note);
    });
    seenNotes = seenNotes.union(onNotes);
    return seenNotes;
}

function windowEventList(eventList, windowTime){
    var len = eventList.length;
    var offset = 0;
    var currentTime = (Date.now() - mTime) * 0.001;
    while(len-offset-1 > -1 && eventList[len-offset-1].time >= currentTime - windowTime){
        offset++;
    }
    return eventList.splice(len-offset);
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
            slopes.push(nextNote > lastNote ? 1 : -1);
        }
    }
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

function largeJumpTriggered(windowedEventList, onNotes, thresh){
    var lastEvt = windowedEventList[windowedEventList.length-1];
    if(lastEvt.type !== "on") return false;
    var latestPitch = lastEvt.note;
    var onPitches = windowedEventList.filter(evt => evt.type === "on").map(evt => evt.note).concat(Array.from(onNotes));
    var numPitches = onPitches.length;
    var pitchAvg = sumArr(onPitches)/numPitches;
    var pitchStdDev = (onPitches.map(n => (n-pitchAvg)**2)/(numPitches-1)) ** 0.5;
    return Math.abs(lastNote - pitchAvg) > pitchStdDev;
}

function avgNoteLength(windowedEventList, onNotes, onTimes, ignoreThresh){
    var now = (Date.now() - mTime)/1000;
    var sortedNotes = hitListToNoteList(windowedEventList);
    var onNoteFilteredTimes = Array.from(onNotes).map(n => now - onTimes[n]).filter(t => t < ignoreThresh);
    var sumLen = sumArr(sortedNotes.map(n => n.dur)) + sumArr(onNoteFilteredTimes);
    return sumLen/(sortedNotes.length + onNoteFilteredTimes.length);
}

function tonalAvg(windowedEventList, onNotes){
    var diatonic = [0, 2, 4, 5, 7, 9, 11];
    var seenNotes = getSeenPitches(windowedEventList, onNotes);
    var tonicRatios = [];

    for(var i = 0; i < 12; i++){
        var keyChroma = new Set(diatonic.map(p => (i+p)%12));
        var inKey = 0;
        var outKey = 0;
        seenNotes.forEach(function(note){
            if(keyChroma.has(note%12)) inKey++;
            else outKey++;
        });
        tonicRatios.push(inKey/(inKey+outKey));
    }

    return Math.max(...tonicRatios);
}