#version 120	// come with opengl 2.1

// given by the program
attribute vec3 a_position;
attribute vec4 a_color;
uniform mat4 u_modelViewProjectionMatrix;

// shared between vertex and fragment shader
varying vec4 v_color;

void main()
{
	v_color = a_color;
    gl_Position = u_modelViewProjectionMatrix * vec4(a_position, 1.0);
}
