using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using Assets;
using Assets.Code;
using FMOD.Studio;
using FMODUnity;
using I2.Loc;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;
using cakeslice;

public class AqueductLine : MonoBehaviour, IConstructionMaster, ISelectableBuilding, IProceduralOutline, IWorkerUIDisplay
{
	private struct CachedSegmentData
	{
		public bool isElbow;

		public Vector3 pos;

		public Quaternion rot;

		public float groundY;

		public float aqueductHeight;

		public bool isTunnel;

		public Vector3 elbowYOffsetPos;

		public float elbowCompTopY;

		public int elbowCompColCount;

		public float elbowConsTopY;

		public int elbowConsColCount;

		public int elbowScaffoldCount;

		public Quaternion pipeRot;

		public Vector3 sideOffset;

		public float pipeLengthScale;

		public float straightColTopY;

		public int straightColCount;

		public bool hasStraightCols;

		public int straightScaffoldCount;

		public bool hasStake;

		public Vector3 stakeHitPoint;

		public bool hasStartEnd;

		public bool hasEndEnd;

		public Vector3 startEndPos;

		public Vector3 endEndPos;

		public Quaternion reverseRot;

		public float startEndColTopY;

		public int startEndColCount;

		public float endEndColTopY;

		public int endEndColCount;
	}

	[Serializable]
	public class WaterFlowStateTransitionNodes
	{
		public float T;

		public float waterAmount;

		[NonSerialized]
		public int createdFrame;
	}

	public struct AqueductLineIntersection
	{
		public AqueductLine line;

		public int segmentIndex;

		public float segmentT;

		public float normalizedT;

		public Vector3 point;
	}

	private struct SolidHitPair
	{
		public Collider collider;

		public float inDist;

		public float outDist;

		public bool hasIn;

		public bool hasOut;
	}

	public struct Wavefront
	{
		public Vector3 worldPos;

		public string label;
	}

	[Serializable]
	public class AqueductLineSaveData : SaveClass<AqueductLine, AqueductLineSaveData>
	{
		private Guid startAB;

		private RiverTap.RiverTapSaveData riverTapData;

		private Guid endAB;

		private int startPort;

		private int endPort;

		private float currentInputFlow;

		private float currentOutputFlow;

		private List<WaterFlowStateTransitionNodes> waterFlowStateTransitionNodes;

		[OptionalField(VersionAdded = 5)]
		private bool savedInHumanUnits;

		[OptionalField(VersionAdded = 5)]
		private float currentInputFlowHuman;

		[OptionalField(VersionAdded = 5)]
		private float currentOutputFlowHuman;

		public bool fullyConstructed;

		public ConstructionForeman.ConstructionForemanSaveData[] constructionForemanSaveDatas;

		public int currentConstructionIndex;

		public bool isProjectPaused;

		public int meshesUnderConstruction;

		[OptionalField(VersionAdded = 2)]
		public SerializableVector3[] waypoints;

		[OptionalField(VersionAdded = 4)]
		public AqueductJunction.AqueductJunctionSaveData startJunctionData;

		[OptionalField(VersionAdded = 4)]
		public AqueductJunction.AqueductJunctionSaveData endJunctionData;

		[OptionalField(VersionAdded = 6)]
		private bool startOpen;

		[OptionalField(VersionAdded = 6)]
		private bool endOpen;

		[OptionalField(VersionAdded = 6)]
		private SerializableVector3[] fullWaypoints;

		private bool endpointsPinned;

		public override AqueductLineSaveData Pack(AqueductLine w)
		{
			startAB = Guid.Empty;
			endAB = Guid.Empty;
			riverTapData = null;
			startJunctionData = null;
			endJunctionData = null;
			if (w.startAB != null)
			{
				if (w.startAB is AqueductJunction obj)
				{
					startJunctionData = new AqueductJunction.AqueductJunctionSaveData().Pack(obj);
				}
				else if (w.startAB is RiverTap obj2)
				{
					riverTapData = new RiverTap.RiverTapSaveData().Pack(obj2);
				}
				else if (w.startAB.b != null)
				{
					startAB = w.startAB.b.guid;
				}
			}
			if (w.endAB != null)
			{
				if (w.endAB is AqueductJunction obj3)
				{
					endJunctionData = new AqueductJunction.AqueductJunctionSaveData().Pack(obj3);
				}
				else if (w.endAB.b != null)
				{
					endAB = w.endAB.b.guid;
				}
			}
			savedInHumanUnits = true;
			currentInputFlowHuman = w.currentInputFlow;
			currentOutputFlowHuman = w.currentOutputFlow;
			currentInputFlow = 0f;
			currentOutputFlow = 0f;
			waterFlowStateTransitionNodes = new List<WaterFlowStateTransitionNodes>(w.waterFlowStateTransitionNodes.Count);
			for (int i = 0; i < w.waterFlowStateTransitionNodes.Count; i++)
			{
				waterFlowStateTransitionNodes.Add(new WaterFlowStateTransitionNodes
				{
					T = w.waterFlowStateTransitionNodes[i].T,
					waterAmount = w.waterFlowStateTransitionNodes[i].waterAmount
				});
			}
			fullyConstructed = w.fullyConstructed;
			isProjectPaused = w.isProjectPaused;
			meshesUnderConstruction = w.meshesUnderConstruction;
			waypoints = (from v in w.waypoints.Skip(1).Take(w.waypoints.Length - 2)
				select new SerializableVector3(v.x, v.y, v.z)).ToArray();
			startOpen = w.startOpen;
			endOpen = w.endOpen;
			endpointsPinned = w.endpointsPinned;
			fullWaypoints = ((w.startOpen || w.endOpen || w.endpointsPinned) ? w.waypoints.Select((Vector3 v) => new SerializableVector3(v.x, v.y, v.z)).ToArray() : null);
			constructionForemanSaveDatas = new ConstructionForeman.ConstructionForemanSaveData[w.constructionForemans.Length];
			for (int num = 0; num < w.constructionForemans.Length; num++)
			{
				constructionForemanSaveDatas[num] = new ConstructionForeman.ConstructionForemanSaveData().Pack(w.constructionForemans[num]);
			}
			return this;
		}

		public override AqueductLine Unpack(AqueductLine w)
		{
			AqueductBuilding aqueductBuilding = null;
			AqueductBuilding aqueductBuilding2 = null;
			if (startJunctionData != null)
			{
				aqueductBuilding = AqueductJunction.EnsureFromSave(startJunctionData);
			}
			else if (riverTapData != null)
			{
				GameObject gameObject = new GameObject("RiverTap");
				gameObject.transform.SetParent(Player.inst.buildingContainer.transform);
				aqueductBuilding = gameObject.AddComponent<RiverTap>();
				riverTapData.Unpack((RiverTap)aqueductBuilding);
			}
			else
			{
				aqueductBuilding = Player.inst.GetBuilding(startAB)?.GetComponent<AqueductBuilding>();
			}
			aqueductBuilding2 = ((endJunctionData == null) ? Player.inst.GetBuilding(endAB)?.GetComponent<AqueductBuilding>() : AqueductJunction.EnsureFromSave(endJunctionData));
			if ((!startOpen && aqueductBuilding == null) || (!endOpen && aqueductBuilding2 == null))
			{
				return null;
			}
			if ((startOpen || endOpen) && (fullWaypoints == null || fullWaypoints.Length < 2))
			{
				return null;
			}
			w.currentInputFlow = (savedInHumanUnits ? currentInputFlowHuman : AqueductBuilding.SystemToHuman(currentInputFlow));
			w.currentOutputFlow = (savedInHumanUnits ? currentOutputFlowHuman : AqueductBuilding.SystemToHuman(currentOutputFlow));
			for (int i = 0; i < waterFlowStateTransitionNodes.Count; i++)
			{
				if (waterFlowStateTransitionNodes[i] == null)
				{
					waterFlowStateTransitionNodes.RemoveAt(i);
					i--;
				}
				else if (!savedInHumanUnits)
				{
					waterFlowStateTransitionNodes[i].waterAmount = AqueductBuilding.SystemToHuman(waterFlowStateTransitionNodes[i].waterAmount);
				}
			}
			w.waterFlowStateTransitionNodes = waterFlowStateTransitionNodes;
			w.fullyConstructed = fullyConstructed;
			w.isProjectPaused = isProjectPaused;
			w.meshesUnderConstruction = meshesUnderConstruction;
			w.endpointsPinned = endpointsPinned && fullWaypoints != null && fullWaypoints.Length >= 2;
			if (startOpen || endOpen || w.endpointsPinned)
			{
				Vector3[] array = fullWaypoints.Select((SerializableVector3 v) => new Vector3(v.x, v.y, v.z)).ToArray();
				w.SetStartEndOpen(aqueductBuilding, startOpen, aqueductBuilding2, endOpen, array);
			}
			else
			{
				if (waypoints == null)
				{
					waypoints = Array.Empty<SerializableVector3>();
				}
				Vector3[] middleWaypoints = waypoints.Select((SerializableVector3 v) => new Vector3(v.x, v.y, v.z)).ToArray();
				w.SetStartEnd(aqueductBuilding, middleWaypoints, aqueductBuilding2);
			}
			w.BuildPersonPositions();
			if (!w.fullyConstructed)
			{
				int num = Mathf.Min(constructionForemanSaveDatas.Length, w.constructionForemans.Length);
				for (int num2 = 0; num2 < num; num2++)
				{
					constructionForemanSaveDatas[num2].Unpack(w.constructionForemans[num2]);
				}
			}
			else
			{
				for (int num3 = 0; num3 < w.constructionForemans.Length; num3++)
				{
					w.constructionForemans[num3].RemoveJobs();
				}
			}
			if (!startOpen && aqueductBuilding != null)
			{
				aqueductBuilding.ConnectLine(w);
				aqueductBuilding.UpdateWaterFlow();
			}
			if (!endOpen && aqueductBuilding2 != null)
			{
				aqueductBuilding2.ConnectLine(w);
				aqueductBuilding2.UpdateWaterFlow();
			}
			w.FullBuild();
			w.Place();
			return w;
		}
	}

	public static int INVALID_STAGNATE = 1;

	public static int INVALID_TOO_STEEP = 0;

	public bool debug;

	public Material waterMaterial;

	public float waterWidth = 0.2f;

	public float waterHeightMult = 1f;

	public float heightOffset;

	public Material arrowMaterial;

	public float arrowWidth = 0.11f;

	public float arrowHeightOffset = 0.002f;

	public int meshesToConstructAtOnce = 5;

	public Vector3 pipeScale = Vector3.one;

	public Vector3 pipeSideScale = Vector3.one;

	public float pipeSideSpacing = 0.4f;

	public float pipeSideHeightOffset;

	public Vector3 tunnelRaycastOffset = Vector3.zero;

	public Vector3 offset = Vector3.zero;

	public Vector3 scale = Vector3.one;

	public Vector3[] waypoints;

	public MaterialPropertyBlock props;

	private int[] constructingTopAquaductMatrixIndices;

	private int[] constructingMiddleAquaductMatrixIndices;

	private int[] constructingTopElbowMatrixIndices;

	private int[] constructingMiddleElbowMatrixIndices;

	private int[] constructingEndTopMatrixIndices;

	private int[] constructingEndMiddleMatrixIndices;

	private List<Matrix4x4> topMatricesBuilder = new List<Matrix4x4>();

	private List<Matrix4x4> middleMatricesBuilder = new List<Matrix4x4>();

	private List<Matrix4x4> constructingAquaductTopMatrixBuilder = new List<Matrix4x4>();

	private List<Matrix4x4> constructingAquaductMiddleMatrixBuilder = new List<Matrix4x4>();

	private List<Matrix4x4> constructingElbowTopMatrixBuilder = new List<Matrix4x4>();

	private List<Matrix4x4> constructingElbowMiddleMatrixBuilder = new List<Matrix4x4>();

	private List<Matrix4x4> constructingEndTopMatrixBuilder = new List<Matrix4x4>();

	private List<Matrix4x4> constructingEndMiddleMatrixBuilder = new List<Matrix4x4>();

	private List<Matrix4x4> endMatricesBuilder = new List<Matrix4x4>();

	private List<Matrix4x4> endMatricesBuilderTop = new List<Matrix4x4>();

	public List<Matrix4x4> tunnelMatricesBuilder = new List<Matrix4x4>();

	public List<Matrix4x4> scaffoldMatricesBuilder = new List<Matrix4x4>();

	public List<Matrix4x4> elbowMatricesBuilderTop = new List<Matrix4x4>();

	public List<Matrix4x4> elbowMatricesBuilder = new List<Matrix4x4>();

	private List<int> buildMaterialIndexesMiddles = new List<int>();

	private List<int> buildMaterialIndexesMiddlesElbows = new List<int>();

	private List<int> buildMaterialIndexesTopElbows = new List<int>();

	private List<int> buildMaterialIndexesTopAqueducts = new List<int>();

	private List<int> buildMaterialIndexesEndTops = new List<int>();

	private List<int> buildMaterialIndexesEndMiddles = new List<int>();

	private List<Matrix4x4> sideConnectors = new List<Matrix4x4>();

	private Vector3 elbowYOffsetCompleted = new Vector3(0f, -0.05f, 0f);

	private Vector3 elbowScale = new Vector3(1.4f, 1f, 1.4f);

	private Vector3 scaffoldElbowScale = new Vector3(0.4f, 1f, 0.4f);

	private Vector3 scaffoldAqueductScale = new Vector3(0.25f, 1f, 0.55f);

	private Vector3 tunnelRaycastExtents = new Vector3(0.001f, 0.025f, 0.125f);

	private int cachedTerrainMask;

	private int cachedDefaultTerrainMask;

	private Matrix4x4[] topMatrices;

	private Matrix4x4[] middleMatrices;

	private Matrix4x4[] constructingTopAquaductMatrix;

	private Matrix4x4[] constructingMiddleAquaductMatrix;

	private Matrix4x4[] constructingTopElbowMatrix;

	private Matrix4x4[] constructingMiddleElbowMatrix;

	private Matrix4x4[] constructingEndTopMatrix;

	private Matrix4x4[] constructingEndMiddleMatrix;

	public Matrix4x4[] endMatrices;

	public Matrix4x4[] endMatricesTop;

	public Matrix4x4[] pipeMatrices;

	public Matrix4x4[] pipeSideLeftMatrices;

	public Matrix4x4[] pipeSideRightMatrices;

	public Matrix4x4[] pipeSideConnectorMatrices;

	public Matrix4x4[] pipeMatricesForConstruction;

	public Matrix4x4[] pipeSideLeftMatricesForConstruction;

	public Matrix4x4[] pipeSideRightMatricesForConstruction;

	public Matrix4x4[] stakesForConstruction;

	public Matrix4x4[] tunnelMatrices;

	public Matrix4x4[] scaffoldMatrices;

	public Matrix4x4[] elbowMatricesTop;

	public Matrix4x4[] elbowMatrices;

	public Mesh aqueductStraight;

	public Mesh aqueductArch;

	public Mesh aqueductLeg;

	public Mesh aqueductEnd;

	public Mesh aqueductEndTop;

	public Mesh aqueductPipe;

	public Mesh aqueductPipeSide;

	public Mesh stakeMesh;

	public Mesh aqueductTunnel;

	public Mesh scaffoldMesh;

	public Mesh elbowMeshTop;

	public Mesh elbowMesh;

	public Mesh waterMesh;

	public Mesh arrowMesh;

	public Material material;

	private Material invalidMaterial;

	private AqueductBuilding startAB;

	private AqueductBuilding endAB;

	private bool startOpen;

	private bool endOpen;

	private bool endpointsPinned;

	private Transform startHandle;

	private Transform endHandle;

	private ConstructionForeman[] constructionForemans;

	private Vector3[][] personPositions;

	private bool[] didConstructionPuff;

	private Material[] buildingMaterial;

	private MeshCollider[] segmentColliders = new MeshCollider[0];

	private bool fullyCollapsed;

	public bool collapse;

	private float collapseTime;

	internal int[] refundStoneAmounts;

	private Vector3[] refundPositions;

	private bool[] isSegmentTunnel;

	private float[] _waypointGroundY;

	private CachedSegmentData[] _cachedSegments;

	private bool _geometryCacheValid;

	private int _cachedNumConstructions;

	private Vector3[] _cachedPipeCenters;

	private Quaternion[] _cachedPipeRotations;

	private Vector3[] _cachedPipeScales;

	private Matrix4x4[] _cachedPipeSideLeftBase;

	private Matrix4x4[] _cachedPipeSideRightBase;

	private Matrix4x4[] _cachedConnectorBase;

	private Matrix4x4[] _cachedTunnelBase;

	private bool[] _segmentCompletedFlag;

	private int _completedSegmentCount;

	private List<Matrix4x4> _completedTopList;

	private List<Matrix4x4> _completedMiddleList;

	private List<Matrix4x4> _completedElbowTopList;

	private List<Matrix4x4> _completedElbowMiddleList;

	private List<Matrix4x4> _completedEndTopList;

	private List<Matrix4x4> _completedEndMiddleList;

	private int[] _activeSegmentIndices;

	private int _activeSegmentCount;

	public bool fullyConstructed;

	public int meshesUnderConstruction;

	private List<RenderInstance> _renderInstances;

	private bool _usingInstancedRendering;

	internal float currentInputFlow;

	public float currentOutputFlow;

	public float valveRatio;

	public List<WaterFlowStateTransitionNodes> waterFlowStateTransitionNodes = new List<WaterFlowStateTransitionNodes>();

	public ObjectHighlighter highlight;

	private bool isProjectPaused;

	internal bool hasWater;

	public PooledWaterfallParticles openEndWaterfallPrefab;

	private PooledWaterfallParticles openEndWaterfall;

	private bool openEndWaterfallActive;

	public ResourceAmount costPerMesh;

	private static GameObject aqueductLinePrefab;

	public static List<AqueductLine> allLines = new List<AqueductLine>();

	public const float CutClearance = 0.5f;

	private static readonly Dictionary<int, SolidHitPair> solidHitPairs = new Dictionary<int, SolidHitPair>();

	private static readonly List<float2> tunnelSpans = new List<float2>();

	private static readonly Comparison<float2> tunnelSpanComparison = (float2 a, float2 b) => a.x.CompareTo(b.x);

	private const float TunnelSampleStep = 0.5f;

	private const float TunnelCollinearDot = 0.996f;

	private static readonly int[] segmentColliderTriangles = new int[36]
	{
		0, 3, 2, 0, 2, 1, 4, 5, 6, 4,
		6, 7, 0, 1, 5, 0, 5, 4, 3, 7,
		6, 3, 6, 2, 0, 4, 7, 0, 7, 3,
		1, 6, 5, 1, 2, 6
	};

	private static readonly Vector3[] segmentColliderVerts = new Vector3[8];

	private int[] waterIndies = new int[100];

	private List<Vector3> waterVerts = new List<Vector3>();

	private List<Vector2> waterUVs = new List<Vector2>();

	private int[] arrowIndies;

	private List<Vector3> arrowVerts = new List<Vector3>();

	private List<Vector2> arrowUVs = new List<Vector2>();

	private const float BELOW_PIPE_SENTINEL = -0.01f;

	private static int _waterSelCacheFrame = -1;

	private static bool _waterSelCached;

	public int numOfFullCost;

	public int numOfReducedCost;

	private const float PortBoxReconnectEpsilon = 0.5f;

	private ResourceAmount freeTrueCost = new ResourceAmount();

	private Vector2Int[][] constructionFootprint;

	private int landmass;

	public EventReference onBuildingCompleteEvent;

	public EventReference onBuildingSelectEvent;

	public EventReference onBuildingDestroyEvent;

	public EventReference ambientEvent;

	private string customName;

	public bool displayOnly;

	private bool invalid;

	internal Vector3 CompletedElbowOffset => elbowYOffsetCompleted;

	internal Vector3 CompletedElbowScale => elbowScale;

	public bool IsOpenEnded
	{
		get
		{
			if (!startOpen)
			{
				return endOpen;
			}
			return true;
		}
	}

	public bool IsStartOpen => startOpen;

	public bool IsEndOpen => endOpen;

	public string CustomName
	{
		get
		{
			if (customName == null)
			{
				return GetFriendlyName(0);
			}
			return customName;
		}
		set
		{
			customName = value;
		}
	}

	public string Description => ScriptLocalization.Building_aqueductDummyBuilding_Description;

	private static bool TryLineIntersectionXZ(Vector3 p1, Vector3 d1, Vector3 p2, Vector3 d2, out Vector3 result)
	{
		Vector2 vector = new Vector2(p1.x, p1.z);
		Vector2 vector2 = new Vector2(p2.x, p2.z);
		Vector2 vector3 = new Vector2(d1.x, d1.z);
		Vector2 vector4 = new Vector2(d2.x, d2.z);
		float num = vector3.x * vector4.y - vector3.y * vector4.x;
		if (Mathf.Abs(num) < 1E-05f)
		{
			result = Vector3.zero;
			return false;
		}
		float num2 = ((vector2.x - vector.x) * vector4.y - (vector2.y - vector.y) * vector4.x) / num;
		result = p1 + d1 * num2;
		return true;
	}

	private float[] BuildRailPullbacks()
	{
		int num = ((waypoints != null) ? Mathf.Max(0, waypoints.Length - 2) : 0);
		float[] array = new float[num];
		if (num == 0)
		{
			return array;
		}
		int num2 = waypoints.Length - 1;
		float[] array2 = new float[num2];
		for (int i = 0; i < num2; i++)
		{
			Vector3 vector = waypoints[i + 1] - waypoints[i];
			vector.y = 0f;
			array2[i] = vector.magnitude;
		}
		for (int j = 0; j < num; j++)
		{
			float num3 = array2[j];
			float num4 = array2[j + 1];
			if (!(num3 < 0.0001f) && !(num4 < 0.0001f))
			{
				Vector3 lhs = waypoints[j + 1] - waypoints[j];
				Vector3 rhs = waypoints[j + 2] - waypoints[j + 1];
				lhs.y = 0f;
				rhs.y = 0f;
				lhs /= num3;
				rhs /= num4;
				float num5 = Vector3.Dot(lhs, rhs);
				float num6 = Mathf.Abs(lhs.z * rhs.x - lhs.x * rhs.z) / Mathf.Max(1f + num5, 1E-06f);
				array[j] = pipeSideSpacing * num6;
			}
		}
		for (int k = 0; k < num2; k++)
		{
			float num7 = ((k > 0) ? array[k - 1] : 0f);
			float num8 = ((k < num) ? array[k] : 0f);
			float num9 = num7 + num8;
			if (num9 > array2[k])
			{
				float num10 = array2[k] / num9;
				if (k > 0)
				{
					array[k - 1] *= num10;
				}
				if (k < num)
				{
					array[k] *= num10;
				}
			}
		}
		return array;
	}

	public static int LineTypeOfInvalid(Vector3 start, Vector3 end)
	{
		if (!LineValidAngle(start, end, 0f, 1f))
		{
			return INVALID_TOO_STEEP;
		}
		return INVALID_STAGNATE;
	}

	public static bool LineValidAngleNormal(Vector3 start, Vector3 end, bool orderMatters = false)
	{
		if (!orderMatters && start.y < end.y)
		{
			Vector3 vector = end;
			Vector3 vector2 = start;
			start = vector;
			end = vector2;
		}
		return LineValidAngle(start, end, -4.5f, 0.1f);
	}

	public static bool LineValidAngleHighPressure(Vector3 start, Vector3 end, bool orderMatters = false)
	{
		if (!orderMatters && start.y < end.y)
		{
			Vector3 vector = end;
			Vector3 vector2 = start;
			start = vector;
			end = vector2;
		}
		return LineValidAngle(start, end, -9f, -4.5f);
	}

	private static bool LineValidAngle(Vector3 start, Vector3 end, float minAngle, float maxAngle)
	{
		float num = Mathff.Dist(start, end);
		float num2 = num * Mathf.Tan(MathF.PI / 180f * minAngle);
		float num3 = num * Mathf.Tan(MathF.PI / 180f * maxAngle);
		if (end.y - start.y > num2)
		{
			return end.y - start.y < num3;
		}
		return false;
	}

	public static float LineAngle(Vector3 start, Vector3 end)
	{
		return Mathf.Atan((end.y - start.y) / Mathff.Dist(start.xz(), end.xz())) * 180f / MathF.PI;
	}

	public static void Clear()
	{
		for (int i = 0; i < allLines.Count; i++)
		{
			if (allLines[i] != null)
			{
				UnityEngine.Object.Destroy(allLines[i].gameObject);
			}
		}
		allLines.Clear();
	}

	private static AqueductLine InstantiateLinePrefab()
	{
		if (aqueductLinePrefab == null)
		{
			aqueductLinePrefab = Resources.Load<GameObject>("AqueductLine");
		}
		return UnityEngine.Object.Instantiate(aqueductLinePrefab).GetComponent<AqueductLine>();
	}

	internal static AqueductLine CreateInstantLine(AqueductBuilding start, Vector3[] middleWaypoints, AqueductBuilding end)
	{
		if (start == null || end == null)
		{
			return null;
		}
		AqueductLine aqueductLine = InstantiateLinePrefab();
		aqueductLine.DisplayOnly(b: false);
		aqueductLine.SetStartEnd(start, middleWaypoints ?? Array.Empty<Vector3>(), end, autoGrade: false);
		if (!aqueductLine.InitInstantLineState())
		{
			return null;
		}
		start.ConnectLine(aqueductLine);
		end.ConnectLine(aqueductLine);
		AqueductFlowController.MarkTopologyDirty("CreateInstantLine");
		return aqueductLine;
	}

	internal static AqueductLine CreateInstantLineOneOpen(AqueductBuilding closed, Vector3[] middleWaypoints, Vector3 openTerminal, bool openIsStart)
	{
		if (closed == null)
		{
			return null;
		}
		if (middleWaypoints == null)
		{
			middleWaypoints = Array.Empty<Vector3>();
		}
		Vector3 pos;
		if (middleWaypoints.Length != 0)
		{
			pos = (openIsStart ? middleWaypoints[^1] : middleWaypoints[0]);
		}
		else
		{
			pos = openTerminal;
		}
		Vector3 portPosition = closed.GetPortPosition(pos);
		List<Vector3> list = new List<Vector3>(middleWaypoints.Length + 2);
		if (openIsStart)
		{
			list.Add(openTerminal);
			list.AddRange(middleWaypoints);
			list.Add(portPosition);
		}
		else
		{
			list.Add(portPosition);
			list.AddRange(middleWaypoints);
			list.Add(openTerminal);
		}
		AqueductLine aqueductLine = InstantiateLinePrefab();
		aqueductLine.DisplayOnly(b: false);
		aqueductLine.SetStartEndOpen(openIsStart ? null : closed, openIsStart, openIsStart ? closed : null, !openIsStart, list.ToArray());
		if (!aqueductLine.InitInstantLineState())
		{
			return null;
		}
		closed.ConnectLine(aqueductLine);
		AqueductFlowController.MarkTopologyDirty("CreateInstantLineOneOpen");
		return aqueductLine;
	}

	private bool InitInstantLineState()
	{
		if (NumberOfConstructions() < 1)
		{
			gameObject.SetActive(value: false);
			UnityEngine.Object.Destroy(gameObject);
			return false;
		}
		fullyConstructed = true;
		meshesUnderConstruction = 0;
		isProjectPaused = false;
		waterFlowStateTransitionNodes.Clear();
		currentInputFlow = 0f;
		currentOutputFlow = 0f;
		if (constructionForemans != null)
		{
			for (int i = 0; i < constructionForemans.Length; i++)
			{
				constructionForemans[i].RemoveJobs();
			}
		}
		Place();
		FullBuild();
		return true;
	}

	private static void AppendPointIfNeeded(List<Vector3> list, Vector3 point)
	{
		if (list.Count == 0)
		{
			list.Add(point);
		}
		else if ((list[list.Count - 1] - point).sqrMagnitude > 0.0001f)
		{
			list.Add(point);
		}
		else
		{
			list[list.Count - 1] = point;
		}
	}

	private static Vector3[] ExtractMiddleWaypoints(List<Vector3> fullWaypoints)
	{
		if (fullWaypoints.Count <= 2)
		{
			return Array.Empty<Vector3>();
		}
		Vector3[] array = new Vector3[fullWaypoints.Count - 2];
		for (int i = 1; i < fullWaypoints.Count - 1; i++)
		{
			array[i - 1] = fullWaypoints[i];
		}
		return array;
	}

	internal static (AqueductLine upstream, AqueductLine downstream) SplitLineAt(AqueductLine line, AqueductJunction junction, AqueductLineIntersection intersection)
	{
		if (line == null || junction == null)
		{
			return (upstream: null, downstream: null);
		}
		AqueductBuilding startBuilding = line.GetStartBuilding();
		AqueductBuilding endBuilding = line.GetEndBuilding();
		if (line.waypoints == null || line.waypoints.Length < 2)
		{
			return (upstream: null, downstream: null);
		}
		if ((startBuilding == null && !line.startOpen) || (endBuilding == null && !line.endOpen))
		{
			return (upstream: null, downstream: null);
		}
		bool startIsOpen = line.startOpen;
		bool endIsOpen = line.endOpen;
		Vector3 point = intersection.point;
		List<Vector3> list = new List<Vector3>();
		List<Vector3> list2 = new List<Vector3>();
		for (int i = 0; i <= intersection.segmentIndex && i < line.waypoints.Length; i++)
		{
			list.Add(line.waypoints[i]);
		}
		AppendPointIfNeeded(list, point);
		AppendPointIfNeeded(list2, point);
		for (int j = intersection.segmentIndex + 1; j < line.waypoints.Length; j++)
		{
			AppendPointIfNeeded(list2, line.waypoints[j]);
		}
		if (line.NumberOfConstructions(list.ToArray()) < 1 || line.NumberOfConstructions(list2.ToArray()) < 1)
		{
			return (upstream: null, downstream: null);
		}
		line.DisableSegmentColliders();
		AqueductLine aqueductLine = CreateSplitLine(startBuilding, startIsOpen, junction, endIsOpen: false, list);
		AqueductLine aqueductLine2 = CreateSplitLine(junction, startIsOpen: false, endBuilding, endIsOpen, list2);
		if (aqueductLine != null && aqueductLine2 != null)
		{
			float num = Mathf.Clamp(intersection.normalizedT, 0.0001f, 0.9999f);
			float num2 = Mathf.Max(num, 0.0001f);
			float num3 = Mathf.Max(1f - num, 0.0001f);
			float num4 = WaterLevelAt(line, num);
			aqueductLine.waterFlowStateTransitionNodes.Clear();
			aqueductLine2.waterFlowStateTransitionNodes.Clear();
			if (line.waterFlowStateTransitionNodes != null)
			{
				for (int k = 0; k < line.waterFlowStateTransitionNodes.Count; k++)
				{
					WaterFlowStateTransitionNodes waterFlowStateTransitionNodes = line.waterFlowStateTransitionNodes[k];
					if (waterFlowStateTransitionNodes != null)
					{
						if (waterFlowStateTransitionNodes.T <= num)
						{
							float t = Mathf.Clamp01(waterFlowStateTransitionNodes.T / num2);
							aqueductLine.waterFlowStateTransitionNodes.Add(new WaterFlowStateTransitionNodes
							{
								T = t,
								waterAmount = waterFlowStateTransitionNodes.waterAmount
							});
						}
						else
						{
							float t2 = Mathf.Clamp01((waterFlowStateTransitionNodes.T - num) / num3);
							aqueductLine2.waterFlowStateTransitionNodes.Add(new WaterFlowStateTransitionNodes
							{
								T = t2,
								waterAmount = waterFlowStateTransitionNodes.waterAmount
							});
						}
					}
				}
			}
			aqueductLine.currentInputFlow = line.currentInputFlow;
			aqueductLine.currentOutputFlow = num4;
			aqueductLine.hasWater = aqueductLine.currentInputFlow > 0f || aqueductLine.currentOutputFlow > 0f;
			aqueductLine2.currentInputFlow = num4;
			aqueductLine2.currentOutputFlow = line.currentOutputFlow;
			aqueductLine2.hasWater = aqueductLine2.currentInputFlow > 0f || aqueductLine2.currentOutputFlow > 0f;
		}
		startBuilding?.RemoveAqueductLine(line);
		endBuilding?.RemoveAqueductLine(line);
		if (allLines.Contains(line))
		{
			allLines.Remove(line);
		}
		UnityEngine.Object.Destroy(line.gameObject);
		AqueductFlowController.MarkTopologyDirty("SplitLineAt");
		return (upstream: aqueductLine, downstream: aqueductLine2);
		static AqueductLine CreateSplitLine(AqueductBuilding start, bool startIsOpen2, AqueductBuilding end, bool endIsOpen2, List<Vector3> points)
		{
			AqueductLine aqueductLine3 = InstantiateLinePrefab();
			aqueductLine3.DisplayOnly(b: false);
			aqueductLine3.SetStartEndOpen(start, startIsOpen2, end, endIsOpen2, points.ToArray());
			if (!aqueductLine3.InitInstantLineState())
			{
				return null;
			}
			start?.ConnectLine(aqueductLine3);
			end?.ConnectLine(aqueductLine3);
			return aqueductLine3;
		}
	}

	public static List<AqueductLine> CutLine(AqueductLine line, Vector3 from, Vector3 to, float radius, float minRemnantLength = 0f)
	{
		List<AqueductLine> list = new List<AqueductLine>();
		if (line == null || line.waypoints == null || line.waypoints.Length < 2 || radius <= 0f)
		{
			return list;
		}
		AqueductBuilding startBuilding = line.GetStartBuilding();
		AqueductBuilding endBuilding = line.GetEndBuilding();
		Vector2 vector = new Vector2(from.x, from.z);
		Vector2 vector2 = new Vector2(to.x, to.z);
		float num = ((minRemnantLength > 0f) ? minRemnantLength : 0.5f);
		List<Vector3> list2 = new List<Vector3>();
		AppendPointIfNeeded(list2, line.waypoints[0]);
		List<float> list3 = new List<float>();
		for (int i = 0; i < line.waypoints.Length - 1; i++)
		{
			Vector3 a = line.waypoints[i];
			Vector3 vector3 = line.waypoints[i + 1];
			list3.Clear();
			CollectCapsuleCrossings(a, vector3, vector, vector2, radius, list3);
			list3.Sort();
			for (int j = 0; j < list3.Count; j++)
			{
				AppendPointIfNeeded(list2, Vector3.Lerp(a, vector3, list3[j]));
			}
			AppendPointIfNeeded(list2, vector3);
		}
		int count = list2.Count;
		if (count < 2)
		{
			return new List<AqueductLine> { line };
		}
		bool[] array = new bool[count - 1];
		bool flag = false;
		float num2 = radius * radius;
		for (int k = 0; k < count - 1; k++)
		{
			Vector3 p = (list2[k] + list2[k + 1]) * 0.5f;
			array[k] = DistSqToSegmentXZ(p, vector, vector2) <= num2;
			flag |= array[k];
		}
		if (!flag)
		{
			return new List<AqueductLine> { line };
		}
		line.DisableSegmentColliders();
		float[] array2 = new float[count];
		float num3 = 0f;
		for (int l = 1; l < count; l++)
		{
			num3 += Mathff.Dist(list2[l - 1], list2[l]);
		}
		if (num3 > 1E-05f)
		{
			float num4 = 0f;
			for (int m = 1; m < count; m++)
			{
				num4 += Mathff.Dist(list2[m - 1], list2[m]);
				array2[m] = num4 / num3;
			}
		}
		int num5 = 0;
		while (num5 < count - 1)
		{
			bool flag2 = array[num5];
			int n;
			for (n = num5; n + 1 < count - 1 && array[n + 1] == flag2; n++)
			{
			}
			List<Vector3> range = list2.GetRange(num5, n + 1 - num5 + 1);
			bool flag3 = num5 == 0;
			bool flag4 = n + 1 == count - 1;
			float num6 = PolyLength(range);
			if (flag2)
			{
				if (num6 > 0.05f)
				{
					SpawnDebrisHusk(range.ToArray());
				}
			}
			else
			{
				if (!flag3)
				{
					PeelCarvedTerminal(range, atStart: true);
				}
				if (!flag4)
				{
					PeelCarvedTerminal(range, atStart: false);
				}
				if (PolyLength(range) >= num)
				{
					AqueductLine aqueductLine = BuildSurvivorPiece(range, flag3 ? startBuilding : null, flag4 ? endBuilding : null);
					if (aqueductLine != null)
					{
						TransferWater(line, aqueductLine, array2[num5], array2[n + 1]);
						aqueductLine.SetWaterFlow(0f);
						list.Add(aqueductLine);
					}
				}
			}
			num5 = n + 1;
		}
		startBuilding?.RemoveAqueductLine(line);
		endBuilding?.RemoveAqueductLine(line);
		(startBuilding as AqueductJunction)?.RemoveIfDangling();
		(endBuilding as AqueductJunction)?.RemoveIfDangling();
		if (allLines.Contains(line))
		{
			allLines.Remove(line);
		}
		UnityEngine.Object.Destroy(line.gameObject);
		AqueductFlowController.MarkTopologyDirty("CutLine");
		return list;
	}

	public static List<AqueductLine> CutAllLinesInRadius(Vector3 point, float radius, float minRemnantLength = 0f)
	{
		return CutAllLinesAlongSegment(point, point, radius, minRemnantLength);
	}

	public static List<AqueductLine> CutAllLinesAlongSegment(Vector3 from, Vector3 to, float radius, float minRemnantLength = 0f)
	{
		List<AqueductLine> list = new List<AqueductLine>();
		if (radius <= 0f)
		{
			return list;
		}
		Vector2 a = new Vector2(from.x, from.z);
		Vector2 b = new Vector2(to.x, to.z);
		float num = radius * radius;
		AqueductJunction[] array = AqueductJunction.SnapshotAll();
		foreach (AqueductJunction aqueductJunction in array)
		{
			if (aqueductJunction != null && DistSqToSegmentXZ(aqueductJunction.transform.position, a, b) <= num)
			{
				aqueductJunction.ClearAndRemove(minRemnantLength);
			}
		}
		AqueductLine[] array2 = allLines.ToArray();
		using (AqueductJunction.SuppressCollapseScope())
		{
			foreach (AqueductLine aqueductLine in array2)
			{
				if (!(aqueductLine == null) && !aqueductLine.displayOnly && aqueductLine.fullyConstructed)
				{
					List<AqueductLine> list2 = CutLine(aqueductLine, from, to, radius, minRemnantLength);
					if (list2.Count != 1 || !(list2[0] == aqueductLine))
					{
						list.AddRange(list2);
					}
				}
			}
		}
		AqueductJunction[] array3 = AqueductJunction.SnapshotAll();
		foreach (AqueductJunction aqueductJunction2 in array3)
		{
			if (!(aqueductJunction2 == null))
			{
				aqueductJunction2.RemoveIfDangling();
				if (aqueductJunction2 != null)
				{
					aqueductJunction2.TryCollapseLines();
				}
			}
		}
		return list;
	}

	private static void CollectCapsuleCrossings(Vector3 A, Vector3 B, Vector2 capA, Vector2 capB, float radius, List<float> tsOut)
	{
		CollectCircleCrossings(A, B, capA, radius, tsOut);
		CollectCircleCrossings(A, B, capB, radius, tsOut);
		Vector2 vector = capB - capA;
		float magnitude = vector.magnitude;
		if (magnitude < 1E-05f)
		{
			return;
		}
		Vector2 rhs = new Vector2(0f - vector.y, vector.x) / magnitude;
		Vector2 vector2 = new Vector2(A.x, A.z);
		float num = Vector2.Dot(new Vector2(B.x - A.x, B.z - A.z), rhs);
		if (!(Mathf.Abs(num) < 1E-08f))
		{
			float num2 = Vector2.Dot(vector2 - capA, rhs);
			float num3 = (radius - num2) / num;
			float num4 = (0f - radius - num2) / num;
			if (num3 > 0.0001f && num3 < 0.9999f)
			{
				tsOut.Add(num3);
			}
			if (num4 > 0.0001f && num4 < 0.9999f)
			{
				tsOut.Add(num4);
			}
		}
	}

	private static float DistSqToSegmentXZ(Vector3 p, Vector2 a, Vector2 b)
	{
		Vector2 vector = new Vector2(p.x, p.z);
		Vector2 vector2 = b - a;
		float sqrMagnitude = vector2.sqrMagnitude;
		float num = ((sqrMagnitude > 1E-08f) ? Mathf.Clamp01(Vector2.Dot(vector - a, vector2) / sqrMagnitude) : 0f);
		Vector2 vector3 = a + vector2 * num;
		return (vector - vector3).sqrMagnitude;
	}

	private static void CollectCircleCrossings(Vector3 A, Vector3 B, Vector2 center, float radius, List<float> tsOut)
	{
		Vector2 vector = new Vector2(A.x, A.z);
		Vector2 vector2 = new Vector2(B.x, B.z) - vector;
		float num = Vector2.Dot(vector2, vector2);
		if (num < 1E-08f)
		{
			return;
		}
		Vector2 vector3 = vector - center;
		float num2 = 2f * Vector2.Dot(vector3, vector2);
		float num3 = Vector2.Dot(vector3, vector3) - radius * radius;
		float num4 = num2 * num2 - 4f * num * num3;
		if (!(num4 <= 0f))
		{
			float num5 = Mathf.Sqrt(num4);
			float num6 = (0f - num2 - num5) / (2f * num);
			float num7 = (0f - num2 + num5) / (2f * num);
			if (num6 > 0.0001f && num6 < 0.9999f)
			{
				tsOut.Add(num6);
			}
			if (num7 > 0.0001f && num7 < 0.9999f)
			{
				tsOut.Add(num7);
			}
		}
	}

	private static float PolyLength(List<Vector3> verts)
	{
		float num = 0f;
		for (int i = 0; i < verts.Count - 1; i++)
		{
			num += Vector3.Distance(verts[i], verts[i + 1]);
		}
		return num;
	}

	private static void PeelCarvedTerminal(List<Vector3> runVerts, bool atStart)
	{
		while (runVerts.Count > 2)
		{
			int index = ((!atStart) ? (runVerts.Count - 1) : 0);
			int index2 = (atStart ? 1 : (runVerts.Count - 2));
			if (!((runVerts[index] - runVerts[index2]).sqrMagnitude >= 0.122499995f))
			{
				runVerts.RemoveAt(index);
				continue;
			}
			break;
		}
	}

	private static void TransferWater(AqueductLine src, AqueductLine dst, float tStart, float tEnd)
	{
		if (src == null || dst == null)
		{
			return;
		}
		float num = Mathf.Max(tEnd - tStart, 0.0001f);
		dst.waterFlowStateTransitionNodes.Clear();
		List<WaterFlowStateTransitionNodes> list = src.waterFlowStateTransitionNodes;
		if (list != null)
		{
			for (int i = 0; i < list.Count; i++)
			{
				WaterFlowStateTransitionNodes waterFlowStateTransitionNodes = list[i];
				if (waterFlowStateTransitionNodes != null && !(waterFlowStateTransitionNodes.T <= tStart) && !(waterFlowStateTransitionNodes.T >= tEnd))
				{
					dst.waterFlowStateTransitionNodes.Add(new WaterFlowStateTransitionNodes
					{
						T = Mathf.Clamp01((waterFlowStateTransitionNodes.T - tStart) / num),
						waterAmount = waterFlowStateTransitionNodes.waterAmount
					});
				}
			}
		}
		dst.currentInputFlow = WaterLevelAt(src, tStart);
		dst.currentOutputFlow = WaterLevelAt(src, tEnd);
		dst.hasWater = dst.currentInputFlow > 0f || dst.currentOutputFlow > 0f;
	}

	private static float WaterLevelAt(AqueductLine line, float t)
	{
		t = Mathf.Clamp01(t);
		if (t <= 0f)
		{
			return line.currentInputFlow;
		}
		List<WaterFlowStateTransitionNodes> list = line.waterFlowStateTransitionNodes;
		if (list != null)
		{
			for (int i = 0; i < list.Count; i++)
			{
				if (list[i] != null && list[i].T >= t)
				{
					return list[i].waterAmount;
				}
			}
		}
		return line.currentOutputFlow;
	}

	private static AqueductLine BuildSurvivorPiece(List<Vector3> runVerts, AqueductBuilding leadingBuilding, AqueductBuilding trailingBuilding)
	{
		Vector3[] middleWaypoints = ExtractMiddleWaypoints(runVerts);
		if (leadingBuilding != null && trailingBuilding != null)
		{
			return CreateInstantLine(leadingBuilding, middleWaypoints, trailingBuilding);
		}
		if (leadingBuilding != null)
		{
			return CreateInstantLineOneOpen(leadingBuilding, middleWaypoints, runVerts[runVerts.Count - 1], openIsStart: false);
		}
		if (trailingBuilding != null)
		{
			return CreateInstantLineOneOpen(trailingBuilding, middleWaypoints, runVerts[0], openIsStart: true);
		}
		return CreateInstantLineBothOpen(runVerts.ToArray());
	}

	internal static AqueductLine CreateInstantLineBothOpen(Vector3[] fullWaypoints)
	{
		if (fullWaypoints == null || fullWaypoints.Length < 2)
		{
			return null;
		}
		AqueductLine aqueductLine = InstantiateLinePrefab();
		aqueductLine.DisplayOnly(b: false);
		aqueductLine.SetStartEndOpen(null, startIsOpen: true, null, endIsOpen: true, fullWaypoints);
		if (!aqueductLine.InitInstantLineState())
		{
			return null;
		}
		AqueductFlowController.MarkTopologyDirty("CreateInstantLineBothOpen");
		return aqueductLine;
	}

	private static void SpawnDebrisHusk(Vector3[] fullWaypoints)
	{
		if (fullWaypoints != null && fullWaypoints.Length >= 2)
		{
			AqueductLine aqueductLine = InstantiateLinePrefab();
			aqueductLine.DisplayOnly(b: false);
			aqueductLine.SetStartEndOpen(null, startIsOpen: true, null, endIsOpen: true, fullWaypoints);
			if (aqueductLine.InitInstantLineState())
			{
				allLines.Remove(aqueductLine);
				aqueductLine.DisableSegmentColliders();
				aqueductLine.UnregisterFromInstanceManager();
				aqueductLine.collapse = true;
			}
		}
	}

	public static void GradeWaypoints(ref Vector3[] waypointArray)
	{
		float y = waypointArray[0].y;
		float y2 = waypointArray[^1].y;
		float num = 0f;
		float[] array = new float[waypointArray.Length];
		array[0] = 0f;
		for (int i = 1; i < waypointArray.Length; i++)
		{
			Vector3 vector = waypointArray[i - 1];
			Vector3 vector2 = waypointArray[i];
			float num2 = Vector2.Distance(new Vector2(vector.x, vector.z), new Vector2(vector2.x, vector2.z));
			num = (array[i] = num + num2);
		}
		for (int j = 0; j < waypointArray.Length; j++)
		{
			float t = ((num > 0f) ? (array[j] / num) : 0f);
			waypointArray[j].y = Mathf.Lerp(y, y2, t);
		}
	}

	public void SetStartEnd()
	{
		SetStartEnd(null, new Vector3[2]
		{
			Vector3.zero,
			Vector3.zero
		}, null);
		landmass = Player.inst.FocusedLandMassIdxLastValid;
	}

	public void SetStartEnd(AqueductBuilding start, Vector3[] middleWaypoints, AqueductBuilding end, bool autoGrade = true)
	{
		waypoints = middleWaypoints;
		if ((bool)start)
		{
			landmass = start.GetLandMass();
			startAB = start;
			endAB = end;
			Vector3 element = ((middleWaypoints.Length != 0) ? start.GetPortPosition(middleWaypoints[0]) : start.GetPortPosition(end.Center()));
			Vector3 element2 = ((middleWaypoints.Length != 0) ? end.GetPortPosition(middleWaypoints[^1]) : end.GetPortPosition(start.Center()));
			waypoints = middleWaypoints.Prepend(element).Append(element2).ToArray();
		}
		if (autoGrade)
		{
			GradeWaypoints(ref waypoints);
		}
		InitConstructionAndMaterials();
	}

	internal void SetStartEndOpen(AqueductBuilding start, bool startIsOpen, AqueductBuilding end, bool endIsOpen, Vector3[] fullWaypoints, bool autoGrade = false)
	{
		waypoints = fullWaypoints;
		startAB = (startIsOpen ? null : start);
		endAB = (endIsOpen ? null : end);
		startOpen = startIsOpen;
		endOpen = endIsOpen;
		if (!startIsOpen && start != null)
		{
			landmass = start.GetLandMass();
		}
		else if (!endIsOpen && end != null)
		{
			landmass = end.GetLandMass();
		}
		else
		{
			landmass = World.inst.GetCellDataClamped(fullWaypoints[0]).landMassIdx;
		}
		if (autoGrade)
		{
			GradeWaypoints(ref waypoints);
		}
		InitConstructionAndMaterials();
	}

	private void EnsureValidLandmass()
	{
		if (IsValidLandmass(landmass))
		{
			return;
		}
		landmass = ((endAB != null) ? endAB.GetLandMass() : (-1));
		for (int i = 0; i < waypoints.Length; i++)
		{
			if (IsValidLandmass(landmass))
			{
				break;
			}
			landmass = World.inst.GetCellDataClamped(waypoints[i]).landMassIdx;
		}
		if (!IsValidLandmass(landmass))
		{
			landmass = Player.inst.FocusedLandMassIdxLastValid;
		}
		if (!IsValidLandmass(landmass))
		{
			landmass = 0;
		}
	}

	private static bool IsValidLandmass(int idx)
	{
		if (idx >= 0)
		{
			return idx < World.inst.NumLandMasses;
		}
		return false;
	}

	private void InitConstructionAndMaterials()
	{
		EnsureValidLandmass();
		LandmassOwner landmassOwner = World.GetLandmassOwner(LandMass());
		if (landmassOwner == null)
		{
			landmassOwner = Player.inst.PlayerLandmassOwner;
		}
		int num = NumberOfConstructions();
		DestroyRuntimeMaterials();
		buildingMaterial = new Material[num];
		for (int i = 0; i < buildingMaterial.Length; i++)
		{
			Material material = new Material(landmassOwner.BuildingMaterial);
			material.SetFloat("_Disabled", 0f);
			material.SetFloat("_Invalid", 0f);
			material.SetFloat("_WallProgress", 1f);
			material.SetFloat("_MinHeight", float.MinValue);
			material.SetFloat("_MaxHeight", float.MaxValue);
			material.SetVector("_BreakPoint", Vector4.zero);
			material.SetVector("_BreakOffset", Vector4.zero);
			material.SetFloat("_MinYAdjustment", 0f);
			material.SetFloat("_MaxYAdjustment", 0f);
			material.SetFloat("_Width", World.inst.GridWidth);
			material.SetFloat("_Height", World.inst.GridHeight);
			material.enableInstancing = true;
			buildingMaterial[i] = material;
		}
		invalidMaterial = new Material(landmassOwner.BuildingMaterial);
		invalidMaterial.SetFloat("_Disabled", 0f);
		invalidMaterial.SetFloat("_Invalid", 1f);
		invalidMaterial.SetFloat("_WallProgress", 1f);
		invalidMaterial.SetFloat("_MinHeight", float.MinValue);
		invalidMaterial.SetFloat("_MaxHeight", float.MaxValue);
		invalidMaterial.SetVector("_BreakPoint", Vector4.zero);
		invalidMaterial.SetVector("_BreakOffset", Vector4.zero);
		invalidMaterial.SetFloat("_MinYAdjustment", 0f);
		invalidMaterial.SetFloat("_MaxYAdjustment", 0f);
		invalidMaterial.SetFloat("_Width", World.inst.GridWidth);
		invalidMaterial.SetFloat("_Height", World.inst.GridHeight);
		invalidMaterial.enableInstancing = true;
		constructionFootprint = new Vector2Int[num][];
		for (int j = 0; j < constructionFootprint.Length; j++)
		{
			constructionFootprint[j] = new Vector2Int[2];
		}
		didConstructionPuff = new bool[num];
		constructionForemans = new ConstructionForeman[num];
		for (int k = 0; k < constructionForemans.Length; k++)
		{
			constructionForemans[k] = new ConstructionForeman();
			constructionForemans[k].Init(this, GetBuildAllowedWorkers(), k, doHideIfManualJob: true);
			constructionForemans[k].AddJobsWithManualAssignment();
		}
		CalculateSegmentTunnelStatus();
		highlight = ObjectHighlighter.SetupOutline(gameObject, this, formToTerrain: false, clipOnTerrain: true);
		props = new MaterialPropertyBlock();
		props.SetFloat("_UScrollSpeed", 1f);
	}

	public AqueductBuilding GetStartBuilding()
	{
		return startAB;
	}

	public AqueductBuilding GetEndBuilding()
	{
		return endAB;
	}

	public void OnEnable()
	{
		waterMesh = new Mesh();
		waterMesh.MarkDynamic();
		arrowMesh = new Mesh();
		arrowMesh.MarkDynamic();
	}

	public void OnDisable()
	{
		if (waterMesh != null)
		{
			UnityEngine.Object.Destroy(waterMesh);
			waterMesh = null;
		}
		if (arrowMesh != null)
		{
			UnityEngine.Object.Destroy(arrowMesh);
			arrowMesh = null;
		}
		for (int i = 0; i < segmentColliders.Length; i++)
		{
			if (segmentColliders[i] != null && segmentColliders[i].sharedMesh != null)
			{
				UnityEngine.Object.Destroy(segmentColliders[i].sharedMesh);
				segmentColliders[i].sharedMesh = null;
			}
		}
	}

	private void Awake()
	{
		cachedTerrainMask = LayerMask.GetMask("Terrain");
		cachedDefaultTerrainMask = LayerMask.GetMask("Default", "Terrain");
	}

	private void RegisterWithInstanceManager()
	{
		if (!_usingInstancedRendering && !displayOnly)
		{
			_renderInstances = new List<RenderInstance>();
			AddMatrices(topMatrices, aqueductStraight);
			AddMatrices(middleMatrices, aqueductArch);
			AddMatrices(pipeMatrices, aqueductPipe);
			AddMatrices(pipeSideLeftMatrices, aqueductPipeSide);
			AddMatrices(pipeSideRightMatrices, aqueductPipeSide);
			AddMatrices(pipeSideConnectorMatrices, aqueductPipeSide);
			AddMatrices(endMatrices, aqueductEnd);
			AddMatrices(endMatricesTop, aqueductEndTop);
			AddMatrices(tunnelMatrices, aqueductTunnel);
			AddMatrices(elbowMatrices, elbowMesh);
			AddMatrices(elbowMatricesTop, elbowMeshTop);
			_usingInstancedRendering = true;
		}
		void AddMatrices(Matrix4x4[] matrices, Mesh mesh)
		{
			if (matrices != null && !(mesh == null))
			{
				for (int i = 0; i < matrices.Length; i++)
				{
					RenderInstance renderInstance = new RenderInstance(mesh, material);
					renderInstance.UpdateMatrix(matrices[i]);
					renderInstance.Visible = true;
					_renderInstances.Add(renderInstance);
				}
			}
		}
	}

	private void UnregisterFromInstanceManager()
	{
		if (_usingInstancedRendering && _renderInstances != null)
		{
			for (int i = 0; i < _renderInstances.Count; i++)
			{
				_renderInstances[i].Visible = false;
			}
			_renderInstances.Clear();
			_renderInstances = null;
			_usingInstancedRendering = false;
		}
	}

	public void OnDestroy()
	{
		UnregisterFromInstanceManager();
		if (highlight != null)
		{
			highlight.Release();
		}
		DestroyRuntimeMaterials();
	}

	private void DestroyRuntimeMaterials()
	{
		if (buildingMaterial != null)
		{
			for (int i = 0; i < buildingMaterial.Length; i++)
			{
				UnityEngine.Object.Destroy(buildingMaterial[i]);
			}
			buildingMaterial = null;
		}
		if (invalidMaterial != null)
		{
			UnityEngine.Object.Destroy(invalidMaterial);
			invalidMaterial = null;
		}
	}

	public int NumberOfMeshes()
	{
		return NumberOfMeshes(waypoints);
	}

	private int NumberOfMeshes(Vector3[] points)
	{
		float z = aqueductStraight.bounds.size.z;
		int num = 0;
		if (points != null && points.Length != 0)
		{
			for (int i = 0; i < points.Length - 1; i++)
			{
				num += Mathf.FloorToInt(Mathff.Dist(points[i], points[i + 1]) / z);
			}
		}
		return num;
	}

	public int NumberOfConstructions()
	{
		return NumberOfConstructions(waypoints);
	}

	private int NumberOfConstructions(Vector3[] points)
	{
		return NumberOfMeshes(points) + points.Length - 2;
	}

	public void BuildPersonPositions()
	{
		Vector3 up = Vector3.up;
		Ray ray = new Ray(Vector3.zero, Vector3.down);
		if (fullyConstructed || personPositions != null)
		{
			return;
		}
		int num = 0;
		personPositions = new Vector3[NumberOfConstructions()][];
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			Vector3 vector = waypoints[i];
			Vector3 vector2 = waypoints[i + 1];
			float z = aqueductStraight.bounds.size.z;
			float num2 = Mathff.Dist(vector, vector2);
			int num3 = Mathf.FloorToInt(num2 / z);
			float num4 = num2 - (float)num3 * z;
			Vector3 normalized = (vector2 - vector).normalized;
			if (i != 0)
			{
				personPositions[num] = new Vector3[GetBuildAllowedWorkers()];
				for (int j = 0; j < GetBuildAllowedWorkers(); j++)
				{
					ray.origin = vector + up * 1000f + new Vector3(SRand.Range(-0.5f, 0.5f), 0f, SRand.Range(-0.5f, 0.5f));
					if (Physics.Raycast(ray, out var hitInfo, 2000f, cachedTerrainMask))
					{
						personPositions[num][j] = hitInfo.point;
					}
				}
				Cell cellData = World.inst.GetCellData(vector);
				constructionFootprint[num][0].x = cellData.x;
				constructionFootprint[num][0].y = cellData.z;
				constructionFootprint[num][1].x = cellData.x;
				constructionFootprint[num][1].y = cellData.z;
				num++;
			}
			int num5 = 0;
			while (num5 < num3)
			{
				personPositions[num] = new Vector3[GetBuildAllowedWorkers()];
				Vector3 vector3 = vector + num5 * normalized * z + normalized * z * 0.5f + normalized * num4 * 0.5f;
				for (int k = 0; k < GetBuildAllowedWorkers(); k++)
				{
					ray.origin = vector3 + up * 1000f + new Vector3(SRand.Range(-0.5f, 0.5f), 0f, SRand.Range(-0.5f, 0.5f));
					if (Physics.Raycast(ray, out var hitInfo2, 2000f, cachedTerrainMask))
					{
						personPositions[num][k] = hitInfo2.point;
					}
				}
				Cell cellData2 = World.inst.GetCellData(vector3);
				constructionFootprint[num][0].x = cellData2.x;
				constructionFootprint[num][0].y = cellData2.z;
				constructionFootprint[num][1].x = cellData2.x;
				constructionFootprint[num][1].y = cellData2.z;
				num5++;
				num++;
			}
		}
	}

	public void DoBuildPuff()
	{
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			Vector3 vector = waypoints[i];
			Vector3 vector2 = waypoints[i + 1];
			float z = aqueductStraight.bounds.size.z;
			float num = Mathff.Dist(vector, vector2);
			int num2 = Mathf.FloorToInt(num / z);
			float num3 = num - (float)num2 * z;
			Vector3 normalized = (vector2 - vector).normalized;
			for (int j = 0; j < num2; j++)
			{
				Vector3 pos = vector + j * normalized * z + normalized * z * 0.5f + normalized * num3 * 0.5f;
				TerrainGen.inst.GetGroundHeight(ref pos);
				pos.y += 0.1f;
				EffectsMan.inst.BuildEffectPuffSmall.CreateAndPlay(pos);
			}
		}
		RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_place_building_large", Vector3.Lerp(waypoints[0], waypoints[waypoints.Length - 1], 0.5f));
	}

	private void AppendTunnelMatrices(Vector3 start, Vector3 end, Vector3 dir, float lineDist, Vector3 collapseOffset, List<Matrix4x4> output)
	{
		tunnelSpans.Clear();
		AppendSolidSpans(start, end, dir, lineDist, tunnelSpans);
		AppendBuriedSpans(start, dir, lineDist, tunnelSpans);
		if (tunnelSpans.Count == 0)
		{
			return;
		}
		tunnelSpans.Sort(tunnelSpanComparison);
		int num = 0;
		for (int i = 1; i < tunnelSpans.Count; i++)
		{
			if (tunnelSpans[i].x <= tunnelSpans[num].y + 0.02f)
			{
				tunnelSpans[num] = new float2(tunnelSpans[num].x, Mathf.Max(tunnelSpans[num].y, tunnelSpans[i].y));
			}
			else
			{
				tunnelSpans[++num] = tunnelSpans[i];
			}
		}
		tunnelSpans.RemoveRange(num + 1, tunnelSpans.Count - num - 1);
		Matrix4x4 mat = default;
		Quaternion rot = Quaternion.LookRotation(dir, Vector3.up);
		float z = aqueductTunnel.bounds.size.z;
		for (int j = 0; j < tunnelSpans.Count; j++)
		{
			float num2 = tunnelSpans[j].y - tunnelSpans[j].x;
			if (!(num2 < 0.02f))
			{
				Vector3 vector = start + dir * (tunnelSpans[j].x + num2 * 0.5f);
				Mathff.SetTRS(scale: new Vector3(pipeScale.x, pipeScale.y, num2 / z), mat: ref mat, pos: vector + collapseOffset, rot: rot);
				output.Add(mat);
			}
		}
	}

	private void AppendSolidSpans(Vector3 start, Vector3 end, Vector3 dir, float lineDist, List<float2> spans)
	{
		Vector3 vector = end - start;
		Vector3 vector2 = start - end;
		Quaternion orientation = Quaternion.LookRotation(vector);
		Quaternion orientation2 = Quaternion.LookRotation(vector2);
		Vector3 flatDir = dir;
		flatDir.y = 0f;
		flatDir.Normalize();
		RaycastHit[] array = Physics.BoxCastAll(start + tunnelRaycastOffset, tunnelRaycastExtents, vector, orientation, lineDist, cachedDefaultTerrainMask);
		RaycastHit[] array2 = Physics.BoxCastAll(end + tunnelRaycastOffset, tunnelRaycastExtents, vector2, orientation2, lineDist, cachedDefaultTerrainMask);
		solidHitPairs.Clear();
		for (int i = 0; i < array.Length; i++)
		{
			Collider collider = array[i].collider;
			if (!SkipForTunnelDetection(collider, flatDir))
			{
				float num = (IsOverlapHit(in array[i]) ? 0f : array[i].distance);
				int instanceID = collider.GetInstanceID();
				solidHitPairs.TryGetValue(instanceID, out var value);
				value.collider = collider;
				value.inDist = (value.hasIn ? Mathf.Min(value.inDist, num) : num);
				value.hasIn = true;
				solidHitPairs[instanceID] = value;
			}
		}
		for (int j = 0; j < array2.Length; j++)
		{
			Collider collider2 = array2[j].collider;
			if (!SkipForTunnelDetection(collider2, flatDir))
			{
				float num2 = (IsOverlapHit(in array2[j]) ? lineDist : (lineDist - array2[j].distance));
				int instanceID2 = collider2.GetInstanceID();
				solidHitPairs.TryGetValue(instanceID2, out var value2);
				value2.collider = collider2;
				value2.outDist = (value2.hasOut ? Mathf.Max(value2.outDist, num2) : num2);
				value2.hasOut = true;
				solidHitPairs[instanceID2] = value2;
			}
		}
		foreach (KeyValuePair<int, SolidHitPair> solidHitPair in solidHitPairs)
		{
			SolidHitPair value3 = solidHitPair.Value;
			float num3 = value3.inDist;
			float num4 = value3.outDist;
			if (!value3.hasIn || !value3.hasOut)
			{
				BoundsSpanAlongLine(value3.collider.bounds, start + tunnelRaycastOffset, dir, lineDist, out var entry, out var exit);
				if (!value3.hasIn)
				{
					num3 = Mathf.Min(entry, value3.hasOut ? num4 : lineDist);
				}
				if (!value3.hasOut)
				{
					num4 = Mathf.Max(exit, value3.hasIn ? num3 : 0f);
				}
			}
			if (num4 - num3 > 0.02f)
			{
				spans.Add(new float2(num3, num4));
			}
		}
	}

	private static bool IsOverlapHit(in RaycastHit hit)
	{
		if (hit.distance <= 0f)
		{
			return hit.point == Vector3.zero;
		}
		return false;
	}

	private bool SkipForTunnelDetection(Collider collider, Vector3 flatDir)
	{
		if (collider.GetComponent<TerrainChunk>() != null)
		{
			return true;
		}
		if (collider.transform.parent == transform)
		{
			return true;
		}
		if (collider.GetComponentInParent<AqueductLine>() != null)
		{
			Vector3 forward = collider.transform.forward;
			forward.y = 0f;
			if (forward.sqrMagnitude > 1E-06f && Mathf.Abs(Vector3.Dot(flatDir, forward.normalized)) >= 0.996f)
			{
				return true;
			}
		}
		return false;
	}

	private static void BoundsSpanAlongLine(Bounds bounds, Vector3 origin, Vector3 dir, float lineDist, out float entry, out float exit)
	{
		float num = 0f;
		float a = lineDist;
		for (int i = 0; i < 3; i++)
		{
			float num2 = origin[i];
			float num3 = dir[i];
			if (!(Mathf.Abs(num3) < 1E-06f))
			{
				float num4 = (bounds.min[i] - num2) / num3;
				float num5 = (bounds.max[i] - num2) / num3;
				if (num4 > num5)
				{
					float num6 = num5;
					float num7 = num4;
					num4 = num6;
					num5 = num7;
				}
				num = Mathf.Max(num, num4);
				a = Mathf.Min(a, num5);
			}
		}
		entry = Mathf.Clamp(num, 0f, lineDist);
		exit = Mathf.Clamp(Mathf.Max(a, num), 0f, lineDist);
	}

	private void AppendBuriedSpans(Vector3 start, Vector3 dir, float lineDist, List<float2> spans)
	{
		float x = 0f;
		float num = 0f;
		bool flag = IsLineBuried(start);
		float num2 = 0.5f;
		while (num < lineDist)
		{
			if (num2 > lineDist)
			{
				num2 = lineDist;
			}
			bool flag2 = IsLineBuried(start + dir * num2);
			if (flag2 != flag)
			{
				float num3 = RefineBuriedCrossing(start, dir, num, num2, flag);
				if (flag)
				{
					spans.Add(new float2(x, num3));
				}
				else
				{
					x = num3;
				}
				flag = flag2;
			}
			num = num2;
			num2 += 0.5f;
		}
		if (flag)
		{
			spans.Add(new float2(x, lineDist));
		}
	}

	private float RefineBuriedCrossing(Vector3 start, Vector3 dir, float nearDist, float farDist, bool stateAtNear)
	{
		for (int i = 0; i < 6; i++)
		{
			float num = (nearDist + farDist) * 0.5f;
			if (IsLineBuried(start + dir * num) == stateAtNear)
			{
				nearDist = num;
			}
			else
			{
				farDist = num;
			}
		}
		return (nearDist + farDist) * 0.5f;
	}

	private bool IsLineBuried(Vector3 p)
	{
		float num = tunnelRaycastOffset.y - tunnelRaycastExtents.y;
		float interpolatedHeight = TerrainGen.inst.GetInterpolatedHeight(p);
		if (p.y + num <= interpolatedHeight)
		{
			return true;
		}
		if (DynamicWater.inst.currentWaterHeightMap != null)
		{
			float exactWaterAmount = DynamicWater.inst.GetExactWaterAmount(p);
			if (exactWaterAmount > 0f && p.y + num <= interpolatedHeight + exactWaterAmount)
			{
				return true;
			}
		}
		return false;
	}

	public void FullBuild()
	{
		bool flag = fullyConstructed;
		bool flag2 = false;
		if (collapse)
		{
			float num = Mathf.Ceil(collapseTime);
			collapseTime += Time.deltaTime;
			if (collapseTime > num)
			{
				flag2 = true;
			}
		}
		Vector3 up = Vector3.up;
		Vector3 down = Vector3.down;
		Vector3 forward = Vector3.forward;
		Vector3 vector = collapseTime * down;
		if (displayOnly)
		{
			fullyConstructed = true;
		}
		else if (Creative.inst.IsCreativeOptionOn(11))
		{
			if (!fullyConstructed && !Creative.inst.IsCreativeOptionOn(0))
			{
				for (int i = 0; i < constructionForemans.Length; i++)
				{
					constructionForemans[i].ConsumeOutstandingCostFromWorld();
				}
			}
			fullyConstructed = true;
			AqueductFlowController.MarkTopologyDirty("FullBuild");
			if (startAB != null)
			{
				startAB.UpdateWaterFlow();
			}
			for (int j = 0; j < constructionForemans.Length; j++)
			{
				constructionForemans[j].RemoveJobs();
			}
			MilestoneManager.inst.CheckAbsurdAqueductMilestone(NumberOfConstructions());
		}
		if (!fullyConstructed)
		{
			fullyConstructed = true;
			for (int k = 0; k < constructionForemans.Length; k++)
			{
				ConstructionForeman constructionForeman = constructionForemans[k];
				if (constructionForeman.ConstructionProgress >= 1f && !isProjectPaused && !constructionForeman.ConstructionPaused)
				{
					constructionForeman.ConstructionPaused = true;
					constructionForeman.RemoveJobs();
					meshesUnderConstruction = Mathff.Max(0, meshesUnderConstruction - 1);
				}
			}
			for (int l = 0; l < constructionForemans.Length; l++)
			{
				ConstructionForeman constructionForeman2 = constructionForemans[l];
				if (constructionForeman2.ConstructionProgress < 1f)
				{
					fullyConstructed = false;
					if (!isProjectPaused && constructionForeman2.ConstructionPaused && meshesUnderConstruction < meshesToConstructAtOnce)
					{
						constructionForeman2.ConstructionPaused = false;
						meshesUnderConstruction++;
					}
				}
			}
			if (fullyConstructed)
			{
				AqueductFlowController.MarkTopologyDirty("FullBuild");
				if (startAB != null)
				{
					startAB.UpdateWaterFlow();
				}
				if (!LoadSave.Loading)
				{
					RuntimeManager.PlayOneShot(onBuildingCompleteEvent.Guid, Center());
					MilestoneManager.inst.TryFirstAqueductMilestone();
					MilestoneManager.inst.CheckAbsurdAqueductMilestone(NumberOfConstructions());
				}
				for (int m = 0; m < constructionForemans.Length; m++)
				{
					constructionForemans[m].RemoveJobs();
				}
				if (startAB is AqueductJunction aqueductJunction)
				{
					aqueductJunction.TryCollapseLines();
				}
				if (this == null)
				{
					return;
				}
				if (endAB is AqueductJunction aqueductJunction2)
				{
					aqueductJunction2.TryCollapseLines();
				}
				if (this == null)
				{
					return;
				}
			}
		}
		int num2 = NumberOfConstructions();
		Quaternion identity = Quaternion.identity;
		Vector3 one = Vector3.one;
		Matrix4x4 mat = default;
		Matrix4x4 mat2 = default;
		isSegmentTunnel = new bool[num2];
		ClearMaterialIndexBuilders();
		if (pipeMatricesForConstruction == null || pipeMatricesForConstruction.Length != num2)
		{
			pipeMatricesForConstruction = new Matrix4x4[num2];
			pipeSideLeftMatricesForConstruction = new Matrix4x4[num2];
			pipeSideRightMatricesForConstruction = new Matrix4x4[num2];
			stakesForConstruction = new Matrix4x4[num2];
		}
		else
		{
			Array.Clear(pipeMatricesForConstruction, 0, num2);
			Array.Clear(pipeSideLeftMatricesForConstruction, 0, num2);
			Array.Clear(pipeSideRightMatricesForConstruction, 0, num2);
			Array.Clear(stakesForConstruction, 0, num2);
		}
		BuildPersonPositions();
		float[] array = BuildRailPullbacks();
		sideConnectors.Clear();
		int num3 = waypoints.Length - 1;
		Vector3[] array2 = new Vector3[num3];
		Vector3[] array3 = new Vector3[num3];
		Vector3[] array4 = new Vector3[num3];
		Vector3[] array5 = new Vector3[num3];
		Vector3[] array6 = new Vector3[num3];
		int num4 = 0;
		numOfFullCost = 0;
		numOfReducedCost = 0;
		_waypointGroundY = new float[waypoints.Length];
		float[] waypointGroundY = _waypointGroundY;
		Ray ray = new Ray(Vector3.zero, down);
		for (int n = 0; n < waypoints.Length; n++)
		{
			ray.origin = waypoints[n] + up * 50f;
			waypointGroundY[n] = (Physics.Raycast(ray, out var hitInfo, 100f, cachedTerrainMask) ? hitInfo.point.y : waypoints[n].y);
		}
		for (int num5 = 0; num5 < waypoints.Length - 1; num5++)
		{
			Vector3 vector2 = waypoints[num5];
			Vector3 vector3 = waypoints[num5 + 1];
			float z = aqueductStraight.bounds.size.z;
			float num6 = Mathff.Dist(vector2, vector3);
			int num7 = Mathf.FloorToInt(num6 / z);
			float num8 = num6 - (float)num7 * z;
			Vector3 normalized = (vector3 - vector2).normalized;
			fullyCollapsed = collapse;
			if (num5 != 0)
			{
				Vector3 forward2 = (vector3 - vector2).xz();
				Quaternion rot = ((forward2.sqrMagnitude > 0.0001f) ? Quaternion.LookRotation(forward2, up) : identity);
				float num9 = (fullyConstructed ? 1f : constructionForemans[num4].ConstructionProgress);
				float num10 = waypointGroundY[num5];
				isSegmentTunnel[num4] = vector2.y <= num10;
				if (num9 >= 1f)
				{
					Vector3 vector4 = vector2 + elbowYOffsetCompleted;
					Mathff.SetTRS(ref mat, vector4 + vector, rot, elbowScale);
					elbowMatricesBuilderTop.Add(mat);
					float y = elbowMesh.bounds.size.y;
					float num11 = (float)Mathf.RoundToInt((vector4.y - (y - 0f)) / y) * y;
					float num12 = vector4.y - num11;
					vector4.y -= num12;
					int num13 = Mathf.CeilToInt((vector4.y - num10) / elbowMesh.bounds.size.y);
					for (int num14 = 0; num14 < num13; num14++)
					{
						Vector3 vector5 = vector4 + down * (elbowMesh.bounds.size.y * (float)num14);
						Mathff.SetTRS(ref mat, vector5 + vector, rot, elbowScale);
						elbowMatricesBuilder.Add(mat);
					}
				}
				else
				{
					float num15 = vector2.y - num10;
					int num16 = Mathf.CeilToInt(num15 / scaffoldMesh.bounds.size.y);
					for (int num17 = 0; num17 < num16; num17++)
					{
						if ((float)num17 / (float)num16 < constructionForemans[num4].ConstructionProgress * 2f && (float)num17 / (float)num16 < (1f - constructionForemans[num4].ConstructionProgress) * 4f)
						{
							Mathff.SetTRS(ref mat, vector.x + vector2.x, vector.y + num10 + scaffoldMesh.bounds.size.y * (float)num17, vector.z + vector2.z, rot, scaffoldElbowScale);
							scaffoldMatricesBuilder.Add(mat);
						}
					}
					if (num9 < 1f && num15 > 0f)
					{
						Vector3 vector6 = vector2;
						Mathff.SetTRS(ref mat, vector6 + vector, rot, elbowScale);
						constructingElbowTopMatrixBuilder.Add(mat);
						buildMaterialIndexesTopElbows.Add(num4);
						buildingMaterial[num4].SetFloat("_WallProgress", num9 * 1.5f);
						buildingMaterial[num4].SetFloat("_MinHeight", num10);
						buildingMaterial[num4].SetFloat("_MaxHeight", vector6.y);
						float y2 = elbowMesh.bounds.size.y;
						float num18 = (float)Mathf.RoundToInt((vector6.y - (y2 + 0f)) / y2) * y2;
						float num19 = vector6.y - num18;
						vector6.y -= num19;
						int num20 = Mathf.CeilToInt((vector6.y - num10) / elbowMesh.bounds.size.y);
						for (int num21 = 0; num21 < num20; num21++)
						{
							Vector3 vector7 = vector6 + down * (elbowMesh.bounds.size.y * (float)num21);
							Mathff.SetTRS(ref mat, vector7 + vector, rot, elbowScale);
							constructingElbowMiddleMatrixBuilder.Add(mat);
							buildMaterialIndexesMiddlesElbows.Add(num4);
						}
					}
					if ((double)num9 >= 0.75 && !didConstructionPuff[num4])
					{
						didConstructionPuff[num4] = true;
						EffectsMan.inst.BuildPuff.CreateAndPlay(new Vector3(vector2.x, num10, vector2.z));
						if (!LoadSave.Loading)
						{
							RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_place_building_small", new Vector3(vector2.x, num10, vector2.z));
						}
					}
				}
				num4++;
			}
			Vector3 vector8 = normalized * z;
			Vector3 vector9 = vector8 * 0.5f;
			Vector3 vector10 = normalized * (num8 * 0.5f);
			Vector3 vector11 = vector3 - vector2;
			Vector3 forward3 = vector11.xz();
			Quaternion quaternion2 = ((forward3.sqrMagnitude > 0.0001f) ? Quaternion.LookRotation(forward3, up) : identity);
			Vector3 vector12 = Vector3.Cross(up, normalized);
			if (vector12.sqrMagnitude < 0.0001f)
			{
				vector12 = Vector3.right;
			}
			vector12.Normalize();
			Vector3 vector13 = vector12 * pipeSideSpacing + up * pipeSideHeightOffset;
			float z2 = z * 2f;
			Quaternion rot2 = ((vector11.sqrMagnitude > 0.0001f) ? Quaternion.LookRotation(vector11, up) : identity);
			Ray ray2 = new Ray(Vector3.zero, down);
			float num22 = waypointGroundY[num5];
			int num23 = 0;
			while (num23 < num7)
			{
				Vector3 vector14 = vector2 + vector8 * num23 + vector9 + vector10;
				Vector3 vector15 = vector2 + vector8 * (num23 + 1);
				float a = num22;
				ray2.origin = vector15 + up * 50f;
				float num24 = (Physics.Raycast(ray2, out var hitInfo2, 100f, cachedTerrainMask) ? hitInfo2.point.y : vector15.y);
				num22 = num24;
				float num25 = Mathf.Min(a, num24);
				float num26 = vector14.y - num25;
				float num27 = num26;
				isSegmentTunnel[num4] = num26 <= 0f;
				bool flag3 = num26 > 0f - vector.y;
				if (collapse & flag3)
				{
					fullyCollapsed = false;
				}
				float num28 = (fullyConstructed ? 1f : constructionForemans[num4].ConstructionProgress);
				float num29 = ((num28 >= 1f) ? 1 : 0);
				if (num26 > 0f)
				{
					Mathff.SetTRS(ref mat, vector14 + vector, quaternion2, scale);
					Mathff.SetTRS(ref mat2, offset, identity, new Vector3(num29, num29, num29));
					topMatricesBuilder.Add(mat * mat2);
					numOfFullCost++;
				}
				else
				{
					numOfReducedCost++;
				}
				float num30 = ((num28 >= 0.75f) ? 1 : 0);
				Vector3 vector16 = num30 * new Vector3(pipeScale.x, pipeScale.y, z2);
				Vector3 vector17 = num30 * new Vector3(pipeSideScale.x, pipeSideScale.y, z2);
				Mathff.SetTRS(ref pipeMatricesForConstruction[num4], vector14 + vector, rot2, vector16);
				Mathff.SetTRS(ref pipeSideLeftMatricesForConstruction[num4], vector14 + vector + vector13, rot2, vector17);
				Mathff.SetTRS(ref pipeSideRightMatricesForConstruction[num4], vector14 + vector - vector13, rot2, vector17);
				Vector3 vector18 = vector14;
				if (num27 > aqueductStraight.bounds.size.y)
				{
					float y3 = aqueductArch.bounds.size.y;
					float num31 = (float)Mathf.RoundToInt((vector14.y - (aqueductArch.bounds.size.y + 0.1f)) / y3) * y3;
					float num32 = vector18.y - num31;
					vector18.y -= num32;
					for (num27 -= num32; num27 > aqueductArch.bounds.size.y; num27 -= aqueductArch.bounds.size.y)
					{
						Mathff.SetTRS(ref mat, vector18 + vector, quaternion2, scale);
						Mathff.SetTRS(ref mat2, offset, identity, new Vector3(num29 + 0.05f, num29, num29));
						middleMatricesBuilder.Add(mat * mat2);
						vector18.y -= aqueductArch.bounds.size.y;
					}
					Mathff.SetTRS(ref mat, vector18 + vector, quaternion2, scale);
					Mathff.SetTRS(ref mat2, offset, identity, new Vector3(num29 + 0.05f, num29, num29));
					middleMatricesBuilder.Add(mat * mat2);
				}
				if (!fullyConstructed && num28 < 1f && num26 > 0f)
				{
					ray2.origin = vector14;
					ray2.direction = down;
					if (Physics.Raycast(ray2, out var hitInfo3, 30f, cachedTerrainMask) && hitInfo3.distance > 0.001f)
					{
						Mathff.SetTRS(ref stakesForConstruction[num4], hitInfo3.point, quaternion2, one * (1f - num29));
					}
					ray2.direction = down;
					Mathff.SetTRS(ref mat, vector14 + vector, quaternion2, scale);
					Mathff.SetTRS(ref mat2, offset, identity, one);
					constructingAquaductTopMatrixBuilder.Add(mat * mat2);
					buildMaterialIndexesTopAqueducts.Add(num4);
					buildingMaterial[num4].SetFloat("_WallProgress", num28 * 1.5f);
					buildingMaterial[num4].SetFloat("_MinHeight", num25);
					buildingMaterial[num4].SetFloat("_MaxHeight", vector14.y);
					vector18 = vector14;
					num27 = num26;
					if (num27 > aqueductStraight.bounds.size.y)
					{
						float y4 = aqueductArch.bounds.size.y;
						float num33 = (float)Mathf.RoundToInt((vector14.y - (aqueductArch.bounds.size.y + 0.1f)) / y4) * y4;
						float num34 = vector18.y - num33;
						vector18.y -= num34;
						for (num27 -= num34; num27 > aqueductArch.bounds.size.y; num27 -= aqueductArch.bounds.size.y)
						{
							Mathff.SetTRS(ref mat, vector18 + vector, quaternion2, scale);
							Mathff.SetTRS(ref mat2, offset, identity, one);
							constructingAquaductMiddleMatrixBuilder.Add(mat * mat2);
							buildMaterialIndexesMiddles.Add(num4);
							vector18.y -= aqueductArch.bounds.size.y;
						}
						Mathff.SetTRS(ref mat, vector18 + vector, quaternion2, scale);
						Mathff.SetTRS(ref mat2, offset, identity, one);
						constructingAquaductMiddleMatrixBuilder.Add(mat * mat2);
						buildMaterialIndexesMiddles.Add(num4);
					}
					int num35 = Mathf.CeilToInt(num26 / scaffoldMesh.bounds.size.y);
					for (int num36 = 0; num36 < num35; num36++)
					{
						if ((float)num36 / (float)num35 < constructionForemans[num4].ConstructionProgress * 2f && (float)num36 / (float)num35 < (1f - constructionForemans[num4].ConstructionProgress) * 4f)
						{
							Mathff.SetTRS(ref mat, vector.x + vector14.x, vector.y + num25 + scaffoldMesh.bounds.size.y * (float)num36, vector.z + vector14.z, quaternion2, scaffoldAqueductScale);
							scaffoldMatricesBuilder.Add(mat);
						}
					}
					if ((double)num28 >= 0.75 && !didConstructionPuff[num4])
					{
						didConstructionPuff[num4] = true;
						EffectsMan.inst.BuildPuff.CreateAndPlay(new Vector3(vector14.x, num25, vector14.z));
						if (!LoadSave.Loading)
						{
							RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_place_building_small", new Vector3(vector14.x, num25, vector14.z));
						}
					}
				}
				if (num8 > 0.3f && num26 > 0f)
				{
					Vector3 vector19 = vector2 + normalized * num8 * 0.5f;
					Vector3 vector20 = vector3 - normalized * num8 * 0.5f;
					float num37 = Mathff.Dist(vector14, vector19);
					bool flag4 = true;
					float num38 = Mathff.Dist(vector14, vector20);
					bool flag5 = true;
					for (int num39 = 0; num39 < num7; num39++)
					{
						if (num39 != num23)
						{
							Vector3 a2 = vector2 + vector8 * num39 + vector9 + vector10;
							if (Mathff.Dist(a2, vector19) < num37)
							{
								flag4 = false;
							}
							if (Mathff.Dist(a2, vector20) < num38)
							{
								flag5 = false;
							}
						}
					}
					bool constructing = num28 < 1f;
					if (flag4)
					{
						Vector3 forward4 = (vector2 - vector3).xz();
						Quaternion endRot = ((forward4.sqrMagnitude > 0.0001f) ? Quaternion.LookRotation(forward4, up) : identity);
						AppendEndColumn(vector19, endRot, waypointGroundY[num5], vector, num4, constructing);
					}
					if (flag5)
					{
						AppendEndColumn(vector20, quaternion2, waypointGroundY[num5 + 1], vector, num4, constructing);
					}
				}
				if (flag2 & flag3)
				{
					EffectsMan.inst.BuildPuff.CreateAndPlay(new Vector3(vector14.x, num25, vector14.z));
				}
				num23++;
				num4++;
			}
		}
		if (flag2)
		{
			RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_place_building_large", Center());
		}
		constructingTopAquaductMatrixIndices = buildMaterialIndexesTopAqueducts.ToArray();
		constructingMiddleAquaductMatrixIndices = buildMaterialIndexesMiddles.ToArray();
		constructingTopAquaductMatrix = constructingAquaductTopMatrixBuilder.ToArray();
		constructingMiddleAquaductMatrix = constructingAquaductMiddleMatrixBuilder.ToArray();
		constructingTopElbowMatrixIndices = buildMaterialIndexesTopElbows.ToArray();
		constructingMiddleElbowMatrixIndices = buildMaterialIndexesMiddlesElbows.ToArray();
		constructingTopElbowMatrix = constructingElbowTopMatrixBuilder.ToArray();
		constructingMiddleElbowMatrix = constructingElbowMiddleMatrixBuilder.ToArray();
		constructingEndTopMatrixIndices = buildMaterialIndexesEndTops.ToArray();
		constructingEndMiddleMatrixIndices = buildMaterialIndexesEndMiddles.ToArray();
		constructingEndTopMatrix = constructingEndTopMatrixBuilder.ToArray();
		constructingEndMiddleMatrix = constructingEndMiddleMatrixBuilder.ToArray();
		topMatrices = topMatricesBuilder.ToArray();
		middleMatrices = middleMatricesBuilder.ToArray();
		elbowMatrices = elbowMatricesBuilder.ToArray();
		elbowMatricesTop = elbowMatricesBuilderTop.ToArray();
		scaffoldMatrices = scaffoldMatricesBuilder.ToArray();
		endMatrices = endMatricesBuilder.ToArray();
		endMatricesTop = endMatricesBuilderTop.ToArray();
		ClearConstructingMatrixBuilders();
		ClearCompletedMatrixBuilders();
		if (!displayOnly)
		{
			MiniBuild();
		}
		int num40 = waypoints.Length - 1;
		if (pipeMatrices == null || pipeMatrices.Length != num40)
		{
			pipeMatrices = new Matrix4x4[num40];
			pipeSideLeftMatrices = new Matrix4x4[num40];
			pipeSideRightMatrices = new Matrix4x4[num40];
		}
		tunnelMatricesBuilder.Clear();
		if (segmentColliders.Length > waypoints.Length - 1)
		{
			for (int num41 = waypoints.Length - 1; num41 < segmentColliders.Length; num41++)
			{
				DestroySegmentCollider(segmentColliders[num41]);
			}
		}
		Array.Resize(ref segmentColliders, waypoints.Length - 1);
		for (int num42 = 0; num42 < waypoints.Length - 1; num42++)
		{
			Vector3 vector21 = waypoints[num42];
			Vector3 vector22 = waypoints[num42 + 1];
			float z3 = aqueductStraight.bounds.size.z;
			float num43 = Mathff.Dist(vector21, vector22);
			int num44 = Mathf.FloorToInt(num43 / z3);
			Vector3 normalized2 = (vector22 - vector21).normalized;
			Vector3 vector23 = Vector3.Lerp(vector21, vector22, 0.5f);
			Vector3 vector24 = new Vector3(pipeScale.x, pipeScale.y, num43 * 2f);
			Quaternion rot3 = ((normalized2.sqrMagnitude > 0.0001f) ? Quaternion.LookRotation(vector22 - vector21, up) : identity);
			Mathff.SetTRS(ref pipeMatrices[num42], vector23 + vector, rot3, vector24);
			Vector3 vector25 = Vector3.Cross(up, normalized2).normalized * pipeSideSpacing;
			Vector3 vector26 = up * pipeSideHeightOffset;
			array2[num42] = vector21 + vector25 + vector26;
			array3[num42] = vector22 + vector25 + vector26;
			array4[num42] = vector21 - vector25 + vector26;
			array5[num42] = vector22 - vector25 + vector26;
			array6[num42] = normalized2;
			float[] array7 = new float[Mathf.Max(0, num3 - 1)];
			for (int num45 = 0; num45 < array7.Length; num45++)
			{
				array7[num45] = Vector3.Cross(array6[num45], array6[num45 + 1]).y;
			}
			for (int num46 = 0; num46 < num3; num46++)
			{
				float num47 = ((num46 > 0) ? array7[num46 - 1] : 0f);
				float num48 = ((num46 < array7.Length) ? array7[num46] : 0f);
				Vector3 vector27 = array2[num46];
				Vector3 vector28 = array3[num46];
				Vector3 vector29 = array4[num46];
				Vector3 vector30 = array5[num46];
				if (num47 > 0f)
				{
					vector27 += array6[num46] * array[num46 - 1];
				}
				if (num48 > 0f)
				{
					vector28 -= array6[num46] * array[num46];
				}
				if (num47 < 0f)
				{
					vector29 += array6[num46] * array[num46 - 1];
				}
				if (num48 < 0f)
				{
					vector30 -= array6[num46] * array[num46];
				}
				Vector3 forward5 = vector28 - vector27;
				float magnitude = forward5.magnitude;
				Vector3 forward6 = ((array6[num46].sqrMagnitude > 0.0001f) ? array6[num46] : forward);
				Quaternion rot4 = ((magnitude > 0.0001f) ? Quaternion.LookRotation(forward5, up) : Quaternion.LookRotation(forward6, up));
				Mathff.SetTRS(scale: new Vector3(pipeSideScale.x, pipeSideScale.y, magnitude * 2f), mat: ref pipeSideLeftMatrices[num46], pos: Vector3.Lerp(vector27, vector28, 0.5f) + vector, rot: rot4);
				Vector3 forward7 = vector30 - vector29;
				float magnitude2 = forward7.magnitude;
				Vector3 forward8 = ((array6[num46].sqrMagnitude > 0.0001f) ? array6[num46] : forward);
				Quaternion rot5 = ((magnitude2 > 0.0001f) ? Quaternion.LookRotation(forward7, up) : Quaternion.LookRotation(forward8, up));
				Mathff.SetTRS(scale: new Vector3(pipeSideScale.x, pipeSideScale.y, magnitude2 * 2f), mat: ref pipeSideRightMatrices[num46], pos: Vector3.Lerp(vector29, vector30, 0.5f) + vector, rot: rot5);
			}
			for (int num49 = 1; num49 < num3; num49++)
			{
				float num50 = array7[num49 - 1];
				if (!(Mathf.Abs(num50) < 0.0001f))
				{
					Vector3 vector31;
					Vector3 vector32;
					if (num50 > 0f)
					{
						vector31 = array5[num49 - 1];
						vector32 = array4[num49];
					}
					else
					{
						vector31 = array3[num49 - 1];
						vector32 = array2[num49];
					}
					Vector3 forward9 = vector32 - vector31;
					float magnitude3 = forward9.magnitude;
					if (!(magnitude3 < 0.0001f))
					{
						Quaternion rot6 = Quaternion.LookRotation(forward9, up);
						Mathff.SetTRS(scale: new Vector3(pipeSideScale.x, pipeSideScale.y, magnitude3 * 2f), mat: ref mat, pos: Vector3.Lerp(vector31, vector32, 0.5f) + vector, rot: rot6);
						sideConnectors.Add(mat);
					}
				}
			}
			pipeSideConnectorMatrices = sideConnectors.ToArray();
			if (fullyConstructed && num43 > 0.0001f)
			{
				AppendTunnelMatrices(vector21, vector22, normalized2, num43, vector, tunnelMatricesBuilder);
			}
			if (!displayOnly && segmentColliders[num42] == null)
			{
				GameObject gameObject = new GameObject("Collider", typeof(MeshCollider), typeof(BuildingCollider));
				gameObject.transform.SetParent(transform, worldPositionStays: false);
				segmentColliders[num42] = gameObject.GetComponent<MeshCollider>();
				segmentColliders[num42].enabled = false;
			}
			if (segmentColliders[num42] != null)
			{
				UpdateSegmentCollider(segmentColliders[num42], vector21, vector22);
			}
		}
		for (int num51 = 0; num51 < waypoints.Length - 1; num51++)
		{
			if (segmentColliders[num51] != null)
			{
				segmentColliders[num51].enabled = true;
			}
		}
		tunnelMatrices = tunnelMatricesBuilder.ToArray();
		if (fullyConstructed && !flag && !collapse && !displayOnly)
		{
			RegisterWithInstanceManager();
		}
	}

	private void ClearMaterialIndexBuilders()
	{
		buildMaterialIndexesMiddles.Clear();
		buildMaterialIndexesMiddlesElbows.Clear();
		buildMaterialIndexesTopElbows.Clear();
		buildMaterialIndexesTopAqueducts.Clear();
		buildMaterialIndexesEndTops.Clear();
		buildMaterialIndexesEndMiddles.Clear();
	}

	private void ClearConstructingMatrixBuilders()
	{
		constructingAquaductTopMatrixBuilder.Clear();
		constructingAquaductMiddleMatrixBuilder.Clear();
		constructingElbowTopMatrixBuilder.Clear();
		constructingElbowMiddleMatrixBuilder.Clear();
		constructingEndTopMatrixBuilder.Clear();
		constructingEndMiddleMatrixBuilder.Clear();
		scaffoldMatricesBuilder.Clear();
	}

	private void ClearCompletedMatrixBuilders()
	{
		topMatricesBuilder.Clear();
		middleMatricesBuilder.Clear();
		elbowMatricesBuilder.Clear();
		elbowMatricesBuilderTop.Clear();
		endMatricesBuilder.Clear();
		endMatricesBuilderTop.Clear();
	}

	private void AppendEndColumn(Vector3 endPos, Quaternion endRot, float groundY, Vector3 collapseOffset, int masterIndex, bool constructing)
	{
		Matrix4x4 mat = default;
		Mathff.SetTRS(ref mat, endPos + collapseOffset, endRot, scale);
		if (constructing)
		{
			constructingEndTopMatrixBuilder.Add(mat);
			buildMaterialIndexesEndTops.Add(masterIndex);
		}
		else
		{
			endMatricesBuilderTop.Add(mat);
		}
		float y = elbowMesh.bounds.size.y;
		float num = (float)Mathf.RoundToInt((endPos.y - (y + 0f)) / y) * y;
		float num2 = endPos.y - num;
		Vector3 vector = endPos;
		vector.y -= num2;
		int num3 = Mathf.CeilToInt((vector.y - groundY) / aqueductEnd.bounds.size.y);
		for (int i = 0; i < num3; i++)
		{
			Vector3 vector2 = vector + Vector3.down * (aqueductEnd.bounds.size.y * (float)i);
			Mathff.SetTRS(ref mat, vector2 + collapseOffset, endRot, scale);
			if (constructing)
			{
				constructingEndMiddleMatrixBuilder.Add(mat);
				buildMaterialIndexesEndMiddles.Add(masterIndex);
			}
			else
			{
				endMatricesBuilder.Add(mat);
			}
		}
	}

	private void UpdateSegmentCollider(MeshCollider segmentCollider, Vector3 start, Vector3 end)
	{
		Vector3 forward = end - start;
		forward.y = 0f;
		float magnitude = forward.magnitude;
		Transform transform = segmentCollider.transform;
		transform.position = new Vector3((start.x + end.x) * 0.5f, 0f, (start.z + end.z) * 0.5f);
		transform.rotation = ((magnitude > 0.0001f) ? Quaternion.LookRotation(forward, Vector3.up) : Quaternion.identity);
		float num = aqueductStraight.bounds.size.x * 0.5f;
		float num2 = Mathf.Max(magnitude * 0.5f, 0.25f);
		float num3 = Mathf.Min(TerrainGen.inst.GetGroundHeight(start.x, start.z), TerrainGen.inst.GetGroundHeight(end.x, end.z));
		int num4 = Mathf.FloorToInt(magnitude);
		for (int i = 1; i <= num4; i++)
		{
			Vector3 vector = Vector3.Lerp(start, end, (float)i / (float)(num4 + 1));
			num3 = Mathf.Min(num3, TerrainGen.inst.GetGroundHeight(vector.x, vector.z));
		}
		float y = Mathf.Min(num3 - 2f, Mathf.Min(start.y, end.y) - 0.5f);
		float y2 = start.y + 0.2f;
		float y3 = end.y + 0.2f;
		segmentColliderVerts[0] = new Vector3(0f - num, y2, 0f - num2);
		segmentColliderVerts[1] = new Vector3(num, y2, 0f - num2);
		segmentColliderVerts[2] = new Vector3(num, y3, num2);
		segmentColliderVerts[3] = new Vector3(0f - num, y3, num2);
		segmentColliderVerts[4] = new Vector3(0f - num, y, 0f - num2);
		segmentColliderVerts[5] = new Vector3(num, y, 0f - num2);
		segmentColliderVerts[6] = new Vector3(num, y, num2);
		segmentColliderVerts[7] = new Vector3(0f - num, y, num2);
		Mesh mesh = segmentCollider.sharedMesh;
		bool flag = mesh == null;
		if (flag)
		{
			mesh = new Mesh
			{
				name = "AqueductSegmentCollider"
			};
		}
		mesh.vertices = segmentColliderVerts;
		if (flag)
		{
			mesh.triangles = segmentColliderTriangles;
		}
		mesh.RecalculateBounds();
		segmentCollider.sharedMesh = null;
		segmentCollider.sharedMesh = mesh;
	}

	private static void DestroySegmentCollider(MeshCollider segmentCollider)
	{
		if (!(segmentCollider == null))
		{
			if (segmentCollider.sharedMesh != null)
			{
				UnityEngine.Object.Destroy(segmentCollider.sharedMesh);
			}
			UnityEngine.Object.Destroy(segmentCollider.gameObject);
		}
	}

	internal void DisableSegmentColliders()
	{
		for (int i = 0; i < segmentColliders.Length; i++)
		{
			if (segmentColliders[i] != null)
			{
				segmentColliders[i].enabled = false;
			}
		}
	}

	public void BuildGeometryCache()
	{
		if (waypoints == null || waypoints.Length < 2)
		{
			return;
		}
		Vector3 up = Vector3.up;
		Vector3 down = Vector3.down;
		Vector3 forward = Vector3.forward;
		Quaternion identity = Quaternion.identity;
		_cachedNumConstructions = NumberOfConstructions();
		meshesToConstructAtOnce = Mathf.Clamp(_cachedNumConstructions / 5, 3, 20);
		_waypointGroundY = new float[waypoints.Length];
		Ray ray = new Ray(Vector3.zero, down);
		for (int i = 0; i < waypoints.Length; i++)
		{
			ray.origin = waypoints[i] + up * 50f;
			_waypointGroundY[i] = (Physics.Raycast(ray, out var hitInfo, 100f, cachedTerrainMask) ? hitInfo.point.y : waypoints[i].y);
		}
		float[] array = BuildRailPullbacks();
		isSegmentTunnel = new bool[_cachedNumConstructions];
		_cachedSegments = new CachedSegmentData[_cachedNumConstructions];
		numOfFullCost = 0;
		numOfReducedCost = 0;
		if (pipeMatricesForConstruction == null || pipeMatricesForConstruction.Length != _cachedNumConstructions)
		{
			pipeMatricesForConstruction = new Matrix4x4[_cachedNumConstructions];
			pipeSideLeftMatricesForConstruction = new Matrix4x4[_cachedNumConstructions];
			pipeSideRightMatricesForConstruction = new Matrix4x4[_cachedNumConstructions];
			stakesForConstruction = new Matrix4x4[_cachedNumConstructions];
		}
		BuildPersonPositions();
		int num = waypoints.Length - 1;
		Vector3[] array2 = new Vector3[num];
		Vector3[] array3 = new Vector3[num];
		Vector3[] array4 = new Vector3[num];
		Vector3[] array5 = new Vector3[num];
		Vector3[] array6 = new Vector3[num];
		int num2 = 0;
		float z = aqueductStraight.bounds.size.z;
		float y = aqueductArch.bounds.size.y;
		float y2 = elbowMesh.bounds.size.y;
		float y3 = aqueductEnd.bounds.size.y;
		float y4 = aqueductStraight.bounds.size.y;
		float y5 = scaffoldMesh.bounds.size.y;
		for (int j = 0; j < waypoints.Length - 1; j++)
		{
			Vector3 vector = waypoints[j];
			Vector3 vector2 = waypoints[j + 1];
			float num3 = Mathff.Dist(vector, vector2);
			int num4 = Mathf.FloorToInt(num3 / z);
			float num5 = num3 - (float)num4 * z;
			Vector3 normalized = (vector2 - vector).normalized;
			Vector3 vector3 = (vector2 - vector).xz();
			Quaternion rot = ((vector3.sqrMagnitude > 0.0001f) ? Quaternion.LookRotation(vector3, up) : identity);
			Vector3 vector4 = Vector3.Cross(up, normalized);
			if (vector4.sqrMagnitude < 0.0001f)
			{
				vector4 = Vector3.right;
			}
			vector4.Normalize();
			Vector3 sideOffset = vector4 * pipeSideSpacing + up * pipeSideHeightOffset;
			float pipeLengthScale = z * 2f;
			Vector3 forward2 = vector2 - vector;
			Quaternion pipeRot = ((forward2.sqrMagnitude > 0.0001f) ? Quaternion.LookRotation(forward2, up) : identity);
			if (j != 0)
			{
				Vector3 forward3 = vector3;
				Quaternion rot2 = ((forward3.sqrMagnitude > 0.0001f) ? Quaternion.LookRotation(forward3, up) : identity);
				float num6 = _waypointGroundY[j];
				float num7 = vector.y - num6;
				ref CachedSegmentData reference = ref _cachedSegments[num2];
				reference.isElbow = true;
				reference.pos = vector;
				reference.rot = rot2;
				reference.groundY = num6;
				reference.aqueductHeight = num7;
				reference.isTunnel = vector.y <= num6;
				isSegmentTunnel[num2] = reference.isTunnel;
				Vector3 elbowYOffsetPos = vector + elbowYOffsetCompleted;
				float num8 = (float)Mathf.RoundToInt((elbowYOffsetPos.y - (y2 - 0f)) / y2) * y2;
				float num9 = elbowYOffsetPos.y - num8;
				reference.elbowYOffsetPos = elbowYOffsetPos;
				reference.elbowCompTopY = elbowYOffsetPos.y - num9;
				reference.elbowCompColCount = Mathf.CeilToInt((reference.elbowCompTopY - num6) / y2);
				float num10 = (float)Mathf.RoundToInt((vector.y - (y2 + 0f)) / y2) * y2;
				float num11 = vector.y - num10;
				reference.elbowConsTopY = vector.y - num11;
				reference.elbowConsColCount = Mathf.CeilToInt((reference.elbowConsTopY - num6) / y2);
				reference.elbowScaffoldCount = Mathf.CeilToInt(num7 / y5);
				num2++;
			}
			int num12 = -1;
			int num13 = -1;
			if (num5 > 0.3f)
			{
				Vector3 b = vector + normalized * num5 * 0.5f;
				Vector3 b2 = vector2 - normalized * num5 * 0.5f;
				float num14 = float.MaxValue;
				float num15 = float.MaxValue;
				Vector3 vector5 = normalized * z;
				Vector3 vector6 = normalized * (num5 * 0.5f);
				for (int k = 0; k < num4; k++)
				{
					Vector3 a = vector + vector5 * k + vector5 * 0.5f + vector6;
					float num16 = Mathff.Dist(a, b);
					float num17 = Mathff.Dist(a, b2);
					if (num16 < num14)
					{
						num14 = num16;
						num12 = k;
					}
					if (num17 < num15)
					{
						num15 = num17;
						num13 = k;
					}
				}
			}
			Ray ray2 = new Ray(Vector3.zero, down);
			float num18 = _waypointGroundY[j];
			Vector3 vector7 = normalized * z;
			Vector3 vector8 = vector7 * 0.5f;
			Vector3 vector9 = normalized * (num5 * 0.5f);
			int num19 = 0;
			while (num19 < num4)
			{
				Vector3 vector10 = vector + vector7 * num19 + vector8 + vector9;
				Vector3 vector11 = vector + vector7 * (num19 + 1);
				float a2 = num18;
				ray2.origin = vector11 + up * 50f;
				float num20 = (Physics.Raycast(ray2, out var hitInfo2, 100f, cachedTerrainMask) ? hitInfo2.point.y : vector11.y);
				num18 = num20;
				float num21 = Mathf.Min(a2, num20);
				float num22 = vector10.y - num21;
				ref CachedSegmentData reference2 = ref _cachedSegments[num2];
				reference2.isElbow = false;
				reference2.pos = vector10;
				reference2.rot = rot;
				reference2.pipeRot = pipeRot;
				reference2.sideOffset = sideOffset;
				reference2.pipeLengthScale = pipeLengthScale;
				reference2.groundY = num21;
				reference2.aqueductHeight = num22;
				reference2.isTunnel = num22 <= 0f;
				isSegmentTunnel[num2] = reference2.isTunnel;
				if (num22 > 0f)
				{
					numOfFullCost++;
				}
				else
				{
					numOfReducedCost++;
				}
				reference2.hasStraightCols = num22 > y4;
				if (reference2.hasStraightCols)
				{
					float num23 = (reference2.straightColTopY = (float)Mathf.RoundToInt((vector10.y - (y + 0.1f)) / y) * y);
					float num24 = num22 - (vector10.y - num23);
					int num25 = 0;
					while (num24 > y)
					{
						num25++;
						num24 -= y;
					}
					num25++;
					reference2.straightColCount = num25;
				}
				reference2.straightScaffoldCount = Mathf.CeilToInt(num22 / y5);
				reference2.hasStake = false;
				if (num22 > 0f)
				{
					ray2.origin = vector10;
					ray2.direction = down;
					if (Physics.Raycast(ray2, out var hitInfo3, 30f, cachedTerrainMask) && hitInfo3.distance > 0.001f)
					{
						reference2.hasStake = true;
						reference2.stakeHitPoint = hitInfo3.point;
					}
					ray2.direction = down;
				}
				reference2.hasStartEnd = false;
				reference2.hasEndEnd = false;
				if (num5 > 0.3f && num22 > 0f)
				{
					Vector3 startEndPos = vector + normalized * num5 * 0.5f;
					Vector3 endEndPos = vector2 - normalized * num5 * 0.5f;
					Vector3 forward4 = (vector - vector2).xz();
					reference2.reverseRot = ((forward4.sqrMagnitude > 0.0001f) ? Quaternion.LookRotation(forward4, up) : identity);
					float num26 = _waypointGroundY[j];
					float num27 = _waypointGroundY[j + 1];
					if (num19 == num12)
					{
						reference2.hasStartEnd = true;
						reference2.startEndPos = startEndPos;
						float num28 = y2;
						float num29 = (float)Mathf.RoundToInt((startEndPos.y - (num28 + 0f)) / num28) * num28;
						float num30 = startEndPos.y - num29;
						reference2.startEndColTopY = startEndPos.y - num30;
						reference2.startEndColCount = Mathf.CeilToInt((reference2.startEndColTopY - num26) / y3);
					}
					if (num19 == num13)
					{
						reference2.hasEndEnd = true;
						reference2.endEndPos = endEndPos;
						float num31 = y2;
						float num32 = (float)Mathf.RoundToInt((endEndPos.y - (num31 + 0f)) / num31) * num31;
						float num33 = endEndPos.y - num32;
						reference2.endEndColTopY = endEndPos.y - num33;
						reference2.endEndColCount = Mathf.CeilToInt((reference2.endEndColTopY - num27) / y3);
					}
				}
				num19++;
				num2++;
			}
		}
		int num34 = num;
		_cachedPipeCenters = new Vector3[num34];
		_cachedPipeRotations = new Quaternion[num34];
		_cachedPipeScales = new Vector3[num34];
		if (segmentColliders.Length > num34)
		{
			for (int l = num34; l < segmentColliders.Length; l++)
			{
				DestroySegmentCollider(segmentColliders[l]);
			}
		}
		Array.Resize(ref segmentColliders, num34);
		List<Matrix4x4> list = new List<Matrix4x4>();
		Matrix4x4 mat = default;
		for (int m = 0; m < waypoints.Length - 1; m++)
		{
			Vector3 vector12 = waypoints[m];
			Vector3 vector13 = waypoints[m + 1];
			float num35 = Mathff.Dist(vector12, vector13);
			Vector3 normalized2 = (vector13 - vector12).normalized;
			_cachedPipeCenters[m] = Vector3.Lerp(vector12, vector13, 0.5f);
			_cachedPipeRotations[m] = ((normalized2.sqrMagnitude > 0.0001f) ? Quaternion.LookRotation(vector13 - vector12, up) : identity);
			_cachedPipeScales[m] = new Vector3(pipeScale.x, pipeScale.y, num35 * 2f);
			Vector3 vector14 = Vector3.Cross(up, normalized2).normalized * pipeSideSpacing;
			Vector3 vector15 = up * pipeSideHeightOffset;
			array2[m] = vector12 + vector14 + vector15;
			array3[m] = vector13 + vector14 + vector15;
			array4[m] = vector12 - vector14 + vector15;
			array5[m] = vector13 - vector14 + vector15;
			array6[m] = normalized2;
			if (num35 > 0.0001f)
			{
				AppendTunnelMatrices(vector12, vector13, normalized2, num35, Vector3.zero, list);
			}
			if (!displayOnly && segmentColliders[m] == null)
			{
				GameObject gameObject = new GameObject("Collider", typeof(MeshCollider), typeof(BuildingCollider));
				gameObject.transform.SetParent(transform, worldPositionStays: false);
				segmentColliders[m] = gameObject.GetComponent<MeshCollider>();
				segmentColliders[m].enabled = false;
			}
			if (segmentColliders[m] != null)
			{
				UpdateSegmentCollider(segmentColliders[m], vector12, vector13);
			}
		}
		for (int n = 0; n < num34; n++)
		{
			if (segmentColliders[n] != null)
			{
				segmentColliders[n].enabled = true;
			}
		}
		float[] array7 = new float[Mathf.Max(0, num - 1)];
		for (int num36 = 0; num36 < array7.Length; num36++)
		{
			array7[num36] = Vector3.Cross(array6[num36], array6[num36 + 1]).y;
		}
		_cachedPipeSideLeftBase = new Matrix4x4[num];
		_cachedPipeSideRightBase = new Matrix4x4[num];
		for (int num37 = 0; num37 < num; num37++)
		{
			float num38 = ((num37 > 0) ? array7[num37 - 1] : 0f);
			float num39 = ((num37 < array7.Length) ? array7[num37] : 0f);
			Vector3 vector16 = array2[num37];
			Vector3 vector17 = array3[num37];
			Vector3 vector18 = array4[num37];
			Vector3 vector19 = array5[num37];
			if (num38 > 0f)
			{
				vector16 += array6[num37] * array[num37 - 1];
			}
			if (num39 > 0f)
			{
				vector17 -= array6[num37] * array[num37];
			}
			if (num38 < 0f)
			{
				vector18 += array6[num37] * array[num37 - 1];
			}
			if (num39 < 0f)
			{
				vector19 -= array6[num37] * array[num37];
			}
			Vector3 forward5 = vector17 - vector16;
			float magnitude = forward5.magnitude;
			Vector3 forward6 = ((array6[num37].sqrMagnitude > 0.0001f) ? array6[num37] : forward);
			Quaternion rot3 = ((magnitude > 0.0001f) ? Quaternion.LookRotation(forward5, up) : Quaternion.LookRotation(forward6, up));
			Mathff.SetTRS(scale: new Vector3(pipeSideScale.x, pipeSideScale.y, magnitude * 2f), mat: ref _cachedPipeSideLeftBase[num37], pos: Vector3.Lerp(vector16, vector17, 0.5f), rot: rot3);
			Vector3 forward7 = vector19 - vector18;
			float magnitude2 = forward7.magnitude;
			Vector3 forward8 = ((array6[num37].sqrMagnitude > 0.0001f) ? array6[num37] : forward);
			Quaternion rot4 = ((magnitude2 > 0.0001f) ? Quaternion.LookRotation(forward7, up) : Quaternion.LookRotation(forward8, up));
			Mathff.SetTRS(scale: new Vector3(pipeSideScale.x, pipeSideScale.y, magnitude2 * 2f), mat: ref _cachedPipeSideRightBase[num37], pos: Vector3.Lerp(vector18, vector19, 0.5f), rot: rot4);
		}
		List<Matrix4x4> list2 = new List<Matrix4x4>();
		for (int num40 = 1; num40 < num; num40++)
		{
			float num41 = array7[num40 - 1];
			if (!(Mathf.Abs(num41) < 0.0001f))
			{
				Vector3 vector20;
				Vector3 vector21;
				if (num41 > 0f)
				{
					vector20 = array5[num40 - 1];
					vector21 = array4[num40];
				}
				else
				{
					vector20 = array3[num40 - 1];
					vector21 = array2[num40];
				}
				Vector3 forward9 = vector21 - vector20;
				float magnitude3 = forward9.magnitude;
				if (!(magnitude3 < 0.0001f))
				{
					Quaternion rot5 = Quaternion.LookRotation(forward9, up);
					Mathff.SetTRS(scale: new Vector3(pipeSideScale.x, pipeSideScale.y, magnitude3 * 2f), mat: ref mat, pos: Vector3.Lerp(vector20, vector21, 0.5f), rot: rot5);
					list2.Add(mat);
				}
			}
		}
		_cachedConnectorBase = list2.ToArray();
		_cachedTunnelBase = list.ToArray();
		int num42 = num;
		pipeMatrices = new Matrix4x4[num42];
		pipeSideLeftMatrices = new Matrix4x4[num42];
		pipeSideRightMatrices = new Matrix4x4[num42];
		for (int num43 = 0; num43 < num42; num43++)
		{
			Mathff.SetTRS(ref pipeMatrices[num43], _cachedPipeCenters[num43], _cachedPipeRotations[num43], _cachedPipeScales[num43]);
			pipeSideLeftMatrices[num43] = _cachedPipeSideLeftBase[num43];
			pipeSideRightMatrices[num43] = _cachedPipeSideRightBase[num43];
		}
		pipeSideConnectorMatrices = ((_cachedConnectorBase.Length != 0) ? ((Matrix4x4[])_cachedConnectorBase.Clone()) : Array.Empty<Matrix4x4>());
		for (int num44 = 0; num44 < _cachedNumConstructions; num44++)
		{
			ref CachedSegmentData reference3 = ref _cachedSegments[num44];
			if (!reference3.isElbow && reference3.hasStake && reference3.aqueductHeight > 0f)
			{
				Mathff.SetTRS(ref stakesForConstruction[num44], reference3.stakeHitPoint, reference3.rot, Vector3.one);
			}
		}
		_segmentCompletedFlag = new bool[_cachedNumConstructions];
		_completedSegmentCount = 0;
		_completedTopList = new List<Matrix4x4>();
		_completedMiddleList = new List<Matrix4x4>();
		_completedElbowTopList = new List<Matrix4x4>();
		_completedElbowMiddleList = new List<Matrix4x4>();
		_completedEndTopList = new List<Matrix4x4>();
		_completedEndMiddleList = new List<Matrix4x4>();
		_activeSegmentIndices = new int[_cachedNumConstructions];
		topMatrices = Array.Empty<Matrix4x4>();
		middleMatrices = Array.Empty<Matrix4x4>();
		elbowMatrices = Array.Empty<Matrix4x4>();
		elbowMatricesTop = Array.Empty<Matrix4x4>();
		endMatrices = Array.Empty<Matrix4x4>();
		endMatricesTop = Array.Empty<Matrix4x4>();
		scaffoldMatrices = Array.Empty<Matrix4x4>();
		tunnelMatrices = Array.Empty<Matrix4x4>();
		constructingTopAquaductMatrix = Array.Empty<Matrix4x4>();
		constructingMiddleAquaductMatrix = Array.Empty<Matrix4x4>();
		constructingTopElbowMatrix = Array.Empty<Matrix4x4>();
		constructingMiddleElbowMatrix = Array.Empty<Matrix4x4>();
		constructingEndTopMatrix = Array.Empty<Matrix4x4>();
		constructingEndMiddleMatrix = Array.Empty<Matrix4x4>();
		constructingTopAquaductMatrixIndices = Array.Empty<int>();
		constructingMiddleAquaductMatrixIndices = Array.Empty<int>();
		constructingTopElbowMatrixIndices = Array.Empty<int>();
		constructingMiddleElbowMatrixIndices = Array.Empty<int>();
		constructingEndTopMatrixIndices = Array.Empty<int>();
		constructingEndMiddleMatrixIndices = Array.Empty<int>();
		if (fullyConstructed)
		{
			PopulateAllCompletedArrays();
			if (!collapse && !displayOnly)
			{
				RegisterWithInstanceManager();
			}
		}
		_geometryCacheValid = true;
	}

	private void PopulateAllCompletedArrays()
	{
		float y = aqueductArch.bounds.size.y;
		float y2 = elbowMesh.bounds.size.y;
		float y3 = aqueductEnd.bounds.size.y;
		Matrix4x4 mat = default;
		Matrix4x4 mat2 = default;
		Quaternion identity = Quaternion.identity;
		Vector3 one = Vector3.one;
		for (int i = 0; i < _cachedNumConstructions; i++)
		{
			_segmentCompletedFlag[i] = true;
			ref CachedSegmentData reference = ref _cachedSegments[i];
			if (reference.isElbow)
			{
				Mathff.SetTRS(ref mat, reference.elbowYOffsetPos, reference.rot, elbowScale);
				_completedElbowTopList.Add(mat);
				for (int j = 0; j < reference.elbowCompColCount; j++)
				{
					Vector3 pos = new Vector3(reference.elbowYOffsetPos.x, reference.elbowCompTopY - y2 * (float)j, reference.elbowYOffsetPos.z);
					Mathff.SetTRS(ref mat, pos, reference.rot, elbowScale);
					_completedElbowMiddleList.Add(mat);
				}
				continue;
			}
			if (reference.aqueductHeight > 0f)
			{
				Mathff.SetTRS(ref mat, reference.pos, reference.rot, scale);
				Mathff.SetTRS(ref mat2, offset, identity, one);
				_completedTopList.Add(mat * mat2);
			}
			if (reference.hasStraightCols)
			{
				Vector3 pos2 = new Vector3(reference.pos.x, reference.straightColTopY, reference.pos.z);
				for (int k = 0; k < reference.straightColCount; k++)
				{
					Mathff.SetTRS(ref mat, pos2, reference.rot, scale);
					Mathff.SetTRS(ref mat2, offset, identity, new Vector3(1.05f, 1f, 1f));
					_completedMiddleList.Add(mat * mat2);
					pos2.y -= y;
				}
			}
			Vector3 vector = new Vector3(pipeScale.x, pipeScale.y, reference.pipeLengthScale);
			Vector3 vector2 = new Vector3(pipeSideScale.x, pipeSideScale.y, reference.pipeLengthScale);
			Mathff.SetTRS(ref pipeMatricesForConstruction[i], reference.pos, reference.pipeRot, vector);
			Mathff.SetTRS(ref pipeSideLeftMatricesForConstruction[i], reference.pos + reference.sideOffset, reference.pipeRot, vector2);
			Mathff.SetTRS(ref pipeSideRightMatricesForConstruction[i], reference.pos - reference.sideOffset, reference.pipeRot, vector2);
			if (reference.hasStake)
			{
				stakesForConstruction[i] = default;
			}
			if (reference.hasStartEnd)
			{
				Mathff.SetTRS(ref mat, reference.startEndPos, reference.reverseRot, scale);
				_completedEndTopList.Add(mat);
				for (int l = 0; l < reference.startEndColCount; l++)
				{
					Vector3 pos3 = new Vector3(reference.startEndPos.x, reference.startEndColTopY - y3 * (float)l, reference.startEndPos.z);
					Mathff.SetTRS(ref mat, pos3, reference.reverseRot, scale);
					_completedEndMiddleList.Add(mat);
				}
			}
			if (reference.hasEndEnd)
			{
				Mathff.SetTRS(ref mat, reference.endEndPos, reference.rot, scale);
				_completedEndTopList.Add(mat);
				for (int m = 0; m < reference.endEndColCount; m++)
				{
					Vector3 pos4 = new Vector3(reference.endEndPos.x, reference.endEndColTopY - y3 * (float)m, reference.endEndPos.z);
					Mathff.SetTRS(ref mat, pos4, reference.rot, scale);
					_completedEndMiddleList.Add(mat);
				}
			}
		}
		_completedSegmentCount = _cachedNumConstructions;
		topMatrices = _completedTopList.ToArray();
		middleMatrices = _completedMiddleList.ToArray();
		elbowMatrices = _completedElbowMiddleList.ToArray();
		elbowMatricesTop = _completedElbowTopList.ToArray();
		endMatrices = _completedEndMiddleList.ToArray();
		endMatricesTop = _completedEndTopList.ToArray();
		tunnelMatrices = ((_cachedTunnelBase.Length != 0) ? ((Matrix4x4[])_cachedTunnelBase.Clone()) : Array.Empty<Matrix4x4>());
	}

	public void AnimationUpdate()
	{
		bool flag = false;
		if (collapse)
		{
			float num = Mathf.Ceil(collapseTime);
			collapseTime += Time.deltaTime;
			if (collapseTime > num)
			{
				flag = true;
			}
		}
		Vector3 down = Vector3.down;
		Quaternion identity = Quaternion.identity;
		Vector3 one = Vector3.one;
		Vector3 vector = collapseTime * down;
		if (Creative.inst.IsCreativeOptionOn(11))
		{
			if (!fullyConstructed && !Creative.inst.IsCreativeOptionOn(0))
			{
				for (int i = 0; i < constructionForemans.Length; i++)
				{
					constructionForemans[i].ConsumeOutstandingCostFromWorld();
				}
			}
			fullyConstructed = true;
			AqueductFlowController.MarkTopologyDirty("AnimationUpdate");
			if (startAB != null)
			{
				startAB.UpdateWaterFlow();
			}
			for (int j = 0; j < constructionForemans.Length; j++)
			{
				constructionForemans[j].RemoveJobs();
			}
			MilestoneManager.inst.CheckAbsurdAqueductMilestone(NumberOfConstructions());
		}
		if (!fullyConstructed)
		{
			fullyConstructed = true;
			for (int k = 0; k < constructionForemans.Length; k++)
			{
				ConstructionForeman constructionForeman = constructionForemans[k];
				if (constructionForeman.ConstructionProgress >= 1f && !isProjectPaused && !constructionForeman.ConstructionPaused)
				{
					constructionForeman.ConstructionPaused = true;
					constructionForeman.RemoveJobs();
					meshesUnderConstruction = Mathff.Max(0, meshesUnderConstruction - 1);
				}
			}
			for (int l = 0; l < constructionForemans.Length; l++)
			{
				ConstructionForeman constructionForeman2 = constructionForemans[l];
				if (constructionForeman2.ConstructionProgress < 1f)
				{
					fullyConstructed = false;
					if (!isProjectPaused && constructionForeman2.ConstructionPaused && meshesUnderConstruction < meshesToConstructAtOnce)
					{
						constructionForeman2.ConstructionPaused = false;
						meshesUnderConstruction++;
					}
				}
			}
			if (fullyConstructed)
			{
				AqueductFlowController.MarkTopologyDirty("AnimationUpdate");
				if (startAB != null)
				{
					startAB.UpdateWaterFlow();
				}
				if (!LoadSave.Loading)
				{
					RuntimeManager.PlayOneShot(onBuildingCompleteEvent.Guid, Center());
					MilestoneManager.inst.TryFirstAqueductMilestone();
					MilestoneManager.inst.CheckAbsurdAqueductMilestone(NumberOfConstructions());
				}
				for (int m = 0; m < constructionForemans.Length; m++)
				{
					constructionForemans[m].RemoveJobs();
				}
				if (startAB is AqueductJunction aqueductJunction)
				{
					aqueductJunction.TryCollapseLines();
				}
				if (this == null)
				{
					return;
				}
				if (endAB is AqueductJunction aqueductJunction2)
				{
					aqueductJunction2.TryCollapseLines();
				}
				if (this == null)
				{
					return;
				}
			}
		}
		Matrix4x4 mat = default;
		Matrix4x4 mat2 = default;
		int cachedNumConstructions = _cachedNumConstructions;
		float y = aqueductArch.bounds.size.y;
		float y2 = elbowMesh.bounds.size.y;
		float y3 = aqueductEnd.bounds.size.y;
		float y4 = scaffoldMesh.bounds.size.y;
		if (collapse)
		{
			ClearMaterialIndexBuilders();
			Array.Clear(pipeMatricesForConstruction, 0, cachedNumConstructions);
			Array.Clear(pipeSideLeftMatricesForConstruction, 0, cachedNumConstructions);
			Array.Clear(pipeSideRightMatricesForConstruction, 0, cachedNumConstructions);
			Array.Clear(stakesForConstruction, 0, cachedNumConstructions);
			fullyCollapsed = true;
			for (int n = 0; n < cachedNumConstructions; n++)
			{
				ref CachedSegmentData reference = ref _cachedSegments[n];
				float num2 = (fullyConstructed ? 1f : constructionForemans[n].ConstructionProgress);
				if (reference.isElbow)
				{
					if (num2 >= 1f)
					{
						Mathff.SetTRS(ref mat, reference.elbowYOffsetPos + vector, reference.rot, elbowScale);
						elbowMatricesBuilderTop.Add(mat);
						for (int num3 = 0; num3 < reference.elbowCompColCount; num3++)
						{
							Vector3 vector2 = new Vector3(reference.elbowYOffsetPos.x, reference.elbowCompTopY - y2 * (float)num3, reference.elbowYOffsetPos.z);
							Mathff.SetTRS(ref mat, vector2 + vector, reference.rot, elbowScale);
							elbowMatricesBuilder.Add(mat);
						}
						continue;
					}
					for (int num4 = 0; num4 < reference.elbowScaffoldCount; num4++)
					{
						if ((float)num4 / (float)reference.elbowScaffoldCount < num2 * 2f && (float)num4 / (float)reference.elbowScaffoldCount < (1f - num2) * 4f)
						{
							Mathff.SetTRS(ref mat, vector.x + reference.pos.x, vector.y + reference.groundY + y4 * (float)num4, vector.z + reference.pos.z, reference.rot, scaffoldElbowScale);
							scaffoldMatricesBuilder.Add(mat);
						}
					}
					if (reference.aqueductHeight > 0f)
					{
						Mathff.SetTRS(ref mat, reference.pos + vector, reference.rot, elbowScale);
						constructingElbowTopMatrixBuilder.Add(mat);
						buildMaterialIndexesTopElbows.Add(n);
						buildingMaterial[n].SetFloat("_WallProgress", num2 * 1.5f);
						buildingMaterial[n].SetFloat("_MinHeight", reference.groundY);
						buildingMaterial[n].SetFloat("_MaxHeight", reference.pos.y);
						for (int num5 = 0; num5 < reference.elbowConsColCount; num5++)
						{
							Vector3 vector3 = new Vector3(reference.pos.x, reference.elbowConsTopY - y2 * (float)num5, reference.pos.z);
							Mathff.SetTRS(ref mat, vector3 + vector, reference.rot, elbowScale);
							constructingElbowMiddleMatrixBuilder.Add(mat);
							buildMaterialIndexesMiddlesElbows.Add(n);
						}
					}
					if (num2 >= 0.75f && !didConstructionPuff[n])
					{
						didConstructionPuff[n] = true;
						EffectsMan.inst.BuildPuff.CreateAndPlay(new Vector3(reference.pos.x, reference.groundY, reference.pos.z));
						if (!LoadSave.Loading)
						{
							RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_place_building_small", new Vector3(reference.pos.x, reference.groundY, reference.pos.z));
						}
					}
					continue;
				}
				bool flag2 = reference.aqueductHeight > 0f - vector.y;
				if (flag2)
				{
					fullyCollapsed = false;
				}
				float num6 = ((num2 >= 1f) ? 1f : 0f);
				if (reference.aqueductHeight > 0f)
				{
					Mathff.SetTRS(ref mat, reference.pos + vector, reference.rot, scale);
					Mathff.SetTRS(ref mat2, offset, identity, new Vector3(num6, num6, num6));
					topMatricesBuilder.Add(mat * mat2);
				}
				float num7 = ((num2 >= 0.75f) ? 1f : 0f);
				Vector3 vector4 = num7 * new Vector3(pipeScale.x, pipeScale.y, reference.pipeLengthScale);
				Vector3 vector5 = num7 * new Vector3(pipeSideScale.x, pipeSideScale.y, reference.pipeLengthScale);
				Mathff.SetTRS(ref pipeMatricesForConstruction[n], reference.pos + vector, reference.pipeRot, vector4);
				Mathff.SetTRS(ref pipeSideLeftMatricesForConstruction[n], reference.pos + vector + reference.sideOffset, reference.pipeRot, vector5);
				Mathff.SetTRS(ref pipeSideRightMatricesForConstruction[n], reference.pos + vector - reference.sideOffset, reference.pipeRot, vector5);
				if (reference.hasStraightCols)
				{
					Vector3 vector6 = new Vector3(reference.pos.x, reference.straightColTopY, reference.pos.z);
					for (int num8 = 0; num8 < reference.straightColCount; num8++)
					{
						Mathff.SetTRS(ref mat, vector6 + vector, reference.rot, scale);
						Mathff.SetTRS(ref mat2, offset, identity, new Vector3(num6 + 0.05f, num6, num6));
						middleMatricesBuilder.Add(mat * mat2);
						vector6.y -= y;
					}
				}
				if (!fullyConstructed && num2 < 1f && reference.aqueductHeight > 0f)
				{
					if (reference.hasStake)
					{
						Mathff.SetTRS(ref stakesForConstruction[n], reference.stakeHitPoint, reference.rot, one * (1f - num6));
					}
					Mathff.SetTRS(ref mat, reference.pos + vector, reference.rot, scale);
					Mathff.SetTRS(ref mat2, offset, identity, one);
					constructingAquaductTopMatrixBuilder.Add(mat * mat2);
					buildMaterialIndexesTopAqueducts.Add(n);
					buildingMaterial[n].SetFloat("_WallProgress", num2 * 1.5f);
					buildingMaterial[n].SetFloat("_MinHeight", reference.groundY);
					buildingMaterial[n].SetFloat("_MaxHeight", reference.pos.y);
					if (reference.hasStraightCols)
					{
						Vector3 vector7 = new Vector3(reference.pos.x, reference.straightColTopY, reference.pos.z);
						for (int num9 = 0; num9 < reference.straightColCount; num9++)
						{
							Mathff.SetTRS(ref mat, vector7 + vector, reference.rot, scale);
							Mathff.SetTRS(ref mat2, offset, identity, one);
							constructingAquaductMiddleMatrixBuilder.Add(mat * mat2);
							buildMaterialIndexesMiddles.Add(n);
							vector7.y -= y;
						}
					}
					int straightScaffoldCount = reference.straightScaffoldCount;
					for (int num10 = 0; num10 < straightScaffoldCount; num10++)
					{
						if ((float)num10 / (float)straightScaffoldCount < num2 * 2f && (float)num10 / (float)straightScaffoldCount < (1f - num2) * 4f)
						{
							Mathff.SetTRS(ref mat, vector.x + reference.pos.x, vector.y + reference.groundY + y4 * (float)num10, vector.z + reference.pos.z, reference.rot, scaffoldAqueductScale);
							scaffoldMatricesBuilder.Add(mat);
						}
					}
					if (num2 >= 0.75f && !didConstructionPuff[n])
					{
						didConstructionPuff[n] = true;
						EffectsMan.inst.BuildPuff.CreateAndPlay(new Vector3(reference.pos.x, reference.groundY, reference.pos.z));
						if (!LoadSave.Loading)
						{
							RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_place_building_small", new Vector3(reference.pos.x, reference.groundY, reference.pos.z));
						}
					}
				}
				if (reference.hasStartEnd)
				{
					Mathff.SetTRS(ref mat, reference.startEndPos + vector, reference.reverseRot, scale);
					if (num2 < 1f)
					{
						constructingEndTopMatrixBuilder.Add(mat);
						buildMaterialIndexesEndTops.Add(n);
					}
					else
					{
						endMatricesBuilderTop.Add(mat);
					}
					for (int num11 = 0; num11 < reference.startEndColCount; num11++)
					{
						Vector3 vector8 = new Vector3(reference.startEndPos.x, reference.startEndColTopY - y3 * (float)num11, reference.startEndPos.z);
						Mathff.SetTRS(ref mat, vector8 + vector, reference.reverseRot, scale);
						if (num2 < 1f)
						{
							constructingEndMiddleMatrixBuilder.Add(mat);
							buildMaterialIndexesEndMiddles.Add(n);
						}
						else
						{
							endMatricesBuilder.Add(mat);
						}
					}
				}
				if (reference.hasEndEnd)
				{
					Mathff.SetTRS(ref mat, reference.endEndPos + vector, reference.rot, scale);
					if (num2 < 1f)
					{
						constructingEndTopMatrixBuilder.Add(mat);
						buildMaterialIndexesEndTops.Add(n);
					}
					else
					{
						endMatricesBuilderTop.Add(mat);
					}
					for (int num12 = 0; num12 < reference.endEndColCount; num12++)
					{
						Vector3 vector9 = new Vector3(reference.endEndPos.x, reference.endEndColTopY - y3 * (float)num12, reference.endEndPos.z);
						Mathff.SetTRS(ref mat, vector9 + vector, reference.rot, scale);
						if (num2 < 1f)
						{
							constructingEndMiddleMatrixBuilder.Add(mat);
							buildMaterialIndexesEndMiddles.Add(n);
						}
						else
						{
							endMatricesBuilder.Add(mat);
						}
					}
				}
				if (flag & flag2)
				{
					EffectsMan.inst.BuildPuff.CreateAndPlay(new Vector3(reference.pos.x, reference.groundY, reference.pos.z));
				}
			}
			if (flag)
			{
				RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_place_building_large", Center());
			}
			constructingTopAquaductMatrixIndices = buildMaterialIndexesTopAqueducts.ToArray();
			constructingMiddleAquaductMatrixIndices = buildMaterialIndexesMiddles.ToArray();
			constructingTopAquaductMatrix = constructingAquaductTopMatrixBuilder.ToArray();
			constructingMiddleAquaductMatrix = constructingAquaductMiddleMatrixBuilder.ToArray();
			constructingTopElbowMatrixIndices = buildMaterialIndexesTopElbows.ToArray();
			constructingMiddleElbowMatrixIndices = buildMaterialIndexesMiddlesElbows.ToArray();
			constructingTopElbowMatrix = constructingElbowTopMatrixBuilder.ToArray();
			constructingMiddleElbowMatrix = constructingElbowMiddleMatrixBuilder.ToArray();
			constructingEndTopMatrixIndices = buildMaterialIndexesEndTops.ToArray();
			constructingEndMiddleMatrixIndices = buildMaterialIndexesEndMiddles.ToArray();
			constructingEndTopMatrix = constructingEndTopMatrixBuilder.ToArray();
			constructingEndMiddleMatrix = constructingEndMiddleMatrixBuilder.ToArray();
			topMatrices = topMatricesBuilder.ToArray();
			middleMatrices = middleMatricesBuilder.ToArray();
			elbowMatrices = elbowMatricesBuilder.ToArray();
			elbowMatricesTop = elbowMatricesBuilderTop.ToArray();
			scaffoldMatrices = scaffoldMatricesBuilder.ToArray();
			endMatrices = endMatricesBuilder.ToArray();
			endMatricesTop = endMatricesBuilderTop.ToArray();
			ClearConstructingMatrixBuilders();
			ClearCompletedMatrixBuilders();
			MiniBuild();
			int num13 = waypoints.Length - 1;
			if (pipeMatrices == null || pipeMatrices.Length != num13)
			{
				pipeMatrices = new Matrix4x4[num13];
				pipeSideLeftMatrices = new Matrix4x4[num13];
				pipeSideRightMatrices = new Matrix4x4[num13];
			}
			for (int num14 = 0; num14 < num13; num14++)
			{
				Mathff.SetTRS(ref pipeMatrices[num14], _cachedPipeCenters[num14] + vector, _cachedPipeRotations[num14], _cachedPipeScales[num14]);
				pipeSideLeftMatrices[num14] = _cachedPipeSideLeftBase[num14];
				pipeSideLeftMatrices[num14].m03 += vector.x;
				pipeSideLeftMatrices[num14].m13 += vector.y;
				pipeSideLeftMatrices[num14].m23 += vector.z;
				pipeSideRightMatrices[num14] = _cachedPipeSideRightBase[num14];
				pipeSideRightMatrices[num14].m03 += vector.x;
				pipeSideRightMatrices[num14].m13 += vector.y;
				pipeSideRightMatrices[num14].m23 += vector.z;
			}
			sideConnectors.Clear();
			for (int num15 = 0; num15 < _cachedConnectorBase.Length; num15++)
			{
				Matrix4x4 item = _cachedConnectorBase[num15];
				item.m03 += vector.x;
				item.m13 += vector.y;
				item.m23 += vector.z;
				sideConnectors.Add(item);
			}
			pipeSideConnectorMatrices = sideConnectors.ToArray();
			tunnelMatricesBuilder.Clear();
			if (fullyConstructed)
			{
				for (int num16 = 0; num16 < _cachedTunnelBase.Length; num16++)
				{
					Matrix4x4 item2 = _cachedTunnelBase[num16];
					item2.m03 += vector.x;
					item2.m13 += vector.y;
					item2.m23 += vector.z;
					tunnelMatricesBuilder.Add(item2);
				}
			}
			tunnelMatrices = tunnelMatricesBuilder.ToArray();
			return;
		}
		bool flag3 = false;
		for (int num17 = 0; num17 < cachedNumConstructions; num17++)
		{
			if (_segmentCompletedFlag[num17] || (fullyConstructed ? 1f : constructionForemans[num17].ConstructionProgress) < 1f)
			{
				continue;
			}
			_segmentCompletedFlag[num17] = true;
			_completedSegmentCount++;
			flag3 = true;
			ref CachedSegmentData reference2 = ref _cachedSegments[num17];
			if (reference2.isElbow)
			{
				Mathff.SetTRS(ref mat, reference2.elbowYOffsetPos, reference2.rot, elbowScale);
				_completedElbowTopList.Add(mat);
				for (int num18 = 0; num18 < reference2.elbowCompColCount; num18++)
				{
					Vector3 pos = new Vector3(reference2.elbowYOffsetPos.x, reference2.elbowCompTopY - y2 * (float)num18, reference2.elbowYOffsetPos.z);
					Mathff.SetTRS(ref mat, pos, reference2.rot, elbowScale);
					_completedElbowMiddleList.Add(mat);
				}
				continue;
			}
			if (reference2.aqueductHeight > 0f)
			{
				Mathff.SetTRS(ref mat, reference2.pos, reference2.rot, scale);
				Mathff.SetTRS(ref mat2, offset, identity, one);
				_completedTopList.Add(mat * mat2);
			}
			if (reference2.hasStraightCols)
			{
				Vector3 pos2 = new Vector3(reference2.pos.x, reference2.straightColTopY, reference2.pos.z);
				for (int num19 = 0; num19 < reference2.straightColCount; num19++)
				{
					Mathff.SetTRS(ref mat, pos2, reference2.rot, scale);
					Mathff.SetTRS(ref mat2, offset, identity, new Vector3(1.05f, 1f, 1f));
					_completedMiddleList.Add(mat * mat2);
					pos2.y -= y;
				}
			}
			Vector3 vector10 = new Vector3(pipeScale.x, pipeScale.y, reference2.pipeLengthScale);
			Vector3 vector11 = new Vector3(pipeSideScale.x, pipeSideScale.y, reference2.pipeLengthScale);
			Mathff.SetTRS(ref pipeMatricesForConstruction[num17], reference2.pos, reference2.pipeRot, vector10);
			Mathff.SetTRS(ref pipeSideLeftMatricesForConstruction[num17], reference2.pos + reference2.sideOffset, reference2.pipeRot, vector11);
			Mathff.SetTRS(ref pipeSideRightMatricesForConstruction[num17], reference2.pos - reference2.sideOffset, reference2.pipeRot, vector11);
			if (reference2.hasStake)
			{
				stakesForConstruction[num17] = default;
			}
			if (reference2.hasStartEnd)
			{
				Mathff.SetTRS(ref mat, reference2.startEndPos, reference2.reverseRot, scale);
				_completedEndTopList.Add(mat);
				for (int num20 = 0; num20 < reference2.startEndColCount; num20++)
				{
					Vector3 pos3 = new Vector3(reference2.startEndPos.x, reference2.startEndColTopY - y3 * (float)num20, reference2.startEndPos.z);
					Mathff.SetTRS(ref mat, pos3, reference2.reverseRot, scale);
					_completedEndMiddleList.Add(mat);
				}
			}
			if (reference2.hasEndEnd)
			{
				Mathff.SetTRS(ref mat, reference2.endEndPos, reference2.rot, scale);
				_completedEndTopList.Add(mat);
				for (int num21 = 0; num21 < reference2.endEndColCount; num21++)
				{
					Vector3 pos4 = new Vector3(reference2.endEndPos.x, reference2.endEndColTopY - y3 * (float)num21, reference2.endEndPos.z);
					Mathff.SetTRS(ref mat, pos4, reference2.rot, scale);
					_completedEndMiddleList.Add(mat);
				}
			}
		}
		if (flag3)
		{
			topMatrices = _completedTopList.ToArray();
			middleMatrices = _completedMiddleList.ToArray();
			elbowMatrices = _completedElbowMiddleList.ToArray();
			elbowMatricesTop = _completedElbowTopList.ToArray();
			endMatrices = _completedEndMiddleList.ToArray();
			endMatricesTop = _completedEndTopList.ToArray();
		}
		if (fullyConstructed & flag3)
		{
			tunnelMatrices = ((_cachedTunnelBase.Length != 0) ? ((Matrix4x4[])_cachedTunnelBase.Clone()) : Array.Empty<Matrix4x4>());
			if (!collapse)
			{
				RegisterWithInstanceManager();
			}
		}
		_activeSegmentCount = 0;
		for (int num22 = 0; num22 < cachedNumConstructions; num22++)
		{
			if (!_segmentCompletedFlag[num22] && constructionForemans[num22].ConstructionProgress > 0f)
			{
				_activeSegmentIndices[_activeSegmentCount++] = num22;
			}
		}
		ClearMaterialIndexBuilders();
		ClearConstructingMatrixBuilders();
		for (int num23 = 0; num23 < _activeSegmentCount; num23++)
		{
			int num24 = _activeSegmentIndices[num23];
			ref CachedSegmentData reference3 = ref _cachedSegments[num24];
			float constructionProgress = constructionForemans[num24].ConstructionProgress;
			if (reference3.isElbow)
			{
				for (int num25 = 0; num25 < reference3.elbowScaffoldCount; num25++)
				{
					if ((float)num25 / (float)reference3.elbowScaffoldCount < constructionProgress * 2f && (float)num25 / (float)reference3.elbowScaffoldCount < (1f - constructionProgress) * 4f)
					{
						Mathff.SetTRS(ref mat, reference3.pos.x, reference3.groundY + y4 * (float)num25, reference3.pos.z, reference3.rot, scaffoldElbowScale);
						scaffoldMatricesBuilder.Add(mat);
					}
				}
				if (reference3.aqueductHeight > 0f)
				{
					Mathff.SetTRS(ref mat, reference3.pos, reference3.rot, elbowScale);
					constructingElbowTopMatrixBuilder.Add(mat);
					buildMaterialIndexesTopElbows.Add(num24);
					buildingMaterial[num24].SetFloat("_WallProgress", constructionProgress * 1.5f);
					buildingMaterial[num24].SetFloat("_MinHeight", reference3.groundY);
					buildingMaterial[num24].SetFloat("_MaxHeight", reference3.pos.y);
					for (int num26 = 0; num26 < reference3.elbowConsColCount; num26++)
					{
						Vector3 pos5 = new Vector3(reference3.pos.x, reference3.elbowConsTopY - y2 * (float)num26, reference3.pos.z);
						Mathff.SetTRS(ref mat, pos5, reference3.rot, elbowScale);
						constructingElbowMiddleMatrixBuilder.Add(mat);
						buildMaterialIndexesMiddlesElbows.Add(num24);
					}
				}
				if (constructionProgress >= 0.75f && !didConstructionPuff[num24])
				{
					didConstructionPuff[num24] = true;
					EffectsMan.inst.BuildPuff.CreateAndPlay(new Vector3(reference3.pos.x, reference3.groundY, reference3.pos.z));
					if (!LoadSave.Loading)
					{
						RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_place_building_small", new Vector3(reference3.pos.x, reference3.groundY, reference3.pos.z));
					}
				}
				continue;
			}
			float num27 = ((constructionProgress >= 0.75f) ? 1f : 0f);
			Vector3 vector12 = num27 * new Vector3(pipeScale.x, pipeScale.y, reference3.pipeLengthScale);
			Vector3 vector13 = num27 * new Vector3(pipeSideScale.x, pipeSideScale.y, reference3.pipeLengthScale);
			Mathff.SetTRS(ref pipeMatricesForConstruction[num24], reference3.pos, reference3.pipeRot, vector12);
			Mathff.SetTRS(ref pipeSideLeftMatricesForConstruction[num24], reference3.pos + reference3.sideOffset, reference3.pipeRot, vector13);
			Mathff.SetTRS(ref pipeSideRightMatricesForConstruction[num24], reference3.pos - reference3.sideOffset, reference3.pipeRot, vector13);
			if (reference3.aqueductHeight > 0f)
			{
				Mathff.SetTRS(ref mat, reference3.pos, reference3.rot, scale);
				Mathff.SetTRS(ref mat2, offset, identity, one);
				constructingAquaductTopMatrixBuilder.Add(mat * mat2);
				buildMaterialIndexesTopAqueducts.Add(num24);
				buildingMaterial[num24].SetFloat("_WallProgress", constructionProgress * 1.5f);
				buildingMaterial[num24].SetFloat("_MinHeight", reference3.groundY);
				buildingMaterial[num24].SetFloat("_MaxHeight", reference3.pos.y);
				if (reference3.hasStraightCols)
				{
					Vector3 pos6 = new Vector3(reference3.pos.x, reference3.straightColTopY, reference3.pos.z);
					for (int num28 = 0; num28 < reference3.straightColCount; num28++)
					{
						Mathff.SetTRS(ref mat, pos6, reference3.rot, scale);
						Mathff.SetTRS(ref mat2, offset, identity, one);
						constructingAquaductMiddleMatrixBuilder.Add(mat * mat2);
						buildMaterialIndexesMiddles.Add(num24);
						pos6.y -= y;
					}
				}
				int straightScaffoldCount2 = reference3.straightScaffoldCount;
				for (int num29 = 0; num29 < straightScaffoldCount2; num29++)
				{
					if ((float)num29 / (float)straightScaffoldCount2 < constructionProgress * 2f && (float)num29 / (float)straightScaffoldCount2 < (1f - constructionProgress) * 4f)
					{
						Mathff.SetTRS(ref mat, reference3.pos.x, reference3.groundY + y4 * (float)num29, reference3.pos.z, reference3.rot, scaffoldAqueductScale);
						scaffoldMatricesBuilder.Add(mat);
					}
				}
				if (constructionProgress >= 0.75f && !didConstructionPuff[num24])
				{
					didConstructionPuff[num24] = true;
					EffectsMan.inst.BuildPuff.CreateAndPlay(new Vector3(reference3.pos.x, reference3.groundY, reference3.pos.z));
					if (!LoadSave.Loading)
					{
						RuntimeManager.PlayOneShot("event:/SFX ASITP/sfx_place_building_small", new Vector3(reference3.pos.x, reference3.groundY, reference3.pos.z));
					}
				}
			}
			if (reference3.hasStartEnd)
			{
				Mathff.SetTRS(ref mat, reference3.startEndPos, reference3.reverseRot, scale);
				constructingEndTopMatrixBuilder.Add(mat);
				buildMaterialIndexesEndTops.Add(num24);
				for (int num30 = 0; num30 < reference3.startEndColCount; num30++)
				{
					Vector3 pos7 = new Vector3(reference3.startEndPos.x, reference3.startEndColTopY - y3 * (float)num30, reference3.startEndPos.z);
					Mathff.SetTRS(ref mat, pos7, reference3.reverseRot, scale);
					constructingEndMiddleMatrixBuilder.Add(mat);
					buildMaterialIndexesEndMiddles.Add(num24);
				}
			}
			if (reference3.hasEndEnd)
			{
				Mathff.SetTRS(ref mat, reference3.endEndPos, reference3.rot, scale);
				constructingEndTopMatrixBuilder.Add(mat);
				buildMaterialIndexesEndTops.Add(num24);
				for (int num31 = 0; num31 < reference3.endEndColCount; num31++)
				{
					Vector3 pos8 = new Vector3(reference3.endEndPos.x, reference3.endEndColTopY - y3 * (float)num31, reference3.endEndPos.z);
					Mathff.SetTRS(ref mat, pos8, reference3.rot, scale);
					constructingEndMiddleMatrixBuilder.Add(mat);
					buildMaterialIndexesEndMiddles.Add(num24);
				}
			}
		}
		constructingTopAquaductMatrixIndices = buildMaterialIndexesTopAqueducts.ToArray();
		constructingMiddleAquaductMatrixIndices = buildMaterialIndexesMiddles.ToArray();
		constructingTopAquaductMatrix = constructingAquaductTopMatrixBuilder.ToArray();
		constructingMiddleAquaductMatrix = constructingAquaductMiddleMatrixBuilder.ToArray();
		constructingTopElbowMatrixIndices = buildMaterialIndexesTopElbows.ToArray();
		constructingMiddleElbowMatrixIndices = buildMaterialIndexesMiddlesElbows.ToArray();
		constructingTopElbowMatrix = constructingElbowTopMatrixBuilder.ToArray();
		constructingMiddleElbowMatrix = constructingElbowMiddleMatrixBuilder.ToArray();
		constructingEndTopMatrixIndices = buildMaterialIndexesEndTops.ToArray();
		constructingEndMiddleMatrixIndices = buildMaterialIndexesEndMiddles.ToArray();
		constructingEndTopMatrix = constructingEndTopMatrixBuilder.ToArray();
		constructingEndMiddleMatrix = constructingEndMiddleMatrixBuilder.ToArray();
		scaffoldMatrices = scaffoldMatricesBuilder.ToArray();
		ClearConstructingMatrixBuilders();
		MiniBuild();
	}

	public float GetInflowAmount()
	{
		return currentInputFlow;
	}

	public bool TryGetClosestPoint(Vector3 worldPosition, out AqueductLineIntersection intersection)
	{
		intersection = default;
		if (waypoints == null || waypoints.Length < 2)
		{
			return false;
		}
		float num = 0f;
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			num += Mathff.Dist(waypoints[i], waypoints[i + 1]);
		}
		if (num <= Mathf.Epsilon)
		{
			return false;
		}
		float num2 = float.MaxValue;
		int num3 = -1;
		float segmentT = 0f;
		Vector3 point = Vector3.zero;
		float normalizedT = 0f;
		float num4 = 0f;
		for (int j = 0; j < waypoints.Length - 1; j++)
		{
			Vector3 vector = waypoints[j];
			Vector3 vector2 = waypoints[j + 1] - vector;
			float magnitude = vector2.magnitude;
			if (!(magnitude <= Mathf.Epsilon))
			{
				float num5 = Mathf.Clamp01(Vector3.Dot(worldPosition - vector, vector2) / (magnitude * magnitude));
				Vector3 vector3 = vector + vector2 * num5;
				float sqrMagnitude = (vector3 - worldPosition).sqrMagnitude;
				if (sqrMagnitude < num2)
				{
					num2 = sqrMagnitude;
					num3 = j;
					segmentT = num5;
					point = vector3;
					normalizedT = (num4 + magnitude * num5) / num;
				}
				num4 += magnitude;
			}
		}
		if (num3 == -1)
		{
			return false;
		}
		intersection = new AqueductLineIntersection
		{
			line = this,
			segmentIndex = num3,
			segmentT = segmentT,
			normalizedT = normalizedT,
			point = point
		};
		return true;
	}

	private static bool WaterReadsAsZero(float waterAmount)
	{
		return waterAmount < 0.5f;
	}

	private float WaterMeshHeight(float humanWater)
	{
		return AqueductBuilding.HumanToSystem(humanWater) * waterHeightMult;
	}

	private float BelowPipeWater()
	{
		return AqueductBuilding.SystemToHuman(-0.01f);
	}

	private void UpdateOpenEndWaterfall()
	{
		bool flag = openEndWaterfallPrefab != null && fullyConstructed && !collapse && endOpen && waypoints != null && waypoints.Length >= 2 && currentOutputFlow >= 1f;
		if (flag == openEndWaterfallActive)
		{
			return;
		}
		openEndWaterfallActive = flag;
		if (flag)
		{
			if (openEndWaterfall == null)
			{
				openEndWaterfall = UnityEngine.Object.Instantiate(openEndWaterfallPrefab, transform);
				Vector3 vector = waypoints[waypoints.Length - 1];
				Vector3 vector2 = waypoints[waypoints.Length - 2];
				float num = WaterMeshHeight(Mathf.Min(currentOutputFlow, AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS));
				openEndWaterfall.transform.position = vector + Vector3.up * (num + heightOffset);
				openEndWaterfall.transform.rotation = OpenEndFlowRotation(vector - vector2);
			}
			openEndWaterfall.gameObject.SetActive(value: true);
			openEndWaterfall.splashParticles.Play(withChildren: true);
			openEndWaterfall.mistParticles.Play(withChildren: true);
		}
		else if (openEndWaterfall != null)
		{
			openEndWaterfall.splashParticles.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmitting);
			openEndWaterfall.mistParticles.Stop(withChildren: true, ParticleSystemStopBehavior.StopEmitting);
		}
	}

	private static Quaternion OpenEndFlowRotation(Vector3 flow)
	{
		if (flow.sqrMagnitude < 1E-06f)
		{
			return Quaternion.identity;
		}
		return Quaternion.LookRotation(flow.normalized, Vector3.up);
	}

	private void MiniBuild()
	{
		if (waterMesh == null)
		{
			return;
		}
		float deltaTime = Time.deltaTime;
		Vector3 up = Vector3.up;
		float num = 0f;
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			num += Mathff.Dist(waypoints[i], waypoints[i + 1]);
		}
		bool flag = false;
		for (int j = 0; j < waterFlowStateTransitionNodes.Count; j++)
		{
			waterFlowStateTransitionNodes[j].T += deltaTime / num;
			if (waterFlowStateTransitionNodes[j].T >= 1f)
			{
				flag = true;
				currentOutputFlow = waterFlowStateTransitionNodes[j].waterAmount;
				waterFlowStateTransitionNodes.RemoveAt(j);
				j--;
			}
		}
		if (flag && endAB != null)
		{
			endAB.UpdateWaterFlow();
		}
		waterVerts.Clear();
		waterUVs.Clear();
		float num2 = currentInputFlow;
		if (WaterReadsAsZero(num2))
		{
			num2 = BelowPipeWater();
		}
		num2 = Mathf.Min(num2, AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS);
		float num3 = currentOutputFlow;
		float num4 = 0f;
		float num5 = 0f;
		float num6 = 0f;
		float num7 = waterWidth / 2f;
		for (int k = 0; k < waypoints.Length - 1; k++)
		{
			Vector3 vector = waypoints[k];
			Vector3 vector2 = waypoints[k + 1];
			float num8 = Mathff.Dist(vector, vector2);
			float num9 = num8 / num;
			num5 = num4 + num9;
			Vector3 normalized = (vector2 - vector).normalized;
			Vector3 vector3 = Vector3.Cross(normalized.xz(), up) * num7;
			Vector3 vector4 = vector + up * WaterMeshHeight(num2) + up * heightOffset;
			waterVerts.Add(vector4 - vector3);
			waterVerts.Add(vector4 + vector3);
			waterUVs.Add(new Vector2(num6, 0.5f - num7));
			waterUVs.Add(new Vector2(num6, 0.5f + num7));
			num3 = num2;
			for (int l = 0; l < waterFlowStateTransitionNodes.Count; l++)
			{
				if (waterFlowStateTransitionNodes[l].T >= num4 && waterFlowStateTransitionNodes[l].T <= num5)
				{
					float waterAmount = waterFlowStateTransitionNodes[l].waterAmount;
					waterAmount = Mathf.Min(waterAmount, AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS);
					if (WaterReadsAsZero(waterAmount))
					{
						waterAmount = BelowPipeWater();
					}
					float t = waterFlowStateTransitionNodes[l].T;
					t = Mathf.InverseLerp(num4, num5, t);
					float num10 = ((l == waterFlowStateTransitionNodes.Count - 1) ? currentOutputFlow : waterFlowStateTransitionNodes[l + 1].waterAmount);
					if (WaterReadsAsZero(num10))
					{
						num10 = BelowPipeWater();
					}
					num10 = Mathf.Min(num10, AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS);
					Vector3 vector5 = num8 * t * normalized + vector + up * WaterMeshHeight(waterAmount) + up * heightOffset;
					waterVerts.Add(vector5 - vector3);
					waterVerts.Add(vector5 + vector3);
					float x = num6 + num8 * t;
					waterUVs.Add(new Vector2(x, 0.5f - num7));
					waterUVs.Add(new Vector2(x, 0.5f + num7));
					Vector3 vector6 = num8 * t * normalized + vector + up * WaterMeshHeight(num10) + up * heightOffset;
					waterVerts.Add(vector6 - vector3);
					waterVerts.Add(vector6 + vector3);
					waterUVs.Add(new Vector2(x, 0.5f - num7));
					waterUVs.Add(new Vector2(x, 0.5f + num7));
					num2 = num10;
					if (WaterReadsAsZero(num2))
					{
						num2 = BelowPipeWater();
					}
					num3 = num10;
				}
			}
			if (WaterReadsAsZero(num3))
			{
				num3 = BelowPipeWater();
			}
			Vector3 vector7 = num8 * normalized + vector + up * WaterMeshHeight(num3) + up * heightOffset;
			waterVerts.Add(vector7 - vector3);
			waterVerts.Add(vector7 + vector3);
			float x2 = num6 + num8;
			waterUVs.Add(new Vector2(x2, 0.5f - num7));
			waterUVs.Add(new Vector2(x2, 0.5f + num7));
			num6 += num8;
			num4 = num5;
		}
		int num11 = (waterVerts.Count - 2) * 6 / 2;
		if (waterIndies == null || waterIndies.Length != num11)
		{
			waterIndies = new int[num11];
			for (int m = 0; m < waterIndies.Length; m += 6)
			{
				int num12 = m / 6 * 2;
				waterIndies[m] = num12;
				waterIndies[m + 1] = num12 + 1;
				waterIndies[m + 2] = num12 + 2;
				waterIndies[m + 3] = num12 + 2;
				waterIndies[m + 4] = num12 + 1;
				waterIndies[m + 5] = num12 + 3;
			}
		}
		waterMesh.Clear();
		waterMesh.SetVertices(waterVerts);
		waterMesh.SetIndices(waterIndies, MeshTopology.Triangles, 0);
		waterMesh.SetUVs(0, waterUVs);
		waterMesh.RecalculateBounds();
		waterMesh.RecalculateNormals();
		waterMesh.RecalculateTangents();
		BuildArrowMesh();
	}

	private void BuildArrowMesh()
	{
		if (arrowMesh == null)
		{
			return;
		}
		if (waypoints == null || waypoints.Length < 2)
		{
			arrowMesh.Clear();
			return;
		}
		arrowVerts.Clear();
		arrowUVs.Clear();
		Vector3 up = Vector3.up;
		Vector3 vector = up * (heightOffset + arrowHeightOffset);
		float num = arrowWidth / 2f;
		float num2 = 0f;
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			Vector3 vector2 = waypoints[i];
			Vector3 vector3 = waypoints[i + 1];
			float num3 = Mathff.Dist(vector2, vector3);
			Vector3 vector4 = Vector3.Cross((vector3 - vector2).normalized.xz(), up) * num;
			Vector3 vector5 = vector2 + vector;
			arrowVerts.Add(vector5 - vector4);
			arrowVerts.Add(vector5 + vector4);
			arrowUVs.Add(new Vector2(num2, 0f));
			arrowUVs.Add(new Vector2(num2, 1f));
			num2 += num3;
			Vector3 vector6 = vector3 + vector;
			arrowVerts.Add(vector6 - vector4);
			arrowVerts.Add(vector6 + vector4);
			arrowUVs.Add(new Vector2(num2, 0f));
			arrowUVs.Add(new Vector2(num2, 1f));
		}
		int num4 = (arrowVerts.Count - 2) * 6 / 2;
		if (arrowIndies == null || arrowIndies.Length != num4)
		{
			arrowIndies = new int[num4];
			for (int j = 0; j < arrowIndies.Length; j += 6)
			{
				int num5 = j / 6 * 2;
				arrowIndies[j] = num5;
				arrowIndies[j + 1] = num5 + 1;
				arrowIndies[j + 2] = num5 + 2;
				arrowIndies[j + 3] = num5 + 2;
				arrowIndies[j + 4] = num5 + 1;
				arrowIndies[j + 5] = num5 + 3;
			}
		}
		arrowMesh.Clear();
		arrowMesh.SetVertices(arrowVerts);
		arrowMesh.SetIndices(arrowIndies, MeshTopology.Triangles, 0);
		arrowMesh.SetUVs(0, arrowUVs);
		arrowMesh.RecalculateBounds();
	}

	public static bool IsWaterBuildingSelected()
	{
		if (_waterSelCacheFrame == Time.frameCount)
		{
			return _waterSelCached;
		}
		_waterSelCacheFrame = Time.frameCount;
		_waterSelCached = false;
		if (GameUI.inst.GetGenericBuildingSelected() is Component component && component != null)
		{
			int waterSelCached;
			if (!(component.GetComponent<AqueductBuilding>() != null) && !(component.GetComponent<AqueductLine>() != null))
			{
				Building component2 = component.GetComponent<Building>();
				waterSelCached = (((object)component2 != null && component2.categoryHash == World.bathCategoryHash) ? 1 : 0);
			}
			else
			{
				waterSelCached = 1;
			}
			_waterSelCached = (byte)waterSelCached != 0;
		}
		return _waterSelCached;
	}

	public void CollectWavefronts(List<Wavefront> results)
	{
		if (!fullyConstructed || displayOnly || waypoints == null || waypoints.Length < 2 || this.waterFlowStateTransitionNodes == null)
		{
			return;
		}
		float num = 0f;
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			num += Mathff.Dist(waypoints[i], waypoints[i + 1]);
		}
		if (num <= 0.0001f)
		{
			return;
		}
		for (int j = 0; j < this.waterFlowStateTransitionNodes.Count; j++)
		{
			WaterFlowStateTransitionNodes waterFlowStateTransitionNodes = this.waterFlowStateTransitionNodes[j];
			if (waterFlowStateTransitionNodes != null)
			{
				float waterAmount = currentOutputFlow;
				if (j + 1 < this.waterFlowStateTransitionNodes.Count && this.waterFlowStateTransitionNodes[j + 1] != null)
				{
					waterAmount = this.waterFlowStateTransitionNodes[j + 1].waterAmount;
				}
				Vector3 worldPos = WorldPositionAtT(waterFlowStateTransitionNodes.T, num) + Vector3.up * (WaterMeshHeight(Mathf.Max(0f, waterFlowStateTransitionNodes.waterAmount)) + heightOffset + 0.12f);
				if (waterFlowStateTransitionNodes.waterAmount - waterAmount > 0f)
				{
					results.Add(new Wavefront
					{
						worldPos = worldPos,
						label = $"{waterFlowStateTransitionNodes.waterAmount - waterAmount:0;-0;0}"
					});
				}
			}
		}
	}

	private Vector3 WorldPositionAtT(float t, float lineDistTotal)
	{
		t = Mathf.Clamp01(t);
		float num = t * lineDistTotal;
		float num2 = 0f;
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			float num3 = Mathff.Dist(waypoints[i], waypoints[i + 1]);
			if (num2 + num3 >= num || i == waypoints.Length - 2)
			{
				float value = ((num3 > 0.0001f) ? ((num - num2) / num3) : 0f);
				return Vector3.Lerp(waypoints[i], waypoints[i + 1], Mathf.Clamp01(value));
			}
			num2 += num3;
		}
		return waypoints[waypoints.Length - 1];
	}

	private void Update()
	{
		if (displayOnly)
		{
			return;
		}
		MiniBuild();
		UpdateOpenEndWaterfall();
		if (!fullyConstructed || collapse)
		{
			if (_geometryCacheValid)
			{
				AnimationUpdate();
			}
			else
			{
				FullBuild();
			}
		}
		if (fullyCollapsed && !LoadSave.Loading)
		{
			UnityEngine.Object.Destroy(gameObject);
			SpawnRefundStacks();
		}
	}

	private void LateUpdate()
	{
		if (displayOnly)
		{
			FullBuild();
			BuildArrowMesh();
		}
		DrawMeshes();
	}

	public void DrawMeshes()
	{
		if (invalid)
		{
			for (int i = 0; i < topMatrices.Length; i++)
			{
				Graphics.DrawMesh(aqueductStraight, topMatrices[i], invalidMaterial, 0);
			}
			for (int j = 0; j < middleMatrices.Length; j++)
			{
				Graphics.DrawMesh(aqueductArch, middleMatrices[j], invalidMaterial, 0);
			}
			invalid = displayOnly;
		}
		else if (!_usingInstancedRendering)
		{
			Graphics.DrawMeshInstanced(aqueductStraight, 0, material, topMatrices);
			Graphics.DrawMeshInstanced(aqueductArch, 0, material, middleMatrices);
		}
		if (fullyConstructed)
		{
			if (invalid)
			{
				DrawStructuralMeshes(invalidMaterial);
				if (!collapse && arrowMaterial != null)
				{
					Graphics.DrawMesh(arrowMesh, Matrix4x4.identity, arrowMaterial, 0, Cam.inst.cam, 0, null, castShadows: false);
				}
				invalid = false;
				return;
			}
			if (_usingInstancedRendering)
			{
				if (!collapse)
				{
					Graphics.DrawMesh(waterMesh, Matrix4x4.identity, waterMaterial, 0, Cam.inst.cam, 0, props, castShadows: false);
					if (arrowMaterial != null)
					{
						Graphics.DrawMesh(arrowMesh, Matrix4x4.identity, arrowMaterial, 0, Cam.inst.cam, 0, null, castShadows: false);
					}
				}
				return;
			}
			DrawStructuralMeshes(material);
			if (!collapse)
			{
				Graphics.DrawMesh(waterMesh, Matrix4x4.identity, waterMaterial, 0, Cam.inst.cam, 0, props, castShadows: false);
				if (arrowMaterial != null)
				{
					Graphics.DrawMesh(arrowMesh, Matrix4x4.identity, arrowMaterial, 0, Cam.inst.cam, 0, null, castShadows: false);
				}
			}
			return;
		}
		for (int k = 0; k < constructingTopAquaductMatrix.Length; k++)
		{
			Graphics.DrawMesh(aqueductStraight, constructingTopAquaductMatrix[k], buildingMaterial[constructingTopAquaductMatrixIndices[k]], 0);
		}
		for (int l = 0; l < constructingMiddleAquaductMatrix.Length; l++)
		{
			Graphics.DrawMesh(aqueductArch, constructingMiddleAquaductMatrix[l], buildingMaterial[constructingMiddleAquaductMatrixIndices[l]], 0);
		}
		for (int m = 0; m < constructingTopElbowMatrix.Length; m++)
		{
			Graphics.DrawMesh(elbowMeshTop, constructingTopElbowMatrix[m], buildingMaterial[constructingTopElbowMatrixIndices[m]], 0);
		}
		for (int n = 0; n < constructingMiddleElbowMatrix.Length; n++)
		{
			Graphics.DrawMesh(elbowMesh, constructingMiddleElbowMatrix[n], buildingMaterial[constructingMiddleElbowMatrixIndices[n]], 0);
		}
		for (int num = 0; num < constructingEndTopMatrix.Length; num++)
		{
			Graphics.DrawMesh(aqueductEndTop, constructingEndTopMatrix[num], buildingMaterial[constructingEndTopMatrixIndices[num]], 0);
		}
		for (int num2 = 0; num2 < constructingEndMiddleMatrix.Length; num2++)
		{
			Graphics.DrawMesh(aqueductEnd, constructingEndMiddleMatrix[num2], buildingMaterial[constructingEndMiddleMatrixIndices[num2]], 0);
		}
		Graphics.DrawMeshInstanced(elbowMesh, 0, material, elbowMatrices);
		Graphics.DrawMeshInstanced(elbowMeshTop, 0, material, elbowMatricesTop);
		Graphics.DrawMeshInstanced(aqueductEnd, 0, material, endMatrices);
		Graphics.DrawMeshInstanced(aqueductEndTop, 0, material, endMatricesTop);
		Graphics.DrawMeshInstanced(stakeMesh, 0, material, stakesForConstruction);
		Graphics.DrawMeshInstanced(aqueductPipe, 0, material, pipeMatricesForConstruction);
		if (pipeSideLeftMatricesForConstruction != null && pipeSideRightMatricesForConstruction != null)
		{
			Graphics.DrawMeshInstanced(aqueductPipeSide, 0, material, pipeSideLeftMatricesForConstruction);
			Graphics.DrawMeshInstanced(aqueductPipeSide, 0, material, pipeSideRightMatricesForConstruction);
		}
		Graphics.DrawMeshInstanced(scaffoldMesh, 0, material, scaffoldMatrices);
	}

	private void DrawStructuralMeshes(Material m)
	{
		Draw(aqueductPipe, pipeMatrices);
		if (pipeSideLeftMatrices != null && pipeSideRightMatrices != null)
		{
			Draw(aqueductPipeSide, pipeSideLeftMatrices);
			Draw(aqueductPipeSide, pipeSideRightMatrices);
			if (pipeSideConnectorMatrices != null && pipeSideConnectorMatrices.Length != 0)
			{
				Draw(aqueductPipeSide, pipeSideConnectorMatrices);
			}
		}
		Draw(aqueductEnd, endMatrices);
		Draw(aqueductTunnel, tunnelMatrices);
		Draw(aqueductEndTop, endMatricesTop);
		Draw(elbowMesh, elbowMatrices);
		Draw(elbowMeshTop, elbowMatricesTop);
		void Draw(Mesh mesh, Matrix4x4[] matrices)
		{
			if (m == invalidMaterial)
			{
				for (int i = 0; i < matrices.Length; i++)
				{
					Graphics.DrawMesh(mesh, matrices[i], m, 0);
				}
			}
			else
			{
				Graphics.DrawMeshInstanced(mesh, 0, m, matrices);
			}
		}
	}

	public void DrawOutline(CommandBuffer commandBuffer, Material m)
	{
		DrawHighlight(commandBuffer, m, 0);
	}

	public ResourceAmount GetBuildCost()
	{
		return costPerMesh * numOfFullCost + ResourceAmount.Make(2, numOfReducedCost);
	}

	public void DrawHighlight(CommandBuffer commandBuffer, Material m, int pass)
	{
		if (collapse)
		{
			return;
		}
		commandBuffer.DrawMeshInstanced(aqueductStraight, 0, m, pass, topMatrices);
		commandBuffer.DrawMeshInstanced(aqueductArch, 0, m, pass, middleMatrices);
		commandBuffer.DrawMeshInstanced(aqueductStraight, 0, m, pass, topMatrices);
		commandBuffer.DrawMeshInstanced(aqueductPipe, 0, m, pass, pipeMatrices);
		if (pipeSideLeftMatrices != null && pipeSideRightMatrices != null)
		{
			commandBuffer.DrawMeshInstanced(aqueductPipeSide, 0, m, pass, pipeSideLeftMatrices);
			commandBuffer.DrawMeshInstanced(aqueductPipeSide, 0, m, pass, pipeSideRightMatrices);
			if (pipeSideConnectorMatrices != null && pipeSideConnectorMatrices.Length != 0)
			{
				commandBuffer.DrawMeshInstanced(aqueductPipeSide, 0, m, pass, pipeSideConnectorMatrices);
			}
		}
		commandBuffer.DrawMeshInstanced(aqueductTunnel, 0, m, pass, tunnelMatrices);
		commandBuffer.DrawMeshInstanced(aqueductEnd, 0, m, pass, endMatrices);
		commandBuffer.DrawMeshInstanced(aqueductEndTop, 0, m, pass, endMatricesTop);
		commandBuffer.DrawMeshInstanced(elbowMesh, 0, m, pass, elbowMatrices);
		commandBuffer.DrawMeshInstanced(elbowMeshTop, 0, m, pass, elbowMatricesTop);
	}

	public void DestroySelf(bool triggerCollapse = true)
	{
		UnregisterFromInstanceManager();
		DisableSegmentColliders();
		if (startAB != null)
		{
			startAB.RemoveAqueductLine(this);
		}
		if (endAB != null)
		{
			endAB.RemoveAqueductLine(this);
		}
		if (allLines.Contains(this))
		{
			allLines.Remove(this);
		}
		AqueductFlowController.MarkTopologyDirty("DestroySelf");
		CalculateRefundAmounts();
		for (int i = 0; i < constructionForemans.Length; i++)
		{
			constructionForemans[i].RemoveJobs();
		}
		if (triggerCollapse)
		{
			collapse = true;
		}
		else
		{
			UnityEngine.Object.Destroy(gameObject);
		}
	}

	public void DetachFrom(AqueductBuilding building)
	{
		if (!(building == null))
		{
			bool flag = false;
			if (startAB == building)
			{
				startAB = null;
				startOpen = true;
				flag = true;
			}
			if (endAB == building)
			{
				endAB = null;
				endOpen = true;
				flag = true;
			}
			if (flag)
			{
				valveRatio = 0f;
				SetWaterFlow(0f);
				AqueductFlowController.MarkTopologyDirty("DetachFrom");
			}
		}
	}

	public static void ReconnectOpenEndsTo(AqueductBuilding building)
	{
		if (LoadSave.Loading || building == null || building is AqueductJunction)
		{
			return;
		}
		for (int i = 0; i < allLines.Count; i++)
		{
			AqueductLine aqueductLine = allLines[i];
			if (!(aqueductLine == null) && aqueductLine.IsOpenEnded)
			{
				if (!building.HasAvailablePorts())
				{
					break;
				}
				aqueductLine.TryReconnectOpenEnd(building);
			}
		}
	}

	private void AttachOpenEnd(AqueductBuilding building, bool atStart)
	{
		int num = ((!atStart) ? (waypoints.Length - 1) : 0);
		int num2 = ((waypoints.Length <= 1) ? num : (atStart ? 1 : (waypoints.Length - 2)));
		Vector3[] array = (Vector3[])waypoints.Clone();
		Vector3 vector = waypoints[num];
		Vector3 vector2 = waypoints[num2];
		Vector3 portPosition = building.GetPortPosition(vector2);
		waypoints[num] = portPosition;
		Vector3 vector3 = new Vector3(portPosition.x - vector2.x, 0f, portPosition.z - vector2.z);
		bool flag = vector3.sqrMagnitude < 0.0001f;
		if (flag || NumberOfConstructions() < 1)
		{
			endpointsPinned = true;
			if (flag)
			{
				vector3 = new Vector3(vector.x - vector2.x, 0f, vector.z - vector2.z);
			}
			Vector3 vector4 = vector2 + vector3.normalized * (aqueductStraight.bounds.size.z * 1.01f);
			vector4.y = portPosition.y;
			waypoints[num] = vector4;
			if (!PointInAnyPortBox(building, vector4, 0f) || NumberOfConstructions() < 1)
			{
				waypoints[num] = vector;
			}
		}
		GradeWaypoints(ref waypoints);
		if (!fullyConstructed && NumberOfConstructions() != constructionForemans.Length)
		{
			endpointsPinned = true;
			waypoints = array;
		}
		if (atStart)
		{
			startAB = building;
			startOpen = false;
		}
		else
		{
			endAB = building;
			endOpen = false;
		}
	}

	private void TryReconnectOpenEnd(AqueductBuilding building)
	{
		if (!(startAB == building) && !(endAB == building))
		{
			if (startOpen && PointInAnyPortBox(building, waypoints[0], 0.5f))
			{
				AttachOpenEnd(building, atStart: true);
				ReconnectTo(building);
			}
			else if (endOpen && PointInAnyPortBox(building, waypoints[^1], 0.5f))
			{
				AttachOpenEnd(building, atStart: false);
				ReconnectTo(building);
			}
		}
	}

	private void ReconnectTo(AqueductBuilding building)
	{
		building.ConnectLine(this);
		UnregisterFromInstanceManager();
		BuildGeometryCache();
		FullBuild();
		building.UpdateWaterFlow();
		AqueductFlowController.MarkTopologyDirty("ReconnectTo");
		if (building is AqueductJunction aqueductJunction)
		{
			aqueductJunction.TryCollapseLines();
		}
	}

	public void CloseOpenEnd(AqueductBuilding building, bool atStart)
	{
		if (!(building == null) && !(atStart ? (!startOpen) : (!endOpen)))
		{
			AttachOpenEnd(building, atStart);
			ReconnectTo(building);
		}
	}

	private static bool PointInAnyPortBox(AqueductBuilding building, Vector3 p, float epsilon)
	{
		if (building.portBoxes == null)
		{
			return false;
		}
		for (int i = 0; i < building.portBoxes.Length; i++)
		{
			AqueductBuilding.PortBox portBox = building.portBoxes[i];
			if (portBox != null && !(portBox.corner1 == null) && !(portBox.corner2 == null))
			{
				building.GetPortBox(out var min, out var max, i);
				if (p.x >= min.x - epsilon && p.x <= max.x + epsilon && p.z >= min.z - epsilon && p.z <= max.z + epsilon)
				{
					return true;
				}
			}
		}
		return false;
	}

	public void CalculateRefundAmounts()
	{
		int num = ((constructionForemans != null) ? constructionForemans.Length : 0);
		refundStoneAmounts = new int[num];
		refundPositions = new Vector3[num];
		if (num == 0 || waypoints == null || waypoints.Length < 2)
		{
			return;
		}
		int num2 = ((costPerMesh != null) ? costPerMesh.Get(2) : 0);
		if (num2 <= 0)
		{
			return;
		}
		if (isSegmentTunnel == null)
		{
			CalculateSegmentTunnelStatus();
		}
		float[] waypointGroundY = _waypointGroundY;
		bool flag = waypointGroundY != null && waypointGroundY.Length == waypoints.Length;
		int num3 = 0;
		float z = aqueductStraight.bounds.size.z;
		int terrainMask = cachedTerrainMask;
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			Vector3 vector = waypoints[i];
			Vector3 vector2 = waypoints[i + 1];
			float num4 = Mathff.Dist(vector, vector2);
			int num5 = Mathf.FloorToInt(num4 / z);
			float num6 = num4 - (float)num5 * z;
			Vector3 normalized = (vector2 - vector).normalized;
			if (i != 0 && num3 < constructionForemans.Length)
			{
				float y = (flag ? waypointGroundY[i] : GetTerrainHeightAt(vector, terrainMask));
				int segmentCost = ((isSegmentTunnel != null && num3 < isSegmentTunnel.Length && isSegmentTunnel[num3]) ? 1 : num2);
				refundPositions[num3] = new Vector3(vector.x, y, vector.z);
				CalculateSegmentRefund(num3, segmentCost);
				num3++;
			}
			for (int j = 0; j < num5; j++)
			{
				if (num3 >= constructionForemans.Length)
				{
					break;
				}
				Vector3 pos = vector + j * normalized * z + normalized * z * 0.5f + normalized * num6 * 0.5f;
				float terrainHeightAt = GetTerrainHeightAt(pos, terrainMask);
				int segmentCost2 = ((isSegmentTunnel != null && num3 < isSegmentTunnel.Length && isSegmentTunnel[num3]) ? 1 : num2);
				refundPositions[num3] = new Vector3(pos.x, terrainHeightAt, pos.z);
				CalculateSegmentRefund(num3, segmentCost2);
				num3++;
			}
		}
	}

	private float GetTerrainHeightAt(Vector3 pos, int terrainMask)
	{
		Vector3 up = Vector3.up;
		Vector3 down = Vector3.down;
		if (Physics.Raycast(new Ray(pos + up * 100f, down), out var hitInfo, 200f, terrainMask))
		{
			return hitInfo.point.y;
		}
		return pos.y;
	}

	private void CalculateSegmentRefund(int segmentIndex, int segmentCost)
	{
		if (fullyConstructed)
		{
			refundStoneAmounts[segmentIndex] = Mathf.Max(1, (int)((float)(segmentCost + 1) * 0.75f));
			return;
		}
		ConstructionForeman constructionForeman = constructionForemans[segmentIndex];
		if (constructionForeman.ConstructionProgress >= 1f)
		{
			refundStoneAmounts[segmentIndex] = Mathf.Max(1, segmentCost);
			return;
		}
		int num = constructionForeman.GetCollectedResources().Get(2);
		refundStoneAmounts[segmentIndex] = num;
	}

	private void SpawnRefundStacks()
	{
		if (refundStoneAmounts == null || refundPositions == null || Creative.inst.IsCreativeOptionOn(0))
		{
			return;
		}
		for (int i = 0; i < refundStoneAmounts.Length; i++)
		{
			if (refundStoneAmounts[i] > 0 && World.inst.GetCellDataClamped(refundPositions[i]).landMassIdx != -1)
			{
				FreeResourceManager.inst.AddOrMakeAutoStackFor(2, refundStoneAmounts[i], refundPositions[i]);
			}
		}
		refundStoneAmounts = null;
		refundPositions = null;
	}

	private void CalculateSegmentTunnelStatus()
	{
		if (waypoints == null || waypoints.Length < 2)
		{
			return;
		}
		Vector3 up = Vector3.up;
		Vector3 down = Vector3.down;
		int num = NumberOfConstructions();
		isSegmentTunnel = new bool[num];
		int num2 = 0;
		float z = aqueductStraight.bounds.size.z;
		int num3 = cachedTerrainMask;
		for (int i = 0; i < waypoints.Length - 1; i++)
		{
			Vector3 vector = waypoints[i];
			Vector3 vector2 = waypoints[i + 1];
			float num4 = Mathff.Dist(vector, vector2);
			int num5 = Mathf.FloorToInt(num4 / z);
			float num6 = num4 - (float)num5 * z;
			Vector3 normalized = (vector2 - vector).normalized;
			if (i != 0 && num2 < num)
			{
				float terrainHeightAt = GetTerrainHeightAt(vector, num3);
				isSegmentTunnel[num2] = vector.y <= terrainHeightAt;
				num2++;
			}
			for (int j = 0; j < num5; j++)
			{
				if (num2 >= num)
				{
					break;
				}
				Vector3 vector3 = vector + j * normalized * z + normalized * z * 0.5f + normalized * num6 * 0.5f;
				Vector3 vector4 = vector + j * normalized * z;
				Vector3 vector5 = vector + (j + 1) * normalized * z;
				float y = vector4.y;
				float y2 = vector5.y;
				Ray ray = new Ray(vector4 + up * 50f, down);
				Ray ray2 = new Ray(vector5 + up * 50f, down);
				if (Physics.Raycast(ray, out var hitInfo, 100f, num3))
				{
					y = hitInfo.point.y;
				}
				if (Physics.Raycast(ray2, out var hitInfo2, 100f, num3))
				{
					y2 = hitInfo2.point.y;
				}
				float num7 = Mathf.Min(y, y2);
				float num8 = vector3.y - num7;
				isSegmentTunnel[num2] = num8 <= 0f;
				num2++;
			}
		}
	}

	public bool IsProvidingWaterTo(AqueductBuilding thisEnd)
	{
		return thisEnd == endAB;
	}

	public bool IsSendingWaterTo(AqueductBuilding thisEnd)
	{
		return thisEnd == startAB;
	}

	public AqueductBuilding GetOtherEnd(AqueductBuilding thisEnd)
	{
		if (thisEnd == startAB)
		{
			return endAB;
		}
		if (thisEnd == endAB)
		{
			return startAB;
		}
		return null;
	}

	public void SetWaterFlow(float waterFlow)
	{
		hasWater = waterFlow >= 1f;
		currentInputFlow = waterFlow;
		List<WaterFlowStateTransitionNodes> list = waterFlowStateTransitionNodes;
		if (list.Count > 0 && Time.frameCount - list[0].createdFrame <= 1)
		{
			list[0].waterAmount = waterFlow;
		}
		else
		{
			if (Math.Abs(((list.Count > 0) ? list[0].waterAmount : currentOutputFlow) - waterFlow) <= 0.5f)
			{
				return;
			}
			list.Insert(0, new WaterFlowStateTransitionNodes
			{
				waterAmount = waterFlow,
				T = 0f,
				createdFrame = Time.frameCount
			});
		}
		float num = ((list.Count > 1) ? list[1].waterAmount : currentOutputFlow);
		if (Math.Abs(list[0].waterAmount - num) <= 0.5f)
		{
			list.RemoveAt(0);
		}
	}

	public ResourceAmount GetTrueCost(int clientIndex)
	{
		if (Creative.inst.IsCreativeOptionOn(0))
		{
			return freeTrueCost;
		}
		if (isSegmentTunnel != null && clientIndex < isSegmentTunnel.Length && isSegmentTunnel[clientIndex])
		{
			return ResourceAmount.Make(2, 1);
		}
		return costPerMesh;
	}

	public string GetFriendlyName(int clientIndex)
	{
		return ScriptLocalization.Building_aqueductDummyBuilding_FriendlyName;
	}

	public float BuildTimeAtMaxStaff(int clientIndex)
	{
		return 10f;
	}

	public void GetBoundingFootprint(int clientIndex, out int minX, out int minZ, out int maxX, out int maxZ)
	{
		minX = constructionFootprint[clientIndex][0].x;
		minZ = constructionFootprint[clientIndex][0].y;
		maxX = constructionFootprint[clientIndex][1].x;
		maxZ = constructionFootprint[clientIndex][1].y;
	}

	public Vector3 GetPosition(int clientIndex)
	{
		Vector3 vector = new Vector3
		{
			x = (float)(constructionFootprint[clientIndex][0].x + constructionFootprint[clientIndex][1].x) * 0.5f,
			z = (float)(constructionFootprint[clientIndex][0].y + constructionFootprint[clientIndex][1].y) * 0.5f
		};
		vector.y = TerrainGen.inst.GetInterpolatedHeight(vector);
		return vector;
	}

	public TransformData GetPositionForBuilder(int clientIndex, int index)
	{
		int num = index;
		if (num >= personPositions[clientIndex].Length)
		{
			num = personPositions[clientIndex].Length - 1;
		}
		return new TransformData
		{
			position = personPositions[clientIndex][num]
		};
	}

	public int LandMass(int clientIndex)
	{
		return landmass;
	}

	public int LandMass()
	{
		return LandMass(0);
	}

	public int TeamID()
	{
		if (endAB != null && endAB.b != null)
		{
			return endAB.b.TeamID();
		}
		if (startAB != null && startAB.b != null)
		{
			return startAB.b.TeamID();
		}
		LandmassOwner landmassOwner = World.GetLandmassOwner(LandMass());
		if (!(landmassOwner != null))
		{
			return 0;
		}
		return landmassOwner.teamId;
	}

	public bool CanDemolishBuilding()
	{
		return true;
	}

	public void DemolishBuilding()
	{
		DestroySelf();
	}

	public void PlaySelectSound()
	{
		EventInstance eventInstance = RuntimeManager.CreateInstance(onBuildingSelectEvent.Guid);
		eventInstance.set3DAttributes(Center().To3DAttributes());
		eventInstance.setParameterByName("parameter:/WaterState", hasWater ? 1 : 0);
		eventInstance.start();
	}

	public bool UnderConstruction()
	{
		return !fullyConstructed;
	}

	public bool ConstructionPaused()
	{
		return isProjectPaused;
	}

	public void PauseConstruction()
	{
		if (isProjectPaused)
		{
			return;
		}
		isProjectPaused = true;
		for (int i = 0; i < constructionForemans.Length; i++)
		{
			if (!constructionForemans[i].ConstructionPaused)
			{
				constructionForemans[i].ConstructionPaused = true;
			}
		}
		meshesUnderConstruction = 0;
	}

	public void UnpauseConstruction()
	{
		if (isProjectPaused)
		{
			isProjectPaused = false;
		}
	}

	public void GetConstructionSummary(ref ConstructionForeman.ConstructionSummary summary)
	{
		summary.Summarize(constructionForemans);
		summary.totalWorkers = GetBuildAllowedWorkers() * Mathff.Min(RemainingToConstruct(), meshesToConstructAtOnce);
		for (int i = 0; i < constructionForemans.Length; i++)
		{
			if (constructionForemans[i].ConstructionProgress >= 1f)
			{
				summary.workersAssigned -= constructionForemans[i].GetWorkersAssigned;
			}
		}
	}

	private int RemainingToConstruct()
	{
		int num = 0;
		for (int i = 0; i < constructionForemans.Length; i++)
		{
			if (constructionForemans[i].ConstructionProgress < 1f)
			{
				num++;
			}
		}
		return num;
	}

	public bool BuildFootprintClear()
	{
		return true;
	}

	public bool WorkersAssignedToClearFootprint()
	{
		return true;
	}

	public int GetBuildAllowedWorkers()
	{
		return 3;
	}

	public Vector3 Center()
	{
		return Vector3.Lerp(waypoints[0], waypoints[^1], 0.5f);
	}

	public int UniqueNameHash()
	{
		return World.aqueductLineHash;
	}

	public bool IsOpen()
	{
		return true;
	}

	public int CategoryHash()
	{
		return World.aqueductLineHash;
	}

	public void SetOutlineImmediate(int colorIdx)
	{
		highlight.SetOutlineImmediate(colorIdx);
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	public void DisplayOnly(bool b)
	{
		displayOnly = b;
	}

	public void SetMeshInvalid()
	{
		invalid = true;
	}

	public void SetMeshValid()
	{
		invalid = false;
	}

	public void Place()
	{
		BuildGeometryCache();
		allLines.Add(this);
	}
}
