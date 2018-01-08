//calculate the distance beterrn two colors
// formula found here - https://stackoverflow.com/a/40950076
float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

// quantize and input number [0, 1] to quantLevels levels
float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec3 quant(vec3 num, float quantLevels){
    vec3 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

void main() {
    vec2 stN = uvN();
    float tScale = time / 10.;
    vec2 colorPoint = vec2(sinN(tScale), cosN(tScale));
    vec2 mouseN = mouse.zw / resolution.xy / 2.;
    mouseN = vec2(mouseN.x, 1. - mouseN.y);
    
    vec3 camFrame = texture2D(channel0, vec2(1.-stN.x, stN.y)).xyz;
    vec3 camPoint = texture2D(channel0, vec2(1. - mouseN.x, mouseN.y)).xyz;
    vec3 vid = texture2D(channel1, stN).xyz;
    vec3 camTex = texture2D(channel1, quant(camFrame.zx, 10.)).xyz;
    vec3 c;
    
    if(colourDistance(camFrame, camPoint) < sinN(time/2.)/2. + 0.15 ){
        c = camTex;
    }
    else {
        c = camFrame;
    }
    
    gl_FragColor = vec4(c, 1.0);
}