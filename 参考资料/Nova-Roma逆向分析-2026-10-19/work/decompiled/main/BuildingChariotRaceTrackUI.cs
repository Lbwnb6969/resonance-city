using UnityEngine;
using UnityEngine.UI;

public class BuildingChariotRaceTrackUI : MonoBehaviour
{
	private Building building;

	private ChariotRaceTrack raceTrack;

	[SerializeField]
	private Button beginRaceBettingBtn;

	[SerializeField]
	private TooltipHook btnTooltip;

	private bool isVisible;

	public bool IsVisible()
	{
		return isVisible;
	}

	public void SetVisibility(bool v)
	{
		Util.SetActive(gameObject, v);
		isVisible = v;
	}

	private void Start()
	{
		beginRaceBettingBtn.onClick.AddListener(OnBeginRaceBetting);
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || (raceTrack = b.GetComponent<ChariotRaceTrack>()) == null)
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
		raceTrack = null;
		SetVisibility(v: false);
	}

	private void Update()
	{
		if (isVisible && !(building == null) && !(raceTrack == null))
		{
			RefreshVisuals();
		}
	}

	public void RefreshVisuals()
	{
		bool flag = building.GetWorkerPercent() >= 1f;
		bool flag2 = flag && building.IsOnFire();
		beginRaceBettingBtn.interactable = flag && !flag2;
		if (!flag)
		{
			btnTooltip.tooltipTerm = "NeedsFullStaff";
		}
		else if (flag2)
		{
			btnTooltip.tooltipTerm = "Fire Risk";
		}
		else
		{
			btnTooltip.tooltipTerm = string.Empty;
		}
	}

	private void OnBeginRaceBetting()
	{
		GameUI.inst.SetCursorModeChariotRace();
	}
}
