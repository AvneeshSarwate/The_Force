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

float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
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



void main() {
    vec2 stN = uvN();
    
    vec3 v0 = texture2D(channel5, stN).rgb;
    vec3 v1 = texture2D(channel6, stN).rgb;
    vec3 v2 = texture2D(channel7, stN).rgb;
    vec3 v3 = texture2D(channel8, stN).rgb;
    // stN = rotate(stN, vec2(0.5), time/5.);
    float numStripes = 10. + sinN(lastNoteOnTime/3.)*10.;
    float numVideos = 4.;
    float stripeMod = mod(floor(quant(stN.y, numStripes)*numStripes), numVideos);
    vec3 c = black;
    if(stripeMod == 0.) c= v0;
    if(stripeMod == 1.) c= v1;
    if(stripeMod == 2.) c= v2;
    if(stripeMod == 3.) c= v3;
    
    
    gl_FragColor = vec4(vec3(c), 1.0);
}