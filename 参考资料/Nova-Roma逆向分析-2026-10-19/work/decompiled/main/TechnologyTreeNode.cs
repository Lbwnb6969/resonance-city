using System;
using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class TechnologyTreeNode : MonoBehaviour
{
	public enum LockForVersion
	{
		None,
		Demo,
		FutureUpdate
	}

	[Serializable]
	public struct IsConnectedToRootData
	{
		public bool isConnected;

		public TechnologyTreeNode[] nodes;
	}

	[SerializeField]
	public bool isRoot;

	[SerializeField]
	public bool IsUnlockedPersistant;

	[SerializeField]
	public bool IsHiddenPersistant;

	[SerializeField]
	public LockForVersion isLockedFor;

	[SerializeField]
	public bool isUnlocked;

	[SerializeField]
	public bool isHidden;

	[HideInInspector]
	public bool isUnlockable;

	public List<bool> isLinkConnectedToRoot = new List<bool>();

	public List<TechnologyTree.TechnologyTreeLink> links = new List<TechnologyTree.TechnologyTreeLink>();

	public List<IsConnectedToRootData> isConnectorsConnectedToRoot = new List<IsConnectedToRootData>();

	public List<TechnologyTreeConnector> connectors = new List<TechnologyTreeConnector>();

	[HideInInspector]
	public RectTransform rectT;

	public RectTransform isUnlockedContainer;

	public RectTransform isLockedContainer;

	public RectTransform isUnlockableContainer;

	public RectTransform isHiddenContainer;

	public RectTransform hideContainer;

	public GameObject costContainer;

	public GameObject requirementsNotMetObj;

	public GameObject insufficientPointsObj;

	public GameObject demoObj;

	public Localize demoLoc;

	public Image outlineImg;

	public RawImage iconRawImage;

	public TextMeshProUGUI titleTMP;

	public TextMeshProUGUI costTMP;

	public RawImage costIcon;

	public RawImage tooltipBackground;

	public Image animRadialBackgroundImg;

	public Image animBackgroundImg;

	public RectTransform animBackgroundRect;

	public Button unlockBtn;

	public Localize unlockLoc;

	public string unlockKey = "unlockkey_";

	public string buildingUniqueName = "";

	public int prosperityPointCost = 1;

	public TechnologyTreeNode[] requireUnlocked;

	public Transform displayModelPrefab;

	[NonSerialized]
	public Transform displayModelInstance;

	public float scaleModifier = 1f;

	public SerializableGuid guid;

	private TechnologyTree technologyTree;

	private static HashSet<string> hasVisited = new HashSet<string>(200);

	private static ArrayExt<TechnologyTreeNode> openset = new ArrayExt<TechnologyTreeNode>(200);

	private static List<TechnologyTreeNode> scratchNodes = new List<TechnologyTreeNode>(8);

	private TechnologyTree TechnologyTree
	{
		get
		{
			if (technologyTree == null)
			{
				technologyTree = GetComponentInParent<TechnologyTree>();
			}
			return technologyTree;
		}
	}

	public void OnNodeClicked()
	{
	}

	public void OnNodeUnlock()
	{
		TechnologyTree.OnTooltipUnlockClicked();
	}

	public void OnNodeEnter()
	{
		TechnologyTree.SetTooltipVisibility(this, isVisible: true);
	}

	public void OnNodeExit()
	{
		if (TechnologyTree.tooltipNode == this)
		{
			TechnologyTree.SetTooltipVisibility(null, isVisible: false);
		}
	}

	public void CalculateState()
	{
		if (isUnlocked)
		{
			isUnlockable = true;
			UpdateVisuals();
			return;
		}
		bool flag = false;
		int num = 0;
		while (true)
		{
			if (num < links.Count)
			{
				if (links[num].DoesProvideUnlock(this))
				{
					flag = true;
					break;
				}
				num++;
				continue;
			}
			for (int i = 0; i < connectors.Count; i++)
			{
				if (connectors[i].link.DoesProvideUnlock(this))
				{
					flag = true;
					break;
				}
			}
			break;
		}
		if (flag && !isUnlockable && requireUnlocked != null && requireUnlocked.Length != 0)
		{
			for (int j = 0; j < requireUnlocked.Length; j++)
			{
				TechnologyTree.inst.UnhideNode(requireUnlocked[j]);
			}
		}
		isUnlockable = flag;
		UpdateVisuals();
	}

	public void UpdateVisuals()
	{
		bool flag = isHidden && Application.isPlaying;
		isUnlockedContainer.gameObject.SetActive(isUnlocked);
		isLockedContainer.gameObject.SetActive(!isUnlocked && !isUnlockable);
		isUnlockableContainer.gameObject.SetActive(isUnlockable && !isUnlocked);
		hideContainer.gameObject.SetActive(!flag || isUnlockable);
		costContainer.SetActive(isUnlockable && !isUnlocked);
		if (isHiddenContainer != null)
		{
			isHiddenContainer.gameObject.SetActive(IsHiddenPersistant && Application.isEditor && !Application.isPlaying);
		}
		titleTMP.text = LocalizationManager.GetTranslation(buildingUniqueName.Equals(string.Empty) ? (unlockKey + "_title") : $"Building {buildingUniqueName} FriendlyName");
		costTMP.text = prosperityPointCost.ToString();
		bool flag2 = isUnlocked;
		if (Application.isPlaying)
		{
			flag2 |= Player.inst.ProsperityPoints >= prosperityPointCost;
		}
		iconRawImage.color = ((flag2 && (isUnlocked || isUnlockable)) ? TechnologyTree.bright : TechnologyTree.dark);
		costTMP.color = ((flag2 && (isUnlocked || isUnlockable)) ? TechnologyTree.bright : TechnologyTree.error);
		costIcon.color = ((flag2 && (isUnlocked || isUnlockable)) ? TechnologyTree.bright : TechnologyTree.error);
		for (int i = 0; i < links.Count; i++)
		{
			if (isLinkConnectedToRoot.Count > i && isLinkConnectedToRoot[i])
			{
				Util.SetActive(links[i].line.demoLock, TechnologyTree.IsLockedForVersion(this));
			}
		}
	}

	public bool RemoveLink(TechnologyTreeNode node)
	{
		if (node == null)
		{
			return false;
		}
		for (int i = 0; i < links.Count; i++)
		{
			TechnologyTree.TechnologyTreeLink technologyTreeLink = links[i];
			if (technologyTreeLink.node1 == node || technologyTreeLink.node2 == node)
			{
				links.RemoveAt(i--);
			}
		}
		return false;
	}

	private void SetTreeDirty()
	{
		isUnlocked = IsUnlockedPersistant;
		isHidden = IsHiddenPersistant;
		TechnologyTree.isDirty = true;
		UpdateVisuals();
	}

	private void OnDemoChanged()
	{
		if (Application.isPlaying || !TechnologyTree.IsLockedForVersion(this))
		{
			return;
		}
		for (int i = 0; i < links.Count; i++)
		{
			if (isLinkConnectedToRoot.Count > i && isLinkConnectedToRoot[i])
			{
				if (isLockedFor != LockForVersion.None)
				{
					links[i].line.ShowDemoLock(isLockedFor);
				}
				else
				{
					links[i].line.HideDemoLock();
				}
			}
		}
	}

	public void Reset()
	{
		isUnlocked = IsUnlockedPersistant;
		isHidden = IsHiddenPersistant;
	}

	private void DebugForceDirtyUpdate()
	{
		SetTreeDirty();
	}

	public void FindLinksToRoot()
	{
		scratchNodes.Clear();
		isLinkConnectedToRoot.Clear();
		for (int i = 0; i < links.Count; i++)
		{
			hasVisited.Clear();
			hasVisited.Add(guid.ToString());
			TechnologyTree.TechnologyTreeLink technologyTreeLink = links[i];
			TechnologyTreeNode item = ((technologyTreeLink.node1 == this) ? technologyTreeLink.node2 : technologyTreeLink.node1);
			openset.Clear();
			openset.Add(item);
			bool item2 = false;
			while (openset.Count > 0)
			{
				TechnologyTreeNode technologyTreeNode = openset.PopFirst();
				if (hasVisited.Contains(technologyTreeNode.guid.ToString()) | TechnologyTree.IsLockedForVersion(technologyTreeNode))
				{
					continue;
				}
				hasVisited.Add(technologyTreeNode.guid.ToString());
				if (technologyTreeNode.isRoot)
				{
					item2 = true;
					break;
				}
				for (int j = 0; j < technologyTreeNode.links.Count; j++)
				{
					TechnologyTree.TechnologyTreeLink technologyTreeLink2 = technologyTreeNode.links[j];
					TechnologyTreeNode technologyTreeNode2 = ((technologyTreeLink2.node1 == technologyTreeNode) ? technologyTreeLink2.node2 : technologyTreeLink2.node1);
					if (!hasVisited.Contains(technologyTreeNode2.guid.ToString()))
					{
						openset.Add(technologyTreeNode2);
					}
				}
				for (int k = 0; k < technologyTreeNode.connectors.Count; k++)
				{
					TechnologyTreeConnector technologyTreeConnector = technologyTreeNode.connectors[k];
					for (int l = 0; l < technologyTreeConnector.link.nodes.Count; l++)
					{
						TechnologyTreeNode technologyTreeNode3 = technologyTreeConnector.link.nodes[l];
						if (!(technologyTreeNode3 == technologyTreeNode) && !hasVisited.Contains(technologyTreeNode3.guid.ToString()))
						{
							openset.Add(technologyTreeNode3);
						}
					}
				}
			}
			isLinkConnectedToRoot.Add(item2);
		}
		scratchNodes.Clear();
		isConnectorsConnectedToRoot.Clear();
		for (int m = 0; m < connectors.Count; m++)
		{
			IsConnectedToRootData item3 = new IsConnectedToRootData
			{
				isConnected = false
			};
			TechnologyTreeConnector technologyTreeConnector2 = connectors[m];
			for (int n = 0; n < technologyTreeConnector2.link.nodes.Count; n++)
			{
				TechnologyTreeNode technologyTreeNode4 = technologyTreeConnector2.link.nodes[n];
				if (technologyTreeNode4 == this)
				{
					continue;
				}
				hasVisited.Clear();
				hasVisited.Add(guid.ToString());
				openset.ClearFast();
				openset.Add(technologyTreeNode4);
				while (openset.Count > 0)
				{
					TechnologyTreeNode technologyTreeNode5 = openset.PopFirst();
					if (hasVisited.Contains(technologyTreeNode5.guid.ToString()))
					{
						continue;
					}
					hasVisited.Add(technologyTreeNode5.guid.ToString());
					if (technologyTreeNode5.isRoot)
					{
						item3.isConnected = true;
						scratchNodes.Add(technologyTreeNode4);
						break;
					}
					for (int num = 0; num < technologyTreeNode5.links.Count; num++)
					{
						TechnologyTree.TechnologyTreeLink technologyTreeLink3 = technologyTreeNode5.links[num];
						TechnologyTreeNode technologyTreeNode6 = ((technologyTreeLink3.node1 == technologyTreeNode5) ? technologyTreeLink3.node2 : technologyTreeLink3.node1);
						if (!hasVisited.Contains(technologyTreeNode6.guid.ToString()))
						{
							openset.Add(technologyTreeNode6);
						}
					}
					for (int num2 = 0; num2 < technologyTreeNode5.connectors.Count; num2++)
					{
						TechnologyTreeConnector technologyTreeConnector3 = technologyTreeNode5.connectors[num2];
						if (technologyTreeConnector2 == technologyTreeConnector3)
						{
							continue;
						}
						for (int num3 = 0; num3 < technologyTreeConnector3.link.nodes.Count; num3++)
						{
							TechnologyTreeNode technologyTreeNode7 = technologyTreeConnector3.link.nodes[num3];
							if (!(technologyTreeNode7 == technologyTreeNode5) && !hasVisited.Contains(technologyTreeNode7.guid.ToString()))
							{
								openset.Add(technologyTreeNode7);
							}
						}
					}
				}
			}
			item3.nodes = scratchNodes.ToArray();
			isConnectorsConnectedToRoot.Add(item3);
		}
	}
}
