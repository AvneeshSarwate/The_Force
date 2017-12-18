
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

/* calculate the average difference between camera and snapshot for the 
hexagon tile enclosing point p */
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

// normalize a sine wave to [0, 1]
float sinN(float t){
   return (sin(t) + 1.) / 2.; 
}

// normalize a cosine wave to [0, 1]
float cosN(float t){
   return (cos(t) + 1.) / 2.; 
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

void main () {

    //the current pixel coordinate 
    vec2 stN = uvN();

    //the current pixel in camera coordinate (this is sometimes transformed)
    vec2 camPos = vec2(stN.x, stN.y);

    //the initial scaling of mouse values (replaced with audio instead)
    vec4 mN = mouse / resolution.xyxy /2.;

    //whether or not "default" drawing parameters are used (based last mouse click location)
    bool useVarying = mN.z < 0.5;
    
    //the two dimensional audio input
    mN = vec4((bands.x+bands.y)/2., (bands.z+bands.w)/2., 0., 0.);

    // the decay factor of the trails
    float decay = useVarying ? 0.795 + clamp(indMap(mN.x, 0.)*1.1, 0., 1.)*0.2 : 0.98;

    // the luminance values of the webcam "shadow" added to the foreground 
    float blockColor = useVarying ? block(20.+ indMap(mN.x, 1.) * 70., 2.+ indMap(mN.y, 0.) *15.) + 0.01 : block(50.+ sinN(time/2.) * 40., 7.+sinN(time/1.5)*10.) + 0.01;
    
    // how much the "shadow" modulates the  foreground 
    float lumBlend = useVarying ? pow(2., scale(indMap(mN.y, 1.), -2., 4.)) : 0.25;

    //the size of the hexagons used to pixelate the foreground 
    float numHex = useVarying ? 30. + indMap(mN.x, 2.) * 90. : 90.;

    // the speed of the foreground animation
    float shadowSpeed = useVarying ? twinGeo(indMap(mN.y, 2.), 5.): 1./5.;
    
    // the center of the camera zoom - its buggy so it's currently always set to the actual frame center, 
    // but i'm keeping the code around to debug it later
    vec2 centCam = useVarying && false ? vec2((1. - sinN(time * sin(time/2000.))) / 2. + 0.2, cosN(time * sin(time/2000.)) / 2.) : vec2(0.5);
    
    //whether or not the zoom is linearly scaled to the input or scaled with the mapping described in the artist statement
    vec2 mouseMap = useVarying ? vec2(scale(indMap(mN.x, 3.), 0.5, 1.), scale(indMap(mN.y, 3.), 0.5, 1.)) : mN.xy; //TODO - allow this > 1?

    // the zoomed coordinates of the camera 
    vec2 zcam = useVarying ? vec2(stN.x * mouseMap.x + (1. -  mouseMap.x)*(centCam.x), stN.y *  mouseMap.y + (1. -  mouseMap.y)*centCam.y) : camPos;
    
    // the color of the current (post zoom) pixel in the snapshot
    vec3 snap = texture2D(channel3, zcam).rgb;  

    //the color of the current (post zoom) pixel in the live webcam input
    vec3 cam = texture2D(channel0, zcam).rgb;  

    //the color of the last drawn frame (used to implement fading trails)
    vec3 bb = texture2D(backbuffer, vec2(stN.x, stN.y)).rgb;


    // the vector that will hold the final color value for this pixel
    vec3 c;

    //how "faded" the current pixel is into the background (used to implement fading trails)
    float lastFeedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a; 

    //the value for how much the current pixel will be "faded" into the background
    float feedback;
    
    // the foreground color 
    vec3 col = diffColor(time * shadowSpeed, stN);

    // how high the avg difference is between camera and snapshot for the current pixel
    float hexDiff = hexDiffAvg(zcam, numHex);

    // how high the difference is between camera and snapshot for the current pixel (not used)
    float pointDiff = colourDistance(cam, snap);
    
    // how high the luminance is in the background texture for the current pixel's bounding hexagon
    float avgLum = hexTexAvg(stN, 30. + indMap(mN.y, 2.) * 200.);

    // add some horizontal scan-line noise to the bacgkround
    avgLum = avgLum > 0.2 ? avgLum-0.3 + rand(vec2(time, quant(stN.y+time/10., 100.)))/1.5 : 0.;

    //convert the float to a vector
    vec3 t1 = vec3(avgLum);
    
    // implement the trailing effectm using the alpha channel to track the state of decay 
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
        if(lastFeedback > 0.5) {
            c = mix(t1, col * pow(blockColor, lumBlend), lastFeedback); 
        } else {
            feedback = 0.;
            c = t1;
        }
    }
    
    gl_FragColor = vec4(vec3(c), feedback);
}
