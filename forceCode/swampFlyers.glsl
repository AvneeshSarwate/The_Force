
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

float timeWarp(float t){
    return (t + sinN(t+sinN(t)) *1.8);
}

vec2 pointWarp(vec2 stN, float t, float i){
    float rwscale = randWalk/(80. + 10.*i);
    vec2 center = vec2(sinN(rwscale), cosN(rwscale))*0.5 +.25;
    // center = vec2(0.5);
    return stN * rotate(stN, center, t);
}


bool multiBallCondition(vec2 stN, float t){
    
    
    bool cond = false;
    
    float rad = 0.03;
    for (float i = 0.0; i < 40.; i++) {
        float twarp = timeWarp(t-i);
        vec2 coordWarp = pointWarp(stN, (time-i), i);
        float randt = twarp * rand(i+1.);
        vec2 p = vec2(sinN(randt * 1.3 + i), cosN(randt * 1.1 + i));
        cond = cond || distance(coordWarp, p) < rad;
    }
    
    return cond;
}

vec2 movementDeviation(float t){ //argument time
    return vec2(sin((cosN(t/5.52)* 20. + sinN(t/6.32)*305.)/50.), 
                     cosN((sinN(t/1.52)* 20. + cosN(t/1.32)*250.)/500.)) *0.005 * sinN(time/10.) + 0.001;
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

vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    // stN = rotate(stN, vec2(0.5), time/18000.);
    // stN = stN - vec2(sin((cosN(time/15.2)* 20. + sinN(time/13.2)*35.)/500.)*10., 
    //                  cos((sinN(time/15.2)* 20. + cosN(time/13.2)*35.)/500.)*1./2.) *0.01;
    vec2 movement = movementDeviation(time);
    // if(movement.x < 0. && gl_FragCoord.x == resolution.x) {
    //     gl_FragColor = vec4(white, 0);
    //     return;
    // }
    // if(movement.x > 0. && gl_FragCoord.x == 0.) {
    //     gl_FragColor = vec4(white, 0);
    //     return;
    // }
    // movement = vec2(-0.01, 0);
    bool newBorderPixel = false;
    if(movement.x < 0. && stN.x > 1. -  abs(movement.x)){
        newBorderPixel = true;
    }
    if(movement.x > 0. && stN.x < movement.x){
        newBorderPixel = true;
    }
    if(movement.y < 0. && stN.y > 1. -  abs(movement.y)){
       newBorderPixel = true;
    }
    if(movement.y > 0. && stN.y < movement.y){
        newBorderPixel = true;
    }
    if(newBorderPixel){
        gl_FragColor = vec4(white, 0);
        return;
        // movement = movementDeviation(time+2.);
    }
    stN = stN - movement;
    stN = wrap(stN, 0., 1.);
    vec2 warpN = coordWarp(uvN(), time/6.).xy;
    vec2 warpN2 = mix(uvN(), warpN, 0.1);
    warpN = mix(uvN(), warpN, 1.91);
    


    vec3 cc;
    float decay = 0.99;
    float feedback;
    float rval = hash(vec3(stN, time)).x;
    vec4 bb = avgColorBB(mix(stN, warpN2, 0.14), 0.0*rand(rval*100.)); texture2D(backbuffer, vec2(stN.x, stN.y));
    float lastFeedback = bb.a;
    // bool crazyCond = (circleSlice(stN, time/6., time + sinN(time*sinN(time)) *1.8).x - circleSlice(stN, (time-sinN(time))/6., time + sinN(time*sinN(time)) *1.8).x) == 0.;
    // bool condition = circleSlice(stN, time/2., randWalk/2. + 1500.).z == 0.; 
    bool condition = multiBallCondition(warpN, time/5.);
    
    
    
    
    vec3 trail = black; // swirl(time/5., trans2) * c.x;
    vec3 foreGround = white;
    
    
    //   implement the trailing effectm using the alpha channel to track the state of decay 
    if(condition){
        if(lastFeedback < .4) {
            feedback = 1.;
            cc = trail; 
        } else {
            feedback = lastFeedback*pow(warpN.x, 4.);
            cc = bb.rgb;
        } 
        // else {
        //     feedback = lastFeedback * decay;
        //     c = mix(snap, bb, lastFeedback);
        // }
    }
    else {
        feedback = lastFeedback * decay;
        if(lastFeedback > 0.2) {
            cc = mix(foreGround, trail, lastFeedback); 
        } else {
            feedback = 0.;
            cc = foreGround;
        }
    }
    
    cc = mix(bb.rgb, cc, 0.5);
    
    gl_FragColor = vec4(cc, feedback);
}