
vec3 _hash33(vec3 p3)
{
    p3 = fract(p3 * vec3(.1031,.11369,.13787));
    p3 += dot(p3, p3.yxz+19.19);
    return -1.0 + 2.0 * fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

bool inBound(float target, float range, float query){
    return target - range <= query && query <= target + range;
}

// simplex noise from https://www.shadertoy.com/view/4sc3z2
float noise2(vec3 p)
{
    const float K1 = 0.333333333;
    const float K2 = 0.166666667;
    
    vec3 i = floor(p + (p.x + p.y + p.z) * K1);
    vec3 d0 = p - (i - (i.x + i.y + i.z) * K2);
    
    // thx nikita: https://www.shadertoy.com/view/XsX3zB
    vec3 e = step(vec3(0.0), d0 - d0.yzx);
    vec3 i1 = e * (1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy * (1.0 - e);
    
    vec3 d1 = d0 - (i1 - 1.0 * K2);
    vec3 d2 = d0 - (i2 - 2.0 * K2);
    vec3 d3 = d0 - (1.0 - 3.0 * K2);
    
    vec4 h = max(0.6 - vec4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
    vec4 n = h * h * h * h * vec4(dot(d0, _hash33(i)), dot(d1, _hash33(i + i1)), dot(d2, _hash33(i + i2)), dot(d3, _hash33(i + 1.0)));
    
    return dot(vec4(31.316), n);
}

//the backbuffer uniform is a texture that stores the last rendered frame
//this example shows how I use it to do feedback/trail effects
out vec4 fragColor;


void main(){
    
    // vec2 camPos = vec2(1.-stN.x, stN.y); //flip the input x dimension because the macbook camera doesn't mirror the image
    // vec3 cam = texture2D(channel0, camPos).rgb; 
    // vec3 snap = texture2D(channel3, camPos).rgb;

    // vec3 c;
    // float feedback; 
    // if(colourDistance(cam, snap) < .5){
    //     feedback = texture2D(backbuffer, vec2(stN.x, stN.y)).a * 0.97;
    // } 
    // else{
    //     feedback = 1.;
    // } 
    
    // float n1 = noise2(hash(vec3(4, 5, 6)) + time/10. + stN.x)*.75 + 0.5;
    // float n2 = noise2(hash(vec3(4, 5, 6)) + time/9. + stN.x + 0.5)*.75 + 0.5;
    bool drawLine = false;
    float t = 0.01;
    float tm = time;
    for(float i = 1.; i < 14.; i++){
        vec2 stN = uvN();
        float noiseVal = noise2(hash(vec3(4, 5, 6)) + tm/20. * (10.+i/10.) + stN.x)*.75 + 0.5;
        drawLine = drawLine || inBound(noiseVal, t, stN.y);
    }
    
    // vec3 col = inBound(n1, 0.01, stN.y) || inBound(n2, 0.01, stN.y) ? white : black;
    vec3 col = drawLine ? white : black;
    
    fragColor = vec4(col, 1);//vec4(c, feedback);
}