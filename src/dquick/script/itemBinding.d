module dquick.script.item_binding;

import std.traits;
import std.typetuple;
import std.string;

import dquick.item.declarative_item;
import dquick.script.native_property_binding;
import dquick.script.virtual_property_binding;
import dquick.script.utils;
import std.stdio;

class ItemBinding(T) : dquick.script.i_item_binding.IItemBinding {
		
	this(dquick.script.dml_engine.DMLEngine dmlEngine)
	{
		this.mDMLEngine = dmlEngine;
		this.item = new T;

		foreach (member; __traits(allMembers, T))
		{
			foreach (type; dquick.script.dml_engine.DMLEngine.propertyTypes)
			{
				enum	isPropertyOfTypeResult = isPropertyOfType!(T, member, type);
				static if ((isPropertyOfTypeResult & IsPropertyOfTypeResult.Getter) && (isPropertyOfTypeResult & IsPropertyOfTypeResult.Signal))
				{
					static if (isPropertyOfTypeResult & IsPropertyOfTypeResult.Setter)
						__traits(getMember, this, member) = new dquick.script.native_property_binding.NativePropertyBinding!type(this, cast(type delegate())(&__traits(getMember, this.item, member)), cast(void delegate(type))(&__traits(getMember, this.item, member)), member);
					else
						__traits(getMember, this, member) = new dquick.script.native_property_binding.NativePropertyBinding!type(this, cast(type delegate())(&__traits(getMember, this.item, member)), member);

					__traits(getMember, this.item, getSignalNameFromPropertyName(member)).connect(cast(TypeTuple!(ParameterTypeTuple!(__traits(getMember, this.item, getSignalNameFromPropertyName(member)).connect))[0])(&__traits(getMember, this, member).onChanged));
				}
			}
		}
	}

	~this()
	{
		foreach (member; __traits(allMembers, T))
		{
			foreach (type; dquick.script.dml_engine.DMLEngine.propertyTypes)
			{
				enum	isPropertyOfTypeResult = isPropertyOfType!(T, member, type);
				static if ((isPropertyOfTypeResult & IsPropertyOfTypeResult.Getter) && (isPropertyOfTypeResult & IsPropertyOfTypeResult.Signal))
					.destroy(__traits(getMember, this, member));
			}
		}

		.destroy(item);
	}

	override dquick.script.dml_engine.DMLEngine	dmlEngine() {return mDMLEngine;};
	dquick.script.dml_engine.DMLEngine	mDMLEngine;

	T	item;
	override DeclarativeItem	declarativeItem() {return item;}

	//dquick.script.dml_engine.DMLEngine	dmlEngine()
	//{
	//	return dmlEngine;
	//}

	override void	executeBindings()
	{
		foreach (member; __traits(allMembers, typeof(this)))
		{
			static if (is(typeof(__traits(getMember, this, member)) : dquick.script.property_binding.PropertyBinding))
			{
				__traits(getMember, this, member).executeBinding();
			}
		}
		foreach (member; virtualProperties)
			member.executeBinding();
	}

	static if (dquick.script.dml_engine.DMLEngine.showDebug)
	{
		override string	displayDependents()
		{
			string	result;
			foreach (member; __traits(allMembers, typeof(this)))
			{
				static if (is(typeof(__traits(getMember, this, member)) : dquick.script.property_binding.PropertyBinding))
				{
					result ~= format("%s\n", member);
					result ~= shiftRight(__traits(getMember, this, member).displayDependents(), "\t", 1);
				}
			}
			return result;
		}
	}

	enum IsPropertyOfTypeResult
	{
		Getter = 0x01,
		Setter = 0x02,
		Signal = 0x04
	}
	static IsPropertyOfTypeResult		isPropertyOfType(T, string member, Type)()
	{
		IsPropertyOfTypeResult	result = cast(IsPropertyOfTypeResult)0x00;

		static if (__traits(compiles, __traits(getOverloads, T, member)))
		{
			foreach (overload; __traits(getOverloads, T, member)) 
			{
				static if (isCallable!(overload))
				{
					//pragma(msg, member, " ", TypeTuple!(ParameterTypeTuple!overload), " == ", TypeTuple!(Type));
					static if (is (ReturnType!(overload) == void) &&
							   TypeTuple!(ParameterTypeTuple!overload).length == 1 && 
							   is (OriginalType!(TypeTuple!(ParameterTypeTuple!overload)[0]) == Type))
					{
						result |= IsPropertyOfTypeResult.Setter;
											//pragma(msg, member, " setter");
					}
					static if (is (OriginalType!(ReturnType!(overload)) == Type) &&
							   TypeTuple!(ParameterTypeTuple!overload).length == 0)
					{
						result |= IsPropertyOfTypeResult.Getter;
											//pragma(msg, member, " getter");
					}
					static if (__traits(hasMember, T, getSignalNameFromPropertyName(member)))
					{
						result |= IsPropertyOfTypeResult.Signal;
											//pragma(msg, member, " signal");
					}
				}
			}
		}
		return result;
	}
	static string	genProperties(T, propertyTypes...)()
	{
		string result = "";

		foreach (member; __traits(allMembers, T))
		{
			foreach (type; propertyTypes)
			{
				enum	isPropertyOfTypeResult = isPropertyOfType!(T, member, type);
				static if ((isPropertyOfTypeResult & IsPropertyOfTypeResult.Getter) && (isPropertyOfTypeResult & IsPropertyOfTypeResult.Signal))
				{
					result ~= "dquick.script.native_property_binding.NativePropertyBinding!" ~ type.stringof ~"\t" ~ member ~ ";\n";
				}
			}
		}

		return result;
	}
	mixin(genProperties!(T, dquick.script.dml_engine.DMLEngine.propertyTypes));

	VirtualPropertyBinding[string]	virtualProperties;
}