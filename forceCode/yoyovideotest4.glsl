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
    
    float rad = .5;
    
    for (float i = 0.0; i < 20.; i++) {
        vec2 p = vec2(sinN(t2* rand(i+1.) * 1.3 + i), cosN(t2 * rand(i+1.) * 1.1 + i));
        // warp = length(p - stN) <= rad ? mix(p, warp, length(stN - p)/rad)  : warp;
        warp = length(p - stN) <= rad ? rotate(warp, p, (1.-length(stN - p)/rad)  * 2.5 * sinN(1.-length(stN - p)/rad * PI)) : warp;
    }
    
    return vec3(warp, distance(warp, stN));
}

void ex3() {
    vec2 stN = uvN();
    vec2 camPos = vec2(1.-stN.x, stN.y);
    vec3 cam = texture2D(channel5, camPos).rgb; 
    vec3 snap = texture2D(channel7, camPos).rgb;

    vec3 c;
    float numLines = 150.;
    vec2 nn = uvN();
    vec2 rotN =  texture2D(channel5, vec2(1.-nn.x, nn.y)).rg;
    float gridThickness = 1./numLines * lum(cam).x;
    if(mod(stN.x, 1./numLines) < gridThickness || mod(stN.y, 1./numLines) < gridThickness) c =black;
    else c = white;
    
    vec2 modN = stN + rotate(hash(vec3(stN,0.)).xy, vec2(0.5), 0.5)/50.;
    modN = mod(stN + modN, 1.);
    
    float numHex = 200.;
    vec2 rotCenter = hexCenter2(stN * numHex, 1.)/numHex;
    float hexDist = distance(rotCenter, stN*numHex);
    vec2 hexRot = rotate(stN, rotCenter, time + rotCenter.x*10.);
    
    vec2 twist = ballTwist(stN, time).xy;
    
    modN = twist;
    vec3 vidnoise = texture2D(channel5, modN).rgb;
    
    vec4 bb = texture2D(backbuffer, stN);
    float feedback; 
    float dist = colourDistance(cam, snap)/colourDistance(black, white);
    if(dist < .3 + sinN(time)*0.3){
        feedback = bb.a * 0.8;
    } 
    else{
        feedback = 1.;
    } 
    
    
    vec3 final  = feedback > 0.2 ? vidnoise : cam;
    final = mix(cam, vidnoise, dist*sinN(time/5.)*10.);
    
    final = colourDistance(cam, black) < 0.1 ? black : final;
    final = mix(final, bb.rgb, sinN(time/4.)*0.8);
    gl_FragColor = vec4(vidnoise, feedback);//vec4(c, feedback);
}

void main(){
    ex3();
}