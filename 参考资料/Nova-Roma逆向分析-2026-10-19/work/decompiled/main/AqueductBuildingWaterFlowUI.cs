using System.Collections.Generic;
using System.Linq;
using Assets;
using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Serialization;
using UnityEngine.UI;
using cakeslice;

public class AqueductBuildingWaterFlowUI : MonoBehaviour, IProceduralOutline
{
	private class ConsumerTypeAggregate
	{
		public int uniqueNameHash;

		public Sprite icon;

		public float volume;

		public int count;

		public float totalConsumption;

		public bool partialNeedWarning;
	}

	private Building building;

	private AqueductBuilding aqueductBuilding;

	private WaterSupplier waterSupplier;

	private BathReservoir bathReservoir;

	public GameObject flowOutLabel;

	public float waterDropletMaxConsumptionRate = 15f;

	public GameObject waterTower;

	public GameObject ironMine;

	[Header("Consumption panel")]
	[FormerlySerializedAs("waterTowerConsumptionPanel")]
	public GameObject consumptionPanel;

	public TextMeshProUGUI consumptionAmount;

	public GameObject flowSummaryContainer;

	public GameObject bathReservoirObj;

	public RectTransform bathReservoirWaterRectT;

	public TextMeshProUGUI bathReservoirStorageTMP;

	public Localize bathStateLocalize;

	private const string BATH_STATE_FILLING = "workerui_aqueductbuilding_bath_filling";

	private const string BATH_STATE_HOLDING = "workerui_aqueductbuilding_bath_holding";

	private const string BATH_STATE_DRAINING = "workerui_aqueductbuilding_bath_draining";

	[Header("Water en route reassurance")]
	public GameObject waterEnRouteContainer;

	[Header("Priority")]
	public GameObject priorityContainer;

	public BetterDropdown priorityDropdown;

	public Image priorityImage;

	private const string PRIORITY_HIGH = "workerui_aqueductbuilding_priority_high";

	private const string PRIORITY_NORMAL = "workerui_aqueductbuilding_priority_normal";

	private const string PRIORITY_LOW = "workerui_aqueductbuilding_priority_low";

	private static readonly WaterPriority[] PRIORITY_BY_INDEX = new WaterPriority[3]
	{
		WaterPriority.High,
		WaterPriority.Normal,
		WaterPriority.Low
	};

	private bool priorityListenerHooked;

	[Header("Water outlet")]
	public GameObject outletSliderContainer;

	public Slider outletSlider;

	public TextMeshProUGUI outletAmountText;

	private bool outletListenerHooked;

	public float outletApplyDelay = 0.2f;

	private float outletPendingValue;

	private bool outletApplyPending;

	private float outletApplyTimer;

	private ObjectHighlighter highlighter;

	private bool inited;

	public Mesh dropletMesh;

	public Mesh dropletOffMesh;

	public Material dropletMaterial;

	private Matrix4x4[] dropletMatrices = new Matrix4x4[100];

	private Matrix4x4[] dropletOffMatrices = new Matrix4x4[100];

	[Header("Consumer quantity labels")]
	public WaveFrontLabel consumerQuantityLabelPrefab;

	[Tooltip("On-screen size vs. distance to camera (matches the wavefront/hub labels' feel).")]
	public AnimationCurve labelScaleToCamDist = AnimationCurve.Linear(0f, 0.5f, 100f, 5f);

	private readonly List<WaveFrontLabel> consumerLabelPool = new List<WaveFrontLabel>(32);

	public Transform buildingFlowInfoContainer;

	public BuildingFlowItemUI buildingFlowItemUIPrefab;

	private readonly List<ConsumerTypeAggregate> consumerTypeAggregates = new List<ConsumerTypeAggregate>(16);

	public float dropletMinScale = 1.5f;

	public float dropletMaxScale = 2f;

	public float labelOffsetY = 0.4f;

	public float dropletOffsetY = 0.3f;

	private ThoughtBubbleSystem.ThoughtMaskHandle waterMaskHandle;

	private int dropletOffMeshCount;

	private int dropletMeshCount;

	public GameObject flowInContainer;

	public GameObject flowOutContainer;

	private List<GameObject> flowIn = new List<GameObject>();

	private List<GameObject> flowOut = new List<GameObject>();

	private WaterOutlet selectedOutlet;

	private void Init()
	{
		inited = true;
		flowOut.AddRange(flowOutContainer.transform.GetComponentsInChildren<AqueductBuildingFlowCard>().Select((AqueductBuildingFlowCard x) =>
		{
			x.Init();
			return x.gameObject;
		}));
		flowIn.AddRange(flowInContainer.transform.GetComponentsInChildren<AqueductBuildingFlowCard>().Select((AqueductBuildingFlowCard x) =>
		{
			x.Init();
			return x.gameObject;
		}));
	}

	private void Update()
	{
		if (building == null)
		{
			return;
		}
		bool flag = building.uniqueNameHash == World.waterTowerHash;
		bool flag2 = building.uniqueNameHash == World.bathReservoirHash;
		bool flag3 = building.uniqueNameHash == World.ironOreMillHash;
		bool flag4 = building.uniqueNameHash == World.waterOutletHash;
		bool flag5 = flag | flag2 | flag3;
		Util.SetActive(waterTower, flag);
		Util.SetActive(ironMine, flag3);
		Util.SetActive(bathReservoirObj, flag2);
		Util.SetActive(bathStateLocalize.gameObject, flag2);
		Util.SetActive(consumptionPanel, flag5);
		if (flag5)
		{
			float num = Mathf.Round(aqueductBuilding.GetCurrentWaterConsumption());
			float num2 = Mathf.Round(aqueductBuilding.GetWaterDemandTotal());
			consumptionAmount.color = ((num2 > num) ? Color.yellow : Color.white);
			consumptionAmount.SetText("{0} / {1}", num, num2);
		}
		Util.SetActive(flowSummaryContainer, !flag4);
		Util.SetActive(outletSliderContainer, flag4);
		if (flag4)
		{
			TickOutletApply();
			UpdateOutletAmountText();
		}
		else
		{
			GenerateFlowSummary();
		}
		if (bathReservoir != null)
		{
			UpdateBathTankState(bathReservoir);
		}
		UpdateWaterEnRouteReassurance();
		if (waterSupplier != null)
		{
			List<WaterConsumer> consumers = waterSupplier.consumers;
			UpdateBuildingFlowInfo(consumers);
			if (consumers.Count > dropletMatrices.Length)
			{
				dropletMatrices = new Matrix4x4[consumers.Count];
			}
			if (consumers.Count > dropletOffMatrices.Length)
			{
				dropletOffMatrices = new Matrix4x4[consumers.Count];
			}
			dropletMeshCount = 0;
			dropletOffMeshCount = 0;
			Camera cam = Cam.inst.cam;
			Vector3 position = cam.transform.position;
			int fromIndex = 0;
			for (int i = 0; i < consumers.Count; i++)
			{
				Vector3 vector = consumers[i].b.Center() + new Vector3(0f, consumers[i].b.size.y + dropletOffsetY, 0f);
				float num3 = Mathff.Lerp(dropletMinScale, dropletMaxScale, consumers[i].consumptionRate * consumers[i].availableWaterPercentage / waterDropletMaxConsumptionRate);
				Vector3 vector2 = vector;
				if ((double)consumers[i].availableWaterPercentage < 0.0001)
				{
					dropletOffMatrices[dropletOffMeshCount] = Matrix4x4.TRS(vector2, Quaternion.LookRotation(-Cam.inst.cam.transform.forward), Vector3.one);
					dropletOffMeshCount++;
				}
				else
				{
					vector2 += new Vector3(0f, Mathf.Sin(Time.unscaledTime * 2f + (float)i) * 0.05f, 0f);
					dropletMatrices[dropletMeshCount] = Matrix4x4.TRS(vector2, Quaternion.LookRotation(Cam.inst.CamPos - vector2, Vector3.up), Vector3.one * num3);
					dropletMeshCount++;
				}
				if (consumerQuantityLabelPrefab != null)
				{
					int num4 = Mathf.RoundToInt(consumers[i].consumptionRate * consumers[i].availableWaterPercentage);
					if (num4 > 0)
					{
						WaveFrontLabel pooledLabel = GetPooledLabel(fromIndex++);
						pooledLabel.text.color = ((consumers[i].availableWaterPercentage > 0.99f) ? Color.white : Color.yellow);
						pooledLabel.SetText(num4.ToString());
						Vector3 worldPos = vector2;
						worldPos.y += labelOffsetY;
						pooledLabel.Place(worldPos, cam, labelScaleToCamDist.Evaluate(Vector3.Distance(vector2, position)));
					}
				}
			}
			HideConsumerLabels(fromIndex);
			Graphics.DrawMeshInstanced(dropletMesh, 0, dropletMaterial, dropletMatrices, dropletMeshCount, null, ShadowCastingMode.Off);
			Graphics.DrawMeshInstanced(dropletOffMesh, 0, dropletMaterial, dropletOffMatrices, dropletOffMeshCount, null, ShadowCastingMode.Off);
			highlighter.SetOutlineImmediate(1);
		}
		else if (bathReservoir != null && bathReservoir.Group != null)
		{
			UpdateBathBuildingFlowInfo(bathReservoir.Group);
			HideConsumerLabels();
		}
		else
		{
			HideConsumerLabels();
			HideAllBuildingFlowItems();
		}
	}

	private void UpdateBathBuildingFlowInfo(BathManager.BathGroup group)
	{
		ResetConsumerAggregates();
		for (int i = 0; i < group.pools.Count; i++)
		{
			BathPool bathPool = group.pools.data[i];
			if (!(bathPool == null) && !(bathPool.b == null))
			{
				AccumulateConsumer(bathPool.b, bathPool.HasWater() ? ((float)BathPool.wConsumption) : 0f, partialNeed: false);
			}
		}
		RenderConsumerAggregates();
	}

	private void UpdateBuildingFlowInfo(List<WaterConsumer> consumers)
	{
		ResetConsumerAggregates();
		for (int i = 0; i < consumers.Count; i++)
		{
			WaterConsumer waterConsumer = consumers[i];
			AccumulateConsumer(waterConsumer.b, waterConsumer.consumptionRate * waterConsumer.availableWaterPercentage, waterConsumer.availableWaterPercentage < 0.99f);
		}
		RenderConsumerAggregates();
	}

	private void ResetConsumerAggregates()
	{
		for (int i = 0; i < consumerTypeAggregates.Count; i++)
		{
			consumerTypeAggregates[i].count = 0;
			consumerTypeAggregates[i].totalConsumption = 0f;
			consumerTypeAggregates[i].partialNeedWarning = false;
		}
	}

	private void AccumulateConsumer(Building b, float consumption, bool partialNeed)
	{
		int uniqueNameHash = b.uniqueNameHash;
		ConsumerTypeAggregate consumerTypeAggregate = null;
		for (int i = 0; i < consumerTypeAggregates.Count; i++)
		{
			if (consumerTypeAggregates[i].uniqueNameHash == uniqueNameHash)
			{
				consumerTypeAggregate = consumerTypeAggregates[i];
				break;
			}
		}
		if (consumerTypeAggregate == null)
		{
			Vector3 size = b.size;
			consumerTypeAggregate = new ConsumerTypeAggregate
			{
				uniqueNameHash = uniqueNameHash,
				icon = b.sprite,
				volume = size.x * size.y * size.z
			};
			consumerTypeAggregates.Add(consumerTypeAggregate);
		}
		consumerTypeAggregate.count++;
		consumerTypeAggregate.totalConsumption += consumption;
		if (partialNeed)
		{
			consumerTypeAggregate.partialNeedWarning = true;
		}
	}

	private void RenderConsumerAggregates()
	{
		consumerTypeAggregates.Sort((ConsumerTypeAggregate a, ConsumerTypeAggregate b) => a.volume.CompareTo(b.volume));
		int num = 0;
		for (int num2 = 0; num2 < consumerTypeAggregates.Count; num2++)
		{
			ConsumerTypeAggregate consumerTypeAggregate = consumerTypeAggregates[num2];
			if (consumerTypeAggregate.count > 0)
			{
				BuildingFlowItemUI buildingFlowItemRow = GetBuildingFlowItemRow(num++);
				buildingFlowItemRow.buildingIcon.sprite = consumerTypeAggregate.icon;
				buildingFlowItemRow.quantity.SetText("{0}x", consumerTypeAggregate.count);
				buildingFlowItemRow.totalWaterConsumption.SetText("{0}", Mathf.RoundToInt(consumerTypeAggregate.totalConsumption));
				if (consumerTypeAggregate.totalConsumption <= 0f)
				{
					buildingFlowItemRow.totalWaterConsumption.color = Color.orangeRed;
				}
				else
				{
					buildingFlowItemRow.totalWaterConsumption.color = (consumerTypeAggregate.partialNeedWarning ? Color.yellow : Color.white);
				}
				Util.SetActive(buildingFlowItemRow.waterConsumeArrow, consumerTypeAggregate.totalConsumption > 0f);
				Util.SetActive(buildingFlowItemRow.waterUnavailable, consumerTypeAggregate.totalConsumption <= 0f);
			}
		}
		for (int num3 = num; num3 < buildingFlowInfoContainer.childCount; num3++)
		{
			Util.SetActive(buildingFlowInfoContainer.GetChild(num3).gameObject, active: false);
		}
	}

	private BuildingFlowItemUI GetBuildingFlowItemRow(int index)
	{
		if (index < buildingFlowInfoContainer.childCount)
		{
			Transform child = buildingFlowInfoContainer.GetChild(index);
			Util.SetActive(child.gameObject, active: true);
			return child.GetComponent<BuildingFlowItemUI>();
		}
		return Object.Instantiate(buildingFlowItemUIPrefab, buildingFlowInfoContainer, worldPositionStays: false);
	}

	private void HideAllBuildingFlowItems()
	{
		for (int i = 0; i < buildingFlowInfoContainer.childCount; i++)
		{
			Util.SetActive(buildingFlowInfoContainer.GetChild(i).gameObject, active: false);
		}
	}

	private WaveFrontLabel GetPooledLabel(int index)
	{
		while (consumerLabelPool.Count <= index)
		{
			consumerLabelPool.Add(Object.Instantiate(consumerQuantityLabelPrefab));
		}
		WaveFrontLabel waveFrontLabel = consumerLabelPool[index];
		if (waveFrontLabel != null && !waveFrontLabel.gameObject.activeSelf)
		{
			waveFrontLabel.gameObject.SetActive(value: true);
		}
		return waveFrontLabel;
	}

	private void HideConsumerLabels(int fromIndex = 0)
	{
		for (int i = fromIndex; i < consumerLabelPool.Count; i++)
		{
			if (consumerLabelPool[i] != null && consumerLabelPool[i].gameObject.activeSelf)
			{
				consumerLabelPool[i].gameObject.SetActive(value: false);
			}
		}
	}

	private void PushWaterMask()
	{
		if (waterMaskHandle == null && ThoughtBubbleSystem.inst != null)
		{
			waterMaskHandle = ThoughtBubbleSystem.inst.PushMask(ThoughtBubbleSystem.ThoughtCategory.Water);
		}
	}

	private void PopWaterMask()
	{
		if (ThoughtBubbleSystem.inst != null)
		{
			ThoughtBubbleSystem.inst.PopMask(ref waterMaskHandle);
		}
	}

	private void OnDisable()
	{
		HideConsumerLabels();
		HideAllBuildingFlowItems();
		PopWaterMask();
	}

	public void DrawOutline(CommandBuffer commandBuffer, Material highlightMaterial)
	{
		commandBuffer.DrawMeshInstanced(dropletMesh, 0, highlightMaterial, 0, dropletMatrices, dropletMeshCount);
		commandBuffer.DrawMeshInstanced(dropletOffMesh, 0, highlightMaterial, 0, dropletOffMatrices, dropletOffMeshCount);
	}

	private void UpdateWaterEnRouteReassurance()
	{
		if (!(waterEnRouteContainer == null))
		{
			bool flag = aqueductBuilding != null && aqueductBuilding.IsWaterEnRoute();
			if (waterEnRouteContainer.activeSelf != flag)
			{
				waterEnRouteContainer.SetActive(flag);
			}
		}
	}

	private void UpdateBathTankState(BathReservoir bReservoir)
	{
		float num = ((BathReservoir.MAX_WATER_STORAGE > 0f) ? (bathReservoir.currWaterStorage / BathReservoir.MAX_WATER_STORAGE) : 0f);
		Vector2 anchoredPosition = bathReservoirWaterRectT.anchoredPosition;
		anchoredPosition.y = (1f - num) * -48f;
		bathReservoirWaterRectT.anchoredPosition = anchoredPosition;
		bathReservoirStorageTMP.text = Mathf.FloorToInt(num * 100f) + "%";
		int num2 = Mathf.RoundToInt(bReservoir.GroupIntake());
		int num3 = Mathf.RoundToInt(bReservoir.GetCurrentWaterConsumption());
		string text;
		if (num2 > num3)
		{
			text = "workerui_aqueductbuilding_bath_filling";
		}
		else
		{
			text = ((num2 < num3) ? "workerui_aqueductbuilding_bath_draining" : "workerui_aqueductbuilding_bath_holding");
		}
		if (bathStateLocalize.Term != text)
		{
			bathStateLocalize.SetTerm(text);
		}
	}

	public void GenerateFlowSummary(bool forceText = false)
	{
		if (!inited)
		{
			Init();
		}
		int num = 0;
		for (int i = 0; i < aqueductBuilding.aqueductLines.Count; i++)
		{
			if (num >= flowIn.Count)
			{
				break;
			}
			AqueductLine aqueductLine = aqueductBuilding.aqueductLines[i];
			if (aqueductLine.IsProvidingWaterTo(aqueductBuilding))
			{
				if (!flowIn[num].gameObject.activeSelf)
				{
					flowIn[num].gameObject.SetActive(value: true);
				}
				float num2 = Mathf.Round(aqueductLine.currentOutputFlow);
				AqueductBuildingFlowCard componentInChildren = flowIn[num].GetComponentInChildren<AqueductBuildingFlowCard>();
				if (forceText)
				{
					flowIn[num].GetComponentInChildren<TextMeshProUGUI>().text = num2.ToString();
					componentInChildren.lastFlow = num2;
				}
				else
				{
					Util.TrySetText(flowIn[num].GetComponentInChildren<TextMeshProUGUI>(), "{0}", num2, ref componentInChildren.lastFlow);
				}
				componentInChildren.SetFullness(num2 / AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS);
				num++;
			}
		}
		for (int j = num; j < flowIn.Count; j++)
		{
			if (flowIn[j].gameObject.activeSelf)
			{
				flowIn[j].gameObject.SetActive(value: false);
			}
		}
		int num3 = 0;
		for (int k = 0; k < aqueductBuilding.aqueductLines.Count; k++)
		{
			if (num3 >= flowOut.Count)
			{
				break;
			}
			AqueductLine aqueductLine2 = aqueductBuilding.aqueductLines[k];
			if (aqueductLine2.IsSendingWaterTo(aqueductBuilding))
			{
				if (!flowOut[num3].gameObject.activeSelf)
				{
					flowOut[num3].gameObject.SetActive(value: true);
				}
				float num4 = Mathf.Round(aqueductLine2.GetInflowAmount());
				AqueductBuildingFlowCard componentInChildren2 = flowOut[num3].GetComponentInChildren<AqueductBuildingFlowCard>();
				if (forceText)
				{
					flowOut[num3].GetComponentInChildren<TextMeshProUGUI>().text = num4.ToString();
					componentInChildren2.lastFlow = num4;
				}
				else
				{
					Util.TrySetText(flowOut[num3].GetComponentInChildren<TextMeshProUGUI>(), "{0}", num4, ref componentInChildren2.lastFlow);
				}
				componentInChildren2.SetFullness(num4 / AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS);
				num3++;
			}
		}
		Util.SetActive(flowOutLabel, num3 > 0);
		for (int l = num3; l < flowOut.Count; l++)
		{
			Util.SetActive(flowOut[l], active: false);
		}
	}

	public void SetVisibility(bool isVisible)
	{
		gameObject.SetActive(isVisible);
		if (!isVisible)
		{
			SetSelectedOutlet(null);
		}
		if (isVisible)
		{
			highlighter = ObjectHighlighter.SetupOutline(gameObject, this);
		}
		else if (highlighter != null)
		{
			highlighter.Release();
			highlighter = null;
		}
	}

	private void RefreshPriorityDropdown()
	{
		bool num = building != null && building.uniqueNameHash == World.waterTowerHash;
		bool flag = building != null && building.uniqueNameHash == World.bathReservoirHash;
		bool flag2 = building != null && building.uniqueNameHash == World.waterOutletHash;
		bool flag3 = num | flag | flag2;
		if (priorityContainer != null)
		{
			Util.SetActive(priorityContainer, flag3);
		}
		WaterPriority p = (flag3 ? CurrentPriority(flag) : WaterPriority.Normal);
		RefreshPriorityImage(p);
		if (flag3 && !(priorityDropdown == null))
		{
			if (!priorityListenerHooked)
			{
				priorityDropdown.onValueSelected.AddListener(OnPrioritySelected);
				priorityListenerHooked = true;
			}
			priorityDropdown.ClearOptions();
			for (int i = 0; i < PRIORITY_BY_INDEX.Length; i++)
			{
				string term = TermForPriority(PRIORITY_BY_INDEX[i]);
				priorityDropdown.options.Add(new BetterDropdown.OptionData
				{
					term = term,
					text = LocalizationManager.GetTranslation(term)
				});
			}
			priorityDropdown.SetValueWithoutNotify(IndexForPriority(p));
			priorityDropdown.RefreshShownValue();
		}
	}

	private void RefreshPriorityImage(WaterPriority p)
	{
		priorityImage.rectTransform.localRotation = Quaternion.Euler(0f, 0f, (p == WaterPriority.Low) ? 180f : 0f);
		Util.SetActive(priorityImage.gameObject, p != WaterPriority.Normal);
	}

	private WaterPriority CurrentPriority(bool isBathReservoir)
	{
		if (isBathReservoir)
		{
			return (WaterPriority)((building.GetComponent<BathReservoir>()?.Group)?.solverPriority ?? 0);
		}
		return aqueductBuilding.WaterPriorityLevel;
	}

	private void OnPrioritySelected(int index)
	{
		if (!(building == null) && index >= 0 && index < PRIORITY_BY_INDEX.Length)
		{
			WaterPriority waterPriority = PRIORITY_BY_INDEX[index];
			if (building.uniqueNameHash == World.bathReservoirHash)
			{
				building.GetComponent<BathReservoir>()?.Group?.SetWaterPriority(waterPriority);
			}
			else
			{
				aqueductBuilding.SetWaterPriority(waterPriority);
			}
			RefreshPriorityImage(waterPriority);
		}
	}

	private static string TermForPriority(WaterPriority p)
	{
		return p switch
		{
			WaterPriority.High => "workerui_aqueductbuilding_priority_high", 
			WaterPriority.Low => "workerui_aqueductbuilding_priority_low", 
			_ => "workerui_aqueductbuilding_priority_normal", 
		};
	}

	private static int IndexForPriority(WaterPriority p)
	{
		for (int i = 0; i < PRIORITY_BY_INDEX.Length; i++)
		{
			if (PRIORITY_BY_INDEX[i] == p)
			{
				return i;
			}
		}
		return 1;
	}

	private void RefreshOutletControls()
	{
		if (!outletListenerHooked)
		{
			outletSlider.onValueChanged.AddListener(OnOutletSliderChanged);
			outletListenerHooked = true;
		}
		outletApplyPending = false;
		if (selectedOutlet != null)
		{
			outletSlider.SetValueWithoutNotify((AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS > 0f) ? (selectedOutlet.targetOutflow / AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS) : 0f);
		}
		UpdateOutletAmountText();
	}

	private void OnOutletSliderChanged(float value)
	{
		if (!(selectedOutlet == null))
		{
			outletPendingValue = Mathf.Clamp01(value);
			outletApplyPending = true;
			outletApplyTimer = outletApplyDelay;
			UpdateOutletAmountText();
		}
	}

	private void TickOutletApply()
	{
		if (outletApplyPending)
		{
			outletApplyTimer -= Time.unscaledDeltaTime;
			if (outletApplyTimer <= 0f)
			{
				FlushOutletApply();
			}
		}
	}

	private void FlushOutletApply()
	{
		if (outletApplyPending)
		{
			outletApplyPending = false;
			if (selectedOutlet != null)
			{
				selectedOutlet.SetTargetOutflow(outletPendingValue * AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS);
			}
		}
	}

	private void UpdateOutletAmountText()
	{
		if (!(outletAmountText == null) && !(selectedOutlet == null))
		{
			float f = (outletApplyPending ? (outletPendingValue * AqueductBuilding.MAX_WATER_FLOW_HUMAN_UNITS) : selectedOutlet.targetOutflow);
			outletAmountText.SetText(LocalizationManager.GetTranslation("workerui_aqueductbuilding_outletflow_details"), Mathf.Round(selectedOutlet.CurrentOutflow()), Mathf.Round(f));
		}
	}

	private void SetSelectedOutlet(WaterOutlet outlet)
	{
		if (!(selectedOutlet == outlet))
		{
			if (selectedOutlet != null)
			{
				selectedOutlet.SetMarkersVisible(visible: false);
			}
			selectedOutlet = outlet;
			if (selectedOutlet != null)
			{
				selectedOutlet.SetMarkersVisible(visible: true);
			}
		}
	}

	public void OnBuildingSelected(Building b)
	{
		if (b == null || (aqueductBuilding = b.GetComponent<AqueductBuilding>()) == null)
		{
			SetSelectedOutlet(null);
			SetVisibility(isVisible: false);
			PopWaterMask();
			return;
		}
		waterSupplier = b.GetComponent<WaterSupplier>();
		bathReservoir = ((b.uniqueNameHash == World.bathReservoirHash) ? b.GetComponent<BathReservoir>() : null);
		building = b;
		SetVisibility(isVisible: true);
		PushWaterMask();
		bool flag = b.uniqueNameHash == World.waterOutletHash;
		SetSelectedOutlet(flag ? b.GetComponent<WaterOutlet>() : null);
		Util.SetActive(flowSummaryContainer, !flag);
		if (!flag)
		{
			GenerateFlowSummary(forceText: true);
		}
		RefreshPriorityDropdown();
		Util.SetActive(outletSliderContainer, flag);
		if (flag)
		{
			RefreshOutletControls();
		}
	}

	public void OnDeselected()
	{
		FlushOutletApply();
		SetSelectedOutlet(null);
		building = null;
		aqueductBuilding = null;
		waterSupplier = null;
		bathReservoir = null;
		PopWaterMask();
	}

	private void OnDestroy()
	{
		if (priorityListenerHooked && priorityDropdown != null)
		{
			priorityDropdown.onValueSelected.RemoveListener(OnPrioritySelected);
			priorityListenerHooked = false;
		}
		if (outletListenerHooked)
		{
			outletSlider.onValueChanged.RemoveListener(OnOutletSliderChanged);
			outletListenerHooked = false;
		}
		for (int i = 0; i < consumerLabelPool.Count; i++)
		{
			if (consumerLabelPool[i] != null)
			{
				Object.Destroy(consumerLabelPool[i].gameObject);
			}
		}
		consumerLabelPool.Clear();
	}
}
