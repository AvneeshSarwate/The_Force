void main(){
    vec2 stN = uvN();
    vec3 cam = texture2D(channel0, vec2(1. - stN.x, stN.y)).xyz;
    vec3 camR = texture2D(channel0, stN).xyz;
    vec3 bb = texture2D(backbuffer, stN).xyz;
   
    vec3 c;
    if(mod(randWalk, 20.) >  10.){
        c = cam;
    } else {
        c = camR;
    }
    
    // Rough gamma correction.    
 gl_FragColor = vec4(vec3(c), 1);
    
}