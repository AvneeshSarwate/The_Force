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

float rand2(float f) {vec2 n = vec2(f); return (fract(1e4 * sin(17.0 * n.x + n.y * 0.1) * (0.1 + abs(sin(n.y * 13.0 + n.x))))-0.5)*0.002;}

vec4 avgColorBB(vec2 nn, float dist){
    vec4 c1 = texture2D(backbuffer, rotate(nn+vec2(0, dist), nn, rand(1.))      +rand2(1.)).rgba;
    vec4 c2 = texture2D(backbuffer, rotate(nn+vec2(0, -dist), nn, rand(2.))     +rand2(2.)).rgba;
    vec4 c3 = texture2D(backbuffer, rotate(nn+vec2(dist, 0), nn, rand(3.))      +rand2(3.)).rgba;
    vec4 c4 = texture2D(backbuffer, rotate(nn+vec2(-dist, 0), nn, rand(4.))     +rand2(4.)).rgba;
    vec4 c5 = texture2D(backbuffer, rotate(nn+vec2(dist, dist), nn, rand(5.))   +rand2(5.)).rgba;
    vec4 c6 = texture2D(backbuffer, rotate(nn+vec2(-dist, -dist), nn, rand(6.)) +rand2(6.)).rgba;
    vec4 c7 = texture2D(backbuffer, rotate(nn+vec2(dist, -dist), nn, rand(7.))  +rand2(7.)).rgba;
    vec4 c8 = texture2D(backbuffer, rotate(nn+vec2(-dist, dist), nn, rand(8.))  +rand2(8.)).rgba;
    
    return (c1+c2+c3+c4+c5+c6+c7+c8)/8.;
}

vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

//the backbuffer uniform is a texture that stores the last rendered frame
//this example shows how I use it to do feedback/trail effects
void ex3() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y); //flip the input x dimension because the macbook camera doesn't mirror the image
    vec2 hashN = hash(vec3(stN, time)).xy - 0.5;
    vec2 hashN2 = hash(vec3(stN, time*1.1)).xy - 0.5;
    float lineW = 0.002;
    vec3 cam = texture2D(channel0, camPos + hashN*lineW).rgb; 
    vec3 snap = texture2D(channel3, camPos+ hashN2*lineW).rgb;
    vec4 bbN = texture2D(backbuffer, stN);
    vec2 warpN = coordWarp(stN, time/5.).xy;

    vec3 c;
    float feedback; 
    if(colourDistance(cam, snap) < 0.52 - pow(sinN(time*1.3+stN.y*PI), 10.)/2.*0.){
        feedback = avgColorBB(mix(stN, warpN-vec2(0.0, 0.2), 0.03), 0.005).a * 0.97;
    } 
    else{
        feedback = 1.;
    } 
    
    gl_FragColor = vec4(mix(feedback, bbN.a, 0.5));//vec4(c, feedback);
}


void main(){
    ex3();
}