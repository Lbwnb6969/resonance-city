using System;
using System.Collections.Generic;
using System.Linq;
using Assets;
using Assets.Code;
using I2.Loc;
using UnityEngine;
using UnityEngine.Rendering;
using cakeslice;

public class EditTerrainProject : MonoBehaviour, ISelectableBuilding, IProceduralOutline, IWorkerUIDisplay, IEmployer
{
	[Serializable]
	public class EditTerrainMoveUnit
	{
		public int fromMeshIndex;

		public int toMeshIndex;

		public int fromProjectIndexId;

		public int toProjectIndexId;

		public SerializableVector3 pickupPosition;

		public SerializableVector3 dropoffPosition;

		public int amount;

		public bool actuallyPickup = true;

		public bool actuallyDropoff = true;

		private const int STATE_MOVINGTO = 1;

		private const int STATE_PICKEDUP = 2;

		private const int STATE_FINISHED = 3;

		public int state = 1;

		public void Pickup()
		{
			state = 2;
		}

		public void Finish()
		{
			state = 3;
		}

		public bool IsFinished()
		{
			return state == 3;
		}

		public EditTerrainMoveUnit(int fromMeshIndex, int toMeshIndex, int fromProjectIndexId, int toProjectIndexId, int amount, bool actuallyPickup, bool actuallyDropoff)
		{
			this.fromMeshIndex = fromMeshIndex;
			this.toMeshIndex = toMeshIndex;
			this.fromProjectIndexId = fromProjectIndexId;
			this.toProjectIndexId = toProjectIndexId;
			this.amount = amount;
			this.actuallyPickup = actuallyPickup;
			this.actuallyDropoff = actuallyDropoff;
			pickupPosition = new Vector3((float)(fromMeshIndex % World.MeshWidth) * 0.5f, 0f, (float)(fromMeshIndex / World.MeshWidth) * 0.5f);
			TerrainGen.inst.GetGroundHeight(ref pickupPosition);
			dropoffPosition = new Vector3((float)(toMeshIndex % World.MeshWidth) * 0.5f, 0f, (float)(toMeshIndex / World.MeshWidth) * 0.5f);
			TerrainGen.inst.GetGroundHeight(ref dropoffPosition);
		}

		public EditTerrainMoveUnit(EditTerrainMoveUnit moveUnit)
		{
			fromMeshIndex = moveUnit.fromMeshIndex;
			toMeshIndex = moveUnit.toMeshIndex;
			fromProjectIndexId = moveUnit.fromProjectIndexId;
			toProjectIndexId = moveUnit.toProjectIndexId;
			amount = moveUnit.amount;
			state = moveUnit.state;
			pickupPosition = moveUnit.pickupPosition;
			dropoffPosition = moveUnit.dropoffPosition;
			actuallyPickup = moveUnit.actuallyPickup;
			actuallyDropoff = moveUnit.actuallyDropoff;
		}
	}

	[Serializable]
	public class EditTerrainProjectSaveData : SaveClass<EditTerrainProject, EditTerrainProjectSaveData>
	{
		public int allowedWorkers;

		public int mostCentralVert;

		public List<object> jobs = new List<object>();

		public int[] cellsWithEditZones;

		public int[] workPoints;

		public float[] endHeights;

		public int[] heightReservations;

		public float totalChangesToMake;

		public float totalChangesMade;

		public int goldCost;

		public bool constructionPaused;

		public int landMass;

		public bool showFences;

		public int jCategory = 36;

		public override EditTerrainProjectSaveData Pack(EditTerrainProject obj)
		{
			allowedWorkers = obj.allowedWorkers;
			mostCentralVert = obj.mostCentralVert;
			cellsWithEditZones = obj.editTerrainZones.Keys.ToArray();
			workPoints = obj.workPoints.ToArray();
			endHeights = obj.endHeights.ToArray();
			heightReservations = obj.heightReservations.ToArray();
			totalChangesToMake = obj.totalChangesToMake;
			totalChangesMade = obj.totalChangesMade;
			goldCost = obj.projectCost.Get(4);
			constructionPaused = obj.constructionPaused;
			showFences = obj.showFences;
			jCategory = obj.jCategory;
			jobs = Job.PackJobList(obj.jobs);
			return this;
		}

		public override EditTerrainProject Unpack(EditTerrainProject obj)
		{
			obj.allowedWorkers = allowedWorkers;
			obj.mostCentralVert = mostCentralVert;
			obj.RestoreRails(cellsWithEditZones);
			obj.workPoints = workPoints.ToArray();
			obj.endHeights = endHeights.ToArray();
			obj.heightReservations = heightReservations.ToArray();
			obj.BuildWorkPointIndexMap();
			obj.totalChangesToMake = totalChangesToMake;
			obj.totalChangesMade = totalChangesMade;
			obj.projectCost.Set(4, goldCost);
			obj.constructionPaused = constructionPaused;
			obj.showFences = showFences;
			obj.jCategory = jCategory;
			obj.CalculateLandmass();
			obj.jobs = new List<Job>();
			foreach (object job in jobs)
			{
				EditTerrainJobs.EditTerrainJobsSaveData editTerrainJobsSaveData = null;
				editTerrainJobsSaveData = ((!(job is SaveEntry saveEntry)) ? (job as EditTerrainJobs.EditTerrainJobsSaveData) : (saveEntry.data as EditTerrainJobs.EditTerrainJobsSaveData));
				if (editTerrainJobsSaveData != null)
				{
					editTerrainJobsSaveData.ProjectRef_Injected = obj;
				}
			}
			Job.UnpackJobList(jobs, obj, obj.jobs);
			return obj;
		}
	}

	private static Mesh highlightMesh;

	private Matrix4x4[] highlightMatrices;

	private bool highlightMatricesDirty = true;

	public bool fullyConstructed;

	public ObjectHighlighter highlight;

	private int mostCentralVert;

	private int allowedWorkers;

	private bool constructionPaused;

	private List<Job> jobs;

	public int[] workPoints;

	public Dictionary<int, int> workPointIndexMap;

	public float[] endHeights;

	private int[] heightReservations;

	public static float perUnit = 0.33f;

	public float totalChangesToMake;

	public float totalChangesMade;

	private ResourceAmount projectCost = new ResourceAmount();

	public bool showFences = true;

	public int jCategory = 36;

	public Dictionary<int, Building> editTerrainZones = new Dictionary<int, Building>();

	private bool cancelled;

	private new static string name = "Terrain Project";

	public static int nameHash = name.GetHashCode();

	private int landMass;

	public string CustomName
	{
		get
		{
			return name;
		}
		set
		{
			name = value;
		}
	}

	public string Description => "Terrain engineering project (If you see me in game, localize me)";

	private static Mesh CreateSingleCellHighlightMesh()
	{
		Mesh mesh = new Mesh();
		mesh.name = "TerrainProjectHighlightMesh";
		Vector3[] array = new Vector3[9];
		int num = 0;
		for (int i = 0; i < 3; i++)
		{
			for (int j = 0; j < 3; j++)
			{
				array[num++] = new Vector3((float)j * 0.5f - 0.5f, 0f, (float)i * 0.5f - 0.5f);
			}
		}
		int[] triangles = new int[24]
		{
			0, 3, 1, 1, 3, 4, 1, 4, 2, 2,
			4, 5, 3, 6, 4, 4, 6, 7, 4, 7,
			5, 5, 7, 8
		};
		mesh.vertices = array;
		mesh.triangles = triangles;
		mesh.RecalculateNormals();
		mesh.RecalculateBounds();
		return mesh;
	}

	public static EditTerrainProject CreateNewEmptyProject()
	{
		return new GameObject("Project").AddComponent<EditTerrainProject>();
	}

	public static EditTerrainProject CreateNewFlattenProject(Cell[] cells, float height, int jCategory = 36)
	{
		List<int> list = new List<int>();
		int num = int.MaxValue;
		for (int i = 0; i < cells.Length; i++)
		{
			int num2 = DynamicWater.MapIndexWorldToMesh(cells[i].index, World.inst.GridWidth) - 1 - World.MeshWidth;
			if (num2 < num)
			{
				num = num2;
			}
			if (!list.Contains(num2))
			{
				list.Add(num2);
			}
			if (!list.Contains(num2 + 1))
			{
				list.Add(num2 + 1);
			}
			if (!list.Contains(num2 + 2))
			{
				list.Add(num2 + 2);
			}
			if (!list.Contains(num2 + World.MeshWidth))
			{
				list.Add(num2 + World.MeshWidth);
			}
			if (!list.Contains(num2 + World.MeshWidth + 1))
			{
				list.Add(num2 + World.MeshWidth + 1);
			}
			if (!list.Contains(num2 + World.MeshWidth + 2))
			{
				list.Add(num2 + World.MeshWidth + 2);
			}
			if (!list.Contains(num2 + World.MeshWidth * 2))
			{
				list.Add(num2 + World.MeshWidth * 2);
			}
			if (!list.Contains(num2 + World.MeshWidth * 2 + 1))
			{
				list.Add(num2 + World.MeshWidth * 2 + 1);
			}
			if (!list.Contains(num2 + World.MeshWidth * 2 + 2))
			{
				list.Add(num2 + World.MeshWidth * 2 + 2);
			}
		}
		List<int> list2 = new List<int>();
		List<float> list3 = new List<float>();
		for (int j = 0; j < list.Count; j++)
		{
			Vector3 vertPosMesh = TerrainGen.inst.GetVertPosMesh(list[j]);
			if (!(Mathf.Abs(vertPosMesh.y - height) < 0.001f))
			{
				list2.Add(list[j]);
				list3.Add(height);
				Debug.DrawLine(vertPosMesh + Vector3.up * 5f, vertPosMesh + Vector3.up * 10f, Color.red, 10000f);
			}
		}
		if (list2.Count == 0)
		{
			return null;
		}
		EditTerrainProject component = CreateNewEmptyProject().GetComponent<EditTerrainProject>();
		component.Init(list2.ToArray(), list3.ToArray(), cells.Length, tightRails: true, showFences: false, jCategory);
		return component;
	}

	public void Init(int[] workPoints, float[] endHeights, int allowedWorkers, bool tightRails, bool showFences, int jCategory = 36, bool zonesUnderBuildings = false)
	{
		int num = projectCost.Get(4);
		Player.inst.PlayerLandmassOwner.Gold -= num;
		if (num > 0)
		{
			ResourceStatistics.AddConsumption(Player.inst.FocusedLandMassIdxLastValid, "terrain_project", 4, num);
		}
		EditTerrainProjectManager.inst.RegisterProject(this);
		this.workPoints = workPoints;
		this.endHeights = endHeights;
		heightReservations = new int[workPoints.Length];
		BuildWorkPointIndexMap();
		this.showFences = showFences;
		this.jCategory = jCategory;
		bool flag = false;
		for (int i = 0; i < workPoints.Length; i++)
		{
			float vertYUnsafe = TerrainGen.inst.GetVertYUnsafe(workPoints[i]);
			float num2 = TerrainRockFill.RaiseFreeFill(workPoints[i] % World.MeshWidth, workPoints[i] / World.MeshWidth, vertYUnsafe, endHeights[i]);
			if (num2 > 0f)
			{
				TerrainGen.inst.ChangeVertY(workPoints[i], num2);
				flag = true;
			}
		}
		if (flag)
		{
			TerrainGen.inst.UpdateTerrainDeformations();
		}
		totalChangesToMake = 0f;
		for (int j = 0; j < workPoints.Length; j++)
		{
			totalChangesToMake += Mathff.Abs(endHeights[j] - TerrainGen.inst.GetVertYUnsafe(workPoints[j]));
		}
		jobs = new List<Job>();
		PlaceRails(workPoints, tightRails, zonesUnderBuildings);
		this.allowedWorkers = allowedWorkers;
		mostCentralVert = workPoints[0];
		CalculateLandmass();
		if (highlightMesh == null)
		{
			highlightMesh = CreateSingleCellHighlightMesh();
		}
		highlight = ObjectHighlighter.SetupOutline(gameObject, this, formToTerrain: true);
	}

	public void AddDirtJobs()
	{
		for (int i = 0; i < allowedWorkers; i++)
		{
			EditTerrainJobs editTerrainJobs = new EditTerrainJobs(this);
			editTerrainJobs.ManualAssignment = constructionPaused;
			jobs.Add(editTerrainJobs);
			JobSystem.inst.AddNewJob(editTerrainJobs, jCategory);
		}
	}

	public void PlaceRails(int[] points, bool tight = false, bool zonesUnderBuildings = false)
	{
		int i = 0;
		for (int num = points.Length; i < num; i++)
		{
			int num2 = points[i] % World.MeshWidth;
			int num3 = points[i] / World.MeshWidth;
			bool flag = num2 % 2 == 0;
			bool flag2 = num3 % 2 == 0;
			if (tight && (flag2 | flag))
			{
				continue;
			}
			for (int j = (flag ? (-1) : 0); j <= (flag ? 1 : 0); j++)
			{
				for (int k = (flag2 ? (-1) : 0); k <= (flag2 ? 1 : 0); k++)
				{
					int num4 = num2 + j;
					int num5 = num3 + k;
					if (num4 < 0 || num5 < 0 || num4 >= World.MeshWidth || num5 >= World.MeshHeight)
					{
						continue;
					}
					int num6 = DynamicWater.MapIndexMeshToWorld(num4 + num5 * World.MeshWidth, World.inst.GridWidth);
					Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(num6);
					if (!editTerrainZones.ContainsKey(num6) && (zonesUnderBuildings || !World.CellBlocksTerrainEdit(cellDataUnsafe)) && cellDataUnsafe.landMassIdx != -1)
					{
						Building building = (showFences ? UnityEngine.Object.Instantiate(GameState.inst.GetPlaceableByUniqueName("editterrainzone")) : UnityEngine.Object.Instantiate(GameState.inst.GetPlaceableByUniqueName("editterrainzone_norails")));
						building.Init();
						editTerrainZones[num6] = building;
						highlightMatricesDirty = true;
						Vector3 pos = new Vector3(num6 % World.inst.GridWidth, 0f, num6 / World.inst.GridWidth);
						TerrainGen.inst.GetGroundHeight(ref pos);
						building.transform.position = pos;
						building.doBuildAnimation = false;
						building.removeTreesOnComplete = false;
						building.removeRocksOnComplete = false;
						World.inst.PlaceFromLoad(building);
						building.BroadcastMessage("OnAdjacentAddRemovedBuilding", false, SendMessageOptions.DontRequireReceiver);
						building.gameObject.AddComponent<EditTerrainProjectReference>().project = this;
						if (!cellDataUnsafe.IsCellClear() && !cellDataUnsafe.Busy)
						{
							ClearCutterJob clearCutterJob = new ClearCutterJob(cellDataUnsafe);
							clearCutterJob.StartClearingAt(cellDataUnsafe);
							JobSystem.inst.AddNewJob(clearCutterJob, jCategory);
						}
					}
				}
			}
		}
	}

	public void RestoreRails(int[] cellsWithZones)
	{
		int i = 0;
		for (int num = cellsWithZones.Length; i < num; i++)
		{
			editTerrainZones[cellsWithZones[i]] = World.inst.GetCellDataUnsafe(cellsWithZones[i]).StructureFindByCategory(World.editTerrainZoneHash);
			editTerrainZones[cellsWithZones[i]].gameObject.AddComponent<EditTerrainProjectReference>().project = this;
			Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(cellsWithZones[i]);
			if (!cellDataUnsafe.IsCellClear() && !cellDataUnsafe.Busy)
			{
				ClearCutterJob clearCutterJob = new ClearCutterJob(cellDataUnsafe);
				clearCutterJob.StartClearingAt(cellDataUnsafe);
				JobSystem.inst.AddNewJob(clearCutterJob, jCategory);
			}
		}
		highlightMatricesDirty = true;
		if (highlightMesh == null)
		{
			highlightMesh = CreateSingleCellHighlightMesh();
		}
		if (highlight == null)
		{
			highlight = ObjectHighlighter.SetupOutline(gameObject, this, formToTerrain: true);
		}
	}

	public void Tick()
	{
		if (jobs.Count == 0 && !cancelled)
		{
			bool flag = true;
			foreach (int key in editTerrainZones.Keys)
			{
				if (!World.inst.GetCellDataUnsafe(key).IsCellClear())
				{
					flag = false;
					break;
				}
			}
			if (flag)
			{
				AddDirtJobs();
			}
		}
		if (Creative.inst.IsCreativeOptionOn(11))
		{
			FixUpRemainingPieces();
			Cancel();
		}
	}

	private void RemoveClearingJobs()
	{
		foreach (KeyValuePair<int, Building> editTerrainZone in editTerrainZones)
		{
			if (World.inst.GetCellDataUnsafe(editTerrainZone.Key).busyObj is ClearCutterJob job)
			{
				JobSystem.inst.RemoveJobDeferred(job);
			}
		}
	}

	public void Cancel()
	{
		cancelled = true;
		for (int i = 0; i < jobs.Count; i++)
		{
			Job job = jobs[i];
			JobSystem.inst.RemoveJobDeferred(job);
		}
		RemoveClearingJobs();
		jobs.Clear();
		ReclassifyTouchedRock();
		RefreshTouchedRoads();
		UnityEngine.Object.Destroy(gameObject);
	}

	public void OnDestroy()
	{
		EditTerrainProjectManager.inst.DeregisterProject(this);
		foreach (KeyValuePair<int, Building> editTerrainZone in editTerrainZones)
		{
			if (editTerrainZone.Value != null)
			{
				World.inst.VanishBuilding(editTerrainZone.Value);
				World.inst.ReplaceItems(editTerrainZone.Value.cachedCell.x, editTerrainZone.Value.cachedCell.z);
			}
		}
		editTerrainZones.Clear();
	}

	public void BuildWorkPointIndexMap()
	{
		workPointIndexMap = new Dictionary<int, int>(workPoints.Length);
		for (int i = 0; i < workPoints.Length; i++)
		{
			workPointIndexMap[workPoints[i]] = i;
		}
	}

	public EditTerrainMoveUnit GetNewMoveUnit()
	{
		float num = float.MinValue;
		float num2 = float.MaxValue;
		int num3 = -1;
		int num4 = -1;
		for (int i = 0; i < workPoints.Length; i++)
		{
			float num5 = EditTerrainProjectManager.inst.CalculateHighestEndHeightFor(workPoints[i]) - TerrainGen.inst.GetVertYUnsafe(workPoints[i]) - (float)heightReservations[i] / 1000f;
			if ((int)(Mathff.Abs(num5) * 1000f) != 0 && num5 != 0f)
			{
				if (num5 > 0f && num5 > num)
				{
					num = num5;
					num3 = i;
				}
				if (num5 < 0f && num5 < num2)
				{
					num2 = num5;
					num4 = i;
				}
			}
		}
		if (num3 == -1 && num4 == -1)
		{
			return null;
		}
		int num6 = num4;
		int num7 = num3;
		int num8 = 0;
		bool actuallyPickup = true;
		bool actuallyDropoff = true;
		if (num3 != -1 && num4 != -1)
		{
			num8 = (int)(Mathf.Min(num, Mathff.Abs(num2), perUnit) * 1000f);
		}
		else if (num3 != -1)
		{
			num8 = (int)(Mathf.Min(Mathff.Abs(num), perUnit) * 1000f);
		}
		else if (num4 != -1)
		{
			num8 = (int)(Mathf.Min(Mathff.Abs(num2), perUnit) * 1000f);
		}
		if (num6 == -1)
		{
			num6 = SRand.Range(0, workPoints.Length);
			actuallyPickup = false;
		}
		else
		{
			heightReservations[num6] -= num8;
		}
		if (num7 == -1)
		{
			num7 = SRand.Range(0, workPoints.Length);
			actuallyDropoff = false;
		}
		else
		{
			heightReservations[num7] += num8;
		}
		return new EditTerrainMoveUnit(workPoints[num6], workPoints[num7], num6, num7, num8, actuallyPickup, actuallyDropoff);
	}

	public void Pickup(EditTerrainMoveUnit moveUnit)
	{
		moveUnit.Pickup();
		if (moveUnit.actuallyPickup)
		{
			TerrainGen.inst.ChangeVertY(moveUnit.fromMeshIndex, (float)(-moveUnit.amount) / 1000f);
			heightReservations[moveUnit.fromProjectIndexId] += moveUnit.amount;
			totalChangesMade += (float)moveUnit.amount / 1000f;
		}
	}

	public void DropOff(EditTerrainMoveUnit moveUnit)
	{
		moveUnit.Finish();
		if (moveUnit.actuallyDropoff)
		{
			TerrainGen.inst.ChangeVertY(moveUnit.toMeshIndex, (float)moveUnit.amount / 1000f);
			heightReservations[moveUnit.toProjectIndexId] -= moveUnit.amount;
			totalChangesMade += (float)moveUnit.amount / 1000f;
		}
	}

	public void DrawOutline(CommandBuffer commandBuffer, Material m)
	{
		if (highlightMesh == null || editTerrainZones.Count == 0)
		{
			return;
		}
		if (highlightMatricesDirty || highlightMatrices == null || highlightMatrices.Length != editTerrainZones.Count)
		{
			highlightMatrices = new Matrix4x4[editTerrainZones.Count];
			int num = 0;
			foreach (KeyValuePair<int, Building> editTerrainZone in editTerrainZones)
			{
				int key = editTerrainZone.Key;
				float x = (float)(key % World.inst.GridWidth) + 0.5f;
				float z = (float)(key / World.inst.GridWidth) + 0.5f;
				highlightMatrices[num] = Matrix4x4.TRS(new Vector3(x, 0f, z), Quaternion.identity, Vector3.one);
				num++;
			}
			highlightMatricesDirty = false;
		}
		commandBuffer.DrawMeshInstanced(highlightMesh, 0, m, 0, highlightMatrices);
	}

	public void SetOutlineImmediate(int colorIdx)
	{
		highlight?.SetOutlineImmediate(colorIdx);
	}

	public string GetUsedSkill()
	{
		return "";
	}

	public int LandMass()
	{
		return landMass;
	}

	public int GetJobCategory()
	{
		return jCategory;
	}

	public bool DuringWorkHours(float buffer = 0f)
	{
		return true;
	}

	public float GetStartHour()
	{
		return -1f;
	}

	public float GetEndHour()
	{
		return -1f;
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
		if (!cancelled)
		{
			cancelled = true;
			int num = ((totalChangesToMake > 0f) ? ((int)((float)projectCost.Get(4) * (1f - Mathff.Clamp01(totalChangesMade / totalChangesToMake)))) : 0);
			Player.inst.PlayerLandmassOwner.Gold += num;
			if (num > 0)
			{
				ResourceStatistics.AddProduction(landMass, "terrain_project_refund", 4, num);
			}
			for (int i = 0; i < jobs.Count; i++)
			{
				Job job = jobs[i];
				JobSystem.inst.RemoveJobDeferred(job);
			}
			RemoveClearingJobs();
			jobs.Clear();
			ReclassifyTouchedRock();
			RefreshTouchedRoads();
			UnityEngine.Object.Destroy(gameObject);
		}
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
		constructionPaused = true;
		for (int i = 0; i < jobs.Count; i++)
		{
			Job job = jobs[i];
			job.ManualAssignment = true;
			Villager employee = job.Employee;
			if (employee != null)
			{
				employee.QuitJob();
			}
		}
	}

	public void UnpauseConstruction()
	{
		constructionPaused = false;
		for (int i = 0; i < jobs.Count; i++)
		{
			jobs[i].ManualAssignment = false;
		}
	}

	public void GetConstructionSummary(ref ConstructionForeman.ConstructionSummary summary)
	{
		summary.constructionPaused = constructionPaused;
		summary.constructionProgress = totalChangesMade / totalChangesToMake;
		summary.jobs = jobs;
		summary.clearLandJobs = new List<ClearCutterJob>();
		summary.friendlyName = LocalizationManager.GetTranslation("constructui_terrainproject_name");
		summary.resourceProgress = 1f;
		summary.notCollected = new ResourceAmount();
		int num = jobs.Count;
		int num2 = 0;
		for (int i = 0; i < jobs.Count; i++)
		{
			if (jobs[i].HasEmployee())
			{
				num2++;
			}
		}
		foreach (KeyValuePair<int, Building> editTerrainZone in editTerrainZones)
		{
			if (World.inst.GetCellDataUnsafe(editTerrainZone.Key).busyObj is ClearCutterJob clearCutterJob)
			{
				summary.clearLandJobs.Add(clearCutterJob);
				num++;
				if (clearCutterJob.HasEmployee())
				{
					num2++;
				}
			}
		}
		summary.workerPercent = ((num > 0) ? ((float)num2 / (float)num) : 0f);
		summary.workersAssigned = num2;
		summary.totalWorkers = num;
	}

	public bool BuildFootprintClear()
	{
		bool result = true;
		foreach (KeyValuePair<int, Building> editTerrainZone in editTerrainZones)
		{
			if (World.inst.GetCellDataUnsafe(editTerrainZone.Key).busyObj is ClearCutterJob)
			{
				result = false;
				break;
			}
		}
		return result;
	}

	public bool WorkersAssignedToClearFootprint()
	{
		foreach (KeyValuePair<int, Building> editTerrainZone in editTerrainZones)
		{
			if (World.inst.GetCellDataUnsafe(editTerrainZone.Key).busyObj is ClearCutterJob clearCutterJob && clearCutterJob.HasEmployee())
			{
				return true;
			}
		}
		return false;
	}

	public int GetBuildAllowedWorkers()
	{
		return allowedWorkers;
	}

	public Vector3 Center()
	{
		return TerrainGen.inst.GetVertPosMesh(mostCentralVert);
	}

	public int CategoryHash()
	{
		return nameHash;
	}

	public int UniqueNameHash()
	{
		return nameHash;
	}

	public Vector3 GetPosition()
	{
		return Center();
	}

	public TransformData GetPositionForPerson(Villager p)
	{
		return new TransformData
		{
			position = Center()
		};
	}

	bool IEmployer.IsOpen()
	{
		return true;
	}

	public void OnAssigned(Villager p)
	{
	}

	public void OnUnAssigned(Villager p)
	{
	}

	public void OnJobRemoved(Job j)
	{
	}

	bool ISelectableBuilding.IsOpen()
	{
		return true;
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	public void LooksLikeImDoneHere(EditTerrainJobs editTerrainJobs)
	{
		jobs.Remove(editTerrainJobs);
		JobSystem.inst.RemoveJobDeferred(editTerrainJobs);
		if (jobs.Count == 0)
		{
			cancelled = true;
			FixUpRemainingPieces();
			ReclassifyTouchedRock();
			RefreshTouchedRoads();
			UnityEngine.Object.Destroy(gameObject);
		}
	}

	public void FixUpRemainingPieces()
	{
		for (int i = 0; i < workPoints.Length; i++)
		{
			float y = EditTerrainProjectManager.inst.CalculateHighestEndHeightFor(workPoints[i]);
			TerrainGen.inst.SetVert(workPoints[i], y, bakeDown: true);
		}
	}

	private void RefreshTouchedRoads()
	{
		if (workPoints == null || workPoints.Length == 0)
		{
			return;
		}
		int num = int.MaxValue;
		int num2 = int.MaxValue;
		int num3 = int.MinValue;
		int num4 = int.MinValue;
		for (int i = 0; i < workPoints.Length; i++)
		{
			int num5 = workPoints[i] % World.MeshWidth;
			int num6 = workPoints[i] / World.MeshWidth;
			if (num5 < num)
			{
				num = num5;
			}
			if (num5 > num3)
			{
				num3 = num5;
			}
			if (num6 < num2)
			{
				num2 = num6;
			}
			if (num6 > num4)
			{
				num4 = num6;
			}
		}
		int num7 = Mathf.Max(0, num / 2 - 1);
		int num8 = Mathf.Max(0, num2 / 2 - 1);
		int num9 = Mathf.Min(World.inst.GridWidth - 1, num3 / 2 + 1);
		int num10 = Mathf.Min(World.inst.GridHeight - 1, num4 / 2 + 1);
		for (int j = num8; j <= num10; j++)
		{
			for (int k = num7; k <= num9; k++)
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(k, j);
				for (int num11 = cellDataUnsafe.OccupyingStructure.Count - 1; num11 >= 0; num11--)
				{
					Building building = cellDataUnsafe.OccupyingStructure[num11];
					if (World.IsTerrainEditableRoad(building))
					{
						if (cellDataUnsafe.Type == TerrainType.Obstruction)
						{
							World.inst.DemolishBuilding(building, reclaimResources: false);
						}
						else
						{
							Vector3 pos = building.transform.position;
							TerrainGen.inst.GetGroundHeight(ref pos);
							building.transform.position = pos;
							building.cachedPos = pos;
							building.UpdateShaderHeight();
						}
					}
				}
			}
		}
	}

	private void ReclassifyTouchedRock()
	{
		if (workPoints == null || workPoints.Length == 0)
		{
			return;
		}
		int num = int.MaxValue;
		int num2 = int.MaxValue;
		int num3 = int.MinValue;
		int num4 = int.MinValue;
		for (int i = 0; i < workPoints.Length; i++)
		{
			int num5 = workPoints[i] % World.MeshWidth;
			int num6 = workPoints[i] / World.MeshWidth;
			if (num5 < num)
			{
				num = num5;
			}
			if (num5 > num3)
			{
				num3 = num5;
			}
			if (num6 < num2)
			{
				num2 = num6;
			}
			if (num6 > num4)
			{
				num4 = num6;
			}
		}
		TerrainRockReclassifier.ReclassifyVertRect(num, num2, num3, num4);
	}

	internal void SetCost(ResourceAmount projectCost)
	{
		this.projectCost = new ResourceAmount(projectCost);
	}

	private void CalculateLandmass()
	{
		for (int i = 0; i < workPoints.Length; i++)
		{
			int landMassIdx = World.inst.GetCellDataUnsafe(DynamicWater.MapIndexMeshToWorld(workPoints[i], World.inst.GridWidth)).landMassIdx;
			if (landMassIdx != -1)
			{
				landMass = landMassIdx;
				break;
			}
		}
	}
}
