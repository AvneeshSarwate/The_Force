var customLoaderUniforms = "";

function setup(){}
function draw(){}

var playAtHalfRate = false;

var customLoaderMap = {};

var webgl2Shaders = new Set(['interactiveGridSlice1','noisePlay1', 'hyperphase', 'guitarPaintBrush', 'snoiseCamWarp_slider', 'foregroundDive', 'kevin', "eyebeamSVG", "preBurningMan", "cosmicHaus", 'snoiseCamWarp_kinect']);
var audioOnShaders = new Set(["drake", "drake2", "drake3", "drake4", "gore", "eno", "hedberg", "vimeoTalk"]);

//TODO - eventually invert this to needs-camera shaders, this is just faster for upcoming performance
var ignoreCameraShaders = new Set([""]);

function videoUploadResponder(){}
function audioFilesSelected(){}
function videoSnapshot(){}
function everyFrameSnapshot(){}
function frameStateUpdate(){}
var frameState = {};

function loadImageFromPanel(videoFile){
    var blobURL = URL.createObjectURL(videoFile);   
    loadImageToTexture(5, blobURL);
}

var ignoreAudioForShader = false;

function enterFullscreen(){
    if (document.body.requestFullScreen)
        document.body.requestFullScreen();
    else if (document.body.mozRequestFullScreen)
        document.body.mozRequestFullScreen();
    else if (document.body.webkitRequestFullScreen)
        document.body.webkitRequestFullScreen(Element.ALLOW_KEYBOARD_INPUT);
}

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
    return texture;
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

            //this is actually supposed to be playbackRate (lowercase b) - so it does nothing, but i don't mind the effect without it
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
    blobVideoLoad(0, 5, "gore.mp4", false, {'postLoadFunc': () => {
        videoSnapshotTexture = mInputs[6] = createVideoSnapshotTexture(gl, videos[0])
    }});

    videoSnapshot = function(){
        if(videoSnapshotTexture && videoSnapshotTexture.globject) updateVideoTexture(gl, videoSnapshotTexture.globject, videos[0]);
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
        if(note == moveDownNote) baseInd = Math.max(baseInd-12, 0);
        else if(note == moveUpNote) baseInd+=12;
        else if(moveDownNote < note && note < moveUpNote ){
            videos[0].currentTime = deviations[baseInd + (note-(lowestKeyboardNote+1))];
        }
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
        if(ind == 3) sliderConfig = trailsSliders3;
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
        let midiCCFunction = (note, vel, chan) => {
            setSliderVal(note-lowestSliderVal, vel/127);
        }

        midiEventHandlers['cc'] = midiCCFunction;
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

    midiDeviceName = "IAC Driver Bus 2";

    patterns = patternList ? patternList : []; 
    if(midiResponseSetup["responsivevis"+i]) midiResponseSetup["responsivevis"+i]();
    osc.on("/changeVisuals", function(msg){
        window.location.href = msg[0];
    });
    osc.on("/enterFullscreen", function(msg){
        enterFullscreen();
    });
    connectOSC(false);
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

customLoaderMap['prince'] = function(){
    midiEventHandlers["on"] = function(note, vel, chan){
        updateManualTime = true;
        manualStepTime = (Date.now() - mTime) * 0.001;
    };
    midiEventHandlers["off"] = function(note, vel, chan){
        updateManualTime = false;
    };
    sliderConfig = princeSliders;
    loadImageToTexture(5, "princeGuitar.jpg");
}

customLoaderMap['randBlob'] = function(){
    setup = randBlobSetup;
    draw = randBlobDraw;
}

customLoaderMap['hyperphase'] = function(){
    // setup = hyperphaseSetup;
    // draw = hyperphaseDraw;

    customLoaderUniforms = `
    uniform float     hyperphasePhases[10];
    `;

    var hyperphasePatterns = arrayOf(10).map(i => ({currentInd: -1, pattern:[0]}));
    var hyperphasePhases = arrayOf(10);
    var patternArrays = [];
    for(var i = 0; i < 10; i++){
        patternArrays.push("uniform float hyperphasePattern" + (i+1) + '[10];');
    }
    customLoaderUniforms += patternArrays.join("\n") + '\nuniform float hyperphaseInds[10];\n';

    osc.on("/hitInfo", function(msg){
        console.log(msg);
        hyperphasePatterns[msg.args[0]].currentInd = msg.args[1];
    });
    osc.on("/pattern", function(msg){
        console.log(msg);
        hyperphasePatterns[msg.args[0]].pattern = msg.args.slice(1);
    });
    osc.on("/phaseVal", function(msg){
        // console.log(msg);
        hyperphasePhases[msg.args[0]] = msg.args[1];
    });

    customLoaderUniformSet = function(time, mProgram){
        var hyperphasePhasesU = gl.getUniformLocation(mProgram, "hyperphasePhases");
        if(hyperphasePhasesU) gl.uniform1fv(hyperphasePhasesU, hyperphasePhases);
        for(var i = 0; i < 10; i++){
            var hyperphasePatternU = gl.getUniformLocation(mProgram, "hyperphasePattern" + (i+1));
            if(hyperphasePatternU) gl.uniform1fv(hyperphasePatternU, hyperphasePatterns[(i+1)].pattern);
        }
        var hyperphaseIndsU = gl.getUniformLocation(mProgram, "hyperphaseInds");
        if(hyperphaseIndsU) gl.uniform1fv(hyperphaseIndsU, hyperphasePatterns.map(p => p.currentInd));
    };
}

customLoaderMap['yoyoPortAuthority'] = function(){
    yoyoVideoTestB();
    everyFrameSnapshot = function(){
        mInputs[6] = mInputs[0];

    }
}

customLoaderMap['yoyoPortAuthority2'] = function(){
    yoyoVideoTestB();
    sliderConfig = yoyoPortAuthoritySliders;
    everyFrameSnapshot = function(){
        mInputs[6] = mInputs[0];

    }
}

customLoaderMap['guitarPaintBrush'] = function(){
    // playAtHalfRate = true;

    setup = guitarPaintSetup;
    draw = guitarPaintDraw;
    customLoaderUniforms = `
    uniform float brushAngles[4];
    uniform vec2 brushPositions[4];
    uniform float fftValues[50];
    uniform float numLoopsPlaying;
    uniform vec2 droneNotes;
    `;

    var fftValues = arrayOf(50);
    var numLoopsPlaying = 0;
    var droneNotes = [-1, -1];

    customLoaderUniformSet = function(time, mProgram){
        var brushAnglesU = gl.getUniformLocation(mProgram, "brushAngles");
        if(brushAnglesU) gl.uniform1fv(brushAnglesU, brushAngles);
        var brushPosU = gl.getUniformLocation(mProgram, "brushPositions");
        var positionArray = brushPositions.map(p => [p.x/p5w, p.y/p5h]).flat();
        if(brushPosU) gl.uniform2fv(brushPosU, positionArray);
        var brushAnglesU = gl.getUniformLocation(mProgram, "brushAngles");
        if(brushAnglesU) gl.uniform1fv(brushAnglesU, brushAngles);
        var fftValuesU = gl.getUniformLocation(mProgram, "fftValues");
        if(fftValuesU) gl.uniform1fv(fftValuesU, fftValues);
        var numLoopsPlayingU = gl.getUniformLocation(mProgram, "numLoopsPlaying");
        if(numLoopsPlayingU) gl.uniform1f(numLoopsPlayingU, numLoopsPlaying);
        var droneNotesU = gl.getUniformLocation(mProgram, "droneNotes");
        if(droneNotesU) gl.uniform2f(droneNotesU, droneNotes[0], droneNotes[1]);
    }

    sliderCallbacks[0] = function(sliderVal){brushAngles = arrayOf(4).map(i => sliderVal*2*PI)};
    sliderCallbacks[1] = function(sliderVal){brushSpeeds = arrayOf(4).map(i => sliderVal*20)};

    sliderConfig = guitarPaintSliders;

    osc.on("/brushAngles", function(msg){
        brushAngles = msg.args;
    });
    osc.on("/brushSpeeds", function(msg){
        brushSpeeds = msg.args;
    });

    osc.on("/changeVisuals", function(msg){
        window.location.href = msg[0];
    });
    osc.on("/enterFullscreen", function(msg){
        enterFullscreen();
    });
    osc.on("/fftValues", function(msg){
        fftValues = msg.args;
    });
    osc.on("/numLoopsPlaying", function(msg){
        numLoopsPlaying = msg.args[0];
        console.log("numLoopsPlaying", numLoopsPlaying);
    });
    osc.on("/droneNotes", function(msg){
        droneNotes[msg.args[0]] = msg.args[1];
    });

    ignoreAudioForShader = true;
    connectOSC(false);
}

customLoaderMap['snoiseCamWarp_slider'] = function(){
    sliderConfig = cameraSinkSliders;
}

customLoaderMap['lightLine_slider'] = function(){
    sliderConfig = arrayOf(10).map((e, i) => ({conf: {min:0, max: 1, value: Math.random()}, label: "slider "+i }));
}

customLoaderMap['beyonceGrain'] = function(){
    setup = beyonceGrainSetup;
    draw = beyonceGrainDraw;
    customLoaderUniforms = `
    uniform vec2 totalPitchDev;
    `;
    customLoaderUniformSet = function(time, mProgram){
        var totalPitchDevU = gl.getUniformLocation(mProgram, "totalPitchDev");
        if(totalPitchDevU) gl.uniform2f(totalPitchDevU, totalPitchDev[0], totalPitchDev[1]);
    }

    var deepcopy = obj => JSON.parse(JSON.stringify(obj));
    osc.on("/grainPitch", function(msg){
        if(msg.args[0] != 0) {
            grainQueue.push(msg.args);
        }
    });
    osc.on("/1/pos", function(msg){
        if(videos[0]) videos[0].currentTime = msg.args[0] * videos[0].duration;
        // console.log(msg);
    });
    osc.on("/2/pos", function(msg){
        if(videos[2]) videos[2].currentTime = msg.args[0] * videos[2].duration;
        // console.log(msg);
    });
    osc.on("/1/volres", function(msg){
        setSliderVal(0, msg.args[1]);
        setSliderVal(1, msg.args[0]);
        // console.log(msg);
    });
    osc.on("/1/q", function(msg){
        setSliderVal(2, msg.args[0]);
        // console.log(msg);
    });
    osc.on("/2/volres", function(msg){
        setSliderVal(3, msg.args[1]);
        setSliderVal(4, msg.args[0]);
        // console.log(msg);
    });
    osc.on("/2/q", function(msg){
        setSliderVal(5, msg.args[0]);
        // console.log(msg);
    });
    osc.on("/2/pos", function(msg){
        if(videos[1]) videos[1].currentTime = msg.args[0] * videos[1].currentTime;
        // console.log(msg);
    });
    osc.on("/voiceVolumes", function(msg){
        voiceVolumes = msg.args;
    });
    //TODO clean terrible use of closure
    var caluclateTotalPitchDev = function(){
        var newDev = [pitchDeviations[0][0]+pitchDeviations[0][1], pitchDeviations[1][0]+pitchDeviations[1][1]];
        var lastDev = [lastPitchDevValues[0][0]+lastPitchDevValues[0][1], lastPitchDevValues[1][0]+lastPitchDevValues[1][1]];
        totalPitchDev = [totalPitchDev[0]+Math.sign(newDev[0]-lastDev[0]), totalPitchDev[1]+Math.sign(newDev[1]-lastDev[1])];
    }
    arrayOf(16).forEach((el, i) => {
        osc.on("/1/playrate/1/"+(i+1), function(msg){
            lastPitchDevValues = deepcopy(pitchDeviations);
            pitchDeviations[0][0] = (i+1) - 11;
            caluclateTotalPitchDev();
        });
        osc.on("/1/pitch/1/"+(i+1), function(msg){
            lastPitchDevValues = deepcopy(pitchDeviations);
            pitchDeviations[0][1] = (i+1) - 11;
            caluclateTotalPitchDev();
        });
        osc.on("/2/playrate/1/"+(i+1), function(msg){
            lastPitchDevValues = deepcopy(pitchDeviations);
            pitchDeviations[1][0] = (i+1) - 11;
            caluclateTotalPitchDev();
        });
        osc.on("/2/pitch/1/"+(i+1), function(msg){
            lastPitchDevValues = deepcopy(pitchDeviations);
            pitchDeviations[1][1] = (i+1) - 11;
            caluclateTotalPitchDev();
        });
    });

    osc.on("/changeVisuals", function(msg){
        window.location.href = msg[0];
    });
    osc.on("/enterFullscreen", function(msg){
        enterFullscreen();
    });

    connectOSC(false);
    blobVideoLoad(0, 5, "halo.mp4", false, {'postLoadFunc': () => setTimeout(() => videos[0].pause(), 200)});
    blobVideoLoad(1, 6, "halo.mp4"); 
    blobVideoLoad(2, 7, "halo.mp4", false, {'postLoadFunc': () => setTimeout(() => videos[2].pause(), 200)});
}

customLoaderMap['fogShip_slider'] = function(){
    mTime += Math.random()*200*1000;
    sliderConfig = arrayOf(6).map((e, i) => ({conf: {min:0, max: 1, value: Math.random()}, label: "slider "+i }));
}

customLoaderMap['yoyoBodyVJ'] = function(){
    var videoSnapshotTexture;
    blobVideoLoad(0, 5, "LaraDance.mp4", false, {'postLoadFunc': () => {
        // videoSnapshotTexture = mInputs[6] = createVideoSnapshotTexture(gl, videos[0])
        blobVideoLoad(1, 7, "LaraDance.mp4", false, {'postLoadFunc': function(){
            setTimeout(() => {videos[1].currentTime = videos[0].currentTime + 0.7}, 2000);
        }});
    }});

    videoSnapshot = function(){
        if(videoSnapshotTexture && videoSnapshotTexture.globject) updateVideoTexture(gl, videoSnapshotTexture.globject, videos[0]);
    }

    everyFrameSnapshot = function(){
        mInputs[6] = mInputs[5];
    }

    sliderConfig = yoyoBodyVJSliders;
    sliderCallbacks[0] = function(sliderVal){timeScale = sliderVal*2};
    sliderCallbacks[1] = function(sliderVal){videos[1].currentTime = mod(videos[0].currentTime + 10*sliderVal, videos[0].duration)};
    sliderCallbacks[2] = function(sliderVal){
        videos[0].playbackRate = Math.max(1/16, sliderVal * 4);
        videos[1].playbackRate = Math.max(1/16, sliderVal * 4);
    }
    videoUploadResponder = function(videoFile){
        replaceVideo(0, 5, videoFile);
    }

    var midiNoteFunction = function(note, vel){
        if(note < 36 || note > 99) return;
        var lowNote = 36+12; 
        var range = 99 - 36;

        videos[0].currentTime = videos[0].duration * (note-lowNote)/range;
        videos[1].currentTime = mod(videos[0].currentTime + 10*sliders[1].value, videos[0].duration);
    }   
    midiEventHandlers["on"] = midiNoteFunction
}

customLoaderMap['kevin'] = function(){
    blobVideoLoad(0, 5, "Attempt1.mov", true);
    blobVideoLoad(1, 6, "Attempt2.mov", true);
    blobVideoLoad(2, 7, "Attempt3.mov", true);
    blobVideoLoad(3, 8, "Attempt4.mov", true);
}

var logHedberg = false;
customLoaderMap['hedberg'] = function(){
    loadImageToTexture(5, "hedberg.jpg");
    blobVideoLoad(0, 5, "hedberg.mp4", true);


    var lastTimeMouthClosed = -1;
    var lastTimeMouthOpened = -1;
    var lastTimeNeutral = -1;
    var lastMouthState = "neither";
    var lastClearState = "closed";
    customLoaderUniforms = `
    uniform float timeSinceMouthClosed;
    uniform float timeSinceMouthOpened;
    uniform float timeSinceNeutral;
    `;

    customLoaderUniformSet = function(time, mProgram){
        var timeSinceMouthClosedU = gl.getUniformLocation(mProgram, "timeSinceMouthClosed");
        if(timeSinceMouthClosedU) gl.uniform1f(timeSinceMouthClosedU, Date.now()/1000 - lastTimeMouthClosed);
        var timeSinceMouthOpenU = gl.getUniformLocation(mProgram, "timeSinceMouthOpen");
        if(timeSinceMouthOpenU) gl.uniform1f(timeSinceMouthOpenU, Date.now()/1000 - lastTimeMouthOpened);
        var timeSinceNeutralU = gl.getUniformLocation(mProgram, "timeSinceNeutral");
        if(timeSinceNeutralU) gl.uniform1f(timeSinceNeutralU, Date.now()/1000 - lastTimeNeutral);
    }


    osc.on("/mouthData", function(msg){
        var mouthData = JSON.parse(msg.args[0]);
        handleMouthData(mouthData);
    });
    
    var handleMouthData = function(mouthData){
        if(!videos[0]) return;
        var openFrac = -1;
        if(mouthData.openDist > 0 && mouthData.closedDist > 0){
            openFrac = (parseFloat(mouthData.avg) - mouthData.closedDist) / (mouthData.openDist - mouthData.closedDist);
            // videos[0].playbackRate = openFrac >= 0.5 ? Math.min(openFrac**2 * 4, 4) : Math.max(1/16, openFrac * 2);
            videos[0].playbackRate = Math.max(1/16, Math.min(openFrac**2, 16));
        }
        
        if(lastMouthState != "open" && mouthData.state == "open"){
            if(lastClearState == "closed"){
                videos[0].currentTime = sentenceList[Math.floor(Math.random()*sentenceList.length)].start;
                videos[0].play();
                console.log("hedberg play");
                lastTimeMouthClosed = Date.now()/1000;
            }
            lastClearState = "open";

        }else if(lastMouthState != "closed" && mouthData.state == "closed"){
            if(lastClearState == "open"){
                videos[0].pause();
                console.log("hedberg pause");
                lastTimeMouthOpened = Date.now()/1000;
            }
            lastClearState = "closed";

        }else if(lastMouthState != "neither" && mouthData.state == "neither"){
            lastTimeNeutral = Date.now()/1000;
        }

        lastMouthState = mouthData.state;
        if(logHedberg) console.log(openFrac, mouthData);
    };


    var wordList = [{start: 0, end: 0}];
    var sentenceList = [{start: 0, end: 0}];
    $.get("hedberg.json", function(result){
        var hedbergJson = result;
        wordlist = hedbergJson.results.map(r => r.alternatives[0].words).flat(1)
            .map(w => ({word:w.word, start: parseFloat(w.startTime.slice(0, -1)), end: parseFloat(w.endTime.slice(0, -1))}));

        sentenceList = hedbergJson.results.map(r => ({start: parseFloat(r.alternatives[0].words[0].startTime),
            end: parseFloat(r.alternatives[0].words.slice(-1)[0].startTime)}))
        console.log(result);
    });
    connectOSC(false);
}

customLoaderMap["eyebeamSVG"] = function(){

    // var svgTexture = loadImageToTexture(5, 'data:image/svg+xml;base64,');
    var svgImg = new Image();
    svgTexture = initVideoTexture(gl, "blankurl");
    var svgTex = {}
    svgTex.globject = svgTexture;
    svgTex.type = "tex_2D";
    svgTex.image = {height: mCanvas.height, width: mCanvas.width};
    svgTex.loaded = true;
    mInputs[5] = svgTex;

    var img2 = new Image();
    img2.src = "trees.jpg";

    var img3 = new Image();
    img3.src = "jesus.jpg"

    var img4 = new Image();
    img4.src = "data:image/svg+xml;base64,PHN2ZyBpZD0iZXllYmVhbSIgdmVyc2lvbj0iMS4xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB4PSIwcHgiIHk9IjBweCIgdmlld0JveD0iMCAwIDE5MjAgMTQ0MCIgc3R5bGU9ImVuYWJsZS1iYWNrZ3JvdW5kOm5ldyAwIDAgMTkyMCAxNDQwOyBkaXNwbGF5OiBub25lOyIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIgeG1sbnM6c3ZnanM9Imh0dHA6Ly9zdmdqcy5jb20vc3ZnanMiPgogICAgICAgICAgICA8ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogICAgICAgICAgICAgICAgPHBvbHlnb24gcG9pbnRzPSIzNy4xMywyMTguNjggMjE4Ljk2OTk5OTk5OTk5OTk3LDIxOC42OCAyMTguOTY5OTk5OTk5OTk5OTcsMTgyLjMwOTk5OTk5OTk5OTk3IDczLjUsMTgyLjMwOTk5OTk5OTk5OTk3IDczLjUsMTQ1Ljk0IDIxOC45Njk5OTk5OTk5OTk5NywxNDUuOTQgMjE4Ljk2OTk5OTk5OTk5OTk3LDEwOS41NyA3My41LDEwOS41NyA3My41LDczLjIgMjE4Ljk2OTk5OTk5OTk5OTk3LDczLjIgMjE4Ljk2OTk5OTk5OTk5OTk3LDM2Ljg0IDM3LjEzLDM2Ljg0IiBmaWxsLW9wYWNpdHk9IjAuOTc1Mjg0MTcwNjUxNDg1Ii8+CiAgICAgICAgICAgICAgICA8cG9seWdvbiBwb2ludHM9IjQxNy41Nzk5OTk5OTk5OTk5LDM2Ljg0IDM3Mi43MiwzNi44NCAzMjYuNjYsMTA1LjkzIDI4MC42LDM2Ljg0IDIzNS43NCwzNi44NCAzMDYuNiwxNDMuMTIgMzA2LjYsMjE4LjY4IDM0Ni43MiwyMTguNjggMzQ2LjcyLDE0My4xMiIgZmlsbC1vcGFjaXR5PSIwLjk1OTgwMjQ0OTUwMTY4MzMiLz4KICAgICAgICAgICAgICAgIDxwb2x5Z29uIHBvaW50cz0iNzcxLjY3MDAwMDAwMDAwMDEsMzYuODQgNzcxLjY3MDAwMDAwMDAwMDEsNzMuMiA0NjcuODksNzMuMiA0NjcuODksMTA5LjU3IDc3MS42NzAwMDAwMDAwMDAxLDEwOS41NyA3NzEuNjcwMDAwMDAwMDAwMSwxNDUuOTQgNDY3Ljg5LDE0NS45NCA0NjcuODksMTgyLjMwOTk5OTk5OTk5OTk3IDc3MS42NzAwMDAwMDAwMDAxLDE4Mi4zMDk5OTk5OTk5OTk5NyA3NzEuNjcwMDAwMDAwMDAwMSwyMTguNjggNDMxLjUyLDIxOC42OCA0MzEuNTIsMzYuODQiIGZpbGwtb3BhY2l0eT0iMC43MTY0MDg2MjM0ODMwNzA4Ii8+CiAgICAgICAgICAgICAgICA8cGF0aCBkPSJNNzkxLjc2IDIxOC42OEwxMDc1LjkwOTk5OTk5OTk5OTkgMjE4LjY4TDEwNzUuOTA5OTk5OTk5OTk5OSAyMTguNjhDMTEwNi4wNCAyMTguNjggMTEzMC40NTk5OTk5OTk5OTk4IDE5NC4yNTk5OTk5OTk5OTk5NiAxMTMwLjQ1OTk5OTk5OTk5OTggMTY0LjEzQzExMzAuNDU5OTk5OTk5OTk5OCAxNDcuODIgMTEyMy4yODk5OTk5OTk5OTk3IDEzMy4xOSAxMTExLjkzOTk5OTk5OTk5OTggMTIzLjE4OTk5OTk5OTk5OTk4QzExMTguMzc5OTk5OTk5OTk5OSAxMTQuMjQgMTEyMi4xNzk5OTk5OTk5OTk4IDEwMy4yNiAxMTIyLjE3OTk5OTk5OTk5OTggOTEuMzg5OTk5OTk5OTk5OTlDMTEyMi4xNzk5OTk5OTk5OTk4IDYxLjc3OTk5OTk5OTk5OTk5NCAxMDk4LjU5IDM3LjcgMTA2OS4xODk5OTk5OTk5OTk4IDM2Ljg4TDEwNjkuMTg5OTk5OTk5OTk5OCAzNi44NEw3OTEuNzYgMzYuODRMNzkxLjc2IDIxOC42OFpNMTA2Ny42NCA3My4yQzEwNzcuNjggNzMuMiAxMDg1LjgyMDAwMDAwMDAwMDIgODEuMzQgMTA4NS44MjAwMDAwMDAwMDAyIDkxLjM3OTk5OTk5OTk5OTk4UzEwNzcuNjggMTA5LjU2IDEwNjcuNjQgMTA5LjU2TDgyOC4xMyAxMDkuNTZMODI4LjEzIDczLjJMMTA2Ny42NCA3My4yWk04MjguMTMgMTgyLjMwOTk5OTk5OTk5OTk3TDgyOC4xMyAxNDUuOTRMMTA3NS45MSAxNDUuOTRMMTA3NS45MSAxNDUuOTRDMTA4NS45NSAxNDUuOTQgMTA5NC4wOTAwMDAwMDAwMDAxIDE1NC4wNzk5OTk5OTk5OTk5OCAxMDk0LjA5MDAwMDAwMDAwMDEgMTY0LjEyQzEwOTQuMDkwMDAwMDAwMDAwMSAxNzQuMTYgMTA4NS45NSAxODIuMyAxMDc1LjkxIDE4Mi4zTDgyOC4xMyAxODIuM1ogIiBmaWxsLW9wYWNpdHk9IjAuMzY1NzQ2NzA0OTUzNzAzNTQiLz4KICAgICAgICAgICAgICAgIDxwb2x5Z29uIHBvaW50cz0iMTQ5NC4wNSwyMTguNjggMTQ5NC4wNSwxODIuMzA5OTk5OTk5OTk5OTcgMTE4Mi42OSwxODIuMzA5OTk5OTk5OTk5OTcgMTE4Mi42OSwxNDUuOTQgMTQ5NC4wNSwxNDUuOTQgMTQ5NC4wNSwxMDkuNTcgMTE4Mi42OSwxMDkuNTcgMTE4Mi42OSw3My4yIDE0OTQuMDUsNzMuMiAxNDk0LjA1LDM2Ljg0IDExNDYuMzIsMzYuODQgMTE0Ni4zMiwyMTguNjgiIGZpbGwtb3BhY2l0eT0iMC4wODE2MzA2MjMwOTczODg4OSIvPgogICAgICAgICAgICAgICAgPHBhdGggZD0iTTE2NTEuNTMgMjE4LjY4TDE2OTAuNzMgMjE4LjY4TDE2MTcuOTkgMzYuODRMMTU4MS42MjAwMDAwMDAwMDAxIDM2Ljg0TDE1MDguODggMjE4LjY4TDE1NDguMDgwMDAwMDAwMDAwMiAyMTguNjhMMTU2Mi42MyAxODIuMzA5OTk5OTk5OTk5OTdMMTYzNi45OCAxODIuMzA5OTk5OTk5OTk5OTdMMTY1MS41MyAyMTguNjhaTTE1NzcuMTgwMDAwMDAwMDAwMyAxNDUuOTRMMTU5OS44MTAwMDAwMDAwMDAyIDg5LjM3TDE2MjIuNDQwMDAwMDAwMDAwMyAxNDUuOTRMMTU3Ny4xODAwMDAwMDAwMDAzIDE0NS45NFogIiBmaWxsLW9wYWNpdHk9IjAuMDA0ODg5MzUwNTg3NzA4MzQxIi8+CiAgICAgICAgICAgICAgICA8cG9seWdvbiBwb2ludHM9IjE3MDIuNjgsMzYuODQgMTcwMi42OCwyMTguNjggMTczOS4wNSwyMTguNjggMTczOS4wNSw3My4yIDE3NzUuNDIsNzMuMiAxNzc1LjQyLDIxOC42OCAxODExLjc4LDIxOC42OCAxODExLjc4LDczLjIgMTg0OC4xNSw3My4yIDE4NDguMTUsMjE4LjY4IDE4ODQuNTIsMjE4LjY4IDE4ODQuNTIsMzYuODQiIGZpbGwtb3BhY2l0eT0iMC4xNzM1NjE1Mzg1MTY5ODk5Ii8+CiAgICAgICAgICAgICAgICA8cG9seWdvbiBwb2ludHM9IjE4ODQuNTIsNDE3LjI5IDE4ODQuNTIsMzcyLjQyOTk5OTk5OTk5OTk1IDE4MTUuNDMsMzI2LjM3IDE4ODQuNTIsMjgwLjMgMTg4NC41MiwyMzUuNDUgMTc3OC4yMywzMDYuMyAxNzAyLjY4LDMwNi4zIDE3MDIuNjgsMzQ2LjQzIDE3NzguMjMsMzQ2LjQzIiBmaWxsLW9wYWNpdHk9IjAuNTA0MDQwNzQ0MzE4MDI2NyIvPgogICAgICAgICAgICAgICAgPHBvbHlnb24gcG9pbnRzPSIxODg0LjUyLDYxMy4wNyAxODQ4LjE1LDYxMy4wNyAxODQ4LjE1LDQ2Ny41OSAxODExLjc4LDQ2Ny41OSAxODExLjc4LDYxMy4wNyAxNzc1LjQyLDYxMy4wNyAxNzc1LjQyLDQ2Ny41OSAxNzM5LjA1LDQ2Ny41OSAxNzM5LjA1LDYxMy4wNyAxNzAyLjY4LDYxMy4wNyAxNzAyLjY4LDQzMS4yMzAwMDAwMDAwMDAxIDE4ODQuNTIsNDMxLjIzMDAwMDAwMDAwMDEiIGZpbGwtb3BhY2l0eT0iMC44MzI1MTcwODA5MjE0NTQ0Ii8+CiAgICAgICAgICAgICAgICA8cGF0aCBkPSJNMTcwMi42OCA2MzMuMTZMMTcwMi42OCA3NjAuNDQ5OTk5OTk5OTk5OUwxNzAyLjY4IDc2MC40NDk5OTk5OTk5OTk5QzE3MDIuNjggNzkwLjU3OTk5OTk5OTk5OTkgMTcyNy4xMDAwMDAwMDAwMDAxIDgxNC45OTk5OTk5OTk5OTk4IDE3NTcuMjMgODE0Ljk5OTk5OTk5OTk5OThDMTc3My41NCA4MTQuOTk5OTk5OTk5OTk5OCAxNzg4LjE3IDgwNy44Mjk5OTk5OTk5OTk4IDE3OTguMTcgNzk2LjQ3OTk5OTk5OTk5OThDMTgwNy4xMjAwMDAwMDAwMDAxIDgwMi45MiAxODE4LjEgODA2LjcxOTk5OTk5OTk5OTkgMTgyOS45NzAwMDAwMDAwMDAzIDgwNi43MTk5OTk5OTk5OTk5QzE4NTkuNTggODA2LjcxOTk5OTk5OTk5OTkgMTg4My42NiA3ODMuMTI5OTk5OTk5OTk5OSAxODg0LjQ4IDc1My43Mjk5OTk5OTk5OTk5TDE4ODQuNTIgNzUzLjcyOTk5OTk5OTk5OTlMMTg4NC41MiA2MzMuMTZMMTcwMi42OCA2MzMuMTZaTTE4NDguMTUgNzUyLjE2OTk5OTk5OTk5OThDMTg0OC4xNSA3NjIuMjA5OTk5OTk5OTk5OSAxODQwLjAxIDc3MC4zNDk5OTk5OTk5OTk5IDE4MjkuOTcwMDAwMDAwMDAwMyA3NzAuMzQ5OTk5OTk5OTk5OUMxODE5LjkyOTk5OTk5OTk5OTggNzcwLjM0OTk5OTk5OTk5OTkgMTgxMS43OSA3NjIuMjA5OTk5OTk5OTk5OSAxODExLjc5IDc1Mi4xNjk5OTk5OTk5OTk4TDE4MTEuNzkgNjY5LjUzTDE4NDguMTU5OTk5OTk5OTk5OSA2NjkuNTNMMTg0OC4xNTk5OTk5OTk5OTk5IDc1Mi4xNjk5OTk5OTk5OTk4Wk0xNzM5LjA1IDY2OS41M0wxNzc1LjQxOTk5OTk5OTk5OTYgNjY5LjUzTDE3NzUuNDE5OTk5OTk5OTk5NiA3NjAuNDQ5OTk5OTk5OTk5OUwxNzc1LjQxOTk5OTk5OTk5OTYgNzYwLjQ0OTk5OTk5OTk5OTlDMTc3NS40MTk5OTk5OTk5OTk2IDc3MC40ODk5OTk5OTk5OTk4IDE3NjcuMjc5OTk5OTk5OTk5NyA3NzguNjI5OTk5OTk5OTk5OSAxNzU3LjIzOTk5OTk5OTk5OTggNzc4LjYyOTk5OTk5OTk5OTlTMTczOS4wNTk5OTk5OTk5OTk3IDc3MC40ODk5OTk5OTk5OTk4IDE3MzkuMDU5OTk5OTk5OTk5NyA3NjAuNDQ5OTk5OTk5OTk5OUwxNzM5LjA1OTk5OTk5OTk5OTcgNjY5LjUzWiAiIGZpbGwtb3BhY2l0eT0iMC45OTYxNzMzNTY0MzE3NDUzIi8+CiAgICAgICAgICAgICAgICA8cG9seWdvbiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHBvaW50cz0iMTcwMi42OCwxMDEyLjY5MDAwMDAwMDAwMDIgMTczOS4wNSwxMDEyLjY5MDAwMDAwMDAwMDIgMTczOS4wNSw4NjcuMjE5OTk5OTk5OTk5OSAxNzc1LjQyLDg2Ny4yMTk5OTk5OTk5OTk5IDE3NzUuNDIsMTAxMi42OTAwMDAwMDAwMDAyIDE4MTEuNzgsMTAxMi42OTAwMDAwMDAwMDAyIDE4MTEuNzgsODY3LjIxOTk5OTk5OTk5OTkgMTg0OC4xNSw4NjcuMjE5OTk5OTk5OTk5OSAxODQ4LjE1LDEwMTIuNjkwMDAwMDAwMDAwMiAxODg0LjUyLDEwMTIuNjkwMDAwMDAwMDAwMiAxODg0LjUyLDgzMC44NSAxNzAyLjY4LDgzMC44NSIgZmlsbC1vcGFjaXR5PSIwLjkxMzg4OTQxNTI5NzM5MjgiLz4KICAgICAgICAgICAgICAgIDxwYXRoIGQ9Ik0xNzAyLjY4IDExNzAuMTdMMTcwMi42OCAxMjA5LjM3MDAwMDAwMDAwMDFMMTg4NC41MiAxMTM2LjYzTDE4ODQuNTIgMTEwMC4yNjAwMDAwMDAwMDAyTDE3MDIuNjggMTAyNy41MjAwMDAwMDAwMDAyTDE3MDIuNjggMTA2Ni43MjAwMDAwMDAwMDAzTDE3MzkuMDUgMTA4MS4yNzAwMDAwMDAwMDAyTDE3MzkuMDUgMTE1NS42MjAwMDAwMDAwMDAxTDE3MDIuNjggMTE3MC4xN1pNMTc3NS40MiAxMDk1LjgyTDE4MzEuOTkwMDAwMDAwMDAwMiAxMTE4LjQ1TDE3NzUuNDIgMTE0MS4wODAwMDAwMDAwMDAyTDE3NzUuNDIgMTA5NS44MlogIiBmaWxsLW9wYWNpdHk9IjAuNjI2NDUxMjkzOTk3NDc2OCIvPgogICAgICAgICAgICAgICAgPHBvbHlnb24gcG9pbnRzPSIxODg0LjUyLDEyMjEuMzIgMTg4NC41MiwxNDAzLjE2IDE3MDIuNjgsMTQwMy4xNiAxNzAyLjY4LDEzNjYuOCAxODQ4LjE1LDEzNjYuOCAxODQ4LjE1LDEzMzAuNDMgMTcwMi42OCwxMzMwLjQzIDE3MDIuNjgsMTI5NC4wNiAxODQ4LjE1LDEyOTQuMDYgMTg0OC4xNSwxMjU3LjY5IDE3MDIuNjgsMTI1Ny42OSAxNzAyLjY4LDEyMjEuMzIiIGZpbGwtb3BhY2l0eT0iMC4yNzYzMzQ1NDEyNTk2MTM1NCIvPgogICAgICAgICAgICAgICAgPHBvbHlnb24gcG9pbnRzPSIxNTA0LjA2OTk5OTk5OTk5OTcsMTQwMy4xNiAxNTQ4LjkzLDE0MDMuMTYgMTU5NC45OSwxMzM0LjA3IDE2NDEuMDUsMTQwMy4xNiAxNjg1LjkxLDE0MDMuMTYgMTYxNS4wNSwxMjk2Ljg4IDE2MTUuMDUsMTIyMS4zMiAxNTc0LjkyOTk5OTk5OTk5OTgsMTIyMS4zMiAxNTc0LjkyOTk5OTk5OTk5OTgsMTI5Ni44OCIgZmlsbC1vcGFjaXR5PSIwLjAzNzA4MjkzNDA3MTEzOTE2Ii8+CiAgICAgICAgICAgICAgICA8cG9seWdvbiBwb2ludHM9IjExNDkuOTgsMTQwMy4xNiAxMTQ5Ljk4LDEzNjYuOCAxNDUzLjc2LDEzNjYuOCAxNDUzLjc2LDEzMzAuNDMgMTE0OS45OCwxMzMwLjQzIDExNDkuOTgsMTI5NC4wNiAxNDUzLjc2LDEyOTQuMDYgMTQ1My43NiwxMjU3LjY5IDExNDkuOTgsMTI1Ny42OSAxMTQ5Ljk4LDEyMjEuMzIgMTQ5MC4xMywxMjIxLjMyIDE0OTAuMTMsMTQwMy4xNiIgZmlsbC1vcGFjaXR5PSIwLjAyNzI4NzI2NjAzNjI3ODM0NiIvPgogICAgICAgICAgICAgICAgPHBhdGggZD0iTTExMjkuODggMTIyMS4zMkw4NDUuNzMgMTIyMS4zMkw4NDUuNzMgMTIyMS4zMkM4MTUuNiAxMjIxLjMyIDc5MS4xODAwMDAwMDAwMDAxIDEyNDUuNzQgNzkxLjE4MDAwMDAwMDAwMDEgMTI3NS44N0M3OTEuMTgwMDAwMDAwMDAwMSAxMjkyLjE3OTk5OTk5OTk5OTggNzk4LjM1MDAwMDAwMDAwMDEgMTMwNi44MSA4MDkuNyAxMzE2LjgxQzgwMy4yNiAxMzI1Ljc2IDc5OS40NiAxMzM2Ljc0IDc5OS40NiAxMzQ4LjYxQzc5OS40NiAxMzc4LjIxOTk5OTk5OTk5OTggODIzLjA1MDAwMDAwMDAwMDEgMTQwMi4zIDg1Mi40NSAxNDAzLjEyTDg1Mi40NSAxNDAzLjE1OTk5OTk5OTk5OTlMMTEyOS44OCAxNDAzLjE1OTk5OTk5OTk5OTlMMTEyOS44OCAxMjIxLjMyWk04NTQuMDEgMTM2Ni44Qzg0My45NyAxMzY2LjggODM1LjgyOTk5OTk5OTk5OTkgMTM1OC42NTk5OTk5OTk5OTk5IDgzNS44Mjk5OTk5OTk5OTk5IDEzNDguNjJDODM1LjgyOTk5OTk5OTk5OTkgMTMzOC41OCA4NDMuOTcgMTMzMC40Mzk5OTk5OTk5OTk4IDg1NC4wMSAxMzMwLjQzOTk5OTk5OTk5OThMMTA5My41MiAxMzMwLjQzOTk5OTk5OTk5OThMMTA5My41MiAxMzY2LjgwOTk5OTk5OTk5OTdMODU0LjAxIDEzNjYuODA5OTk5OTk5OTk5N1pNMTA5My41MiAxMjU3LjY5TDEwOTMuNTIgMTI5NC4wNkw4NDUuNzMgMTI5NC4wNkw4NDUuNzMgMTI5NC4wNkM4MzUuNjkgMTI5NC4wNiA4MjcuNTUwMDAwMDAwMDAwMSAxMjg1LjkxOTk5OTk5OTk5OTggODI3LjU1MDAwMDAwMDAwMDEgMTI3NS44Nzk5OTk5OTk5OTk5UzgzNS42OSAxMjU3LjY5OTk5OTk5OTk5OTggODQ1LjczIDEyNTcuNjk5OTk5OTk5OTk5OEwxMDkzLjUyIDEyNTcuNjk5OTk5OTk5OTk5OFogIiBmaWxsLW9wYWNpdHk9IjAuMjUxODAyOTk0ODAzOTQyNzUiLz4KICAgICAgICAgICAgICAgIDxwb2x5Z29uIHBvaW50cz0iNDI3LjYsMTIyMS4zMiA0MjcuNiwxMjU3LjY5IDczOC45NiwxMjU3LjY5IDczOC45NiwxMjk0LjA2IDQyNy42LDEyOTQuMDYgNDI3LjYsMTMzMC40MyA3MzguOTYsMTMzMC40MyA3MzguOTYsMTM2Ni44IDQyNy42LDEzNjYuOCA0MjcuNiwxNDAzLjE2IDc3NS4zMywxNDAzLjE2IDc3NS4zMywxMjIxLjMyIiBmaWxsLW9wYWNpdHk9IjAuNTk5MzQzNDg4ODk3ODc1OSIvPgogICAgICAgICAgICAgICAgPHBhdGggZD0iTTI3MC4xMiAxMjIxLjMyTDIzMC45MjAwMDAwMDAwMDAwMiAxMjIxLjMyTDMwMy42NiAxNDAzLjE1OTk5OTk5OTk5OTlMMzQwLjAzIDE0MDMuMTU5OTk5OTk5OTk5OUw0MTIuNzcgMTIyMS4zMkwzNzMuNTcwMDAwMDAwMDAwMDUgMTIyMS4zMkwzNTkuMDIgMTI1Ny42ODk5OTk5OTk5OTk4TDI4NC42NzAwMDAwMDAwMDAxIDEyNTcuNjg5OTk5OTk5OTk5OEwyNzAuMTIgMTIyMS4zMlpNMzQ0LjQ3IDEyOTQuMDZMMzIxLjg0MDAwMDAwMDAwMDAzIDEzNTAuNjI5OTk5OTk5OTk5OUwyOTkuMjEwMDAwMDAwMDAwMDQgMTI5NC4wNkwzNDQuNDcgMTI5NC4wNlogIiBmaWxsLW9wYWNpdHk9IjAuODk3NjQyMDI3NDc2ODQ4OCIvPgogICAgICAgICAgICAgICAgPHBvbHlnb24gcG9pbnRzPSIyMTguOTY5OTk5OTk5OTk5OTcsMTQwMy4xNiAyMTguOTY5OTk5OTk5OTk5OTcsMTIyMS4zMiAxODIuNTk5OTk5OTk5OTk5OTcsMTIyMS4zMiAxODIuNTk5OTk5OTk5OTk5OTcsMTM2Ni44IDE0Ni4yMywxMzY2LjggMTQ2LjIzLDEyMjEuMzIgMTA5Ljg3LDEyMjEuMzIgMTA5Ljg3LDEzNjYuOCA3My41LDEzNjYuOCA3My41LDEyMjEuMzIgMzcuMTMsMTIyMS4zMiAzNy4xMywxNDAzLjE2IiBmaWxsLW9wYWNpdHk9IjAuOTk4ODM5NzY0MjU1NDY0MyIvPgogICAgICAgICAgICAgICAgPHBvbHlnb24gcG9pbnRzPSIzNy4xMywxMDIyLjcxIDM3LjEzLDEwNjcuNTcgMTA2LjIyLDExMTMuNjMgMzcuMTMsMTE1OS43IDM3LjEzLDEyMDQuNTUgMTQzLjQyLDExMzMuNyAyMTguOTY5OTk5OTk5OTk5OTcsMTEzMy43IDIxOC45Njk5OTk5OTk5OTk5NywxMDkzLjU3IDE0My40MiwxMDkzLjU3IiBmaWxsLW9wYWNpdHk9IjAuODUyNzc1NjE1NDQxODI0Ii8+CiAgICAgICAgICAgICAgICA8cG9seWdvbiBwb2ludHM9IjM3LjEzLDgyNi45MyA3My41LDgyNi45MyA3My41LDk3Mi40MTAwMDAwMDAwMDAxIDEwOS44Nyw5NzIuNDEwMDAwMDAwMDAwMSAxMDkuODcsODI2LjkzIDE0Ni4yMyw4MjYuOTMgMTQ2LjIzLDk3Mi40MTAwMDAwMDAwMDAxIDE4Mi41OTk5OTk5OTk5OTk5Nyw5NzIuNDEwMDAwMDAwMDAwMSAxODIuNTk5OTk5OTk5OTk5OTcsODI2LjkzIDIxOC45Njk5OTk5OTk5OTk5Nyw4MjYuOTMgMjE4Ljk2OTk5OTk5OTk5OTk3LDEwMDguNzcgMzcuMTMsMTAwOC43NyIgZmlsbC1vcGFjaXR5PSIwLjUzMTg0OTgwNzA3NTIxMzgiLz4KICAgICAgICAgICAgICAgIDxwYXRoIGQ9Ik0yMTguOTY5OTk5OTk5OTk5OTcgODA2Ljg0TDIxOC45Njk5OTk5OTk5OTk5NyA2NzkuNTVMMjE4Ljk2OTk5OTk5OTk5OTk3IDY3OS41NUMyMTguOTY5OTk5OTk5OTk5OTcgNjQ5LjQyIDE5NC41NSA2MjUgMTY0LjQyMDAwMDAwMDAwMDAyIDYyNUMxNDguMTEgNjI1IDEzMy40ODAwMDAwMDAwMDAwMiA2MzIuMTcgMTIzLjQ4MDAwMDAwMDAwMDAyIDY0My41MkMxMTQuNTMwMDAwMDAwMDAwMDIgNjM3LjA3OTk5OTk5OTk5OTkgMTAzLjU1MDAwMDAwMDAwMDAxIDYzMy4yOCA5MS42ODAwMDAwMDAwMDAwNCA2MzMuMjhDNjIuMDcwMDAwMDAwMDAwMDIgNjMzLjI4IDM3Ljk5MDAwMDAwMDAwMDAyIDY1Ni44NyAzNy4xNzAwMDAwMDAwMDAwMiA2ODYuMjdMMzcuMTMwMDAwMDAwMDAwMDI0IDY4Ni4yN0wzNy4xMzAwMDAwMDAwMDAwMjQgODA2LjgzOTk5OTk5OTk5OTlMMjE4Ljk2OTk5OTk5OTk5OTk3IDgwNi44Mzk5OTk5OTk5OTk5Wk03My41IDY4Ny44M0M3My41IDY3Ny43OTAwMDAwMDAwMDAxIDgxLjY0IDY2OS42NTAwMDAwMDAwMDAxIDkxLjY4IDY2OS42NTAwMDAwMDAwMDAxUzEwOS44NjAwMDAwMDAwMDAwMSA2NzcuNzkwMDAwMDAwMDAwMSAxMDkuODYwMDAwMDAwMDAwMDEgNjg3LjgzTDEwOS44NjAwMDAwMDAwMDAwMSA3NzAuNDdMNzMuNSA3NzAuNDdMNzMuNSA2ODcuODNaTTE4Mi41OTk5OTk5OTk5OTk5NyA3NzAuNDdMMTQ2LjIzIDc3MC40N0wxNDYuMjMgNjc5LjU1MDAwMDAwMDAwMDFMMTQ2LjIzIDY3OS41NTAwMDAwMDAwMDAxQzE0Ni4yMyA2NjkuNTEwMDAwMDAwMDAwMSAxNTQuMzcgNjYxLjM3MDAwMDAwMDAwMDEgMTY0LjQxIDY2MS4zNzAwMDAwMDAwMDAxQzE3NC40NSA2NjEuMzcwMDAwMDAwMDAwMSAxODIuNTkgNjY5LjUxMDAwMDAwMDAwMDEgMTgyLjU5IDY3OS41NTAwMDAwMDAwMDAxTDE4Mi41OSA3NzAuNDdaICIgZmlsbC1vcGFjaXR5PSIwLjE5NTEzNjg1NzMyMDExMDU1Ii8+CiAgICAgICAgICAgICAgICA8cG9seWdvbiBwb2ludHM9IjIxOC45Njk5OTk5OTk5OTk5Nyw0MjcuMzEwMDAwMDAwMDAwMDYgMTgyLjU5OTk5OTk5OTk5OTk3LDQyNy4zMTAwMDAwMDAwMDAwNiAxODIuNTk5OTk5OTk5OTk5OTcsNTcyLjc4IDE0Ni4yMyw1NzIuNzggMTQ2LjIzLDQyNy4zMTAwMDAwMDAwMDAwNiAxMDkuODcsNDI3LjMxMDAwMDAwMDAwMDA2IDEwOS44Nyw1NzIuNzggNzUuNzkwMTg3NjkxMzI1NCw1NzMuMTQ3MTY0Mzk1NTA0OCA3My41LDQyNy4zMTAwMDAwMDAwMDAwNiAzNy4xMyw0MjcuMzEwMDAwMDAwMDAwMDYgMzcuMTMsNjA5LjE1IDIxOC45Njk5OTk5OTk5OTk5Nyw2MDkuMTUiIGZpbGwtb3BhY2l0eT0iMC4wMDk1MzY2MzEzNDUzOTYzOTYiLz4KICAgICAgICAgICAgICAgIDxwYXRoIGQ9Ik0yMTguOTY5OTk5OTk5OTk5OTcgMjY5LjgzTDIxOC45Njk5OTk5OTk5OTk5NyAyMzAuNjNMMzcuMTMgMzAzLjM3TDM3LjEzIDMzOS43NEwyMTguOTY5OTk5OTk5OTk5OTcgNDEyLjQ4TDIxOC45Njk5OTk5OTk5OTk5NyAzNzMuMjgwMDAwMDAwMDAwMDNMMTgyLjU5OTk5OTk5OTk5OTk3IDM1OC43M0wxODIuNTk5OTk5OTk5OTk5OTcgMjg0LjM4TDIxOC45Njk5OTk5OTk5OTk5NyAyNjkuODNaTTE0Ni4yMyAzNDQuMThMODkuNjYgMzIxLjU1TDE0Ni4yMyAyOTguOTJMMTQ2LjIzIDM0NC4xOFogIiBmaWxsLW9wYWNpdHk9IjAuMDY3MDQ2MzI5NzEzNzY0NzMiLz4gICAgCiAgICAgICAgICAgIDwvZz4KICAgICAgICA8L3N2Zz4="
    window.img4 = img4;

    window.svgTexture = svgTexture;
    svgCanvas = document.createElement("canvas")//new Canvas(mCanvas.width, mCanvas.height);
    svgCanvas.width = mCanvas.width;
    svgCanvas.height = mCanvas.height;
    svgCanvas.id = "svgCanvas"
    var svgContext = svgCanvas.getContext("2d");
    document.body.append(svgCanvas);

    window.svgContext = svgContext;

    svgImg.onload = function(){
        svgContext.clearRect(0, 0, svgCanvas.width, svgCanvas.height);
        var randImg = Math.random() > 0.5 ? img2 : img3;
        svgContext.drawImage(randImg, 0, 0);
    }

    everyFrameSnapshot = function(){
        
        updateVideoTexture(gl, svgTexture, svgCanvas, "svg");
    }

    setup = svgP5setup;
    draw = bindDrawFunc(svgImg);
}

customLoaderMap['preBurningMan'] = function(){
    // playAtHalfRate = true;

    setup = guitarPaintSetup;
    draw = guitarPaintDraw;
    customLoaderUniforms = `
    uniform float fftValues[50];
    `;

    var fftValues = arrayOf(50);

    customLoaderUniformSet = function(time, mProgram){
        var fftValuesU = gl.getUniformLocation(mProgram, "fftValues");
        if(fftValuesU) gl.uniform1fv(fftValuesU, fftValues);
    }

    osc.on("/enterFullscreen", function(msg){
        enterFullscreen();
    });
    osc.on("/fftValues", function(msg){
        fftValues = msg.args;
    });

    sliderConfig = guitarPaintSliders;

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

    ignoreAudioForShader = true;
    connectOSC(false);
}

customLoaderMap['cosmicHaus'] = function(){
    // playAtHalfRate = true;

    setup = guitarPaintSetup;
    draw = guitarPaintDraw;
    customLoaderUniforms = `
    uniform float fftValues[512];
    uniform float fftSmallVals[512];
    uniform float fftLogVals[9];
    `;

    var fftValues = arrayOf(512);
    var fftLogVals = arrayOf(9);
    var fftSmallVals = arrayOf(64);

    customLoaderUniformSet = function(time, mProgram){
        var fftValuesU = gl.getUniformLocation(mProgram, "fftValues");
        if(fftValuesU) gl.uniform1fv(fftValuesU, fftValues);
        var fftLogValsU = gl.getUniformLocation(mProgram, "fftLogVals");
        if(fftLogValsU) gl.uniform1fv(fftLogValsU, fftLogVals);
        var fftSmallValsU = gl.getUniformLocation(mProgram, "fftSmallVals");
        if(fftSmallValsU) gl.uniform1fv(fftLogValsU, fftSmallVals);
    }

    osc.on("/enterFullscreen", function(msg){
        enterFullscreen();
    });
    osc.on("/fftValues", function(msg){
        fftValues = msg.args;
        fftLogVals = arrayOf(10);
        fftValues.forEach((e, i) => {
            let logInd = Math.floor(Math.log2(i+1));
            fftLogVals[logInd] += e/2**logInd / 905;
            fftValues[i] /= 905;
            fftSmallVals[Math.floor(i/8)] += e/8; 
        });
    });

    sliderConfig = guitarPaintSliders;

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

    ignoreAudioForShader = true;
    connectOSC(false);
}

// 