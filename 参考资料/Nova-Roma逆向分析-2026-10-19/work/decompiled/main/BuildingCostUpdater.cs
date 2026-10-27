using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class BuildingCostUpdater : MonoBehaviour, BuildBuildingData
{
	public TextMeshProUGUI titleText;

	public TextMeshProUGUI costText;

	public GameObject buildingObject;

	public Light highlight;

	public Building PreReq;

	public Building prefab;

	public RectTransform infoMount;

	public Transform displayModel;

	public Button btn;

	public GameObject technologyUnlockIndicator;

	public BuildTab.OnButtonClicked onButtonClicked;

	private bool imActive;

	private bool isVisible;

	public float rotation;

	private float angleLerp;

	[HideInInspector]
	private const float inactiveAngle = -45f;

	[HideInInspector]
	private const float activeAngle = -30f;

	private bool _enabled = true;

	public GameObject SubMenuIndication;

	public float highlightLightIntensity = 1.8f;

	public float lightIntensity = 1.1f;

	public bool Enabled
	{
		get
		{
			return _enabled;
		}
		set
		{
			if (value && !_enabled)
			{
				highlight.enabled = true;
				btn.interactable = true;
				TextMeshProUGUI textMeshProUGUI = costText;
				Color color = (titleText.color = Color.white);
				textMeshProUGUI.color = color;
			}
			if (!value && _enabled)
			{
				highlight.enabled = false;
				btn.interactable = false;
				TextMeshProUGUI textMeshProUGUI2 = costText;
				Color color = (titleText.color = new Color(0.9f, 0.9f, 0.9f, 0.7f));
				textMeshProUGUI2.color = color;
			}
			_enabled = value;
		}
	}

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		if (v)
		{
			technologyUnlockIndicator.SetActive(value: true);
		}
		gameObject.SetActive(v);
		isVisible = v;
	}

	public Building GetBuilding()
	{
		return buildingObject.GetComponent<Building>();
	}

	public bool IsEnabled()
	{
		return Enabled;
	}

	private void Awake()
	{
		EventTrigger componentInParent = GetComponentInParent<EventTrigger>();
		EventTrigger.Entry entry = new EventTrigger.Entry();
		entry.eventID = EventTriggerType.PointerDown;
		entry.callback.AddListener((BaseEventData eventData) =>
		{
			OnPointerDown();
		});
		componentInParent.triggers.Add(entry);
		EventTrigger.Entry entry2 = new EventTrigger.Entry();
		entry2.eventID = EventTriggerType.PointerEnter;
		entry2.callback.AddListener((BaseEventData eventData) =>
		{
			OnPointerEnter();
		});
		componentInParent.triggers.Add(entry2);
		EventTrigger.Entry entry3 = new EventTrigger.Entry();
		entry3.eventID = EventTriggerType.Submit;
		entry3.callback.AddListener((BaseEventData eventData) =>
		{
			OnPointerDown();
		});
		componentInParent.triggers.Add(entry3);
		EventTrigger.Entry entry4 = new EventTrigger.Entry();
		entry4.eventID = EventTriggerType.PointerExit;
		entry4.callback.AddListener((BaseEventData eventData) =>
		{
			OnPointerExit();
		});
		componentInParent.triggers.Add(entry4);
		EventTrigger.Entry entry5 = new EventTrigger.Entry();
		entry5.eventID = EventTriggerType.Cancel;
		entry5.callback.AddListener((BaseEventData eventData) =>
		{
			GameUI.inst.ReturnToDefaultCursorMode();
		});
		componentInParent.triggers.Add(entry5);
	}

	private bool IsSubMenu()
	{
		if (!prefab.GetComponent<StatueBuildDummy>() && !prefab.GetComponent<CemeteryBuildDummy>())
		{
			return prefab.UniqueName == World.parkDummyName;
		}
		return true;
	}

	private void OnPointerDown()
	{
		if (Enabled)
		{
			onButtonClicked?.Invoke(this);
		}
	}

	private void OnPointerEnter()
	{
	}

	private void OnPointerExit()
	{
		BuildInfoFloating.inst.DeferredHide();
		imActive = false;
	}

	private void OnDisable()
	{
		imActive = false;
	}

	private void Update()
	{
		if (Player.inst != null)
		{
			Building component = buildingObject.GetComponent<Building>();
			bool flag = Player.inst.FocusedResources.HasCost(component.GetCost(Player.inst.FocusedLandMass));
			Enabled = (flag && PreReq == null) || (PreReq != null && Player.inst.DoesAnyBuildingHaveUniqueNameOnPlayerLandMass(PreReq.UniqueName, mustBeBuilt: true));
			if (imActive)
			{
				highlight.intensity = highlightLightIntensity;
			}
			else
			{
				highlight.intensity = lightIntensity;
			}
			int num = 30;
			if (flag && imActive)
			{
				angleLerp = Mathf.Clamp01(angleLerp + Time.unscaledDeltaTime * 4.5f);
				num = 55;
			}
			else
			{
				angleLerp = Mathf.Clamp01(angleLerp - Time.unscaledDeltaTime * 4.5f);
			}
			if (!_enabled)
			{
				num = 12;
			}
			rotation += Time.unscaledDeltaTime * (float)num;
			displayModel.rotation = Quaternion.Euler(Mathf.Lerp(-45f, -30f, angleLerp), 0f, 0f);
			displayModel.Rotate(Vector3.up, rotation);
			if (rotation > 360f)
			{
				rotation -= 360f;
			}
		}
	}

	public void ResetDisplayModelRotation()
	{
		rotation = 45f;
		displayModel.rotation = Quaternion.Euler(-45f, 0f, 0f);
		displayModel.Rotate(Vector3.up, rotation);
		SubMenuIndication.SetActive(IsSubMenu());
	}
}
