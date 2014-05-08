module dquick.renderer3D.generic;

enum VBOType
{
	Indexes,
	Geometry
}

enum VBOMode
{
	Static,
	Dynamic
}

enum PrimitiveType
{
	Points,
	LineStrip,
	LineLoop,
	Lines,
	TriangleStrip,
	TriangleFan,
	Triangles,
	QuadStrip,
	Quads,
	Polygon
}

enum ParameterType
{
	Int,
	Float,
	Float2D,
	Matrix4f,
}
