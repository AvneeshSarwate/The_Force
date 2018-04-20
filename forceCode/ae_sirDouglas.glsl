//calculate the distance beterrn two colors
// formula found here - https://stackoverflow.com/a/40950076
float colourDistance(vec3 e1, vec3 e2) {
  float rmean = (e1.r + e2.r ) / 2.;
  float r = e1.r - e2.r;
  float g = e1.g - e2.g;
  float b = e1.b - e2.b;
  return sqrt((((512.+rmean)*r*r)/256.) + 4.*g*g + (((767.-rmean)*b*b)/256.));
}

// quantize and input number [0, 1] to quantLevels levels
float quant(float num, float quantLevels){
    float roundPart = floor(fract(num*quantLevels)*2.);
    return (floor(num*quantLevels)+roundPart)/quantLevels;
}

// same as above but for vectors, applying the quantization to each element
vec2 quant(vec2 num, float quantLevels){
    vec2 roundPart = floor(fract(num*quantLevels)*2.);
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
    for (int i = 0; i < 3; i++) {
        stN = rowWaves3(stN, div, time2, power);
        stN = columnWaves3(stN, div, time2, power);
    }
    return stN;
}


float colormap_red(float x) {
	if (x < 0.122867923365625) {
		return -5.81788489736069E+02 * x + 2.50471590909091E+02;
	} else if (x < 0.2449046174927113) {
		return 1.99984352773830E+02 * x + 1.54416785206258E+02;
	} else if (x < 0.3729729104526915) {
		return 1.43786086956516E+02 * x + 1.68180000000001E+02;
	} else if (x < 0.5011116081610979) {
		return 2.52012802275928E+02 * x + 1.27814366998585E+02;
	} else if (x < 0.6239282365941264) {
		return 7.85450500555661E+00 * x + 2.50164923989616E+02;
	} else if (x < 0.7520403577351265) {
		return -2.00555718475049E+02 * x + 3.80197947214058E+02;
	} else if (x < 0.8796535309192707) {
		return 1.86622408963526E+02 * x + 8.90243697479360E+01;
	} else {
		return -9.30674082313196E+01 * x + 3.35054505005547E+02;
	}
}

float colormap_green(float x) {
	if (x < 0.2498801528138394) {
		return 2.21725710445469E+02 * x + 1.79002480158730E+02;
	} else if (x < 0.3735167574956272) {
		return -2.52975806451616E+02 * x + 2.97620967741935E+02;
	} else if (x < 0.5007872003710714) {
		return 1.09439266615749E+02 * x + 1.62252864782272E+02;
	} else if (x < 0.6262274652716027) {
		return 3.02956451612894E+02 * x + 6.53419354838611E+01;
	} else if (x < 0.752848702686641) {
		return -3.10470307917895E+02 * x + 4.49486620234600E+02;
	} else if (x < 0.8827503622135592) {
		return 2.27675070027963E+01 * x + 1.98608963585427E+02;
	} else {
		return 1.95678708265011E+02 * x + 4.59715380404256E+01;
	}
}

float colormap_blue(float x) {
	if (x < 0.1232989588096424) {
		return 4.29695747800585E+02 * x + 1.74153409090909E+02;
	} else if (x < 0.2476314320040304) {
		return -2.40499266862156E+02 * x + 2.56787756598238E+02;
	} else if (x < 0.3742360961829455) {
		return 2.41095161290329E+02 * x + 1.37529838709676E+02;
	} else if (x < 0.4998594481260504) {
		return -4.90936497326148E+02 * x + 4.11482508912633E+02;
	} else if (x < 0.6256351261233096) {
		return 2.96955882352941E+02 * x + 1.76470588235230E+01;
	} else if (x < 0.7525509527474964) {
		return -1.11771301446066E+02 * x + 2.73361142009640E+02;
	} else if (x < 0.8785969154660433) {
		return 3.73063712757765E+02 * x - 9.15019098547990E+01;
	} else {
		return 4.55448275862047E+01 * x + 1.96255172413811E+02;
	}
}

vec4 colormap(float x) {
	float r = clamp(colormap_red(x) / 255.0, 0.0, 1.0);
	float g = clamp(colormap_green(x) / 255.0, 0.0, 1.0);
	float b = clamp(colormap_blue(x) / 255.0, 0.0, 1.0);
	return vec4(r, g, b, 1.0);
}


float lum(vec3 color){
    vec3 weights = vec3(0.212, 0.7152, 0.0722);
    return dot(color, weights);
}

vec3 czm_saturation(vec3 rgb, float adjustment)
{
    // Algorithm from Chapter 16 of OpenGL Shading Language
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}

void main() {
    vec2 stN = uvN();
    float tScale = time / 10.;
    vec2 colorPoint = vec2(sinN(tScale), cosN(tScale));
    vec2 mouseN = mouse.zw / resolution.xy / 2.;
    mouseN = vec2(sinN(time), cosN(time)) / 2. + 0.25; vec2(mouseN.x, 1. - mouseN.y);
    
    float waveIntensity, colorDiff;
    
    int cue = 2;
    if(cue == 1) {
        waveIntensity = 0.05;
        colorDiff = 0.15;
    }
    if(cue == 2) {
        waveIntensity = 0.1;
        colorDiff = 0.45;
    }
    
    
    
    
    vec2 waveCoord = rowColWave(stN, 100., time, waveIntensity);
    
    vec3 camFrame = texture2D(channel0, vec2(1.-stN.x, stN.y)).xyz;
    vec3 quantCam = quant(texture2D(channel0, quant(vec2(1.-stN.x, stN.y), 100.)).xyz, 3.);
    vec3 camPoint = texture2D(channel0, vec2(1. - mouseN.x, mouseN.y)).xyz;
    vec3 vid = texture2D(channel1, stN).xyz;
    vec3 camTex = texture2D(channel1, quant(camFrame.zx, 100.)).xyz;
    camTex = swirl(time/5., stN);
    // camTex = mod(camFrame * (2.+ sinN(time/5.)*20.), 1.);
    // camTex = mod(camTex * (1.+ sinN(time/5.)*1.), 1.);
    if((cue == 1) || (cue ==2)){
        camTex = texture2D(channel0, vec2(1.-waveCoord.x, waveCoord.y)).xyz;
    }
    camTex = texture2D(channel0, quant(vec2(1.-stN.x, stN.y), 50.)).xyz;
    
    vec3 c;
    
    if(colourDistance(camFrame, camPoint) < colorDiff ){
        c = camTex;
    }
    else {
        c = camFrame;
    }
    
    // c = mix(c, (pink + blue) / 2., 0.3);
    c = colormap(lum(c)).rgb; ((colormap(c.r) + colormap(c.g) + colormap(c.b))/3.).rgb;
    // c = vec3(colormap())
    
    if(distance(stN, mouseN) < 0.01) c = white;
    
    gl_FragColor = vec4(czm_saturation(c, 1.5 + sinN(time)*2.), 1.0);
}