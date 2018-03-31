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

// quantize and input number [0, 1] to quantLevels levels
float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

vec3 quant(vec3 num, float quantLevels){
    vec3 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

/* bound a number to [low, high] and "wrap" the number back into the range
if it exceeds the range on either side - 
for example wrap(10, 1, 9) -> 8
and wrap (-2, -1, 9) -> 0
*/
float wrap(float val, float low, float high){
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

vec2 wrap(vec2 val, float low, float high){
    return vec2(wrap(val.x, low, high), wrap(val.y, low, high));
}

vec3 wrap(vec3 val, float low, float high){
    return vec3(wrap(val.x, low, high), wrap(val.y, low, high), wrap(val.z, low, high));
}

//slice the matrix up into columns and translate the individual columns in a moving wave
vec2 columnWaves3(vec2 stN, float numColumns, float time2, float power){
    return vec2(wrap(stN.x + sin(time2*8.)*0.05 * power, 0., 1.), wrap(stN.y + cos(quant(stN.x, numColumns)*5.+time2*2.)*0.22 * power, 0., 1.));
}

//slice the matrix up into rows and translate the individual rows in a moving wave
vec2 rowWaves3(vec2 stN, float numColumns, float time2, float power){
    return vec2(wrap(stN.x + sin(quant(stN.y, numColumns)*5.+time2*2.)*0.22 * power, 0., 1.), wrap(stN.y + cos(time2*8.)*0.05 * power, 0., 1.));
}


//iteratively apply the rowWave and columnWave functions repeatedly to 
//granularly warp the grid
vec2 rowColWave(vec2 stN, float div, float time2, float power){
    for (int i = 0; i < 5; i++) {
        stN = rowWaves3(stN, div, time2, power);
        stN = columnWaves3(stN, div, time2, power);
    }
    return stN;
}

float getNoteVel(int ind){
    if(ind == 0) return noteVel[0];
    if(ind == 1) return noteVel[1];
    if(ind == 2) return noteVel[2];
    if(ind == 3) return noteVel[3];
    if(ind == 4) return noteVel[4];
    if(ind == 5) return noteVel[5];
    if(ind == 6) return noteVel[6];
    if(ind == 7) return noteVel[7];
    if(ind == 8) return noteVel[8];
    if(ind == 9) return noteVel[9];
}

float noteColorBalls(vec2 stN){
    
    float rad = .05;
    bool cond = false;
    float ballInd = -1.;
    
    for (float i = 0.0; i < 10.; i++) {
        if(i == numNotesOn) break;
        vec2 p = vec2(sinN(time * rand(i+1.) * 1.3 + i), cosN(time * rand(i+1.) * 1.1 + i));
        if(distance(stN, p) < 0.01 + getNoteVel(int(i))/(128. * 4.)) ballInd = i;
    }
    
    return ballInd;
}

vec3 getNoteColor(int ind){
    if(ind == 0) return noteColors[0];
    if(ind == 1) return noteColors[1];
    if(ind == 2) return noteColors[2];
    if(ind == 3) return noteColors[3];
    if(ind == 4) return noteColors[4];
    if(ind == 5) return noteColors[5];
    if(ind == 6) return noteColors[6];
    if(ind == 7) return noteColors[7];
    if(ind == 8) return noteColors[8];
    if(ind == 9) return noteColors[9];
}

float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    vec2 camN = vec2(1.- stN.x, stN.y);
    vec2 warpStn = coordWarp(stN);
    vec2 warpQ = quant(warpStn, 10.);
    
    float t0, t1, t2, t3, t4, rw;
    t0 = time/4.;
    t1 = time/2.;
    t2 = time;
    t3 = time;
    rw =  randWalk/90.; //a random walk value used to parameterize the rotation of the final frame
    t4 = time;
    vec2 deepTileWave = rowColWave(camN * (.2 + sinN(t0)*3.), 1. + sinN(t1) * 20., t2, 0.1 + sinN(t3)/2.);
    vec2 warpTileCoord2 = wrap(rotate(deepTileWave, vec2(0.5), rw)*5., 0., 1.);
    vec3 liquidGrid = texture2D(channel5, deepTileWave).xyz;
    
    
    vec3 c;
    float decay = 0.99;
    float feedback;
    
    float lastFeedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a; 
    vec3 camQ = texture2D(channel0, quant(camN, 140.)).xyz;
    vec3 cam = texture2D(channel0, camN).xyz;
    vec3 snap = texture2D(channel3, camN).xyz;
    vec3 album = texture2D(channel5, camN).xyz;

    vec3 foreGround = texture2D(channel5, mix(stN, quant(camQ.xy, 30.), sinN(time))).xyz;
    
    
    

    int ballInd = noteColorBalls(warpStn, time*2.);
    ballInd = noteColorBalls(stN, time*2.);
    vec4 bb = texture2D(backbuffer, vec2(stN.x, stN.y));
    vec3 ballColor;
    if(ballInd == -1){ 
        ballColor = bb.rgb;
    }else {
        ballColor = getArrayElem(noteColors, ballInd);
        ballColor = wrap(ballColor*(1.+sinN(time)*10.), 0., 1.);
        // ballColor = colorWarp(foreGround, (ballInd+1)*2);
        // ballColor = vec3(1.) - quant(hexAvg(stN, 150., channel5), 10.);
    }
    
    bool condition =  multiBallCondition(stN, time*2.); colourDistance(cam, snap) > 0.2; 
    vec3 trail = ballColor;

    foreGround = album;
    trail = ballColor;
    
    // implement the trailing effectm using the alpha channel to track the state of decay 
    if(condition){
        if(lastFeedback < 1.1) { 
            feedback = 1.;
            c = trail; 
        } 
    }
    else {
        feedback = lastFeedback * decay;
        if(lastFeedback > 0.4) {
            c = mix(foreGround, trail, lastFeedback); 
        } else {
            feedback = 0.;
            c = foreGround;
        }
        c = bb.rgb;
    }
    
    gl_FragColor = vec4(vec3(c), feedback);
}