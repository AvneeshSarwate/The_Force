vec2 coordWarp(vec2 stN){
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(time/5. * rand(i) * 1.3 + i), cosN(time/5. * rand(i) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return warp;
}

bool multiBallCondition(vec2 stN, float t2){
    
    float rad = .05;
    bool cond = false;
    
    for (int i = 0; i < 10; i++) {
        float i_f = float(i);
        if(i_f == numNotesOn) break;
        vec2 p = vec2(sinN(t2 * rand(i_f+1.) * 1.3 + i_f), cosN(t2 * rand(i_f+1.) * 1.1 + i_f));
        cond = cond || distance(stN, p) < 0.01 + noteVel[i]/(128. * 4.);
    }
    
    return cond;
}

int noteColorBalls(vec2 stN, float t2){
    
    float rad = .05;
    bool cond = false;
    int ballInd = -1;
    
    for (int i = 0; i < 10; i++) {
        float i_f = float(i);
        if(i_f == numNotesOn) break;
        vec2 p = vec2(sinN(t2 * rand(i_f+1.) * 1.3 + i_f), cosN(t2 * rand(i_f+1.) * 1.1 + i_f));
        if(distance(stN, p) < 0.01 + noteVel[i]/(128. * 4.)) ballInd = i;
    }
    
    return ballInd;
}

vec3 colorWarp(vec3 col, int warpFactor){
    return mod(col*float(warpFactor), 1.);
}


vec3 getArrayElem(vec3[10] arr, int ind){
    for(int i = 0; i <= 10; i++){
        if(i == ind) return arr[i];
    }
    return vec3(0.);
}

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    
    vec3 c;
    float decay = 0.997;
    float feedback;
    
    float lastFeedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a; 
    

    vec3 foreGround = texture2D(channel5, vec2(stN.x, stN.y)).xyz;
    
    vec2 warpStn = coordWarp(stN);

    int ballInd = noteColorBalls(warpStn, time*2.);
    vec4 bb = texture2D(backbuffer, vec2(stN.x, stN.y));
    vec3 ballColor;
    if(ballInd == -1){ 
        ballColor = bb.rgb;
    }else {
        ballColor = getArrayElem(noteColors, ballInd);
        ballColor = colorWarp(foreGround, (ballInd+1)*2);
    }

    bool condition = multiBallCondition(warpStn, time*2.); distance(in1.xy, stN) < .1;
    vec3 trail = ballColor;
    
    
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