using System.Collections.Generic;
using Assets;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class WorkerUI : UIWindowBase
{
	private enum ShowType
	{
		Workers,
		Residents
	}

	public static WorkerUI inst;

	public BuildingInfoUI infoUI;

	public BuildingHealthUI healthUI;

	public BuildingHappinessUI happinessUI;

	public BuildingProductionUI productionUI;

	public BuildingTaxUI taxUI;

	public BuildingMarketUI marketUI;

	public SpillwayUI spillwayUI;

	public AqueductBuildingWaterFlowUI aqueductBuildingFlowUI;

	public WaterConsumptionUI waterConsumptionUI;

	public BuildingDemolishUI demolishUI;

	public BuildingBathUI bathUI;

	public BuildingRubbleUI rubbleUI;

	public BuildingRadiusBonusUI radiusBonusUI;

	public BuildingRadiusHealthBonusUI radiusHealthBonusUI;

	public BuildingRomanOutpostUI outpostUI;

	public BuildingBarracksUI barracksUI;

	public AqueductWaterChartUI aqueductWaterChartUI;

	public RiverTapCapacityUI riverTapCapacityUI;

	public CommuteUI commuteUI;

	public BuildingChariotRaceTrackUI chariotRaceTrackUI;

	public BuildingStockpileUI stockpileUI;

	public BuildingLogisticsUI logisticsUI;

	public BuildingDockUI dockUI;

	public StorageTabUI storageTabUI;

	public BuildingCemeteryUI cemeteryUI;

	public GameObject workerUI;

	public GameObject findVillagersButton;

	public VillagerListUI villagerListUi;

	public TextMeshProUGUI personDesc;

	public GameObject close;

	public GameObject consoleClose;

	private ISelectableBuilding building;

	private IWorkerUIElement[] uiElements;

	private bool deferTitleTextInteractibleFalse;

	private ShowType showType;

	private ArrayExt<Vector3> positionsScratch = new ArrayExt<Vector3>(50);

	private IResidence residenceCache;

	private IWorkerUIDisplay workerUIDisplayCache;

	private Home homeCache;

	private bool isHome;

	private bool isSetupComplete;

	private int prevWorkers = -1;

	private int prevResidents = -1;

	private void Awake()
	{
		inst = this;
		findVillagersButton.GetComponent<Button>().onClick.AddListener(() =>
		{
			FindWorkersButtonClicked();
		});
	}

	private void OnEnable()
	{
		if (GameUI.inst != null && GameUI.inst.GetGenericBuildingSelected() != null)
		{
			UpdateForNewSelection();
		}
	}

	public override void SetVisible(bool v)
	{
		if (!v && visible && GamepadControl.inst.isControllerActive)
		{
			GameUI.inst.ClearCellSelected();
			ConsoleTileUI.inst.SetVisible(v: false);
		}
		base.SetVisible(v);
	}

	public void UpdateConsoleUI(bool isControllerActive)
	{
	}

	private void FindWorkersButtonClicked()
	{
		SfxSystem.PlayUiSelect();
		showType = ShowType.Workers;
		positionsScratch.ClearFast();
		if (this.building == null || !(this.building is Building { jobs: var jobs }))
		{
			return;
		}
		for (int i = 0; i < jobs.Count; i++)
		{
			if (jobs[i].Employee != null)
			{
				positionsScratch.Add(jobs[i].Employee.Pos);
			}
		}
		Cam.inst.BringIntoView(this.building.Center(), positionsScratch);
	}

	private void FindResidentsButtonClicked()
	{
		SfxSystem.PlayUiSelect();
		showType = ShowType.Residents;
		if (this.building == null || !(this.building is Building building))
		{
			return;
		}
		IResidence component = building.GetComponent<IResidence>();
		if (component != null)
		{
			List<Villager> residents = component.GetResidents();
			positionsScratch.ClearFast();
			for (int i = 0; i < residents.Count; i++)
			{
				positionsScratch.Add(residents[i].Pos);
			}
			Cam.inst.BringIntoView(this.building.Center(), positionsScratch);
		}
	}

	public void Shutdown()
	{
		Object.Destroy(workerUI);
	}

	public void SetWorkerCounts(int workers, int maxWorkers)
	{
		personDesc.text = string.Format(ScriptLocalization.WorkerUIWorkers, workers, maxWorkers);
	}

	public void SetResidentCounts(int residents, int maxResidents)
	{
		personDesc.text = string.Format(ScriptLocalization.WorkerUIResidents, residents, maxResidents);
	}

	private void ResetAll()
	{
	}

	public void TryShow()
	{
		if (uiElements == null)
		{
			uiElements = transform.GetComponentsInChildren<IWorkerUIElement>(includeInactive: true);
		}
		for (int i = 0; i < uiElements.Length; i++)
		{
			uiElements[i].TryShow();
		}
	}

	public void UpdateForNewSelection()
	{
		if (uiElements == null)
		{
			uiElements = transform.GetComponentsInChildren<IWorkerUIElement>(includeInactive: true);
		}
		for (int i = 0; i < uiElements.Length; i++)
		{
			uiElements[i].UpdateForNewSelection();
		}
		residenceCache = null;
		workerUIDisplayCache = null;
		building = GameUI.inst.GetGenericBuildingSelected();
		if (building != null && !building.UnderConstruction())
		{
			World.IsAILandmass(building.LandMass());
			if (building is Component component)
			{
				residenceCache = component.GetComponent<IResidence>();
				workerUIDisplayCache = component.GetComponent<IWorkerUIDisplay>();
				homeCache = component.GetComponent<Home>();
			}
			isHome = building.CategoryHash() == World.houseCategoryHash;
			villagerListUi.SetDataSource((building as Component).gameObject, residenceCache != null);
			Building b = building as Building;
			infoUI.OnBuildingSelected(b, building);
			healthUI.OnBuildingSelected(b);
			happinessUI.OnBuildingSelected(b);
			productionUI.OnBuildingSelected(b);
			taxUI.OnBuildingSelected(b);
			marketUI.OnBuildingSelected(b);
			spillwayUI.OnBuildingSelected(b);
			aqueductBuildingFlowUI.OnBuildingSelected(b);
			waterConsumptionUI.OnBuildingSelected(b);
			demolishUI.OnBuildingSelected(building);
			bathUI.OnBuildingSelected(b);
			rubbleUI.OnBuildingSelected(b);
			radiusBonusUI.OnBuildingSelected(b);
			radiusHealthBonusUI.OnBuildingSelected(b);
			outpostUI.OnBuildingSelected(b);
			barracksUI.OnBuildingSelected(b);
			aqueductWaterChartUI.OnBuildingSelected(building);
			riverTapCapacityUI.OnBuildingSelected(building);
			chariotRaceTrackUI.OnBuildingSelected(b);
			storageTabUI.OnBuildingSelected(b);
			cemeteryUI.OnBuildingSelected(b);
			stockpileUI.OnBuildingSelected(b);
			logisticsUI.OnBuildingSelected(b);
			dockUI.OnBuildingSelected(b);
		}
		if (isHome)
		{
			showType = ShowType.Residents;
		}
		else
		{
			showType = ShowType.Workers;
		}
		UpdateLayout();
	}

	private void OnDisable()
	{
		isSetupComplete = false;
		infoUI.OnDeselected();
		healthUI.OnDeselected();
		happinessUI.OnDeselected();
		productionUI.OnDeselected();
		taxUI.OnDeselected();
		marketUI.OnDeselected();
		spillwayUI.OnDeselected();
		aqueductBuildingFlowUI.OnDeselected();
		waterConsumptionUI.OnDeselected();
		demolishUI.OnDeselected();
		bathUI.OnDeselected();
		rubbleUI.OnDeselected();
		radiusBonusUI.OnDeselected();
		radiusHealthBonusUI.OnDeselected();
		outpostUI.OnDeselected();
		barracksUI.OnDeselected();
		aqueductWaterChartUI.OnDeselected();
		riverTapCapacityUI.OnDeselected();
		chariotRaceTrackUI.OnDeselected();
		dockUI.OnDeselected();
		stockpileUI.OnDeselected();
		logisticsUI.OnDeselected();
		cemeteryUI.OnDeselected();
	}

	public override void UpdateInternal(float dt)
	{
		base.UpdateInternal(dt);
		this.building = GameUI.inst.GetGenericBuildingSelected();
		if (this.building == null)
		{
			SetVisible(v: false);
		}
		else
		{
			if (this.building == null || !(this.building is Building building))
			{
				return;
			}
			MarkerDrawer.inst.Clear();
			if (isHome)
			{
				if (prevResidents != homeCache.Residents.Count)
				{
					SetResidentCounts(homeCache.Residents.Count, homeCache.MaxResidents);
					prevResidents = homeCache.Residents.Count;
				}
			}
			else if (building.WorkersForFullYield > 0 && prevWorkers != building.WorkersAllocated)
			{
				SetWorkerCounts(building.WorkersAllocated, building.WorkersForFullYield);
				prevWorkers = building.WorkersAllocated;
			}
			if (showType == ShowType.Workers)
			{
				for (int i = 0; i < building.jobs.Count; i++)
				{
					if (building.jobs[i].Employee != null)
					{
						TryAddMarkerPos(building.jobs[i].Employee);
					}
				}
			}
			else if (showType == ShowType.Residents && residenceCache != null)
			{
				List<Villager> residents = residenceCache.GetResidents();
				for (int j = 0; j < residents.Count; j++)
				{
					TryAddMarkerPos(residents[j]);
				}
			}
			MarkerDrawer.inst.Draw();
			if (!isSetupComplete && GamepadControl.inst.isControllerActive && (!isHome || (isHome && residenceCache.GetResidents().Count == 0)))
			{
				isSetupComplete = true;
				GetComponent<ConsoleUIItem>().Hover();
			}
		}
	}

	private void TryAddMarkerPos(Villager employee)
	{
		MarkerDrawer.inst.AddPoint(employee.GetPosWithOffset() + new Vector3(0f, 0.5f, 0f));
	}

	public void UpdateLayout()
	{
		this.building = GameUI.inst.GetGenericBuildingSelected();
		bool flag = false;
		bool flag2 = true;
		if (this.building != null)
		{
			flag = World.IsAILandmass(this.building.LandMass());
			if (this.building is Building building)
			{
				bool flag3 = building.WorkersForFullYield > 0;
				bool flag4 = false;
				if (!flag3)
				{
					flag2 = false;
				}
				else if (isHome)
				{
					SetResidentCounts(homeCache.Residents.Count, homeCache.MaxResidents);
					prevResidents = homeCache.Residents.Count;
					flag4 = true;
				}
				else if (building.WorkersForFullYield > 0)
				{
					SetWorkerCounts(building.WorkersAllocated, building.WorkersForFullYield);
					prevWorkers = building.WorkersAllocated;
					flag4 = true;
					if (building.WorkersForFullYield <= 0)
					{
						flag2 = false;
					}
				}
				personDesc.gameObject.SetActive(flag4 && !flag);
			}
			else
			{
				flag2 = false;
				personDesc.gameObject.SetActive(value: false);
			}
		}
		if (flag)
		{
			flag2 = false;
		}
		if (villagerListUi.gameObject.activeSelf != flag2)
		{
			villagerListUi.gameObject.SetActive(flag2);
		}
	}
}
