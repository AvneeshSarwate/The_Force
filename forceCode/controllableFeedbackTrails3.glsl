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

float rand2(float f, float d) {vec2 n = vec2(f); return (fract(1e4 * sin(17.0 * n.x + n.y * 0.1) * (0.1 + abs(sin(n.y * 13.0 + n.x))))-0.5)*d;}

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

void ex3() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y);
    vec3 cam = texture2D(channel0, camPos).rgb; 
    vec3 snap = texture2D(channel3, camPos).rgb;
    vec3 vid = texture2D(channel5, stN).rgb;

    float feedback; 
    vec2 bbN = vec2(stN.x+0.1*sliderVals[9], stN.y);
    float d = 0.01 * sliderVals[4];
    vec4 bb =  mix(texture2D(backbuffer, bbN), avgColorBB(bbN, d, d), pow(sliderVals[3], 6.));
    float maxColorDist = colourDistance(black, white);
    if(colourDistance(cam, snap)/maxColorDist < sliderVals[2]){
        feedback = bb.a - 0.2 * (1.-sliderVals[0]);
    } 
    else{
        feedback = 1.;
    } 
    
    vec3 c = vec3(feedback);
    c = mix(c, bb.rgb, sliderVals[1]);
    vec3 col = hsv2rgb(vec3(c.x*sliderVals[3]*4.+time*sliderVals[4]*4. + sliderVals[5], sliderVals[6], sliderVals[7]));
    vec3 cc = mix(c, col, sliderVals[8]);
    bool haveLightShowVideo = false;
    if(haveLightShowVideo && colourDistance(cam, white) < 0.1) cc = vid;
    else if(feedback < 0.001) cc = black;
    gl_FragColor = vec4(cc, feedback);//vec4(c, feedback);
}

void main(){
    ex3();
}