#version 300 es
precision lowp float;

in vec2 position;

void main()
{
    gl_Position = vec4( position , 0, 1);
}