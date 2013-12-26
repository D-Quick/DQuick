module dquick.script.dmlEngineCore;

import derelict.lua.lua;

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
	import dquick.item.declarativeItem;
	import std.signals;
	class SimpleItem : dquick.script.iItemBinding.IItemBinding
	{
		mixin(dquick.script.itemBinding.I_ITEM_BINDING);

		this()
		{
			idProperty = new typeof(idProperty)(this, this);
			readOnlyPropertyProperty = new typeof(readOnlyPropertyProperty)(this, this);
		}

		dquick.script.nativePropertyBinding.NativePropertyBinding!(string, SimpleItem, "id")	idProperty;
		string	id() { return mId; }
		void	id(string value) { mId = value; }
		string	mId;

		dquick.script.nativePropertyBinding.NativePropertyBinding!(string, SimpleItem, "readOnlyProperty")	readOnlyPropertyProperty;
		string	readOnlyProperty() { return "readOnlyProperty"; }
	}
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

			nativePropertyArrayProperty = new typeof(nativePropertyArrayProperty)(this, this);
			onNativePropertyArrayChanged.connect(&nativePropertyArrayProperty.onChanged); // Signal

			nativePropertyDoubleArrayProperty = new typeof(nativePropertyDoubleArrayProperty)(this, this);
			onNativePropertyDoubleArrayChanged.connect(&nativePropertyDoubleArrayProperty.onChanged); // Signal

			nativePropertyStaticDoubleArrayProperty = new typeof(nativePropertyStaticDoubleArrayProperty)(this, this);
			onNativePropertyStaticDoubleArrayChanged.connect(&nativePropertyStaticDoubleArrayProperty.onChanged); // Signal

			nativePropertyDoubleMapProperty = new typeof(nativePropertyDoubleMapProperty)(this, this);
			onNativePropertyDoubleMapChanged.connect(&nativePropertyDoubleMapProperty.onChanged); // Signal
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
			enumVal3,
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

		dquick.script.nativePropertyBinding.NativePropertyBinding!(int[], Item, "nativePropertyArray")	nativePropertyArrayProperty;
		void	nativePropertyArray(int[] value)
		{
			if (mNativePropertyArray != value)
			{
				mNativePropertyArray = value;
				onNativePropertyArrayChanged.emit(value);
			}
		}
		int[]		nativePropertyArray()
		{
			return mNativePropertyArray;
		}
		mixin Signal!(int[]) onNativePropertyArrayChanged;
		int[]		mNativePropertyArray;

		dquick.script.nativePropertyBinding.NativePropertyBinding!(string[][], Item, "nativePropertyDoubleArray")	nativePropertyDoubleArrayProperty;
		void	nativePropertyDoubleArray(string[][] value)
		{
			if (mNativePropertyDoubleArray != value)
			{
				mNativePropertyDoubleArray = value;
				onNativePropertyDoubleArrayChanged.emit(value);
			}
		}
		string[][]		nativePropertyDoubleArray()
		{
			return mNativePropertyDoubleArray;
		}
		mixin Signal!(string[][]) onNativePropertyDoubleArrayChanged;
		string[][]		mNativePropertyDoubleArray;

		dquick.script.nativePropertyBinding.NativePropertyBinding!(Enum[3][2], Item, "nativePropertyStaticDoubleArray")	nativePropertyStaticDoubleArrayProperty;
		void	nativePropertyStaticDoubleArray(Enum[3][2] value)
		{
			if (mNativePropertyStaticDoubleArray != value)
			{
				mNativePropertyStaticDoubleArray = value;
				onNativePropertyStaticDoubleArrayChanged.emit(value);
			}
		}
		Enum[3][2]		nativePropertyStaticDoubleArray()
		{
			return mNativePropertyStaticDoubleArray;
		}
		mixin Signal!(Enum[3][2]) onNativePropertyStaticDoubleArrayChanged;
		Enum[3][2]		mNativePropertyStaticDoubleArray;

		dquick.script.nativePropertyBinding.NativePropertyBinding!(float[int][string], Item, "nativePropertyDoubleMap")	nativePropertyDoubleMapProperty;
		void	nativePropertyDoubleMap(float[int][string] value)
		{
			if (mNativePropertyDoubleMap != value)
			{
				mNativePropertyDoubleMap = value;
				onNativePropertyDoubleMapChanged.emit(value);
			}
		}
		float[int][string]		nativePropertyDoubleMap()
		{
			return mNativePropertyDoubleMap;
		}
		mixin Signal!(float[int][string]) onNativePropertyDoubleMapChanged;
		float[int][string]		mNativePropertyDoubleMap;
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
	dmlEngine.addObjectBindingType!(SimpleItem, "SimpleItem");

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

	// Test signals 2 (slot call it's own binding)
	{
		string lua = q"(
			Item {
				id = "item4_1",
				nativeTotalProperty = 500,
				virtualProperty = function()
					return 1000
				end,
				onVirtualPropertyChanged = function()
					item4_1.nativeTotalProperty = item4_1.nativeTotalProperty + item4_1.virtualProperty
				end,
			}
		)";
		dmlEngine.execute(lua, "");
		assert(dmlEngine.getLuaGlobal!Item("item4_1").nativeTotalProperty == 1500);
	}

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
	try
	{
		uint	oldSize = dmlEngine.propertyBindingStackSize;
		dmlEngine.propertyBindingStackSize = 10;
		scope(exit) dmlEngine.propertyBindingStackSize = oldSize;
		string lua6 = q"(
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
		dmlEngine.execute(lua6, "Test property binding loop detection");
	}
	catch (Throwable e)
	{
		auto expected = "property binding loop detected, callstack:\n"
			"item8.nativeProperty\n"
			"item9.virtualProperty\n"
			"item10.nativeTotalProperty\n"
			"item8.nativeProperty\n"
			"item9.virtualProperty\n"
			"item10.nativeTotalProperty\n"
			"...\n"
			"\t[D] in function __index\n"
			"\t[string \"Test property binding loop detection\"]:5\n"
			"\t[D] in function __index\n"
			"\t[string \"Test property binding loop detection\"]:11\n"
			"\t[D] in function __index\n"
			"\t[string \"Test property binding loop detection\"]:17\n"
			"\t[D] in function __index\n"
			"\t[string \"Test property binding loop detection\"]:5\n"
			"\t[D] in function __index\n"
			"\t[string \"Test property binding loop detection\"]:11\n";
		auto m = mismatch(e.msg[0 .. min(e.msg.length, expected.length)], expected);
		assert(m[0] == "" && m[1] == "");
	}

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

	// Check error 1
	try
	{
		string lua = q"(
			Item()
		)";
		dmlEngine.execute(lua, "Check error 1");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a table was expected as argument, got none\n\t[D] in function Item\n\t[string \"Check error 1\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 2
	try
	{
		string lua = q"(
			getmetatable(Item).__call()
		)";
		dmlEngine.execute(lua, "Check error 2");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a table was expected as self, got none, the function was altered\n\t[D] in function __call\n\t[string \"Check error 2\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 3
	try
	{
		string lua = q"(
			getmetatable(Item).__call(1)
		)";
		dmlEngine.execute(lua, "Check error 3");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a table was expected as self, got number, the function was altered\n\t[D] in function __call\n\t[string \"Check error 3\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 4
	try
	{
		string lua = q"(
			getmetatable(Item).__call(1, 1)
		)";
		dmlEngine.execute(lua, "Check error 4");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a table was expected as self, got number, the function was altered\n\t[D] in function __call\n\t[string \"Check error 4\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 5
	try
	{
		string lua = q"(
			Item(1)
		)";
		dmlEngine.execute(lua, "Check error 5");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a table was expected as argument, got number\n\t[D] in function Item\n\t[string \"Check error 5\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 6
	try
	{
		string lua = q"(
			Item(1, 1)
		)";
		dmlEngine.execute(lua, "Check error 6");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a table was expected as argument, got number\n\t[D] in function Item\n\t[string \"Check error 6\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 7
	try
	{
		string lua = q"(
			Item({}, 1)
		)";
		dmlEngine.execute(lua, "Check error 7");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "too many arguments, only one table was expected as argument\n\t[D] in function Item\n\t[string \"Check error 7\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 8
	try
	{
		string lua = q"(
			Item {
				id = "item21",
			}
			getmetatable(item21).__index()
		)";
		dmlEngine.execute(lua, "Check error 8");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a userdata was expected as self, got none, the function was altered\n\t[D] in function __index\n\t[string \"Check error 8\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 9
	try
	{
		string lua = q"(
			Item {
				id = "item22",
			}
			getmetatable(item22).__index(1)
		)";
		dmlEngine.execute(lua, "Check error 9");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a userdata was expected as self, got number, the function was altered\n\t[D] in function __index\n\t[string \"Check error 9\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 10
	try
	{
		string lua = q"(
			Item {
				id = "item23",
			}
			getmetatable(item23).__index(item23)
		)";
		dmlEngine.execute(lua, "Check error 10");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a string was expected as key, got none\n\t[D] in function __index\n\t[string \"Check error 10\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 11
	try
	{
		string lua = q"(
			Item {
				id = "item24",
			}
			local test = item24[1]
		)";
		dmlEngine.execute(lua, "Check error 11");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a string was expected as key, got number\n\t[D] in function __index\n\t[string \"Check error 11\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 12
	try
	{
		string lua = q"(
			Item {
				id = "item25",
			}
			getmetatable(item25).__index(item25, "test", 10)
		)";
		dmlEngine.execute(lua, "Check error 12");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "too many arguments, only a userdata as self and a string as key was expected as arguments\n\t[D] in function __index\n\t[string \"Check error 12\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 13
	try
	{
		string lua = q"(
			Item {
				id = "item26",
			}
			getmetatable(item26).__newindex()
		)";
		dmlEngine.execute(lua, "Check error 13");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a userdata was expected as self, got none, the function was altered\n\t[D] in function __newindex\n\t[string \"Check error 13\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 14
	try
	{
		string lua = q"(
			Item {
				id = "item27",
			}
			getmetatable(item27).__newindex(1)
		)";
		dmlEngine.execute(lua, "Check error 14");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a userdata was expected as self, got number, the function was altered\n\t[D] in function __newindex\n\t[string \"Check error 14\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 15
	try
	{
		string lua = q"(
			Item {
				id = "item28",
			}
			getmetatable(item28).__newindex(item28)
		)";
		dmlEngine.execute(lua, "Check error 15");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a string was expected as key, got none\n\t[D] in function __newindex\n\t[string \"Check error 15\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 16
	try
	{
		string lua = q"(
			Item {
				id = "item29",
			}
			getmetatable(item29).__newindex(item29, nil)
		)";
		dmlEngine.execute(lua, "Check error 16");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a string was expected as key, got nil\n\t[D] in function __newindex\n\t[string \"Check error 16\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 17
	try
	{
		string lua = q"(
			Item {
				id = "item30",
			}
			getmetatable(item30).__newindex(item30, "test")
		)";
		dmlEngine.execute(lua, "Check error 17");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "an assignment value was expected, got none\n\t[D] in function __newindex\n\t[string \"Check error 17\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 18
	try
	{
		string lua = q"(
			Item {
				id = "item31",
			}
			item31.test = nil
		)";
		dmlEngine.execute(lua, "Check error 18");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "property \"test\" doesn't exist on object \"item31\"\n\t[D] in function __newindex\n\t[string \"Check error 18\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 19
	try
	{
		string lua = q"(
			Item {
				id = "item32",
			}
			getmetatable(item32).__newindex(item32, "test", 1, 0)
		)";
		dmlEngine.execute(lua, "Check error 19");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "too many arguments, only a userdata as self, a string as key and an assignment value was expected as arguments\n\t[D] in function __newindex\n\t[string \"Check error 19\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 20
	try
	{
		string lua = q"(
			Item {
				id = "item33",
			}
			item33.nativeProperty = "test"
		)";
		dmlEngine.execute(lua, "Check error 20");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "Lua value at index 1 is a string, a number was expected\n\t[D] in function __newindex\n\t[string \"Check error 20\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 21
	try
	{
		dmlEngine.addFunction!(testSumFunctionBinding, "testSumFunctionBinding2")();
		string lua = q"(
			test = testSumFunctionBinding2("test", 200)
		)";
		dmlEngine.execute(lua, "Check error 21");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "Lua value at index 1 is a string, a number was expected\n\t[D] in function testSumFunctionBinding2\n\t[string \"Check error 21\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 22
	try
	{
		dmlEngine.addFunction!(testSumFunctionBinding, "testSumFunctionBinding3")();
		string lua = q"(
			test = testSumFunctionBinding3(200)
		)";
		dmlEngine.execute(lua, "Check error 22");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "Lua value at index 2 is a none, a number was expected\n\t[D] in function testSumFunctionBinding3\n\t[string \"Check error 22\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 23
	try
	{
		dmlEngine.addFunction!(testSumFunctionBinding, "testSumFunctionBinding4")();
		string lua = q"(
			test = testSumFunctionBinding4(200, 200, 0)
		)";
		dmlEngine.execute(lua, "Check error 23");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "too many arguments, expected 2\n\t[D] in function testSumFunctionBinding4\n\t[string \"Check error 23\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 24
	try
	{
		Item	testObject3 = new Item;
		dmlEngine.addObjectBinding(testObject3, "testObject3");
		string lua = q"(
			test = getmetatable(testObject3.testNormalMethod).__call()
		)";
		dmlEngine.execute(lua, "Check error 24");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a userdata was expected as self, got none, the function was altered\n\t[D] in function __call\n\t[string \"Check error 24\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 25
	try
	{
		Item	testObject4 = new Item;
		dmlEngine.addObjectBinding(testObject4, "testObject4");
		string lua = q"(
			test = testObject4.testNormalMethod(nil)
		)";
		dmlEngine.execute(lua, "Check error 25");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "Lua value at index 1 is a nil, a number was expected\n\t[D] in function testNormalMethod\n\t[string \"Check error 25\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 26
	try
	{
		Item	testObject5 = new Item;
		dmlEngine.addObjectBinding(testObject5, "testObject5");
		string lua = q"(
			test = testObject5.testNormalMethod(200, 200, 0)
		)";
		dmlEngine.execute(lua, "Check error 26");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "too many arguments, expected 2\n\t[D] in function testNormalMethod\n\t[string \"Check error 26\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 27
	try
	{
		Item	testObject6 = new Item;
		dmlEngine.addObjectBinding(testObject6, "testObject6");
		string lua = q"(
			test = testObject6.testNormalMethod.test
		)";
		dmlEngine.execute(lua, "Check error 27");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "attempt to index a method\n\t[D] in function __index\n\t[string \"Check error 27\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 28
	try
	{
		Item	testObject7 = new Item;
		dmlEngine.addObjectBinding(testObject7, "testObject7");
		string lua = q"(
			testObject7.testNormalMethod.test = nil
		)";
		dmlEngine.execute(lua, "Check error 28");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "attempt to assign a method\n\t[D] in function __newindex\n\t[string \"Check error 28\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 29
	try
	{
		string lua = q"(
			ImportComponent()
		)";
		dmlEngine.execute(lua, "Check error 29");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a string was expected as argument, got none\n\t[D] in function ImportComponent\n\t[string \"Check error 29\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 30
	try
	{
		string lua = q"(
			ImportComponent("Check error 30.lua", 0)
		)";
		dmlEngine.execute(lua, "Check error 30");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "too many arguments, only one string was expected as argument\n\t[D] in function ImportComponent\n\t[string \"Check error 30\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 31
	try
	{
		string lua = q"(
			ImportComponent("CheckError31.lua")
			CheckError31()
		)";
		dmlEngine.execute(lua, "Check error 31");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "a table was expected as argument, got none\n\t[D] in function CheckError31\n\t[string \"Check error 31\"]:3");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 32
	try
	{
		string lua = q"(
			ImportComponent("CheckError32.lua")
			CheckError32({}, 0)
		)";
		dmlEngine.execute(lua, "Check error 32");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "too many arguments, only one table was expected as argument\n\t[D] in function CheckError32\n\t[string \"Check error 32\"]:3");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 33
	try
	{
		string	checkError33 = q"(
		)";
		std.file.write("CheckError33.lua", checkError33);

		string lua = q"(
			ImportComponent("CheckError33.lua")
			CheckError33 {
			}
		)";
		dmlEngine.execute(lua, "Check error 33");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "\"CheckError33\" component has no root item\n\t[D] in function CheckError33\n\t[string \"Check error 33\"]:3");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 34
	try
	{
		string	checkError34 = q"(
			Item {
			}
		)";
		std.file.write("CheckError34.lua", checkError34);
		string lua = q"(
			ImportComponent("CheckError34.lua")
			Item {
				id = "checkError34",

				CheckError34 {
					id = "checkError34"
				}
			}
		)";
		dmlEngine.execute(lua, "Check error 34");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "an item with id \"checkError34\" already exist in that component\n\t[D] in function Item\n\t[string \"Check error 34\"]:3");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 35
	try
	{
		string	checkError35 = q"(
			Item {
			}
		)";
		std.file.write("CheckError35.lua", checkError35);
		string lua = q"(
			ImportComponent("CheckError35.lua")
			CheckError35 {
				id = "checkError35",

				Item {
					id = "checkError35"
				}
			}
		)";
		dmlEngine.execute(lua, "Check error 35");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "an item with id \"checkError35\" already exist in that component\n\t[D] in function CheckError35\n\t[string \"Check error 35\"]:3");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 36
	try
	{
		string lua = q"(
			Item {
				onNativePropertyChanged = 10
			}
		)";
		dmlEngine.execute(lua, "Check error 36");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "attribute \"onNativePropertyChanged\" is a number, a function was expected\n\t[D] in function Item\n\t[string \"Check error 36\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 37
	try
	{
		string lua = q"(
			Item {
				onVirtualPropertyChanged = 10
			}
		)";
		dmlEngine.execute(lua, "Check error 37");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "attribute \"onVirtualPropertyChanged\" is a number, a function was expected\n\t[D] in function Item\n\t[string \"Check error 37\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 38
	try
	{
		string lua = q"(
			Item {
				10
			}
		)";
		dmlEngine.execute(lua, "Check error 38");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "attribute \"1\" is a number, an item was expected\n\t[D] in function Item\n\t[string \"Check error 38\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 39
	try
	{
		Item	testObject7 = new Item;
		dmlEngine.addObjectBinding(testObject7, "testObject7");
		string lua = q"(
			Item {
				testObject7.testNormalMethod
			}
		)";
		dmlEngine.execute(lua, "Check error 39");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "Lua value at index -1 is not an item\n\t[D] in function Item\n\t[string \"Check error 39\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 40
	try
	{
		string lua = q"(
			Item {
				SimpleItem {
				}
			}
		)";
		dmlEngine.execute(lua, "Check error 40");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "can't add item at key \"1\" as child without an appropriate addChild method\n\t[D] in function Item\n\t[string \"Check error 40\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 41
	try
	{
		string lua = q"(
			SimpleItem {
				Item {
				}
			}
		)";
		dmlEngine.execute(lua, "Check error 41");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "can't add item at key \"1\" as child without an appropriate addChild method\n\t[D] in function SimpleItem\n\t[string \"Check error 41\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 42
	try
	{
		string lua = q"(
			SimpleItem {
				id = "simpleItem1"
			}
			simpleItem1.readOnlyProperty = "test"
		)";
		dmlEngine.execute(lua, "Check error 42");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "property \"readOnlyProperty\" is read only\n\t[D] in function __newindex\n\t[string \"Check error 42\"]:5");
		assert(m[0] == "" && m[1] == "");
	}

	// Check error 43
	try
	{
		string lua = q"(
			Item {
				id = "checkError43Item",
				nativeProperty = function()
					return 1, 3
				end
			}
		)";
		dmlEngine.execute(lua, "Check error 43");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "too few or too many return values on property binding checkError43Item.nativeProperty, got 2, expected 1");
		assert(m[0] == "" && m[1] == "");
	}

	// Simple array from lua to D
	{
		string lua = q"(
			Item {
				id = "array1",
				nativePropertyArray = {10, 20, 30}
			}
		)";
		dmlEngine.execute(lua, "Simple array from lua to D");
		assert(dmlEngine.getLuaGlobal!Item("array1").nativePropertyArray == [10, 20, 30]);
	}

	// Array error 1
	try
	{
		string lua = q"(
			Item {
				id = "arrayError1",
				nativePropertyArray = 10
			}
		)";
		dmlEngine.execute(lua, "Array error 1");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "Lua value at index -1 is a number, a table or a userdata was expected\n\t[D] in function Item\n\t[string \"Array error 1\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Array error 2
	try
	{
		string lua = q"(
			Item {
				id = "arrayError2",
				nativePropertyArray = {10, "test", 30}
			}
		)";
		dmlEngine.execute(lua, "Array error 2");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "Lua value at index -1 is a string, a number was expected\n\t[D] in function Item\n\t[string \"Array error 2\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Simple array from lua to D in virtual property
	{
		string lua = q"(
			Item {
				id = "array2",
				virtualPropertyArray = {10, 20, 30 }
			}
			array2.nativePropertyArray = array2.virtualPropertyArray
		)";
		dmlEngine.execute(lua, "Simple array from lua to D in virtual property");
		assert(dmlEngine.getLuaGlobal!Item("array2").nativePropertyArray == [10, 20, 30]);
	}

	// Simple array from D to lua
	{
		Item	array3 = new Item;
		dmlEngine.addObjectBinding(array3, "array3");
		array3.nativePropertyArray = [100, 200, 300];
		string lua = q"(
			test = array3.nativePropertyArray
		)";
		dmlEngine.execute(lua, "Simple array from D to lua");
		assert(dmlEngine.getLuaGlobal!(int[])("test") == [100, 200, 300]);
	}

	// Double array from lua to D
	{
		string lua = q"(
			Item {
				id = "array4",
				nativePropertyDoubleArray = {
					{"10", "20", "30"},
					{"100", "200", "300"}
				}
			}
		)";
		dmlEngine.execute(lua, "Double array from lua to D");
		assert(dmlEngine.getLuaGlobal!Item("array4").nativePropertyDoubleArray == [["10", "20", "30"], ["100", "200", "300"]]);
	}

	// Double array from lua to D in virtual property
	{
		string lua = q"(
			Item {
				id = "array5",
				virtualPropertyDoubleArray = {
					{"10", "20", "30"},
					{"100", "200", "300"}
				}
			}
			array5.nativePropertyDoubleArray = array5.virtualPropertyDoubleArray
		)";
		dmlEngine.execute(lua, "Double array from lua to D in virtual property");
		assert(dmlEngine.getLuaGlobal!Item("array5").nativePropertyDoubleArray == [["10", "20", "30"], ["100", "200", "300"]]);
	}

	// Double array from D to lua
	{
		Item	array6 = new Item;
		dmlEngine.addObjectBinding(array6, "array6");
		array6.nativePropertyDoubleArray = [["100", "200", "300"], ["1000", "2000", "3000"]];
		string lua = q"(
			test = array6.nativePropertyDoubleArray
		)";
		dmlEngine.execute(lua, "Double array from D to lua");
		assert(dmlEngine.getLuaGlobal!(string[][])("test") == [["100", "200", "300"], ["1000", "2000", "3000"]]);
	}

	// Static double array from lua to D
	{
		string lua = q"(
			Item {
				id = "array7",
				nativePropertyStaticDoubleArray = {
					{Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3},
					{Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3}
				}
			}
		)";
		dmlEngine.execute(lua, "Static double array from lua to D");
		assert(dmlEngine.getLuaGlobal!Item("array7").nativePropertyStaticDoubleArray == [
			[Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3],
			[Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3]
		]);
	}

	// Array error 3
	try
	{
		string lua = q"(
			Item {
				id = "arrayError3",
				nativePropertyStaticDoubleArray = {
					{Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3},
					{Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3, Item.Enum.enumVal3}
				}
			}
		)";
		dmlEngine.execute(lua, "Array error 3");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "Lua value at index -1 is a table that overflows\n\t[D] in function Item\n\t[string \"Array error 3\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Array error 4
	try
	{
		string lua = q"(
			Item {
				id = "arrayError4",
				nativePropertyStaticDoubleArray = {
					{Item.Enum.enumVal1, Item.Enum.enumVal2},
					{Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3}
				}
			}
		)";
		dmlEngine.execute(lua, "Array error 4");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "Lua value at index -1 is a table that underflows\n\t[D] in function Item\n\t[string \"Array error 4\"]:2");
		assert(m[0] == "" && m[1] == "");
	}

	// Static double array from lua to D in virtual property
	{
		string lua = q"(
			Item {
				id = "array8",
				virtualPropertyStaticDoubleArray = {
					{Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3},
					{Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3}
				}
			}
			array8.nativePropertyStaticDoubleArray = array8.virtualPropertyStaticDoubleArray
		)";
		dmlEngine.execute(lua, "Static double array from lua to D in virtual property");
		assert(dmlEngine.getLuaGlobal!Item("array8").nativePropertyStaticDoubleArray == [
			[Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3],
			[Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3]
		]);
	}

	// Static double array from D to lua
	{
		Item	array9 = new Item;
		dmlEngine.addObjectBinding(array9, "array9");
		Item.Enum[3][2]	a;
		a[0][0] = Item.Enum.enumVal1;
		a[0][1] = Item.Enum.enumVal2;
		a[0][2] = Item.Enum.enumVal3;
		a[1][0] = Item.Enum.enumVal1;
		a[1][1] = Item.Enum.enumVal2;
		a[1][2] = Item.Enum.enumVal3;
		array9.nativePropertyStaticDoubleArray = a;
		string lua = q"(
			test = array9.nativePropertyStaticDoubleArray
		)";
		dmlEngine.execute(lua, "Static double array from D to lua");
		assert(dmlEngine.getLuaGlobal!(Item.Enum[3][2])("test") == [
			[Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3],
			[Item.Enum.enumVal1, Item.Enum.enumVal2, Item.Enum.enumVal3]
		]);
	}

	// Double map from lua to D
	{
		string lua = q"(
			Item {
				id = "array10",
				nativePropertyDoubleMap = {
					test1 = {
						[10] = 100.0,
						[20] = 200.0,
						[30] = 300.0
					},
					test2 = {
						[1000] = 10000.0,
						[2000] = 20000.0,
						[3000] = 30000.0
					}
				}
			}
		)";
		dmlEngine.execute(lua, "Double map from lua to D");
		assert(dmlEngine.getLuaGlobal!Item("array10").nativePropertyDoubleMap == [
			"test1" : [
				10 : 100.0f,
				20 : 200.0f,
				30 : 300.0f
			],
			"test2" : [
				1000 : 10000.0f,
				2000 : 20000.0f,
				3000 : 30000.0f
			]
		]);
	}

	// Double map from D to lua
	{
		Item	array11 = new Item;
		dmlEngine.addObjectBinding(array11, "array11");
		array11.nativePropertyDoubleMap = [
			"test1" : [
				10 : 100.0f,
				20 : 200.0f,
				30 : 300.0f
			],
			"test2" : [
				1000 : 10000.0f,
				2000 : 20000.0f,
				3000 : 30000.0f
			]
		];
		string lua = q"(
			test = array11.nativePropertyDoubleMap
		)";
		dmlEngine.execute(lua, "Double map from D to lua");
		assert(dmlEngine.getLuaGlobal!(float[int][string])("test") == [
			"test1" : [
				10 : 100.0f,
				20 : 200.0f,
				30 : 300.0f
			],
			"test2" : [
				1000 : 10000.0f,
				2000 : 20000.0f,
				3000 : 30000.0f
			]
		]);
	}

	// Check that double array from D to lua are passed by reference
	{
		Item	array12 = new Item;
		dmlEngine.addObjectBinding(array12, "array12");
		array12.nativePropertyDoubleMap = [
			"test1" : [
				10 : 100.0f,
				20 : 200.0f,
				30 : 300.0f
			],
			"test2" : [
				1000 : 10000.0f,
				2000 : 20000.0f,
				3000 : 30000.0f
			]
		];
		string lua = q"(
			test = array12.nativePropertyDoubleMap
			test["test1"][10] = test["test2"][1000]
		)";
		dmlEngine.execute(lua, "Check that double map from D to lua are passed by reference");
		assert(dmlEngine.getLuaGlobal!(float[int][string])("test") == [
			"test1" : [
				10 : 10000.0f,
				20 : 200.0f,
				30 : 300.0f
			],
			"test2" : [
				1000 : 10000.0f,
				2000 : 20000.0f,
				3000 : 30000.0f
			]
		]);
	}

	// Check that double map from D to lua are passed by reference
	{
		Item	array13 = new Item;
		dmlEngine.addObjectBinding(array13, "array13");
		array13.nativePropertyDoubleArray = [
			["100", "200", "300"],
			["10000", "20000", "30000"]
		];
		string lua = q"(
			test = array13.nativePropertyDoubleArray
			test[0][0] = test[1][0]
		)";
		dmlEngine.execute(lua, "Check that double map from D to lua are passed by reference");
		assert(dmlEngine.getLuaGlobal!(string[][])("test") == [
			["10000", "200", "300"],
			["10000", "20000", "30000"]
		]);
	}

	// Array error 5
	try
	{
		string lua = q"(
			Item {
				id = "arrayError5",
			}
			arrayError5.nativePropertyDoubleArray[0][0] = "10"
		)";
		dmlEngine.execute(lua, "Array error 5");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "[string \"Array error 5\"]:5: attempt to index field '?' (a nil value)");
		assert(m[0] == "" && m[1] == "");
	}

	// Array error 6
	try
	{
		string lua = q"(
			Item {
				id = "arrayError6",
			}
			arrayError6.nativePropertyDoubleArray = {
				{}
			}
			arrayError6.nativePropertyDoubleArray[0][0] = "10"
		)";
		dmlEngine.execute(lua, "Array error 6");
	}
	catch (Throwable e)
	{
		auto m = mismatch(e.msg, "the key value 0 is out of bound\n\t[D] in function __newindex\n\t[string \"Array error 6\"]:8");
		assert(m[0] == "" && m[1] == "");
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
		scope(exit) mReentrencyLevel--;
		size_t	itemCount = mItems.length;

		// Save _ENV
		if (lua_getupvalue(luaState, -1, 1) == null)
			throw new Exception("no _ENV upvalue");
		mEnvStack ~= luaL_ref(luaState, LUA_REGISTRYINDEX);

		static if (showDebug)
			writeln("CREATE ==================================================================================================");

		if (lua_pcall(luaState, 0, LUA_MULTRET, 0) != LUA_OK)
		{
			string error = to!(string)(lua_tostring(luaState, -1));
			lua_pop(luaState, 1);
			throw new Exception(error);
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
			string error = to!(string)(lua_tostring(luaState, -1));
			lua_pop(luaState, 1);
			throw new Exception(error);
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

	uint	propertyBindingStackSize = 50;
protected:
	dquick.script.iItemBinding.IItemBinding[]		mItems;
	dquick.script.iItemBinding.IItemBinding			mLastItemBindingCreated;
	
	package lua_State*	luaState;
	package dquick.script.propertyBinding.PropertyBinding[]		currentlyExecutedBindingStack;
	package dquick.script.propertyBinding.PropertyBinding		propertyBindingBeeingSet;
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
			
			dquick.script.utils.valueToLua!(typeof(array[key]))(L, *valuePtr);

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
					return 0;
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