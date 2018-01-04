float logi(float x){
    return 1. / (1. + (1./exp(x)));
}


vec2 coordWarp(vec2 stN){
    // vec2 p1 = vec2(sinN(time * 1.3), cosN(time));
    // // p1 = vec2(0.25);
    // vec2 p2 = vec2(sinN(time * 1.3 + 1.), cosN(time * 1.1 + 1.));
    // // p2 = vec2(0.75);
    // warp = length(p1 - stN) <= rad ? mix(warp, p1, 1. - length(stN - p1)/rad)  : warp;
    // warp = length(p2 - stN) < rad ?  mix(warp, p2, length(stN - p2)/rad)  : warp;
    
    
    vec2 warp = stN;
    
    float rad = .2;
    
    for (float i = 0.0; i < 100.; i++) {
        vec2 p = vec2(sinN(time/10. * rand(i) * 1.3 + i), cosN(time/10. * rand(i) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return warp;
}

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 warp = coordWarp(stN);

    vec3 cam = texture2D(channel0, vec2(1.-warp.x, warp.y)).rgb;

    //This is a new thing - explore it further (using cam.xy instead of stN)
    cam = swirl(time/10., cam.xy);
    
    
    
    gl_FragColor = vec4(vec3(cam), 1);
}