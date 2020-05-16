float sigmoid(float x){
    return 1. / (1. + exp(-x));
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

vec2 rand2(float f, float d) {
    vec2 n = vec2(f*100000.); 
    float x =  (fract(1e4 * sin(17.0 * n.x) * (0.1 + abs(sin(n.y * 13.0 ))))-.5)*d;
    float y =  (fract(1e4 * sin(13.0 * n.x) * (0.1 + abs(sin(n.y * 103.0))))-.5)*d;
    return vec2(x, y);
}


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

vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

float snoiseN(float a, float b){
    return (snoise(vec2(a, b))+1.)/2.;
}

bool outOfBounds(vec2 nn){
    return nn.x < 0. || nn.y < 0. || nn.x > 1. || nn.y > 1.;
}


void ex1(){
    vec2 stN = uvN(); //function for getting the [0, 1] scaled corrdinate of each pixel
    vec2 cent =  vec2(0.5);
    
    float t2 = time/2.; //time is the uniform for global time
    float speed = 0.004;
    vec2 dev = snoiseN(time, 4.5) < 0.5 ? vec2(speed, 0) : vec2(0, speed);
    dev = snoiseN(time, 40.4) < 0.5 ? dev : dev*-1.;
    // dev = mix(dev, coordWarp(dev, time).xy, 0.01);
    // dev = rotate(vec2(speed, 0), vec2(0), snoiseN(stepTime(time, 0.9), 3.4)*PI2);
    // dev*=0.;
    vec4 bb = texture2D(backbuffer, stN+dev);
    vec4 bbb = mix(bb, avgColorBB(stN+dev, 0.001, 0.002), 0.05);
    
    float rad = 0.04 * pow(sinN(time), 3.)+0.01;
    float brushEdge = 0.0035;
    float brd = snoiseN(atan(stN.y-0.5, stN.x-0.5)*PI*rad+time, 4.5);
    vec3 penColor = mix(bb.rgb, 1.-bb.rgb, 1.); black;
    vec3 col = distance(stN+brd*brushEdge, cent) < rad ? penColor : bb.rgb;
    col = outOfBounds(stN+dev) ? vec3(mod(stepTime(time, 0.9), 1.)) : col;
    vec3 cam = texture2D(channel0, stN).rgb;
    col.r = bb.b;
    
    // col = vec3(brd);
    //the fragment color variable name (slightly different from shader toy)
    gl_FragColor = vec4(time < 2. ? vec3(time/2.) : col, 1.);
}


void main(){
    ex1();
}