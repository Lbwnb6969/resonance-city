using System;
using Assets.Code;
using Assets.Code.UI;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class EditTerrainUI : UIWindowBase
{
	public static EditTerrainUI inst;

	public EditTerrainCursorMode cursorMode;

	public TextMeshProUGUI tempStateText;

	public Transform windowDesc;

	public float workToGoldMultiplier = 7f;

	public Confirmation closeConfirmation;

	[SerializeField]
	private Toggle[] ToolToggles;

	[SerializeField]
	private Slider CrewSize_Slider;

	[SerializeField]
	private TMP_InputField CrewSize_Input;

	private const int MIN_CREW_SIZE = 1;

	private const int MAX_CREW_SIZE = 50;

	[SerializeField]
	public float workToCrewSizeMultiplier = 10f;

	[SerializeField]
	private Slider BrushSize_Slider;

	[SerializeField]
	private TMP_InputField BrushSize_Input;

	private const int MIN_BRUSH_SIZE = 1;

	private const int MAX_BRUSH_SIZE = 10;

	private const int DEFAULT_BRUSH_SIZE = 2;

	[SerializeField]
	private Slider DirtOMeter_Slider;

	[SerializeField]
	private Button StartProject_Button;

	[SerializeField]
	private TextMeshProUGUI StartProject_ButtonText;

	[SerializeField]
	private Button Exit_Button;

	[SerializeField]
	public Button undoButton;

	[SerializeField]
	public Button resetWaterButton;

	[SerializeField]
	private GameObject CostContainer;

	[SerializeField]
	private TextMeshProUGUI CostAmount;

	[SerializeField]
	private GameObject CostError;

	[SerializeField]
	private Slider WaterSimTimeUserSlider;

	[SerializeField]
	private Slider WaterSimTimeVisualSlider;

	[SerializeField]
	private float WaterSimMaxTime = 10f;

	[SerializeField]
	private float WaterSimMinTime = 2f;

	[SerializeField]
	private float WaterSimStartTime = 5f;

	private Timer waterResetTimer = new Timer(5f);

	private int crewSize = 1;

	private bool userHasSetCrewSize;

	private int currentTool;

	private int brushSize = 1;

	private EditTerrainProject project;

	private ResourceAmount projectCost = new ResourceAmount();

	private float[] terrainState;

	private DynamicWater.DynamicWaterSaveData waterState;

	public void Awake()
	{
		inst = this;
		TryInitCursorMode();
		CrewSize_Input.SetTextWithoutNotify("1");
		CrewSize_Input.onEndEdit.AddListener(OnCrewSizeInputChanged);
		CrewSize_Slider.SetValueWithoutNotify(1f);
		CrewSize_Slider.value = 1f;
		CrewSize_Slider.wholeNumbers = true;
		CrewSize_Slider.minValue = 1f;
		CrewSize_Slider.maxValue = 50f;
		CrewSize_Slider.onValueChanged.AddListener(OnCrewSizeSliderChanged);
		BrushSize_Input.SetTextWithoutNotify("1");
		BrushSize_Input.onEndEdit.AddListener(OnBrushSizeInputChanged);
		BrushSize_Slider.SetValueWithoutNotify(1f);
		BrushSize_Slider.value = 1f;
		BrushSize_Slider.wholeNumbers = true;
		BrushSize_Slider.minValue = 1f;
		BrushSize_Slider.maxValue = 10f;
		BrushSize_Slider.onValueChanged.AddListener(OnBrushSizeSliderChanged);
		DirtOMeter_Slider.SetValueWithoutNotify(0f);
		DirtOMeter_Slider.interactable = false;
		WaterSimTimeUserSlider.minValue = 0f;
		WaterSimTimeUserSlider.maxValue = WaterSimMaxTime;
		WaterSimTimeVisualSlider.minValue = 0f;
		WaterSimTimeVisualSlider.maxValue = WaterSimMaxTime;
		WaterSimTimeUserSlider.onValueChanged.AddListener(OnWaterSimTimeUserSliderChanged);
		WaterSimTimeUserSlider.SetValueWithoutNotify(WaterSimStartTime);
		StartProject_Button.onClick.AddListener(OnStartProject);
		for (int i = 0; i < ToolToggles.Length; i++)
		{
			int p = i;
			ToolToggles[i].onValueChanged.AddListener((bool isOn) =>
			{
				OnToolToggleChanged(isOn, p);
			});
		}
		Exit_Button.onClick.AddListener(OnExit);
		if (undoButton != null)
		{
			undoButton.onClick.AddListener(OnUndo);
		}
		if (resetWaterButton != null)
		{
			resetWaterButton.onClick.AddListener(OnResetWater);
		}
	}

	private void OnResetWater()
	{
		ResetWaterState();
	}

	private void OnUndo()
	{
		cursorMode.PerformUndo();
	}

	private void OnWaterSimTimeUserSliderChanged(float t)
	{
		if (t < WaterSimMinTime)
		{
			t = WaterSimMinTime;
		}
		WaterSimTimeUserSlider.onValueChanged.RemoveListener(OnWaterSimTimeUserSliderChanged);
		WaterSimTimeUserSlider.value = t;
		WaterSimTimeUserSlider.onValueChanged.AddListener(OnWaterSimTimeUserSliderChanged);
	}

	private void OnExit()
	{
		AskToClose();
	}

	private void OnToolToggleChanged(bool isOn, int id)
	{
		if (isOn)
		{
			cursorMode.currentTool = id;
			SfxSystem.PlayUiSelect();
		}
	}

	private void OnStartProject()
	{
		cursorMode.GetChangeData(out var points, out var _, out var ends);
		ResetTerrainState();
		ResetWaterState();
		project.SetCost(projectCost);
		project.Init(points, ends, crewSize, tightRails: false, showFences: true);
		MilestoneManager.inst.TryFirstTerrainProjectMilestone();
		SetVisible(v: false);
	}

	private void OnCrewSizeInputChanged(string str)
	{
		int result = 0;
		if (int.TryParse(str, out result))
		{
			result = Mathff.Clamp(result, 1, 50);
			CrewSize_Slider.SetValueWithoutNotify(result);
			CrewSize_Input.SetTextWithoutNotify(result.ToString());
			SetCrewSize(result);
		}
	}

	private void OnCrewSizeSliderChanged(float val)
	{
		int num = Mathf.RoundToInt(val);
		CrewSize_Input.SetTextWithoutNotify(num.ToString());
		CrewSize_Slider.SetValueWithoutNotify(num);
		SetCrewSize(num);
	}

	private void SetCrewSize(int size)
	{
		crewSize = size;
		userHasSetCrewSize = true;
	}

	private void OnBrushSizeInputChanged(string str)
	{
		int result = 0;
		if (int.TryParse(str, out result))
		{
			result = Mathff.Clamp(result, 1, 10);
			BrushSize_Slider.SetValueWithoutNotify(result);
			BrushSize_Input.SetTextWithoutNotify(result.ToString());
			SetBrushSize(result);
		}
	}

	private void OnBrushSizeSliderChanged(float val)
	{
		int num = Mathf.RoundToInt(val);
		BrushSize_Input.SetTextWithoutNotify(num.ToString());
		BrushSize_Slider.SetValueWithoutNotify(num);
		SetBrushSize(num);
	}

	private void SetBrushSize(int size)
	{
		brushSize = size;
		cursorMode.brushSize = size;
	}

	public void OnDestroy()
	{
	}

	public void OnClickedClose()
	{
		ResetTerrainState();
		ResetWaterState();
		SetVisible(v: false);
		SfxSystem.PlayUiCancel();
	}

	private void TryInitCursorMode()
	{
		if (cursorMode == null)
		{
			cursorMode = new EditTerrainCursorMode();
		}
	}

	private void OnDisable()
	{
	}

	public override void UpdateInternal(float dt)
	{
		base.UpdateInternal(dt);
		float workAmount = cursorMode.GetWorkAmount();
		projectCost.Set(4, Mathf.FloorToInt(Mathff.Abs(workAmount * workToGoldMultiplier)));
		if (Creative.inst.IsCreativeOptionOn(0))
		{
			projectCost.Set(4, 0);
		}
		if (cursorMode.updateWork)
		{
			if (!userHasSetCrewSize)
			{
				int num = Mathf.Clamp(Mathf.FloorToInt(Mathff.Abs(workAmount * workToCrewSizeMultiplier)), 1, 50);
				CrewSize_Slider.SetValueWithoutNotify(num);
				CrewSize_Input.SetTextWithoutNotify(num.ToString());
				crewSize = num;
			}
			cursorMode.updateWork = false;
		}
		bool flag = Player.inst.FocusedResources.HasCost(projectCost);
		CostAmount.text = projectCost.NeedCost(Player.inst.FocusedResources);
		bool flag2 = projectCost.Get(4) == 0;
		if (CostContainer.gameObject.activeSelf == flag2)
		{
			CostContainer.gameObject.SetActive(!flag2);
		}
		Util.SetActive(CostError, !flag);
		StartProject_Button.interactable = flag && Mathf.Abs(workAmount) > 0.1f;
		if (undoButton != null)
		{
			undoButton.interactable = cursorMode.CanUndo;
		}
		if (Input.GetKeyDown(KeyCode.LeftShift) || Input.GetKeyUp(KeyCode.LeftShift))
		{
			if (cursorMode.currentTool == 0)
			{
				OnToolToggleChanged(isOn: true, 1);
			}
			else if (cursorMode.currentTool == 1)
			{
				OnToolToggleChanged(isOn: true, 0);
			}
			else if (cursorMode.currentTool == 2)
			{
				OnToolToggleChanged(isOn: true, 3);
			}
			else if (cursorMode.currentTool == 3)
			{
				OnToolToggleChanged(isOn: true, 2);
			}
		}
		if (cursorMode.TryingToQuit)
		{
			cursorMode.TryingToQuit = false;
			AskToClose();
		}
		tempStateText.text = "";
	}

	public void AskToClose()
	{
		closeConfirmation.ShowConfirmation(CloseConfirmed, CloseCancelled);
	}

	public void CloseCancelled()
	{
	}

	public void CloseConfirmed()
	{
		OnClickedClose();
	}

	public void ResetTerrainState()
	{
		float[] heightCache = TerrainGen.inst.heightCache;
		int num = int.MaxValue;
		int num2 = int.MaxValue;
		int num3 = int.MinValue;
		int num4 = int.MinValue;
		for (int i = 0; i < heightCache.Length; i++)
		{
			if (terrainState[i] != heightCache[i])
			{
				int num5 = i % World.MeshWidth;
				int num6 = i / World.MeshWidth;
				if (num5 < num)
				{
					num = num5;
				}
				if (num5 > num3)
				{
					num3 = num5;
				}
				if (num6 < num2)
				{
					num2 = num6;
				}
				if (num6 > num4)
				{
					num4 = num6;
				}
			}
		}
		Array.Copy(terrainState, TerrainGen.inst.heightCache, TerrainGen.inst.heightCache.Length);
		TerrainGen.inst.FinalizeChanges();
		if (num3 >= num)
		{
			TerrainRockReclassifier.ReclassifyVertRect(num, num2, num3, num4);
		}
	}

	public void ResetWaterState()
	{
		if (waterState != null)
		{
			DynamicWater.inst.RestoreState(waterState);
		}
	}

	public override void SetVisible(bool v)
	{
		if (Visible && !v)
		{
			WorldMask.inst.Deactivate();
			if (GameUI.inst.currCursorMode == cursorMode)
			{
				GameUI.inst.ReturnToDefaultCursorMode();
			}
			World.inst.HideResourceTooltipUIs();
			GodManager.inst.EnsureMinCooldown(5f);
		}
		if (v)
		{
			TimeManager.inst.SetLocked(val: true);
		}
		else if (!v && visible)
		{
			TimeManager.inst.SetLocked(val: false);
		}
		base.SetVisible(v);
		if (v)
		{
			GameUI.inst.SetCursorMode(cursorMode);
			userHasSetCrewSize = false;
			crewSize = 1;
			CrewSize_Slider.SetValueWithoutNotify(1f);
			CrewSize_Input.SetTextWithoutNotify(1.ToString());
			brushSize = 2;
			cursorMode.brushSize = 2;
			BrushSize_Slider.SetValueWithoutNotify(2f);
			BrushSize_Input.SetTextWithoutNotify(2.ToString());
			BrushSize_Slider.interactable = true;
			BrushSize_Input.interactable = true;
			CreativeUI.inst.SetWindowVisibility(v: false);
			waterState = DynamicWater.inst.SaveState();
			terrainState = new float[World.MeshWidth * World.MeshHeight];
			Array.Copy(TerrainGen.inst.heightCache, terrainState, TerrainGen.inst.heightCache.Length);
			cursorMode.SetOriginalHeightsCache(terrainState);
			cursorMode.ClearUndoHistory();
			project = EditTerrainProject.CreateNewEmptyProject();
			currentTool = 0;
			cursorMode.currentTool = 0;
			if (ToolToggles.Length != 0)
			{
				ToolToggles[0].isOn = true;
			}
		}
		TerrainGen.inst.EditTerrainSimulateOn(v);
		DynamicWater.inst.EditTerrainSimulateOn(v);
		DynamicWater.inst.waterfallParticleManager.SimulationMode(v);
	}

	private void OnEnable()
	{
	}
}
