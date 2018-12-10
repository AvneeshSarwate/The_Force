//definitions of various p5 sketches to use as textures
"use strict";

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
var sinN = t => (Math.sin(t)+1)/2;
var cosN = t => (Math.cos(t)+1)/2;
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

function rotVec2_p5(x,y, cx, cy, amount){
    var space = {x: x/p5w,  y: y/p5h};
    var center = {x: cx/p5w,  y: cy/p5h};
    var newX = cos(amount) * (space.x - center.x) + sin(amount) * (space.y - center.y) + center.x;
    var newY =cos(amount) * (space.y - center.y) - sin(amount) * (space.x - center.x) + center.y;;
    return {x: newX*p5w, y: newY*p5h};
}

var lastTime = Date.now() / 1000;
var newTime = Date.now() / 1000;
var time = 0;
var times = arrayOf(1000);
var timeDiffs = arrayOf(1000).map(e => 1);
var mix = (v1, v2, a) => ({x: v1.x*(1-a) + v2.x*a, y: v1.y*(1-a) + v2.y*a});
var mixn = (n1, n2, a) => n1*(1-a) + n2*a;
var length = v => (v.x**2 + v.y**2)**0.5;

var fract = v => v - Math.floor(v);
var randf = v => fract(sin(v*1000));

function vecsub(v1, v2){
    var isVec = !(typeof v2 == "number");
    return {x: v1.x - (isVec ? v2.x : v2), y: v1.y - (isVec ? v2.y : v2)}
};
function vecadd(v1, v2){
    var isVec = !(typeof v2 == "number");
    return {x: v1.x + (isVec ? v2.x : v2), y: v1.y + (isVec ? v2.y : v2)}
};
var vecmul = (v, c) => ({x: v.x*c, y: v.y*c});
var vecdiv = (v, c) => ({x: v.x/c, y: v.y/c});

function coordWarp(stN, t2, rad, numBalls){
    var warp = {x: stN.x, y: stN.y};
    for (var i = 0; i < numBalls; i++) {
        var p = {x: sinN(t2* randf(i+1.) * 1.3 + i), y: cosN(t2 * randf(i+1.) * 1.1 + i)};
        warp = length(vecsub(stN,p)) <= rad ? mix(warp, p, 1. - length(vecsub(stN,p))/rad)  : warp;
    }
    return warp;
}

//wrap a normalized coordinate mapping function to p5 coordinates 
function normExec(p5N, transFunc){
    var inN = {x: p5N.x / p5w, y: p5N.y/p5h};
    var out = transFunc(inN);
    return {x: out.x*p5w, y: out.y*p5h};
}

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
        var ct = rotVec2_p5(p5w*0.5, p5h*0.5 + rad1*p5h, p5w*0.5, p5h*0.5, PI*2*i/numCenters + time*speed1);
        ct = {x: ct.x + sin(time*(1+i/20))*p5w*0.2 * sliderVals[2], y: ct.y + cos(time*(1+i/20))*p5h*0.2 * sliderVals[2]};
        // ellipse(pt.x, pt.y, 20, 20);
        var rd2 = i%5 == 0 ? sliderVals[0] * 0.3 : rad2;
        for(var j = 0; j < 10; j++){
            var tmodT = circleCounter%2 == 0 ? sliderVals[6] * 3 : 0;
            var pt = rotVec2_p5(ct.x + rd2*p5w, ct.y, ct.x, ct.y, PI*2*j/10 - (times[2]+tmodT)*speed2);
            var ptW = normExec(pt, p => coordWarp(p, (time+tmodT)/10., 0.4, 20));
            ptW = mix(pt, ptW, sliderVals[5]);

            var sz = size*(1 + sinN((times[3]+tmodT) + (i/numCenters*PI*2))*(1+ sliderVals[4]*4.));
            ellipse(ptW.x, ptW.y, sz, sz);
            circleCounter++;
        }
    }

    frameCount++;
}


class RasterBlob{
    constructor(x, y, height, width, numLines, lineThickness, changeFunc){ //x/y denote top left
        this.x = x;
        this.y = y;
        this.height = height;
        this.width = width;
        this.numLines = numLines;
        this.lineThickness = lineThickness; //denotes how much of a line's allocated thickness is actually filled in;
        this.changeFunc = changeFunc; //returns a value from 0-1 indicating line width as a function of time + yposition
        this.funcScale = PI_2; //how many oscilations the changeFunc gives - sinN(time+funcScale*y)
        this.angle = 0;
        this.warpFunc = (id, time) => id;
    }

    getPos(){
        return {x: this.x, y: this.y};
    }

    getCenter(){
        return {x: this.x + this.width/2, y: this.y + this.height/2};
    }


    render(time){
        for(var i = 0; i < this.numLines; i++){
            var yN = i / this.numLines;
            var lineWidthN = this.changeFunc(time+this.funcScale*yN);
            var xStart = this.x + this.width*(1-lineWidthN)/2;
            var calcStroke = this.height/this.numLines * p5h * this.lineThickness;
            strokeWeight(calcStroke);
            var y = yN*this.height + this.y;
            var linePoints = [{x: xStart, y}, {x: xStart + lineWidthN*this.width, y}];
            linePoints = linePoints.map(p => this.warpFunc(p, time));
            line(linePoints[0].x*p5w, linePoints[0].y*p5h, linePoints[1].x*p5w, linePoints[1].y*p5h);
        }
    }
}

class CurveBlob{
    constructor(x, y, radius, numPoints, lineThickness, radFunc){ //x/y denote center of blob
        this.x = x;
        this.y = y;
        this.radius = radius;
        this.numPoints = numPoints;
        this.lineThickness = lineThickness; 
        this.radFunc = radFunc; 
        this.funcScale = PI_2; //how many oscilations the changeFunc gives - sinN(time+funcScale*y)
        this.angle = 0;
        this.warpFunc = (id, time) => id;
    }

    setPos(p){
        this.x = p.x;
        this.y = p.y;
        return this;
    }

    setRad(rad){
        this.radius = rad;
        return this;
    }

    getPos(){
        return {x: this.x, y: this.y};
    }



    render(time, n){
        var points = [];
        noFill();
        beginShape();
        for(var i = 0; i < this.numPoints; i++){
            var theta = i/this.numPoints * PI_2;
            var rad = this.radFunc(theta, time);
            var deviation = {x: cos(theta)*rad*this.radius, y: sin(theta)*rad*this.radius};
            var devLen = length(deviation);
            if(devLen < 0.1){
                var fff = 5;
            }
            var pt = vecadd(this.getPos(), deviation);
            points.push(pt);
            strokeWeight(this.radius * this.lineThickness * p5h);
            stroke((n/numBlobs)%1 * 255);
            curveVertex(pt.x * p5w, pt.y * p5h);


            // var yN = i / this.numLines;
            // var lineWidthN = this.changeFunc(time+this.funcScale*yN);
            // var xStart = this.x + this.width*(1-lineWidthN)/2;
            // var calcStroke = this.height/this.numLines * p5h * this.lineThickness;
            // strokeWeight(calcStroke);
            // var y = yN*this.height + this.y;
            // var linePoints = [{x: xStart, y}, {x: xStart + lineWidthN*this.width, y}];
            // linePoints = linePoints.map(p => this.warpFunc(p, time));
            // line(linePoints[0].x*p5w, linePoints[0].y*p5h, linePoints[1].x*p5w, linePoints[1].y*p5h);
        }
        for(var i = 0; i < 3; i++){
            curveVertex(points[i].x*p5w, points[i].y*p5h);
        }
        endShape();
    }
}

function responsevis2Setup(){
    p5w = 1280/1.5;
    p5h = 720/1.5;
    var gv = n => (n/numCircles) * 255; //converts to greyscale value;
    cirlces = cirlces.map((x, i) => new MovingCircle(color(gv(i), gv(i), gv(i)), i));
    createCanvas(p5w, p5h);
    noSmooth();
}

function rotVec2(space, center, amount){
    var newX = cos(amount) * (space.x - center.x) + sin(amount) * (space.y - center.y) + center.x;
    var newY =cos(amount) * (space.y - center.y) - sin(amount) * (space.x - center.x) + center.y;;
    return {x: newX, y: newY};
}

var blob = new RasterBlob(0, .0, .5, .5, 30, 0.5, i => 1);
blob.warpFunc = (p, time) => coordWarp(p, time, 0.4, 20);
blob.warpFunc = function(p, time){ 
    return rotVec2(p, this.getCenter(), time);
}

var blobGrid = 5;
var numBlobs = blobGrid**2;
var PI_2 = 3.14159 * 2;


var rasterBlobs = arrayOf(numBlobs)
    .map((e, i) => (new RasterBlob((i%blobGrid)/blobGrid, Math.floor(i/blobGrid)/blobGrid, 1/blobGrid, 1/blobGrid, 30, 0.5, sinN)))
    .map(function(blob, i){
        // blob.warpFunc = (p, time) => coordWarp(p, time, 0.4, 20);
        blob.funcScale = PI_2 * (1+ sinN(i*blobGrid)*5);
        blob.warpFunc = function(p, time){ 
            return rotVec2(p, this.getCenter(), time);
        }
        return blob
    });

var cellRad = 1/(blobGrid*2);

var dancerPos1 = arrayOf(numBlobs).map((e, i) => ({x: ((i%blobGrid)*2+1)*cellRad, y: (Math.floor(i/blobGrid)*2+1)*cellRad}));
var dancerPos2 = arrayOf(numBlobs).map((e, i) => ({x: cosN(i/numBlobs*PI_2), y: sinN(i/numBlobs*PI_2)}));
var dancerPos3 = arrayOf(numBlobs).map(e => ({x: 0.5, y: 0.5}) );

var sett = 1;
var weirdFunc = (th, t) => (sinN(th*2*(sin(t/4.4)) + t/1.2)+cosN(th*2+t/3.1))/2;

// var curveBlobs = dancerPos1.map((pos, i) => (new CurveBlob(pos.x, pos.y, cellRad*3, 10, 0.1, 
    // (th, t) => (sinN(th*2*(sin(t/4.4)) + t/1.2)+cosN(th*2+t+ mixn(3.1, 0, sliderVals[0])*(1+i*sinN(time/5)) ))/2)));

var curveBlobs = dancerPos1.map((pos, i) => (new CurveBlob(0.5, 0.5, 0.5/(i+1), 10, 0.1, 
    (th, t) => (sinN(th*2*(sin(t/4.4)) + t/1.2)+cosN(th*2+t+ mixn(3.1, 0, sliderVals[0])*(1+(1+sliderVals[1]*i)*sinN(time/5)) ))/2)));

var initRadii = curveBlobs.map(b => b.radius);

var cent = {x:0.5, y: 0.5};
frameCount = 0;
function responsevis2Draw(){
    clear();
    background(255);
    stroke(0);
    fill(0);

    lastTime = newTime;
    newTime = Date.now() / 1000;
    var timeDiff = newTime - lastTime;
    var timeScale = 1;
    time += timeDiff * timeScale;


    var colorPhaseTimeInd = numBlobs+1;
    timeDiffs[colorPhaseTimeInd] = sliderVals[4]*120;

    times = times.map((t, i) => t + timeDiff * timeDiffs[i]);
    
    // blob.height = sinN(time*5)* 0.4 + 0.1;
    // blob.lineThickness = sinN(time*5)* 0.5 + 0.5;
    // blob.render(time);
    // dancerPos1.map((p, i) => mix(p, dancerPos2[i], sinN(time/8 * PI_2 + i*sinN(time/9)))).map((p, i) => curveBlobs[i].setPos(p));

    var radPos = arrayOf(numBlobs).map((e, i) => (mix({x: cosN(i/numBlobs*PI_2), y: sinN(i/numBlobs*PI_2)}, cent, sinN(i/numPoints*PI_2 + time)) ));
    radPos = radPos.map(p => mix(cent, p, sliderVals[2]));
    radPos.map((p, i) => curveBlobs[i].setPos(rotVec2(p, cent, -time))).map((blob, i) => blob.setRad(mixn(initRadii[i], cellRad*(.1 + sinN(i/numBlobs*PI_2+time*3)*2.9), sliderVals[3])));

    curveBlobs.map((blob, i) => blob.render(times[i], times[colorPhaseTimeInd]+i));
    frameCount++;
}


function responsevis3Setup(){
    p5w = 1280;
    p5h = 720;
    createCanvas(p5w, p5h);
    numTiles = {x: 128/4, y: 72/4};
    tileSize = {x: p5w/numTiles.x, y: p5h/numTiles.y};
    noSmooth();
}

var numTiles;
var tileSize;

function responsevis3Draw(){
    clear();
    for(let i = 0; i < numTiles.x; i++){
        for(let j = 0; j < numTiles.y; j++){
            rect(i* tileSize.x, j* tileSize.y, tileSize.x/2, tileSize.y/2);
        }
    }

    times = times.map((t, i) => t + timeDiff * timeDiffs[i]);

    lastTime = newTime;
    newTime = Date.now() / 1000;
    var timeDiff = newTime - lastTime;
    var timeScale = 1;
    time += timeDiff * timeScale;
}


class Point{
    constructor(x, y, xVel, yVel, size, midiVel, note, lastTimeMoved){
        this.x = x;
        this.y = y;
        this.xVel = xVel;
        this.yVel = yVel;
        this.size = size;
        this.midiVel = midiVel;
        this.note = note;
        this.lastTimeMoved = lastTimeMoved;
    }

    calcMovement(sink, time){
        var forceDirection = {x:sink.x  - this.x, y:sink.y - this.y};
        var vecMagnitude = (forceDirection.x**2 + forceDirection.y**2)**0.5
        this.xVel += forceDirection.x / vecMagnitude * sink.force;
        this.yVel += forceDirection.y / vecMagnitude * sink.force;
        var timeDiff = time - this.lastTimeMoved;
        this.x += this.xVel * timeDiff;
        this.y += this.yVel * timeDiff;
        this.lastTimeMoved = time;

        return this;
    }

    draw(){
        fill(0);
        ellipse(this.x, this.y, this.size, this.size);
    }

    isInFrame(xSize, ySize){
        return 0-this.size <= this.x && this.x <= xSize+this.size && 0-this.size <= this.y && this.y <= ySize+this.size;
    }
}

class Sink{
    constructor(x, y, force){
        this.x = x;
        this.y = y;
        this.force = force;
    }
}

var sinks = [];
var points = [];
function responsevis2bSetup(){
    p5w = 1280;
    p5h = 720;
    createCanvas(p5w, p5h);
    noSmooth();

    var s = new Sink(p5w/2, p5h, 10);
    sinks.push(s);
}

function makePoint(){
    var p = new Point(0, 0, 0, 5, 10, 0, 0, Date.now()/1000);
    points.push(p);
}

function responsevis2bDraw(){
    clear();
    background(255);
    points = points.filter(p => p.isInFrame(p5w, p5h));
    time = Date.now()/1000;
    points.map(p => p.calcMovement(sinks[0], time)).map(p => p.draw());   
}

