// normalize a sine wave to [0, 1]
float sinN(float t){
   return (sin(t) + 1.) / 2.; 
}

// normalize a cosine wave to [0, 1]
float cosN(float t){
   return (cos(t) + 1.) / 2.; 
}

vec3 swirl(float time2, vec2 stN){
    stN = rotate(vec2(0.5+sin(time2)*0.5, 0.5+cos(time2)*0.5), stN, sin(time2));
    
    vec2 segGrid = vec2(floor(stN.x*30.0 * sin(time2/7.)), floor(stN.y*30.0 * sin(time2/7.)));

    vec2 xy;
    float noiseVal = rand(stN)*sin(time2/7.) * 0.15;
    if(mod(segGrid.x, 2.) == mod(segGrid.y, 2.)) xy = rotate(vec2(sinN(time2), cosN(time2)), stN.xy, time2 + noiseVal);
    else xy = rotate(vec2(sinN(time2), cosN(time2)), stN.xy, - time2 - noiseVal);
    
    float section = floor(xy.x*30.0 * sin(time2/7.)); 
    float tile = mod(section, 2.);

    float section2 = floor(xy.y*30.0 * cos(time2/7.)); 
    float tile2 = mod(section2, 2.);
    float timeMod = time2 - (1. * floor(time2/1.)); 
    
    return vec3(tile, tile2, timeMod);
}

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
    vec3 cam = texture2D(channel0, vec2(1. - stN.x, stN.y)).xyz;
    vec3 camR = texture2D(channel0, stN).xyz;
    vec3 bb = texture2D(backbuffer, stN).xyz;
   
    vec3 c;
    if(mod(randWalk, 20.) >  10.){
        c = cam;
    } else {
        c = camR;
    }
    
    
    
    vec3 c1 = quant(1. - c, 3.);
    vec3 c2 = quant(1. - lum(c), 10.);
    vec3 c3 = 1. - c;
    
    int cue = 2;
    
    if(cue == 2) {
        if(mod(randWalk + 531., 35.) >  17.){
            c = 1. - cam;
        } else {
            c = texture2D(channel0, quant(vec2(1. - stN.x, stN.y), 75.)).xyz;
        }
    }
    
    
    // Rough gamma correction.    
 gl_FragColor = vec4(c, 1);
    
}