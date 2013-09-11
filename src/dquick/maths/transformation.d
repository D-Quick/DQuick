module dquick.maths.transformation;

//import gl3n.linalg;

public import dquick.maths.vector3f32;
public import dquick.maths.matrix4x4;
public import dquick.maths.quaternion;

struct Transformation
{
public:
	Vector3f32	origin = Vector3f32(0.0f, 0.0f, 0.0f);	/// Origin of orientation tranformation
	Vector3f32	position = Vector3f32(0.0f, 0.0f, 0.0f);
	Vector3f32	scaling = Vector3f32(1.0f, 1.0f, 1.0f);
	Quaternion	orientation = Quaternion.identity();

	Matrix4x4	toMatrix()
	{
		Matrix4x4	matrix;

		matrix.make_identity();

		matrix.translate(position.x, position.y, position.z);

		matrix.translate(-origin.x, -origin.y, -origin.z);

		matrix = orientation.to_matrix!(4, 4) * matrix;
		matrix.scale(scaling.x, scaling.y, scaling.z);

		matrix.translate(origin.x, origin.y, origin.z);

		return matrix;
	}
}
