module dquick.script.dmlEngineCore;

import derelict.lua.lua;

import dquick.item.declarativeItem;
import dquick.item.graphicItem;
import dquick.item.imageItem;

import dquick.system.window;

import dquick.script.propertyBinding;
import dquick.script.utils;
import dquick.script.itemBinding;

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
	interface Interface : dquick.script.iItemBinding.IItemBinding
	{
		int		nativeProperty();
	}
	class SubItem : DeclarativeItem, dquick.script.iItemBinding.IItemBinding
	{
		mixin(dquick.script.itemBinding.I_ITEM_BINDING);

		this()
		{
			nativePropertyProperty = new typeof(nativePropertyProperty)(this, this);
			onNativePropertyChanged.connect(&nativePropertyProperty.onChanged); // Signal
		}

		dquick.script.nativePropertyBinding.NativePropertyBinding!(int, SubItem, "nativeProperty")	nativePropertyProperty;
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
	}
	class Item : DeclarativeItem, dquick.script.iItemBinding.IItemBinding, Interface
	{
		mixin(dquick.script.itemBinding.I_ITEM_BINDING);

		this()
		{
			nativePropertyProperty = new typeof(nativePropertyProperty)(this, this);
			onNativePropertyChanged.connect(&nativePropertyProperty.onChanged); // Signal

			nativeTotalPropertyProperty = new typeof(nativeTotalPropertyProperty)(this, this);
			onNativeTotalPropertyChanged.connect(&nativeTotalPropertyProperty.onChanged); // Signal

			nativeEnumPropertyProperty = new typeof(nativeEnumPropertyProperty)(this, this);
			onNativeEnumPropertyChanged.connect(&nativeEnumPropertyProperty.onChanged); // Signal

			nativeSubItemProperty = new typeof(nativeSubItemProperty)(this, this);
			onNativeSubItemChanged.connect(&nativeSubItemProperty.onChanged); // Signal
		}

		dquick.script.nativePropertyBinding.NativePropertyBinding!(int, Item, "nativeProperty")	nativePropertyProperty;
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

		dquick.script.nativePropertyBinding.NativePropertyBinding!(int, Item, "nativeTotalProperty")	nativeTotalPropertyProperty;
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

		dquick.script.nativePropertyBinding.NativePropertyBinding!(Enum, Item, "nativeEnumProperty")	nativeEnumPropertyProperty;
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

		int	testNormalMethod(int a, int b)
		{
			return a + b + nativeProperty;
		}
		int	testNormalMethod2(Item a, Interface b)
		{
			return a.nativeProperty + b.nativeProperty + nativeProperty;
		}

		dquick.script.nativePropertyBinding.NativePropertyBinding!(SubItem, Item, "nativeSubItem")	nativeSubItemProperty;
		void	nativeSubItem(SubItem value)
		{
			if (mNativeSubItem != value)
			{
				mNativeSubItem = value;
				onNativeSubItemChanged.emit(value);
			}
		}
		SubItem		nativeSubItem()
		{
			return mNativeSubItem;
		}
		mixin Signal!(SubItem) onNativeSubItemChanged;
		SubItem		mNativeSubItem;
	}

	int	testSumFunctionBinding(int a, int b)
	{
		return a + b;
	}

	int	testSumFunctionBinding2(Item a, Interface b)
	{
		return a.nativeProperty + b.nativeProperty;
	}
}

unittest
{
	DMLEngineCore	dmlEngine = new DMLEngineCore;
	dmlEngine.create();
	dmlEngine.addObjectBindingType!(Item, "Item");

	// Test basic item
	string lua1 = q"(
		Item {
			id = "item1"
		}
	)";
	dmlEngine.execute(lua1, "");
	assert(dmlEngine.itemBinding!Item("item1") !is null);
	assert(dmlEngine.rootItemBinding() !is null);
	assert(dmlEngine.rootItemBinding().id == "item1");

	// Test native property
	string lua2 = q"(
		Item {
			id = "item2",
			nativeProperty = 100
		}
	)";
	dmlEngine.execute(lua2, "");
	assert(dmlEngine.itemBinding!Item("item2").nativeProperty == 100);
	dmlEngine.execute("item2.nativeProperty = item2.nativeProperty * 2", "");
	assert(dmlEngine.itemBinding!Item("item2").nativeProperty == 200);

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
	assert(dmlEngine.itemBinding!Item("item3").nativeProperty == 1100);

	// Test signals
	string lua4 = q"(
		Item {
			id = "item4",
			nativeTotalProperty = 0,
			virtualProperty = 1000,
			onVirtualPropertyChanged = function()
				item4.nativeTotalProperty = item4.nativeTotalProperty + item4.virtualProperty
			end,
			nativeProperty = 100,
			onNativePropertyChanged = function()
				item4.nativeTotalProperty = item4.nativeTotalProperty + item4.nativeProperty
			end,
		}
		item4.virtualProperty = 10000
		item4.nativeProperty = 500
	)";
	dmlEngine.execute(lua4, "");
	assert(dmlEngine.itemBinding!Item("item4").nativeTotalProperty == 10500);

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
	assert(dmlEngine.itemBinding!Item("item7").nativeTotalProperty == 175);

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
	assert(dmlEngine.itemBinding!Item("item11").nativeEnumProperty == Item.Enum.enumVal2);

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
	assert(dmlEngine.itemBinding!Item("item13").nativeProperty == 200);

	// Test 2 ways property alias (parent to child and parent to child, usefull for buttons that can be checked from qml or mouse input)
	string lua9 = q"(
		Item {
			id = "item14",

			Item {
				id = "item15",
				nativeProperty = 100,
				onNativePropertyChanged = function()
					item14.nativePropertyAlias = item15.nativeProperty
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
	assert(dmlEngine.itemBinding!Item("item15").nativeProperty == 100); // Test init value propagation

	dmlEngine.execute("item14.nativePropertyAlias = 200", "");
	assert(dmlEngine.itemBinding!Item("item15").nativeProperty == 200); // Test propagation from parent to child

	dmlEngine.itemBinding!Item("item15").nativeProperty = 300;
	assert(dmlEngine.itemBinding!Item("item14").nativeTotalProperty == 300); // Test propagation from child to parent

	// Test function binding
	dmlEngine.addFunction!(testSumFunctionBinding, "testSumFunctionBinding")();
	string lua10 = q"(
		test = testSumFunctionBinding(100, 200)
	)";
	dmlEngine.execute(lua10, "");
	assert(dmlEngine.getLuaGlobal!int("test") == 300);

	// Test function binding with polymorphic object parameters
	dmlEngine.addFunction!(testSumFunctionBinding2, "testSumFunctionBinding2")();
	dmlEngine.execute("test2 = testSumFunctionBinding2(item2, item3)", "");
	assert(dmlEngine.getLuaGlobal!int("test2") == 1300);

	// Test already existing class instance binding
	Item	testObject = new Item;
	dmlEngine.addObjectBinding(testObject, "testObject");
	testObject.nativeProperty = 1000;
	string lua11 = q"(
		testObject.nativeProperty = 2000;
	)";
	dmlEngine.execute(lua11, "");
	assert(testObject.nativeProperty == 2000);

	// Test normal method binding
	Item	testObject2 = new Item;
	dmlEngine.addObjectBinding(testObject2, "testObject2");
	testObject2.nativeProperty = 100;
	string lua12 = q"(
		total = testObject2.testNormalMethod(1, 10)
	)";
	dmlEngine.execute(lua12, "");
	assert(dmlEngine.getLuaGlobal!int("total") == 111);

	// Test normal method binding with polymorphic object parameters
	dmlEngine.execute("total2 = testObject2.testNormalMethod2(item2, item3)", "");
	assert(dmlEngine.getLuaGlobal!int("total2") == 1400);

	// Test subitem property binding
	{
		Item	testObject3 = new Item;
		dmlEngine.addObjectBinding(testObject3, "testObject3");

		dmlEngine.execute("subItemGlobal1 = testObject3.nativeSubItem", "");
		assert(dmlEngine.getLuaGlobal!SubItem("subItemGlobal1") is null);

		testObject3.nativeSubItem = new SubItem;
		dmlEngine.execute("subItemGlobal2 = testObject3.nativeSubItem", "");
		assert(dmlEngine.getLuaGlobal!SubItem("subItemGlobal2") !is null);

		testObject3.nativeSubItem.nativeProperty = 10;
		dmlEngine.execute("subItemGlobal3 = testObject3.nativeSubItem.nativeProperty", "");
		assert(dmlEngine.getLuaGlobal!int("subItemGlobal3") == 10);
		dmlEngine.execute("subItemGlobal4 = subItemGlobal2.nativeProperty", "");
		assert(dmlEngine.getLuaGlobal!int("subItemGlobal4") == 10);

		testObject3.nativeSubItem = new SubItem;
		testObject3.nativeSubItem.nativeProperty = 20;
		dmlEngine.execute("subItemGlobal5 = testObject3.nativeSubItem.nativeProperty", "");
		assert(dmlEngine.getLuaGlobal!int("subItemGlobal5") == 20);

		dmlEngine.addObjectBinding(testObject3, "testObject4");
		dmlEngine.execute("subItemGlobal6 = testObject3.nativeSubItem", "");
		dmlEngine.execute("subItemGlobal7 = testObject4.nativeSubItem", "");
		assert(dmlEngine.getLuaGlobal!SubItem("subItemGlobal6") is dmlEngine.getLuaGlobal!SubItem("subItemGlobal7"));

		dmlEngine.execute("testObject3.nativeSubItem.nativeProperty = 30", "");
		assert(testObject3.nativeSubItem.nativeProperty == 30);

		testObject3.nativeSubItem = new SubItem;
		dmlEngine.execute("testObject3.nativeSubItem = nil", "");
		assert(testObject3.nativeSubItem is null);
		testObject3.nativeSubItem = new SubItem;
		assert(testObject3.nativeSubItem !is null);
		testObject3.nativeSubItem = null;
		assert(testObject3.nativeSubItem is null);

		Item	testObject5 = new Item;
		dmlEngine.addObjectBinding(testObject5, "testObject5");
		dmlEngine.execute("testObject3.nativeSubItem = testObject5.nativeSubItem", "");
		assert(testObject3.nativeSubItem is null);
		testObject5.nativeSubItem = new SubItem;
		dmlEngine.execute("testObject3.nativeSubItem = testObject5.nativeSubItem", "");
		dmlEngine.execute("subItemGlobal8 = testObject3.nativeSubItem", "");
		assert(dmlEngine.getLuaGlobal!SubItem("subItemGlobal8") is testObject5.nativeSubItem);
	}
}

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
	}

	void	addObjectBindingType(type, string luaName)()
	{
		// Create a lua table to host enums and factory
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
				lua_pushcfunction(mLuaState, cast(lua_CFunction)&createLuaBind!(type));
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

	void	addObjectBinding(T)(T object, string id = "")
	{
		static assert(is(T : dquick.script.iItemBinding.IItemBinding), "object must inherit from IItemBinding");

		addObjectBindingType!(T, "__dquick_reserved1");

		if (object !is null)
		{
			object.dmlEngine = this;
			object.creating = false;
			mVoidToDeclarativeItems[cast(void*)(object)] = object;
			if (id != "")
			{
				if (id in mIdToDeclarativeItems)
					throw new Exception(format("an object with id \"%s\" already exist\n", id));
				mIdToDeclarativeItems[id] = cast(dquick.script.iItemBinding.IItemBinding)object;
			}
		}

		if (id != "")
			setLuaGlobal(id, object);
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

		//GC.disable();
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
			writeln("DMLEngineCore.execute: error: " ~ to!(string)(error));
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
			writeln("DMLEngineCore.execute: error: " ~ to!(string)(error));
			lua_pop(luaState(), 1);
			assert(false);

			version (release)
			{
				return;
			}
		}

		static if (showDebug)
			writeln("INIT ==================================================================================================");
		foreach (key, binding; mVoidToDeclarativeItems)
			binding.executeBindings();
		initializationPhase = false;

		static if (showDebug)
		{
			writeln("DEPENDANCY TREE ==================================================================================================");
			foreach (key, bindingRef; mItemsToItemBindings)
				writefln("%s\n%s", key, shiftRight(bindingRef.iItemBinding.displayDependents(), "\t", 1));
			writeln("=======================================================================================================");
		}
	}

	void	execute(int functionRef)
	{
		lua_rawgeti(luaState(), LUA_REGISTRYINDEX, functionRef);
		if (lua_pcall(luaState(), 0, LUA_MULTRET, 0) != LUA_OK)
		{
			const char* error = lua_tostring(luaState(), -1);
			writeln("DMLEngineCore.execute: error: " ~ to!(string)(error));
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

	DeclarativeItem	rootItemBinding()
	{
		foreach (key, binding; mVoidToDeclarativeItems)
		{
			DeclarativeItem	declarativeItem = cast(DeclarativeItem)(binding);
			if (declarativeItem && declarativeItem.parent() is null)
				return declarativeItem;
		}
		return null;
	}

	T	itemBinding(T)(string id)
	{
		auto iItemBinding = mIdToDeclarativeItems[id];
		if (iItemBinding !is null)
			return cast(T)(iItemBinding);
		return null;
	}

	T	getLuaGlobal(T)(string name)
	{
		lua_getglobal(mLuaState, name.toStringz());
		if (lua_isnone(mLuaState, -1) || lua_isnil(mLuaState, -1))
			throw new Exception(format("global \"%s\" is nil\n", name));

		return dquick.script.utils.valueFromLua!T(mLuaState, -1);
	}

	void	setLuaGlobal(T)(string name, T value)
	{
		dquick.script.utils.valueToLua!T(mLuaState, value);
		lua_setglobal(mLuaState, name.toStringz());
	}

	static immutable bool showDebug = 0;
protected:
	dquick.script.iItemBinding.IItemBinding[void*]	mVoidToDeclarativeItems;
	dquick.script.iItemBinding.IItemBinding[string]	mIdToDeclarativeItems;
	lua_State*	mLuaState;
	IWindow		mWindow;
	package dquick.script.propertyBinding.PropertyBinding[]		currentlyExecutedBindingStack;
	string		itemTypeIds;
	package alias TypeTuple!(int, float, string, bool, Object)	propertyTypes;
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
			writeln("[DMLEngineCore] " ~ to!(string)(error));
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
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			T	itemBinding = new T();
			itemBinding.dmlEngine = dmlEngine;
			itemBinding.creating = true;

			/* table is in the stack at index 't' */
			lua_pushnil(L);  /* first key */
			while (lua_next(L, -2) != 0) {
				/* uses 'key' (at index -2) and 'value' (at index -1) */

				if (lua_type(L, -2) == LUA_TSTRING)
				{
					string	key = to!(string)(lua_tostring(L, -2));

					if (key == "id")
					{
						itemBinding.id = to!(string)(lua_tostring(L, -1));
					}
					else
					{
						bool	found = false;
						foreach (member; __traits(allMembers, typeof(itemBinding)))
						{
							static if (is(typeof(__traits(getMember, itemBinding, member)) : dquick.script.propertyBinding.PropertyBinding))
							{
								if (key == getPropertyNameFromPropertyDeclaration(member))
								{
									found = true;
									__traits(getMember, itemBinding, member).bindingFromLua(L, -1);
									break;
								}
								else if (key == getSignalNameFromPropertyName(getPropertyNameFromPropertyDeclaration(member)))
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
									dquick.script.virtualPropertyBinding.VirtualPropertyBinding virtualProperty;
									auto virtualPropertyPtr = (propertyName in itemBinding.virtualProperties);
									if (!virtualPropertyPtr)
									{
										virtualProperty = new dquick.script.virtualPropertyBinding.VirtualPropertyBinding(itemBinding, propertyName);
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
								dquick.script.virtualPropertyBinding.VirtualPropertyBinding virtualProperty;
								auto virtualPropertyPtr = (key in itemBinding.virtualProperties);
								if (!virtualPropertyPtr)
								{
									virtualProperty = new dquick.script.virtualPropertyBinding.VirtualPropertyBinding(itemBinding, key);
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
					void*	itemBindingPtr = *(cast(void**)lua_touserdata(L, -1));
					auto	child = cast(dquick.script.iItemBinding.IItemBinding)(itemBindingPtr);
					if (child is null)
					{
						writefln("createLuaBind:: can't find item at key \"%d\"\n", lua_type(L, -2));
						return 0;
					}

					static if (__traits(hasMember, T, "addChild") == false)
					{
						writefln("createLuaBind:: can't add item at key \"%d\" as child without addChild method\n", lua_type(L, -2));
						return 0;
					}

					foreach (overload; __traits(getOverloads, T, "addChild")) 
					{
						alias ParameterTypeTuple!(overload) MyParameterTypeTuple;
						static if (MyParameterTypeTuple.length == 1)
						{
							DeclarativeItem	test = cast(DeclarativeItem)child;
							MyParameterTypeTuple[0]	castedItemBinding = cast(MyParameterTypeTuple[0])(child);
							if (castedItemBinding !is null)
								__traits(getMember, itemBinding, "addChild")(castedItemBinding);
						}
					}
				}

				/* removes 'value'; keeps 'key' for next iteration */
				lua_pop(L, 1);
			}
			lua_pop(L, 1); // Remove param 1 (table)

			itemBinding.creating = false;
			dmlEngine.addObjectBinding!T(itemBinding, itemBinding.id);
			lua_getglobal(L, itemBinding.id.toStringz());

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
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			T	itemBinding = dquick.script.utils.valueFromLua!(T)(L, 1);
			assert(itemBinding !is null);
			lua_remove(L, 1);
			string	propertyId = dquick.script.utils.valueFromLua!(string)(L, 1);
			lua_remove(L, 1);

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
							// Create a userdata that contains instance void ptr and return it to emulate a method
							// It also contains a metatable for calling
							dquick.script.iItemBinding.IItemBinding	iItemBinding = cast(dquick.script.iItemBinding.IItemBinding)itemBinding;
							void*	itemBindingVoidPtr = cast(void*)iItemBinding;
							void*	userData = lua_newuserdata(L, itemBindingVoidPtr.sizeof);
							memcpy(userData, &itemBindingVoidPtr, itemBindingVoidPtr.sizeof);

							// Create metatable
							lua_newtable(L);
							{
								// Call metamethod to instanciate type
								lua_pushstring(L, "__call");
								lua_pushcfunction(L, cast(lua_CFunction)&methodLuaBind!(member, typeof(itemBinding)));
								lua_settable(L, -3);
							}
							lua_setmetatable(L, -2);
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
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			T	itemBinding = dquick.script.utils.valueFromLua!(T)(L, 1);
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
				virtualProperty.bindingFromLua(L, 1);
				virtualProperty.dirty = true;
				virtualProperty.executeBinding();
				return 1;
			}

			writefln("newindexLuaBind:: Property %s doesn't exist on object %s", propertyId, itemBinding);
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
			static assert(__traits(isStaticFunction, func), "func must be a function");

			luaCallD!(func)(L, 1);

			return 1;
		}
		catch (Throwable e)
		{
			writeln(e.toString());
			return 0;
		}
	}

	// Handle method binding
	private int	methodLuaBind(string methodName, T)(lua_State* L)
	{
		try
		{
			static assert(isSomeFunction!(__traits(getMember, T, methodName)) &&
							!__traits(isStaticFunction, __traits(getMember, T, methodName)) &&
								!isDelegate!(__traits(getMember, T, methodName)),
							"func must be a method");

			if (lua_gettop(L) < 1)
				throw new Exception(format("too few param, got %d, expected at least 1\n", lua_gettop(L)));
			if (!lua_isuserdata(L, 1))
				throw new Exception("param 1 is not a userdata");

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			T	itemBinding = dquick.script.utils.valueFromLua!(T)(L, 1);
			lua_remove(L, 1);
			assert(itemBinding !is null);

			luaCallThisD!(methodName, T)(itemBinding, L, 1);

			return 1;
		}
		catch (Throwable e)
		{
			writeln(e.toString());
			return 0;
		}
	}
}