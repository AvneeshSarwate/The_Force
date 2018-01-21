vec2 coordWarp(vec2 stN){
    vec2 warp = stN;
    
    float rad = .2;
    
    for (float i = 0.0; i < 100.; i++) {
        vec2 p = vec2(sinN(time/5. * rand(i) * 1.3 + i), cosN(time/5. * rand(i) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return warp;
}

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    
    vec3 c;
    float decay = 0.99;
    float feedback;
    vec3 cam = texture2D(channel0, stN).xyz;
    vec3 camWarp = texture2D(channel0, coordWarp(stN)).xyz;
    float lastFeedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a; 
    bool condition = distance(in1.xy, stN) < .1;
    vec3 trail = length(in2) > 0. ? cam * in2.xyz : white;
    vec3 foreGround = length(in3) > 0. ? camWarp * in3.xzy : black;
    
    // implement the trailing effectm using the alpha channel to track the state of decay 
    if(condition){
        if(lastFeedback < 1.1) {
            feedback = 1.;
            c = trail; 
        } 
        // else {
        //     feedback = lastFeedback * decay;
        //     c = mix(snap, bb, lastFeedback);
        // }
    }
    else {
        feedback = lastFeedback * decay;
        if(lastFeedback > 0.4) {
            c = mix(foreGround, trail, lastFeedback); 
        } else {
            feedback = 0.;
            c = foreGround;
        }
    }
    
    gl_FragColor = vec4(vec3(c), feedback);
}