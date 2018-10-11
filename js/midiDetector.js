

/* features
average speed between hits
exact pitch sequence matching
time since each note



*/

var timeWindow = 20;

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

}

function avgSlope(windowedEventList, handNotes){

}

function avgNoteLength(windowedEventList){

}

function triggerSustainEvent(onNotes, onTimes){

}

function tonalAvg(windowedEventList){

}