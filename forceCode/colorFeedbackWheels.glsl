float sinN(float v){
    return (sin(v)+1.)/2.;
}

void main () {
    vec2 stN = uvN();
    vec2 st = uv();
    
    vec3 t1 = texture2D(channel0, stN.xy).rgb;
    vec3 t2 = texture2D(channel1, stN.xy).rgb;
    vec3 bb = texture2D(backbuffer, stN.xy).rgb;
    vec3 c;
    
    float sinNorm = sinN(time/7.) + 0.5;
    
    float numDiv = 10. * sinNorm;
    vec2 xy;
    
    vec2 segGrid = vec2(floor(stN.x * numDiv), floor(stN.y* numDiv));
    
    vec2 center = vec2((segGrid.x+0.5)/numDiv, (segGrid.y+0.5)/numDiv);
    
    if(distance(stN, center) < 1./numDiv/2.) {
        if(mod(segGrid.x, 2.) == mod(segGrid.y, 2.)) xy = rotate(stN, center, time/100.);
        else xy = rotate(stN, center, - time/100.);
    }
    else xy = stN;
    
    vec3 bbr = texture2D(backbuffer, xy).rgb;
    c = bbr;
    // c = t2;
    gl_FragColor = vec4(c, 1);
}