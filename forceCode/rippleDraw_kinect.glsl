
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
    return (floor(num*quantLevels))/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec3 quant(vec3 num, float quantLevels){
    vec3 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels))/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
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


void main () {
    
    //block for calculating one circular "wave"
    vec2 stN = uvN();
    vec3 c;
    
    vec2 camPos = vec2(1.-stN.x, stN.y); //flip the input x dimension because the macbook camera doesn't mirror the image
    vec3 cam = texture2D(channel0, camPos).rgb; 
    
    vec2 cent = vec2(0.5);
    
    
    vec3 params1 = vec3(1., 0.005, 0.84);
    vec3 params2 = vec3(4., 0.002, 0.98);
    params2 = params1;
    
    vec3 params = mix(params1, params2, 1. - sigmoid(sin(time/7.)*10.));
    // params = mix(params1, params2, wrap3(time/4., 0., 1.)/2. + 0.25); //isolating the transitory "earthquake" looking motion
    
    float timeDiv = params.x;
    float distLimit = params.y;
    float fdbk = .995;params.z;
    
    // stN = distance(cent, uvN()) < mix(sinN(stN.x*PI*sin(time*10.)), stN.y, sinN(time/14.)) ? rotate(stN, cent, time/2.) : stN;
    
    float tScale = time/timeDiv * mix(1., sinN(stN.x+time/3.)*cosN(stN.y+time/2.7), 0.0);
    vec3 warpN = coordWarp(stN, tScale);
    vec3 warpN2 = coordWarp(stN, time/10.);
    stN = mix(stN, warpN.xy, 0.05);
    vec2 dropCoord = drops(stN, tScale/10., 20.);

    
    stN = dropCoord;
    // stN = stN + (hash(vec3(stN, 5.)).xy-0.5)*0.00;
    float numLines = 50.;
    float gridThickness = 0.003;
    if(mod(stN.x, 1./numLines) < gridThickness || mod(stN.y, 1./numLines) < gridThickness) c =black;
    else c = white;
    
    vec3 cc;
    float decay = fdbk;
    float feedback;
    vec4 bb = texture2D(backbuffer, stN + (hash(vec3(4.)).xy)/100.);
    float lastFeedback = bb.a;
    // bool crazyCond = (circleSlice(stN, time/6., time + sinN(time*sinN(time)) *1.8).x - circleSlice(stN, (time-sinN(time))/6., time + sinN(time*sinN(time)) *1.8).x) == 0.;
    bool condition =  distance(uvN(), stN) < distLimit; c == black;
    vec3 trail = black; // swirl(time/5., trans2) * c.x;
    vec3 foreGround = white;
    
    condition =  condition && distance(uvN(), vec2(0.5)+vec2(cos(time), sin(time))*0.3) < 0.1;
    
    //   implement the trailing effectm using the alpha channel to track the state of decay 
    float trailThresh = 0.1;
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
    
    vec3 bb2 =texture2D(backbuffer, uvN()).rgb;
    vec2 stN0 = uvN();
    vec3 warpCoord = coordWarp(stN, time/10.);
    float dist = distance(warpCoord.xy, vec2(0.5));
    // cc =  mod(dist+time/9., 0.1) < 0.05 ? cc : 1. - cc;
    float numStripes = distance(warpN2.xy, uvN())*.3 + 1.4; //lower is more stripes
    float amountDraw = 0.25; 
    vec2 cent2 = vec2(sinN(time), cosN(time))/2. + 0.25;
    
    cam = quant(cam, 3.);
    
    cc =  mix((1.-cc)*cam, bb2, sigmoid(distance(warpN.xy, cent)*20.)*0.95);
    
    float p = 1.;
    cc = vec3(pow(cc.r, p), pow(cc.g, p), pow(cc.b, p));
    
    gl_FragColor = vec4(cc, feedback);
}