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
    for (int i = 0; i < 20; i++) {
        if(i > int(vjlastnote[1])) break;
        stN = rowWaves3(stN, div, time2, power);
        stN = columnWaves3(stN, div, time2, power);
    }
    return mix(stN, vec2(0.5), sinN(time/midi[16+2])*0.99);
}

vec2 coordWarp(vec2 stN){ 
    vec2 warp = stN;
    
    float rad = .1;
    
    for (float i = 0.0; i < 200.; i++) {
        vec2 p = vec2(sinN(time* rand(i+1.) * 1.3 + i), cosN(time * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return warp;
}

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    // stN = coordWarp(stN);
    vec2 camN = vec2(1.- stN.x, stN.y);
    

    //define several different timescales for the transformations
    float t0, t1, t2, t3, t4, rw;
    
    float tmidi = vjlastnote[0] + time * midi[16+1]/70.;
    
    t0 = tmidi/4.;
    t1 = tmidi/2.;
    t2 = tmidi;
    t3 = tmidi;
    rw =  tmidi/90.; //a random walk value used to parameterize the rotation of the final frame
    t4 = tmidi;
    
    vec2 deepTileWave = rowColWave(camN * (.2 + sinN(t0)*3.), 1. + sinN(t1) * 20., t2, 0.1 + sinN(t3)/2.);
    vec2 warpTileCoord2 = wrap(rotate(deepTileWave, vec2(0.5), rw)*5., 0., 1.);
    vec3 wrapTile = texture2D(channel0, quant(coordWarp(warpTileCoord2), 50.)).rgb;
    
    vec3 c = wrapTile * (1.5 + midi[16+0]/10.);
    // c = swirl(time/5., stN);
    gl_FragColor = vec4(c, 1);
}

