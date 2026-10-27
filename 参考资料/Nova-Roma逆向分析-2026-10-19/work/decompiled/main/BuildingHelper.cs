using UnityEngine.Scripting;

public static class BuildingHelper
{
	[Preserve]
	public static bool IsGUID(this Building building, string guid)
	{
		if (building != null)
		{
			return building.guid.ToString() == guid;
		}
		return false;
	}
}
