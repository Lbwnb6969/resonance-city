using System;
using System.Collections.Generic;
using System.Runtime.Serialization;
using Assets;
using I2.Loc;
using UnityEngine;
using UnityEngine.Rendering;
using cakeslice;

public class RiverTap : AqueductBuilding, IOutputInfo, ISelectableBuilding, IProceduralOutline, IWorkerUIDisplay
{
	[Serializable]
	public class RiverTapSaveData : SaveClass<RiverTap, RiverTapSaveData>
	{
		private SerializableVector3 position;

		private SerializableQuaternion rotation;

		private float inputFromEnvironment;

		[OptionalField(VersionAdded = 5)]
		private bool savedInHumanUnits;

		[OptionalField(VersionAdded = 5)]
		private float inputFromEnvironmentHuman;

		[OptionalField(VersionAdded = 6)]
		private bool open;

		private bool damMounted;

		private SerializableVector3 mountDir;

		[OnDeserializing]
		private void SetDefaults(StreamingContext sc)
		{
			open = true;
		}

		public override RiverTapSaveData Pack(RiverTap w)
		{
			savedInHumanUnits = true;
			inputFromEnvironmentHuman = w.inputFromEnvironment;
			inputFromEnvironment = 0f;
			open = w.open;
			damMounted = w.damMounted;
			mountDir = w.mountDir;
			position = w.transform.position;
			rotation = w.transform.rotation;
			return this;
		}

		public override RiverTap Unpack(RiverTap w)
		{
			w.inputFromEnvironment = (savedInHumanUnits ? inputFromEnvironmentHuman : AqueductBuilding.SystemToHuman(inputFromEnvironment));
			w.open = open;
			w.damMounted = damMounted;
			w.mountDir = mountDir;
			w.transform.position = position;
			w.transform.rotation = rotation;
			return w;
		}
	}

	public bool updateNeeded;

	private float waterExtractedThisFrame;

	private float maxNeed = 1f;

	private float waterTransitionTimer;

	private const float WATER_TRANSITION_INTERVAL = 0.5f;

	private float accumulatedWater;

	private int waterExtractionCount;

	private float perStepBudgetSys = AqueductBuilding.MAX_WATER_FLOW;

	private float lastBatchBudgetHuman = -1f;

	private bool forceBudgetPublish;

	private float physicalCapacity;

	private float accumulatedCapacity;

	private float lastPhysCap;

	public const float CAPACITY_DIRTY_EPSILON = 1f;

	private bool foundWaterThisFrame;

	private Timer timer = new Timer(3f);

	private bool debugOnWaterOn;

	private bool debug;

	private bool hasEverHadConnection;

	private Mesh buildingMesh;

	private Mesh supportMesh;

	private Material material;

	private Matrix4x4[] supportMatrices;

	public ThoughtBubbleSystem.ThoughtBubble thought;

	private ObjectHighlighter highlight;

	public AqueductPlacementError previewError;

	public bool noColliders;

	private static Material invalidPreviewMat;

	public bool damMounted;

	public Vector3 mountDir = Vector3.zero;

	private const float DAM_TUBE_LEN_STRAIGHT = 0.25f;

	private const float DAM_TUBE_LEN_DIAGONAL = 0.6f;

	private const float DAM_TUBE_TIP_OVERSHOOT_STRAIGHT = 0.15f;

	private Mesh damElbowMesh;

	private Vector3 damIntakeTubeScale = Vector3.one;

	private Matrix4x4[] damIntakeTubeMatrices;

	private int damIntakeTubeCount;

	private CapsuleCollider[] damTubeColliders;

	private bool damTubesDirty = true;

	private int damTerrainMask;

	private MeshCollider buildingCollider;

	private BoxCollider damClickCollider;

	public const int MAX_DAM_THICKNESS = 1;

	private DynamicWater.WaterExtractionRequest waterExtractionRequest;

	private int lastExtractionMeshIndex = int.MinValue;

	private Vector3 lastExtractionPos = new Vector3(float.NaN, float.NaN, float.NaN);

	private List<DynamicWater.WaterExtractionRequest.ExtractionPoint> ExtractionPoints = new List<DynamicWater.WaterExtractionRequest.ExtractionPoint>();

	private bool errorNoWaterExtractedThisFrame;

	public static string categoryName = "rivertap";

	public static int categoryHash = categoryName.GetHashCode();

	public static string uniqueName = "rivertap";

	public static int uniqueHash = uniqueName.GetHashCode();

	public const float MIN_DISTANCE_BETWEEN_TAPS = 1f;

	private static List<RiverTap> allRiverTaps = new List<RiverTap>();

	private bool open = true;

	public bool previewInvalid => previewError != AqueductPlacementError.None;

	public string CustomName
	{
		get
		{
			return LocalizationManager.GetTranslation("Building " + uniqueName + " FriendlyName");
		}
		set
		{
		}
	}

	public string Description => LocalizationManager.GetTranslation("Building " + uniqueName + " Description");

	public void Awake()
	{
		portBoxes = new PortBox[1];
		portBoxes[0] = new PortBox();
		portBoxes[0].corner1 = transform;
		portBoxes[0].corner2 = transform;
		maxPorts = 1;
		onlyOutgoing = true;
		onlyIncoming = false;
		RegisterTap();
		material = World.inst.romeUnimaterial;
		buildingMesh = Resources.Load<Mesh>("Models/springhouse");
		supportMesh = Resources.Load<Mesh>("Models/watertap_support");
		damTerrainMask = LayerMask.GetMask("Terrain");
		if (thought == null)
		{
			thought = ThoughtBubbleSystem.inst.AddThoughtBubble(Center());
		}
		thought.visible = false;
		thought.offset = new Vector3(0f, 0.5f, 0f);
		thought.scaleMod = 0.9f;
		highlight = ObjectHighlighter.SetupOutline(base.gameObject, this, formToTerrain: false, clipOnTerrain: true);
		GameObject gameObject = new GameObject("Collider", typeof(MeshCollider));
		gameObject.transform.SetParent(transform, worldPositionStays: false);
		buildingCollider = gameObject.GetComponent<MeshCollider>();
		buildingCollider.sharedMesh = buildingMesh;
		gameObject.AddComponent<BuildingCollider>();
	}

	private void EnsureDamVisual()
	{
		if (damElbowMesh == null)
		{
			GameObject gameObject = Resources.Load<GameObject>("AqueductLine");
			AqueductLine aqueductLine = ((gameObject != null) ? gameObject.GetComponent<AqueductLine>() : null);
			if (aqueductLine != null)
			{
				damElbowMesh = aqueductLine.elbowMesh;
				Vector3 completedElbowScale = aqueductLine.CompletedElbowScale;
				float num = Mathf.Max(damElbowMesh.bounds.size.y, 0.01f);
				damIntakeTubeScale = new Vector3(completedElbowScale.x * 0.5f, 0.35f / num, completedElbowScale.z * 0.5f);
			}
		}
		if (damClickCollider == null && buildingCollider != null)
		{
			buildingCollider.sharedMesh = null;
			buildingCollider.transform.localPosition = Vector3.zero;
			buildingCollider.transform.localRotation = Quaternion.identity;
			damClickCollider = buildingCollider.gameObject.AddComponent<BoxCollider>();
			damClickCollider.size = new Vector3(0.5f, 0.5f, 0.4f);
		}
		if (damTubeColliders == null && buildingCollider != null && !noColliders)
		{
			damTubeColliders = new CapsuleCollider[6];
			for (int i = 0; i < damTubeColliders.Length; i++)
			{
				GameObject gameObject2 = new GameObject("TubeCollider", typeof(CapsuleCollider), typeof(BuildingCollider));
				gameObject2.transform.SetParent(transform, worldPositionStays: false);
				damTubeColliders[i] = gameObject2.GetComponent<CapsuleCollider>();
				damTubeColliders[i].radius = 0.1f;
			}
		}
	}

	private void UpdateIntakeTubeMatrices()
	{
		int num = ExtractionPoints.Count;
		if (damElbowMesh == null || num == 0)
		{
			damIntakeTubeCount = 0;
			return;
		}
		if (!damTubesDirty && damIntakeTubeMatrices != null)
		{
			return;
		}
		damIntakeTubeCount = num * 2;
		if (damIntakeTubeMatrices == null || damIntakeTubeMatrices.Length < damIntakeTubeCount)
		{
			damIntakeTubeMatrices = new Matrix4x4[damIntakeTubeCount];
		}
		float segmentLength = Mathf.Max(damElbowMesh.bounds.size.y, 0.01f);
		float pivotToCenter = damElbowMesh.bounds.center.y;
		Vector3 position = transform.position;
		int num2;
		float num3;
		if (Mathf.Abs(mountDir.x) > 0.01f)
		{
			num2 = ((Mathf.Abs(mountDir.z) > 0.01f) ? 1 : 0);
			if (num2 != 0)
			{
				num3 = 0.6f;
				goto IL_0106;
			}
		}
		else
		{
			num2 = 0;
		}
		num3 = 0.25f;
		goto IL_0106;
		IL_0106:
		float num4 = num3;
		float num5 = ((num2 != 0) ? 0f : 0.15f);
		for (int i = 0; i < num; i++)
		{
			DynamicWater.WaterExtractionRequest.ExtractionPoint extractionPoint = ExtractionPoints[i];
			Vector3 vector = new Vector3((float)(extractionPoint.index % World.MeshWidth) * 0.5f, extractionPoint.altitude, (float)(extractionPoint.index / World.MeshWidth) * 0.5f);
			Vector3 vector2 = vector + mountDir * num5;
			Vector3 a = vector - mountDir * num4;
			damIntakeTubeMatrices[i] = Pipe(i, a, vector2);
			damIntakeTubeMatrices[num + i] = Pipe(num + i, position, a);
		}
		damTubesDirty = false;
		Matrix4x4 Pipe(int idx, Vector3 vector4, Vector3 b)
		{
			Vector3 vector3 = b - vector4;
			float num6 = Mathf.Max(vector3.magnitude, 0.01f);
			Vector3 vector5 = vector3 / num6;
			Vector3 vector6 = (vector4 + b) * 0.5f;
			Quaternion quaternion = Quaternion.FromToRotation(Vector3.up, vector5);
			CapsuleCollider capsuleCollider = ((damTubeColliders != null && idx < damTubeColliders.Length) ? damTubeColliders[idx] : null);
			if (capsuleCollider != null)
			{
				capsuleCollider.transform.SetPositionAndRotation(vector6, quaternion);
				capsuleCollider.height = num6 + capsuleCollider.radius * 2f;
			}
			Vector3 s = new Vector3(damIntakeTubeScale.x, num6 / segmentLength, damIntakeTubeScale.z);
			return Matrix4x4.TRS(vector6 - vector5 * (pivotToCenter * s.y), quaternion, s);
		}
	}

	public void LateUpdate()
	{
		if (debug)
		{
			updateNeeded = false;
			if (timer.Update(Time.deltaTime))
			{
				debugOnWaterOn = !debugOnWaterOn;
				if (debugOnWaterOn)
				{
					waterExtractedThisFrame = AqueductBuilding.MAX_WATER_FLOW;
				}
				else
				{
					waterExtractedThisFrame = 0f;
				}
				updateNeeded = true;
			}
		}
		waterTransitionTimer += Time.deltaTime;
		if (updateNeeded || (waterTransitionTimer >= 0.5f && waterExtractionCount > 0))
		{
			bool flag = updateNeeded;
			float newInput;
			float system;
			if (updateNeeded)
			{
				newInput = Mathf.Round(AqueductBuilding.SystemToHuman(waterExtractedThisFrame));
				system = lastPhysCap;
			}
			else
			{
				float system2 = ((waterExtractionCount > 0) ? (accumulatedWater / (float)waterExtractionCount) : 0f);
				system = ((waterExtractionCount > 0) ? (accumulatedCapacity / (float)waterExtractionCount) : 0f);
				newInput = Mathf.Round(AqueductBuilding.SystemToHuman(system2));
				ResetAveragingWindow();
			}
			if (FlowChanged(newInput, flag || forceBudgetPublish))
			{
				inputFromEnvironment = newInput;
			}
			if (!flag)
			{
				forceBudgetPublish = false;
			}
			float num = Mathf.Round(AqueductBuilding.SystemToHuman(system));
			if (Mathff.Abs(num - physicalCapacity) > 1f)
			{
				AqueductFlowDiagnostics.Note($"RiverTap({(int)transform.position.x},{(int)transform.position.z}) capacity {physicalCapacity:F0}->{num:F0}");
				physicalCapacity = num;
				AqueductFlowController.MarkDemandDirty("LateUpdate");
			}
			UpdateWaterFlow();
		}
		waterExtractedThisFrame = 0f;
		updateNeeded = false;
		bool flag2 = false;
		for (int i = 0; i < aqueductLines.Count; i++)
		{
			AqueductLine aqueductLine = aqueductLines[i];
			if (!(aqueductLine == null) && !aqueductLine.displayOnly)
			{
				flag2 = true;
				hasEverHadConnection = true;
				break;
			}
		}
		if (!flag2 && hasEverHadConnection)
		{
			UnityEngine.Object.Destroy(gameObject);
			return;
		}
		if (damMounted)
		{
			EnsureDamVisual();
			UpdateIntakeTubeMatrices();
			Material material = (previewInvalid ? InvalidPreviewMaterial() : this.material);
			for (int j = 0; j < damIntakeTubeCount; j++)
			{
				Graphics.DrawMesh(damElbowMesh, damIntakeTubeMatrices[j], material, 0);
			}
			return;
		}
		float interpolatedHeight = TerrainGen.inst.GetInterpolatedHeight(transform.position);
		float num2 = transform.position.y - interpolatedHeight;
		int num3 = Mathf.Max(1, Mathf.RoundToInt(num2 / supportMesh.bounds.size.y)) + 1;
		if (supportMatrices == null || supportMatrices.Length != num3)
		{
			supportMatrices = new Matrix4x4[num3];
		}
		Vector3 position = transform.position;
		for (int k = 0; k < num3; k++)
		{
			supportMatrices[k] = Matrix4x4.TRS(new Vector3(position.x, position.y - (float)k * supportMesh.bounds.size.y, position.z), transform.rotation, Vector3.one);
		}
		Graphics.DrawMesh(buildingMesh, transform.localToWorldMatrix, this.material, 0);
		Graphics.DrawMeshInstanced(supportMesh, 0, this.material, supportMatrices);
	}

	public override void UpdateWaterFlow()
	{
		UpdateDrawPoints();
		base.UpdateWaterFlow();
		if (thought != null)
		{
			thought.pos = Center();
		}
	}

	private void ResetAveragingWindow()
	{
		accumulatedWater = 0f;
		accumulatedCapacity = 0f;
		waterExtractionCount = 0;
		waterTransitionTimer = 0f;
	}

	public void MountOnDam(Vector3 tapPos, Vector3 dirIntoWall)
	{
		if (!damMounted || !(tapPos == transform.position) || !(dirIntoWall == mountDir))
		{
			damMounted = true;
			mountDir = dirIntoWall;
			transform.position = tapPos;
			transform.rotation = Quaternion.LookRotation(-dirIntoWall, Vector3.up);
			EnsureDamVisual();
			damTubesDirty = true;
			updateNeeded = true;
		}
	}

	private static Material InvalidPreviewMaterial()
	{
		if (invalidPreviewMat == null)
		{
			invalidPreviewMat = new Material(Player.inst.PlayerLandmassOwner.BuildingMaterial);
			invalidPreviewMat.SetFloat("_Disabled", 0f);
			invalidPreviewMat.SetFloat("_Invalid", 1f);
			invalidPreviewMat.SetFloat("_WallProgress", 1f);
			invalidPreviewMat.SetFloat("_MinHeight", float.MinValue);
			invalidPreviewMat.SetFloat("_MaxHeight", float.MaxValue);
			invalidPreviewMat.SetVector("_BreakPoint", Vector4.zero);
			invalidPreviewMat.SetVector("_BreakOffset", Vector4.zero);
			invalidPreviewMat.SetFloat("_MinYAdjustment", 0f);
			invalidPreviewMat.SetFloat("_MaxYAdjustment", 0f);
			invalidPreviewMat.SetFloat("_Width", World.inst.GridWidth);
			invalidPreviewMat.SetFloat("_Height", World.inst.GridHeight);
			invalidPreviewMat.enableInstancing = true;
		}
		return invalidPreviewMat;
	}

	public static bool TryFindWaterCellThroughDam(Vector3 tapPos, Vector3 dir, out Cell waterCell)
	{
		waterCell = null;
		if (dir.sqrMagnitude < 0.5f)
		{
			return false;
		}
		Vector3 worldPos = tapPos + dir * 0.5f;
		for (int i = 0; i < 1; i++)
		{
			worldPos += dir;
			Cell cellDataClamped = World.inst.GetCellDataClamped(worldPos);
			if (cellDataClamped == null)
			{
				return false;
			}
			if (!CellHasBuiltDamAt(cellDataClamped, tapPos.y))
			{
				waterCell = cellDataClamped;
				return true;
			}
		}
		return false;
	}

	public static (int centre, int lateral) DamIntakeMeshIndices(Vector3 dirIntoWall, Cell waterCell)
	{
		int num = Mathf.RoundToInt(dirIntoWall.x);
		int num2 = Mathf.RoundToInt(dirIntoWall.z);
		return (centre: DynamicWater.MapIndexWorldToMesh(waterCell.index, World.inst.GridWidth) - num - num2 * World.MeshWidth, lateral: num2 - num * World.MeshWidth);
	}

	public static float DamIntakeCapacityHuman(Vector3 tapPos, Vector3 dirIntoWall, Cell waterCell)
	{
		(int centre, int lateral) tuple = DamIntakeMeshIndices(dirIntoWall, waterCell);
		int item = tuple.centre;
		int item2 = tuple.lateral;
		float altitude = tapPos.y - DynamicWater.inst.WaterMeshExtraHeight;
		float num = 0f;
		for (int i = -1; i <= 1; i++)
		{
			num += DynamicWater.inst.SampleWaterAvailable(item + i * item2, altitude);
		}
		return Mathf.Round(AqueductBuilding.SystemToHuman(Mathff.Min(AqueductBuilding.MAX_WATER_FLOW, num)));
	}

	public static bool CellHasBuiltDamAt(Cell cell, float y, Building except = null)
	{
		if (cell == null)
		{
			return false;
		}
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			Building building = cell.OccupyingStructure[i];
			if (!(building == null) && !(building == except) && building.uniqueNameHash == World.damHash && building.IsBuilt())
			{
				float y2 = building.cachedPos.y;
				float num = y2 + (float)building.StackHeight * 0.25f;
				if (y >= y2 - 0.01f && y <= num + 0.01f)
				{
					return true;
				}
			}
		}
		return false;
	}

	public static void OnDamBlockChanged(Cell cell, Building dying)
	{
		if (LoadSave.Loading || cell == null)
		{
			return;
		}
		for (int num = allRiverTaps.Count - 1; num >= 0; num--)
		{
			RiverTap riverTap = allRiverTaps[num];
			if (!(riverTap == null) && riverTap.damMounted)
			{
				if (World.inst.GetCellDataClamped(riverTap.transform.position + riverTap.mountDir * 0.5f) == cell && !CellHasBuiltDamAt(cell, riverTap.transform.position.y, dying))
				{
					UnityEngine.Object.Destroy(riverTap.gameObject);
				}
				else
				{
					riverTap.lastExtractionMeshIndex = int.MinValue;
				}
			}
		}
	}

	public void UpdateDrawPoints()
	{
		int num = 0;
		int num2;
		if (damMounted)
		{
			if (!TryFindWaterCellThroughDam(transform.position, mountDir, out var waterCell))
			{
				waterCell = World.inst.GetCellDataClamped(transform.position + mountDir * 1.5f);
			}
			(num2, num) = DamIntakeMeshIndices(mountDir, waterCell);
		}
		else
		{
			num2 = Mathf.RoundToInt(transform.position.x * 2f) + Mathf.RoundToInt(transform.position.z * 2f) * World.MeshWidth;
		}
		if (waterExtractionRequest != null && num2 == lastExtractionMeshIndex && transform.position == lastExtractionPos)
		{
			return;
		}
		if (waterExtractionRequest != null)
		{
			DynamicWater.inst.RemoveWaterExtractionRequest(waterExtractionRequest);
			waterExtractionRequest = null;
		}
		lastExtractionMeshIndex = num2;
		lastExtractionPos = transform.position;
		damTubesDirty = true;
		ExtractionPoints.Clear();
		if (damMounted)
		{
			for (int i = -1; i <= 1; i++)
			{
				DynamicWater.WaterExtractionRequest.ExtractionPoint extractionPoint = new DynamicWater.WaterExtractionRequest.ExtractionPoint();
				extractionPoint.index = num2 + i * num;
				extractionPoint.altitude = transform.position.y - DynamicWater.inst.WaterMeshExtraHeight;
				ExtractionPoints.Add(extractionPoint);
			}
		}
		else
		{
			int[] array = new int[9]
			{
				-1 - World.MeshWidth,
				-World.MeshWidth,
				1 - World.MeshWidth,
				1,
				0,
				1 + World.MeshWidth,
				World.MeshWidth,
				-1 + World.MeshWidth,
				-1
			};
			for (int j = 0; j < array.Length; j++)
			{
				DynamicWater.WaterExtractionRequest.ExtractionPoint extractionPoint2 = new DynamicWater.WaterExtractionRequest.ExtractionPoint();
				extractionPoint2.index = num2 + array[j];
				extractionPoint2.altitude = transform.position.y - DynamicWater.inst.WaterMeshExtraHeight;
				ExtractionPoints.Add(extractionPoint2);
			}
		}
		waterExtractionRequest = DynamicWater.inst.AddWaterExtractionRequest(ExtractionPoints.ToArray(), OnExtractionComplete);
		waterExtractionRequest.perStepBudget = perStepBudgetSys;
	}

	public void OnExtractionComplete(float extractedSys, float availableSys, int steps)
	{
		if (!open)
		{
			waterExtractedThisFrame = 0f;
			perStepBudgetSys = 0f;
			if (waterExtractionRequest != null)
			{
				waterExtractionRequest.perStepBudget = 0f;
			}
			errorNoWaterExtractedThisFrame = false;
			thought.visible = false;
			return;
		}
		float num = (lastPhysCap = Mathff.Min(AqueductBuilding.MAX_WATER_FLOW * maxNeed, availableSys));
		float num2 = Mathf.Round(AqueductBuilding.SystemToHuman(perStepBudgetSys));
		if (num2 != lastBatchBudgetHuman)
		{
			lastBatchBudgetHuman = num2;
			ResetAveragingWindow();
			forceBudgetPublish = true;
		}
		waterExtractedThisFrame = extractedSys / (float)Mathf.Max(1, steps);
		WaterFlowDiagnostics.ReportRemoved(this, AqueductBuilding.SystemToHuman(waterExtractedThisFrame));
		float sourceExtraction = AqueductFlowController.GetSourceExtraction(this);
		if (!HasNetworkedLine())
		{
			perStepBudgetSys = 0f;
		}
		else
		{
			perStepBudgetSys = (float.IsInfinity(sourceExtraction) ? (AqueductBuilding.MAX_WATER_FLOW * maxNeed) : Mathff.Min(AqueductBuilding.MAX_WATER_FLOW * maxNeed, AqueductBuilding.HumanToSystem(sourceExtraction)));
		}
		if (waterExtractionRequest != null)
		{
			waterExtractionRequest.perStepBudget = perStepBudgetSys;
		}
		errorNoWaterExtractedThisFrame = num <= 0f;
		if (errorNoWaterExtractedThisFrame)
		{
			updateNeeded = true;
			thought.thought = ThoughtBubbleSystem.Thought.WaterCritical;
			thought.visible = true;
		}
		else
		{
			accumulatedWater += waterExtractedThisFrame;
			accumulatedCapacity += num;
			waterExtractionCount++;
			thought.visible = false;
		}
	}

	public override float SourceCapacity()
	{
		if (!open)
		{
			return 0f;
		}
		return physicalCapacity;
	}

	public void SeedCapacityFromWorld()
	{
		UpdateDrawPoints();
		float num = 0f;
		for (int i = 0; i < ExtractionPoints.Count; i++)
		{
			num += DynamicWater.inst.SampleWaterAvailable(ExtractionPoints[i].index, ExtractionPoints[i].altitude);
		}
		physicalCapacity = Mathf.Round(AqueductBuilding.SystemToHuman(lastPhysCap = Mathff.Min(AqueductBuilding.MAX_WATER_FLOW * maxNeed, num)));
	}

	public string GetError()
	{
		if (errorNoWaterExtractedThisFrame)
		{
			return ScriptLocalization.WaterTapNeedRaiseLevels;
		}
		return string.Empty;
	}

	public override int GetLandMass()
	{
		return World.inst.GetCellDataClamped(transform.position).landMassIdx;
	}

	public void SetOutlineImmediate(int i)
	{
		highlight?.SetOutlineImmediate(i);
	}

	public int LandMass()
	{
		return GetLandMass();
	}

	public int TeamID()
	{
		return World.GetLandmassOwner(GetLandMass()).teamId;
	}

	public bool CanDemolishBuilding()
	{
		return true;
	}

	public void DemolishBuilding()
	{
		for (int num = aqueductLines.Count - 1; num >= 0; num--)
		{
			aqueductLines[num].DestroySelf();
		}
	}

	public void PlaySelectSound()
	{
	}

	public bool UnderConstruction()
	{
		return false;
	}

	public bool ConstructionPaused()
	{
		return false;
	}

	public void PauseConstruction()
	{
	}

	public void UnpauseConstruction()
	{
	}

	public void GetConstructionSummary(ref ConstructionForeman.ConstructionSummary summary)
	{
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
		return 0;
	}

	public override Vector3 Center()
	{
		return transform.position;
	}

	public static bool IsTooCloseToExistingTap(Vector3 position, RiverTap excludeTap = null)
	{
		float num = 1f;
		for (int i = 0; i < allRiverTaps.Count; i++)
		{
			RiverTap riverTap = allRiverTaps[i];
			if (!(riverTap == null) && !(riverTap == excludeTap) && (riverTap.transform.position - position).sqrMagnitude < num)
			{
				return true;
			}
		}
		return false;
	}

	public static bool AnyTapMountedOnCell(Cell cell)
	{
		for (int i = 0; i < allRiverTaps.Count; i++)
		{
			RiverTap riverTap = allRiverTaps[i];
			if (!(riverTap == null) && riverTap.damMounted && World.inst.GetCellDataClamped(riverTap.transform.position + riverTap.mountDir * 0.5f) == cell)
			{
				return true;
			}
		}
		return false;
	}

	private void RegisterTap()
	{
		if (!allRiverTaps.Contains(this))
		{
			allRiverTaps.Add(this);
		}
	}

	private void UnregisterTap()
	{
		allRiverTaps.Remove(this);
	}

	public int CategoryHash()
	{
		return categoryHash;
	}

	public int UniqueNameHash()
	{
		return uniqueHash;
	}

	public bool IsOpen()
	{
		return open;
	}

	public void SetOpen(bool on)
	{
		if (open == on)
		{
			return;
		}
		open = on;
		if (!on)
		{
			perStepBudgetSys = 0f;
			if (waterExtractionRequest != null)
			{
				waterExtractionRequest.perStepBudget = 0f;
			}
			waterExtractedThisFrame = 0f;
			ResetAveragingWindow();
		}
		else
		{
			perStepBudgetSys = AqueductBuilding.MAX_WATER_FLOW * maxNeed;
			SeedCapacityFromWorld();
		}
		updateNeeded = true;
		AqueductFlowController.MarkDemandDirty("SetOpen");
	}

	public override void OnDestroy()
	{
		UnregisterTap();
		if (waterExtractionRequest != null)
		{
			DynamicWater.inst.RemoveWaterExtractionRequest(waterExtractionRequest);
			waterExtractionRequest = null;
		}
		if (thought != null)
		{
			ThoughtBubbleSystem.inst.RemoveThoughtBubble(ref thought);
			thought = null;
		}
		if (highlight != null)
		{
			highlight.Release();
		}
		base.OnDestroy();
	}

	public void DrawOutline(CommandBuffer commandBuffer, Material highlightMaterial)
	{
		if (damMounted)
		{
			EnsureDamVisual();
			UpdateIntakeTubeMatrices();
			for (int i = 0; i < damIntakeTubeCount; i++)
			{
				commandBuffer.DrawMesh(damElbowMesh, damIntakeTubeMatrices[i], highlightMaterial);
			}
		}
		else
		{
			commandBuffer.DrawMesh(buildingMesh, transform.localToWorldMatrix, highlightMaterial);
			if (supportMatrices != null && supportMatrices.Length != 0)
			{
				commandBuffer.DrawMeshInstanced(supportMesh, 0, highlightMaterial, 0, supportMatrices);
			}
		}
	}

	public bool ShowOpenClose()
	{
		return true;
	}

	public bool ShowDemolish()
	{
		return true;
	}
}
