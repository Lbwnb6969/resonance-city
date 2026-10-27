using System;
using UnityEngine;

public class DrawBridge : Tickable
{
	public Transform bridge;

	private Building b;

	private Vector3 bridgeFwd;

	private Vector3 bridgeRight;

	public bool wasOpen;

	[NonSerialized]
	public float openTime;

	public override void OnEnableInternal()
	{
		transform.GetChild(0).localPosition = new Vector3(0.5f, -0.4f, 0.5f);
		b = GetComponent<Building>();
		AdjacentMesh.RefreshSurroundingRoads(GetComponent<Building>());
		base.OnEnableInternal();
	}

	public override void OnDisableInternal()
	{
		AdjacentMesh.RefreshSurroundingRoads(GetComponent<Building>());
		base.OnDisableInternal();
	}

	private void OnBuilt()
	{
		AdjacentMesh.RefreshSurroundingRoads(GetComponent<Building>());
	}

	private void OnBuildingPlacement(bool undo)
	{
		bridgeFwd = -transform.GetChild(0).forward;
		bridgeRight = transform.GetChild(0).right;
	}

	private bool TestShipPos(Vector3 currPos, Cell buildingCell, Cell buildingCell2)
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
		}
		return false;
	}

	public override void Tick(float dt, int currFrame)
	{
		bool flag = false;
		if (!b.IsBuilt())
		{
			return;
		}
		Cell cell = b.GetCell();
		int teamIDB = b.TeamID();
		if (cell != null)
		{
			Cell cellData = World.inst.GetCellData(cell.x + (int)bridgeFwd.x, cell.z + (int)bridgeFwd.z);
			IMoveableUnit moveableUnit = OrdersManager.inst.FindUnitAt(cellData.x, cellData.z);
			if (moveableUnit != null && World.inst.RelationBetween(moveableUnit.TeamID(), teamIDB) == World.Relations.Enemy)
			{
				flag = true;
			}
			moveableUnit = OrdersManager.inst.FindUnitAt(cell.x + (int)bridgeRight.x, cell.z + (int)bridgeRight.z);
			if (moveableUnit != null && World.inst.RelationBetween(moveableUnit.TeamID(), teamIDB) == World.Relations.Enemy)
			{
				flag = true;
			}
			moveableUnit = OrdersManager.inst.FindUnitAt(cell.x - (int)bridgeRight.x, cell.z - (int)bridgeRight.z);
			if (moveableUnit != null && World.inst.RelationBetween(moveableUnit.TeamID(), teamIDB) == World.Relations.Enemy)
			{
				flag = true;
			}
			int num = 1;
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
						if (shipBase.arrived)
						{
							continue;
						}
						Vector3 pos = shipBase.dynamics.Pos;
						Vector3 normalized = (shipBase.GetTargetPos(0) - pos).normalized;
						Vector3 currPos = normalized + pos;
						Vector3 currPos2 = normalized * 2f + pos;
						Vector3 currPos3 = normalized * -1f + pos;
						if (!TestShipPos(pos, cell, cellData) && !TestShipPos(currPos, cell, cellData) && !TestShipPos(currPos2, cell, cellData) && !TestShipPos(currPos3, cell, cellData))
						{
							continue;
						}
						goto IL_02ae;
					}
				}
				continue;
				IL_02ae:
				flag = true;
				break;
			}
		}
		if (flag && !wasOpen)
		{
			SfxSystem.inst.PlayFromBankIfVisible("drawBridgeDown", b.transform.position);
			b.BakePathing();
		}
		else if (!flag && wasOpen)
		{
			SfxSystem.inst.PlayFromBankIfVisible("drawBridgeUp", b.transform.position);
			b.BakePathing();
		}
		wasOpen = flag;
		openTime += (flag ? dt : (0f - dt));
		openTime = Mathff.Clamp01(openTime);
		bridge.localRotation = Quaternion.Euler(Mathff.Lerp(0f, 90f, openTime), 0f, 0f);
	}

	public void CanPlace(Building obj, Cell cell, ref PlacementValidationResult result)
	{
		if (cell.Type == TerrainType.Water && !cell.deepWater && cell.BottomStructureIsCategory(World.pathHash))
		{
			result = PlacementValidationResult.Valid;
		}
	}
}
