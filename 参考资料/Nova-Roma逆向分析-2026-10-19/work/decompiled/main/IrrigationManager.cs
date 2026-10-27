using System;
using System.Collections.Generic;
using UnityEngine;

public class IrrigationManager : MonoBehaviour
{
	public delegate void ReservoirIrrigationUpdateHandler();

	private struct IrrigationNode
	{
		public bool isNextToWater;

		public Building b;

		public IWaterSystemUser w;
	}

	private static int noriaUniqueHash = "noria".GetHashCode();

	private static int aqueductUniqueHash = "aqueduct".GetHashCode();

	private static int reservoirUniqueHash = "reservoir".GetHashCode();

	private static int bathhouseUniqueHash = "bathhouse".GetHashCode();

	[NonSerialized]
	public bool wasReservoirIrrigationUpdated;

	private List<IrrigationNode> nodes = new List<IrrigationNode>(100);

	public event ReservoirIrrigationUpdateHandler OnReservoirIrrigationUpdated;

	public void Reset()
	{
		Broadcast.BuildingAddRemove.Listen(noriaUniqueHash, UpdateIrrigation);
		Broadcast.BuildingAddRemove.Listen(aqueductUniqueHash, UpdateIrrigation);
		Broadcast.BuildingAddRemove.Listen(reservoirUniqueHash, UpdateIrrigation);
		Broadcast.BuildingAddRemove.Listen(bathhouseUniqueHash, UpdateIrrigation);
		if (OnReservoirIrrigationUpdated != null)
		{
			Delegate[] invocationList = OnReservoirIrrigationUpdated.GetInvocationList();
			for (int i = 0; i < invocationList.Length; i++)
			{
				ReservoirIrrigationUpdateHandler value = (ReservoirIrrigationUpdateHandler)invocationList[i];
				OnReservoirIrrigationUpdated -= value;
			}
		}
	}

	public void Update()
	{
		if (wasReservoirIrrigationUpdated)
		{
			if (OnReservoirIrrigationUpdated != null)
			{
				OnReservoirIrrigationUpdated();
			}
			wasReservoirIrrigationUpdated = false;
		}
	}

	private void UpdateIrrigation(object sender, OnBuildingAddRemove obj)
	{
		UpdateIrrigation();
	}

	public void UpdateIrrigation()
	{
		ReinitializeWaterBuildings();
		ResetVisited();
		FloodFillAqueducts();
	}

	private void ReinitializeWaterBuildings()
	{
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList("aqueduct");
		for (int i = 0; i < buildingList.Count; i++)
		{
			buildingList.data[i].GetComponent<Aqueduct>().HasWater = false;
			buildingList.data[i].GetComponent<Aqueduct>().IsConnected = false;
		}
		ArrayExt<Building> buildingList2 = Player.inst.GetBuildingList("reservoir");
		for (int j = 0; j < buildingList2.Count; j++)
		{
			buildingList2.data[j].GetComponent<Reservoir>().HasWater = false;
			buildingList2.data[j].GetComponent<Reservoir>().IsConnected = false;
		}
		ArrayExt<Building> buildingList3 = Player.inst.GetBuildingList("bathhouse");
		for (int k = 0; k < buildingList3.Count; k++)
		{
			buildingList3.data[k].GetComponent<Bathhouse>().HasWater = false;
			buildingList3.data[k].GetComponent<Bathhouse>().IsConnected = false;
		}
		ArrayExt<Building> buildingList4 = Player.inst.GetBuildingList("noria");
		for (int l = 0; l < buildingList4.Count; l++)
		{
			buildingList4.data[l].GetComponent<Noria>().HasWater = false;
		}
	}

	private void ResetVisited()
	{
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList("aqueduct");
		for (int i = 0; i < buildingList.Count; i++)
		{
			buildingList.data[i].GetComponent<Aqueduct>().IsVisited = false;
		}
		ArrayExt<Building> buildingList2 = Player.inst.GetBuildingList("reservoir");
		for (int j = 0; j < buildingList2.Count; j++)
		{
			buildingList2.data[j].GetComponent<Reservoir>().IsVisited = false;
		}
		ArrayExt<Building> buildingList3 = Player.inst.GetBuildingList("bathhouse");
		for (int k = 0; k < buildingList3.Count; k++)
		{
			buildingList3.data[k].GetComponent<Bathhouse>().IsVisited = false;
		}
		ArrayExt<Building> buildingList4 = Player.inst.GetBuildingList("noria");
		for (int l = 0; l < buildingList4.Count; l++)
		{
			buildingList4.data[l].GetComponent<Noria>().IsVisited = false;
		}
	}

	private void FloodFillAqueducts()
	{
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList("noria");
		for (int i = 0; i < buildingList.Count; i++)
		{
			int num = buildingList.data[i].GetComponent<Noria>().WaterPressure * 2;
			if (!buildingList.data[i].IsBuilt())
			{
				continue;
			}
			nodes.Clear();
			nodes.Add(new IrrigationNode
			{
				b = buildingList.data[i],
				w = buildingList.data[i].GetComponent<IWaterSystemUser>()
			});
			while (nodes.Count != 0)
			{
				Building b = nodes[0].b;
				IWaterSystemUser w = nodes[0].w;
				bool isNextToWater = nodes[0].isNextToWater;
				nodes.RemoveAt(0);
				bool flag = num > 0;
				bool flag2 = false;
				w.IsConnected = true;
				if (b.uniqueNameHash == noriaUniqueHash)
				{
					w.HasWater |= flag;
					flag2 = b.GetComponent<Noria>().ShouldIrrigate();
				}
				else
				{
					flag2 = w.HasWater;
					if (b.uniqueNameHash == reservoirUniqueHash || b.uniqueNameHash == bathhouseUniqueHash)
					{
						w.HasWater |= flag | isNextToWater;
					}
					else if (b.uniqueNameHash == aqueductUniqueHash)
					{
						w.HasWater |= flag;
					}
				}
				if (flag && !flag2)
				{
					num = ((b.uniqueNameHash != bathhouseUniqueHash) ? (num - 2) : (num - 6));
				}
				b.GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
				minX = Mathff.Clamp(minX - 1, 0, World.inst.GridWidth - 1);
				minZ = Mathff.Clamp(minZ - 1, 0, World.inst.GridWidth - 1);
				maxX = Mathff.Clamp(maxX + 1, 0, World.inst.GridHeight - 1);
				maxZ = Mathff.Clamp(maxZ + 1, 0, World.inst.GridHeight - 1);
				for (int j = minX; j <= maxX; j++)
				{
					for (int k = minZ; k <= maxZ; k++)
					{
						if ((k == minZ && j == minX) || (k == maxZ && j == maxX) || (k == minZ && j == maxX) || (k == maxZ && j == minX))
						{
							continue;
						}
						Building building = World.inst.GetCellDataClamped(j, k).StructureFind<IWaterSystemUser>();
						if (!(building == b) && !(building == null) && building.IsBuilt())
						{
							IWaterSystemUser component = building.GetComponent<IWaterSystemUser>();
							if (!component.IsVisited)
							{
								component.IsVisited = true;
								nodes.Add(new IrrigationNode
								{
									b = building,
									w = component,
									isNextToWater = (flag | flag2)
								});
							}
						}
					}
				}
			}
			ResetVisited();
		}
	}
}
