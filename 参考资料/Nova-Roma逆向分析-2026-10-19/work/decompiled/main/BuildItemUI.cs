using System;
using FMODUnity;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using cakeslice;

public class BuildItemUI : MonoBehaviour
{
	public Button btn;

	public TextMeshProUGUI titleTMP;

	public Transform modelContainer;

	[SerializeField]
	private Light light;

	[SerializeField]
	private EventTrigger eventTrigger;

	[SerializeField]
	private GameObject unlockedObj;

	[SerializeField]
	private GameObject subGroupObj;

	[SerializeField]
	private RectTransform infoAnchor;

	[SerializeField]
	private GameObject highlightImg;

	[NonSerialized]
	public bool isHovered;

	[NonSerialized]
	public float hovering;

	[NonSerialized]
	public float rotating;

	[NonSerialized]
	public BuildUI.BuildGroup.BuildItem item;

	[NonSerialized]
	public BuildUI.BuildGroup group;

	private bool isVisible = true;

	private static float yRot = 33f;

	private static int pulseFrame = -1;

	private static float pulseFillBase;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void Init(BuildUI.BuildGroup.BuildItem item)
	{
		this.item = item;
		titleTMP.GetComponent<Localize>().SetTerm(item.prefab.GetFriendlyNameTerm);
		subGroupObj.SetActive(item.type == 1);
		MeshFilter[] array = null;
		Transform transform = null;
		if (item.prefab.DisplayModel != null)
		{
			array = item.prefab.DisplayModel.GetComponentsInChildren<MeshFilter>();
			transform = item.prefab.DisplayModel.transform;
		}
		else
		{
			array = new MeshFilter[1] { item.prefab.transform.GetComponentInChildren<MeshFilter>() };
			transform = item.prefab.transform.GetChild(0);
		}
		for (int i = 0; i < array.Length; i++)
		{
			if (array[i].gameObject.activeSelf)
			{
				GameObject gameObject = new GameObject(array[i].transform.name);
				gameObject.layer = LayerMask.NameToLayer("UI");
				Vector3 localPosition = array[i].transform.position - transform.position;
				gameObject.transform.SetParent(modelContainer, worldPositionStays: false);
				gameObject.transform.localPosition = localPosition;
				gameObject.transform.localRotation = array[i].transform.rotation;
				gameObject.transform.localScale = array[i].transform.lossyScale;
				MeshFilter meshFilter = gameObject.AddComponent<MeshFilter>();
				MeshRenderer meshRenderer = gameObject.AddComponent<MeshRenderer>();
				if (array[i].GetComponent<MeshRenderer>().sharedMaterial.shader.name == "Custom/Building")
				{
					meshRenderer.sharedMaterial = World.inst.romeUnimaterialNoSnow;
				}
				else
				{
					meshRenderer.sharedMaterial = array[i].GetComponent<MeshRenderer>().sharedMaterial;
				}
				meshFilter.sharedMesh = array[i].sharedMesh;
			}
		}
		modelContainer.localScale = item.scale * 1.25f;
		btn.onClick.AddListener(() =>
		{
			if (!item.isEnabled)
			{
				BuildInfoFloating.inst.dismissed = false;
				BuildInfoFloating.inst.PointAt(infoAnchor, item.prefab, item.preqPrefab);
				if (Player.inst.FocusedLandMass == -1)
				{
					BuildInfoFloating.inst.StartFlicker(1);
				}
				else if (!item.isPreqPassed)
				{
					BuildInfoFloating.inst.StartFlicker(2);
				}
				else if (!item.isAffordable)
				{
					BuildInfoFloating.inst.StartFlicker(0);
				}
				RuntimeManager.PlayOneShot("event:/SFX ASITP/UI/ui_upgrade_select");
			}
			else if (item.type == 0)
			{
				GameUI.inst.OnBuild(item.prefab);
			}
			else if (item.type == 1)
			{
				BuildUI.inst.ShowGroup(item.groupName);
			}
			else if (item.type == 2)
			{
				item.onCustomSelected?.Invoke();
			}
		});
		EventTrigger.Entry entry = new EventTrigger.Entry();
		entry.eventID = EventTriggerType.PointerEnter;
		entry.callback.AddListener((BaseEventData bData) =>
		{
			if (!BuildUI.inst.IsAnimating())
			{
				isHovered = true;
				BuildInfoFloating.inst.PointAt(infoAnchor, item.prefab, item.preqPrefab);
				unlockedObj.SetActive(value: false);
				BuildUI.inst.OnHoveredUnlock(item.prefab.UniqueName);
			}
		});
		eventTrigger.triggers.Add(entry);
		entry = new EventTrigger.Entry();
		entry.eventID = EventTriggerType.PointerExit;
		entry.callback.AddListener((BaseEventData bData) =>
		{
			isHovered = false;
			BuildInfoFloating.inst.DeferredHide();
		});
		eventTrigger.triggers.Add(entry);
	}

	public void SetVisibility(bool v)
	{
		gameObject.SetActive(v);
		isVisible = v;
	}

	public void UpdateVisuals(float udt)
	{
		float num;
		if (item.isEnabled)
		{
			num = ((!item.isAffordable || !item.isPreqPassed || !isHovered) ? 20f : 30f);
		}
		else
		{
			num = 8f;
		}
		float num2 = num;
		hovering = Mathff.Clamp01(hovering + (isHovered ? udt : (0f - udt)) * 5f);
		if (isHovered)
		{
			rotating = Mathf.Repeat(rotating + udt * num2, 360f);
		}
		else
		{
			rotating = 0f;
		}
		modelContainer.rotation = Quaternion.Euler(Mathf.Lerp(-33f, -25f, hovering), 0f, 0f) * Quaternion.AngleAxis(yRot + rotating, Vector3.up);
		Util.SetEnabled(light, item.isEnabled);
		Util.SetActive(highlightImg, isHovered);
		if (!isHovered)
		{
			return;
		}
		if (item.type == 1)
		{
			BuildUI.BuildGroup buildGroup = BuildUI.inst.GetGroup(item.groupName);
			if (buildGroup != null)
			{
				for (int i = 0; i < buildGroup.items.Count; i++)
				{
					if (buildGroup.items[i].prefab != null)
					{
						OutlineBuiltInstances(buildGroup.items[i].prefab);
					}
				}
			}
		}
		else
		{
			OutlineBuiltInstances(item.prefab);
		}
		DriveFillPulse();
	}

	private static void DriveFillPulse()
	{
		OutlineEffect instance = OutlineEffect.Instance;
		if (!(instance == null))
		{
			if (pulseFrame < 0)
			{
				pulseFillBase = instance.fillAmount2;
			}
			pulseFrame = Time.frameCount;
			float t = 0.5f + 0.5f * Mathf.Sin(Time.unscaledTime * 5f);
			instance.fillAmount2 = Mathf.Lerp(0.1f, 0.6f, t);
		}
	}

	public static void RestoreFillPulse()
	{
		if (pulseFrame >= 0 && Time.frameCount > pulseFrame)
		{
			OutlineEffect instance = OutlineEffect.Instance;
			if (instance != null)
			{
				instance.fillAmount2 = pulseFillBase;
			}
			pulseFrame = -1;
		}
	}

	private static void OutlineBuiltInstances(Building prefab)
	{
		string uniqueName = prefab.UniqueName;
		if (uniqueName == World.roadName || uniqueName == World.stoneRoadName || uniqueName == World.woodBridgeName || uniqueName == World.stoneBridgeName || uniqueName == World.drawBridgeName)
		{
			return;
		}
		if (prefab.UniqueName == World.aqueductDummyName)
		{
			for (int i = 0; i < AqueductLine.allLines.Count; i++)
			{
				if (AqueductLine.allLines[i].highlight != null)
				{
					AqueductLine.allLines[i].SetOutlineImmediate(0);
				}
			}
			return;
		}
		if (prefab.UniqueName == World.transportCartName)
		{
			ArrayExt<LogisticCart> logisticCarts = LogisticsManager.inst.logisticCarts;
			for (int j = 0; j < logisticCarts.Count; j++)
			{
				logisticCarts.data[j].SetHighlightImmediate(0);
			}
			return;
		}
		ArrayExt<Building> buildingList = Player.inst.GetBuildingList(prefab.UniqueName);
		for (int k = 0; k < buildingList.Count; k++)
		{
			if (FogOfWar.inst.IsVisible(buildingList.data[k].Center()))
			{
				buildingList.data[k].SetOutlineImmediate(0);
			}
		}
	}

	public void SetUnlockedVisuals(bool v)
	{
		Util.SetActive(unlockedObj, v);
	}
}
