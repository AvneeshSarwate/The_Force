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

vec3 coordWarp(vec2 stN, float t2){ 
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 40.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
    }
    
    return vec3(warp, distance(warp, stN));
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
    }
    
    return new ? stN2 : v;
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

vec4 colormap(float x) {
    return vec4(colormap_red(x), colormap_green(x), colormap_blue(x), 1.0);
}

float sigmoid(float x){
    return 1. / (1. + exp(-x));
}

float mosh(){
    
    //block for calculating one circular "wave"
    vec2 stN = uvN();
    
    float tScale = time/10.;
    vec2 stN2 = mix(stN, vec2(0.5), 10.);
    // stN = rotate(stN, vec2(0.5)*stN.x, time*(0.2+stN.y/100.));
    vec2 dropCoord = rowColWave(stN2, 5., time/4., 1.9);


    
    // stN = rowColWave(dropCoord, 1000., time, 0.00);
    // stN = stN + (hash(vec3(stN, 5.)).xy-0.5)*0.00;

    float modVal = 0.3 + sinN(time/4.)*0.7;
    float c = mod(distance(dropCoord, uvN()), modVal)/modVal;
    float bb = texture2D(backbuffer, uvN()).r;
    vec2 warpCoord = coordWarp(stN, time/7.4).xy;
    float mixVal = sigmoid((wrap3(warpCoord.x+randWalk/200., 0., 1.)-0.5)*100.);
    float cc = mix(bb, c, mixVal);
    return cc;
}

vec3 rainbowLava () {
    float t2 = time/5. + 1000.;
    
    vec4 mouseN = mouse / vec4(resolution, resolution) / 2.;
    mouseN = vec4(mouseN.x, 1.-mouseN.y, mouseN.z, 1.-mouseN.w);

    vec2 stN = uvN();
    float numCells = 400.;
    vec3 warp = coordWarp(stN, time/2.);
    // vec3 warp2 = coordWarp(stN, time +4.);
    stN = mix(stN, warp.xy, 0.025);
    vec2 hashN = stN + (hash(vec3(stN, t2)).xy + -0.5)/numCells;

    
    vec3 cc;
    float decay = 0.999;
    float decay2 = 0.01;
    float feedback;
    vec4 bb = texture2D(backbuffer, hashN);
    float lastFeedback = bb.a;

    // vec2 multBall = multiBallCondition(stN, t2/2.);
    bool condition = mod(stN.x*numCells, 1.) < sinN(time + stN.x*PI) || mod(stN.y*numCells, 1.) < cosN(time + stN.y*PI); //multBall.x == 1.; 
    condition = distance(quant(hashN, numCells) + vec2(sinN(t2), cosN(t2))/numCells/2. - 1./numCells/4., hashN) < 1./(numCells*10.);

    //   implement the trailing effectm using the alpha channel to track the state of decay 
    if(condition){
        if(lastFeedback < .9) {
            feedback = 1. ;// * multBall.y;
        } else {
            // feedback = lastFeedback * decay;
            feedback = lastFeedback - decay2;
        }
    }
    else {
        // feedback = lastFeedback * decay;
        feedback = lastFeedback - decay2;
    }
    
    vec3 c = vec3(sinN(feedback*10.), sinN(feedback*14.), cosN(feedback*5.));
    
    vec3 col = vec3(feedback);
    
    vec2 cent = vec2(0.5);
    
    col.xy = rotate(col.xy, cent, warp.x*3.);
    col.yz = rotate(col.yz, cent, warp.y*3.);
    col.zx = rotate(col.zx, cent, warp.z*3.);
    col = mix(bb.rgb, col, 0.01);
    
    return col;
}

void ex3() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y);
    vec2 cent = vec2(0.5);
    
    vec3 cam = texture2D(channel0, camPos).rgb;
    vec3 snap = texture2D(channel3, camPos).rgb;
    float diff = colourDistance(cam, snap);

    vec2 modN;
    vec2 twist = ballTwist(stN, time*sliderVals[4]).xy;
    modN = twist;
    modN = vec2(mod(twist.x+time*sliderVals[6], 1.), twist.y);
    vec3 rawVid = texture2D(channel5, stN).rgb;
    vec3 rawSnap = texture2D(channel7, stN).rgb;

    
    vec4 bb = texture2D(backbuffer, stN);
    float feedback; 

    float decay = sliderVals[0]; //sweetspot .98
    bool condition  = colourDistance(rawVid, rawSnap) > 0.1 || colourDistance(cam, snap) > 0.5;
    if(condition){
        feedback = 1.;
        
    } 
    else{
        feedback = bb.a * decay;
        if(feedback < 0.1) feedback = 0.;
    } 
    
    gl_FragColor = vec4((feedback+rawVid*(0.5+sliderVals[1]))*sliderVals[2]*cam, feedback);//vec4(c, feedback);
}

void main(){
    ex3();
}