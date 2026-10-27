using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using System.Runtime.Serialization;
using Assets;
using Assets.Code;
using Assets.Code.Interface;
using Code;
using FMOD;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using UnityEngine;

public class Building : MonoBehaviour, IEmployer, IMoveTarget, IProjectileHitable, IConstructionMaster, ISelectableBuilding
{
	public enum HighlightType
	{
		None,
		Name,
		Category
	}

	public enum DragPlacementMode
	{
		None,
		Path,
		Rectangle,
		Line,
		LineFillDown
	}

	[Serializable]
	public class SnapPoints
	{
		public Transform[] xform;
	}

	public delegate void OnJobAssignmentUpdated(Villager v, bool isAssigned);

	public delegate void VisibilityChanged(bool v);

	public delegate void EvaluateCell(int x, int z, Cell cell);

	public delegate void EvaluateCellWithIndex(int x, int z, Cell cell, int index);

	public enum PlacementBehavior
	{
		None,
		Foundation,
		Align,
		Flatten,
		FlattenWithNeighbors,
		FoundationEdge,
		FlattenWithNeighborsMaxHeight,
		AlignWithNeighbors,
		Average
	}

	public delegate void CanPlace(ref PlacementValidationResult result);

	public enum OverlayType
	{
		None,
		Integrity
	}

	public enum CastleBlockType
	{
		None,
		Wood,
		Stone,
		Any
	}

	[Serializable]
	public class BuildingSaveData : SaveClass<Building, BuildingSaveData>
	{
		public Guid guid;

		public string uniqueName;

		public SerializableVector3 globalPosition;

		public SerializableVector3 localPosition;

		public SerializableQuaternion rotation;

		public ResourceAmount CollectForBuild;

		public bool built;

		public bool placed;

		public bool open;

		public bool doBuildAnimation = true;

		public bool constructionPaused;

		public float constructionProgress;

		public float life;

		public float ModifiedMaxLife;

		public int yearBuilt = -1;

		public float decayProtection;

		public bool isDemolishing;

		[OptionalField(VersionAdded = 3)]
		public bool seenByPlayer;

		public List<object> components = new List<object>();

		public List<object> jobs = new List<object>();

		[OptionalField(VersionAdded = 2)]
		public string customName;

		[OptionalField(VersionAdded = 4)]
		public ConstructionForeman.ConstructionForemanSaveData foremanSaveData;

		[OptionalField(VersionAdded = 5)]
		public int meshVariant;

		[OptionalField(VersionAdded = 6)]
		public bool ignoreForObstructionAndLayout;

		[OptionalField(VersionAdded = 7)]
		public int[] terrainVertexIndices;

		[OptionalField(VersionAdded = 7)]
		public float[] terrainOriginalHeights;

		[OnDeserializing]
		internal void OnDeserializingMethod(StreamingContext context)
		{
			meshVariant = -1;
		}

		private static Type[] GetComponentSaveTypes(Type type)
		{
			if (World.inst.buildingTypeMap.TryGetValue(type, out var value))
			{
				return value;
			}
			List<Type> list = new List<Type>();
			Type type2 = type;
			while (type2 != null && type2 != typeof(Building) && type2 != typeof(MonoBehaviour))
			{
				Type[] nestedTypes = type2.GetNestedTypes();
				for (int i = 0; i < nestedTypes.Length; i++)
				{
					if (Util.IsSubclassOfSaveClass(nestedTypes[i]))
					{
						list.Add(nestedTypes[i]);
					}
				}
				type2 = type2.BaseType;
			}
			value = list.ToArray();
			World.inst.buildingTypeMap.Add(type, value);
			return value;
		}

		private static void PackComponentSaveData(Component comp, List<object> into)
		{
			Type type = comp.GetType();
			if (!(type == typeof(Building)))
			{
				Type[] componentSaveTypes = GetComponentSaveTypes(type);
				foreach (Type obj in componentSaveTypes)
				{
					object arg = Util.CreateInstance(obj);
					object data = Util.GetPackMethod(obj)(arg, new object[1] { comp });
					into.Add(new SaveEntry
					{
						key = type.Name,
						data = data
					});
				}
			}
		}

		public static List<object> PackComponents(Building b, Func<Component, bool> filter = null)
		{
			List<object> list = null;
			scratchComponents.Clear();
			b.GetComponents(scratchComponents);
			for (int i = 0; i < scratchComponents.Count; i++)
			{
				if (filter == null || filter(scratchComponents[i]))
				{
					if (list == null)
					{
						list = new List<object>();
					}
					PackComponentSaveData(scratchComponents[i], list);
				}
			}
			scratchComponents.Clear();
			return list;
		}

		public static void ApplyComponentSaveData(Building b, List<object> components)
		{
			if (components == null)
			{
				return;
			}
			object[] array = new object[1];
			for (int i = 0; i < components.Count; i++)
			{
				object obj;
				if (components[i] is SaveEntry saveEntry)
				{
					if (saveEntry.data == null)
					{
						UnityEngine.Debug.LogWarning("Skipping component '" + saveEntry.key + "' — type not found (mod removed?)");
						continue;
					}
					obj = saveEntry.data;
				}
				else
				{
					obj = components[i];
					if (obj == null)
					{
						UnityEngine.Debug.LogWarning("Skipping null component in legacy save");
						continue;
					}
				}
				Type type = obj.GetType();
				Type declaringType = type.DeclaringType;
				if (!(declaringType == null))
				{
					array[0] = b.GetComponent(declaringType);
					if (array[0] != null)
					{
						Util.GetUnpackMethod(type)(obj, array);
					}
				}
			}
		}

		public override BuildingSaveData Pack(Building b)
		{
			customName = b.customName;
			components = PackComponents(b);
			jobs = Job.PackJobList(b.jobs);
			guid = b.guid;
			uniqueName = b.UniqueName;
			globalPosition = b.xform.position;
			Transform cachedChildTransform = b.cachedChildTransform;
			rotation = cachedChildTransform.rotation;
			localPosition = cachedChildTransform.localPosition;
			built = b.built;
			placed = b.placed;
			open = b.open;
			doBuildAnimation = b.doBuildAnimation;
			life = b.Life;
			ModifiedMaxLife = b.ModifiedMaxLife;
			yearBuilt = b.yearBuilt;
			decayProtection = b.decayProtection;
			seenByPlayer = b.seenByPlayer;
			meshVariant = b.selectedVariant;
			ignoreForObstructionAndLayout = b.ignoreForLayout;
			foremanSaveData = new ConstructionForeman.ConstructionForemanSaveData().Pack(b.ConstructionForeman);
			if (b.terrainVertexIndices != null && b.terrainVertexIndices.Length != 0)
			{
				terrainVertexIndices = (int[])b.terrainVertexIndices.Clone();
				terrainOriginalHeights = (float[])b.terrainOriginalHeights.Clone();
			}
			return this;
		}

		public override Building Unpack(Building b)
		{
			b.customName = customName;
			b.guid = guid;
			b.transform.position = globalPosition;
			b.transform.GetChild(0).rotation = rotation;
			b.transform.GetChild(0).localPosition = localPosition;
			b.RefreshCachedValues();
			if (meshVariant == -1)
			{
				if (b.variants != null && b.variants.Length != 0)
				{
					b.SetVariant(SRand.Range(0, b.variants.Length));
				}
			}
			else
			{
				b.SetVariant(meshVariant);
			}
			b.built = built;
			b.placed = placed;
			b.Open = open;
			b.doBuildAnimation = doBuildAnimation;
			b.Life = life;
			if (ModifiedMaxLife == 0f)
			{
				ModifiedMaxLife = b.MaxLife;
			}
			b.ModifiedMaxLife = ModifiedMaxLife;
			b.seenByPlayer = seenByPlayer;
			if (yearBuilt <= 0)
			{
				b.yearBuilt = SRand.Range(0, SeasonManager.inst.CurrentYear());
			}
			else
			{
				b.yearBuilt = yearBuilt;
			}
			b.decayProtection = decayProtection;
			if (b.Life < b.ModifiedMaxLife)
			{
				b.TryAddToDamagedList();
			}
			b.ignoreForLayout = ignoreForObstructionAndLayout;
			if (terrainVertexIndices != null && terrainVertexIndices.Length != 0)
			{
				b.terrainVertexIndices = (int[])terrainVertexIndices.Clone();
				b.terrainOriginalHeights = (float[])terrainOriginalHeights.Clone();
			}
			return b;
		}

		private void AddJob(Building b, Job j)
		{
			JobSystem.inst.AddNewJob(j);
			b.jobs.Add(j);
		}

		private void AddJob(Building b, Job j, int jobCategory)
		{
			JobSystem.inst.AddNewJob(j, jobCategory);
			b.jobs.Add(j);
		}

		public Building UnpackStage2(Building b)
		{
			ApplyComponentSaveData(b, components);
			Job.UnpackJobList(jobs, b, b.jobs);
			if (foremanSaveData != null)
			{
				foremanSaveData.Unpack(b.ConstructionForeman);
			}
			if (built)
			{
				b.KillEffects();
				b.AddAllResourceProviders();
				b.StartAmbience();
				while (b.WorkersForFullYield < b.jobs.Count)
				{
					JobSystem.inst.RemoveJob(b.jobs[0]);
					b.jobs.RemoveAt(0);
				}
			}
			else if (b.ConstructionForeman.ConstructionPaused)
			{
				b.KillEffects();
			}
			for (int i = 0; i < b.fullMaterial.Count; i++)
			{
				b.fullMaterial[i].SetFloat("_WallProgress", Mathf.Clamp(b.ConstructionForeman.ConstructionProgress, 0.2f, 1f));
			}
			b.SendMessage("OnFinishedLoad", SendMessageOptions.DontRequireReceiver);
			if (built)
			{
				b.TryAddJobs();
			}
			b.UpdateMaterialSelection();
			return b;
		}
	}

	public Guid guid;

	public Sprite sprite;

	public bool disableEditorTerm;

	public int jobCategory;

	public EventReference onBuildingCompleteEvent;

	public EventReference onBuildingSelectEvent;

	public EventReference ambientEvent;

	public EventReference onBuildingPlacedEvent;

	public EventReference onBuildingDestroyedHeadEvent;

	public EventReference onBuildingDestroyedTailEvent;

	public string[] placementSounds;

	public string[] SelectionSounds;

	public string selectedAmbientSound;

	public string UniqueName = "<INSERT UNIQUE NAME>";

	[NonSerialized]
	public int uniqueNameHash;

	[NonSerialized]
	public string customName;

	public string CategoryName = "<INSERT CATEGORY, IF ANY>";

	[NonSerialized]
	public int categoryHash;

	public string buildingFriendlyNameLocalizationKey;

	private float hitCrackSpread = 2f;

	public ConstructionForeman ConstructionForeman = new ConstructionForeman();

	public List<bool> hasBakedPathingDataVariantsList = new List<bool>();

	public List<PathingGraphBaked> bakedLocalPathingDataVariantsList = new List<PathingGraphBaked>();

	[HideInInspector]
	public bool hasBakedPathingData;

	[HideInInspector]
	public PathingGraphBaked bakedPathingData;

	public bool clipUnderTerrain = true;

	public bool formToTerrain;

	public bool allowPlacementOnForum;

	public bool ignoreForLayout;

	public bool isPreviewBuilding;

	public bool transparent;

	public HighlightType highlightType;

	public bool revertLandOnDemolish;

	[NonSerialized]
	public int[] terrainVertexIndices;

	[NonSerialized]
	public float[] terrainOriginalHeights;

	private string descOverride;

	public string buildingDescriptionLocalizationKey;

	public string buildingThoughtOnBuiltLocalizationKey;

	public GameObject DisplayModel;

	public bool SubStructure;

	public string skillUsed = "";

	[NonSerialized]
	public int skillUsedHash;

	[NonSerialized]
	public bool seenByPlayer;

	public Vector3 size = new Vector3(1f, 1f, 1f);

	[SerializeField]
	private ResourceAmount Cost;

	private ResourceAmount empty = new ResourceAmount();

	public bool isFreeToBuild;

	private bool CollectResourcesAllowed = true;

	public bool Stackable;

	public int StackHeight;

	public float BuildShaderMinYAdjustment;

	public float BuildShaderMaxYAdjustment;

	public ObjectHighlighter highlight;

	public DynamicMesh dMesh;

	internal Transform xform;

	private float renderMinY;

	private float renderMaxY;

	private static List<Renderer> scratchRenderers = new List<Renderer>();

	public List<MeshRenderer> meshesRequiringOutline = new List<MeshRenderer>();

	public List<SkinnedMeshRenderer> skinnedMeshesRequiringOutline = new List<SkinnedMeshRenderer>();

	[NonSerialized]
	public bool destroyedWhileInPlay = true;

	private bool shutdown;

	public float workStartHour = 4f;

	public float workEndHour = 20f;

	public bool RotateOnlyToValid;

	public bool PerturbPersonPositions;

	public List<PersonPositionsVariant> personPositionsVariantsList = new List<PersonPositionsVariant>();

	public Transform[] attractionPositions;

	public Transform[] personPositions;

	public float builtTime = float.NegativeInfinity;

	private bool built;

	private bool placed;

	[NonSerialized]
	public List<Renderer> renderersWithBuildingShader = new List<Renderer>();

	[NonSerialized]
	public List<Material> fullMaterial = new List<Material>();

	[NonSerialized]
	private MaterialPropertyBlock propertyBlock;

	private bool open = true;

	public DragPlacementMode dragPlacementMode;

	public bool entireDragMustBeValid;

	public bool ignoreRoadCoverageForPlacement;

	public bool autoRotateToFaceRoad;

	public int maxPlacementAngle = -1;

	public bool showHappinessOverlay;

	public string snapBuildingTarget = "";

	public SnapPoints[] insideBuildingSnapPoints;

	public Transform[] snapInstances;

	[HideInInspector]
	public bool isDemolishing;

	private float percentForFirstDmgMat = 0.8f;

	public OnJobAssignmentUpdated onJobAssignmentUpdated;

	private int landmass = -1;

	private static readonly int MinHeightId = Shader.PropertyToID("_MinHeight");

	private static readonly int MinYAdjustmentId = Shader.PropertyToID("_MinYAdjustment");

	private static readonly int MaxHeightId = Shader.PropertyToID("_MaxHeight");

	private bool valid_material = true;

	private bool cachedVisibility = true;

	public bool doBuildAnimation = true;

	public bool doScaffoldingDuringConstruction = true;

	private int footprintMinX = -1;

	private int footprintMaxX = -1;

	private int footprintMinZ = -1;

	private int footprintMaxZ = -1;

	[NonSerialized]
	public Cell cachedCell;

	[NonSerialized]
	public Vector3 cachedPos;

	public PlacementBehavior placementBehavior;

	public int selectedVariant;

	public GameObject[] variants;

	public float RotateRandomY;

	private List<OneOffEffect> buildEffects = new List<OneOffEffect>(10);

	private OneOffEffect[] splashEffects;

	private EventInstance buildingSoundInstance;

	public float fireChance = 0.5f;

	public float BuildTimeAtMax = 5f;

	public int BuildAllowedWorkers = 5;

	public bool BuildersRequiredOnLocation;

	public int WorkersForFullYield = 1;

	[NonSerialized]
	public List<Job> jobs = new List<Job>();

	[NonSerialized]
	public List<Job> attractionJobs = new List<Job>();

	[NonSerialized]
	public int WorkersAllocated;

	private int lastFrameSkillCalculated = -1;

	private float avgSkill;

	public static List<Building> ConstructionList = new List<Building>();

	private float waterCheckTimer;

	private int consequetiveWaterHits;

	private int castleblockHash = "castleblock".GetHashCode();

	private int projectiletopperHash = "projectiletopper".GetHashCode();

	private int gateHash = "gate".GetHashCode();

	public CanPlace PlacementValidaton;

	private float oldConstructionProgress;

	private bool firstConstructionUpdate = true;

	private RenderInstance[] scaffolds;

	private Quaternion defaultRot = Quaternion.identity;

	private Vector3 defaultScale = Vector3.one;

	public bool CompletelyQuiet;

	private int yearBuilt;

	public float decayRate = 0.1f;

	public int decayChance = -1;

	public static int defaultDecayChance = 9;

	public float decayProtection;

	private static string BuildingDecayName = "Building Decay";

	private OverlayType overlayType;

	public bool removeTreesOnComplete = true;

	public bool removeRocksOnComplete = true;

	private GUID blankGuid = new GUID
	{
		Data1 = 0,
		Data2 = 0,
		Data3 = 0,
		Data4 = 0
	};

	public bool transportCartsCanTravelOn;

	public bool troopsCanWalkOn;

	public bool allowOverAndUnderAqueducts;

	public List<string> tierOfBuildingUniqueNames;

	public CastleBlockType allowCastleBlocksOnTop;

	internal int jobInitIdx;

	private List<OneOffEffect> upgradeFX = new List<OneOffEffect>();

	private Transform cachedChildTransform;

	public ThoughtBubbleSystem.ThoughtBubble thought;

	public float Life = 1f;

	public float ModifiedMaxLife = 1f;

	public float MaxLife = 1f;

	private Vector4 firstHit = Vector4.zero;

	private int flashCount;

	private float currFlashTime;

	private float flashTime;

	private static List<Building> damageFlashAnimator = new List<Building>();

	private float timeAtDamagedTaken;

	private bool inDamagedList;

	private bool inDamageFlashAnimator;

	private float timeAtPreviousFlash;

	public static float minTimeBetweenFlash = 0.5f;

	public bool TakesWaterDamage = true;

	private static List<Component> scratchComponents = new List<Component>();

	private float infoMode;

	private Color infoColor;

	internal EventInstance ambience;

	[HideInInspector]
	public string FriendlyName
	{
		get
		{
			if (string.IsNullOrEmpty(buildingFriendlyNameLocalizationKey))
			{
				GenerateLocalizationKeys();
			}
			return LocalizationManager.GetTranslation(buildingFriendlyNameLocalizationKey);
		}
	}

	[HideInInspector]
	public string GetFriendlyNameTerm
	{
		get
		{
			if (string.IsNullOrEmpty(buildingFriendlyNameLocalizationKey))
			{
				GenerateLocalizationKeys();
			}
			return buildingFriendlyNameLocalizationKey;
		}
	}

	[HideInInspector]
	public string Description
	{
		get
		{
			if (string.IsNullOrEmpty(buildingDescriptionLocalizationKey))
			{
				GenerateLocalizationKeys();
			}
			if (!string.IsNullOrEmpty(descOverride))
			{
				return descOverride;
			}
			return LocalizationManager.GetTranslation(buildingDescriptionLocalizationKey);
		}
		set
		{
			descOverride = value;
		}
	}

	[HideInInspector]
	public string ThoughtOnBuilt
	{
		get
		{
			if (string.IsNullOrEmpty(buildingThoughtOnBuiltLocalizationKey))
			{
				GenerateLocalizationKeys();
			}
			LanguageSourceData sourceContaining = LocalizationManager.GetSourceContaining(buildingThoughtOnBuiltLocalizationKey);
			TermData termData = LocalizationManager.GetTermData(buildingThoughtOnBuiltLocalizationKey);
			if (termData != null && sourceContaining != null && !string.IsNullOrEmpty(termData.GetTranslation(sourceContaining.GetLanguageIndex(LocalizationManager.CurrentLanguage))))
			{
				return LocalizationManager.GetTranslation(buildingThoughtOnBuiltLocalizationKey);
			}
			return "";
		}
	}

	public bool Open
	{
		get
		{
			return open;
		}
		set
		{
			if (IsBuilt() && value != open)
			{
				UpdateShaderHeight();
				Broadcast.BuildingOpenClose.Broadcast(this, new OnBuildingOpenClose
				{
					targetBuilding = this,
					open = value
				});
				open = value;
				for (int i = 0; i < fullMaterial.Count; i++)
				{
					fullMaterial[i].SetFloat("_Disabled", (!open) ? 1 : 0);
				}
				UpdateMaterialSelection();
			}
			_ = open;
		}
	}

	public bool Transparent
	{
		get
		{
			return transparent;
		}
		set
		{
			if (value != transparent)
			{
				transparent = value;
				for (int i = 0; i < fullMaterial.Count; i++)
				{
					fullMaterial[i].SetFloat("_Ethereal", transparent ? 1 : 0);
				}
				UpdateMaterialSelection();
			}
		}
	}

	public int YearBuilt => yearBuilt;

	public string CustomName
	{
		get
		{
			return customName;
		}
		set
		{
			customName = value;
		}
	}

	public event VisibilityChanged visibilityChanged;

	public ResourceAmount GetTrueCost(int clientIndex)
	{
		return GetCost(landmass);
	}

	public Transform GetOffset()
	{
		return transform.GetChild(0);
	}

	string IConstructionMaster.GetFriendlyName(int clientIndex)
	{
		return FriendlyName;
	}

	public float BuildTimeAtMaxStaff(int clientIndex)
	{
		return BuildTimeAtMax;
	}

	public bool AreWorkersNear(int num)
	{
		float num2 = 3.5f;
		int num3 = 0;
		for (int i = 0; i < jobs.Count; i++)
		{
			if (jobs[i].HasEmployee() && Mathff.DistSqrd(jobs[i].Employee.Pos, cachedPos) < num2)
			{
				num3++;
				if (num3 >= num)
				{
					return true;
				}
			}
		}
		return false;
	}

	public ResourceAmount GetCost(int landmass)
	{
		ResourceAmount amount = new ResourceAmount();
		return GetCost(landmass, ref amount);
	}

	public ResourceAmount GetCost(int landmass, ref ResourceAmount amount)
	{
		amount.Clear();
		if (isFreeToBuild)
		{
			return amount;
		}
		if (StreamerEffects.Flag_FreeBuilding)
		{
			return amount;
		}
		if (Creative.inst.IsCreativeOptionOn(0))
		{
			return amount;
		}
		if (World.inst.inFirstPlacementPhase && Player.inst.LandMassIsAPlayerLandMass(landmass) && UniqueName == World.dockName)
		{
			return amount;
		}
		amount.Add(in Cost);
		Governor.TraitInstance traitInstance = null;
		Governor governor = ((landmass != -1) ? Player.inst.governors[landmass] : null);
		if (governor != null)
		{
			traitInstance = governor.GetTrait(Traits.BuildCosts);
		}
		if (governor != null && traitInstance != null)
		{
			for (int i = 0; i < amount.resources.Count; i++)
			{
				float num = ((amount.resources[i].Amount > 0) ? Mathff.Max(1f, (float)amount.resources[i].Amount * traitInstance.magnitude) : 0f);
				if (num > 0f)
				{
					int num2 = amount.resources[i].Amount + (int)(traitInstance.negative ? num : (0f - num));
					amount.resources[i].Amount = (int)Mathff.Max(1f, num2);
				}
			}
		}
		if (StreamerEffects.Flag_BuildingCostsReduced)
		{
			amount *= 0.5f;
		}
		return amount;
	}

	public ResourceAmount GetBaseCost()
	{
		return new ResourceAmount(Cost);
	}

	public void DisableResourceCollection()
	{
		CollectResourcesAllowed = false;
	}

	public bool CanCollectResources()
	{
		return CollectResourcesAllowed;
	}

	public void SetUpHashes()
	{
		uniqueNameHash = UniqueName.GetHashCode();
		categoryHash = CategoryName.GetHashCode();
		skillUsedHash = skillUsed.GetHashCode();
	}

	public void Awake()
	{
		xform = transform;
		cachedChildTransform = transform.GetChild(0);
		if (!disableEditorTerm)
		{
			GenerateLocalizationKeys();
		}
	}

	public void GenerateLocalizationKeys()
	{
		buildingFriendlyNameLocalizationKey = $"Building {UniqueName} FriendlyName";
		buildingDescriptionLocalizationKey = $"Building {UniqueName} Description";
		buildingThoughtOnBuiltLocalizationKey = $"Building {UniqueName} ThoughtOnBuilt";
	}

	public void Init()
	{
		SetUpHashes();
		guid = Guid.NewGuid();
		Life = (ModifiedMaxLife = MaxLife);
		showHappinessOverlay = false;
		built = false;
		placed = false;
		open = true;
		firstHit = Vector4.zero;
		jobs.Clear();
		if (thought == null)
		{
			thought = ThoughtBubbleSystem.inst.AddThoughtBubble(Center());
		}
		thought.visible = false;
		thought.offset = new Vector3(0f, size.y * 0.5f, 0f);
		thought.scaleMod = 0.9f;
		ConstructionForeman.Init(this, BuildAllowedWorkers, 0);
		ConstructionForeman.ConstructionPaused = false;
		dMesh = GetComponent<DynamicMesh>();
		if (renderersWithBuildingShader.Count == 0)
		{
			transform.GetComponentsInChildren(includeInactive: true, scratchRenderers);
			for (int i = 0; i < scratchRenderers.Count; i++)
			{
				Renderer renderer = scratchRenderers[i];
				if (renderer.sharedMaterial != null && renderer.sharedMaterial.shader.name == "Custom/Building")
				{
					if (i == 0)
					{
						renderMinY = renderer.bounds.min.y;
						renderMaxY = renderer.bounds.max.y;
					}
					Material material = renderer.material;
					LandmassOwner landmassOwner = Player.inst.PlayerLandmassOwner;
					if (landmass != -1)
					{
						landmassOwner = World.GetLandmassOwner(landmass);
					}
					material = new Material(landmassOwner.BuildingMaterial);
					material.SetFloat("_Disabled", 0f);
					material.SetFloat("_Invalid", 0f);
					material.SetFloat("_WallProgress", 1f);
					material.SetFloat("_MinHeight", float.MinValue);
					material.SetFloat("_MaxHeight", float.MaxValue);
					material.SetVector("_BreakPoint", Vector4.zero);
					material.SetFloat("_MinYAdjustment", BuildShaderMinYAdjustment);
					material.SetFloat("_MaxYAdjustment", BuildShaderMaxYAdjustment);
					material.SetFloat("_Width", World.inst.GridWidth);
					material.SetFloat("_Height", World.inst.GridHeight);
					renderersWithBuildingShader.Add(renderer);
					fullMaterial.Add(material);
				}
			}
		}
		if (propertyBlock == null && renderersWithBuildingShader.Count > 0)
		{
			propertyBlock = new MaterialPropertyBlock();
			UpdateCrackOrigin(GetOffset().position);
		}
		UpdateMaterialSelection();
		if (variants != null && variants.Length != 0)
		{
			SetVariant(SRand.Range(0, variants.Length));
		}
		SendMessage("OnInit", SendMessageOptions.DontRequireReceiver);
		BroadcastMessage("EnableColliders", false, SendMessageOptions.DontRequireReceiver);
		if (!LoadSave.Loading)
		{
			SetupHighlight();
		}
	}

	public void SetupHighlight()
	{
		if (meshesRequiringOutline.Count == 0)
		{
			Transform child = transform.GetChild(0);
			for (int i = 0; i < child.childCount; i++)
			{
				Transform child2 = child.GetChild(i);
				if (variants != null && variants.Length != 0)
				{
					int num = 0;
					while (num < variants.Length)
					{
						if (!(variants[num] == child2.gameObject) || num == selectedVariant)
						{
							num++;
							continue;
						}
						goto IL_00bf;
					}
				}
				MeshRenderer component = child2.GetComponent<MeshRenderer>();
				if ((bool)component)
				{
					meshesRequiringOutline.Add(component);
				}
				SkinnedMeshRenderer component2 = child2.GetComponent<SkinnedMeshRenderer>();
				Cloth component3 = child2.GetComponent<Cloth>();
				if ((bool)component2 && component3 == null)
				{
					skinnedMeshesRequiringOutline.Add(component2);
				}
				IL_00bf:;
			}
		}
		highlight = ObjectHighlighter.SetupOutlines(gameObject, meshesRequiringOutline, skinnedMeshesRequiringOutline, formToTerrain, clipUnderTerrain);
	}

	public void SetVariant(int variant)
	{
		if (variants != null && variants.Length != 0)
		{
			for (int i = 0; i < variants.Length; i++)
			{
				variants[i].gameObject.SetActive(value: false);
			}
			selectedVariant = variant;
			variants[selectedVariant].gameObject.SetActive(value: true);
		}
	}

	public void OnDisable()
	{
		BroadcastMessage("EnableColliders", false, SendMessageOptions.DontRequireReceiver);
		if (!shutdown)
		{
			Shutdown();
		}
	}

	public void Shutdown()
	{
		if (shutdown)
		{
			UnityEngine.Debug.LogError("Is trying to shutdown multiple times?");
			return;
		}
		shutdown = true;
		if (highlight != null)
		{
			highlight.Release();
		}
		Player.inst.buildingDamageAnimator.CleanUp(transform.GetChild(0));
		if (inDamageFlashAnimator)
		{
			damageFlashAnimator.Remove(this);
		}
		inDamageFlashAnimator = false;
		SendMessage("OnShutdown", SendMessageOptions.DontRequireReceiver);
		IResourceProvider[] components = GetComponents<IResourceProvider>();
		if (built)
		{
			for (int i = 0; i < components.Length; i++)
			{
				FreeResourceManager.inst.RemoveResourceProvider(components[i]);
			}
			if (GetComponent<IResourceProviderContainer>() != null)
			{
				GetComponent<IResourceProviderContainer>().RemoveResourceProvider();
			}
		}
		if (destroyedWhileInPlay)
		{
			RevertTerrainIfLastBuildingInCells();
			for (int j = 0; j < jobs.Count; j++)
			{
				JobSystem.inst.RemoveJob(jobs[j]);
			}
			for (int k = 0; k < attractionJobs.Count; k++)
			{
				JobSystem.inst.RemoveJob(attractionJobs[k]);
			}
			ConstructionForeman.RemoveJobs();
		}
		jobs.Clear();
		if (!IsBuilt() && doBuildAnimation)
		{
			ConstructionList.Remove(this);
		}
		TryRemoveFromDamagedList();
		KillEffects();
		if (ambience.isValid() && ambience.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
		{
			ambience.stop(STOP_MODE.IMMEDIATE);
		}
	}

	private void TryRemoveFromDamagedList()
	{
		if (Player.inst.DamagedList != null && landmass != -1)
		{
			Player.inst.DamagedList[landmass].Remove(this);
		}
		inDamagedList = false;
	}

	public void CaptureTerrainForRevert()
	{
		GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		Dictionary<int, float> dictionary = new Dictionary<int, float>();
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				int num = j * 2 + 1;
				int num2 = i * 2 + 1;
				for (int k = -1; k <= 1; k++)
				{
					for (int l = -1; l <= 1; l++)
					{
						int num3 = num + l;
						int num4 = (num2 + k) * World.MeshWidth + num3;
						if (!dictionary.ContainsKey(num4))
						{
							dictionary[num4] = TerrainGen.inst.GetVertYUnsafe(num4);
						}
					}
				}
			}
		}
		terrainVertexIndices = new int[dictionary.Count];
		terrainOriginalHeights = new float[dictionary.Count];
		int num5 = 0;
		foreach (KeyValuePair<int, float> item in dictionary)
		{
			terrainVertexIndices[num5] = item.Key;
			terrainOriginalHeights[num5] = item.Value;
			num5++;
		}
	}

	public void CaptureTerrainForRevertDepression(float cellX, float cellZ, int offsetX, int offsetZ, int radiusMeshSpace)
	{
		int num = (int)cellX * 2 + 1 + offsetX;
		int num2 = (int)cellZ * 2 + 1 + offsetZ;
		int num3 = Mathf.Clamp(num - radiusMeshSpace, 0, World.MeshWidth - 1);
		int num4 = Mathf.Clamp(num + radiusMeshSpace, 0, World.MeshWidth - 1);
		int num5 = Mathf.Clamp(num2 - radiusMeshSpace, 0, World.MeshHeight - 1);
		int num6 = Mathf.Clamp(num2 + radiusMeshSpace, 0, World.MeshHeight - 1);
		int num7 = (num4 - num3 + 1) * (num6 - num5 + 1);
		terrainVertexIndices = new int[num7];
		terrainOriginalHeights = new float[num7];
		int num8 = 0;
		for (int i = num5; i <= num6; i++)
		{
			for (int j = num3; j <= num4; j++)
			{
				int num9 = i * World.MeshWidth + j;
				terrainVertexIndices[num8] = num9;
				terrainOriginalHeights[num8] = TerrainGen.inst.GetVertYUnsafe(num9);
				num8++;
			}
		}
	}

	private bool ShouldRevertBuildingVertex(int vertIdx)
	{
		GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minZ - 1; i <= maxZ + 1; i++)
		{
			for (int j = minX - 1; j <= maxX + 1; j++)
			{
				Cell cellDataClamped = World.inst.GetCellDataClamped(j, i);
				if (cellDataClamped == null)
				{
					continue;
				}
				foreach (Building item in cellDataClamped.OccupyingStructure)
				{
					if (item == this || !item.revertLandOnDemolish || item.terrainVertexIndices == null)
					{
						continue;
					}
					for (int k = 0; k < item.terrainVertexIndices.Length; k++)
					{
						if (item.terrainVertexIndices[k] == vertIdx)
						{
							return false;
						}
					}
				}
			}
		}
		return true;
	}

	public void RevertTerrainIfLastBuildingInCells()
	{
		if (!revertLandOnDemolish || terrainVertexIndices == null || terrainVertexIndices.Length == 0 || GameState.IsQuitting)
		{
			return;
		}
		GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				Cell cellDataClamped = World.inst.GetCellDataClamped(j, i);
				if (cellDataClamped == null)
				{
					continue;
				}
				foreach (Building item in cellDataClamped.OccupyingStructure)
				{
					if (item != this)
					{
						return;
					}
				}
			}
		}
		bool flag = false;
		int num = int.MaxValue;
		int num2 = int.MaxValue;
		int num3 = int.MinValue;
		int num4 = int.MinValue;
		for (int k = 0; k < terrainVertexIndices.Length; k++)
		{
			int num5 = terrainVertexIndices[k];
			if (ShouldRevertBuildingVertex(num5))
			{
				TerrainGen.inst.SetVert(num5, terrainOriginalHeights[k], bakeDown: true);
				flag = true;
				int num6 = num5 % World.MeshWidth;
				int num7 = num5 / World.MeshWidth;
				if (num6 < num)
				{
					num = num6;
				}
				if (num6 > num3)
				{
					num3 = num6;
				}
				if (num7 < num2)
				{
					num2 = num7;
				}
				if (num7 > num4)
				{
					num4 = num7;
				}
			}
		}
		if (flag)
		{
			TerrainGen.inst.UpdateTerrainDeformations();
			Water.UpdateNeeded = true;
			if (!LoadSave.Loading)
			{
				TerrainRockReclassifier.ReclassifyVertRect(num, num2, num3, num4, bakeDeformations: false);
			}
		}
	}

	private void OnDemolished()
	{
		RevertTerrainIfLastBuildingInCells();
	}

	public bool DuringWorkHours(float buffer)
	{
		float num = workStartHour - buffer;
		float num2 = workEndHour + buffer;
		return DayNightManager.inst.NowIsBetween(num, num2);
	}

	public float GetStartHour()
	{
		return workStartHour;
	}

	public float GetEndHour()
	{
		return workEndHour;
	}

	internal void Rotate(float angle)
	{
		int num = 4;
		if (RotateOnlyToValid)
		{
			num = 0;
		}
		do
		{
			Transform child = transform.GetChild(0);
			if ((bool)child)
			{
				if (IsSquare())
				{
					child.RotateAround(transform.position + new Vector3(size.x / 2f, 0f, size.z / 2f), new Vector3(0f, 1f, 0f), angle);
				}
				else
				{
					child.RotateAround(transform.position + new Vector3(0.5f, 0f, 0.5f), new Vector3(0f, 1f, 0f), angle);
				}
			}
			if (RotateOnlyToValid)
			{
				PlacementValidationResult result = PlacementValidationResult.Valid;
				PlacementValidaton?.Invoke(ref result);
				if (result == PlacementValidationResult.Valid)
				{
					break;
				}
			}
			num++;
		}
		while (num < 4);
	}

	public void OnDestroy()
	{
		KillEffects();
		if (scaffolds != null)
		{
			for (int i = 0; i < scaffolds.Length; i++)
			{
				scaffolds[i].Visible = false;
			}
		}
		for (int j = 0; j < fullMaterial.Count; j++)
		{
			UnityEngine.Object.DestroyImmediate(fullMaterial[j], allowDestroyingAssets: true);
		}
		fullMaterial.Clear();
		if (thought != null)
		{
			ThoughtBubbleSystem.inst.RemoveThoughtBubble(ref thought);
		}
		if (ambience.isValid() && ambience.getPlaybackState(out var state) == RESULT.OK && state == PLAYBACK_STATE.PLAYING)
		{
			ambience.stop(STOP_MODE.IMMEDIATE);
		}
		if (buildingSoundInstance.isValid())
		{
			buildingSoundInstance.stop(STOP_MODE.IMMEDIATE);
			buildingSoundInstance.release();
		}
	}

	public TransformData GetPositionForPerson(Villager person)
	{
		TransformData result = default;
		Cell cell = ((cachedCell != null) ? cachedCell : World.inst.GetCellData(base.transform.position));
		result.position = cell.Center3D;
		bool flag = false;
		for (int i = 0; i < jobs.Count; i++)
		{
			if (!jobs[i].HasEmployee() || !(jobs[i].Employee.guid == person.guid))
			{
				continue;
			}
			flag = true;
			bool flag2 = true;
			if (personPositions.Length != 0)
			{
				Transform transform = personPositions[Mathf.Clamp(i, 0, personPositions.Length - 1)];
				if (transform != null)
				{
					flag2 = false;
					result.position = transform.position;
					result.rotation = transform.rotation;
				}
			}
			if (flag2)
			{
				result.position.y = World.GetCellHeightPos(cell).y;
			}
			break;
		}
		if (!flag)
		{
			int j = 0;
			for (int count = attractionJobs.Count; j < count; j++)
			{
				if (!attractionJobs[j].HasEmployee() || !(attractionJobs[j].Employee.guid == person.guid))
				{
					continue;
				}
				flag = true;
				if (attractionPositions.Length != 0)
				{
					Transform transform2 = attractionPositions[Mathf.Clamp(j, 0, attractionPositions.Length - 1)];
					if (transform2 != null)
					{
						result.position = transform2.position;
						result.rotation = transform2.rotation;
					}
				}
				else
				{
					UnityEngine.Debug.LogError(UniqueName + " has no attraction positions!");
				}
				break;
			}
		}
		return result;
	}

	public TransformData GetPositionForBuilder(int clientIndex, int buildingIndex)
	{
		TransformData result = default;
		Cell cell = ((cachedCell != null) ? cachedCell : World.inst.GetCellData(base.transform.position));
		result.position = cell.Center2D;
		bool flag = true;
		if (personPositions.Length != 0)
		{
			Transform transform = personPositions[Mathf.Clamp(buildingIndex, 0, personPositions.Length - 1)];
			if (transform != null)
			{
				flag = false;
				result.position = transform.position;
				result.rotation = transform.rotation;
			}
		}
		if (flag)
		{
			result.position.y = World.GetCellHeightPos(cell).y;
		}
		Cell cellDataClamped = World.inst.GetCellDataClamped(result.position);
		if (cellDataClamped.landMassIdx == -1)
		{
			cellDataClamped = World.inst.FindMatchingSurroundingCell(cellDataClamped, testOrigin: false, 5, (Cell c) => c.landMassIdx != -1);
			result.position = cellDataClamped.Center2D;
		}
		return result;
	}

	public bool VerifyJobIs(int v, Type t)
	{
		if (t == typeof(IdleJob))
		{
			if (v < attractionJobs.Count)
			{
				return attractionJobs[v].GetType() == t;
			}
		}
		else if (v < jobs.Count)
		{
			return jobs[v].GetType() == t;
		}
		return false;
	}

	public void SetAndAddJob(int idx, Job job)
	{
		if (job.idleJob)
		{
			if (idx < attractionJobs.Count)
			{
				Villager villager = attractionJobs[idx].Employee;
				if (villager != null && villager.job != attractionJobs[idx])
				{
					villager = null;
				}
				JobSystem.inst.RemoveJob(attractionJobs[idx]);
				attractionJobs[idx] = job;
				JobSystem.inst.AddNewJob(attractionJobs[idx], 37);
				if (villager != null)
				{
					attractionJobs[idx].AssignEmployee(villager);
				}
			}
			else
			{
				attractionJobs.Add(job);
				JobSystem.inst.AddNewJob(job, 37);
			}
		}
		else if (idx < jobs.Count)
		{
			Villager employee = jobs[idx].Employee;
			JobSystem.inst.RemoveJob(jobs[idx]);
			jobs[idx] = job;
			JobSystem.inst.AddNewJob(jobs[idx]);
			if (employee != null)
			{
				jobs[idx].AssignEmployee(employee);
			}
		}
		else
		{
			jobs.Add(job);
			JobSystem.inst.AddNewJob(job);
		}
	}

	public void SetOutlineImmediate(int colorIdx)
	{
		if (categoryHash == World.castleblockHash && !GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			Cell cell = GetCell();
			for (int i = 0; i < cell.OccupyingStructure.Count; i++)
			{
				if (cell.OccupyingStructure[i].categoryHash == World.castleblockHash)
				{
					cell.OccupyingStructure[i].highlight.SetOutlineImmediate(colorIdx);
				}
			}
		}
		else if (dMesh != null && dMesh.dMeshObject != (object)null && dMesh.doBespokeHighlight)
		{
			dMesh.dMeshObject.objHiglight.SetOutlineImmediate(colorIdx);
		}
		else
		{
			highlight.SetOutlineImmediate(colorIdx);
		}
	}

	string IEmployer.GetUsedSkill()
	{
		return skillUsed;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public bool IsBuilt()
	{
		return built;
	}

	[MethodImpl(MethodImplOptions.AggressiveInlining)]
	public bool IsPlaced()
	{
		return placed;
	}

	public void UpdateMaterialSelection()
	{
		float num = Life / ModifiedMaxLife;
		if (CanUseUniMaterial() && !inDamageFlashAnimator)
		{
			if (formToTerrain)
			{
				for (int i = 0; i < renderersWithBuildingShader.Count; i++)
				{
					renderersWithBuildingShader[i].material = World.GetUniMaterialTerrainFormFor(LandMass());
				}
			}
			else
			{
				for (int j = 0; j < renderersWithBuildingShader.Count; j++)
				{
					renderersWithBuildingShader[j].material = World.GetUniMaterialFor(LandMass());
				}
			}
		}
		else if (built && num < percentForFirstDmgMat && !inDamageFlashAnimator)
		{
			int num2 = 0;
			if (num < 0.65f && num >= 0.4f)
			{
				num2 = 1;
			}
			else if (num < 0.4f)
			{
				num2 = 2;
			}
			for (int k = 0; k < renderersWithBuildingShader.Count; k++)
			{
				Material sharedMaterial = (formToTerrain ? World.GetLandmassOwner(LandMass()).UniMaterialsCrackedWithTerrainForm[num2] : World.GetLandmassOwner(LandMass()).UniMaterialsCracked[num2]);
				renderersWithBuildingShader[k].sharedMaterial = sharedMaterial;
			}
		}
		else
		{
			for (int l = 0; l < renderersWithBuildingShader.Count; l++)
			{
				renderersWithBuildingShader[l].sharedMaterial = fullMaterial[l];
				renderersWithBuildingShader[l].sharedMaterial.SetFloat("_FormToTerrain", formToTerrain ? 1 : 0);
			}
		}
		if (overlayType == OverlayType.Integrity)
		{
			UpdateIntegrityOverlayMaterial();
		}
		else if (dMesh != null && dMesh.dMeshObject != (object)null)
		{
			dMesh.dMeshObject.SetUniMaterial();
		}
	}

	public float GetCosMaxPlacementAngle()
	{
		return Mathf.Cos((float)((maxPlacementAngle == -1) ? 50 : maxPlacementAngle) * (MathF.PI / 180f));
	}

	public bool CanSnapInside(Building parent)
	{
		if (snapBuildingTarget.GetHashCode() == parent.categoryHash && parent.insideBuildingSnapPoints.Length != 0)
		{
			return parent.insideBuildingSnapPoints[parent.selectedVariant].xform.Length != 0;
		}
		return false;
	}

	public void ResetSnapPointCovers()
	{
		if (insideBuildingSnapPoints.Length == 0)
		{
			return;
		}
		SnapPoints snapPoints = insideBuildingSnapPoints[selectedVariant];
		for (int i = 0; i < snapPoints.xform.Length; i++)
		{
			Transform obj = snapPoints.xform[i];
			int x = (int)obj.position.x;
			int z = (int)obj.position.z;
			bool flag = false;
			Cell cellData = World.inst.GetCellData(x, z);
			for (int j = 0; j < cellData.OccupyingStructure.Count; j++)
			{
				if (cellData.OccupyingStructure[j].CanSnapInside(this))
				{
					flag = true;
				}
			}
			snapPoints.xform[i].GetChild(0).gameObject.SetActive(!flag);
		}
	}

	public void SnapInside(Building parent)
	{
		int num = (int)transform.position.x;
		int num2 = (int)transform.position.z;
		int num3 = 0;
		SnapPoints snapPoints = parent.insideBuildingSnapPoints[parent.selectedVariant];
		for (int i = 0; i < snapPoints.xform.Length; i++)
		{
			if (num3 >= snapInstances.Length)
			{
				break;
			}
			Transform obj = snapPoints.xform[i];
			int num4 = (int)obj.position.x;
			int num5 = (int)obj.position.z;
			if (num == num4 && num2 == num5)
			{
				snapInstances[num3].gameObject.SetActive(value: true);
				snapInstances[num3].SetPositionAndRotation(snapPoints.xform[i].position, snapPoints.xform[i].rotation);
				snapPoints.xform[i].GetChild(0).gameObject.SetActive(value: false);
				num3++;
			}
		}
		for (int j = num3; j < snapInstances.Length; j++)
		{
			snapInstances[j].gameObject.SetActive(value: false);
		}
	}

	private bool CanUseUniMaterial()
	{
		if (open && built && Life / ModifiedMaxLife >= percentForFirstDmgMat && !showHappinessOverlay && overlayType != OverlayType.Integrity && !isDemolishing)
		{
			return !transparent;
		}
		return false;
	}

	public bool IsOpen()
	{
		return open;
	}

	public void OnAssigned(Villager p)
	{
		if (!p.job.idleJob)
		{
			WorkersAllocated++;
		}
		p.SetWorkPosition(GetPositionForPerson(p));
		onJobAssignmentUpdated?.Invoke(p, isAssigned: true);
	}

	public void OnUnAssigned(Villager p)
	{
		if (!p.job.idleJob)
		{
			WorkersAllocated--;
		}
		onJobAssignmentUpdated?.Invoke(p, isAssigned: false);
	}

	public void OnJobRemoved(Job j)
	{
	}

	public int LandMass(int clientIndex)
	{
		return LandMass();
	}

	public int LandMass()
	{
		return landmass;
	}

	public int GetJobCategory()
	{
		return jobCategory;
	}

	public void UpdateShaderHeight()
	{
		for (int i = 0; i < renderersWithBuildingShader.Count; i++)
		{
			Bounds bounds = renderersWithBuildingShader[i].bounds;
			fullMaterial[i].SetFloat(MinHeightId, Mathff.Max(bounds.min.y, TerrainGen.SeaLevel));
			if (bounds.min.y < TerrainGen.SeaLevel)
			{
				fullMaterial[i].SetFloat(MinYAdjustmentId, 0f);
			}
			fullMaterial[i].SetFloat(MaxHeightId, bounds.max.y);
		}
	}

	public void GetRenderersYMinMax(out float minY, out float maxY)
	{
		minY = float.MaxValue;
		maxY = float.MinValue;
		for (int i = 0; i < renderersWithBuildingShader.Count; i++)
		{
			minY = Mathf.Min(minY, renderersWithBuildingShader[i].bounds.min.y);
			maxY = Mathf.Max(maxY, renderersWithBuildingShader[i].bounds.max.y);
		}
	}

	public void SetScaffoldOverride(bool on)
	{
		for (int i = 0; i < fullMaterial.Count; i++)
		{
			fullMaterial[i].SetFloat("_ScaffoldMaxOverride", on ? 1 : 0);
		}
	}

	public void SetValid(bool valid)
	{
		if (valid_material != valid)
		{
			valid_material = valid;
			for (int i = 0; i < fullMaterial.Count; i++)
			{
				fullMaterial[i].SetFloat("_Invalid", (!valid) ? 1 : 0);
			}
		}
	}

	public bool IsVisibleForFog()
	{
		if (!cachedVisibility)
		{
			return seenByPlayer;
		}
		return true;
	}

	public void SetVisibleForFog(bool val)
	{
		cachedVisibility = val || seenByPlayer;
		for (int i = 0; i < renderersWithBuildingShader.Count; i++)
		{
			renderersWithBuildingShader[i].enabled = cachedVisibility;
		}
		visibilityChanged?.Invoke(cachedVisibility);
		if (val)
		{
			seenByPlayer = true;
		}
	}

	public bool IsSquare()
	{
		return Mathf.Abs(size.x - size.z) < 0.001f;
	}

	public void ForEachTileInBounds(EvaluateCell Func)
	{
		Vector3 vector = World.inst.SnapToGrid2DR(base.transform.position);
		Transform transform = (IsSquare() ? null : base.transform.GetChild(0));
		int num = Mathf.RoundToInt(size.x);
		int num2 = Mathf.RoundToInt(size.z);
		for (int i = 0; i < num; i++)
		{
			for (int j = 0; j < num2; j++)
			{
				Vector3 vector2 = new Vector3(i, 0f, j);
				if (!IsSquare())
				{
					vector2 = transform.transform.rotation * vector2;
				}
				int x = Mathf.RoundToInt(vector.x + vector2.x);
				int z = Mathf.RoundToInt(vector.z + vector2.z);
				Cell cellData = World.inst.GetCellData(x, z);
				if (cellData != null)
				{
					Func(x, z, cellData);
				}
			}
		}
	}

	public void ForEachTileInBounds(EvaluateCellWithIndex Func)
	{
		Vector3 vector = World.inst.SnapToGrid2DR(base.transform.position);
		Transform transform = (IsSquare() ? null : base.transform.GetChild(0));
		int num = Mathf.RoundToInt(size.x);
		int num2 = Mathf.RoundToInt(size.z);
		int num3 = 0;
		for (int i = 0; i < num; i++)
		{
			for (int j = 0; j < num2; j++)
			{
				Vector3 vector2 = new Vector3(i, 0f, j);
				if (!IsSquare())
				{
					vector2 = transform.transform.rotation * vector2;
				}
				int x = Mathf.RoundToInt(vector.x + vector2.x);
				int z = Mathf.RoundToInt(vector.z + vector2.z);
				Cell cellData = World.inst.GetCellData(x, z);
				if (cellData != null)
				{
					Func(x, z, cellData, num3);
					num3++;
				}
			}
		}
	}

	public Vector3 GetBounds()
	{
		Vector3 vector = transform.GetChild(0).transform.rotation * size;
		return new Vector3(Mathf.Abs(vector.x), Mathf.Abs(vector.y), Mathf.Abs(vector.z));
	}

	public void GetBoundingFootprint(int clientIndex, out int minX, out int minZ, out int maxX, out int maxZ)
	{
		GetBoundingFootprint(out minX, out minZ, out maxX, out maxZ);
	}

	public void GetBoundingFootprint(out int minX, out int minZ, out int maxX, out int maxZ)
	{
		minX = footprintMinX;
		maxX = footprintMaxX;
		minZ = footprintMinZ;
		maxZ = footprintMaxZ;
	}

	public void CalculateBoundingFootprint(out int minX, out int minZ, out int maxX, out int maxZ)
	{
		Vector3 vector = (IsSquare() ? new Vector3(size.x - 1f, 0f, size.z - 1f) : (transform.GetChild(0).transform.rotation * new Vector3(size.x - 1f, 0f, size.z - 1f)));
		World.inst.ToGridCoord(transform.position, out var x, out var z);
		int num = x + Mathf.RoundToInt(vector.x);
		int num2 = z + Mathf.RoundToInt(vector.z);
		minX = ((x > num) ? num : x);
		minZ = ((z > num2) ? num2 : z);
		maxX = ((x < num) ? num : x);
		maxZ = ((z < num2) ? num2 : z);
		minX = Mathf.Max(minX, 0);
		minZ = Mathf.Max(minZ, 0);
		maxX = Mathf.Min(maxX, World.inst.GridWidth - 1);
		maxZ = Mathf.Min(maxZ, World.inst.GridHeight - 1);
	}

	public void BakeBoundingFootprint()
	{
		CalculateBoundingFootprint(out footprintMinX, out footprintMinZ, out footprintMaxX, out footprintMaxZ);
	}

	public void RefreshCachedValues()
	{
		cachedPos = transform.position;
		BakeBoundingFootprint();
		for (int i = footprintMinZ; i <= footprintMaxZ; i++)
		{
			for (int j = footprintMinX; j <= footprintMaxX; j++)
			{
				Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(j, i);
				if (cellDataUnsafe.landMassIdx != -1)
				{
					cachedCell = cellDataUnsafe;
					landmass = cellDataUnsafe.landMassIdx;
					break;
				}
			}
		}
	}

	public void OnPlacementPuff()
	{
		if ((!LoadSave.Loading || !built) && IsVisibleForFog())
		{
			ForEachTileInBounds((int x, int z, Cell cell, int i) =>
			{
				OneOffEffect oneOffEffect = EffectsMan.inst.BuildEffect.CreateAndPlay(new Vector3(x, transform.position.y, z));
				oneOffEffect.AllowRelease = true;
				buildEffects.Add(oneOffEffect);
			});
		}
	}

	public void TransformBakedPathingToWorldSpace()
	{
		if (hasBakedPathingDataVariantsList.Count > selectedVariant)
		{
			hasBakedPathingData = hasBakedPathingDataVariantsList[selectedVariant];
			bakedPathingData = bakedLocalPathingDataVariantsList[selectedVariant];
			if (personPositionsVariantsList.Count > selectedVariant)
			{
				PersonPositionsVariant personPositionsVariant = personPositionsVariantsList[selectedVariant];
				if (personPositionsVariant.positions.Length != 0)
				{
					if (personPositions.Length < personPositionsVariant.positions.Length)
					{
						personPositions = new Transform[personPositionsVariant.positions.Length];
					}
					for (int i = 0; i < personPositionsVariant.positions.Length; i++)
					{
						personPositions[i] = new GameObject("Person Positions " + i).transform;
						personPositions[i].SetParent(transform.GetChild(0));
						personPositions[i].localPosition = personPositionsVariant.positions[i];
						personPositions[i].localRotation = personPositionsVariant.rotations[i];
					}
				}
			}
			if (hasBakedPathingData)
			{
				int j = 0;
				for (int num = bakedPathingData.vertices.Length; j < num; j++)
				{
					_ = (Vector3)bakedPathingData.vertices[j];
					bakedPathingData.vertices[j] = transform.GetChild(0).TransformPoint(bakedPathingData.vertices[j]);
				}
			}
		}
		else
		{
			hasBakedPathingData = false;
		}
	}

	private bool IsVertPinnedByOtherFlatten(int vx, int vz)
	{
		for (int i = (vz - 1) / 2; i <= vz / 2; i++)
		{
			for (int j = (vx - 1) / 2; j <= vx / 2; j++)
			{
				Cell cellData = World.inst.GetCellData(j, i);
				if (cellData == null)
				{
					continue;
				}
				for (int k = 0; k < cellData.OccupyingStructure.Count; k++)
				{
					Building building = cellData.OccupyingStructure[k];
					if (building != this && building.placementBehavior == PlacementBehavior.Flatten)
					{
						return true;
					}
				}
			}
		}
		return false;
	}

	private GameObject MakeAndParentFoundation()
	{
		GameObject gameObject = UnityEngine.Object.Instantiate(World.inst.foundationPrefab);
		gameObject.transform.SetParent(base.gameObject.transform.GetChild(0));
		gameObject.transform.localRotation = Quaternion.Euler(0f, SRand.Range(0, 3) * 90, 0f);
		gameObject.transform.localScale = new Vector3(1.1f, 1f, 1.1f);
		return gameObject;
	}

	public void OnPlacement(bool byAI)
	{
		thought.pos = Center();
		waterCheckTimer = SRand.Range(0f, 1f);
		if (customName == null)
		{
			customName = FriendlyName;
		}
		if (!IsBuilt() && doBuildAnimation && !Creative.inst.IsCreativeOptionOn(11))
		{
			ConstructionList.Add(this);
			buildingSoundInstance = RuntimeManager.CreateInstance("event:/SFX ASITP/sfx_underConstruction_lp");
			buildingSoundInstance.set3DAttributes(transform.position.To3DAttributes());
			buildingSoundInstance.start();
		}
		placed = true;
		SendMessage("OnPlaced", SendMessageOptions.DontRequireReceiver);
		builtTime = Time.time;
		GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		if (revertLandOnDemolish && !LoadSave.Loading)
		{
			CaptureTerrainForRevert();
		}
		bool flag = false;
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				if (FogOfWar.inst.IsVisible(j, i))
				{
					flag = true;
				}
			}
		}
		cachedVisibility = flag;
		if (allowPlacementOnForum)
		{
			for (int k = minZ; k <= maxZ; k++)
			{
				for (int l = minX; l <= maxX; l++)
				{
					Cell cellData = World.inst.GetCellData(l, k);
					int num = 0;
					while (num < cellData.OccupyingStructure.Count)
					{
						if (cellData.OccupyingStructure[num].categoryHash != World.forumHash)
						{
							num++;
							continue;
						}
						goto IL_015f;
					}
				}
				continue;
				IL_015f:
				placementBehavior = PlacementBehavior.None;
				break;
			}
		}
		if (placementBehavior == PlacementBehavior.Foundation)
		{
			for (int m = minZ; m <= maxZ; m++)
			{
				for (int n = minX; n <= maxX; n++)
				{
					if (!LoadSave.Loading)
					{
						TerrainGen.inst.SetBakedTileHeight(n, m, transform.position.y);
					}
					GameObject gameObject = MakeAndParentFoundation();
					gameObject.transform.position = new Vector3((float)n + 0.5f, transform.position.y, (float)m + 0.5f);
					Vector3 localPosition = gameObject.transform.localPosition;
					localPosition.y = 0f;
					gameObject.transform.localPosition = localPosition;
					gameObject.GetComponent<MeshRenderer>().material = World.inst.romeUnimaterial;
				}
			}
			Vector3 localPosition2 = transform.GetChild(0).transform.localPosition;
			localPosition2.y = 0.1f;
			transform.GetChild(0).transform.localPosition = localPosition2;
		}
		if (placementBehavior == PlacementBehavior.FoundationEdge)
		{
			for (int num2 = minZ; num2 <= maxZ; num2++)
			{
				for (int num3 = minX; num3 <= maxX; num3++)
				{
					TerrainGen.inst.SetBakedTileHeight(num3, num2, transform.position.y);
				}
			}
			for (int num4 = minZ - 1; num4 <= maxZ + 1; num4++)
			{
				for (int num5 = minX - 1; num5 <= maxX + 1; num5++)
				{
					World.inst.ReplaceItems(num5, num4);
				}
			}
			for (int num6 = minZ; num6 <= maxZ; num6++)
			{
				for (int num7 = minX; num7 <= maxX; num7++)
				{
					if (num7 == minX || num7 == maxX || num6 == minZ || num6 == maxZ)
					{
						TerrainGen.inst.SetBakedTileHeight(num7, num6, transform.position.y);
						GameObject gameObject2 = UnityEngine.Object.Instantiate(World.inst.foundationPrefab);
						gameObject2.transform.SetParent(base.gameObject.transform.GetChild(0));
						gameObject2.transform.position = new Vector3((float)num7 + 0.5f, transform.position.y, (float)num6 + 0.5f);
						gameObject2.GetComponent<MeshRenderer>().material = World.inst.romeUnimaterial;
					}
				}
			}
			if (!LoadSave.Loading)
			{
				Vector3 position = transform.GetChild(0).transform.position;
				position.y += 0.1f;
				transform.GetChild(0).transform.position = position;
			}
		}
		if (placementBehavior == PlacementBehavior.Flatten && !LoadSave.Loading)
		{
			for (int num8 = minZ; num8 <= maxZ; num8++)
			{
				for (int num9 = minX; num9 <= maxX; num9++)
				{
					if (World.inst.GetCellData(num9, num8).Type == TerrainType.Water)
					{
						continue;
					}
					for (int num10 = num8 * 2; num10 <= num8 * 2 + 2; num10++)
					{
						for (int num11 = num9 * 2; num11 <= num9 * 2 + 2; num11++)
						{
							if (!IsVertPinnedByOtherFlatten(num11, num10))
							{
								TerrainGen.inst.SetVert(num11, num10, transform.position.y, bakeDown: true);
							}
						}
					}
				}
			}
			for (int num12 = minZ - 1; num12 <= maxZ + 1; num12++)
			{
				for (int num13 = minX - 1; num13 <= maxX + 1; num13++)
				{
					World.inst.ReplaceItems(num13, num12);
				}
			}
		}
		if (placementBehavior == PlacementBehavior.Average && !LoadSave.Loading)
		{
			int num14 = 0;
			for (int num15 = minZ - num14; num15 <= maxZ + num14; num15++)
			{
				for (int num16 = minX - num14; num16 <= maxX + num14; num16++)
				{
					TerrainGen.inst.SetAverageTileHeight(num16, num15, 0.5f);
				}
			}
		}
		if ((placementBehavior == PlacementBehavior.FlattenWithNeighbors || placementBehavior == PlacementBehavior.FlattenWithNeighborsMaxHeight) && !LoadSave.Loading)
		{
			for (int num17 = minZ - 1; num17 <= maxZ + 1; num17++)
			{
				for (int num18 = minX - 1; num18 <= maxX + 1; num18++)
				{
					if (num17 != minZ - 1 && num17 != maxZ + 1 && num18 != minX - 1)
					{
						_ = maxX + 1;
					}
					World.inst.ReplaceItems(num18, num17);
				}
			}
		}
		if (placementBehavior == PlacementBehavior.AlignWithNeighbors && !LoadSave.Loading)
		{
			bool flag2 = false;
			float num19 = float.MinValue;
			for (int num20 = minZ - 1; num20 <= maxZ + 1; num20++)
			{
				for (int num21 = minX - 1; num21 <= maxX + 1; num21++)
				{
					if (num20 != minZ - 1 && num20 != maxZ + 1 && num21 != minX - 1 && num21 != maxX + 1)
					{
						continue;
					}
					Cell cellData2 = World.inst.GetCellData(num21, num20);
					if (cellData2.StructureCompareCategory(categoryHash))
					{
						float y = cellData2.StructureFindByCategory(categoryHash).transform.position.y;
						if (y > num19)
						{
							num19 = y;
						}
						flag2 = true;
					}
				}
			}
			if (!flag2)
			{
				for (int num22 = minZ; num22 <= maxZ; num22++)
				{
					for (int num23 = minX; num23 <= maxX; num23++)
					{
						float tileHeight = TerrainGen.inst.GetTileHeight(World.inst.GetCellData(num23, num22));
						if (tileHeight > num19)
						{
							num19 = tileHeight;
						}
					}
				}
			}
			Vector3 position2 = transform.position;
			position2.y = num19;
			transform.position = position2;
		}
		if (placementBehavior == PlacementBehavior.Align && !LoadSave.Loading)
		{
			Vector3 vector = new Vector3(minX, TerrainGen.inst.GetGroundHeight(minX, minZ), minZ);
			Vector3 vector2 = new Vector3(minX, TerrainGen.inst.GetGroundHeight(minX, maxZ + 1), maxZ + 1);
			Vector3 normalized = Vector3.Cross(rhs: new Vector3(maxX + 1, TerrainGen.inst.GetGroundHeight(maxX + 1, minZ), minZ) - vector, lhs: vector2 - vector).normalized;
			Vector3 vector3 = new Vector3(maxX + 1, TerrainGen.inst.GetGroundHeight(maxX + 1, minZ), minZ);
			Vector3 vector4 = new Vector3(minX, TerrainGen.inst.GetGroundHeight(minX, maxZ + 1), maxZ + 1);
			Vector3 normalized2 = Vector3.Cross(rhs: new Vector3(maxX + 1, TerrainGen.inst.GetGroundHeight(maxX + 1, maxZ + 1), maxZ + 1) - vector3, lhs: vector4 - vector3).normalized;
			Vector3 normalized3 = ((normalized + normalized2) * 0.5f).normalized;
			Vector3 vector5 = Center();
			UnityEngine.Debug.DrawLine(vector5, vector5 + normalized3 * 2f, Color.red, 100f);
			transform.GetChild(0).rotation *= Quaternion.FromToRotation(Vector3.up, normalized3);
		}
		if (RotateRandomY > 0f && !LoadSave.Loading)
		{
			transform.GetChild(0).Rotate(0f, SRand.Range(0f - RotateRandomY, RotateRandomY), 0f);
		}
		BroadcastMessage("EnableColliders", true, SendMessageOptions.DontRequireReceiver);
		for (int num24 = 0; num24 < renderersWithBuildingShader.Count; num24++)
		{
			fullMaterial[num24].SetFloat("_WallProgress", ConstructionForeman.ConstructionProgress);
			fullMaterial[num24].SetFloat("_MinHeight", Mathff.Max(renderersWithBuildingShader[num24].bounds.min.y, TerrainGen.SeaLevel));
			if (renderersWithBuildingShader[num24].bounds.min.y < TerrainGen.SeaLevel)
			{
				fullMaterial[num24].SetFloat("_MinYAdjustment", 0f);
			}
			fullMaterial[num24].SetFloat("_MaxHeight", renderersWithBuildingShader[num24].bounds.max.y);
		}
		if (ConstructionForeman.ConstructionProgress <= 0f)
		{
			OnPlacementPuff();
		}
		ResourceAmount cost = GetCost(-1);
		if (cost.Get(2) == 0 && cost.Get(1) == 0 && cost.Get(14) == 0)
		{
			ConstructionForeman.ResourceProgress = 1f;
		}
		if (StreamerEffects.Flag_FreeBuilding)
		{
			ConstructionForeman.AddBuildResource(Cost);
		}
		if (StreamerEffects.Flag_BuildingCostsReduced)
		{
			ConstructionForeman.AddBuildResource(Cost * 0.5f);
		}
		if (!doBuildAnimation)
		{
			for (int num25 = 0; num25 < fullMaterial.Count; num25++)
			{
				fullMaterial[num25].SetFloat("_WallProgress", 1f);
			}
			CompleteBuild();
			KillEffects();
		}
		else
		{
			if (renderersWithBuildingShader.Count > 0)
			{
				renderMinY = renderersWithBuildingShader[0].bounds.min.y;
				renderMaxY = renderersWithBuildingShader[0].bounds.max.y;
			}
			else
			{
				renderMinY = (renderMaxY = transform.position.y);
			}
			if (!byAI)
			{
				GameUI.inst.UpdateVisibilityForSelectedCellUI();
			}
		}
		if (PerturbPersonPositions)
		{
			for (int num26 = 0; num26 < personPositions.Length; num26++)
			{
				Vector3 position3 = personPositions[num26].position;
				position3.x += SRand.Range(-0.05f, 0.05f);
				position3.z += SRand.Range(-0.05f, 0.05f);
				personPositions[num26].position = position3;
			}
		}
		int num27 = Mathf.RoundToInt(size.x);
		int num28 = Mathf.RoundToInt(size.z);
		splashEffects = new OneOffEffect[num27 * num28];
		TransformBakedPathingToWorldSpace();
	}

	public Cell GetCell()
	{
		if (cachedCell != null)
		{
			return cachedCell;
		}
		return World.inst.GetCellDataClamped(transform.position);
	}

	public bool IsOnFire()
	{
		return GetCell().busyObj is Fire;
	}

	public float GetMaxVigilesCoverage()
	{
		GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		minX = Mathff.Clamp(minX, 0, World.inst.GridWidth - 1);
		minZ = Mathff.Clamp(minZ, 0, World.inst.GridWidth - 1);
		maxX = Mathff.Clamp(maxX, 0, World.inst.GridHeight - 1);
		maxZ = Mathff.Clamp(maxZ, 0, World.inst.GridHeight - 1);
		Cell cell = GetCell();
		float num = FirehouseManager.inst.GetProtection(cell.x, cell.z);
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				float protection = FirehouseManager.inst.GetProtection(j, i);
				if (protection > num)
				{
					num = protection;
				}
			}
		}
		return num;
	}

	public float GetWorkerPercent()
	{
		if (WorkersForFullYield != 0)
		{
			return (float)WorkersAllocated / (float)WorkersForFullYield;
		}
		return 1f;
	}

	public float GetAvgSkill()
	{
		if (lastFrameSkillCalculated != Tickable.frame)
		{
			lastFrameSkillCalculated = Tickable.frame;
			float num = 0f;
			int num2 = 0;
			for (int i = 0; i < jobs.Count; i++)
			{
				if (jobs[i].HasEmployee())
				{
					num += jobs[i].Employee.FindSkill(skillUsedHash);
					num2++;
				}
			}
			avgSkill = ((num2 > 0) ? (num / (float)num2) : 0f);
		}
		return avgSkill;
	}

	public bool DoSkillBonus()
	{
		return GetAvgSkill() > 0.5f;
	}

	public static void ClearBuildingConstructionList()
	{
		ConstructionList.Clear();
	}

	public static void UpdateBuildingConstruction(float dt)
	{
		for (int i = 0; i < ConstructionList.Count; i++)
		{
			ConstructionList[i].UpdateConstruction(dt);
			if (ConstructionList[i].IsBuilt())
			{
				ConstructionList.RemoveAt(i);
				i--;
			}
		}
	}

	public void UpdateBuildingWaterDamage(float dt)
	{
		waterCheckTimer += dt;
		if (!(waterCheckTimer > 1f))
		{
			return;
		}
		waterCheckTimer = 0f;
		bool flag = false;
		bool flag2 = false;
		float num = 0.3f;
		float num2 = 0f;
		for (int i = footprintMinZ; i <= footprintMaxZ; i++)
		{
			for (int j = footprintMinX; j <= footprintMaxX; j++)
			{
				if (j == footprintMinX || i == footprintMinZ || j == footprintMaxX || i == footprintMaxZ)
				{
					Cell cellDataUnsafe = World.inst.GetCellDataUnsafe(j, i);
					float num3 = DynamicWater.inst.simplifiedWaterGrid[cellDataUnsafe.index];
					float num4 = DynamicLava.inst.simplifiedWaterGrid[cellDataUnsafe.index];
					bool flag3 = num3 > 0.05f && !DynamicWater.inst.editTerrainSimulate;
					bool flag4 = num4 > 0f;
					if (num3 > num2)
					{
						num2 = num3;
					}
					flag2 |= flag3;
					flag |= flag4;
				}
			}
		}
		if (flag2)
		{
			consequetiveWaterHits += ((!(num2 > num)) ? 1 : 2);
		}
		else
		{
			consequetiveWaterHits = 0;
		}
		if (consequetiveWaterHits < 3)
		{
			return;
		}
		for (int k = footprintMinZ; k <= footprintMaxZ; k++)
		{
			for (int l = footprintMinX; l <= footprintMaxX; l++)
			{
				if (num2 > num)
				{
					EffectsMan.inst.WaterHitEffect.CreateAndPlay(new Vector3((float)l + 0.5f, transform.position.y + 0.15f, (float)k + 0.5f), Quaternion.identity);
				}
				else
				{
					EffectsMan.inst.WaterHitEffectSmall.CreateAndPlay(new Vector3((float)l + 0.5f, transform.position.y + 0f, (float)k + 0.5f), Quaternion.identity);
				}
			}
		}
		if (num2 > num)
		{
			TakeDamage(0.6f, Center(), "Water damage", damageMovement: false);
		}
		else
		{
			TakeDamage(0.2f, Center(), "Water damage", damageMovement: false);
		}
	}

	private bool IsCastleBelowToFinished()
	{
		Cell cell = GetCell();
		if (cell.OccupyingStructure.Count == 0)
		{
			return true;
		}
		for (int i = 0; i < cell.OccupyingStructure.Count; i++)
		{
			Building building = cell.OccupyingStructure[i];
			if (building == this)
			{
				return true;
			}
			if ((building.categoryHash == castleblockHash || building.categoryHash == gateHash) && !building.IsBuilt())
			{
				return false;
			}
		}
		return false;
	}

	public bool IsPlayerBuilding()
	{
		return World.GetLandmassOwner(GetCell().landMassIdx) == Player.inst.PlayerLandmassOwner;
	}

	public LandmassOwner GetLandMassOwner()
	{
		return World.GetLandmassOwner(LandMass());
	}

	public void EnterPausedConstruction()
	{
		ConstructionForeman.ConstructionPaused = true;
		KillEffects();
	}

	public void ExitPausedConstruction()
	{
		ConstructionForeman.ConstructionPaused = false;
		TryAddBuilderJobs();
		OnPlacementPuff();
	}

	private void TryAddBuilderJobs()
	{
		ConstructionForeman.GetLandState(out var isLandClear, out var isTerrainWorkClear);
		if (!isLandClear)
		{
			ConstructionForeman.TryAddClearLandJobs(BuildAllowedWorkers);
		}
		else if (isTerrainWorkClear && ((categoryHash != castleblockHash && categoryHash != projectiletopperHash) || IsCastleBelowToFinished()))
		{
			ConstructionForeman.AddJobs();
		}
		for (int i = 0; i < renderersWithBuildingShader.Count; i++)
		{
			renderersWithBuildingShader[i].enabled = isLandClear & isTerrainWorkClear;
		}
	}

	internal void DrawScaffolding(float T)
	{
		if (scaffolds == null)
		{
			scaffolds = new RenderInstance[Mathff.Max(1, Mathf.CeilToInt(size.x * size.z * size.y))];
			for (int i = 0; i < scaffolds.Length; i++)
			{
				scaffolds[i] = new RenderInstance(World.inst.scaffoldMesh, World.inst.romeUnimaterial);
			}
		}
		int num = Mathf.RoundToInt(size.x * size.z * size.y * Mathff.Clamp01(T));
		GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		int j = 0;
		for (int k = minZ; k <= maxZ; k++)
		{
			for (int l = minX; l <= maxX; l++)
			{
				for (int m = 0; (float)m < size.y; m++)
				{
					if (j < num && j < scaffolds.Length)
					{
						Vector3 pos = new Vector3((float)l + 0.5f, transform.position.y + (float)m * 0.35f, (float)k + 0.5f);
						scaffolds[j].UpdateTRS(pos, defaultRot, defaultScale);
						scaffolds[j].Visible = true;
						j++;
					}
				}
			}
		}
		for (; j < num && j < scaffolds.Length; j++)
		{
			scaffolds[j].Visible = false;
		}
	}

	public void ForceCompleteBuild()
	{
		ConstructionForeman.ResourceProgress = 1f;
		ConstructionForeman.ConstructionProgress = 1f;
		UpdateConstruction(0f);
	}

	private void UpdateConstruction(float dt)
	{
		buildingSoundInstance.setPaused(TimeManager.inst.IsPaused() || ConstructionForeman.ConstructionPaused);
		if (ConstructionForeman.ConstructionPaused)
		{
			return;
		}
		if (BuildTimeAtMax < 0f)
		{
			CompleteBuild();
			PlayBuiltSound();
			KillEffects();
			return;
		}
		TryAddBuilderJobs();
		if (Creative.inst.IsCreativeOptionOn(11))
		{
			if (!Creative.inst.IsCreativeOptionOn(0))
			{
				ConstructionForeman.ConsumeOutstandingCostFromWorld();
			}
			ConstructionForeman.ResourceProgress = 1f;
			ConstructionForeman.ConstructionProgress = 1f;
		}
		if (oldConstructionProgress < 0.3f && ConstructionForeman.ConstructionProgress >= 0.3f)
		{
			BakePathing();
		}
		if (doScaffoldingDuringConstruction)
		{
			float t = World.inst.scaffoldCurve.Evaluate(ConstructionForeman.ConstructionProgress);
			DrawScaffolding(t);
		}
		if (doBuildAnimation && (ConstructionForeman.ConstructionProgress > oldConstructionProgress || firstConstructionUpdate))
		{
			firstConstructionUpdate = false;
			for (int i = 0; i < renderersWithBuildingShader.Count; i++)
			{
				fullMaterial[i].SetFloat("_WallProgress", Mathf.Clamp(ConstructionForeman.ConstructionProgress, 0.2f, 1f));
			}
			for (int j = 0; j < buildEffects.Count; j++)
			{
				Vector3 position = buildEffects[j].transform.position;
				position.y = Mathf.Lerp(renderMinY, renderMaxY, ConstructionForeman.ConstructionProgress);
				if (position.y < -0.05f)
				{
					position.y = 0.05f;
				}
				buildEffects[j].transform.position = position;
			}
		}
		oldConstructionProgress = ConstructionForeman.ConstructionProgress;
		if (!(ConstructionForeman.ConstructionProgress >= 1f))
		{
			return;
		}
		for (int k = 0; k < renderersWithBuildingShader.Count; k++)
		{
			fullMaterial[k].SetFloat("_WallProgress", 1f);
		}
		ConstructionForeman.RemoveJobs();
		KillEffects();
		PlayBuiltSound();
		CompleteBuild();
		if (IsVisibleForFog() && !CompletelyQuiet)
		{
			ForEachTileInBounds((int x, int z, Cell c) =>
			{
				if (c.TopStructure != null)
				{
					Vector3 center2D = c.Center2D;
					center2D.y += c.TopStructure.transform.position.y;
					EffectsMan.inst.BuildPuff.CreateAndPlay(center2D);
				}
				else
				{
					EffectsMan.inst.BuildPuff.CreateAndPlay(c.Center2D);
				}
			});
		}
		Broadcast.BuildingBuilt.Broadcast(this, new OnBuildingBuilt
		{
			targetBuilding = this
		});
	}

	private void AddAllResourceProviders()
	{
		IResourceProvider[] components = GetComponents<IResourceProvider>();
		for (int i = 0; i < components.Length; i++)
		{
			if (!FreeResourceManager.inst.Contains(components[i]))
			{
				FreeResourceManager.inst.AddResourceProvider(components[i]);
			}
		}
		if (GetComponent<IResourceProviderContainer>() != null)
		{
			GetComponent<IResourceProviderContainer>().AddResourceProvider();
		}
	}

	public bool TryApplyDecay()
	{
		int num = SRand.Range(0, 100);
		int num2 = decayChance;
		if (num2 == -1)
		{
			num2 = defaultDecayChance;
		}
		Governor governor = Player.inst.governors[landmass];
		float num3 = 1f;
		if (governor != null)
		{
			Governor.TraitInstance trait = governor.GetTrait(Traits.BuildingDecay);
			if (trait != null)
			{
				num3 = 1f + (trait.negative ? trait.magnitude : (0f - trait.magnitude));
			}
		}
		num2 = Mathf.RoundToInt((float)num2 * num3);
		if (num <= num2)
		{
			if (decayProtection >= decayRate)
			{
				decayProtection -= decayRate * num3;
			}
			else
			{
				float dmg = decayRate - decayProtection;
				decayProtection = 0f;
				TakeDamage(dmg, Center(), BuildingDecayName);
			}
			return true;
		}
		return false;
	}

	public void ShowOverlay(OverlayType t)
	{
		if (!Player.inst.LandMassIsAPlayerLandMass(LandMass()))
		{
			return;
		}
		if (decayChance == 0 && uniqueNameHash != World.rubbleHash)
		{
			HideOverlay();
		}
		else if (overlayType != t)
		{
			if (t == OverlayType.Integrity)
			{
				UpdateIntegrityOverlayMaterial();
			}
			overlayType = t;
		}
	}

	public void HideOverlay()
	{
		if (overlayType != OverlayType.None)
		{
			overlayType = OverlayType.None;
			UpdateMaterialSelection();
		}
	}

	public void UpdateIntegrityOverlayMaterial()
	{
		if (uniqueNameHash != World.roadHash && uniqueNameHash != World.stoneRoadHash)
		{
			Material integrityMaterial = GetIntegrityMaterial(Life / ModifiedMaxLife, uniqueNameHash);
			for (int i = 0; i < renderersWithBuildingShader.Count; i++)
			{
				renderersWithBuildingShader[i].sharedMaterial = integrityMaterial;
			}
			if (dMesh != null && dMesh.dMeshObject != (object)null)
			{
				dMesh.dMeshObject.TrySetIntegrityVisuals();
			}
		}
	}

	public static Material GetIntegrityMaterial(float norm, int bHash = -1)
	{
		if (bHash == World.rubbleHash)
		{
			return Player.inst.VeryLowIntegrity;
		}
		if (norm >= 0.95f)
		{
			return Player.inst.HighIntegrity;
		}
		if (norm < 0.95f && norm >= 0.75f)
		{
			return Player.inst.MediumIntegrity;
		}
		if (norm < 0.75f && norm >= 0.5f)
		{
			return Player.inst.LowIntegrity;
		}
		return Player.inst.VeryLowIntegrity;
	}

	public void CompleteBuild()
	{
		if (scaffolds != null)
		{
			for (int i = 0; i < scaffolds.Length; i++)
			{
				scaffolds[i].Visible = false;
			}
			scaffolds = null;
		}
		built = true;
		ForEachTileInBounds((int x, int z, Cell c) =>
		{
			c.ClearCell(removeTreesOnComplete, removeRocksOnComplete);
		});
		if (IntegrityUI.inst.overlayOn)
		{
			ShowOverlay(OverlayType.Integrity);
		}
		for (int num = 0; num < renderersWithBuildingShader.Count; num++)
		{
			renderersWithBuildingShader[num].enabled = true;
		}
		UpdateMaterialSelection();
		SendMessage("OnBuilt", SendMessageOptions.DontRequireReceiver);
		yearBuilt = SeasonManager.inst.CurrentYear();
		if (UniqueName == World.colosseumName)
		{
			MilestoneManager.inst.TryFirstColosseum();
		}
		else if (UniqueName == World.dockName)
		{
			MilestoneManager.inst.TryFirstDockMilestone();
		}
		AddAllResourceProviders();
		Player.inst.BuildingNowBuilt(this);
		TryAddJobs();
		BakePathing();
		if (buildingSoundInstance.isValid() && buildingSoundInstance.getPlaybackState(out var _) == RESULT.OK)
		{
			buildingSoundInstance.stop(STOP_MODE.IMMEDIATE);
			buildingSoundInstance.release();
		}
		StartAmbience();
	}

	public void BakePathing()
	{
		GetBoundingFootprint(out var minX, out var minZ, out var maxX, out var maxZ);
		for (int i = minZ; i <= maxZ; i++)
		{
			for (int j = minX; j <= maxX; j++)
			{
				World.inst.rebakeCells.Add(World.inst.GetCellDataClamped(j, i));
			}
		}
	}

	public void PlayBuiltSound()
	{
		if (IsPlayerBuilding() && !CompletelyQuiet)
		{
			if (onBuildingCompleteEvent.Guid == blankGuid)
			{
				UnityEngine.Debug.LogWarning(FriendlyName + " is missing onBuildingCompleteEvent sound");
			}
			else
			{
				RuntimeManager.PlayOneShot(onBuildingCompleteEvent.Guid, Center());
			}
		}
	}

	public void PlaySelectSound()
	{
		EventInstance eventInstance = RuntimeManager.CreateInstance(onBuildingSelectEvent.Guid);
		eventInstance.set3DAttributes(Center().To3DAttributes());
		if (GetComponent<AqueductBuilding>() != null)
		{
			eventInstance.setParameterByName("parameter:/WaterState", GetComponent<AqueductBuilding>().HasWater() ? 1 : 0);
		}
		if (categoryHash == World.fountainHash)
		{
			eventInstance.setParameterByName("parameter:/WaterState", GetComponent<Fountain>().receievingWater ? 1 : 0);
		}
		if (uniqueNameHash == World.waterOutletHash)
		{
			eventInstance.setParameterByName("parameter:/WaterState", GetComponent<WaterOutlet>().HasWater() ? 1 : 0);
		}
		eventInstance.start();
		eventInstance.release();
	}

	public bool IsLowerTier(Building other)
	{
		if (tierOfBuildingUniqueNames == null)
		{
			return false;
		}
		int num = tierOfBuildingUniqueNames.IndexOf(other.UniqueName);
		if (num >= 0)
		{
			return num < tierOfBuildingUniqueNames.IndexOf(UniqueName);
		}
		return false;
	}

	public void FinishAnimateUpgrade(float time, GameObject ObjToDisable)
	{
		ObjToDisable.SetActive(value: false);
		for (int i = 0; i < upgradeFX.Count; i++)
		{
			upgradeFX[i].Stop();
		}
		upgradeFX.Clear();
	}

	public int GetDesiredWorkerCount()
	{
		return WorkersForFullYield;
	}

	private void TryAddJobs()
	{
		SendMessage("OnAddJobs", this, SendMessageOptions.DontRequireReceiver);
		for (int i = jobs.Count; i < WorkersForFullYield; i++)
		{
			if (!VerifyJobIs(i, typeof(Job)))
			{
				SetAndAddJob(i, new Job(this));
			}
		}
	}

	public void UpgradeTo()
	{
		ForEachTileInBounds((int x, int z, Cell c) =>
		{
			OneOffEffect oneOffEffect = EffectsMan.inst.BuildEffect.CreateAndPlay(c.Position);
			oneOffEffect.AllowRelease = true;
			upgradeFX.Add(oneOffEffect);
		});
	}

	private void KillEffects()
	{
		for (int i = 0; i < buildEffects.Count; i++)
		{
			if ((bool)buildEffects[i])
			{
				buildEffects[i].StopImmediately();
			}
		}
		buildEffects.Clear();
		for (int j = 0; j < upgradeFX.Count; j++)
		{
			upgradeFX[j].StopImmediately();
		}
		if (splashEffects != null)
		{
			for (int k = 0; k < splashEffects.Length; k++)
			{
				if ((bool)splashEffects[k])
				{
					splashEffects[k].StopImmediately();
				}
			}
		}
		upgradeFX.Clear();
	}

	public Vector3 Center()
	{
		return cachedChildTransform.position;
	}

	public int CategoryHash()
	{
		return categoryHash;
	}

	public int UniqueNameHash()
	{
		return uniqueNameHash;
	}

	public Vector3 LocalCenter()
	{
		return transform.rotation * transform.GetChild(0).localPosition;
	}

	public bool IsDestroyed()
	{
		return Life <= 0f;
	}

	public bool IsDamaged()
	{
		return Life < ModifiedMaxLife;
	}

	public float GetDamage()
	{
		return ModifiedMaxLife - Life;
	}

	private void RepairInternal(float amount)
	{
		Life += amount;
		Life = Mathf.Clamp(Life, 0f, ModifiedMaxLife);
		if (Life != ModifiedMaxLife)
		{
			firstHit.w = (size.x + size.z + size.y) / hitCrackSpread * (1f - Life / ModifiedMaxLife);
		}
		else
		{
			firstHit = Vector4.zero;
		}
		if (Life >= ModifiedMaxLife)
		{
			TryRemoveFromDamagedList();
		}
		for (int i = 0; i < fullMaterial.Count; i++)
		{
			fullMaterial[i].SetVector("_BreakPoint", firstHit);
		}
		UpdateMaterialSelection();
	}

	public void Repair(float amount)
	{
		RepairInternal(amount);
		EffectsMan.inst.HealthEffect.CreateAndPlay(Center() + new Vector3(0f, size.y / 2f, 0f));
		List<Building> occupyingStructure = GetCell().OccupyingStructure;
		for (int i = 0; i < occupyingStructure.Count; i++)
		{
			Building building = occupyingStructure[i];
			if (building != this && building.CategoryName == "castleblock")
			{
				building.RepairInternal(amount);
			}
		}
	}

	public HitSfxResult TakeDamage(float dmg, Vector3 pos, string attackerName, bool damageMovement = true)
	{
		TakeDamageInternal(dmg, pos, updateBrothers: true, attackerName, damageMovement);
		if (UniqueName == "castleblock" || UniqueName == "church" || UniqueName == "throneroom" || UniqueName == "chamberofwar" || UniqueName == "greathall" || UniqueName == "hospital" || UniqueName == "library" || UniqueName == "clinic")
		{
			return HitSfxResult.Stone;
		}
		if (!(UniqueName == "well"))
		{
			_ = UniqueName == "woodcastleblock";
		}
		return HitSfxResult.Wood;
	}

	public static void ClearDamageFlashAnimators()
	{
		damageFlashAnimator.Clear();
	}

	public static void UpdateFlash()
	{
		float deltaTime = Time.deltaTime;
		for (int i = 0; i < damageFlashAnimator.Count; i++)
		{
			Building building = damageFlashAnimator[i];
			if (building.flashCount <= 0)
			{
				continue;
			}
			building.currFlashTime -= deltaTime;
			if (building.currFlashTime <= 0f - building.flashTime)
			{
				building.currFlashTime = building.flashTime;
				building.flashCount--;
				if (building.flashCount <= 0)
				{
					building.inDamageFlashAnimator = false;
					damageFlashAnimator.RemoveAt(i);
					building.UpdateMaterialSelection();
					i--;
				}
			}
		}
	}

	public bool IsBeingDamaged()
	{
		return Time.time - timeAtDamagedTaken < 10f;
	}

	private void TryAddToDamagedList()
	{
		if (!inDamagedList)
		{
			Player.inst.DamagedList[LandMass()].Add(this);
			inDamagedList = true;
		}
	}

	private void TryAddDamageFlashAnimator()
	{
		if (!inDamageFlashAnimator)
		{
			damageFlashAnimator.Add(this);
			inDamageFlashAnimator = true;
		}
	}

	private void TakeDamageInternal(float dmg, Vector3 damagePos, bool updateBrothers, string attackerName, bool damageMovement = true)
	{
		if (uniqueNameHash == World.rubbleHash)
		{
			UnityEngine.Debug.Log("Rubble taking damage? From " + attackerName);
		}
		float time = Time.time;
		if (attackerName != BuildingDecayName)
		{
			timeAtDamagedTaken = time;
		}
		if (Life <= 0f)
		{
			return;
		}
		if (!built)
		{
			dmg *= 2f;
		}
		Life -= dmg;
		TryAddToDamagedList();
		_ = time - timeAtPreviousFlash;
		_ = minTimeBetweenFlash;
		UpdateMaterialSelection();
		for (int i = 0; i < fullMaterial.Count; i++)
		{
			if (firstHit == Vector4.zero)
			{
				firstHit = damagePos;
			}
			firstHit.w = (size.x + size.z + size.y) / 2f * (1f - Life / ModifiedMaxLife);
			fullMaterial[i].SetVector("_BreakPoint", firstHit);
		}
		Transform child = transform.GetChild(0);
		float num = 0.3f;
		if (dmg < 0.15f && dmg >= 0.05f)
		{
			num = 0.1f;
		}
		else if (dmg < 0.05f)
		{
			num = 0f;
		}
		if ((Life > 0f && !Player.inst.buildingDamageAnimator.IsAnimating(child) && num > 0f) & damageMovement)
		{
			Vector3 leveledDamageOffset = (child.position - damagePos).normalized * num;
			leveledDamageOffset.y = 0f;
			Player.inst.buildingDamageAnimator.AddAnimation(child, leveledDamageOffset, damagePos, fullMaterial);
		}
		if (!updateBrothers)
		{
			return;
		}
		List<Building> occupyingStructure = GetCell().OccupyingStructure;
		for (int j = 0; j < occupyingStructure.Count; j++)
		{
			Building building = occupyingStructure[j];
			if (building != this && building.CategoryName == "castleblock")
			{
				building.TakeDamageInternal(dmg, damagePos, updateBrothers: false, attackerName);
			}
		}
		if (!(Life <= 0f) || isDemolishing)
		{
			return;
		}
		if (IsPlayerBuilding() && attackerName == BuildingDecayName)
		{
			attackerName = ScriptLocalization.BuildingDecayDamageType;
		}
		AIKingdom kingdomByLandmass = AIKingdom.GetKingdomByLandmass(LandMass());
		if (kingdomByLandmass != null)
		{
			Cell cell = GetCell();
			if (categoryHash == World.castleblockHash || categoryHash == World.gateHash)
			{
				kingdomByLandmass.AddThreat();
			}
			kingdomByLandmass.Layout.AddInvalidZone(cell.x, cell.z);
		}
		if (uniqueNameHash == World.stoneBridgeHash || uniqueNameHash == World.woodBridgeHash)
		{
			Bridge component = GetComponent<Bridge>();
			for (int k = 0; k < component.bridgePath.Count; k++)
			{
				Cell cellData = World.inst.GetCellData(component.bridgePath.data[k]);
				for (int l = 0; l < cellData.OccupyingStructure.Count; l++)
				{
					Building building2 = cellData.OccupyingStructure[l];
					if (building2 != null && building2.uniqueNameHash == uniqueNameHash)
					{
						BuildingCollapseManager.inst.Collapse(building2);
					}
				}
			}
		}
		else
		{
			World.inst.MovePeopleInsideToGround(this);
			BuildingCollapseManager.inst.CollapseCell(GetCell());
		}
		SendMessage("OnBuildingCollapse", SendMessageOptions.DontRequireReceiver);
		if (GameUI.inst.GetBuildingSelected() == this)
		{
			GameUI.inst.ClearCellSelected();
		}
	}

	public void GruesomeVillagerDeath()
	{
		for (int i = 0; i < jobs.Count; i++)
		{
			if (jobs[i].HasEmployee() && Vector3.Distance(transform.position.xz(), jobs[i].Employee.Pos.xz()) < 1.5f && World.inst.GetVillagerCountForLandmass(landmass) > 5)
			{
				Player.inst.DestroyPerson(jobs[i].Employee, leaveBehindBody: true);
			}
		}
	}

	public Vector3 GetPos()
	{
		return Center();
	}

	public Vector3 GetPosition(int clientIdx)
	{
		return Center();
	}

	public bool IsStationary()
	{
		return true;
	}

	public int TeamID()
	{
		return World.GetLandmassOwner(LandMass()).teamId;
	}

	public bool CanDemolishBuilding()
	{
		if (this != null)
		{
			Cell cell = GetCell();
			if (DamProjectManager.inst.IsCellPartOfProject(cell, out var _))
			{
				return false;
			}
			if (cell.Busy && !(cell.busyObj is ClearCutterJob))
			{
				return false;
			}
			if (cell.StructureCompareUniqueNameAll(World.keepHash))
			{
				return false;
			}
			if (cell.TopMostStructure == this)
			{
				return true;
			}
			if (cell.TopStructureCategoryIs(World.projectileTopperHash))
			{
				if (cell.OccupyingStructure.FindAll((Building i) => i.CategoryName == World.castleblockName).Count > 1)
				{
					return true;
				}
				return false;
			}
			if (categoryHash == World.castleblockHash)
			{
				return true;
			}
			if (categoryHash == World.pathHash)
			{
				return true;
			}
			if (uniqueNameHash == World.aqueductHash)
			{
				return true;
			}
			if (cell.OccupyingStructure.Count > 0)
			{
				if (categoryHash == gateHash && cell.StructureCompareCategoryNameAll(World.castleblockHash))
				{
					return false;
				}
				return true;
			}
		}
		return false;
	}

	public void DemolishBuilding()
	{
	}

	public bool UnderConstruction()
	{
		return !IsBuilt();
	}

	public bool ConstructionPaused()
	{
		return ConstructionForeman.ConstructionPaused;
	}

	public void PauseConstruction()
	{
		if (!ConstructionForeman.ConstructionPaused)
		{
			EnterPausedConstruction();
		}
	}

	public void UnpauseConstruction()
	{
		if (ConstructionForeman.ConstructionPaused)
		{
			ExitPausedConstruction();
		}
	}

	public void GetConstructionSummary(ref ConstructionForeman.ConstructionSummary summary)
	{
		summary.Summarize(ConstructionForeman);
	}

	public ConstructionForeman GetConstructionForeman()
	{
		return ConstructionForeman;
	}

	public bool BuildFootprintClear()
	{
		bool landClear = true;
		ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			if (!cell.IsCellClear())
			{
				landClear = false;
			}
		});
		return landClear;
	}

	public bool WorkersAssignedToClearFootprint()
	{
		bool workerAssigned = false;
		ForEachTileInBounds((int x, int z, Cell cell) =>
		{
			if (cell.busyObj is ClearCutterJob clearCutterJob && clearCutterJob.HasEmployee())
			{
				workerAssigned = true;
			}
			if (EditTerrainProjectManager.inst.IsCellPartOfProject(cell, out var project))
			{
				ConstructionForeman.ConstructionSummary summary = default;
				project.GetConstructionSummary(ref summary);
				if (summary.workersAssigned > 0)
				{
					workerAssigned = true;
				}
			}
		});
		return workerAssigned;
	}

	public int GetBuildAllowedWorkers()
	{
		return BuildAllowedWorkers;
	}

	public float GetRadius()
	{
		return 1f;
	}

	public Vector3 GetPosition()
	{
		return Center();
	}

	public Vector3 GetVelocity()
	{
		return Vector3.zero;
	}

	public Vector3 GetPredictedPosition(float time)
	{
		return Center();
	}

	public HitSfxResult TakeProjectileDamage(float dmg, DamageType dmgType, DamageSource dmgSource, Vector3 sourcePos, Vector3 incomingVel, int attackerTeamID)
	{
		if (Life <= 0f)
		{
			return HitSfxResult.None;
		}
		AIKingdom kingdomFromTeamId = AIBrainsContainer.inst.GetKingdomFromTeamId(attackerTeamID);
		string attackerName = "";
		if (attackerTeamID == 1)
		{
			attackerName = "I2.Loc.ScriptLocalization.Vikings";
		}
		else if (kingdomFromTeamId != null)
		{
			attackerName = kingdomFromTeamId.GetLocalizedName();
		}
		AIKingdom kingdomFromTeamId2 = AIBrainsContainer.inst.GetKingdomFromTeamId(TeamID());
		HitSfxResult result = TakeDamage(dmg, sourcePos, attackerName);
		if (Life <= 0f && kingdomFromTeamId2 != null && TeamID() != attackerTeamID && attackerTeamID != 1)
		{
			kingdomFromTeamId2.LandmassOwner.ModifyStandingFor(attackerTeamID, -3 * (int)size.x * (int)size.z);
			if (ForeignRegionNameUI.inst != null)
			{
				if (size.x * size.z >= 4f)
				{
					ForeignRegionNameUI.inst.PlayAnimForWreckedBuilding();
				}
				else if (SRand.Range(0, 100) < 20)
				{
					ForeignRegionNameUI.inst.PlayAnimForWreckedBuilding();
				}
			}
			kingdomFromTeamId2.damagePoints += (int)(size.x * size.z);
		}
		if (Life <= 0f && UniqueName == "keep" && TeamID() != attackerTeamID && kingdomFromTeamId2 != null)
		{
			kingdomFromTeamId2.transform.position = GetPos();
			Cam.inst.SetDesiredTrackingPos(Center().xz());
			Player.inst.AddHappinessMod("overthrowtrauma", SeasonManager.inst.TimeInYear() * 100f, -20, ScriptLocalization.LongTermInvasionTrauma, LandMass());
			attackerTeamID = 0;
			LandmassOwner landmassOwnerByTeamId = World.GetLandmassOwnerByTeamId(TeamID());
			landmassOwnerByTeamId.SetStandingFor(Player.inst.PlayerLandmassOwner.teamId, LandmassOwner.Standing.VeryUnfavorable);
			GameUI.inst.diplomacyUI.Show(null, landmassOwnerByTeamId, LandMass(), kingdomFromTeamId2);
			GameUI.inst.diplomacyUI.ChangeMood("Devastated");
			GameUI.inst.diplomacyUI.StartDefeatConvo();
		}
		return result;
	}

	public bool IsInvalid()
	{
		return false;
	}

	public static Building CreateBuilding(GameObject obj, int jobCategory, string[] placementSounds, string[] selectionSounds, string selectedAmbientSound, string uniqueName, string categoryName, GameObject displayModel, bool substructue, string skillUsed, Vector3 size, ResourceAmount cost, bool stackable, float buildShaderMinAdjustment, float buildShaderMaxAdjustment, Transform[] personPositions, DragPlacementMode dragPlacementMode, bool ignoreRoadCoverageForPlace, bool doBuildAnimation, float fireChance, float buildTimeAtMax, int buildAllowedWorkers, bool buildersRequiredOnLocation, int workersForFullYield, int attractionSeats, float decayRate, int decayChance, float decayProtection, bool transportCartsCanTravelOn, bool troopsCanWalkOn, bool allowOverUnderAqueduct, CastleBlockType allowCastleBlocksOnTop, float maxLife)
	{
		Building building = obj.AddComponent<Building>();
		building.jobCategory = jobCategory;
		building.placementSounds = placementSounds;
		building.SelectionSounds = selectionSounds;
		building.selectedAmbientSound = selectedAmbientSound;
		building.UniqueName = uniqueName;
		building.CategoryName = categoryName;
		building.DisplayModel = displayModel;
		building.SubStructure = substructue;
		building.skillUsed = skillUsed;
		building.size = size;
		building.Cost = cost;
		building.Stackable = stackable;
		building.BuildShaderMinYAdjustment = buildShaderMinAdjustment;
		building.BuildShaderMaxYAdjustment = buildShaderMaxAdjustment;
		building.personPositions = personPositions;
		building.dragPlacementMode = dragPlacementMode;
		building.ignoreRoadCoverageForPlacement = ignoreRoadCoverageForPlace;
		building.doBuildAnimation = doBuildAnimation;
		building.fireChance = fireChance;
		building.BuildTimeAtMax = buildTimeAtMax;
		building.BuildAllowedWorkers = buildAllowedWorkers;
		building.BuildersRequiredOnLocation = buildersRequiredOnLocation;
		building.WorkersForFullYield = workersForFullYield;
		building.decayRate = decayRate;
		building.decayChance = decayChance;
		building.decayProtection = decayProtection;
		building.transportCartsCanTravelOn = transportCartsCanTravelOn;
		building.troopsCanWalkOn = troopsCanWalkOn;
		building.allowOverAndUnderAqueducts = allowOverUnderAqueduct;
		building.allowCastleBlocksOnTop = allowCastleBlocksOnTop;
		building.Life = (building.ModifiedMaxLife = (building.Life = maxLife));
		return building;
	}

	public void ApplyMaterialPropertyBlock()
	{
		if (propertyBlock != null)
		{
			propertyBlock.SetColor("_InfoColor", infoColor);
			propertyBlock.SetFloat("_InfoMode", 1f);
			ApplyPropertyBlock();
		}
	}

	public void SetInfoColor(Color color, bool apply = true)
	{
		infoMode = 1f;
		infoColor = color;
		if (apply)
		{
			ApplyMaterialPropertyBlock();
		}
	}

	public void SetLights(float l)
	{
		if (propertyBlock != null)
		{
			propertyBlock.SetFloat("_LightAlpha", l);
			ApplyPropertyBlock();
		}
	}

	private void SetRandomInfoColor()
	{
		Color color = new Color(UnityEngine.Random.Range(0f, 1f), UnityEngine.Random.Range(0f, 1f), UnityEngine.Random.Range(0f, 1f), 0.2f);
		SetInfoColor(color);
	}

	public void ClearInfoOverlay()
	{
		if (propertyBlock != null)
		{
			propertyBlock.SetFloat("_InfoMode", 0f);
			ApplyPropertyBlock();
		}
	}

	private void ApplyPropertyBlock()
	{
		for (int i = 0; i < renderersWithBuildingShader.Count; i++)
		{
			if (renderersWithBuildingShader[i] != null)
			{
				renderersWithBuildingShader[i].SetPropertyBlock(propertyBlock);
			}
		}
	}

	public void UpdateCrackOrigin(Vector3 pos)
	{
		if (propertyBlock != null)
		{
			propertyBlock.SetVector("_CrackOrigin", new Vector4(pos.x, pos.y, pos.z, 0f));
			ApplyPropertyBlock();
		}
	}

	private void StartAmbience()
	{
		if (ambientEvent.Guid != Guid.Empty)
		{
			ambience = RuntimeManager.CreateInstance(ambientEvent.Guid);
			ambience.set3DAttributes(transform.position.To3DAttributes());
			ambience.start();
			ambience.release();
		}
	}
}
