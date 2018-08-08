
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

vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 40.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

// quantize and input number [0, 1] to quantLevels levels
float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec3 quant(vec3 num, float quantLevels){
    vec3 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

//slice the matrix up into columns and translate the individual columns in a moving wave
vec2 columnWaves3(vec2 stN, float numColumns, float time2, float power){
    return vec2(wrap3(stN.x + sin(time2*8.)*0.05 * power, 0., 1.), wrap3(stN.y + cos(quant(stN.x, numColumns)*5.+time2*2.)*0.22 * power, 0., 1.));
}

//slice the matrix up into rows and translate the individual rows in a moving wave
vec2 rowWaves3(vec2 stN, float numColumns, float time2, float power){
    return vec2(wrap3(stN.x + sin(quant(stN.y, numColumns)*5.+time2*2.)*0.22 * power, 0., 1.), wrap3(stN.y + cos(time2*8.)*0.05 * power, 0., 1.));
}


//iteratively apply the rowWave and columnWave functions repeatedly to 
//granularly warp the grid
vec2 rowColWave(vec2 stN, float div, float time2, float power){
    for (int i = 0; i < 10; i++) {
        stN = rowWaves3(stN, div, time2, power);
        stN = columnWaves3(stN, div, time2, power);
    }
    return stN;
}

vec2 drops(vec2 stN2, float t2, float numRipples){
    
    vec2 stN0 = stN2;
    float thickness = 0.05;   
    vec2 v = uvN();
    
    bool new = true; //whether the sanity check ripple or parameterized ripple calculation is used (see comments in block)
    
    //when the loop is commented out, everything works normally, but when the
    //loop is uncommented and only iterates once, things look wrong
    float maxRad = 0.5;
    for (float j = 0.; j < 100.; j++) {
        if(j == numRipples) break;
        if(new) {
            //parameterized wave calculation to render multiple waves at once
            float tRad = mod(t2 + j/numRipples, 1.)*maxRad;
            vec2 center = vec2(0.5) + (hash(vec3(0.5, 1.1, 34.1)*j).xy-0.5)/2.; 
            float dist = distance(stN0, center);
            float distToCircle = abs(dist-tRad);
            float thetaFromCenter = stN0.y - center.y > 0. ? acos((stN0.x-center.x) / dist) : PI2*1. - acos((stN0.x-center.x) / dist);
            vec2 nearestCirclePoint = vec2(cos(thetaFromCenter), sin(thetaFromCenter))*tRad + center;
            stN2 = distToCircle < thickness ? mix(stN2, nearestCirclePoint, (1. - distToCircle/thickness) *(maxRad- tRad)/maxRad) : stN2;
        }
        else {
            //essentially copy pasting the wave calculation in main() as a sanity check
            vec2 stN = uvN();
            vec2 center = vec2(0.5);
            float tRad = wrap3(time/3., 0., 1.)/2.;
            float thickness = 0.15;
            float dist = distance(stN, center);
            vec3 c = tRad - thickness < dist && dist < tRad + thickness ? black : white; 
            float distToCircle = abs(dist-tRad);
            float thetaFromCenter = stN.y - 0.5 > 0. ? acos((stN.x-0.5) / dist) : PI2 - acos((stN.x-0.5) / dist);
            vec2 nearestCirclePoint = vec2(cos(thetaFromCenter), sin(thetaFromCenter))*tRad + 0.5;
            v = distToCircle < thickness ? mix(stN, nearestCirclePoint, 1. - distToCircle/thickness) : stN;
        }
    }
    
    return new ? stN2 : v;
}

float sigmoid(float x){
    return 1. / (1. + exp(-x));
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

void main () {
    
    //block for calculating one circular "wave"
    vec2 stN = uvN();
    
    float tScale = time/10.;
    stN = mix(stN, vec2(0.5), 10.);
    // stN = rotate(stN, vec2(0.5)*stN.x, time*(0.2+stN.y/100.));
    stN = rowColWave(stN, 5., time/4., 1.9);
    vec2 dropCoord = stN; 

    
    // stN = rowColWave(dropCoord, 1000., time, 0.00);
    // stN = stN + (hash(vec3(stN, 5.)).xy-0.5)*0.00;

    float modVal = 0.3 + sinN(time/4.)*0.7;
    gl_FragColor = vec4(mod(distance(dropCoord, uvN()), modVal)/modVal);
}