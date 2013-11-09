module dquick.maths.color;

import gl3n.linalg;

alias Vector!(float, 4) Color;

float toGrey(in Color col)
{
	return (col.r + col.g + col.b) / 3.0f;
}
