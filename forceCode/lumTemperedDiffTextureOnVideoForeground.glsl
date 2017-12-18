
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

vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}

//float scaleval = 110.;

float hexLumAvg(vec2 p, float numHex){
    vec2 p2 = p * numHex;
    vec2 center = hexCenter2(p2, 1.);
    bool contained = false;
    float avgLum = 0.;
    for(float i = 0.; i < 6.; i++){
        float rad = i * PI / 3.;
        vec2 corner = rotate(vec2(center.x+1., center.y), center, rad);
        for(float j = 0.; j < 3.; j++){
            vec2 samp = mix(center, corner, (0.2*(j+1.))) / numHex;
            vec3 cam = texture2D(channel0, vec2(1.-samp.x, samp.y)).xyz;
            avgLum += lum(cam).x;
        }
    }
    return avgLum / 18.;
}

float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

float hexDiffAvg(vec2 p, float numHex){
    vec2 p2 = p * numHex;
    vec2 center = hexCenter2(p2, 1.);
    bool contained = false;
    float diff = 0.;
    for(float i = 0.; i < 6.; i++){
        float rad = i * PI / 3.;
        vec2 corner = rotate(vec2(center.x+1., center.y), center, rad);
        for(float j = 0.; j < 3.; j++){
            vec2 samp = mix(center, corner, (0.2*(j+1.))) / numHex;
            vec3 cam = texture2D(channel0, vec2(1.-samp.x, samp.y)).xyz;
            vec3 snap = texture2D(channel3, vec2(1.-samp.x, samp.y)).xyz;
            diff += colourDistance(cam, snap);
        }
    }
    return diff / 18.;
}

float sinN(float t){
   return (sin(t) + 1.) / 1.; 
}

float cosN(float t){
   return (cos(t) + 1.) / 1.; 
}

vec3 diffColor(float time2){
    vec2 stN = uvN();
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

vec3 quant(vec3 num, float quantLevels){
    vec3 roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}


float wrap(float val, float low, float high){
    if(val < low) return low + (low-val);
    if(val > high) return high - (val - high);
    return val;
}

float bound(float val, float lower, float upper){
    return max(lower, min(upper, val));
}

bool boxHasColorDiff(vec2 xy, float boxSize, float diffThresh, float diffFrac){
    float boxArea = boxSize * boxSize;
    return true;
}

float block(float numBlocks, float quantLevel) {
    vec2 stN = uvN();
    vec3 cam = texture2D(channel0, vec2(1.-stN.x, stN.y)).xyz; 
    vec3 lumC = lum(cam);
    vec2 res = gl_FragCoord.xy / stN;
    vec2 blockSize = res.xy / numBlocks;
    vec2 blockStart = floor(gl_FragCoord.xy / blockSize) * blockSize / res.xy;
    float blockAvgLuma = 0.;
    vec2 counter = blockStart;
    
    vec2 inc = vec2(1. / (numBlocks *100.));
    for(float i = 0.; i < 10.; i += 1.){
        for(float j = 0.; j < 10.; j += 1.){
            blockAvgLuma += lum(texture2D(channel0, vec2(1.-counter.x, counter.y)).xyz).r;
            counter += inc;
        }
    }
    blockAvgLuma /= 100.;
    
    return quant(blockAvgLuma, quantLevel);
}

void main () {
    vec2 stN = uvN();
    vec3 snap = texture2D(channel3, vec2(1. -stN.x, stN.y)).rgb;  
    vec3 cam = texture2D(channel0, vec2(1. -stN.x, stN.y)).rgb;  
    vec3 bb = texture2D(backbuffer, vec2(stN.x, stN.y)).rgb;
    vec3 t1 = texture2D(channel1, vec2(1. -stN.x, stN.y)).rgb;  
    vec3 col = diffColor(time/5.);

    vec3 c;
    float lastFeedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a; 
    float feedback; 
    float decay = 0.975;
    float blockColor = block(50.+ sinN(time/2.) * 40., 7.+sinN(time/1.5)*10.) + 0.01;
    float lumBlend = 0.25;
    
    if(colourDistance(cam, snap) > 0.6){
        if(lastFeedback < 1.) {
            feedback = 1.;
            c = col * pow(blockColor, lumBlend);
        } else {
            feedback = lastFeedback * decay;
            c = mix(snap, bb, lastFeedback);
        }
    }
    else {
        feedback = lastFeedback * decay;
        if(lastFeedback > 0.5) {
            c = mix(snap, col * pow(blockColor, lumBlend), lastFeedback); //swap col for bb for glitchier effect
        } else {
            c = t1;
        }
    }
    
    gl_FragColor = vec4(c, feedback);
}