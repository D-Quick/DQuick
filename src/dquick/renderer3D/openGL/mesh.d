module dquick.renderer3D.openGL.mesh;

import dquick.renderer3D.openGL.renderer;
import dquick.renderer3D.openGL.texture;
import dquick.renderer3D.openGL.shader;
import dquick.renderer3D.openGL.shaderProgram;
import dquick.renderer3D.openGL.VBO;
import dquick.renderer3D.openGL.util;
import dquick.renderer3D.openGL.renderer;

import dquick.maths.color;

import dquick.media.image;

import dquick.utils.utils;

import derelict.opengl3.gl;

import std.stdio;
import std.variant;

import core.runtime;

/*
Mettre les VBO en interleaved et sur le mesh ajouter une propriété pour savoir s'ils sont dynamique ou pas.
Les textes sont par exemple statique (car je les rebuild complètement si on modifie une propriété comme la taille) et peuvent du coup entre rendu en même temps s'ils ne se chevauchent pas ce qui est courant, surtout qu'ils partagent généralement la même texture grâce a l'atlas.
*/


// TODO check an attribut with id 0 is always send for the shader (else some drivers have issues)

struct Mesh
{
public:
	enum PrimitiveType
	{
		Points = GL_POINTS,
		LineStrip = GL_LINE_STRIP,
		LineLoop = GL_LINE_LOOP,
		Lines = GL_LINES,
		TriangleStrip = GL_TRIANGLE_STRIP,
		TriangleFan = GL_TRIANGLE_FAN,
		Triangles = GL_TRIANGLES,
		QuadStrip = GL_QUAD_STRIP,
		Quads = GL_QUADS,
		Polygon = GL_POLYGON
	}

	~this()
	{
		debug destructorAssert(vertices is null, "Mesh.destruct method wasn't called.", mTrace);
	}

	bool	setTexture(string filePath)
	{
		mTexture = dquick.renderer3D.openGL.renderer.resourceManager.getResource!Texture(filePath);
		return true;
	}
	bool	setTexture(Image image)
	{
		Variant[] options;
		options ~= Variant(image);
		mTexture = dquick.renderer3D.openGL.renderer.resourceManager.getResource!Texture(image.filePath(), options);
		return true;
	}
	bool	setTexture(Texture texture)
	{
		mTexture = texture;
		return true;
	}
	Texture	texture() {return mTexture;}

	void	setShader(Shader shader)
	{
		mShader = shader;

		mPositionAttribute = checkgl!glGetAttribLocation(mShader.getProgram(), cast(char*)("a_position"));
		mColorAttribute = checkgl!glGetAttribLocation(mShader.getProgram(), cast(char*)("a_color"));
		mTexcoordAttribute = checkgl!glGetAttribLocation(mShader.getProgram(), cast(char*)("a_texcoord"));
		mTextureUniform = checkgl!glGetUniformLocation(mShader.getProgram(), cast(char*)("u_texture"));
		mMDVMatrixUniform = checkgl!glGetUniformLocation(mShader.getProgram(), cast(char*)("u_modelViewProjectionMatrix"));
	}
	Shader	shader() {return mShader;}

	void			setShaderProgram(ShaderProgram program) {mShaderProgram = program;}
	ShaderProgram	shaderProgram() {return mShaderProgram;}

	VBO!GLuint		indexes = null;
	VBO!GLfloat		vertices = null;
	VBO!GLfloat		colors = null;
	VBO!GLfloat		texCoords = null;
	PrimitiveType	primitiveType = PrimitiveType.Triangles;		/// Default type is Triangles

	void	draw()
	{
		if (mShader)
		{
			mShaderProgram.execute();

			// TODO use parameter on mShaderProgram instead
			glUniformMatrix4fv(mMDVMatrixUniform, 1, false, Renderer.currentMDVMatrix.value_ptr);
		}

		// bind the texture and set the "tex" uniform in the fragment shader
		if (mTexture)
		{
			checkgl!glActiveTexture(GL_TEXTURE0);
			checkgl!glBindTexture(GL_TEXTURE_2D, mTexture.id());
			checkgl!glUniform1i(mTextureUniform, 0); //set to 0 because the texture is bound to GL_TEXTURE0
		}

		// Can be in a VAO
		{
			indexes.bind();
			vertices.bind();
			checkgl!glEnableVertexAttribArray(mPositionAttribute);
			checkgl!glVertexAttribPointer(mPositionAttribute, 3, GL_FLOAT, GL_FALSE, cast(GLsizei)(3 * GLfloat.sizeof), null + cast(GLvoid*)(0 * GLfloat.sizeof));
			colors.bind();
			checkgl!glEnableVertexAttribArray(mColorAttribute);
			checkgl!glVertexAttribPointer(mColorAttribute, 4, GL_FLOAT, GL_FALSE, cast(GLsizei)(4 * GLfloat.sizeof), null + cast(GLvoid*)(0 * GLfloat.sizeof));
			if (mTexture)
			{
				texCoords.bind();
				checkgl!glEnableVertexAttribArray(mTexcoordAttribute);
				checkgl!glVertexAttribPointer(mTexcoordAttribute, 2, GL_FLOAT, GL_FALSE, cast(GLsizei)(2 * GLfloat.sizeof), null + cast(GLvoid*)(0 * GLfloat.sizeof));
			}
		}

		// draw the VBOs
		checkgl!glDrawElements(primitiveType, cast(GLsizei)indexes.length, GL_UNSIGNED_INT, null);
		checkgl!glDisableVertexAttribArray(mPositionAttribute);
		checkgl!glDisableVertexAttribArray(mColorAttribute);
		if (mTexture)
			checkgl!glDisableVertexAttribArray(mTexcoordAttribute);

		// unbind VBOs, the program and the texture
		indexes.unbind();	// One unbind per type
		vertices.unbind();	// One unbind per type
		checkgl!glBindTexture(GL_TEXTURE_2D, mBadId);
		checkgl!glBindBuffer(GL_ARRAY_BUFFER, mBadId);
		checkgl!glUseProgram(mBadId);
	}

	void	construct()
	{
		debug mTrace = defaultTraceHandler(null);

		destruct();
		indexes = new VBO!GLuint(cast(GLenum)GL_ELEMENT_ARRAY_BUFFER);
		vertices = new VBO!GLfloat(cast(GLenum)GL_ARRAY_BUFFER);
		colors = new VBO!GLfloat(cast(GLenum)GL_ARRAY_BUFFER);
		texCoords = new VBO!GLfloat(cast(GLenum)GL_ARRAY_BUFFER);
	}

	void	destruct()
	{
		if (indexes)
		{
			indexes.unload();
			indexes = null;
			vertices.unload();
			vertices = null;
			colors.unload();
			colors = null;
			texCoords.unload();
			texCoords = null;
		}
		if (mTexture)
		{
			dquick.renderer3D.openGL.renderer.resourceManager.releaseResource(mTexture);
			mTexture = null;
		}
		if (mShader)
		{
			dquick.renderer3D.openGL.renderer.resourceManager.releaseResource(mShader);
			mShader = null;
		}
	}

private:
	static const GLuint		mBadId = 0;

	GLint					mPositionAttribute;
	GLint					mColorAttribute;
	GLint					mTexcoordAttribute;
	GLint					mTextureUniform;
	GLint					mMDVMatrixUniform;

	Shader					mShader;
	ShaderProgram			mShaderProgram;
	Texture					mTexture;			// TODO move to Material

	debug Throwable.TraceInfo	mTrace;
}
