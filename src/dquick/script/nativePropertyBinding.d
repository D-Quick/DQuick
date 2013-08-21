module dquick.script.native_property_binding;

import std.stdio;
import std.conv;
import std.string;
import std.array;

import derelict.lua.lua;

import dquick.script.property_binding;
import dquick.script.i_item_binding;

class NativePropertyBinding(T) : PropertyBinding
{
	T delegate()		getter;
	void delegate(T)	setter;

	this(IItemBinding itemBinding, T delegate() getter, void delegate(T) setter, string propertyName)
	{
		super(itemBinding, propertyName);
		this.getter = getter;
		this.setter = setter;
	}

	this(IItemBinding itemBinding, T delegate() getter, string propertyName)
	{
		super(itemBinding, propertyName);
		this.getter = getter;
	}

	void	onChanged(T t)
	{
		super.onChanged();
	}

	override void	valueFromLua(lua_State* L, int index, bool popFromStack = false)
	{
		if (setter.ptr == null)
			return;

		T	value;
		static if (is(typeof(this) : NativePropertyBinding!int))
		{
			if (!lua_isnumber(L, index))
			{
				writefln("NativePropertyBinding.valueFromLua(T): param %d is not a number\n", index);
				//lua_Debug ar;
				//lua_getstack(L, 1, &ar);
				//lua_getinfo(L, toStringz("nSl"), &ar);
				//lua_pushstring(L, std.string.format("lua error, exception from call to C function on file \"%s\" at line %d: NativePropertyBinding.valueFromLua(T): param %d is not a number\n", ar.short_src, ar.currentline, index).toStringz());
				//lua_error(L);
			}
			value = cast(int)lua_tointeger(L, index);
		}
		else static if (is(typeof(this) : NativePropertyBinding!float))
		{
			if (!lua_isnumber(L, index))
			{
				writefln("NativePropertyBinding.valueFromLua: param %d is not a number\n", index);
			}
			value = cast(float)lua_tonumber(L, index);
		}
		else static if (is(typeof(this) : NativePropertyBinding!string))
		{
			if (!lua_isstring(L, index))
			{
				writefln("NativePropertyBinding.valueFromLua: param %d is not a string\n", index);
			}
			value = to!(string)(lua_tostring(L, index));
		}
		else static if (is(typeof(this) : NativePropertyBinding!bool))
		{
			if (!lua_isboolean(L, index))
			{
				writefln("NativePropertyBinding.valueFromLua: param %d is not a boolean\n", index);
			}
			value = cast(bool)lua_toboolean(L, index);
		}
		else
		{
			assert(false);
		}
		if (popFromStack)
			lua_remove(L, index);
		setter(value);
	}

	override void	valueToLua(lua_State* L)
	{
		super.valueToLua(L);
		static if (is(typeof(this) == NativePropertyBinding!int))
			lua_pushinteger(L, getter());
		else static if (is(typeof(this) == NativePropertyBinding!float))
			lua_pushnumber(L, getter());
		else static if (is(typeof(this) == NativePropertyBinding!string))
			lua_pushstring(L, getter().toStringz());
		else static if (is(typeof(this) == NativePropertyBinding!bool))
			lua_pushboolean(L, getter());
	}
}
