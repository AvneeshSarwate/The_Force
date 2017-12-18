float sinN(float v){
    return (v+1.)/2.;
}
void main () {
    vec2 stN = uvN();
    vec3 t1 = texture2D(channel0, stN).rgb;
    vec3 t2 = texture2D(channel1, stN).rgb;
    
    float rad = 0.1;
    vec3 c;
    float d = distance(stN, vec2(sinN(pos.x), sinN(pos.y)));
    if(d < rad) c = mix(t2, t1, 1. - d / rad);
    else c = t2;
    
	gl_FragColor = vec4(c, 1.0);
}