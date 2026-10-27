using Assets.Code;
using FMOD.Studio;
using UnityEngine;

public class GreatHall : MonoBehaviour, IWorkerUIDisplay
{
	private EventInstance festivalSfx;

	public GameObject lights;

	public GameObject lights2;

	public ParticleSystem chimneySmoke;

	public ParticleSystem chimneySmoke2;

	private float feastTime;

	public bool ShowCustomButton()
	{
		return true;
	}

	public bool CustomButtonInteractable()
	{
		return feastTime <= 0f;
	}

	public bool ShowOpenClose()
	{
		return false;
	}

	public bool ShowDemolish()
	{
		return true;
	}

	public string CustomButtonTitle()
	{
		return string.Empty;
	}

	public string CustomButtonText()
	{
		ResourceAmount feastCost = GetFeastCost();
		return feastCost.Get(0) + "<sprite name=icon_food> " + feastCost.Get(9) + "<sprite name=icon_apple>";
	}

	private ResourceAmount GetFeastCost()
	{
		ResourceAmount resourceAmount = new ResourceAmount();
		ArrayExt<Villager> villagersForLandMass = World.inst.GetVillagersForLandMass(GetComponent<Building>().LandMass());
		int val = Mathff.Max(5, villagersForLandMass.Count / 3);
		int val2 = Mathff.Max(5, villagersForLandMass.Count / 8);
		resourceAmount.Set(9, val2);
		resourceAmount.Set(0, val);
		return resourceAmount;
	}

	private void Start()
	{
		lights.SetActive(value: false);
		lights2.SetActive(value: false);
	}

	public Sprite CustomButtonImage()
	{
		return null;
	}

	public void CustomButtonClicked()
	{
		if (!TryStartFeast())
		{
			GameUI.inst.resourceUI.FlashResourcesUIRed(GetFeastCost());
		}
	}

	public bool TryStartFeast()
	{
		Building component = GetComponent<Building>();
		int num = component.LandMass();
		new ResourceAmount();
		ResourceAmount feastCost = GetFeastCost();
		if (Player.inst.resourcesPerLandmass[num].TrySubtract(feastCost))
		{
			int num2 = (int)SeasonManager.inst.TimeInYear();
			feastTime = num2;
			LandmassOwner landmassOwner = World.GetLandmassOwner(component.LandMass());
			ArrayExt<Building> buildingListForLandMassOwner = Player.inst.GetBuildingListForLandMassOwner(landmassOwner, World.greatHallHash);
			for (int i = 0; i < buildingListForLandMassOwner.Count; i++)
			{
				buildingListForLandMassOwner.data[i].GetComponent<GreatHall>().SetFX(on: true);
				buildingListForLandMassOwner.data[i].GetComponent<GreatHall>().feastTime = num2;
			}
			SetFX(on: true);
			return true;
		}
		return false;
	}

	private void SetFX(bool on)
	{
		if (on)
		{
			festivalSfx = SfxSystem.inst.PlayFromBankIfVisible("EventFestival", transform.position);
			chimneySmoke.Play();
			chimneySmoke2.Play();
		}
		else
		{
			chimneySmoke.Stop();
			chimneySmoke2.Stop();
			festivalSfx.stop(STOP_MODE.ALLOWFADEOUT);
		}
		lights.gameObject.SetActive(on);
		lights2.gameObject.SetActive(on);
	}

	private void Update()
	{
		float deltaTime = Time.deltaTime;
		feastTime -= deltaTime;
		if (feastTime <= 0f)
		{
			SetFX(on: false);
		}
	}
}
