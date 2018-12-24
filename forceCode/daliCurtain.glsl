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

vec3 ballTwist(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .55;
    
    for (float i = 0.0; i < 10.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        // warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
        warp = length(p - stN) <= rad ? rotate(warp, p, (1.-length(stN - p)/rad)  * 2.5 * sinN(1.-length(stN - p)/rad * PI)) : warp;
    }
    
    return vec3(warp, distance(warp, stN));
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
    float topInd = -1.;
    for(float i = 0.; i < 40.; i++){
        float seed = 1./i;
        stN = rotate(stN0, vec2(0.5), 0.2 * sin(rw+ i*50.));
        float loc = mod(hash(vec3(seed)).x + sinN(rw*seed*5. + seed) * i/5., 1.);
        if(abs(loc - stN.x) < .01) {
            inStripe = inStripe || true;
            topInd = i;
        }
    }
    return inStripe ? vec3(0., 0., topInd) : vec3(1., 1., topInd);
}

vec3 inStripeY2(vec2 stN, float t){
    bool inStripe = false;
    vec2 stN0 = stN;
    float topInd = -1.;
    for(float i = 0.; i < 40.; i++){
        float seed = 1./i;
        stN = rotate(stN0, vec2(0.5), 0.2 * sin(t+ i*50.));
        float loc = mod(hash(vec3(seed)).x + sinN(t*seed*5. + seed) * i/5., 1.);
        if(abs(loc - stN.y) < .01) {
            inStripe = inStripe || true;
            topInd = i;
        }
    }
    return inStripe ? vec3(0., 0., topInd) : vec3(1., 1., topInd);;
}

// calculates the luminance value of a pixel
// formula found here - https://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color 
vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}
float sigmoid(float x){
    return 1. / (1. + exp(-x));
}

float getShimmer(){
    float t2 = time/5. + 1000.;
    vec2 stN = uvN();
    stN.y += 0.001 + sinN(time+stN.x*PI)*0.0015 * sinN(time+stN.x*PI*10.)*0.0015;
    float numCells = 400.;

    vec2 hashN = stN + (hash(vec3(stN, t2)).xy + -0.5)/numCells;

    
    vec3 cc;
    float decay = 0.999;
    float decay2 = 0.01;
    float feedback;
    vec4 bb = texture2D(backbuffer, hashN);
    float lastFeedback = bb.a;

    // vec2 multBall = multiBallCondition(stN, t2/2.);
    bool condition = mod(stN.x*numCells, 1.) < sinN(time + stN.x*PI) || mod(stN.y*numCells, 1.) < cosN(time + stN.y*PI); //multBall.x == 1.; 
    condition = distance(quant(hashN, numCells) + vec2(sinN(t2), cosN(t2))/numCells/2. - 1./numCells/4., hashN) < 1./(numCells*10.);

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
    
    return feedback;
}

float splits(vec2 stN, float low, float high){
    
    float xHigh = high;
    float xLow = low;
    float seed = quant(time/5., 1.);
    float oldSeed = seed - 1.;
    
    float yHigh = high;
    float yLow = low;
    
    bool xSplit = false;
    bool ySplit = false;
    bool dark = false;
    for(int i = 0; i < 8; i++){
        float phase = dark ? 0. : 1.;
        float randSplit = 0.3 + rand(float(i)+phase + seed)*0.4; // * sinN(time*mix(1., rotN.y, sinN(time+stN.y*PI)/300.) + float(i)*PI2/8.);
        float oldSplit = 0.3 + rand(float(i)+phase + oldSeed)*0.4; // * sinN(time*mix(1., rotN.y, sinN(time+stN.y*PI)/300.) + float(i)*PI2/8.);
        randSplit = mix(randSplit, oldSplit, sinN(time*PI/5.));
        if(mod(float(i), 2.) == 0.) {
            float xPos = mix(xLow, xHigh, randSplit);
            if(stN.x <= xPos){
                dark = !dark;
                xHigh = xPos;
            } else {
                xLow = xPos;   
            }
        }
        else {
            float yPos = mix(yLow, yHigh, randSplit);
            if(stN.y <= yPos){
                dark = !dark;
                yHigh = yPos;
            } else {
                yLow = yPos;   
            }
        }
    }
    
    
    float line = 0.005;
    bool nearLine = abs(stN.x - xLow) < line || abs(stN.x - xHigh) < line || abs(stN.y - yLow) < line || abs(stN.y - yHigh) < line;
    return (dark  || nearLine) ? 0. : 1. ;
}


void main () {
    vec2 stN = uvN();
    stN.y += 0.002;
    vec2 cent = vec2(0.5);
    vec3 warpN = ballTwist(stN, time/15. - sinN(time*PI/5.));
    

    float tMod = mod(time, 1.)/2.;
    float split = splits(mix(vec2(warpN.x, stN.x), cent, 0.), 0., 1.);
    float shimmer = getShimmer();


    vec4 bb = texture2D(backbuffer, stN + (hash(vec3(5.))-0.5).xy/300.);
    vec3 col = vec3(split)*shimmer;
    
    col = split == 0. ? col : mix(col, bb.rgb, 0.9);
    
    
    gl_FragColor = vec4(col, shimmer);
}