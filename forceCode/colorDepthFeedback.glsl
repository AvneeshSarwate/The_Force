vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

float rand2(float f, float d) {vec2 n = vec2(f, rand(f)); return (fract(1e4 * sin(13.0 * n.x + n.y * 0.1) * (0.1 + abs(sin(n.y * 13.0 + n.x))))-0.5)*d;}

vec4 avgColorBB(vec2 nn, float dist, float d){
    vec4 c1 = texture2D(backbuffer, nn+vec2(0, dist)      +rand2(1., d)).rgba;
    vec4 c2 = texture2D(backbuffer, nn+vec2(0, -dist)     +rand2(2., d)).rgba;
    vec4 c3 = texture2D(backbuffer, nn+vec2(dist, 0)      +rand2(3., d)).rgba;
    vec4 c4 = texture2D(backbuffer, nn+vec2(-dist, 0)     +rand2(4., d)).rgba;
    vec4 c5 = texture2D(backbuffer, nn+vec2(dist, dist)   +rand2(5., d)).rgba;
    vec4 c6 = texture2D(backbuffer, nn+vec2(-dist, -dist) +rand2(6., d)).rgba;
    vec4 c7 = texture2D(backbuffer, nn+vec2(dist, -dist)  +rand2(7., d)).rgba;
    vec4 c8 = texture2D(backbuffer, nn+vec2(-dist, dist)  +rand2(8., d)).rgba;
    
    return (c1+c2+c3+c4+c5+c6+c7+c8)/8.;
}

void ex1(){
    vec2 stN = uvN(); //function for getting the [0, 1] scaled corrdinate of each pixel
    vec2 warpN = coordWarp(stN, time*0.1).xy;
    
    vec2 mouseN = mouse.xy/2./resolution.xy;
    vec2 circ = vec2(mouseN.x, 1.-mouseN.y);
    float rad = 0.1;
    bool mouseCond = distance(mix(stN, warpN, 0.), circ) < rad;
    
    float t2 = time/2.; //time is the uniform for global time
    vec4 bb = avgColorBB(stN, 0.0007, 0.00);
    vec4 bb2 = avgColorBB(mix(stN, warpN.xy, 0.01), 0.0004, 0.0);
    //scaling perlin noise to 0-1 - http://digitalfreepen.com/2017/06/20/range-perlin-noise.html
    vec2 cent = (vec2(snoise(vec3(0.5, 0.7, t2)), snoise(vec3(0.8, 0.7, t2)))/sqrt(3./4.)+1.)/2.;
    vec2 brushPos = vec2(0.3, 0.7);
    vec2 staticBrush = stN+brushPos-cent;
    vec2 bugBrush = stN-brushPos+cent;
    vec4 img =texture2D(channel5, staticBrush+vec2(sin(t2), cos(t2))*0.1);
    vec4 img2 = texture2D(channel5, mix(stN, rotate(bb2.rg, vec2(0.5), 0.9*time), 0.1));
    vec4 col = distance(cent, warpN) < 0.1 && img.r > bb.r*sinN(time+stN.x) ? img : bb;
    bool drawCond =  distance(cent, warpN) < 0.1;
    // drawCond = mouseCond;
    col = drawCond ? img2 : bb2;
    
    float decay = 0.01;
    float feedback;
    if(drawCond){
        feedback = 1.;
    } else {
        feedback = bb.a - decay;
    }
    
    col.rgb =  mix(black,  col.rgb, pow(feedback, 0.001));
    
    
    
    //the fragment color variable name (slightly different from shader toy)
    gl_FragColor = vec4(col.rgb, feedback);
}

// quantize and input number [0, 1] to quantLevels levels
float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
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
    vec2 warpN = coordWarp(stN, time*0.1).xy;
    
    vec4 bb2 = avgColorBB(mix(stN, warpN.xy, 0.01), 0.004, 0.0);
    vec4 img = texture2D(channel0, stN);
    vec4 img2 = texture2D(channel0, mix(stN, rotate(1.-bb2.rg, vec2(0.5), time), 0.1));
    gl_FragColor = mix(img2, bb2, 0.8);
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
    ex2();
}