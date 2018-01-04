


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
    
    float rad = .2;
    
    for (float i = 0.0; i < 100.; i++) {
        vec2 p = vec2(sinN(time/5. * rand(i) * 1.3 + i), cosN(time/5. * rand(i) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return warp;
}

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();

    //the current pixel in camera coordinate (this is sometimes transformed)
    vec2 camPos = vec2(1.- stN.x, stN.y);

    // the decay factor of the trails
    float decay = 0.99;
  
    // the color of the current (post zoom) pixel in the snapshot
    vec3 snap = texture2D(channel3, camPos).rgb;
    vec3 warpSnap = texture2D(channel3, coordWarp(camPos)).rgb;

    //the color of the current (post zoom) pixel in the live webcam input
    vec3 cam = texture2D(channel0, camPos).rgb;  
    vec3 warpCam = texture2D(channel0, coordWarp(camPos)).rgb;  

    //the color of the last drawn frame (used to implement fading trails)
    vec3 bb = texture2D(backbuffer, vec2(stN.x, stN.y)).rgb;


    // the vector that will hold the final color value for this pixel
    vec3 c;

    //how "faded" the current pixel is into the background (used to implement fading trails)
    float lastFeedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a; 

    //the value for how much the current pixel will be "faded" into the background
    float feedback;
    // how high the difference is between camera and snapshot for the current pixel (not used)
    float pointDiff = colourDistance(warpCam, warpSnap);
    
    vec3 warpSwirl = swirl(time/10., warpCam.xy);
    
    vec3 trail = warpCam;
    vec3 foreGround = warpSwirl;
    
    // implement the trailing effectm using the alpha channel to track the state of decay 
    if(pointDiff > .3){
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