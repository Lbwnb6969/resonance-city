using System;
using I2.Loc;
using TMPro;
using UnityEngine;

public class PopulationUI : MonoBehaviour
{
	public static PopulationUI inst;

	public GameObject cityFullMarker;

	public ExplanationUI populationCountUI;

	public ExplanationUI bedCountUI;

	public ExplanationUI idleCountUI;

	public TextMeshProUGUI workerTextUI;

	public TextMeshProUGUI freeWorkerTextUI;

	public TextMeshProUGUI freeWorkerTextLabel;

	public TextMeshProUGUI totalResidentialTextUI;

	public RegionNameUI regionName;

	private EventHandler<OnBuildingAddRemove> addRemoveEventHandler;

	private EventHandler<OnBuildingBuilt> builtEventHandler;

	private int cachedResidentialSlots;

	private int lastWorkerCount = -1;

	private int lastFreeWorkerCount = -1;

	private int prevFocusedLandmass = -1;

	private void Start()
	{
		inst = this;
		populationCountUI.explanationDelegate = GetPopulationExplanation;
		bedCountUI.explanationDelegate = GetBedExplanation;
		idleCountUI.explanationDelegate = GetIdleExplanation;
	}

	private void OnEnable()
	{
		prevFocusedLandmass = -2;
	}

	private string GetBedExplanation()
	{
		string text = "";
		int focusedLandMass = Player.inst.FocusedLandMass;
		if (focusedLandMass != -1)
		{
			text = text + ScriptLocalization.populationui_beds_description + "\n\n";
			if (cachedResidentialSlots <= World.inst.GetVillagersForLandMass(focusedLandMass).Count)
			{
				text = text + "<color=yellow><b>" + ScriptLocalization.populationui_error_cityfull + "</b></color>\n\n";
			}
		}
		return text;
	}

	private string GetIdleExplanation()
	{
		int num = World.inst.AvailableWorkersOnLandMass(Player.inst.FocusedLandMass);
		string text = "";
		text = text + "<b>" + ScriptLocalization.Idle + "</b>\n";
		text = text + ScriptLocalization.populationui_idle_description + "\n";
		if (num <= 0)
		{
			text = text + ScriptLocalization.populationui_idle_fullemployment + "\n\n";
			text = text + "<color=yellow><b>" + ScriptLocalization.populationui_idle_needmoreworkers + "</b></color>";
		}
		return text;
	}

	private string GetPopulationExplanation()
	{
		string text = "";
		int focusedLandMass = Player.inst.FocusedLandMass;
		if (focusedLandMass != -1 && cachedResidentialSlots <= World.inst.GetVillagersForLandMass(focusedLandMass).Count)
		{
			text = text + "<color=yellow><b>" + ScriptLocalization.populationui_error_cityfull + "</b></color>\n\n";
		}
		text += ScriptLocalization.populationui_immigrant_desc1;
		return text + "\n\n" + ScriptLocalization.populationui_immigrant_desc2;
	}

	private void BuildingAddRemove(object sender, OnBuildingAddRemove obj)
	{
		if (obj.targetBuilding.LandMass() == prevFocusedLandmass && obj.targetBuilding.categoryHash == World.houseCategoryHash)
		{
			UpdateResidentialSlots();
		}
	}

	private void BuildingBuilt(object sender, OnBuildingBuilt obj)
	{
		if (obj.targetBuilding.LandMass() == prevFocusedLandmass && obj.targetBuilding.categoryHash == World.houseCategoryHash)
		{
			UpdateResidentialSlots();
		}
	}

	public void UpdateResidentialSlots()
	{
		if (Player.inst.FocusedLandMass != -1)
		{
			cachedResidentialSlots = Player.inst.TotalResidentialSlotsOnLandMass(Player.inst.FocusedLandMass);
			totalResidentialTextUI.SetText("{0}", cachedResidentialSlots);
		}
	}

	private void Update()
	{
		if (LoadSave.Loading)
		{
			return;
		}
		bool active = false;
		if (Player.inst.FocusedLandMass != -1)
		{
			if (Player.inst.FocusedLandMass != prevFocusedLandmass)
			{
				UpdateResidentialSlots();
			}
			Util.TrySetText(workerTextUI, "{0}", World.inst.GetVillagersForLandMass(Player.inst.FocusedLandMass).Count, ref lastWorkerCount);
			Util.TrySetText(freeWorkerTextUI, "{0}", World.inst.AvailableWorkersOnLandMass(Player.inst.FocusedLandMass), ref lastFreeWorkerCount);
			int count = World.inst.GetVillagersForLandMass(Player.inst.FocusedLandMass).Count;
			if (cachedResidentialSlots <= count)
			{
				totalResidentialTextUI.color = Color.yellow;
				if (!bedCountUI.explanationUI.gameObject.activeSelf && cachedResidentialSlots >= 15)
				{
					active = true;
				}
			}
			else
			{
				totalResidentialTextUI.color = Color.white;
			}
		}
		Util.SetActive(cityFullMarker, active);
		prevFocusedLandmass = Player.inst.FocusedLandMass;
	}

	internal void InitListeners()
	{
		addRemoveEventHandler = Broadcast.BuildingAddRemove.ListenAny(BuildingAddRemove);
		builtEventHandler = Broadcast.BuildingBuilt.ListenAny(BuildingBuilt);
	}
}
