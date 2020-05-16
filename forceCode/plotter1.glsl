float snoiseN(float a, float b){
    return (snoise(vec2(a, b))+1.)/2.;
}

bool outOfBounds(vec2 nn){
    return nn.x < 0. || nn.y < 0. || nn.x > 1. || nn.y > 1.;
}

void ex1(){
    vec2 stN = uvN(); //function for getting the [0, 1] scaled corrdinate of each pixel
    vec2 cent = vec2(0.5);
    
    float t2 = time/2.; //time is the uniform for global time
    float noiseN = snoiseN(time, 4.5);
    float speed = 0.005;
    vec2 dev = noiseN < 0.5 ? vec2(speed, 0) : vec2(0, speed);
    dev = mod(noiseN, 0.5) < 0.25 ? dev : dev*-1.;
    vec4 bb = texture2D(backbuffer, stN+dev);
    
    vec3 col = distance(stN, cent) < 0.014 * pow(sinN(time), 3.)+0.003 ? black : bb.rgb;
    col = outOfBounds(stN+dev) ? white : col;
    
    //the fragment color variable name (slightly different from shader toy)
    gl_FragColor = vec4(col, 1.);
}


void main(){
    ex1();
}