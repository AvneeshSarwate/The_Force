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
    constructor(numPoints, snakeColor, id){
        this.points = arrayOf(numPoints).map(x => [p5w/2, p5h/2]);
        this.xPos = p5w/2 + (Math.random()-0.5) * 500;
        this.yPos = p5h/2 + (Math.random()-0.5) * 300;
        this.stepDist = 10;
        this.xStep = 10;
        this.yStep = 10;
        this.snakeColor = snakeColor;
        this.numPoints = numPoints;
        this.id = id;
        this.angle = (Math.random()-0.5) * TWO_PI;
        this.strokeWeight = () => (4 + sinN((frameCount)/20 + this.id*TWO_PI/6)*50)*2;
        this.switchScheduled = false;
        this.swellManager = {
            duration: 0.4,
            startTime: 0,
            isActive: false,
            default: 50,
            val: 50,
            updateFunc: function(time){
                if(!this.isActive) return this.default;
                var activeDur = time - this.startTime;
                var growTime = 0.05;
                var growSize = 150;
                // console.log("snek", this.id, activeDur);
                if(activeDur < growTime) return this.default + activeDur/growTime * growSize;
                else if(growTime <= activeDur && activeDur < this.duration) return growSize + this.default - (activeDur-growTime)/(this.duration-growTime)*growSize;
                else {
                    this.isActive = false;
                    return this.default;
                } 
            }
        };
    }

    drawSnake(frameCount, time){
        this.swellManager.val = this.swellManager.updateFunc(time);
        this.stepSnake(frameCount, time);
        // beginShape();
        for(var i = 0; i < this.numPoints-1; i++){ //indexing-1 due to the fact we are drawing lines and don't want to close the loop
            this.drawSegment(i, frameCount, time);
        }
        // endShape();
    }

    stepSnake(frameCount, time){
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

    drawSegment(i, frameCount, time, weight){
        // if(!weight) return;
        noFill();
        stroke(this.snakeColor);

        var curveInd = frameCount%this.numPoints;
        var p = this.points[(curveInd+i+1)%this.numPoints]; //indexing with +1 here because the next point in the ringbuffer is the oldest one
        var p2 = this.points[(curveInd+i+2)%this.numPoints];

        // ellipse(p[0], p[1], 4 + sinN((frameCount + i)/20)*30);
        if(weight) {
            strokeWeight(weight);
        }
        else {
            strokeWeight(this.swellManager.val);
            // strokeWeight(this.swellManager.updateFunc(time));

        }
        line(p[0], p[1], p2[0], p2[1]);
        // curveVertex(p[0], p[1]);
    }

    switchFunc(frameCount){
        this.angle = this.angle + (Math.random()-0.5) * PI/2;
        var switching = this.switchScheduled;
        var dist = 4;
        var switchData = [frameCount%20 ==0, sin(this.angle) * dist, cos(this.angle) * dist];
        this.switchScheduled = this.switchScheduled && false;
        return switchData;
    }
}

var numSnakes = 6;
var sneks = arrayOf(numSnakes);
var snekLen = 100;
var snakeOrder = 0;
var rotateFrame = false;
function phialSetup(){
    p5w = 1280/1.5;
    p5h = 720/1.5;
    createCanvas(p5w, p5h);
    // background(255);
    noSmooth();
    sneks = sneks.map((x, i) => new Snake(snekLen, color(i*10, i*10, i*10), i));
}

function phialDraw(){
    clear();
    background(255);
    // sneks.map(snek => snek.stepSnake(frameCount));
    // for(var i = 0; i < snekLen-1; i++){
    //     sneks.map(snek => snek.drawSegment(i, frameCount));
    // }
    // sneks.map(snek => snek.drawSnake(frameCount))
    var time = Date.now() / 1000;
    for(var i = 0; i < numSnakes; i++){
        sneks[(snakeOrder+i)%numSnakes].drawSnake(frameCount, time);
    }
    frameCount++;
}



class MovingCircle {
    constructor(circleColor, id){
        var numPoints = 1;
        this.points = arrayOf(numPoints).map(x => [p5w/2, p5h/2]);
        this.xPos = p5w/2 + (Math.random()-0.5) * 500;
        this.yPos = p5h/2 + (Math.random()-0.5) * 300;
        this.stepDist = 10;
        this.xStep = 10;
        this.yStep = 10;
        this.circleColor = circleColor;
        this.numPoints = numPoints;
        this.id = id;
        this.angle = (Math.random()-0.5) * TWO_PI;
        this.strokeWeight = () => (4 + sinN((frameCount)/20 + this.id*TWO_PI/6)*50)*2;
        this.switchScheduled = false;
        this.swellManager = {
            duration: 0.4,
            startTime: 0,
            isActive: false,
            default: 10,
            val: 10,
            updateFunc: function(time){
                if(!this.isActive) return this.default;
                var activeDur = time - this.startTime;
                var growTime = 0.05;
                var growSize = 150;
                // console.log("snek", this.id, activeDur);
                if(activeDur < growTime) return this.default + activeDur/growTime * growSize;
                else if(growTime <= activeDur && activeDur < this.duration) return growSize + this.default - (activeDur-growTime)/(this.duration-growTime)*growSize;
                else {
                    this.isActive = false;
                    return this.default;
                } 
            }
        };
    }

    drawCircle(frameCount, time){
        this.swellManager.val = this.swellManager.updateFunc(time);
        this.stepCircle(frameCount, time);
        this.renderCircle();
    }

    stepCircle(frameCount, time){
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

    renderCircle(){
        fill(this.circleColor);
        stroke(this.circleColor);

        var p = this.points[0];
        var rad = this.swellManager.val;

        ellipse(p[0], p[1], rad, rad);
    }

    switchFunc(frameCount){
        this.angle = this.angle + (Math.random()-0.5) * PI/2;
        var switching = this.switchScheduled;
        var dist = 4;
        var switchData = [frameCount%20 ==0, sin(this.angle) * dist, cos(this.angle) * dist];
        this.switchScheduled = this.switchScheduled && false;
        return switchData;
    }
}

var numCircles = 100;
var cirlces = arrayOf(numCircles);
function responsevis1Setup(){
    p5w = 1280/1.5;
    p5h = 720/1.5;
    var gv = n => (n/numCircles) * 255; //converts to greyscale value;
    cirlces = cirlces.map((x, i) => new MovingCircle(color(gv(i), gv(i), gv(i)), i));
    createCanvas(p5w, p5h);
    noSmooth();
}

function rotVec2(x,y, cx, cy, amount){
    var space = {x: x/p5w,  y: y/p5h};
    var center = {x: cx/p5w,  y: cy/p5h};
    var newX = cos(amount) * (space.x - center.x) + sin(amount) * (space.y - center.y) + center.x;
    var newY =cos(amount) * (space.y - center.y) - sin(amount) * (space.x - center.x) + center.y;;
    return {x: newX*p5w, y: newY*p5h};
}

var lastTime = Date.now() / 1000;
var newTime = Date.now() / 1000;
var time = 0;
var times = arrayOf(20);
function responsevis1Draw(){
    clear();
    background(255);
    stroke(0);
    fill(0);
    lastTime = newTime;
    newTime = Date.now() / 1000;
    var timeDiff = newTime - lastTime;
    var timeScale = 1;
    time += timeDiff * timeScale;
    times[2] += timeDiff * (0.3 + sliderVals[1]*3);
    times[3] += timeDiff * (4+30*sliderVals[3]);
    // cirlces.forEach(function(circle){ circle.drawCircle(frameCount, time/4.)});
    var rad1 = 0.3;
    var rad2 = 0.05;
    var speed1 = 1/1.5;
    var speed2 = 5;
    var size = 10;
    var numCenters = 40;
    var circleCounter = 0;
    for(var i = 0; i < numCenters; i++){
        var ct = rotVec2(p5w*0.5, p5h*0.5 + rad1*p5h, p5w*0.5, p5h*0.5, PI*2*i/numCenters + time*speed1);
        ct = {x: ct.x + sin(time*(1+i/20))*p5w*0.2 * sliderVals[2], y: ct.y + cos(time*(1+i/20))*p5h*0.2 * sliderVals[2]};
        // ellipse(pt.x, pt.y, 20, 20);
        var rd2 = i%5 == 0 ? sliderVals[0] * 0.3 : rad2;
        for(var j = 0; j < 10; j++){
            pt = rotVec2(ct.x + rd2*p5w, ct.y, ct.x, ct.y, PI*2*j/10 - times[2]*speed2);
            var sz = size*(1 + sinN(times[3] + (i/numCenters*PI*2))*(1+ sliderVals[4]*4.));
            ellipse(pt.x, pt.y, sz, sz);
            circleCounter++;
        }
    }
    frameCount++;
}
