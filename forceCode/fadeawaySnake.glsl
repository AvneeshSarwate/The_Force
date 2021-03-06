float wrap3(float val, float low, float high){
    float range  = high - low;
    if(val > high){
        float dif = val-high;
        float difMod = mod(dif, range);
        float numWrap = dif/range - difMod;
        if(mod(numWrap, 2.) == 0.){
            return high - difMod;
        } else {
            return low + difMod;
        }
    }
    if(val < low){
        float dif = low-val;
        float difMod = mod(dif, range);
        float numWrap = dif/range - difMod;
        if(mod(numWrap, 2.) == 0.){
            return low + difMod;
        } else {
            return high - difMod;
        }
    }
    return val;
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

//slice the matrix up into columns and translate the individual columns in a moving wave
vec2 columnWaves3(vec2 stN, float numColumns, float time2, float power){
    return vec2(wrap3(stN.x + sin(time2*8.)*0.05 * power, 0., 1.), wrap3(stN.y + cos(quant(stN.x, numColumns)*5.+time2*2.)*0.22 * power, 0., 1.));
}

//slice the matrix up into rows and translate the individual rows in a moving wave
vec2 rowWaves3(vec2 stN, float numColumns, float time2, float power){
    return vec2(wrap3(stN.x + sin(quant(stN.y, numColumns)*5.+time2*2.)*0.22 * power, 0., 1.), wrap3(stN.y + cos(time2*8.)*0.05 * power, 0., 1.));
}


//iteratively apply the rowWave and columnWave functions repeatedly to 
//granularly warp the grid
vec2 rowColWave(vec2 stN, float div, float time2, float power){
    for (int i = 0; i < 10; i++) {
        stN = rowWaves3(stN, div, time2, power);
        stN = columnWaves3(stN, div, time2, power);
    }
    return stN;
}

vec2 drops(vec2 stN2, float t2, float numRipples){
    
    vec2 stN0 = stN2;
    float thickness = 0.05;   
    vec2 v = uvN();
    
    bool new = true; //whether the sanity check ripple or parameterized ripple calculation is used (see comments in block)
    
    //when the loop is commented out, everything works normally, but when the
    //loop is uncommented and only iterates once, things look wrong
    float maxRad = 0.5;
    for (float j = 0.; j < 100.; j++) {
        if(j == numRipples) break;
        if(new) {
            //parameterized wave calculation to render multiple waves at once
            float tRad = mod(t2 + j/numRipples, 1.)*maxRad;
            vec2 center = vec2(0.5) + (hash(vec3(0.5, 1.1, 34.1)*j).xy-0.5)/2.; 
            float dist = distance(stN0, center);
            float distToCircle = abs(dist-tRad);
            float thetaFromCenter = stN0.y - center.y > 0. ? acos((stN0.x-center.x) / dist) : PI2*1. - acos((stN0.x-center.x) / dist);
            vec2 nearestCirclePoint = vec2(cos(thetaFromCenter), sin(thetaFromCenter))*tRad + center;
            stN2 = distToCircle < thickness ? mix(stN2, nearestCirclePoint, (1. - distToCircle/thickness) *(maxRad- tRad)/maxRad) : stN2;
        }
        else {
            //essentially copy pasting the wave calculation in main() as a sanity check
            vec2 stN = uvN();
            vec2 center = vec2(0.5);
            float tRad = wrap3(time/3., 0., 1.)/2.;
            float thickness = 0.15;
            float dist = distance(stN, center);
            vec3 c = tRad - thickness < dist && dist < tRad + thickness ? black : white; 
            float distToCircle = abs(dist-tRad);
            float thetaFromCenter = stN.y - 0.5 > 0. ? acos((stN.x-0.5) / dist) : PI2 - acos((stN.x-0.5) / dist);
            vec2 nearestCirclePoint = vec2(cos(thetaFromCenter), sin(thetaFromCenter))*tRad + 0.5;
            v = distToCircle < thickness ? mix(stN, nearestCirclePoint, 1. - distToCircle/thickness) : stN;
        }
    }
    
    return new ? stN2 : v;
}

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

vec4 avgSamp1(sampler2D tex, vec2 nn, float dist, float d){
    vec4 c1 = texture2D(tex, nn+vec2(0, dist)      +rand2(1., d)).rgba;
    vec4 c2 = texture2D(tex, nn+vec2(0, -dist)     +rand2(2., d)).rgba;
    vec4 c3 = texture2D(tex, nn+vec2(dist, 0)      +rand2(3., d)).rgba;
    vec4 c4 = texture2D(tex, nn+vec2(-dist, 0)     +rand2(4., d)).rgba;
    vec4 c5 = texture2D(tex, nn+vec2(dist, dist)   +rand2(5., d)).rgba;
    vec4 c6 = texture2D(tex, nn+vec2(-dist, -dist) +rand2(6., d)).rgba;
    vec4 c7 = texture2D(tex, nn+vec2(dist, -dist)  +rand2(7., d)).rgba;
    vec4 c8 = texture2D(tex, nn+vec2(-dist, dist)  +rand2(8., d)).rgba;
    
    return (c1+c2+c3+c4+c5+c6+c7+c8)/8.;
}

vec4 avgSamp2(sampler2D tex, vec2 nn, float dist) {
    vec4 av = vec4(0);
    for(float i = 1.; i < 20.; i++){
        vec2 samp = hash(vec3(nn, i)).xy- 0.5;
        av += texture2D(tex, nn+(samp*dist));
    }
    
    // return (c1+c2+c3+c4+c5+c6+c7+c8)/8.;
    return av/(20.*1.);
}

vec3 gridWave(vec2 nn, float t){
    float quantNum = 10.;
   
    float yNoise = snoise(vec2(quant(nn.y+t*0.5, quantNum)+t/5., 53.));
    float quantX = quant(nn.x+t/5. + yNoise, quantNum)*50.;
    vec3 col = snoise(vec2(t*0.1, quantX)) < 0. ? black : white;;
    
    return col;
}

void main () {
    
    //block for calculating one circular "wave"
    vec2 stN = uvN();
    float t = time * 0.3;
    vec2 center = vec2(0.5)+vec2(snoise(vec2(t, 55.)), snoise(vec2(t, 25.)))*0.5;
    
    // stN = distance(center, stN) < 0.2 ? 1.-stN : stN;
   
    float quantNum = 10.;
   
    float yNoise = snoise(vec2(quant(stN.y+time*0.5, quantNum)+time/5., 53.));
    float quantX = quant(stN.x+time/5. + yNoise, quantNum)*50.;
    vec3 col = snoise(vec2(time*0.1, quantX)) < 0. ? black : white;
    
    vec4 bb = texture2D(backbuffer, stN);
    vec4 avgBB = avgColorBB(mix(stN, vec2(0.5), -0.00), 0.001, 0.002);
    // avgBB = avgSamp2(backbuffer, stN, 0.05);
    float lastFeedback = bb.a;
    float decay = 0.002;
    float feedback;
    bool condition =  distance(center, stN) < 0.1;
    
    if(condition){
        feedback = 1.;
    } else {
        feedback = max(lastFeedback - decay, 0.);
    }
    
    col = feedback > 0.5 ? gridWave(stN, time*.09+feedback*2.) : mix(bb, avgBB, 1.).rgb;
    // col = avgSamp1(channel0, stN, 0.01 , 0.005+sinN(time)).rgb;
    // col = avgSamp2(channel0, stN, 0.01+sinN(time)).rgb;
    // col = abs(mod(time*0.2, 1.) - stN.x) < 0.01 ? white : avgBB.rgb;
    
    //make this back to just "col" for orig    
    gl_FragColor = vec4(col, feedback);
}
