//rolltide-sliders

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


vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
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

vec3 inStripeX(vec2 stN, float rw){
    bool inStripe = false;
    for(float i = 0.; i < 40.; i++){
        float seed = 1./i;
        float loc = mod(hash(vec3(seed)).x + rw, 1.);
        if(abs(loc - stN.x) < 0.002) inStripe = inStripe || true;
    }
    return inStripe ? black : white;
}

vec3 inStripeY(vec2 stN, float t){
    bool inStripe = false;
    for(float i = 0.; i < 40.; i++){
        float seed = 1./i;
        float loc = mod(hash(vec3(seed)).x + t, 1.);
        if(abs(loc - stN.y) < 0.002) inStripe = inStripe || true;
    }
    return inStripe ? black : white;
}

vec3 inStripeX2(vec2 stN, float rw){
    bool inStripe = false;
    vec2 stN0 = stN;
    for(float i = 0.; i < 40.; i++){
        float seed = 1./i;
        stN = rotate(stN0, vec2(0.5), 0.2 * sin(rw+ i*50.));
        float loc = mod(hash(vec3(seed)).x + sinN(rw*seed*5. + seed) * i/5., 1.);
        if(abs(loc - stN.x) < rand(seed)*0.005 + 0.001) inStripe = inStripe || true;
    }
    return inStripe ? black : white;
}

vec3 inStripeY2(vec2 stN, float t){
    bool inStripe = false;
    vec2 stN0 = stN;
    for(float i = 0.; i < 40.; i++){
        float seed = 1./i;
        stN = rotate(stN0, vec2(0.5), 0.2 * sin(t+ i*50.));
        float loc = mod(hash(vec3(seed)).x + sinN(t*seed*5. + seed) * i/5., 1.);
        if(abs(loc - stN.y) < rand(seed)*0.005  + 0.001) inStripe = inStripe || true;
    }
    return inStripe ? black : white;
}

vec2 xLens(vec2 stN, float rw){
    bool inStripe = false;
    vec2 stN0 = stN;
    vec2 coord = stN;
    float lensSize = 0.05;
    for(float i = 0.; i < 40.; i++){
        float seed = 1./i;
        stN = rotate(stN0, vec2(0.5), 0.3 * sin(rw+ i*50.));
        float loc = mod(hash(vec3(seed)).x + sinN(rw*seed*5. + seed) * i/5., 1.);
        if(abs(loc - stN.x) < lensSize) coord = vec2(mix(loc, coord.x, abs(loc - stN.x)/lensSize), coord.y);
    }
    return coord;
}

vec2 yLens(vec2 stN, float t){
    bool inStripe = false;
    vec2 stN0 = stN;
    vec2 coord = stN;
    float lensSize = 0.05;
    for(float i = 0.; i < 40.; i++){
        float seed = 1./i;
        stN = rotate(stN0, vec2(0.5), 0.3 * sin(t+ i*50.));
        float loc = mod(hash(vec3(seed)).x + sinN(t*seed*5. + seed) * i/5., 1.);
        if(abs(loc - stN.y) < lensSize) coord = vec2(coord.x, mix(loc, coord.y, abs(loc - stN.y)/lensSize));
    }
    return coord;
}

// calculates the luminance value of a pixel
// formula found here - https://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color 
vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}

float logisticSigmoid (float x, float a){
  // n.b.: this Logistic Sigmoid has been normalized.

  float epsilon = 0.0001;
  float min_param_a = 0.0 + epsilon;
  float max_param_a = 1.0 - epsilon;
  a = max(min_param_a, min(max_param_a, a));
  a = (1./(1.-a) - 1.);

  float A = 1.0 / (1.0 + exp(0. -((x-0.5)*a*2.0)));
  float B = 1.0 / (1.0 + exp(a));
  float C = 1.0 / (1.0 + exp(0.-a)); 
  float y = (A-B)/(C-B);
  return y;
}

float stepTime(float t, float a){
    return floor(t) + logisticSigmoid(fract(t), a);
}

float rand2(float f) {vec2 n = vec2(f); return (fract(1e4 * sin(17.0 * n.x + n.y * 0.1) * (0.1 + abs(sin(n.y * 13.0 + n.x))))-0.5)*0.002;}

vec4 avgColorBB(vec2 nn, float dist){
    vec4 c1 = texture2D(backbuffer, nn+vec2(0, dist)      +rand2(1.)).rgba;
    vec4 c2 = texture2D(backbuffer, nn+vec2(0, -dist)     +rand2(2.)).rgba;
    vec4 c3 = texture2D(backbuffer, nn+vec2(dist, 0)      +rand2(3.)).rgba;
    vec4 c4 = texture2D(backbuffer, nn+vec2(-dist, 0)     +rand2(4.)).rgba;
    vec4 c5 = texture2D(backbuffer, nn+vec2(dist, dist)   +rand2(5.)).rgba;
    vec4 c6 = texture2D(backbuffer, nn+vec2(-dist, -dist) +rand2(6.)).rgba;
    vec4 c7 = texture2D(backbuffer, nn+vec2(dist, -dist)  +rand2(7.)).rgba;
    vec4 c8 = texture2D(backbuffer, nn+vec2(-dist, dist)  +rand2(8.)).rgba;
    
    return (c1+c2+c3+c4+c5+c6+c7+c8)/8.;
}

//slice the matrix up into columns and translate the individual columns in a moving wave
vec2 columnWaves3(vec2 stN, float numColumns, float time2, float power){
    return vec2(wrap3(stN.x + sin(time2*7.3)*sliderVals[0] * power, 0., 1.), wrap3(stN.y + cos(quant(stN.x, numColumns)*5.+time2*2.)*sliderVals[1] * power, 0., 1.));
}

//slice the matrix up into rows and translate the individual rows in a moving wave
vec2 rowWaves3(vec2 stN, float numColumns, float time2, float power){
    return vec2(wrap3(stN.x + sin(quant(stN.y, numColumns)*5.+time2*2.5)*sliderVals[2] * power, 0., 1.), wrap3(stN.y + cos(time2*8.)*sliderVals[3] * power, 0., 1.));
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

void main () {
    vec2 stN = uvN();
    vec2 rotN = rotate(stN, vec2(0.5), controllableTime/2.);
    
    rotN = rowColWave(stN, ceil(pow(sliderVals[4], 10.)*1000.+1.), controllableTime*.1, pow(sliderVals[6], 3.));
    
    float numCells = (2.+rotN.x*PI) *(pow(sliderVals[5], 4.)+0.001)*10.;
    float rad = 0.5/numCells;
    vec2 quantN = quant(rotN, numCells);
    vec2 circCenter = quantN;
    
    float rad2 = 0.01 + rad * sinN(controllableTime*4.  + stN.x*PI * 3.) * 0.6;
    // rad2 = rad* 0.3;
    vec3 c = distance(rotN, circCenter) < rad2 ? black : white;

    
    vec3 cc;
    float decay = 0.97;
    float feedback;
    vec4 bb = avgColorBB(mix(stN, rotN, 0.1*liderVals[7]), 0.005);
    float lastFeedback = bb.a;
    // bool crazyCond = (circleSlice(stN, time/6., time + sinN(time*sinN(time)) *1.8).x - circleSlice(stN, (time-sinN(time))/6., time + sinN(time*sinN(time)) *1.8).x) == 0.;
    bool condition = c == black; 
    vec3 trail = black; // swirl(time/5., trans2) * c.x;
    vec3 foreGround = white;
    
    
    //   implement the trailing effectm using the alpha channel to track the state of decay 
    if(condition){
        if(lastFeedback < 1.1) {
            feedback = 1.;
            cc = trail; 
        } 
        // else {
        //     feedback = lastFeedback * decay;
        //     c = mix(snap, bb, lastFeedback);
        // }
    }
    else {
        feedback = lastFeedback * decay;
        if(lastFeedback > 0.4) {
            cc = mix(foreGround, trail, lastFeedback); 
        } else {
            feedback = 0.;
            cc = foreGround;
        }
    }
    cc = mix(cc, bb.rgb, distance(stN, quantN)*numCells/2.);
    
    
    gl_FragColor = vec4(cc, feedback);
}
