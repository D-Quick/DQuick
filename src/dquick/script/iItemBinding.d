module dquick.script.i_item_binding;

import dquick.item.declarative_item;
import dquick.script.dml_engine;

class IItemBinding {

	this()
	{
		creating = true;
	}
	dquick.script.dml_engine.DMLEngine	dmlEngine() {return null;}
	DeclarativeItem	declarativeItem() {return null;}
	void	executeBindings() {};
	string	displayDependents() {return "";};
	bool	creating;
}
