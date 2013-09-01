module dquick.script.dml_engine;

import derelict.lua.lua;

import dquick.item.declarative_item;
import dquick.item.graphic_item;
import dquick.item.image_item;

import dquick.system.window;

import dquick.script.property_binding;
import dquick.script.utils;

import std.conv;
import std.file, std.stdio;
import std.string;
import core.memory;
import std.algorithm;
import std.traits;
import std.typetuple;
import std.c.string;

version(unittest)
{
	class Item : DeclarativeItem
	{
		void	nativeProperty(int value)
		{
			if (mNativeProperty != value)
			{
				mNativeProperty = value;
				onNativePropertyChanged.emit(value);
			}
		}
		int		nativeProperty()
		{
			return mNativeProperty;
		}
		mixin Signal!(int) onNativePropertyChanged;
		int		mNativeProperty;

		void	nativeTotalProperty(int value)
		{
			if (mNativeTotalProperty != value)
			{
				mNativeTotalProperty = value;
				onNativeTotalPropertyChanged.emit(value);
			}
		}
		int		nativeTotalProperty()
		{
			return mNativeTotalProperty;
		}
		mixin Signal!(int) onNativeTotalPropertyChanged;
		int		mNativeTotalProperty;

		enum Enum
		{
			enumVal1,
			enumVal2,
		}
		void	nativeEnumProperty(Enum value)
		{
			if (mNativeEnumProperty != value)
			{
				mNativeEnumProperty = value;
				onNativeEnumPropertyChanged.emit(value);
			}
		}
		Enum		nativeEnumProperty()
		{
			return mNativeEnumProperty;
		}
		mixin Signal!(Enum) onNativeEnumPropertyChanged;
		Enum		mNativeEnumProperty;
	}

	int	testSumFunctionBinding(int a, int b)
	{
		return a + b;
	}
}

unittest
{
	DMLEngine	dmlEngine = new DMLEngine;
	dmlEngine.create();
	dmlEngine.addItemType!(Item, "Item");

	// Test basic item
	string lua1 = q"(
		Item {
			id = "item1"
		}
	)";
	dmlEngine.execute(lua1, "");
	assert(dmlEngine.rootItem() !is null);
	assert(dmlEngine.rootItem().id == "item1");

	// Test native property
	string lua2 = q"(
		Item {
			id = "item2",
			nativeProperty = 100
		}
	)";
	dmlEngine.execute(lua2, "");
	assert(dmlEngine.item!Item("item2").nativeProperty == 100);
	dmlEngine.execute("item2.nativeProperty = item2.nativeProperty * 2", "");
	assert(dmlEngine.item!Item("item2").nativeProperty == 200);

	// Test virtual property
	string lua3 = q"(
		Item {
			id = "item3",
			virtualProperty = 1000,
			nativeProperty = 100
		}
		item3.nativeProperty = item3.virtualProperty + item3.nativeProperty
	)";
	dmlEngine.execute(lua3, "");
	assert(dmlEngine.item!Item("item3").nativeProperty == 1100);

	// Test signals
	string lua4 = q"(
		Item {
			id = "item4",
			nativeTotalProperty = 0,
			virtualProperty = 1000,
			onVirtualPropertyChanged = function()
				item4.nativeTotalProperty = item4.nativeTotalProperty + item4.virtualProperty
				print("onVirtualPropertyChanged")
			end,
			nativeProperty = 100,
			onNativePropertyChanged = function()
				item4.nativeTotalProperty = item4.nativeTotalProperty + item4.nativeProperty
				print("onNativePropertyChanged")
			end,
		}
		item4.virtualProperty = 10000
		item4.nativeProperty = 500
	)";
	dmlEngine.execute(lua4, "");
	assert(dmlEngine.item!Item("item4").nativeTotalProperty == 10500);

	// Test property binding
	string lua5 = q"(
		Item {
			id = "item5",
			nativeProperty = 100
		}
		Item {
			id = "item6",
			virtualProperty = function()
				return item5.nativeProperty + 50
			end
		}
		Item {
			id = "item7",
			nativeTotalProperty = function()
				return item6.virtualProperty + 25
			end
		}
	)";
	dmlEngine.execute(lua5, "");
	assert(dmlEngine.item!Item("item7").nativeTotalProperty == 175);

	// Test property binding loop detection
	/*string lua6 = q"(
		Item {
			id = "item8",
			nativeProperty = function()
				return item10.nativeTotalProperty + 100
			end
		}
		Item {
			id = "item9",
			virtualProperty = function()
				return item8.nativeProperty + 50
			end
		}
		Item {
			id = "item10",
			nativeTotalProperty = function()
				return item9.virtualProperty + 25
			end
		}
	)";
	dmlEngine.execute(lua6, "");*/

	// Test enums
	string lua7 = q"(
		Item {
			id = "item11",
			nativeEnumProperty = Item.Enum.enumVal2
		}
	)";
	dmlEngine.execute(lua7, "");
	assert(dmlEngine.item!Item("item11").nativeEnumProperty == Item.Enum.enumVal2);

	// Test simple property alias (parent to child)
	string lua8 = q"(
		Item {
			id = "item12",
			nativePropertyAlias = 100,

			Item {
				id = "item13",
				nativeProperty = function()
					return item12.nativePropertyAlias
				end
			}
		}
		item12.nativePropertyAlias = 200
	)";
	dmlEngine.execute(lua8, "");
	assert(dmlEngine.item!Item("item13").nativeProperty == 200);

	// Test 2 ways property alias (parent to child and parent to child, usefull for buttons that can be checked from qml or mouse input)
	string lua9 = q"(
		Item {
			id = "item14",

			Item {
				id = "item15",
				nativeProperty = 100,
				onNativePropertyChanged = function()
					item14.nativePropertyAlias = item15.nativeProperty
					print(item14.nativePropertyAlias)
				end,
			},
			nativePropertyAlias = item15.nativeProperty,
			onNativePropertyAliasChanged = function()
				item15.nativeProperty = item14.nativePropertyAlias
			end,

			nativeTotalProperty = function() -- To test property nativeTotalProperty from D
				return item14.nativePropertyAlias
			end,
		}
	)";
	dmlEngine.execute(lua9, "");
	assert(dmlEngine.item!Item("item15").nativeProperty == 100); // Test init value propagation

	dmlEngine.execute("item14.nativePropertyAlias = 200", "");
	assert(dmlEngine.item!Item("item15").nativeProperty == 200); // Test propagation from parent to child

	dmlEngine.item!Item("item15").nativeProperty = 300;
	assert(dmlEngine.item!Item("item14").nativeTotalProperty == 300); // Test propagation from child to parent

	// Test function binding
	dmlEngine.addFunction!(testSumFunctionBinding, "testSumFunctionBinding")();
	string lua10 = q"(
		test = testSumFunctionBinding(100, 200)
	)";
	dmlEngine.execute(lua10, "");
	assert(dmlEngine.getLuaGlobal!int("test") == 300);
}

class DMLEngine
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
		luaL_openlibs(mLuaState);
		lua_atpanic(mLuaState, cast(lua_CFunction)&luaPanicFunction);
		initializationPhase = false;
		static if (showDebug)
			lvl = 0;
	}

	void	destroy()
	{
		if (mLuaState)
		{
			lua_close(mLuaState);
			mLuaState = null;
		}
		mDeclarativeItems = null;
	}

	void	addItemType(type, string luaName)()
	{
		// Create a lua table to host enums
		lua_newtable(mLuaState);
		{
			// Add enums
			foreach (member; __traits(allMembers, type))
			{
				static if (__traits(compiles, EnumMembers!(__traits(getMember, type, member))) && is(OriginalType!(__traits(getMember, type, member)) == int)) // If its an int enum
				{
					// Create enum table
					lua_pushstring(mLuaState, member.toStringz());
					lua_newtable(mLuaState);
					{
						auto enumMembers = EnumMembers!(__traits(getMember, type, member));
						foreach (enumMember; enumMembers)
						{
							lua_pushstring(mLuaState, to!(string)(enumMember).toStringz());
							lua_pushinteger(mLuaState, cast(int)enumMember);

							lua_settable(mLuaState, -3);
						}
					}
					lua_settable(mLuaState, -3);
				}
			}

			// Create metatable
			lua_newtable(mLuaState);
			{
				// Call metamethod to instanciate type
				lua_pushstring(mLuaState, "__call");
				lua_pushcfunction(mLuaState, cast(lua_CFunction)&createLuaBind!type);
				lua_settable(mLuaState, -3);
			}
			lua_setmetatable(mLuaState, -2);
		}
		// Add type to a global
		lua_setglobal(mLuaState, luaName.toStringz());
	}

	void	addFunction(alias func, string luaName)()
	{
		static assert(isSomeFunction!func, "func must be a function");

		lua_pushcfunction(mLuaState, cast(lua_CFunction)&functionLuaBind!func);
		lua_setglobal(mLuaState, luaName.toStringz());
	}

	bool	isCreated()
	{
		return mLuaState != null;
	}

	void	executeFile(string filePath)
	{
		assert(isCreated());

		string	text;
		text = cast(string)read(filePath);
		execute(text, filePath);
	}

	void	execute(string text, string filePath)
	{
		assert(isCreated());

		GC.disable();
		//scope(exit) GC.enable();

		lua_pushstring(luaState(), "__This");
		lua_pushlightuserdata(luaState(), cast(void*)this);
		lua_settable(luaState(), LUA_REGISTRYINDEX);

		initializationPhase = true;

		static if (showDebug)
			writeln("CREATE ==================================================================================================");

		if (luaL_loadbuffer(luaState(), cast(const char*)text.ptr, text.length, filePath.toStringz()) != LUA_OK)
		{
			const char* error = lua_tostring(luaState(), -1);
			writeln("DMLEngine.execute: error: " ~ to!(string)(error));
			lua_pop(luaState(), 1);
			assert(false);

			version (release)
			{
				return;
			}
		}

		if (lua_pcall(luaState(), 0, LUA_MULTRET, 0) != LUA_OK)
		{
			const char* error = lua_tostring(luaState(), -1);
			writeln("DMLEngine.execute: error: " ~ to!(string)(error));
			lua_pop(luaState(), 1);
			assert(false);

			version (release)
			{
				return;
			}
		}

		static if (showDebug)
			writeln("INIT ==================================================================================================");
		foreach (key, binding; mDeclarativeItems)
			binding.executeBindings();
		initializationPhase = false;


		static if (showDebug)
		{
			writeln("DEPENDANCY TREE ==================================================================================================");
			foreach (key, binding; mDeclarativeItems)
				writefln("%s\n%s", key, shiftRight(binding.displayDependents(), "\t", 1));
			writeln("=======================================================================================================");
		}
	}

	void	execute(int functionRef)
	{
		lua_rawgeti(luaState(), LUA_REGISTRYINDEX, functionRef);
		if (lua_pcall(luaState(), 0, LUA_MULTRET, 0) != LUA_OK)
		{
			const char* error = lua_tostring(luaState(), -1);
			writeln("DMLEngine.execute: error: " ~ to!(string)(error));
			lua_pop(luaState(), 1);
			assert(false);

			version (release)
			{
				currentlyExecutedBindingRef = -1;
				return;
			}
		}
	}

	package lua_State*	luaState()
	{
		return mLuaState;
	}

	DeclarativeItem	rootItem()
	{
		foreach (key, binding; mDeclarativeItems)
		{
			if (binding.declarativeItem.parent() is null)
			{
				writeln("rootItem " ~ binding.declarativeItem.id);
				return binding.declarativeItem;
			}
		}
		foreach (binding; mAnonymousDeclarativeItems)
		{
			if (binding.declarativeItem.parent() is null)
			{
				writeln("rootItem is anonymous");
				return binding.declarativeItem;
			}
		}
		return null;
	}

	T	item(T)(string id)
	{
		foreach (key, binding; mDeclarativeItems)
		{
			if (binding.declarativeItem.id == id)
			{
				return cast(T)binding.declarativeItem;
			}
		}
		foreach (binding; mAnonymousDeclarativeItems)
		{
			if (binding.declarativeItem.id == id)
			{
				return cast(T)binding.declarativeItem;
			}
		}
		return null;
	}

	T	getLuaGlobal(T)(string name)
	{
		lua_getglobal(mLuaState, name.toStringz());
		T	value = dquick.script.utils.valueFromLua!T(mLuaState, -1);
		lua_pop(mLuaState, 1);
		return value;
	}

	static immutable bool showDebug = 0;
private:
	dquick.script.i_item_binding.IItemBinding[string]	mDeclarativeItems;
	dquick.script.i_item_binding.IItemBinding[]			mAnonymousDeclarativeItems;
	lua_State*	mLuaState;
	IWindow		mWindow;
	package dquick.script.property_binding.PropertyBinding[]		currentlyExecutedBindingStack;
	string		itemTypeIds;
	package alias TypeTuple!(int, float, string, bool)	propertyTypes;
	package bool	initializationPhase;
	static if (showDebug)
		package int	lvl;
}

extern(C)
{
	private int	luaPanicFunction(lua_State* L)
	{
		try
		{
			const char* error = lua_tostring(L, 1);
			writeln("[DMLEngine] " ~ to!(string)(error));
			lua_pop(L, 1);
			assert(false);

			version(release)
			{
				return 1;
			}
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
			if (lua_gettop(L) != 2)
			{
				writefln("createLuaBind:: too few or too many param, got %d, expected 1\n", lua_gettop(L));
				return 0;
			}
			if (!lua_istable(L, 1))
			{
				writeln("createLuaBind:: the lua value is not a table\n");
				return 0;
			}
			if (!lua_istable(L, 2))
			{
				writeln("createLuaBind:: the lua value is not a table\n");
				return 0;
			}

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngine	dmlEngine = cast(DMLEngine)lua_touserdata(L, -1);
			lua_pop(L, 1);

			dquick.script.item_binding.ItemBinding!T	itemBinding = new dquick.script.item_binding.ItemBinding!T(dmlEngine);

			/* table is in the stack at index 't' */
			lua_pushnil(L);  /* first key */
			while (lua_next(L, -2) != 0) {
				/* uses 'key' (at index -2) and 'value' (at index -1) */

				if (lua_type(L, -2) == LUA_TSTRING)
				{
					string	key = to!(string)(lua_tostring(L, -2));

					if (key == "id")
					{
						itemBinding.item.id = to!(string)(lua_tostring(L, -1));
					}
					else
					{
						bool	found = false;
						foreach (member; __traits(allMembers, typeof(itemBinding)))
						{
							//writefln("member = %s", member);
							static if (is(typeof(__traits(getMember, itemBinding, member)) : dquick.script.property_binding.PropertyBinding))
							{
								if (key == member)
								{
									found = true;
									__traits(getMember, itemBinding, member).bindingFromLua(L, -1);
									break;
								}
								else if (key == getSignalNameFromPropertyName(member))
								{
									found = true;

									if (lua_isfunction(L, -1))
									{
										__traits(getMember, itemBinding, member).slotLuaReference = luaL_ref(L, LUA_REGISTRYINDEX);
										lua_pushnil(L); // To compensate the value poped by luaL_ref
									}
									else
										writefln("createLuaBind:: Attribute %s is not a function", key);
									break;
								}
							}
						}

						if (found == false)
						{
							auto	propertyName = getPropertyNameFromSignalName(key);
							if (propertyName != "")
							{
								found = true;

								if (lua_isfunction(L, -1))
								{
									dquick.script.virtual_property_binding.VirtualPropertyBinding virtualProperty;
									auto virtualPropertyPtr = (propertyName in itemBinding.virtualProperties);
									if (!virtualPropertyPtr)
									{
										virtualProperty = new dquick.script.virtual_property_binding.VirtualPropertyBinding(itemBinding, propertyName);
										itemBinding.virtualProperties[propertyName] = virtualProperty;
									}
									else
									{
										virtualProperty = *virtualPropertyPtr;
									}
									virtualProperty.slotLuaReference = luaL_ref(L, LUA_REGISTRYINDEX);
									lua_pushnil(L); // To compensate the value poped by luaL_ref
								}
								else
									writefln("createLuaBind:: Attribute %s is not a function", key);
							}
							else
							{
								dquick.script.virtual_property_binding.VirtualPropertyBinding virtualProperty;
								auto virtualPropertyPtr = (key in itemBinding.virtualProperties);
								if (!virtualPropertyPtr)
								{
									virtualProperty = new dquick.script.virtual_property_binding.VirtualPropertyBinding(itemBinding, key);
									itemBinding.virtualProperties[key] = virtualProperty;
								}
								else
								{
									virtualProperty = *virtualPropertyPtr;
								}
								virtualProperty.bindingFromLua(L, -1);
							}
						}
					}
				}
				else if (lua_type(L, -2) == LUA_TNUMBER)
				{
					string	itemId = to!(string)(cast(char*)lua_touserdata(L, -1));

					auto	child = itemId in dmlEngine.mDeclarativeItems;
					if (child == null)
					{
						writeln("createLuaBind:: can't find item \"%s\"\n", itemId);
						return 0;
					}

					itemBinding.item.addChild(child.declarativeItem);
				}

				/* removes 'value'; keeps 'key' for next iteration */
				lua_pop(L, 1);
			}
			lua_pop(L, 1); // Remove param 1 (table)

			if (itemBinding.item.id == "")
			{
				dmlEngine.mAnonymousDeclarativeItems ~= itemBinding;
			}
			else
			{
				if (itemBinding.item.id in dmlEngine.mDeclarativeItems)
				{
					writefln("createLuaBind:: an item with id \"%s\" already exist\n", itemBinding.item.id);
					return 0;
				}
				dmlEngine.mDeclarativeItems[itemBinding.item.id] = cast(dquick.script.i_item_binding.IItemBinding)itemBinding;
			}

			itemBinding.creating = false;

			void*	userData = lua_newuserdata(L, itemBinding.item.id().length + 1);
			memcpy(userData, itemBinding.item.id().toStringz(), itemBinding.item.id().length + 1);

			lua_newtable(L);

			lua_pushstring(L, "__index");
			lua_pushcfunction(L, cast(lua_CFunction)&indexLuaBind!T);
			lua_settable(L, -3);
			lua_pushstring(L, "__newindex");
			lua_pushcfunction(L, cast(lua_CFunction)&newindexLuaBind!T);
			lua_settable(L, -3);

			lua_setmetatable(L, -2);

			if (itemBinding.item.id() != "")
			{
				lua_pushvalue(L, -1); // Copy userdata to compensate lua_setglobal pop
				lua_setglobal(L, itemBinding.item.id().toStringz());
			}

			return 1;
		}
		catch (Throwable e)
		{
			writeln(e.toString());
			return 0;
		}
	}

	private int	indexLuaBind(T)(lua_State* L)
	{
		try
		{
			if (lua_gettop(L) != 2)
			{
				writefln("indexLuaBind:: too few or too many param, got %d, expected 2\n", lua_gettop(L));
				return 0;
			}
			if (!lua_isuserdata(L, 1))
			{
				writeln("indexLuaBind:: param 1 is not a userdata\n");
				return 0;
			}
			if (!lua_isstring(L, 2))
			{
				writeln("indexLuaBind:: param 2 is not a string\n");
				return 0;
			}

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngine	dmlEngine = cast(DMLEngine)lua_touserdata(L, -1);
			lua_pop(L, 1);

			string	itemId = to!(string)(cast(char*)lua_touserdata(L, 1));
			string	propertyId = to!(string)(lua_tostring(L, 2));

			auto	iItemBinding = itemId in dmlEngine.mDeclarativeItems;
			if (iItemBinding == null)
				return 0;
			dquick.script.item_binding.ItemBinding!T	itemBinding = cast(dquick.script.item_binding.ItemBinding!T)(*iItemBinding);

			foreach (member; __traits(allMembers, typeof(itemBinding)))
			{
				static if (is(typeof(__traits(getMember, itemBinding, member)) : dquick.script.property_binding.PropertyBinding))
				{
					if (propertyId == member)
					{
						__traits(getMember, itemBinding, member).valueToLua(L);
						return 1;
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
			writeln(e.toString());
			return 0;
		}
	}

	private int	newindexLuaBind(T)(lua_State* L)
	{
		try
		{
			if (lua_gettop(L) != 3)
			{
				writefln("newindexLuaBind:: too few or too many param, got %d, expected 3\n", lua_gettop(L));
				return 0;
			}
			if (!lua_isuserdata(L, 1))
			{
				writeln("newindexLuaBind:: param 1 is not a string\n");
				return 0;
			}
			if (!lua_isstring(L, 2))
			{
				writeln("newindexLuaBind:: param 2 is not a string\n");
				return 0;
			}

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngine	dmlEngine = cast(DMLEngine)lua_touserdata(L, -1);
			lua_pop(L, 1);

			string	itemId = to!(string)(cast(char*)lua_touserdata(L, 1));
			string	propertyId = to!(string)(lua_tostring(L, 2));

			auto	iItemBinding = itemId in dmlEngine.mDeclarativeItems;
			if (iItemBinding == null)
				return 0;
			dquick.script.item_binding.ItemBinding!T	itemBinding = cast(dquick.script.item_binding.ItemBinding!T)(*iItemBinding);

			bool	found = false;
			foreach (member; __traits(allMembers, typeof(itemBinding)))
			{
				static if (is(typeof(__traits(getMember, itemBinding, member)) : dquick.script.property_binding.PropertyBinding))
				{
					if (propertyId == member)
					{
						found = true;
						__traits(getMember, itemBinding, member).bindingFromLua(L, 3);
						__traits(getMember, itemBinding, member).dirty = true;
						if (dmlEngine.initializationPhase == false)					
							__traits(getMember, itemBinding, member).executeBinding();
						return 1;
					}
				}
			}

			auto virtualProperty = (propertyId in itemBinding.virtualProperties);
			if (virtualProperty)
			{
				virtualProperty.bindingFromLua(L, 3);
				virtualProperty.dirty = true;
				virtualProperty.executeBinding();
				return 1;
			}

			writefln("newindexLuaBind:: Property %s doesn't exist on object %s", propertyId, itemId);
			return 0;
		}
		catch (Throwable e)
		{
			writeln(e.toString());
			return 0;
		}
	}

	// Handle simple function binding
	private int	functionLuaBind(alias func)(lua_State* L)
	{
		try
		{
			static assert(isSomeFunction!func, "func must be a function");

			// Collect all argument in a tuple
			alias ParameterTypeTuple!func MyParameterTypeTuple;
			MyParameterTypeTuple	parameterTuple;
			foreach (index, paramType; MyParameterTypeTuple)
				parameterTuple[index] = dquick.script.utils.valueFromLua!paramType(L, index + 1);

			// Call D function
			ReturnType!func returnVal = func(parameterTuple);

			// Write return value into lua stack
			valueToLua(L, returnVal);

			return 1;
		}
		catch (Throwable e)
		{
			writeln(e.toString());
			return 0;
		}
	}
}
