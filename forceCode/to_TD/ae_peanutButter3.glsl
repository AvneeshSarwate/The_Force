float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec3 quant(vec3 num, float quantLevels){
    vec3 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}

void main(){
    vec2 stN = uvN();
    vec3 cam = texture(channel0, vec2(1. - stN.x, stN.y)).xyz;
    vec3 camR = texture(channel0, stN).xyz;
    vec3 camQ = texture(channel0, quant(vec2(1. - stN.x, stN.y), 75.)).xyz;
    vec3 camRQ = texture(channel0, quant(stN, 75.)).xyz;
    vec3 bb = texture(backbuffer, stN).xyz;
    bool flipped = false;
   
    vec3 c;
    if(mod(randWalk, 20.) >  10.){
        c = cam;
        flipped = false;
    } else {
        c = camR;
        flipped = true;
    }
    
    
    
    vec3 c1 = quant(1. - c, 3.);
    vec3 c2 = quant(1. - lum(c), 10.);
    vec3 c3 = 1. - c;
    
    int cue = 2;
    
    if(cue == 2) {
        if(mod(randWalk + 531., 35.) >  17.){
            c = 1. - c;
        } else {
            c = flipped ? camRQ : camQ;
        }
    }
       
    // Rough gamma correction.    
 gl_FragColor = vec4(c, 1);
    
}