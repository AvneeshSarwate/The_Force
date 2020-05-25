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

float logisticSigmoid (float x, float a){
  // n.b.: this Logistic Sigmoid has been normalized.

  float epsilon = 0.0001;
  float min_param_a = 0.0 + epsilon;
  float max_param_a = 1.0 - epsilon;
  a = max(min_param_a, min(max_param_a, a));
  a = (1./(1.-a) - 1.);

  float A = 1.0 / (1.0 + exp(0. -((x-0.5)*a*2.0)));
  float B = 1.0 / (1.0 + exp(a));
  float C = 1.0 / (1.0 + exp(0.-a)); 
  float y = (A-B)/(C-B);
  return y;
}

float stepTime(float t, float a){
    return floor(t) + logisticSigmoid(fract(t), a);
}

float snoiseN(vec3 v){ return (snoise(v)+1.)/2.;}
float snoiseN(vec2 v){ return (snoise(v)+1.)/2.;}

vec3 coordWarp(vec2 stN, float t2, float numBalls){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 100.; i++) {
        if(i==numBalls) break;
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

float ballDist(vec2 stN, float t2, float numBalls){ 
    vec2 warp = stN;
    
    float rad = .5;
    float dist = 3.;
    
    for (float i = 0.0; i < 100.; i++) {
        if(i==numBalls) break;
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        dist = min(dist, distance(stN, p));// < 0.02 ? 1. : 0.;
    }
    
    return dist;
}

vec2 rand2(float f, float d) {
    vec2 n = vec2(f*100000.); 
    float x =  (fract(1e4 * sin(17.0 * n.x) * (0.1 + abs(sin(n.y * 13.0 ))))-.5)*d;
    float y =  (fract(1e4 * sin(13.0 * n.x) * (0.1 + abs(sin(n.y * 103.0))))-.5)*d;
    return vec2(x, y);
}

vec3 sinN(vec3 n) {return vec3(sinN(n.x), sinN(n.y), sinN(n.z));}


vec4 avgColorBB(vec2 nn, float dist, float d){
    vec4 c1 = texture2D(backbuffer, nn+vec2(0, dist)      +rand2(10., d)).rgba;
    vec4 c2 = texture2D(backbuffer, nn+vec2(0, -dist)     -rand2(20., d)).rgba;
    vec4 c3 = texture2D(backbuffer, nn+vec2(dist, 0)      +rand2(30., d)).rgba;
    vec4 c4 = texture2D(backbuffer, nn+vec2(-dist, 0)     -rand2(40., d)).rgba;
    vec4 c5 = texture2D(backbuffer, nn+vec2(dist, dist)   +rand2(50., d)).rgba;
    vec4 c6 = texture2D(backbuffer, nn+vec2(-dist, -dist) -rand2(60., d)).rgba;
    vec4 c7 = texture2D(backbuffer, nn+vec2(dist, -dist)  +rand2(70., d)).rgba;
    vec4 c8 = texture2D(backbuffer, nn+vec2(-dist, dist)  -rand2(80., d)).rgba;
    
    return (c1+c2+c3+c4+c5+c6+c7+c8)/8.;
}

void ex1(){
    vec2 stN = uvN(); //function for getting the [0, 1] scaled corrdinate of each pixel
    vec2 nn = uvN();
    float t2 = stepTime(snoiseN(vec2(45., time*0.15)), 0.8); //time is the uniform for global time
    
    vec2 p1 = vec2(sinN(time), cosN(time))*0.3 + 0.5;
    vec2 p2 = vec2(sinN(time*1.3), cosN(time*1.05))*0.3 + 0.2;
    stN = coordWarp(stN, time*0.2, 20.).xy;
    
    float riverdeviation = snoise(vec2(30., time*0.3+nn.y))*0.1;
    
    vec2 bbN = uvN() + vec2(riverdeviation*0.01, +0.01);
    vec4 bb = texture2D(backbuffer, bbN);
    bb = avgColorBB(bbN,  0.001, 0.002);
    
    float d = ballDist(stN, stepTime(time*0.5+t2, 0.9), 4.); max(distance(stN, p1), distance(stN, p2));
    float sharpness = pow(snoiseN(vec2(stN.x*0.3, time*0.3)), 0.2); //sinN(time+stN.x*PI);
    sharpness = sinN(t2*PI+stN.x*PI*2.*snoiseN(vec2(25., time*0.3)));
    // sharpness = pow(snoiseN(vec3(stN, time*0.2)), .2);
    d = logisticSigmoid(pow(d*1.5, 1.5), sharpness);
    
    float riverx = 0.5 + riverdeviation;
    float riverblend = logisticSigmoid(abs(riverx-nn.x)*(9.-sinN(time*5.)*0.), 0.9);
    vec3 rivercolor = vec3(logisticSigmoid(bb.r, .3));
    vec3 col = mix(rivercolor, vec3(pow(d, 1.)), riverblend);
    float riverborderdist = abs(nn.x - riverx); //0.07
    // col = riverborderdist < 0.07 ? red : vec3(riverblend);
    col =  abs(riverborderdist - 0.07) < 0.01 ? mix(white, col, logisticSigmoid(riverborderdist*10., .93)) : col;

    gl_FragColor = vec4(vec3(col), 1.);
}


void main(){
    ex1();
}