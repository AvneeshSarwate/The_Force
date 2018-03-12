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

/* constructs a series that produces interesting results for mapping,
 particularly when used in the denominator */ 
float twinGeo(float v, float range){
    if(v > 0.5) return (v-0.5) * 2. * range;
    if(v < 0.5) return 1. / (abs(v-0.5) * 2. * range);
    return 1.;
}


vec2 columnWaves(vec2 stN, float numColumns){
    return vec2(wrap3(stN.x + sin(quant(stN.x, numColumns)*time*8.)*0.05, 0., 1.), wrap3(stN.y + cos(quant(stN.x, numColumns)*5.+time*2.)*0.22, 0., 1.));
}
vec2 rowWaves(vec2 stN, float numColumns){
    return vec2(wrap3(stN.x + sin(quant(stN.y, numColumns)*5.+time*2.)*0.22, 0., 1.), wrap3(stN.y + cos(quant(stN.y, numColumns)*time*8.)*0.05, 0., 1.));
}

//removed position dependent speed for more order
vec2 columnWaves2(vec2 stN, float numColumns){
    return vec2(wrap3(stN.x + sin(time*8.)*0.05, 0., 1.), wrap3(stN.y + cos(quant(stN.x, numColumns)*5.+time*2.)*0.22, 0., 1.));
}
vec2 rowWaves2(vec2 stN, float numColumns){
    return vec2(wrap3(stN.x + sin(quant(stN.y, numColumns)*5.+time*2.)*0.22, 0., 1.), wrap3(stN.y + cos(time*8.)*0.05, 0., 1.));
}

vec2 columnWaves3(vec2 stN, float numColumns, float time2, float power){
    return vec2(wrap3(stN.x + sin(time2*8.)*0.05 * power, 0., 1.), wrap3(stN.y + cos(quant(stN.x, numColumns)*5.+time2*2.)*0.22 * power, 0., 1.));
}
vec2 rowWaves3(vec2 stN, float numColumns, float time2, float power){
    return vec2(wrap3(stN.x + sin(quant(stN.y, numColumns)*5.+time2*2.)*0.22 * power, 0., 1.), wrap3(stN.y + cos(time2*8.)*0.05 * power, 0., 1.));
}

vec2 rowColWave(vec2 stN, float div, float time2, float power){
    for (int i = 0; i < 5; i++) {
        stN = rowWaves3(stN, div, time2, power);
        stN = columnWaves3(stN, div, time2, power);
    }
    return stN;
}

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 camN = vec2(1.- stN.x, stN.y);
    

    
    float t0, t1, t2, t3, t4, rw;
    t0 = time/4.;
    t1 = time/2.;
    t2 = time;
    t3 = time;
    rw =  randWalk/90.;
    t4 = time;
    
    vec2 deepTileWave = rowColWave(camN * (.2 + sinN(t0)*3.), 1. + sinN(t1) * 20., t2, 0.1 + sinN(t3)/2.);
    vec2 wrapTileCoord = wrap(rotate(deepTileWave, vec2(sinN(time/3.), cosN(time/3.)), time)*(1. + sinN(time/5.)*10.), 0., 1.);
    vec2 warpTileCoord2 = wrap(rotate(deepTileWave, vec2(0.5), rw)*5., 0., 1.);
    vec3 wrapTile = texture2D(channel0, warpTileCoord2).rgb;
    
    gl_FragColor = vec4(wrapTile, 1);
}

