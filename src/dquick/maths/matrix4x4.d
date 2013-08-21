module dquick.maths.matrix4x4;

import gl3n.linalg;

/// Row-Major matrix
alias Matrix!(float, 4, 4) Matrix4x4;

@safe
pure Matrix4x4	switchMatrixRowsColumns(Matrix4x4 matrix)
{
	Matrix4x4	result;

	result[0][0] = matrix[0][0];
	result[0][1] = matrix[1][0];
	result[0][2] = matrix[2][0];
	result[0][3] = matrix[3][0];
	result[1][0] = matrix[0][1];
	result[1][1] = matrix[1][1];
	result[1][2] = matrix[2][1];
	result[1][3] = matrix[3][1];
	result[2][0] = matrix[0][2];
	result[2][1] = matrix[1][2];
	result[2][2] = matrix[2][2];
	result[2][3] = matrix[3][2];
	result[3][0] = matrix[0][3];
	result[3][1] = matrix[1][3];
	result[3][2] = matrix[2][3];
	result[3][3] = matrix[3][3];

	return result;
}
