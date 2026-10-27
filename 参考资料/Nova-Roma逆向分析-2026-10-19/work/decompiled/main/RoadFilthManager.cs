using System.Collections.Generic;
using UnityEngine;

public class RoadFilthManager : MonoBehaviour
{
	private int roadIdx;

	private int stoneRoadIdx;

	public Dictionary<int, int> HappinessBonuses = new Dictionary<int, int>(64);

	public int filthThreshold = 5;

	private void Start()
	{
	}

	private void Update()
	{
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList(World.roadHash);
		ArrayExt<Building> buildingList2 = Player.inst.GetBuildingList(World.stoneRoadHash);
		int num = (int)Mathff.Clamp(30f * Time.deltaTime, 1f, 10f);
		for (int i = 0; i < num; i++)
		{
			if (roadIdx >= buildingList.Count)
			{
				roadIdx = 0;
			}
			if (stoneRoadIdx >= buildingList2.Count)
			{
				stoneRoadIdx = 0;
			}
			if (buildingList.Count > 0)
			{
				EvalForFilth(buildingList.data[roadIdx]);
				roadIdx++;
			}
			if (buildingList2.Count > 0)
			{
				EvalForFilth(buildingList2.data[stoneRoadIdx]);
				stoneRoadIdx++;
			}
		}
	}

	private void EvalForFilth(Building b)
	{
		HappinessBonuses.Clear();
		Vector3 position = b.transform.position;
		int x = (int)position.x;
		int z = (int)position.z;
		float num = 0f;
		CellInfluence cellInfluenceDataClamped = World.inst.GetCellInfluenceDataClamped(x, z);
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(b.LandMass());
		int num2 = Mathf.Min(10, (villagersForLandMass.Count - 500) / 200);
		for (int i = 0; i < cellInfluenceDataClamped.radiusBonuses.Count; i++)
		{
			int residentialTileID = cellInfluenceDataClamped.radiusBonuses.data[i].residentialTileID;
			if (residentialTileID != 208 && residentialTileID != 204 && residentialTileID != 223 && residentialTileID != 222 && residentialTileID != 231 && residentialTileID != 234 && residentialTileID != 213 && residentialTileID != 231)
			{
				continue;
			}
			int radialHappiness = cellInfluenceDataClamped.radiusBonuses.data[i].GetRadialHappiness(position);
			if (HappinessBonuses.TryGetValue(residentialTileID, out var value))
			{
				if (radialHappiness > value)
				{
					HappinessBonuses[residentialTileID] = radialHappiness;
				}
			}
			else
			{
				HappinessBonuses.Add(residentialTileID, radialHappiness);
			}
		}
		foreach (KeyValuePair<int, int> happinessBonuse in HappinessBonuses)
		{
			num += (float)happinessBonuse.Value;
		}
		float protectionWithStaff = PublicToiletManager.inst.GetProtectionWithStaff(x, z);
		num *= 1f - protectionWithStaff;
		RoadBasic component = b.GetComponent<RoadBasic>();
		if (!(component != null))
		{
			return;
		}
		if (num >= (float)(filthThreshold - num2))
		{
			if (!component.filthRadius.applied)
			{
				component.filthRadius.ApplyBonus();
			}
			b.thought.thought = ThoughtBubbleSystem.Thought.PoopCritical;
			b.thought.visible = true;
		}
		else
		{
			if (component.filthRadius.applied)
			{
				component.filthRadius.RemoveBonus();
			}
			b.thought.thought = ThoughtBubbleSystem.Thought.Satisfied;
			b.thought.visible = false;
		}
	}
}
