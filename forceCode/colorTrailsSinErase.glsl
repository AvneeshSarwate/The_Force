float sinN(float t){
   return (sin(t) + 1.) / 1.; 
}

float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

void main() {
    vec2 stN = uvN();
    vec2 xy = stN;
    vec3 cam = texture2D(channel0, vec2(1. - xy.x, 1. - xy.y)).rgb;
    vec3 t1 = texture2D(channel1, vec2(xy.x, xy.y)).rgb; 
    vec3 bb = texture2D(backbuffer, stN).rgb;
    float frameNum = floor(time * 60.);
    vec3 c;
    if(colourDistance(cam, bb) < .5) c = cam; 
    else c = t1;
    c = mix(c, cam, sinN(time));
     
    gl_FragColor = vec4(c, 1.);
}