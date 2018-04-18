void main() {

    vec3 c = texture2D(channel0, uvN()).rgb;

    if(lastPattern == 0.) c = texture2D(channel1, uvN()).rgb;
    if(lastPattern == 1.) c = texture2D(channel5, uvN()).rgb;
    
    gl_FragColor = vec4(c, 1.0);
}