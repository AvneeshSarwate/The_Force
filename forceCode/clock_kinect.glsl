void ex1(){
    vec2 stN = uvN(); //function for getting the [0, 1] scaled corrdinate of each pixel
    
    float t2 = time/2.; //time is the uniform for global time
    
    //the fragment color variable name (slightly different from shader toy)
    vec2 warpN = stN + vec2(snoise(vec3(stN, time)), snoise(vec3(stN, time+4.)))/4.;
    stN = mix(stN, warpN, distance(stN, vec2(0.5))*2.);
    stN = rotate(stN, vec2(0.5), time/1.);
    vec3 col = stN.y < 0.5 && stN.y > 0.1 && stN.x > 0.495 && stN.x < 0.505 ? black : white;
    
    gl_FragColor = vec4(col, 1.);
}

float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

void ex2() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y); //flip the x coordinate to get the camera to show as "mirrored"
    vec4 cam = texture2D(channel0, camPos); //channel0 is the texture of the live camera
    vec4 snap = texture2D(channel3, camPos); //channel4 is the texture of the live camera snapshotted ever 80ms
    vec4 diff = colourDistance(cam.xyz, snap.xyz) > 0.8 ? mod((cam-snap)*10., 1.) : cam ;
    gl_FragColor = diff;
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

/* bound a number to [low, high] and "wrap" the number back into the range
if it exceeds the range on either side - 
for example wrap(10, 1, 9) -> 8
and wrap (-2, -1, 9) -> 0
*/
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
vec2 wrap(vec2 val, float low, float high){
    return vec2(wrap3(val.x, low, high), wrap3(val.y, low, high));
}


//the backbuffer uniform is a texture that stores the last rendered frame
//this example shows how I use it to do feedback/trail effects
void ex3() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y); //flip the input x dimension because the macbook camera doesn't mirror the image
    vec3 cam = texture2D(channel0, camPos).rgb; 
    vec3 snap = texture2D(channel3, camPos).rgb;
    vec2 nn = uvN();
    float centT = time/5.;
    vec2 cent0 = vec2(0.5);
    vec2 cent = vec2(0.5) + vec2(sin(centT), cos(centT))/5.;
    
    float t2 = time/2.; //time is the uniform for global time
    
    //the fragment color variable name (slightly different from shader toy)
    float noiseT = time/2.;
    stN = rotate(stN, cent0, time/10.);
    vec2 warpN = stN + vec2(snoise(vec3(stN, noiseT)), snoise(vec3(stN, noiseT+4.)))/4.; //play with warp amount
    vec2 warpN2 = stN + vec2(snoise(vec3(stN, noiseT/2.)), snoise(vec3(stN, noiseT/2.+4.)))/4.;
    // warpN = mod(warpN, 0.2 + sinN(time/5.5)); wrap(warpN, 0., 1.);
    // warpN2 = mod(warpN2, 0.2 + sinN(time/5.5)); wrap(warpN2, 0., 1.);
    stN = mix(stN, warpN, distance(stN, cent)*2.);
    vec2 stN2 = mix(stN, warpN2, distance(stN, cent)*2.);
    
    float width = 0.001 + 0.001 * pow(distance(nn, cent), 1.)*500.;
    vec3 col = stN.y < 0.5 && stN.y > 0.1 && stN.x > .5-width && stN.x < 0.5+width ? black : white;
    
    
    
    vec3 c;
    vec2 bbN = mix(nn, stN2, distance(nn, vec2(0.5))/(10. + cosN(time/2.3)*1000.) ); //play with warp feedback mix
    vec4 bb = texture2D(backbuffer, bbN);
    vec4 bb0 = texture2D(backbuffer, nn);
    float fb2;
    float feedback; 
    bool condition = distance(uvN(), cent0+sin(time)*0.3) > 0.1;
    if(condition){
        feedback = bb.a * 0.97;
        fb2 = bb0.a * 0.97;
    } 
    else{
        feedback = 1.;
        fb2 = 1.;
    } 
    
    feedback  = mix(feedback, fb2, sinN(time/5.));
    vec3 lowFdbkCol = vec3(feedback); vec3(cosN(feedback * distance(stN, vec2(0.5))*(10.+50.*distance(stN, cent))));
    float cc = feedback < 0.4 ? 0.: sinN(-time*10. + feedback * distance(stN, vec2(0.5))*(10.+50.*distance(stN, cent)));
    
    cc = pow(cc, 1. + 200. * pow(sinN(time/2.), 10.)); //play with pulsed line resolution
    
    gl_FragColor = vec4(vec3(cc), feedback);//vec4(c, feedback);
}


void main(){
    ex3();
}