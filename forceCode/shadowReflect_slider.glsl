// quantize and input number [0, 1] to quantLevels levels
float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels))/quantLevels;
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

vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}


float rand2(float f, float d) {vec2 n = vec2(f, rand(f)); return (fract(1e4 * sin(17.0 * n.x + n.y * 0.1) * (0.1 + abs(sin(n.y * 13.0 + n.x))))-0.5)*d;}

vec4 avgColorBB(vec2 nn, float dist, float d){
    vec4 c1 = texture2D(backbuffer, nn+vec2(0, dist)      +rand2(1., d)).rgba;
    vec4 c2 = texture2D(backbuffer, nn+vec2(0, -dist)     +rand2(2., d)).rgba;
    vec4 c3 = texture2D(backbuffer, nn+vec2(dist, 0)      +rand2(3., d)).rgba;
    vec4 c4 = texture2D(backbuffer, nn+vec2(-dist, 0)     +rand2(4., d)).rgba;
    vec4 c5 = texture2D(backbuffer, nn+vec2(dist, dist)   +rand2(5., d)).rgba;
    vec4 c6 = texture2D(backbuffer, nn+vec2(-dist, -dist) +rand2(6., d)).rgba;
    vec4 c7 = texture2D(backbuffer, nn+vec2(dist, -dist)  +rand2(7., d)).rgba;
    vec4 c8 = texture2D(backbuffer, nn+vec2(-dist, dist)  +rand2(8., d)).rgba;
    
    return (c1+c2+c3+c4+c5+c6+c7+c8)/8.;
}

//slider vals 8/9 control hi/lo intensities - 6/7 open to be mapped
void ex1(){
    vec2 stN = uvN(); //function for getting the [0, 1] scaled corrdinate of each pixel
    stN = quant(stN, 2000.*pow(1.-sliderVals[5], 4.)+10.);
    float t2 = time/2.; //time is the uniform for global time
    
    vec3 warpN = coordWarp(stN, time);
    vec3 col;
    float swing = +sinN(time*PI*4.)*0.3*sliderVals[9]; //make this bass?
    for(float i = 0.; i < 6.; i++){
        float iSwing = i*pow(sinN(t2/4.), 0.3)*(1.+sliderVals[3]*2.);
        vec2 start = rotate(vec2(0.3)-sliderVals[3], vec2(0.5), iSwing);
        vec2 center = mix(start, vec2(0.7), sinN(t2+iSwing+swing));
        vec2 warpCent = coordWarp(center, t2/10.).xy;
        col =(distance(stN, warpCent) < 0.03 + sliderVals[3]*0.1 ? black : white) + col;
    }
    col /= 6.;
    // col.xy = warpN.xy;

    //like laserGlow_slider, make some kind of coordinate noise grain effect the highs?
    
    vec3 hashN = hash(vec3(stN, time))-0.5;
    
    float feedback; 
    float highSwing = pow(sinN(time*PI*4.), 4.)*0.3*sliderVals[8]; //make this treble?
    vec4 bbN = texture2D(backbuffer, stN+hashN.xy*0.1);
    vec4 bbNoise = texture2D(backbuffer, stN);
    vec2 fdbkN = rotate(stN, vec2(0.5), PI/8.*(1.-sliderVals[4]))+hashN.xy*0.1*sliderVals[0];
    vec4 bbWarp = texture2D(backbuffer, mix(fdbkN, vec2(0.5), -highSwing));
    vec2 trailPoint = vec2(0.5); //mix(vec2(0.5), coordWarp(vec2(0.5), time).xy, 2.5);
    vec2 warpMix = mix(mix(stN, warpN.xy, 0.01), trailPoint, 0.01 * sin(time/3.));
    vec4 bb = avgColorBB(warpMix, 0.005, 0.01);
    
    bool condition = col == white;
    
    if(condition){
        feedback = bb.a * 0.99;
    } 
    else{
        feedback = 1.;
    }
    
    vec3 cc = (feedback > 0.5 ? white : black) - feedback;
    cc = vec3(sinN(feedback*(5.+sliderVals[1]*45.)));
    
    cc = mix(cc, bbWarp.rgb, 0.5);
    
    //the fragment color variable name (slightly different from shader toy)
    float c = cc.x > 0.5 ? pow(cc.x, 1.-sliderVals[2]) : pow(cc.x, 1.+sliderVals[2]);
    gl_FragColor = time < 1. ? vec4(0.) : vec4(vec3(c), feedback);
}

void main(){
    ex1();
}