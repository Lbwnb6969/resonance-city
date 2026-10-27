using System;
using System.Collections;
using System.Collections.Generic;
using Assets.Code;
using FMODUnity;
using Sirenix.OdinInspector;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class BuildUI : MonoBehaviour
{
	[Serializable]
	public class BuildGroup
	{
		[Serializable]
		public class BuildItem
		{
			public Building prefab;

			public Building preqPrefab;

			public Vector3 scale;

			public int type;

			public static ValueDropdownList<int> TypeDropdownOptions = new ValueDropdownList<int>
			{
				{ "Default", 0 },
				{ "Open Group", 1 },
				{ "Custom", 2 }
			};

			public const int TYPE_DEFAULT = 0;

			public const int TYPE_OPENGROUP = 1;

			public const int TYPE_CUSTOM = 2;

			[SerializeField]
			public UnityEvent onCustomSelected;

			[SerializeField]
			public string groupName;

			[NonSerialized]
			public BuildItemUI itemUI;

			[NonSerialized]
			public bool isEnabled;

			[NonSerialized]
			public bool isUnlocked;

			[NonSerialized]
			public bool isAffordable;

			[NonSerialized]
			public bool isPreqPassed;

			private static IEnumerable GetGroupNames()
			{
				ValueDropdownList<string> valueDropdownList = new ValueDropdownList<string>();
				BuildingDefinitions buildingDefinitions = Resources.Load<BuildingDefinitions>("BuildingDefinitions");
				for (int i = 0; i < buildingDefinitions.Groups.Length; i++)
				{
					if (buildingDefinitions.Groups[i].isSubGroup)
					{
						valueDropdownList.Add(buildingDefinitions.Groups[i].category);
					}
				}
				return valueDropdownList;
			}

			public BuildItem(Building building, Building preq, Vector3 scale, string subGroup = "")
			{
				prefab = building;
				preqPrefab = preq;
				this.scale = scale;
			}

			public BuildItem(BuildItem item)
			{
				prefab = item.prefab;
				preqPrefab = item.preqPrefab;
				scale = item.scale;
				type = item.type;
				onCustomSelected = item.onCustomSelected;
			}
		}

		public string category;

		public string categoryPreq;

		public string lockedTooltipTerm = "";

		[Tooltip("Does not create build button, Used on items to open sub groups")]
		public bool isSubGroup;

		public Sprite icon;

		[NonSerialized]
		public bool isGroupUnlocked;

		[NonSerialized]
		public BuildButtonUI buttonUI;

		[NonSerialized]
		public BuildGroupUI groupUI;

		public List<BuildItem> items = new List<BuildItem>(8);

		[NonSerialized]
		public GameObject returnItemUI;

		public BuildGroup(BuildGroup g)
		{
			category = g.category;
			categoryPreq = g.categoryPreq;
			lockedTooltipTerm = g.lockedTooltipTerm;
			isSubGroup = g.isSubGroup;
			icon = g.icon;
			for (int i = 0; i < g.items.Count; i++)
			{
				items.Add(new BuildItem(g.items[i]));
			}
		}
	}

	public class DLCBuildItem
	{
		public string name;

		public Vector3 scale;
	}

	public static BuildUI inst;

	[SerializeField]
	private BuildButtonUI buttonPrefab;

	[SerializeField]
	private BuildGroupUI groupPrefab;

	[SerializeField]
	private BuildItemUI itemPrefab;

	[SerializeField]
	private GameObject returnItemPrefab;

	[SerializeField]
	private Canvas[] canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	[SerializeField]
	private GraphicRaycaster groupGraphicRaycaster;

	[SerializeField]
	private Transform buttonContainer;

	[SerializeField]
	private RectTransform groupContainer;

	[SerializeField]
	private GameObject landmassOverlay;

	public float hideY = -135f;

	public float showY = 55f;

	public float animSpeed = 5f;

	private Vector3 targetPos;

	private float animTime;

	private int status;

	private const int None = 0;

	private const int Showing = 1;

	private const int Hiding = 2;

	private ResourceAmount sResourceAmount = new ResourceAmount();

	private bool isVisible;

	private string prevActiveGroup;

	private BuildGroup activeGroup;

	private EventHandler<OnTechnologyTreeUnlock> onTechnologyTreeUnlock;

	private EventHandler<OnBuildingBuilt> onBuildingBuilt;

	private EventHandler<OnBuildingAddRemove> onBuildingAddRemove;

	private bool isPreqCheckDirty;

	private List<BuildGroup> buildGroups = new List<BuildGroup>(32);

	public Dictionary<string, bool> UnlockedMap = new Dictionary<string, bool>(128);

	public ArrayExt<string> BuildingPreq = new ArrayExt<string>(64);

	public ArrayExt<string> GroupsPreq = new ArrayExt<string>(64);

	private int lastLandmass = -1;

	public static DLCBuildItem[] parksAndStatues = new DLCBuildItem[25]
	{
		new DLCBuildItem
		{
			name = World.parkDummyName,
			scale = new Vector3(0.9f, 0.9f, 0.9f)
		},
		new DLCBuildItem
		{
			name = "statue_lion",
			scale = new Vector3(1.3f, 1.3f, 1.3f)
		},
		new DLCBuildItem
		{
			name = "statue_horseknight",
			scale = new Vector3(1.2f, 1.2f, 1.2f)
		},
		new DLCBuildItem
		{
			name = "statue_knight",
			scale = new Vector3(1.5f, 1.5f, 1.5f)
		},
		new DLCBuildItem
		{
			name = "statue_princess",
			scale = new Vector3(1.5f, 1.5f, 1.5f)
		},
		new DLCBuildItem
		{
			name = "statue_gargoyle",
			scale = new Vector3(1.5f, 1.5f, 1.5f)
		},
		new DLCBuildItem
		{
			name = "statue_gnome",
			scale = new Vector3(1.5f, 1.5f, 1.5f)
		},
		new DLCBuildItem
		{
			name = "statue_fish",
			scale = new Vector3(1.5f, 1.5f, 1.5f)
		},
		new DLCBuildItem
		{
			name = "statue_obelisk",
			scale = new Vector3(1.5f, 1.5f, 1.5f)
		},
		new DLCBuildItem
		{
			name = "statue_slab",
			scale = new Vector3(1.5f, 1.5f, 1.5f)
		},
		new DLCBuildItem
		{
			name = "park_banner",
			scale = new Vector3(0.9f, 0.9f, 0.9f)
		},
		new DLCBuildItem
		{
			name = "park_brazier",
			scale = new Vector3(0.9f, 0.9f, 0.9f)
		},
		new DLCBuildItem
		{
			name = "park_pinetree",
			scale = new Vector3(0.9f, 0.9f, 0.9f)
		},
		new DLCBuildItem
		{
			name = "park_tree",
			scale = new Vector3(0.9f, 0.9f, 0.9f)
		},
		new DLCBuildItem
		{
			name = "park_flowers",
			scale = new Vector3(0.9f, 0.9f, 0.9f)
		},
		new DLCBuildItem
		{
			name = "park_stone1x1",
			scale = new Vector3(0.9f, 0.9f, 0.9f)
		},
		new DLCBuildItem
		{
			name = "park_grass",
			scale = new Vector3(0.9f, 0.9f, 0.9f)
		},
		new DLCBuildItem
		{
			name = "park_stonetile",
			scale = new Vector3(0.9f, 0.9f, 0.9f)
		},
		new DLCBuildItem
		{
			name = "park_treerow",
			scale = new Vector3(0.9f, 0.9f, 0.9f)
		},
		new DLCBuildItem
		{
			name = "park_reflectingpool",
			scale = new Vector3(0.6f, 0.6f, 0.6f)
		},
		new DLCBuildItem
		{
			name = "park_stone2x1",
			scale = new Vector3(0.6f, 0.6f, 0.6f)
		},
		new DLCBuildItem
		{
			name = "park_flowers2x1",
			scale = new Vector3(0.6f, 0.6f, 0.6f)
		},
		new DLCBuildItem
		{
			name = "park_pond",
			scale = new Vector3(0.6f, 0.6f, 0.6f)
		},
		new DLCBuildItem
		{
			name = "park_tree2x2",
			scale = new Vector3(0.6f, 0.6f, 0.6f)
		},
		new DLCBuildItem
		{
			name = "park_flowers2x2",
			scale = new Vector3(0.6f, 0.6f, 0.6f)
		}
	};

	public bool IsVisible()
	{
		return isVisible;
	}

	public bool IsGroupActive()
	{
		return activeGroup != null;
	}

	public void SetVisibility(bool v)
	{
		for (int i = 0; i < canvas.Length; i++)
		{
			Util.SetEnabled(canvas[i], v);
		}
		gRaycaster.enabled = v;
		enabled = v;
		if (v != isVisible && !v)
		{
			groupGraphicRaycaster.enabled = false;
		}
		if (!v && activeGroup != null)
		{
			activeGroup.groupUI.SetVisibility(v: false);
			if (!activeGroup.isSubGroup)
			{
				Util.SetEnabled(activeGroup.buttonUI.isSelectedRawImg, active: false);
			}
			activeGroup = null;
			SetStatus(2);
			animTime = 1f;
			groupContainer.anchoredPosition = targetPos;
		}
		isVisible = v;
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		BuildingDefinitions buildingDefinitions = Resources.Load<BuildingDefinitions>("BuildingDefinitions");
		if (buildingDefinitions != null)
		{
			BuildingDefinitions buildingDefinitions2 = UnityEngine.Object.Instantiate(buildingDefinitions);
			for (int i = 0; i < buildingDefinitions2.Groups.Length; i++)
			{
				AddGroup(buildingDefinitions2.Groups[i]);
			}
		}
		onTechnologyTreeUnlock = Broadcast.TechnologyTreeUnlockEvent.Listen(OnTechnologyTreeUnlock);
	}

	private void OnDestroy()
	{
		Broadcast.TechnologyTreeUnlockEvent.Unlisten(OnTechnologyTreeUnlock);
	}

	public void AddGroup(BuildGroup group)
	{
		if (!group.isSubGroup)
		{
			BuildButtonUI buildButtonUI = UnityEngine.Object.Instantiate(buttonPrefab, buttonContainer, worldPositionStays: false);
			group.buttonUI = buildButtonUI;
			buildButtonUI.transform.name = group.category;
			buildButtonUI.icon.sprite = group.icon;
			buildButtonUI.btn.onClick.AddListener(() =>
			{
				if (!IsAnimating())
				{
					ShowGroup(group.category);
				}
			});
			buildButtonUI.lockedTooltipHook.SetTerm(group.lockedTooltipTerm);
			buildButtonUI.unlockedTooltipHook.SetTerm(group.category);
		}
		BuildGroupUI buildGroupUI = UnityEngine.Object.Instantiate(groupPrefab, groupContainer, worldPositionStays: false);
		group.groupUI = buildGroupUI;
		buildGroupUI.name = group.category;
		if (group.isSubGroup)
		{
			GameObject gameObject = UnityEngine.Object.Instantiate(returnItemPrefab, buildGroupUI.itemContainer, worldPositionStays: false);
			gameObject.GetComponentInChildren<Button>().onClick.AddListener(ShowPreviousGroup);
			group.returnItemUI = gameObject;
		}
		for (int num = 0; num < group.items.Count; num++)
		{
			BuildGroup.BuildItem buildItem = group.items[num];
			if (!(buildItem.prefab == null))
			{
				BuildItemUI buildItemUI = (buildItem.itemUI = UnityEngine.Object.Instantiate(itemPrefab, buildGroupUI.itemContainer, worldPositionStays: false));
				buildItemUI.name = buildItem.prefab.UniqueName;
				buildItemUI.Init(buildItem);
			}
		}
		buildGroups.Add(group);
	}

	public void AddBuilding(string category, BuildGroup.BuildItem item)
	{
		if (item.prefab == null)
		{
			Debug.Log("Failed to add building, prefab is null");
			return;
		}
		for (int i = 0; i < buildGroups.Count; i++)
		{
			BuildGroup buildGroup = buildGroups[i];
			if (!(buildGroup.category != category))
			{
				BuildItemUI buildItemUI = (item.itemUI = UnityEngine.Object.Instantiate(itemPrefab, buildGroup.groupUI.itemContainer, worldPositionStays: false));
				buildItemUI.name = item.prefab.UniqueName;
				buildItemUI.Init(item);
				buildGroup.items.Add(item);
				return;
			}
		}
		Debug.Log("Failed to add " + item.prefab.UniqueName + " to " + category + " Build Group");
	}

	public void ShowGroup(string category)
	{
		lastLandmass = -1;
		BuildGroup buildGroup = GetGroup(category);
		BuildInfoFloating.inst.SetVisibility(v: false);
		ConsoleBuildMenu.inst.HideSelectorVisuals();
		if (buildGroup == null || buildGroup.items.Count == 0)
		{
			return;
		}
		if (activeGroup == null && status == 0)
		{
			GameUI.inst.ReturnToDefaultCursorMode();
			GameUI.inst.ClearSelection();
			GameUI.inst.CellHighlighter.SetHoverIcon(GameUI.HoverIcons.None);
			GameUI.inst.ClearUIForClick();
			ProsperityUI.inst.SetMissionVisibility(v: false);
			CreativeUI.inst.SetWindowVisibility(v: false);
		}
		if (activeGroup == buildGroup)
		{
			HideGroups();
			return;
		}
		if (activeGroup != null)
		{
			groupGraphicRaycaster.enabled = true;
			if (!activeGroup.isSubGroup)
			{
				activeGroup.buttonUI.isSelectedRawImg.enabled = false;
			}
			activeGroup.groupUI.SetVisibility(v: false);
		}
		else
		{
			SetStatus(1);
			BuildInfoFloating.inst.dismissed = false;
		}
		if (!buildGroup.isSubGroup)
		{
			buildGroup.buttonUI.HideUnlock();
			buildGroup.buttonUI.isSelectedRawImg.enabled = true;
		}
		else
		{
			GetBuildButtonForSubGroup(buildGroup).HideUnlock();
		}
		buildGroup.groupUI.SetVisibility(v: true);
		prevActiveGroup = activeGroup?.category;
		activeGroup = buildGroup;
		UpdateItemVisibilityCustom(buildGroup);
		isPreqCheckDirty = true;
		RuntimeManager.PlayOneShot("event:/SFX ASITP/UI/ui_buildMenu_select_topMenu_down");
		GameUI.inst.CurrPlacementMode.AbortPlacement(refund: true);
		TerrainGen.inst.StopTerritoryTexture();
	}

	public void UpdateItemVisibilityCustom(BuildGroup target)
	{
		for (int i = 0; i < target.items.Count; i++)
		{
			if (!(target.items[i].prefab.UniqueName == "romanoutpost"))
			{
				continue;
			}
			Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass("romanoutpost", mustBeBuilt: false);
			int num = 0;
			for (int j = 0; j < Player.inst.PlayerLandmassOwner.ownedLandMasses.Count; j++)
			{
				if (Player.inst.GetBuildingListForLandMass(Player.inst.PlayerLandmassOwner.ownedLandMasses.data[i]).Count > 0)
				{
					num++;
				}
			}
			bool flag = Player.inst.GetBuildingListForLandMass(Player.inst.FocusedLandMass).Count > 0 && Player.inst.GetBuildingListForLandMass(Player.inst.FocusedLandMass, "romanoutpost".GetHashCode()).Count <= 0;
			bool active = (num <= 0) | flag;
			target.items[i].itemUI.gameObject.SetActive(active);
			break;
		}
	}

	public void HideGroups()
	{
		if (activeGroup != null)
		{
			if (status != 2)
			{
				RuntimeManager.PlayOneShot("event:/SFX ASITP/UI/ui_buildMenu_select_topMenu_release");
			}
			SetStatus(2);
		}
	}

	public BuildGroup GetGroup(string category)
	{
		for (int i = 0; i < buildGroups.Count; i++)
		{
			if (buildGroups[i].category == category)
			{
				return buildGroups[i];
			}
		}
		return null;
	}

	public void ShowPreviousGroup()
	{
		if (!string.IsNullOrEmpty(prevActiveGroup))
		{
			ShowGroup(prevActiveGroup);
		}
	}

	public bool IsAnimating()
	{
		return status != 0;
	}

	private void SetStatus(int s)
	{
		animTime = 0f;
		switch (s)
		{
		case 1:
			groupGraphicRaycaster.enabled = false;
			targetPos = groupContainer.anchoredPosition;
			targetPos.y = showY;
			ProsperityUI.inst.SetMissionVisibility(v: false);
			break;
		case 2:
			groupGraphicRaycaster.enabled = false;
			BuildInfoFloating.inst.SetVisibility(v: false);
			targetPos = groupContainer.anchoredPosition;
			targetPos.y = hideY;
			break;
		}
		if (s == 0 && activeGroup != null)
		{
			if (status == 2)
			{
				if (!activeGroup.isSubGroup)
				{
					activeGroup.buttonUI.isSelectedRawImg.enabled = false;
				}
				activeGroup.groupUI.SetVisibility(v: false);
				activeGroup = null;
				groupGraphicRaycaster.enabled = false;
			}
			else if (status == 1)
			{
				groupGraphicRaycaster.enabled = true;
			}
		}
		status = s;
	}

	private void Update()
	{
		if (!GameState.inst.IsPlayMode() || LoadSave.Loading)
		{
			return;
		}
		BuildItemUI.RestoreFillPulse();
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		int focusedLandMass = Player.inst.FocusedLandMass;
		landmassOverlay.SetActive(focusedLandMass == -1);
		int num = status;
		if ((uint)(num - 1) <= 1u)
		{
			animTime = Mathff.Clamp01(animTime + unscaledDeltaTime * animSpeed);
			Vector3 a = groupContainer.anchoredPosition;
			a = Vector3.Lerp(a, targetPos, animTime);
			groupContainer.anchoredPosition = a;
			if (animTime >= 1f)
			{
				SetStatus(0);
			}
		}
		for (int i = 0; i < buildGroups.Count; i++)
		{
			BuildGroup buildGroup = buildGroups[i];
			if (!buildGroup.isGroupUnlocked && isPreqCheckDirty && (string.IsNullOrEmpty(buildGroup.categoryPreq) || Player.inst.DoesAnyBuildingHaveCategoryOnPlayerLandmass(buildGroup.categoryPreq, mustBeBuilt: true)))
			{
				OnGroupPreqPassed(buildGroup);
			}
			if (buildGroup.isGroupUnlocked && (!buildGroup.isSubGroup || (buildGroup.isSubGroup && buildGroup.groupUI.gameObject.activeSelf)))
			{
				bool active = true;
				for (int j = 0; j < buildGroup.items.Count; j++)
				{
					BuildGroup.BuildItem buildItem = buildGroup.items[j];
					if (buildItem.itemUI.IsVisible())
					{
						active = false;
						if (!buildItem.isPreqPassed && isPreqCheckDirty && DefaultItemPreqCheck(buildItem))
						{
							OnItemPreqPassed(buildItem);
						}
						if (!buildItem.isUnlocked && buildItem.isPreqPassed)
						{
							UnlockItem(buildGroup, buildItem);
						}
						active &= !buildItem.isUnlocked;
						if (buildGroup.groupUI.gameObject.activeSelf)
						{
							buildItem.isAffordable = Player.inst.FocusedResources.HasCost(buildItem.prefab.GetCost(Player.inst.FocusedLandMass, ref sResourceAmount));
							buildItem.isEnabled = buildItem.isUnlocked && buildItem.isPreqPassed && buildItem.isAffordable && focusedLandMass != -1;
							buildItem.itemUI.UpdateVisuals(unscaledDeltaTime);
						}
					}
				}
				Util.SetEnabled(buildGroup.groupUI.emptyTMP, active);
			}
			if (focusedLandMass != lastLandmass && buildGroup.groupUI.gameObject.activeSelf)
			{
				UpdateItemVisibilityCustom(buildGroup);
			}
		}
		lastLandmass = focusedLandMass;
		isPreqCheckDirty = false;
	}

	private void UnlockItem(BuildGroup group, BuildGroup.BuildItem item)
	{
		UnlockedMap.TryAdd(item.prefab.UniqueName, value: false);
		if (!UnlockedMap[item.prefab.UniqueName])
		{
			if (!group.isSubGroup)
			{
				group.buttonUI.OnItemUnlocked();
			}
			else
			{
				GetBuildButtonForSubGroup(group).OnItemUnlocked();
			}
			item.itemUI.SetUnlockedVisuals(v: true);
		}
		else
		{
			item.itemUI.SetUnlockedVisuals(v: false);
		}
		item.isUnlocked = true;
	}

	private BuildButtonUI GetBuildButtonForSubGroup(BuildGroup target)
	{
		if (!target.isSubGroup)
		{
			return target.buttonUI;
		}
		for (int i = 0; i < buildGroups.Count; i++)
		{
			BuildGroup buildGroup = buildGroups[i];
			if (buildGroup.isSubGroup)
			{
				continue;
			}
			for (int j = 0; j < buildGroup.items.Count; j++)
			{
				BuildGroup.BuildItem buildItem = buildGroup.items[j];
				if (buildItem.type == 1 && buildItem.groupName == target.category)
				{
					return buildGroup.buttonUI;
				}
			}
		}
		return null;
	}

	private void OnGroupPreqPassed(BuildGroup group)
	{
		if (!group.isSubGroup)
		{
			group.buttonUI.Unlock();
		}
		group.isGroupUnlocked = true;
		if (!GroupsPreq.Contains(group.category))
		{
			GroupsPreq.Add(group.category);
		}
	}

	private void OnItemPreqPassed(BuildGroup.BuildItem item)
	{
		item.isPreqPassed = true;
		if (!BuildingPreq.Contains(item.prefab.UniqueName))
		{
			BuildingPreq.Add(item.prefab.UniqueName);
		}
	}

	public void OnHoveredUnlock(string uniqueName)
	{
		if (UnlockedMap.ContainsKey(uniqueName))
		{
			UnlockedMap[uniqueName] = true;
		}
	}

	public void Reset()
	{
		for (int i = 0; i < buildGroups.Count; i++)
		{
			BuildGroup buildGroup = buildGroups[i];
			buildGroup.isGroupUnlocked = false;
			if (!buildGroup.isSubGroup)
			{
				buildGroup.buttonUI.Reset();
			}
			for (int j = 0; j < buildGroup.items.Count; j++)
			{
				BuildGroup.BuildItem buildItem = buildGroup.items[j];
				buildItem.isUnlocked = (buildItem.isEnabled = (buildItem.isAffordable = (buildItem.isPreqPassed = false)));
				buildItem.itemUI.SetUnlockedVisuals(v: false);
			}
			buildGroup.groupUI.SetVisibility(v: false);
		}
		UnlockedMap.Clear();
		GroupsPreq.ClearFast();
		BuildingPreq.ClearFast();
		HideGroups();
		animTime = 1f;
		activeGroup = null;
		isPreqCheckDirty = true;
		onBuildingBuilt = Broadcast.BuildingBuilt.ListenAny(OnBuildingBuilt);
		onBuildingAddRemove = Broadcast.BuildingAddRemove.ListenAny(OnBuildingAddRemove);
	}

	public void ApplyPreqs()
	{
		for (int i = 0; i < buildGroups.Count; i++)
		{
			for (int j = 0; j < GroupsPreq.Count; j++)
			{
				if (buildGroups[i].category == GroupsPreq.data[j])
				{
					OnGroupPreqPassed(buildGroups[i]);
					break;
				}
			}
			for (int k = 0; k < buildGroups[i].items.Count; k++)
			{
				for (int l = 0; l < BuildingPreq.Count; l++)
				{
					string text = BuildingPreq.data[l];
					if (buildGroups[i].items[k].prefab.UniqueName == text)
					{
						OnItemPreqPassed(buildGroups[i].items[k]);
						break;
					}
				}
			}
		}
	}

	private bool DefaultItemPreqCheck(BuildGroup.BuildItem item)
	{
		if (!(item.preqPrefab == null))
		{
			return Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass(item.preqPrefab.UniqueName, mustBeBuilt: false);
		}
		return true;
	}

	public Building GetPrefabByUniqueName(string name)
	{
		for (int i = 0; i < buildGroups.Count; i++)
		{
			BuildGroup buildGroup = buildGroups[i];
			for (int j = 0; j < buildGroup.items.Count; j++)
			{
				BuildGroup.BuildItem buildItem = buildGroup.items[j];
				if (buildItem.prefab.UniqueName == name)
				{
					return buildItem.prefab;
				}
			}
		}
		return null;
	}

	private void OnBuildingBuilt(object sender, OnBuildingBuilt data)
	{
		if (Player.inst.LandMassIsAPlayerLandMass(data.targetBuilding.LandMass()))
		{
			isPreqCheckDirty = true;
		}
	}

	private void OnBuildingAddRemove(object sender, OnBuildingAddRemove data)
	{
		if (data.added && Player.inst.LandMassIsAPlayerLandMass(data.targetBuilding.LandMass()))
		{
			isPreqCheckDirty = true;
		}
	}

	private void OnTechnologyTreeUnlock(object sender, OnTechnologyTreeUnlock data)
	{
		string[] array = data.unlockKey.Split("_");
		if (array.Length >= 2)
		{
			string uniqueName = array[1];
			SetButtonVisibilityInTab(uniqueName, data.unlocked);
		}
		SetButtonVisibilityInTab("insula1x3", visibility: false);
		switch (data.unlockKey)
		{
		case "unlockkey_terraforming2":
			break;
		case "unlockkey_forum":
			SetButtonVisibilityInTab(World.forumDummyName, data.unlocked);
			break;
		case "unlockkey_terraforming1":
			SetButtonVisibilityInTab(World.moatName, data.unlocked);
			SetButtonVisibilityInTab(World.moundName, data.unlocked);
			break;
		case "unlockkey_watercontrol":
			SetButtonVisibilityInTab(World.damName, data.unlocked);
			SetButtonVisibilityInTab(World.spilloverName, data.unlocked);
			break;
		case "unlockkey_waterengineering":
			SetButtonVisibilityInTab(World.waterTowerName, data.unlocked);
			SetButtonVisibilityInTab(World.castellumaquaeName, data.unlocked);
			SetButtonVisibilityInTab("aqueductDummyBuilding", data.unlocked);
			break;
		case "unlockkey_cemeteries":
			SetButtonVisibilityInTab(World.cemetery3x3Name, data.unlocked);
			SetButtonVisibilityInTab("cemeteryrow", data.unlocked);
			SetButtonVisibilityInTab(World.cemeteryCircleName, data.unlocked);
			SetButtonVisibilityInTab(World.cemeteryDiamondName, data.unlocked);
			break;
		case "unlockkey_foodcourt":
			SetButtonVisibilityInTab("shopsdummy", data.unlocked);
			break;
		case "unlockkey_woodcastleblock":
			SetButtonVisibilityInTab(World.woodengateName, data.unlocked);
			break;
		case "unlockkey_castleblock":
			SetButtonVisibilityInTab(World.gateName, data.unlocked);
			break;
		}
	}

	private bool SetButtonVisibilityInTab(string uniqueName, bool visibility)
	{
		for (int i = 0; i < buildGroups.Count; i++)
		{
			BuildGroup buildGroup = buildGroups[i];
			bool flag = false;
			bool visibility2 = visibility;
			for (int j = 0; j < buildGroup.items.Count; j++)
			{
				BuildGroup.BuildItem buildItem = buildGroup.items[j];
				if (buildItem.prefab.UniqueName != uniqueName)
				{
					if (buildItem.itemUI.IsVisible())
					{
						visibility2 = true;
					}
					continue;
				}
				flag = true;
				buildItem.itemUI.SetVisibility(visibility);
				if (visibility)
				{
					UnlockItem(buildGroup, buildItem);
				}
			}
			if (!flag)
			{
				continue;
			}
			if (buildGroup.isSubGroup)
			{
				for (int k = 0; k < buildGroups.Count; k++)
				{
					List<BuildGroup.BuildItem> items = buildGroups[k].items;
					int num = 0;
					BuildGroup.BuildItem buildItem2;
					while (num < items.Count)
					{
						buildItem2 = items[num];
						if (buildItem2.type != 1 || !(buildItem2.groupName == buildGroup.category))
						{
							num++;
							continue;
						}
						goto IL_00d7;
					}
					continue;
					IL_00d7:
					buildItem2.itemUI.SetVisibility(visibility2);
					break;
				}
			}
			return true;
		}
		return false;
	}

	public void TryAddSurvivalStatue()
	{
	}

	public BuildTab GetConsoleTab(string t)
	{
		return null;
	}

	public void UpdateMaterials(int bannerIdx)
	{
	}

	public void SetConsoleTabActive(string t)
	{
	}
}
