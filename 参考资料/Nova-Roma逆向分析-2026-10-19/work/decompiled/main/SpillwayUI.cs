using System;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SpillwayUI : MonoBehaviour
{
	public TextMeshProUGUI percent;

	public Slider slider;

	public Slider arrowSlider;

	public Spillover spilloverBuilding;

	public GameObject tickPrefab;

	private GameObject[] ticks = new GameObject[0];

	private bool damPlannerMode;

	private Action<Spillover, float> onHeightChangedCallback;

	public RectTransform tickSpreadStart;

	public RectTransform tickSpreadEnd;

	public void Start()
	{
		slider.onValueChanged.AddListener(SliderChanged);
	}

	public void InitForDamPlanner(Spillover spillover, Action<Spillover, float> onHeightChanged)
	{
		spilloverBuilding = spillover;
		damPlannerMode = true;
		onHeightChangedCallback = onHeightChanged;
		SetVisibility(isVisible: true);
	}

	public void SliderChanged(float value)
	{
		if (!(spilloverBuilding == null))
		{
			if (damPlannerMode)
			{
				spilloverBuilding.spillwayOpenPercentDesired = Mathf.Clamp01(value);
				spilloverBuilding.spillwayOpenPercentCurrent = spilloverBuilding.spillwayOpenPercentDesired;
				spilloverBuilding.UpdateSpillwayDoor();
				TerrainGen.inst.RecalcWaterObstructionForArea(spilloverBuilding.b.cachedCell.x, spilloverBuilding.b.cachedCell.z, 1, 1);
				onHeightChangedCallback?.Invoke(spilloverBuilding, value);
			}
			else
			{
				spilloverBuilding.SetSpilloverHeight = value;
			}
			UpdateHeightText();
		}
	}

	private void UpdateHeightText()
	{
		float spillwayWorldHeight = GetSpillwayWorldHeight();
		percent.text = $"{spillwayWorldHeight * 10f:F1}m";
	}

	private float GetSpillwayWorldHeight()
	{
		if (spilloverBuilding == null || spilloverBuilding.topBlock == null || spilloverBuilding.topBlock.WaterObstructionActive == null || spilloverBuilding.topBlock.WaterObstructionActive.Length == 0)
		{
			return 0f;
		}
		float a = TerrainGen.inst.heightCache[spilloverBuilding.meshIndexForDoor];
		float y = spilloverBuilding.topBlock.WaterObstructionActive[0].transform.position.y;
		return Mathf.Lerp(a, y, spilloverBuilding.spillwayOpenPercentDesired);
	}

	public void SetVisibility(bool isVisible)
	{
		gameObject.SetActive(isVisible);
		if (isVisible)
		{
			Refresh();
		}
	}

	public void Refresh()
	{
		if (!(spilloverBuilding == null))
		{
			slider.SetValueWithoutNotify(spilloverBuilding.spillwayOpenPercentDesired);
			arrowSlider.SetValueWithoutNotify(spilloverBuilding.spillwayOpenPercentCurrent);
			UpdateHeightText();
			RebuildTicks();
		}
	}

	public void RebuildTicks()
	{
		for (int i = 0; i < ticks.Length; i++)
		{
			UnityEngine.Object.Destroy(ticks[i]);
		}
		Canvas.ForceUpdateCanvases();
		float[] tickPercentages = spilloverBuilding.GetTickPercentages();
		List<GameObject> list = new List<GameObject>();
		Vector3 localPosition = tickSpreadStart.localPosition;
		Vector3 localPosition2 = tickSpreadEnd.localPosition;
		for (int j = 0; j < tickPercentages.Length; j++)
		{
			GameObject gameObject = UnityEngine.Object.Instantiate(tickPrefab, slider.transform);
			Vector3 vector = Vector3.Lerp(localPosition, localPosition2, tickPercentages[j]);
			gameObject.transform.localPosition = new Vector3(vector.x, vector.y, 0f);
			gameObject.SetActive(value: true);
			list.Add(gameObject);
		}
		ticks = list.ToArray();
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || (spilloverBuilding = b.GetComponent<Spillover>()) == null)
		{
			SetVisibility(isVisible: false);
			return;
		}
		RefreshVisuals();
		SetVisibility(isVisible: true);
	}

	public void OnDeselected()
	{
		spilloverBuilding = null;
	}

	private void Update()
	{
		if (!(spilloverBuilding == null))
		{
			RefreshVisuals();
		}
	}

	private void RefreshVisuals()
	{
		if (damPlannerMode)
		{
			arrowSlider.SetValueWithoutNotify(spilloverBuilding.spillwayOpenPercentDesired);
		}
		else
		{
			arrowSlider.SetValueWithoutNotify(spilloverBuilding.spillwayOpenPercentCurrent);
		}
	}
}
