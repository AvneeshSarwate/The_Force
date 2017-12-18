float sinN(float t){
   return (sin(t) + 1.) / 2.; 
}

float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

void main(){
    vec2 stN = uvN();
    vec3 cam = texture2D(channel0, vec2(1. - stN.x, stN.y)).xyz;

    
    float randval = rand(vec2(quant(stN.x+time/10., 10.), quant(stN.y+time/7., 70.)));
    float randval2 = rand(vec2(quant(stN.x+sin(time)/6., 10.), quant(stN.y+sin(time)/5., 70.)));
    float randval3 = rand(vec2(quant(time, 5.), quant(stN.x+sin(time/1.)/4., 20.+sinN(time/5.)*51.) + quant(stN.y+cos(time/1.)/4.,  20.+sinN(time/5.)*50.)));
    float randval4 = rand(vec2(quant(time, 10.), quant(stN.x, 200.) + quant(stN.y, 10.))) > 0.25 + sinN(time)/2. ? 1. : 0.;
    
    vec3 col;
    int scheme = 3;
    if(scheme == 1) {
        if(randval > 0.3 && randval2 > 0.5){
            col = cam;
        } else {
            col = 1. - cam;//vec3(randval);
        }
    }
    if(scheme == 2) {
        if(randval > 0.3 && randval2 > 0.5){
            col = cam;
        } else {
            col = vec3(randval);
        }
    }
    if(scheme == 3) {
        if(randval3 > 0.5){
            col = cam;
        } else {
            col = 1. -vec3(cam);
        }
    }

    
    // Rough gamma correction.    
    gl_FragColor = vec4(vec3(randval4), 1);
    
}