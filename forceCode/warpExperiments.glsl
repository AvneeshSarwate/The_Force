float logi(float x){
    return 1. / (1. + (1./exp(x)));
}


vec2 coordWarp(vec2 stN){
    vec2 p1 = vec2(sinN(time * 1.3), cosN(time));
    // p1 = vec2(0.25);
    
    vec2 p2 = vec2(sinN(time * 1.3 + 1.), cosN(time * 1.1 + 1.));
    // p2 = vec2(0.75);
    
    
    vec2 warp = stN;
    
    float rad = 1.;
    
    warp = length(p1 - stN) < rad ? mix(stN, p1, length(stN - p1))/rad  : warp;
    
    warp =length(p2 - stN) < rad ?  mix(warp, p2, 1. - length(stN - p2))/rad  : warp;
    
    return warp;
}

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 warp = coordWarp(stN);

    vec3 cam = texture2D(channel0, vec2(1.-warp.x, warp.y)).rgb;
    // cam = swirl(time/3., warp);
    
    
    
    gl_FragColor = vec4(vec3(cam), 1);
}


    