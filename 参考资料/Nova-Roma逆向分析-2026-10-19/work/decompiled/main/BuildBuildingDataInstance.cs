public class BuildBuildingDataInstance : BuildBuildingData
{
	private Building b;

	private bool enabled;

	public BuildBuildingDataInstance(Building b, bool enabled)
	{
		this.b = b;
		this.enabled = enabled;
	}

	public Building GetBuilding()
	{
		return b;
	}

	public bool IsEnabled()
	{
		return enabled;
	}
}
