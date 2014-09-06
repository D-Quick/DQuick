module dquick.item.graphicItem;

public import dquick.item.declarativeItem;
public import dquick.maths.vector2f32;
public import dquick.maths.vector4f32;
public import dquick.maths.transformation;
public import dquick.maths.color;

import dquick.renderer3D.all;

import std.stdio;
import std.math;
import std.variant;

import dquick.script.itemBinding;

// TODO Verifier la gestion des matrices, j'ai un doute sur la bonne application/restoration des transformation (Je crains que la matrice de la camera soit ecrasee)

/// Interface for items that can be renderer or have some geometrical properties
class GraphicItem : DeclarativeItem
{
	mixin(dquick.script.itemBinding.I_ITEM_BINDING);

public:
	this(DeclarativeItem parent = null)
	{
		super(parent);
		visibleProperty = new typeof(visibleProperty)(this, this);
		xProperty = new typeof(xProperty)(this, this);
		yProperty = new typeof(yProperty)(this, this);
		widthProperty = new typeof(widthProperty)(this, this);
		heightProperty = new typeof(heightProperty)(this, this);
		implicitWidthProperty = new typeof(implicitWidthProperty)(this, this);
		implicitHeightProperty = new typeof(implicitHeightProperty)(this, this);
		clipProperty = new typeof(clipProperty)(this, this);
		scaleProperty = new typeof(scaleProperty)(this, this);
		orientationProperty = new typeof(orientationProperty)(this, this);

		mTransformationUpdated = true;	// Override default value of DeclarativeItem
	}

	// visible
	dquick.script.nativePropertyBinding.NativePropertyBinding!(bool, GraphicItem, "visible")	visibleProperty;
	void	visible(bool visible)
	{
		if (visible == mVisible)
			return;
		mVisible = visible;
		onVisibleChanged.emit(visible);
	}
	bool	visible() {return mVisible;}
	mixin Signal!(bool) onVisibleChanged;

	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, GraphicItem, "x")	xProperty;
	void	x(float x)
	{
		if (x == mTransformation.position.x)
			return;
		mTransformation.position.x = x;
		mTransformationUpdated = true;
		onXChanged.emit(x);
	}
	float	x() {return mTransformation.position.x;}
	mixin Signal!(float) onXChanged;

	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, GraphicItem, "y")	yProperty;
	void	y(float y)
	{
		if (y == mTransformation.position.y)
			return;
		mTransformation.position.y = y;
		mTransformationUpdated = true;
		onYChanged.emit(y);
	}
	float	y() {return mTransformation.position.y;}
	mixin Signal!(float) onYChanged;

	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, GraphicItem, "width")	widthProperty;
	void	width(float width)
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
	float	width() {return mSize.x;}
	mixin Signal!(float) onWidthChanged;

	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, GraphicItem, "height")	heightProperty;
	void	height(float height)
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
	float	height() {return mSize.y;}
	mixin Signal!(float) onHeightChanged;

	/// Return the natural width of the GraphicItem
	/// The default implicit width for most items is float.nan, however some items have an inherent implicit width which cannot be overridden, e.g. Image, Text.
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, GraphicItem, "implicitWidth")	implicitWidthProperty;
	float	implicitWidthBinding() {return float.nan;}
	void	implicitWidth(float) {}
	float	implicitWidth() {return float.nan;}
	mixin Signal!(float) onImplicitWidthChanged;

	/// Return the natural height of the GraphicItem
	/// The default implicit height for most items is float.nan, however some items have an inherent implicit height which cannot be overridden, e.g. Image, Text.
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, GraphicItem, "implicitHeight")	implicitHeightProperty;
	float	implicitHeightBinding() {return float.nan;}
	void	implicitHeight(float) {}
	float	implicitHeight() {return float.nan;}
	mixin Signal!(float) onImplicitHeightChanged;

	/// Put it to true to clip parts of item that are out of his rectangle (determined by his size)
	/// It's implemented with a scissor, so don't use it with rotations
	dquick.script.nativePropertyBinding.NativePropertyBinding!(bool, GraphicItem, "clip")	clipProperty;
	void	clip(bool flag)
	{
		if (flag == mClip)
			return;
		mClip = flag;
		onClipChanged.emit(flag);
	}
	bool	clip() {return mClip;}
	mixin Signal!(bool) onClipChanged;

	/// Change the scale factor, tranformation origin is the center of item
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, GraphicItem, "scale")	scaleProperty;
	void	scale(float value)
	{
		if (value == mTransformation.scaling.y)
			return;
		mTransformation.scaling.x = value;
		mTransformation.scaling.y = value;
		mTransformationUpdated = true;
		onScaleChanged.emit(value);
	}
	float	scale() {return mTransformation.scaling.x;}
	mixin Signal!(float) onScaleChanged;

	/// Change the orientation angle in degrees clockwise, tranformation origin is the center of item
	dquick.script.nativePropertyBinding.NativePropertyBinding!(float, GraphicItem, "orientation")	orientationProperty;
	void	orientation(float value)
	{
		if (mOrientation == value)
			return;
		mOrientation = value;
		mTransformationUpdated = true;
		mTransformation.orientation = Quaternion.zrotation((value % 360.0) / 180 * std.math.PI);
		onOrientationChanged.emit(value);
	}
	float	orientation() {return mOrientation;}
	mixin Signal!(float) onOrientationChanged;

	override
	void	paint(bool transformationUpdated)
	{
		if (!mVisible)
			return;
		startPaint(transformationUpdated);
		paintChildren();
		endPaint();
	}

	override
	void	release()
	{
		debug
		{
			mDebugMesh.destruct();
			mDebugMesh = null;
			mDebugImplicitMesh.destruct();
			mDebugImplicitMesh = null;
		}
		super.release();
	}

	/// Color will be used to draw the rectangle that represent the GraphicItem's size
	void	debugMeshColor(Color color)
	{
		debug
		{
			mRebuildDebugMeshes = true;
			mDebugMeshColor = color;
			onDebugMeshColorChanged.emit(color);
		}
	}
	Color	debugMeshColor()
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
	void	debugImplicitMeshColor(Color color)
	{
		debug
		{
			mRebuildDebugMeshes = true;
			mDebugImplicitMeshColor = color;
			onDebugImplicitMeshColorChanged.emit(color);
		}
	}
	Color	debugImplicitMeshColor()
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
		mTransformationUpdated = transformationUpdated | mTransformationUpdated;	// Don't alter mTransformationUpdated if already true
		
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

			pos = mMatrix * pos;
			size = mMatrix * size;

			float	invertedY = Renderer.viewportSize().y - pos.y - size.y;

			Renderer.startScissor(cast(int)round(pos.x), cast(int)round(invertedY), cast(int)round(size.x), cast(int)round(size.y));
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
			Renderer.endScissor();
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

			Variant[] options;
			options ~= Variant(import("color.vert"));
			options ~= Variant(import("color.frag"));
			mDebugShader = Renderer.resourceManager.getResource!Shader("color", options);
			mDebugShaderProgram = cast(ShaderProgram)mDebugShader.getProgram();

			// Size
			mDebugMesh = new Mesh;
			mDebugMesh.construct();
			mDebugMesh.setShader(mDebugShader);
			mDebugMesh.setShaderProgram(mDebugShaderProgram);
			mDebugMesh.setPrimitiveType(PrimitiveType.LineLoop);

			mDebugMesh.indexes.setArray(cast(uint[])[0, 1, 2, 3], VBOMode.Static);
			mDebugMesh.geometry.setArray(debugMeshGeometryArray(), VBOMode.Dynamic);

			// ImplicitSize
			mDebugImplicitMesh = new Mesh;
			mDebugImplicitMesh.construct();
			mDebugImplicitMesh.setShader(mDebugShader);
			mDebugImplicitMesh.setShaderProgram(mDebugShaderProgram);
			mDebugImplicitMesh.setPrimitiveType(PrimitiveType.LineLoop);

			mDebugImplicitMesh.indexes.setArray(cast(uint[])[0, 1, 2, 3], VBOMode.Static);
			mDebugImplicitMesh.geometry.setArray(debugImplicitMeshGeometryArray(), VBOMode.Dynamic);

			mRebuildDebugMeshes = false;
		}

		void	updateDebugMesh()
		{
			createDebugMeshes();	// TODO find a way to avoid update just after creation

			mDebugMesh.geometry.updateArray(debugMeshGeometryArray());
			mDebugImplicitMesh.geometry.updateArray(debugImplicitMeshGeometryArray());

			mRebuildDebugMeshes = false;
		}
	}

	debug
	{
		float[]	debugMeshGeometryArray()
		{
			return [
				0.0f,		0.0f,		0.0f,		mDebugMeshColor.x, mDebugMeshColor.y, mDebugMeshColor.z, mDebugMeshColor.w,
				mSize.x,	0.0f,		0.0f,		mDebugMeshColor.x, mDebugMeshColor.y, mDebugMeshColor.z, mDebugMeshColor.w,
				mSize.x,	mSize.y,	0.0f,		mDebugMeshColor.x, mDebugMeshColor.y, mDebugMeshColor.z, mDebugMeshColor.w,
				0.0f,		mSize.y,	0.0f,		mDebugMeshColor.x, mDebugMeshColor.y, mDebugMeshColor.z, mDebugMeshColor.w];
		}

		float[]	debugImplicitMeshGeometryArray()
		{
			return [
				0.0f,			0.0f,			0.0f,		mDebugImplicitMeshColor.x, mDebugImplicitMeshColor.y, mDebugImplicitMeshColor.z, mDebugImplicitMeshColor.w,
				implicitWidth,	0.0f,			0.0f,		mDebugImplicitMeshColor.x, mDebugImplicitMeshColor.y, mDebugImplicitMeshColor.z, mDebugImplicitMeshColor.w,
				implicitWidth,	implicitHeight,	0.0f,		mDebugImplicitMeshColor.x, mDebugImplicitMeshColor.y, mDebugImplicitMeshColor.z, mDebugImplicitMeshColor.w,
				0.0f,			implicitHeight,	0.0f,		mDebugImplicitMeshColor.x, mDebugImplicitMeshColor.y, mDebugImplicitMeshColor.z, mDebugImplicitMeshColor.w];
		}
	}

	bool			mVisible = true;
	bool			mClip = false;
	Transformation	mTransformation;
	Vector2f32		mSize = Vector2f32(0, 0);
	float			mOrientation = 0.0f;

	debug
	{
		bool			mRebuildDebugMeshes = true;
		Color			mDebugMeshColor = Color(0.0f, 1.0f, 0.0f, 1.0f);
		Mesh			mDebugMesh;
		Color			mDebugImplicitMeshColor = Color(0.0f, 1.0f, 0.0f, 1.0f);
		Mesh			mDebugImplicitMesh;
		Shader			mDebugShader;
		ShaderProgram	mDebugShaderProgram;
	}
}
