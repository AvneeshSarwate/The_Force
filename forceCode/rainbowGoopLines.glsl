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

vec4 colormap_hsv2rgb(float h, float s, float v) {
    float r = v;
    float g = v;
    float b = v;
    if (s > 0.0) {
        h *= 6.0;
        int i = int(h);
        float f = h - float(i);
        if (i == 1) {
            r *= 1.0 - s * f;
            b *= 1.0 - s;
        } else if (i == 2) {
            r *= 1.0 - s;
            b *= 1.0 - s * (1.0 - f);
        } else if (i == 3) {
            r *= 1.0 - s;
            g *= 1.0 - s * f;
        } else if (i == 4) {
            r *= 1.0 - s * (1.0 - f);
            g *= 1.0 - s;
        } else if (i == 5) {
            g *= 1.0 - s;
            b *= 1.0 - s * f;
        } else {
            g *= 1.0 - s * (1.0 - f);
            b *= 1.0 - s;
        }
    }
    return vec4(r, g, b, 1.0);
}

vec4 colormap(float x) {
    float h = clamp(-7.44981265666511E-01 * x + 7.47965390904122E-01, 0.0, 1.0);
    float s = 1.0;
    float v = 1.0;
    return colormap_hsv2rgb(h, s, v);
}

float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

vec4 circleSlice(vec2 stN, float t, float randw){
    
    //define several different timescales for the transformations
    float t0, t1, t2, t3, t4, rw;
    t0 = t/4.5;
    t1 = t/2.1;
    t2 = t/1.1;
    t3 = t/0.93;
    rw =  randw/290.; //a random walk value used to parameterize the rotation of the final frame
    t4 = t;
    
    t1 = t1 / 2.;
    t0 = t0 / 2.;
    rw = rw / 2.;
    float divx = sinN(t0) * 120.+10.;
    float divy = cosN(t1) * 1400.+10.;
    stN = stN * rotate(stN, vec2(0.5), rw);
    vec2 trans2 = vec2(mod(floor(stN.y * divx), 2.) == 0. ? mod(stN.x + (t1 + rw)/4., 1.) : mod(stN.x - t1/4., 1.), 
                       mod(floor(stN.x * divy), 2.) == 0. ? mod(stN.y + t1, 1.) : mod(stN.y - t1, 1.));
    
    
    bool inStripe = false;
    float dist = distance(trans2, vec2(0.5));


    float numStripes = 20.;
    float d = 0.05;
    float stripeWidth =(0.5 - d) / numStripes;
    for(int i = 0; i < 100; i++){
        if(d < dist && dist < d + stripeWidth/2.) {
            inStripe = inStripe || true;
        } else {
            inStripe = inStripe || false;
        }
        d = d + stripeWidth;
        if(d > 0.5) break;
    }
    
    vec4 c = !inStripe ? vec4(white, 1) : vec4(black, 0);
    return c;
    
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

vec2 multiBallCondition(vec2 stN, float t2, float rad){
    
    
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

vec3 ballTwist(vec2 stN, float t2, float numBalls, float rad, float twist){ 
    vec2 warp = stN;
    

    
    for (float i = 0.0; i < 100.; i++) {
        if(i == numBalls) break;
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        // warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
        warp = length(p - stN) <= rad ? rotate(warp, p, (1.-length(stN - p)/rad)  * twist * sinN(1.-length(stN - p)/rad * PI)) : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

float getColor(vec2 stN){
    float numCells = 400.;
    vec2 cent = vec2(0.5);
    vec3 warpN = ballTwist(rotate(stN, cent, time/5.), time/4. + 120., 10., .9, 3.5);
    
    vec2 hashN = stN + sin(time+warpN.xy*PI)/numCells*5.*warpN.xy;
    
    float t = 1500.; //sinN(time+sinN(time)*3.)*10. + 1000.;
    vec3 warpN2 = coordWarp(hashN, time + t/4.*mix(hashN.x-0.5, .5, 0.85+0.05*sinN(t/4.)) * mix(hashN.y-0.5, .5, 0.85+0.05*cosN(t/5.)));
    
    float warpDist = distance(stN, warpN2.xy);
    float playVal = sigmoid((warpDist-0.3)*100.*warpN2.z);
    
    float quantLev = 10.;
    vec2 quantW = quant(warpN.xy, quantLev);
    float parity = mod(quantW.x*quantLev, 2.) == mod(quantW.y*quantLev, 2.) ? 1. : 0.;
    
    vec3 bb2 = texture2D(backbuffer, stN).rgb;
    float fdbkFloor = 0.9;
    
    //basic texture when parity = 0. and fdbkFloor = 0.;
    parity = 0.;
    fdbkFloor = 0.;
    vec2 quantN = quant(stN, quantLev);
    // fdbkFloor = quantN.x; sinN(time/2.5);
    // parity = quantN.y; sinN(time/2.1);
    vec3 col = mix(vec3(playVal), bb2, mix(fdbkFloor,  max(warpDist*10., fdbkFloor), parity));
    
    return col.x;
}

void main () {
    vec2 stN = uvN();
    float numCells = 400.;
    vec2 cent = vec2(0.5);
    float mixN = mix(stN.y, stN.x, sinN(time/2.+stN.x*PI));
    vec3 warpN = ballTwist(stN, (time/4.+1000.)*mix(1., mixN, 0.1) + 120., 20., .35, 5.5);
    vec3 warpN2 = ballTwist(stN, (time/6.2+1000.)*mix(1., mixN, 0.1) + 120., 20., .55, 5.5);
    

    vec3 cc;
    float decay = 0.999;
    float decay2 = 0.05;
    float feedback;
    vec4 bb = texture2D(backbuffer, mix(stN, warpN2.xy, 0.01));
    float lastFeedback = bb.a;

    // vec2 multBall = multiBallCondition(stN, t2/2.);
    float t3 = time/3.;
    float zoomScale = 0.5;
    float numLev = 100.*sinN(time/12.) + 10.; //vs just 10.
    float posLineDif = .01;
    float xw = rotate(warpN.xy, cent, time/10.*PI2).x;
    float lineGranularity = 1.;
    bool condition = mod(xw + time/3., lineGranularity) < lineGranularity*0.5;

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
    
    
    vec3 col = vec3(feedback, warpN.xy);

    float refreshLine = sinN(warpN.x*PI + time/10.);
    
    col = mix(bb.rgb, col, 0.495 < refreshLine && refreshLine < 0.505  ? 1. : 0.01);
    
    // col = multiBallCondition(warpN.xy, time/4., 0.015).x == 1.  ? (hash(vec3(stN, 0.3)).x < 0. ?  white : black) : col;
    
    vec4 bb2 = texture2D(backbuffer, mix(stN, warpN2.xy, 0.005));
    col = mix(bb2.rgb, col, 0.5);
    col = multiBallCondition(warpN.xy, time/4., 0.015).x == 1.  ? (hash(vec3(stN, 0.3)).x < 0. ?  white : black) : col;
    
    gl_FragColor = vec4(col, feedback);
}