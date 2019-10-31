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


// out vec4 fragColor;
void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 cent = vec2(0.5);
    
    vec2 camPos = vec2(1.-stN.x, stN.y); //flip the input x dimension because the macbook camera doesn't mirror the image
    vec3 cam = texture2D(channel0, camPos).rgb; 
    

    float dev = 100.;
    // vec2 n1 = stN + snoise(vec3(stN*100.*sliderVals[4], time*sliderVals[5]*10.))/dev;
    float tScale = time * 0.7;
    float tm = tScale/4. ;quant(time, 2.);
    float res = 0.0166;
    float scale = .575; sliderVals[0];
    vec2 n2 = stN + vec2(snoise(vec3(stN*100.*res*(scale), tm+0.))/dev, snoise(vec3(stN*100.*res*(scale), tm+35.))/dev);

    float dev2 = 1.;
    vec2 n3 = stN + vec2(snoise(vec3(stN*dev2, tm)), snoise(vec3(stN*dev2, tm+35.)))/dev2;
    

    
    float dist  = distance(stN, n2)*dev;
    dist = clamp(dist, 0., 1.);
    
    float dist2  = distance(stN, n3)*dev2;
    dist2 = clamp(dist2, 0., 1.);

    

    

    
    
    
    
    vec3 cc;
   

    vec3 bb2 = texture2D(backbuffer, mix(stN, n2, 10.5)).rgb;
    vec2 rotN = rotate(stN, cent, snoise(vec3(0.5, 10., tScale/10.))*10.);
    // vec2 rotN2 = rotate(stN, cent, snoise(vec3(1.5, 10., time/10.))*10.);
    vec3 grid = mod(rotN.x*10., 1.) < 0.5 ? black : white;
    // vec3 grid2 = mod(rotN2.y*10., 1.) < 0.5 ? black : white;
    cc = dist < 0.1 + sinN(tScale)*0.4 ? grid :bb2;
    // cc = dist2 < .3 && dist >= 0.1 + sinN(tScale)*0.4 ? black : cc;
    vec3 bb = texture2D(backbuffer, stN).rgb;
    bool condition = distance(uvN(), vec2(0.5)+vec2(cos(time), sin(time))*0.2) < 0.1;
    
    vec3 outCol = cc == white ? cam : 1. - cam;
    
    cc = condition ? outCol : bb;
    
    if(!condition) cc = mix(cc, black, 0.005);
    
    
    
    
    gl_FragColor = vec4(vec3(cc), 1.);
}
