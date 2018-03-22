float logi(float x){
    return 1. / (1. + (1./exp(x)));
}


//a function that simulates lenses moving across a screen
//having lots of lenses moving across a screen is similar to 
//the visual effect of looking at an image through rippling water
vec2 coordWarp(vec2 stN){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 10.; i++) {
        vec2 p = vec2(sinN(time* rand(i+1.) * 1.3 + i), cosN(time * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, (1. - length(stN - p)/rad) * (0.1 +sinN(time)/2.))  : warp;
    }
    
    return warp;
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

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 warp = stN;
    warp = coordWarp(stN);

    vec3 cam = quant(texture2D(channel0, vec2(1.-warp.x, warp.y)).rgb, 10.);
    
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

    vec3 sw = swirl(time/40., cam.xy); //the original "swirl" texture
    
    
    gl_FragColor = vec4(vec3(sw), 1);
}


    