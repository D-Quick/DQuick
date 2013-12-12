module dquick.item.graphicItem;

public import dquick.item.declarativeItem;
public import dquick.maths.vector2f32;
public import dquick.maths.vector4f32;
public import dquick.maths.transformation;
public import dquick.maths.color;

public import dquick.renderer3D.openGL.renderer;
import dquick.renderer3D.openGL.mesh;
import dquick.renderer3D.openGL.shader;
import dquick.renderer3D.openGL.shaderProgram;

public import std.signals;
import std.stdio;
import std.math;
import std.variant;

// TODO Verifier la gestion des matrices, j'ai un doute sur la bonne application/restoration des transformation (Je crains que la matrice de la camera soit ecrasee)

/// Interface for items that can be renderer or have some geometrical properties
class GraphicItem : DeclarativeItem
{
public:
	this(DeclarativeItem parent = null)
	{
		super(parent);
		mSize = Vector2f32(0, 0);
		mTransformationUpdated = true;
		debug
		{
			mRebuildDebugMeshes = true;
			mDebugMeshColor = [0.0f, 1.0f, 0.0f, 1.0f];
			mDebugImplicitMeshColor = [0.0f, 1.0f, 0.0f, 1.0f];
		}
	}

	@property void	x(float x)
	{
		if (x == mTransformation.position.x)
			return;
		mTransformation.position.x = x;
		mTransformationUpdated = true;
		onXChanged.emit(x);
	}
	@property float	x() {return mTransformation.position.x;}
	mixin Signal!(float) onXChanged;

	@property void	y(float y)
	{
		if (y == mTransformation.position.y)
			return;
		mTransformation.position.y = y;
		mTransformationUpdated = true;
		onYChanged.emit(y);
	}
	@property float	y() {return mTransformation.position.y;}
	mixin Signal!(float) onYChanged;

	/// Have to be called only on rootItem by window
	void	setSize(Vector2f32 size)
	{
		if (size == mSize)
			return;
		mSize = size;
		mTransformation.origin.x = mSize.x / 2.0f;
		mTransformation.origin.y = mSize.y / 2.0f;
		mTransformationUpdated = true;
		onWidthChanged.emit(mSize.x);
		onHeightChanged.emit(mSize.y);

		debug
		{
			mRebuildDebugMeshes = true;
		}
	}

	@property void	width(float width)
	{
		if (width == mSize.x)
			return;
		mSize.x = width;
		mTransformation.origin.x = mSize.x / 2.0f;
		mTransformationUpdated = true;
		onWidthChanged.emit(width);

		debug
		{
			mRebuildDebugMeshes = true;
		}
	}
	@property float	width() {return mSize.x;}
	mixin Signal!(float) onWidthChanged;

	@property void	height(float height)
	{
		if (height == mSize.y)
			return;
		mSize.y = height;
		mTransformation.origin.y = mSize.y / 2.0f;
		mTransformationUpdated = true;
		onHeightChanged.emit(height);

		debug
		{
			mRebuildDebugMeshes = true;
		}
	}
	@property float	height() {return mSize.y;}
	mixin Signal!(float) onHeightChanged;

	/// Return the natural width of the GraphicItem
	/// The default implicit width for most items is float.nan, however some items have an inherent implicit width which cannot be overridden, e.g. Image, Text.
	@property float	implicitWidth() {return float.nan;}
	mixin Signal!(float) onImplicitWidthChanged;

	/// Return the natural height of the GraphicItem
	/// The default implicit height for most items is float.nan, however some items have an inherent implicit height which cannot be overridden, e.g. Image, Text.
	@property float	implicitHeight() {return float.nan;}
	mixin Signal!(float) onImplicitHeightChanged;

	/// Put it to true to clip parts of item that are out of his rectangle (determined by his size)
	/// It's implemented with a scissor, so don't use it with rotations
	@property void	clip(bool flag)
	{
		if (flag == mClip)
			return;
		mClip = flag;
		onClipChanged.emit(flag);
	}
	@property bool	clip() {return mClip;}
	mixin Signal!(bool) onClipChanged;

	/// Change the scale factor, tranformation origin is the center of item
	@property void	scale(float value)
	{
		if (value == mTransformation.scaling.y)
			return;
		mTransformation.scaling.x = value;
		mTransformation.scaling.y = value;
		mTransformationUpdated = true;
		onScaleChanged.emit(value);
	}
	@property float	scale() {return mTransformation.scaling.x;}
	mixin Signal!(float) onScaleChanged;

	/// Change the orientation angle in degrees clockwise, tranformation origin is the center of item
	@property void	orientation(float value)
	{
		if (mOrientation == value)
			return;
		mOrientation = value;
		mTransformationUpdated = true;
		mTransformation.orientation = Quaternion.zrotation((value % 360.0) / 180 * std.math.PI);
		onOrientationChanged.emit(value);
	}
	@property float	orientation() {return mOrientation;}
	mixin Signal!(float) onOrientationChanged;

	override
	void	paint(bool transformationUpdated)
	{
		startPaint(transformationUpdated);
		paintChildren();
		endPaint();
	}

	/// Color will be used to draw the rectangle that represent the GraphicItem's size
	@property void	debugMeshColor(Color color)
	{
		debug
		{
			mRebuildDebugMeshes = true;
			mDebugMeshColor = color;
			onDebugMeshColorChanged.emit(color);
		}
	}
	@property Color	debugMeshColor()
	{
		debug
		{
			return mDebugMeshColor;
		}
		else
		{
			return Color();
		}
	}
	mixin Signal!(Color) onDebugMeshColorChanged;

	/// Color will be used to draw the rectangle that represent the GraphicItem's implicitSize
	@property void	debugImplicitMeshColor(Color color)
	{
		debug
		{
			mRebuildDebugMeshes = true;
			mDebugImplicitMeshColor = color;
			onDebugImplicitMeshColorChanged.emit(color);
		}
	}
	@property Color	debugImplicitMeshColor()
	{
		debug
		{
			return mDebugImplicitMeshColor;
		}
		else
		{
			return Color();
		}
	}
	mixin Signal!(Color) onDebugImplicitMeshColorChanged;

protected:
	void	startPaint(bool transformationUpdated)
	{
		if (transformationUpdated)
			mTransformationUpdated = true;
		
		if (mTransformationUpdated)
		{
			if (parent())
				mMatrix = parent().matrix() * mTransformation.toMatrix();
			else
				mMatrix = mTransformation.toMatrix();
		}

		Renderer.currentMDVMatrix(switchMatrixRowsColumns(Renderer.currentCamera * mMatrix));

		if (mClip)	// TODO move that to the renderer (no gl commands have to be used here)
		{
			Vector4f32	pos = Vector4f32(x, y, 0.0f, 0.0f);
			Vector4f32	size = Vector4f32(width, height, 0.0f, 0.0f);

			glEnable(GL_SCISSOR_TEST);

			pos = mMatrix * pos;
			size = mMatrix * size;

			float	invertedY = Renderer.viewportSize().y - pos.y - size.y;

			glScissor(cast(int)round(pos.x), cast(int)round(invertedY), cast(int)round(size.x), cast(int)round(size.y));
		}

		debug
		{
			if (mRebuildDebugMeshes)
				updateDebugMesh();
			mDebugMesh.draw();
			if ((implicitWidth != float.nan && implicitHeight != float.nan)
				&& (implicitWidth != mSize.x && implicitHeight != mSize.y))
				mDebugImplicitMesh.draw();
		}
	}

	void	endPaint()
	{
		mTransformationUpdated = false;
		if (mClip)
			glDisable(GL_SCISSOR_TEST);
	}

	bool	isIn(Vector2f32 point)
	{
		assert(false);
		version(release)
		return false;
	}

	debug
	{
		void	createDebugMeshes()	// Safe to call it if mesh is already created
		{
			if (mDebugMesh)
				return;

			mDebugShaderProgram = new ShaderProgram();

			Variant[] options;
			options ~= Variant(import("color.vert"));
			options ~= Variant(import("color.frag"));
			mDebugShader = dquick.renderer3D.openGL.renderer.resourceManager.getResource!Shader("color", options);
			mDebugShaderProgram.setProgram(mDebugShader.getProgram());

			// Size
			mDebugMesh = new Mesh();
			mDebugMesh.setShader(mDebugShader);
			mDebugMesh.setShaderProgram(mDebugShaderProgram);
			mDebugMesh.primitiveType = Mesh.PrimitiveType.LineLoop;

			mDebugMesh.indexes.setArray(cast(GLuint[])[0, 1, 2, 3],
								   cast(GLenum)GL_ELEMENT_ARRAY_BUFFER, cast(GLenum)GL_STATIC_DRAW);

			mDebugMesh.vertices.setArray(cast(GLfloat[])[
				0.0f,		0.0f,		0.0f,
				mSize.x,	0.0f,		0.0f,
				mSize.x,	mSize.y,	0.0f,
				0.0f,		mSize.y,	0.0f],
											cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_DYNAMIC_DRAW);

			mDebugMesh.colors.setArray(cast(GLfloat[])[
				mDebugMeshColor.x, mDebugMeshColor.y, mDebugMeshColor.z, mDebugMeshColor.w,
				mDebugMeshColor.x, mDebugMeshColor.y, mDebugMeshColor.z, mDebugMeshColor.w,
				mDebugMeshColor.x, mDebugMeshColor.y, mDebugMeshColor.z, mDebugMeshColor.w,
				mDebugMeshColor.x, mDebugMeshColor.y, mDebugMeshColor.z, mDebugMeshColor.w],
										  cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_DYNAMIC_DRAW);

			// ImplicitSize
			mDebugImplicitMesh = new Mesh();
			mDebugImplicitMesh.setShader(mDebugShader);
			mDebugImplicitMesh.setShaderProgram(mDebugShaderProgram);
			mDebugImplicitMesh.primitiveType = Mesh.PrimitiveType.LineLoop;

			mDebugImplicitMesh.indexes.setArray(cast(GLuint[])[0, 1, 2, 3],
										cast(GLenum)GL_ELEMENT_ARRAY_BUFFER, cast(GLenum)GL_STATIC_DRAW);

			mDebugImplicitMesh.vertices.setArray(cast(GLfloat[])[
				0.0f,			0.0f,			0.0f,
				implicitWidth,	0.0f,			0.0f,
				implicitWidth,	implicitHeight,	0.0f,
				0.0f,			implicitHeight,	0.0f],
										 cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_DYNAMIC_DRAW);

			mDebugImplicitMesh.colors.setArray(cast(GLfloat[])[
				mDebugImplicitMeshColor.x, mDebugImplicitMeshColor.y, mDebugImplicitMeshColor.z, mDebugImplicitMeshColor.w,
				mDebugImplicitMeshColor.x, mDebugImplicitMeshColor.y, mDebugImplicitMeshColor.z, mDebugImplicitMeshColor.w,
				mDebugImplicitMeshColor.x, mDebugImplicitMeshColor.y, mDebugImplicitMeshColor.z, mDebugImplicitMeshColor.w,
				mDebugImplicitMeshColor.x, mDebugImplicitMeshColor.y, mDebugImplicitMeshColor.z, mDebugImplicitMeshColor.w],
									   cast(GLenum)GL_ARRAY_BUFFER, cast(GLenum)GL_DYNAMIC_DRAW);

			mRebuildDebugMeshes = false;
		}

		void	updateDebugMesh()
		{
			createDebugMeshes();	// TODO find a way to avoid update just after creation

			// Size
			mDebugMesh.vertices.updateArray(cast(GLfloat[])[
				0.0f,		0.0f,		0.0f,
				mSize.x,	0.0f,		0.0f,
				mSize.x,	mSize.y,	0.0f,
				0.0f,		mSize.y,	0.0f]);

			mDebugMesh.colors.updateArray(cast(GLfloat[])[
				mDebugMeshColor.x, mDebugMeshColor.y, mDebugMeshColor.z, mDebugMeshColor.w,
				mDebugMeshColor.x, mDebugMeshColor.y, mDebugMeshColor.z, mDebugMeshColor.w,
				mDebugMeshColor.x, mDebugMeshColor.y, mDebugMeshColor.z, mDebugMeshColor.w,
				mDebugMeshColor.x, mDebugMeshColor.y, mDebugMeshColor.z, mDebugMeshColor.w]);

			// ImplicitSize
			mDebugImplicitMesh.vertices.updateArray(cast(GLfloat[])[
				0.0f,			0.0f,			0.0f,
				implicitWidth,	0.0f,			0.0f,
				implicitWidth,	implicitHeight,	0.0f,
				0.0f,			implicitHeight,	0.0f]);

			mDebugImplicitMesh.colors.updateArray(cast(GLfloat[])[
				mDebugImplicitMeshColor.x, mDebugImplicitMeshColor.y, mDebugImplicitMeshColor.z, mDebugImplicitMeshColor.w,
				mDebugImplicitMeshColor.x, mDebugImplicitMeshColor.y, mDebugImplicitMeshColor.z, mDebugImplicitMeshColor.w,
				mDebugImplicitMeshColor.x, mDebugImplicitMeshColor.y, mDebugImplicitMeshColor.z, mDebugImplicitMeshColor.w,
				mDebugImplicitMeshColor.x, mDebugImplicitMeshColor.y, mDebugImplicitMeshColor.z, mDebugImplicitMeshColor.w]);

			mRebuildDebugMeshes = false;
		}
	}

	bool			mClip = false;
	Transformation	mTransformation;
	Vector2f32		mSize;
	float			mOrientation = 0.0f;

	debug
	{
		bool			mRebuildDebugMeshes;
		Color			mDebugMeshColor;
		Mesh			mDebugMesh;
		Color			mDebugImplicitMeshColor;
		Mesh			mDebugImplicitMesh;
		Shader			mDebugShader;
		ShaderProgram	mDebugShaderProgram;
	}
}
