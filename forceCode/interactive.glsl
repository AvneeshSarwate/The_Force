void main2() {
    vec2 stN = uvN();
    vec3 c = texture2D(channel0, vec2(1.-stN.x, stN.y)).rgb;
    
    if(lastPattern == 0.) c = texture2D(channel1, stN).rgb;
    if(lastPattern == -1.) c = texture2D(channel5, mix(stN, c.rg, 0.2 + sinN(time)*0.6)).rgb;
    vec2 vidCamWarp = mix(c.rg, stN, sinN(time/7.));
    c = swirl(time/5., vidCamWarp);
    c = texture2D(channel0, vidCamWarp).rgb;
    
    gl_FragColor = vec4(c, 1.0);
}



// same as above but for vectors, applying the quantization to each element
vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}



vec2 cube_to_axial(vec3 cube){
    float q = cube.x;
    float r = cube.z;
    return vec2(q, r);
}

vec3 axial_to_cube(vec2 hex){
    float x = hex.x;
    float z = hex.y;
    float y = -x-z;
    return vec3(x, y, z);
}

float round(float v){
    return floor(v+0.5);
}

vec3 cube_round(vec3 cube){
    float rx = round(cube.x);
    float ry = round(cube.y);
    float rz = round(cube.z);

    float x_diff = abs(rx - cube.x);
    float y_diff = abs(ry - cube.y);
    float z_diff = abs(rz - cube.z);

    if (x_diff > y_diff && x_diff > z_diff){
        rx = -ry-rz;
    }
    else if (y_diff > z_diff) {
        ry = -rx-rz;
    } else{
        rz = -rx-ry;
    }

    return vec3(rx, ry, rz);
}

vec2 hex_round(vec2 hex){
    return cube_to_axial(cube_round(axial_to_cube(hex))); 
}

vec2 cube_to_oddr(vec3 cube){
      float col = cube.x + (cube.z - mod(cube.z,2.)) / 2.;
      float row = cube.z;
      return vec2(col, row);
}

vec3 oddr_to_cube(vec2 hex){
      float x = hex.x - (hex.x - mod(hex.x,2.)) / 2.;
      float z = hex.y;
      float y = -x-z;
      return vec3(x, y, z);
}

vec2 hex_to_pixel(vec2 hex, float size){
    float x = size * sqrt(3.) * (hex.x + hex.y/2.);
    float y = size * 3./2. * hex.y;
    return vec2(x, y);
}

vec2 pixel_to_hex(vec2 p, float size){
    float x = p.x;
    float y = p.y;
    float q = (x * sqrt(3.)/3. - y / 3.) / size;
    float r = y * 2./3. / size;
    return vec2(q, r);
}

vec2 hexCenter2(vec2 p, float size){
    return hex_to_pixel(hex_round(pixel_to_hex(p, size)), size);
}

float sigmoid(float x){
    return 1. / (1. + exp(-x));
}

vec2 videoLayerWarp(vec2 stN, vec3 c, int quantMode, float quantNum, float t2){
    vec2 warp1, warp2;
    float mix1, mix2;
    

    //generalize this video-based pixel-position remapping technique
    //procedurally generate gradient/texture videos so you can 
    //design your own time-based remappings (e.g, someting like swirl for remapping)

    float quantSize = 1./quantNum;
    float hexMix = .5;
    float scale = 8.;
    
    for(float i = 0.; i < 5.; i++){
        mix2 = sinN(t2+i)*0.4;
        warp2 = mix(stN, quant(c.rg, 10.), mix2);
        if(quantMode == 1) warp2 = mix(warp2, hexCenter2(warp2, quantSize), hexMix);
        if(quantMode == 2) {
            vec2 pole = quant(warp2, quantNum);
            float dist = sigmoid(distance(warp2, pole) * quantNum * scale);
            warp2 = mix(warp2, pole, dist);
        }
        c = texture2D(channel5, warp2).rgb;
        mix1 = sinN(t2/7. +i)*0.5 + 0.5;
        warp1 = mix(c.rg, stN, mix1);
        if(quantMode == 1) warp1 = mix(warp1, hexCenter2(warp1, quantSize), hexMix);
        if(quantMode == 2) {
            vec2 pole = quant(warp1, quantNum);
            float dist = sigmoid(distance(warp1, pole) * quantNum * scale);
            warp2 = mix(warp1, pole,  dist);
        }
        c = texture2D(channel0, vec2(1. - warp1.x, warp1.y)).rgb;
    }
    return warp1;
}

void main() {
    vec2 stN = uvN();
    vec3 c = texture2D(channel0, vec2(1.-stN.x, stN.y)).rgb;
    
    vec2 warp = videoLayerWarp(stN, c, 2, 10., 0.);
    c = texture2D(channel0, vec2(1. - warp.x, warp.y)).rgb;
    vec3 bb = texture2D(backbuffer, stN).rgb;
    c = mix(c, bb, 0.8);
    
    float numPoles = 5.;
    vec2 pole = quant(stN, numPoles);
    float scale = 6.;
    float sigdist = sigmoid(distance(stN, pole) * numPoles * scale);
    float dist = distance(stN, pole) * numPoles;
    vec2 mixPole = mix(stN, pole, dist);
    
    vec3 c2 = texture2D(channel0, mixPole).rgb;
    
    
    gl_FragColor = vec4(vec3(c), 1.0);
}