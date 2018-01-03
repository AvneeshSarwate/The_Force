void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 mouseN = mouse.xy / resolution.xy;
    vec2 p1 = vec2(sinN(time / 1.3), cosN(time));
    
    vec2 p2 = vec2(sinN(time / 1.3 + 1.), cosN(time * 1.1 + 1.));
    
    vec2 warp = stN;
    
    // warp = mix(stN, p1.xy, 1. / (length(abs(stN.xy - p1.xy)) + 1.1) );
    
    warp = mix(warp, p2.xy, 1. / (length(abs(stN.xy - p2.xy)) + 1.1) );

    vec3 cam = texture2D(channel0, vec2(1.-warp.x, warp.y)).rgb;
    
    
    
    gl_FragColor = vec4(vec3(cam), 1);
}


    