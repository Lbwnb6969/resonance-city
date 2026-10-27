using System;
using Assets.Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ResourceLineItemUI : MonoBehaviour
{
	public TMP_InputField orderAmt;

	private int price;

	private int availableAmount;

	[NonSerialized]
	public int rtype;

	public Image resourceImage;

	public TextMeshProUGUI priceUI;

	public TextMeshProUGUI availableUI;

	public TextMeshProUGUI costUI;

	public TooltipHook tooltipHook;

	[NonSerialized]
	public bool buy = true;

	public void Set(int r, int price, int available)
	{
		FreeResourceSystem.ResourceDef resourceDef = FreeResourceSystem.inst.resourceDefMap[r];
		resourceImage.sprite = resourceDef.texture;
		tooltipHook.toolTipText = LocalizationManager.GetTranslation(resourceDef.name);
		priceUI.SetText("{0}", price);
		availableUI.SetText("{0}", available);
		costUI.SetText("{0}", 0f);
		orderAmt.text = "0";
		rtype = r;
		this.price = price;
		availableAmount = available;
	}

	public int GetOrderAmount()
	{
		int result = 0;
		if (int.TryParse(orderAmt.text, out result))
		{
			return result;
		}
		return 0;
	}

	public int GetCost()
	{
		return GetOrderAmount() * price;
	}

	public ResourceAmount GetOrderedResources()
	{
		return ResourceAmount.Make(rtype, GetOrderAmount());
	}

	private void Start()
	{
		orderAmt.onSelect.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = false;
			ClampOrder();
		});
		orderAmt.onEndEdit.AddListener((string val) =>
		{
			GameState.inst.AlphaNumericHotkeysEnabled = true;
			ClampOrder();
		});
	}

	private void ClampOrder()
	{
		if (GetOrderAmount() < 0)
		{
			orderAmt.text = "0";
			return;
		}
		if (buy && GetCost() > Player.inst.PlayerLandmassOwner.Gold)
		{
			int num = Player.inst.PlayerLandmassOwner.Gold / price;
			if (num < 0)
			{
				num = 0;
			}
			orderAmt.text = num.ToString();
		}
		if (availableAmount < GetOrderAmount())
		{
			orderAmt.text = availableAmount.ToString();
		}
		costUI.SetText("{0}", GetCost());
	}

	public void UpdateAvailable(int available)
	{
		availableAmount = available;
		availableUI.SetText("{0}", availableAmount);
		ClampOrder();
	}

	private void Update()
	{
		ClampOrder();
	}
}
