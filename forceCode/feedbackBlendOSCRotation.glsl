float sinN(float v){
    return (sin(v)+1.)/2.;
}

float nn(float v){
    return (v+1.)/2.;
}

void main () {
    vec2 stN = uvN();
    vec2 st = uv();
    
    vec3 t1 = texture2D(channel0, stN.xy).rgb; //webcam texture
    vec3 bb = texture2D(backbuffer, stN.xy).rgb;
    vec3 c;
    vec3 tex = t1;
    vec2 points[5];
    
    points[0]=p0.xy; points[1]=p1.xy; points[2]=p2.xy; points[3]=p3.xy; points[4]=p4.xy;
    
    
    // stN = rotate(stN, vec2(0.5, 0.5), time/200.);
    
    vec2 xy = stN;
    
    float timeSpeed = 10.;
    
    // vec2 center = vec2((segGrid.x+0.5)/numDiv, (segGrid.y+0.5)/numDiv);
    
    float timeInd = floor(time*60.);
    
    for(int i = 0; i < 5; i++){
        float sinNorm = sinN(time/(3.+float(i)) + float(i))/2. + 0.1;
        vec2 center = vec2(nn(points[i].x), nn(points[i].y));
        if(distance(stN, center) < sinNorm) {
            if(mod(float(i), 2.) == 0.) xy = rotate(stN, center, time/timeSpeed);
            else xy = rotate(stN, center, - time/timeSpeed);
        } 
        vec3 bbr = texture2D(backbuffer, xy).rgb;
        c = bbr;
        c = mix(c, tex, sinN(time/3. + float(i))/2.);
    }
    
    
    // c = tex;
    gl_FragColor = vec4(c, 1);
}