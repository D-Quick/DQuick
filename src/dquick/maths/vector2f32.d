module dquick.maths.vector2f32;

import dquick.maths.vector2s32;

import gl3n.linalg;

struct Vector2f32
{
	this(float x, float y)
	{
		vec.x = x;
		vec.y = y;
	}

	this(Vector2s32 vec2)
	{
		vec.x = vec2.x;
		vec.y = vec2.y;
	}

	Vector!(float, 2)	vec;
	alias vec	this;
}
