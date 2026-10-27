using UnityEngine;
using UnityEngine.UI;

public class ChamberOfWarUI : MonoBehaviour, IWorkerUIElement
{
	private ChamberOfWar selectedChamberOfWar;

	public Toggle hazardPayToggle;

	public BatchMaterial batchMaterial;

	public Slider progressBar;

	private bool suppressChange;

	private readonly int chamberOfWarHash = "chamberofwar".GetHashCode();

	public Timer hazardPayWarmup;

	private void Start()
	{
		hazardPayToggle.onValueChanged.AddListener(OnHazardButtonToggled);
	}

	private void OnHazardButtonToggled(bool value)
	{
		if (!suppressChange)
		{
			LandmassOwner landMassOwner = selectedChamberOfWar.b.GetLandMassOwner();
			if (!landMassOwner.hazardPay)
			{
				landMassOwner.Gold -= 50;
				SfxSystem.inst.PlayFromBank("ui_merchant_sellto", Cam.inst.transform.position);
			}
			else
			{
				SfxSystem.PlayUiSelect();
			}
			if (landMassOwner.teamId == 0)
			{
				Player.inst.ChangeHazardPayActive(!landMassOwner.hazardPay, warmup: true);
			}
			else
			{
				landMassOwner.hazardPay = !landMassOwner.hazardPay;
			}
		}
	}

	public void UpdateForNewSelection()
	{
		if (GameUI.inst.SelectedBuildingIs(chamberOfWarHash))
		{
			selectedChamberOfWar = GameUI.inst.GetBuildingSelected().GetComponent<ChamberOfWar>();
			suppressChange = true;
			hazardPayToggle.isOn = selectedChamberOfWar.b.GetLandMassOwner().hazardPay;
			suppressChange = false;
		}
	}

	void IWorkerUIElement.TryShow()
	{
		gameObject.SetActive(CanShow());
	}

	public bool CanShow()
	{
		return GameUI.inst.SelectedBuildingIs(chamberOfWarHash);
	}

	private void Update()
	{
		if (selectedChamberOfWar != null)
		{
			LandmassOwner landMassOwner = selectedChamberOfWar.b.GetLandMassOwner();
			progressBar.gameObject.SetActive(Player.inst.hazardPayWarmup.Enabled);
			progressBar.value = Player.inst.hazardPayWarmup.CurrTime / Player.inst.hazardPayWarmup.Duration;
			hazardPayToggle.interactable = ((double)selectedChamberOfWar.b.GetWorkerPercent() > 0.95 && World.GetLandmassOwner(selectedChamberOfWar.b.LandMass()).Gold >= 50) || landMassOwner.hazardPay;
			if (progressBar.gameObject.activeSelf)
			{
				hazardPayToggle.interactable = false;
			}
			batchMaterial.SetFloat("_Desaturate", (!hazardPayToggle.interactable) ? 1 : 0);
			if (hazardPayToggle.isOn && !landMassOwner.hazardPay && !progressBar.gameObject.activeSelf)
			{
				suppressChange = true;
				hazardPayToggle.isOn = false;
				suppressChange = false;
			}
		}
	}
}
