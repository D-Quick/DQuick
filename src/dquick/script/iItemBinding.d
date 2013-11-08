module dquick.script.iItemBinding;

import dquick.item.declarativeItem;
import dquick.script.dmlEngine;

class IItemBinding {

	this()
	{
		creating = true;
	}
	dquick.script.dmlEngine.DMLEngine	dmlEngine() {return null;}
	DeclarativeItem	declarativeItem() {return null;}
	void	executeBindings() {};
	string	displayDependents() {return "";};
	bool	creating;
}
