
void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    
    vec3 c;
    float decay = 0.98;
    float feedback;
    float lastFeedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a; 
    bool condition = distance(touch1.xy, stN) < .1;
    vec3 trail = length(touch2) > 0. ? touch2.xyz : white;
    vec3 foreGround = length(touch3) > 0. ? touch3.xzy : black;
    
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
        if(lastFeedback > 0.6) {
            c = mix(foreGround, trail, lastFeedback); 
        } else {
            feedback = 0.;
            c = foreGround;
        }
    }
    
    gl_FragColor = vec4(vec3(c), feedback);
}