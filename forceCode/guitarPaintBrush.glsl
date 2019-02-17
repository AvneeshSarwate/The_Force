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

    float strokePos = (rotSTN.y-(brushPos.y-brushH))/(2.*brushH);

    vec3 swirlCol = vec3(0.3 + sinN(strokePos*10.*PI+sinN(time*10.)*PI*10.))*swirl(time, stN);
    float bandArr[4];
    bandArr[0] = bands.x;
    bandArr[1] = bands.y;
    bandArr[2] = bands.z;
    bandArr[3] = bands.w;
    return vec3(bandArr[int(floor(strokePos*4.))]);
}

out vec4 fragColor;
void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 cent = vec2(0.5);

    
    float brushH = 0.3 * sliderVals[2];
    float brushW = 0.1 * sliderVals[3];
    
    
    float dev = 100.;
    // vec2 n1 = stN + snoise(vec3(stN*100.*sliderVals[4], time*sliderVals[5]*10.))/dev;
    vec2 n2 = stN + vec2(snoise(vec3(stN*100.*sliderVals[4], time*sliderVals[5]*10.))/dev, snoise(vec3(stN*100.*sliderVals[4], time*sliderVals[5]*10.+35.))/dev);
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
    vec3 c1 = hsv2rgb(vec3(sliderVals[10], 1., 1.));
    vec3 c2 = hsv2rgb(vec3(sliderVals[10]+sliderVals[11]+sinN(time*0.9)/4., 1., 1.));
    float mixVal1 = sinN(rotate(n3, cent, sinN(n3.x+time)*10./(1.+sinN(n3.y*PI+time))).x*10.*PI)/10.;
    float mixVal2 = sliderVals[12];
    vec3 bgCol = /*vec3(distance(stN, n3)*dev)*/mix(c1, c2,  quant(sinN(stN.x*10.*PI), 2.+sinN(time)*10.));
    
    
    
    vec4 bb = texture(backbuffer, mix(stN, n2, sliderVals[6]));
    
    
    vec3 cc;
    float decay = 0.002 + (1.-sliderVals[8])*.05;
    float feedback;
    float lastFeedback = bb.a;
    
    bool condition =  inBrushBox(stN, brushH, brushW); 
    vec3 trail =  brushColor(stN, brushH, brushW)*2.; // swirl(time/5., trans2) * c.x;
    vec3 foreGround = bb.rgb*bgCol;trail;black; lum(swirl(time/4., stN));
    
    
    

    
    if(condition){
        //to make "playhead" stand out from trail you could draw a perimiter around the box using inBrushBox with a border parameter
        feedback = 1.;
        cc = trail*2.;
    }
    else {
        feedback = lastFeedback - decay;
        if(lastFeedback > 0.4) {
            cc = mix(foreGround, bb.rgb, feedback); //trail
        } else {
            feedback = 0.;
            cc = bgCol; 
        }
    }
    
    vec3 cam = texture(channel0, n2).rgb;

    
    
    fragColor = vec4(cc, feedback);
}
