#version 120	// come with opengl 2.1

// given by the program
attribute vec3 a_position;
attribute vec2 a_texcoord;
attribute vec4 a_color;
uniform mat4 u_modelViewProjectionMatrix;
uniform mat4 u_modelProjectionInvertedMatrix;   // cause inverse(mat4) was introduced with version 140

uniform vec2 u_rectangleSize;
uniform vec2 u_textureSize;
uniform vec2 u_horizontalBordersSize;
uniform vec2 u_verticalBordersSize;

// shared between vertex and fragment shader
varying vec2 v_texcoord;
varying vec4 v_color;
varying mat4 v_modelProjectionInvertedMatrix;
varying vec2 v_vertex;

varying vec2 v_rectangleSize;
varying vec2 v_textureSize;
varying vec2 v_horizontalBordersSize;
varying vec2 v_verticalBordersSize;

void main()
{
    v_texcoord = a_texcoord;
	v_color = a_color;
    v_modelProjectionInvertedMatrix = u_modelProjectionInvertedMatrix;

	v_rectangleSize = u_rectangleSize;
	v_textureSize = u_textureSize;
	v_horizontalBordersSize = u_horizontalBordersSize;
	v_verticalBordersSize = u_verticalBordersSize;

    gl_Position = u_modelViewProjectionMatrix * vec4(a_position, 1.0);

    v_vertex = vec2(gl_Position.x, gl_Position.y);
}
