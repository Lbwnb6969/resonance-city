using I2.Loc;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class MilitaryShipUI : MonoBehaviour
{
	public TextMeshProUGUI shipName;

	public TextMeshProUGUI shipHealth;

	public Image generalIcon;

	public GameObject[] onBoardContainers;

	public Image[] onBoardImages;

	public Sprite[] knightSprites;

	public Sprite[] archerSprites;

	public Sprite[] catapultSprites;

	public Sprite[] settlerSprites;

	public Sprite[] envoySprites;

	private TroopTransportShip ship;

	private int prevOnBoardCount = -1;

	private void Start()
	{
	}

	private void OnDisable()
	{
	}

	public void SetSelectedArmy(TroopTransportShip v)
	{
		ship = v;
		SfxSystem.inst.PlayFromBank("TranspotShipSelect", v.transform.position);
		shipName.text = "ScriptLocalization.Building_trooptransportship_FriendlyName";
		UpdateOnBoardVisuals();
	}

	private void UpdateOnBoardVisuals()
	{
		if (!(ship != null))
		{
			return;
		}
		int num = (prevOnBoardCount = ship.CarryCount());
		int bannerIdx = World.GetLandmassOwnerByTeamId(ship.teamID).bannerIdx;
		for (int i = 0; i < 3; i++)
		{
			if (num <= i)
			{
				onBoardContainers[i].SetActive(value: false);
				continue;
			}
			IMoveableUnit carried = ship.GetCarried(i);
			onBoardContainers[i].SetActive(value: true);
			if (carried is ArmySystem.Army)
			{
				ArmySystem.Army army = carried as ArmySystem.Army;
				if (army.armyType == ArmySystem.ArmyType.Default)
				{
					onBoardImages[i].sprite = knightSprites[bannerIdx];
				}
				else if (army.armyType == ArmySystem.ArmyType.Archer)
				{
					onBoardImages[i].sprite = archerSprites[bannerIdx];
				}
				else if (army.armyType == ArmySystem.ArmyType.Settler)
				{
					onBoardImages[i].sprite = settlerSprites[bannerIdx];
				}
				else if (army.armyType == ArmySystem.ArmyType.Envoy)
				{
					onBoardImages[i].sprite = envoySprites[bannerIdx];
				}
			}
			else if (carried is SiegeCatapult)
			{
				onBoardImages[i].sprite = catapultSprites[bannerIdx];
			}
		}
	}

	public void OnClickedDisband()
	{
		if (ship != null)
		{
			ship.Disband();
			ship = null;
			gameObject.SetActive(value: false);
		}
	}

	private void Update()
	{
		if (!(ship == null) && ship != null)
		{
			shipHealth.SetText(ScriptLocalization.Health + " {0}/{1}", (int)ship.CurrHealth(), (int)ship.MaxHealth());
			if (ship.state == ShipBase.State.Sinking)
			{
				ship = null;
				gameObject.SetActive(value: false);
			}
			if (prevOnBoardCount != ship.CarryCount())
			{
				UpdateOnBoardVisuals();
			}
		}
	}
}
