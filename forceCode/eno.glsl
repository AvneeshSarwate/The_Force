void main(){
    vec3 c = texture2D(channel5, uvN()).rgb;
    pattern([10, [2200, 1100]])
    gl_FragColor = vec4(vec3(c), 1.);
}