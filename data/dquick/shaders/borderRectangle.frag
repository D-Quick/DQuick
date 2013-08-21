#version 120	// come with opengl 2.1
varying vec4 v_color;
varying vec2 v_texcoord;
varying mat4 v_modelProjectionInvertedMatrix;
varying vec2 v_vertex;

varying vec2 v_rectangleSize;
varying vec2 v_textureSize;
varying vec2 v_horizontalBordersSize;
varying vec2 v_verticalBordersSize;

uniform sampler2D u_texture;

void main()
{
    vec4    temp;
	vec2	coords;
    vec2    localPixel;

    temp = v_modelProjectionInvertedMatrix * vec4(gl_FragCoord.x, gl_FragCoord.y, 0.0, 1.0);
    localPixel.x = temp.x + v_rectangleSize.x / 2.0;
    localPixel.y = temp.y + v_rectangleSize.y / 2.0;

    if (v_texcoord.x <= v_horizontalBordersSize.x / v_textureSize.x)
    {
	    coords.x = v_texcoord.x;
    }
    else if (v_texcoord.x < (v_textureSize.x - v_horizontalBordersSize.y) / v_textureSize.x)
    {
    	coords.x = mod(localPixel.x - v_horizontalBordersSize.x, v_textureSize.x - v_horizontalBordersSize.x - v_horizontalBordersSize.y) / v_textureSize.x + v_horizontalBordersSize.x / v_textureSize.x;
    }
    else
    {
	    coords.x = v_texcoord.x;
    }

    if (v_texcoord.y <= v_verticalBordersSize.x / v_textureSize.y)
    {
	    coords.y = v_texcoord.y;
    }
    else if (v_texcoord.y < (v_textureSize.y - v_verticalBordersSize.y) / v_textureSize.y)
    {
    	coords.y = mod(localPixel.y - v_verticalBordersSize.x, v_textureSize.y - v_verticalBordersSize.x - v_verticalBordersSize.y) / v_textureSize.y + v_verticalBordersSize.x / v_textureSize.y;
    }
    else
    {
	    coords.y = v_texcoord.y;
    }

	gl_FragColor = texture2D(u_texture, coords) * v_color;
}
