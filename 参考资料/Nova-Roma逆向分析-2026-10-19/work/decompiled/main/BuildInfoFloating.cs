using System;
using Assets.Code;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class BuildInfoFloating : MonoBehaviour
{
	[Serializable]
	public class Flicker
	{
		public RawImage rawImage;

		public Color baseColor;

		public Color highlightColor;

		[NonSerialized]
		public int status;

		[NonSerialized]
		public float time;

		public float speed = 5f;

		[NonSerialized]
		public int count;

		public int maxCount = 3;
	}

	public static BuildInfoFloating inst;

	[SerializeField]
	private RectTransform rootRectT;

	[SerializeField]
	private RectTransform arrowRectT;

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	[SerializeField]
	private RectTransform canvasRectT;

	[SerializeField]
	private TextMeshProUGUI titleTMP;

	[SerializeField]
	private TextMeshProUGUI sizeTMP;

	[SerializeField]
	private TextMeshProUGUI descriptionTMP;

	[SerializeField]
	private TextMeshProUGUI prerequisiteTMP;

	[SerializeField]
	private TextMeshProUGUI workersTMP;

	[SerializeField]
	private TextMeshProUGUI producesTMP;

	[SerializeField]
	private TextMeshProUGUI residentsTMP;

	[SerializeField]
	private TextMeshProUGUI storesTMP;

	[SerializeField]
	private GameObject costContainer;

	[SerializeField]
	private TextMeshProUGUI costTMP;

	[SerializeField]
	private GameObject costError;

	[SerializeField]
	private GameObject descriptionDivider;

	[SerializeField]
	private GameObject errorContainer;

	[SerializeField]
	private TextMeshProUGUI errorTMP;

	[SerializeField]
	private GameObject preqContainer;

	[SerializeField]
	private Button exitBtn;

	private Color tempColor;

	private const int FLICKER_NONE = 0;

	private const int FLICKER_EASE_OUT = 1;

	private const int FlICKER_EASE_IN = 2;

	private const int FLICKER_PING_PONG = 3;

	public const int COST_FLICKER = 0;

	public const int OCEAN_FOCUS_FLICKER = 1;

	public const int PREQ_FLICKER = 2;

	public Flicker[] flickers;

	[NonSerialized]
	public bool dismissed;

	private bool isVisible;

	private Timer hideTimer = new Timer(0.25f);

	private RectTransform mountRectT;

	private Building targetBuilding;

	private Building targetPrereq;

	public void StartFlicker(int idx)
	{
		Flicker flicker = flickers[idx];
		flicker.time = 0f;
		flicker.count = 0;
		flicker.rawImage.color = flicker.baseColor;
		flicker.status = 2;
	}

	public void StopFlickers()
	{
		for (int i = 0; i < flickers.Length; i++)
		{
			flickers[i].time = 0f;
			flickers[i].count = 0;
			flickers[i].rawImage.color = flickers[i].baseColor;
			flickers[i].status = 0;
		}
	}

	private void Awake()
	{
		inst = this;
		exitBtn.onClick.AddListener(() =>
		{
			dismissed = true;
			SetVisibility(v: false);
			SfxSystem.PlayUiCancel();
		});
		SetVisibility(v: false);
	}

	public void SetVisibility(bool v)
	{
		enabled = v;
		Util.SetEnabled(canvas, v);
		gRaycaster.enabled = v;
		if (!v)
		{
			targetBuilding = null;
			targetPrereq = null;
			StopFlickers();
			hideTimer.Enabled = false;
			hideTimer.Reset();
		}
		isVisible = v;
	}

	public void DeferredHide()
	{
		hideTimer.Enabled = true;
	}

	public void OnPointerEnter()
	{
		if (GameUI.inst.CurrPlacementMode.IsPlacing())
		{
			SetVisibility(v: false);
		}
		else
		{
			hideTimer.Enabled = false;
		}
	}

	public void OnPointerExit()
	{
		hideTimer.Enabled = true;
		hideTimer.Reset();
	}

	public void PointAt(RectTransform mount, Building b, Building prereq = null)
	{
		if (dismissed)
		{
			return;
		}
		hideTimer.Reset();
		hideTimer.Enabled = false;
		targetBuilding = b;
		targetPrereq = prereq;
		mountRectT = mount;
		titleTMP.text = b.FriendlyName;
		workersTMP.text = "<b>" + LocalizationManager.GetTranslation("WorkersColon") + "</b> " + b.WorkersForFullYield;
		workersTMP.gameObject.SetActive(b.WorkersForFullYield > 0);
		sizeTMP.text = $"{b.size.x}x{b.size.z}";
		descriptionTMP.text = b.Description;
		if (prereq != null)
		{
			if (Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass(prereq.UniqueName, mustBeBuilt: false) || BuildUI.inst.BuildingPreq.Contains(b.UniqueName))
			{
				prerequisiteTMP.text = "";
			}
			else
			{
				prerequisiteTMP.text = "<b>" + ScriptLocalization.RequiresColon + "</b> <color=#ff6863>" + prereq.FriendlyName;
			}
			preqContainer.SetActive(value: true);
		}
		else
		{
			preqContainer.SetActive(value: false);
		}
		IProductionInfo component = b.GetComponent<IProductionInfo>();
		if (!component.IsNull() && b.UniqueName != World.coppiceName)
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
			producesTMP.text = text;
			producesTMP.gameObject.SetActive(value: true);
		}
		else
		{
			producesTMP.gameObject.SetActive(value: false);
		}
		IStorageInfo component2 = b.GetComponent<IStorageInfo>();
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
			storesTMP.text = text2;
			storesTMP.gameObject.SetActive(value: true);
		}
		else
		{
			storesTMP.gameObject.SetActive(value: false);
		}
		IResidence component3 = b.GetComponent<IResidence>();
		if (!component3.IsNull())
		{
			residentsTMP.text = "<b>" + LocalizationManager.GetTranslation("ResidentsColon") + "</b> " + component3.GetTotalResidentialSlots();
			residentsTMP.gameObject.SetActive(value: true);
		}
		else
		{
			residentsTMP.gameObject.SetActive(value: false);
		}
		descriptionDivider.SetActive(producesTMP.gameObject.activeSelf || preqContainer.activeSelf || workersTMP.gameObject.activeSelf);
		StopFlickers();
		RefreshVisuals(b);
		SetVisibility(v: true);
	}

	private void RefreshVisuals(Building b)
	{
		if (b == null)
		{
			return;
		}
		ResourceAmount baseCost = b.GetBaseCost();
		costContainer.SetActive(!baseCost.IsNone());
		int focusedLandMass = Player.inst.FocusedLandMass;
		if (focusedLandMass == -1)
		{
			costTMP.text = baseCost.NeedCost(ResourceAmount.empty);
			errorTMP.text = ScriptLocalization.BuildInfoFocusOverLand;
			errorContainer.SetActive(value: true);
			costError.SetActive(value: false);
			return;
		}
		errorContainer.SetActive(value: false);
		if (Creative.inst.IsCreativeOptionOn(0))
		{
			costTMP.text = b.GetBaseCost().ToString();
			costError.SetActive(value: false);
			return;
		}
		ResourceAmount focusedResources = Player.inst.FocusedResources;
		ResourceAmount cost = b.GetCost(focusedLandMass);
		costTMP.text = cost.NeedCost(focusedResources, "    ");
		costError.SetActive(!focusedResources.HasCost(cost));
	}

	private void Update()
	{
		float unscaledDeltaTime = Time.unscaledDeltaTime;
		if (hideTimer.Enabled && hideTimer.Update(unscaledDeltaTime))
		{
			SetVisibility(v: false);
		}
		RefreshVisuals(targetBuilding);
		Vector2 sizeDelta = canvasRectT.sizeDelta;
		Vector3 position = mountRectT.position;
		rootRectT.position = position;
		arrowRectT.position = position;
		Vector2 anchoredPosition = rootRectT.anchoredPosition;
		Vector2 sizeDelta2 = rootRectT.sizeDelta;
		float num = anchoredPosition.x + sizeDelta2.x / 2f;
		float num2 = anchoredPosition.x - sizeDelta2.x / 2f;
		Vector2 vector = new Vector2(0f, 0f);
		if (num >= sizeDelta.x)
		{
			vector.x = sizeDelta.x - num;
		}
		else if (num2 <= 0f)
		{
			vector.x = 0f - num2 + 5f;
		}
		rootRectT.anchoredPosition += vector;
		for (int i = 0; i < flickers.Length; i++)
		{
			Flicker flicker = flickers[i];
			switch (flicker.status)
			{
			case 2:
				flicker.time += unscaledDeltaTime * flicker.speed;
				tempColor = Color.Lerp(flicker.baseColor, flicker.highlightColor, flicker.time);
				flicker.rawImage.color = tempColor;
				if (flicker.time >= 1f)
				{
					flicker.status = 3;
					flicker.time = 0f;
				}
				break;
			case 3:
				flicker.time += unscaledDeltaTime * flicker.speed;
				tempColor = Color.Lerp(flicker.highlightColor, flicker.baseColor, Mathf.PingPong(flicker.time, 1f));
				flicker.rawImage.color = tempColor;
				if (flicker.time >= 2f)
				{
					flicker.count++;
					flicker.time -= 2f;
					if (flicker.count == flicker.maxCount)
					{
						flicker.status = 1;
						flicker.time = 0f;
					}
				}
				break;
			case 1:
				flicker.time += unscaledDeltaTime * flicker.speed;
				tempColor = Color.Lerp(flicker.highlightColor, flicker.baseColor, flicker.time);
				flicker.rawImage.color = tempColor;
				if (flicker.time >= 1f)
				{
					flicker.time = 0f;
					flicker.status = 0;
				}
				break;
			}
		}
	}

	public static bool CanAfford(int landMass, ResourceAmount amount)
	{
		if (landMass == -1)
		{
			return false;
		}
		bool flag = false;
		ResourceAmount resourceAmount = Player.inst.resourcesPerLandmass[landMass];
		for (int i = 0; i < amount.resources.Count; i++)
		{
			int amount2 = amount.resources[i].Amount;
			if (resourceAmount.Get(amount.resources[i].resourceID) - amount2 < 0 && amount2 > 0)
			{
				flag = true;
			}
		}
		return !flag;
	}
}
