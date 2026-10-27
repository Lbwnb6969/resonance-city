using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class OutputUI : MonoBehaviour, IWorkerUIElement
{
	public GameObject warningContainer;

	public TextMeshProUGUI warning;

	public TextMeshProUGUI errorText;

	public RectTransform errorUI;

	private Color yellow = new Color(0.81f, 0.638f, 0.08f, 1f);

	private Color red = new Color(0.81f, 0.28f, 0.16f, 1f);

	private void Start()
	{
	}

	private void Update()
	{
		Building buildingSelected = GameUI.inst.GetBuildingSelected();
		ISelectableBuilding genericBuildingSelected = GameUI.inst.GetGenericBuildingSelected();
		if (buildingSelected != null)
		{
			if (!buildingSelected.IsBuilt() || World.IsAILandmass(buildingSelected.LandMass()))
			{
				return;
			}
			IOutputInfo component = buildingSelected.GetComponent<IOutputInfo>();
			if (component != null)
			{
				buildingSelected.GetComponent<WagePayer>();
				bool flag = buildingSelected.GetComponent<Home>() != null;
				string text;
				if (buildingSelected.IsOpen() && buildingSelected.WorkersAllocated <= 0 && buildingSelected.WorkersForFullYield > 0 && !flag && buildingSelected.categoryHash != World.romanOutpostHashNewIsland && buildingSelected.uniqueNameHash != World.romanOutpostHash && (buildingSelected.GetComponent<WagePayer>() == null || buildingSelected.GetComponent<WagePayer>().CanPayWage()))
				{
					errorUI.GetComponent<Image>().color = red;
					if (buildingSelected.categoryHash == World.stockpileHash || buildingSelected.categoryHash == World.granaryCategoryHash || buildingSelected.categoryHash == World.taxOfficeHash)
					{
						errorUI.GetComponent<Image>().color = yellow;
					}
					text = ScriptLocalization.OutputUINotFullyStaffed;
				}
				else
				{
					text = ((!buildingSelected.thought.visible || (buildingSelected.thought.thought != ThoughtBubbleSystem.Thought.Wage && buildingSelected.thought.thought != ThoughtBubbleSystem.Thought.WageCritical)) ? component.GetError() : ScriptLocalization.NoGoldForWages);
					if (buildingSelected.categoryHash == World.stockpileHash)
					{
						errorUI.GetComponent<Image>().color = yellow;
					}
					else
					{
						errorUI.GetComponent<Image>().color = red;
					}
				}
				if (string.IsNullOrEmpty(text) && buildingSelected.IsOpen())
				{
					if (buildingSelected.WorkersAllocated < buildingSelected.WorkersForFullYield && buildingSelected.WorkersForFullYield > 0 && !flag && buildingSelected.uniqueNameHash != World.romanOutpostHash)
					{
						errorUI.GetComponent<Image>().color = yellow;
						text = ScriptLocalization.OutputUINotFullyStaffed;
					}
					if (buildingSelected.GetComponent<YieldProducer>() != null || buildingSelected.GetComponent<IProductionInfo>() != null)
					{
						CommuteUI componentInChildren = transform.parent.GetComponentInChildren<CommuteUI>(includeInactive: true);
						if (componentInChildren.gameObject.activeSelf)
						{
							float commuteFactor = componentInChildren.GetCommuteFactor(buildingSelected);
							if (commuteFactor <= 0.65f && commuteFactor != -1f)
							{
								errorUI.GetComponent<Image>().color = red;
								text = ScriptLocalization.workerui_error_longcommute;
							}
						}
					}
				}
				if (!string.IsNullOrEmpty(text))
				{
					errorText.text = text;
					errorUI.gameObject.SetActive(value: true);
				}
				else
				{
					errorUI.gameObject.SetActive(value: false);
				}
				string text2 = null;
				if (!buildingSelected.IsOpen())
				{
					text2 = ScriptLocalization.OutputUIClosed;
				}
				warning.text = text2;
				Util.SetActive(warningContainer, !string.IsNullOrEmpty(text2));
			}
			if (buildingSelected.thought.thought == ThoughtBubbleSystem.Thought.Tired)
			{
				errorText.text = LocalizationManager.GetTranslation("EmployerTiredError");
				errorUI.gameObject.SetActive(value: true);
			}
		}
		else
		{
			if (genericBuildingSelected == null)
			{
				return;
			}
			IOutputInfo interfaceFromSelectableBuilding = GameUI.inst.GetInterfaceFromSelectableBuilding<IOutputInfo>(genericBuildingSelected);
			if (interfaceFromSelectableBuilding != null)
			{
				string error = interfaceFromSelectableBuilding.GetError();
				errorUI.GetComponent<Image>().color = red;
				if (!string.IsNullOrEmpty(error))
				{
					errorText.text = error;
					errorUI.gameObject.SetActive(value: true);
				}
				else
				{
					errorUI.gameObject.SetActive(value: false);
				}
			}
			string text3 = null;
			if (!genericBuildingSelected.IsOpen())
			{
				text3 = ScriptLocalization.OutputUIClosed;
			}
			warning.text = text3;
			Util.SetActive(warningContainer, !string.IsNullOrEmpty(text3));
		}
	}

	public void UpdateForNewSelection()
	{
		errorUI.gameObject.SetActive(value: false);
		Util.SetActive(warningContainer, active: false);
		Update();
	}

	void IWorkerUIElement.TryShow()
	{
		gameObject.SetActive(CanShow());
	}

	public bool CanShow()
	{
		return GameUI.inst.SelectedBuildingIs<IOutputInfo>();
	}
}
