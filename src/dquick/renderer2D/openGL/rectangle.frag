#version 120	// come with opengl 2.1
varying vec4 v_color;
varying vec2 v_texcoord;

uniform sampler2D u_texture;

void main()
{
	gl_FragColor = texture2D(u_texture, v_texcoord) * v_color;
}
