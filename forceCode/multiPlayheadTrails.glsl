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


bool multiBallCondition(vec2 stN, float t2){
    
    float rad = .05;
    bool cond = false;
    
    for (int i = 0; i < 10; i++) {
        float i_f = float(i);
        if(i_f == numNotesOn) break;
        vec2 p = vec2(sinN(t2 * rand(i_f+1.) * 1.3 + i_f), cosN(t2 * rand(i_f+1.) * 1.1 + i_f));
        cond = cond || distance(stN, p) < 0.01 + noteVel[i]/(128. * 4.);
    }
    
    return cond;
}

float colormap_red(float x) {
    return ((((1.30858855846896E+03 * x - 2.84649723684787E+03) * x + 1.76048857883363E+03) * x - 3.99775093706324E+02) * x + 2.69759225316811E+01) * x + 2.54587325383574E+02;
}

float colormap_green(float x) {
    return ((((-8.85605750526301E+02 * x + 2.20590941129997E+03) * x - 1.50123293069936E+03) * x + 2.38490009587258E+01) * x - 6.03460495073813E+01) * x + 2.54768707485247E+02;
}

float colormap_blue(float x) {
    if (x < 0.2363454401493073) {
        return (-3.68734834041388E+01 * x - 3.28163398692792E+02) * x + 2.27342862588147E+02;
    } else if (x < 0.7571054399013519) {
        return ((((1.60988309475108E+04 * x - 4.18782706486673E+04) * x + 4.14508040221340E+04) * x - 1.88926043556059E+04) * x + 3.50108270140290E+03) * x - 5.28541997751406E+01;
    } else {
        return 1.68513761929930E+01 * x - 1.06424668227935E+01;
    }
}

vec4 colormap(float x) {
    float r = clamp(colormap_red(x) / 255.0, 0.0, 1.0);
    float g = clamp(colormap_green(x) / 255.0, 0.0, 1.0);
    float b = clamp(colormap_blue(x) / 255.0, 0.0, 1.0);
    return vec4(r, g, b, 1.0);
}
float lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return dot(color, weights);
}

vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

void main() {
    vec2 stN = uvN();
    
    vec3 v0 = texture2D(channel5, stN).rgb;
    vec3 v1 = texture2D(channel6, stN).rgb;
    vec3 v2 = texture2D(channel7, stN).rgb;
    vec3 v3 = texture2D(channel8, stN).rgb;
    // stN = rotate(stN, vec2(0.5), time/5.);
    float numStripes = floor(10. + sinN(time/10.)*1000.);
    float numVideos = 4.;
    float stripeMod = mod(floor(quant(stN.y, numStripes)*numStripes), numVideos);
    stripeMod = round(hash(vec3(quant(stN, 50. + sinN(time)*800.), time)).x*3.);
    vec3 c = black;
    if(stripeMod == 0.) c = v0;
    if(stripeMod == 1.) c = v1;
    if(stripeMod == 2.) c = v2;
    if(stripeMod == 3.) c = v3;
    
    vec2 warpStn = coordWarp(stN, time).xy;
    vec3 cWarp = black;
    if(stripeMod == 0.) cWarp = texture2D(channel5, warpStn).rgb;
    if(stripeMod == 1.) cWarp = texture2D(channel6, warpStn).rgb;;
    if(stripeMod == 2.) cWarp = texture2D(channel7, warpStn).rgb;;
    if(stripeMod == 3.) cWarp = texture2D(channel8, warpStn).rgb;


    vec4 bb = texture2D(backbuffer, stN);    
    vec3 cc;
    float decay = 0.99;
    float feedback;
    // float lastFeedback = texture2D(backbuffer, rotate(stN, vec2(0.5), time/5.)).a;
    float lastFeedback = texture2D(backbuffer, stN).a;
    // bool crazyCond = (circleSlice(stN, time/6., time + sinN(time*sinN(time)) *1.8).x - circleSlice(stN, (time-sinN(time))/6., time + sinN(time*sinN(time)) *1.8).x) == 0.;
    bool condition = colourDistance(v0, v1) > 0.4; multiBallCondition(coordWarp(stN, time/10.).xy, time); 
    vec3 trail = mix(colormap(lum(c)/lum(vec3(1.))).rgb, c, 0.5); // swirl(time/5., trans2) * c.x;
    vec3 foreGround = c;
    
    
    //   implement the trailing effectm using the alpha channel to track the state of decay 
    if(condition){
        if(lastFeedback < 1.1) {
            feedback = 1.;
            cc = trail; 
        } 
        // else {
        //     feedback = lastFeedback * decay;
        //     c = mix(snap, bb, lastFeedback);
        // }
    }
    else {
        feedback = lastFeedback * decay;
        if(lastFeedback > 0.4) {
            cc = mix(foreGround, trail, lastFeedback); 
        } else {
            feedback = 0.;
            cc = foreGround;
        }
    }

    
    
    gl_FragColor = vec4(vec3(cc), feedback);
}