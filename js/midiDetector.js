

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
    while(eventList[len-offset-1].time >= currentTime - windowTime && len-offset-1 > -1 ){
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

}

function avgNoteLength(windowedEventList, onNotes, onTimes, ignoreThresh){

}

function triggerSustainEvent(onNotes, onTimes){

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