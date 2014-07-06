module dquick.script.nativePropertyBinding;

import std.stdio;
import std.conv;
import std.string;
import std.array;
import std.traits;

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

	override void	executeBinding()
	{
		if (itemBinding.dmlEngine is null)
			throw new Exception(format("item \"%s\" is not in a dmlEngine\n", itemBinding.id));

		// No property binding or slot call while the item is in creation to ensure there is no particular initialisation order between properties of an object
		if (dirty == false || itemBinding.creating == true)
			return;

		static if (__traits(hasMember, item, getDBindingNameFromPropertyName(PropertyName)) &&
				   is(ReturnType!(__traits(getMember, item, getDBindingNameFromPropertyName(PropertyName))) == ValueType) &&
				   ParameterTypeTuple!(__traits(getMember, item, getDBindingNameFromPropertyName(PropertyName))).length == 0)
			const hasDBinding = true;
		else
			const hasDBinding = false;
		if (hasDBinding || luaReference != -1)
		{
			// Binding overflow or property binding loop detection
			if (itemBinding.dmlEngine.currentlyExecutedBindingStack.length >= itemBinding.dmlEngine.propertyBindingStackSize)
			{
				string	bindingLoopCallStack;
				int	loopCount = 0;
				for (int index = cast(int)(itemBinding.dmlEngine.currentlyExecutedBindingStack.length - 1);  index >= 0; index--)
				{
					bindingLoopCallStack ~= itemBinding.dmlEngine.currentlyExecutedBindingStack[index].itemBinding.id;
					bindingLoopCallStack ~= ".";
					bindingLoopCallStack ~= itemBinding.dmlEngine.currentlyExecutedBindingStack[index].propertyName;
					bindingLoopCallStack ~= "\n";
					if (itemBinding.dmlEngine.currentlyExecutedBindingStack[index] is this)
					{
						loopCount++;
						if (loopCount == 2)
							break;
					}
				}
				if (loopCount != 0)
					throw new Exception(format("property binding loop detected, callstack:\n%s...", bindingLoopCallStack));
				else
					throw new Exception(format("binding stack overflow (more than 50):\n%s...", bindingLoopCallStack));
			}

			static if (dquick.script.dmlEngineCore.DMLEngineCore.showDebug)
			{
				writefln("%s%s.%s.executeBinding {", replicate("|\t", itemBinding.dmlEngine.lvl++), itemBinding.id, propertyName);
				scope(exit)
				{
					assert(itemBinding.dmlEngine.lvl >= 1);
					itemBinding.dmlEngine.lvl--;
					writefln("%s}", replicate("|\t", itemBinding.dmlEngine.lvl));
				}
			}

			foreach (dependency; dependencies)
				dependency.dependents[this] = null;

			dependencies.clear();

			itemBinding.dmlEngine.currentlyExecutedBindingStack ~= this;
			scope(exit) itemBinding.dmlEngine.currentlyExecutedBindingStack.length--;
			scope(failure) dependencies.clear();

			//writefln("%sinitializationPhase = %d executeBinding %s", repeat("|\t", lvl), initializationPhase, item.id);
			//writefln("top = %d", lua_gettop(luaState));

			static if (hasDBinding)
			{
				ValueType value = __traits(getMember, item, getDBindingNameFromPropertyName(PropertyName))();
			}
			else
			{
				int	top = lua_gettop(itemBinding.dmlEngine.luaState);
				lua_rawgeti(itemBinding.dmlEngine.luaState, LUA_REGISTRYINDEX, luaReference);
				if (lua_pcall(itemBinding.dmlEngine.luaState, 0, LUA_MULTRET, 0) != LUA_OK)
				{
					string error = to!(string)(lua_tostring(itemBinding.dmlEngine.luaState, -1));
					lua_pop(itemBinding.dmlEngine.luaState, 1);
					throw new Exception(error);
				}
			}

			static if (dquick.script.dmlEngine.DMLEngine.showDebug)
			{
				foreach (dependency; dependencies)
				{
					writefln("%sdepend on %s.%s", replicate("|\t", itemBinding.dmlEngine.lvl), dependency.itemBinding.id, dependency.propertyName);
				}
			}
			foreach (dependency; dependencies)
				dependency.dependents[this] = this;

			static if (hasDBinding == false)
			{
				if (lua_gettop(itemBinding.dmlEngine.luaState) - top != 1)
					throw new Exception(format("too few or too many return values on property binding %s.%s, got %d, expected 1", itemBinding.id, propertyName, lua_gettop(itemBinding.dmlEngine.luaState) - top));
			}

			// Put this so that onChanged can detect it's a value change from binding or from D
			itemBinding.dmlEngine.propertyBindingBeeingSet = this;
			scope(exit) itemBinding.dmlEngine.propertyBindingBeeingSet = null;
			static if (hasDBinding)
			{
				static if (__traits(compiles, __traits(getMember, cast(ItemType)(item), PropertyName)(value)))
					__traits(getMember, item, PropertyName)(value);
				else
					throw new Exception(format("property \"%s\" is read only", PropertyName));
			}
			else
			{
				valueFromLua(itemBinding.dmlEngine.luaState, -1, true);
			}
		}
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

	ValueType	value()
	{
		super.valueToLua(null);
		return __traits(getMember, cast(ItemType)(item), PropertyName);
	}

	void	value(ValueType value)
	{
		super.valueFromLua(null, 0);
		static if (__traits(compiles, __traits(getMember, cast(ItemType)(item), PropertyName)(value)))
			__traits(getMember, cast(ItemType)(item), PropertyName)(value);
		else
			throw new Exception(format("property \"%s\" is read only", PropertyName));	
	}

	template	type()
	{
		alias T	type;
	}
}
