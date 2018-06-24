

// hexagon stuff from here - https://www.redblobgames.com/grids/hexagons/#hex-to-pixel
/*
This set of functions is used to help me implement "hexagonal pixelation".
For each pixel, I compute what hexagon it is a part of, then sample points 
from that hexagonal region, and then calculate some metric over the sampled 
points (such as avg luminance, avg color-distance between camera and snapshot, etc)
*/

/*most of the following functions are translations between different types of 
coordinate systems for describing hexagon tiling in 2D, all described in the 
above link
*/
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


//This function is important - it returns the center of the hexagon of which 
//the pixel p is a member of. 
vec2 hexCenter2(vec2 p, float size){
    return hex_to_pixel(hex_round(pixel_to_hex(p, size)), size);
}
// end of  borrowed hexagon code


// calculates the luminance value of a pixel
// formula found here - https://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color 
vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}

//calculate the distance beterrn two colors
// formula found here - https://stackoverflow.com/a/40950076
float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

/* The function that generates the rotating grid texture. Given a point, it
returns the color for that point. It can be parameterized by time to 
control its speed. The input point can also be transformed at the callsite to 
further distort the texture. */
vec3 diffColor(float time2, vec2 stN){
    stN = rotate(vec2(0.5+sin(time2)*0.5, 0.5+cos(time2)*0.5), stN, sin(time2));
    
    vec2 segGrid = vec2(floor(stN.x*30.0 * sin(time2/7.)), floor(stN.y*30.0 * sin(time2/7.)));

    vec2 xy;
    float noiseVal = rand(stN)*sin(time2/7.) * 0.15;
    if(mod(segGrid.x, 2.) == mod(segGrid.y, 2.)) xy = rotate(vec2(sinN(time2), cosN(time2)), stN.xy, time2 + noiseVal);
    else xy = rotate(vec2(sinN(time2), cosN(time2)), stN.xy, - time2 - noiseVal);
    
    float section = floor(xy.x*30.0 * sin(time2/7.)); 
    float tile = mod(section, 2.);

    float section2 = floor(xy.y*30.0 * cos(time2/7.)); 
    float tile2 = mod(section2, 2.);
    float timeMod = time2 - (1. * floor(time2/1.)); 
    
    return vec3(tile, tile2, timeMod);
}

/* calculate the average luminance of the swirling texture for the 
hexagon tile enclosing point p */
float hexTexAvg(vec2 p, float numHex){
    vec2 p2 = p * numHex;
    vec2 center = hexCenter2(p2, 1.);
    bool contained = false;
    float avgLum = 0.;
    for(float i = 0.; i < 6.; i++){
        float rad = i * PI / 3.;
        vec2 corner = rotate(vec2(center.x+1., center.y), center, rad);
        for(float j = 0.; j < 3.; j++){
            vec2 samp = mix(center, corner, (0.2*(j+1.))) / numHex;
            vec3 tex = diffColor(time / 8., samp);
            avgLum += lum(tex).x;
        }
    }
    return avgLum / 18.;
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

/* bound a number to [low, high] and "wrap" the number back into the range
if it exceeds the range on either side - 
for example wrap(10, 1, 9) -> 8
and wrap (-2, -1, 9) -> 0
*/
float wrap(float val, float low, float high){
    if(val < low) return low + (low-val);
    if(val > high) return high - (val - high);
    return val;
}

// bound a number between the limits
float bound(float val, float lower, float upper){
    return max(lower, min(upper, val));
}

/* calculates the average luminance of the block containing the current pixel.
The size of the rectangular tiling and the quantization of the luminance
are both parameters. 
*/


//val assumed between 0 - 1
float scale(float val, float minv, float maxv){
    float range = maxv - minv;
    return minv + val*range;
}

// implement the mapping scheme described in the artist statement
float indMap(float val, float ind){
    return cosN(val * PI * pow(2., ind));
}

/* constructs a series that produces interesting results for mapping,
 particularly when used in the denominator */ 
float twinGeo(float v, float range){
    if(v > 0.5) return (v-0.5) * 2. * range;
    if(v < 0.5) return 1. / (abs(v-0.5) * 2. * range);
    return 1.;
}

vec2 coordWarp(vec2 stN){
    vec2 warp = stN;
    
    float rad = .2;
    
    for (float i = 0.0; i < 100.; i++) {
        vec2 p = vec2(sinN(time/5. * rand(i) * 1.3 + i), cosN(time/5. * rand(i) * 1.1 + i));
        warp = length(p - stN) <= rad ? mix(warp, p, 1. - length(stN - p)/rad)  : warp;
    }
    
    return warp;
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

bool multiBallCondition(vec2 stN){
    
    float rad = .05;
    bool cond = false;
    
    for (float i = 0.0; i < 10.; i++) {
        if(i == numNotesOn) break;
        vec2 p = vec2(sinN(time * rand(i+1.) * 1.3 + i), cosN(time * rand(i+1.) * 1.1 + i));
        cond = cond || distance(stN, p) < 0.01 + getNoteVel(int(i))/(128. * 4.);
    }
    
    return cond;
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

/* bound a number to [low, high] and "wrap" the number back into the range
if it exceeds the range on either side - 
for example wrap(10, 1, 9) -> 8
and wrap (-2, -1, 9) -> 0
*/
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
vec2 wrap(vec2 val, float low, float high){
    return vec2(wrap3(val.x, low, high), wrap3(val.y, low, high));
}

vec3 wrap(vec3 val, float low, float high){
    return vec3(wrap3(val.x, low, high), wrap3(val.y, low, high), wrap3(val.z, low, high));
}

vec3 snowflakes(vec2 stN, float time){
    return hash(vec3(stN, time));
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

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();
    // // stN = quant(stN, 40. + 100.* sinN(time));
    
    // vec3 c;
    // float decay = 0.997;
    // float feedback;
    
    // float lastFeedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a; 
    

    // float ballInd = noteColorBalls(stN);
    // vec4 bb = texture2D(backbuffer, vec2(stN.x, stN.y));
    // vec3 ballColor;
    // if(ballInd == -1.){ 
    //     ballColor = bb.rgb;
    // }else {
    //     ballColor = getNoteColor(int(ballInd));
    // }

    // bool condition = multiBallCondition(stN); distance(in1.xy, stN) < .1;
    // vec3 trail = ballColor;
    // vec3 foreGround = black;
    
    // // implement the trailing effectm using the alpha channel to track the state of decay 
    // if(condition){
    //     if(lastFeedback < 1.1) { 
    //         feedback = 1.;
    //         c = trail; 
    //         c = wrap(c*(1.+sinN(time)*10.), 0., 1.);
    //     } 
    //     // else {
    //     //     feedback = lastFeedback * decay;
    //     //     c = mix(snap, bb, lastFeedback);
    //     // }
    // }
    // else {
    //     // feedback = lastFeedback * decay;
    //     // if(lastFeedback > 0.4) {
    //     //     c = mix(foreGround, trail, lastFeedback); 
    //     // } else {
    //     //     c = trail;
    //     // }
    //     c = bb.rgb;
    // }
    
    
    gl_FragColor = vec4(snowflakes(quant(coordWarp(stN, lastNoteOnTime + min((time-lastNoteOnTime)*2., 1.)).xy , 50.), 5.), 1);
}