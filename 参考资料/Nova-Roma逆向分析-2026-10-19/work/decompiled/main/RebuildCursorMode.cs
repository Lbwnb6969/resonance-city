using System.Collections.Generic;
using Assets.Code;
using UnityEngine;

public class RebuildCursorMode : TileOperationCursorMode
{
	private Dictionary<string, int> rubbleMap = new Dictionary<string, int>(32);

	private List<BuildingCollapseManager.RubbleGroup> rubbleGroups = new List<BuildingCollapseManager.RubbleGroup>(32);

	private List<Building> rubble = new List<Building>(32);

	private ResourceAmount[] lmCost;

	private void DoEffect(Cell cell)
	{
		OneOffEffect oneOffEffect = EffectsMan.inst.TileActionEffect.Create(cell.Center3D);
		oneOffEffect.Color = new Color(1f, 1f, 0.5f);
		oneOffEffect.AllowRelease = true;
		oneOffEffect.Play();
	}

	private void Reset()
	{
		if (lmCost == null || lmCost.Length != World.inst.NumLandMasses)
		{
			lmCost = new ResourceAmount[World.inst.NumLandMasses];
		}
		for (int i = 0; i < lmCost.Length; i++)
		{
			if (lmCost[i] == null)
			{
				lmCost[i] = new ResourceAmount();
			}
			else
			{
				lmCost[i].Clear();
			}
		}
		rubbleMap.Clear();
		rubbleGroups.Clear();
		rubble.Clear();
	}

	public override void HandleDragPrimaryUp(int minX, int minZ, int maxX, int maxZ, bool returnedToOriginal)
	{
		Reset();
		ResourceAmount resourceAmount = new ResourceAmount();
		for (int i = minX; i < maxX; i++)
		{
			for (int j = minZ; j < maxZ; j++)
			{
				Cell cellData = World.inst.GetCellData(i, j);
				if (!Player.inst.LandMassIsAPlayerLandMass(cellData.landMassIdx))
				{
					continue;
				}
				if (BuildingCollapseManager.CollectGroups(cellData, ref rubbleGroups, ref rubbleMap, ref rubble))
				{
					ResourceAmount obj = Player.inst.resourcesPerLandmass[cellData.landMassIdx];
					ResourceAmount addR = BuildingCollapseManager.GetTotalCost(cellData.landMassIdx, ref rubbleMap);
					resourceAmount.Clear();
					resourceAmount.Add(in lmCost[cellData.landMassIdx]);
					resourceAmount.Add(in addR);
					if (obj.HasCost(resourceAmount))
					{
						ResourceAmount[] array = lmCost;
						int landMassIdx = cellData.landMassIdx;
						array[landMassIdx] += addR;
						BuildingCollapseManager.RebuildGroups(rubbleGroups);
					}
					rubbleGroups.Clear();
					rubbleMap.Clear();
					rubble.Clear();
				}
				DoEffect(cellData);
			}
		}
		for (int k = 0; k < lmCost.Length; k++)
		{
			int num = lmCost[k].Get(4);
			if (num > 0)
			{
				World.GetLandmassOwner(k).Gold -= num;
			}
		}
		base.HandleDragPrimaryUp(minX, minZ, maxX, maxZ, returnedToOriginal);
	}

	public override bool DoPrimaryClick(ISelectableBuilding clickedBuilding, Cell clickedCell)
	{
		Reset();
		Building building = clickedBuilding as Building;
		if (building != null && building.IsPlayerBuilding())
		{
			LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
			Cell cell = building.GetCell();
			if (BuildingCollapseManager.CollectGroups(cell, ref rubbleGroups, ref rubbleMap, ref rubble))
			{
				ResourceAmount obj = Player.inst.resourcesPerLandmass[cell.landMassIdx];
				ResourceAmount totalCost = BuildingCollapseManager.GetTotalCost(cell.landMassIdx, ref rubbleMap);
				if (obj.HasCost(totalCost))
				{
					BuildingCollapseManager.RebuildGroups(rubbleGroups);
					playerLandmassOwner.Gold -= totalCost.Get(4);
				}
			}
			DoEffect(cell);
		}
		return true;
	}
}
