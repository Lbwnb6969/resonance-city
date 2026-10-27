using System;
using UnityEngine;

public class CastleStairs : MonoBehaviour
{
	private EventHandler<OnBuildingAddRemove> listenEventHandler;

	private Building b;

	public GameObject north;

	public GameObject south;

	public GameObject east;

	public GameObject west;

	private void Start()
	{
	}

	private void OnInit()
	{
		listenEventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		b = GetComponent<Building>();
		b.PlacementValidaton = PlacementValidation;
	}

	public void PlacementValidation(ref PlacementValidationResult result)
	{
		if (World.inst.GetCellDataClamped(b.Center()).StructureCompareCategoryNameAll(World.pathHash))
		{
			result = PlacementValidationResult.Valid;
		}
	}

	private void OnBuilt()
	{
		RefreshSurroundingRotation();
	}

	public void UpdateRotation()
	{
		RefreshSurroundingRotation();
	}

	private void OnBuildingPlacement(bool undo)
	{
		RefreshSurroundingRotation();
		BlockBuilding.MarkBlockStackAndNeighborsDirty(GetComponent<Building>().GetCell());
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		RefreshSurroundingRotation();
	}

	private void OnDisable()
	{
		RefreshSurroundingRotation();
		Broadcast.BuildingAddRemove.UnlistenAny(listenEventHandler);
		BlockBuilding.MarkBlockStackAndNeighborsDirty(GetComponent<Building>().GetCell());
	}

	private static bool ToggleStairs(int x, int z, GameObject stairs)
	{
		Cell cellData = World.inst.GetCellData(x, z);
		if (cellData.TopStructureIs(World.castlestairsHash))
		{
			stairs.SetActive(value: false);
			return false;
		}
		Building building = cellData.StructureFind(World.gateHash);
		Building building2 = cellData.StructureFindByCategory(World.castleblockHash);
		stairs.SetActive((bool)building2 && !building);
		return stairs.activeSelf;
	}

	private void OnPostLoad()
	{
		RefreshSurroundingRotation();
	}

	private void RefreshSurroundingRotation()
	{
		Building component = GetComponent<Building>();
		Vector3 position = component.transform.position;
		bool activeSelf = north.activeSelf;
		bool activeSelf2 = south.activeSelf;
		bool activeSelf3 = west.activeSelf;
		bool activeSelf4 = east.activeSelf;
		bool flag = false;
		flag |= ToggleStairs((int)position.x, (int)position.z + 1, north);
		flag |= ToggleStairs((int)position.x, (int)position.z - 1, south);
		flag |= ToggleStairs((int)position.x + 1, (int)position.z, east);
		flag |= ToggleStairs((int)position.x - 1, (int)position.z, west);
		if (flag)
		{
			transform.GetChild(0).localRotation = Quaternion.identity;
		}
		if (!component.IsBuilt() && !flag)
		{
			north.gameObject.SetActive(value: true);
		}
		if (component.IsBuilt() && !flag)
		{
			if (!activeSelf && !activeSelf2 && !activeSelf3 && !activeSelf4)
			{
				north.SetActive(value: true);
				return;
			}
			north.SetActive(activeSelf);
			south.SetActive(activeSelf2);
			west.SetActive(activeSelf3);
			east.SetActive(activeSelf4);
		}
	}
}
