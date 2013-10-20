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
	class SubItem : DeclarativeItem
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
	}
	class Item : DeclarativeItem
	{
		this()
		{
		}

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

		int	testNormalMethod(int a, int b)
		{
			return a + b + nativeProperty;
		}

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
	//assert(dmlEngine.rootItem() !is null);
	//assert(dmlEngine.rootItem().id == "item1");

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

	// Test already existing class instance binding
	Item	testObject = new Item;
	dmlEngine.addObject(testObject, "testObject");
	testObject.nativeProperty = 1000;
	string lua11 = q"(
		testObject.nativeProperty = 2000;
	)";
	dmlEngine.execute(lua11, "");
	assert(testObject.nativeProperty == 2000);

	// Test normal method binding
	Item	testObject2 = new Item;
	dmlEngine.addObject(testObject2, "testObject2");
	testObject2.nativeProperty = 100;
	string lua12 = q"(
		total = testObject2.testNormalMethod(1, 10)
	)";
	dmlEngine.execute(lua12, "");
	assert(dmlEngine.getLuaGlobal!int("total") == 111);

	// Test subitem property binding
	{
		Item	testObject3 = new Item;
		dmlEngine.addObject(testObject3, "testObject3");

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

		dmlEngine.addObject(testObject3, "testObject4");
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
		dmlEngine.addObject(testObject5, "testObject5");
		dmlEngine.execute("testObject3.nativeSubItem = testObject5.nativeSubItem", "");
		assert(testObject3.nativeSubItem is null);
		testObject5.nativeSubItem = new SubItem;
		dmlEngine.execute("testObject3.nativeSubItem = testObject5.nativeSubItem", "");
		dmlEngine.execute("subItemGlobal8 = testObject3.nativeSubItem", "");
		assert(dmlEngine.getLuaGlobal!SubItem("subItemGlobal8") is testObject5.nativeSubItem);
	}

	// This
	{
		string lua = q"(
			Item {
				id = "item16",
				virtualProperty = 10,
				nativeProperty = function()
					return virtualProperty
				end
			}
		)";
		dmlEngine.execute(lua, "");
		assert(dmlEngine.item!Item("item16").nativeProperty == 10);
	}
	
	// Parent
	{
		string lua = q"(
			Item {
				virtualProperty = 100,
				Item {
					id = "item17",
					nativeProperty = function()
						return parent.virtualProperty
					end
				}
			)";
		dmlEngine.execute(lua, "");
		assert(dmlEngine.item!Item("item17").nativeProperty == 100);
	}
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
	}

	void	addItemType(type, string luaName)()
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
				lua_pushcfunction(mLuaState, cast(lua_CFunction)&createLuaBind!(dquick.script.item_binding.ItemBinding!(type)));
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

	void	addObject(T)(T object, string luaName)
	{
		addItemType!(T, "__dquick_reserved1");
		static if (is(T : DeclarativeItem))
			object.id = luaName;

		dquick.script.item_binding.ItemBinding!T	itemBinding = registerItem!T(object);
		setLuaGlobal(luaName, object);
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
		foreach (key, binding; mVoidToDeclarativeItems)
		{
			if (binding.declarativeItem.parent() is null)
			{
				writeln("rootItem " ~ binding.declarativeItem.id);
				return binding.declarativeItem;
			}
		}
		return null;
	}

	T	item(T)(string id)
	{
		auto iItemBinding = mIdToDeclarativeItems[id];
		if (iItemBinding !is null)
			return cast(T)(iItemBinding.declarativeItem);
		return null;
	}

	T	getLuaGlobal(T)(string name)
	{
		lua_getglobal(mLuaState, name.toStringz());
		if (lua_isnone(mLuaState, -1) || lua_isnil(mLuaState, -1))
			throw new Exception(format("global \"%s\" is nil\n", name));

		T	value;
		static if (is(T : dquick.item.declarative_item.DeclarativeItem))
		{
			void*	itemBindingPtr;
			itemBindingPtr = cast(void*)(dquick.script.utils.valueFromLua!(dquick.script.i_item_binding.IItemBinding)(mLuaState, -1));
			if (itemBindingPtr is null)
				return null;

			auto	iItemBinding = itemBindingPtr in mVoidToDeclarativeItems;
			assert(iItemBinding !is null);

			value = cast(T)iItemBinding.declarativeItem();
		}
		else
		{
			value = dquick.script.utils.valueFromLua!T(mLuaState, -1);
		}

		lua_pop(mLuaState, 1);
		return value;
	}

	void	setLuaGlobal(T)(string name, T value)
	{
		static if (is(T : dquick.item.declarative_item.DeclarativeItem))
		{
			dquick.script.item_binding.ItemBinding!T itemBinding = registerItem!(T)(value);
			dquick.script.utils.valueToLua!(dquick.script.item_binding.ItemBinding!T)(mLuaState, itemBinding);
		}
		else
		{
			dquick.script.utils.valueToLua!T(mLuaState, value);
		}

		lua_setglobal(mLuaState, name.toStringz());
	}

	static immutable bool showDebug = 0;
private:

	dquick.script.item_binding.ItemBinding!T	registerItem(T)(T item)
	{
		auto	refCountPtr = item in mItemsToItemBindings;
		if (refCountPtr !is null)
		{
			refCountPtr.count++;
			return cast(dquick.script.item_binding.ItemBinding!T)refCountPtr.iItemBinding;
		}

		dquick.script.item_binding.ItemBinding!T	itemBinding = new dquick.script.item_binding.ItemBinding!T(this, item);
		//static if (is(T : DeclarativeItem))
		//	itemBinding.item.id = luaName;
		addObjectBinding!(dquick.script.item_binding.ItemBinding!T)(itemBinding, "");

		ItemRefCounting	newRefCount;
		newRefCount.count = 1;
		newRefCount.iItemBinding = itemBinding;
		mItemsToItemBindings[item] = newRefCount;
		return itemBinding;
	}

	void	unregisterItem(T)(T item)
	{
		auto	refCountPtr = item in mItemsToItemBindings;
		if (refCountPtr is null)
		{
			int toto = 10;
			writefln("");
		}
		assert(refCountPtr !is null);

		refCountPtr.count--;
		if (refCountPtr.count == 0)
			mItemsToItemBindings.remove(item);
	}

	void	addObjectBinding(T)(T itemBinding, string id)
	{
		mVoidToDeclarativeItems[cast(void*)(itemBinding)] = itemBinding;

		if (id != "")
		{
			if (id in mIdToDeclarativeItems)
				throw new Exception(format("an item with id \"%s\" already exist\n", id));
			mIdToDeclarativeItems[id] = cast(dquick.script.i_item_binding.IItemBinding)itemBinding;
		}

		itemBinding.creating = false;

		if (id != "")
		{
			valueToLua!T(mLuaState, itemBinding);
			lua_setglobal(mLuaState, itemBinding.item.id().toStringz());
		}
	}

	struct ItemRefCounting
	{
		dquick.script.i_item_binding.IItemBinding	iItemBinding;
		uint										count;
	}
	ItemRefCounting[DeclarativeItem]	mItemsToItemBindings;
	dquick.script.i_item_binding.IItemBinding[void*]	mVoidToDeclarativeItems;
	dquick.script.i_item_binding.IItemBinding[string]	mIdToDeclarativeItems;
	lua_State*	mLuaState;
	IWindow		mWindow;
	package dquick.script.property_binding.PropertyBinding[]		currentlyExecutedBindingStack;
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

			T	itemBinding = new T(dmlEngine);

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
					void*	itemBindingPtr = *(cast(void**)lua_touserdata(L, -1));

					auto	child = itemBindingPtr in dmlEngine.mVoidToDeclarativeItems;
					if (child == null)
					{
						writeln("createLuaBind:: can't find item\n");
						return 0;
					}

					itemBinding.item.addChild(child.declarativeItem);
				}

				/* removes 'value'; keeps 'key' for next iteration */
				lua_pop(L, 1);
			}
			lua_pop(L, 1); // Remove param 1 (table)

			dmlEngine.addObjectBinding!T(itemBinding, itemBinding.item.id);
			lua_getglobal(L, itemBinding.item.id.toStringz());

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

			void*	itemBindingPtr = *(cast(void**)lua_touserdata(L, 1));
			lua_remove(L, 1);
			string	propertyId = to!(string)(lua_tostring(L, 1));
			lua_remove(L, 1);

			auto	iItemBinding = itemBindingPtr in dmlEngine.mVoidToDeclarativeItems;
			assert(iItemBinding !is null);
			T	itemBinding = cast(T)(*iItemBinding);

			// Search for property binding on the itemBinding
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
			// Search for simple method on the item
			foreach (member; __traits(allMembers, typeof(itemBinding.item)))
			{
				static if (__traits(compiles, isCallable!(__traits(getMember, typeof(itemBinding.item), member))))
				{
					static if (isCallable!(__traits(getMember, typeof(itemBinding.item), member)) && __traits(compiles, luaCallThisD!(member, typeof(itemBinding.item))(itemBinding.item, L, 1)))
					{
						if (propertyId == member)
						{
							// Create a userdata that contains instance void ptr and return it to emulate a method
							// It also contains a metatable for calling
							void*	userData = lua_newuserdata(L, itemBindingPtr.sizeof);
							memcpy(userData, &itemBindingPtr, itemBindingPtr.sizeof);

							// Create metatable
							lua_newtable(L);
							{
								// Call metamethod to instanciate type
								lua_pushstring(L, "__call");
								lua_pushcfunction(L, cast(lua_CFunction)&methodLuaBind!(member, typeof(itemBinding.item)));
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
			DMLEngine	dmlEngine = cast(DMLEngine)lua_touserdata(L, -1);
			lua_pop(L, 1);

			void*	itemBindingPtr = *(cast(void**)lua_touserdata(L, 1));
			lua_remove(L, 1);
			string	propertyId = to!(string)(lua_tostring(L, 1));
			lua_remove(L, 1);

			auto	iItemBinding = itemBindingPtr in dmlEngine.mVoidToDeclarativeItems;
			assert(iItemBinding !is null);
			T	itemBinding = cast(T)(*iItemBinding);

			bool	found = false;
			foreach (member; __traits(allMembers, typeof(itemBinding)))
			{
				static if (is(typeof(__traits(getMember, itemBinding, member)) : dquick.script.property_binding.PropertyBinding))
				{
					if (propertyId == member)
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

			writefln("newindexLuaBind:: Property %s doesn't exist on object %s", propertyId, itemBinding.item);
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
			DMLEngine	dmlEngine = cast(DMLEngine)lua_touserdata(L, -1);
			lua_pop(L, 1);

			void*	itemBindingPtr = *(cast(void**)lua_touserdata(L, 1));
			lua_remove(L, 1);

			auto	iItemBinding = itemBindingPtr in dmlEngine.mVoidToDeclarativeItems;
			assert(iItemBinding !is null);
			dquick.script.item_binding.ItemBinding!T	itemBinding = cast(dquick.script.item_binding.ItemBinding!T)(*iItemBinding);

			int test = lua_gettop(L);
			luaCallThisD!(methodName, T)(itemBinding.item, L, 1);

			return 1;
		}
		catch (Throwable e)
		{
			writeln(e.toString());
			return 0;
		}
	}
}
