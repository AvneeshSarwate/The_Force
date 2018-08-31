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

float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}

vec3 ballTwist(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .15;
    
    for (float i = 0.0; i < 100.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        // warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
        warp = length(p - stN) <= rad ? rotate(warp, p, (1.-length(stN - p)/rad)  * 2.5 * sinN(1.-length(stN - p)/rad * PI)) : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

float wrap3(float val, float low, float high){
    float range  = high - low;
    if(val > high){
        float dif = val-high;
        float difMod = mod(dif, range);
        float numWrap = dif/range - difMod;
        if(mod(numWrap, 2.) == 0.){
            return high - difMod;
        } else {
            return low + difMod;
        }
    }
    if(val < low){
        float dif = low-val;
        float difMod = mod(dif, range);
        float numWrap = dif/range - difMod;
        if(mod(numWrap, 2.) == 0.){
            return low + difMod;
        } else {
            return high - difMod;
        }
    }
    return val;
}

float colormap_red(float x) {
    if (x < 37067.0 / 158860.0) {
        return 0.0;
    } else if (x < 85181.0 / 230350.0) {
        float xx = x - 37067.0 / 158860.0;
        return (780.25 * xx + 319.71) * xx / 255.0;
    } else if (x < (sqrt(3196965649.0) + 83129.0) / 310480.0) {
        return ((1035.33580904442 * x - 82.5380748768798) * x - 52.8985266363332) / 255.0;
    } else if (x < 231408.0 / 362695.0) {
        return (339.41 * x - 33.194) / 255.0;
    } else if (x < 152073.0 / 222340.0) {
        return (1064.8 * x - 496.01) / 255.0;
    } else if (x < 294791.0 / 397780.0) {
        return (397.78 * x - 39.791) / 255.0;
    } else if (x < 491189.0 / 550980.0) {
        return 1.0;
    } else if (x < 1.0) {
        return (5509.8 * x + 597.91) * x / 255.0;
    } else {
        return 1.0;
    }
}

float colormap_green(float x) {
    float xx;
    if (x < 0.0) {
        return 0.0;
    } else if (x < (-sqrt(166317494.0) + 39104.0) / 183830.0) {
        return (-1838.3 * x + 464.36) * x / 255.0;
    } else if (x < 37067.0 / 158860.0) {
        return (-317.72 * x + 74.134) / 255.0;
    } else if (x < (3.0 * sqrt(220297369.0) + 58535.0) / 155240.0) {
        return 0.0;
    } else if (x < 294791.0 / 397780.0) {
        xx = x - (3.0 * sqrt(220297369.0) + 58535.0) / 155240.0;
        return (-1945.0 * xx + 1430.2) * xx / 255.0;
    } else if (x < 491189.0 / 550980.0) {
        return ((-1770.0 * x + 3.92813840044638e3) * x - 1.84017494792245e3) / 255.0;
    } else {
        return 1.0;
    }
}

float colormap_blue(float x) {
    if (x < 0.0) {
        return 0.0;
    } else if (x < 51987.0 / 349730.0) {
        return (458.79 * x) / 255.0;
    } else if (x < 85181.0 / 230350.0) {
        return (109.06 * x + 51.987) / 255.0;
    } else if (x < (sqrt(3196965649.0) + 83129.0) / 310480.0) {
        return (339.41 * x - 33.194) / 255.0;
    } else if (x < (3.0 * sqrt(220297369.0) + 58535.0) / 155240.0) {
        return ((-1552.4 * x + 1170.7) * x - 92.996) / 255.0;
    } else if (x < 27568.0 / 38629.0) {
        return 0.0;
    } else if (x < 81692.0 / 96241.0) {
        return (386.29 * x - 275.68) / 255.0;
    } else if (x <= 1.0) {
        return (1348.7 * x - 1092.6) / 255.0;
    } else {
        return 1.0;
    }
}

vec4 colormap(float x) {
    return vec4(colormap_red(x), colormap_green(x), colormap_blue(x), 1.0);
}

float sigmoid(float x){
    return 1. / (1. + exp(-x));
}

void ex3() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y);

    
    vec2 modN;
    
    modN = stN;
    vec3 vid = texture2D(channel5, stN).rgb;
    vec3 vidSnap = texture2D(channel7, stN).rgb;
    // modN = mix(stN, modN, sigmoid(sin(time+stN.x*20.*PI)*100.));
    vec3 vidnoise = texture2D(channel5, mix(vid.xy, modN, sinN(time))).rgb;
    
    vec4 bb = texture2D(backbuffer, stN);
    float feedback; 
    float dist = colourDistance(vid, vidSnap)/colourDistance(black, white);
    if(dist < .3 + sinN(time)*0.3){
        feedback = bb.a * 0.8;
    } 
    else{
        feedback = 1.;
    } 
    
    // vidnoise = dist > 0.6 ? vid : vidnoise;
    
  
    gl_FragColor = vec4(dist*10.);//vec4(c, feedback);
}

void main(){
    ex3();
}