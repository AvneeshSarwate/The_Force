/*
HSLUV-GLSL v4.2
HSLUV is a human-friendly alternative to HSL. ( http://www.hsluv.org )
GLSL port by William Malo ( https://github.com/williammalo )
Put this code in your fragment shader.
*/

vec3 hsluv_intersectLineLine(vec3 line1x, vec3 line1y, vec3 line2x, vec3 line2y) {
    return (line1y - line2y) / (line2x - line1x);
}

vec3 hsluv_distanceFromPole(vec3 pointx,vec3 pointy) {
    return sqrt(pointx*pointx + pointy*pointy);
}

vec3 hsluv_lengthOfRayUntilIntersect(float theta, vec3 x, vec3 y) {
    vec3 len = y / (sin(theta) - x * cos(theta));
    if (len.r < 0.0) {len.r=1000.0;}
    if (len.g < 0.0) {len.g=1000.0;}
    if (len.b < 0.0) {len.b=1000.0;}
    return len;
}

float hsluv_maxSafeChromaForL(float L){
    mat3 m2 = mat3(
         3.2409699419045214  ,-0.96924363628087983 , 0.055630079696993609,
        -1.5373831775700935  , 1.8759675015077207  ,-0.20397695888897657 ,
        -0.49861076029300328 , 0.041555057407175613, 1.0569715142428786  
    );
    float sub0 = L + 16.0;
    float sub1 = sub0 * sub0 * sub0 * .000000641;
    float sub2 = sub1 > 0.0088564516790356308 ? sub1 : L / 903.2962962962963;

    vec3 top1   = (284517.0 * m2[0] - 94839.0  * m2[2]) * sub2;
    vec3 bottom = (632260.0 * m2[2] - 126452.0 * m2[1]) * sub2;
    vec3 top2   = (838422.0 * m2[2] + 769860.0 * m2[1] + 731718.0 * m2[0]) * L * sub2;

    vec3 bounds0x = top1 / bottom;
    vec3 bounds0y = top2 / bottom;

    vec3 bounds1x =              top1 / (bottom+126452.0);
    vec3 bounds1y = (top2-769860.0*L) / (bottom+126452.0);

    vec3 xs0 = hsluv_intersectLineLine(bounds0x, bounds0y, -1.0/bounds0x, vec3(0.0) );
    vec3 xs1 = hsluv_intersectLineLine(bounds1x, bounds1y, -1.0/bounds1x, vec3(0.0) );

    vec3 lengths0 = hsluv_distanceFromPole( xs0, bounds0y + xs0 * bounds0x );
    vec3 lengths1 = hsluv_distanceFromPole( xs1, bounds1y + xs1 * bounds1x );

    return  min(lengths0.r,
            min(lengths1.r,
            min(lengths0.g,
            min(lengths1.g,
            min(lengths0.b,
                lengths1.b)))));
}

float hsluv_maxChromaForLH(float L, float H) {

    float hrad = radians(H);

    mat3 m2 = mat3(
         3.2409699419045214  ,-0.96924363628087983 , 0.055630079696993609,
        -1.5373831775700935  , 1.8759675015077207  ,-0.20397695888897657 ,
        -0.49861076029300328 , 0.041555057407175613, 1.0569715142428786  
    );
    float sub1 = pow(L + 16.0, 3.0) / 1560896.0;
    float sub2 = sub1 > 0.0088564516790356308 ? sub1 : L / 903.2962962962963;

    vec3 top1   = (284517.0 * m2[0] - 94839.0  * m2[2]) * sub2;
    vec3 bottom = (632260.0 * m2[2] - 126452.0 * m2[1]) * sub2;
    vec3 top2   = (838422.0 * m2[2] + 769860.0 * m2[1] + 731718.0 * m2[0]) * L * sub2;

    vec3 bound0x = top1 / bottom;
    vec3 bound0y = top2 / bottom;

    vec3 bound1x =              top1 / (bottom+126452.0);
    vec3 bound1y = (top2-769860.0*L) / (bottom+126452.0);

    vec3 lengths0 = hsluv_lengthOfRayUntilIntersect(hrad, bound0x, bound0y );
    vec3 lengths1 = hsluv_lengthOfRayUntilIntersect(hrad, bound1x, bound1y );

    return  min(lengths0.r,
            min(lengths1.r,
            min(lengths0.g,
            min(lengths1.g,
            min(lengths0.b,
                lengths1.b)))));
}

float hsluv_fromLinear(float c) {
    return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
}
vec3 hsluv_fromLinear(vec3 c) {
    return vec3( hsluv_fromLinear(c.r), hsluv_fromLinear(c.g), hsluv_fromLinear(c.b) );
}

float hsluv_toLinear(float c) {
    return c > 0.04045 ? pow((c + 0.055) / (1.0 + 0.055), 2.4) : c / 12.92;
}

vec3 hsluv_toLinear(vec3 c) {
    return vec3( hsluv_toLinear(c.r), hsluv_toLinear(c.g), hsluv_toLinear(c.b) );
}

float hsluv_yToL(float Y){
    return Y <= 0.0088564516790356308 ? Y * 903.2962962962963 : 116.0 * pow(Y, 1.0 / 3.0) - 16.0;
}

float hsluv_lToY(float L) {
    return L <= 8.0 ? L / 903.2962962962963 : pow((L + 16.0) / 116.0, 3.0);
}

vec3 xyzToRgb(vec3 tuple) {
    const mat3 m = mat3( 
        3.2409699419045214  ,-1.5373831775700935 ,-0.49861076029300328 ,
       -0.96924363628087983 , 1.8759675015077207 , 0.041555057407175613,
        0.055630079696993609,-0.20397695888897657, 1.0569715142428786  );
    
    return hsluv_fromLinear(tuple*m);
}

vec3 rgbToXyz(vec3 tuple) {
    const mat3 m = mat3(
        0.41239079926595948 , 0.35758433938387796, 0.18048078840183429 ,
        0.21263900587151036 , 0.71516867876775593, 0.072192315360733715,
        0.019330818715591851, 0.11919477979462599, 0.95053215224966058 
    );
    return hsluv_toLinear(tuple) * m;
}

vec3 xyzToLuv(vec3 tuple){
    float X = tuple.x;
    float Y = tuple.y;
    float Z = tuple.z;

    float L = hsluv_yToL(Y);
    
    float div = 1./dot(tuple,vec3(1,15,3)); 

    return vec3(
        1.,
        (52. * (X*div) - 2.57179),
        (117.* (Y*div) - 6.08816)
    ) * L;
}


vec3 luvToXyz(vec3 tuple) {
    float L = tuple.x;

    float U = tuple.y / (13.0 * L) + 0.19783000664283681;
    float V = tuple.z / (13.0 * L) + 0.468319994938791;

    float Y = hsluv_lToY(L);
    float X = 2.25 * U * Y / V;
    float Z = (3./V - 5.)*Y - (X/3.);

    return vec3(X, Y, Z);
}

vec3 luvToLch(vec3 tuple) {
    float L = tuple.x;
    float U = tuple.y;
    float V = tuple.z;

    float C = length(tuple.yz);
    float H = degrees(atan(V,U));
    if (H < 0.0) {
        H = 360.0 + H;
    }
    
    return vec3(L, C, H);
}

vec3 lchToLuv(vec3 tuple) {
    float hrad = radians(tuple.b);
    return vec3(
        tuple.r,
        cos(hrad) * tuple.g,
        sin(hrad) * tuple.g
    );
}

vec3 hsluvToLch(vec3 tuple) {
    tuple.g *= hsluv_maxChromaForLH(tuple.b, tuple.r) * .01;
    return tuple.bgr;
}

vec3 lchToHsluv(vec3 tuple) {
    tuple.g /= hsluv_maxChromaForLH(tuple.r, tuple.b) * .01;
    return tuple.bgr;
}

vec3 hpluvToLch(vec3 tuple) {
    tuple.g *= hsluv_maxSafeChromaForL(tuple.b) * .01;
    return tuple.bgr;
}

vec3 lchToHpluv(vec3 tuple) {
    tuple.g /= hsluv_maxSafeChromaForL(tuple.r) * .01;
    return tuple.bgr;
}

vec3 lchToRgb(vec3 tuple) {
    return xyzToRgb(luvToXyz(lchToLuv(tuple)));
}

vec3 rgbToLch(vec3 tuple) {
    return luvToLch(xyzToLuv(rgbToXyz(tuple)));
}

vec3 hsluvToRgb(vec3 tuple) {
    return lchToRgb(hsluvToLch(tuple));
}

vec3 rgbToHsluv(vec3 tuple) {
    return lchToHsluv(rgbToLch(tuple));
}

vec3 hpluvToRgb(vec3 tuple) {
    return lchToRgb(hpluvToLch(tuple));
}

vec3 rgbToHpluv(vec3 tuple) {
    return lchToHpluv(rgbToLch(tuple));
}

vec3 luvToRgb(vec3 tuple){
    return xyzToRgb(luvToXyz(tuple));
}

// allow vec4's
vec4   xyzToRgb(vec4 c) {return vec4(   xyzToRgb( vec3(c.x,c.y,c.z) ), c.a);}
vec4   rgbToXyz(vec4 c) {return vec4(   rgbToXyz( vec3(c.x,c.y,c.z) ), c.a);}
vec4   xyzToLuv(vec4 c) {return vec4(   xyzToLuv( vec3(c.x,c.y,c.z) ), c.a);}
vec4   luvToXyz(vec4 c) {return vec4(   luvToXyz( vec3(c.x,c.y,c.z) ), c.a);}
vec4   luvToLch(vec4 c) {return vec4(   luvToLch( vec3(c.x,c.y,c.z) ), c.a);}
vec4   lchToLuv(vec4 c) {return vec4(   lchToLuv( vec3(c.x,c.y,c.z) ), c.a);}
vec4 hsluvToLch(vec4 c) {return vec4( hsluvToLch( vec3(c.x,c.y,c.z) ), c.a);}
vec4 lchToHsluv(vec4 c) {return vec4( lchToHsluv( vec3(c.x,c.y,c.z) ), c.a);}
vec4 hpluvToLch(vec4 c) {return vec4( hpluvToLch( vec3(c.x,c.y,c.z) ), c.a);}
vec4 lchToHpluv(vec4 c) {return vec4( lchToHpluv( vec3(c.x,c.y,c.z) ), c.a);}
vec4   lchToRgb(vec4 c) {return vec4(   lchToRgb( vec3(c.x,c.y,c.z) ), c.a);}
vec4   rgbToLch(vec4 c) {return vec4(   rgbToLch( vec3(c.x,c.y,c.z) ), c.a);}
vec4 hsluvToRgb(vec4 c) {return vec4( hsluvToRgb( vec3(c.x,c.y,c.z) ), c.a);}
vec4 rgbToHsluv(vec4 c) {return vec4( rgbToHsluv( vec3(c.x,c.y,c.z) ), c.a);}
vec4 hpluvToRgb(vec4 c) {return vec4( hpluvToRgb( vec3(c.x,c.y,c.z) ), c.a);}
vec4 rgbToHpluv(vec4 c) {return vec4( rgbToHpluv( vec3(c.x,c.y,c.z) ), c.a);}
vec4   luvToRgb(vec4 c) {return vec4(   luvToRgb( vec3(c.x,c.y,c.z) ), c.a);}
// allow 3 floats
vec3   xyzToRgb(float x, float y, float z) {return   xyzToRgb( vec3(x,y,z) );}
vec3   rgbToXyz(float x, float y, float z) {return   rgbToXyz( vec3(x,y,z) );}
vec3   xyzToLuv(float x, float y, float z) {return   xyzToLuv( vec3(x,y,z) );}
vec3   luvToXyz(float x, float y, float z) {return   luvToXyz( vec3(x,y,z) );}
vec3   luvToLch(float x, float y, float z) {return   luvToLch( vec3(x,y,z) );}
vec3   lchToLuv(float x, float y, float z) {return   lchToLuv( vec3(x,y,z) );}
vec3 hsluvToLch(float x, float y, float z) {return hsluvToLch( vec3(x,y,z) );}
vec3 lchToHsluv(float x, float y, float z) {return lchToHsluv( vec3(x,y,z) );}
vec3 hpluvToLch(float x, float y, float z) {return hpluvToLch( vec3(x,y,z) );}
vec3 lchToHpluv(float x, float y, float z) {return lchToHpluv( vec3(x,y,z) );}
vec3   lchToRgb(float x, float y, float z) {return   lchToRgb( vec3(x,y,z) );}
vec3   rgbToLch(float x, float y, float z) {return   rgbToLch( vec3(x,y,z) );}
vec3 hsluvToRgb(float x, float y, float z) {return hsluvToRgb( vec3(x,y,z) );}
vec3 rgbToHsluv(float x, float y, float z) {return rgbToHsluv( vec3(x,y,z) );}
vec3 hpluvToRgb(float x, float y, float z) {return hpluvToRgb( vec3(x,y,z) );}
vec3 rgbToHpluv(float x, float y, float z) {return rgbToHpluv( vec3(x,y,z) );}
vec3   luvToRgb(float x, float y, float z) {return   luvToRgb( vec3(x,y,z) );}
// allow 4 floats
vec4   xyzToRgb(float x, float y, float z, float a) {return   xyzToRgb( vec4(x,y,z,a) );}
vec4   rgbToXyz(float x, float y, float z, float a) {return   rgbToXyz( vec4(x,y,z,a) );}
vec4   xyzToLuv(float x, float y, float z, float a) {return   xyzToLuv( vec4(x,y,z,a) );}
vec4   luvToXyz(float x, float y, float z, float a) {return   luvToXyz( vec4(x,y,z,a) );}
vec4   luvToLch(float x, float y, float z, float a) {return   luvToLch( vec4(x,y,z,a) );}
vec4   lchToLuv(float x, float y, float z, float a) {return   lchToLuv( vec4(x,y,z,a) );}
vec4 hsluvToLch(float x, float y, float z, float a) {return hsluvToLch( vec4(x,y,z,a) );}
vec4 lchToHsluv(float x, float y, float z, float a) {return lchToHsluv( vec4(x,y,z,a) );}
vec4 hpluvToLch(float x, float y, float z, float a) {return hpluvToLch( vec4(x,y,z,a) );}
vec4 lchToHpluv(float x, float y, float z, float a) {return lchToHpluv( vec4(x,y,z,a) );}
vec4   lchToRgb(float x, float y, float z, float a) {return   lchToRgb( vec4(x,y,z,a) );}
vec4   rgbToLch(float x, float y, float z, float a) {return   rgbToLch( vec4(x,y,z,a) );}
vec4 hsluvToRgb(float x, float y, float z, float a) {return hsluvToRgb( vec4(x,y,z,a) );}
vec4 rgbToHslul(float x, float y, float z, float a) {return rgbToHsluv( vec4(x,y,z,a) );}
vec4 hpluvToRgb(float x, float y, float z, float a) {return hpluvToRgb( vec4(x,y,z,a) );}
vec4 rgbToHpluv(float x, float y, float z, float a) {return rgbToHpluv( vec4(x,y,z,a) );}
vec4   luvToRgb(float x, float y, float z, float a) {return   luvToRgb( vec4(x,y,z,a) );}

/*
END HSLUV-GLSL
*/

// quantize and input number [0, 1] to quantLevels levels
float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

float quant0(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels))/quantLevels;
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

vec3 ballTwist2(vec2 stN, float t2, float numBalls, float intensity, float size){ 
    vec2 warp = stN;
    
    float rad = size;
    
    for (float i = 0.0; i < 100.; i++) {
        if(i == numBalls) break;
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        // warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
        warp = length(p - stN) <= rad ? rotate(warp, p, (1.-length(stN - p)/rad)  * 10.5 * intensity * sinN(1.-length(stN - p)/rad * PI)) : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

vec4 colormap_hsv2rgb(float h, float s, float v) {
    float r = v;
    float g = v;
    float b = v;
    if (s > 0.0) {
        h *= 6.0;
        int i = int(h);
        float f = h - float(i);
        if (i == 1) {
            r *= 1.0 - s * f;
            b *= 1.0 - s;
        } else if (i == 2) {
            r *= 1.0 - s;
            b *= 1.0 - s * (1.0 - f);
        } else if (i == 3) {
            r *= 1.0 - s;
            g *= 1.0 - s * f;
        } else if (i == 4) {
            r *= 1.0 - s * (1.0 - f);
            g *= 1.0 - s;
        } else if (i == 5) {
            g *= 1.0 - s;
            b *= 1.0 - s * f;
        } else {
            g *= 1.0 - s * (1.0 - f);
            b *= 1.0 - s;
        }
    }
    return vec4(r, g, b, 1.0);
}

vec4 colormap(float x) {
    float h = clamp(-7.44981265666511E-01 * x + 7.47965390904122E-01, 0.0, 1.0);
    float s = 1.0;
    float v = 1.0;
    return colormap_hsv2rgb(h, s, v);
}

float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

vec4 circleSlice(vec2 stN, float t, float randw){
    
    //define several different timescales for the transformations
    float t0, t1, t2, t3, t4, rw;
    t0 = t/4.5;
    t1 = t/2.1;
    t2 = t/1.1;
    t3 = t/0.93;
    rw =  randw/290.; //a random walk value used to parameterize the rotation of the final frame
    t4 = t;
    
    t1 = t1 / 2.;
    t0 = t0 / 2.;
    rw = rw / 2.;
    float divx = sinN(t0) * 120.+10.;
    float divy = cosN(t1) * 1400.+10.;
    stN = stN * rotate(stN, vec2(0.5), rw);
    vec2 trans2 = vec2(mod(floor(stN.y * divx), 2.) == 0. ? mod(stN.x + (t1 + rw)/4., 1.) : mod(stN.x - t1/4., 1.), 
                       mod(floor(stN.x * divy), 2.) == 0. ? mod(stN.y + t1, 1.) : mod(stN.y - t1, 1.));
    
    
    bool inStripe = false;
    float dist = distance(trans2, vec2(0.5));


    float numStripes = 20.;
    float d = 0.05;
    float stripeWidth =(0.5 - d) / numStripes;
    for(int i = 0; i < 100; i++){
        if(d < dist && dist < d + stripeWidth/2.) {
            inStripe = inStripe || true;
        } else {
            inStripe = inStripe || false;
        }
        d = d + stripeWidth;
        if(d > 0.5) break;
    }
    
    vec4 c = !inStripe ? vec4(white, 1) : vec4(black, 0);
    return c;
    
}

vec3 inStripeX2(vec2 stN, float rw){
    bool inStripe = false;
    vec2 stN0 = stN;
    for(float i = 0.; i < 40.; i++){
        float seed = 1./i;
        stN = rotate(stN0, vec2(0.5), 0.2 * sin(rw+ i*50.));
        float loc = mod(hash(vec3(seed)).x + sinN(rw*seed*5. + seed) * i/5., 1.);
        if(abs(loc - stN.x) < rand(seed)*0.005 + 0.001) inStripe = inStripe || true;
    }
    return inStripe ? black : white;
}

vec3 inStripeY2(vec2 stN, float t){
    bool inStripe = false;
    vec2 stN0 = stN;
    for(float i = 0.; i < 40.; i++){
        float seed = 1./i;
        stN = rotate(stN0, vec2(0.5), 0.2 * sin(t+ i*50.));
        float loc = mod(hash(vec3(seed)).x + sinN(t*seed*5. + seed) * i/5., 1.);
        if(abs(loc - stN.y) < rand(seed)*0.005  + 0.001) inStripe = inStripe || true;
    }
    return inStripe ? black : white;
}

vec2 xLens(vec2 stN, float rw){
    bool inStripe = false;
    vec2 stN0 = stN;
    vec2 coord = stN;
    float lensSize = 0.05;
    for(float i = 0.; i < 40.; i++){
        float seed = 1./i;
        stN = rotate(stN0, vec2(0.5), 0.3 * sin(rw+ i*50.));
        float loc = mod(hash(vec3(seed)).x + sinN(rw*seed*5. + seed) * i/5., 1.);
        if(abs(loc - stN.x) < lensSize) coord = vec2(mix(loc, coord.x, abs(loc - stN.x)/lensSize), coord.y);
    }
    return coord;
}

vec2 yLens(vec2 stN, float t){
    bool inStripe = false;
    vec2 stN0 = stN;
    vec2 coord = stN;
    float lensSize = 0.05;
    for(float i = 0.; i < 40.; i++){
        float seed = 1./i;
        stN = rotate(stN0, vec2(0.5), 0.3 * sin(t+ i*50.));
        float loc = mod(hash(vec3(seed)).x + sinN(t*seed*5. + seed) * i/5., 1.);
        if(abs(loc - stN.y) < lensSize) coord = vec2(coord.x, mix(loc, coord.y, abs(loc - stN.y)/lensSize));
    }
    return coord;
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

vec2 multiBallCondition(vec2 stN, float t2){
    
    float rad = .08;
    bool cond = false;
    float ballInd = -1.;
    
    for (int i = 0; i < 20; i++) {
        float i_f = float(i);
        vec2 p = vec2(sinN(t2 * rand(vec2(i_f+1., 10.)) * 1.3 + i_f), cosN(t2 * rand(vec2(i_f+1., 10.)) * 1.1 + i_f));
        cond = cond || distance(stN, p) < rad;
        if(distance(stN, p) < rad) ballInd = float(i); 
    }
    
    return vec2(cond ? 1. :0., ballInd/20.);
}

float sigmoid(float x){
    return 1. / (1. + exp(-x));
}

// calculates the luminance value of a pixel
// formula found here - https://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color 
vec3 lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return vec3(dot(color, weights));
}

float getShimmer(){
    float t2 = time/5. + 1000.;
    vec2 stN = uvN();
    stN = quant(stN, 1000.*midiCC[18]);
    stN.y += 0.001 + sinN(time+stN.x*PI)*0.0015 * sinN(time+stN.x*PI*10.)*0.0015;
    float numCells = 400.;

    vec2 hashN = stN + (hash(vec3(stN, t2)).xy + -0.5)/numCells;

    
    vec3 cc;
    float decay = 0.999;
    float decay2 = 0.01;
    float feedback;
    vec4 bb = texture(backbuffer, hashN);
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
    
    return feedback;
}

vec4 clock() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y); //flip the input x dimension because the macbook camera doesn't mirror the image
    vec2 nn = uvN();
    float centT = time/5. + midiCC[0]*2.;
    vec2 cent0 = vec2(0.5);
    vec2 cent = vec2(0.5) + vec2(sin(centT), cos(centT))/5.;
    
    float t2 = time/2.; //time is the uniform for global time
    
    //the fragment color variable name (slightly different from shader toy)
    float noiseT = time/2.;
    stN = rotate(stN, cent0, time/10.*midiCC[2]);
    vec2 warpN = stN + vec2(snoise(vec3(stN, noiseT)), snoise(vec3(stN, noiseT+4.)))/4.; //play with warp amount
    vec2 warpN2 = stN + vec2(snoise(vec3(stN, noiseT/2.)), snoise(vec3(stN, noiseT/2.+4.)))/4.;
    // warpN = mod(warpN, 0.2 + sinN(time/5.5)); wrap(warpN, 0., 1.);
    // warpN2 = mod(warpN2, 0.2 + sinN(time/5.5)); wrap(warpN2, 0., 1.);
    stN = mix(stN, warpN, distance(stN, cent)*2.);
    vec2 stN2 = mix(stN, warpN2, distance(stN, cent)*2.);
    
    float width = 0.001 + 0.001 * pow(distance(nn, cent), 1.)*500.;
    vec3 col = stN.y < 0.5 && stN.y > 0.1 && stN.x > .5-width && stN.x < 0.5+width ? black : white;
    
    
    
    vec3 c;
    vec2 bbN = mix(nn, stN2, distance(nn, vec2(0.5))/(10. + cosN(time/2.3)*1000.) ); //play with warp feedback mix
    vec4 bb = texture(backbuffer, mix(bbN, vec2(0.5), midiCC[4]));
    vec4 bb0 = texture(backbuffer, nn);
    float fb2;
    float feedback; 
    if(col == white){
        feedback = bb.a * 0.97;
        fb2 = bb0.a * 0.97;
    } 
    else{
        feedback = 1.;
        fb2 = 1.;
    } 
    
    feedback  = mix(feedback, fb2, sinN(time/5.));
    vec3 lowFdbkCol = vec3(feedback); vec3(cosN(feedback * distance(stN, vec2(0.5))*(10.+50.*distance(stN, cent))));
    float cc = feedback < 0.4 ? 0.: sinN(-time*10. + feedback * distance(stN, vec2(0.5))*(10.+50.*distance(stN, cent)));
    
    cc = pow(cc, 1. + 200. * pow(sinN(time/2.), 10.)); //play with pulsed line resolution
    
    return vec4(vec3(cc), feedback);//vec4(c, feedback);
}

vec4 traffic () {
    vec2 stN = uvN();
    vec3 c;

    //take 1
    // stN = rowColWave(stN, 100., -time, 0.05);
    // stN = coordWarp(stN, time).xy;
    // float t2 = time / 4.;
    // for(int i = 0; i < 2; i++) {
    //     stN = wrap(rotate(stN, vec2(0.5), t2+0.1) * rotate(stN, vec2(0.5), t2), 0., 1.);
    // }
    // stN = wrap(vec2(tan(stN.x+time/8.), tan(stN.y+time/10.)), 0., 1.);
    
    // stN = xLens(stN, time/20.);
    // stN = yLens(stN, time/30.);
    
    
    
    float zoom = 2.;
    // stN = rowColWave(stN, time, 1000., .1);
    // stN = mix(rotate(stN, vec2(0.5), time/420. * distance(stN, vec2(0.5)) * 0.  ), vec2(0.5), 4.);
    vec3 cam = texture(channel0, stN).rgb;
    float t2 = 3.* PI; 
    float t3 = time/5.;
    float t4 = time;
    float rad = 0.0;
    vec2 warp1 = vec2(-1., 1.);
    vec2 warp2 = vec2(0.5, 0.);
    vec2 warpXY = mix(warp1, warp2, 0.);
    stN = mix(stN, rotate(stN, vec2(0.5) + sin(t4)*rad, t3), sinN(stN.x*PI*(1.+sinN(t2/2.)*5.) + t2*3.) * warpXY.x*2.);
    stN = mix(stN, rotate(stN, vec2(0.5) + cos(t4)*rad, t3), sinN(stN.y*PI*(1.+sinN(t2/2.)*5.) + t2*3.) * warpXY.y *2.);
    // stN = mix(stN, rotate(stN, vec2(0.5), t2), sinN((distance(stN, vec2(0.5))+0.01)*PI*(1.+sinN(t2/2.)*5.) + t2*3.) * sin(time)*2.);
    // t2 = time;
    // stN = mix(stN, rotate(stN, vec2(0.5), t2), sinN(stN.x*PI*(1.+sinN(t2/2.)*5.) + t2*3.));
    // stN = rotate(stN, vec2(0.5), abs(stN.x-0.5) * abs(stN.y-0.5));

    
    //take2
    float timeVal = time+3000.;
    stN = quant(stN, 200.);
    vec2 stN2 = rotate(stN, vec2(0.5), time/2.);
    c = inStripeX2(stN, timeVal/10. * (.5 + stN.x)) * inStripeY2(stN, timeVal/7. * (.5 + stN.y));
    
    vec3 cc;
    float decay = 0.97;
    float feedback;
    vec4 bb = texture(backbuffer, vec2(stN.x, stN.y));
    float lastFeedback = bb.a;
    // bool crazyCond = (circleSlice(stN, time/6., time + sinN(time*sinN(time)) *1.8).x - circleSlice(stN, (time-sinN(time))/6., time + sinN(time*sinN(time)) *1.8).x) == 0.;
    bool condition = c == black; 
    vec3 trail = black; // swirl(time/5., trans2) * c.x;
    vec3 foreGround = white;
    
    
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
    cc = mix(cc, bb.rgb, sinN(time/14.)*0.95);
    
    //todo - don't forget to make these lines linear lenses
    
    return vec4(c, feedback);
}

vec4 lightLine_slider () {
    float timeSwing = sinN(time + midiCC[8]*15.)*midiCC[7];
    float t2 = midiCC[1] * 20. + timeSwing;
    
    vec4 mouseN = mouse / vec4(resolution, resolution) / 2.;
    // mouseN = vec4(mouseN.x, 1.-mouseN.y, mouseN.z, 1.-mouseN.w);
    vec2 cent = vec2(0.5);
    float time1 = midiCC[0]*3. * midiCC[11]*10. + midiCC[12]*100. + midiCC[13]*10.+ timeSwing;
    
    vec3 hslScale = vec3(360, 100, 100);
    vec3 hslCol = vec3(0.5, 1., .8);
    vec3 rgbCol = hsluvToRgb(hslCol*hslScale);



    vec2 stN = uvN();
    stN = mix(stN, cent, midiCC[10]/10.);
    float numCells = 400.;
    vec3 warp = ballTwist2(stN, time1/2., 20., midiCC[5], midiCC[6]);
    vec3 warpSink = vec3(0.);
    // warpSink = coordWarp(stN, time/20., 3.);
    warpSink = ballTwist2(coordWarp(stN, time1/6.).xy, time1/30., 30., midiCC[5], midiCC[6]);
    // vec3 warp2 = coordWarp(stN, time +4.);
    stN = mix(stN, warp.xy, 0.025);
    vec2 texN = vec2(0.);
    texN =(hash(vec3(stN, t2)).xy + -0.5)/numCells;
    // texN = vec2(sin(stN.x*numCells), cos(stN.y*numCells))/numCells;
    vec2 hashN = stN + texN;


    float height = 0.5;
    float thickness = 0.03;
    
    vec3 warp2 = coordWarp(warp.xy, time1/2.);
    bool lineCond = abs(warp2.y - height) < thickness;
    // if(mouseN.z > 0.) cent = mouseN.xy;
    bool ballCond = distance(warp2.xy, cent) < sinN(t2/2.)*0.3 && distance(warp2.xy, cent) > sinN(t2/2.)*0.2;
    
    vec3 cc;
    float decay = 0.999;
    float decay2 = 0.05 * midiCC[2];
    float feedback;
    vec4 bb = texture(backbuffer, mix(hashN, warpSink.xy, (midiCC[9]-0.5)*0.2));
    float lastFeedback = bb.a;

    // vec2 multBall = multiBallCondition(stN, t2/2.);
    bool condition = ballCond;

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
    

    float col = sinN((1.-feedback)*PI*5.);
    
    // col = sigmoid((col-0.5)*5.);
    col = mix(bb.r, col, midiCC[3]);
    vec3 c = vec3(feedback < midiCC[4] ? 0. : col);
    
    // c.xy = rotate(c.xy, cent, warp.x*3.);
    // c.yz = rotate(c.yz, cent, warp.y*3.);
    // c.zx = rotate(c.zx, cent, warp.z*3.);
    // c = mix(bb.rgb, col, 0.01);
    
    
    return vec4(c, feedback);
}

vec4 fogShip () {
    float t2 = time + 1000.;
    
    vec4 mouseN = mouse / vec4(resolution, resolution) / 2.;
    mouseN = vec4(mouseN.x, 1.-mouseN.y, mouseN.z, 1.-mouseN.w);

    vec2 stN = uvN();
    float numCells = 5.;
    vec2 rotN = rotate(stN, vec2(0.5), PI);
    vec2 rowColN = rowColWave(rotN, 1000., time/4., 0.3);
    vec2 rowColN2 = rowColWave(stN, 1000., time/4., 0.03);
    vec2 hashN = stN + (hash(vec3(stN, t2)).xy + -0.5)/numCells/(10. + sinN(rowColN.x*PI+time/1.5)*100.);
    vec2 warpCoord = mix(stN, coordWarp(rowColN2, time/5.).xy, .8);
    
    vec3 cc;
    float decay = 0.999;
    float decay2 = 0.5;
    float feedback;
    vec4 bb = texture(backbuffer, mix(hashN, rotN, 0.01*pow(rotN.y, .02)));
    float lastFeedback = bb.a;

    // vec2 multBall = multiBallCondition(stN, t2/2.);
    bool condition = mod(stN.x*numCells, 1.) < sinN(time + stN.x*PI) || mod(stN.y*numCells, 1.) < cosN(time + stN.y*PI); //multBall.x == 1.; 
    condition = distance(warpCoord, stN) > 0.1; 1./(numCells*10.*(0.5+rowColN.y));

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
    col = mix(bb.rgb, col, 0.1);
    
    vec2 cent = vec2(0.5);
    
    col = mix(bb.rgb, col, 0.1);
    
    return vec4(col, feedback);
}

float splits(vec2 stN){
    
    float xHigh = 1.;
    float xLow = 0.;
    float seed = 1.; quant(time/4., 1.);
    
    float yHigh = 1.;
    float yLow = 0.;
    
    bool xSplit = false;
    bool ySplit = false;
    bool dark = false;
    vec2 rotN = rotate(stN, vec2(0.5), time/5.+midiCC[11]);
    for(int i = 0; i < 6; i++){
        float phase = dark ? 0. : 1.;
        float randSplit= 0.3 + rand(float(i)+phase + seed)*0.4 * sinN(time*mix(1., rotN.x, sinN(time+stN.y*PI)/300.) + float(i)*PI2/8.);
        if(mod(float(i), 2.) == 0.) {
            float xPos = mix(xLow, xHigh, randSplit);
            if(stN.x <= xPos){
                dark = !dark;
                xHigh = xPos;
            } else {
                xLow = xPos;   
            }
        }
        else {
            float yPos = mix(yLow, yHigh, randSplit);
            if(stN.y <= yPos){
                dark = !dark;
                yHigh = yPos;
            } else {
                yLow = yPos;   
            }
        }
    }
    
    
    float line = 0.005;
    bool nearLine = abs(stN.x - xLow) < line || abs(stN.x - xHigh) < line || abs(stN.y - yLow) < line || abs(stN.y - yHigh) < line;
    return (dark  || nearLine) ? 0. : 1. ;
}

vec4 tiles () {
    vec2 stN = uvN();
    vec2 cent = vec2(0.5);
    stN = mix(stN, cent, midiCC[10]);
    vec3 warpN = ballTwist(stN, time);
    vec3 warpN2 = coordWarp(stN, time/5.);
    
   
    // c = mix(c, bb.rgb, 0.1);
    
    //todo - don't forget to make these lines linear lenses
    float split = splits(mix(stN, stN.xy, warpN.z));
    float shimmer = getShimmer();
    float c = split == 1. ? shimmer : 1. - shimmer;
    c = pow(c+0.4, .2 + sinN(time+warpN.x)*10.);
    
    vec4 bb = texture(backbuffer, mix(stN, warpN.xy, midiCC[1]));
    stN = mix(stN, cent, sinN(time/3.));
    vec2 warpM = mix(stN, warpN2.xy, 1.);
    float xMix = quant(mod(time/5. +warpM.x + sinN(time/5.), 1.), 1.);
    float yMix = quant(mod(time/5.5 +warpM.y + sinN(time/5. * 0.9), 1.), 1.);
    split = mix(split, bb.x, xMix);
    split = mix(split, bb.x, yMix);
    
    stN = uvN();
    stN = rotate(stN, cent, 0.01*sin(time + sinN(time/1.15)*0.5 ));
    
    if(xMix + yMix != 0.) split = texture(backbuffer, vec2(stN.x, stN.y+0.01)).x * mix(1., shimmer, 0.03);
    else if(split == 0.) split = mix(split, bb.x, 0.);
    
    
    return vec4(vec3(split), shimmer);
}


out vec4 fragColor;
void main () {
    float t2 = time/5. + 1000.;
    
    vec4 mouseN = mouse / vec4(resolution, resolution) / 2.;
    mouseN = vec4(mouseN.x, 1.-mouseN.y, mouseN.z, 1.-mouseN.w);

    vec2 stN = uvN();
    vec2 cent = vec2(0.5);
        vec2 warpN = coordWarp(stN, time).xy;
    stN = quant(stN, 10.+pow(midiCC[5], 10.)*1000.);
    stN = mix(stN, cent, midiCC[3]/10.);
    float numCells = 400.;
    
    vec3 cam = red;texture(channel0, vec2(1.-stN.x, stN.y)).rgb;
    float shim = getShimmer();
    vec2 hashN = stN + vec2(shim, mod(shim+0.3, 1.));// (cam.xy-0.5)/numCells;(hash(vec3(stN, t2)).xy + -0.5)/numCells;
    

    
    vec3 cc;
    float decay = 0.999;
    float decay2 = 0.01;
    float feedback;
    vec4 bb = texture(backbuffer, hashN);
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
    
    vec3 hslScale = vec3(360, 100, 100);
    vec3 hslCol = vec3(0.5, 1., .8);
    vec3 rgbCol = hsluvToRgb(hslCol*hslScale);
    stN = rotate(hashN, cent, midiCC[1]*PI2);
    float n = 9.;
    int ind = int(quant0(stN.x, n)*n);
    float logVal = fftLogVals[ind]*10.;
    float n2 = 20.;
    int ind2 = int(quant0(mix(stN.x, warpN.x, midiCC[0]*1.), n2)*n2);
    float fftVal = fftValues[ind2]*10.;
    float n3 = 10. + sinN(time/1.5)*20.;
    int ind3 = int(quant0(mix(stN.x, warpN.x, midiCC[0]*1.), n3)*n3);
    float fftSmall = fftValues[ind3]*10.;
    
    // col = quant(col, 1.);
    // col = mix(bb.rgb, col, 0.025);
    vec3 fftCol = vec3(fftValues[int(quant(stN.x, 49.)*50.)]/255.);
    vec3 midiCol = vec3(midiCC[int(quant(stN.x, 8.)*8.)]/127.);
    
    // float modVal = 1.;
    // float slitTime = time/2.;
    // float fdbk = bb.a;
    // float slitW = midiCC[2];
    // stN = mix(stN, coordWarp(stN, time).xy, 0.9);
    // float slitCondition = float(mod(slitTime, modVal) < stN.x && stN.x < mod(slitTime, modVal) + slitW );
    // col = mix(bb.rgb, vec3(fftSmall*100.), slitCondition);
    // col = circleSlice(uvN()*rotate(uvN(), cent, time/4.), time/5., randWalk);
    
    
    
    vec3 col2 = mix(white, rgbCol, midiCC[4]) * vec3(fftSmall*30.);
    vec4 lightLine = lightLine_slider();
    vec4 tileLight = mix(lightLine, tiles(), midiCC[14]);
    // vec4 clockV = clock();
    vec4 doubleMix = mix(tileLight,  vec4(col2, feedback), midiCC[15]);
    // vec4 clockLine = mix(clockV, lightLine, midiCC[18])*1.1;;
    fragColor = vec4(quant(doubleMix.rgb, 100.*midiCC[18]), doubleMix.a)*1.09;
}

//clock, traffic, lightLine_slider - 7 is activeWobble, fogShip, tiles