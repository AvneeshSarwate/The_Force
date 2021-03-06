var fbos = [null, null];
var pingPong = 0;
var mQuadVBO = null;
var mQuadTVBO = null;
var mProgram = null;
var screenProgram = null;
var mInputs = [null, null, null, null, null, null, null, null, null, null, null];
var mInputsStr = "";
var mOSCStr = "";
var mMIDIStr = "";
var vsScreen = null;
var vsDraw = null;
var elapsedBandPeaks = [0.0, 0.0, 0.0, 0.0];
//unifoms
var vertPosU, l2, l3, l4, l5, l6, l7, l8, ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7, ch8, bs, screenResU, screenTexU, screenBlendU, translateUniform, scaleUniform, rotateUniform, gammaU, bandsTimeU, midiCCU;
var timeVec, zoom;
var controllableTime = 0, controllableTimeU;
var timeScale = 1;
var referenceTime = 0;
var randValueU, randValueVal = 0, randWalkU, randWalkVal = 0;
var markovState = 0, markovP = 0.05;
var zoomVal = 1;
var resos = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
resos = resos.concat(resos);
var oscM = [null, null, null, null, null, null, null, null, null, null];
var gammaValues = [1.0, 1.0, 1.0, 1.0];
var chordChromaColorU = null, noteColorsU = null, numNotesOnU = null, noteVelU = null;
var lastNoteOnTimeU, lastNoteOffTimeU, lastNoteValueU; 
var frameCount = 0, frameCountU = null;

var svgCanvas;

var vjNoteUniforms = Array.from(new Array(10), () => null);
var vjLastNoteUniforms = Array.from(new Array(5), () => null);
var lastPatternU = null;
var sliderValsU = null;
var midiFeaturesU = null;
var manualStepTime = 0, manualStepTimeU = null, manualHoldTime = 0, manualHoldTimeU = null, updateHoldTime = false;

var mHeader = null;
var webglVersionPrefix = "";
var fsNew = "void main () {\n\tgl_FragColor = vec4(black, 1.0);\n}";
var fsNewWGL2 = `
out vec4 fragColor;
void main () {
    fragColor = vec4(black, 1.0);
}
`;
var finalFragShader = '';

var testingImage = false;
var testTexture;

var webcamTexture;
var p5Texture;
var webcam;
var wcTex;
var p5Tex;
var p5SnapTex;
var p5SnapTexture;

var videos = [null, null, null, null];
var videoTextures = [null, null, null, null];
var videosReady = [false, false, false, false];

var webcamSnapshotTexture;
var takeSnapshot = true;

var defaultShaderCompiled = false;

//simple 2 state (0,1) markov model with single probability pChange
//that determines whether you stay on the same state or swap to the other
function markovWalk(pChange, state){
    return Math.random() < pChange ? !state + 0 : state;
}

var useWebGL2 = false;
function createGlContext(useWGL2) {
    var gGLContext = null;
    var names = ["webgl", "experimental-webgl", "webkit-3d", "moz-webgl"];
    if(useWGL2) names.unshift("webgl2");
    for (var i = 0; i < names.length; i++) {
        try {
            gGLContext = mCanvas.getContext(names[i], {
                alpha: false,
                depth: false,
                antialias: true,
                stencil: false,
                premultipliedAlpha: false,
                preserveDrawingBuffer: true
            });
        } catch (e) {
            gGLContext = null;
        }
        if (gGLContext){
            console.log("context type used", names[i]);
            break;
        }
    }

    if (gGLContext === null) {
        mIsPaused = true;
        console.log("no GL");
    }

    gl = gGLContext;
    resizeGLCanvas(window.innerWidth, window.innerHeight);

    var wglSuffix = useWGL2 ? "2" : "";

    //because I want to load shaders as files. :/
    $.when($.ajax({ url: "shaders/draw"+wglSuffix+".vert", dataType: "text" }),
        $.ajax({ url: "shaders/screen"+wglSuffix+".vert", dataType: "text" }),
        $.ajax({ url: "shaders/screen"+wglSuffix+".frag", dataType: "text" }),
        $.ajax({ url: "shaders/header.frag", dataType: "text" })).done(function(d, v, f, h) {

        if(useWebGL2) h[0] = "#version 300 es\n"+h[0];

        //build screen shader
        var res = createForceShader(v[0], f[0]);

        if (res.mSuccess === false) {
            console.log(res.mInfo);
            alert("error");
        }

        if (screenProgram !== null)
            gl.deleteProgram(screenProgram);

        screenProgram = res.mProgram;

        gl.useProgram(screenProgram);
        vertPosU = gl.getAttribLocation(screenProgram, "position");
        texLocationAttribute = gl.getAttribLocation(screenProgram, "a_texCoord");
        screenResU = gl.getUniformLocation(screenProgram, "resolution");
        screenTexU = gl.getUniformLocation(screenProgram, "texture");
        screenBlendU = gl.getUniformLocation(screenProgram, "edgeBlend");
        translateUniform = gl.getUniformLocation(screenProgram, "translation");
        scaleUniform = gl.getUniformLocation(screenProgram, "u_scale");
        rotateUniform = gl.getUniformLocation(screenProgram, "u_degrees");
        gammaU = gl.getUniformLocation(screenProgram, "colorCurves");
        //vertex data
        mQuadVBO = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, mQuadVBO);
        gl.bufferData(gl.ARRAY_BUFFER,
            new Float32Array([-1.0, -1.0,
                1.0, -1.0, -1.0, 1.0,
                1.0, 1.0
            ]),
            gl.STATIC_DRAW);
        gl.enableVertexAttribArray(vertPosU);
        gl.vertexAttribPointer(vertPosU, 2, gl.FLOAT, false, 0, 0);

        mQuadTVBO = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, mQuadTVBO);
        gl.bufferData(
            gl.ARRAY_BUFFER,
            new Float32Array([
                0.0, 0.0,
                1.0, 0.0,
                0.0, 1.0,
                1.0, 1.0
            ]),
            gl.STATIC_DRAW);
        gl.enableVertexAttribArray(texLocationAttribute);
        gl.vertexAttribPointer(texLocationAttribute, 2, gl.FLOAT, false, 0, 0);


        vsScreen = v[0];
        mHeader = h[0];
        vsDraw = d[0];
        var res = newShader(vsDraw, useWebGL2 ? fsNewWGL2 : fsNew);
        if (res.mSuccess === false) {
            console.log(res.mInfo);
            alert("error");
        }
    }); //end $.when

    testTexture = gl.createTexture();
    testImage = new Image();
    testImage.onload = function() { handleTextureLoaded(testImage, testTexture); }
    testImage.src = "images/test.jpg";
}


function createTarget(width, height) {
    var target = {};


    if (target.framebuffer && gl.isFramebuffer(target.framebuffer))
        gl.deleteFramebuffer(target.framebuffer);

    if (target.texture && gl.isTexture(target.texture))
        gl.deleteTexture(target.texture);

    target.framebuffer = gl.createFramebuffer();
    target.texture = gl.createTexture();

    // set up framebuffer
    gl.bindTexture(gl.TEXTURE_2D, target.texture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);

    gl.bindFramebuffer(gl.FRAMEBUFFER, target.framebuffer);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, target.texture, 0);

    // clean up
    gl.bindTexture(gl.TEXTURE_2D, null);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);

    return target;
}

function setShaderFromEditor(shaderCode) {
    var editorCode = shaderCode ? shaderCode : editor.getValue();
    var postSequenceResult = stripAndProcessSequencing(editorCode)
    var result = newShader(vsDraw, postSequenceResult.shaderCode);
    result.sequenceErrors = postSequenceResult.errors;
    sendOSCMessages();
    return setShader(result, false);
}

function stripAndProcessSequencing(code){
  var codeLines = code.split("\n");
  var i = 0; 
  var sequenceErrors = {};
  var patternLines = [];
  while(i < codeLines.length){
    var line  = codeLines[i];
    if(line.indexOf("pattern") > -1){
        codeLines.splice(i, 1);
        patternLines.push(line);
        var seqError = parseAndTriggerSequence(line);
        if(seqError){
          sequenceErrors[i] = seqError;
        }
    } else {
        i++
    }
  }
  return {shaderCode: codeLines.join("\n"), errors: sequenceErrors, patternStrings: patternLines};
}

function shaderMinusSequencing(code){
    var codeLines = code.split("\n");
    var i = 0; 
    var sequenceErrors = {};
    var patternLines = [];
    while(i < codeLines.length){
      var line  = codeLines[i];
      if(line.indexOf("pattern") > -1){
          codeLines.splice(i, 1);
      } else {
          i++
      }
    }
    return  codeLines.join("\n");
}  

var seq = 0;
var player;
var sequenceFunc = function(time, note){ };
// function(time, note){
//           // mMousePosX = Math.random() * 500;
//           // mMousePosY = Math.random() * 500;
//           // //console.log(mMousePosX, mMousePosY);
//           // //straight quater notes
//           // $('#tonedebug').html(note);
//           player.stop()
//           player.start(Tone.now(), note);
//           console.log("pattern note", note);
//         }

function parseAndTriggerSequence(patternString){
    console.log("pattern", patternString);
    var patternTrim = patternString.trim();
    var patternCode = patternTrim.substring("pattern(".length, patternTrim.length-1);
    if(seq || patternCode == "stop"){
      seq.stop();
      seq.dispose();
    } 
    if(patternCode == "stop"){
      return "stopped";
    }else {
      try { 
        seq = new Tone.Sequence(sequenceFunc, eval(patternCode), "4n");
        seq.start();
        return "success";
      } catch(err){
        return err; 
      } 
    }
}

function newShader(vs, shaderCode) {
    var fragShader = mHeader + customLoaderUniforms + mInputsStr + mOSCStr + mMIDIStr + shaderCode;
    finalFragShader = fragShader;
    var res = createForceShader(vs, fragShader); //, true);

    if (res.mSuccess === false) {
        return res;
    }

    defaultShaderCompiled = shaderCode === shaderMinusSequencing(defaultShader) || defaultShaderCompiled;
    if(defaultShaderCompiled){
      console.log("SHADER LEN " + defaultShader.length);
    }

    if (typeof(Storage) !== "undefined") {
        localStorage.lastValidCode = shaderCode;
    }


    if (mProgram !== null)
        gl.deleteProgram(mProgram);

    mProgram = res.mProgram;

    // vertPosU =  gl.getUniformLocation(mProgram, "position");
    l2 = gl.getUniformLocation(mProgram, "time");
    controllableTimeU = gl.getUniformLocation(mProgram, "controllableTime");
    timeVec = gl.getUniformLocation(mProgram, "timeVec");
    zoom = gl.getUniformLocation(mProgram, "zoom");
    randValueU = gl.getUniformLocation(mProgram, "randValue");
    randWalkU = gl.getUniformLocation(mProgram, "randWalk");
    l3 = gl.getUniformLocation(mProgram, "resolution");
    l4 = gl.getUniformLocation(mProgram, "mouse");
    l5 = gl.getUniformLocation(mProgram, "channelTime");
    l7 = gl.getUniformLocation(mProgram, "date");
    l8 = gl.getUniformLocation(mProgram, "channelResolution");

    ch0 = gl.getUniformLocation(mProgram, "channel0");
    ch1 = gl.getUniformLocation(mProgram, "channel1");
    ch2 = gl.getUniformLocation(mProgram, "channel2");
    ch3 = gl.getUniformLocation(mProgram, "channel3");
    ch4 = gl.getUniformLocation(mProgram, "backbuffer");
    //TODO cam-background - add something here (why?)
    ch5 = gl.getUniformLocation(mProgram, "channel5");
    ch6 = gl.getUniformLocation(mProgram, "channel6");
    ch7 = gl.getUniformLocation(mProgram, "channel7");
    ch8 = gl.getUniformLocation(mProgram, "channel8");

    for(var i = 0; i < 5; i++){
      vjNoteUniforms[i*2] = gl.getUniformLocation(mProgram, "vjvel"+i);
      vjNoteUniforms[i*2+1] = gl.getUniformLocation(mProgram, "vjlastvel"+i);
    }
    vjLastNoteUniform = gl.getUniformLocation(mProgram, "vjlastnote");


    bs = gl.getUniformLocation(mProgram, "bands");
    bandsTimeU = gl.getUniformLocation(mProgram, "bandsTime");

    chordChromaColorU = gl.getUniformLocation(mProgram, "chordChromaColor");
    noteColorsU = gl.getUniformLocation(mProgram, "noteColors");
    numNotesOnU = gl.getUniformLocation(mProgram, "numNotesOn");
    noteVelU = gl.getUniformLocation(mProgram, "noteVel");

    lastPatternU = gl.getUniformLocation(mProgram, "lastPattern");
    sliderValsU = gl.getUniformLocation(mProgram, "sliderVals");
    midiFeaturesU = gl.getUniformLocation(mProgram, "midiFeatures");
    manualStepTimeU = gl.getUniformLocation(mProgram, "manualStepTime");
    manualHoldTimeU = gl.getUniformLocation(mProgram, "manualHoldTime");

    lastNoteOnTimeU = gl.getUniformLocation(mProgram, "lastNoteOnTime");
    lastNoteOffTimeU = gl.getUniformLocation(mProgram, "lastNoteOffTime");
    lastNoteValueU = gl.getUniformLocation(mProgram, "lastNoteValue");

    frameCountU = gl.getUniformLocation(mProgram, "frameCount");

    //OSC uniforms
    for (var i = 0; i < oscM.length; i++) {
        if (oscM[i] !== null) {
            oscM[i].uniLoc = gl.getUniformLocation(mProgram, oscM[i].uniName);
        }
    }

    //MIDI uniform
    if (midi !== null) {
        midiCCU = gl.getUniformLocation(mProgram, "midiCC");
    }

    return res; //means success
}

function createForceShader(vertShader, fragShader) {
    if (gl === null) return;

    var tmpProgram = gl.createProgram();

    var vs = gl.createShader(gl.VERTEX_SHADER);
    var fs = gl.createShader(gl.FRAGMENT_SHADER);

    gl.shaderSource(vs, vertShader);
    gl.shaderSource(fs, fragShader);

    gl.compileShader(vs);
    gl.compileShader(fs);

    if (!gl.getShaderParameter(vs, gl.COMPILE_STATUS)) {
        var infoLog = gl.getShaderInfoLog(vs);
        gl.deleteProgram(tmpProgram);
        return {
            mSuccess: false,
            mInfo: infoLog
        };
    }

    if (!gl.getShaderParameter(fs, gl.COMPILE_STATUS)) {
        var infoLog = gl.getShaderInfoLog(fs);
        gl.deleteProgram(tmpProgram);
        return {
            mSuccess: false,
            mInfo: infoLog
        };
    }

    gl.attachShader(tmpProgram, vs);
    gl.attachShader(tmpProgram, fs);

    gl.deleteShader(vs);
    gl.deleteShader(fs);

    gl.linkProgram(tmpProgram);

    if (!gl.getProgramParameter(tmpProgram, gl.LINK_STATUS)) {
        var infoLog = gl.getProgramInfoLog(tmpProgram);
        gl.deleteProgram(tmpProgram);
        return {
            mSuccess: false,
            mInfo: infoLog
        };
    }

    return {
        mSuccess: true,
        mProgram: tmpProgram
    }
}

function destroyInput(id) {
    if (mInputs[id] === null) return;
    if (gl === null) return;

    var inp = mInputs[id];

    if (inp.type == "texture") {
        gl.deleteTexture(inp.globject);
    } else if (inp.type == "slideshow") {
        gl.deleteTexture(inp.globject);
    } else if (inp.type == "webcam") {
        gl.deleteTexture(inp.globject);
    } else if (inp.type == "video") { //TODO AVN: make sure this is handled correctly for this/webcam
        inp.video.pause();
        inp.video = null;
        gl.deleteTexture(inp.globject);
    } else if (inp.type == "music") {
        inp.audio.pause();
        inp.audio = null;
        gl.deleteTexture(inp.globject);
    } else if (inp.type == "cubemap") {
        gl.deleteTexture(inp.globject);
    } else if (inp.type == "tex_keyboard") {
        gl.deleteTexture(inp.globject);
    }

    mInputs[id] = null;
}

function createInputStr() {
    mInputsStr = "";
    for (var i = 0; i < mInputs.length; i++) {
        var inp = mInputs[i];

        if (inp !== null && inp.type == "cubemap")
            mInputsStr += "uniform samplerCube channel" + i + ";\n";
        else
            mInputsStr += "uniform sampler2D channel" + i + ";\n";
    }
    var db = 5;
    //TODO cam-background - declare uniform for background here
}

function createOSCUniforms() {
    mOSCStr = "";
    for (var i = 0; i < oscM.length; i++) {
        var inp = oscM[i];

        if (inp !== null) {
            // mOSCStr += "uniform vec4 " + $('#inOSCUniform'+i).val() + ";\n";
            // mOSCStr += "uniform vec4 " + oscM[i].uniName + ";\n";
            mOSCStr += "uniform vec4 " + inp.uniName + ";";
            // mOSCStr = "uniform vec4 analogInput;";
        }
    }
}

function createMIDIUniforms() {
    mMIDIStr = "";
    if (midiIn !== null) {
        mMIDIStr = "uniform float midi[128];";
    }

}

function getHeaderSize() {
    var n = (mHeader + customLoaderUniforms + mInputsStr + mOSCStr + mMIDIStr).split(/\r\n|\r|\n/).length;
    return n;
}


function setupVideo(url, ind) {
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

  if(url) {
    video.src = url;
    video.play();
  }

  function checkReady() {
    if (playing && timeupdate) {
      videosReady[ind] = true;
    }
  }

  return video;
}

// will set to true when video can be copied to texture
var webcamReady = false;

function setupWebcam() {
  const video = document.createElement('video');


  var hasUserMedia = navigator.mediaDevices.getUserMedia ? true : false;

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

  var constraints = {video: { width: 1280, height: 720 } }; 

  navigator.mediaDevices.getUserMedia(constraints)
  .then(function(mediaStream) {
    video.srcObject = mediaStream;
    video.onloadedmetadata = function(e) {
      video.play();
    };
  })
  .catch(function(err) { console.log(err.name + ": " + err.message); }); // always check for errors at the end.

  function checkReady() {
    if (playing && timeupdate) {
      webcamReady = hasUserMedia;
    }
  }

  return video;
}

function changeWebcamSelection(camInd){
    navigator.mediaDevices.enumerateDevices()
        .then(function(deviceList){return deviceList.filter(device => device.kind == "videoinput")}) 
        .catch(function(err) { console.log(err.name + ": " + err.message); })  
        .then(function(cameras){
            var constraints = {video: { width: 1280, height: 720,  deviceId: cameras[camInd].deviceId} }; 
            navigator.mediaDevices.getUserMedia(constraints)
              .then(function(mediaStream) {
                webcam.srcObject = mediaStream;
                webcam.onloadedmetadata = function(e) {
                  webcam.play();
                };
              })
        });
}


function initVideoTexture(gl, url) {
  const texture = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, texture);

  // Because video has to be download over the internet
  // they might take a moment until it's ready so
  // put a single pixel in the texture so we can
  // use it immediately.
  const level = 0;
  const internalFormat = gl.RGBA;
  const width = 1;
  const height = 1;
  const border = 0;
  const srcFormat = gl.RGBA;
  const srcType = gl.UNSIGNED_BYTE;
  const pixel = new Uint8Array([0, 0, 255, 255]);  // opaque blue
  gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
                width, height, border, srcFormat, srcType,
                pixel);

  // Turn off mips and set  wrapping to clamp to edge so it
  // will work regardless of the dimensions of the video.
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);

  return texture;
}

function createNewVideoTexture(gl, url, ind){
    var textureObj = initVideoTexture(gl, url);
    var video = setupVideo(url, ind);
    var texture = {};
    texture.globject = textureObj;
    texture.type = "tex_2D";
    texture.image = {height: video.height, video: video.width};
    texture.loaded = true; //this is ok to do because the update loop checks videosReady[]
    videos[ind] = video;
    videoTextures[ind] = texture;
}

function createVideoSnapshotTexture(gl, video){
    var textureObj = initVideoTexture(gl, null);
    var texture = {};
    texture.globject = textureObj;
    texture.type = "tex_2D";
    texture.image = {height: video.height, video: video.width};
    texture.loaded = true; //this is ok to do because the update loop checks videosReady[]
    return texture;
}

function updateVideoTexture(gl, texture, video, debugFlag) {
    const level = 0;
    const internalFormat = gl.RGBA;
    const srcFormat = gl.RGBA;
    const srcType = gl.UNSIGNED_BYTE;
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
                    srcFormat, srcType, video);
    if(debugFlag == "svg"){
        x = 5;
    }
    if(debugFlag == "p5"){
        x = 5;
    }
}

function handleTextureLoaded(image, texture) {
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.bindTexture(gl.TEXTURE_2D, null);
}

function createGLTexture(ctx, image, format, texture) {
    if (ctx === null) return;

    ctx.bindTexture(ctx.TEXTURE_2D, texture);
    ctx.pixelStorei(ctx.UNPACK_FLIP_Y_WEBGL, false);
    ctx.texImage2D(ctx.TEXTURE_2D, 0, format, ctx.RGBA, ctx.UNSIGNED_BYTE, image);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MAG_FILTER, ctx.LINEAR);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MIN_FILTER, ctx.LINEAR_MIPMAP_LINEAR);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_WRAP_S, ctx.REPEAT);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_WRAP_T, ctx.REPEAT);
    ctx.generateMipmap(ctx.TEXTURE_2D);
    ctx.bindTexture(ctx.TEXTURE_2D, null);
}

function createGLTextureLinear(ctx, image, texture) {
    if (ctx === null) return;

    ctx.bindTexture(ctx.TEXTURE_2D, texture);
    ctx.pixelStorei(ctx.UNPACK_FLIP_Y_WEBGL, false);
    ctx.texImage2D(ctx.TEXTURE_2D, 0, ctx.RGBA, ctx.RGBA, ctx.UNSIGNED_BYTE, image);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MAG_FILTER, ctx.LINEAR);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MIN_FILTER, ctx.LINEAR);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_WRAP_S, ctx.CLAMP_TO_EDGE);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_WRAP_T, ctx.CLAMP_TO_EDGE);
    ctx.bindTexture(ctx.TEXTURE_2D, null);
}


function createGLTextureNearestRepeat(ctx, image, texture) {
    if (ctx === null) return;

    ctx.bindTexture(ctx.TEXTURE_2D, texture);
    ctx.pixelStorei(ctx.UNPACK_FLIP_Y_WEBGL, false);
    ctx.texImage2D(ctx.TEXTURE_2D, 0, ctx.RGBA, ctx.RGBA, ctx.UNSIGNED_BYTE, image);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MAG_FILTER, ctx.NEAREST);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MIN_FILTER, ctx.NEAREST);
    ctx.bindTexture(ctx.TEXTURE_2D, null);
}

function createGLTextureNearest(ctx, image, texture) {
    if (ctx === null) return;

    ctx.bindTexture(ctx.TEXTURE_2D, texture);
    ctx.pixelStorei(ctx.UNPACK_FLIP_Y_WEBGL, true);
    ctx.texImage2D(ctx.TEXTURE_2D, 0, ctx.RGBA, ctx.RGBA, ctx.UNSIGNED_BYTE, image);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MAG_FILTER, ctx.NEAREST);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MIN_FILTER, ctx.NEAREST);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_WRAP_S, ctx.CLAMP_TO_EDGE);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_WRAP_T, ctx.CLAMP_TO_EDGE);
    ctx.bindTexture(ctx.TEXTURE_2D, null);
}

function createAudioTexture(ctx, texture) {
    if (ctx === null) return;

    ctx.bindTexture(ctx.TEXTURE_2D, texture);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MAG_FILTER, ctx.NEAREST);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MIN_FILTER, ctx.NEAREST);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_WRAP_S, ctx.CLAMP_TO_EDGE);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_WRAP_T, ctx.CLAMP_TO_EDGE);
    ctx.texImage2D(ctx.TEXTURE_2D, 0, ctx.LUMINANCE, 512, 2, 0, ctx.LUMINANCE, ctx.UNSIGNED_BYTE, null);
    ctx.bindTexture(ctx.TEXTURE_2D, null);
}

function createKeyboardTexture(ctx, texture) {
    if (ctx === null) return;

    ctx.bindTexture(ctx.TEXTURE_2D, texture);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MAG_FILTER, ctx.NEAREST);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MIN_FILTER, ctx.NEAREST);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_WRAP_S, ctx.CLAMP_TO_EDGE);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_WRAP_T, ctx.CLAMP_TO_EDGE);
    ctx.texImage2D(ctx.TEXTURE_2D, 0, ctx.LUMINANCE, 256, 2, 0, ctx.LUMINANCE, ctx.UNSIGNED_BYTE, null);
    ctx.bindTexture(ctx.TEXTURE_2D, null);
}

function resizeGLCanvas(width, height) {
    mCanvas.width = width / quality;
    mCanvas.height = height / quality;

    if(svgCanvas) {
        svgCanvas.width = mCanvas.width;
        svgCanvas.height = mCanvas.height;
    }

    mCanvas.style.width = width + 'px';
    mCanvas.style.height = height + 'px';

    gl.viewport(0, 0, mCanvas.width, mCanvas.height);

    fbos[0] = createTarget(mCanvas.width, mCanvas.height);
    fbos[1] = createTarget(mCanvas.width, mCanvas.height);
}

function updateKeyboardDown(event) {
    for (var i = 0; i < mInputs.length; i++) {
        var inp = mInputs[i];
        if (inp !== null && inp.type == "tex_keyboard") {
            inp.mData[event] = 255;
        }
    }
}

function updateKeyboardUp(event) {
    for (var i = 0; i < mInputs.length; i++) {
        var inp = mInputs[i];
        if (inp !== null && inp.type == "tex_keyboard") {
            inp.mData[event] = 0;
        }
    }
}

var d = null, dates = null;

var shaderTime = 0;
var shaderTimeUpdates = 0;
setInterval(function(){
  shaderTime = (Date.now() - mTime) * 0.001;
  shaderTimeUpdates += 1;
}, 34);


var customLoaderUniformSet = function(){};

function paint(timeVal) {
    if (gl === null) return;
    if (mProgram === null) return;

    frameStateUpdate();

    matchPattern();

    gl.useProgram(mProgram);

    var d = new Date();
    var dates = [
        d.getFullYear(), // the year (four digits)
        d.getMonth(), // the month (from 0-11)
        d.getDate(), // the day of the month (from 1-31)
        d.getHours() * 60.0 * 60 + d.getMinutes() * 60 + d.getSeconds()
    ];

    //init dimensions
    resos = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    resos = resos.concat(resos);

    var toneTime = Tone.Transport.seconds;
    //add uniform stuff
    
    controllableTime += ((Date.now() - mTime) * 0.001 - referenceTime) * timeScale;
    if(controllableTimeU !== null) gl.uniform1f(controllableTimeU, controllableTime);
    if (l2 !== null) gl.uniform1f(l2, (Date.now() - mTime) * 0.001);
    referenceTime = (Date.now() - mTime) * 0.001;
    if (timeVec !== null) gl.uniform2f(timeVec, toneTime, timeVal);
    if (zoom !== null && zoomVal != 'undefined') gl.uniform1f(zoom, zoomVal);
    markovState = markovWalk(markovP, markovState)
    if (randWalkU !== null) gl.uniform1f(randWalkU, randWalkVal += markovState ? 1 : -1);
    // console.log(markovState);
    if (randValueU !== null) gl.uniform1f(randValueU, Math.random());
    if (l3 !== null) gl.uniform2f(l3, mCanvas.width, mCanvas.height);
    if (l4 !== null) gl.uniform4f(l4, mMousePosX, mMousePosY, mMouseClickX, mMouseClickY);
    if (l7 !== null) gl.uniform4f(l7, d.getFullYear(), d.getMonth(), d.getDate(),
        d.getHours() * 60 * 60 + d.getMinutes() * 60 + d.getSeconds());

    if (ch0 !== null) gl.uniform1i(ch0, 0);
    if (ch1 !== null) gl.uniform1i(ch1, 1);
    if (ch2 !== null) gl.uniform1i(ch2, 2);
    if (ch3 !== null) gl.uniform1i(ch3, 3);
    if (ch4 !== null) gl.uniform1i(ch4, 4); //backbuffer
    if (ch5 !== null) gl.uniform1i(ch5, 5);
    if (ch6 !== null) gl.uniform1i(ch6, 6);
    if (ch7 !== null) gl.uniform1i(ch7, 7);
    if (ch8 !== null) gl.uniform1i(ch8, 8);
    //TODO cam-background - add something here (why?) (setting gl.TEXTURE[i] value?)

    var col = chromaToColor(chroma);
    if(chordChromaColorU !== null) gl.uniform3f(chordChromaColorU, col[0], col[1], col[2]);

    //the uniform assumes 10 note colors - we pad with 0s if there are not enough notes
    var noteColorData = [].concat.apply([], getNoteColors().slice(0, 10)); //flatten the color values to a single array
    //var noteColorBuffer = noteColorData.concat(Array.from(new Array(Math.max(30-noteColorData.length, 0)), () => 0)); //add padding TODO: is 0 padding even needed?
    if(noteColorsU !== null) gl.uniform3fv(noteColorsU, noteColorData.length > 0 ? noteColorData : Array.from(new Array(30), () => 0));

    if(numNotesOnU !== null) gl.uniform1f(numNotesOnU, onNoteSet.size);
    var noteVelocities = getNoteVelocities().slice(0, 10);
    if(noteVelU !== null) gl.uniform1fv(noteVelU, noteVelocities.length > 0 ? noteVelocities : Array.from(new Array(10), () => 0));

    if(lastPatternU !== null) gl.uniform1f(lastPatternU, lastMatchedPattern);
    if(lastNoteOnTimeU !== null) gl.uniform1fv(lastNoteOnTimeU, lastNoteOnTime);
    if(lastNoteOffTimeU !== null) gl.uniform1fv(lastNoteOffTimeU, lastNoteOffTime);
    if(lastNoteValueU !== null) gl.uniform1f(lastNoteValueU, lastNoteValue);
    if(midiCCU !== null) gl.uniform1fv(midiCCU, midiCC);
    if(sliderValsU !== null) gl.uniform1fv(sliderValsU, sliderVals);
    if(midiFeaturesU !== null) gl.uniform1fv(midiFeaturesU, midiFeatures);
    if(updateHoldTime) manualHoldTime = (Date.now() - mTime) * 0.001;
    if(manualStepTimeU !== null) gl.uniform1f(manualStepTimeU, manualStepTime);
    if(manualHoldTimeU !== null) gl.uniform1f(manualHoldTimeU, manualHoldTime);

    if(frameCountU !== null) gl.uniform1i(frameCountU, frameCount++);


    for(var i = 0; i < 5; i++){
      // vjNoteUniforms[i*2] = gl.getUniformLocation(mProgram, "vjvel"+i);
      if(vjNoteUniforms[i*2] !== null) gl.uniform1fv(vjNoteUniforms[i*2], vjPadNoteInfo[i].notes.map(note => note.vel));
      // vjNoteUniforms[i*2+1] = gl.getUniformLocation(mProgram, "vjlastvel"+i);
      if(vjNoteUniforms[i*2+1] !== null) gl.uniform1fv(vjNoteUniforms[i*2+1], vjPadNoteInfo[i].notes.map(note => note.lastVel));
    }
    // vjLastNoteUniform = gl.getUniformLocation(mProgram, "vjlastnote");
    if(vjLastNoteUniform !== null) gl.uniform1fv(vjLastNoteUniform, vjPadNoteInfo.map(chan => chan.last));

    // gl.bindBuffer( gl.ARRAY_BUFFER, mQuadVBO);
    // gl.vertexAttribPointer(vertPosU, 2,  gl.FLOAT, false, 0, 0);

    customLoaderUniformSet((Date.now() - mTime) * 0.001, mProgram);

    //minputs
    //fourband sound
    if (mSound && bandsOn && mAudioContext !== null) {
        if (bs !== null) {

            gl.uniform4f(bs, mSound.low, mSound.mid, mSound.upper, mSound.high);
        }
        if (bandsTimeU !== null) { //this is for per fft band time elapsed events
            if (mSound.low > .7)
                elapsedBandPeaks[0] = 0.0;
            else
                elapsedBandPeaks[0] += meter.duration * .001;

            if (mSound.mid > .7)
                elapsedBandPeaks[1] = 0.0;
            else
                elapsedBandPeaks[1] += meter.duration * .001;

            if (mSound.upper > .7)
                elapsedBandPeaks[2] = 0.0;
            else
                elapsedBandPeaks[2] += meter.duration * .001;

            if (mSound.high > .7)
                elapsedBandPeaks[3] = 0.0;
            else
                elapsedBandPeaks[3] += meter.duration * .001;

            gl.uniform4f(bandsTimeU, elapsedBandPeaks[0], elapsedBandPeaks[1], elapsedBandPeaks[2], elapsedBandPeaks[4]);
        }
        // }
    }

    for (var i = 0; i < mInputs.length; i++) {
        var inp = mInputs[i];

        gl.activeTexture(gl.TEXTURE0 + i);

        if (inp === null) {
            gl.bindTexture(gl.TEXTURE_2D, null);
        } else if (inp.type == "tex_2D") {
            if (inp.loaded === false)
                gl.bindTexture(gl.TEXTURE_2D, null);
            else {
                gl.bindTexture(gl.TEXTURE_2D, inp.globject);
                resos[3 * i + 0] = inp.image.width;
                resos[3 * i + 1] = inp.image.height;
                resos[3 * i + 2] = 1;
            }
        } else if (inp.type == "tex_audio") {
            mSound.mAnalyser.getByteTimeDomainData(mSound.mWaveData);
            mSound.mAnalyser.getByteFrequencyData(mSound.mFreqData);
            gl.bindTexture(gl.TEXTURE_2D, inp.globject);
            var waveLen = Math.min(mSound.mWaveData.length, 512);
            gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, waveLen, 1, gl.LUMINANCE, gl.UNSIGNED_BYTE, mSound.mWaveData);
            gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 1, 512, 1, gl.LUMINANCE, gl.UNSIGNED_BYTE, mSound.mFreqData);
        } else if (inp.type == "tex_keyboard") {
            // if (inp.loaded === false)
            //     gl.bindTexture(gl.TEXTURE_2D, null);
            // else {
            gl.bindTexture(gl.TEXTURE_2D, inp.globject);

            gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);
            gl.texSubImage2D(gl.TEXTURE_2D, 0, 0, 0, 256, 2, gl.LUMINANCE, gl.UNSIGNED_BYTE, inp.mData);
            // }
        }
    }

    // OSC values
    for (var i = 0; i < oscM.length; i++) {
        if (oscM[i] !== null) {
            gl.uniform4fv(oscM[i].uniLoc, oscM[i].args);
        }
    }

    //MIDI values
    if (midi !== null) {
        gl.uniform1fv(midiCCU, midiCC);
    }

    // if (l5 !== null)  gl.uniform1fv(l5, times);
    if (l8 !== null) gl.uniform3fv(l8, resos);

    gl.activeTexture(gl.TEXTURE4); //backbuffer as texture
    gl.bindTexture(gl.TEXTURE_2D, fbos[pingPong].texture);

    pingPong = (pingPong + 1) % 2;

    gl.bindFramebuffer(gl.FRAMEBUFFER, fbos[pingPong].framebuffer);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

    //draw to screen
    if (numScreens == 1) {
        // gl.blendFunc(gl.ONE, gl.ONE);
        gl.disable(gl.BLEND);
        gl.useProgram(screenProgram);
        gl.uniform2f(screenResU, mCanvas.width, mCanvas.height);
        gl.uniform1i(screenTexU, 0);
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, fbos[pingPong].texture);

        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
        gl.clear(gl.COLOR_BUFFER_BIT);
        //center
        gl.uniform2f(translateUniform, $("#point1X").val(), $("#point1Y").val());
        gl.uniform2f(scaleUniform, $("#scale1X").val(), $("#scale1Y").val());
        gl.uniform1f(rotateUniform, $("#rotate1").val());
        gl.uniform4f(screenBlendU, 0.0, .001, 1.0, .001);
        // $("#blend2X").val(), $("#blend2Y").val(),
        // $("#blend2Z").val(), $("#blend2W").val());
        gl.uniform4fv(gammaU, gammaValues);
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    } else if (numScreens == 3) {
        gl.blendFunc(gl.ONE, gl.ONE);
        gl.enable(gl.BLEND);

        gl.enableVertexAttribArray(texLocationAttribute);

        gl.useProgram(screenProgram);

        gl.bindBuffer(gl.ARRAY_BUFFER, mQuadVBO);
        gl.vertexAttribPointer(vertPosU, 2, gl.FLOAT, false, 0, 0);
        gl.bindBuffer(gl.ARRAY_BUFFER, mQuadTVBO);
        gl.vertexAttribPointer(texLocationAttribute, 2, gl.FLOAT, false, 0, 0);


        gl.uniform2f(screenResU, mCanvas.width, mCanvas.height);
        gl.uniform1i(screenTexU, 0);
        gl.activeTexture(gl.TEXTURE0);

        if (testingImage)
            gl.bindTexture(gl.TEXTURE_2D, testTexture);
        else
            gl.bindTexture(gl.TEXTURE_2D, fbos[pingPong].texture);

        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // left
        gl.uniform2f(translateUniform, $("#point1X").val(), $("#point1Y").val());
        gl.uniform2f(scaleUniform, $("#scale1X").val(), $("#scale1Y").val());
        gl.uniform4f(screenBlendU, $("#blend1X").val(), $("#blend1Y").val(),
            $("#blend1Z").val(), $("#blend1W").val());
        gl.uniform1f(rotateUniform, $("#rotate1").val());
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

        // right
        gl.uniform2f(translateUniform, $("#point3X").val(), $("#point3Y").val());
        gl.uniform2f(scaleUniform, $("#scale3X").val(), $("#scale3Y").val());
        gl.uniform4f(screenBlendU, $("#blend3X").val(), $("#blend3Y").val(),
            $("#blend3Z").val(), $("#blend3W").val());
        gl.uniform1f(rotateUniform, $("#rotate3").val());
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);


        //center
        gl.uniform2f(translateUniform, $("#point2X").val(), $("#point2Y").val());
        gl.uniform2f(scaleUniform, $("#scale2X").val(), $("#scale2Y").val());
        gl.uniform4f(screenBlendU, $("#blend2X").val(), $("#blend2Y").val(),
            $("#blend2Z").val(), $("#blend2W").val());
        gl.uniform1f(rotateUniform, $("#rotate2").val());
        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
    }
}
