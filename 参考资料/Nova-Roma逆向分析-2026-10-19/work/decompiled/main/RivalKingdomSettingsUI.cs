using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class RivalKingdomSettingsUI : MonoBehaviour
{
	private List<int> inUseRivalCodes = new List<int>();

	[NonSerialized]
	public RivalItemUI[] rivalItems;

	public static RivalKingdomSettingsUI inst;

	public Toggle randomToggle;

	public GameObject randomCover;

	public GameObject flagPrefab;

	private AIStartFlagpole heldFlag;

	public ConsoleUIItem rivalEntry;

	public ConsoleUIItem rootEntry;

	private int lastCode = -1;

	public void Awake()
	{
		inst = this;
	}

	public void UpdateSlotAvailability()
	{
		inUseRivalCodes.Clear();
		inUseRivalCodes.Add(Player.inst.PlayerLandmassOwner.bannerIdx);
		if (rivalItems != null)
		{
			for (int i = 0; i < rivalItems.Length; i++)
			{
				rivalItems[i].Locked = true;
				rivalItems[i].flag?.SetLandMass(-1);
				rivalItems[i].flag?.gameObject.SetActive(value: false);
			}
			for (int j = 0; j < rivalItems.Length && j < World.inst.validStartLandmassForAICount - 1; j++)
			{
				rivalItems[j].Locked = false;
			}
			TerrainGen.inst.ClearOverlay(updateToo: true);
		}
	}

	public void Start()
	{
		SetupNRivals(1);
		UpdateSlotAvailability();
		for (int i = 0; i < rivalItems.Length; i++)
		{
			rivalItems[i].flag = UnityEngine.Object.Instantiate(flagPrefab).GetComponent<AIStartFlagpole>();
			rivalItems[i].flag.gameObject.SetActive(value: false);
		}
	}

	public void OnEnable()
	{
		inUseRivalCodes.Clear();
		inUseRivalCodes.Add(Player.inst.PlayerLandmassOwner.bannerIdx);
		if (rivalItems == null)
		{
			rivalItems = gameObject.GetComponentsInChildren<RivalItemUI>();
			for (int i = 0; i < rivalItems.Length; i++)
			{
				rivalItems[i].Enabled = false;
				MakeRivalEnableState(rivalItems[i]);
				MakeRivalFlagButton(rivalItems[i]);
			}
			randomToggle.onValueChanged.AddListener(ToggleRandomToggle);
		}
		for (int j = 0; j < rivalItems.Length; j++)
		{
			AIStartFlagpole flag = rivalItems[j].flag;
			if ((object)flag == null || flag.landmass != -1)
			{
				rivalItems[j].flag?.gameObject.SetActive(value: true);
			}
		}
	}

	public void MakeRivalEnableState(RivalItemUI item)
	{
		item.enableButton.onClick.AddListener(() =>
		{
			ActivateRivalItem(item);
		});
	}

	public void OnDisable()
	{
		for (int i = 0; i < rivalItems.Length; i++)
		{
			rivalItems[i]?.flag?.gameObject.SetActive(value: false);
		}
	}

	public void Update()
	{
		if (heldFlag == null)
		{
			if (PointingSystem.GetPointer().GetPrimaryDown() && !GameUI.inst.PointerOverUI())
			{
				Physics.Raycast(PointingSystem.GetRay(), out var hitInfo, 200f, LayerMask.GetMask("AIStartFlag"));
				AIStartFlagpole aIStartFlagpole = hitInfo.transform?.GetComponent<AIStartFlagpole>();
				if (aIStartFlagpole != null)
				{
					heldFlag = aIStartFlagpole;
				}
			}
			return;
		}
		Plane plane = new Plane(Vector3.up, Vector3.zero);
		Ray ray = PointingSystem.GetRay();
		plane.Raycast(ray, out var enter);
		Vector3 point = ray.GetPoint(enter);
		if (PointingSystem.GetPointer().GetPrimaryUp())
		{
			heldFlag.StopHolding(point);
			for (int i = 0; i < rivalItems.Length; i++)
			{
				if (rivalItems[i].flag.landmass == heldFlag.landmass && rivalItems[i].flag != heldFlag)
				{
					rivalItems[i].flag.ClearFlag();
				}
			}
			UpdateLandColors();
			if (heldFlag.landmass == -1)
			{
				heldFlag.ClearFlag();
			}
			heldFlag = null;
		}
		else
		{
			heldFlag.SetHoldPosition(point);
		}
		if (PointingSystem.GetPointer().GetSecondaryDown())
		{
			heldFlag.ClearFlag();
			UpdateLandColors();
			heldFlag = null;
		}
	}

	public void ResetRivalItems()
	{
		if (rivalItems != null)
		{
			for (int i = 0; i < rivalItems.Length; i++)
			{
				rivalItems[i].flag.landmass = -1;
			}
		}
		UpdateSlotAvailability();
	}

	public void UpdateLandColors()
	{
		TerrainGen.inst.ClearOverlay(updateToo: false);
		for (int i = 0; i < rivalItems.Length; i++)
		{
			if (rivalItems[i].flag.landmass != -1)
			{
				Color mapColor = World.inst.liverySets[rivalItems[i].bannerIdx].mapColor;
				ArrayExt<Cell> arrayExt = World.inst.cellsToLandmass[rivalItems[i].flag.landmass];
				for (int j = 0; j < arrayExt.Count; j++)
				{
					Cell cell = arrayExt.data[j];
					TerrainGen.inst.SetOverlayTileColor(cell.x, cell.z, mapColor);
				}
			}
		}
		TerrainGen.inst.UpdateOverlayTextures(1f, 0f, 1f);
		TerrainGen.inst.FadeOverlay(1f);
	}

	public void ToggleRandomToggle(bool on)
	{
		randomCover.SetActive(on);
		for (int i = 0; i < rivalItems.Length; i++)
		{
			rivalItems[i].transform.GetChild(0).gameObject.SetActive(!on);
		}
		if (on)
		{
			if (rivalEntry.isHovered)
			{
				rivalEntry.Reset();
				rivalEntry.lastChildSelected = null;
				rootEntry.Hover();
			}
			PickRandomRivals();
		}
	}

	public void SetupNRivals(int n)
	{
		int num = n;
		for (int i = 0; i < rivalItems.Length; i++)
		{
			if (rivalItems[i].Enabled)
			{
				RemoveRivalItem(rivalItems[i]);
			}
			if (num > 0)
			{
				ActivateRivalItem(rivalItems[i]);
			}
			num--;
		}
	}

	public void PickRandomRivals()
	{
		SetupNRivals(UnityEngine.Random.Range(1, 5));
	}

	public void MakeRivalFlagButton(RivalItemUI item)
	{
		EventTrigger.Entry entry = new EventTrigger.Entry();
		entry.eventID = EventTriggerType.PointerDown;
		entry.callback.AddListener((BaseEventData data) =>
		{
			ActivateRivalFlag(item);
		});
		item.bannerTrigger.triggers.Add(entry);
	}

	public void ActivateRivalFlag(RivalItemUI item)
	{
		heldFlag = item.flag;
		item.flag.gameObject.SetActive(value: true);
		heldFlag.SetFlagMaterial(World.inst.liverySets[item.bannerIdx].bannerMaterial);
	}

	public void ActivateRivalItem(RivalItemUI rivalItem)
	{
		int num = FindUnusedRivalCode();
		rivalItem.bannerIdx = num;
		rivalItem.rivalName.text = AIBrainsContainer.inst.AIKingdomNamePool[num];
		rivalItem.SetTexture(World.inst.liverySets[num].banners);
		rivalItem.flavorText.text = AIBrainsContainer.inst.AIKingdomFlavorTextPool[num];
		rivalItem.removeButton.onClick.RemoveAllListeners();
		rivalItem.removeButton.onClick.AddListener(() =>
		{
			RemoveRivalItem(rivalItem);
		});
		rivalItem.personalityDropdown.onValueChanged.AddListener((int newValue) =>
		{
		});
		inUseRivalCodes.Add(num);
		lastCode = num;
		rivalItem.Enabled = true;
	}

	public void RemoveRivalItem(RivalItemUI rivalItem)
	{
		inUseRivalCodes.Remove(rivalItem.bannerIdx);
		rivalItem.flag.ClearFlag();
		rivalItem.Enabled = false;
		UpdateLandColors();
	}

	public int FindUnusedRivalCode()
	{
		do
		{
			lastCode++;
			if (lastCode >= World.inst.liverySets.Count)
			{
				lastCode = 0;
			}
		}
		while (inUseRivalCodes.Contains(lastCode));
		return lastCode;
	}
}
