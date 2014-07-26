module dquick.script.dmlEngineCore;

import derelict.lua.lua;

import dquick.script.propertyBinding;
import dquick.script.utils;
import dquick.script.itemBinding;
import dquick.script.dmlEngine;

import std.conv;
import std.file, std.stdio;
import std.string;
import core.memory;
import std.algorithm;
import std.traits;
import std.typetuple;
import std.c.string;
import std.path;

class DMLEngineCore
{
public:
	this()
	{
	}

	~this()
	{
		destroy();
	}

	void	create()
	{
		destroy();

		mLuaState = luaL_newstate();
		luaL_openlibs(luaState);
		lua_atpanic(luaState, cast(lua_CFunction)&luaPanicFunction);
		mReentrencyLevel = 0;
		static if (showDebug)
			lvl = 0;

		//GC.disable();
		//scope(exit) GC.enable();

		lua_pushstring(luaState, "__This");
		lua_pushlightuserdata(luaState, cast(void*)this);
		lua_settable(luaState, LUA_REGISTRYINDEX);

		// ImportComponent
		lua_pushcfunction(luaState, cast(lua_CFunction)&importComponentLuaBind);
		lua_setglobal(luaState, "ImportComponent");

		lua_getglobal(luaState, "_G");
		assert(lua_istable(luaState, -1));
		mEnvStack ~= luaL_ref(luaState, LUA_REGISTRYINDEX);

		mInitializedItemCount = 0;
	}

	void	destroy()
	{
		if (luaState)
		{
			lua_close(luaState);
			mLuaState = null;
		}
	}

	void	addObjectBindingType(type, string luaName)()
	{
		// Create a lua table to host enums and factory
		lua_newtable(luaState);
		{
			// Add enums
			foreach (member; __traits(allMembers, type))
			{
				static if (__traits(compiles, EnumMembers!(__traits(getMember, type, member))) && is(OriginalType!(__traits(getMember, type, member)) == int)) // If its an int enum
				{
					// Create enum table
					lua_pushstring(luaState, member.toStringz());
					lua_newtable(luaState);
					{
						auto enumMembers = EnumMembers!(__traits(getMember, type, member));
						foreach (enumMember; enumMembers)
						{
							lua_pushstring(luaState, to!(string)(enumMember).toStringz());
							lua_pushinteger(luaState, cast(int)enumMember);

							lua_settable(luaState, -3);
						}
					}
					lua_settable(luaState, -3);
				}
			}

			// Create metatable
			lua_newtable(luaState);
			{
				// Call metamethod to instanciate type
				lua_pushstring(luaState, "__call");
				lua_pushcfunction(luaState, cast(lua_CFunction)&createLuaBind!(type));
				lua_settable(luaState, -3);
			}
			lua_setmetatable(luaState, -2);
		}
		// Add type to a global
		lua_setglobal(luaState, luaName.toStringz());
	}

	void	addFunction(alias func, string luaName)()
	{
		static assert(isSomeFunction!func, "func must be a function");

		lua_pushcfunction(luaState, cast(lua_CFunction)&functionLuaBind!func);
		lua_setglobal(luaState, luaName.toStringz());
	}

	void	addObjectBinding(T)(T object, string id = "")
	{
		static assert(is(T : dquick.script.iItemBinding.IItemBinding), "object must inherit from IItemBinding");
		static assert(!is(T == dquick.script.iItemBinding.IItemBinding), "object must inherit from IItemBinding but not be an IItemBinding");
			
		addObjectBindingType!(T, "__dquick_reserved1");

		if (object !is null)
		{
			if (object.dmlEngine is null)
			{
				assert(find(mItems, object) == [], format("Object \"%s\" is already added", id));
				mItems ~= object;
				object.dmlEngine = this;
			}
			mLastItemBindingCreated = object;
		}

		if (id != "")
			setLuaGlobal(id, object);
	}

	bool	isCreated()
	{
		return luaState != null;
	}

	void	executeFile(string filePath)
	{
		assert(isCreated());

		loadFile(filePath);
		execute();
	}

	void	loadFile(string filePath)
	{
		assert(isCreated());

		string	text;
		text = cast(string)read(filePath);
		load(text, filePath);
	}

	void	load(string text, string filePath)
	{
		assert(isCreated());

		if (luaL_loadbuffer(luaState, cast(const char*)text.ptr, text.length, filePath.toStringz()) != LUA_OK)
		{
			const char* error = lua_tostring(luaState, -1);
			writeln("DMLEngineCore.execute: error: " ~ to!(string)(error));
			lua_pop(luaState, 1);
			assert(false);

			version (release)
			{
				return;
			}
		}
	}

	void	execute()
	{
		assert(isCreated());

		// Save _ENV
		const char*	upvalue = lua_getupvalue(luaState, -1, 1);
		if (upvalue == null)
			throw new Exception("no _ENV upvalue");
		if (strcmp(upvalue, "_ENV") != 0)
		{
			lua_pop(luaState, 1);
			throw new Exception("no _ENV upvalue");
		}
		mEnvStack ~= luaL_ref(luaState, LUA_REGISTRYINDEX);

		static if (showDebug)
			writeln("execute: CREATE ==================================================================================================");

		luaPCall(0);

		luaL_unref(luaState, LUA_REGISTRYINDEX, mEnvStack[mEnvStack.length - 1]);
		mEnvStack.length--;
	}

	void	execute(string text, string filePath)
	{
		load(text, filePath);
		execute();
	}

	T	rootItemBinding(T)()
	{
		return cast(T)(mLastItemBindingCreated);
	}

	T	getLuaGlobal(T)(string name)
	{
		lua_getglobal(luaState, name.toStringz());
		T	value;
		dquick.script.utils.valueFromLua!T(luaState, -1, value);
		lua_pop(luaState, 1);
		return value;
	}

	void	setLuaGlobal(T)(string name, T value)
	{
		dquick.script.utils.valueToLua!T(luaState, value);
		lua_setglobal(luaState, name.toStringz());
	}

	static immutable bool showDebug = 1;

	int		currentLuaEnv()
	{
		assert(mEnvStack.length > 0);
		return mEnvStack[mEnvStack.length - 1];
	}

	void	beginTransaction()
	{
		mReentrencyLevel++;
	}

	void	endTransaction()
	{
		mReentrencyLevel--;
		if (mReentrencyLevel == 0) // Call bindings only after the last execute to avoid errors in bindings due to partial creation
		{
			static if (showDebug)
				writeln("execute: INIT ==================================================================================================");
			{
				size_t index = mInitializedItemCount; // Begin at mInitializedItemCount to avoid calling already initialized objects
				// Increment before in case executeBindings throws an exception:
				// The current execute will be invalid but the dmlEngine must stay fully usable
				mInitializedItemCount = mItems.length;
				while (index < mItems.length) 
				{
					static if (showDebug)
						writefln("[%s]", mItems[index].id);
					mItems[index].executeBindings();
					index++;
				}
			}

			static if (showDebug)
			{
				writeln("execute: DEPENDANCY TREE ==================================================================================================");
				for (size_t index = 0; index < mItems.length; index++)
					writefln("[%s]\n%s", mItems[index].id, shiftRight(mItems[index].displayDependencies(), "\t", 1));
				writeln("=======================================================================================================");
			}
		}
	}

	uint	propertyBindingStackSize = 50;

	lua_State*	luaState() { return mLuaState; }
protected:
	package void	luaPCall(int paramCount)
	{
		assert(isCreated());

		beginTransaction();
		scope(exit) endTransaction();

		if (lua_pcall(luaState, paramCount, LUA_MULTRET, 0) != LUA_OK)
		{
			string error = to!(string)(lua_tostring(luaState, -1));
			lua_pop(luaState, 1);
			throw new Exception(error);
		}
	}

	dquick.script.iItemBinding.IItemBinding[]		mItems;
	int												mInitializedItemCount;
	dquick.script.iItemBinding.IItemBinding			mLastItemBindingCreated;
	
	package lua_State*	mLuaState;
	package dquick.script.propertyBinding.PropertyBinding[]		currentlyExecutedBindingStack;
	package dquick.script.propertyBinding.PropertyBinding[]		propertyBindingBeeingSet;
	string		itemTypeIds;
	package int	mReentrencyLevel;
	int[string]	mComponentLuaReferences;
	static if (showDebug)
		package int	lvl;
	int[]		mEnvStack;
}

extern(C)
{
	private int	luaPanicFunction(lua_State* L)
	{
		try
		{
			const char* error = lua_tostring(L, 1);
			lua_pop(L, 1);
			throw new Exception(format("luaPanicFunction error: %s", error));
		}
		catch (Throwable e)
		{
			writeln(e.toString());
			return 0;
		}
	}

	private int	createLuaBind(T)(lua_State* L)
	{
		try
		{
			if (!lua_istable(L, 1))
				throw new Exception(format("a table was expected as self, got %s, the function was altered", getLuaTypeName(L, 1)));
			if (!lua_istable(L, 2))
				throw new Exception(format("a table was expected as argument, got %s", getLuaTypeName(L, 2)));
			if (lua_gettop(L) > 2)
				throw new Exception("too many arguments, only one table was expected as argument");

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			T	itemBinding = new T();
			dmlEngine.addObjectBinding!T(itemBinding);

			lua_remove(L, 1);
			itemBinding.valuesFromLuaTable(L);

			dquick.script.utils.valueToLua!T(L, itemBinding);

			// Set global from id
			if (itemBinding.id != "")
			{
				// Get _ENV
				lua_rawgeti(L, LUA_REGISTRYINDEX, dmlEngine.currentLuaEnv);

				lua_pushstring(L, itemBinding.id.toStringz());

				{ // Check for id conflict
					lua_pushvalue(L, -1);
					lua_rawget(L, -3); // Raw get without calling index metamethod to not get parent components values
					if (lua_isnil(L, -1) == false)
						throw new Exception(format("an item with id \"%s\" already exist in that component", itemBinding.id));
					lua_pop(L, 1);
				}

				lua_pushvalue(L, -3);

				lua_settable(L, -3);
				lua_pop(L, 1);
			}

			return 1;
		}
		catch (Throwable e)
		{
			luaError(L, e.msg);
			return 0;
		}
	}

	private int	indexLuaBind(T)(lua_State* L)
	{
		try
		{
			if (!lua_isuserdata(L, 1))
				throw new Exception(format("a userdata was expected as self, got %s, the function was altered", getLuaTypeName(L, 1)));
			if (!lua_isstring(L, 2))
				throw new Exception(format("a string was expected as key, got %s", getLuaTypeName(L, 2)));
			if (lua_gettop(L) > 2)
				throw new Exception("too many arguments, only a userdata as self and a string as key was expected as arguments");

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			T	itemBinding;
			dquick.script.utils.valueFromLua!(T)(L, 1, itemBinding);
			assert(itemBinding !is null);
			lua_remove(L, 1);
			const char*	propertyIdCString = lua_tostring(L, 1);
			const(char)[]	propertyId = propertyIdCString[0 .. strlen(propertyIdCString)];
			//string	propertyId;
			//dquick.script.utils.valueFromLua!(string)(L, 1, propertyId);
			//lua_remove(L, 1);

			// Search for property binding on the itemBinding
			foreach (member; __traits(allMembers, typeof(itemBinding)))
			{
				static if (is(typeof(__traits(getMember, itemBinding, member)) : dquick.script.propertyBinding.PropertyBinding))
				{
					if (propertyId == getPropertyNameFromPropertyDeclaration(member))
					{
						__traits(getMember, itemBinding, member).valueToLua(L);
						return 1;
					}
				}
			}
			// Search for simple method on the item
			foreach (member; __traits(allMembers, typeof(itemBinding)))
			{
				static if (__traits(compiles, isCallable!(__traits(getMember, typeof(itemBinding), member))))
				{
					static if (isCallable!(__traits(getMember, typeof(itemBinding), member)) && __traits(compiles, luaCallThisD!(member, typeof(itemBinding))(itemBinding, L, 1)))
					{
						if (propertyId == member)
						{
							dquick.script.utils.methodToLua!(T, member)(L, itemBinding);
							return 1;
						}
					}
				}
			}

			auto virtualProperty = (propertyId in itemBinding.virtualProperties);
			if (virtualProperty == null)
				return 0;

			virtualProperty.valueToLua(L);

			return 1;
		}
		catch (Throwable e)
		{
			luaError(L, e.msg);
			return 0;
		}
	}

	private int	newindexLuaBind(T)(lua_State* L)
	{
		try
		{
			if (!lua_isuserdata(L, 1))
				throw new Exception(format("a userdata was expected as self, got %s, the function was altered", getLuaTypeName(L, 1)));
			if (!lua_isstring(L, 2))
				throw new Exception(format("a string was expected as key, got %s", getLuaTypeName(L, 2)));
			if (lua_isnone(L, 3))
				throw new Exception(format("an assignment value was expected, got %s", getLuaTypeName(L, 3)));
			if (lua_gettop(L) > 3)
				throw new Exception("too many arguments, only a userdata as self, a string as key and an assignment value was expected as arguments");

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			T	itemBinding;
			dquick.script.utils.valueFromLua!(T)(L, 1, itemBinding);
			assert(itemBinding !is null);
			lua_remove(L, 1);
			string	propertyId = to!(string)(lua_tostring(L, 1));
			lua_remove(L, 1);

			bool	found = false;
			foreach (member; __traits(allMembers, typeof(itemBinding)))
			{
				static if (is(typeof(__traits(getMember, itemBinding, member)) : dquick.script.propertyBinding.PropertyBinding))
				{
					if (propertyId == getPropertyNameFromPropertyDeclaration(member))
					{
						found = true;
						__traits(getMember, itemBinding, member).bindingFromLua(L, 1);
						return 0;
					}
				}
			}

			auto virtualProperty = (propertyId in itemBinding.virtualProperties);
			if (virtualProperty)
			{
				virtualProperty.bindingFromLua(L, 1);
				virtualProperty.executeBinding();
				return 0;
			}

			throw new Exception(format("property \"%s\" doesn't exist on object \"%s\"", propertyId, itemBinding.id));
		}
		catch (Throwable e)
		{
			luaError(L, e.msg);
			return 0;
		}
	}

	// Handle simple function binding
	private int	functionLuaBind(alias func)(lua_State* L)
	{
		try
		{
			static assert(__traits(isStaticFunction, func), "func must be a function");

			return luaCallD!(func)(L, 1);
		}
		catch (Throwable e)
		{
			luaError(L, e.msg);
			return 0;
		}
	}

	// Handle method binding
	private int	methodCallLuaBind(string methodName, T)(lua_State* L)
	{
		try
		{
			static assert(isSomeFunction!(__traits(getMember, T, methodName)) &&
							!__traits(isStaticFunction, __traits(getMember, T, methodName)) &&
								!isDelegate!(__traits(getMember, T, methodName)),
							"func must be a method");

			if (!lua_isuserdata(L, 1))
				throw new Exception(format("a userdata was expected as self, got %s, the function was altered", getLuaTypeName(L, 1)));

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			T	itemBinding;
			dquick.script.utils.methodFromLua!(T)(L, 1, itemBinding);
			lua_remove(L, 1);
			assert(itemBinding !is null);

			return luaCallThisD!(methodName, T)(itemBinding, L, 1);
		}
		catch (Throwable e)
		{
			luaError(L, e.msg);
			return 0;
		}
	}
	// Index metamethod to warn user that it's a method
	private int	methodIndexLuaBind(string methodName, T)(lua_State* L)
	{
		luaError(L, "attempt to index a method");
		return 0;
	}
	// newIndex metamethod to warn user that it's a method
	private int	methodNewIndexLuaBind(string methodName, T)(lua_State* L)
	{
		luaError(L, "attempt to assign a method");
		return 0;
	}

	private int	importComponentLuaBind(lua_State* L)
	{
		try
		{
			if (!lua_isstring(L, 1))
				throw new Exception(format("a string was expected as argument, got %s", getLuaTypeName(L, 1)));
			if (lua_gettop(L) > 1)
				throw new Exception("too many arguments, only one string was expected as argument");

			string	path = to!(string)(lua_tostring(L, 1));
			lua_pop(L, 1);

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			string	componentName = baseName(stripExtension(path));
			lua_getglobal(L, componentName.toStringz());
			if (lua_iscfunction(L, -1) == false)
			{
				lua_pushstring(dmlEngine.luaState, path.toStringz());
				lua_pushcclosure(dmlEngine.luaState, cast(lua_CFunction)&createComponentLuaBind, 1);
				// Add type to a global
				lua_setglobal(dmlEngine.luaState, componentName.toStringz());
			}

			/*string	varName = baseName(stripExtension(path));
			lua_getglobal(L, varName.toStringz());
			if (lua_iscfunction(L, -1) == false)
			{
				dmlEngine.loadFile(path);
				lua_pushcclosure(dmlEngine.luaState, cast(lua_CFunction)&createComponentLuaBind, 1);
				// Add type to a global
				lua_setglobal(dmlEngine.luaState, varName.toStringz());
			}*/

			return 0;
		}
		catch (Throwable e)
		{
			luaError(L, e.msg);
			return 0;
		}
	}

	private int	createComponentLuaBind(lua_State* L)
	{
		try
		{
			if (!lua_istable(L, 1))
				throw new Exception(format("a table was expected as argument, got %s", getLuaTypeName(L, 1)));
			if (lua_gettop(L) > 1)
				throw new Exception("too many arguments, only one table was expected as argument");

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			// Load env chaining __index function
			string	lua = q"(
				__env_chaining_index = function (_, n)
				    local localRawGet = rawget(_, n)
					if localRawGet == nil then
						return _ENV[n]
					else
						return localRawGet
					end
				end
			)";
			dmlEngine.load(lua, "ComponentEnvChaining");
			dmlEngine.execute();

			// Get component code
			string	path = to!(string)(lua_tostring(L, lua_upvalueindex(1)));
			dmlEngine.loadFile(path);

			/*lua_pushvalue(dmlEngine.luaState, lua_upvalueindex(1));
			assert(lua_isfunction(dmlEngine.luaState, -1));*/

			// Create new _ENV table
			lua_newtable(dmlEngine.luaState);
			// Create new _ENV's metatable
			lua_newtable(dmlEngine.luaState);
			{
				// __index metamethod to chain lookup to the parent env
				lua_pushstring(dmlEngine.luaState, "__index");
				lua_getglobal(dmlEngine.luaState, "__env_chaining_index");

				// Put component env
				lua_rawgeti(dmlEngine.luaState, LUA_REGISTRYINDEX, dmlEngine.currentLuaEnv);
				const char*	envUpvalue = lua_setupvalue(dmlEngine.luaState, -2, 1);
				if (envUpvalue == null) // No access to env, env table is still on the stack so we need to pop it
					lua_pop(dmlEngine.luaState, 1);

				lua_settable(dmlEngine.luaState, -3);
			}
			lua_setmetatable(dmlEngine.luaState, -2);

			dquick.script.iItemBinding.IItemBinding	previousRootItem = dmlEngine.rootItemBinding!(dquick.script.iItemBinding.IItemBinding)();

			// Set table to _ENV upvalue
			const char*	envUpvalue = lua_setupvalue(dmlEngine.luaState, -2, 1);
			if (envUpvalue == null) // No access to env, env table is still on the stack so we need to pop it
				lua_pop(dmlEngine.luaState, 1);
			// Execute component code
			dmlEngine.execute();

			dquick.script.iItemBinding.IItemBinding	iItemBinding = dmlEngine.rootItemBinding!(dquick.script.iItemBinding.IItemBinding)();
			if (iItemBinding is null || iItemBinding == previousRootItem)
			{
				string	componentName = baseName(stripExtension(path));
				throw new Exception(format("\"%s\" component has no root item", componentName));
			}

			string	componentId;
			lua_pushstring(L, "id");
			lua_gettable(L, -2);
			if (lua_isnil(L, -1) == false)
				componentId = to!(string)(lua_tostring(L, -1));
			lua_pop(L, 1);

			iItemBinding.valuesFromLuaTable(L);
			iItemBinding.pushToLua(L);

			// Set global from id
			if (componentId != "")
			{
				// Get _ENV
				lua_rawgeti(L, LUA_REGISTRYINDEX, dmlEngine.currentLuaEnv);
				lua_pushstring(L, componentId.toStringz());

				{ // Check for id conflict
					lua_pushvalue(L, -1);
					lua_rawget(L, -3); // Raw get without calling index metamethod to not get parent components values
					if (lua_isnil(L, -1) == false)
						throw new Exception(format("an item with id \"%s\" already exist in that component", componentId));
					lua_pop(L, 1);
				}

				lua_pushvalue(L, -3);

				lua_settable(L, -3);
				lua_pop(L, 1);
			}

			return 1;
		}
		catch (Throwable e)
		{
			luaError(L, e.msg);
			return 0;
		}
	}

	private int	arrayIndexLuaBind(T)(lua_State* L)
	{
		try
		{
			if (!lua_isuserdata(L, 1))
				throw new Exception(format("a userdata was expected as self, got %s, the function was altered", getLuaTypeName(L, 1)));
			if (lua_isnone(L, 2) || lua_isnil(L, 2))
				throw new Exception(format("a value was expected as key, got %s", getLuaTypeName(L, 2)));
			if (lua_gettop(L) > 2)
				throw new Exception("too many arguments, only a userdata as self and a string as key was expected as arguments");

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			T	array;
			dquick.script.utils.valueFromLua!(T)(L, 1, array);
			static if (isAssociativeArray!T)
				KeyType!T	key;
			else
				uint	key;
			dquick.script.utils.valueFromLua!(typeof(key))(L, 2, key);

			static if (isAssociativeArray!T)
			{
				ForeachType!(T)*	valuePtr = key in array;
				if (valuePtr == null)
				{
					lua_pushnil(L);
					return 1;
				}
			}
			else
			{
				if (key >= array.length)
				{
					lua_pushnil(L);
					return 1;
				}
				ForeachType!(T)*	valuePtr = &array[key];
			}
			
			static if (is(typeof(array[key]) : dquick.script.iItemBinding.IItemBinding))
			{
				dmlEngine.addObjectBinding(*valuePtr);
				dquick.script.utils.valueToLua!(typeof(array[key]))(L, *valuePtr);
			}
			else
			{
				static if (is(typeof(array[key]) : dquick.item.declarativeItem.DeclarativeItem))
				{
					DMLEngine	dmlEngine2 = cast(DMLEngine)dmlEngine;
					assert(dmlEngine2);
					dquick.script.itemBinding.ItemBinding!(typeof(array[key])) itemBinding = dmlEngine2.registerItem!(typeof(array[key]))(*valuePtr);
					dquick.script.utils.valueToLua(dmlEngine.luaState, itemBinding);
				}
				else
				{
					dquick.script.utils.valueToLua!(typeof(array[key]))(L, *valuePtr);
				}
			}

			return 1;
		}
		catch (Throwable e)
		{
			luaError(L, e.msg);
			return 0;
		}
	}

	private int	arrayNewindexLuaBind(T)(lua_State* L)
	{
		try
		{
			if (!lua_isuserdata(L, 1))
				throw new Exception(format("a userdata was expected as self, got %s, the function was altered", getLuaTypeName(L, 1)));
			if (lua_isnone(L, 2) || lua_isnil(L, 2))
				throw new Exception(format("a value was expected as key, got %s", getLuaTypeName(L, 2)));
			if (lua_isnone(L, 3))
				throw new Exception(format("an assignment value was expected, got %s", getLuaTypeName(L, 3)));
			if (lua_gettop(L) > 3)
				throw new Exception("too many arguments, only a userdata as self, a string as key and an assignment value was expected as arguments");

			T	array;
			dquick.script.utils.valueFromLua!(T)(L, 1, array);
			static if (isAssociativeArray!T)
				KeyType!T	key;
			else
				uint	key;
			dquick.script.utils.valueFromLua!(typeof(key))(L, 2, key);

			static if (isAssociativeArray!T == false)
			{
				if (key >= array.length)
				{
					throw new Exception(format("the key value %d is out of bound", key));
				}
			}

			ForeachType!(T)	value = void;
			dquick.script.utils.valueFromLua!(typeof(value))(L, 3, value);
			array[key] = value;

			return 0;
		}
		catch (Throwable e)
		{
			luaError(L, e.msg);
			return 0;
		}
	}
}