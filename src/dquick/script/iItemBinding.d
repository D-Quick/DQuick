module dquick.script.iItemBinding;

import dquick.item.declarativeItem;
import dquick.script.dmlEngineCore;

interface IItemBinding {
	dquick.script.dmlEngineCore.DMLEngineCore	dmlEngine();
	void										dmlEngine(dquick.script.dmlEngineCore.DMLEngineCore);
	void	executeBindings();
	static if (dquick.script.dmlEngine.DMLEngine.showDebug)
		string	displayDependents();
	bool	creating();
}
