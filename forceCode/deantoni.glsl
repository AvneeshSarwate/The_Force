void main() {
    vec2 stN = uvN();
    vec3 c = texture2D(channel0, vec2(1.-stN.x, stN.y)).rgb;
    
    if(lastPattern == 0.) c = texture2D(channel1, stN).rgb;
    if(lastPattern == -1.) c = texture2D(channel5, mix(stN, c.rg, 0.2 + sinN(time)*0.6)).rgb;
    vec2 vidCamWarp = mix(c.rg, stN, sinN(time/7.));
    c = swirl(time/5., vidCamWarp);
    c = texture2D(channel0, vidCamWarp).rgb;
    
    gl_FragColor = vec4(c, 1.0);
}



// same as above but for vectors, applying the quantization to each element
vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}



void main2() {
    vec2 stN = uvN();
    vec3 c = texture2D(channel0, vec2(1.-stN.x, stN.y)).rgb;
    vec2 warp1, warp2;
    float mix1, mix2;
    

    //generalize this video-based pixel-position remapping technique
    //procedurally generate gradient/texture videos so you can 
    //design your own time-based remappings (e.g, someting like swirl for remapping)
    for(float i = 0.; i < 2.; i++){
        mix2 = 0.8;sinN(time+i)*0.6;
        warp2 = mix(stN, c.rg, mix2);
        c = texture2D(channel5, warp2).rgb;
        mix1 = 0.5; sinN(time/7. +i)*0.5;
        warp1 = mix(c.rg, stN, mix1);
        c = texture2D(channel0, warp1).rgb;
    }
    
    vec3 c2 = texture2D(channel5, vec2(1.-stN.x, stN.y)).rgb;
    
    gl_FragColor = vec4(c, 1.0);
}