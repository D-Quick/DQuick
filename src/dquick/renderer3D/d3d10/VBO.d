module dquick.renderer3D.d3d10.VBO;

import dquick.renderer3D.d3d10.util;
import dquick.renderer3D.generic;
import dquick.utils.resourceManager;

import dquick.utils.utils;

import std.stdio;

import core.runtime;

import dquick.buildSettings;

/*
1	#define D3DFVF_CUSTOMVERTEX (D3DFVF_XYZ | D3DFVF_NORMAL | D3DFVF_DIFFUSE | D3DFVF_TEX2)
2	 
3	IDirect3DVertexBuffer9* g_pVB = NULL;
4	if( FAILED( g_pd3dDevice->CreateVertexBuffer( vertexCount * sizeof(CUSTOMVERTEX), D3DUSAGE_WRITEONLY, D3DFVF_CUSTOMVERTEX, D3DPOOL_MANAGED, &g_pVB, NULL ) ) )
5	    return E_FAIL;
6	 
7	VOID* pVertices;
8	if( FAILED( g_pVB->Lock( 0, sizeof(CUSTOMVERTEX) * vertexCount, (void**)&pVertices, 0 ) ) )
9	    return E_FAIL;
10	  
11	memcpy( pVertices, vertices, sizeof(S3DVertex) * vertexCount );
12	  
13	g_pVB->Unlock();
14	 
15	 
16	// Render
17	g_pd3dDevice->SetStreamSource( 0, g_pVB, 0, sizeof(CUSTOMVERTEX) );
18	g_pd3dDevice->SetFVF( D3DFVF_CUSTOMVERTEX );
19	g_pd3dDevice->DrawPrimitive( D3DPT_TRIANGLELIST, 0, vertexCount / 3 );
*/

static if (renderer == RendererMode.D3D10)	// TODO remove it, it will be better if both version can be built, this will enforce the API chechs during compilation (all renderers will be compiled)
final class VBO(T) : IResource
{
	mixin ResourceBase;

public:
	this(VBOType type)
	{
//		mType = typeToGLenum(type);
	}

	~this()
	{
//		debug destructorAssert(mId == 0, "VBO.release method wasn't called.", mTrace);
	}

	void	load(string filePath, Variant[] options)
	{
		release();

		debug mTrace = defaultTraceHandler(null);

		assert(options && options.length == 2
			   && options[0].type() == typeid(VBOType)
			   && options[1].type() == typeid(VBOMode)
			   && options[2].type() == typeid(T[]));
/*		mType = typeToGLenum(options[0].get!VBOType());
		mMode = modeToGLenum(options[1].get!VBOMode());
		mArray = options[2].get!(T[])();

		mWeight = mArray.sizeof;
		mFilePath = filePath;*/
	}

	void	release()
	{
	}

	void	bind()
	{
	}

	void	unbind()
	{
	}

	void	setArray(T[] array, VBOMode mode)
	{
	}

	void	updateArray(T[] array)
	{
	}

	size_t	length() {return mArray.length;}

private:
	void	create()
	{
	}

//	IDirect3DVertexBuffer9*	buffer;

	T[]		mArray;

	debug Throwable.TraceInfo	mTrace;
}
