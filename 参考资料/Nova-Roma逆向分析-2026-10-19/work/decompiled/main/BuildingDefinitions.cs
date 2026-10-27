using UnityEngine;

[CreateAssetMenu(fileName = "BuildingDefinitions", menuName = "ScriptableObjects/BuildingDefinitions")]
public class BuildingDefinitions : ScriptableObject
{
	public BuildUI.BuildGroup[] Groups;

	public static void OnClickedAqueduct()
	{
		GameUI.inst.SetCursorModeAqueductPlacement();
	}

	public static void OnClickedDam()
	{
		DamPlannerUI.inst.SetVisible(v: true);
	}

	public static void OnClickedGroup(string group)
	{
		BuildUI.inst.ShowGroup(group);
	}
}
