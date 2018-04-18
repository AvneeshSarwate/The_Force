void main() {

    vec3 c = texture2D(channel5, uvN()).rgb;
    
    gl_FragColor = vec4(c, 1.0);
}