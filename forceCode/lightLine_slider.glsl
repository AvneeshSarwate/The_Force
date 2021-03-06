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
    for (int i = 0; i < 10; i++) {
        stN = rowWaves3(stN, div, time2, power);
        stN = columnWaves3(stN, div, time2, power);
    }
    return stN;
}

vec3 coordWarp(vec2 stN, float t2, float numBalls){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 100.; i++) {
        if(i==numBalls) break;
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}



vec2 multiBallCondition(vec2 stN, float t2){
    
    float rad = .08;
    bool cond = false;
    float ballInd = -1.;
    
    for (int i = 0; i < 20; i++) {
        float i_f = float(i);
        vec2 p = vec2(sinN(t2 * rand(vec2(i_f+1., 10.)) * 1.3 + i_f), cosN(t2 * rand(vec2(i_f+1., 10.)) * 1.1 + i_f));
        cond = cond || distance(stN, p) < rad;
        if(distance(stN, p) < rad) ballInd = float(i); 
    }
    
    return vec2(cond ? 1. :0., ballInd/20.);
}

float sigmoid(float x){
    return 1. / (1. + exp(-x));
}

// calculates the luminance value of a pixel
// formula found here - https://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color 
vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}

vec3 ballTwist(vec2 stN, float t2, float numBalls, float intensity, float size){ 
    vec2 warp = stN;
    
    float rad = size;
    
    for (float i = 0.0; i < 100.; i++) {
        if(i == numBalls) break;
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        // warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
        warp = length(p - stN) <= rad ? rotate(warp, p, (1.-length(stN - p)/rad)  * 10.5 * intensity * sinN(1.-length(stN - p)/rad * PI)) : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

//sliderv 7 controls kick - might not need a high
void main () {
    float lowAudio = sinN(time*PI*4.)*sliderVals[7];
    float timeSwing = lowAudio;
    float t2 = sliderVals[1] * 20. + timeSwing;
    
    // vec4 mouseN = mouse / vec4(resolution, resolution) / 2.;
    // mouseN = vec4(mouseN.x, 1.-mouseN.y, mouseN.z, 1.-mouseN.w);
    vec2 cent = vec2(0.5);
    float time1 = sliderVals[0] * 60. + timeSwing;

    vec2 stN = uvN();
    float numCells = 400.;
    vec3 warp = ballTwist(stN, time1/2., 20., sliderVals[5], sliderVals[6]);
    vec3 warpSink = vec3(0.);
    // warpSink = coordWarp(stN, time/20., 3.);
    warpSink = ballTwist(coordWarp(stN, time1/6., 20.).xy, time1/30., 30., sliderVals[5], sliderVals[6]);
    // vec3 warp2 = coordWarp(stN, time +4.);
    stN = mix(stN, warp.xy, 0.025);
    vec2 texN = vec2(0.);
    texN =(hash(vec3(stN, t2)).xy + -0.5)/numCells;
    // texN = vec2(sin(stN.x*numCells), cos(stN.y*numCells))/numCells;
    vec2 hashN = stN + texN;


    float height = 0.5;
    float thickness = 0.03;
    
    vec3 warp2 = coordWarp(warp.xy, time1/2., 20.);
    bool lineCond = abs(warp2.y - height) < thickness;
    // if(mouseN.z > 0.) cent = mouseN.xy;
    bool ballCond = distance(warp2.xy, cent) < sinN(t2/2.)*0.3 && distance(warp2.xy, cent) > sinN(t2/2.)*0.2;
    
    vec3 cc;
    float decay = 0.999;
    float decay2 = 0.05 * sliderVals[2];
    float feedback;
    vec4 bb = texture2D(backbuffer, mix(hashN, warpSink.xy, (sliderVals[4]-0.5)*0.2));
    float lastFeedback = bb.a;

    // vec2 multBall = multiBallCondition(stN, t2/2.);
    bool condition = ballCond;

    //   implement the trailing effectm using the alpha channel to track the state of decay 
    if(condition){
        if(lastFeedback < .9) {
            feedback = 1. ;// * multBall.y;
        } else {
            // feedback = lastFeedback * decay;
            feedback = lastFeedback - decay2;
        }
    }
    else {
        // feedback = lastFeedback * decay;
        feedback = lastFeedback - decay2;
    }
    

    float col = sinN((1.-feedback)*PI*5.);
    
    // col = sigmoid((col-0.5)*5.);
    col = mix(bb.r, col, sliderVals[3]);
    vec3 c = vec3(feedback < 0.1 ? 0. : col);
    
    // c.xy = rotate(c.xy, cent, warp.x*3.);
    // c.yz = rotate(c.yz, cent, warp.y*3.);
    // c.zx = rotate(c.zx, cent, warp.z*3.);
    // c = mix(bb.rgb, col, 0.01);
    
    
    gl_FragColor = vec4(c, feedback);
}