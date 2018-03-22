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

float logi(float x){
    return 1. / (1. + (1./exp(x)));
}


//a function that simulates lenses moving across a screen
//having lots of lenses moving across a screen is similar to 
//the visual effect of looking at an image through rippling water
vec2 coordWarp(vec2 stN){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(time* rand(i+1.) * 1.3 + i), cosN(time * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return warp;
}

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 warp = stN;
    warp = coordWarp(stN);

    vec3 cam = texture2D(channel0, vec2(1.-warp.x, warp.y)).rgb;
    
    //The next two lines show a retexturing trick using the "swirl" procedural texture. 
    //The swirl function just generates a particular sinusodal spinning texture I like.
    //Usually, the second argument of the swirl function is uvN or some
    //scaled transformation of that. However, if you pass in the rg (or rb, gb, etc)
    //of the current camera pixel color, you can re-color your camera input to a
    //texture generally similar to the "swirl" texture. In fact, this technique of 
    //replacing the pixel xy with the camera(xy).rg can be used to take any texture-map
    //and cheaply re-texturize the camera input with it.  
    //The first of the following lines shows retexturing via the "swirl" procedural texture.
    //The next lne shows retexturing via an example video stored in channel1
    
    //cam = swirl(time/10., cam.rg);
    // cam = texture2D(channel1, cam.rg).xyz;

    
    vec3 vid = texture2D(channel1, stN).xyz; //the original video

    vec3 sw = swirl(time/2., stN); //the original "swirl" texture
    
    
    gl_FragColor = vec4(vec3(cam), 1);
}


    