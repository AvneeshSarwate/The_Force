void main () {
    vec2 stN = uvN();
    
    vec3 t1 = texture2D(channel0, stN.xy).rgb;
    vec3 t2 = texture2D(channel1, stN.xy).rgb;
    vec3 bb = texture2D(backbuffer, stN.xy).rgb;
    vec3 c;
    
    vec2 center = vec2(0.5, 0.5);
    vec2 xy;
    
    float sinNorm = (sin(time/7.)+1.)/2. + 0.5;
    vec2 segGrid = vec2(floor(stN.x*30.0 * sinNorm), floor(stN.y*30.0 * sinNorm));
    if(mod(segGrid.x, 2.) == mod(segGrid.y, 2.)) xy = rotate(vec2(center.x, center.y), stN.xy, time);
    else xy = rotate(vec2(center.x, center.y), stN.xy, - time);
    
    
    //given that you're close to 60 fps, the * 60 will pretty reliably get you the next sequential "frame index"
    float frameInd = floor(time * 60.);
    if(mod(frameInd, 120.) == 0.) {
        c = t1;
    }
    else if(mod(frameInd, 3.) == 0.) {
        vec3 bbr = texture2D(backbuffer, xy).rgb;
        c = bbr.brg;
        
    }
    else {
        c = bb;
    }
    gl_FragColor = vec4(c, 1);
}