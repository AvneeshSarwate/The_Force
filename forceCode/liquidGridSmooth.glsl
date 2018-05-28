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

float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 translate = vec2(sin(time/2.5), cos(time/3.1))*stN;
    // stN = wrap(stN+translate, 0., 1.);
    // stN = mod(stN+translate, 1.);
    vec2 camN = vec2(1.- stN.x, stN.y);
    vec3 cam = texture2D(channel0, camN).rgb;
    vec3 snap = texture2D(channel3, camN).rgb;
    float colorDist = colourDistance(cam, snap)/colourDistance(vec3(0.), vec3(1.)); 
    
    
    float tScale = time / 5.;
    vec2 colorPoint = vec2(sinN(tScale), cosN(tScale));
    vec2 mouseN = mouse.zw / resolution.xy / 2.;
    mouseN = vec2(mouseN.x, 1. - mouseN.y);
    vec3 mouseCam = texture2D(channel0, colorPoint).xyz;
    float blend = 0.1;
    
    blend = (colourDistance(mouseCam, cam) / colourDistance(vec3(0.), vec3(1.))) > 0.2 ? 0.1: 0.;
    
    stN = mix(stN, cam.xy, blend * sinN(time / 9.5));
    

    //define several different timescales for the transformations
    float t0, t1, t2, t3, t4, rw;
    t0 = time/4.5;
    t1 = time/2.1;
    t2 = time/1.1;
    t3 = time/0.93;
    rw =  randWalk/290.; //a random walk value used to parameterize the rotation of the final frame
    t4 = time;
    
    vec2 coord = stN*0.8; camN * (.2 + sinN(t0)*3.);
    float div = 500.; 1. + sinN(t1) * 20.;
    float power = 0.5; 0.1 + sinN(t3)/2.;
    
    vec2 trans = rowColWave(coord, div, t2/10., power);
    trans = wrap(rotate(trans, vec2(0.5), rw)*1., 0., 1.);
    // trans = quant(trans, 3.);
    vec3 wrapTile = texture2D(channel0, trans).rgb;
    
    
    bool inStripe = false;
    float dist = distance(trans, vec2(0.5));
    float stripeRadius = 0.;
    for(float d = 0.05; d < 0.5; d += 0.03){
        if(d < dist && dist < d + 0.015) {
            inStripe = inStripe || true;
            stripeRadius = d;
        } else {
            inStripe = inStripe || false;
        }
    }
    
    vec3 c = !inStripe ? white : black;
    
    vec3 bb = texture2D(backbuffer, stN).rgb;
    // c = quant(c, 2.);

    c = mix(bb, c, 0.1 + sinN(t0)*0.5);
    
    gl_FragColor = vec4(vec3(c), 1);
}

