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



function blobVideoLoad(videoInd, textureInd, videoFileURL, playAudio, videoPlayFunc){
    var req = new XMLHttpRequest();
    req.open('GET', videoFileURL, true);
    req.responseType = 'blob';

    req.onload = function() {
        // Onload is triggered even on 404
        // so we need to check the status code
        if (this.status === 200) {
            var videoBlob = this.response;
            var vid = URL.createObjectURL(videoBlob); // IE10+
            // Video is now downloaded
            // and we can set it as source on the video element


            const video = document.createElement('video');

            var playing = false;
            var timeupdate = false;

            video.autoplay = true;
            video.muted = true;
            video.loop = true;

            if(playAudio){
                $("#demogl").click(function(){
                    video.muted = false;
                    video.play();
                    if(videoPlayFunc) videoPlayFunc();
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
    }
    req.onerror = function() {
        // Error
    }

    req.send();
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

    customLoaderUniformSet = function(){
        var enoProgU = gl.getUniformLocation(mProgram, "enoProg");
        if(enoProgU) gl.uniform1f(enoProgU, enoTime/songLength);
    }

}

function goreLoader(){
    var goreSequencer = new Tone.Sequence(function(time, note){
        videos[1].currentTime = videos[1].currentTime + (-1 + Math.random()*2);
        videos[1].playBackRate = Math.min(5, Math.max(1/16, videos[1].playBackRate + (-0.1 + Math.random()*0.2)));
    }, [1, [1, 1]], "4n");
    var videoPlayFunc = function(){
        goreSequencer.start();
        console.log("gore sequencer started");
    }
    blobVideoLoad(1, 6, "gore.mp4", true, videoPlayFunc);
    loadImageToTexture(7, "clicktoplay.png");
    customLoaderUniformSet = function(){
        var enoProgU = gl.getUniformLocation(mProgram, "enoProg");
        if(enoProgU) gl.uniform1f(enoProgU, videos[1] ? videos[1].currentTime/100 : 0);
    }

}