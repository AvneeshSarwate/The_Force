void main() {

    vec3 c;
    vec2 stN = uvN();
    if(mouse.z > 0.) {
        vec3 cam = texture2D(channel0, vec2(1.-stN.x, stN.y)).rgb;
        vec3 vid = texture2D(channel5, stN).rgb;
        c = mix(cam, vid, 0.25 + sinN(time)*0.75);
    } else {
        c = texture2D(channel7, stN).rgb;
    }
    
    vec3 c2 = texture2D(channel5, vec2(1.-stN.x, stN.y)).rgb;
    
    gl_FragColor = vec4(c, 1.0);
}