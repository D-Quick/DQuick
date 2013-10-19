module dquick.script.item_binding;

import std.traits;
import std.typetuple;
import std.string;
import std.stdio;
import std.signals;

import dquick.item.declarative_item;
import dquick.script.native_property_binding;
import dquick.script.virtual_property_binding;
import dquick.script.utils;

class ItemBinding(T) : dquick.script.i_item_binding.IItemBinding {

	this(dquick.script.dml_engine.DMLEngine dmlEngine, T item)
	{
		this.mDMLEngine = dmlEngine;
		this.item = item;
		creating = true;

		foreach (member; __traits(allMembers, typeof(this)))
		{
			static if (is(typeof(__traits(getMember, this, member)) : dquick.script.property_binding.PropertyBinding)) // Instantiate property binding
			{
				static if (__traits(hasMember, this, "____"~member~"ItemBinding")) // Instanciate subitem binding
				{
					//__traits(getMember, this, "____"~member~"ItemBinding") = new typeof(__traits(getMember, this, "____"~member~"ItemBinding"))(dmlEngine, __traits(getMember, item, member)); // Instanciate subitem binding
					//dmlEngine.addObjectBinding!(typeof(__traits(getMember, this, "____"~member~"ItemBinding")))(__traits(getMember, this, "____"~member~"ItemBinding"), "");
					__traits(getMember, this, member) = new typeof(__traits(getMember, this, member))(this, this);  // Instantiate property binding linked to __member inside this
					__traits(getMember, this, "__"~getSignalNameFromPropertyName(member~"ItemBinding")).connect(&__traits(getMember, this, member).onChanged); // Signal

					__traits(getMember, this.item, getSignalNameFromPropertyName(member)).connect(&__traits(getMember, this, "__"~getSignalNameFromPropertyName(member))); // Signal
					__traits(getMember, this, "__"~getSignalNameFromPropertyName(member))(__traits(getMember, item, member)); // Set initial value
				}
				else // Simple type
				{
					__traits(getMember, this, member) = new typeof(__traits(getMember, this, member))(this, item);  // Instantiate property binding linked to member inside item
					__traits(getMember, this.item, getSignalNameFromPropertyName(member)).connect(&__traits(getMember, this, member).onChanged); // Signal
				}

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
					assert(__traits(getMember, this, member) !is null);
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
									//return ReturnType!(overload);

									//static if (member == "nativeSubItem")
									//pragma(msg, member, " ", OriginalType!(ReturnType!(overload)));
									static if (is(ReturnType!(overload) : dquick.item.declarative_item.DeclarativeItem))
									{
										//pragma(msg, fullyQualifiedName!(dquick.script.item_binding.ItemBinding!(ReturnType!(overload))));

										result ~= format("void															__%s(%s value) {
																if (!(value is null && ____%sItemBinding is null) && !(____%sItemBinding && value is ____%sItemBinding.item))
																{

																	if (____%sItemBinding)
																		dmlEngine.unregisterItem!(%s)(____%sItemBinding.item);
																	if (value)
																		____%sItemBinding = dmlEngine.registerItem!(%s)(value);
																	else
																		____%sItemBinding = null;
																	__%s.emit(____%sItemBinding);
																}																
														}",
														 getSignalNameFromPropertyName(member), fullyQualifiedName2!(ReturnType!(overload)),
														 member, member, member,
														 member,
														 fullyQualifiedName2!(ReturnType!(overload)), member,
														 member, fullyQualifiedName2!(ReturnType!(overload)),
														 member,
														 getSignalNameFromPropertyName(member~"ItemBinding"), member);	// Item Signal

										result ~= format("dquick.script.item_binding.ItemBinding!(%s)					____%sItemBinding;\n", fullyQualifiedName2!(ReturnType!(overload)), member); // ItemBinding
										result ~= format("dquick.script.item_binding.ItemBinding!(%s)					__%sItemBinding() {
																return ____%sItemBinding;
														 }",
														 fullyQualifiedName2!(ReturnType!(overload)), member,
														 member); // ItemBinding Getter
										result ~= format("void															__%sItemBinding(dquick.script.item_binding.ItemBinding!(%s) value) {
																if (value != ____%sItemBinding)
																{
																	if (____%sItemBinding !is null)
														 				dmlEngine.unregisterItem!(%s)(____%sItemBinding.item);
																	____%sItemBinding = value;
																	if (____%sItemBinding !is null)
																	{
																		dmlEngine.registerItem!(%s)(____%sItemBinding.item);
																		item.%s = value.item;
																	}
																	else
																	{
																		item.%s = null;
																	}
																	__%s.emit(value);
																}
															}",
															member, fullyQualifiedName2!(ReturnType!(overload)),
															member,
															member,
															fullyQualifiedName2!(ReturnType!(overload)), member,
															member,
															member,
															fullyQualifiedName2!(ReturnType!(overload)), member,
															member,
															member,
															getSignalNameFromPropertyName(member~"ItemBinding"));	// ItemBinding Setter
										result ~= format("mixin Signal!(dquick.script.item_binding.ItemBinding!(%s))	__%s;", fullyQualifiedName2!(ReturnType!(overload)), getSignalNameFromPropertyName(member~"ItemBinding"));

										result ~= format("dquick.script.native_property_binding.NativePropertyBinding!(dquick.script.item_binding.ItemBinding!(%s), dquick.script.item_binding.ItemBinding!T, \"__%sItemBinding\")	%s;\n", fullyQualifiedName2!(ReturnType!(overload)), member, member);
									}
									else
										result ~= format("dquick.script.native_property_binding.NativePropertyBinding!(%s, T, \"%s\")\t%s;\n", fullyQualifiedName2!(ReturnType!(overload)), member, member);
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