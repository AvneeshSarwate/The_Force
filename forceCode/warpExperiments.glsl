float logi(float x){
    return 1. / (1. + (1./exp(x)));
}

float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

vec3 quant(vec3 num, float quantLevels){
    vec3 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

//a function that simulates lenses moving across a screen
//having lots of lenses moving across a screen is similar to 
//the visual effect of looking at an image through rippling water
vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

void main () {

    //the current pixel coordinate 
    float t2 = time/2.;
    vec2 stN = uvN();
    vec3 warp = coordWarp(stN, t2);
    vec3 warp2 = coordWarp(warp.xy, t2/10.);

    vec3 cam = texture2D(channel0, vec2(1.-warp.x, warp.y)).rgb;
    
    bool inStripe = false;
    vec2 coord = warp2.xy;
    
    
    float dist = distance(quant(mix(coord, stN, logi(sin(t2*5. + cos(t2)*10.) * sin(t2/10.) *1.)-0.35), 50. + sinN(t2/3.+1.)*1000.), vec2(0.5));
    for(float d = 0.05; d < 0.5; d += 0.03){
        if(d < dist && dist < d + 0.015) inStripe = inStripe || true;
        else inStripe = inStripe || false;
    }
    
    vec3 c = !inStripe ? warp : black;
    vec3 bb = texture2D(backbuffer, warp2.xy).rgb;
    // c = quant(c, 2.);

    c = mix(bb, c, 4.2);
    
    
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
    
    
    // float randval = rand(vec2(quant(coord.x+time/10., 10.), quant(coord.y+time/7., 70.)));
    // float randval2 = rand(vec2(quant(coord.x+sin(time)/6., 10.), quant(coord.y+sin(time)/5., 70.)));
    // float randval3 = rand(vec2(quant(time, 5.), quant(coord.x+sin(time/1.)/4., 20.+sinN(time/5.)*51.) + quant(coord.y+cos(time/1.)/4.,  20.+sinN(time/5.)*50.)));
    // float randval4 = rand(vec2(quant(time, 10.), quant(coord.x, 200.) + quant(coord.y, 10.))) > 0.25 + sinN(time)/2. ? 1. : 0.;

    
    vec3 vid = texture2D(channel1, stN).xyz; //the original video

    vec3 sw = swirl(time/2., stN); //the original "swirl" texture
    
    
    gl_FragColor = vec4(vec3(c), 1);
}