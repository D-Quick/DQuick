module dquick.script.nativePropertyBinding;

import std.stdio;
import std.conv;
import std.string;
import std.array;

import derelict.lua.lua;

import dquick.script.propertyBinding;
import dquick.script.iItemBinding;
import dquick.script.itemBinding;
import dquick.script.utils;

class NativePropertyBinding(ValueType, ItemType, string PropertyName) : PropertyBinding
{
	ItemType	item;
	this(IItemBinding itemBinding, ItemType item)
	{
		this.item = item;
		super(itemBinding, PropertyName);
	}

	void	onChanged(ValueType t)
	{
		super.onChanged();
	}

	override void	valueFromLua(lua_State* L, int index, bool popFromStack = false)
	{
		ValueType	value;
		dquick.script.utils.valueFromLua!ValueType(L, index, value);
		if (popFromStack)
			lua_remove(L, index);
		static if (__traits(compiles, __traits(getMember, cast(ItemType)(item), PropertyName)(value)))
			__traits(getMember, item, PropertyName)(value);
		else
			throw new Exception(format("Property \"%s\" is not writeable\n", PropertyName));			
	}

	override void	valueToLua(lua_State* L)
	{
		super.valueToLua(L);
		ValueType	value = __traits(getMember, cast(ItemType)(item), PropertyName);
		static if (is(ValueType : dquick.script.iItemBinding.IItemBinding))
			itemBinding.dmlEngine.addObjectBinding(value);
		dquick.script.utils.valueToLua!ValueType(L, value);
	}

	template	type()
	{
		alias T	type;
	}
}
