using System;
using UnityEngine;

public class SeaGate : Tickable
{
	public Transform bridge;

	private Building b;

	private float closedZ = 0.3171233f;

	private float openedZ = 1.1f;

	private bool wasOpen;

	[NonSerialized]
	public float openTime;

	private Vector3 bridgeFwd;

	private void Awake()
	{
		b = GetComponent<Building>();
		b.PlacementValidaton = PlacementValidation;
	}

	private void PlacementValidation(ref PlacementValidationResult validationResult)
	{
		Cell cellDataClamped = World.inst.GetCellDataClamped(b.Center());
		validationResult = PlacementValidationResult.Valid;
		if (cellDataClamped.TopStructure != null)
		{
			validationResult = PlacementValidationResult.ExistingStructure;
		}
		else if (cellDataClamped.Type != TerrainType.Water)
		{
			validationResult = PlacementValidationResult.SeaGateNotOnWater;
		}
		else if (cellDataClamped.Type == TerrainType.Water && cellDataClamped.deepWater)
		{
			validationResult = PlacementValidationResult.MustBeOnShallowWater;
		}
	}

	public override void OnEnableInternal()
	{
		transform.GetChild(0).localPosition = new Vector3(0.5f, -0.4f, 0.5f);
		b = GetComponent<Building>();
		base.OnEnableInternal();
	}

	private bool TestShipPos(Vector3 currPos, Cell buildingCell, Cell buildingCell2, Cell buildingCell3)
	{
		Cell cellData = World.inst.GetCellData(currPos);
		if (cellData != null && Mathff.Abs(cellData.x - buildingCell.x) <= 1 && Mathff.Abs(cellData.z - buildingCell.z) <= 1)
		{
			int num = (int)currPos.x;
			int num2 = (int)currPos.z;
			if (num == buildingCell.x && num2 == buildingCell.z)
			{
				return true;
			}
			if (num == buildingCell2.x && num2 == buildingCell2.z)
			{
				return true;
			}
			if (num == buildingCell3.x && num2 == buildingCell3.z)
			{
				return true;
			}
		}
		return false;
	}

	private void OnBuildingPlacement(bool undo)
	{
		bridgeFwd = -transform.GetChild(0).forward;
	}

	public override void Tick(float dt, int currFrame)
	{
		bool flag = false;
		Cell cell = b.GetCell();
		if (cell != null && b.IsBuilt())
		{
			Cell cellData = World.inst.GetCellData(cell.x + (int)bridgeFwd.x, cell.z + (int)bridgeFwd.z);
			Cell cellData2 = World.inst.GetCellData(cellData.x + (int)bridgeFwd.x, cell.z + (int)bridgeFwd.z);
			int teamIDA = b.TeamID();
			int num = 2;
			int num2 = (int)Mathf.Clamp(b.cachedPos.x - (float)num, 0f, World.inst.GridWidth - 1);
			int num3 = (int)Mathf.Clamp(b.cachedPos.z - (float)num, 0f, World.inst.GridHeight - 1);
			int num4 = (int)Mathf.Clamp(b.cachedPos.x + (float)num, 0f, World.inst.GridWidth - 1);
			int num5 = (int)Mathf.Clamp(b.cachedPos.z + (float)num, 0f, World.inst.GridHeight - 1);
			for (int i = num3; i <= num5; i++)
			{
				for (int j = num2; j <= num4; j++)
				{
					ArrayExt<ShipBase> shipsAt = ShipSystem.inst.GetShipsAt(j, i);
					for (int k = 0; k < shipsAt.Count; k++)
					{
						ShipBase shipBase = shipsAt.data[k];
						if (World.inst.RelationBetween(teamIDA, shipBase.teamID) == World.Relations.Enemy)
						{
							continue;
						}
						Vector3 pos = shipBase.dynamics.Pos;
						Vector3 normalized = (shipBase.GetTargetPos(0) - pos).normalized;
						Vector3 currPos = normalized + pos;
						Vector3 currPos2 = normalized * 2f + pos;
						Vector3 currPos3 = normalized * -1f + pos;
						if (!TestShipPos(pos, cell, cellData, cellData2) && !TestShipPos(currPos, cell, cellData, cellData2) && !TestShipPos(currPos2, cell, cellData, cellData2) && !TestShipPos(currPos3, cell, cellData, cellData2))
						{
							continue;
						}
						goto IL_0229;
					}
				}
				continue;
				IL_0229:
				flag = true;
				break;
			}
		}
		if (flag && !wasOpen)
		{
			SfxSystem.inst.PlayFromBankIfVisible("drawBridgeDown", b.transform.position);
		}
		if (!flag && wasOpen)
		{
			SfxSystem.inst.PlayFromBankIfVisible("drawBridgeUp", b.transform.position);
		}
		wasOpen = flag;
		openTime += (flag ? dt : (0f - dt));
		openTime = Mathff.Clamp01(openTime);
		Vector3 localPosition = bridge.localPosition;
		localPosition.z = Mathff.Lerp(closedZ, openedZ, openTime);
		bridge.localPosition = localPosition;
	}
}
