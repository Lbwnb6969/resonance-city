using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

public class BlockBuilding : Building
{
	public GameObject doorPrefab;

	public Transform doorContainer;

	public Transform Straight4Way;

	public Transform Straight3Way;

	public Transform StraightStraight;

	public Transform StraightCorner;

	public Transform StraightDeadEnd;

	public Transform StraightSingle;

	public Transform DiagonalDeadEnd;

	public Transform DiagonalStraight;

	public Transform DiagonalCorner;

	public Transform Diagonal3Way;

	public Transform Diagonal4Way;

	public Transform DiagonalBendLeft;

	public Transform DiagonalBendRight;

	public Transform Diagonal2Straight1;

	public Transform Diagonal1Straight2;

	public Transform Straight4WayTop;

	public Transform Straight3WayTop;

	public Transform StraightStraightTop;

	public Transform StraightCornerTop;

	public Transform StraightDeadEndTop;

	public Transform StraightSingleTop;

	public Transform DiagonalDeadEndTop;

	public Transform DiagonalStraightTop;

	public Transform DiagonalCornerTop;

	public Transform Diagonal3WayTop;

	public Transform Diagonal4WayTop;

	public Transform DiagonalBendLeftTop;

	public Transform DiagonalBendRightTop;

	public Transform Diagonal2Straight1Top;

	public Transform Diagonal1Straight2Top;

	public Transform Straight4WayBottom;

	public Transform Straight3WayBottom;

	public Transform StraightStraightBottom;

	public Transform StraightCornerBottom;

	public Transform StraightDeadEndBottom;

	public Transform StraightSingleBottom;

	public Transform DiagonalDeadEndBottom;

	public Transform DiagonalStraightBottom;

	public Transform DiagonalCornerBottom;

	public Transform Diagonal3WayBottom;

	public Transform Diagonal4WayBottom;

	public Transform DiagonalBendLeftBottom;

	public Transform DiagonalBendRightBottom;

	public Transform Diagonal2Straight1Bottom;

	public Transform Diagonal1Straight2Bottom;

	public Transform Straight4WayCollider;

	public Transform Straight3WayCollider;

	public Transform StraightStraightCollider;

	public Transform StraightCornerCollider;

	public Transform StraightDeadEndCollider;

	public Transform StraightSingleCollider;

	public Transform DiagonalDeadEndCollider;

	public Transform DiagonalStraightCollider;

	public Transform DiagonalCornerCollider;

	public Transform Diagonal3WayCollider;

	public Transform Diagonal4WayCollider;

	public Transform DiagonalBendLeftCollider;

	public Transform DiagonalBendRightCollider;

	public Transform Diagonal2Straight1Collider;

	public Transform Diagonal1Straight2Collider;

	public Transform Straight4WayTopCollider;

	public Transform Straight3WayTopCollider;

	public Transform StraightStraightTopCollider;

	public Transform StraightCornerTopCollider;

	public Transform StraightDeadEndTopCollider;

	public Transform StraightSingleTopCollider;

	public Transform DiagonalDeadEndTopCollider;

	public Transform DiagonalStraightTopCollider;

	public Transform DiagonalCornerTopCollider;

	public Transform Diagonal3WayTopCollider;

	public Transform Diagonal4WayTopCollider;

	public Transform DiagonalBendLeftTopCollider;

	public Transform DiagonalBendRightTopCollider;

	public Transform Diagonal2Straight1TopCollider;

	public Transform Diagonal1Straight2TopCollider;

	public Transform Straight4WayBottomCollider;

	public Transform Straight3WayBottomCollider;

	public Transform StraightStraightBottomCollider;

	public Transform StraightCornerBottomCollider;

	public Transform StraightDeadEndBottomCollider;

	public Transform StraightSingleBottomCollider;

	public Transform DiagonalDeadEndBottomCollider;

	public Transform DiagonalStraightBottomCollider;

	public Transform DiagonalCornerBottomCollider;

	public Transform Diagonal3WayBottomCollider;

	public Transform Diagonal4WayBottomCollider;

	public Transform DiagonalBendLeftBottomCollider;

	public Transform DiagonalBendRightBottomCollider;

	public Transform Diagonal2Straight1BottomCollider;

	public Transform Diagonal1Straight2BottomCollider;

	[FormerlySerializedAs("WaterObstructionLayoutsOpen")]
	public Transform[] WaterObstructionLayoutsStraight4Way;

	[FormerlySerializedAs("WaterObstructionLayoutsSingle")]
	public Transform[] WaterObstructionLayoutsStraight3Way;

	[FormerlySerializedAs("WaterObstructionLayoutsOpposite")]
	public Transform[] WaterObstructionLayoutsStraightStraight;

	[FormerlySerializedAs("WaterObstructionLayoutsAdjacent")]
	public Transform[] WaterObstructionLayoutsStraightCorner;

	[FormerlySerializedAs("WaterObstructionLayoutsDeadEnd")]
	[FormerlySerializedAs("WaterObstructionLayoutsThreeside")]
	public Transform[] WaterObstructionLayoutsStraightDeadEnd;

	[FormerlySerializedAs("WaterObstructionLayoutsAlone")]
	[FormerlySerializedAs("WaterObstructionLayoutsClosed")]
	public Transform[] WaterObstructionLayoutsStraightAlone;

	public Transform[] WaterObstructionLayoutsDiagonalDeadEnd;

	public Transform[] WaterObstructionLayoutsDiagonalStraight;

	public Transform[] WaterObstructionLayoutsDiagonalCorner;

	public Transform[] WaterObstructionLayoutsDiagonal3Way;

	public Transform[] WaterObstructionLayoutsDiagonal4Way;

	public Transform[] WaterObstructionLayoutsDiagonalBendLeft;

	public Transform[] WaterObstructionLayoutsDiagonalBendRight;

	public Transform[] WaterObstructionLayoutsDiagonal2Straight1;

	public Transform[] WaterObstructionLayoutsDiagonal1Straight2;

	public Transform[] WaterObstructionActive;

	[NonSerialized]
	public Vector3[] waterObstructionWorldPoints;

	[NonSerialized]
	public int waterObstructionWorldPointCount;

	private bool applyVisualLayout = true;

	public Building b;

	public bool singleLevelOnly;

	public bool UseDiagonals;

	public virtual void OnInit()
	{
		b = GetComponent<Building>();
		b.Stackable = true;
		Util.SetMesh(transform, StraightSingle, StraightSingleCollider);
		b.UpdateMaterialSelection();
		b.visibilityChanged += B_visibilityChanged;
	}

	private void B_visibilityChanged(bool v)
	{
		VisibleDoors(b.IsBuilt() & v);
	}

	private void ClearDoors()
	{
		for (int i = 0; i < doorContainer.childCount; i++)
		{
			UnityEngine.Object.Destroy(doorContainer.GetChild(i).gameObject);
		}
	}

	private void VisibleDoors(bool visible)
	{
		for (int i = 0; i < doorContainer.childCount; i++)
		{
			doorContainer.GetChild(i).gameObject.SetActive(visible);
		}
	}

	private void ResetRotation()
	{
		Transform child = base.transform.GetChild(0);
		float y = child.rotation.eulerAngles.y;
		if (BlockStackUpdateSystem.inst.SuppressColliderUpdates && Mathf.Abs(y) > 0.01f)
		{
			Transform transform = child.GetComponentInChildren<MeshCollider>()?.transform;
			if (transform != null && transform != child)
			{
				BlockStackUpdateSystem.inst.QueueColliderRotationReset(transform, transform.localRotation);
				transform.Rotate(Vector3.up, y, Space.World);
			}
		}
		child.RotateAround(base.transform.position + new Vector3(b.size.x / 2f, 0f, b.size.z / 2f), Vector3.up, 0f - y);
	}

	private void RotatePiece(float degrees)
	{
		Transform child = base.transform.GetChild(0);
		child.RotateAround(base.transform.position + new Vector3(b.size.x / 2f, 0f, b.size.z / 2f), Vector3.up, degrees);
		if (BlockStackUpdateSystem.inst.SuppressColliderUpdates)
		{
			Transform transform = child.GetComponentInChildren<MeshCollider>()?.transform;
			if (transform != null && transform != child)
			{
				BlockStackUpdateSystem.inst.QueueColliderRotationReset(transform, transform.localRotation);
				transform.Rotate(Vector3.up, 0f - degrees, Space.World);
			}
		}
	}

	private bool DoesConnect(Cell otherCell, bool builtOnly = false)
	{
		if (otherCell == null || ignoreForLayout)
		{
			return false;
		}
		int count = otherCell.OccupyingStructure.Count;
		List<Building> occupyingStructure = otherCell.OccupyingStructure;
		for (int i = 0; i < count; i++)
		{
			Building building = occupyingStructure[i];
			if (!building.ignoreForLayout && !(building == this) && (!builtOnly || building.IsBuilt()))
			{
				if (building.uniqueNameHash == uniqueNameHash)
				{
					return true;
				}
				if ((uniqueNameHash == World.castleblockHash || uniqueNameHash == World.woodcastleblockHash) && (building.uniqueNameHash == World.castleblockHash || building.uniqueNameHash == World.woodcastleblockHash || building.categoryHash == World.gateHash))
				{
					return true;
				}
				if ((building.uniqueNameHash == World.spilloverHash && b.uniqueNameHash == World.damHash) || (building.uniqueNameHash == World.damHash && b.uniqueNameHash == World.spilloverHash))
				{
					return true;
				}
			}
		}
		if (builtOnly)
		{
			return false;
		}
		Building[] array = GameUI.inst.CurrPlacementMode?.buildingMap;
		if (array != null)
		{
			Building building2 = array[otherCell.index];
			if (building2 != null && !building2.ignoreForLayout && building2 != b)
			{
				if (building2.uniqueNameHash == uniqueNameHash)
				{
					return true;
				}
				if ((uniqueNameHash == World.castleblockHash || uniqueNameHash == World.woodcastleblockHash) && (building2.uniqueNameHash == World.castleblockHash || building2.uniqueNameHash == World.woodcastleblockHash || building2.categoryHash == World.gateHash))
				{
					return true;
				}
				if ((building2.uniqueNameHash == World.spilloverHash && b.uniqueNameHash == World.damHash) || (building2.uniqueNameHash == World.damHash && b.uniqueNameHash == World.spilloverHash))
				{
					return true;
				}
			}
		}
		return false;
	}

	public void UpdateBlock()
	{
		Cell cell = b.GetCell();
		if (cell == null)
		{
			return;
		}
		float num = float.MaxValue;
		float num2 = float.MinValue;
		for (int num3 = cell.OccupyingStructure.Count - 1; num3 >= 0; num3--)
		{
			Building building = cell.OccupyingStructure[num3];
			if (building.uniqueNameHash == World.damHash)
			{
				if (building.cachedPos.y > num2)
				{
					num2 = building.cachedPos.y;
				}
				if (building.cachedPos.y < num)
				{
					num = building.cachedPos.y;
				}
			}
		}
		PlacementMode currPlacementMode = GameUI.inst.CurrPlacementMode;
		if (currPlacementMode != null && b.isPreviewBuilding)
		{
			int index = cell.index;
			if (currPlacementMode.cellHighestDamY.TryGetValue(index, out var value) && value > num2)
			{
				num2 = value;
			}
			if (currPlacementMode.cellLowestDamY.TryGetValue(index, out var value2) && value2 < num)
			{
				num = value2;
			}
		}
		float y = b.transform.position.y;
		bool flag = Mathf.Approximately(y, num);
		bool top = Mathf.Approximately(y, num2);
		if (singleLevelOnly)
		{
			flag = false;
			top = false;
		}
		flag = false;
		int x = cell.x;
		int z = cell.z;
		if (!BlockStackUpdateSystem.inst.SuppressColliderUpdates && !LoadSave.Loading && !b.isPreviewBuilding)
		{
			ApplyBlockLayout(DoesConnect(World.inst.GetCellDataClamped(x, z + 1), builtOnly: true), DoesConnect(World.inst.GetCellDataClamped(x, z - 1), builtOnly: true), DoesConnect(World.inst.GetCellDataClamped(x + 1, z), builtOnly: true), DoesConnect(World.inst.GetCellDataClamped(x - 1, z), builtOnly: true), DoesConnect(World.inst.GetCellDataClamped(x + 1, z + 1), builtOnly: true), DoesConnect(World.inst.GetCellDataClamped(x - 1, z + 1), builtOnly: true), DoesConnect(World.inst.GetCellDataClamped(x + 1, z - 1), builtOnly: true), DoesConnect(World.inst.GetCellDataClamped(x - 1, z - 1), builtOnly: true), top, flag, applyVisual: false);
			CaptureWaterObstructionPoints();
		}
		else
		{
			waterObstructionWorldPointCount = 0;
		}
		ApplyBlockLayout(DoesConnect(World.inst.GetCellDataClamped(x, z + 1)), DoesConnect(World.inst.GetCellDataClamped(x, z - 1)), DoesConnect(World.inst.GetCellDataClamped(x + 1, z)), DoesConnect(World.inst.GetCellDataClamped(x - 1, z)), DoesConnect(World.inst.GetCellDataClamped(x + 1, z + 1)), DoesConnect(World.inst.GetCellDataClamped(x - 1, z + 1)), DoesConnect(World.inst.GetCellDataClamped(x + 1, z - 1)), DoesConnect(World.inst.GetCellDataClamped(x - 1, z - 1)), top, flag, applyVisual: true);
		ClearDoors();
		int num4 = 0;
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			num4 += cell.OccupyingStructure[i].StackHeight;
			if (cell.OccupyingStructure[i] == b)
			{
				break;
			}
		}
		VisibleDoors(b.IsBuilt() && b.IsVisibleForFog());
		b.UpdateShaderHeight();
		b.SetScaffoldOverride(b != cell.TopStructure);
		Building building2 = cell.StructureFind(World.pierHash);
		if (building2 != null)
		{
			building2.GetComponent<Building>().SetScaffoldOverride(cell.OccupyingStructure.Count != 0);
		}
	}

	private void CaptureWaterObstructionPoints()
	{
		Transform[] waterObstructionActive = WaterObstructionActive;
		int num = waterObstructionActive?.Length ?? 0;
		if (waterObstructionWorldPoints == null || waterObstructionWorldPoints.Length < num)
		{
			waterObstructionWorldPoints = new Vector3[num];
		}
		for (int i = 0; i < num; i++)
		{
			waterObstructionWorldPoints[i] = waterObstructionActive[i].position;
		}
		waterObstructionWorldPointCount = num;
	}

	private void SetMeshIfVisual(Transform prefab, Transform colliderPrefab)
	{
		if (applyVisualLayout)
		{
			Util.SetMesh(transform, prefab, colliderPrefab);
		}
	}

	private void ApplyBlockLayout(bool north, bool south, bool east, bool west, bool northEast, bool northWest, bool southEast, bool southWest, bool top, bool bottom, bool applyVisual)
	{
		applyVisualLayout = applyVisual;
		ResetRotation();
		if (north)
		{
			northEast = (northWest = false);
		}
		if (south)
		{
			southEast = (southWest = false);
		}
		if (east)
		{
			northEast = (southEast = false);
		}
		if (west)
		{
			southWest = (northWest = false);
		}
		bool num = northEast | northWest | southEast | southWest;
		int num2 = 0;
		if (north)
		{
			num2++;
		}
		if (south)
		{
			num2++;
		}
		if (east)
		{
			num2++;
		}
		if (west)
		{
			num2++;
		}
		int num3 = 0;
		if (northEast)
		{
			num3++;
		}
		if (northWest)
		{
			num3++;
		}
		if (southEast)
		{
			num3++;
		}
		if (southWest)
		{
			num3++;
		}
		if (!num)
		{
			switch (num2)
			{
			case 0:
				if (top)
				{
					if (GameUI.inst.CurrPlacementMode.buildings.Count > 0 && GameUI.inst.CurrPlacementMode.buildings[0].gameObject == gameObject)
					{
						SetMeshIfVisual(StraightStraightTop, StraightStraightTopCollider);
					}
					else
					{
						SetMeshIfVisual(StraightSingleTop, StraightSingleTopCollider);
					}
				}
				else if (bottom)
				{
					SetMeshIfVisual(StraightSingleBottom, StraightSingleBottomCollider);
				}
				else
				{
					SetMeshIfVisual(StraightSingle, StraightSingleCollider);
				}
				if (applyVisualLayout)
				{
					b.UpdateMaterialSelection();
				}
				WaterObstructionActive = WaterObstructionLayoutsStraightAlone;
				break;
			case 1:
				if (top)
				{
					SetMeshIfVisual(StraightDeadEndTop, StraightDeadEndTopCollider);
				}
				else if (bottom)
				{
					SetMeshIfVisual(StraightDeadEndBottom, StraightDeadEndBottomCollider);
				}
				else
				{
					SetMeshIfVisual(StraightDeadEnd, StraightDeadEndCollider);
				}
				if (applyVisualLayout)
				{
					b.UpdateMaterialSelection();
				}
				if (north)
				{
					RotatePiece(90f);
				}
				if (east)
				{
					RotatePiece(180f);
				}
				if (south)
				{
					RotatePiece(270f);
				}
				WaterObstructionActive = WaterObstructionLayoutsStraightDeadEnd;
				break;
			case 2:
				if ((north & south) || (east & west))
				{
					if (top)
					{
						SetMeshIfVisual(StraightStraightTop, StraightStraightTopCollider);
					}
					else if (bottom)
					{
						SetMeshIfVisual(StraightStraightBottom, StraightStraightBottomCollider);
					}
					else
					{
						SetMeshIfVisual(StraightStraight, StraightStraightCollider);
					}
					if (applyVisualLayout)
					{
						b.UpdateMaterialSelection();
					}
					if (north & south)
					{
						RotatePiece(90f);
					}
					WaterObstructionActive = WaterObstructionLayoutsStraightStraight;
					break;
				}
				if (top)
				{
					SetMeshIfVisual(StraightCornerTop, StraightCornerTopCollider);
				}
				else if (bottom)
				{
					SetMeshIfVisual(StraightCornerBottom, StraightCornerBottomCollider);
				}
				else
				{
					SetMeshIfVisual(StraightCorner, StraightCornerCollider);
				}
				if (applyVisualLayout)
				{
					b.UpdateMaterialSelection();
				}
				if (west & north)
				{
					RotatePiece(90f);
				}
				if (north & east)
				{
					RotatePiece(180f);
				}
				if (east & south)
				{
					RotatePiece(270f);
				}
				WaterObstructionActive = WaterObstructionLayoutsStraightCorner;
				break;
			case 3:
				if (top)
				{
					SetMeshIfVisual(Straight3WayTop, Straight3WayTopCollider);
				}
				else if (bottom)
				{
					SetMeshIfVisual(Straight3WayBottom, Straight3WayBottomCollider);
				}
				else
				{
					SetMeshIfVisual(Straight3Way, Straight3WayCollider);
				}
				if (applyVisualLayout)
				{
					b.UpdateMaterialSelection();
				}
				if (!east)
				{
					RotatePiece(90f);
				}
				if (!south)
				{
					RotatePiece(180f);
				}
				if (!west)
				{
					RotatePiece(270f);
				}
				WaterObstructionActive = WaterObstructionLayoutsStraight3Way;
				break;
			case 4:
				if (top)
				{
					SetMeshIfVisual(Straight4WayTop, Straight4WayTopCollider);
				}
				else if (bottom)
				{
					SetMeshIfVisual(Straight4WayBottom, Straight4WayBottomCollider);
				}
				else
				{
					SetMeshIfVisual(Straight4Way, Straight4WayCollider);
				}
				if (applyVisualLayout)
				{
					b.UpdateMaterialSelection();
				}
				WaterObstructionActive = WaterObstructionLayoutsStraight4Way;
				break;
			}
			return;
		}
		if (num3 == 1)
		{
			switch (num2)
			{
			case 1:
			{
				bool flag = false;
				if (north && southEast)
				{
					flag = true;
				}
				if (east)
				{
					RotatePiece(90f);
					if (southWest)
					{
						flag = true;
					}
				}
				if (south)
				{
					RotatePiece(180f);
					if (northWest)
					{
						flag = true;
					}
				}
				if (west)
				{
					RotatePiece(270f);
					if (northEast)
					{
						flag = true;
					}
				}
				if (flag)
				{
					RotatePiece(180f);
					if (top)
					{
						SetMeshIfVisual(DiagonalBendLeftTop, DiagonalBendLeftTopCollider);
					}
					else if (bottom)
					{
						SetMeshIfVisual(DiagonalBendLeftBottom, DiagonalBendLeftBottomCollider);
					}
					else
					{
						SetMeshIfVisual(DiagonalBendLeft, DiagonalBendLeftCollider);
					}
					if (applyVisualLayout)
					{
						b.UpdateMaterialSelection();
					}
					WaterObstructionActive = WaterObstructionLayoutsDiagonalBendLeft;
				}
				else
				{
					if (top)
					{
						SetMeshIfVisual(DiagonalBendRightTop, DiagonalBendRightTopCollider);
					}
					else if (bottom)
					{
						SetMeshIfVisual(DiagonalBendRightBottom, DiagonalBendRightBottomCollider);
					}
					else
					{
						SetMeshIfVisual(DiagonalBendRight, DiagonalBendRightCollider);
					}
					if (applyVisualLayout)
					{
						b.UpdateMaterialSelection();
					}
					WaterObstructionActive = WaterObstructionLayoutsDiagonalBendRight;
				}
				break;
			}
			case 2:
				if (top)
				{
					SetMeshIfVisual(Diagonal1Straight2Top, Diagonal1Straight2TopCollider);
				}
				else if (bottom)
				{
					SetMeshIfVisual(Diagonal1Straight2Bottom, Diagonal1Straight2BottomCollider);
				}
				else
				{
					SetMeshIfVisual(Diagonal1Straight2, Diagonal1Straight2Collider);
				}
				if (southEast)
				{
					RotatePiece(90f);
				}
				if (southWest)
				{
					RotatePiece(180f);
				}
				if (northWest)
				{
					RotatePiece(270f);
				}
				if (applyVisualLayout)
				{
					b.UpdateMaterialSelection();
				}
				WaterObstructionActive = WaterObstructionLayoutsDiagonal1Straight2;
				break;
			default:
				if (top)
				{
					SetMeshIfVisual(DiagonalDeadEndTop, DiagonalDeadEndTopCollider);
				}
				else if (bottom)
				{
					SetMeshIfVisual(DiagonalDeadEndBottom, DiagonalDeadEndBottomCollider);
				}
				else
				{
					SetMeshIfVisual(DiagonalDeadEnd, DiagonalDeadEndCollider);
				}
				if (northEast)
				{
					RotatePiece(90f);
				}
				else if (southEast)
				{
					RotatePiece(180f);
				}
				else if (southWest)
				{
					RotatePiece(270f);
				}
				if (applyVisualLayout)
				{
					b.UpdateMaterialSelection();
				}
				WaterObstructionActive = WaterObstructionLayoutsDiagonalDeadEnd;
				break;
			}
		}
		if (num3 == 2)
		{
			if ((northEast & southWest) || (northWest & southEast))
			{
				if (top)
				{
					SetMeshIfVisual(DiagonalStraightTop, DiagonalStraightTopCollider);
				}
				else if (bottom)
				{
					SetMeshIfVisual(DiagonalStraightBottom, DiagonalStraightBottomCollider);
				}
				else
				{
					SetMeshIfVisual(DiagonalStraight, DiagonalStraightCollider);
				}
				if (northEast & southWest)
				{
					RotatePiece(90f);
				}
				if (applyVisualLayout)
				{
					b.UpdateMaterialSelection();
				}
				WaterObstructionActive = WaterObstructionLayoutsDiagonalStraight;
			}
			else if (num2 == 1)
			{
				if (top)
				{
					SetMeshIfVisual(Diagonal2Straight1Top, Diagonal2Straight1TopCollider);
				}
				else if (bottom)
				{
					SetMeshIfVisual(Diagonal2Straight1Bottom, Diagonal2Straight1BottomCollider);
				}
				else
				{
					SetMeshIfVisual(Diagonal2Straight1, Diagonal2Straight1Collider);
				}
				if (east)
				{
					RotatePiece(90f);
				}
				else if (south)
				{
					RotatePiece(180f);
				}
				else if (west)
				{
					RotatePiece(270f);
				}
				if (applyVisualLayout)
				{
					b.UpdateMaterialSelection();
				}
				WaterObstructionActive = WaterObstructionLayoutsDiagonal2Straight1;
			}
			else
			{
				if (top)
				{
					SetMeshIfVisual(DiagonalCornerTop, DiagonalCornerTopCollider);
				}
				else if (bottom)
				{
					SetMeshIfVisual(DiagonalCornerBottom, DiagonalCornerBottomCollider);
				}
				else
				{
					SetMeshIfVisual(DiagonalCorner, DiagonalCornerCollider);
				}
				if (southWest & northWest)
				{
					RotatePiece(90f);
				}
				else if (northWest & northEast)
				{
					RotatePiece(180f);
				}
				else if (northEast & southEast)
				{
					RotatePiece(270f);
				}
				if (applyVisualLayout)
				{
					b.UpdateMaterialSelection();
				}
				WaterObstructionActive = WaterObstructionLayoutsDiagonalCorner;
			}
		}
		if (num3 == 3)
		{
			if (top)
			{
				SetMeshIfVisual(Diagonal3WayTop, Diagonal3WayTopCollider);
			}
			else if (bottom)
			{
				SetMeshIfVisual(Diagonal3WayBottom, Diagonal3WayBottomCollider);
			}
			else
			{
				SetMeshIfVisual(Diagonal3Way, Diagonal3WayCollider);
			}
			if (!northEast)
			{
				RotatePiece(90f);
			}
			else if (!southEast)
			{
				RotatePiece(180f);
			}
			else if (!southWest)
			{
				RotatePiece(270f);
			}
			if (applyVisualLayout)
			{
				b.UpdateMaterialSelection();
			}
			WaterObstructionActive = WaterObstructionLayoutsDiagonal3Way;
		}
		if (num3 == 4)
		{
			if (top)
			{
				SetMeshIfVisual(Diagonal4WayTop, Diagonal4WayTopCollider);
			}
			else if (bottom)
			{
				SetMeshIfVisual(Diagonal4WayBottom, Diagonal4WayBottomCollider);
			}
			else
			{
				SetMeshIfVisual(Diagonal4Way, Diagonal4WayCollider);
			}
			if (applyVisualLayout)
			{
				b.UpdateMaterialSelection();
			}
			WaterObstructionActive = WaterObstructionLayoutsDiagonal4Way;
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		Vector3 position = transform.position;
		int num = (int)position.x;
		int num2 = (int)position.z;
		World.inst.ForEachTile(num - 5, num2 - 5, num + 5, num2 + 5, (int x, int z, Cell cell) =>
		{
			cell.Danger += ((!undo) ? 1 : (-1));
		});
		if (!undo && !LoadSave.Loading)
		{
			MarkBlockStackAndNeighborsDirty(b.GetCell());
		}
	}

	public void UpdateStackPostLoad()
	{
		Cell cell = b.GetCell();
		UpdateBlockStack(cell);
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			Spillover component = cell.OccupyingStructure[i].GetComponent<Spillover>();
			if (component != null)
			{
				component.UpdateVisual(ignoreValidation: true);
				if (component.b.IsBuilt())
				{
					component.UpdateMovables();
				}
			}
		}
		RecalcObstruction();
	}

	protected virtual void OnBuilt()
	{
		VisibleDoors(b.IsBuilt() && b.IsVisibleForFog());
		if (!LoadSave.Loading)
		{
			MarkBlockStackAndNeighborsDirty(b.GetCell());
		}
		RecalcObstruction();
	}

	public void RecalcObstruction()
	{
		BlockStackUpdateSystem.inst.MarkWaterDirty(b.cachedCell);
	}

	private new void OnDestroy()
	{
		base.OnDestroy();
		b.visibilityChanged -= B_visibilityChanged;
		ClearDoors();
	}

	private new void OnDisable()
	{
		base.OnDisable();
		if (!GameState.IsQuitting && b != null && b.destroyedWhileInPlay && !b.isPreviewBuilding)
		{
			RevertTerrainIfLastDamInCell();
			MarkBlockStackAndNeighborsDirty(b.GetCell());
			if (b.IsBuilt())
			{
				OnUnBuilt();
			}
		}
	}

	protected virtual void OnUnBuilt()
	{
		RecalcObstruction();
	}

	public static void UpdateBlockStack(Cell c)
	{
		if (c == null)
		{
			return;
		}
		BlockBuilding blockBuilding = null;
		for (int i = 0; i < c.OccupyingStructure.Count; i++)
		{
			if (!(c.OccupyingStructure[i] == null))
			{
				BlockBuilding component = c.OccupyingStructure[i].GetComponent<BlockBuilding>();
				if (component != null)
				{
					component.UpdateBlock();
					blockBuilding = component;
				}
			}
		}
		if (!LoadSave.Loading && blockBuilding != null)
		{
			blockBuilding.RecalcObstruction();
		}
		Building building = c.StructureFind<Spillover>();
		if (building != null)
		{
			building.GetComponent<Spillover>().updateNeeded = true;
		}
	}

	public static void MarkBlockStackDirty(Cell c)
	{
		BlockStackUpdateSystem.inst.MarkBlockStackDirty(c);
	}

	public static void MarkBlockStackAndNeighborsDirty(Cell c)
	{
		BlockStackUpdateSystem.inst.MarkBlockStackAndNeighborsDirty(c);
	}

	public void SetTerrainRestorationData(int[] vertexIndices, float[] originalHeights)
	{
		terrainVertexIndices = vertexIndices;
		terrainOriginalHeights = originalHeights;
	}

	private static bool ShouldRevertVertex(int vertIdx, Cell excludeCell)
	{
		int x = excludeCell.x;
		int z = excludeCell.z;
		for (int i = -1; i <= 1; i++)
		{
			for (int j = -1; j <= 1; j++)
			{
				if (j == 0 && i == 0)
				{
					continue;
				}
				Cell cellDataClamped = World.inst.GetCellDataClamped(x + j, z + i);
				if (cellDataClamped == null)
				{
					continue;
				}
				foreach (Building item in cellDataClamped.OccupyingStructure)
				{
					if (item.uniqueNameHash != World.damHash)
					{
						continue;
					}
					BlockBuilding component = item.GetComponent<BlockBuilding>();
					if (!(component != null) || component.terrainVertexIndices == null)
					{
						continue;
					}
					for (int k = 0; k < component.terrainVertexIndices.Length; k++)
					{
						if (component.terrainVertexIndices[k] == vertIdx)
						{
							return false;
						}
					}
				}
			}
		}
		return true;
	}

	public void RevertTerrainIfLastDamInCell()
	{
		if (b == null || b.uniqueNameHash != World.damHash || terrainVertexIndices == null || terrainVertexIndices.Length == 0)
		{
			return;
		}
		Cell cell = b.GetCell();
		if (cell == null)
		{
			return;
		}
		int num = 0;
		foreach (Building item in cell.OccupyingStructure)
		{
			if (item.uniqueNameHash == World.damHash && item != b)
			{
				num++;
			}
		}
		if (num > 0)
		{
			return;
		}
		bool flag = false;
		int num2 = int.MaxValue;
		int num3 = int.MaxValue;
		int num4 = int.MinValue;
		int num5 = int.MinValue;
		for (int i = 0; i < terrainVertexIndices.Length; i++)
		{
			int num6 = terrainVertexIndices[i];
			if (ShouldRevertVertex(num6, cell))
			{
				TerrainGen.inst.SetVert(num6, terrainOriginalHeights[i], bakeDown: true);
				flag = true;
				int num7 = num6 % World.MeshWidth;
				int num8 = num6 / World.MeshWidth;
				if (num7 < num2)
				{
					num2 = num7;
				}
				if (num7 > num4)
				{
					num4 = num7;
				}
				if (num8 < num3)
				{
					num3 = num8;
				}
				if (num8 > num5)
				{
					num5 = num8;
				}
			}
		}
		if (flag)
		{
			TerrainGen.inst.UpdateTerrainDeformations();
			if (!LoadSave.Loading)
			{
				TerrainRockReclassifier.ReclassifyVertRect(num2, num3, num4, num5, bakeDeformations: false);
			}
		}
	}

	private void OnDemolished()
	{
		RevertTerrainIfLastDamInCell();
	}
}
