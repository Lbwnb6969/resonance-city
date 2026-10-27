using I2.Loc;
using UnityEngine;

public class RoadBasic : MonoBehaviour, IWorkerUIDisplay, IOutputInfo
{
	public Building b;

	public AdjacentMesh adjMesh;

	public RadiusBonus filthRadius;

	public MeshRenderer buildMarker;

	public bool ShowCustomButton()
	{
		return false;
	}

	public bool CustomButtonInteractable()
	{
		return false;
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	public string CustomButtonTitle()
	{
		return "";
	}

	public string CustomButtonText()
	{
		return "";
	}

	public Sprite CustomButtonImage()
	{
		return null;
	}

	public void CustomButtonClicked()
	{
	}

	private void OnInit()
	{
		b.PlacementValidaton = PlacementValidation;
		if ((bool)adjMesh && b.uniqueNameHash == World.stoneRoadHash)
		{
			adjMesh.shouldConnect = ShouldConnectStoneRoad;
		}
	}

	public void PlacementValidation(ref PlacementValidationResult result)
	{
		if (result != PlacementValidationResult.ExistingStructure)
		{
			return;
		}
		Cell cellDataClamped = World.inst.GetCellDataClamped(b.Center());
		if (b.uniqueNameHash == World.stoneRoadHash)
		{
			bool flag = false;
			for (int i = 0; i < cellDataClamped.OccupyingStructure.Count; i++)
			{
				if (cellDataClamped.OccupyingStructure[i].uniqueNameHash == World.roadHash)
				{
					flag = true;
					break;
				}
			}
			if (flag)
			{
				result = PlacementValidationResult.Valid;
			}
		}
		if ((result != PlacementValidationResult.Valid && cellDataClamped.BottomStructure.uniqueNameHash == World.stoneBridgeHash) || cellDataClamped.BottomStructure.uniqueNameHash == World.woodBridgeHash)
		{
			if (cellDataClamped.BottomStructure.GetComponent<Bridge>().isEndPiece)
			{
				bool flag2 = true;
				for (int j = 0; j < cellDataClamped.OccupyingStructure.Count; j++)
				{
					if (World.IsLandRoad(cellDataClamped.OccupyingStructure[j]))
					{
						flag2 = false;
						break;
					}
				}
				if (flag2)
				{
					result = PlacementValidationResult.Valid;
				}
			}
		}
		else
		{
			bool flag3 = true;
			for (int k = 0; k < cellDataClamped.OccupyingStructure.Count; k++)
			{
				if (cellDataClamped.OccupyingStructure[k].uniqueNameHash != World.waterTowerHash)
				{
					flag3 = false;
					break;
				}
			}
			if (flag3)
			{
				result = PlacementValidationResult.Valid;
			}
		}
		if (cellDataClamped.BottomStructure != null && World.IsLandRoad(cellDataClamped.BottomStructure) && b.uniqueNameHash != cellDataClamped.BottomStructure.uniqueNameHash && cellDataClamped.BottomStructure.uniqueNameHash == World.roadHash)
		{
			result = PlacementValidationResult.Valid;
		}
		if (cellDataClamped.StructureFindByCategory(World.gateHash) != null && !World.IsLandRoad(cellDataClamped.BottomStructure))
		{
			result = PlacementValidationResult.Valid;
		}
	}

	public static void ApplyRoadCoverage(Building b, bool undo)
	{
		int num = 5;
		Vector3 position = b.transform.position;
		int sx = (int)position.x;
		int sz = (int)position.z;
		World.inst.ForEachTile(sx - num, sz - num, sx + num, sz + num, (int x, int z, Cell cell) =>
		{
			int num2 = 1;
			if ((x - sx) * (x - sx) + (z - sz) * (z - sz) <= num2 || cell.Type != TerrainType.Water)
			{
				cell.AddRoadCoverage((!undo) ? 1 : (-1));
			}
		});
	}

	private void OnBuildingPlacement(bool undo)
	{
		ApplyRoadCoverage(b, undo);
		int num = SRand.Range(0, 3);
		transform.GetChild(0).Rotate(new Vector3(0f, 90 * num, 0f), Space.Self);
	}

	private void OnBuilt()
	{
		TerrainGen.inst.SetRoadTile(b.GetCell(), isWood: true, isStone: false);
		if ((bool)buildMarker)
		{
			buildMarker.enabled = false;
		}
	}

	private void OnFinishedLoad()
	{
		if (b.IsBuilt())
		{
			TerrainGen.inst.SetRoadTile(b.GetCell(), isWood: true, isStone: false);
			if ((bool)buildMarker)
			{
				buildMarker.enabled = false;
			}
		}
	}

	private void OnDisable()
	{
		if (b.IsBuilt())
		{
			TerrainGen.inst.SetRoadTile(b.GetCell(), isWood: false, isStone: false);
		}
	}

	public static bool ConnectsToStoneRoad(Building b)
	{
		if (b.uniqueNameHash != World.stoneBridgeHash && b.uniqueNameHash != World.woodBridgeHash && b.uniqueNameHash != World.roadHash)
		{
			if (b.categoryHash != World.pathHash && b.categoryHash != World.gateHash && b.uniqueNameHash != World.townsquareHash)
			{
				return b.categoryHash == World.parkHash;
			}
			return true;
		}
		return false;
	}

	public static bool ShouldConnectStoneRoad(Cell c)
	{
		if (c != null)
		{
			for (int i = 0; i < c.OccupyingStructure.Count; i++)
			{
				if (ConnectsToStoneRoad(c.OccupyingStructure[i]))
				{
					return true;
				}
			}
			if (GameUI.inst.CurrPlacementMode.TestRoadConnection(c))
			{
				return true;
			}
		}
		return false;
	}

	public string GetError()
	{
		if (b.thought.thought == ThoughtBubbleSystem.Thought.PoopCritical)
		{
			if (PublicToiletManager.inst.GetProtectionWithStaff((int)b.Center().x, (int)b.Center().z) > 0f)
			{
				return LocalizationManager.GetTranslation("workerui_filtherrormoretoilets");
			}
			return LocalizationManager.GetTranslation("workerui_filtherror");
		}
		return "";
	}
}
