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




out vec4 fragColor;
void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 cent = vec2(0.5);
    
    vec2 mouseN = mouse.xy/2./resolution.xy;
    vec2 circ = vec2(mouseN.x, 1.-mouseN.y);
    
    float dev = 100.;
    // vec2 n1 = stN + snoise(vec3(stN*100.*0.05, time*0.05*10.))/dev;
    vec2 n2 = stN + vec2(snoise(vec3(stN*100.*0.05, time*0.05*10. + 0.05*10.))/dev, snoise(vec3(stN*100.*0.05, time*0.05*10.+35. + 0.05*10.))/dev);
    
    float dist  = distance(stN, n2)*dev;
    dist = clamp(dist, 0., 1.);

    
    vec4 bb = texture(backbuffer, mix(stN, n2, 0.05));
    
    bool condition = distance(uvN(), circ) < 0.3;
    
    vec3 cc;
    float decay = 0.002 + (1.-0.05)*.05;
    float feedback;
    float lastFeedback = bb.a;
    
    
    
    vec2 camPos = vec2(1.-stN.x, stN.y);
    vec2 camPos2 = vec2(1.-n2.x, n2.y);
    vec3 cam = texture(channel0, camPos).rgb;
    vec3 cam2 = texture(channel0, camPos2).rgb;
    vec3 bb2 = texture(backbuffer, mix(stN, n2, 0.2)).rgb;
    bool trailCond = dist <= 0.25;
    cc = trailCond ? cam : bb2.rgb;
    vec3 bb2hsv = rgb2hsv(bb2);
    cc = dist < 0.25 ? cam2 : hsv2rgb(bb2hsv + vec3(0., -0.03 + 0.5*0.06, 0.));

    cc = condition || !trailCond ? cc : black;
    
    
    fragColor = vec4(vec3(cc), feedback);
}
