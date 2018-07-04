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

vec2 circleSlice(vec2 stN, float t, float randw){
    
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
    return trans2;
    
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

vec3 colorMix(float v){
    vec3 colors[5];
    
    colors[0] = vec3(90.,44.,116.)/255.;
    colors[1] = vec3(171.,110.,182.)/255.;
    colors[2] = vec3(221.,111.,150.)/255.;
    colors[3] = vec3(76.,178.,165.)/255.;
    colors[4] = vec3(33.,141.,128.)/255.;
    float v2 = mod(v, 5.);
    float v3 = mod(v, 1.);
    float mixfactor = 1.;
    if((0. <= v2) && (v2 < 1.)) return mix(colors[0], colors[1], v3*mixfactor);
    else if((1. <= v2) && (v2 < 2.)) return mix(colors[1], colors[2], v3*mixfactor);
    else  if((2. <= v2) && (v2 < 3.)) return mix(colors[2], colors[3], v3*mixfactor);
    else if((3. <= v2) && (v2 < 4.)) return mix(colors[3], colors[4], v3*mixfactor);
    else if((4. <= v2) && (v2 <= 5.)) return mix(colors[4], colors[0], v3*mixfactor);
    else return black;
}

void main () {
    vec2 stN = uvN();
    vec3 c;

    //take 1
    // stN = rowColWave(stN, 100., -time, 0.05);
    // stN = coordWarp(stN, time).xy;
    // float t2 = time / 4.;
    // for(int i = 0; i < 2; i++) {
    //     stN = wrap(rotate(stN, vec2(0.5), t2+0.1) * rotate(stN, vec2(0.5), t2), 0., 1.);
    // }
    // stN = wrap(vec2(tan(stN.x+time/8.), tan(stN.y+time/10.)), 0., 1.);
    stN = mix(stN, rowColWave(stN, 1000., time/10., 0.1), sinN(time/9.));
    stN = mix(stN, circleSlice(stN, time/2., randWalk/2. + 1500.), sinN(time/200.)*0.7);
    stN = xLens(stN, time/10.);
    stN = yLens(stN, time/7.);
    
    
    vec2 center = vec2(0.5);
    
    float dist = distance(stN, center);
    
    vec3 cc = colorMix(dist * 10.);
    
    gl_FragColor = vec4(cc, 1);
}