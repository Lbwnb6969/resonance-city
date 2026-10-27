using System;
using System.Collections.Generic;
using Assets;
using Assets.Code;
using Assets.Code.Jobs;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ConstructUI : MonoBehaviour
{
	public static ConstructUI inst;

	public RectTransform root;

	[SerializeField]
	private Canvas canvas;

	[SerializeField]
	private GraphicRaycaster gRaycaster;

	[SerializeField]
	private Slider constructProgressSlider;

	[SerializeField]
	private Slider resourceProgressSlider;

	[SerializeField]
	private GameObject clearLandWait;

	[SerializeField]
	private GameObject noBuilderError;

	[SerializeField]
	private TextMeshProUGUI remainingTitleTMP;

	[SerializeField]
	private TextMeshProUGUI resourceRemainingTMP;

	[SerializeField]
	private Button exitBtn;

	[SerializeField]
	private Button demolishBtn;

	[SerializeField]
	private TextMeshProUGUI buildingTitleTMP;

	[SerializeField]
	private TextMeshProUGUI buildersInfoTMP;

	[SerializeField]
	private Button buildersBtn;

	[SerializeField]
	private Toggle pauseToggle;

	[SerializeField]
	private Toggle playToggle;

	[SerializeField]
	private Button prioritizeBtn;

	[SerializeField]
	private TextMeshProUGUI statusTMP;

	[SerializeField]
	private RawImage prioritizeRI;

	[SerializeField]
	private TooltipHook demolishTooltip;

	[SerializeField]
	private GameObject materialsCheck;

	private ArrayExt<ISelectableBuilding> isPrioritized = new ArrayExt<ISelectableBuilding>(32);

	private ResourceAmount scratchAmount = new ResourceAmount();

	private bool isVisible;

	private ISelectableBuilding targetBuilding;

	private EditTerrainProject pendingTerrainProject;

	private float haltNoBuilderUICheckTime;

	private ArrayExt<Vector3> positionsScratch = new ArrayExt<Vector3>(50);

	public bool IsVisible()
	{
		return isVisible;
	}

	private void Awake()
	{
		inst = this;
		exitBtn.onClick.AddListener(() =>
		{
			SetVisibility(v: false);
		});
		demolishBtn.onClick.AddListener(() =>
		{
			World.inst.DemolishSelectedBuildingByPlayer();
		});
		buildersBtn.onClick.AddListener(FindBuildersButtonClicked);
		pauseToggle.onValueChanged.AddListener(OnPauseToggle);
		playToggle.onValueChanged.AddListener(OnPlayToggle);
		prioritizeBtn.onClick.AddListener(OnPrioritizeClicked);
		Player.onPlayerReset = (Player.OnPlayerEvent)Delegate.Combine(Player.onPlayerReset, new Player.OnPlayerEvent(OnPlayerReset));
		SetVisibility(v: false);
	}

	public void SetVisibility(bool v)
	{
		if (isVisible && !v)
		{
			targetBuilding = null;
		}
		else if (!isVisible & v)
		{
			CreativeUI.inst.SetVisibility(v: false);
		}
		Util.SetEnabled(canvas, v);
		Util.SetEnabled(gRaycaster, v);
		Util.SetEnabled(this, v);
		isVisible = v;
	}

	public void UpdateForNewSelection()
	{
		targetBuilding = GameUI.inst.GetGenericBuildingSelected();
		if (targetBuilding == null || !targetBuilding.UnderConstruction() || targetBuilding is Building { isDemolishing: not false })
		{
			if (targetBuilding != null && IsBuildingPrioritized(out var idx))
			{
				isPrioritized.RemoveAtSwap(idx);
			}
			SetVisibility(v: false);
			targetBuilding = null;
			return;
		}
		if (targetBuilding.ConstructionPaused())
		{
			statusTMP.enabled = true;
			pauseToggle.SetIsOnWithoutNotify(value: true);
		}
		else
		{
			statusTMP.enabled = false;
			playToggle.SetIsOnWithoutNotify(value: true);
		}
		EditTerrainProjectManager.inst.IsCellPartOfProject(World.inst.GetCellData(targetBuilding.Center()), out pendingTerrainProject);
		prioritizeRI.enabled = IsBuildingPrioritized(out var _);
		bool active = true;
		if (targetBuilding is IWorkerUIDisplay workerUIDisplay)
		{
			active = workerUIDisplay.ShowDemolish();
		}
		demolishBtn.gameObject.SetActive(active);
		SetVisibility(v: true);
	}

	public void Init()
	{
	}

	private void Update()
	{
		if (targetBuilding == null || targetBuilding.Equals(null) || GameUI.inst.GetGenericBuildingSelected() == null)
		{
			SetVisibility(v: false);
		}
		else if (ConfigurableControls.inst.GetInputActionKeyDownAndConsume(304))
		{
			Cell cell = null;
			if (targetBuilding is Building building)
			{
				cell = building.GetCell();
			}
			World.inst.DemolishSelectedBuildingByPlayer();
			if (cell != null)
			{
				for (int num = cell.OccupyingStructure.Count - 1; num >= 0; num--)
				{
					if (!cell.OccupyingStructure[num].isDemolishing)
					{
						GameUI.inst.SetSelectedBuildingNew(cell.OccupyingStructure[num], forceUpdate: true);
					}
				}
			}
			else
			{
				GameUI.inst.ClearCellSelected();
			}
			targetBuilding = null;
			SetVisibility(v: false);
		}
		else if (targetBuilding.UnderConstruction())
		{
			EditTerrainProjectManager.inst.IsCellPartOfProject(World.inst.GetCellData(targetBuilding.Center()), out pendingTerrainProject);
			float unscaledDeltaTime = Time.unscaledDeltaTime;
			ConstructionForeman.ConstructionSummary summary = default;
			targetBuilding.GetConstructionSummary(ref summary);
			MarkerDrawer.inst.Clear();
			List<Job> jobs = summary.jobs;
			for (int i = 0; i < jobs.Count; i++)
			{
				if (jobs[i].Employee != null)
				{
					MarkerDrawer.inst.AddPoint(jobs[i].Employee.Pos + new Vector3(0f, 0.5f, 0f));
				}
			}
			List<ClearCutterJob> clearLandJobs = summary.clearLandJobs;
			for (int j = 0; j < clearLandJobs.Count; j++)
			{
				if (clearLandJobs[j].Employee != null)
				{
					MarkerDrawer.inst.AddPoint(clearLandJobs[j].Employee.Pos + new Vector3(0f, 0.5f, 0f));
				}
			}
			MarkerDrawer.inst.Draw();
			bool flag = targetBuilding.BuildFootprintClear();
			Util.SetActive(clearLandWait.gameObject, !flag);
			Util.SetActive(materialsCheck.gameObject, summary.resourceProgress >= 1f);
			resourceProgressSlider.value = summary.resourceProgress;
			constructProgressSlider.value = summary.constructionProgress;
			buildingTitleTMP.text = summary.friendlyName;
			int workersAssigned = summary.workersAssigned;
			int totalWorkers = summary.totalWorkers;
			if (pendingTerrainProject != null && pendingTerrainProject != targetBuilding)
			{
				ConstructionForeman.ConstructionSummary summary2 = default;
				pendingTerrainProject.GetConstructionSummary(ref summary2);
				workersAssigned = summary2.workersAssigned;
				totalWorkers = summary2.totalWorkers;
			}
			buildersInfoTMP.text = $"{workersAssigned}/{totalWorkers}";
			ResourceAmount notCollected = summary.notCollected;
			notCollected.Set(4, 0);
			resourceRemainingTMP.text = notCollected.ToString(", ");
			remainingTitleTMP.text = (notCollected.IsNone() ? ScriptLocalization.ConstructUIFinishingUp : ScriptLocalization.ConstructUIWaitingFor);
			if (pendingTerrainProject != null)
			{
				remainingTitleTMP.text = LocalizationManager.GetTranslation("constructui_levelingforconstruction");
			}
			bool flag2 = targetBuilding.WorkersAssignedToClearFootprint();
			noBuilderError.SetActive(!summary.constructionPaused && World.inst.AvailableWorkersOnLandMass(targetBuilding.LandMass()) <= 0 && summary.workerPercent <= 0f && haltNoBuilderUICheckTime <= 0f && !flag2);
			haltNoBuilderUICheckTime -= unscaledDeltaTime;
			if (demolishBtn.gameObject.activeSelf)
			{
				demolishTooltip.toolTipText = BuildingDemolishUI.GetDemolishTooltip(scratchAmount, targetBuilding);
			}
		}
		else
		{
			targetBuilding = null;
			SetVisibility(v: false);
			GameUI.inst.UpdateVisibilityForSelectedCellUI();
			GameUI.inst.UpdateForNewSelection();
		}
	}

	public void OnPlayToggle(bool isOn)
	{
		if (isOn && targetBuilding != null && targetBuilding.UnderConstruction())
		{
			SfxSystem.PlayUiSelect();
			targetBuilding.UnpauseConstruction();
			haltNoBuilderUICheckTime = 0.3f;
			statusTMP.enabled = false;
		}
	}

	public void OnPauseToggle(bool isOn)
	{
		if (isOn && targetBuilding != null && targetBuilding.UnderConstruction())
		{
			SfxSystem.PlayUiSelect();
			targetBuilding.PauseConstruction();
			if (IsBuildingPrioritized(out var idx))
			{
				isPrioritized.RemoveAtSwap(idx);
				prioritizeRI.enabled = false;
			}
			statusTMP.enabled = true;
		}
	}

	public void OnPrioritizeClicked()
	{
		if (targetBuilding == null)
		{
			return;
		}
		if (targetBuilding.ConstructionPaused())
		{
			playToggle.isOn = true;
		}
		else
		{
			SfxSystem.PlayUiSelect();
		}
		if (IsBuildingPrioritized(out var idx))
		{
			prioritizeRI.enabled = false;
			isPrioritized.RemoveAtSwap(idx);
			return;
		}
		prioritizeRI.enabled = true;
		isPrioritized.Add(targetBuilding);
		ConstructionForeman.ConstructionSummary summary = default;
		targetBuilding.GetConstructionSummary(ref summary);
		List<Job> jobs = summary.jobs;
		int num = 0;
		bool flag = true;
		for (int i = 0; i < jobs.Count; i++)
		{
			if (jobs[i].HasEmployee())
			{
				num++;
			}
			if (!(jobs[i] is BuilderJob))
			{
				flag = false;
			}
		}
		if (!flag || num == jobs.Count)
		{
			return;
		}
		int num2 = targetBuilding.LandMass();
		if (!JobSystem.jobCategoriesMap.TryGetValue(1, out var value))
		{
			return;
		}
		ArrayExtRef<Job> arrayExtRef = value.jobs.data[num2];
		int num3 = arrayExtRef.Count - 1;
		for (int num4 = arrayExtRef.Count - 1; num4 >= 0; num4--)
		{
			if (!jobs.Contains(arrayExtRef.data[num4]))
			{
				if (num < jobs.Count && arrayExtRef.data[num4].HasEmployee())
				{
					arrayExtRef.data[num4].Employee.QuitJob();
					num++;
				}
				arrayExtRef.data[num3] = arrayExtRef.data[num4];
				num3--;
			}
		}
		for (int j = 0; j < jobs.Count; j++)
		{
			arrayExtRef.data[j] = jobs[j];
		}
	}

	private void FindBuildersButtonClicked()
	{
		if (targetBuilding == null)
		{
			return;
		}
		SfxSystem.PlayUiSelect();
		positionsScratch.ClearFast();
		ConstructionForeman.ConstructionSummary summary = default;
		targetBuilding.GetConstructionSummary(ref summary);
		List<Job> jobs = summary.jobs;
		for (int i = 0; i < jobs.Count; i++)
		{
			if (jobs[i].Employee != null)
			{
				positionsScratch.Add(jobs[i].Employee.Pos);
			}
		}
		Cam.inst.BringIntoView(targetBuilding.Center(), positionsScratch);
	}

	private void OnPlayerReset()
	{
		isPrioritized.ClearFast();
	}

	private bool IsBuildingPrioritized(out int idx)
	{
		idx = 0;
		if (targetBuilding == null)
		{
			return false;
		}
		while (idx < isPrioritized.Count)
		{
			if (isPrioritized.data[idx] == targetBuilding)
			{
				return true;
			}
			idx++;
		}
		return false;
	}
}
