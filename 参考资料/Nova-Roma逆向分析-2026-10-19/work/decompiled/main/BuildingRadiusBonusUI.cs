using TMPro;
using UnityEngine;

public class BuildingRadiusBonusUI : MonoBehaviour
{
	[SerializeField]
	private BuildingHealthItemUI itemPrefab;

	[SerializeField]
	private GameObject topObj;

	[SerializeField]
	private RectTransform itemContainer;

	[SerializeField]
	private TextMeshProUGUI happinessTMP;

	private int itemPoolCount;

	private ArrayExt<BuildingHealthItemUI> itemPool = new ArrayExt<BuildingHealthItemUI>(8);

	private Building building;

	private Tavern tavern;

	private RadiusBonus radBonus;

	public Sprite successBG;

	public Sprite failBG;

	public void SetVisibility(bool isVisible)
	{
		gameObject.SetActive(isVisible);
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null)
		{
			SetVisibility(isVisible: false);
			return;
		}
		radBonus = b.GetComponent<RadiusBonus>();
		if (radBonus == null || (!radBonus.OverlayWhenPlacing && !radBonus.OverlayWhenSelected) || !radBonus.applied || DoIgnoreRadiusBonus(b))
		{
			SetVisibility(isVisible: false);
			radBonus = null;
			return;
		}
		building = b;
		tavern = b.GetComponent<Tavern>();
		itemPoolCount = 0;
		if (tavern != null && tavern.gatherTypes != null && tavern.gatherTypes.Length != 0)
		{
			for (int i = 0; i < tavern.gatherTypes.Length; i++)
			{
				BuildingHealthItemUI item = GetItem();
				FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefMap[tavern.gatherTypes[i]];
				item.iconImg.sprite = resourceDef.texture;
				item.tooltipHook.SetTerm(resourceDef.name);
				Util.SetActive(item.gameObject, active: true);
			}
			for (int num = itemPool.Count - 1; num >= itemPoolCount; num--)
			{
				Util.SetActive(itemPool.data[num].gameObject, active: false);
			}
			Util.SetActive(topObj.gameObject, active: true);
		}
		else
		{
			Util.SetActive(topObj.gameObject, active: false);
		}
		RefreshVisuals();
		SetVisibility(isVisible: true);
	}

	public void OnDeselected()
	{
		building = null;
		tavern = null;
		itemPoolCount = 0;
	}

	private void Update()
	{
		if (!(radBonus == null) && !(building == null))
		{
			RefreshVisuals();
		}
	}

	private void RefreshVisuals()
	{
		if (tavern != null && tavern.gatherTypes != null && tavern.gatherTypes.Length != 0)
		{
			for (int i = 0; i < tavern.gatherTypes.Length; i++)
			{
				int rID = tavern.gatherTypes[i];
				int maxResourceAmount = tavern.GetMaxResourceAmount(rID);
				int num = Mathff.Min(tavern.GetStoredResourceAmount(rID), maxResourceAmount);
				BuildingHealthItemUI obj = itemPool.data[i];
				obj.storageTMP.text = $"{num}/{maxResourceAmount}";
				Util.SetActive(obj.consumeCheck, num > 0);
				Util.SetActive(obj.consumeAbort, num <= 0);
				obj.circleBG.sprite = ((num > 0) ? successBG : failBG);
			}
		}
		int maxHappiness = radBonus.GetMaxHappiness();
		int currentHappiness = radBonus.GetCurrentHappiness();
		if (!radBonus.VariableBonus)
		{
			happinessTMP.text = ((maxHappiness >= 0) ? "<color=green>" : "<color=red>") + Util.GetSuffixSymbol(maxHappiness) + maxHappiness;
		}
		else
		{
			happinessTMP.text = string.Format("{0}{1}</color> / {2}", (currentHappiness <= 0 && currentHappiness != maxHappiness) ? "<color=red>" : "<color=green>", Util.GetSuffixSymbol(currentHappiness) + currentHappiness, maxHappiness);
		}
	}

	private BuildingHealthItemUI GetItem()
	{
		if (itemPoolCount == itemPool.Count)
		{
			BuildingHealthItemUI item = Object.Instantiate(itemPrefab, itemContainer);
			itemPool.Add(item);
		}
		return itemPool.data[itemPoolCount++];
	}

	private bool DoIgnoreRadiusBonus(Building b)
	{
		return b.categoryHash == World.bathCategoryHash;
	}
}
