// quantize and input number [0, 1] to quantLevels levels
float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec3 quant(vec3 num, float quantLevels){
    vec3 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

/* bound a number to [low, high] and "wrap" the number back into the range
if it exceeds the range on either side - 
for example wrap(10, 1, 9) -> 8
and wrap (-2, -1, 9) -> 0
*/
float wrap3(float val, float low, float high){
    float range  = high - low;
    if(val > high){
        float dif = val-high;
        float difMod = mod(dif, range);
        float numWrap = dif/range - difMod;
        if(mod(numWrap, 2.) == 0.){
            return high - difMod;
        } else {
            return low + difMod;
        }
    }
    if(val < low){
        float dif = low-val;
        float difMod = mod(dif, range);
        float numWrap = dif/range - difMod;
        if(mod(numWrap, 2.) == 0.){
            return low + difMod;
        } else {
            return high - difMod;
        }
    }
    return val;
}
vec2 wrap(vec2 val, float low, float high){
    return vec2(wrap3(val.x, low, high), wrap3(val.y, low, high));
}

//slice the matrix up into columns and translate the individual columns in a moving wave
vec2 columnWaves3(vec2 stN, float numColumns, float time2, float power){
    return vec2(wrap3(stN.x + sin(time2*8.)*0.05 * power, 0., 1.), wrap3(stN.y + cos(quant(stN.x, numColumns)*5.+time2*2.)*0.22 * power, 0., 1.));
}

//slice the matrix up into rows and translate the individual rows in a moving wave
vec2 rowWaves3(vec2 stN, float numColumns, float time2, float power){
    return vec2(wrap3(stN.x + sin(quant(stN.y, numColumns)*5.+time2*2.)*0.22 * power, 0., 1.), wrap3(stN.y + cos(time2*8.)*0.05 * power, 0., 1.));
}

//iteratively apply the rowWave and columnWave functions repeatedly to 
//granularly warp the grid
vec2 rowColWave(vec2 stN, float div, float time2, float power){
    for (int i = 0; i < 60; i++) {
        if(float(i) > 60. * enoProg) break;
        stN = rowWaves3(stN, div, time2, power);
        stN = columnWaves3(stN, div, time2, power);
    }
    return stN;
}

vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}


//TODO return index of brush (0-4, or -1 if none), map brush width to note velocity
//or, make it bool based on all brushes
int inBrushBox(vec2 stN, float brushH, float brushW){
    // vec2 tl = rotate(brushPos + vec2(-brushW, brushH), brushPos, brushAngle);
    // vec2 tr = rotate(brushPos + vec2(brushW, brushH), brushPos, brushAngle);
    // vec2 bl = rotate(brushPos + vec2(-brushW, -brushH), brushPos, brushAngle);
    // vec2 br = rotate(brushPos + vec2(-brushW, brushH), brushPos, brushAngle);
    int brushInd = -1;
    for(int i = 0; i < 4; i++) {
        vec2 rotSTN = rotate(stN, brushPositions[i], brushAngles[i]);
        vec2 boxDist = abs(rotSTN - brushPositions[i]);

        brushInd = boxDist.x <= brushW && boxDist.y <= brushH ? i : brushInd;
    }
    return brushInd;
}

vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}

vec3 brushColor(vec2 stN, float brushH, float brushW, int brushInd){
    // vec2 tl = rotate(brushPos + vec2(-brushW, brushH), brushPos, brushAngle);
    // vec2 tr = rotate(brushPos + vec2(brushW, brushH), brushPos, brushAngle);
    // vec2 bl = rotate(brushPos + vec2(-brushW, -brushH), brushPos, brushAngle);
    // vec2 br = rotate(brushPos + vec2(-brushW, brushH), brushPos, brushAngle);
    vec2 brushPos = brushPositions[brushInd];
    float brushAngle = brushAngles[brushInd];
    vec2 rotSTN = rotate(stN, brushPos, brushAngle);
    vec2 boxDist = abs(rotSTN - brushPos);

    float strokePos = (rotSTN.y-(brushPos.y-brushH))/(2.*brushH);

    vec3 swirlCol = vec3(0.3 + sinN(strokePos*10.*PI+sinN(time*10.)*PI*10.))*swirl(time, stN);
    float bandArr[4];
    bandArr[0] = bands.x;
    bandArr[1] = bands.y;
    bandArr[2] = bands.z;
    bandArr[3] = bands.w;
    return vec3(fftValues[int(floor(strokePos*50.))]/255.);
}

out vec4 fragColor;
void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 cent = vec2(0.5);

    
    float brushH = 0.3 * sliderVals[2];
    float brushW = 0.1 * sliderVals[3];
    
    
    float loopBlend = min(numLoopsPlaying/5., 1.);

    float dev = 100.;
    // vec2 n1 = stN + snoise(vec3(stN*100.*sliderVals[4], time*sliderVals[5]*10.))/dev;
    float warpZoom = mix(sliderVals[4], 0.02, loopBlend);
    vec2 n2 = stN + vec2(snoise(vec3(stN*100.*warpZoom, time*sliderVals[5]*10.))/dev, snoise(vec3(stN*100.*warpZoom, time*sliderVals[5]*10.+35.))/dev);
    float dev2 = 10.;
    vec2 n3 = stN + vec2(snoise(vec3(stN*10.*sliderVals[9], time*sliderVals[5]*10.)), snoise(vec3(stN*10.*sliderVals[9], time*sliderVals[5]*10.+35.)))/dev2;
    
    float dist  = distance(stN, n2)*dev;
    dist = clamp(dist, 0., 1.);

    

    float d2 = dist <= 0.3 + sinN(time)*0.6 ? 1. : 0.;
    float d3 = pow(dist, 0.1+sinN(time+stN.x*PI)*1.8);
    vec3 sw1 = swirl(time/100., mix(n2, cent, sliderVals[7]));
    vec3 sw2 = swirl(time/50.+10., mix(n2, cent, sliderVals[7]));
    
    //decide whether to use n2 or n3 or what combination 
    // n3 = quant(n3,10.);
    vec3 c1 = droneNotes.x < 0. ? black : hsv2rgb(vec3(sliderVals[10] + mod(droneNotes.x, 12.)/12. * 0.3, 1., 1.))/2.;
    vec3 c2 = droneNotes.y < 0. ? black : hsv2rgb(vec3(sliderVals[10] + mod(droneNotes.y, 12.)/12. * 0.3, 1., 1.));

    
    //todo: times here dependent on drone note onsets (either triggered envelopes or sustain times)
    float noiseVal = snoise(vec3(stN*5., time/5.));
    
    vec3 bgCol = mix(c1, c2,  (noiseVal*noiseVal)/noiseVal);
    
    
    float trailWarpMix = mix(sliderVals[6], 1., loopBlend);
    vec4 bb = texture(backbuffer, mix(stN, n2, trailWarpMix));
    
    
    vec3 cc;
    float decayScale = mix(sliderVals[8], 1., loopBlend);
    float decay = 0.002 + (1.-decayScale)*.05;
    float feedback;
    float lastFeedback = bb.a;
    
    int brushInd = inBrushBox(stN, brushH, brushW);
    bool condition = brushInd > -1; 
    vec3 trail = brushColor(stN, brushH, brushW, brushInd)*2.; // swirl(time/5., trans2) * c.x;
    vec3 hsvCol = rgb2hsv(bgCol);
    vec3 foreGround = hsv2rgb(hsvCol*vec3(1., sliderVals[13], sliderVals[14]));
    
    
    

    
    if(condition){
        //to make "playhead" stand out from trail you could draw a perimiter around the box using inBrushBox with a border parameter
        feedback = 1.;
        cc = trail*2.;
    }
    else {
        feedback = lastFeedback - decay;
        if(lastFeedback > 0.4) {
            // cc = mix(foreGround, mix(hsv2rgb(foreGround), bb.rgb*(1.-foreGround), feedback), feedback); //trail
            cc = mix(bgCol, bb.rgb, pow(feedback, 0.5));
        } else {
            feedback = 0.;
            cc = foreGround; 
        }
    }

    
    
    fragColor = vec4(cc, feedback);
}
