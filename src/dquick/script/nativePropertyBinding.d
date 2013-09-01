module dquick.script.native_property_binding;

import std.stdio;
import std.conv;
import std.string;
import std.array;

import derelict.lua.lua;

import dquick.script.property_binding;
import dquick.script.i_item_binding;
import dquick.script.utils;

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

		T	value = dquick.script.utils.valueFromLua!T(L, index);
		if (popFromStack)
			lua_remove(L, index);
		setter(value);
	}

	override void	valueToLua(lua_State* L)
	{
		super.valueToLua(L);
		dquick.script.utils.valueToLua!T(L, getter());
	}
}
