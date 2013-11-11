module dquick.algorithms.weak;

import core.atomic;

auto weak(T)(T val)
{
	return new Weak!T(val);
}

final class Weak(T)
	if(is(T == interface) || is(T == class) || is(T == delegate))
{
	this()
	{
	}
	
	this(T val)
	{
		if(val !is null)
		{
			mData = val;
			rt_attachDisposeEvent(val.asObject, &this.onDispose);
		}
	}
	
	~this()
	{
		Object obj = mData.object;
		if(obj !is null)
			rt_detachDisposeEvent(obj, &this.onDispose);
	}
	
	@property T target() const
	{
		return mData.target;
	}
	
	void opAssign(T val)
	{
		Object obj = mData.object;
		if(obj !is null)
			rt_detachDisposeEvent(obj, &this.onDispose);
		
		mData = val;
		
		if(val !is null)
			rt_attachDisposeEvent(val.asObject, &this.onDispose);
	}
	
	private
	{
		WeakData!T mData;
		
		void onDispose(Object obj)
		{
			mData.reset();
		}
	}
}

private
{
	struct WeakData(T)
	{
		shared size_t addr;
		static if(is(T == delegate))
			void* func;
			
		this(T val)
		{
			static if(is(T == delegate))
			{
				func = cast(void*)val.funcptr;
				atomicStore(addr, cast(size_t)cast(void*)val.ptr);
			}
			else		
				atomicStore(addr, cast(size_t)cast(void*)val);
		}
			
		void opAssign(T val)
		{
			atomicStore(addr, cast(size_t)0);
			
			static if(is(T == delegate))
			{
				func = cast(void*)val.funcptr;
				atomicStore(addr, cast(size_t)cast(void*)val.ptr);
			}
			else		
				atomicStore(addr, cast(size_t)cast(void*)val);
		}
		
		void reset()
		{
			atomicStore(addr, cast(size_t)0);
			static if(is(T == delegate))
				func = null;
		}
		
		Object object() const
		{
			shared void* ptr;
			atomicStore(ptr, cast(shared void*)addr);
			return cast(Object)ptr;
		}
		
		T target() const
		{
			shared void* ptr;
			atomicStore(ptr, cast(shared void*)addr);
			static if(is(T == delegate))
			{
				T dlg;
				dlg.ptr = cast(void*)ptr;
				dlg.funcptr = cast(typeof(dlg.funcptr))func;
				return dlg;
			}
			else
				return cast(T)ptr;
		}
	}
	
	Object asObject(T)(T r)
	{
		static if(is(T == delegate))
			return cast(Object)r.ptr;
		else
			return r;
	}

	alias void delegate(Object) DisposeEvt;
	extern (C) void rt_attachDisposeEvent(Object obj, DisposeEvt evt);
	extern (C) void rt_detachDisposeEvent(Object obj, DisposeEvt evt);
}
