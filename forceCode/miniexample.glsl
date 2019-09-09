void main() {
    vec2 stN = uvN();
    vec2 cent = vec2(sinN(time), cosN(time))*0.5 + 0.25;
    float col = distance(stN, cent) < 0.3 ? 0. : 1.;

    gl_FragColor = vec4(col);
}