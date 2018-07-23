
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


vec2 drops(vec2 stN2, float t2){
    
    vec2 stN0 = stN2;
    float thickness = 0.15;   
    vec2 v = uvN();
    
    bool new = true; //whether the sanity check ripple or parameterized ripple calculation is used (see comments in block)
    
    //when the loop is commented out, everything works normally, but when the
    //loop is uncommented and only iterates once, things look wrong
    
    for (float j = 0.; j < 1.; j++) {
        if(new) {
            //parameterized wave calculation to render multiple waves at once
            float tRad = wrap3(t2/3., 0., 1.)/2.;
            vec2 center = vec2(0.5) + vec2(sin(time), cos(time))*0.2; 
            float dist = distance(stN0, center);
            float distToCircle = abs(dist-tRad);
            float thetaFromCenter = stN0.y - center.y > 0. ? acos((stN0.x-center.x) / dist) : PI2 - acos((stN0.x-center.x) / dist);
            vec2 nearestCirclePoint = vec2(cos(thetaFromCenter), sin(thetaFromCenter))*tRad + center;
            stN2 = distToCircle < thickness ? mix(stN2, nearestCirclePoint, 1. - distToCircle/thickness) : stN2;
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

void main () {
    
    //block for calculating one circular "wave"
    vec2 stN = uvN();
    vec2 center = vec2(0.5);
    float tRad = wrap3(time/3., 0., 1.)/2.;
    float thickness = 0.15;
    float dist = distance(stN, center);
    vec3 c = tRad - thickness < dist && dist < tRad + thickness ? black : white; 
    float distToCircle = abs(dist-tRad);
    float thetaFromCenter = stN.y - 0.5 > 0. ? acos((stN.x-0.5) / dist) : PI2 - acos((stN.x-0.5) / dist);
    vec2 nearestCirclePoint = vec2(cos(thetaFromCenter), sin(thetaFromCenter))*tRad + 0.5;
    vec2 stnW = distToCircle < thickness ? mix(stN, nearestCirclePoint, 1. - distToCircle/thickness) : stN;
    
    vec3 cam = texture2D(channel0, stnW).rgb;
    // c = distance(stN, nearestCirclePoint) < thickness ? black : white;
    
    vec2 dropCoord = drops(stN, time);
    cam = texture2D(channel0, dropCoord).rgb;
    
    gl_FragColor = vec4(cam, 1);
}