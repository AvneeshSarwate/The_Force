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

//the backbuffer uniform is a texture that stores the last rendered frame
//this example shows how I use it to do feedback/trail effects
void ex3() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y); //flip the input x dimension because the macbook camera doesn't mirror the image
    vec3 cam = texture2D(channel0, camPos).rgb; 
    vec3 snap = texture2D(channel3, camPos).rgb;
    
    float t2 = time/2.; //time is the uniform for global time
    
    //the fragment color variable name (slightly different from shader toy)
    vec2 warpN = stN + vec2(snoise(vec3(stN, time)), snoise(vec3(stN, time+4.)))/4.;
    stN = mix(stN, warpN, distance(stN, vec2(0.5))*2.);
    stN = rotate(stN, vec2(0.5), time/1.);
    vec3 col = stN.y < 0.5 && stN.y > 0.1 && stN.x > 0.495 && stN.x < 0.505 ? black : white;
    
    vec2 nn = uvN();
    
    vec3 c;
    float feedback; 
    if(col == white){
        feedback = texture2D(backbuffer, mix(nn, stN, distance(nn, vec2(0.5))/100. )).a * 0.97;
    } 
    else{
        feedback = 1.;
    } 
    
    vec3 cc = vec3(sinN(feedback * distance(nn, vec2(0.5))*10.));
    
    gl_FragColor = vec4(cc, feedback);//vec4(c, feedback);
}


void main(){
    ex3();
}