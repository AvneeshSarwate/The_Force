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




void main () {
    
    //normalized coordinates [0, 1]
    vec2 stN = uvN();
    vec3 c;
    
    vec2 cent = vec2(0.5);
    
    //normalized coordinates again, but these wont get messed with
    vec2 nn = uvN();
    
    
    //can replate sin(1.) with sin(time) to make the "bend" direction oscilate
    stN = rotate(stN, cent, sin(1.)*PI/4. );

    float numLines = 100.;
    
    float gridThickness = 0.5/numLines; 
    
    //the transformation on the x coordinate is what gives it that janky depth/perspective effect
    //the transformation on the y coordinate is what gives it the scrolling motion
    stN = vec2(mix(stN.x, 0.5, (1.-nn.y)), mod(nn.y+time/5., 1.));
    
    //the grild lines are a function of the "position"
    bool gridLineCondition = (mod(stN.x, 1./numLines) < gridThickness || mod(stN.y, 1./numLines*4.) < gridThickness);
    
    //adding the random gaps into the grid lines
    vec2 quantN = quant(stN, numLines);
    bool checkeredTextureCondition = hash(vec3(quantN, 54.)).y > 0.2;
    
    if(gridLineCondition && checkeredTextureCondition) c =black;
    else c = white;
    
    gl_FragColor = vec4(c, 1.);
}