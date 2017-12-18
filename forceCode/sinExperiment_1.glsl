void main () {
    vec2 stN = uvN();
    
    float mousex = time / 5. + mouse.x / resolution.x + mouse.y / resolution.y;

    stN = rotate(vec2(0.5+sin(mousex)*0.5, 0.5+cos(mousex)*0.5), stN, sin(mousex));
    
    vec2 segGrid = vec2(floor(stN.x*30.0 * sin(mousex/7.)), floor(stN.y*30.0 * sin(mousex/7.)));

    vec2 xy;
    float noiseVal = rand(stN)*sin(mousex/7.) * 0.15;
    if(mod(segGrid.x, 2.) == mod(segGrid.y, 2.)) xy = rotate(vec2(sin(mousex),cos(mousex)), stN.xy, mousex + noiseVal);
    else xy = rotate(vec2(sin(mousex),cos(mousex)), stN.xy, - mousex - noiseVal);
    
    float section = floor(xy.x*30.0 * sin(mousex/7.));
    float tile = mod(section, 2.);

    float section2 = floor(xy.y*30.0 * cos(mousex/7.));
    float tile2 = mod(section2, 2.);
    
    float mousexMod = mousex - (1. * floor(mousex/1.));

    gl_FragColor = vec4(tile, tile2, mousexMod, 1);
}