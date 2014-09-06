module dquick.script.dmlEngine;

import derelict.lua.lua;
import dquick.script.propertyBinding;
import dquick.script.utils;

import std.conv;
import std.file, std.stdio;
import std.string;
import core.memory;
import std.algorithm;
import std.traits;
import std.typetuple;
import std.c.string;

class DMLEngine : dquick.script.dmlEngineCore.DMLEngineCore
{
public:
	void	addItemType(type, string luaName)()
	{
		static if ((is(type : Object) || __traits(isAbstractClass, type) || __traits(isFinalClass, type)) && is(type : dquick.script.iItemBinding.IItemBinding) == false)
			addObjectBindingType!(dquick.script.itemBinding.ItemBinding!(type), luaName)();
		else
			addObjectBindingType!(type, luaName)();
	}

	void	addObject(T)(T object, string luaName)
	{
		addItemType!(T, "__dquick_reserved1");
		static if (is(T : dquick.script.iItemBinding.IItemBinding))
			object.id = luaName;

		dquick.script.itemBinding.ItemBinding!T	itemBinding = registerItem!T(object);
		setLuaGlobal(luaName, object);
	}

	T	rootItem(T)()
	{
		static if ((is(T : Object) || __traits(isAbstractClass, T) || __traits(isFinalClass, T)) && is(T : dquick.script.iItemBinding.IItemBinding) == false)
		{
			dquick.script.itemBinding.ItemBindingBase!T	result = rootItemBinding!(dquick.script.itemBinding.ItemBindingBase!T)();
			if (result !is null)
				return cast(T)result.itemObject;
			else 
				return null;
		}
		else
		{
			return rootItemBinding!(T)();
		}
	}

	T	getLuaGlobal(T)(string name)
	{
		lua_getglobal(luaState, name.toStringz());
		T	value;
		static if ((is(T : Object) || __traits(isAbstractClass, T) || __traits(isFinalClass, T)) && is(T : dquick.script.iItemBinding.IItemBinding) == false)
		{
			dquick.script.itemBinding.ItemBindingBase!T	itemBinding;
			dquick.script.utils.valueFromLua!(dquick.script.itemBinding.ItemBindingBase!(T))(luaState, -1, itemBinding);
			if (itemBinding is null)
				return null;
			value = cast(T)(itemBinding.itemObject());
		}
		else
		{
			dquick.script.utils.valueFromLua!T(luaState, -1, value);
		}

		lua_pop(luaState, 1);
		return value;
	}

	void	setLuaGlobal(T)(string name, T value)
	{
		static if ((is(T : Object) || __traits(isAbstractClass, T) || __traits(isFinalClass, T)) && is(T : dquick.script.iItemBinding.IItemBinding) == false)
		{
			dquick.script.itemBinding.ItemBinding!T itemBinding = registerItem!(T)(value);
			dquick.script.utils.valueToLua!(dquick.script.itemBinding.ItemBinding!T)(luaState, itemBinding);
		}
		else
		{
			dquick.script.utils.valueToLua!T(luaState, value);
		}

		lua_setglobal(luaState, name.toStringz());
	}

	void	addFunction(alias func, string luaName)()
	{
		string	functionMixin;
		static if (	isCallable!(func) &&
					isSomeFunction!(func) &&
				   __traits(isStaticFunction, func) &&
					   !isDelegate!(func))
		{
			static if (__traits(compiles, dquick.script.itemBinding.generateFunctionOrMethodBinding!(func))) // Hack because of a bug in fullyQualifiedName
			{
				mixin("static " ~ dquick.script.itemBinding.generateFunctionOrMethodBinding!(func));
				mixin("alias " ~ __traits(identifier, func) ~ " wrappedFunc;");
				dquick.script.dmlEngineCore.DMLEngineCore.addFunction!(wrappedFunc, luaName);
			}
		}
	}
private:

	dquick.script.iItemBinding.IItemBinding	getIItemBindingFromItem(T)(T item)
	{
		auto	refCountPtr = item in mItemsToItemBindings;
		if (refCountPtr !is null)
			return refCountPtr.iItemBinding;
		return null;
	}

	dquick.script.itemBinding.ItemBinding!T	registerItem(T)(T item)
	{
		auto	refCountPtr = item in mItemsToItemBindings;
		if (refCountPtr !is null)
		{
			refCountPtr.count++;
			return cast(dquick.script.itemBinding.ItemBinding!T)refCountPtr.iItemBinding;
		}

		// item binding doesn't already exists (item come from outside dmlEngine)
		dquick.script.itemBinding.ItemBinding!T	itemBinding = new dquick.script.itemBinding.ItemBinding!T(item);
		addObjectBinding!(dquick.script.itemBinding.ItemBinding!T)(itemBinding, "");
		return itemBinding;
	}

	// registerItem when a new item
	dquick.script.itemBinding.ItemBinding!T	registerItem(T)(T item, dquick.script.itemBinding.ItemBinding!T itemBinding)
	{
		assert((item in mItemsToItemBindings) is null);
		ItemRefCounting	newRefCount;
		newRefCount.count = 1;
		newRefCount.iItemBinding = itemBinding;
		mItemsToItemBindings[item] = newRefCount;
		return itemBinding;
	}

	void	unregisterItem(T)(T item)
	{
		auto	refCountPtr = item in mItemsToItemBindings;
		assert(refCountPtr !is null);

		refCountPtr.count--;
		if (refCountPtr.count == 0)
			mItemsToItemBindings.remove(item);
	}

	struct ItemRefCounting
	{
		dquick.script.iItemBinding.IItemBinding	iItemBinding;
		uint										count;
	}
	ItemRefCounting[Object]	mItemsToItemBindings;
}
