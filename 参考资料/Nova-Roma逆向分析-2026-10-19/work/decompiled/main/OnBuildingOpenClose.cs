using System;

public class OnBuildingOpenClose : EventArgs
{
	public Building targetBuilding;

	public bool open;
}
