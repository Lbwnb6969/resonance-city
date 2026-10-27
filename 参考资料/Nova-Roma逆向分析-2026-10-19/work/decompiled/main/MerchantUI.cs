using System;
using System.Collections.Generic;
using Assets.Code;
using Assets.Code.UI;
using Assets.Interface;
using Colorful;
using FMODUnity;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class MerchantUI : MonoBehaviour
{
	public static MerchantUI inst;

	[SerializeField]
	private MerchantResourceItemUI resourceItemPrefab;

	private int resourceUIPoolCount;

	private ArrayExt<MerchantResourceItemUI> resourceUIPool = new ArrayExt<MerchantResourceItemUI>(64);

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	[SerializeField]
	private RectTransform containerRectT;

	[SerializeField]
	public Toggle[] tabToggles;

	[SerializeField]
	private GameObject buysellContainerObj;

	[SerializeField]
	private Transform buysellItemContainer;

	[SerializeField]
	private GameObject sellHeaderObj;

	[SerializeField]
	private GameObject buyHeaderObj;

	[SerializeField]
	private Button completeTransactionBtn;

	[SerializeField]
	private Localize transactionLocalize;

	[SerializeField]
	private TextMeshProUGUI discountTMP;

	[SerializeField]
	private GameObject discountObj;

	[SerializeField]
	private TextMeshProUGUI totalTMP;

	[SerializeField]
	private GameObject goldWarningObj;

	[SerializeField]
	private Button closeBtn;

	[SerializeField]
	private Confirmation dismissConfirmation;

	[SerializeField]
	private Button dismissBtn;

	[SerializeField]
	private GameObject transactionContainer;

	[SerializeField]
	private GameObject sailingContainer;

	[SerializeField]
	private Localize sailingLocalize;

	[SerializeField]
	private ConsoleUIItem consoleEntry;

	[SerializeField]
	private GameObject consoleClose;

	[SerializeField]
	private RectTransform tooltipRectT;

	public const int TAB_NONE = -1;

	public const int TAB_BUY = 0;

	public const int TAB_SELL = 1;

	public const int TAB_SPECIAL = 3;

	private int currTab = -1;

	private TMP_InputField prevInput;

	private bool isEditingInput;

	private bool hasStoppedEditingThisFrame;

	[NonSerialized]
	public IMerchant ship;

	[NonSerialized]
	public MerchantShip mShip;

	private Cam.TransformCapture camCapture;

	private bool isVisible;

	private bool isTransactionVisible;

	private static ArrayExt<Vector3> tempPoints = new ArrayExt<Vector3>(16);

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool visible)
	{
		if (isVisible && !visible)
		{
			SetTransactionVisibility(v: false);
			Cam.inst.ClearTrack();
			GameUI.inst.RemoveFromSelection(ship as ISelectable);
			GameState.inst.AlphaNumericHotkeysEnabled = true;
			dismissConfirmation.Reset();
			currTab = -1;
		}
		else if (!isVisible & visible)
		{
			CreativeUI.inst.SetVisibility(v: false);
			UpdateContainerVisuals();
		}
		Util.SetEnabled(canvas, visible);
		Util.SetEnabled(gRaycaster, visible);
		isVisible = visible;
	}

	private void SetTransactionVisibility(bool v)
	{
		if (isTransactionVisible != v)
		{
			if (isTransactionVisible && !v)
			{
				GameState.inst.AlphaNumericHotkeysEnabled = true;
				Cam.inst.GetComponent<FastVignette>().enabled = false;
				SetGameUIVisibility(v: true);
				Cam.inst.ApplyTransformCapture(camCapture);
				TimeManager.inst.SetLocked(val: false);
				RectTransform rectTransform = containerRectT;
				RectTransform rectTransform2 = containerRectT;
				Vector2 vector = (containerRectT.anchorMin = new Vector2(1f, 0f));
				Vector2 pivot = (rectTransform2.anchorMax = vector);
				rectTransform.pivot = pivot;
				containerRectT.anchoredPosition = new Vector2(0f, 0f);
			}
			else if (!isTransactionVisible & v)
			{
				GameState.inst.AlphaNumericHotkeysEnabled = false;
				Cam.inst.GetComponent<FastVignette>().enabled = true;
				SetGameUIVisibility(v: false);
				camCapture = Cam.inst.CaptureCameraTransform();
				TimeManager.inst.SetLocked(val: true);
				tempPoints.ClearFast();
				tempPoints.Add(ship.GetPos());
				tempPoints.Add(ship.GetCurrentDock().bi.Center());
				Vector3 input = tempPoints.data[0] + tempPoints.data[1];
				input.NonAllocateMultiply(0.5f);
				Cam.inst.BringIntoView(input, tempPoints);
				RectTransform rectTransform3 = containerRectT;
				RectTransform rectTransform4 = containerRectT;
				Vector2 vector = (containerRectT.anchorMin = new Vector2(0.5f, 0f));
				Vector2 pivot = (rectTransform4.anchorMax = vector);
				rectTransform3.pivot = pivot;
				containerRectT.anchoredPosition = new Vector2(350f, 156.5f);
				SelectTab(0, doSilent: true);
			}
		}
		Util.SetActive(transactionContainer, v);
		Util.SetActive(sailingContainer, !v);
		isTransactionVisible = v;
	}

	private void SetGameUIVisibility(bool v)
	{
		NotificationUI.inst.SetVisibility(v);
		BuildUI.inst.SetVisibility(v);
		CursorModeUI.inst.SetVisibility(v);
		ProsperityUI.inst.SetVisibility(v);
		MiniMapUI.inst.SetVisibility(v);
		SpeedControlUI.inst.SetVisibility(v);
		SeasonViewer.inst.SetVisibility(v);
	}

	private void Awake()
	{
		inst = this;
	}

	private void Start()
	{
		for (int i = 0; i < tabToggles.Length; i++)
		{
			int i2 = i;
			tabToggles[i].onValueChanged.AddListener((bool b) =>
			{
				if (b)
				{
					SelectTab(i2);
				}
			});
		}
		closeBtn.onClick.AddListener(() =>
		{
			SetVisibility(visible: false);
		});
		dismissBtn.onClick.AddListener(() =>
		{
			dismissConfirmation.ShowConfirmation(DismissShip, null);
		});
		completeTransactionBtn.onClick.AddListener(() =>
		{
			if (currTab == 1)
			{
				OnCompleteSellTransaction();
			}
			else if (currTab == 0)
			{
				OnCompleteBuyTransaction();
			}
		});
		GamepadControl gamepadControl = GamepadControl.inst;
		gamepadControl.controllerUpdate = (GamepadControl.ControllerActivity)Delegate.Combine(gamepadControl.controllerUpdate, new GamepadControl.ControllerActivity(OnConsoleUpdate));
	}

	public void SelectMerchant(IMerchant s)
	{
		ship = s;
		if (ship != null)
		{
			mShip = ship as MerchantShip;
			SetVisibility(visible: true);
			Cam.inst.Track(ship as MerchantShip);
		}
	}

	private MerchantResourceItemUI GetResourceItemUI()
	{
		MerchantResourceItemUI item = null;
		if (resourceUIPoolCount == resourceUIPool.Count)
		{
			item = UnityEngine.Object.Instantiate(resourceItemPrefab, buysellItemContainer, worldPositionStays: false);
			Util.SetEnabled(item.background, resourceUIPool.Count % 2 == 0);
			resourceUIPool.Add(item);
			item.amtInput.onSelect.AddListener((string val) =>
			{
				isEditingInput = true;
				prevInput = item.amtInput;
			});
			EventTrigger.Entry entry = new EventTrigger.Entry();
			entry.eventID = EventTriggerType.PointerEnter;
			entry.callback.AddListener((BaseEventData pData) =>
			{
				if (item.isSellAmountOffset)
				{
					tooltipRectT.transform.position = item.storageTMP.transform.position;
					Util.SetActive(tooltipRectT.gameObject, active: true);
				}
			});
			item.tooltipTrigger.triggers.Add(entry);
			entry = new EventTrigger.Entry();
			entry.eventID = EventTriggerType.PointerExit;
			entry.callback.AddListener((BaseEventData pData) =>
			{
				Util.SetActive(tooltipRectT.gameObject, active: false);
			});
			item.tooltipTrigger.triggers.Add(entry);
		}
		item = resourceUIPool.data[resourceUIPoolCount++];
		item.amtInput.onEndEdit.RemoveAllListeners();
		item.amtInput.onEndEdit.AddListener((string val) =>
		{
			if (prevInput == item.amtInput)
			{
				prevInput = null;
				isEditingInput = false;
				hasStoppedEditingThisFrame = true;
			}
		});
		Util.SetActive(item.gameObject, active: true);
		return item;
	}

	private void HideAccessResourceItems()
	{
		for (int num = resourceUIPool.Count - 1; num >= resourceUIPoolCount; num--)
		{
			Util.SetActive(resourceUIPool.data[num].gameObject, active: false);
		}
	}

	private void DismissShip()
	{
		if (ship != null && ship is MerchantShip merchantShip)
		{
			merchantShip.Leave();
			SetVisibility(visible: false);
		}
	}

	public void SelectTab(int tabIdx, bool doSilent = false)
	{
		if (!doSilent)
		{
			SfxSystem.PlayUiSelect();
		}
		switch (tabIdx)
		{
		case 0:
			RefreshBuyWindow();
			break;
		case 1:
			RefreshSellWindow();
			break;
		}
		Util.SetActive(sellHeaderObj, tabIdx == 1);
		Util.SetActive(buyHeaderObj, tabIdx == 0);
		Util.SetActive(buysellContainerObj, tabIdx == 0 || tabIdx == 1);
		for (int i = 0; i < tabToggles.Length; i++)
		{
			tabToggles[i].SetIsOnWithoutNotify(tabIdx == i);
		}
		currTab = tabIdx;
	}

	private void RefreshBuyWindow()
	{
		Util.SetActive(goldWarningObj, active: false);
		resourceUIPoolCount = 0;
		transactionLocalize.SetTerm("Buy");
		ResourceAmount hold = ship.GetHold();
		ResourceAmount buyFromPrice = ship.GetBuyFromPrice();
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		for (int i = 0; i < resourceDefs.Count; i++)
		{
			FreeResourceSystem.ResourceDef rDef = resourceDefs[i];
			int amt = hold.Get(rDef.ID);
			if (amt <= 0)
			{
				continue;
			}
			int cost = buyFromPrice.Get(rDef.ID);
			MerchantResourceItemUI itemUI = GetResourceItemUI();
			itemUI.rID = rDef.ID;
			itemUI.isSellAmountOffset = false;
			Util.SetEnabled(itemUI.exclamationIcon, active: false);
			itemUI.amtInput.interactable = true;
			itemUI.resourceTooltip.SetTerm(rDef.name);
			itemUI.resourceIcon.sprite = rDef.texture;
			itemUI.amtInput.SetTextWithoutNotify("0");
			itemUI.storageTMP.text = amt.ToString();
			itemUI.priceTMP.text = cost.ToString();
			itemUI.costTMP.text = "0";
			itemUI.amtInput.onEndEdit.AddListener((string str) =>
			{
				if (!int.TryParse(str, out var result))
				{
					itemUI.amtInput.SetTextWithoutNotify("0");
					result = 0;
				}
				if (result > 0)
				{
					result = TryGetDesiredAmount(Mathff.Min(result, amt), ship.GetBuyFromPrice(), rDef.ID);
				}
				itemUI.amtInput.SetTextWithoutNotify(result.ToString());
				itemUI.costTMP.text = (cost * result).ToString();
				RefreshBuyTotal();
			});
		}
		RefreshBuyTotal();
		HideAccessResourceItems();
	}

	private void RefreshBuyTotal()
	{
		totalTMP.text = ScriptLocalization.Total + ": " + GetTotalPrice(ship.GetBuyFromPrice(), doDiscounts: true) + " <sprite name=icon_gold>";
	}

	public void OnCompleteBuyTransaction()
	{
		Dock currentDock = ship.GetCurrentDock();
		int landmass = currentDock.bi.LandMass();
		LandmassOwner landmassOwner = World.GetLandmassOwner(currentDock.bi.LandMass());
		ResourceAmount buyFromPrice = ship.GetBuyFromPrice();
		ResourceAmount resourceAmount = new ResourceAmount();
		int num = 0;
		int num2 = 0;
		Vector3 unloadPosition = currentDock.GetUnloadPosition();
		Stockpile component = currentDock.GetComponent<Stockpile>();
		ResourceAmount amt = new ResourceAmount();
		for (int i = 0; i < resourceUIPoolCount; i++)
		{
			MerchantResourceItemUI merchantResourceItemUI = resourceUIPool.data[i];
			if (int.TryParse(merchantResourceItemUI.amtInput.text, out var result) && result > 0)
			{
				amt.Clear();
				resourceAmount.Add(merchantResourceItemUI.rID, result);
				num += buyFromPrice.Get(merchantResourceItemUI.rID) * result;
				num2 += result;
				ResourceStatistics.AddProduction(landmass, "trading", merchantResourceItemUI.rID, result);
				if (!mShip.itemsSold.TryAdd(merchantResourceItemUI.rID, result))
				{
					mShip.itemsSold[merchantResourceItemUI.rID] += result;
				}
				int num3 = component.SpaceAvailable(merchantResourceItemUI.rID);
				if (num3 > 0)
				{
					int num4 = Mathff.Min(num3, result);
					result -= num4;
					amt.Add(merchantResourceItemUI.rID, num4);
					component.Deposit(ref amt);
				}
				while (result > 0)
				{
					int num5 = Mathff.Min(30, result);
					result -= num5;
					FreeResourceManager.inst.AddOrMakeAutoStackFor(merchantResourceItemUI.rID, num5, unloadPosition);
				}
			}
		}
		ship.RemoveFromHold(resourceAmount);
		if (num > 0)
		{
			float num6 = 0f;
			float[] discounts = GetDiscounts();
			for (int num7 = discounts.Length - 1; num7 >= 0; num7--)
			{
				if (!TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_shrewddealmaking") || num2 >= num7 * 50)
				{
					num6 = discounts[num7];
					break;
				}
			}
			int num8 = ((num6 < 0f) ? Mathf.FloorToInt((float)num * num6) : Mathf.CeilToInt((float)num * num6));
			num = Mathff.Max(1, num - num8);
			landmassOwner.Gold -= num;
			ResourceStatistics.AddConsumption(landmass, "trading", 4, num);
			RuntimeManager.PlayOneShot("event:/SFX ASITP/UI/ui_merchant_buyfrom");
		}
		RefreshBuyWindow();
	}

	public void RefreshSellWindow()
	{
		resourceUIPoolCount = 0;
		transactionLocalize.SetTerm("Sell");
		IResourceStorage loadingStorageComponent = ship.GetCurrentDock().loadingStorageComponent;
		ResourceAmount sellToPrice = ship.GetSellToPrice();
		List<FreeResourceSystem.ResourceDef> resourceDefs = FreeResourceSystem.inst.resourceDefs;
		for (int i = 0; i < resourceDefs.Count; i++)
		{
			FreeResourceSystem.ResourceDef resourceDef = resourceDefs[i];
			int amt = loadingStorageComponent.StoredPublicResources(resourceDef.ID);
			int value = 0;
			mShip.itemsSold.TryGetValue(resourceDef.ID, out value);
			if (amt <= 0)
			{
				continue;
			}
			amt = Mathff.Max(0, amt - value);
			int pay = sellToPrice.Get(resourceDef.ID);
			MerchantResourceItemUI itemUI = GetResourceItemUI();
			itemUI.rID = resourceDef.ID;
			itemUI.isSellAmountOffset = value > 0;
			Util.SetEnabled(itemUI.exclamationIcon, value > 0);
			itemUI.resourceTooltip.SetTerm(resourceDef.name);
			itemUI.resourceIcon.sprite = resourceDef.texture;
			itemUI.amtInput.SetTextWithoutNotify("0");
			itemUI.amtInput.interactable = amt > 0;
			itemUI.storageTMP.text = ((value > 0) ? "<color=#FFDB0F>" : "") + amt;
			itemUI.priceTMP.text = pay.ToString();
			itemUI.costTMP.text = "0";
			itemUI.amtInput.onEndEdit.AddListener((string str) =>
			{
				if (!int.TryParse(str, out var result))
				{
					itemUI.amtInput.SetTextWithoutNotify("0");
					result = 0;
				}
				result = Mathff.Min(result, amt);
				itemUI.amtInput.SetTextWithoutNotify(result.ToString());
				itemUI.costTMP.text = (pay * result).ToString();
				RefreshSellTotal();
			});
		}
		RefreshSellTotal();
		HideAccessResourceItems();
	}

	public void OnCompleteSellTransaction()
	{
		Dock currentDock = ship.GetCurrentDock();
		int landmass = currentDock.bi.LandMass();
		IResourceStorage loadingStorageComponent = currentDock.loadingStorageComponent;
		LandmassOwner landmassOwner = World.GetLandmassOwner(currentDock.bi.LandMass());
		ResourceAmount sellToPrice = ship.GetSellToPrice();
		int num = 0;
		ResourceAmount resourceAmount = new ResourceAmount();
		for (int i = 0; i < resourceUIPoolCount; i++)
		{
			MerchantResourceItemUI merchantResourceItemUI = resourceUIPool.data[i];
			if (int.TryParse(merchantResourceItemUI.amtInput.text, out var result) && result > 0)
			{
				resourceAmount.Add(merchantResourceItemUI.rID, result);
				num += result * sellToPrice.Get(merchantResourceItemUI.rID);
			}
		}
		if (num > 0)
		{
			ResourceStatistics.AddProduction(landmass, "trading", 4, num);
			ResourceStatistics.AddConsumption(landmass, "trading", resourceAmount);
			landmassOwner.Gold += num;
			ship.AddToHold(resourceAmount);
			loadingStorageComponent.RemoveResources(resourceAmount);
			RuntimeManager.PlayOneShot("event:/SFX ASITP/UI/ui_merchant_sellto");
		}
		RefreshSellWindow();
	}

	private void RefreshSellTotal()
	{
		int totalPrice = GetTotalPrice(ship.GetSellToPrice(), doDiscounts: false);
		LandmassOwner playerLandmassOwner = Player.inst.PlayerLandmassOwner;
		Util.SetActive(goldWarningObj, totalPrice + playerLandmassOwner.Gold > playerLandmassOwner.MaxGoldStorage);
		totalTMP.text = ScriptLocalization.Total + ": " + totalPrice + " <sprite name=icon_gold>";
	}

	private int GetTotalPriceRaw(ResourceAmount price, out int pendingCount, int rIDIgnore = -1)
	{
		int num = 0;
		pendingCount = 0;
		for (int i = 0; i < resourceUIPoolCount; i++)
		{
			MerchantResourceItemUI merchantResourceItemUI = resourceUIPool.data[i];
			if (merchantResourceItemUI.rID != rIDIgnore && int.TryParse(merchantResourceItemUI.amtInput.text, out var result))
			{
				int num2 = price.Get(merchantResourceItemUI.rID);
				num += result * num2;
				pendingCount += result;
			}
		}
		return num;
	}

	private float[] GetDiscounts()
	{
		float[] array = ((!TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_shrewddealmaking")) ? new float[1] : new float[3] { 0f, 0.1f, 0.2f });
		Governor.TraitInstance traitInstance = Player.inst.governors[ship.GetCurrentDock().bi.LandMass()]?.GetTrait(Traits.MerchantPrices);
		if (traitInstance != null)
		{
			for (int i = 0; i < array.Length; i++)
			{
				array[i] += (traitInstance.negative ? (0f - traitInstance.magnitude) : traitInstance.magnitude);
			}
		}
		return array;
	}

	private int TryGetDesiredAmount(int desiredAmt, ResourceAmount price, int rID)
	{
		int gold = Player.inst.PlayerLandmassOwner.Gold;
		int totalPriceRaw = GetTotalPriceRaw(price, out var pendingCount, rID);
		float[] discounts = GetDiscounts();
		for (int num = discounts.Length - 1; num >= 0; num--)
		{
			float num2 = discounts[num];
			float num3 = (float)totalPriceRaw - (float)totalPriceRaw * num2;
			float num4 = (float)gold - num3;
			float num5 = Mathf.Max(0f, num4 + num4 * num2);
			int num6 = Mathf.Min(desiredAmt, Mathf.FloorToInt(num5 / (float)price.Get(rID)));
			if (!TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_shrewddealmaking") || num6 + pendingCount >= num * 50)
			{
				return num6;
			}
		}
		return Mathf.FloorToInt((gold - totalPriceRaw) / price.Get(rID));
	}

	private int GetTotalPrice(ResourceAmount price, bool doDiscounts)
	{
		int num = 0;
		int num2 = 0;
		for (int i = 0; i < resourceUIPoolCount; i++)
		{
			MerchantResourceItemUI merchantResourceItemUI = resourceUIPool.data[i];
			if (int.TryParse(merchantResourceItemUI.amtInput.text, out var result))
			{
				int num3 = price.Get(merchantResourceItemUI.rID);
				num += result * num3;
				num2 += result;
			}
		}
		float num4 = 0f;
		if (doDiscounts)
		{
			string text = string.Empty;
			float num5 = 0f;
			float num6 = 0f;
			float[] discounts = GetDiscounts();
			int num7 = discounts.Length - 1;
			while (num7 >= 0)
			{
				float num8 = 0f;
				if (TechnologyTree.inst.IsTechnologyUnlocked("unlockkey_shrewddealmaking"))
				{
					if (num2 < num7 * 50)
					{
						num7--;
						continue;
					}
					switch (num7)
					{
					case 2:
						num8 = 0.2f;
						break;
					case 1:
						num8 = 0.1f;
						break;
					}
					num5 = (float)num * num8;
				}
				Governor.TraitInstance traitInstance = Player.inst.governors[ship.GetCurrentDock().bi.LandMass()]?.GetTrait(Traits.MerchantPrices);
				if (num5 > 0f || traitInstance != null)
				{
					text = text + string.Format(LocalizationManager.GetTranslation("merchantui_subtotal"), num) + Environment.NewLine;
				}
				if (num5 != 0f)
				{
					text = string.Format(ScriptLocalization.merchantui_buy_discount, Mathf.FloorToInt((0f - num8) * 100f), (traitInstance == null) ? Mathf.CeilToInt(num5) : Mathf.FloorToInt(num5));
				}
				if (traitInstance != null)
				{
					num6 = (float)num * (traitInstance.negative ? (0f - traitInstance.magnitude) : traitInstance.magnitude);
					if (num5 != 0f)
					{
						float num9 = num5 % 1f;
						Debug.Log(num9);
						num6 += num9;
						text += Environment.NewLine;
					}
					num6 = ((num6 < 0f) ? Mathf.FloorToInt(num6) : Mathf.CeilToInt(num6));
					text = ((!traitInstance.negative) ? (text + string.Format(LocalizationManager.GetTranslation("merchantui_buy_govenor_trait_positive_desc"), "#D6FF8E", (0f - traitInstance.magnitude) * 100f, 0f - num6)) : (text + string.Format(LocalizationManager.GetTranslation("merchantui_buy_govenor_trait_negative_desc"), "#FFA68D", "+" + traitInstance.magnitude * 100f, $"+{0f - num6}")));
				}
				num4 = discounts[num7];
				break;
			}
			discountTMP.text = text;
			Util.SetActive(discountObj, text != string.Empty);
		}
		else
		{
			Util.SetActive(discountObj, active: false);
		}
		float num10 = ((num4 < 0f) ? Mathf.FloorToInt(num4 * (float)num) : Mathf.CeilToInt(num4 * (float)num));
		return Mathf.CeilToInt((float)num - num10);
	}

	public void OnConsoleUpdate(bool isControllerActive)
	{
		closeBtn.gameObject.SetActive(!isControllerActive);
		consoleClose.SetActive(isControllerActive);
	}

	public void RefreshSpecialWindow()
	{
	}

	private void UpdateContainerVisuals()
	{
		if (ship == null)
		{
			SetVisibility(visible: false);
			return;
		}
		MerchantShip merchantShip = ship as MerchantShip;
		if (merchantShip == null)
		{
			return;
		}
		if (merchantShip.IsWaiting() && merchantShip.isTargetPlayerDock && !merchantShip.GetPathFailed())
		{
			SetTransactionVisibility(v: true);
			return;
		}
		SetTransactionVisibility(v: false);
		if (merchantShip.status == MerchantShip.Status.Leaving)
		{
			sailingLocalize.SetTerm("merchantui_sailing_leaving");
		}
		else if (merchantShip.status == MerchantShip.Status.SailingToDock)
		{
			sailingLocalize.SetTerm("merchantui_sailing_to_dock");
		}
	}

	private void Update()
	{
		if (isVisible)
		{
			UpdateContainerVisuals();
			if (hasStoppedEditingThisFrame)
			{
				hasStoppedEditingThisFrame = false;
			}
			else if (!isEditingInput && ConfigurableControls.inst.GetInputActionKeyDown(900))
			{
				SetVisibility(visible: false);
			}
		}
	}
}
