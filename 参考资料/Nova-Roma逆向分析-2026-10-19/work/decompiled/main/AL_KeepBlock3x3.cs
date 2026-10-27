using UnityEngine;

public class AL_KeepBlock3x3 : AILayoutBlock
{
	private Building buildingRef;

	public override void Init()
	{
		OutlineWithRoads = false;
		ParseEditorCodes(AIBuildingBlockType.None, "3,3:N,keep,0,0,3,3");
	}

	public override bool BlockValidityTest(int posX, int posZ)
	{
		if (buildingRef == null)
		{
			buildingRef = GameState.inst.GetPlaceableByUniqueName("keep");
		}
		buildingRef.transform.position = new Vector3(posX, 0f, posZ);
		return World.inst.CanPlace(buildingRef, ignoreLandMassChecks: true, allowBuildOverForest: true) == PlacementValidationResult.Valid;
	}
}
