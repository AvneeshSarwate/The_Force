// bitwise stuff from here https://gist.github.com/EliCDavis/f35a9e4afb8e1c9ae94cce8f3c2c9b9a
int OR(int n1, int n2){

    float v1 = float(n1);
    float v2 = float(n2);
    
    int byteVal = 1;
    int result = 0;
    
    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){
            
            bool addOn = mod(v1, 2.0) > 0.0 || mod(v2, 2.0) > 0.0;
            
            if(addOn){
                result += byteVal;
            }
            
            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);
            
            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;  
}

int AND(int n1, int n2){
    
    float v1 = float(n1);
    float v2 = float(n2);
    
    int byteVal = 1;
    int result = 0;
    
    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){
            
            bool addOn = mod(v1, 2.0) > 0.0 && mod(v2, 2.0) > 0.0;
            
            if(addOn){
                result += byteVal;
            }
            
            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);
            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;
}

int NAND(int n1, int n2){
    
    float v1 = float(n1);
    float v2 = float(n2);
    
    int byteVal = 1;
    int result = 0;
    
    for(int i = 0; i < 32; i++){
        bool keepGoing = v1>0.0 || v2 > 0.0;
        if(keepGoing){
            
            bool addOn = mod(v1, 2.0) != mod(v2, 2.0);
            
            if(addOn){
                result += byteVal;
            }
            
            v1 = floor(v1 / 2.0);
            v2 = floor(v2 / 2.0);
            byteVal *= 2;
        } else {
            return result;
        }
    }
    return result;
}

int XOR(int n1, int n2){
    return AND(NAND(n1, n2), OR(n1, n2));
}

int RShift(int num, float shifts){
    return int(floor(float(num) / pow(2.0, shifts)));
}

// hexagon stuff from here - https://www.redblobgames.com/grids/hexagons/#hex-to-pixel
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

//val assumed between 0 - 1
float scale(float val, float minv, float maxv){
    float range = maxv - minv;
    return minv + val*range;
}

float indMap(float val, float ind){
    return cosN(val * PI * pow(2., ind));
}

float twinGeo(float v, float range){
    if(v > 0.5) return (v-0.5) * 2. * range;
    if(v < 0.5) return 1. / (abs(v-0.5) * 2. * range);
    return 1.;
}

int intS(float v){
    return int(v* pow(2., 30.));
}

vec3 v3XOR(vec3 col, vec3 t1){
    return vec3(XOR(intS(col.x), intS(t1.x)), XOR(intS(col.y), intS(t1.y)), XOR(intS(col.z), intS(t1.z))) / pow(2., 30.);
}

void main () {
    vec2 stN = uvN();
     vec2 camPos = vec2(stN.x, stN.y);

    vec4 mN = mouse / resolution.xyxy /2.;
    
    bool useVarying = mN.z < 0.5;

    float decay = useVarying ? 0.795 + clamp(indMap(mN.x, 0.)*1.1, 0., 1.)*0.2 : 0.98;
    float blockColor = useVarying ? block(20.+ indMap(mN.x, 1.) * 70., 2.+ indMap(mN.y, 0.) *15.) + 0.01 : block(50.+ sinN(time/2.) * 40., 7.+sinN(time/1.5)*10.) + 0.01;
    float lumBlend = useVarying ? pow(2., scale(indMap(mN.y, 1.), -2., 4.)) : 0.25;
    float numHex = useVarying ? 30. + indMap(mN.x, 2.) * 90. : 90.;
    float shadowSpeed = useVarying ? twinGeo(indMap(mN.y, 2.), 5.): 1./5.;
    float backZoom = 1.;
    float shadowZoom = 1.;
    
    vec2 cent = useVarying ? vec2(sinN(time * sin(time/2000.)) / 2. + 0.2, cosN(sin((1. + (1.-mN.y) * 5.) * time/2000.)) / 2.) : vec2(0.5);
    vec2 z = useVarying ? vec2(stN.x * mN.x + (1. - mN.x)*cent.x, stN.y * mN.y + (1. - mN.y)*cent.y) : stN;
    
    vec2 centCam = useVarying && false ? vec2((1. - sinN(time * sin(time/2000.))) / 2. + 0.2, cosN(time * sin(time/2000.)) / 2.) : vec2(0.5);
    vec2 mouseMap = useVarying ? vec2(scale(indMap(mN.x, 3.), 0.5, 1.), scale(indMap(mN.y, 3.), 0.5, 1.)) : mN.xy; //TODO - allow this > 1?
    vec2 zcam = useVarying ? vec2(stN.x * mouseMap.x + (1. -  mouseMap.x)*(centCam.x), stN.y *  mouseMap.y + (1. -  mouseMap.y)*centCam.y) : camPos;
    
    vec3 snap = texture2D(channel3, zcam).rgb;  
    vec3 cam = texture2D(channel0, zcam).rgb;  
    vec3 bb = texture2D(backbuffer, vec2(stN.x, stN.y)).rgb;
    vec3 t1 = texture2D(channel1, stN).rgb;
    vec3 t2 = vec3(stN.x < 0.5);
    
    vec3 c;
    float lastFeedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a; 
    float feedback;
    
    vec3 col = diffColor(time * shadowSpeed, stN);
    vec3 col2 = diffColor(time / 8., stN);
    float hexDiff = hexDiffAvg(zcam, numHex);
    float pointDiff = colourDistance(cam, snap);
    
    // CHeck Swaps of layers 
    int t = int(5.);
    vec3 col_ = mix(col, t1, mN.x);
    // vec3 t1_ = mix(t1, v3XOR(lum(col2), t1), indMap(mN.y, 2.));
    float avgLum = hexTexAvg(stN, 30. + indMap(mN.y, 2.) * 200.);
    avgLum = avgLum > 0.2 ? avgLum-0.3 + rand(vec2(time, quant(stN.y+time/10., 100.)))/1.5 : 0.;
    t1 = vec3(avgLum);
    
    // col = v3XOR(col, t1);
    
    if(hexDiff > 0.8){
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
        if(lastFeedback > 0.5) { //if you put this below 1 you might have never-fading shadows 
            c = mix(t1, col * pow(blockColor, lumBlend), lastFeedback); //swap col for bb for glitchier effect
        } else {
            feedback = 0.;
            c = t1;
            //c = vec3(0.);
        }
    }
    
    gl_FragColor = vec4(vec3(c), feedback);
}
