float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

void main () {
    vec2 stN = uvN();
    vec3 snap = texture2D(channel3, vec2(1. -stN.x, stN.y)).rgb;
    vec3 cam = texture2D(channel0, vec2(1. -stN.x, 1.-stN.y)).rgb;
    vec3 tex = texture2D(channel1, vec2(stN.x, 1.-stN.y)).rgb;
    vec3 c;
    if(colourDistance(cam, snap) < .5) c = cam; 
    else c = tex;
	gl_FragColor = vec4(c, 1.0);
}