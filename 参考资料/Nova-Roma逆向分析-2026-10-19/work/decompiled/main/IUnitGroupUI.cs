public interface IUnitGroupUI
{
	void SetVisibility(bool v);

	bool DoShowTab(UnitUI.GroupEntry entry, ArrayExt<IUnitControllable> currSelection);
}
