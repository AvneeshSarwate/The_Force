//definitions of various p5 sketches to use as textures

var p5w = 1280;
var p5h = 720;
function testSetup() {
    createCanvas(p5w, p5h);
}
var frameCount = 0;
function testDraw() {
    clear();
    background(0);
    var t = Date.now()/1000;
    var c = [127+sin(t)*50, 127+sin(t+PI/2)*50, 127+sin(t+PI/3)*50]; 
    line(c);
    fill(c);
    ellipse(500+sin(t)*300, 300+cos(t)*300, 100, 100);
    if(frameCount++ %10 == 0) console.log(c);
}




var step = 8; //optical flow step
var vidScale = 2; //downsampling factor of video for optical flow
var centerX = p5w/2;
var centerY = p5h/2;
var capture;
var previousPixels;
var flow;
var hFlip = (n, x) => (n-x)*-1+x; //flip a point around an x-axis value
var toCellInd = (x, y, scale) => ({x: Math.max((x/scale-step-1)/(2*step+1), 0), y: Math.max((y/scale-step-1)/(2*step+1), 0)});
var devDim = [Math.floor((p5w/vidScale-step-1)/(2*step+1))+1, Math.floor((p5h/vidScale-step-1)/(2*step+1))+1];

function hulldrawSetup(){
    createCanvas(p5w, p5h);
    capture = createCapture(VIDEO);
    capture.size(p5w/vidScale, p5h/vidScale);
    capture.hide();
    flow = new FlowCalculator(step);
    frameRate(30);
}

function hulldraw(){
    clear();
    capture.loadPixels();

    if (capture.pixels.length > 0) {
        if (previousPixels) {

            // cheap way to ignore duplicate frames
            if (same(previousPixels, capture.pixels, 4, width)) {
                return;
            }

            flow.calculate(previousPixels, capture.pixels, capture.width, capture.height);
        }
        previousPixels = copyImage(capture.pixels, previousPixels);

        var flowScreenPoints = new Array();

        var flowThresh = 5;

        if (flow.flow && flow.flow.u != 0 && flow.flow.v != 0) {
            // uMotionGraph.addSample(flow.flow.u);
            // vMotionGraph.addSample(flow.flow.v);

            strokeWeight(2);
            flow.flow.zones
            .filter((zone) => Math.abs(zone.u) > flowThresh && Math.abs(zone.v) > flowThresh)
            .forEach((zone) => {
                stroke(map(zone.u, -step, +step, 0, 255), map(zone.v, -step, +step, 0, 255), 128);
                //fliped visualization to look like proper mirroring
                strokeWeight(Math.abs(zone.u) + Math.abs(zone.v));
                line(hFlip((zone.x*vidScale), p5w/2), zone.y*vidScale, hFlip((zone.x + zone.u)*vidScale, p5w/2), (zone.y + zone.v)*vidScale);
                
                flowScreenPoints.push([hFlip((zone.x*vidScale), p5w/2), zone.y*vidScale]);

            });
        }

        noFill();
        strokeWeight(10);
        stroke(255);
        var hullPoints = hull(flowScreenPoints, 300);
        var useBezier = false;
        if(useBezier) { 
            bezier.apply(null, [].concat.apply([], hullPoints));
            // bezier(85, 20, 10, 10, 90, 90, 15, 80);
        } else {
            beginShape();
            for(var i = 0; i < hullPoints.length; i++){
                curveVertex(hullPoints[i][0], hullPoints[i][1]);
            }
            endShape(CLOSE);
        }
    } 
}

