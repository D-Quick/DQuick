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
import std.path;

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
			idProperty = new typeof(idProperty)(this, this);
			nativePropertyProperty = new typeof(nativePropertyProperty)(this, this);
			onNativePropertyChanged.connect(&nativePropertyProperty.onChanged); // Signal
		}

		dquick.script.nativePropertyBinding.NativePropertyBinding!(string, SubItem, "id")	idProperty;
		override string	id() { return DeclarativeItem.id(); }
		override void	id(string value) { return DeclarativeItem.id(value); }

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
			idProperty = new typeof(idProperty)(this, this);

			nativePropertyProperty = new typeof(nativePropertyProperty)(this, this);
			onNativePropertyChanged.connect(&nativePropertyProperty.onChanged); // Signal

			nativeTotalPropertyProperty = new typeof(nativeTotalPropertyProperty)(this, this);
			onNativeTotalPropertyChanged.connect(&nativeTotalPropertyProperty.onChanged); // Signal

			nativeEnumPropertyProperty = new typeof(nativeEnumPropertyProperty)(this, this);
			onNativeEnumPropertyChanged.connect(&nativeEnumPropertyProperty.onChanged); // Signal

			nativeSubItemProperty = new typeof(nativeSubItemProperty)(this, this);
			onNativeSubItemChanged.connect(&nativeSubItemProperty.onChanged); // Signal
		}

		dquick.script.nativePropertyBinding.NativePropertyBinding!(string, Item, "id")	idProperty;
		override string	id() { return DeclarativeItem.id(); }
		override void	id(string value) { return DeclarativeItem.id(value); }

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
	try
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
	assert(dmlEngine.getLuaGlobal!Item("item1") !is null);
	assert(dmlEngine.rootItemBinding!DeclarativeItem() !is null);
	assert(dmlEngine.rootItemBinding!DeclarativeItem().id == "item1");

	// Test native property
	string lua2 = q"(
		Item {
			id = "item2",
			nativeProperty = 100
		}
	)";
	dmlEngine.execute(lua2, "");
	assert(dmlEngine.getLuaGlobal!Item("item2").nativeProperty == 100);
	dmlEngine.execute("item2.nativeProperty = item2.nativeProperty * 2", "");
	assert(dmlEngine.getLuaGlobal!Item("item2").nativeProperty == 200);

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
	assert(dmlEngine.getLuaGlobal!Item("item3").nativeProperty == 1100);

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
	assert(dmlEngine.getLuaGlobal!Item("item4").nativeTotalProperty == 10500);

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
	assert(dmlEngine.getLuaGlobal!Item("item7").nativeTotalProperty == 175);

	// Test native property anti hijack protection (property assignment from D that compete with his binding)
	{
		string lua = q"(
			Item {
				id = "item7_1",
				nativeProperty = function()
					return 100
				end
			}
		)";
		dmlEngine.execute(lua, "");
		assert(dmlEngine.getLuaGlobal!Item("item7_1").nativeProperty == 100);
		dmlEngine.getLuaGlobal!Item("item7_1").nativeProperty = 200;
		assert(dmlEngine.getLuaGlobal!Item("item7_1").nativeProperty == 100);
	}

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
	assert(dmlEngine.getLuaGlobal!Item("item11").nativeEnumProperty == Item.Enum.enumVal2);

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
	assert(dmlEngine.getLuaGlobal!Item("item13").nativeProperty == 200);

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
	assert(dmlEngine.getLuaGlobal!Item("item15").nativeProperty == 100); // Test init value propagation

	dmlEngine.execute("item14.nativePropertyAlias = 200", "");
	assert(dmlEngine.getLuaGlobal!Item("item15").nativeProperty == 200); // Test propagation from parent to child

	dmlEngine.getLuaGlobal!Item("item15").nativeProperty = 300;
	assert(dmlEngine.getLuaGlobal!Item("item14").nativeTotalProperty == 300); // Test propagation from child to parent

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

	// Component
	{
		string	subComponent = q"(
			Item {
				id = "subComponentRoot",
				virtualProperty = 600,
				nativeProperty = function()
					return item1800.nativeProperty
				end,
				Item {
					id = "item1800",
					virtualProperty = function()
						return subComponentRoot.virtualProperty
					end,
					nativeProperty = function()
						return item1800.virtualProperty
					end,
				},
			}
		)";
		std.file.write("SubComponent.lua", subComponent);
		string	component = q"(
			ImportComponent("SubComponent.lua")
			Item {
				id = "componentRoot",
				virtualProperty = 200,
				nativeProperty = function()
					return item180.nativeProperty
				end,
				SubComponent {
					id = "item180",
					virtualProperty = function()
						return componentRoot.virtualProperty
					end,
				},
			}
		)";
		std.file.write("Component.lua", component);
		string lua = q"(
			ImportComponent("Component.lua")
			Item {
				id = "item16",
				Component {
					id = "item17",
					virtualProperty = 300,
					nativeTotalProperty = function()
						return item18.virtualProperty
					end,
				},
				Component {
					id = "item18",
					virtualProperty = 400,
				},
			}
		)";
		dmlEngine.execute(lua, "");
		Item	item17 = dmlEngine.getLuaGlobal!Item("item17");
		Item	item18 = dmlEngine.getLuaGlobal!Item("item18");
		assert(item17 !is null);
		assert(item18 !is null);
		assert(item17.nativeProperty == 300);
		assert(item17.nativeTotalProperty == 400);
		assert(item18.nativeProperty == 400);
	}

	// Explicit this
	{
		string lua = q"(
			Item {
				id = "item19",
				virtualProperty = 10,
				nativeProperty = function()
					return this.virtualProperty
				end,
				onNativePropertyChanged = function()
					this.nativeTotalProperty = this.virtualProperty
				end
			}
		)";
		dmlEngine.execute(lua, "");
		assert(dmlEngine.getLuaGlobal!Item("item19").nativeProperty == 10);
		assert(dmlEngine.getLuaGlobal!Item("item19").nativeTotalProperty == 10);
	}

	// Implicit this
	{
		string lua = q"(
			Item {
				id = "item20",
				virtualProperty = 10,
				nativeProperty = function()
					return virtualProperty
				end,
				onNativePropertyChanged = function()
					nativeTotalProperty = virtualProperty
				end
			}
		)";
		dmlEngine.execute(lua, "");
		assert(dmlEngine.getLuaGlobal!Item("item20").nativeProperty == 10);
		assert(dmlEngine.getLuaGlobal!Item("item20").nativeTotalProperty == 10);
	}
	}
	catch (Throwable e)
	{
		writeln(e.toString());
		int toto = 10;
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

		luaState = luaL_newstate();
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
	}

	void	destroy()
	{
		if (luaState)
		{
			lua_close(luaState);
			luaState = null;
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
				object.dmlEngine = this;
				assert(find(mItems, object) == [], format("Object \"%s\" is already added", id));
				mItems ~= object;
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

		mReentrencyLevel++;
		size_t	itemCount = mItems.length;

		// Save _ENV
		lua_getupvalue(luaState, -1, 1);
		mEnvStack ~= luaL_ref(luaState, LUA_REGISTRYINDEX);

		static if (showDebug)
			writeln("CREATE ==================================================================================================");

		if (lua_pcall(luaState, 0, LUA_MULTRET, 0) != LUA_OK)
		{
			string error = to!(string)(lua_tostring(luaState, -1));
			lua_pop(luaState, 1);
			throw new Exception(format("lua_pcall error: %s", error));
		}

		luaL_unref(luaState, LUA_REGISTRYINDEX, mEnvStack[mEnvStack.length - 1]);
		mEnvStack.length--;

		if (mReentrencyLevel == 1) // Call bindings only after the last execute to avoid errors in bindings due to partial creation
		{
			static if (showDebug)
				writeln("INIT ==================================================================================================");
			for (size_t index = itemCount; index < mItems.length; index++)
				mItems[index].executeBindings();

			static if (showDebug)
			{
				writeln("DEPENDANCY TREE ==================================================================================================");
				for (size_t index = 0; index < mItems.length; index++)
					writefln("%s\n%s", mItems[index].id, shiftRight(mItems[index].displayDependents(), "\t", 1));
				writeln("=======================================================================================================");
			}
		}
		mReentrencyLevel--;
	}

	void	execute(string text, string filePath)
	{
		load(text, filePath);
		execute();
	}

	void	execute(int functionRef)
	{
		lua_rawgeti(luaState, LUA_REGISTRYINDEX, functionRef);
		if (lua_pcall(luaState, 0, LUA_MULTRET, 0) != LUA_OK)
		{
			const char* error = lua_tostring(luaState, -1);
			writeln("DMLEngineCore.execute: error: " ~ to!(string)(error));
			lua_pop(luaState, 1);
			assert(false);

			version (release)
			{
				currentlyExecutedBindingRef = -1;
				return;
			}
		}
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

	static immutable bool showDebug = 0;

	int		currentLuaEnv()
	{
		assert(mEnvStack.length > 0);
		return mEnvStack[mEnvStack.length - 1];
	}

protected:
	dquick.script.iItemBinding.IItemBinding[]		mItems;
	dquick.script.iItemBinding.IItemBinding			mLastItemBindingCreated;
	
	package lua_State*	luaState;
	IWindow		mWindow;
	package dquick.script.propertyBinding.PropertyBinding[]		currentlyExecutedBindingStack;
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
			if (lua_gettop(L) != 2)
				throw new Exception(format("too few or too many param, got %d, expected 1\n", lua_gettop(L)));
			if (!lua_istable(L, 1))
				throw new Exception(format("Lua value at index %d is a \"%s\", a table was expected\n", 1, getLuaTypeName(L, 1)));
			if (!lua_istable(L, 2))
				throw new Exception(format("Lua value at index %d is a \"%s\", a table was expected\n", 2, getLuaTypeName(L, 2)));

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			T	itemBinding = new T();
			dmlEngine.addObjectBinding!T(itemBinding);

			lua_remove(L, 1);
			itemBinding.valueFromLua(L);

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
						throw new Exception(format("An item with id \"%s\" already exist in that component", itemBinding.id));
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
			luaL_error(L, e.msg.toStringz());
			return 0;
		}
	}

	private int	indexLuaBind(T)(lua_State* L)
	{
		try
		{
			if (lua_gettop(L) != 2)
				throw new Exception(format("too few or too many param, got %d, expected 1\n", lua_gettop(L)));
			if (!lua_isuserdata(L, 1))
				throw new Exception(format("Lua value at index %d is a \"%s\", a userdata was expected\n", 1, getLuaTypeName(L, 1)));
			if (!lua_isstring(L, 2))
				throw new Exception(format("Lua value at index %d is a \"%s\", a string was expected\n", 2, getLuaTypeName(L, 2)));

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
								lua_pushcfunction(L, cast(lua_CFunction)&methodCallLuaBind!(member, typeof(itemBinding)));
								lua_settable(L, -3);
								// Index metamethod to warn user that it's a method
								lua_pushstring(L, "__index");
								lua_pushcfunction(L, cast(lua_CFunction)&methodIndexLuaBind!(member, typeof(itemBinding)));
								lua_settable(L, -3);
								// newIndex metamethod to warn user that it's a method
								lua_pushstring(L, "__newindex");
								lua_pushcfunction(L, cast(lua_CFunction)&methodNewIndexLuaBind!(member, typeof(itemBinding)));
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
			luaL_error(L, e.msg.toStringz());
			return 0;
		}
	}

	private int	newindexLuaBind(T)(lua_State* L)
	{
		try
		{
			if (lua_gettop(L) != 3)
				throw new Exception(format("too few or too many param, got %d, expected 3\n", lua_gettop(L)));
			if (!lua_isuserdata(L, 1))
				throw new Exception(format("Lua value at index %d is a \"%s\", a userdata was expected\n", 1, getLuaTypeName(L, 1)));
			if (!lua_isstring(L, 2))
				throw new Exception(format("Lua value at index %d is a \"%s\", a string was expected\n", 2, getLuaTypeName(L, 2)));

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
						return 1;
					}
				}
			}

			auto virtualProperty = (propertyId in itemBinding.virtualProperties);
			if (virtualProperty)
			{
				virtualProperty.bindingFromLua(L, 1);
				virtualProperty.executeBinding();
				return 1;
			}

			writefln("newindexLuaBind:: Property %s doesn't exist on object %s", propertyId, itemBinding);
			return 0;
		}
		catch (Throwable e)
		{
			luaL_error(L, e.msg.toStringz());
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
	private int	methodCallLuaBind(string methodName, T)(lua_State* L)
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
				throw new Exception(format("Lua value at index %d is a \"%s\", a userdata was expected\n", 1, getLuaTypeName(L, 1)));

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			T	itemBinding;
			dquick.script.utils.valueFromLua!(T)(L, 1, itemBinding);
			lua_remove(L, 1);
			assert(itemBinding !is null);

			luaCallThisD!(methodName, T)(itemBinding, L, 1);

			return 1;
		}
		catch (Throwable e)
		{
			luaL_error(L, e.msg.toStringz());
			return 0;
		}
	}
	// Index metamethod to warn user that it's a method
	private int	methodIndexLuaBind(string methodName, T)(lua_State* L)
	{
		luaL_error(L, "methodIndexLuaBind: attempt to index a method");
		return 0;
	}
	// newIndex metamethod to warn user that it's a method
	private int	methodNewIndexLuaBind(string methodName, T)(lua_State* L)
	{
		luaL_error(L, "methodIndexLuaBind: attempt to assign a method");
		return 0;
	}

	private int	importComponentLuaBind(lua_State* L)
	{
		try
		{
			if (lua_gettop(L) != 1)
				throw new Exception(format("too few param, got %d, expected 1\n", lua_gettop(L)));
			if (!lua_isstring(L, 1))
				throw new Exception(format("Lua value at index %d is a \"%s\", a string was expected\n", 1, getLuaTypeName(L, 1)));

			string	path = to!(string)(lua_tostring(L, 1));
			lua_pop(L, 1);

			lua_pushstring(L, "__This");
			lua_gettable(L, LUA_REGISTRYINDEX);
			DMLEngineCore	dmlEngine = cast(DMLEngineCore)lua_touserdata(L, -1);
			lua_pop(L, 1);

			string	varName = baseName(stripExtension(path));
			lua_getglobal(L, varName.toStringz());
			if (lua_iscfunction(L, -1) == false)
			{
				lua_pushstring(dmlEngine.luaState, path.toStringz());
				lua_pushcclosure(dmlEngine.luaState, cast(lua_CFunction)&createComponentLuaBind, 1);
				// Add type to a global
				lua_setglobal(dmlEngine.luaState, varName.toStringz());
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

			return 1;
		}
		catch (Throwable e)
		{
			writeln(e.toString());
			return 0;
		}
	}

	private int	createComponentLuaBind(lua_State* L)
	{
		try
		{
			if (lua_gettop(L) != 1)
				throw new Exception(format("too few or too many param, got %d, expected 1\n", lua_gettop(L)));
			if (!lua_istable(L, 1))
				throw new Exception("the lua value is not a table\n");

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
			dmlEngine.load(lua, "");
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

			// Set table to _ENV upvalue
			lua_setupvalue(dmlEngine.luaState, -2, 1);
			// Execute component code
			dmlEngine.execute();

			dquick.script.iItemBinding.IItemBinding	iItemBinding = dmlEngine.rootItemBinding!(dquick.script.iItemBinding.IItemBinding)();
			if (iItemBinding is null)
				throw new Exception("\"Button\" component has no root item");

			string	componentId;
			lua_pushstring(L, "id");
			lua_gettable(L, -2);
			if (lua_isnil(L, -1) == false)
				componentId = to!(string)(lua_tostring(L, -1));
			lua_pop(L, 1);

			iItemBinding.valueFromLua(L);
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
						throw new Exception(format("An item with id \"%s\" already exist in that component", componentId));
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
			writeln(e.toString());
			return 0;
		}
	}
}