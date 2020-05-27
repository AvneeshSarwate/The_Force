float sigmoid(float x){
    return 1. / (1. + exp(-x));
}

// quantize and input number [0, 1] to quantLevels levels
float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels))/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec3 quant(vec3 num, float quantLevels){
    vec3 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels))/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels))/quantLevels;
}

vec2 randRemap(vec2 stN, float quantNum){
    vec2 quantN = quant(stN, quantNum);
    vec2 quantR = (hash(vec3(quantN, 32)).xy-0.5)*2.;
    vec2 hashN = hash(vec3(quantN, 1)).xy;
    return mod(hashN + (stN - quantN) + vec2(time*0.1, time*0.2)*quantR, 1.);
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

void ex1(){
    vec2 stN = uvN(); //function for getting the [0, 1] scaled corrdinate of each pixel
    stN = mix(stN, randRemap(stN, 20.), 0.5);
    vec3 c1 = mix(hash(vec3(31, 5, 65)), hash(vec3(3, 5, 65)), logisticSigmoid(stN.y, 1.-sinN(time)*0.2-0.002));
    vec3 c2 = hash(vec3(3, 25, 5));
    
   vec3 h1 = rgbToHsluv(c1);
   vec3 h2 = rgbToHsluv(c2);
   
   vec3 cc = hsluvToRgb(mix(h1, h2, logisticSigmoid(stN.x, 0.999)));
  cc = mix(c1, c2, logisticSigmoid(stN.x-0.25, 1.-cosN(time*0.9)*0.2-.002));
    
    //the fragment color variable name (slightly different from shader toy)
    gl_FragColor = vec4(cc, 1.);
}


void main(){
    ex1();
}