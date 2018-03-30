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

vec3 hexAvg(vec2 p, float numHex, sampler2D tex){
    vec2 p2 = p * numHex;
    vec2 center = hexCenter2(p2, 1.);
    bool contained = false;
    vec3 diff = vec3(0.);
    for(float i = 0.; i < 6.; i++){
        float rad = i * PI / 3.;
        vec2 corner = rotate(vec2(center.x+1., center.y), center, rad);
        for(float j = 0.; j < 3.; j++){
            vec2 samp = mix(center, corner, (0.2*(j+1.))) / numHex;
            vec3 cam = texture2D(tex, vec2(1.-samp.x, samp.y)).xyz;
            diff += cam;
        }
    }
    return diff / 18.;
}

bool inSampleSet(vec2 p, vec2 center){
    float size = 1.;
    bool contained = false;
    for(float i = 0.; i < 6.; i++){
        float rad = i * PI / 3.;
        vec2 corner = rotate(vec2(center.x+size, center.y), center, rad);
        for(float j = 0.; j < 3.; j++){
            vec2 samp = mix(center, corner, (0.2*(j+1.)));
            contained = contained || distance(p, samp) < 0.05;
        }
    }
    return contained;
}

vec2 coordWarp(vec2 stN){
    vec2 warp = stN;
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(time/5. * rand(i) * 1.3 + i), cosN(time/5. * rand(i) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return warp;
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

int noteColorBalls(vec2 stN, float t2){
    
    float rad = .05;
    bool cond = false;
    int ballInd = -1;
    
    for (int i = 0; i < 10; i++) {
        float i_f = float(i);
        if(i_f == numNotesOn) break;
        vec2 p = vec2(sinN(t2 * rand(i_f+1.) * 1.3 + i_f), cosN(t2 * rand(i_f+1.) * 1.1 + i_f));
        if(distance(stN, p) < 0.01 + noteVel[i]/(128. * 4.)) ballInd = i;
    }
    
    return ballInd;
}

vec3 colorWarp(vec3 col, int warpFactor){
    return mod(col*float(warpFactor), 1.);
}


vec3 getArrayElem(vec3[10] arr, int ind){
    for(int i = 0; i <= 10; i++){
        if(i == ind) return arr[i];
    }
    return vec3(0.);
}

vec3 quant(vec3 num, float quantLevels){
    vec3 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    
    vec3 c;
    float decay = 0.997;
    float feedback;
    
    float lastFeedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a; 
    
    vec3 camColor = texture2D(channel0, quant(stN, 140.)).xyz;

    vec3 foreGround = texture2D(channel5, quant(camColor.xy, 3.)).xyz;
    
    vec2 warpStn = quant(coordWarp(stN), 10.);

    int ballInd = noteColorBalls(warpStn, time*2.);
    vec4 bb = texture2D(backbuffer, vec2(stN.x, stN.y));
    vec3 ballColor;
    if(ballInd == -1){ 
        ballColor = bb.rgb;
    }else {
        ballColor = getArrayElem(noteColors, ballInd);
        ballColor = colorWarp(foreGround, (ballInd+1)*2);
        ballColor = vec3(1.) - quant(hexAvg(stN, 150., channel5), 10.);
    }

    bool condition = multiBallCondition(warpStn, time*2.); distance(in1.xy, stN) < .1;
    vec3 trail = ballColor;
    
    
    // implement the trailing effectm using the alpha channel to track the state of decay 
    if(condition){
        if(lastFeedback < 1.1) { 
            feedback = 1.;
            c = trail; 
        } 
        // else {
        //     feedback = lastFeedback * decay;
        //     c = mix(snap, bb, lastFeedback);
        // }
    }
    else {
        feedback = lastFeedback * decay;
        if(lastFeedback > 0.4) {
            c = mix(foreGround, trail, lastFeedback); 
        } else {
            feedback = 0.;
            c = foreGround;
        }
    }
    
    gl_FragColor = vec4(vec3(foreGround), feedback);
}