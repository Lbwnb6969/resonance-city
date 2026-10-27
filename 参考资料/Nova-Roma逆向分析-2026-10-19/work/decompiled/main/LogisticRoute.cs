public struct LogisticRoute
{
	public Building targetBuilding;

	public Building sourceBuilding;

	public bool IsSame(Building tBuilding, Building sBuilding)
	{
		if (targetBuilding == tBuilding)
		{
			return sourceBuilding == sBuilding;
		}
		return false;
	}
}
