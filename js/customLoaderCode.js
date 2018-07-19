var customLoaderUniforms = "";

function setup(){}
function draw(){}

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


var blobVideoURLs = {};
function blobVideoLoad(videoInd, textureInd, videoFileURL, playAudio, otherArgs){
    var req = new XMLHttpRequest();
    req.open('GET', videoFileURL, true);
    req.responseType = 'blob';

    var createVideoElement = function(vid){
        const video = document.createElement('video');

        var playing = false;
        var timeupdate = false;

        video.autoplay = true;
        video.muted = true;
        video.loop = true;

        if(playAudio){
            loadImageToTexture(7, "clicktoplay.png");
            $("#demogl").click(function(){
                video.muted = false;
                video.play();
                if(otherArgs.videoPlayFunc) otherArgs.videoPlayFunc();
            });
        }

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


    if(blobVideoURLs[videoFileURL]){
        createVideoElement(blobVideoURLs[videoFileURL]);
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

                createVideoElement(vid);
                if(otherArgs.multiPlayheadCacheLoader) otherArgs.multiPlayheadCacheLoader();
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
    loadImageToTexture(7, "black.jpg");
    blobVideoLoad(1, 6, "gore.mp4", true, {'videoPlayFunc': videoPlayFunc});
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
    blobVideoLoad(0, 5, movieFiles, false, {'multiPlayheadCacheLoader': cacheLoader});

    customLoaderUniforms = `
uniform float lastNoteValue;
    `;
    
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

var fft;
function phialLoader(){
    setup = phialSetup;
    draw = phialDraw;
    fft = new Tone.FFT(32);
    var kickMidi;
    var leadMidi;
    MidiConvert.load("./phial/phial_kick.mid", function(midi){
        kickMidi = midi;
    })
    MidiConvert.load("./phial/phial_lead.mid", function(midi){
        leadMidi = midi;
    })
    // var player = new Tone.Player({
    //     "url" : "./phial_snip.[mp3|ogg]",
    //     "loop" : true,
    //     "autostart": true
    // }).fan(fft).toMaster();
}