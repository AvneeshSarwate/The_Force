var numSliders = 10;
var sliders = arrayOf(numSliders);
var sliderVals = arrayOf(numSliders);
var sliderContainer; 

var sliderConfig = arrayOf(10).map((id, ind) => ({label: "label", conf: {min: 0, max: 1, value: 0}}));

function setUpSliders(){
    sliderContainer = $('#videoUploadPanel');
    sliders = sliders.map((elem, ind) => {
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
    {conf: {min: 0, max: 1, value: 0}, label: "label"},
    {conf: {min: 0, max: 1, value: 0}, label: "label"},
    {conf: {min: 0, max: 1, value: 0}, label: "label"}
];