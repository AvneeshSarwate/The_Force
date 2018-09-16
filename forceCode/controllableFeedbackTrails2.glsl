void ex1(){
    vec2 stN = uvN(); //function for getting the [0, 1] scaled corrdinate of each pixel
    
    float t2 = time/2.; //time is the uniform for global time
    
    //the fragment color variable name (slightly different from shader toy)
    gl_FragColor = vec4(vec2(stN.x < 0.5 ? 0. : 1.), mod(t2, 1.), 1.);
}

float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
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

void ex2() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y); //flip the x coordinate to get the camera to show as "mirrored"
    vec4 cam = texture2D(channel0, camPos); //channel0 is the texture of the live camera
    vec4 snap = texture2D(channel3, camPos); //channel4 is the texture of the live camera snapshotted ever 80ms
    vec4 diff = colourDistance(cam.xyz, snap.xyz) > 0.8 ? mod((cam-snap)*10., 1.) : cam ;
    gl_FragColor = diff;
}

void ex3() {
    float quantNum = 10.;
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y);
    vec2 cent = vec2(0.5);
    vec2 quantCent = quant(camPos, quantNum) + 0.5/quantNum;
    
    vec3 cam = texture2D(channel0, camPos).rgb; 
    vec3 flipCam = texture2D(channel0, stN).rgb; 
    vec3 snap = texture2D(channel3, camPos).rgb;
    vec3 vid = texture2D(channel5, stN).rgb;

    float feedback; 
    vec4 bb = texture2D(backbuffer, vec2(stN.x+0.1*sliderVals[9], stN.y));
    float maxColorDist = colourDistance(black, white);
    if(colourDistance(cam, snap)/maxColorDist < sliderVals[2]){
        feedback = bb.a - 0.2 * (1.-sliderVals[0]);
    } 
    else{
        feedback = 1.;
    } 
    
    vec3 cc;
    
    vec3 spinCam = texture2D(channel0, rotate(camPos, cent, feedback*PI * sliderVals[3])).rgb;
    
    vec3 ccHSV = rgb2hsv(spinCam);
    spinCam = hsv2rgb(vec3(ccHSV.r + time, ccHSV.g*sliderVals[4]*10., ccHSV.b));
    
    cc = feedback < 0.1 ? cam : spinCam;
    cc = mix(cc, bb.rgb, sliderVals[1]);
    
    
    
    gl_FragColor = vec4(cc, feedback);//vec4(c, feedback);
}

void main(){
    ex3();
}