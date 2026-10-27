using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SeedShipUI : MonoBehaviour
{
	public TextMeshProUGUI shipHealth;

	public Button SettleButton;

	private SeedShip army;

	public GameObject outpostPrefab;

	public Image outpost;

	private void OnDisable()
	{
	}

	public void SetSelectedArmy(SeedShip v)
	{
		army = v;
		SfxSystem.inst.PlayFromBank("TranspotShipSelect", v.transform.position);
	}

	public void OnClickedDisband()
	{
		if (army != null)
		{
			army.Disband();
			army = null;
			gameObject.SetActive(value: false);
		}
	}

	public void OnClickedSettle()
	{
		if (army != null)
		{
			GameUI.inst.CurrPlacementMode.SetCursorObject(outpostPrefab.GetComponent<Building>(), notFirstPlacement: false).GetComponent<Outpost>().placementRadius = army.SearchRadius;
			gameObject.SetActive(value: false);
		}
	}

	private void Update()
	{
		if (!(army == null) && army != null)
		{
			shipHealth.SetText(ScriptLocalization.Health + " {0}/{1}", (int)army.CurrHealth(), (int)army.MaxHealth());
			if (army.state == ShipBase.State.Sinking)
			{
				army = null;
				gameObject.SetActive(value: false);
			}
			SettleButton.interactable = army.CanSettle;
			if (army.CanSettle)
			{
				outpost.color = Color.white;
			}
			else
			{
				outpost.color = Color.gray;
			}
		}
	}
}
