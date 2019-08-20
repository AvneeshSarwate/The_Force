vec3 coordWarp(vec2 stN, float t2, float rad){ 
    vec2 warp = stN;
    
    
    for (float i = 0.0; i < 10.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

void ex1(){
    vec2 stN = uvN();
    float col = 1.;
    float dist = 0.01;
    float rad = 0.8;
    vec3 warpN = coordWarp(stN, time/2., 0.1);
    vec3 warpN2 = coordWarp(stN, time/2., 0.5);
    warpN.xy = mix(stN, warpN.xy, 0.9);
    bool inDot = false;
    for(int i = 0; i < 20; i++){
        float t = time*float(i+1)/170. + sinN(rand(float(i+1))*time/8.)*1.;
        vec2 pt = vec2(sinN(t*2.), cosN(t))*rad + (1.-rad)/2.;
        vec2 warpPt = coordWarp(pt, time, 0.1).xy;
        if(distance(warpN.xy, warpPt) < (dist+5.*dist*sinN(time*1.+float(i)*PI))*(1.+sinN(time+warpN2.x*PI))) {
            col = col * 0.;
            inDot = true;
        }
    }
    
    gl_FragColor = vec4(vec3(col) + mix(0., pow(warpN.z*5., .7)*0., float(inDot)), 1.);
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