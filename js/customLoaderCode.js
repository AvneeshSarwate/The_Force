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



function blobVideoLoad(videoInd, textureInd, videoFileURL){
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
            video.play();
        }
    }
    req.onerror = function() {
        // Error
    }

    req.send();
}

function deantoniLoader(){
    blobVideoLoad(1, 5, "GLASS_VEIN.mov");
}