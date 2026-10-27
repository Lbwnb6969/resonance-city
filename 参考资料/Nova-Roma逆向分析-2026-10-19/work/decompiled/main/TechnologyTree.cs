using System;
using System.Collections;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using FMODUnity;
using I2.Loc;
using Sirenix.OdinInspector;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class TechnologyTree : MonoBehaviour
{
	[Serializable]
	public class TechnologyTreeLink
	{
		public TechnologyTreeNode node1;

		public TechnologyTreeNode node2;

		public TechnologyTreeLine line;

		public bool DoesProvideUnlock(TechnologyTreeNode node)
		{
			if (!(node1 != node) || !node1.isUnlocked)
			{
				if (node2 != node)
				{
					return node2.isUnlocked;
				}
				return false;
			}
			return true;
		}

		public void UpdateVisuals()
		{
			bool foregroundVisibility = (node1.isUnlockable && node1.isUnlocked) || (node2.isUnlockable && node2.isUnlocked);
			bool fillForegroundVisibility = node1.isUnlocked && node2.isUnlocked;
			line.SetForegroundVisibility(foregroundVisibility);
			line.SetFillForegroundVisibility(fillForegroundVisibility);
		}

		public override bool Equals(object obj)
		{
			if (obj is TechnologyTreeLink technologyTreeLink)
			{
				if (line == technologyTreeLink.line && node1 == technologyTreeLink.node1)
				{
					return node2 == technologyTreeLink.node2;
				}
				return false;
			}
			return base.Equals(obj);
		}
	}

	[Serializable]
	public class TechnologyTreeRequireLink
	{
		public List<TechnologyTreeNode> nodes = new List<TechnologyTreeNode>();

		public List<TechnologyTreeLine> lines = new List<TechnologyTreeLine>();

		public TechnologyTreeNode requirerNode;

		public TechnologyTreeLine requirerLine;

		public TechnologyTreeConnector connector;

		public void UpdateVisuals()
		{
			bool isUnlocked = requirerNode.isUnlocked;
			bool flag = true;
			bool flag2 = false;
			for (int i = 0; i < nodes.Count; i++)
			{
				lines[i].SetForegroundVisibility(nodes[i].isUnlocked);
				lines[i].SetFillForegroundVisibility(isUnlocked);
				if (nodes[i].isUnlocked)
				{
					flag2 = true;
				}
				else
				{
					flag = false;
				}
			}
			if (flag2)
			{
				for (int j = 0; j < nodes.Count; j++)
				{
					if (nodes[j].isHidden)
					{
						nodes[j].isHidden = false;
						nodes[j].UpdateVisuals();
					}
				}
			}
			requirerLine.SetForegroundVisibility(flag);
			requirerLine.SetFillForegroundVisibility(requirerNode.isUnlocked);
			connector.SetVisibility(!flag & flag2);
			string rText = string.Empty;
			inst.IsNodeRequirementsUnlocked(requirerNode, ref rText);
			connector.tooltipHook.toolTipText = rText;
		}

		public bool DoesProvideUnlock(TechnologyTreeNode node)
		{
			if (node == requirerNode)
			{
				for (int i = 0; i < nodes.Count; i++)
				{
					if (nodes[i].isUnlocked)
					{
						return true;
					}
				}
			}
			return false;
		}

		public bool IsUnlockable()
		{
			for (int i = 0; i < nodes.Count; i++)
			{
				if (!nodes[i].isUnlocked)
				{
					return false;
				}
			}
			return true;
		}

		public override bool Equals(object obj)
		{
			if (obj is TechnologyTreeRequireLink technologyTreeRequireLink)
			{
				if (connector != technologyTreeRequireLink.connector || requirerNode != technologyTreeRequireLink.requirerNode || requirerLine != technologyTreeRequireLink.requirerLine)
				{
					return false;
				}
				for (int i = 0; i < nodes.Count; i++)
				{
					if (technologyTreeRequireLink.nodes[i] != nodes[i])
					{
						return false;
					}
				}
			}
			return base.Equals(obj);
		}
	}

	public enum AnimationStage
	{
		EaseInOut,
		LineFill,
		Sheen
	}

	[Serializable]
	public class TechnologyTreeSaveData : SaveClass<TechnologyTree, TechnologyTreeSaveData>
	{
		[Serializable]
		public struct NodeData
		{
			public bool isUnlockable;

			public bool isUnlocked;

			public bool isHidden;

			public SerializableGuid guid;
		}

		private NodeData[] nodeData;

		private List<string> unlockedKeys;

		private bool isFirstTimeOpening;

		public override TechnologyTreeSaveData Pack(TechnologyTree techTree)
		{
			nodeData = new NodeData[techTree.nodes.Count];
			for (int i = 0; i < techTree.nodes.Count; i++)
			{
				TechnologyTreeNode technologyTreeNode = techTree.nodes[i];
				nodeData[i].isUnlockable = technologyTreeNode.isUnlockable;
				nodeData[i].isUnlocked = technologyTreeNode.isUnlocked;
				nodeData[i].isHidden = technologyTreeNode.isHidden;
				nodeData[i].guid = technologyTreeNode.guid;
			}
			isFirstTimeOpening = techTree.isFirstTimeOpening;
			return this;
		}

		public override TechnologyTree Unpack(TechnologyTree techTree)
		{
			techTree.unlockedKeys = new List<string>(nodeData.Length);
			for (int i = 0; i < techTree.nodes.Count; i++)
			{
				TechnologyTreeNode technologyTreeNode = techTree.nodes[i];
				for (int j = 0; j < nodeData.Length; j++)
				{
					if (technologyTreeNode.guid.Equals(nodeData[j].guid))
					{
						if (nodeData[j].isUnlocked && !techTree.unlockedKeys.Contains(technologyTreeNode.unlockKey))
						{
							techTree.AddUnlockKey(technologyTreeNode.unlockKey);
						}
						technologyTreeNode.isUnlockable = nodeData[j].isUnlockable;
						technologyTreeNode.isUnlocked = nodeData[j].isUnlocked;
						technologyTreeNode.isHidden = nodeData[j].isHidden;
						break;
					}
				}
			}
			for (int k = 0; k < techTree.unlockedKeys.Count; k++)
			{
				Broadcast.TechnologyTreeUnlockEvent.Broadcast(new OnTechnologyTreeUnlock
				{
					unlockKey = techTree.unlockedKeys[k],
					unlocked = true
				});
			}
			techTree.isFirstTimeOpening = isFirstTimeOpening;
			techTree.UpdateNodes();
			return techTree;
		}
	}

	public class UnlockKeys
	{
		public const string Forum = "unlockkey_forum";

		public const string Winery = "unlockkey_winery";

		public const string Weaponsmith = "unlockkey_weaponsmith";

		public const string Toolsmith = "unlockkey_toolsmith";

		public const string TaxOffice = "unlockkey_taxoffice";

		public const string Mason = "unlockkey_mason";

		public const string OliveTress = "unlockkey_olivetrees";

		public const string OlivePress = "unlockkey_olivepress";

		public const string Firehouse = "unlockkey_firehouse";

		public const string LargeGranary = "unlockkey_largegranary";

		public const string LargePotteryWorkshop = "unlockkey_largeworkshop";

		public const string Barracks = "unlockkey_barracks";

		public const string CastleBlock = "unlockkey_castleblock";

		public const string AdvancedBakery = "unlockkey_advancedbakery";

		public const string AdvancedQuarry = "unlockkey_advancedquarry";

		public const string AdvancedFarm = "unlockkey_advancedfarm";

		public const string BathReservoir = "unlockkey_bathreservoir";

		public const string BathColdPool = "unlockkey_bathcoldpool";

		public const string BathHotPool = "unlockkey_bathhotpool";

		public const string ShrewdDealmaking = "unlockkey_shrewddealmaking";

		public const string TradingPost = "unlockkey_tradingpost";

		public const string TradeAgreements = "unlockkey_tradeagreements";

		public const string FineWine = "unlockkey_finewine";

		public const string FireEngines = "unlockkey_fireengines";

		public const string ThermalFracturing = "unlockkey_thermalfracturing";

		public const string Clinic = "unlockkey_clinic";

		public static IEnumerable DropdownValues = new ValueDropdownList<string>
		{
			{ "Forum", "unlockkey_forum" },
			{ "Winery", "unlockkey_winery" },
			{ "Weaponsmith", "unlockkey_weaponsmith" },
			{ "Toolsmith", "unlockkey_toolsmith" },
			{ "AdvancedBakery", "unlockkey_advancedbakery" },
			{ "AdvancedQuarry", "unlockkey_advancedquarry" },
			{ "AdvancedFarm", "unlockkey_advancedfarm" }
		};
	}

	public class TechnologyTreeAnimation
	{
		public bool isComplete;

		protected float currTime;

		public bool isExclusive;

		public bool doAcceleration;

		public virtual void Init()
		{
		}

		public virtual void Animate(float udt)
		{
		}
	}

	public class HighlightNode : TechnologyTreeAnimation
	{
		public TechnologyTreeNode node;

		public Color highlightColor;

		public Color radialColor;

		private bool doRadialBackground;

		private bool isForUnlocked;

		public HighlightNode(TechnologyTreeNode node, Color c, bool isForUnlocked = false, bool doRadialBackground = false)
		{
			isExclusive = false;
			doAcceleration = false;
			this.node = node;
			this.isForUnlocked = isForUnlocked;
			highlightColor = c;
			radialColor = c;
			this.doRadialBackground = doRadialBackground;
		}

		public override void Animate(float udt)
		{
			if (currTime <= 0f)
			{
				Util.SetEnabled(node.animRadialBackgroundImg, doRadialBackground);
				Util.SetEnabled(node.animBackgroundImg, active: true);
				if (!isForUnlocked)
				{
					SfxSystem.inst.PlayFromBank3DUIOneShot("event:/SFX ASITP/UI/ui_upgrage_reveal_avatar", node.rectT.position);
				}
			}
			if (!isComplete)
			{
				currTime = Mathff.Min(currTime + udt * inst.highlightAnimSpeed, 1f);
				float num = inst.highlightAnimCurve.Evaluate(currTime);
				highlightColor.a = num;
				node.animBackgroundImg.color = highlightColor;
				if (doRadialBackground)
				{
					radialColor.a = num * 0.1f;
					node.animRadialBackgroundImg.color = radialColor;
				}
				float z = currTime * (360f * (float)inst.highlightAnimRotationCount);
				node.animBackgroundRect.rotation = Quaternion.Euler(0f, 0f, z);
				if (currTime >= 1f)
				{
					isComplete = true;
					Util.SetEnabled(node.animBackgroundImg, active: false);
					Util.SetEnabled(node.animRadialBackgroundImg, active: false);
				}
			}
		}
	}

	public class NodeEase : TechnologyTreeAnimation
	{
		private TechnologyTreeNode node;

		private Color outlineColor;

		public NodeEase(TechnologyTreeNode node, bool isNewUnlock = false)
		{
			this.node = node;
			outlineColor = (isNewUnlock ? UnlockOutlineAnim : DefaultOutlineAnim);
		}

		public override void Animate(float udt)
		{
			if (!isComplete)
			{
				currTime = Mathff.Min(currTime + udt * scaleSpeed, 1f);
				float a = Mathf.PingPong(currTime, 0.5f);
				outlineColor.a = a;
				node.animBackgroundImg.color = outlineColor;
				float z = currTime * 360f;
				node.animBackgroundRect.rotation = Quaternion.Euler(0f, 0f, z);
				if (currTime >= 1f)
				{
					isComplete = true;
					SfxSystem.inst.PlayFromBank3DUIOneShot("event:/SFX ASITP/UI/ui_upgrage_reveal_avatar", node.rectT.position);
				}
			}
		}
	}

	public class FillLine : TechnologyTreeAnimation
	{
		private TechnologyTreeLine line;

		private List<float> cacheDist = new List<float>(8);

		private List<Vector3> cachePos = new List<Vector3>(8);

		private int idx;

		private float currDist;

		private float distOverflow;

		public FillLine(TechnologyTreeLine line)
		{
			isExclusive = true;
			doAcceleration = true;
			this.line = line;
			for (int i = 0; i < line.backgroundPoints.Length; i++)
			{
				cachePos.Add(line.backgroundPoints[i]);
				if (i != 0)
				{
					cacheDist.Add((line.backgroundPoints[i] - line.backgroundPoints[i - 1]).magnitude);
				}
			}
			line.foregroundLineRenderer.positionCount = 2;
			line.foregroundLineRenderer.SetPosition(0, cachePos[0]);
			line.foregroundLineRenderer.SetPosition(1, cachePos[0]);
			Util.SetActive(line.foregroundLineRenderer.gameObject, active: true);
			currTime = 0f;
			idx = 0;
		}

		public override void Animate(float udt)
		{
			if (isComplete)
			{
				return;
			}
			float num = udt * moveTowardsSpeed;
			num += distOverflow;
			bool flag = Mathff.MoveTowards(currDist, cacheDist[idx], num, out var actualAmt, out var newPos);
			distOverflow = Mathff.Max(0f, num - actualAmt);
			currDist = newPos;
			float val = Mathff.Clamp01(currDist / cacheDist[idx]);
			Vector3 input = cachePos[idx + 1] - cachePos[idx];
			input.NonAllocateMultiply(val);
			input.NonAllocateAdd(cachePos[idx]);
			line.foregroundLineRenderer.SetPosition(idx + 1, input);
			if (flag)
			{
				idx++;
				currDist = 0f;
				if (idx >= cacheDist.Count)
				{
					currTime = 0f;
					isComplete = true;
					line.isAnimatingForeground = false;
				}
				else
				{
					line.foregroundLineRenderer.positionCount = idx + 2;
					line.foregroundLineRenderer.SetPosition(idx + 1, cachePos[idx]);
				}
			}
		}
	}

	public class NewLineFillEndNodeEase : TechnologyTreeAnimation
	{
		private TechnologyTreeNode startNode;

		private TechnologyTreeNode endNode;

		private TechnologyTreeLine line;

		private bool isNewlyUnlockable;

		private bool doReverse;

		private List<float> cacheDist = new List<float>(8);

		private List<Vector3> cachePos = new List<Vector3>(8);

		private AnimationStage stage = AnimationStage.LineFill;

		private int idx;

		private float currDist;

		private float distOverflow;

		public NewLineFillEndNodeEase(TechnologyTreeNode startNode, TechnologyTreeNode endNode, TechnologyTreeLine line, bool isNewlyUnlockable)
		{
			isExclusive = true;
			doAcceleration = true;
			this.startNode = startNode;
			this.endNode = endNode;
			doReverse = startNode.rectT != line.startConnection;
			this.isNewlyUnlockable = isNewlyUnlockable;
			this.line = line;
			line.isAnimatingForeground = true;
			if (!doReverse)
			{
				for (int i = 0; i < line.backgroundPoints.Length; i++)
				{
					cachePos.Add(line.backgroundPoints[i]);
					if (i != 0)
					{
						cacheDist.Add((line.backgroundPoints[i] - line.backgroundPoints[i - 1]).magnitude);
					}
				}
			}
			else
			{
				for (int num = line.backgroundPoints.Length - 1; num >= 0; num--)
				{
					cachePos.Add(line.backgroundPoints[num]);
					if (num != line.backgroundPoints.Length - 1)
					{
						cacheDist.Add((line.backgroundPoints[num] - line.backgroundPoints[num + 1]).magnitude);
					}
				}
			}
			line.foregroundLineRenderer.positionCount = 2;
			line.foregroundLineRenderer.SetPosition(0, cachePos[0]);
			line.foregroundLineRenderer.SetPosition(1, cachePos[0]);
			Util.SetActive(line.foregroundLineRenderer.gameObject, active: true);
			currTime = 0f;
			idx = 0;
		}

		public override void Animate(float udt)
		{
			if (isComplete)
			{
				return;
			}
			switch (stage)
			{
			case AnimationStage.LineFill:
			{
				float num = udt * moveTowardsSpeed;
				num += distOverflow;
				bool flag = Mathff.MoveTowards(currDist, cacheDist[idx], num, out var actualAmt, out var newPos);
				distOverflow = Mathff.Max(0f, num - actualAmt);
				currDist = newPos;
				float val = Mathff.Clamp01(currDist / cacheDist[idx]);
				Vector3 input = cachePos[idx + 1] - cachePos[idx];
				input.NonAllocateMultiply(val);
				input.NonAllocateAdd(cachePos[idx]);
				line.foregroundLineRenderer.SetPosition(idx + 1, input);
				if (flag)
				{
					idx++;
					currDist = 0f;
					if (idx >= cacheDist.Count)
					{
						isComplete = true;
						currTime = 0f;
						stage = AnimationStage.EaseInOut;
						line.isAnimatingForeground = false;
					}
					else
					{
						line.foregroundLineRenderer.positionCount = idx + 2;
						line.foregroundLineRenderer.SetPosition(idx + 1, cachePos[idx]);
					}
				}
				break;
			}
			case AnimationStage.EaseInOut:
			{
				currTime = Mathff.Min(currTime + udt * scaleSpeed, 1f);
				float a = Mathf.PingPong(currTime, 0.5f);
				Color defaultOutlineAnim = DefaultOutlineAnim;
				defaultOutlineAnim.a = a;
				endNode.animBackgroundImg.color = defaultOutlineAnim;
				float z = currTime * 360f;
				endNode.animBackgroundRect.rotation = Quaternion.Euler(0f, 0f, z);
				if (currTime >= 1f)
				{
					isComplete = true;
					SfxSystem.inst.PlayFromBank3DUIOneShot("event:/SFX ASITP/UI/ui_upgrage_reveal_avatar", endNode.rectT.position);
				}
				break;
			}
			}
		}
	}

	public static TechnologyTree inst;

	[SerializeField]
	public List<TechnologyTreeNode> nodes = new List<TechnologyTreeNode>();

	[SerializeField]
	public List<TechnologyTreeLink> links = new List<TechnologyTreeLink>();

	[SerializeField]
	public List<TechnologyTreeRequireLink> requireLinks = new List<TechnologyTreeRequireLink>();

	private List<string> unlockedKeys;

	[SerializeField]
	public TechnologyTreeNode nodePrefab;

	public TechnologyTreeLine linePrefab;

	public TechnologyTreeConnector connectorPrefab;

	public Texture2D defaultSelectedTexture;

	public Texture2D unlockedSelectedTexture;

	[SerializeField]
	public RectTransform maskContainer;

	[SerializeField]
	public RectTransform container;

	[SerializeField]
	private RectTransform nodeContainer;

	public RectTransform lineContainer;

	public RectTransform connectorContainer;

	[SerializeField]
	private TextMeshProUGUI prosperityText;

	[SerializeField]
	private GameObject prosperityHint;

	[SerializeField]
	private GameObject festivalHint;

	[SerializeField]
	private Canvas[] canvases;

	[SerializeField]
	private GraphicRaycaster[] graphicRaycasters;

	[SerializeField]
	private RectUnionSDFController lockedAreaOverlay;

	private bool overlayReferenceCaptured;

	private bool needsOverlaySync;

	private Vector2 overlayReferenceCorner;

	[SerializeField]
	private RectTransform tooltip;

	[SerializeField]
	private TextMeshProUGUI tooltipTitle;

	[SerializeField]
	private TextMeshProUGUI tooltipDescription;

	[SerializeField]
	private GameObject tooltipLocked;

	[SerializeField]
	private GameObject tooltipUnLockable;

	[SerializeField]
	private TextMeshProUGUI tooltipUnlockableTMP;

	[SerializeField]
	private GameObject tooltipUnlocked;

	[SerializeField]
	private GameObject tooltipModelContainer;

	[SerializeField]
	private float tooltipDist = 1f;

	[SerializeField]
	private float tooltipModelRotationSpeed = 1f;

	[SerializeField]
	private Light tooltipLight;

	[SerializeField]
	private GameObject tooltipDetailsContainer;

	[SerializeField]
	private TextMeshProUGUI tooltipResidentsTMP;

	[SerializeField]
	private TextMeshProUGUI tooltipWorkerTMP;

	[SerializeField]
	private TextMeshProUGUI tooltipProductionTMP;

	[SerializeField]
	private TextMeshProUGUI tooltipRequireTMP;

	[SerializeField]
	private TextMeshProUGUI tooltipStoresTMP;

	[SerializeField]
	private TextMeshProUGUI tooltipWagesTMP;

	public float minZoom = 0.85f;

	public float maxZoom = 1.5f;

	public Color baseLineColor = Color.white;

	public Color unlockedLineColor = Color.yellow;

	public Color preqSucessColor;

	public Color preqFailColor;

	public static readonly Color dark = new Color(0.4f, 0.4f, 0.4f, 1f);

	public static readonly Color bright = new Color(1f, 1f, 1f, 1f);

	public static readonly Color error = new Color(1f, 0.45f, 0.45f, 1f);

	public static readonly Color UnlockOutlineAnim = new Color(0.992f, 0.831f, 0.443f, 0f);

	public static readonly Color DefaultOutlineAnim = new Color(0.169f, 0.553f, 0.792f, 0f);

	private bool isVisible;

	private TechnologyTreeNode rootNode;

	public bool isDirty;

	private List<RaycastResult> results = new List<RaycastResult>();

	public TechnologyTreeNode tooltipNode;

	private bool isHoveringTooltip;

	private PointerEventData pEventData;

	private bool isGrabbing;

	private Vector2 initAnchorPos;

	private Vector2 initOffsetPos;

	private Vector2 initLocalPos;

	private Vector2 minMaskBound;

	private Vector2 maxMaskBound;

	private Vector3 minBound;

	private Vector3 maxBound;

	private Vector2 containerMinBound;

	private Vector2 containerMaxBound;

	public float padding = 600f;

	private static float scaleMod = 1.5f;

	private static float scaleSpeed = 2f;

	private static float fillSpeed = 1.5f;

	public float animAcceleration = 1f;

	public float animAccelerationStep = 0.1f;

	public float animAccelerationMax = 25f;

	private static float moveTowardsSpeed = 150f;

	[Min(0f)]
	private static float scaleUnderShoot = 2f;

	[Min(0f)]
	private static float scaleOverShoot = 0f;

	private int cachedPlaySpeed;

	public bool isFirstTimeOpening = true;

	private float currDragDist;

	private const float MIN_DRAGGING_DIST = 2.5f;

	public float moveSpeed = 1f;

	private Vector3 moveDir = new Vector3(0f, 0f, 0f);

	public List<TechnologyTreeAnimation> activeAnimations = new List<TechnologyTreeAnimation>(32);

	public List<TechnologyTreeAnimation> toRemove = new List<TechnologyTreeAnimation>(8);

	private ArrayExt<string> unHideBuildingNodes = new ArrayExt<string>(8);

	private ArrayExt<TechnologyTreeNode> unhideNodes = new ArrayExt<TechnologyTreeNode>(8);

	public List<NonDrawingGraphic> clickBlockers = new List<NonDrawingGraphic>();

	private Vector3[] scratch4 = new Vector3[4];

	private readonly Vector3[] worldCorners = new Vector3[4];

	private float tooltipScreenPoint = 0.75f;

	private float scaleVel;

	private float desiredScale = 1f;

	private Vector3 targetPos;

	private Vector3[] scratchCorners = new Vector3[4];

	internal bool isFineWineUnlocked;

	public AnimationCurve highlightAnimCurve;

	public float highlightAnimSpeed = 0.1f;

	public int highlightAnimRotationCount = 5;

	public static bool IsLockedForVersion(TechnologyTreeNode node)
	{
		if (node != null)
		{
			return node.isLockedFor == TechnologyTreeNode.LockForVersion.FutureUpdate;
		}
		return false;
	}

	public void UpdateNodeLinksToRoot()
	{
		for (int i = 0; i < nodes.Count; i++)
		{
			TechnologyTreeNode technologyTreeNode = nodes[i];
			if (!technologyTreeNode.isRoot)
			{
				technologyTreeNode.FindLinksToRoot();
			}
		}
	}

	private void Awake()
	{
		inst = this;
		unlockedKeys = new List<string>(nodes.Count);
		minBound = default(Vector2);
		maxBound = default(Vector2);
		if (lockedAreaOverlay != null)
		{
			lockedAreaOverlay.ForceRootRectUpdate();
		}
		for (int i = 0; i < nodes.Count; i++)
		{
			RectTransform rectT = nodes[i].rectT;
			rectT.GetLocalCorners(scratch4);
			Vector3 localPosition = rectT.localPosition;
			for (int j = 0; j < 4; j++)
			{
				Vector3 vector = scratch4[j];
				vector.x += localPosition.x;
				vector.y += localPosition.y;
				if (vector.x < minBound.x)
				{
					minBound.x = vector.x;
				}
				if (vector.y < minBound.y)
				{
					minBound.y = vector.y;
				}
				if (vector.x > maxBound.x)
				{
					maxBound.x = vector.x;
				}
				if (vector.y > maxBound.y)
				{
					maxBound.y = vector.y;
				}
			}
		}
		maxBound.x += padding;
		maxBound.y += padding;
		minBound.x -= padding;
		minBound.y -= padding;
		maskContainer.GetLocalCorners(scratch4);
		minMaskBound = scratch4[0];
		maxMaskBound = scratch4[2];
	}

	private void Start()
	{
		Player player = Player.inst;
		player.onProsperityChanged = (Player.OnProsperityChanged)Delegate.Combine(player.onProsperityChanged, new Player.OnProsperityChanged(OnProsperityChanged));
	}

	private void OnDestroy()
	{
		Player player = Player.inst;
		player.onProsperityChanged = (Player.OnProsperityChanged)Delegate.Remove(player.onProsperityChanged, new Player.OnProsperityChanged(OnProsperityChanged));
	}

	private void CalculateBounds()
	{
		Rect rect = maskContainer.rect;
		minMaskBound.x = rect.x;
		minMaskBound.y = rect.y;
		maxMaskBound.x = rect.xMax;
		maxMaskBound.y = rect.yMax;
		float x = container.localScale.x;
		Vector2 vector = minBound * x;
		Vector2 vector2 = maxBound * x;
		Vector2 vector3 = minMaskBound - vector;
		Vector2 vector4 = maxMaskBound - vector2;
		containerMinBound.x = Mathff.Min(-50f, vector4.x);
		containerMinBound.y = Mathff.Min(-50f, vector4.y);
		containerMaxBound.x = Mathff.Max(50f, vector3.x);
		containerMaxBound.y = Mathff.Max(50f, vector3.y);
	}

	private void RefreshProsperityDisplay(int amt)
	{
		prosperityText.text = $"{amt}";
		if (amt <= 0)
		{
			prosperityText.color = Color.orangeRed;
		}
		else
		{
			prosperityText.color = Color.white;
		}
		Util.SetActive(prosperityHint, amt <= 0);
		bool active = false;
		if (IsTechnologyUnlocked("unlockkey_temple2") && amt < 10 && GodManager.inst.tasksComplete > 25)
		{
			for (int i = 0; i < nodes.Count; i++)
			{
				if (!nodes[i].isUnlocked && nodes[i].prosperityPointCost > amt)
				{
					active = true;
					break;
				}
			}
		}
		Util.SetActive(festivalHint, active);
	}

	private void OnProsperityChanged(int amt)
	{
		RefreshProsperityDisplay(amt);
		if (tooltipNode != null && tooltipNode.isUnlockable && !tooltipNode.isUnlocked)
		{
			bool flag = amt >= tooltipNode.prosperityPointCost;
			bool flag2 = IsLockedForVersion(tooltipNode);
			string rText = string.Empty;
			bool flag3 = !DoesNodeHaveRequirements(tooltipNode) || IsNodeRequirementsUnlocked(tooltipNode, ref rText);
			Util.SetActive(tooltipNode.requirementsNotMetObj, flag && !flag3 && !flag2);
			Util.SetActive(tooltipNode.insufficientPointsObj, (!flag & flag3) && !flag2);
			Util.SetActive(tooltipNode.unlockBtn.gameObject, (flag3 & flag) && !flag2);
			Util.SetActive(tooltipNode.demoObj, flag2);
			Util.SetActive(tooltipUnLockable, (!flag || !flag3) && !flag2);
			tooltipLight.intensity = ((tooltipNode.isUnlocked || (flag && tooltipNode.isUnlockable)) ? 1.1f : 0.5f);
		}
		RefreshCostVisuals();
	}

	private void RefreshCostVisuals()
	{
		int prosperityPoints = Player.inst.ProsperityPoints;
		for (int i = 0; i < nodes.Count; i++)
		{
			TechnologyTreeNode technologyTreeNode = nodes[i];
			bool flag = prosperityPoints >= technologyTreeNode.prosperityPointCost;
			technologyTreeNode.iconRawImage.color = ((technologyTreeNode.isUnlocked || (flag && technologyTreeNode.isUnlockable)) ? bright : dark);
			technologyTreeNode.costTMP.color = ((technologyTreeNode.isUnlocked || (flag && technologyTreeNode.isUnlockable)) ? bright : error);
			technologyTreeNode.costIcon.color = ((technologyTreeNode.isUnlocked || (flag && technologyTreeNode.isUnlockable)) ? bright : error);
		}
	}

	public void SetVisibility(bool v)
	{
		targetPos = container.anchoredPosition;
		if (v)
		{
			GameUI.inst.ClearUIForCinematics();
			ProsperityUI.inst.SetMissionVisibility(v: false);
			ProsperityUI.inst.SetProsperityNotifyVisibility(v: false);
			GameUI.inst.CurrPlacementMode.AbortPlacement(refund: true);
			GameUI.inst.ReturnToDefaultCursorMode();
			CreativeUI.inst.SetWindowVisibility(v: false);
			NotificationUI.inst.LogUI.SetVisibility(visible: false);
			NotificationUI.inst.HideNotificationGroups();
			if (unHideBuildingNodes.Count > 0)
			{
				for (int i = 0; i < nodes.Count; i++)
				{
					TechnologyTreeNode technologyTreeNode = nodes[i];
					if (!technologyTreeNode.isHidden || string.IsNullOrEmpty(technologyTreeNode.buildingUniqueName))
					{
						continue;
					}
					for (int j = 0; j < unHideBuildingNodes.Count; j++)
					{
						if (!(unHideBuildingNodes.data[j] != technologyTreeNode.buildingUniqueName))
						{
							technologyTreeNode.isHidden = false;
							isDirty = true;
							unHideBuildingNodes.RemoveAt(j);
							break;
						}
					}
					if (unHideBuildingNodes.Count == 0)
					{
						break;
					}
				}
				unHideBuildingNodes.ClearFast();
			}
			RefreshProsperityDisplay(Player.inst.ProsperityPoints);
			UpdateLinkVisuals();
			RefreshCostVisuals();
			if (isFirstTimeOpening)
			{
				TechnologyTreeNode technologyTreeNode2 = GetRootNode();
				activeAnimations.Add(new HighlightNode(technologyTreeNode2, UnlockOutlineAnim, isForUnlocked: true, doRadialBackground: true));
				for (int k = 0; k < technologyTreeNode2.links.Count; k++)
				{
					TechnologyTreeNode technologyTreeNode3 = ((technologyTreeNode2.links[k].node1 != technologyTreeNode2) ? technologyTreeNode2.links[k].node1 : technologyTreeNode2.links[k].node2);
					activeAnimations.Add(new NewLineFillEndNodeEase(technologyTreeNode2, technologyTreeNode3, technologyTreeNode2.links[k].line, isNewlyUnlockable: true));
					activeAnimations.Add(new HighlightNode(technologyTreeNode3, DefaultOutlineAnim));
				}
				isFirstTimeOpening = false;
			}
			SfxSystem.PlayUiOpen();
		}
		else
		{
			SetTooltipVisibility(null, isVisible: false);
		}
		if (!v && isVisible)
		{
			TimeManager.inst.SetSpeed(cachedPlaySpeed, skipSfx: true);
		}
		else if (v && !isVisible)
		{
			cachedPlaySpeed = TimeManager.inst.speedInUse;
			TimeManager.inst.SetSpeed(0, skipSfx: true);
		}
		Util.SetActive(lineContainer.gameObject, v);
		SetBlockingGraphicsEnabled(v);
		MiniMapUI.inst.SetVisibility(!v);
		GameState.inst.AlphaNumericHotkeysEnabled = !v;
		Cam.inst.disableDrag = v;
		Cam.inst.disableZoom = v;
		Cam.inst.disableRotate = v;
		for (int l = 0; l < canvases.Length; l++)
		{
			Util.SetEnabled(canvases[l], v);
		}
		for (int m = 0; m < graphicRaycasters.Length; m++)
		{
			Util.SetEnabled(graphicRaycasters[m], v);
		}
		isVisible = v;
		if (!v)
		{
			overlayReferenceCaptured = false;
			needsOverlaySync = false;
		}
		else
		{
			overlayReferenceCaptured = false;
			needsOverlaySync = true;
		}
		if (v)
		{
			CalculateBounds();
			Canvas.ForceUpdateCanvases();
			if (SyncLockedAreaOverlay(container.localScale.x))
			{
				needsOverlaySync = false;
			}
			float x = canvases[0].GetComponent<RectTransform>().rect.size.x;
			tooltipScreenPoint = 1f - (tooltip.rect.size.x + 10f) / x;
		}
	}

	public void SetBlockingGraphicsEnabled(bool enabled)
	{
		for (int i = 0; i < clickBlockers.Count; i++)
		{
			NonDrawingGraphic nonDrawingGraphic = clickBlockers[i];
			if (nonDrawingGraphic != null)
			{
				nonDrawingGraphic.raycastTarget = enabled;
			}
		}
	}

	public void ToggleVisibility()
	{
		SetVisibility(!isVisible);
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	public TechnologyTreeNode GetRootNode()
	{
		if (rootNode == null)
		{
			for (int i = 0; i < nodes.Count; i++)
			{
				if (nodes[i].isRoot)
				{
					rootNode = nodes[i];
					break;
				}
			}
		}
		if (rootNode == null)
		{
			Debug.Log("Root Nodes Does Not Exist");
		}
		else if (!rootNode.isRoot)
		{
			Debug.Log("Root Node is Marked Node.isRoot = FALSE");
		}
		return rootNode;
	}

	private bool SyncLockedAreaOverlay(float currentZoom)
	{
		if (lockedAreaOverlay == null || container == null)
		{
			return false;
		}
		RectTransform rootRect = lockedAreaOverlay.RootRect;
		if (rootRect == null)
		{
			return false;
		}
		Vector2 size = rootRect.rect.size;
		if (size.x <= 0.0001f || size.y <= 0.0001f)
		{
			return false;
		}
		container.GetWorldCorners(worldCorners);
		Vector3 position = worldCorners[0];
		Vector3 vector = rootRect.InverseTransformPoint(position);
		Rect rect = rootRect.rect;
		Vector2 vector2 = new Vector2(Mathf.Approximately(rect.width, 0f) ? 0f : ((vector.x - rect.xMin) / rect.width), Mathf.Approximately(rect.height, 0f) ? 0f : ((vector.y - rect.yMin) / rect.height));
		if (!overlayReferenceCaptured)
		{
			overlayReferenceCorner = vector2;
			overlayReferenceCaptured = true;
		}
		float num = Mathf.Max(currentZoom, 0.0001f);
		Vector2 scale = new Vector2(1f / num, 1f / num);
		Vector2 offset = overlayReferenceCorner - vector2;
		lockedAreaOverlay.SetExternalTextureTransform(scale, offset);
		return true;
	}

	private void Update()
	{
		if (isDirty)
		{
			UpdateNodes();
			isDirty = false;
		}
		if (!isVisible)
		{
			return;
		}
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		if (unhideNodes.Count > 0)
		{
			for (int i = 0; i < unhideNodes.Count; i++)
			{
				unhideNodes.data[i].isHidden = false;
			}
			unhideNodes.ClearFast();
			isDirty = true;
		}
		if (ConfigurableControls.inst.GetInputActionKeyDown(900) || ConfigurableControls.inst.GetInputActionKeyDownAndConsume(903))
		{
			SetVisibility(v: false);
			return;
		}
		IPointer pointer = PointingSystem.GetPointer();
		ref float x = ref moveDir.x;
		ref float y = ref moveDir.y;
		ref float z = ref moveDir.z;
		x = 0f;
		y = 0f;
		z = 0f;
		if (ConfigurableControls.inst.GetInputActionKey(100, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true))
		{
			moveDir.y--;
		}
		if (ConfigurableControls.inst.GetInputActionKey(101, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true))
		{
			moveDir.y++;
		}
		if (ConfigurableControls.inst.GetInputActionKey(102, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true))
		{
			moveDir.x++;
		}
		if (ConfigurableControls.inst.GetInputActionKey(103, ignoreCtrl: true, ignoreAlt: true, ignoreShift: true))
		{
			moveDir.x--;
		}
		moveDir.NonAllocateNormalize();
		bool flag = moveDir.magnitude > 0.0001f;
		if (flag)
		{
			bool flag2 = Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift);
			Vector3 vector = container.anchoredPosition;
			targetPos = vector + moveDir * ((flag2 ? (moveSpeed * 2f) : moveSpeed) * container.localScale.x);
			isGrabbing = false;
		}
		if (pointer.GetSecondaryUp())
		{
			isGrabbing = false;
			if (currDragDist < 2.5f)
			{
				SetTooltipVisibility(null, isVisible: false);
			}
		}
		else if (!flag && (pointer.GetSecondaryDown() || isGrabbing))
		{
			Vector2 screenPoint = Input.mousePosition;
			RectTransformUtility.ScreenPointToLocalPointInRectangle(maskContainer, screenPoint, GUICamera.inst.cam, out var localPoint);
			if (!isGrabbing)
			{
				initAnchorPos = container.anchoredPosition;
				initOffsetPos = localPoint - initAnchorPos;
				initLocalPos = localPoint;
				currDragDist = 0f;
			}
			Vector2 vector2 = localPoint - initOffsetPos;
			targetPos.x = Mathff.Clamp(vector2.x, containerMinBound.x, containerMaxBound.x);
			targetPos.y = Mathff.Clamp(vector2.y, containerMinBound.y, containerMaxBound.y);
			currDragDist = (localPoint - initLocalPos).magnitude;
			isGrabbing = true;
		}
		if (!isGrabbing)
		{
			float axis = Input.GetAxis("Mouse ScrollWheel");
			if (Mathff.Abs(axis) > 0.01f)
			{
				desiredScale = Mathff.Clamp(container.localScale.x + (Assets.Settings.inst.InvertZoom ? 2f : (-2f)) * axis, minZoom, maxZoom);
			}
		}
		Vector2 vector3 = container.localScale;
		if (Mathff.Abs(desiredScale - vector3.x) > 0.001f)
		{
			float num = Mathf.SmoothDamp(vector3.x, desiredScale, ref scaleVel, 0.1f, float.MaxValue, Time.unscaledDeltaTime);
			float num2 = num / vector3.x;
			RectTransformUtility.ScreenPointToLocalPointInRectangle(maskContainer, Input.mousePosition, GUICamera.inst.cam, out var localPoint2);
			Vector2 vector4 = container.anchoredPosition - localPoint2;
			Vector3 vector5 = localPoint2 + vector4 * num2;
			vector3.x = (vector3.y = num);
			container.localScale = vector3;
			CalculateBounds();
			vector5.x = Mathff.Clamp(vector5.x, containerMinBound.x, containerMaxBound.x);
			vector5.y = Mathff.Clamp(vector5.y, containerMinBound.y, containerMaxBound.y);
			container.anchoredPosition = vector5;
			targetPos = vector5;
		}
		Vector2 anchoredPosition = container.anchoredPosition;
		anchoredPosition = Vector3.Lerp(anchoredPosition, targetPos, Time.unscaledDeltaTime * 15f);
		anchoredPosition.x = Mathff.Clamp(anchoredPosition.x, containerMinBound.x, containerMaxBound.x);
		anchoredPosition.y = Mathff.Clamp(anchoredPosition.y, containerMinBound.y, containerMaxBound.y);
		container.anchoredPosition = anchoredPosition;
		if (needsOverlaySync)
		{
			Canvas.ForceUpdateCanvases();
			needsOverlaySync = !SyncLockedAreaOverlay(vector3.x);
		}
		else
		{
			SyncLockedAreaOverlay(vector3.x);
		}
		if (tooltipNode != null)
		{
			tooltipNode.rectT.GetWorldCorners(scratchCorners);
			Vector2 vector6 = GUICamera.inst.cam.WorldToViewportPoint(scratchCorners[3]);
			float x2 = tooltip.pivot.x;
			if (vector6.x >= tooltipScreenPoint && x2 != 0f)
			{
				RectTransform rectTransform = tooltip;
				RectTransform rectTransform2 = tooltip;
				Vector2 vector7 = (tooltip.pivot = Vector2.zero);
				Vector2 anchorMin = (rectTransform2.anchorMax = vector7);
				rectTransform.anchorMin = anchorMin;
				tooltip.anchoredPosition3D = Vector3.zero;
			}
			else if (vector6.x < tooltipScreenPoint && x2 == 0f)
			{
				RectTransform rectTransform3 = tooltip;
				RectTransform rectTransform4 = tooltip;
				Vector2 vector7 = (tooltip.pivot = Vector2.right);
				Vector2 anchorMin = (rectTransform4.anchorMax = vector7);
				rectTransform3.anchorMin = anchorMin;
				tooltip.anchoredPosition3D = Vector3.zero;
			}
			if (tooltipNode.displayModelInstance != null)
			{
				tooltipNode.displayModelInstance.Rotate(Vector3.up, tooltipModelRotationSpeed * unscaledDeltaTime, Space.Self);
			}
		}
		if (activeAnimations.Count == 0)
		{
			return;
		}
		animAcceleration = Mathf.Clamp(animAcceleration + animAccelerationStep, 1f, animAccelerationMax);
		for (int j = 0; j < activeAnimations.Count; j++)
		{
			TechnologyTreeAnimation technologyTreeAnimation = activeAnimations[j];
			technologyTreeAnimation.Animate(technologyTreeAnimation.doAcceleration ? (unscaledDeltaTime * animAcceleration) : unscaledDeltaTime);
			if (technologyTreeAnimation.isComplete)
			{
				toRemove.Add(technologyTreeAnimation);
			}
			else if (technologyTreeAnimation.isExclusive)
			{
				break;
			}
		}
		bool flag3 = true;
		for (int num3 = activeAnimations.Count - 1; num3 >= 0; num3--)
		{
			if (activeAnimations[num3].isComplete)
			{
				activeAnimations.RemoveAt(num3);
			}
			else if (activeAnimations[num3].doAcceleration)
			{
				flag3 = false;
			}
		}
		if (flag3)
		{
			animAcceleration = 1f;
		}
	}

	private void UpdateLinkVisuals()
	{
		for (int i = 0; i < links.Count; i++)
		{
			links[i].UpdateVisuals();
		}
		for (int j = 0; j < requireLinks.Count; j++)
		{
			requireLinks[j].UpdateVisuals();
		}
	}

	public bool AddLink(TechnologyTreeNode item1, TechnologyTreeNode item2)
	{
		if (item1 == null || item2 == null || item1 == item2)
		{
			return false;
		}
		for (int i = 0; i < links.Count; i++)
		{
			TechnologyTreeLink technologyTreeLink = links[i];
			if ((technologyTreeLink.node1 == item1 && technologyTreeLink.node2 == item2) || (technologyTreeLink.node1 == item2 && technologyTreeLink.node2 == item1))
			{
				return false;
			}
		}
		TechnologyTreeLine technologyTreeLine = UnityEngine.Object.Instantiate(linePrefab, lineContainer, worldPositionStays: false);
		technologyTreeLine.startConnection = item1.rectT;
		technologyTreeLine.endConnection = item2.rectT;
		TechnologyTreeLink item3 = new TechnologyTreeLink
		{
			node1 = item1,
			node2 = item2,
			line = technologyTreeLine
		};
		item1.links.Add(item3);
		item2.links.Add(item3);
		links.Add(item3);
		TryAutoAdjustLines(technologyTreeLine);
		UpdateNodes();
		return true;
	}

	public void TryAutoAdjustLines(TechnologyTreeLine line)
	{
		RectTransform startConnection = line.startConnection;
		RectTransform endConnection = line.endConnection;
		line.ClearControlPoints();
		Vector2 normalized = (startConnection.anchoredPosition - endConnection.anchoredPosition).normalized;
		if (normalized.x != 0f && normalized.y != 0f)
		{
			Vector2 vector = new Vector2(0f, 0f);
			if (Mathff.GetIntersectionInRect(startConnection.rect, startConnection.anchoredPosition, endConnection.anchoredPosition, ref vector.x, ref vector.y) == 1)
			{
				line.AddControlPoint().anchoredPosition = vector;
			}
			Vector2 vector2 = new Vector2(0f, 0f);
			if (Mathff.GetIntersectionInRect(endConnection.rect, endConnection.anchoredPosition, startConnection.anchoredPosition, ref vector2.x, ref vector2.y) == 1)
			{
				line.AddControlPoint().anchoredPosition = vector2;
			}
			int cardinalIndex = GetCardinalIndex(normalized);
			RectTransform rectTransform = line.InsertControlPoint(1);
			RectTransform rectTransform2 = line.InsertControlPoint(2);
			Vector2 vector3 = (vector2 + vector) * 0.5f;
			Vector2 anchoredPosition = vector;
			Vector2 anchoredPosition2 = vector2;
			switch (cardinalIndex)
			{
			case 0:
			case 2:
				anchoredPosition.y = vector3.y;
				rectTransform.anchoredPosition = anchoredPosition;
				anchoredPosition2.y = vector3.y;
				rectTransform2.anchoredPosition = anchoredPosition2;
				break;
			case 1:
			case 3:
				anchoredPosition.x = vector3.x;
				rectTransform.anchoredPosition = anchoredPosition;
				anchoredPosition2.x = vector3.x;
				rectTransform2.anchoredPosition = anchoredPosition2;
				break;
			}
		}
	}

	public void SetRightAnglesForLine(TechnologyTreeLine line)
	{
		RectTransform startConnection = line.startConnection;
		RectTransform endConnection = line.endConnection;
		for (int num = line.controlPoints.Count - 2; num > 0; num--)
		{
			UnityEngine.Object.DestroyImmediate(line.controlPoints[num].gameObject);
			line.controlPoints.RemoveAt(num);
		}
		Vector2 anchoredPosition = line.controlPoints[0].anchoredPosition;
		List<RectTransform> controlPoints = line.controlPoints;
		Vector2 anchoredPosition2 = controlPoints[controlPoints.Count - 1].anchoredPosition;
		Vector2 normalized = (startConnection.anchoredPosition - endConnection.anchoredPosition).normalized;
		if (normalized.x != 0f && normalized.y != 0f)
		{
			int cardinalIndex = GetCardinalIndex(normalized);
			RectTransform rectTransform = line.InsertControlPoint(1);
			RectTransform rectTransform2 = line.InsertControlPoint(2);
			Vector2 vector = (anchoredPosition2 + anchoredPosition) * 0.5f;
			Vector2 anchoredPosition3 = anchoredPosition;
			Vector2 anchoredPosition4 = anchoredPosition2;
			switch (cardinalIndex)
			{
			case 0:
			case 2:
				anchoredPosition3.y = vector.y;
				rectTransform.anchoredPosition = anchoredPosition3;
				anchoredPosition4.y = vector.y;
				rectTransform2.anchoredPosition = anchoredPosition4;
				break;
			case 1:
			case 3:
				anchoredPosition3.x = vector.x;
				rectTransform.anchoredPosition = anchoredPosition3;
				anchoredPosition4.x = vector.x;
				rectTransform2.anchoredPosition = anchoredPosition4;
				break;
			}
		}
	}

	private int GetCardinalIndex(Vector3 dir)
	{
		float num = Mathf.Atan2(dir.y, dir.x) * (180f / MathF.PI);
		if (num < 0f)
		{
			num += 360f;
		}
		if (num >= 45f && num < 135f)
		{
			return 0;
		}
		if (num >= 135f && num < 225f)
		{
			return 3;
		}
		if (num >= 225f && num < 315f)
		{
			return 2;
		}
		return 1;
	}

	private Vector2 GetExitPosition(Rect rect, Vector2 center, Vector2 dir)
	{
		float a = (rect.xMin - center.x) / dir.x;
		float b = (rect.xMax - center.x) / dir.x;
		float a2 = (rect.yMin - center.y) / dir.y;
		float b2 = (rect.yMax - center.y) / dir.y;
		Mathf.Max(Mathf.Min(a, b), Mathf.Min(a2, b2));
		float num = Mathf.Min(Mathf.Max(a, b), Mathf.Max(a2, b2));
		return center + dir * num;
	}

	public void AddRequiredLink(List<TechnologyTreeNode> nodes, TechnologyTreeConnector rConnector = null)
	{
		if (nodes == null || nodes.Count == 0 || (rConnector != null && rConnector.link == null))
		{
			return;
		}
		TechnologyTreeRequireLink technologyTreeRequireLink = null;
		if (rConnector == null)
		{
			technologyTreeRequireLink = new TechnologyTreeRequireLink();
			rConnector = UnityEngine.Object.Instantiate(connectorPrefab, connectorContainer, worldPositionStays: false);
			rConnector.link = technologyTreeRequireLink;
			technologyTreeRequireLink.connector = rConnector;
			requireLinks.Add(technologyTreeRequireLink);
		}
		else
		{
			technologyTreeRequireLink = rConnector.link;
		}
		for (int i = 0; i < nodes.Count; i++)
		{
			if (!technologyTreeRequireLink.nodes.Contains(nodes[i]) && !nodes[i].connectors.Contains(rConnector))
			{
				TechnologyTreeLine technologyTreeLine = UnityEngine.Object.Instantiate(linePrefab, lineContainer, worldPositionStays: false);
				technologyTreeLine.startConnection = nodes[i].rectT;
				technologyTreeLine.endConnection = rConnector.rectT;
				technologyTreeRequireLink.lines.Add(technologyTreeLine);
				technologyTreeRequireLink.nodes.Add(nodes[i]);
				nodes[i].connectors.Add(rConnector);
			}
		}
	}

	public void SetRequiredNodeLink(TechnologyTreeNode node, TechnologyTreeConnector rConnector)
	{
		if (!(rConnector == null) && rConnector.link != null)
		{
			TechnologyTreeRequireLink link = rConnector.link;
			TechnologyTreeLine technologyTreeLine = UnityEngine.Object.Instantiate(linePrefab, lineContainer, worldPositionStays: false);
			technologyTreeLine.startConnection = rConnector.rectT;
			technologyTreeLine.endConnection = node.rectT;
			link.requirerLine = technologyTreeLine;
			link.requirerNode = node;
			node.connectors.Add(rConnector);
		}
	}

	public void RemoveRequiredNodeLink(TechnologyTreeConnector connector)
	{
		if (!(connector == null) && connector.link != null)
		{
			TechnologyTreeRequireLink link = connector.link;
			for (int i = 0; i < link.lines.Count; i++)
			{
				UnityEngine.Object.DestroyImmediate(link.lines[i].gameObject);
			}
			for (int j = 0; j < link.nodes.Count; j++)
			{
				link.nodes[j].connectors.Remove(connector);
			}
			if (link.requirerNode != null)
			{
				link.requirerNode.connectors.Remove(connector);
			}
			if (link.requirerLine != null)
			{
				UnityEngine.Object.DestroyImmediate(link.requirerLine.gameObject);
			}
			if (link.connector != null)
			{
				UnityEngine.Object.DestroyImmediate(link.connector.gameObject);
			}
			requireLinks.Remove(link);
		}
	}

	public bool RemoveLink(TechnologyTreeNode n1, TechnologyTreeNode n2)
	{
		if (n1 == null || n2 == null)
		{
			return false;
		}
		for (int i = 0; i < links.Count; i++)
		{
			TechnologyTreeLink technologyTreeLink = links[i];
			if ((technologyTreeLink.node1 == n1 && technologyTreeLink.node2 == n2) || (technologyTreeLink.node1 == n2 && technologyTreeLink.node2 == n1))
			{
				technologyTreeLink.node1.links.Remove(technologyTreeLink);
				technologyTreeLink.node2.links.Remove(technologyTreeLink);
				links.RemoveAt(i);
				UnityEngine.Object.DestroyImmediate(technologyTreeLink.line.gameObject);
				UpdateNodes();
				return true;
			}
		}
		return false;
	}

	public bool RemoveLink(TechnologyTreeNode n1)
	{
		if (n1 == null)
		{
			return false;
		}
		for (int i = 0; i < links.Count; i++)
		{
			TechnologyTreeLink technologyTreeLink = links[i];
			if (technologyTreeLink.node1 == n1 || technologyTreeLink.node2 == n1)
			{
				technologyTreeLink.node1.links.Remove(technologyTreeLink);
				technologyTreeLink.node2.links.Remove(technologyTreeLink);
				if (technologyTreeLink.line != null)
				{
					UnityEngine.Object.DestroyImmediate(technologyTreeLink.line.gameObject);
				}
				links.RemoveAt(i--);
			}
		}
		return false;
	}

	public void UpdateNodes()
	{
		for (int i = 0; i < nodes.Count; i++)
		{
			nodes[i].CalculateState();
		}
	}

	public void UpdateNodePrefabs()
	{
		for (int i = 0; i < nodes.Count; i++)
		{
			TechnologyTreeNode technologyTreeNode = nodes[i];
			TechnologyTreeNode technologyTreeNode2 = UnityEngine.Object.Instantiate(nodePrefab, nodeContainer);
			for (int j = 0; j < nodes.Count; j++)
			{
				if (j == i || nodes[j].requireUnlocked == null)
				{
					continue;
				}
				for (int k = 0; k < nodes[j].requireUnlocked.Length; k++)
				{
					if (nodes[j].requireUnlocked[k] == technologyTreeNode)
					{
						nodes[j].requireUnlocked[k] = technologyTreeNode2;
					}
				}
			}
			technologyTreeNode2.requireUnlocked = technologyTreeNode.requireUnlocked;
			technologyTreeNode2.transform.SetSiblingIndex(technologyTreeNode.transform.GetSiblingIndex());
			technologyTreeNode2.rectT.anchoredPosition = technologyTreeNode.rectT.anchoredPosition;
			technologyTreeNode2.guid = technologyTreeNode.guid;
			technologyTreeNode2.unlockKey = technologyTreeNode.unlockKey;
			technologyTreeNode2.prosperityPointCost = technologyTreeNode.prosperityPointCost;
			technologyTreeNode2.buildingUniqueName = technologyTreeNode.buildingUniqueName;
			technologyTreeNode2.isUnlockable = technologyTreeNode.isUnlockable;
			technologyTreeNode2.isHidden = technologyTreeNode.isHidden;
			technologyTreeNode2.IsHiddenPersistant = technologyTreeNode.IsHiddenPersistant;
			technologyTreeNode2.isLockedFor = technologyTreeNode.isLockedFor;
			technologyTreeNode2.IsUnlockedPersistant = technologyTreeNode.IsUnlockedPersistant;
			technologyTreeNode2.isRoot = technologyTreeNode.isRoot;
			technologyTreeNode2.displayModelPrefab = technologyTreeNode.displayModelPrefab;
			technologyTreeNode2.scaleModifier = technologyTreeNode.scaleModifier;
			technologyTreeNode2.iconRawImage.texture = technologyTreeNode.iconRawImage.texture;
			for (int l = 0; l < technologyTreeNode.links.Count; l++)
			{
				TechnologyTreeLink technologyTreeLink = technologyTreeNode.links[l];
				if (technologyTreeLink.node1 == technologyTreeNode)
				{
					technologyTreeLink.node1 = technologyTreeNode2;
					for (int m = 0; m < technologyTreeLink.node2.links.Count; m++)
					{
						TechnologyTreeLink technologyTreeLink2 = technologyTreeLink.node2.links[m];
						if (technologyTreeLink2.node1 == technologyTreeNode)
						{
							technologyTreeLink2.node1 = technologyTreeNode2;
						}
						if (technologyTreeLink2.node2 == technologyTreeNode)
						{
							technologyTreeLink2.node2 = technologyTreeNode2;
						}
						technologyTreeLink.node2.links[m] = technologyTreeLink2;
					}
				}
				if (technologyTreeLink.node2 == technologyTreeNode)
				{
					technologyTreeLink.node2 = technologyTreeNode2;
					for (int n = 0; n < technologyTreeLink.node1.links.Count; n++)
					{
						TechnologyTreeLink technologyTreeLink3 = technologyTreeLink.node1.links[n];
						if (technologyTreeLink3.node1 == technologyTreeNode)
						{
							technologyTreeLink3.node1 = technologyTreeNode2;
						}
						if (technologyTreeLink3.node2 == technologyTreeNode)
						{
							technologyTreeLink3.node2 = technologyTreeNode2;
						}
						technologyTreeLink.node1.links[n] = technologyTreeLink3;
					}
				}
				technologyTreeNode2.links.Add(technologyTreeLink);
			}
			for (int num = 0; num < links.Count; num++)
			{
				TechnologyTreeLink technologyTreeLink4 = links[num];
				if (technologyTreeLink4.node1 == technologyTreeNode)
				{
					technologyTreeLink4.node1 = technologyTreeNode2;
					technologyTreeLink4.line.startConnection = technologyTreeNode2.rectT;
				}
				if (technologyTreeLink4.node2 == technologyTreeNode)
				{
					technologyTreeLink4.node2 = technologyTreeNode2;
					technologyTreeLink4.line.endConnection = technologyTreeNode2.rectT;
				}
			}
			for (int num2 = 0; num2 < technologyTreeNode.connectors.Count; num2++)
			{
				TechnologyTreeConnector technologyTreeConnector = technologyTreeNode.connectors[num2];
				if (technologyTreeConnector.link.requirerNode == technologyTreeNode)
				{
					technologyTreeConnector.link.requirerNode = technologyTreeNode2;
					technologyTreeConnector.link.requirerLine.endConnection = technologyTreeNode2.rectT;
				}
				else
				{
					for (int num3 = 0; num3 < technologyTreeConnector.link.nodes.Count; num3++)
					{
						if (technologyTreeNode == technologyTreeConnector.link.nodes[num3])
						{
							technologyTreeConnector.link.nodes[num3] = technologyTreeNode2;
							technologyTreeConnector.link.lines[num3].startConnection = technologyTreeNode2.rectT;
						}
					}
				}
				technologyTreeNode2.connectors.Add(technologyTreeConnector);
			}
			for (int num4 = 0; num4 < technologyTreeNode.isLinkConnectedToRoot.Count; num4++)
			{
				technologyTreeNode2.isLinkConnectedToRoot.Add(technologyTreeNode.isLinkConnectedToRoot[num4]);
			}
			for (int num5 = 0; num5 < technologyTreeNode.isConnectorsConnectedToRoot.Count; num5++)
			{
				technologyTreeNode2.isConnectorsConnectedToRoot.Add(technologyTreeNode.isConnectorsConnectedToRoot[num5]);
			}
			for (int num6 = 0; num6 < requireLinks.Count; num6++)
			{
				TechnologyTreeRequireLink technologyTreeRequireLink = requireLinks[num6];
				if (technologyTreeRequireLink.requirerNode == technologyTreeNode)
				{
					technologyTreeRequireLink.requirerNode = technologyTreeNode2;
				}
				for (int num7 = 0; num7 < technologyTreeRequireLink.nodes.Count; num7++)
				{
					if (technologyTreeRequireLink.nodes[num7] == technologyTreeNode)
					{
						technologyTreeRequireLink.nodes[num7] = technologyTreeNode2;
					}
				}
			}
			UnityEngine.Object.DestroyImmediate(technologyTreeNode.gameObject);
			technologyTreeNode2.UpdateVisuals();
			nodes[i] = technologyTreeNode2;
		}
	}

	public void UpdateLinesToPrefab()
	{
		for (int i = 0; i < links.Count; i++)
		{
			if (links[i].line == null)
			{
				continue;
			}
			TechnologyTreeLine line = links[i].line;
			TechnologyTreeLine technologyTreeLine = UnityEngine.Object.Instantiate(linePrefab, lineContainer, worldPositionStays: false);
			technologyTreeLine.startConnection = line.startConnection;
			technologyTreeLine.endConnection = line.endConnection;
			for (int j = 0; j < line.controlPoints.Count; j++)
			{
				Vector3 vector = line.controlPoints[j].anchoredPosition;
				RectTransform controlPointItem = technologyTreeLine.GetControlPointItem();
				controlPointItem.anchoredPosition = vector;
				technologyTreeLine.controlPoints.Add(controlPointItem);
			}
			links[i].line = technologyTreeLine;
			technologyTreeLine.RefreshVisuals();
			TechnologyTreeNode node = links[i].node1;
			TechnologyTreeNode node2 = links[i].node2;
			for (int k = 0; k < node.links.Count; k++)
			{
				if (node.links[k].line == line)
				{
					node.links[k].line = technologyTreeLine;
				}
			}
			for (int l = 0; l < node2.links.Count; l++)
			{
				if (node2.links[l].line == line)
				{
					node2.links[l].line = technologyTreeLine;
				}
			}
			UnityEngine.Object.DestroyImmediate(line.gameObject);
		}
	}

	public bool IsTechnologyUnlocked(string unlockKey)
	{
		if (unlockedKeys == null)
		{
			return false;
		}
		for (int i = 0; i < unlockedKeys.Count; i++)
		{
			if (unlockedKeys[i] == unlockKey)
			{
				return true;
			}
		}
		return false;
	}

	public void ForceUnlock(string key)
	{
		if (unlockedKeys.Contains(key))
		{
			return;
		}
		AddUnlockKey(key);
		for (int i = 0; i < nodes.Count; i++)
		{
			TechnologyTreeNode technologyTreeNode = nodes[i];
			if (technologyTreeNode.unlockKey == key)
			{
				technologyTreeNode.isUnlocked = true;
			}
		}
		Broadcast.TechnologyTreeUnlockEvent.Broadcast(new OnTechnologyTreeUnlock
		{
			unlockKey = key,
			unlocked = true
		});
		UpdateNodes();
	}

	public void OnSuccessUnlock(TechnologyTreeNode node)
	{
		if (!unlockedKeys.Contains(node.unlockKey))
		{
			AddUnlockKey(node.unlockKey);
			Broadcast.TechnologyTreeUnlockEvent.Broadcast(new OnTechnologyTreeUnlock
			{
				unlockKey = node.unlockKey,
				unlocked = true
			});
			Player.inst.TakeProsperityPoints(node.prosperityPointCost);
			RuntimeManager.PlayOneShot("event:/SFX ASITP/UI/ui_upgrade_unlock");
			MilestoneManager.inst.TryFirstTechnologyUnlocked();
		}
		else
		{
			Debug.LogError("Node Already Unlocked!");
		}
		tooltipUnlocked.SetActive(node.isUnlocked);
		tooltipUnLockable.SetActive(node.isUnlockable && !node.isUnlocked);
		Util.SetActive(node.unlockBtn.gameObject, active: false);
		if (tooltipNode != null)
		{
			tooltipNode.tooltipBackground.texture = unlockedSelectedTexture;
		}
		activeAnimations.Add(new HighlightNode(node, UnlockOutlineAnim, isForUnlocked: true, doRadialBackground: true));
		for (int i = 0; i < links.Count; i++)
		{
			if (links[i].node1 == node || links[i].node2 == node)
			{
				TechnologyTreeNode technologyTreeNode = ((links[i].node1 != node) ? links[i].node1 : links[i].node2);
				if (!technologyTreeNode.isUnlocked)
				{
					activeAnimations.Add(new NewLineFillEndNodeEase(node, technologyTreeNode, links[i].line, !technologyTreeNode.isUnlockable && technologyTreeNode.isHidden));
					activeAnimations.Add(new HighlightNode(technologyTreeNode, DefaultOutlineAnim));
				}
			}
		}
		for (int j = 0; j < requireLinks.Count; j++)
		{
			bool flag = false;
			TechnologyTreeRequireLink technologyTreeRequireLink = requireLinks[j];
			for (int k = 0; k < technologyTreeRequireLink.nodes.Count; k++)
			{
				if (technologyTreeRequireLink.nodes[k] == node)
				{
					FillLine item = new FillLine(technologyTreeRequireLink.lines[k]);
					activeAnimations.Add(item);
					flag = true;
				}
			}
			if (flag && !technologyTreeRequireLink.requirerNode.isUnlocked && technologyTreeRequireLink.IsUnlockable())
			{
				FillLine item2 = new FillLine(technologyTreeRequireLink.requirerLine);
				activeAnimations.Add(item2);
				NodeEase item3 = new NodeEase(technologyTreeRequireLink.requirerNode);
				activeAnimations.Add(item3);
			}
		}
		UpdateNodes();
		UpdateLinkVisuals();
	}

	public void OnFailedUnlock(TechnologyTreeNode node)
	{
		Debug.LogError($"Not Enough Prosperity Points: Cost {node.prosperityPointCost}");
	}

	public void SetTooltipVisibility(TechnologyTreeNode node, bool isVisible)
	{
		if (isGrabbing)
		{
			return;
		}
		isVisible &= node != null;
		if (tooltipNode != null)
		{
			Util.SetActive(tooltipNode.tooltipBackground.gameObject, active: false);
			Util.SetActive(tooltipNode.unlockBtn.gameObject, active: false);
			Util.SetActive(tooltipNode.requirementsNotMetObj, active: false);
			Util.SetActive(tooltipNode.insufficientPointsObj, active: false);
			Util.SetActive(tooltipNode.demoObj, active: false);
			if (tooltipNode != node)
			{
				SetReqOutlineVisuals(tooltipNode, isVisible: false);
			}
		}
		SetReqOutlineVisuals(node, isVisible);
		if (isVisible)
		{
			tooltipNode = node;
			bool flag = IsLockedForVersion(node);
			tooltipUnlocked.SetActive(node.isUnlocked);
			tooltipLocked.SetActive((!node.isUnlockable && !node.isUnlocked) | flag);
			bool flag2 = Player.inst.ProsperityPoints >= node.prosperityPointCost;
			string rText = string.Empty;
			bool flag3 = IsNodeRequirementsUnlocked(node, ref rText);
			tooltipRequireTMP.text = rText;
			Util.SetActive(tooltipRequireTMP.gameObject, rText != string.Empty);
			Util.SetActive(tooltipNode.unlockBtn.gameObject, (flag3 & flag2) && node.isUnlockable && !node.isUnlocked && !flag);
			Util.SetActive(tooltipNode.requirementsNotMetObj, !flag3 && node.isUnlockable && !node.isUnlocked && !flag);
			Util.SetActive(tooltipNode.insufficientPointsObj, (!flag2 & flag3) && node.isUnlockable && !node.isUnlocked && !flag);
			Util.SetActive(tooltipNode.demoObj, flag);
			if (tooltipNode.isLockedFor == TechnologyTreeNode.LockForVersion.Demo)
			{
				tooltipNode.demoLoc.SetTerm("technologytree_line_demo_lock_tooltip");
			}
			else if (tooltipNode.isLockedFor == TechnologyTreeNode.LockForVersion.FutureUpdate)
			{
				tooltipNode.demoLoc.SetTerm("updatelock");
			}
			if (!flag3)
			{
				tooltipUnlockableTMP.text = ScriptLocalization.RequirementsNotMet;
			}
			else if (!flag2)
			{
				tooltipUnlockableTMP.text = ScriptLocalization.Insufficient_Points + $" <size=14><color=red>{node.prosperityPointCost}</color> <sprite name=icon_prosperity>";
			}
			tooltipUnLockable.SetActive((!flag3 || !flag2) && node.isUnlockable && !node.isUnlocked && !flag);
			tooltipTitle.text = LocalizationManager.GetTranslation(node.buildingUniqueName.Equals(string.Empty) ? (node.unlockKey + "_title") : $"Building {node.buildingUniqueName} FriendlyName");
			tooltipDescription.text = LocalizationManager.GetTranslation(node.buildingUniqueName.Equals(string.Empty) ? (node.unlockKey + "_description") : $"Building {node.buildingUniqueName} Description");
			Building building = null;
			if (!node.buildingUniqueName.Equals(string.Empty))
			{
				building = GameState.inst.GetPlaceableByUniqueName(node.buildingUniqueName);
				if (building != null)
				{
					tooltipWorkerTMP.text = "<b>" + LocalizationManager.GetTranslation("WorkersColon") + "</b> " + building.WorkersForFullYield;
					tooltipWorkerTMP.gameObject.SetActive(building.WorkersForFullYield > 0);
					IProductionInfo component = building.GetComponent<IProductionInfo>();
					if (!component.IsNull() && building.UniqueName != World.coppiceName)
					{
						string text = "<b>" + LocalizationManager.GetTranslation("ProducesColon") + "</b> ";
						for (int i = 0; i < FreeResourceSystem.inst.resourceDefs.Count; i++)
						{
							FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefs[i];
							if (component.GetResult(resourceDef.ID) > 0)
							{
								text = text + $" <link={resourceDef.ID}>" + ResourceAmount.ResourceIcon(resourceDef.ID) + "</link> ";
							}
						}
						tooltipProductionTMP.text = text;
						tooltipProductionTMP.gameObject.SetActive(value: true);
					}
					else
					{
						tooltipProductionTMP.gameObject.SetActive(value: false);
					}
					IStorageInfo component2 = building.GetComponent<IStorageInfo>();
					if (!component2.IsNull())
					{
						string text2 = "<b>" + LocalizationManager.GetTranslation("StoresColon") + "</b> ";
						foreach (FreeResourceSystem.ResourceDef resourceDef2 in FreeResourceSystem.inst.resourceDefs)
						{
							if (component2.DoesStoreResource(resourceDef2.ID))
							{
								text2 = text2 + $" <link={resourceDef2.ID}>" + resourceDef2.iconName + "</link> ";
							}
						}
						tooltipStoresTMP.text = text2;
						tooltipStoresTMP.gameObject.SetActive(value: true);
					}
					else
					{
						tooltipStoresTMP.gameObject.SetActive(value: false);
					}
					IResidence component3 = building.GetComponent<IResidence>();
					if (!component3.IsNull())
					{
						tooltipResidentsTMP.text = "<b>" + LocalizationManager.GetTranslation("ResidentsColon") + "</b> " + component3.GetTotalResidentialSlots();
						tooltipResidentsTMP.gameObject.SetActive(value: true);
					}
					else
					{
						tooltipResidentsTMP.gameObject.SetActive(value: false);
					}
					WagePayer component4 = building.GetComponent<WagePayer>();
					if (component4 != null)
					{
						float num = (float)component4.GetGoldWage(Player.inst.PlayerLandmassOwner) * component4.PaydaysPerYear();
						tooltipWagesTMP.text = "<b>" + ScriptLocalization.technologytreeui_tooltip_wagecolon + "</b>" + $"{(int)num} <sprite name=icon_gold>";
					}
					Util.SetActive(tooltipWagesTMP.gameObject, component4 != null);
				}
			}
			bool active = building != null && (tooltipRequireTMP.gameObject.activeSelf || tooltipWorkerTMP.gameObject.activeSelf || tooltipProductionTMP.gameObject.activeSelf || tooltipStoresTMP.gameObject.activeSelf || tooltipResidentsTMP.gameObject.activeSelf || tooltipWagesTMP.gameObject.activeSelf);
			Util.SetActive(tooltipDetailsContainer, active);
			if (node.displayModelInstance == null && node.displayModelPrefab != null)
			{
				node.displayModelInstance = UnityEngine.Object.Instantiate(node.displayModelPrefab, tooltipModelContainer.transform, worldPositionStays: false);
				Util.SetLayerRecursively(node.displayModelInstance.gameObject, LayerMask.NameToLayer("UI"));
				float num2 = 100f * node.scaleModifier;
				node.displayModelInstance.localScale = new Vector3(num2, num2, num2);
				node.displayModelInstance.localPosition = new Vector3(0f, 0f, -100f);
				node.displayModelInstance.rotation = Quaternion.Euler(-15f, -60f, 25f);
			}
			if (node.displayModelInstance != null)
			{
				node.displayModelInstance.gameObject.SetActive(value: true);
			}
			node.tooltipBackground.texture = (node.isUnlocked ? unlockedSelectedTexture : defaultSelectedTexture);
			node.tooltipBackground.gameObject.SetActive(value: true);
			tooltipLight.intensity = ((node.isUnlocked || (flag2 && node.isUnlockable)) ? 1.1f : 0.5f);
		}
		else
		{
			tooltipNode = null;
		}
		for (int j = 0; j < tooltipModelContainer.transform.childCount; j++)
		{
			Transform child = tooltipModelContainer.transform.GetChild(j);
			if ((tooltipNode == null || child != tooltipNode.displayModelInstance) && child.name != "Spot Light")
			{
				child.gameObject.SetActive(value: false);
			}
		}
		tooltipModelContainer.SetActive(isVisible);
		tooltip.gameObject.SetActive(isVisible);
	}

	public void OnTooltipExit(PointerEventData pData)
	{
		isHoveringTooltip = false;
	}

	public void OnTooltipEnter(PointerEventData pData)
	{
		isHoveringTooltip = true;
	}

	private void SetReqOutlineVisuals(TechnologyTreeNode node, bool isVisible)
	{
		if (node == null)
		{
			return;
		}
		string rText = string.Empty;
		bool flag = !DoesNodeHaveRequirements(node) || IsNodeRequirementsUnlocked(node, ref rText);
		isVisible &= !node.isUnlocked && !(node.isUnlockable & flag);
		for (int i = 0; i < node.requireUnlocked.Length; i++)
		{
			TechnologyTreeNode technologyTreeNode = node.requireUnlocked[i];
			Util.SetEnabled(technologyTreeNode.outlineImg, isVisible);
			if (isVisible)
			{
				technologyTreeNode.outlineImg.color = (technologyTreeNode.isUnlocked ? preqSucessColor : preqFailColor);
			}
		}
	}

	private bool DoesNodeHaveRequirements(TechnologyTreeNode node)
	{
		if (node.requireUnlocked != null)
		{
			return node.requireUnlocked.Length != 0;
		}
		return false;
	}

	private bool IsNodeRequirementsUnlocked(TechnologyTreeNode node, ref string rText)
	{
		bool flag = true;
		if (DoesNodeHaveRequirements(node))
		{
			rText = "<b>" + LocalizationManager.GetTranslation("RequiredColon") + "</b> ";
			for (int i = 0; i < node.requireUnlocked.Length; i++)
			{
				bool flag2 = IsTechnologyUnlocked(node.requireUnlocked[i].unlockKey);
				if (i != 0)
				{
					rText += ", ";
				}
				string format = (flag2 ? "<color=green>{0}</color>" : "<color=red>{0}</color>");
				rText += string.Format(format, LocalizationManager.GetTranslation(node.requireUnlocked[i].buildingUniqueName.Equals(string.Empty) ? (node.requireUnlocked[i].unlockKey + "_title") : $"Building {node.requireUnlocked[i].buildingUniqueName} FriendlyName"));
				flag &= flag2;
			}
		}
		return flag;
	}

	public void OnTooltipUnlockClicked()
	{
		if (!(tooltipNode == null))
		{
			if (tooltipNode.prosperityPointCost <= Player.inst.ProsperityPoints)
			{
				tooltipNode.isUnlocked = true;
				OnSuccessUnlock(tooltipNode);
			}
			else
			{
				OnFailedUnlock(tooltipNode);
			}
		}
	}

	public void Reset()
	{
		Util.SetActive(lineContainer.gameObject, active: false);
		for (int i = 0; i < canvases.Length; i++)
		{
			Util.SetEnabled(canvases[i], active: false);
		}
		for (int j = 0; j < graphicRaycasters.Length; j++)
		{
			Util.SetEnabled(graphicRaycasters[j], active: false);
		}
		unHideBuildingNodes.ClearFast();
		unhideNodes.ClearFast();
		animAcceleration = 1f;
		for (int k = 0; k < nodes.Count; k++)
		{
			Broadcast.TechnologyTreeUnlockEvent.Broadcast(new OnTechnologyTreeUnlock
			{
				unlockKey = nodes[k].unlockKey,
				unlocked = false
			});
			nodes[k].Reset();
		}
		ClearUnlockKeys();
		isFirstTimeOpening = true;
		UpdateNodes();
	}

	public static bool IsLineHidden(TechnologyTreeLink link)
	{
		return IsLineHidden(link.node1, link.node2);
	}

	public static bool IsLineHidden(TechnologyTreeNode node1, TechnologyTreeNode node2)
	{
		if (!node1.isHidden || node2.isUnlocked)
		{
			if (node2.isHidden)
			{
				return !node1.isUnlocked;
			}
			return false;
		}
		return true;
	}

	private void AddUnlockKey(string key)
	{
		unlockedKeys.Add(key);
		if (key == "unlockkey_finewine")
		{
			isFineWineUnlocked = true;
		}
	}

	private void ClearUnlockKeys()
	{
		if (unlockedKeys != null)
		{
			unlockedKeys.Clear();
		}
		isFineWineUnlocked = false;
	}

	public void UnlockAll()
	{
		unlockedKeys = new List<string>(nodes.Count);
		for (int i = 0; i < nodes.Count; i++)
		{
			TechnologyTreeNode technologyTreeNode = nodes[i];
			technologyTreeNode.isUnlocked = true;
			if (!unlockedKeys.Contains(technologyTreeNode.unlockKey))
			{
				AddUnlockKey(technologyTreeNode.unlockKey);
				Broadcast.TechnologyTreeUnlockEvent.Broadcast(new OnTechnologyTreeUnlock
				{
					unlockKey = technologyTreeNode.unlockKey,
					unlocked = true
				});
			}
		}
		UpdateNodes();
	}

	public void UnlockAvailable()
	{
		for (int i = 0; i < nodes.Count; i++)
		{
			TechnologyTreeNode technologyTreeNode = nodes[i];
			if (!IsLockedForVersion(technologyTreeNode))
			{
				technologyTreeNode.isUnlocked = true;
				if (!unlockedKeys.Contains(technologyTreeNode.unlockKey))
				{
					AddUnlockKey(technologyTreeNode.unlockKey);
					Broadcast.TechnologyTreeUnlockEvent.Broadcast(new OnTechnologyTreeUnlock
					{
						unlockKey = technologyTreeNode.unlockKey,
						unlocked = true
					});
				}
			}
		}
		UpdateNodes();
	}

	public void ShowBuildingNode(string uniqueName)
	{
		unHideBuildingNodes.Add(uniqueName);
	}

	public void UnhideNode(TechnologyTreeNode node)
	{
		if (!unhideNodes.Contains(node) && node.isHidden)
		{
			unhideNodes.Add(node);
			for (int i = 0; i < node.requireUnlocked.Length; i++)
			{
				UnhideNode(node.requireUnlocked[i]);
			}
		}
	}
}
