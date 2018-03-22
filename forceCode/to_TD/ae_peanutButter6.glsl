// normalize a sine wave to [0, 1]
float sinN(float t){
   return (sin(t) + 1.) / 2.; 
}

// normalize a cosine wave to [0, 1]
float cosN(float t){
   return (cos(t) + 1.) / 2.; 
}

vec3 swirl(float time2, vec2 stN){
    stN = rotate(vec2(0.5+sin(time2)*0.5, 0.5+cos(time2)*0.5), stN, sin(time2));
    
    vec2 segGrid = vec2(floor(stN.x*30.0 * sin(time2/7.)), floor(stN.y*30.0 * sin(time2/7.)));

    vec2 xy;
    float noiseVal = rand(stN)*sin(time2/7.) * 0.15;
    if(mod(segGrid.x, 2.) == mod(segGrid.y, 2.)) xy = rotate(vec2(sinN(time2), cosN(time2)), stN.xy, time2 + noiseVal);
    else xy = rotate(vec2(sinN(time2), cosN(time2)), stN.xy, - time2 - noiseVal);
    
    float section = floor(xy.x*30.0 * sin(time2/7.)); 
    float tile = mod(section, 2.);

    float section2 = floor(xy.y*30.0 * cos(time2/7.)); 
    float tile2 = mod(section2, 2.);
    float timeMod = time2 - (1. * floor(time2/1.)); 
    
    return vec3(tile, tile2, timeMod);
}


//calculate the distance beterrn two colors
// formula found here - https://stackoverflow.com/a/40950076
float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

vec2 coordWarp(vec2 stN){
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(time/5. * rand(i) * 1.3 + i), cosN(time/5. * rand(i) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return warp;
}

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

vec3 wrap(vec3 val, float low, float high){
    return vec3(wrap3(val.x, low, high), wrap3(val.y, low, high), wrap3(val.z, low, high));
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

void main () {

    int cue = 3;

    //the current pixel coordinate 
    vec2 stN = uvN();
    
    //mirror screen, taking the "left" side from the behind-cam perspective
    if(cue == 3){
        stN = stN.x > 0.5 ? stN : vec2(1.- stN.x, stN.y);
    }
    
    //the current pixel in camera coordinate (this is sometimes transformed)
    vec2 camPos = vec2(1.- stN.x, stN.y);


    // the decay factor of the trails
    float decay = 0.97;
  
    // the color of the current (post zoom) pixel in the snapshot
    vec3 snap = texture2D(channel3, camPos).rgb;
    vec3 warpSnap = texture2D(channel3, coordWarp(camPos)).rgb;

    //the color of the current (post zoom) pixel in the live webcam input
    vec3 cam = texture2D(channel0, camPos).rgb;  
    vec3 warpCam = texture2D(channel0, coordWarp(camPos)).rgb;  

    //the color of the last drawn frame (used to implement fading trails)
    vec3 bb = texture2D(backbuffer, vec2(stN.x, stN.y)).rgb;


    vec3 negCam = 1. - texture2D(channel0, quant(vec2(1.-stN.x, stN.y), 150.+sinN(time/2.)*50.)).rgb;
    vec3 warpNeg = 1. - texture2D(channel0, quant(coordWarp(vec2(1.-stN.x, stN.y)), 150.+sinN(time/2.)*50.)).rgb;
    
    vec3 coll = wrap(negCam*(1.+sinN(time)*10.), 0., 1.);
    vec3 warpColl = wrap(warpNeg*(1.+sinN(time)*10.), 0., 1.);

    // the vector that will hold the final color value for this pixel
    vec3 c;

    //how "faded" the current pixel is into the background (used to implement fading trails)
    float lastFeedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a; 

    //the value for how much the current pixel will be "faded" into the background
    float feedback;
    // how high the difference is between camera and snapshot for the current pixel (not used)
    float warpDiff = colourDistance(warpCam, warpSnap);
    float pointDiff = colourDistance(cam, snap);
    
    vec3 warpSwirl = swirl(time/10., warpCam.xy);
    
    vec3 trail = coll;
    vec3 foreGround = cam;
    
    float diffThresh = 0.8;
    
    float diffStyle = pointDiff;
    
    if(cue == 1 ){
        diffThresh = 0.9;
        diffStyle = pointDiff;
        decay = 0.93;
        foreGround = cam;
        trail = coll;
    }
    if(cue == 2 ){
        diffThresh = 0.3;
        diffStyle = warpDiff;
        decay = 0.98;
        foreGround = coll;
        trail = warpCam;
    }
    if(cue == 3 ){
        diffThresh = 0.3;
        diffStyle = warpDiff;
        decay = 0.98;
        foreGround = coll;
        trail = warpCam;
    }
    
    // implement the trailing effectm using the alpha channel to track the state of decay 
    if(diffStyle > diffThresh){
        if(lastFeedback < 1.) {
            feedback = 1.;
            c = trail; 
        } 
        // else {
        //     feedback = lastFeedback * decay;
        //     c = mix(snap, bb, lastFeedback);
        // }
    }
    else {
        feedback = lastFeedback * decay;
        if(lastFeedback > 0.8) {
            c = mix(foreGround, trail, lastFeedback); 
        } else {
            feedback = 0.;
            c = foreGround;
        }
    }
    
    gl_FragColor = vec4(vec3(c), feedback);
}