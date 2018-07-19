//definitions of various p5 sketches to use as textures

var p5w = 1280*1.5;
var p5h = 720*1.5;
function testSetup() {
    createCanvas(p5w, p5h);
}
var frameCount = 0;
function testDraw() {
    clear();
    background(255);
    var t = Date.now()/1000;
    var c = [127+sin(t)*50, 127+sin(t+PI/2)*50, 127+sin(t+PI/3)*50]; 
    stroke(c);
    fill(c);
    ellipse(500+sin(t)*300, 300+cos(t)*300, 100, 100);
    //if(frameCount++ %10 == 0) console.log(c);
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


var xStep = 10;
var yStep = 10;
var stepDist = 10;
var xPos = p5w/2;
var yPos = p5h/2;
var mat;
var r = () => Math.random()*20 - 10;
var sinN = t => (Math.sin(t)+1)/2
var numPoints = 200;
var arrayOf = n => Array.from(new Array(n), () => 0);
var curvePoints = arrayOf(100);
function mod(n, m) {
  return ((n % m) + m) % m;
}

function wrapVal(val, low, high){
    var range  = high - low;
    if(val > high){
        var dif = val-high;
        var difMod = mod(dif, range);
        var numWrap = (dif-difMod)/range;
        // console.log("high", dif, difMod, numWrap)
        if(mod(numWrap, 2) == 0){
            return high - difMod;
        } else {
            return low + difMod;
        }
    }
    if(val < low){
        var dif = low-val;
        var difMod = mod(dif, range);
        var numWrap = (dif- difMod)/range ;
        // console.log("low", dif, difMod, numWrap)
        if(mod(numWrap, 2.) == 0.){
            return low + difMod;
        } else {
            return high - difMod;
        }
    }
    return val;
}


class Snake {
    constructor(numPoints, snakeColor, switchFunc, id){
        this.points = arrayOf(numPoints).map(x => [p5w/2, p5h/2]);
        this.switchFunc = switchFunc;
        this.xPos = p5w/2;
        this.yPos = p5h/2;
        this.stepDist = 10;
        this.xStep = 10;
        this.yStep = 10;
        this.snakeColor = snakeColor;
        this.numPoints = numPoints;
        this.id = id;
    }

    drawSnake(frameCount){
        this.stepSnake(frameCount);
        // beginShape();
        for(var i = 0; i < this.numPoints-1; i++){ //indexing-1 due to the fact we are drawing lines and don't want to close the loop
            this.drawSegment(i, frameCount);
        }
        // endShape();
    }

    stepSnake(frameCount){
        if(this.xPos + this.xStep > p5w || this.xPos + xStep < 0) this.xStep *= -1;
        if(this.yPos + this.yStep > p5h || this.yPos + this.yStep < 0) this.yStep *= -1;
        this.xPos = wrapVal(this.xPos+this.xStep, 0, p5w);
        this.yPos = wrapVal(this.yPos+this.yStep, 0, p5h);

        var switchData = this.switchFunc(frameCount);
        if(switchData[0]){
            this.xStep = switchData[1];
            this.yStep = switchData[2];
        }

        var curveInd = frameCount%this.numPoints;
        this.points[curveInd] = [this.xPos, this.yPos];
    }

    drawSegment(i, frameCount){
        noFill();
        stroke(this.snakeColor);

        var curveInd = frameCount%this.numPoints;
        var p = this.points[(curveInd+i+1)%this.numPoints]; //indexing with +1 here because the next point in the ringbuffer is the oldest one
        var p2 = this.points[(curveInd+i+2)%this.numPoints];

        // ellipse(p[0], p[1], 4 + sinN((frameCount + i)/20)*30);
        strokeWeight((4 + sinN((frameCount)/20 + this.id*TWO_PI/6)*50)*2)
        line(p[0], p[1], p2[0], p2[1]);
        // curveVertex(p[0], p[1]);
    }
}

var sneks = arrayOf(6);
var snekLen = 100;
function phialSetup(){
    p5w = 1280/1.5;
    p5h = 720/1.5;
    createCanvas(p5w, p5h);
    background(255);
    var switchFunc = fc => [fc%20 == 0, sin(Math.random()*TWO_PI) * 10, cos(Math.random()*TWO_PI) * 10];
    sneks = sneks.map((x, i) => new Snake(snekLen, color(i*10, i*10, i*10), switchFunc, i));
}

function phialDraw(){
    clear();
    background(255);
    
    sneks.map(snek => snek.stepSnake(frameCount));
    for(var i = 0; i < snekLen-1; i++){
        sneks.map(snek => snek.drawSegment(i, frameCount));
    }
    // sneks.map(snek => snek.drawSnake(frameCount))
    frameCount++;
}
