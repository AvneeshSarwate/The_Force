vec3 coordWarp(vec2 stN, float t2, float rad){ 
    vec2 warp = stN;
    
    
    for (float i = 0.0; i < 10.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

float rand2(float f) {vec2 n = vec2(f); return (fract(1e4 * sin(17.0 * n.x + n.y * 0.1) * (0.1 + abs(sin(n.y * 13.0 + n.x))))-0.5)*0.002;}

vec4 avgColorBB(vec2 nn, float dist){
    vec4 c1 = texture2D(backbuffer, nn+vec2(0, dist)      +rand2(1.)).rgba;
    vec4 c2 = texture2D(backbuffer, nn+vec2(0, -dist)     +rand2(2.)).rgba;
    vec4 c3 = texture2D(backbuffer, nn+vec2(dist, 0)      +rand2(3.)).rgba;
    vec4 c4 = texture2D(backbuffer, nn+vec2(-dist, 0)     +rand2(4.)).rgba;
    vec4 c5 = texture2D(backbuffer, nn+vec2(dist, dist)   +rand2(5.)).rgba;
    vec4 c6 = texture2D(backbuffer, nn+vec2(-dist, -dist) +rand2(6.)).rgba;
    vec4 c7 = texture2D(backbuffer, nn+vec2(dist, -dist)  +rand2(7.)).rgba;
    vec4 c8 = texture2D(backbuffer, nn+vec2(-dist, dist)  +rand2(8.)).rgba;
    
    return (c1+c2+c3+c4+c5+c6+c7+c8)/8.;
}

void ex1(){
    vec2 stN = uvN();
    float col = 1.;
    float dist = 0.01;
    float rad = 0.8;
     //texture2D(backbuffer, stN);
    vec3 warpN = coordWarp(stN, time/2., 0.1);
    vec3 warpN2 = coordWarp(stN, time/2., 0.5);
    vec4 bb = avgColorBB(mix(stN, warpN2.xy, 0.05), 0.01);
    warpN.xy = mix(stN, warpN.xy, 0.9);
    bool inDot = false;
    for(int i = 0; i < 20; i++){
        float i_f = float(i)*sin(time/10.)+1.;
        float t = time*i_f/470. + sinN(i_f/20.+time/8.)*4.5;
        vec2 pt = vec2(sinN(t*2.), cosN(t))*rad + (1.-rad)/2.;
        vec2 warpPt = coordWarp(pt, time, 0.1).xy;
        if(distance(warpN.xy, warpPt) < (dist+5.*dist*sinN(time*1.+i_f*PI))*(1.+sinN(time+warpN2.x*PI))) {
            col = col * 0.;
            inDot = true;
        }
    }
    
    gl_FragColor = vec4(pow(mix(col, bb.r, 0.95)+0.01, 1. + sinN(warpN2.z*30.)*0.1));


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