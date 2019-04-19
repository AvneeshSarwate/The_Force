float logi(float x){
    return 1. / (1. + (1./exp(x)));
}

float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

vec3 quant(vec3 num, float quantLevels){
    vec3 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

//a function that simulates lenses moving across a screen
//having lots of lenses moving across a screen is similar to 
//the visual effect of looking at an image through rippling water
vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

void main () {
    vec2 stN = uvN();

    vec3 cam = texture2D(channel0, vec2(1.-stN.x, stN.y)).rgb;
    vec3 hedberg = texture2D(channel5, mix(stN, cam.xy, bands.y/3.)).rgb;
    
    
    gl_FragColor = vec4(vec3(hedberg), 1);
}