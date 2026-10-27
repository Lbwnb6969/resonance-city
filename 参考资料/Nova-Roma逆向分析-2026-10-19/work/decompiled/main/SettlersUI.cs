using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SettlersUI : MonoBehaviour
{
	public TextMeshProUGUI generalName;

	public TextMeshProUGUI armyHealth;

	public Image generalIcon;

	public Button settlerBtn;

	private ArmySystem.Army army;

	private void OnDisable()
	{
	}

	public void SetSelectedArmy(ArmySystem.Army v)
	{
		army = v;
		SfxSystem.inst.PlayFromBank("VillagerSelect", v.general.position);
	}

	public void OnClickedSettle()
	{
		if (army != null)
		{
			army.Disband();
			army = null;
			gameObject.SetActive(value: false);
		}
	}

	private void Update()
	{
		if (army == null)
		{
			return;
		}
		if (army.general == null)
		{
			army = null;
			gameObject.SetActive(value: false);
		}
		if (army != null)
		{
			int num = 0;
			int armyHealthMax = 0;
			ArmySystem.inst.CalculateMinMaxHealth(army, ref num, ref armyHealthMax);
			armyHealth.SetText("ScriptLocalization.GeneralUIArmyHealth", num, armyHealthMax);
			Cell cellDataClamped = World.inst.GetCellDataClamped(army.generalPos);
			settlerBtn.interactable = Player.inst.LandMassIsAPlayerLandMass(cellDataClamped.landMassIdx);
			if (army.generalStatus == ArmySystem.Army.GeneralStatus.Dying)
			{
				army = null;
				gameObject.SetActive(value: false);
			}
		}
	}
}
