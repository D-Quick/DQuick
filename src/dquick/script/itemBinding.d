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

	this(dquick.script.dml_engine.DMLEngine dmlEngine, T item)
	{
		this.mDMLEngine = dmlEngine;
		this.item = item;

		foreach (member; __traits(allMembers, typeof(this)))
		{
			static if (is(typeof(__traits(getMember, this, member)) : dquick.script.property_binding.PropertyBinding))
			{
				__traits(getMember, this, member) = new typeof(__traits(getMember, this, member))(this);

				/*foreach (overload; __traits(getOverloads, T, member)) 
				{
					static if (isCallable!(overload))
					{	
						static if (!is (OriginalType!(ReturnType!(overload)) == void) && TypeTuple!(ParameterTypeTuple!overload).length == 0) // Getter
						{
							alias OriginalType!(ReturnType!(overload)) type;
						pragma(msg, "ok cool", member);
							static if (is(OriginalType!(__traits(getMember, this.item, member)) == void delegate(OriginalType!(ReturnType!(overload))))) // Has a setter
								__traits(getMember, this, member) = new typeof(__traits(getMember, this, member))(	this,
																																			cast(OriginalType!(ReturnType!(overload)) delegate())(__traits(getMember, this.item, member)),
																																			cast(void delegate(OriginalType!(ReturnType!(overload))))(__traits(getMember, this.item, member)),
																																			member);
							else
							{
								auto getter = cast(type delegate())(__traits(getMember, this.item, member));
								__traits(getMember, this, member) = new typeof(__traits(getMember, this, member))(this, getter, member);
							}
						}
					}
				}*/

				__traits(getMember, this.item, getSignalNameFromPropertyName(member)).connect(cast(TypeTuple!(ParameterTypeTuple!(__traits(getMember, this.item, getSignalNameFromPropertyName(member)).connect))[0])(&__traits(getMember, this, member).onChanged));
			}
		}
	}

	this(dquick.script.dml_engine.DMLEngine dmlEngine)
	{
		T item = new T;
		this(dmlEngine, item);
	}

	~this()
	{
		foreach (member; __traits(allMembers, typeof(this)))
		{
			static if (is(typeof(__traits(getMember, this, member)) : dquick.script.property_binding.PropertyBinding))
			{
				assert(__traits(getMember, this, member) !is null);
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
				assert(__traits(getMember, this, member) !is null);
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
					assert(__traits(getMember, this, member) != null);
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

	static bool		isProperty(T, string member)()
	{
		static if (__traits(compiles, __traits(getOverloads, T, member)))
		{
			foreach (overload; __traits(getOverloads, T, member)) 
			{
				static if (isCallable!(overload))
				{
					static if (!is(ReturnType!(overload) == void) && TypeTuple!(ParameterTypeTuple!overload).length == 0) // Has a getter
					{
						static if (__traits(hasMember, T, getSignalNameFromPropertyName(member))) // Has a signal
							return true;
					}
				}
			}
		}
		return false;
	}
	static auto		propertyType(T, string member)()
	{
		static if (__traits(compiles, __traits(getOverloads, T, member)))
		{
			foreach (overload; __traits(getOverloads, T, member)) 
			{
				static if (isCallable!(overload))
				{
					static if (!is(ReturnType!(overload) == void) && TypeTuple!(ParameterTypeTuple!overload).length == 0) // Has a getter
					{
						static if (__traits(hasMember, T, getSignalNameFromPropertyName(member))) // Has a signal
						{
							//pragma(msg, member);
							return ReturnType!(overload);
						}
					}
				}
			}
		}
		static assert(false, member ~ " has no return type");
	}
	static bool		hasSetter(T, string member)()
	{
		static if (__traits(compiles, __traits(getOverloads, T, member)))
		{
			foreach (overload; __traits(getOverloads, T, member)) 
			{
				static if (isCallable!(overload))
				{
					static if (is (ReturnType!(overload) == void) && TypeTuple!(ParameterTypeTuple!overload).length == 1)
						return true;
				}
			}
		}
		return false;
	}

	static string	genProperties(T, propertyTypes...)()
	{
		string result = "";

		foreach (member; __traits(allMembers, T))
		{
			static if (isProperty!(T, member))
			{
				//pragma(msg, member);
				static if (__traits(compiles, __traits(getOverloads, T, member)))
				{
					foreach (overload; __traits(getOverloads, T, member)) 
					{
						static if (isCallable!(overload))
						{
							static if (!is(ReturnType!(overload) == void) && TypeTuple!(ParameterTypeTuple!overload).length == 0) // Has a getter
							{
								static if (__traits(hasMember, T, getSignalNameFromPropertyName(member))) // Has a signal
								{
									pragma(msg, fullyQualifiedName2!(ReturnType!(overload)));
									//return ReturnType!(overload);

									//static if (member == "nativeSubItem")
									//pragma(msg, member, " ", OriginalType!(ReturnType!(overload)));
									//static if (is(ReturnType!(overload) : dquick.item.declarative_item.DeclarativeItem))
									//	result ~= "dquick.script.native_property_binding.NativePropertyBinding!(" ~ fullyQualifiedName2!(dquick.script.item_binding.ItemBinding!(ReturnType!(overload))) ~", T, \"" ~ member ~ "\")\t" ~ member ~ ";\n";
									//else
										result ~= "dquick.script.native_property_binding.NativePropertyBinding!(" ~ fullyQualifiedName2!(ReturnType!(overload)) ~", T, \"" ~ member ~ "\")\t" ~ member ~ ";\n";
								}
							}
						}
					}
				}

			}
		}

		return result;
	}
	mixin(genProperties!(T, dquick.script.dml_engine.DMLEngine.propertyTypes));

	VirtualPropertyBinding[string]	virtualProperties;
}