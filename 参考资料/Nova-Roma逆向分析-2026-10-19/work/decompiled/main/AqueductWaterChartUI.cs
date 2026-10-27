using System.Collections.Generic;
using I2.Loc;
using TMPro;
using UnityEngine;

public class AqueductWaterChartUI : MonoBehaviour
{
	[SerializeField]
	private GameObject chartContainer;

	[SerializeField]
	private TextMeshProUGUI titleText;

	[SerializeField]
	private TextMeshProUGUI flowText;

	[SerializeField]
	private TextMeshProUGUI lengthText;

	[SerializeField]
	private TextMeshProUGUI noWaterErrorText;

	[SerializeField]
	private RectTransform chartArea;

	[SerializeField]
	private GameObject waterPointPrefab;

	[SerializeField]
	private MeshFilter chartMeshFilter;

	[SerializeField]
	private Material waterMaterialReference;

	[SerializeField]
	private TextMeshProUGUI utilizationText;

	[SerializeField]
	private TextMeshProUGUI axisLabelBottom;

	[SerializeField]
	private TextMeshProUGUI axisLabelMid;

	[SerializeField]
	private TextMeshProUGUI axisLabelTop;

	private static readonly int[] ScaleLadder = new int[6] { 5, 10, 25, 50, 100, 250 };

	private const float SCALE_DOWN_HYSTERESIS = 0.85f;

	private float currentScale = 5f;

	private float currentUtilizationPct;

	public const float UTILIZATION_WARNING_PCT = 80f;

	public const float UTILIZATION_ERROR_PCT = 95f;

	private Color utilizationNormalColor;

	private bool utilizationColorCaptured;

	private AqueductLine selectedAqueductLine;

	private bool isVisible;

	private TooltipHook chartTooltip;

	private Dictionary<AqueductLine.WaterFlowStateTransitionNodes, GameObject> transitionNodeToChartElement = new Dictionary<AqueductLine.WaterFlowStateTransitionNodes, GameObject>();

	public Mesh chartMesh;

	private List<Vector3> meshVertices = new List<Vector3>();

	private List<int> meshTriangles = new List<int>();

	private List<Vector2> meshUVs = new List<Vector2>();

	private ThoughtBubbleSystem.ThoughtMaskHandle waterMaskHandle;

	public void SetVisibility(bool isVisible)
	{
		this.isVisible = isVisible;
		if (chartContainer != null)
		{
			chartContainer.SetActive(isVisible);
		}
		if (isVisible)
		{
			if (waterMaskHandle == null)
			{
				waterMaskHandle = ThoughtBubbleSystem.inst.PushMask(ThoughtBubbleSystem.ThoughtCategory.Water);
			}
		}
		else
		{
			ThoughtBubbleSystem.inst.PopMask(ref waterMaskHandle);
		}
	}

	public void OnBuildingSelected(ISelectableBuilding building)
	{
		selectedAqueductLine = null;
		if (building != null && building is AqueductLine aqueductLine)
		{
			selectedAqueductLine = aqueductLine;
		}
		if (selectedAqueductLine != null && selectedAqueductLine.fullyConstructed)
		{
			SetVisibility(isVisible: true);
			InitializeChart();
		}
		else
		{
			SetVisibility(isVisible: false);
		}
	}

	public void OnDeselected()
	{
		selectedAqueductLine = null;
		SetVisibility(isVisible: false);
		ClearChart();
	}

	private void Update()
	{
		if (!isVisible || !(selectedAqueductLine != null))
		{
			return;
		}
		if (selectedAqueductLine == null || selectedAqueductLine.collapse)
		{
			OnDeselected();
			return;
		}
		AqueductBuilding startBuilding = selectedAqueductLine.GetStartBuilding();
		AqueductBuilding endBuilding = selectedAqueductLine.GetEndBuilding();
		if (startBuilding != null)
		{
			HeightMarker.Show(startBuilding);
		}
		if (endBuilding != null)
		{
			HeightMarker.Show(endBuilding);
		}
		UpdateChart();
		UpdateWaterTextureScroll();
		UpdateChartTooltip();
	}

	private void InitializeChart()
	{
		ClearChart();
		InitializeMesh();
		SetupChartTooltip();
		if (titleText != null)
		{
			titleText.text = LocalizationManager.GetTranslation("workerui_aqueductui_waterflowtitle");
		}
		UpdateScaleAndStats(snap: true);
		UpdateSummaryText();
		UpdateChartMesh();
	}

	private void InitializeMesh()
	{
		if (chartMesh == null)
		{
			chartMesh = new Mesh();
			chartMesh.name = "AqueductWaterChart";
		}
	}

	private void UpdateChart()
	{
		if (selectedAqueductLine?.waterFlowStateTransitionNodes != null)
		{
			bool flag = HasWaterInAqueduct();
			if (noWaterErrorText != null)
			{
				noWaterErrorText.gameObject.SetActive(!flag);
			}
			UpdateScaleAndStats(snap: false);
			UpdateSummaryText();
			UpdateChartMesh();
		}
	}

	private void UpdateChartMesh()
	{
		if (!(chartArea == null))
		{
			GenerateRectangleMesh();
			ApplyMeshToImage();
		}
	}

	private void GenerateRectangleMesh()
	{
		meshVertices.Clear();
		meshTriangles.Clear();
		meshUVs.Clear();
		if (selectedAqueductLine == null)
		{
			return;
		}
		Rect rect = chartArea.rect;
		float width = rect.width;
		float height = rect.height;
		List<(float, float)> list = new List<(float, float)>();
		float num = 0f;
		num = ((selectedAqueductLine.waterFlowStateTransitionNodes.Count <= 0) ? selectedAqueductLine.currentOutputFlow : selectedAqueductLine.waterFlowStateTransitionNodes[0].waterAmount);
		num = Mathf.Min(num, AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS);
		list.Add((0f, num));
		if (selectedAqueductLine.waterFlowStateTransitionNodes != null)
		{
			foreach (AqueductLine.WaterFlowStateTransitionNodes waterFlowStateTransitionNode in selectedAqueductLine.waterFlowStateTransitionNodes)
			{
				float item = waterFlowStateTransitionNode.T * width;
				float item2 = Mathf.Min(waterFlowStateTransitionNode.waterAmount, AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS);
				list.Add((item, item2));
			}
		}
		float item3 = Mathf.Min(selectedAqueductLine.currentOutputFlow, AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS);
		list.Add((width, item3));
		for (int i = 0; i < list.Count - 1; i++)
		{
			(float, float) tuple = list[i];
			(float, float) tuple2 = list[i + 1];
			var (num2, _) = tuple;
			var (num3, _) = tuple2;
			Mathf.Clamp(tuple.Item2 / currentScale * height, 0f, height);
			float num4 = Mathf.Clamp(tuple2.Item2 / currentScale * height, 0f, height);
			int count = meshVertices.Count;
			float num5 = num4;
			meshVertices.Add(new Vector3(num2, 0f, 0f));
			meshVertices.Add(new Vector3(num3, 0f, 0f));
			meshVertices.Add(new Vector3(num3, num5, 0f));
			meshVertices.Add(new Vector3(num2, num5, 0f));
			meshUVs.Add(new Vector2(num2 / width, 0f));
			meshUVs.Add(new Vector2(num3 / width, 0f));
			meshUVs.Add(new Vector2(num3 / width, num5 / height));
			meshUVs.Add(new Vector2(num2 / width, num5 / height));
			meshTriangles.Add(count);
			meshTriangles.Add(count + 2);
			meshTriangles.Add(count + 1);
			meshTriangles.Add(count);
			meshTriangles.Add(count + 3);
			meshTriangles.Add(count + 2);
		}
	}

	private void ApplyMeshToImage()
	{
		if (!(chartMesh == null))
		{
			chartMesh.Clear();
			chartMesh.SetVertices(meshVertices);
			chartMesh.SetTriangles(meshTriangles, 0);
			chartMesh.SetUVs(0, meshUVs);
			chartMesh.RecalculateNormals();
			chartMesh.RecalculateBounds();
			chartMeshFilter.sharedMesh = chartMesh;
		}
	}

	private float GetTotalAqueductDistance()
	{
		if (selectedAqueductLine?.waypoints == null || selectedAqueductLine.waypoints.Length < 2)
		{
			return 0f;
		}
		float num = 0f;
		for (int i = 0; i < selectedAqueductLine.waypoints.Length - 1; i++)
		{
			num += Vector3.Distance(selectedAqueductLine.waypoints[i], selectedAqueductLine.waypoints[i + 1]);
		}
		return num;
	}

	private float GetPeakHumanFlow()
	{
		if (selectedAqueductLine == null)
		{
			return 0f;
		}
		float inflowAmount = selectedAqueductLine.GetInflowAmount();
		inflowAmount = Mathf.Max(inflowAmount, selectedAqueductLine.currentOutputFlow);
		List<AqueductLine.WaterFlowStateTransitionNodes> waterFlowStateTransitionNodes = selectedAqueductLine.waterFlowStateTransitionNodes;
		if (waterFlowStateTransitionNodes != null)
		{
			for (int i = 0; i < waterFlowStateTransitionNodes.Count; i++)
			{
				inflowAmount = Mathf.Max(inflowAmount, waterFlowStateTransitionNodes[i].waterAmount);
			}
		}
		return Mathf.Min(inflowAmount, AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS);
	}

	private static int SmallestRungAtLeast(float peak)
	{
		for (int i = 0; i < ScaleLadder.Length; i++)
		{
			if (peak <= (float)ScaleLadder[i])
			{
				return ScaleLadder[i];
			}
		}
		return ScaleLadder[ScaleLadder.Length - 1];
	}

	private static int RungIndex(float scale)
	{
		for (int i = 0; i < ScaleLadder.Length; i++)
		{
			if (ScaleLadder[i] == (int)scale)
			{
				return i;
			}
		}
		return 0;
	}

	private void UpdateScaleAndStats(bool snap)
	{
		float peakHumanFlow = GetPeakHumanFlow();
		int num = SmallestRungAtLeast(peakHumanFlow);
		if (snap || (float)num > currentScale)
		{
			currentScale = num;
		}
		else if ((float)num < currentScale)
		{
			int num2 = RungIndex(currentScale);
			float num3 = ((num2 > 0) ? ((float)ScaleLadder[num2 - 1]) : 0f);
			if (peakHumanFlow <= num3 * 0.85f)
			{
				currentScale = num;
			}
		}
		currentUtilizationPct = Mathf.Round(peakHumanFlow / AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS * 100f);
	}

	public static Color UtilizationColor(float pct, Color normal)
	{
		if (GameUI.inst == null || pct < 80f)
		{
			return normal;
		}
		if (pct >= 95f)
		{
			Color failColor = GameUI.inst.failColor;
			failColor.a = 1f;
			return failColor;
		}
		return new Color(GameUI.inst.failColor.r, GameUI.inst.successColor.g, 0f, 1f);
	}

	private void UpdateSummaryText()
	{
		if (!(selectedAqueductLine != null))
		{
			return;
		}
		float inflowAmount = selectedAqueductLine.GetInflowAmount();
		float currentOutputFlow = selectedAqueductLine.currentOutputFlow;
		float num = GetTotalAqueductDistance() * 10f;
		int num2 = (int)AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS;
		flowText.text = string.Format(LocalizationManager.GetTranslation("aqueductwaterchart_ui_flow"), inflowAmount, currentOutputFlow);
		lengthText.text = string.Format(LocalizationManager.GetTranslation("aqueductwaterchart_ui_length"), num, num2);
		if (axisLabelBottom != null)
		{
			axisLabelBottom.text = "0";
		}
		if (axisLabelMid != null)
		{
			axisLabelMid.text = (currentScale * 0.5f).ToString("0.#");
		}
		if (axisLabelTop != null)
		{
			axisLabelTop.text = currentScale.ToString("0.#");
		}
		if (utilizationText != null)
		{
			if (!utilizationColorCaptured)
			{
				utilizationNormalColor = utilizationText.color;
				utilizationColorCaptured = true;
			}
			utilizationText.text = string.Format(LocalizationManager.GetTranslation("aqueductwaterchart_ui_utilization"), (int)currentUtilizationPct);
			utilizationText.color = UtilizationColor(currentUtilizationPct, utilizationNormalColor);
		}
	}

	private void ClearChart()
	{
		transitionNodeToChartElement.Clear();
		if (chartMesh != null)
		{
			chartMesh.Clear();
		}
		meshVertices.Clear();
		meshTriangles.Clear();
		meshUVs.Clear();
	}

	private void OnDestroy()
	{
		ClearChart();
		if (ThoughtBubbleSystem.inst != null)
		{
			ThoughtBubbleSystem.inst.PopMask(ref waterMaskHandle);
		}
	}

	private void UpdateWaterTextureScroll()
	{
		if (waterMaterialReference == null || selectedAqueductLine == null || !HasWaterInAqueduct())
		{
			return;
		}
		float totalAqueductDistance = GetTotalAqueductDistance();
		if (!(totalAqueductDistance <= 0f))
		{
			float num = 1f / totalAqueductDistance;
			num *= waterMaterialReference.mainTextureScale.x;
			Vector2 mainTextureOffset = waterMaterialReference.mainTextureOffset;
			mainTextureOffset.x -= num * Time.deltaTime;
			if (mainTextureOffset.x < 0f)
			{
				mainTextureOffset.x++;
			}
			waterMaterialReference.mainTextureOffset = mainTextureOffset;
		}
	}

	private bool HasWaterInAqueduct()
	{
		if (selectedAqueductLine == null)
		{
			return false;
		}
		if (Mathf.RoundToInt(selectedAqueductLine.GetInflowAmount()) > 0)
		{
			return true;
		}
		if (Mathf.RoundToInt(selectedAqueductLine.currentOutputFlow) > 0)
		{
			return true;
		}
		if (selectedAqueductLine.waterFlowStateTransitionNodes != null)
		{
			foreach (AqueductLine.WaterFlowStateTransitionNodes waterFlowStateTransitionNode in selectedAqueductLine.waterFlowStateTransitionNodes)
			{
				if (Mathf.RoundToInt(waterFlowStateTransitionNode.waterAmount) > 0)
				{
					return true;
				}
			}
		}
		return false;
	}

	private void SetupChartTooltip()
	{
		if (!(chartArea == null))
		{
			chartTooltip = chartArea.GetComponent<TooltipHook>();
			if (chartTooltip == null)
			{
				chartTooltip = chartArea.gameObject.AddComponent<TooltipHook>();
			}
			chartTooltip.toolTipText = "Hover over chart to see water amount";
		}
	}

	private void UpdateChartTooltip()
	{
		if (!(chartTooltip == null) && !(chartArea == null) && chartTooltip.isOver)
		{
			RectTransformUtility.ScreenPointToLocalPointInRectangle(chartArea, Input.mousePosition, GameUI.inst.UICamera, out var localPoint);
			Rect rect = chartArea.rect;
			float normalizedX = Mathf.Clamp01((localPoint.x - rect.xMin) / rect.width);
			float num = CalculateWaterAtNormalizedPosition(normalizedX);
			float totalAqueductDistance = GetTotalAqueductDistance();
			chartTooltip.toolTipText = string.Format(LocalizationManager.GetTranslation("aqueductwaterchart_ui_tooltip_flow"), num);
		}
	}

	private float CalculateWaterAtNormalizedPosition(float normalizedX)
	{
		if (selectedAqueductLine == null)
		{
			return 0f;
		}
		float b = selectedAqueductLine.GetInflowAmount();
		List<AqueductLine.WaterFlowStateTransitionNodes> waterFlowStateTransitionNodes = selectedAqueductLine.waterFlowStateTransitionNodes;
		if (waterFlowStateTransitionNodes != null && waterFlowStateTransitionNodes.Count > 0)
		{
			foreach (AqueductLine.WaterFlowStateTransitionNodes item in waterFlowStateTransitionNodes)
			{
				if (!(item.T <= normalizedX))
				{
					b = item.waterAmount;
					break;
				}
			}
		}
		if (normalizedX >= 0.99f)
		{
			b = selectedAqueductLine.currentOutputFlow;
		}
		return Mathf.Max(0f, b);
	}
}
