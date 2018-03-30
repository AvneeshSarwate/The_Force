const float tau = 6.2831853;


vec4 distort(vec4 col){
    return .7+.3*sin(time+vec4(13,17,23,1)*col);
}

void main()
{
    float zoomScale = 1.;
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy) * zoomScale / resolution.y;
    

    float r = 1.;
    float a = time*.1;
    float c = cos(a)*r;
    float s = sin(a)*r;
    for ( int i=0; i<20; i++ )
    {
        //uv = abs(uv);
        
        // higher period symmetry
        float t = atan(uv.x,uv.y);
        const float q = 10. / tau;
        t *= q;
        t = abs(fract(t*.5+.5)*2.0-1.0);
        t /= q;
        uv = length(uv)*vec2(sin(t),cos(t));
        
        uv -= .7;
        uv = uv*c + s*uv.yx*vec2(1,-1);
    }
    
    vec4 colorDistort = .5+.5*sin(time+vec4(13,17,23,1));
    
    
        
    gl_FragColor =texture2D( channel5, uv*vec2(1,-1)+.5, -1.0);
}