using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using UnityEngine;

public class DamPlanningProject : MonoBehaviour, ISelectableBuilding
{
	[Serializable]
	public class DamPlanningProjectSaveData : SaveClass<DamPlanningProject, DamPlanningProjectSaveData>
	{
		public List<BuildingDescriptionDamPlanning> damsToRemove = new List<BuildingDescriptionDamPlanning>();

		public List<BuildingDescriptionDamPlanning> damsToAdd = new List<BuildingDescriptionDamPlanning>();

		private Dictionary<int, SpillwayResetData> spillwayResetData = new Dictionary<int, SpillwayResetData>();

		private Dictionary<int, float> plannedSpillwayHeights = new Dictionary<int, float>();

		[OptionalField(VersionAdded = 2)]
		private HashSet<int> manuallyAdjustedSpillwayCells = new HashSet<int>();

		private int[] cachedWaterObstructionPointsIndex;

		private SerializableVector3[][] cachedWaterObstructionPoints;

		private int[] deferredTerrainVertices;

		private float[] deferredTerrainOriginalHeights;

		private float[] deferredTerrainNewHeights;

		private Dictionary<int, CellTerrainData> cellTerrainDataMap;

		[OnDeserializing]
		internal void OnDeserializingMethod(StreamingContext context)
		{
			manuallyAdjustedSpillwayCells = new HashSet<int>();
		}

		public override DamPlanningProjectSaveData Pack(DamPlanningProject obj)
		{
			damsToRemove = obj.damsToRemove.ToList();
			damsToAdd = obj.damsToAdd.ToList();
			cachedWaterObstructionPointsIndex = obj.cachedWaterObstructionPointsIndex.ToArray();
			cachedWaterObstructionPoints = obj.cachedWaterObstructionPoints.Select((Vector3[] v) => ((IEnumerable<Vector3>)v).Select((Func<Vector3, SerializableVector3>)((Vector3 w) => w)).ToArray()).ToArray();
			spillwayResetData = new Dictionary<int, SpillwayResetData>();
			foreach (KeyValuePair<int, SpillwayResetData> spillwayResetDatum in obj.spillwayResetData)
			{
				spillwayResetData[spillwayResetDatum.Key] = new SpillwayResetData
				{
					current = spillwayResetDatum.Value.current,
					desired = spillwayResetDatum.Value.desired,
					originalWorldHeight = spillwayResetDatum.Value.originalWorldHeight
				};
			}
			plannedSpillwayHeights = new Dictionary<int, float>(obj.plannedSpillwayHeights);
			manuallyAdjustedSpillwayCells = new HashSet<int>(obj.manuallyAdjustedSpillwayCells);
			deferredTerrainVertices = obj.deferredTerrainVertices;
			deferredTerrainOriginalHeights = obj.deferredTerrainOriginalHeights;
			deferredTerrainNewHeights = obj.deferredTerrainNewHeights;
			if (obj.cellTerrainDataMap != null)
			{
				cellTerrainDataMap = new Dictionary<int, CellTerrainData>(obj.cellTerrainDataMap);
			}
			return this;
		}

		public override DamPlanningProject Unpack(DamPlanningProject obj)
		{
			obj.Init(damsToRemove.ToList(), damsToAdd.ToList(), spillwayResetData, plannedSpillwayHeights);
			obj.manuallyAdjustedSpillwayCells = new HashSet<int>(manuallyAdjustedSpillwayCells);
			obj.SetCaches(cachedWaterObstructionPointsIndex, cachedWaterObstructionPoints.Select((SerializableVector3[] v) => ((IEnumerable<SerializableVector3>)v).Select((Func<SerializableVector3, Vector3>)((SerializableVector3 w) => w)).ToArray()).ToArray());
			obj.SetDeferredTerrainData(deferredTerrainVertices, deferredTerrainOriginalHeights, deferredTerrainNewHeights, cellTerrainDataMap);
			return obj;
		}
	}

	private List<BuildingDescriptionDamPlanning> damsToRemove = new List<BuildingDescriptionDamPlanning>();

	internal List<BuildingDescriptionDamPlanning> damsToAdd = new List<BuildingDescriptionDamPlanning>();

	public int[] cachedWaterObstructionPointsIndex;

	public Vector3[][] cachedWaterObstructionPoints;

	public Dictionary<int, SpillwayResetData> spillwayResetData;

	public Dictionary<int, float> plannedSpillwayHeights = new Dictionary<int, float>();

	public HashSet<int> manuallyAdjustedSpillwayCells = new HashSet<int>();

	public int[] deferredTerrainVertices;

	public float[] deferredTerrainOriginalHeights;

	public float[] deferredTerrainNewHeights;

	public Dictionary<int, CellTerrainData> cellTerrainDataMap;

	public bool Done;

	public List<Vector3> scaffoldColumns = new List<Vector3>();

	private List<RenderInstance> scaffoldInsts;

	public bool constructionPaused;

	public string CustomName
	{
		get
		{
			throw new NotImplementedException();
		}
		set
		{
			throw new NotImplementedException();
		}
	}

	public string Description
	{
		get
		{
			throw new NotImplementedException();
		}
	}

	public static DamPlanningProject CreateNewProject()
	{
		return new GameObject("Dam Planning Project").AddComponent<DamPlanningProject>();
	}

	public void Init(List<BuildingDescriptionDamPlanning> damsToRemove, List<BuildingDescriptionDamPlanning> damsToAdd, Dictionary<int, SpillwayResetData> spillwayResetData, Dictionary<int, float> plannedSpillwayHeights = null)
	{
		DamProjectManager.inst.RegisterProject(this);
		this.damsToRemove = damsToRemove;
		this.damsToAdd = damsToAdd;
		this.spillwayResetData = spillwayResetData;
		this.plannedSpillwayHeights = plannedSpillwayHeights ?? new Dictionary<int, float>();
		ReCreateWorksiteScaffold();
	}

	public void SetCaches(int[] cachedWaterObstructionPointsIndex, Vector3[][] cachedWaterObstructionPoints)
	{
		this.cachedWaterObstructionPointsIndex = cachedWaterObstructionPointsIndex;
		this.cachedWaterObstructionPoints = cachedWaterObstructionPoints;
	}

	public void MarkSpillwayManuallyAdjusted(int cellIndex)
	{
		manuallyAdjustedSpillwayCells.Add(cellIndex);
	}

	public void SetDeferredTerrainData(int[] vertices, float[] originalHeights, float[] newHeights, Dictionary<int, CellTerrainData> cellData)
	{
		deferredTerrainVertices = vertices;
		deferredTerrainOriginalHeights = originalHeights;
		deferredTerrainNewHeights = newHeights;
		cellTerrainDataMap = cellData;
	}

	public void ReCreateWorksiteScaffold()
	{
		Vector3 scale = Vector3.one * 1.1f;
		scaffoldColumns.Clear();
		foreach (BuildingDescriptionDamPlanning item in damsToAdd)
		{
			bool flag = false;
			for (int i = 0; i < scaffoldColumns.Count; i++)
			{
				if (Mathf.Approximately(scaffoldColumns[i].x, item.position.x) && Mathf.Approximately(scaffoldColumns[i].z, item.position.z))
				{
					flag = true;
					if (scaffoldColumns[i].y < item.position.y)
					{
						scaffoldColumns[i] = item.position;
					}
					break;
				}
			}
			if (!flag)
			{
				scaffoldColumns.Add(item.position);
			}
		}
		foreach (BuildingDescriptionDamPlanning item2 in damsToRemove)
		{
			bool flag2 = false;
			for (int j = 0; j < scaffoldColumns.Count; j++)
			{
				if (Mathf.Approximately(scaffoldColumns[j].x, item2.position.x) && Mathf.Approximately(scaffoldColumns[j].z, item2.position.z))
				{
					flag2 = true;
					if (scaffoldColumns[j].y < item2.position.y)
					{
						scaffoldColumns[j] = item2.position;
					}
					break;
				}
			}
			if (!flag2)
			{
				scaffoldColumns.Add(item2.position);
			}
		}
		if (spillwayResetData != null && plannedSpillwayHeights != null)
		{
			foreach (KeyValuePair<int, float> plannedSpillwayHeight in plannedSpillwayHeights)
			{
				int key = plannedSpillwayHeight.Key;
				float value = plannedSpillwayHeight.Value;
				if (!spillwayResetData.TryGetValue(key, out var value2) || Mathf.Approximately(value, value2.desired))
				{
					continue;
				}
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(key);
				if (cellDataUnsafe == null)
				{
					continue;
				}
				bool flag3 = false;
				for (int k = 0; k < scaffoldColumns.Count; k++)
				{
					int num = Mathf.FloorToInt(scaffoldColumns[k].x);
					int num2 = Mathf.FloorToInt(scaffoldColumns[k].z);
					if (cellDataUnsafe.x == num && cellDataUnsafe.z == num2)
					{
						flag3 = true;
						break;
					}
				}
				if (!flag3)
				{
					Building topStructure = cellDataUnsafe.TopStructure;
					if (topStructure != null)
					{
						scaffoldColumns.Add(topStructure.Center());
					}
					else
					{
						scaffoldColumns.Add(cellDataUnsafe.Center3D);
					}
				}
			}
		}
		scaffoldInsts = new List<RenderInstance>(10);
		for (int l = 0; l < scaffoldColumns.Count; l++)
		{
			Vector3 vector = scaffoldColumns[l];
			Vector3 pos = scaffoldColumns[l];
			TerrainGen.inst.GetGroundHeight(ref pos);
			for (float num3 = vector.y + 0.2f; num3 > pos.y - 1f; num3 -= 0.45f)
			{
				RenderInstance renderInstance = new RenderInstance(World.inst.scaffoldMesh, World.inst.romeUnimaterial);
				renderInstance.Visible = true;
				renderInstance.UpdateTRS(new Vector3(scaffoldColumns[l].x, num3, scaffoldColumns[l].z), Quaternion.identity, scale);
				scaffoldInsts.Add(renderInstance);
			}
		}
	}

	public void Tick()
	{
		for (int i = 0; i < damsToAdd.Count; i++)
		{
			BuildingDescriptionDamPlanning buildingDescriptionDamPlanning = damsToAdd[i];
			Building building = DamPlannerUI.FindBuilding(buildingDescriptionDamPlanning);
			if (!(building != null) || building.uniqueNameHash != buildingDescriptionDamPlanning.uniqueNameHash || !(building.ConstructionForeman.ConstructionProgress >= 1f))
			{
				return;
			}
		}
		FinishProject();
	}

	public void FinishProject()
	{
		Done = true;
		ApplyDeferredTerrain();
		damsToRemove.Sort((BuildingDescriptionDamPlanning v1, BuildingDescriptionDamPlanning v2) => (int)(v2.position.y * 1000f) - (int)(v1.position.y * 1000f));
		for (int num = 0; num < damsToRemove.Count; num++)
		{
			Building building = DamPlannerUI.FindBuilding(damsToRemove[num]);
			if (building != null)
			{
				World.inst.DemolishBuilding(building);
			}
		}
		for (int num2 = 0; num2 < damsToAdd.Count; num2++)
		{
			DamPlannerUI.FindBuilding(damsToAdd[num2]).ignoreForLayout = false;
		}
		for (int num3 = 0; num3 < scaffoldColumns.Count; num3++)
		{
			Cell cellData = World.inst.GetCellData(scaffoldColumns[num3]);
			Building building2 = cellData.StructureFind<Spillover>();
			if (building2 != null)
			{
				building2.ignoreForLayout = false;
				Spillover component = building2.GetComponent<Spillover>();
				component.UpdateVisual(ignoreValidation: true);
				if (!manuallyAdjustedSpillwayCells.Contains(cellData.index))
				{
					if (plannedSpillwayHeights.TryGetValue(cellData.index, out var value))
					{
						component.spillwayOpenPercentDesired = value;
						component.spillwayOpenPercentCurrent = value;
						component.UpdateSpillwayDoor();
					}
					else
					{
						component.SetInitialSpillwayOpenPercent();
					}
				}
				component.UpdateMovables();
			}
			BlockBuilding.MarkBlockStackAndNeighborsDirty(cellData);
			TerrainGen.inst.RecalcWaterObstructionForArea(cellData.x - 1, cellData.z - 1, 3, 3);
		}
		foreach (KeyValuePair<int, float> plannedSpillwayHeight in plannedSpillwayHeights)
		{
			Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(plannedSpillwayHeight.Key);
			if (cellDataUnsafe == null || manuallyAdjustedSpillwayCells.Contains(plannedSpillwayHeight.Key))
			{
				continue;
			}
			bool flag = false;
			for (int num4 = 0; num4 < scaffoldColumns.Count; num4++)
			{
				Cell cellData2 = World.inst.GetCellData(scaffoldColumns[num4]);
				if (cellData2 != null && cellData2.index == cellDataUnsafe.index)
				{
					flag = true;
					break;
				}
			}
			if (!flag)
			{
				Building building3 = cellDataUnsafe.StructureFind<Spillover>();
				if (building3 != null)
				{
					Spillover component2 = building3.GetComponent<Spillover>();
					component2.UpdateVisual(ignoreValidation: true);
					component2.spillwayOpenPercentDesired = plannedSpillwayHeight.Value;
					component2.spillwayOpenPercentCurrent = plannedSpillwayHeight.Value;
					component2.UpdateSpillwayDoor();
					component2.UpdateMovables();
					TerrainGen.inst.RecalcWaterObstructionForArea(cellDataUnsafe.x - 1, cellDataUnsafe.z - 1, 3, 3);
				}
			}
		}
		BlockStackUpdateSystem.inst.FlushBlockStackUpdates();
		MilestoneManager.inst.TryFirstDamProjectBuiltMilestone();
		MilestoneManager.inst.timeAtDamProjectComplete = Time.time;
	}

	public void OnDestroy()
	{
		Done = true;
		if (scaffoldInsts != null)
		{
			for (int i = 0; i < scaffoldInsts.Count; i++)
			{
				scaffoldInsts[i].Visible = false;
				scaffoldInsts[i] = null;
			}
			scaffoldInsts = null;
		}
	}

	public bool IsCellPartOfProject(Cell cell)
	{
		for (int i = 0; i < scaffoldColumns.Count; i++)
		{
			int num = Mathf.FloorToInt(scaffoldColumns[i].x);
			int num2 = Mathf.FloorToInt(scaffoldColumns[i].z);
			if (cell.x == num && cell.z == num2 && !Done)
			{
				return true;
			}
		}
		return false;
	}

	public void RecalcWaterObstruction()
	{
		for (int i = 0; i < scaffoldColumns.Count; i++)
		{
			Cell cellData = World.inst.GetCellData(scaffoldColumns[i]);
			TerrainGen.inst.RecalcWaterObstructionForArea(cellData.x - 1, cellData.z - 1, 3, 3);
		}
	}

	private void CancelProject()
	{
		Done = true;
		for (int i = 0; i < damsToAdd.Count; i++)
		{
			Building building = DamPlannerUI.FindBuilding(damsToAdd[i]);
			if (building != null)
			{
				World.inst.VanishBuilding(building);
				TerrainGen.inst.RecalcWaterObstructionForArea(building.cachedCell.x - 1, building.cachedCell.z - 1, 3, 3);
			}
		}
		foreach (KeyValuePair<int, SpillwayResetData> spillwayResetDatum in spillwayResetData)
		{
			Building building2 = World.inst.GetCellDataUnsafe(spillwayResetDatum.Key).StructureFind<Spillover>();
			if (building2 != null)
			{
				Spillover component = building2.GetComponent<Spillover>();
				component.spillwayOpenPercentCurrent = spillwayResetDatum.Value.current;
				component.spillwayOpenPercentDesired = spillwayResetDatum.Value.desired;
			}
		}
		Vector3 input = default;
		for (int j = 0; j < scaffoldColumns.Count; j++)
		{
			Cell cellData = World.inst.GetCellData(scaffoldColumns[j]);
			BlockBuilding.MarkBlockStackAndNeighborsDirty(cellData);
			TerrainGen.inst.RecalcWaterObstructionForArea(cellData.x - 1, cellData.z - 1, 3, 3);
			Vector3 center3D = cellData.Center3D;
			input.NonAllocateAdd(center3D);
			EffectsMan.inst.DemolishEffectPuff.CreateAndPlay(center3D);
		}
		if (scaffoldColumns.Count > 0)
		{
			input.NonAllocateDivide(scaffoldColumns.Count);
			EventInstance eventInstance = RuntimeManager.CreateInstance("event:/SFX ASITP/sfx_building_med_destroy_head");
			eventInstance.set3DAttributes(input.To3DAttributes());
			eventInstance.start();
			eventInstance.release();
		}
		BlockStackUpdateSystem.inst.FlushBlockStackUpdates();
	}

	public void SetOutlineImmediate(int i)
	{
	}

	public int LandMass()
	{
		return World.inst.GetCellData(scaffoldColumns[0]).landMassIdx;
	}

	public int TeamID()
	{
		return 0;
	}

	public bool CanDemolishBuilding()
	{
		return true;
	}

	public void DemolishBuilding()
	{
		GameUI.inst.ClearCellSelected();
		CancelProject();
	}

	public void PlaySelectSound()
	{
	}

	public bool UnderConstruction()
	{
		return true;
	}

	public bool ConstructionPaused()
	{
		return constructionPaused;
	}

	public void PauseConstruction()
	{
		if (constructionPaused)
		{
			return;
		}
		constructionPaused = true;
		foreach (BuildingDescriptionDamPlanning item in damsToAdd)
		{
			Building building = DamPlannerUI.FindBuilding(item);
			if (building != null)
			{
				building.ConstructionForeman.ConstructionPaused = true;
			}
		}
	}

	public void UnpauseConstruction()
	{
		if (!constructionPaused)
		{
			return;
		}
		constructionPaused = false;
		foreach (BuildingDescriptionDamPlanning item in damsToAdd)
		{
			Building building = DamPlannerUI.FindBuilding(item);
			if (building != null)
			{
				building.ConstructionForeman.ConstructionPaused = false;
			}
		}
	}

	public void GetConstructionSummary(ref ConstructionForeman.ConstructionSummary summary)
	{
		List<ConstructionForeman> list = new List<ConstructionForeman>();
		foreach (BuildingDescriptionDamPlanning item in damsToAdd)
		{
			Building building = DamPlannerUI.FindBuilding(item);
			if (building != null)
			{
				list.Add(building.ConstructionForeman);
			}
		}
		summary.Summarize(list.ToArray());
		summary.friendlyName = LocalizationManager.GetTranslation("constructui_damproject_title");
	}

	public bool BuildFootprintClear()
	{
		return true;
	}

	public bool WorkersAssignedToClearFootprint()
	{
		return false;
	}

	public int GetBuildAllowedWorkers()
	{
		int num = 0;
		foreach (BuildingDescriptionDamPlanning item in damsToAdd)
		{
			Building building = DamPlannerUI.FindBuilding(item);
			if (building != null)
			{
				num += building.ConstructionForeman.GetWorkersAssigned;
			}
		}
		return num;
	}

	public Vector3 Center()
	{
		Vector3 zero = Vector3.zero;
		foreach (Vector3 scaffoldColumn in scaffoldColumns)
		{
			float y = TerrainGen.inst.GetInterpolatedHeight(scaffoldColumn);
			Building topStructure = World.inst.GetCellData(scaffoldColumn).TopStructure;
			if (topStructure != null)
			{
				y = topStructure.cachedPos.y;
			}
			zero += new Vector3(scaffoldColumn.x, y, scaffoldColumn.z);
		}
		return zero / scaffoldColumns.Count;
	}

	public int CategoryHash()
	{
		return World.damPlanningProjectHash;
	}

	public int UniqueNameHash()
	{
		return World.damPlanningProjectHash;
	}

	public bool IsOpen()
	{
		return true;
	}

	private void ApplyDeferredTerrain()
	{
		if (deferredTerrainVertices == null || deferredTerrainVertices.Length == 0)
		{
			return;
		}
		for (int i = 0; i < deferredTerrainVertices.Length; i++)
		{
			TerrainGen.inst.SetVert(deferredTerrainVertices[i], deferredTerrainNewHeights[i], bakeDown: true);
		}
		TerrainGen.inst.UpdateTerrainDeformations();
		if (cellTerrainDataMap == null)
		{
			return;
		}
		foreach (KeyValuePair<int, CellTerrainData> item in cellTerrainDataMap)
		{
			Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(item.Key);
			if (cellDataUnsafe == null)
			{
				continue;
			}
			foreach (Building item2 in cellDataUnsafe.OccupyingStructure)
			{
				if (item2.uniqueNameHash == World.damHash)
				{
					BlockBuilding component = item2.GetComponent<BlockBuilding>();
					if (component != null)
					{
						component.SetTerrainRestorationData((int[])item.Value.vertexIndices.Clone(), (float[])item.Value.originalHeights.Clone());
					}
				}
			}
		}
	}
}
