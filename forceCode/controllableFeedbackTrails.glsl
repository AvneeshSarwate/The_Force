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

void ex3() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y);
    vec3 cam = texture2D(channel0, camPos).rgb; 
    vec3 snap = texture2D(channel3, camPos).rgb;

    float feedback; 
    vec4 bb = texture2D(backbuffer, vec2(stN.x+0.1*sliderVals[9], stN.y));
    float maxColorDist = colourDistance(black, white);
    if(colourDistance(cam, snap)/maxColorDist < sliderVals[2]){
        feedback = bb.a - 0.2 * (1.-sliderVals[0]);
    } 
    else{
        feedback = 1.;
    } 
    
    vec3 c = vec3(1.-feedback);
    c = mix(c, bb.rgb, sliderVals[1]);
    vec3 col = hsv2rgb(vec3(c.x*sliderVals[3]*4.+time*sliderVals[4]*4. + sliderVals[5], sliderVals[6], sliderVals[7]));
    vec3 cc = mix(c, col, sliderVals[8]);
    if(feedback < 0.001) cc = white;
    gl_FragColor = vec4(cc, feedback);//vec4(c, feedback);
}

void main(){
    ex3();
}