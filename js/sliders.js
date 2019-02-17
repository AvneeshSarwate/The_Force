var numSliders = 10;
var sliders = arrayOf(numSliders);
var sliderVals = arrayOf(numSliders);
var sliderContainer; 

var sliderCallbacks = {};
var sliderConfig = arrayOf(numSliders).map((id, ind) => ({label: "slider "+ind, conf: {min: 0, max: 1, value: 0}}));


function setSliderVal(num, value){
    $("#sliderVal"+(num)).val(value);
    sliders[num].value = value;
    sliderVals[num] = value;
}

function setUpSliders(){
    sliderContainer = $('#videoUploadPanel');
    sliders = sliderConfig.map((elem, ind) => {
        let id = ind;
        var sliderHTMLTemplate = 
        `<br>
            <span><div id="slider${id}" style="display: inline;"></div></span>
            <span><input id="sliderVal${id}" type="text" style="width: 50px; display: inline;"></span>
            <span id="sliderLabel${id}">${sliderConfig[id].label}</span>
        `;
        sliderContainer.append(sliderHTMLTemplate);
        var slider = new Nexus.Slider("#slider"+id, sliderConfig[id].conf);
        sliderVals[id] = sliderConfig[id].conf.value;
        $('#sliderVal'+id).val(sliderVals[id]);
        $('#sliderVal'+id).change(function(ev){
            slider.value = $(this).val()
        });
        slider.on('change', function(v){
            $('#sliderVal'+id).val(v);
            sliderVals[id] = v;
            if(sliderCallbacks[id]) sliderCallbacks[id](v);
        });
        return slider;
    });
}

var videoBlendSliderVals = [
    {conf: {min: 0, max: 1, value: 0}, label: "video/camera blend (default 0)"},
    {conf: {min: 0, max: 1, value: 0.1}, label: "movement detection threshold (default 0.1)"},
    {conf: {min: 0, max: 1, value: 1}, label: "movement brightness scaling (default 1)"},
    {conf: {min: 0, max: 1, value: 0.97}, label: "movement trail decay (default 0.97)"},
    {conf: {min: 0, max: 1, value: 0.1}, label: "rbg layer separation distance (default 0.1)"},
    {conf: {min: 0, max: 1, value: 0.5}, label: "bleedthrough outline clarity (default 0.5)"},
    {conf: {min: 0, max: 1, value: 0.5}, label: "bleedthrough color intensity (default 0.5)"},
];



var yoyoSliders = [
    {conf: {min: 0, max: 10, value: 0.7}, label: "(type value, slider buggy) lag between playheads in seconds"},
    {conf: {min: 0, max: 2, value: 0.5}, label: "waviness of playhead 1"},
    {conf: {min: 0, max: 2, value: 0.5}, label: "waviness of playead 2"},
    {conf: {min: 0, max: 2, value: 1.2}, label: "white-saturation of color (sensitive betwee 0.95 and 1.2)"},
    {conf: {min: 0, max: 4, value: 1}, label: "waviness speed"},
    {conf: {min: 0, max: 1, value: 0.5}, label: "trail decay time (1 is infinite)"},
    {conf: {min: -2, max: 2, value: 0}, label: "horizontal scrolling speed"},
    {conf: {min: 0, max: 1, value: 0}, label: "amount of black overlay of non-distorted dancer"},
];

var trailsSliders = [
    {conf: {min: 0, max: 1, value: 0.5}, label: "slider trail decay time"},
    {conf: {min: 0, max: 1, value: 0.1}, label: "trail smoothing (higher values also increase trail decay time)"},
    {conf: {min: 0, max: 1, value: 0.2}, label: "movement detection threshold"},
    {conf: {min: 0, max: 1, value: 0.3}, label: "hue spread"},
    {conf: {min: 0, max: 1, value: 0.1}, label: "hue rotation speed"},
    {conf: {min: 0, max: 1, value: 0.5}, label: "hue offset"},
    {conf: {min: 0, max: 1, value: 1}, label: "saturation"},
    {conf: {min: 0, max: 1, value: 1}, label: "brightness"},
    {conf: {min: 0, max: 1, value: 0}, label: "hsv mix"},
    {conf: {min: 0, max: 1, value: 0}, label: "horizontal scrolling"}
];

var trailsSliders2 = [
    {conf: {min: 0, max: 1, value: 0.5}, label: "trail decay time"},
    {conf: {min: 0, max: 1, value: 0.1}, label: "frame smoothing/blur (higher values also increase trail decay time)"},
    {conf: {min: 0, max: 1, value: 0.2}, label: "movement detection threshold"},
    {conf: {min: 0, max: 1, value: 0.3}, label: "trail rotation"},
    {conf: {min: 0, max: 1, value: 0.1}, label: "trail color saturation (0.1 is normal color)"},
];

var fogShipSliders = [
    {conf: {min: 0, max: 1, value: 0.5}, label: "feedback noise spread"},
    {conf: {min: 0, max: 1, value: 0.4}, label: "feedback rotation mix"},
    {conf: {min: 0, max: 1, value: 0.35}, label: "ball distance threshold"},
    {conf: {min: 0, max: 1, value: 0.1}, label: "backbuffer blend"},
    {conf: {min: 0, max: 1, value: 0.2}, label: "trail decay speed"},
    {conf: {min: 0, max: 1, value: 0.5}, label: "feedback rotation angle"},
];

var rainbowHitsSliders = [
    {conf: {min: 0, max: 1, value: 0.5}, label: "warp amount"},
    {conf: {min: 0, max: 1, value: 0.4}, label: "ball density"},
    {conf: {min: 0, max: 1, value: 0.35}, label: "zoom"},
    {conf: {min: 0, max: 1, value: 0.1}, label: "zoom center x position"},
    {conf: {min: 0, max: 1, value: 0.2}, label: "zoomCenter y position"},
    {conf: {min: 0, max: 1, value: 1}, label: "shimmer width"},
    {conf: {min: 0, max: 1, value: 0}, label: "black/inverse color blend"},
    {conf: {min: 0, max: 1, value: 0}, label: "hyper glitch blend"},
    {conf: {min: 0, max: 1, value: 1}, label: "color texture resolution"},
    {conf: {min: 0, max: 1, value: 1}, label: "frame blur"},
]

var princeSliders = [
    {conf: {min: 0, max: 1, value: 0.05}, label: "background warp amount"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "ring warp amount"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "ring size"},
    {conf: {min: 0, max: 1, value: 0.85}, label: "generated background grit"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "guitar overlay"},
    {conf: {min: 0, max: 1, value: 1}, label: "gold ring overlay"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "slider 0"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "slider 1"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "slider 2"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "slider 3"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "slider 4"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "slider 5"},
];

var yoyoPortAuthoritySliders = [
    {conf: {min: 0, max: 1, value: 0.98}, label: "trail feedback time"},
    {conf: {min: 0, max: 5, value: 0.5}, label: "dancer brightness"},
    {conf: {min: 0, max: 5, value: 1}, label: "trail Brightness"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "slider 3"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "slider 4"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "slider 5"},
];

var guitarPaintSliders = [
    {conf: {min: 0, max: 1, value: 0.25}, label: "0: brush angle"},
    {conf: {min: 0, max: 1, value: 0.2}, label: "1: brush speed"},
    {conf: {min: 0, max: 1, value: 0.4}, label: "2: brush height"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "3: brush width"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "4: warp resolution"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "5: warp speed"},
    {conf: {min: 0, max: 1, value: 0.2}, label: "6: trail warp mix"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "7: background zoom"},
    {conf: {min: 0, max: 1, value: 0.5}, label: "8: decay time"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "9: background warp zoom"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "10: color base"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "11: color deviation"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "12: color mix"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "13: blank"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "14: blank"},
    {conf: {min: 0, max: 1, value: 0.05}, label: "15: blank"}
];

/*
responsivevis1 sliderVals = [0.475, 0.116, 0.691, 0.016, 0.208, 1, 0, 0, 0, 0] - for only p5, no shader
responsivevis1 sliderVals = [0.445, 0.075, 0.525, 0, 0.183, 1, 0, 0, 0.883, 0]
responsivevis1 sliderVals = [.4, .1, .79, 0, .2, .8]
*/
