using System;
using System.Collections.Generic;
using UnityEngine;

public class Spillover : MonoBehaviour, IWorkerUIDisplay
{
	[Serializable]
	public class SpilloverSaveData : SaveClass<Spillover, SpilloverSaveData>
	{
		private float spillwayOpenPercentDesired;

		private float spillwayOpenPercentCurrent;

		private int meshIndexForDoor;

		public override SpilloverSaveData Pack(Spillover j)
		{
			spillwayOpenPercentDesired = j.spillwayOpenPercentDesired;
			spillwayOpenPercentCurrent = j.spillwayOpenPercentCurrent;
			meshIndexForDoor = j.meshIndexForDoor;
			return this;
		}

		public override Spillover Unpack(Spillover j)
		{
			j.spillwayOpenPercentDesired = spillwayOpenPercentDesired;
			j.spillwayOpenPercentCurrent = spillwayOpenPercentCurrent;
			j.meshIndexForDoor = meshIndexForDoor;
			return j;
		}
	}

	public Mesh straightBottomMesh;

	public Mesh straightMiddleMesh;

	public Mesh straightTopMesh;

	public Mesh diagonalBottomMesh;

	public Mesh diagonalMiddleMesh;

	public Mesh diagonalTopMesh;

	public GameObject prefab;

	public Building b;

	public float doorMoveSpeed = 0.1f;

	[Range(0f, 1f)]
	public float spillwayOpenPercentDesired = 1f;

	[HideInInspector]
	public float spillwayOpenPercentCurrent = 1f;

	public Mesh spillwayLogMesh;

	public Material spillwayLogMaterial;

	public Matrix4x4[] spillwayLogMatrices = new Matrix4x4[1];

	[HideInInspector]
	public int meshIndexForDoor;

	private bool spillwayDoorInitialized;

	[HideInInspector]
	public float obstructionHeight;

	[HideInInspector]
	public BlockBuilding topBlock;

	[HideInInspector]
	public bool diagonal;

	[HideInInspector]
	public Vector3 forward;

	private Cell[] neighbors = new Cell[8];

	private int logCount;

	private Cell lastCell;

	public GameObject[] spillOverDamBlocks;

	public bool updateNeeded;

	public float SetSpilloverHeight
	{
		get
		{
			return spillwayOpenPercentDesired;
		}
		set
		{
			spillwayOpenPercentDesired = Mathf.Clamp01(value);
			DamProjectManager.inst.MarkSpillwayManuallyAdjusted(b.GetCell().index);
		}
	}

	private void Start()
	{
		b.PlacementValidaton = PlacementValidaton;
	}

	private void PlacementValidaton(ref PlacementValidationResult result)
	{
		PlacementValidationResult res = PlacementValidationResult.Valid;
		b.ForEachTileInBounds((int x, int z, Cell cell2) =>
		{
			if (cell2.Type == TerrainType.Water)
			{
				res = PlacementValidationResult.CannotBuildOnWater;
			}
		});
		Cell cell = b.GetCell();
		if (cell.OccupyingStructure.Count > 0)
		{
			bool flag = cell.StructureCompareUniqueNameAll(World.damHash);
			bool flag2 = cell.StructureCompareUniqueNameAll(World.spilloverHash);
			if (cell.TopStructureIs(World.spilloverHash))
			{
				res = PlacementValidationResult.SpilloverAlreadyASpillover;
			}
			else if (flag || (flag2 && LoadSave.Loading))
			{
				World.inst.GetNeighborCellsExtended(cell, ref neighbors);
				bool flag3 = neighbors[0] != null && neighbors[0].StructureCompareUniqueNameAll(World.damHash);
				bool flag4 = neighbors[1] != null && neighbors[1].StructureCompareUniqueNameAll(World.damHash);
				bool flag5 = neighbors[2] != null && neighbors[2].StructureCompareUniqueNameAll(World.damHash);
				bool flag6 = neighbors[3] != null && neighbors[3].StructureCompareUniqueNameAll(World.damHash);
				bool flag7 = neighbors[4] != null && neighbors[4].StructureCompareUniqueNameAll(World.damHash);
				bool flag8 = neighbors[5] != null && neighbors[5].StructureCompareUniqueNameAll(World.damHash);
				bool flag9 = neighbors[6] != null && neighbors[6].StructureCompareUniqueNameAll(World.damHash);
				bool flag10 = neighbors[7] != null && neighbors[7].StructureCompareUniqueNameAll(World.damHash);
				if ((flag3 & flag7) && !flag5 && !flag9)
				{
					res = PlacementValidationResult.Valid;
					forward = (neighbors[2].Center2D - neighbors[6].Center2D).normalized;
					diagonal = false;
				}
				else if ((!flag3 && !flag7) & flag5 & flag9)
				{
					res = PlacementValidationResult.Valid;
					forward = (neighbors[0].Center2D - neighbors[4].Center2D).normalized;
					diagonal = false;
				}
				else if ((flag4 & flag8) && !flag6 && !flag10 && !flag3 && !flag5 && !flag7 && !flag9)
				{
					res = PlacementValidationResult.Valid;
					forward = (neighbors[3].Center2D - neighbors[7].Center2D).normalized;
					diagonal = true;
				}
				else if (((!flag4 && !flag8) & flag6 & flag10) && !flag3 && !flag5 && !flag7 && !flag9)
				{
					res = PlacementValidationResult.Valid;
					forward = (neighbors[1].Center2D - neighbors[5].Center2D).normalized;
					diagonal = true;
				}
				else
				{
					res = PlacementValidationResult.SpilloverMustBeBetweenTwoDamsOnly;
				}
			}
			else
			{
				res = PlacementValidationResult.SpilloverMustBeBetweenTwoDamsOnly;
			}
		}
		else
		{
			res = PlacementValidationResult.SpilloverMustBeBetweenTwoDamsOnly;
		}
		if (res == PlacementValidationResult.Valid && RiverTap.AnyTapMountedOnCell(cell))
		{
			res = PlacementValidationResult.SpilloverDamHasTap;
		}
		if (DamProjectManager.inst.IsCellPartOfProject(cell, out var _))
		{
			res = PlacementValidationResult.CannotBuildOnExistingDamPlanningProject;
		}
		if (forward != Vector3.zero)
		{
			transform.GetChild(0).transform.rotation = Quaternion.LookRotation(forward, Vector3.up);
		}
		result = res;
	}

	public void JustCalcOrientation()
	{
		Cell cell = b.GetCell();
		World.inst.GetNeighborCellsExtended(cell, ref neighbors);
		bool flag = neighbors[0] != null && neighbors[0].StructureCompareUniqueNameAll(World.damHash);
		bool flag2 = neighbors[1] != null && neighbors[1].StructureCompareUniqueNameAll(World.damHash);
		bool flag3 = neighbors[2] != null && neighbors[2].StructureCompareUniqueNameAll(World.damHash);
		bool flag4 = neighbors[3] != null && neighbors[3].StructureCompareUniqueNameAll(World.damHash);
		bool flag5 = neighbors[4] != null && neighbors[4].StructureCompareUniqueNameAll(World.damHash);
		bool flag6 = neighbors[5] != null && neighbors[5].StructureCompareUniqueNameAll(World.damHash);
		bool flag7 = neighbors[6] != null && neighbors[6].StructureCompareUniqueNameAll(World.damHash);
		bool flag8 = neighbors[7] != null && neighbors[7].StructureCompareUniqueNameAll(World.damHash);
		if ((flag & flag5) && !flag3 && !flag7)
		{
			forward = (neighbors[2].Center2D - neighbors[6].Center2D).normalized;
			diagonal = false;
		}
		else if ((!flag && !flag5) & flag3 & flag7)
		{
			forward = (neighbors[0].Center2D - neighbors[4].Center2D).normalized;
			diagonal = false;
		}
		else if ((flag2 & flag6) && !flag4 && !flag8 && !flag && !flag3 && !flag5 && !flag7)
		{
			forward = (neighbors[3].Center2D - neighbors[7].Center2D).normalized;
			diagonal = true;
		}
		else if (((!flag2 && !flag6) & flag4 & flag8) && !flag && !flag3 && !flag5 && !flag7)
		{
			forward = (neighbors[1].Center2D - neighbors[5].Center2D).normalized;
			diagonal = true;
		}
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		DamPlanningProject project;
		return !DamProjectManager.inst.IsCellPartOfProject(b.cachedCell, out project);
	}

	public void LateUpdate()
	{
		if (!b.IsBuilt() || updateNeeded)
		{
			UpdateVisual(updateNeeded);
			updateNeeded = false;
		}
		if (b.IsBuilt())
		{
			UpdateMovables();
		}
		Graphics.DrawMeshInstanced(spillwayLogMesh, 0, spillwayLogMaterial, spillwayLogMatrices, logCount);
	}

	public void UpdateMovables()
	{
		if (topBlock.WaterObstructionActive.Length != 0 && (!spillwayDoorInitialized || spillwayOpenPercentCurrent != spillwayOpenPercentDesired))
		{
			spillwayDoorInitialized = true;
			spillwayOpenPercentCurrent = Mathf.MoveTowards(spillwayOpenPercentCurrent, spillwayOpenPercentDesired, Time.deltaTime * doorMoveSpeed);
			UpdateSpillwayDoor();
			TerrainGen.inst.RecalcWaterObstructionForArea(b.cachedCell.x, b.cachedCell.z, 1, 1);
		}
	}

	public void UpdateSpillwayDoor(float visualOverride = float.PositiveInfinity)
	{
		float num;
		if (topBlock != null && topBlock.WaterObstructionActive != null && topBlock.WaterObstructionActive.Length != 0)
		{
			num = topBlock.WaterObstructionActive[0].transform.position.y;
		}
		else
		{
			if (!(topBlock != null))
			{
				return;
			}
			num = topBlock.transform.position.y + 0.5f;
		}
		float num2 = Mathf.Lerp(TerrainGen.inst.heightCache[meshIndexForDoor], num, spillwayOpenPercentCurrent);
		obstructionHeight = num2 - TerrainGen.inst.heightCache[meshIndexForDoor];
		float num3 = TerrainGen.inst.heightCache[meshIndexForDoor];
		float num4 = num2;
		if (visualOverride != float.PositiveInfinity)
		{
			num4 = visualOverride;
		}
		float y = spillwayLogMesh.bounds.size.y;
		logCount = Mathf.CeilToInt((num4 - num3) / y);
		float num5 = y / 2f;
		Vector3 center2D = b.GetCell().Center2D;
		JustCalcOrientation();
		if (spillwayLogMatrices.Length < logCount)
		{
			spillwayLogMatrices = new Matrix4x4[logCount];
		}
		Quaternion q = Quaternion.AngleAxis(90f, Vector3.up);
		if (forward != Vector3.zero)
		{
			q = Quaternion.LookRotation(forward, Vector3.up) * Quaternion.AngleAxis(90f, Vector3.up);
		}
		for (int i = 0; i < logCount; i++)
		{
			spillwayLogMatrices[i] = Matrix4x4.TRS(new Vector3(center2D.x, num3 + y * (float)i + num5, center2D.z), q, Vector3.one);
		}
	}

	public void OnBuildingPlacement(bool undo)
	{
		if (!LoadSave.Loading)
		{
			BlockBuilding.MarkBlockStackDirty(b.cachedCell);
		}
	}

	public void OnShutdown()
	{
		if (lastCell != null)
		{
			UnApplySpillover(lastCell);
		}
		if (b.IsBuilt() && !GameState.IsQuitting && !LoadSave.Loading)
		{
			TerrainGen.inst.RecalcWaterObstructionForArea(b.cachedCell.x, b.cachedCell.z, 1, 1);
		}
	}

	public void UpdateVisual(bool ignoreValidation = false)
	{
		Cell cell = b.GetCell();
		if ((cell != lastCell) | ignoreValidation)
		{
			PlacementValidationResult result = PlacementValidationResult.Valid;
			if (ignoreValidation)
			{
				JustCalcOrientation();
			}
			else
			{
				PlacementValidaton(ref result);
			}
			if (lastCell != null)
			{
				UnApplySpillover(lastCell);
			}
			if ((result == PlacementValidationResult.Valid) | ignoreValidation)
			{
				ApplySpillover(cell);
				lastCell = cell;
			}
		}
	}

	public void ApplySpillover(Cell cell)
	{
		List<GameObject> list = new List<GameObject>();
		Mesh mesh = (diagonal ? diagonalTopMesh : straightTopMesh);
		Mesh mesh2 = (diagonal ? diagonalMiddleMesh : straightMiddleMesh);
		Mesh mesh3 = (diagonal ? diagonalBottomMesh : straightBottomMesh);
		Building building = null;
		for (int num = cell.OccupyingStructure.Count - 1; num >= 0; num--)
		{
			if (cell.OccupyingStructure[num].uniqueNameHash == World.damHash)
			{
				building = cell.OccupyingStructure[num];
				break;
			}
		}
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			if (cell.OccupyingStructure[i].uniqueNameHash == World.damHash)
			{
				cell.OccupyingStructure[i].transform.GetChild(0).GetChild(0).GetComponent<MeshRenderer>()
					.enabled = false;
				GameObject gameObject = UnityEngine.Object.Instantiate(prefab, cell.OccupyingStructure[i].transform.position + new Vector3(0.5f, 0f, 0.5f), cell.OccupyingStructure[i].transform.GetChild(0).transform.rotation, transform.GetChild(0));
				gameObject.gameObject.SetActive(value: true);
				if (cell.OccupyingStructure[i] == building)
				{
					gameObject.GetComponent<MeshFilter>().mesh = mesh;
				}
				else if (i == 0)
				{
					gameObject.GetComponent<MeshFilter>().mesh = mesh3;
				}
				else
				{
					gameObject.GetComponent<MeshFilter>().mesh = mesh2;
				}
				gameObject.GetComponent<MeshRenderer>().sharedMaterial = World.inst.romeUnimaterial;
				list.Add(gameObject);
			}
		}
		topBlock = null;
		float num2 = float.MinValue;
		for (int j = 0; j < cell.OccupyingStructure.Count; j++)
		{
			if (cell.OccupyingStructure[j].uniqueNameHash == World.damHash)
			{
				BlockBuilding component = cell.OccupyingStructure[j].GetComponent<BlockBuilding>();
				if (component != null && component.transform.position.y > num2)
				{
					num2 = component.transform.position.y;
					topBlock = component;
				}
			}
		}
		spillOverDamBlocks = list.ToArray();
		meshIndexForDoor = DynamicWater.MapIndexWorldToMesh(cell.index, World.inst.GridWidth);
	}

	public void SetInitialSpillwayOpenPercent()
	{
		if (!LoadSave.Loading)
		{
			spillwayOpenPercentCurrent = ((float)spillOverDamBlocks.Length - 2f) / (float)spillOverDamBlocks.Length;
			spillwayOpenPercentDesired = Mathf.Clamp01(spillwayOpenPercentCurrent);
			UpdateSpillwayDoor();
		}
	}

	public void UnApplySpillover(Cell cell)
	{
		for (int i = 0; i < spillOverDamBlocks.Length; i++)
		{
			UnityEngine.Object.Destroy(spillOverDamBlocks[i]);
		}
		lastCell = null;
		if (LoadSave.Loading)
		{
			return;
		}
		for (int j = 0; j < cell.OccupyingStructure.Count; j++)
		{
			if (cell.OccupyingStructure[j].uniqueNameHash == World.damHash)
			{
				cell.OccupyingStructure[j].transform.GetChild(0).GetChild(0).GetComponent<MeshRenderer>()
					.enabled = true;
			}
		}
	}

	public float[] GetTickPercentages()
	{
		List<float> list = new List<float>();
		for (int i = 1; i < spillOverDamBlocks.Length; i++)
		{
			float num = TerrainGen.inst.heightCache[meshIndexForDoor];
			float y = topBlock.WaterObstructionActive[0].transform.position.y;
			list.Add(Mathf.Clamp01((spillOverDamBlocks[i].transform.position.y - num) / (y - num)));
		}
		return list.ToArray();
	}
}
