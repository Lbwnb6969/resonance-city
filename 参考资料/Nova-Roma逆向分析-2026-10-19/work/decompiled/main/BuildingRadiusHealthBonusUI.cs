using TMPro;
using UnityEngine;

public class BuildingRadiusHealthBonusUI : MonoBehaviour
{
	public static BuildingRadiusHealthBonusUI inst;

	[SerializeField]
	private BuildingHealthItemUI itemPrefab;

	[SerializeField]
	private GameObject topObj;

	[SerializeField]
	private RectTransform itemContainer;

	[SerializeField]
	private TextMeshProUGUI healthTMP;

	private int itemPoolCount;

	private ArrayExt<BuildingHealthItemUI> itemPool = new ArrayExt<BuildingHealthItemUI>(8);

	private Building building;

	private RadiusBonusHealth radHealthBonus;

	public Sprite successBG;

	public Sprite failBG;

	private void Awake()
	{
		inst = this;
	}

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
		radHealthBonus = b.GetComponent<RadiusBonusHealth>();
		if (radHealthBonus == null || (!radHealthBonus.OverlayWhenPlacing && !radHealthBonus.OverlayWhenSelected) || !radHealthBonus.applied || DoIgnoreRadiusBonus(b))
		{
			SetVisibility(isVisible: false);
			radHealthBonus = null;
			return;
		}
		building = b;
		itemPoolCount = 0;
		Util.SetActive(topObj.gameObject, active: false);
		RefreshVisuals();
		SetVisibility(isVisible: true);
	}

	public void OnDeselected()
	{
		building = null;
		itemPoolCount = 0;
	}

	private void Update()
	{
		if (!(radHealthBonus == null) && !(building == null))
		{
			RefreshVisuals();
		}
	}

	private void RefreshVisuals()
	{
		int maxHealth = radHealthBonus.GetMaxHealth();
		int currentHealth = radHealthBonus.GetCurrentHealth();
		if (!radHealthBonus.VariableBonus)
		{
			healthTMP.text = ((maxHealth >= 0) ? "<color=green>" : "<color=red>") + Util.GetSuffixSymbol(maxHealth) + maxHealth;
		}
		else
		{
			healthTMP.text = string.Format("{0}{1}</color> / {2}", (currentHealth <= 0 && currentHealth != maxHealth) ? "<color=red>" : "<color=green>", Util.GetSuffixSymbol(currentHealth) + currentHealth, maxHealth);
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
		return false;
	}
}
