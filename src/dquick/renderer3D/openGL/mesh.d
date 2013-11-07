module dquick.renderer3D.opengl.mesh;

import dquick.renderer3D.opengl.renderer;
import dquick.renderer3D.opengl.texture;
import dquick.renderer3D.opengl.shader;
import dquick.renderer3D.opengl.shaderProgram;
import dquick.renderer3D.opengl.vbo;
import dquick.renderer3D.opengl.util;
import dquick.renderer3D.opengl.renderer;

import dquick.maths.color;

import dquick.media.image;

import derelict.opengl3.gl;

import std.stdio;
import std.variant;

class Mesh
{
public:
	this()
	{
		create();

		indexes = new VBO!GLuint();
		vertices = new VBO!GLfloat();
		colors = new VBO!GLfloat();
		texCoords = new VBO!GLfloat();
	}

	~this()
	{
		destroy();
	}

	bool	setTexture(string filePath)
	{
		mTexture = dquick.renderer3D.opengl.renderer.resourceManager.getResource!Texture(filePath);
		return true;
	}
	bool	setTexture(Image image)
	{
		Variant[] options;
		options ~= Variant(image);
		mTexture = dquick.renderer3D.opengl.renderer.resourceManager.getResource!Texture(image.filePath(), options);
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

	VBO!GLuint		indexes;
	VBO!GLfloat		vertices;
	VBO!GLfloat		colors;
	VBO!GLfloat		texCoords;

	void	draw()
	{
/*		checkgl!glUseProgram(mShader.getProgram);

		glUniformMatrix4fv(mMDVInvertedMatrixUniform, 1, false, (Renderer.currentCamera().inverse() * Renderer.currentMDVMatrix).inverse().value_ptr);*/

		mShaderProgram.execute();

		glUniformMatrix4fv(mMDVMatrixUniform, 1, false, Renderer.currentMDVMatrix.value_ptr);

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
			texCoords.bind();
			checkgl!glEnableVertexAttribArray(mTexcoordAttribute);
			checkgl!glVertexAttribPointer(mTexcoordAttribute, 2, GL_FLOAT, GL_FALSE, cast(GLsizei)(2 * GLfloat.sizeof), null + cast(GLvoid*)(0 * GLfloat.sizeof));
		}

		// draw the VBOs
		checkgl!glDrawElements(GL_TRIANGLES, cast(GLsizei)indexes.length, GL_UNSIGNED_INT, null);

		// unbind VBOs, the program and the texture
		indexes.unbind();	// One unbind per type
		vertices.unbind();	// One unbind per type
		checkgl!glBindTexture(GL_TEXTURE_2D, mBadId);
		checkgl!glBindBuffer(GL_ARRAY_BUFFER, mBadId);
		checkgl!glUseProgram(mBadId);
	}

private:
	void	create()
	{
/*		Variant[] options;

		options ~= Variant(import("rectangle.vert"));
		options ~= Variant(import("rectangle.frag"));
		mShader = dquick.renderer3D.opengl.renderer.resourceManager.getResource!Shader("rectangle", options);

		mMDVInvertedMatrixUniform = checkgl!glGetUniformLocation(mShader.getProgram(), cast(char*)("u_modelViewProjectionInvertedMatrix"));*/
	}

	void	destroy()
	{
		dquick.renderer3D.opengl.renderer.resourceManager.releaseResource(mTexture);
		mTexture = null;
		clear(indexes);
		clear(vertices);
		clear(colors);
		clear(texCoords);

//		.destroy(mShader);
	}

	static const GLuint		mBadId = 0;

	GLint					mPositionAttribute;
	GLint					mColorAttribute;
	GLint					mTexcoordAttribute;
	GLint					mTextureUniform;
	GLint					mMDVMatrixUniform;

	Shader					mShader;
	ShaderProgram			mShaderProgram;
	Texture					mTexture;			// TODO move to Material
}
