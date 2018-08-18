vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

// calculates the luminance value of a pixel
// formula found here - https://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color 
vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}

void main () {
    vec2 stN = uvN();
    
    float yShrink = 1.;
    float waveWidth = yShrink / 10. + sinN(randWalk/40.) * sinN(stN.x * time/4.);
    vec2 warpStn = coordWarp(stN, time/3.).xy;
    stN = rotate(stN, vec2(0.5), warpStn.x*4.);
    float y = sin(stN.x * PI2 * 1. + time * (1. * stN.x/100.))/yShrink + 0.5;
    vec3 c = (y - waveWidth/2. < stN.y) && (stN.y < y + waveWidth/2.) ? black : white;

    stN = rotate(stN, vec2(0.5), -warpStn.x*1.);
    
    vec3 cc;
    float decay = 0.97;
    float feedback;
    vec4 bb = texture2D(backbuffer, stN.yx);
    float lastFeedback = bb.a;
    // bool crazyCond = (circleSlice(stN, time/6., time + sinN(time*sinN(time)) *1.8).x - circleSlice(stN, (time-sinN(time))/6., time + sinN(time*sinN(time)) *1.8).x) == 0.;
    bool condition = c == black; 
    vec3 trail = black; // swirl(time/5., trans2) * c.x;
    vec3 foreGround = white;
    
    
    //   implement the trailing effectm using the alpha channel to track the state of decay 
    if(condition){
        if(lastFeedback < 1.1) {
            feedback = 1.;
            cc = trail; 
        } 
        // else {
        //     feedback = lastFeedback * decay;
        //     c = mix(snap, bb, lastFeedback);
        // }
    }
    else {
        feedback = lastFeedback * decay;
        if(lastFeedback > 0.4) {
            cc = mix(foreGround, trail, lastFeedback); 
        } else {
            feedback = 0.;
            cc = foreGround;
        }
    }
    // cc = mix(cc, bb.rgb, 0.5);
    
    
    gl_FragColor = vec4(cc, feedback);
}
