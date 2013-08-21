module dquick.maths.vector3f32;

import dquick.maths.vector4f32;

import gl3n.linalg;

//alias Vector!(float, 3) Vector3f32;

struct Vector3f32
{
	this(float x, float y, float z)
	{
		vec.x = x;
		vec.y = y;
		vec.z = z;
	}

	this(Vector!(float, 4) vec4)
	{
		float	div = vec4.w;

		if (div == 0.0f)
			div = float.min_normal;

		vec.x = vec4.x / div;
		vec.y = vec4.y / div;
		vec.z = vec4.z / div;
	}

	Vector!(float, 3)	vec;
	alias vec	this;
}
