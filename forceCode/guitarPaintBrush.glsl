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

bool inBrushBox(vec2 stN, float brushH, float brushW){
    // vec2 tl = rotate(brushPos + vec2(-brushW, brushH), brushPos, brushAngle);
    // vec2 tr = rotate(brushPos + vec2(brushW, brushH), brushPos, brushAngle);
    // vec2 bl = rotate(brushPos + vec2(-brushW, -brushH), brushPos, brushAngle);
    // vec2 br = rotate(brushPos + vec2(-brushW, brushH), brushPos, brushAngle);

    vec2 rotSTN = rotate(stN, brushPos, brushAngle);
    vec2 boxDist = abs(rotSTN - brushPos);

    return boxDist.x <= brushW && boxDist.y <= brushH;
}

vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}

vec3 brushColor(vec2 stN, float brushH, float brushW){
    // vec2 tl = rotate(brushPos + vec2(-brushW, brushH), brushPos, brushAngle);
    // vec2 tr = rotate(brushPos + vec2(brushW, brushH), brushPos, brushAngle);
    // vec2 bl = rotate(brushPos + vec2(-brushW, -brushH), brushPos, brushAngle);
    // vec2 br = rotate(brushPos + vec2(-brushW, brushH), brushPos, brushAngle);

    vec2 rotSTN = rotate(stN, brushPos, brushAngle);
    vec2 boxDist = abs(rotSTN - brushPos);

    float strokePos = (stN.y-(brushPos.y-brushH))/(2.*brushH);

    return vec3(0.3 + sinN(strokePos*10.*PI+sinN(time*10.)*PI*10.))*swirl(time, stN);
}

out vec4 fragColor;
void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 cent = vec2(0.5);


    vec3 p5 = texture(channel1, stN).rgb;
    vec3 p5Snap = texture(channel2, stN).rgb;
    
    
    float brushH = 0.3 * sliderVals[2];
    float brushW = 0.1 * sliderVals[3];
    
    
    float dev = 100.;
    vec2 n2 = stN + snoise(vec3(stN*100.*sliderVals[4], time*sliderVals[5]*10.))/dev;
    
    float dist  = distance(stN, n2)*dev;
    dist = clamp(dist, 0., 1.);
    // dist = .1 + pow(dist, 1.0)*.8;
    
    // dist = 0.3 + dist*0.7;
    float d2 = dist <= 0.3 + sinN(time)*0.6 ? 1. : 0.;
    float d3 = pow(dist, 0.1+sinN(time+stN.x*PI)*1.8);
    vec3 sw1 = swirl(time/100., mix(n2, cent, sliderVals[7]));
    vec3 sw2 = swirl(time/50.+10., mix(n2, cent, sliderVals[7]));
    vec3 bgCol = vec3(mix(sw1, sw2, d3));
    vec4 bb = texture(backbuffer, mix(stN, n2, sliderVals[6]));
    
    
    vec3 cc;
    float decay = 0.002;
    float feedback;
    float lastFeedback = bb.a;
    // bool crazyCond = (circleSlice(stN, time/6., time + sinN(time*sinN(time)) *1.8).x - circleSlice(stN, (time-sinN(time))/6., time + sinN(time*sinN(time)) *1.8).x) == 0.;
    bool condition =  inBrushBox(stN, brushH, brushW); 
    vec3 trail =  brushColor(stN, brushH, brushW); // swirl(time/5., trans2) * c.x;
    vec3 foreGround = lum(swirl(time/4., stN));
    
    
    //   implement the trailing effectm using the alpha channel to track the state of decay 
    

    
    if(condition){
        feedback = 1.;
        cc = trail;
    }
    else {
        feedback = lastFeedback - decay;
        if(lastFeedback > 0.4) {
            cc = mix(foreGround, bb.rgb, feedback);
        } else {
            feedback = 0.;
            vec4 bb2 = texture(backbuffer, n2);
            cc = mix(foreGround, bb.rgb, feedback);
            cc =bgCol; // mix(red, blue, distance(stN, n2)*50. *sliderVals[4]+.5*(1.-sliderVals[4]));
        }
        // cc = foreGround;
    }
    
    vec3 cam = texture(channel0, n2).rgb;
    p5 = inBrushBox(stN, 0.1, 0.005)  ? brushColor(stN, 0.1, 0.005) : bb.rgb;
    
    
    fragColor = vec4(cc, feedback);
}
