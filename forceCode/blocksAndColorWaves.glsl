float sinN(float t){
   return (sin(t) + 1.) / 1.; 
}

vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}

vec3 quant(vec3 num, float quantLevels){
    vec3 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}


float wrap(float val, float low, float high){
    if(val < low) return low + (low-val);
    if(val > high) return high - (val - high);
    return val;
}

void main() {
    vec2 stN = uvN();
    vec2 xy = vec2(wrap(stN.x + sin(quant(stN.x, 10.)*time*8.)*0.05, 0., 1.), wrap(stN.y + cos(stN.y+time*2.)*0.12, 0., 1.));
    vec3 cam = texture2D(channel0, vec2(1.-xy.x, xy.y)).xyz;
    vec3 bb = texture2D(backbuffer, xy).xyz;
    vec2 center = vec2(0.5, 0.5);
    vec3 lumWave = quant(lum(cam), 1. + sinN(time + xy.x*2. + xy.y)*3.);
    vec3 colorWave = quant(cam, sinN(time/2. - distance(xy, center))*3.);
    vec3 colorPowerWave = vec3(pow(lumWave.x, sin(time/2.)), pow(lumWave.y, sin(time)), pow(lumWave.z, sin(time/3.)));
    vec3 colorMultWave = vec3(lumWave.x * sinN(time/2.), lumWave.y * sinN(time), lumWave.z * sinN(time/3.));
    vec3 c = mix(colorWave, lumWave, sin(time));
    
    
    vec3 lumC = lum(cam);
    float numBlocks = sinN(time/7.) * 50.;
    vec2 res = gl_FragCoord.xy / xy;
    vec2 blockSize = res.xy / numBlocks;
    vec2 blockStart = floor(gl_FragCoord.xy / blockSize) * blockSize / res.xy;
    vec3 blockAvgLuma = vec3(0.);
    vec2 counter = blockStart;
    
    vec2 inc = vec2(1. / (numBlocks *100.));
    for(float i = 0.; i < 10.; i += 1.){
        for(float j = 0.; j < 10.; j += 1.){
            blockAvgLuma += lum(texture2D(channel0, vec2(1.-counter.x, counter.y)).xyz);
            counter += inc;
        }
    }
    blockAvgLuma /= 100.;
    
    
    // gl_FragColor = vec4((blockAvgLuma) * colorPowerWave, 1.0);
}