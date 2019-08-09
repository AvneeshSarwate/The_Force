
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

vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

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

vec2 drops(vec2 stN2, float t2, float numRipples){
    
    vec2 stN0 = stN2;
    float thickness = 0.05;   
    vec2 v = uvN();
    
    bool new = true; //whether the sanity check ripple or parameterized ripple calculation is used (see comments in block)
    
    //when the loop is commented out, everything works normally, but when the
    //loop is uncommented and only iterates once, things look wrong
    float maxRad = 0.5;
    for (float j = 0.; j < 100.; j++) {
        if(j == numRipples) break;
        if(new) {
            //parameterized wave calculation to render multiple waves at once
            float tRad = mod(t2 + j/numRipples, 1.)*maxRad;
            vec2 center = vec2(0.5) + (hash(vec3(0.5, 1.1, 34.1)*j).xy-0.5)/2.; 
            float dist = distance(stN0, center);
            float distToCircle = abs(dist-tRad);
            float thetaFromCenter = stN0.y - center.y > 0. ? acos((stN0.x-center.x) / dist) : PI2*1. - acos((stN0.x-center.x) / dist);
            vec2 nearestCirclePoint = vec2(cos(thetaFromCenter), sin(thetaFromCenter))*tRad + center;
            stN2 = distToCircle < thickness ? mix(stN2, nearestCirclePoint, (1. - distToCircle/thickness) *(maxRad- tRad)/maxRad) : stN2;
        }
        else {
            //essentially copy pasting the wave calculation in main() as a sanity check
            vec2 stN = uvN();
            vec2 center = vec2(0.5);
            float tRad = wrap3(time/3., 0., 1.)/2.;
            float thickness = 0.15;
            float dist = distance(stN, center);
            vec3 c = tRad - thickness < dist && dist < tRad + thickness ? black : white; 
            float distToCircle = abs(dist-tRad);
            float thetaFromCenter = stN.y - 0.5 > 0. ? acos((stN.x-0.5) / dist) : PI2 - acos((stN.x-0.5) / dist);
            vec2 nearestCirclePoint = vec2(cos(thetaFromCenter), sin(thetaFromCenter))*tRad + 0.5;
            v = distToCircle < thickness ? mix(stN, nearestCirclePoint, 1. - distToCircle/thickness) : stN;
        }
    }
    
    return new ? stN2 : v;
}

float sigmoid(float x){
    return 1. / (1. + exp(-x));
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

void main () {
    
    //block for calculating one circular "wave"
    vec2 stN = uvN();
    vec3 c;
    stN += rand2(5.);
    stN = mix(stN, vec2(0.5), pow(sinN(time*4.*PI), 2.)*0.05);
    stN = mix(stN, vec2(0.5), sinN(time*0.125*PI)*0.3);
    
    
    vec3 params1 = vec3(1., 0.005, 0.84);
    vec3 params2 = vec3(4., 0.009, 0.98);
    params2 = params1;
    
    float tm = stepTime(time/2. +stN.y/3., .4 + sinN(time)*0.);
    
    vec3 params = mix(params1, params2, 1. - sigmoid(sin(tm/10.)*50.));
    
    float timeDiv = params.x;
    float distLimit = params.y * pow(sinN(time*4.*PI), 2.);
    float fdbk = params.z;
    
    
    float tScale = tm/timeDiv;
    stN = mix(stN, coordWarp(stN, tScale).xy, 0.2);
    // stN = rowColWave(stN, 1000., tm/4., 0.005);
    vec2 dropCoord = drops(stN, tScale/10., 20.);

    
    stN = rowColWave(dropCoord, 1000., tm, 0.00);
    // stN = stN + (hash(vec3(stN, 5.)).xy-0.5)*0.00;
    float numLines = 50.;
    float gridThickness = 0.003;
    if(mod(stN.x, 1./numLines) < gridThickness || mod(stN.y, 1./numLines) < gridThickness) c =black;
    else c = white;
    
    vec3 cc;
    float decay = fdbk;
    float feedback;
    vec4 bb = avgColorBB(stN, 0.003);
    vec4 bbN = texture2D(backbuffer, mix(uvN(), vec2(0.5), 0.01));
    float lastFeedback = bb.a;
    // bool crazyCond = (circleSlice(stN, time/6., time + sinN(time*sinN(time)) *1.8).x - circleSlice(stN, (time-sinN(time))/6., time + sinN(time*sinN(time)) *1.8).x) == 0.;
    bool condition =  distance(uvN(), stN) < distLimit; c == black;
    vec3 trail = black; // swirl(time/5., trans2) * c.x;
    vec3 foreGround = white;
    
    
    //   implement the trailing effectm using the alpha channel to track the state of decay 
    float trailThresh = 0.3;
    if(condition){
        if(lastFeedback < 1.1) {
            feedback = 1.;
            cc = trail; 
        } 
        else {
            feedback = lastFeedback * decay;
            cc = mix(foreGround, bb.rgb, lastFeedback);
        }
    }
    else {
        feedback = lastFeedback * decay;
        if(lastFeedback > trailThresh) {
            cc = mix(foreGround, trail, lastFeedback); 
        } else {
            feedback = 0.;
            cc = foreGround;
        }
    }
    
    vec2 nn = uvN();
    vec2 down = vec2(nn.x, nn.y+0.01);
    vec3 col = mix(vec3(feedback), avgColorBB(down, 0.01 ).rgb, pow(sinN(time+nn.x*PI), 0.5));
    
    gl_FragColor = vec4(feedback);
}