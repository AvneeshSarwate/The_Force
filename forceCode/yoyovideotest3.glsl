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

void ex2() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y); //flip the x coordinate to get the camera to show as "mirrored"
    vec4 cam = texture2D(channel0, camPos); //channel0 is the texture of the live camera
    vec4 snap = texture2D(channel3, camPos); //channel4 is the texture of the live camera snapshotted ever 80ms
    vec4 diff = colourDistance(cam.xyz, snap.xyz) > 0.8 ? mod((cam-snap)*10., 1.) : cam ;
    gl_FragColor = diff;
}

vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}

void ex3() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y);
    vec3 cam = texture2D(channel5, camPos).rgb; 
    vec3 snap = texture2D(channel6, camPos).rgb;

    vec3 c;
    float numLines = 150.;
    vec2 nn = uvN();
    vec2 rotN =  texture2D(channel5, vec2(1.-nn.x, nn.y)).rg;
    float gridThickness = 1./numLines * lum(cam).x;
    if(mod(stN.x, 1./numLines) < gridThickness || mod(stN.y, 1./numLines) < gridThickness) c =black;
    else c = white;
    
    
    float feedback; 
    if(colourDistance(cam, snap)/colourDistance(black, white) < .3 + sinN(time)*0.3){
        feedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a * 0.8;
    } 
    else{
        feedback = 1.;
    } 
    
    
    vec3 final  = feedback > 0.4 ? c : cam;
    
    final = colourDistance(cam, black) < 0.1 ? black : final;
    gl_FragColor = vec4(final, feedback);//vec4(c, feedback);
}

void main(){
    ex3();
}