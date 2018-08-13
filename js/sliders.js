var numSliders = 10;
var sliders = arrayOf(numSliders);
var sliderVals = arrayOf(numSliders);
var sliderContainer; 

var sliderConfig = arrayOf(10).map((id, ind) => ({label: "label"+ind, conf: {min: 0, max: 1}}));

function setUpSliders(){
    sliderContainer = $('#videoUploadPanel');
    sliders = sliders.map((elem, ind) => {
        let id = ind;
        var sliderHTMLTemplate = 
        `<br>
            <span><div id="slider${id}" style="display: inline;"></div></span>
            <span><input id="sliderVal${id} type="text" style="width: 50px; display: inline;"></span>
            <span id="sliderLabel${id}">${sliderConfig[id].label}</span>
        `;
        sliderContainer.append(sliderHTMLTemplate);
        var slider = new Nexus.Slider("#slider"+id, sliderConfig[id].conf);

        return slider;
    });
}

var videoBlendLabels = [
    "label1",
    "label2",
    "label3",
    "label4",
    "label5",
    "label6",
    "label7",
    "label8",
    "label9",
    "label10",
];