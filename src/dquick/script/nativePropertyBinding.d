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
		static if (__traits(hasMember, item, getSignalNameFromPropertyName(PropertyName)))
			__traits(getMember, item, getSignalNameFromPropertyName(PropertyName)).connect(&onChanged);
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
			throw new Exception(format("property \"%s\" is read only", PropertyName));			
	}

	override void	valueToLua(lua_State* L)
	{
		super.valueToLua(L);
		ValueType	value = void; // Assignation not on the same line due to a dmd compilation bug with multi dim static arrays
		value = __traits(getMember, cast(ItemType)(item), PropertyName);
		static if (is(ValueType : dquick.script.iItemBinding.IItemBinding))
			itemBinding.dmlEngine.addObjectBinding(value);
		dquick.script.utils.valueToLua!ValueType(L, value);
	}

	template	type()
	{
		alias T	type;
	}
}
