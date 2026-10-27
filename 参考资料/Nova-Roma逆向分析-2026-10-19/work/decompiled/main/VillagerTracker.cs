using System.Collections.Generic;
using UnityEngine;

public class VillagerTracker : LineTracker
{
	public static ArrayExt<Villager> tempVillagers = new ArrayExt<Villager>(32);

	public void TrackVillagers(Vector3 startPoint, int minX, int minZ, int maxX, int maxZ, ArrayExtRef<Villager> villagers, Color color)
	{
		if (villagers == null || villagers.Count == 0)
		{
			return;
		}
		int num = Mathff.Max(1, maxX - minX);
		int num2 = Mathff.Max(1, maxZ - minZ);
		for (int i = 0; i < villagers.Count; i++)
		{
			Villager villager = villagers.data[i];
			if (!(villager == null))
			{
				Vector3 posWithOffset = villager.GetPosWithOffset();
				if (!(posWithOffset.x >= (float)minX - 0.15f) || !(posWithOffset.x <= (float)maxX + 1.15f) || !(posWithOffset.z >= (float)minZ - 0.15f) || !(posWithOffset.z <= (float)maxZ + 1.15f))
				{
					startOffsetRadius = (float)((num > num2) ? num : num2) * 0.5f * 1.4142135f;
					Vector3 endPoint = posWithOffset;
					endPoint.y += 0.25f;
					DisplayLine(startPoint, endPoint, color);
					Mesh mesh = (villager.useLadyMesh ? VillagerSystem.inst.ladyVillagerMeshs[(int)villager.MeshType] : VillagerSystem.inst.villagerMeshs[(int)villager.MeshType]);
					DisplayOutline(mesh, villager.GetPosWithOffset(), villager.Rot, Vector3.one);
				}
			}
		}
	}

	public void TrackVillagers(ISelectableBuilding sBuilding)
	{
		if (sBuilding == null)
		{
			return;
		}
		tempVillagers.ClearFast();
		Building building = sBuilding as Building;
		if (building != null)
		{
			List<Job> jobs = building.jobs;
			for (int i = 0; i < jobs.Count; i++)
			{
				if (jobs[i].Employee != null)
				{
					tempVillagers.Add(jobs[i].Employee);
				}
			}
			Home component = building.transform.GetComponent<Home>();
			if (component != null)
			{
				List<Villager> residents = component.Residents;
				for (int j = 0; j < residents.Count; j++)
				{
					if (residents[j] != null)
					{
						tempVillagers.Add(residents[j]);
					}
				}
			}
		}
		if (sBuilding.UnderConstruction() && !sBuilding.ConstructionPaused())
		{
			ConstructionForeman.ConstructionSummary summary = default;
			sBuilding.GetConstructionSummary(ref summary);
			for (int k = 0; k < summary.jobs.Count; k++)
			{
				Villager employee = summary.jobs[k].Employee;
				if (employee != null)
				{
					tempVillagers.Add(employee);
				}
			}
		}
		for (int l = 0; l < tempVillagers.Count; l++)
		{
			Villager villager = tempVillagers.data[l];
			if (villager == null)
			{
				continue;
			}
			Vector3 posWithOffset = villager.GetPosWithOffset();
			if (building != null)
			{
				building.CalculateBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
				if (posWithOffset.x >= (float)minX - 0.15f && posWithOffset.x <= (float)maxX + 1.15f && posWithOffset.z >= (float)minZ - 0.15f && posWithOffset.z <= (float)maxZ + 1.15f)
				{
					continue;
				}
				startOffsetRadius = ((building.size.x > building.size.z) ? building.size.x : building.size.z) * 0.5f * 1.4142135f;
			}
			else
			{
				startOffsetRadius = 0f;
			}
			Vector3 startPoint = sBuilding.Center();
			Vector3 endPoint = posWithOffset;
			endPoint.y += 0.25f;
			DisplayLine(startPoint, endPoint, Color.white);
			Mesh mesh = (villager.useLadyMesh ? VillagerSystem.inst.ladyVillagerMeshs[(int)villager.MeshType] : VillagerSystem.inst.villagerMeshs[(int)villager.MeshType]);
			DisplayOutline(mesh, villager.GetPosWithOffset(), villager.Rot, Vector3.one);
		}
	}
}
