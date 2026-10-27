using UnityEngine;

public class ForumGate : MonoBehaviour
{
	private Building b;

	private void Awake()
	{
		b = GetComponent<Building>();
	}

	private void OnInit()
	{
		b.PlacementValidaton = PlacementValidaton;
	}

	private void PlacementValidaton(ref PlacementValidationResult result)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(b.Center());
		if (result != PlacementValidationResult.ExistingStructure)
		{
			return;
		}
		for (int i = 0; i < cellDataClamped.OccupyingStructure.Count; i++)
		{
			if (cellDataClamped.OccupyingStructure[i].categoryHash != World.forumHash)
			{
				return;
			}
		}
		result = PlacementValidationResult.Valid;
	}
}
