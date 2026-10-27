using System;
using System.Runtime.Serialization;
using UnityEngine;

public class Cemetery : Tickable, IWorkerUIDisplay, IOutputInfo
{
	[Serializable]
	public class GraveDataSave
	{
		public bool occupied;

		public float timeStanding;

		public GraveData.QualityState qualityState;

		public string personName;

		public float personAge;
	}

	[Serializable]
	public class CemeterySaveData : SaveClass<Cemetery, CemeterySaveData>
	{
		private GraveDataSave[] savedGraveData;

		[OptionalField(VersionAdded = 2)]
		public SerializableVector3[] gravePoss;

		[OptionalField(VersionAdded = 2)]
		public SerializableQuaternion[] graveRots;

		public override CemeterySaveData Pack(Cemetery obj)
		{
			savedGraveData = new GraveDataSave[obj.gravesData.Length];
			for (int i = 0; i < obj.gravesData.Length; i++)
			{
				savedGraveData[i] = new GraveDataSave
				{
					occupied = obj.gravesData[i].occupied,
					timeStanding = obj.gravesData[i].timeStanding,
					qualityState = obj.gravesData[i].qualityState,
					personName = obj.gravesData[i].personName,
					personAge = obj.gravesData[i].personAge
				};
			}
			gravePoss = new SerializableVector3[obj.gravesRenderInstance.Length];
			graveRots = new SerializableQuaternion[obj.gravesRenderInstance.Length];
			for (int j = 0; j < obj.gravesRenderInstance.Length; j++)
			{
				gravePoss[j] = obj.gravesRenderInstance[j].GetMatrix().MultiplyPoint(Vector3.zero);
				graveRots[j] = obj.gravesRenderInstance[j].GetMatrix().rotation;
			}
			return this;
		}

		public override Cemetery Unpack(Cemetery obj)
		{
			for (int i = 0; i < savedGraveData.Length && i < obj.gravesData.Length; i++)
			{
				obj.gravesData[i].occupied = savedGraveData[i].occupied;
				obj.gravesData[i].qualityState = savedGraveData[i].qualityState;
				obj.gravesData[i].timeStanding = savedGraveData[i].timeStanding;
				obj.gravesData[i].personName = savedGraveData[i].personName;
				obj.gravesData[i].personAge = savedGraveData[i].personAge;
				obj.gravesRenderInstance[i].Visible = obj.gravesData[i].occupied;
			}
			if (gravePoss != null)
			{
				for (int j = 0; j < obj.gravesRenderInstance.Length; j++)
				{
					obj.gravesRenderInstance[j].UpdateTRS(gravePoss[j], graveRots[j], new Vector3(1f, 1f, 1f));
				}
			}
			obj.openGraves = obj.GetOpenGraves();
			return obj;
		}
	}

	public Building b;

	public AdjacentMesh adjMesh;

	private const int GraveAgeMaxYear = 3;

	private RenderInstance[] gravesRenderInstance;

	private GraveData[] gravesData;

	public Material GraveMaterial;

	public Mesh[] GraveMeshes;

	public Transform[] graveOffsets;

	public GameObject roof;

	private Transform curr;

	private Timer updateInterval;

	private int openGraves;

	public float terrainDrop = 0.5f;

	private CullingGroup cullingGroup;

	private BoundingSphere[] spheres = new BoundingSphere[1];

	private bool inFrustum;

	private static ArrayExt<Cemetery>[] cemeteries;

	private static ArrayExt<Cemetery> emptyCemeteryList = new ArrayExt<Cemetery>(1);

	public bool isColumbarium;

	public int GetMaxGraveCount()
	{
		return gravesData.Length;
	}

	public int GetUsedGraveCount()
	{
		return gravesData.Length - openGraves;
	}

	private void Awake()
	{
		b = GetComponent<Building>();
		adjMesh = GetComponent<AdjacentMesh>();
		if ((bool)adjMesh)
		{
			adjMesh.shouldConnect = ShouldConnect;
		}
		if ((bool)roof)
		{
			roof.gameObject.SetActive(value: true);
		}
	}

	private bool ShouldConnect(Cell c)
	{
		if (c == null)
		{
			return false;
		}
		for (int i = 0; i < c.OccupyingStructure.Count; i++)
		{
			if (c.OccupyingStructure[i].categoryHash == b.categoryHash || c.OccupyingStructure[i].categoryHash == World.cemeteryKeeperHash)
			{
				return true;
			}
		}
		return false;
	}

	public void OnSelectionChanged()
	{
		if ((bool)roof)
		{
			if (GameUI.inst.GetBuildingSelected() == b)
			{
				roof.SetActive(value: false);
			}
			else
			{
				roof.SetActive(b.IsBuilt());
			}
		}
	}

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

	string IOutputInfo.GetError()
	{
		return string.Empty;
	}

	private void OnInit()
	{
		updateInterval = new Timer(30f);
		updateInterval.CurrTime = 30.Random0toN();
		SetupGraves();
	}

	public override void Tick(float dt, int currFrame)
	{
		UpdateGraveVisibility();
		if (updateInterval == null || !updateInterval.Update(dt))
		{
			return;
		}
		for (int i = 0; i < gravesData.Length; i++)
		{
			if (gravesData[i].occupied)
			{
				gravesData[i].timeStanding += updateInterval.Duration;
				if (gravesData[i].timeStanding / SeasonManager.inst.TimeInYear() >= 3f)
				{
					gravesRenderInstance[i].Visible = false;
					gravesData[i].occupied = false;
					openGraves++;
				}
			}
		}
	}

	public void UpdateGraveVisibility()
	{
		bool visible = b.IsVisibleForFog() && inFrustum;
		for (int i = 0; i < gravesData.Length; i++)
		{
			if (gravesData[i].occupied)
			{
				gravesRenderInstance[i].Visible = visible;
			}
		}
	}

	public void LateUpdate()
	{
		if (!b.IsPlaced())
		{
			for (int i = 0; i < graveOffsets.Length; i++)
			{
				gravesRenderInstance[i].UpdateTRS(graveOffsets[i].position, graveOffsets[i].rotation, Vector3.one);
				gravesRenderInstance[i].Visible = true;
			}
		}
	}

	private void OnBuilt()
	{
		if (isColumbarium)
		{
			TerrainGen.inst.MakeSquareDepression((int)b.transform.position.x, (int)b.transform.position.z, 1, 1, 1, terrainDrop);
		}
		if ((bool)roof)
		{
			roof.SetActive(value: true);
		}
	}

	private void OnBuildingPlacement(bool undo)
	{
		if (!undo)
		{
			cullingGroup = new CullingGroup();
			cullingGroup.onStateChanged = StateChangedMethod;
			cullingGroup.SetBoundingSpheres(spheres);
			cullingGroup.SetBoundingSphereCount(1);
			cullingGroup.targetCamera = Cam.inst.cam;
			spheres[0] = new BoundingSphere(b.Center(), 2f);
		}
		for (int i = 0; i < graveOffsets.Length; i++)
		{
			Vector3 pos = graveOffsets[i].position;
			TerrainGen.inst.GetGroundHeight(ref pos);
			gravesRenderInstance[i].UpdateTRS(pos, graveOffsets[i].rotation, Vector3.one);
			gravesRenderInstance[i].Visible = false;
		}
		if (!undo)
		{
			cemeteries[b.LandMass()].Add(this);
		}
		else
		{
			cemeteries[b.LandMass()].RemoveSwap(this);
		}
		if ((bool)roof && !b.IsBuilt())
		{
			roof.SetActive(value: false);
		}
	}

	public void StateChangedMethod(CullingGroupEvent evt)
	{
		if (evt.hasBecomeVisible)
		{
			inFrustum = true;
		}
		if (evt.hasBecomeInvisible)
		{
			inFrustum = false;
		}
	}

	private void SetupGraves()
	{
		gravesRenderInstance = new RenderInstance[graveOffsets.Length];
		gravesData = new GraveData[graveOffsets.Length];
		for (int i = 0; i < graveOffsets.Length; i++)
		{
			gravesData[i] = new GraveData
			{
				occupied = false
			};
			gravesRenderInstance[i] = new RenderInstance(GraveMeshes[GraveMeshes.Length.Random0toN()], GraveMaterial);
			gravesRenderInstance[i].UpdateTRS(graveOffsets[i].position, graveOffsets[i].rotation, Vector3.one);
			gravesRenderInstance[i].Visible = false;
			gravesRenderInstance[i].castShadows = false;
		}
		openGraves = gravesData.Length;
	}

	public void OnDestroy()
	{
		if (cullingGroup != null)
		{
			cullingGroup.Dispose();
			cullingGroup = null;
		}
	}

	private void OnShutdown()
	{
		if (gravesRenderInstance != null)
		{
			for (int i = 0; i < gravesRenderInstance.Length; i++)
			{
				gravesRenderInstance[i].Visible = false;
			}
		}
	}

	public int GetOpenGraves()
	{
		int num = 0;
		for (int i = 0; i < gravesData.Length; i++)
		{
			if (!gravesData[i].occupied)
			{
				num++;
			}
		}
		return num;
	}

	public bool BuryPerson(DeadVillager person)
	{
		for (int i = 0; i < gravesData.Length; i++)
		{
			if (!gravesData[i].occupied)
			{
				gravesData[i].occupied = true;
				gravesData[i].timeStanding = 0f;
				gravesData[i].personName = person.name;
				gravesData[i].personAge = person.timeAlive;
				gravesData[i].qualityState = GraveData.QualityState.Good;
				gravesRenderInstance[i].Visible = true;
				openGraves--;
				return true;
			}
		}
		return false;
	}

	public static ArrayExt<Cemetery> CemeteriesForLandMass(int landMass)
	{
		if (landMass != -1)
		{
			return cemeteries[landMass];
		}
		return emptyCemeteryList;
	}

	public static void ResetCemeteries()
	{
		cemeteries = new ArrayExt<Cemetery>[World.inst.NumLandMasses];
		for (int i = 0; i < cemeteries.Length; i++)
		{
			cemeteries[i] = new ArrayExt<Cemetery>(10);
		}
	}

	public static bool IsCemetery(int x, int z)
	{
		return World.inst.GetCellData(x, z).StructureFindByCategory(World.cemeteryHash) != null;
	}

	public int GravesAvailable()
	{
		return openGraves;
	}

	public Vector3 FirstOpenGravePosition()
	{
		for (int i = 0; i < gravesData.Length; i++)
		{
			if (!gravesData[i].occupied)
			{
				return graveOffsets[i].position;
			}
		}
		return Vector3.zero;
	}
}
