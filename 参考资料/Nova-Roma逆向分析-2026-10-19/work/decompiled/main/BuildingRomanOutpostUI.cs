using System;
using TMPro;
using UnityEngine;

public class BuildingRomanOutpostUI : MonoBehaviour
{
	public static BuildingRomanOutpostUI inst;

	[SerializeField]
	private TextMeshProUGUI storageTMP;

	private Building building;

	private Keep keep;

	private void Awake()
	{
		inst = this;
	}

	public void SetVisibility(bool v)
	{
		Util.SetActive(gameObject, v);
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || (keep = b.GetComponent<Keep>()) == null)
		{
			SetVisibility(v: false);
			return;
		}
		building = b;
		RefreshVisuals();
		SetVisibility(v: true);
	}

	public void OnDeselected()
	{
		building = null;
		keep = null;
	}

	public void RefreshVisuals()
	{
		string text = "";
		text = text + $"<link={0}><sprite name=icon_wheat></link> {keep.foodStack.Count()}/{keep.foodStack.MaxCapacity()}" + Environment.NewLine;
		text = text + $"<link={9}><sprite name=icon_apples></link> {keep.appleStack.Count()}/{keep.appleStack.MaxCapacity()}" + Environment.NewLine;
		text = text + $"<link={1}><sprite name=icon_wood></link> {keep.woodStack.Count()}/{keep.woodStack.MaxCapacity()}" + Environment.NewLine;
		text += $"<link={2}><sprite name=icon_stone></link> {keep.stoneStack.Count()}/{keep.stoneStack.MaxCapacity()}";
		storageTMP.text = text;
	}

	private void Update()
	{
		if (building == null || keep == null)
		{
			SetVisibility(v: false);
		}
		else
		{
			RefreshVisuals();
		}
	}
}
