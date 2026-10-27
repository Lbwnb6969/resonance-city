using System;
using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;

public class DemolishWarningUI : MonoBehaviour
{
	public GameObject CellHighlighterPrefab;

	private Selector CellHighlighter;

	public Material fillRedMat;

	private static List<Cell> selectedCells = new List<Cell>();

	private HashSet<Guid> topBuildingIdentifiers = new HashSet<Guid>();

	private HashSet<Guid> subBuildingIdentifiers = new HashSet<Guid>();

	private HashSet<Guid> milestoneBuildingIdentifiers = new HashSet<Guid>();

	private const int MIN_BUILDING_COUNT = 25;

	public TextMeshProUGUI message;

	private ArrayExt<Guid> highlightedBridgeGroups = new ArrayExt<Guid>(32);

	private void TryInit()
	{
		if (CellHighlighter == null)
		{
			CellHighlighter = UnityEngine.Object.Instantiate(GameUI.inst.HighlightPrefab).GetComponent<Selector>();
			CellHighlighter.SetVisibility(v: false);
		}
	}

	private void Start()
	{
		TryInit();
	}

	public void AddCell(Cell cell)
	{
		if ((cell.OccupyingStructure.Count <= 0 && cell.SubStructure.Count <= 0) || gameObject.activeSelf)
		{
			return;
		}
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			Building building = cell.OccupyingStructure[i];
			topBuildingIdentifiers.Add(building.guid);
			if (building.categoryHash != World.forumHash && building.categoryHash != World.pathHash)
			{
				milestoneBuildingIdentifiers.Add(building.guid);
			}
		}
		selectedCells.Add(cell);
	}

	public void DoDemolishOrShowWarning(int minX, int maxX, int minZ, int maxZ)
	{
		if (topBuildingIdentifiers.Count != 0 || subBuildingIdentifiers.Count != 0)
		{
			if (((topBuildingIdentifiers.Count != 0) ? topBuildingIdentifiers.Count : subBuildingIdentifiers.Count) > 25)
			{
				ShowUI(minX, maxX, minZ, maxZ);
			}
			else
			{
				DemolishBuildings();
			}
		}
	}

	public void ShowUI(int minX, int maxX, int minZ, int maxZ)
	{
		int num = ((topBuildingIdentifiers.Count != 0) ? topBuildingIdentifiers.Count : subBuildingIdentifiers.Count);
		message.text = string.Format(ScriptLocalization.DemolishWarningUI, num);
		GameUI.inst.ClearCellSelected();
		GameUI.inst.CellHighlighter.SetHoverIcon(GameUI.HoverIcons.None);
		gameObject.SetActive(value: true);
		TryInit();
		CellHighlighter.SetVisibility(v: true);
		CellHighlighter.SetTargetWorldBounds(minX, maxX, minZ, maxZ);
	}

	public void ExitUI()
	{
		if (GameUI.inst.currCursorMode == GameUI.inst.demolishCursorMode)
		{
			GameUI.inst.CellHighlighter.SetHoverIcon(GameUI.HoverIcons.Demolish);
		}
		gameObject.SetActive(value: false);
		CellHighlighter.SetVisibility(v: false);
		selectedCells.Clear();
		topBuildingIdentifiers.Clear();
		subBuildingIdentifiers.Clear();
		milestoneBuildingIdentifiers.Clear();
	}

	public void DemolishBuildingsButton()
	{
		DemolishBuildings();
		ExitUI();
	}

	public void DemolishBuildings()
	{
		highlightedBridgeGroups.ClearFast();
		bool doEffects = true;
		bool flag = topBuildingIdentifiers.Count == 0;
		for (int i = 0; i < selectedCells.Count; i++)
		{
			Cell cell = selectedCells[i];
			List<Building> list;
			if (cell.OccupyingStructure.Count > 0)
			{
				list = cell.OccupyingStructure;
			}
			else
			{
				if (!flag || cell.SubStructure.Count <= 0)
				{
					continue;
				}
				list = cell.SubStructure;
			}
			OneOffEffect oneOffEffect = EffectsMan.inst.TileActionEffect.Create(cell.Center3D + new Vector3(0f, 1f, 0f));
			oneOffEffect.Color = new Color(1f, 0.3f, 0.3f);
			oneOffEffect.AllowRelease = true;
			oneOffEffect.Play();
			for (int num = list.Count - 1; num >= 0; num--)
			{
				Building building = list[num];
				if (!building.CanDemolishBuilding())
				{
					continue;
				}
				if (building.TryGetComponent<EditTerrainProjectReference>(out var component))
				{
					component.project.DemolishBuilding();
					continue;
				}
				if (building.uniqueNameHash == World.stoneBridgeHash || building.uniqueNameHash == World.woodBridgeHash)
				{
					Bridge component2 = building.GetComponent<Bridge>();
					if (highlightedBridgeGroups.Contains(component2.groupGuid))
					{
						continue;
					}
					highlightedBridgeGroups.Add(component2.groupGuid);
					for (int j = 0; j < component2.bridgePath.Count; j++)
					{
						if (component2.bridgePathIdx == j)
						{
							continue;
						}
						Cell cellData = World.inst.GetCellData(component2.bridgePath.data[j]);
						for (int k = 0; k < cellData.OccupyingStructure.Count; k++)
						{
							Building building2 = cellData.OccupyingStructure[k];
							if (building2 != null && building2.uniqueNameHash == building.uniqueNameHash)
							{
								World.inst.DemolishBuildingByPlayer(building2, doEffects);
							}
						}
					}
				}
				World.inst.DemolishBuildingByPlayer(building, doEffects);
				doEffects = false;
			}
		}
		MilestoneManager.inst.CheckDemolish25AtOnceMilestone(milestoneBuildingIdentifiers.Count);
		selectedCells.Clear();
		topBuildingIdentifiers.Clear();
		subBuildingIdentifiers.Clear();
		milestoneBuildingIdentifiers.Clear();
	}

	public void HighlightBuildings(int minX, int minZ, int maxX, int maxZ)
	{
		highlightedBridgeGroups.ClearFast();
		for (int i = minZ; i < maxZ; i++)
		{
			for (int j = minX; j < maxX; j++)
			{
				Cell cellData = World.inst.GetCellData(j, i);
				if (cellData == null)
				{
					continue;
				}
				for (int k = 0; k < cellData.OccupyingStructure.Count; k++)
				{
					Building building = cellData.OccupyingStructure[k];
					building.SetOutlineImmediate(2);
					if (building.uniqueNameHash != World.stoneBridgeHash && building.uniqueNameHash != World.woodBridgeHash)
					{
						continue;
					}
					Bridge component = building.GetComponent<Bridge>();
					if (highlightedBridgeGroups.Contains(component.groupGuid))
					{
						continue;
					}
					highlightedBridgeGroups.Add(component.groupGuid);
					for (int l = 0; l < component.bridgePath.Count; l++)
					{
						if (component.bridgePathIdx != l)
						{
							Building building2 = World.inst.GetCellData(component.bridgePath.data[l]).StructureFind(building.uniqueNameHash);
							if (building2 != null)
							{
								building2.SetOutlineImmediate(2);
							}
						}
					}
				}
			}
		}
	}
}
