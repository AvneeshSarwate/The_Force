void main() {
    vec2 stN = uvN();
    vec3 c = texture2D(channel0, vec2(1.-stN.x, stN.y)).rgb;
    
    if(lastPattern == 0.) c = texture2D(channel1, stN).rgb;
    if(lastPattern == -1.) c = texture2D(channel5, mix(stN, c.rg, 0.2 + sinN(time)*0.6)).rgb;
    vec2 vidCamWarp = mix(c.rg, stN, sinN(time/7.));
    c = swirl(time/5., vidCamWarp);
    c = texture2D(channel0, vidCamWarp).rgb;
    
    gl_FragColor = vec4(c, 1.0);
}