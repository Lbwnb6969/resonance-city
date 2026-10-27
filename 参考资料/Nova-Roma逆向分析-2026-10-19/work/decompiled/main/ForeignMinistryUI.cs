using Assets.Code;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ForeignMinistryUI : MonoBehaviour, IWorkerUIElement
{
	public ResourceAmountUI giftAmountUI;

	public Button makeGift;

	public Button cancelGift;

	public GameObject giveInstructions;

	public GameObject giveProgress;

	public Slider progressSlider;

	public Transform giftAmountContainer;

	public GameObject giftButtons;

	public GameObject giftButtonsTopLevel;

	public GameObject[] kingdomGiftButtons;

	private HallOfDiplomacy ministry;

	private ResourceAmount prevGiftTarget;

	private void Start()
	{
	}

	public void UpdateForNewSelection()
	{
		if (!GameUI.inst.SelectedBuildingIs("hallofdiplomacy".GetHashCode()))
		{
			return;
		}
		ministry = GameUI.inst.GetBuildingSelected().GetComponent<HallOfDiplomacy>();
		bool flag = !ministry.MakingGift() && !ministry.HasGift();
		giftButtonsTopLevel.SetActive(flag);
		giftAmountContainer.gameObject.SetActive(!flag);
		giftButtons.gameObject.SetActive(!flag);
		if (!flag)
		{
			return;
		}
		for (int i = 0; i < kingdomGiftButtons.Length; i++)
		{
			kingdomGiftButtons[i].SetActive(value: false);
		}
		for (int j = 0; j < AIBrainsContainer.inst.kingdoms.Count && j < kingdomGiftButtons.Length; j++)
		{
			AIKingdom aIKingdom = AIBrainsContainer.inst.kingdoms[j];
			if (aIKingdom.currMission is BuildingResourceRequest { status: Mission.Status.InProgress } buildingResourceRequest)
			{
				kingdomGiftButtons[j].transform.GetChild(0).GetComponent<TextMeshProUGUI>().text = string.Format("I2.Loc.ScriptLocalization.MakeGiftOf", buildingResourceRequest.request.ToString());
				kingdomGiftButtons[j].transform.GetChild(1).GetComponent<RawImage>().texture = aIKingdom.LandmassOwner.BannerTexture;
				kingdomGiftButtons[j].SetActive(value: true);
			}
		}
	}

	public void OnClickedMakeCustomGift()
	{
		giftButtonsTopLevel.SetActive(value: false);
		giftAmountContainer.gameObject.SetActive(value: true);
		giftButtons.gameObject.SetActive(value: true);
	}

	public void OnMakeGift()
	{
		ministry.StartMakingGift(giftAmountUI.GetResourceAmount());
	}

	private void MakeGiftForKingdom(int idx)
	{
		giftButtonsTopLevel.SetActive(value: false);
		giftAmountContainer.gameObject.SetActive(value: true);
		giftButtons.gameObject.SetActive(value: true);
		BuildingResourceRequest buildingResourceRequest = AIBrainsContainer.inst.kingdoms[idx].currMission as BuildingResourceRequest;
		giftAmountUI.SetResourceAmount(buildingResourceRequest.request);
		OnMakeGift();
	}

	public void OnMakeGiftKingdom1()
	{
		MakeGiftForKingdom(0);
	}

	public void OnMakeGiftKingdom2()
	{
		MakeGiftForKingdom(1);
	}

	public void OnMakeGiftKingdom3()
	{
		MakeGiftForKingdom(2);
	}

	public void OnCancelGift()
	{
		if (ministry.MakingGift() || ministry.HasGift())
		{
			ministry.CancelGift();
			return;
		}
		giftButtonsTopLevel.SetActive(value: true);
		giftAmountContainer.gameObject.SetActive(value: false);
		giftButtons.gameObject.SetActive(value: false);
	}

	private void Update()
	{
		if (ministry.MakingGift() || ministry.HasGift())
		{
			makeGift.gameObject.SetActive(value: false);
			if (ministry.HasGift())
			{
				giveProgress.gameObject.SetActive(value: false);
				giveInstructions.gameObject.SetActive(value: true);
			}
			else
			{
				giveProgress.gameObject.SetActive(value: true);
				giveInstructions.gameObject.SetActive(value: false);
				float value = ministry.GiftProgress();
				progressSlider.value = value;
			}
			UpdateConsoleNavigation(isNavigatable: false);
		}
		else
		{
			giveProgress.gameObject.SetActive(value: false);
			giveInstructions.gameObject.SetActive(value: false);
			makeGift.gameObject.SetActive(value: true);
			if (prevGiftTarget != ministry.giftTarget)
			{
				giftAmountUI.SetResourceAmount(ministry.giftTarget);
			}
			UpdateConsoleNavigation(isNavigatable: true);
		}
		prevGiftTarget = ministry.giftTarget;
	}

	private void UpdateConsoleNavigation(bool isNavigatable)
	{
		for (int i = 0; i < giftAmountContainer.childCount - 1; i++)
		{
			giftAmountContainer.GetChild(i).GetChild(2).gameObject.SetActive(isNavigatable);
		}
	}

	private void OnDisable()
	{
	}

	void IWorkerUIElement.TryShow()
	{
		gameObject.SetActive(CanShow());
	}

	public bool CanShow()
	{
		return GameUI.inst.SelectedBuildingIs("hallofdiplomacy".GetHashCode());
	}
}
