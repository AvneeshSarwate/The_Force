var customLoaderUniforms = "";

function setup(){}
function draw(){}


var customLoaderMap = {};


function videoUploadResponder(){}
function audioFilesSelected(){}
function videoSnapshot(){}


function loadImageToTexture(slotID, imageUrl){
    destroyInput(slotID);
    var texture = {};
    texture.type = "tex_2D";
    texture.globject = gl.createTexture();
    texture.image = new Image();
    texture.loaded = false;
    whichSlot = "";
    texture.image.onload = function()
    {
        createGLTextureNearest(gl, texture.image, texture.globject);
        texture.loaded = true;
    }
    texture.image.src = imageUrl;
    mInputs[slotID] = texture;
    createInputStr();
}



function empressAlbumArtLoader(){
	var slotID = 5;
    destroyInput(slotID);
    var texture = {};
    texture.type = "tex_2D";
    texture.globject = gl.createTexture();
    texture.image = new Image();
    texture.loaded = false;
    whichSlot = "";
    texture.image.onload = function()
    {
        createGLTextureNearest(gl, texture.image, texture.globject);
        texture.loaded = true;
    }
    texture.image.src = 'presets/empress.png';
    mInputs[slotID] = texture;
    createInputStr();
}


var createVideoElement = function(vid, videoInd, textureInd, playAudio){
    const video = document.createElement('video');

    var playing = false;
    var timeupdate = false;

    video.autoplay = true;
    video.muted = !playAudio;
    video.loop = true;

    // if(playAudio){
    //     loadImageToTexture(7, "clicktoplay.png");
    //     $("#demogl").click(function(){
    //         video.muted = false;
    //         video.play();
    //         if(otherArgs.videoPlayFunc) otherArgs.videoPlayFunc();
    //     });
    // }

      // Waiting for these 2 events ensures
      // there is data in the video

    video.addEventListener('playing', function() {
        playing = true;
        checkReady();
    }, true);

    video.addEventListener('timeupdate', function() {
        timeupdate = true;
        checkReady();
    }, true);

    function checkReady() {
        if (playing && timeupdate) {
            videosReady[videoInd] = true;
        }
    }

    video.src = vid;

    var textureObj = initVideoTexture(gl, null);
    texture = {};
    texture.globject = textureObj;
    texture.type = "tex_2D";
    texture.image = {height: video.height, video: video.width};
    texture.loaded = true; //this is ok to do because the update loop checks videosReady[]
    videos[videoInd] = video;
    videoTextures[videoInd] = texture;
    mInputs[textureInd] = texture;
    if(!playAudio) video.play();
}

var blobVideoURLs = {};
function blobVideoLoad(videoInd, textureInd, videoFileURL, playAudio, otherArgs){
    var req = new XMLHttpRequest();
    req.open('GET', videoFileURL, true);
    req.responseType = 'blob';

    if(blobVideoURLs[videoFileURL]){
        createVideoElement(blobVideoURLs[videoFileURL], videoInd, textureInd, playAudio);
        if(otherArgs && otherArgs.postLoadFunc) otherArgs.postLoadFunc();
    } else {

        req.onload = function() {
            // Onload is triggered even on 404
            // so we need to check the status code
            if (this.status === 200) {
                var videoBlob = this.response;
                var vid = URL.createObjectURL(videoBlob); // IE10+
                // Video is now downloaded
                // and we can set it as source on the video element
                blobVideoURLs[videoFileURL] = vid;
                
                createVideoElement(vid, videoInd, textureInd, playAudio);
                if(otherArgs && otherArgs.postLoadFunc) otherArgs.postLoadFunc();
            }
        }
        req.onerror = function() {
            // Error
        }

        req.send();
    }
}

function interactiveLoader(){
    blobVideoLoad(1, 5, "GLASS_VEIN.mov");
}

function reedLoader(){
    blobVideoLoad(1, 5, "happyBirthday.mp4", true);
    loadImageToTexture(6, "reedFace.jpg");
    loadImageToTexture(7, "clicktoplay.png");
}

var enoTime = 0;
var enoIncrement = 1;
var songLength = 2912;
var playingSeq = false; 
var startTime = 0;
var progressTime = 0;
var startIncTime = 6.67;
var resetEno;
function enoLoader(){

    var bufferLoadFunc = function(){
        startTime = Date.now();
        console.log("eno buffer loaded");
        Tone.Transport.scheduleOnce(function(time){
            console.log("eno incrementing started");
            Tone.Transport.bpm.rampTo(600, 60-startIncTime);
            enoTime = startIncTime;
            playingSeq = true;
        }, Tone.now() + startIncTime);
    }

    var filter =  new Tone.Filter(2000, "lowpass", -48).toMaster();
    player = new Tone.Player("airport2.mp3", bufferLoadFunc).connect(filter);
    player.autostart = true;

    resetEno = function(){
        enoTime = 0;
        enoIncrement = 1;
        songLength = 2912;
        playingSeq = false; 
        startTime = 0;
        progressTime = 0;
        Tone.Transport.bpm.value = 120;
        player.stop();
        player.start(Tone.now(), 0);
        bufferLoadFunc();
    }

    sequenceFunc = function(time, note){
        if(playingSeq && enoTime < songLength){
            if(progressTime < 10) enoIncrement += 0
            else if(progressTime < 19.5) enoIncrement += 0.005
            else if(progressTime < 28.5) enoIncrement += 0.025
            else if(enoIncrement < 15 && progressTime > 28.5) enoIncrement += 0.045;
            enoTime += enoIncrement;
            player.stop()
            player.start(Tone.now(), enoTime);
            progressTime = (Date.now() - startTime)/1000;
            console.log("pattern note", enoTime, enoIncrement, progressTime);
        }
    }

    loadImageToTexture(5, "airports.jpg");

    customLoaderUniformSet = function(time){
        var enoProgU = gl.getUniformLocation(mProgram, "enoProg");
        if(enoProgU) gl.uniform1f(enoProgU, enoTime/songLength);
    }

}

function goreLoader(){
    var goreSequencer = new Tone.Sequence(function(time, note){
        if(videos[1]) {
            videos[1].currentTime = videos[1].currentTime + (-1 + Math.random()*2);
            videos[1].playBackRate = Math.min(5, Math.max(1/16, videos[1].playBackRate + (-0.1 + Math.random()*0.2)));
        }
    }, [1, [1, 1]], "4n");
    var videoPlayFunc = function(){
        goreSequencer.start();
        console.log("gore sequencer started");
    }
    videoUploadResponder = function(videoFile){
        var blobURL = URL.createObjectURL(videoFile);
        var oldVid = videos[1];
        // videos[0].pause(); //todo - delete the underlying video element to free memory
        createVideoElement(blobURL, 1, 6, true, {'postLoadFunc': videoPlayFunc});
        oldVid.pause();
        URL.revokeObjectURL(oldVid.src);
        oldVid.removeAttribute("src");
        oldVid.load();

    }
    loadImageToTexture(7, "black.jpg");
    blobVideoLoad(1, 6, "gore.mp4", true, {'postLoadFunc': videoPlayFunc});
    customLoaderUniformSet = function(time){
        var enoProgU = gl.getUniformLocation(mProgram, "enoProg");
        if(enoProgU) gl.uniform1f(enoProgU, videos[1] ? videos[1].currentTime/100 : 0);
    }
}

function watchmanLoader(){
    blobVideoLoad(1, 5, "watchman.mp4", true);
    loadImageToTexture(7, "clicktoplay.png");
}

var sinN = (x) => (Math.sin(x) + 1)/2;
var cosN = (x) => (Math.cos(x) + 1)/2;
function movieSpliceLoader(){
    var movieFiles = "gore.mp4";
    var cacheLoader = function(){
        blobVideoLoad(1, 6, movieFiles, false);
        blobVideoLoad(2, 7, movieFiles, false);
        blobVideoLoad(3, 8, movieFiles, false);
    };
    blobVideoLoad(0, 5, movieFiles, false, {'postLoadFunc': cacheLoader});

//     customLoaderUniforms = `
// uniform float lastNoteValue;
//     `;
    
    //these variables help stop videos from constantly getting start/stopped on every frame 
    //when the global midi event count values stay static
    var midiOnCountTracker = 0;
    var midiOffCountTracker = 0;

    //time in secondsPassed
    customLoaderUniformSet = function(time, mProgram){
        var lastNoteValU = gl.getUniformLocation(mProgram, "lastNoteValue");
        if(lastNoteValU) gl.uniform1f(lastNoteValU, lastNoteValue);
        for(var i = 0; i < videos.length; i++){
            if(videos[i]){
                videos[i].playbackRate = 0.8 + sinN(time/3+i)*0.4;
            }
        }
        //todo - instead of this - move the channel 5-8 texture update code here?
        var noteOnCountMod = noteOnEventCount % 4;
        var noteOffCountMod = noteOffEventCount % 4; 
        if(noteOnEventCount > midiOnCountTracker && !videos[noteOnCountMod].paused) {
            midiOnCountTracker++;
            videos[noteOnCountMod].pause();
            console.log("paused", noteOnCountMod);
        }
        if(noteOffEventCount > midiOffCountTracker && videos[noteOffCountMod].paused) { 
            midiOffCountTracker++
            videos[noteOffCountMod].play();
            console.log("played", noteOffCountMod);
        }
    }
}

function p5TestLoader(){
    setup = testSetup;
    draw = testDraw;
}

function p5hullLoader(){
    setup = hulldrawSetup;
    draw = hulldraw;
}

function p5Sensel(){
    setup = senselSetup;
    draw = sensel;
}

var fft, waveform; 
function phialLoader(){
    setup = phialSetup;
    draw = phialDraw;

    var kickMidi, kickPart, kickLoaded = false;
    var leadMidi, leadPart, leadLoaded = false;
    var player, playerLoaded = false;
    var kickSnakeInd = 0;
    var leadSnakeInd = 0;
    loadImageToTexture(5, "phial.png");
    var everyThingLoaded = () => kickLoaded && leadLoaded && playerLoaded;
    var startEverything = function(){
        Tone.Transport.bpm.value = 124;
        Tone.Transport.start(Tone.now()+1);
        kickPart.start(Tone.now()+1);
        leadPart.start(Tone.now()+1);
        player.start(Tone.now()+1);
    };

    MidiConvert.load("./phial/phial_kick.mid", function(midi){
        kickMidi = midi;
        kickPart = new Tone.Part(function(time, note){
            // console.log("kick", time, note);
            snakeOrder++;
            rotateFrame++;
        }, kickMidi.tracks[0].notes);
        kickLoaded = true;
        if(everyThingLoaded()) startEverything();
    });

    MidiConvert.load("./phial/phial_lead.mid", function(midi){
        leadMidi = midi;
        leadPart = new Tone.Part(function(time, note){
            // console.log("lead", time, note);
            // sneks[leadSnakeInd].switchScheduled = true;
            // leadSnakeInd = (leadSnakeInd+1) % numSnakes;

            // sneks.map(snek => {{snek.switchScheduled=true}})
            sneks[leadSnakeInd].swellManager.startTime = Date.now()/1000;
            sneks[leadSnakeInd].swellManager.isActive = true;
            leadSnakeInd = (leadSnakeInd+1)%numSnakes;
        }, leadMidi.tracks[0].notes);
        leadLoaded = true;
        if(everyThingLoaded()) startEverything();
    })

    fft = new Tone.FFT(32);
    waveform = new Tone.Waveform(1024)
    player = new Tone.Player({
        "url" : "./phial_snip.[mp3|ogg]",
        "loop" : true,
        "onload": function() {
            playerLoaded = true;
            if(everyThingLoaded()) startEverything();
        }
    }).connect(fft).toMaster();
}

//a sampler where the keys correspond to jump-points in the video.
//you can scroll forwards through the jump points with the highest key, and backwards with the lowest key
function videoSoundSampler1Loader(){
    blobVideoLoad(0, 5, "gore.mp4", true, {'postLoadFunc': () => 5});
    videoUploadResponder = function(videoFile){
        var blobURL = URL.createObjectURL(videoFile);
        var oldVid = videos[0];
        // videos[0].pause(); //todo - delete the underlying video element to free memory
        createVideoElement(blobURL, 0, 5, true);
        oldVid.pause();
        URL.revokeObjectURL(oldVid.src);
        oldVid.removeAttribute("src");
        oldVid.load();

    }
    var deviations = arrayOf(1000).map((elem, i) => i + Math.random());
    var baseInd = 0;
    var moveDownNote = 48;
    var moveUpNote = 48 + 24;
    var midiNoteFunction = function(note, vel){
        if(note == moveDownNote) baseInd = Math.max(baseInd-1, 0);
        else if(note == moveUpNote) baseInd++;
        else videos[0].currentTime = deviations[baseInd + (note-37)];
    }   
    midiEventHandlers["on"] = midiNoteFunction;
}

function setLowestKeyboardNote(val){ 
    lowestKeyboardNote = int($("#lowestNote").val());
}
var lowestKeyboardNote = 48;
//a sampler where the keys correspond to jump-points in the video.
//you can scroll forwards through the jump points with the highest key, and backwards with the lowest key
function videoSoundSampler2Loader(){
    var videoSnapshotTexture;
    blobVideoLoad(0, 5, "gore.mp4", true, {'postLoadFunc': () => {
        videoSnapshotTexture = mInputs[6] = createVideoSnapshotTexture(gl, videos[0])
    }});

    videoSnapshot = function(){
        if(videoSnapshotTexture.globject) updateVideoTexture(gl, videoSnapshotTexture.globject, videos[0]);
    }

    sliderConfig = videoBlendSliderVals;

    videoUploadResponder = function(videoFile){
        var blobURL = URL.createObjectURL(videoFile);
        var oldVid = videos[0];
        // videos[0].pause(); //todo - delete the underlying video element to free memory
        createVideoElement(blobURL, 0, 5, true);
        oldVid.pause();
        URL.revokeObjectURL(oldVid.src);
        oldVid.removeAttribute("src");
        oldVid.load();

    }
    var players = arrayOf(10);
    audioFilesSelected = function(audioFiles){
        console.log(audioFiles);
        players.forEach(player => player ? player.dispose() : 0);
        for(var i = 0; i < Math.min(10, audioFiles.length); i++){
            var objUrl = URL.createObjectURL(audioFiles[i]);
            players[i] = new Tone.Player(objUrl).toMaster();
        }
    }
    var deviations = arrayOf(1000).map((elem, i) => i + Math.random());
    var baseInd = 0;
    var midiNoteFunction = function(note, vel){
        var moveDownNote = lowestKeyboardNote;
        var moveUpNote = lowestKeyboardNote + 24; //62
        if(note == moveDownNote) baseInd = Math.max(baseInd-6, 0);
        else if(note == moveUpNote) baseInd+=6;
        else if(moveDownNote < note && note <= moveDownNote + 12 ){
            videos[0].currentTime = deviations[baseInd + (note-37)];
        }
        else if(moveDownNote + 12 < note && note < moveUpNote && vel > 0) players[note % (moveDownNote+13)].start(); //sample on
        else if(moveDownNote + 12 < note && note < moveUpNote && vel == 0) players[note % (moveDownNote+13)].stop(); //sample off
    }   
    midiEventHandlers["on"] = midiNoteFunction;

    var midiCCFunction = function(ccNum, val){
        sliders[ccNum].value = val/128;
    }
    midiEventHandlers["cc"] = midiCCFunction;
}


function replaceVideo(vidInd, textureInd, videoFile){
    var blobURL = URL.createObjectURL(videoFile);
    var oldVid = videos[vidInd];
    // videos[0].pause(); //todo - delete the underlying video element to free memory
    createVideoElement(blobURL, vidInd, textureInd, true);
    oldVid.pause();
    URL.revokeObjectURL(oldVid.src);
    oldVid.removeAttribute("src");
    oldVid.load();
}

function yoyoVideoTest(){
    var videoSnapshotTexture;
    blobVideoLoad(0, 5, "fast_stable.m4v", false, {'postLoadFunc': () => {
        videoSnapshotTexture = mInputs[6] = createVideoSnapshotTexture(gl, videos[0])
        blobVideoLoad(1, 7, "fast_stable.m4v", false, {'postLoadFunc': () => {videos[1].currentTime = (videos[0].currentTime - 0.05) % videos[0].duration}}) ;
    }});

    videoSnapshot = function(){
        if(videoSnapshotTexture && videoSnapshotTexture.globject) updateVideoTexture(gl, videoSnapshotTexture.globject, videos[0]);
    }

    sliderConfig = videoBlendSliderVals;

    videoUploadResponder = function(videoFile){
        replaceVideo(0, 5, videoFile)
    }
}

function yoyoVideoTestB(){
    var videoSnapshotTexture;
    blobVideoLoad(0, 5, "LaraDance.mp4", false, {'postLoadFunc': () => {
        // videoSnapshotTexture = mInputs[6] = createVideoSnapshotTexture(gl, videos[0])
        blobVideoLoad(1, 7, "LaraDance.mp4", false, {'postLoadFunc': function(){
            setTimeout(() => {videos[0].currentTime = videos[1].currentTime + 0.7}, 2000);
            // var setVideoLag = function(){
            //     console.log("lagVidTime", videos[0].currentTime, videos[0].duration, mod((videos[0].currentTime - 0.05), videos[0].duration));
            //     if(videos[0].duration && videos[1].duration) videos[1].currentTime = mod((videos[0].currentTime - 0.05), videos[0].duration);
            //     // videos[1].currentTime = (videos[0].currentTime - 0.05);
            // }
            // // setTimeout(setVideoLag(), 1500);
            // videos[0].addEventListener('durationchange', setVideoLag);
            // videos[1].addEventListener('durationchange', setVideoLag);
        }});
        blobVideoLoad(2, 8, "LaraDance.mp4", false);
    }});

    videoSnapshot = function(){
        if(videoSnapshotTexture && videoSnapshotTexture.globject) updateVideoTexture(gl, videoSnapshotTexture.globject, videos[0]);
    }

    sliderConfig = yoyoSliders;
    sliderCallbacks[0] = function(sliderVal){videos[0].currentTime = videos[1].currentTime + sliderVal};

    videoUploadResponder = function(videoFile){
        replaceVideo(0, 5, videoFile)
    }
}

function sliderTrails(ind){
    return function(){
        if(ind == 0) sliderConfig = trailsSliders;
        if(ind == 2) sliderConfig = trailsSliders2;
        navigator.mediaDevices.enumerateDevices().then(function(deviceList){
            var cameras = deviceList.filter(device => device.kind == "videoinput");
            var camSelector = $("#cameraSelector");
            for(var i = 0; i < cameras.length; i++){
                camSelector.append("<option value=\""+i+"\">cameara "+i+"</option>")
            }
            camSelector.change(function(event){
                camcam = camSelector;
                changeWebcamSelection(parseInt(camSelector.val()));
                console.log(event);
            })
        });
        // blobVideoLoad(0, 5, "GLASS_VEIN.mov", false);
    }
}

function responsivevisLoader(i){
    try { 
        setup = eval("responsevis"+i+"Setup");
        draw = eval("responsevis"+i+"Draw");  
    } catch(e){
        console.log("p5 function eval error", e);
    }
    var patternList = midiPatternMap["responsivevis"+i];
    patterns = patternList ? patternList : []; 
    if(midiResponseSetup["responsivevis"+i]) midiResponseSetup["responsivevis"+i]();
}

customLoaderMap["solidCoating"] = function(){
    setup = eval("responsevis1Setup");
    draw = eval("responsevis1Draw");  
    sliderConfig[0].conf.value = .55;
    sliderConfig[7].conf.value = 1;
    sliderConfig[8].conf.value = 1;   
}

customLoaderMap['rainbowHits_slider'] = function(){
    patterns = midiPatternMap['rainbowHits_slider'];
    sliderConfig = rainbowHitsSliders;
}

// 