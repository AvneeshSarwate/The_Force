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

vec2 rand2(float f, float d) {
    vec2 n = vec2(f*100000.); 
    float x =  (fract(1e4 * sin(17.0 * n.x) * (0.1 + abs(sin(n.y * 13.0 ))))-.5)*d;
    float y =  (fract(1e4 * sin(13.0 * n.x) * (0.1 + abs(sin(n.y * 103.0))))-.5)*d;
    return vec2(x, y);
}

vec4 avgSamp1(sampler2D tex, vec2 nn, float dist, float d){
    vec4 c1 = texture2D(tex, nn+vec2(0, dist)      +rand2(1., d)).rgba;
    vec4 c2 = texture2D(tex, nn+vec2(0, -dist)     +rand2(2., d)).rgba;
    vec4 c3 = texture2D(tex, nn+vec2(dist, 0)      +rand2(3., d)).rgba;
    vec4 c4 = texture2D(tex, nn+vec2(-dist, 0)     +rand2(4., d)).rgba;
    vec4 c5 = texture2D(tex, nn+vec2(dist, dist)   +rand2(5., d)).rgba;
    vec4 c6 = texture2D(tex, nn+vec2(-dist, -dist) +rand2(6., d)).rgba;
    vec4 c7 = texture2D(tex, nn+vec2(dist, -dist)  +rand2(7., d)).rgba;
    vec4 c8 = texture2D(tex, nn+vec2(-dist, dist)  +rand2(8., d)).rgba;
    
    return (c1+c2+c3+c4+c5+c6+c7+c8)/8.;
}

float normAngle(vec2 pt, vec2 cent){
    return pt.x >= cent.x ? (asin((pt.y-cent.y)/distance(pt, cent))+(PI/2.))/PI/2. : (1.-(asin((pt.y-cent.y)/distance(pt, cent))+(PI/2.))/PI)*0.5+0.5;
}

float radFunc(float angle, float t){
    return sinN(sin(angle*5.+sin(t*4.3+angle*5.1))*4.+t);
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

//sliderv 7 controls kick - might not need a high
void main () {

    vec2 stN = uvN();
    float t2 = time*0.2;
    vec2 dev = vec2(snoise(vec2(t2, 0.5)), snoise(vec2(2, 50.)))*0.5;
    float t3 = stepTime(time*0.3, .8);;
    dev = vec2(snoise(vec2(t3, 0.5)), cos(time*1.3))*0.3;
    vec2 cent = vec2(0.5) + dev;
    float angle = normAngle(rotate(stN, cent, -time*1.3), cent);
    
    float t = time*0.25;
    float rad = mix(radFunc(angle+t, 5.), radFunc(t, 5.), pow(angle, 10.))*0.1;
    vec3 col = rad +0.05 < distance(stN, cent) && distance(stN, cent) < 0.1 + rad  ? white : black;
    
    
    float feedback;
    vec4 bb = texture2D(backbuffer, stN);
    bb = avgSamp1(backbuffer, stN, 0.001, 0.002);
    float lastFeedback = bb.a;
    float decay = 0.01;
    bool condition = col == white;
    
    if(condition){
        feedback = 1.;
    } else {
        feedback = max(0., lastFeedback - decay);
    }
    
    col = mix(white, black, 1.-pow(feedback, 1.));
    // col =distance(stN, cent) < 0.1 + rad ? vec3(sinN(col.x*10.)) : bb.rgb;
    col = vec3(1.-cosN(col.x*4.*PI));
    
    gl_FragColor = vec4(col, feedback);
}
