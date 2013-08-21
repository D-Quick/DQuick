module dquick.maths.vector4f32;

import dquick.maths.vector3f32;

import gl3n.linalg;

//alias Vector!(float, 3) Vector3f32;

struct Vector4f32
{
	this(float x, float y, float z, float w)
	{
		vec.x = x;
		vec.y = y;
		vec.z = z;
		vec.w = w;
	}

	this(Vector3f32 vec3)
	{
		vec.x = vec3.x;
		vec.y = vec3.y;
		vec.z = vec3.z;
		vec.w = 1.0f;
	}

	Vector!(float, 4)	vec;
	alias vec	this;
}
