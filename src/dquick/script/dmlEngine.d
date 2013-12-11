module dquick.script.dmlEngine;

import derelict.lua.lua;

import dquick.item.declarativeItem;
import dquick.item.graphicItem;
import dquick.item.imageItem;

import dquick.system.window;

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

version(unittest)
{
	interface Interface
	{
		int		nativeProperty();
	}
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
	class Item : DeclarativeItem, Interface
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
		int	testNormalMethod2(Item a, Interface b)
		{
			return a.nativeProperty + b.nativeProperty + nativeProperty;
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

	int	testSumFunctionBinding2(Item a, Interface b)
	{
		return a.nativeProperty + b.nativeProperty;
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
	assert(dmlEngine.getLuaGlobal!Item("item1") !is null);
	assert(dmlEngine.rootItem!Item() !is null);
	assert(dmlEngine.rootItem!Item().id == "item1");

	// Test native property
	string lua2 = q"(
		Item {
			id = "item2",
			nativeProperty = 100
		}
	)";
	dmlEngine.execute(lua2, "");
	assert(dmlEngine.getLuaGlobal!Item("item2") !is null);
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

	// Test normal method binding with polymorphic object parameters
	dmlEngine.execute("total2 = testObject2.testNormalMethod2(item2, item3)", "");
	assert(dmlEngine.getLuaGlobal!int("total2") == 1400);

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

class DMLEngine : dquick.script.dmlEngineCore.DMLEngineCore
{
public:
	void	addItemType(type, string luaName)()
	{
		addObjectBindingType!(dquick.script.itemBinding.ItemBinding!(type), luaName)();
	}

	void	addObject(T)(T object, string luaName)
	{
		addItemType!(T, "__dquick_reserved1");
		static if (is(T : DeclarativeItem))
			object.id = luaName;

		dquick.script.itemBinding.ItemBinding!T	itemBinding = registerItem!T(object);
		setLuaGlobal(luaName, object);
	}

	T	rootItem(T)()
	{
		dquick.script.itemBinding.ItemBindingBase!T	result = rootItemBinding!(dquick.script.itemBinding.ItemBindingBase!T)();
		if (result !is null)
			return cast(T)result.itemObject;
		return null;
	}

	T	getLuaGlobal(T)(string name)
	{
		lua_getglobal(luaState, name.toStringz());
		T	value;
		static if (is(T : dquick.item.declarativeItem.DeclarativeItem))
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
		static if (is(T : dquick.item.declarativeItem.DeclarativeItem))
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

	dquick.script.itemBinding.ItemBinding!T	registerItem(T)(T item)
	{
		auto	refCountPtr = item in mItemsToItemBindings;
		if (refCountPtr !is null)
		{
			refCountPtr.count++;
			return cast(dquick.script.itemBinding.ItemBinding!T)refCountPtr.iItemBinding;
		}

		dquick.script.itemBinding.ItemBinding!T	itemBinding = new dquick.script.itemBinding.ItemBinding!T(item);
		registerItem!T(item, itemBinding);
		addObjectBinding!(dquick.script.itemBinding.ItemBinding!T)(itemBinding, "");
		return itemBinding;
	}
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
	ItemRefCounting[DeclarativeItem]	mItemsToItemBindings;
}
