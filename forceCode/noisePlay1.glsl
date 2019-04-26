
vec3 _hash33(vec3 p3)
{
    p3 = fract(p3 * vec3(.1031,.11369,.13787));
    p3 += dot(p3, p3.yxz+19.19);
    return -1.0 + 2.0 * fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

// quantize and input number [0, 1] to quantLevels levels
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

bool inBound(float target, float range, float query){
    return target - range <= query && query <= target + range;
}

// simplex noise from https://www.shadertoy.com/view/4sc3z2
float noise2(vec3 p)
{
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;
    
    vec3 i = floor(p + (p.x + p.y + p.z) * K1);
    vec3 d0 = p - (i - (i.x + i.y + i.z) * K2);
    
    // thx nikita: https://www.shadertoy.com/view/XsX3zB
    vec3 e = step(vec3(0.0), d0 - d0.yzx);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);
    
    vec3 d1 = d0 - (i1 - 1.0 * K2);
    vec3 d2 = d0 - (i2 - 2.0 * K2);
    vec3 d3 = d0 - (1.0 - 3.0 * K2);
    
    vec4 h = max(0.6 - vec4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
    vec4 n = h * h * h * h * vec4(dot(d0, _hash33(i)), dot(d1, _hash33(i + i1)), dot(d2, _hash33(i + i2)), dot(d3, _hash33(i + 1.0)));
    
    return dot(vec4(31.316), n);
}

//the backbuffer uniform is a texture that stores the last rendered frame
//this example shows how I use it to do feedback/trail effects
out vec4 fragColor;

vec3 ballTwist(vec2 stN, float t2, float numBalls){ 
    vec2 warp = stN;
    
    float rad = .35;
    
    for (float i = 0.0; i < 100.; i++) {
        if(i == numBalls) break;
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        // warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
        warp = length(p - stN) <= rad ? rotate(warp, p, (1.-length(stN - p)/rad)  * 5.5 * sinN(1.-length(stN - p)/rad * PI)) : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

float sigmoid(float x){
    return 1. / (1. + exp(-x));
}

void main(){
    
    // vec2 camPos = vec2(1.-stN.x, stN.y); //flip the input x dimension because the macbook camera doesn't mirror the image
    // vec3 cam = texture2D(channel0, camPos).rgb; 
    // vec3 snap = texture2D(channel3, camPos).rgb;

    // vec3 c;
    // float feedback; 
    // if(colourDistance(cam, snap) < .5){
    //     feedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a * 0.97;
    // } 
    // else{
    //     feedback = 1.;
    // } 
    
    // float n1 = noise2(hash(vec3(4, 5, 6)) + time/10. + stN.x)*.75 + 0.5;
    // float n2 = noise2(hash(vec3(4, 5, 6)) + time/9. + stN.x + 0.5)*.75 + 0.5;
    vec2 stN = uvN();
    bool drawLine = false;
    float th = 0.02 + sinN(time+stN.x)/10.;
    float tm = time/50.+10000000.*quant(mod(stN.x+time/9., 1.), 4.)+400.;
    vec3 lineCol = white;
    float topLine = 10.;
    
    for(float i = 1.; i < 10.; i++){
        if(i == 1.) stN = uvN() + vec2(0, sin(tm*+stN.x*100.)/10.);
        float noiseVal = noise2(hash(vec3(4, 5, 6)) + tm/60. * (10.+i/500. * sin(tm*.5+i/30.*PI2)) + stN.x)*.75 + 0.5;
        float t = th * sinN(tm/1.01 + i/30. * PI2);
        bool drawThisLine = inBound(noiseVal, t, stN.y);
        drawLine = drawLine || drawThisLine;
        if(drawThisLine) topLine = i;
        lineCol = white*sinN(tm/1.1+topLine/30.*PI2);
    }
    
    // vec3 col = inBound(n1, 0.01, stN.y) || inBound(n2, 0.01, stN.y) ? white : black;
    vec3 col = drawLine ? lineCol : black;
    vec4 bb = texture(backbuffer, uvN());
    
    float mixVal = pow(sinN(time+topLine/30.*PI2), 0.07);
    col = vec3(pow(mix(col, bb.rgb, mixVal*0.9).x, .95 + sigmoid(sin(time/10.+topLine/30.*PI2)*8.4)*0.05) );
    
    fragColor = vec4(quant(col, 200.), 1);//vec4(c, feedback);
}