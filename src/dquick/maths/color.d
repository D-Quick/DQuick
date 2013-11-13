module dquick.maths.color;

import gl3n.linalg;

alias Vector!(float, 4) Color;

float toGrey(in Color col)
{
	return col.r*0.21f + col.g*0.71f + col.b*0.07f;
}
