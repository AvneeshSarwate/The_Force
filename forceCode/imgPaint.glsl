vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

void ex1(){
    vec2 stN = uvN(); //function for getting the [0, 1] scaled corrdinate of each pixel
    vec2 warpN = coordWarp(stN, time).xy;
    
    float t2 = time/2.; //time is the uniform for global time
    vec4 bb = texture2D(backbuffer, stN);
    //scaling perlin noise to 0-1 - http://digitalfreepen.com/2017/06/20/range-perlin-noise.html
    vec2 cent = (vec2(snoise(vec3(0.5, 0.7, t2)), snoise(vec3(0.8, 0.7, t2)))/sqrt(3./4.)+1.)/2.;
    vec2 brushPos = vec2(0.3, 0.7);
    vec2 staticBrush = stN+brushPos-cent;
    vec2 bugBrush = stN-brushPos+cent;
    vec4 img =texture2D(channel5, staticBrush+vec2(sin(time), cos(time))*0.1);
    vec4 col = distance(cent, warpN) < 0.1 ? img : bb;
    
    
    
    //the fragment color variable name (slightly different from shader toy)
    gl_FragColor = col;vec4(vec2(stN.x < 0.5 ? 0. : 1.), mod(t2, 1.), 1.);
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

//the backbuffer uniform is a texture that stores the last rendered frame
//this example shows how I use it to do feedback/trail effects
void ex3() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y); //flip the input x dimension because the macbook camera doesn't mirror the image
    vec3 cam = texture2D(channel0, camPos).rgb; 
    vec3 snap = texture2D(channel3, camPos).rgb;

    vec3 c;
    float feedback; 
    if(colourDistance(cam, snap) < .5){
        feedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a * 0.97;
    } 
    else{
        feedback = 1.;
    } 
    
    gl_FragColor = vec4(feedback);//vec4(c, feedback);
}


void main(){
    ex1();
}