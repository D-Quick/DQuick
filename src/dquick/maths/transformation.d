module dquick.maths.transformation;

//import gl3n.linalg;

public import dquick.maths.vector3f32;
public import dquick.maths.matrix4x4;
public import dquick.maths.quaternion;

struct Transformation
{
public:
	Vector3f32	origin = Vector3f32(0.0f, 0.0f, 0.0f);	/// Origin of rotation tranformation
	Vector3f32	position = Vector3f32(0.0f, 0.0f, 0.0f);
	Vector3f32	scaling = Vector3f32(1.0f, 1.0f, 1.0f);
	Quaternion	rotation = Quaternion.identity();

	Matrix4x4	toMatrix()
	{
		Matrix4x4	matrix;

		matrix.make_identity();

		matrix.scale(scaling.x, scaling.y, scaling.z);
		matrix.translate(position.x + origin.x, position.y + origin.y, position.z + origin.z);
		matrix = matrix * rotation.to_matrix!(4, 4);
		return matrix;
	}
}
