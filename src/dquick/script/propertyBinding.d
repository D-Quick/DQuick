module dquick.script.property_binding;

import std.algorithm;
import std.file, std.stdio;
import std.conv;
import std.string;
import std.array;

import derelict.lua.lua;

import dquick.script.dml_engine;
import dquick.script.i_item_binding;

class PropertyBinding
{
	int	_slotLuaReference = -1;
	void	slotLuaReference(int luaRef)
	{
		if (_slotLuaReference != -1)
			luaL_unref(itemBinding.dmlEngine.luaState(), LUA_REGISTRYINDEX, _slotLuaReference);
		_slotLuaReference = luaRef;
	}
	int		slotLuaReference()
	{
		return _slotLuaReference;
	}

	int	_luaReference = -1;
	void	luaReference(int luaRef)
	{
		if (_luaReference != -1)
			luaL_unref(itemBinding.dmlEngine.luaState(), LUA_REGISTRYINDEX, _luaReference);
		_luaReference = luaRef;
	}
	int		luaReference()
	{
		return _luaReference;
	}

	PropertyBinding[]	dependencies;
	PropertyBinding[]	dependents;

	byte	dirty;

	dquick.script.i_item_binding.IItemBinding itemBinding;

	string	propertyName;
	this(IItemBinding itemBinding, string propertyName)
	{
		this.itemBinding = itemBinding;
		this.propertyName = propertyName;
		dirty = true;
	}
	string	displayDependents()
	{
		string	result;
		foreach (dependent; dependents)
			result ~= format("%s.%s\n", itemBinding.declarativeItem().id, dependent.propertyName);
		return result;
	}

	void	executeBinding()
	{
		if (dirty == false)
			return;

		if (luaReference != -1)
		{
			// Binding overflow or property binding loop detection
			if (itemBinding.dmlEngine.currentlyExecutedBindingStack.length >= 50)
			{
				string	bindingLoopCallStack;
				int	loopCount = 0;
				for (int index = cast(int)(itemBinding.dmlEngine.currentlyExecutedBindingStack.length - 1);  index >= 0; index--)
				{
					bindingLoopCallStack ~= itemBinding.dmlEngine.currentlyExecutedBindingStack[index].itemBinding.declarativeItem.id;
					bindingLoopCallStack ~= ".";
					bindingLoopCallStack ~= itemBinding.dmlEngine.currentlyExecutedBindingStack[index].propertyName;
					bindingLoopCallStack ~= "\n";
					if (itemBinding.dmlEngine.currentlyExecutedBindingStack[index] == this)
					{
						loopCount++;
						if (loopCount == 2)
							break;
					}
				}
				if (loopCount != 0)
					writefln("DMLEngine.IItemBinding.PropertyBinding.executeBinding: property binding loop detected, callstack:\n%s...", bindingLoopCallStack);
				else
					writeln("DMLEngine.IItemBinding.PropertyBinding.executeBinding: error, binding stack overflow (more than 100)");
				return;
			}

			static if (dquick.script.dml_engine.DMLEngine.showDebug)
			{
				writefln("%s%s.%s.executeBinding {", replicate("|\t", itemBinding.dmlEngine.lvl++), itemBinding.declarativeItem.id, propertyName);
				scope(exit)
				{
					itemBinding.dmlEngine.lvl--;
					writefln("%s}", replicate("|\t", itemBinding.dmlEngine.lvl));
				}
			}

			foreach (dependency; dependencies)
			{
				for (int index = 0; index < cast(int)dependency.dependents.length; index++)
				{
					if (dependency.dependents[index] == this)
					{
						dependency.dependents = remove(dependency.dependents, index);
						index--;
					}
				}
			}

			dependencies.clear();

			itemBinding.dmlEngine.currentlyExecutedBindingStack ~= this;

			//writefln("%sinitializationPhase = %d executeBinding %s", repeat("|\t", lvl), initializationPhase, item.id);
			//writefln("top = %d", lua_gettop(luaState()));

			int	top = lua_gettop(itemBinding.dmlEngine.luaState());
			lua_rawgeti(itemBinding.dmlEngine.luaState(), LUA_REGISTRYINDEX, luaReference);
			if (lua_pcall(itemBinding.dmlEngine.luaState(), 0, LUA_MULTRET, 0) != LUA_OK)
			{
				const char* error = lua_tostring(itemBinding.dmlEngine.luaState(), -1);
				writeln("DMLEngine.IItemBinding.PropertyBinding.executeBinding: error: " ~ to!(string)(error));
				assert(false);
				version (release)
				{
					currentlyExecutedBindingStack.length--;
					dependencies.clear();
					return;
				}
			}
			scope(exit) lua_pop(itemBinding.dmlEngine.luaState(), lua_gettop(itemBinding.dmlEngine.luaState()) - top);

			static if (dquick.script.dml_engine.DMLEngine.showDebug)
			{
				foreach (dependency; dependencies)
					writefln("%s dependent of %s.%s", replicate("|\t", itemBinding.dmlEngine.lvl), itemBinding.declarativeItem.id, dependency.propertyName);
			}
			foreach (dependency; dependencies)
				dependency.dependents ~= this;

			itemBinding.dmlEngine.currentlyExecutedBindingStack.length--;

			if (lua_gettop(itemBinding.dmlEngine.luaState()) - top != 1)
			{
				writefln("executeBinding:: too few or too many return values, got %d, expected 1\n", lua_gettop(itemBinding.dmlEngine.luaState()) - top);
				return;
			}
			valueFromLua(itemBinding.dmlEngine.luaState(), -1, true);
		}
	}

	void	onChanged()
	{
		dirty = false;
		if (itemBinding.creating == false && slotLuaReference != -1)
			itemBinding.dmlEngine.execute(slotLuaReference);
		if (itemBinding.dmlEngine.initializationPhase == false)
		{
			static if (dquick.script.dml_engine.DMLEngine.showDebug)
			{
				writefln("%s%s.%s.onChanged {", replicate("|\t", itemBinding.dmlEngine.lvl++), itemBinding.declarativeItem.id, propertyName);
				scope(exit)
				{
					itemBinding.dmlEngine.lvl--;
					writefln("%s}", replicate("|\t", itemBinding.dmlEngine.lvl));
				}
			}

			auto dependentsCopy = dependents.dup;
			foreach (dependent; dependentsCopy)
			{
				dependent.dirty = true;
				dependent.executeBinding();
			}
		}
	}

	void	valueFromLua(lua_State* L, int index, bool popFromStack = false)
	{
	}

	void	valueToLua(lua_State* L)
	{
		executeBinding();
		//writefln("id = %s", declarativeItem.id);
		// Register acces to value for property binding auto update
		//if (currentlyExecutedBindingStack.length > 100)
		//	writefln("currentlyExecutedBindingStack.length = %d", currentlyExecutedBindingStack.length);

		if (itemBinding.dmlEngine.currentlyExecutedBindingStack.length > 0)
		{
			assert(itemBinding.dmlEngine.currentlyExecutedBindingStack[itemBinding.dmlEngine.currentlyExecutedBindingStack.length - 1] != this);
			itemBinding.dmlEngine.currentlyExecutedBindingStack[itemBinding.dmlEngine.currentlyExecutedBindingStack.length - 1].dependencies ~= this;
		}
	}

	void	bindingFromLua(lua_State* L, int index)
	{
		if (lua_isfunction(L, index)) // Binding is a lua function
		{
			luaReference = luaL_ref(L, LUA_REGISTRYINDEX);
			lua_pushnil(L); // To compensate the value poped by luaL_ref
		}
		else // Binding is juste a value
		{
			luaReference = -1;
			valueFromLua(L, index);
		}
	}
}

