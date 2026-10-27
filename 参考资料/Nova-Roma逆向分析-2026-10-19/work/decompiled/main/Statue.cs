using System;
using UnityEngine;

public class Statue : MonoBehaviour
{
	[NonSerialized]
	public Building b;

	public bool allowOverRoads = true;

	private void Awake()
	{
		b = GetComponent<Building>();
		b.PlacementValidaton = PlacementValidation;
	}

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		if (validationResult != PlacementValidationResult.ExistingStructure || !allowOverRoads)
		{
			return;
		}
		bool isValid = true;
		b.ForEachTileInBounds((int x, int z, Cell c) =>
		{
			if (isValid)
			{
				for (int i = 0; i < c.OccupyingStructure.Count; i++)
				{
					int uniqueNameHash = c.OccupyingStructure[i].uniqueNameHash;
					int categoryHash = c.OccupyingStructure[i].categoryHash;
					if (uniqueNameHash != World.stoneRoadHash && uniqueNameHash != World.roadHash && categoryHash != World.forumHash)
					{
						isValid = false;
						break;
					}
				}
			}
		});
		if (isValid)
		{
			validationResult = PlacementValidationResult.Valid;
		}
	}

	private void OnAddJobs(Building b)
	{
		for (int i = 0; i < b.attractionPositions.Length; i++)
		{
			if (!b.VerifyJobIs(i, typeof(IdleJob)))
			{
				b.SetAndAddJob(i, new IdleJob(b, IdleJob.IdleBehavior.Looking));
			}
		}
	}
}
